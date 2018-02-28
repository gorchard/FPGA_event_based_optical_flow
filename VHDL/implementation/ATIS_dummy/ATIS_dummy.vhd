----------------------------------------------------------------------------------
-- Company: 
-- Engineer: Garrick Orchard
-- 
-- Create Date:    15:57:28 12/15/2010 
-- Design Name: 
-- Module Name:    ATIS_dummy - Behavioral 
-- Project Name: 
-- Target Devices: Xilinx Spartan 6 lx150
-- Tool versions: 
-- Description: This module recreates an ATIS event stream as if it had come from the ATIS sensor itself. 
--					 Useful for software simulation or hardware in the loop simulation
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_misc.all;
use IEEE.std_logic_unsigned.all;

entity ATIS_dummy is
    generic (
                    evt_type_TimerOverflow : integer := 2 --this generic needs to be explicitly assigned when instantiating
    );
    Port ( 		    clk 			: in  STD_LOGIC; -- 100MHz clock. If another clock is used, the "PreCounter" module will need to be modified accordingly.
					reset			: in  STD_LOGIC;
					
					enable			: in  STD_LOGIC; -- set enable to '1' to enable this module. This allows the fifo to be filled before the module is enabled
					data_in_type	: in  STD_LOGIC_VECTOR (7 downto 0); -- 32 bits, if the input interface from PC is less, a FIFO with different read and write widths can be used
					data_in_subtype : in  STD_LOGIC_VECTOR (7 downto 0);
					data_in_x       : in  STD_LOGIC_VECTOR (15 downto 0);
					data_in_y       : in  STD_LOGIC_VECTOR (15 downto 0);
					data_in_ts      : in  STD_LOGIC_VECTOR (15 downto 0);
					data_in_valid	: in  STD_LOGIC; --indicates that the RAM FIFO contains valid data
					data_in_read	: out  STD_LOGIC	:= '0'; --read data from the RAM FIFO
				
					evt_type 		: out	STD_LOGIC_VECTOR (7 downto 0);
					evt_sub_type 	: out	STD_LOGIC_VECTOR (7 downto 0);
					evt_x			: out	STD_LOGIC_VECTOR (15 downto 0);
					evt_y		 	: out	STD_LOGIC_VECTOR (15 downto 0);
					evt_ts			: out	STD_LOGIC_VECTOR (15 downto 0);
					evt_tsMSB		: out	STD_LOGIC_VECTOR (15 downto 0);
					evt_valid		: out  STD_LOGIC -- indicates that the event data is valid
			  );
end ATIS_dummy; 

architecture Behavioral of ATIS_dummy is


-- A FIFO for buffering input data. Data will be delayed in this FIFO until the correct time arrives to pass it on to the rest of the processing system
COMPONENT ATIS_dummy_fifo
  PORT (
    clk : IN STD_LOGIC;
    rst : IN STD_LOGIC;
    din : IN STD_LOGIC_VECTOR(63 DOWNTO 0);
    wr_en : IN STD_LOGIC;
    rd_en : IN STD_LOGIC;
    dout : OUT STD_LOGIC_VECTOR(63 DOWNTO 0);
    full : OUT STD_LOGIC;
    empty : OUT STD_LOGIC;
    valid : OUT STD_LOGIC
  );
END COMPONENT;

COMPONENT PreTimestampCounter
  PORT (
    clk : IN STD_LOGIC;
    ce : IN STD_LOGIC;
    sclr : IN STD_LOGIC;
    thresh0 : OUT STD_LOGIC;
    q : OUT STD_LOGIC_VECTOR(6 DOWNTO 0)
  );
END COMPONENT;

COMPONENT TimestampCounter
  PORT (
    clk : IN STD_LOGIC;
    ce : IN STD_LOGIC;
    sclr : IN STD_LOGIC;
    thresh0 : OUT STD_LOGIC;
    q : OUT STD_LOGIC_VECTOR(15 DOWNTO 0)
  );
END COMPONENT;

---- Synplicity black box declaration
--attribute syn_black_box : boolean;

signal	CounterValue		:	std_logic_VECTOR(15 downto 0);
signal	PreCounterOverflow, CounterOverflow			   	: 	STD_LOGIC;

--signal	DataOutOVERFLOW					: 	STD_LOGIC_VECTOR(31 downto 0)	:= (others => '0');

signal	Valid_internal						: 	STD_LOGIC := '0';
signal	Fifo_data_valid					: 	STD_LOGIC;

signal 	TimeStamp_MSBs_internal			:	STD_LOGIC_VECTOR(15 downto 0)	:= (others => '0');

--signal  dummy   : STD_LOGIC;

signal	fifo_full					: STD_LOGIC;
signal	data_in_read_internal	: STD_LOGIC	:= '0';
signal	data_in_read_internal_delayed	: STD_LOGIC	:= '0';


signal	evt_type_internal 		: STD_LOGIC_VECTOR (7 downto 0);
signal	evt_sub_type_internal 	: STD_LOGIC_VECTOR (7 downto 0);
signal	evt_y_internal		 	: STD_LOGIC_VECTOR (15 downto 0);
signal	evt_x_internal			: STD_LOGIC_VECTOR (15 downto 0);
signal	evt_ts_internal			: STD_LOGIC_VECTOR (15 downto 0);


begin

-- we are not interested in the actual counter value, so long as we get an "overflow" pulse once per microsecond
PreCounter_Inst : PreTimestampCounter
port map (
	clk 		=> clk,
	sclr 		=> reset,
	q 			=> open,
	ce			=> enable,
	thresh0	=> PreCounterOverflow
	);

-- this counter is driven by the microsecond pulse, thus providing a microsecond clock counter
TimestampCounter_Inst : TimestampCounter
port map (
	clk 		=> clk,
	ce			=> PreCounterOverflow,
	sclr 		=> reset,
	thresh0	=> CounterOverflow,
	q			=> CounterValue
	);

                        
ATIS_dummy_fifo_inst : ATIS_dummy_fifo
  PORT MAP (
    clk => clk,
    rst => reset,
    din(63 downto 56) => data_in_type,
    din(55 downto 48) => data_in_subtype,
    din(47 downto 32) => data_in_y,
    din(31 downto 16) => data_in_x,
    din(15 downto 0) => data_in_ts,
    wr_en => data_in_read_internal,
    rd_en => Valid_internal,
    dout(63 downto 56) => evt_type_internal,
	dout(55 downto 48) => evt_sub_type_internal,
	dout(47 downto 32) => evt_y_internal,
	dout(31 downto 16) => evt_x_internal,
	dout(15 downto 0) => evt_ts_internal,
    full => fifo_full,
    empty => open,
    valid => Fifo_data_valid
  );
  

evt_type			<= evt_type_internal;
evt_sub_type 	<= evt_sub_type_internal;
evt_y		 		<= evt_y_internal;
evt_x				<= evt_x_internal;
evt_ts			<= evt_ts_internal;
					
evt_valid 			<= Valid_internal;
data_in_read	<=  data_in_read_internal;

evt_tsMSB		<= TimeStamp_MSBs_internal;



process (clk) begin
	if rising_edge(clk) then 
		
		if reset = '1' then
			Valid_internal <= '0';
			data_in_read_internal <= '0';
			TimeStamp_MSBs_internal	<= (others => '0');
		else
			--- this IF statement handles reading data from the external memory fifo
			data_in_read_internal_delayed	<= data_in_read_internal;
			if data_in_valid = '1' and fifo_full = '0' and data_in_read_internal = '0' and data_in_read_internal_delayed = '0' then
				data_in_read_internal	<= '1';
			else
				data_in_read_internal <= '0';
			end if;
			
			if CounterOverflow = '1' and PreCounterOverflow = '1' then
				TimeStamp_MSBs_internal	<=  TimeStamp_MSBs_internal + "01";
			end if;
			
			-- if we have just output an event then bring the Valid signal low again
			if Valid_internal = '1' then 
				Valid_internal <= '0';
			else
				if enable = '1' then
					-- if the data in the fifo is valid
					if Fifo_data_valid = '1' then
						-- if the current time matches the timestamp of the event
						if unsigned(evt_ts_internal) = unsigned(CounterValue) then 
							if unsigned(evt_type_internal) = evt_type_TimerOverflow then --check whether this is a timer overflow event
								if PreCounterOverflow = '1' and CounterOverflow = '1' then --if so, only output when the timer overflows
									Valid_internal <= '1'; 
								end if;
							else
								Valid_internal <= '1'; --if it is not a time overflow event, then output immediately
							end if;
						end if;
					end if;
				end if;
			end if;
		end if;
	end if;
end process;
end Behavioral;