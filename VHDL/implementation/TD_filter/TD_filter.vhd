--This module implements noise filtering and refractory period, 
--which can be used as a preprocessing step before computing optical flow
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_misc.all;
use IEEE.std_logic_unsigned.all;

use work.ATISpackage.all;

entity TD_filter is

    Port (
		clk					: in STD_LOGIC;
		Filter_enable		: in STD_LOGIC;
		Refraction_enable : in STD_LOGIC;
		refractory_period	: in STD_LOGIC_VECTOR(15 downto 0);
		threshold			: in STD_LOGIC_VECTOR(15 downto 0);
		evt_in_type 		: in STD_LOGIC_VECTOR(7 downto 0);
		evt_in_sub_type 	: in STD_LOGIC_VECTOR(7 downto 0);
		evt_in_y		 		: in STD_LOGIC_VECTOR(15 downto 0);
		evt_in_x				: in STD_LOGIC_VECTOR(15 downto 0);
		evt_in_ts			: in STD_LOGIC_VECTOR(15 downto 0);
		evt_in_valid		: in STD_LOGIC;

		evt_out_type 		: out STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
		evt_out_sub_type 	: out STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
		evt_out_y		 	: out STD_LOGIC_VECTOR(15 downto 0) := (others => '0');
		evt_out_x			: out STD_LOGIC_VECTOR(15 downto 0) := (others => '0');
		evt_out_ts			: out STD_LOGIC_VECTOR(15 downto 0) := (others => '0');
		evt_out_valid		: out STD_LOGIC);
			  
end TD_filter;

architecture Behavioral of TD_filter is

COMPONENT counter1ms
  PORT (
    clk 	: IN STD_LOGIC;
	 ce	: IN STD_LOGIC;
    thresh0 : OUT STD_LOGIC;
    q : OUT STD_LOGIC_VECTOR(16 DOWNTO 0)
  );
END COMPONENT;

COMPONENT counter256
  PORT (
    clk 	: IN STD_LOGIC;
    ce 	: IN STD_LOGIC;
	 q 	: OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
  );
END COMPONENT;

COMPONENT TDfilter_RAM
  PORT (
    clka : IN STD_LOGIC;
    wea : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
	 ena	: IN STD_LOGIC;
    addra : IN STD_LOGIC_VECTOR(16 DOWNTO 0);
    dina : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    clkb : IN STD_LOGIC;
	 enb	: IN STD_LOGIC;
    addrb : IN STD_LOGIC_VECTOR(16 DOWNTO 0);
    doutb : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
  );
END COMPONENT;

COMPONENT filter_fifo
  PORT (
    clk : IN STD_LOGIC;
    din : IN STD_LOGIC_VECTOR(63 DOWNTO 0);
    wr_en : IN STD_LOGIC;
    rd_en : IN STD_LOGIC;
    dout : OUT STD_LOGIC_VECTOR(63 DOWNTO 0);
    full : OUT STD_LOGIC;
    empty : OUT STD_LOGIC;
    valid : OUT STD_LOGIC
  );
END COMPONENT;

signal x_internal				: STD_LOGIC_VECTOR(8 downto 0);
signal y_internal				: STD_LOGIC_VECTOR(7 downto 0);

signal read_address 			: STD_LOGIC_VECTOR(16 downto 0);
signal delayed_address_1	: STD_LOGIC_VECTOR(16 downto 0);
signal delayed_address_2	: STD_LOGIC_VECTOR(16 downto 0);
signal write_address 		: STD_LOGIC_VECTOR(16 downto 0);
signal read_time				: STD_LOGIC_VECTOR(7 downto 0);
signal write_time				: STD_LOGIC_VECTOR(7 downto 0);
signal write_enable			: STD_LOGIC;

signal house_keeping_X		 : STD_LOGIC_VECTOR(8 downto 0) := (others => '0');
signal house_keeping_Y		 : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');


signal millisecond_tick		: STD_LOGIC;
signal counter_time			: STD_LOGIC_VECTOR(7 downto 0);

signal processing_stage		: STD_LOGIC_VECTOR(12 downto 0) := (others => '0'); --one hot encoding of which processing step we're in
signal house_keeping_stage	: STD_LOGIC_VECTOR(2 downto 0) := (others => '0'); --one hot encoding of which processing step we're in

signal filter_valid			: STD_LOGIC := '0'; --used to mark whether the event gets through the neighbour filter
signal refractory_valid		: STD_LOGIC := '0'; --used to mark whether the event gets through the refractory filter

signal fifo_read_en			: STD_LOGIC;
signal fifo_valid				: STD_LOGIC;
signal x_fifo					: STD_LOGIC_VECTOR(15 downto 0);
signal y_fifo					: STD_LOGIC_VECTOR(15 downto 0);
signal subtype_fifo, type_fifo	: STD_LOGIC_VECTOR(7 downto 0);
signal ts_fifo					: STD_LOGIC_VECTOR(15 downto 0);

signal	clk_enable			:	STD_LOGIC	:= '0';

begin

filter_fifo_inst : filter_fifo
  PORT MAP (
    clk 						=> clk,
    din(63 downto 56) 	=> evt_in_type,
	 din(55 downto 48) 	=> evt_in_sub_type,
	 din(47 downto 32)	=> evt_in_y,
	 din(31 downto 16) 	=> evt_in_x,
	 din(15 downto 0) 	=> evt_in_ts,
    wr_en 					=> evt_in_valid,
    rd_en 					=> fifo_read_en,
	 dout(63 downto 56) 	=> type_fifo,
	 dout(55 downto 48)	=> subtype_fifo,
	 dout(47 downto 32)	=> y_fifo,
	 dout(31 downto 16) 	=> x_fifo,
	 dout(15 downto 0) 	=> ts_fifo,
    full 	=> open,
    empty 	=> open,
    valid 	=> fifo_valid
  );
  
PreCounter_Inst : counter1ms
port map (
	clk 		=> clk,
	ce			=> clk_enable,
	thresh0	=> millisecond_tick,
	q			=> open
	);

Counter_Inst : counter256
port map (
	clk 		=> clk,
	ce			=> millisecond_tick,
	q			=> counter_time
	);

TDfilter_RAM_INST : TDfilter_RAM
port map(
    clka 	=> clk,
    ena		=> Filter_enable,
	 wea(0) 	=> write_enable,
    addra 	=> write_address,
    dina 	=> write_time,
    clkb 	=> clk,
	 enb		=> Filter_enable,
    addrb  	=> read_address,
    doutb 	=> read_time
  );
  
process (clk) begin
	if rising_edge(clk) then
		clk_enable <= Filter_enable or refraction_enable;
		if Filter_enable = '0' and refraction_enable = '0' then
			processing_stage	<= (others => '0');
			write_enable		<= '0';
			refractory_valid	<= '0';
			filter_valid	<= '0';
			
			if fifo_valid = '1' then
				if fifo_read_en = '0' then
					fifo_read_en		<= '1';
					evt_out_valid		<=	'0';
				else
					fifo_read_en		<= '0';
					evt_out_valid		<=	'1';
				end if;
			else
				fifo_read_en		<= '0';
				evt_out_valid		<=	'0';
			end if;
			evt_out_x				<=	x_fifo;
			evt_out_y				<=	y_fifo;
			evt_out_ts				<=	ts_fifo;
			evt_out_sub_type		<=	subtype_fifo;
			evt_out_type			<=	type_fifo;
			
		else
			processing_stage(12 downto 1)	<= processing_stage(11 downto 0);
			house_keeping_stage(2 downto 1) <= house_keeping_stage(1 downto 0);
			-- if there is a spike to be processed, initialize the processing
			if unsigned(processing_stage) = 0 then
				
				if fifo_valid = '1' and fifo_read_en = '0' then
					evt_out_x				<=	x_fifo;
					evt_out_y				<=	y_fifo;
					evt_out_ts				<=	ts_fifo;
					evt_out_sub_type		<=	subtype_fifo;
					evt_out_type			<=	type_fifo;
					
					x_internal 				<= x_fifo(8 downto 0) - "01"; --ONLY SUPPORTS ATIS RESOLUTION AT THE MOMENT
					y_internal 				<= y_fifo(7 downto 0) - "01"; --ONLY SUPPORTS ATIS RESOLUTION AT THE MOMENT
					if unsigned(type_fifo) /= unsigned(evt_type_TD) then --if it is not a TD event
						evt_out_valid			<= '1';
						--fifo_read_en 			<= '1';
					else
						processing_stage(0)	<= '1';
						evt_out_valid			<= '0';
					end if;
					
					house_keeping_stage(0) <= '0';
					filter_valid				<= '0';
					fifo_read_en 			<= '1';
				else
					--fifo_read_en 			<= '1';
					evt_out_valid			<= '0';
					fifo_read_en 			<= '0';
					read_address			<= house_keeping_X & house_keeping_Y; 
					if unsigned(house_keeping_Y) = 239 then
						house_keeping_Y	<= (others => '0');
						if unsigned(house_keeping_X) = 303 then
							house_keeping_X	<= (others => '0');
						else
							house_keeping_X <= house_keeping_X + "01";
						end if;
					else
						house_keeping_Y <= house_keeping_Y + "01";
					end if;
					house_keeping_stage(0) <= '1';
					processing_stage(0)	<= '0';
				end if;
			else
				fifo_read_en 			<= '0';
				house_keeping_stage(0) <= '0';
				processing_stage(0)	<= '0';
			end if;
			
			
			-- if processing has been initialized, go through the surrounding neighbourhood
			if processing_stage(0) = '1' then --first read address assigned during this clock tick
				read_address			<= x_internal & y_internal; 
			end if;

			if processing_stage(1) = '1' then --first read address valid during this clock tick
				read_address			<= x_internal + "01" & y_internal;
			end if;
			
			if processing_stage(2) = '1' then --first read data valid during this clock tick
				read_address			<= x_internal + "10" & y_internal;
			end if;
			
			if processing_stage(3) = '1' then
				read_address			<= x_internal & y_internal + "01";
			end if;
			
			if processing_stage(4) = '1' then
				read_address			<= x_internal + "01" & y_internal + "01";
			end if;
			
			if processing_stage(5) = '1' then
				read_address			<= x_internal + "10" & y_internal + "01";
			end if;
			
			if processing_stage(6) = '1' then
				read_address			<= x_internal & y_internal + "10";
			end if;
			
			if processing_stage(7) = '1' then
				read_address			<= x_internal + "01" & y_internal + "10";
			end if;
			
			if processing_stage(8) = '1' then
				read_address			<= x_internal + "10" & y_internal + "10";
			end if;
			
			if processing_stage(12) = '1' then --this is when all computation is finishing
				if (filter_valid = '1' or Filter_enable = '0')and (refractory_valid = '1' or refraction_enable = '0') then --output the event either way, but mark it as filtered if it doesn't meet criteria
					evt_out_valid	<= '1';
				else
					evt_out_type	<=	evt_type_TD_Filtered;
					evt_out_valid		<= '1';
				end if;
			end if;
			
			--
			delayed_address_1 <= read_address;
			delayed_address_2 <= delayed_address_1;
			write_address <= delayed_address_2;
			if unsigned(processing_stage(6 downto 3)) >0 or unsigned(processing_stage(11 downto 8)) >0 then --these are the stages where read_data is valid and not the same pixel
				if (unsigned(counter_time - read_time) < unsigned(threshold)) and (unsigned(read_time) /=0) then
					filter_valid	<= '1';
					write_time	<= read_time;
				else -- if the time is above the threshold, write zeros in to indicate an invalid time
					write_time	<= (others => '0'); 
				end if;
				write_enable	<= '1';
			end if;
			
			-- write the most recent time to the pixel array, but avoid writing the number zero since it indicates an invalid time
			if processing_stage(7) = '1' then 
				if unsigned(counter_time) /= 0 then
					write_time	<= counter_time;
				else
					write_time	<= "00000001";
				end if;
				write_enable	<= '1';
				if (unsigned(counter_time - read_time) <= unsigned(refractory_period)) and (unsigned(read_time) /=0) then
					refractory_valid <= '0';
				else
					refractory_valid <= '1';
				end if;
			end if;
			
			-- if housekeeping stage
			if house_keeping_stage(2) = '1' then
				if (unsigned(counter_time - read_time) < unsigned(threshold)) or (unsigned(counter_time - read_time) < unsigned(refractory_period)) then
					write_time	<= read_time; --no need to write the time back
					write_enable	<= '0';
				else
					write_time		<= (others => '0'); 
					write_enable	<= '1';
				end if;
			end if;
			
			if (house_keeping_stage(2) = '0') and (unsigned(processing_stage(11 downto 3)) = 0) then
				write_enable	<= '0';
			end if;
		end if;
	end if;
end process;
end Behavioral;