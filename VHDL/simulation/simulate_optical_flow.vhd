--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   15:07:34 02/18/2018
-- Design Name:   
-- Module Name:   /neuromorphic/home_dirs/gorchard/Desktop/regado_motion/VHDL/ATIS_FPGA/simulate_optical_flow.vhd
-- Project Name:  ATIS_ISL
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: optical_flow
-- 
-- Dependencies:
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
-- Notes: 
-- This testbench has been automatically generated using types std_logic and
-- std_logic_vector for the ports of the unit under test.  Xilinx recommends
-- that these types always be used for the top-level I/O of a design in order
-- to guarantee that the testbench will bind correctly to the post-implementation 
-- simulation model.
--------------------------------------------------------------------------------
use std.textio.all;


library IEEE;
use ieee.std_logic_textio.all;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_misc.all;
use IEEE.std_logic_unsigned.all;

use work.ATISpackage.all;
--use work.utils_pack.all;


ENTITY simulate_optical_flow IS
END simulate_optical_flow;
 
ARCHITECTURE behavior OF simulate_optical_flow IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 component optical_flow is
port(
	NUM_PIXELS_THRESHOLD		: in std_logic_vector(3 downto 0);
	OLD_PIXELS_THRESHOLD		: in std_logic_vector(17 downto 0); --in microseconds
   FIT_DISTANCE_THRESHOLD	: in std_logic_vector(17 downto 0); --in microseconds
	REFRACTORY_PERIOD			: in std_logic_vector(17 downto 0); --in microseconds

	-- end user input parameters
	rst							: in std_logic;
	clk							: in std_logic;

	--input events
	event_valid_in				: in std_logic;
	x_in							: in std_logic_vector(8 downto 0);
	y_in							: in std_logic_vector(7 downto 0);
	current_time				: in std_logic_vector(18 downto 0);
	
	--output motion events
	event_valid_out			: out std_logic;
	x_out							: out std_logic_vector(8 downto 0);
	y_out							: out std_logic_vector(7 downto 0);
	vx_out						: out std_logic_vector(15 downto 0);
	vy_out						: out std_logic_vector(15 downto 0)
	);
end component;
    
	 COMPONENT ATIS_dummy
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
    END COMPONENT;
	 
   --Inputs
   signal NUM_PIXELS_THRESHOLD : std_logic_vector(3 downto 0) 		:= conv_std_logic_vector(6,4);
   signal OLD_PIXELS_THRESHOLD : std_logic_vector(17 downto 0) 	:= conv_std_logic_vector(200000,18);
   signal FIT_DISTANCE_THRESHOLD : std_logic_vector(17 downto 0) 	:= conv_std_logic_vector(4000,18);
   signal REFRACTORY_PERIOD : std_logic_vector(17 downto 0) 		:= conv_std_logic_vector(50000,18);
   signal rst : std_logic := '0';
   signal clk : std_logic := '0';

 	--Outputs
   signal event_valid_out : std_logic;
   signal x_out : std_logic_vector(8 downto 0);
   signal y_out : std_logic_vector(7 downto 0);
   signal vx_out : std_logic_vector(15 downto 0);
   signal vy_out : std_logic_vector(15 downto 0);

   -- Clock period definitions
   constant clk_period : time := 10 ns;

	signal evt_type			:	STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
	signal evt_sub_type		:	STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
	signal evt_ts				:	STD_LOGIC_VECTOR(31 downto 0) := (others => '0');
	signal event_valid_in : std_logic := '0';
   signal x_in : std_logic_vector(15 downto 0) := (others => '0');
   signal y_in : std_logic_vector(15 downto 0) := (others => '0');
	
BEGIN

	-- Instantiate the Unit Under Test (UUT)
   uut: optical_flow PORT MAP (
          NUM_PIXELS_THRESHOLD => NUM_PIXELS_THRESHOLD,
          OLD_PIXELS_THRESHOLD => OLD_PIXELS_THRESHOLD,
          FIT_DISTANCE_THRESHOLD => FIT_DISTANCE_THRESHOLD,
          REFRACTORY_PERIOD => REFRACTORY_PERIOD,
          rst => rst,
          clk => clk,
          event_valid_in => event_valid_in,
          x_in => x_in(8 downto 0),
          y_in => y_in(7 downto 0),
			 current_time => evt_ts(18 downto 0),
          event_valid_out => event_valid_out,
          x_out => x_out,
          y_out => y_out,
          vx_out => vx_out,
          vy_out => vy_out
        );

   -- Clock process definitions
   clk_process :process
   begin
		clk <= '0';
		wait for clk_period/2;
		clk <= '1';
		wait for clk_period/2;
   end process;

	
	stim_proc: process
	
   begin		
      -- hold reset state for 100 ns.
      wait for 100 ns;	
      wait for clk_period*100;
      rst   <= '1';
      wait for clk_period*10;
      rst   <= '0';
      wait for clk_period;
      -- insert stimulus here
		
		x_in				<=	conv_std_logic_vector(10, 9);
		y_in				<=	conv_std_logic_vector(10, 8);
		evt_ts			<=	conv_std_logic_vector(1000, 32);
		event_valid_in	<= '1';
		wait for clk_period;
		x_in				<=	conv_std_logic_vector(10, 9);
		y_in				<=	conv_std_logic_vector(9, 8);
		evt_ts			<=	conv_std_logic_vector(1000, 32);
		event_valid_in	<= '1';
		wait for clk_period;
		x_in				<=	conv_std_logic_vector(10, 9);
		y_in				<=	conv_std_logic_vector(11, 8);
		evt_ts			<=	conv_std_logic_vector(1000, 32);
		event_valid_in	<= '1';
		wait for clk_period;
		x_in				<=	conv_std_logic_vector(11, 9);
		y_in				<=	conv_std_logic_vector(10, 8);
		evt_ts			<=	conv_std_logic_vector(2000, 32);
		event_valid_in	<= '1';
		wait for clk_period;
		x_in				<=	conv_std_logic_vector(11, 9);
		y_in				<=	conv_std_logic_vector(9, 8);
		evt_ts			<=	conv_std_logic_vector(2000, 32);
		event_valid_in	<= '1';
		wait for clk_period;
		x_in				<=	conv_std_logic_vector(11, 9);
		y_in				<=	conv_std_logic_vector(11, 8);
		evt_ts			<=	conv_std_logic_vector(2000, 32);
		event_valid_in	<= '1';
		
      wait;
   end process;
	
	
END;
