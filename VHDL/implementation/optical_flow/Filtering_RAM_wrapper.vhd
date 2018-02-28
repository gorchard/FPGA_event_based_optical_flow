----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    12:51:35 02/06/2014 
-- Design Name: 
-- Module Name:    IBGhandler - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_misc.all;
use IEEE.std_logic_unsigned.all;
use work.ATISpackage.all;
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity Filtering_RAM_wrapper is
    Port ( 	
			REFRACTORY_PERIOD 	: in std_logic_vector(17 downto 0);
			OLD_PIXELS_THRESHOLD 	: in std_logic_vector(17 downto 0);
			
			clk 				: in  STD_LOGIC;
			reset 			: in  STD_LOGIC;
			
			--input event interface
			input_valid		: in  STD_LOGIC;
			X_address		: in 	STD_LOGIC_VECTOR(8 downto 0);
			Y_address		: in 	STD_LOGIC_VECTOR(7 downto 0);
			current_time	: in 	STD_LOGIC_VECTOR(18 downto 0);

			--output event interface
			X_out				: out	STD_LOGIC_VECTOR(8 downto 0)	:= (others => '0');
			Y_out				: out	STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
			output_valid	: out STD_LOGIC;
			fifo_error		: out STD_LOGIC	:= '0';
			fifo_full		: out STD_LOGIC;
			region5x5		: out region5x5signed_type	:= (others => (others => (others => '0')))
);
end Filtering_RAM_wrapper;


architecture Behavioral of Filtering_RAM_wrapper is

signal	Y_address_fifo, Y_address_internal, Y_in	: STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
signal	X_address_fifo, X_address_internal, X_in	: STD_LOGIC_VECTOR(8 downto 0) := (others => '0');
signal 	pipeline					: STD_LOGIC_VECTOR(3 downto 0)	:= (others => '0');
signal 	readcounter 				: STD_LOGIC_VECTOR(2 downto 0)	:= (others => '0');
signal	region5x5_internal	: region5x5signed_type	:= (others => (others => (others => '0')));
signal	row 						: region5x5signed_subtype := (others => (others => '0'));
signal	read_minor_address, read_minor_address_out : STD_LOGIC_VECTOR(2 downto 0)	:= (others => '0');

type write_enable_type is array (7 downto 0) of STD_LOGIC_VECTOR(0 downto 0);
signal	write_enable_a, write_enable_b			: write_enable_type	:= (others => "0");

type	data_type is array (7 downto 0) of STD_LOGIC_VECTOR(18 downto 0);
signal	write_data				: data_type			:= (others => (others => '0'));
signal	read_data_a, read_data_b				: data_type;

type	address_type is array (7 downto 0) of STD_LOGIC_VECTOR(13 downto 0);
signal	read_subaddress		:	address_type	:= (others => (others => '0'));

signal	write_subaddress		:	STD_LOGIC_VECTOR(13 downto 0);

signal	current_time_internal, current_time_internal_delay, current_time_fifo	: STD_LOGIC_VECTOR(18 downto 0)	:= (others => '0');
signal	delta_time					: STD_LOGIC_VECTOR(18 downto 0) := (others => '0');

type housekeeper is (reading, waiting, checking);
signal	currentState	: housekeeper	:= reading;

signal	housekeeping_X	: STD_LOGIC_VECTOR(5 downto 0)	:= (others => '0');
signal	housekeeping_Y	: STD_LOGIC_VECTOR(7 downto 0)	:= (others => '0');

signal	mark_invalid			:	STD_LOGIC	:= '0';
signal 	border					:	STD_LOGIC	:= '0';


signal	fifo_empty				:	STD_LOGIC;
signal	read_fifo				:	STD_LOGIC	:= '0';
signal	fifo_overflow			:	STD_LOGIC;
signal 	fifo_in, fifo_out		:	STD_LOGIC_VECTOR(35 downto 0);


signal	ready						:  STD_LOGIC	:= '1';
signal 	get_new_data				: STD_LOGIC :='0' ;


begin
---- a transpose happens here to keep consistency with other modules where location is addressed as region(y)(x)
---- could be written more compactly, just rushing through this...
--region5x5(-2)(-2) <= region5x5_internal(-2)(-2);
--region5x5(-2)(-1) <= region5x5_internal(-1)(-2);
--region5x5(-2)( 0) <= region5x5_internal( 0)(-2);
--region5x5(-2)( 1) <= region5x5_internal( 1)(-2);
--region5x5(-2)( 2) <= region5x5_internal( 2)(-2);
--region5x5(-1)(-2) <= region5x5_internal(-2)(-1);
--region5x5(-1)(-1) <= region5x5_internal(-1)(-1);
--region5x5(-1)( 0) <= region5x5_internal( 0)(-1);
--region5x5(-1)( 1) <= region5x5_internal( 1)(-1);
--region5x5(-1)( 2) <= region5x5_internal( 2)(-1);
--region5x5( 0)(-2) <= region5x5_internal(-2)( 0);
--region5x5( 0)(-1) <= region5x5_internal(-1)( 0);
----region5x5( 0)( 0) <= region5x5_internal( 0)( 0);
--region5x5( 0)( 0) <= current_time_internal; --middle pixel is always current time
--region5x5( 0)( 1) <= region5x5_internal( 1)( 0);
--region5x5( 0)( 2) <= region5x5_internal( 2)( 0);
--region5x5( 1)(-2) <= region5x5_internal(-2)( 1);
--region5x5( 1)(-1) <= region5x5_internal(-1)( 1);
--region5x5( 1)( 0) <= region5x5_internal( 0)( 1);
--region5x5( 1)( 1) <= region5x5_internal( 1)( 1);
--region5x5( 1)( 2) <= region5x5_internal( 2)( 1);
--region5x5( 2)(-2) <= region5x5_internal(-2)( 2);
--region5x5( 2)(-1) <= region5x5_internal(-1)( 2);
--region5x5( 2)( 0) <= region5x5_internal( 0)( 2);
--region5x5( 2)( 1) <= region5x5_internal( 1)( 2);
--region5x5( 2)( 2) <= region5x5_internal( 2)( 2);

region5x5(-2) <= region5x5_internal(-2);
region5x5(-1) <= region5x5_internal(-1);
region5x5(0)(-2) <= region5x5_internal(0)(-2);
region5x5(0)(-1) <= region5x5_internal(0)(-1);
region5x5(0)(0) <= current_time_internal;
region5x5(0)(1) <= region5x5_internal(0)(1);
region5x5(0)(2) <= region5x5_internal(0)(2);
region5x5(1) <= region5x5_internal(1);
region5x5(2) <= region5x5_internal(2);

fifo_in	<= (current_time & X_address & Y_address);
current_time_fifo <= fifo_out(35 downto 17);
X_address_fifo <= fifo_out(16 downto 8);
Y_address_fifo <= fifo_out(7 downto 0);



input_event_fifo_instance : entity work.input_event_fifo
  PORT MAP (
    clk => clk,
    rst => reset,
    din => fifo_in,
    wr_en => input_valid,
    rd_en => read_fifo,
    dout => fifo_out,
    full => fifo_full,
    overflow => fifo_overflow,
    empty => fifo_empty
  );
  
GenLoopInst:
for blk_RAM_num in 0 to 7 generate
filtering_RAM_Inst : entity work.preprocessing_RAM
PORT MAP (
    clka	=> clk,
    wea 	=> write_enable_a(blk_RAM_num),
    addra => write_subaddress,
    dina	=> write_data(blk_RAM_num),
	 douta => read_data_a(blk_RAM_num),
    clkb => clk,
	 web => write_enable_b(blk_RAM_num),
    addrb => read_subaddress(blk_RAM_num),
	 dinb => current_time_internal,
    doutb => read_data_b(blk_RAM_num)
  );
end generate GenLoopInst;


process (clk) begin
	if rising_edge(clk) then
		if fifo_overflow = '1' then
			fifo_error	<= '1';
		end if;
		
		pipeline(3 downto 1)	<= pipeline(2 downto 0);

		-- if the external module has requested a read
		if ready = '1' and fifo_empty = '0' then
			Y_address_internal	<= Y_address_fifo - "10"; --this is the first address of the 5x5 region to read
			X_address_internal	<= X_address_fifo - "10"; --this is the first address of the 5x5 region to read
			Y_in						<= Y_address_fifo;	--this is the address of the middle pixel
			X_in						<= X_address_fifo;	--this is the address of the middle pixel
			read_fifo <= '1';
			--Check if we are near the border
			if unsigned(X_address_fifo)>1 and unsigned(Y_address_fifo)>1 and unsigned(X_address_fifo)<302 and unsigned(Y_address_fifo)<238 then
				border	<= '0';
			else
				border	<= '1';	--if so, mark this as a border pixel
			end if;
			
			ready						<= '0'; --communicate that the module is not ready for new data
			pipeline(0)				<= '1'; --initiate the pipeline
			
			--store the time internally, but make sure not to use "0" since this is reserved for old/invalid pixels
			if unsigned(current_time_fifo) = 0 then
				current_time_internal_delay	<= conv_std_logic_vector(1,19);
			else
				current_time_internal_delay	<= current_time_fifo;
			end if;
		else
			read_fifo <= '0';
			--if pipeline(0) = '0' then
			if get_new_data = '1' then
				ready	<= '1';
			end if;
		end if;
		
		
		-- if we have just read the middle pixel, then check the input pixel against it for the refractory period
		if unsigned(readcounter) = 4 then
			case read_minor_address is
				when "000" =>
					if unsigned(read_data_b(2)) = 0 then
						delta_time	<= (others => '1');
					else
						delta_time	<= current_time_internal - read_data_b(2);
					end if;
				when "001" =>
					if unsigned(read_data_b(3)) = 0 then
						delta_time	<= (others => '1');
					else
						delta_time	<= current_time_internal - read_data_b(3);
					end if;
				when "010" =>
					if unsigned(read_data_b(4)) = 0 then
						delta_time	<= (others => '1');
					else
						delta_time	<= current_time_internal - read_data_b(4);
					end if;
				when "011" =>
					if unsigned(read_data_b(5)) = 0 then
						delta_time	<= (others => '1');
					else
						delta_time	<= current_time_internal - read_data_b(5);
					end if;
				when "100" =>
					if unsigned(read_data_b(6)) = 0 then
						delta_time	<= (others => '1');
					else
						delta_time	<= current_time_internal - read_data_b(6);
					end if;
				when "101" =>
					if unsigned(read_data_b(7)) = 0 then
						delta_time	<= (others => '1');
					else
						delta_time	<= current_time_internal - read_data_b(7);
					end if;
				when "110" =>
					if unsigned(read_data_b(0)) = 0 then
						delta_time	<= (others => '1');
					else
						delta_time	<= current_time_internal - read_data_b(0);
					end if;
				when "111" =>
					if unsigned(read_data_b(1)) = 0 then
						delta_time	<= (others => '1');
					else
						delta_time	<= current_time_internal - read_data_b(1);
					end if;
				when others =>
			end case;
		end if;

		
		
		-- 1st pipeline stage: split up the read address across all 8 RAMs
		if pipeline(0) = '1' then
			
			case X_address_internal(2 downto 0) is
				when "111"	=>
					for i in 7 downto 7 loop
						read_subaddress(i)	<= X_address_internal(8 downto 3) & Y_address_internal;
					end loop;
					for i in 6 downto 0 loop
						read_subaddress(i)	<= (X_address_internal(8 downto 3) + "01")  & Y_address_internal;
					end loop;
				when "110" =>
					for i in 7 downto 6 loop
						read_subaddress(i)	<= X_address_internal(8 downto 3)  & Y_address_internal;
					end loop;
					for i in 5 downto 0 loop
						read_subaddress(i)	<= (X_address_internal(8 downto 3) + "01")  & Y_address_internal;
					end loop;
				when "101"	=>
					for i in 7 downto 5 loop
						read_subaddress(i)	<= X_address_internal(8 downto 3) & Y_address_internal;
					end loop;
					for i in 4 downto 0 loop
						read_subaddress(i)	<= (X_address_internal(8 downto 3) + "01")  & Y_address_internal;
					end loop;
				when "100"	=>
					for i in 7 downto 4 loop
						read_subaddress(i)	<= X_address_internal(8 downto 3) & Y_address_internal;
					end loop;
					for i in 3 downto 0 loop
						read_subaddress(i)	<= (X_address_internal(8 downto 3) + "01")  & Y_address_internal;
					end loop;
				when others	=>
					for i in 7 downto 0 loop
						read_subaddress(i)	<= X_address_internal(8 downto 3) & Y_address_internal;
					end loop;
			end case;
			--read_major_address	<= X_address_internal(8 downto 3) & Y_address_internal;
			read_minor_address	<= X_address_internal(2 downto 0);
			
			Y_address_internal	<= Y_address_internal + "01";
			if unsigned(readcounter) = 4 then
				readcounter				<= (others => '0');
				pipeline(0) 			<= '0';
			else
				readcounter				<= readcounter + "01";
			end if;
		end if;
		
		-- 2nd pipeline stage: now the read address is valid
		if pipeline(1) = '1' then
			current_time_internal	<= current_time_internal_delay;
			read_minor_address_out	<= read_minor_address;
			X_out	<= X_in;
			Y_out <= Y_in;
			-- if this is the last pixel to be read, then determine whether to write the new pixel based on refractory period
			if pipeline(0) = '0' then 
				if unsigned(delta_time) > unsigned(REFRACTORY_PERIOD) then
					read_subaddress	<= (others => X_in(8 downto 3) & Y_in);
						case read_minor_address is
							when "000" =>
								write_enable_b(2)	<= "1";
							when "001" =>
								write_enable_b(3)	<= "1";
							when "010" =>
								write_enable_b(4)	<= "1";
							when "011" =>
								write_enable_b(5)	<= "1";
							when "100" =>
								write_enable_b(6)	<= "1";
							when "101" =>
								write_enable_b(7)	<= "1";
							when "110" =>
								write_enable_b(0)	<= "1";
							when "111" =>
								write_enable_b(1)	<= "1";
							when others =>
								write_enable_b	<= (others => "0");
						end case;
					if border = '0' then
						mark_invalid	<= '0';
					else
						mark_invalid	<= '1';
					end if;
				else
					mark_invalid	<= '1';
				end if;
			end if;
		else
			write_enable_b	<= (others => "0");
		end if;
		
		-- 3rd pipeline stage, now the output data is valid, arrange it into the correct X locations within the current row
		if pipeline(2) = '1' then
			case read_minor_address_out is
				when "000" =>
					row(-2)	<= read_data_b(0);
					row(-1)	<= read_data_b(1);
					row(0)	<= read_data_b(2);
					row(1)	<= read_data_b(3);
					row(2)	<= read_data_b(4);
				when "001" =>
					row(-2)	<= read_data_b(1);
					row(-1)	<= read_data_b(2);
					row(0)	<= read_data_b(3);
					row(1)	<= read_data_b(4);
					row(2)	<= read_data_b(5);
				when "010" =>
					row(-2)	<= read_data_b(2);
					row(-1)	<= read_data_b(3);
					row(0)	<= read_data_b(4);
					row(1)	<= read_data_b(5);
					row(2)	<= read_data_b(6);
				when "011" =>
					row(-2)	<= read_data_b(3);
					row(-1)	<= read_data_b(4);
					row(0)	<= read_data_b(5);
					row(1)	<= read_data_b(6);
					row(2)	<= read_data_b(7);
				when "100" =>
					row(-2)	<= read_data_b(4);
					row(-1)	<= read_data_b(5);
					row(0)	<= read_data_b(6);
					row(1)	<= read_data_b(7);
					row(2)	<= read_data_b(0);
				when "101" =>
					row(-2)	<= read_data_b(5);
					row(-1)	<= read_data_b(6);
					row(0)	<= read_data_b(7);
					row(1)	<= read_data_b(0);
					row(2)	<= read_data_b(1);
				when "110" =>
					row(-2)	<= read_data_b(6);
					row(-1)	<= read_data_b(7);
					row(0)	<= read_data_b(0);
					row(1)	<= read_data_b(1);
					row(2)	<= read_data_b(2);
				when "111" =>
					row(-2)	<= read_data_b(7);
					row(-1)	<= read_data_b(0);
					row(0)	<= read_data_b(1);
					row(1)	<= read_data_b(2);
					row(2)	<= read_data_b(3);
				when others =>
			end case;
		end if;
		
		-- 4th pipeline stage, the row data is valid, shift it into the correct row
		if pipeline(3) = '1' then
			region5x5_internal(2)				<= row;
			region5x5_internal(1 downto -2)	<= region5x5_internal(2 downto -1);
			
			if pipeline(2) = '0' then
				if mark_invalid = '0' then
					output_valid <= '1';
				end if;
				get_new_data <= '1' ;
			else
				get_new_data <= '0' ;
			end if;
			
		else
			get_new_data <= '0' ;
			output_valid <= '0';
		end if;
		
	
	
	
	
	-- do some housekeeping to prevent timer overflows. We need to check each pixel at least once every 2^(time_resolution_bits-1) timesteps.  
	-- Currently it checks once every 10ns*3clock cycles*304*240pixels/8memories = 273us
	-- High frequency of checking means that collisions are likely. Currently we just skip a pixel if we detect a possible collision
	-- Better (more power efficient) manner would be to trigger housekeeping occasionally, and pause it when a conflict is detected
	 
	 case currentState is
		when reading =>	--set the read address and increment
			if unsigned(housekeeping_Y) = 239 then
				housekeeping_Y	<= (others => '0');
				if unsigned(housekeeping_X) = 37 then
					housekeeping_X	<= (others => '0');
				else
					housekeeping_X	<= housekeeping_X + "01";
				end if;
			else
				housekeeping_Y	<= housekeeping_Y + "01";
			end if;
			
			write_subaddress	<= housekeeping_X & housekeeping_Y;
			currentState	<= waiting;
			write_enable_a	<= (others => "0");
						
		 when waiting => -- one clock cycle pause for reading
			-- during write cycle for main code, all read_addresses are the same. If our write address is the same as the read address, skip to the next pixel to avoid a conflict
			if write_subaddress = read_subaddress(0) then 
				currentState	<= reading;
			else
				currentState	<= checking;
			end if;

		 when checking => -- check if the pixel is older than the old pixel threshold
 			-- during write cycle for main code, all read_addresses are the same. If our write address is the same as the read address, skip to the next pixel to avoid a conflict
			if write_subaddress = read_subaddress(0) then 
				currentState	<= reading;
			else
				for i in 7 downto 0 loop
					if (unsigned(current_time_internal - read_data_a(i)) >= unsigned(OLD_PIXELS_THRESHOLD)) then --if so, write 0 to the location to mark it as overflowed/invalid
						write_data(i)	<= (others => '0');
						write_enable_a(i)	<= "1";
					else --otherwise do not worry about writing
						--write_data(i)	<= read_data_a(i);
						write_enable_a(i)	<= "0";
					end if;
				end loop;
				currentState	<= reading; --go back to the start and repeat
			end if;

	 end case;

	end if;
end process;

end Behavioral;