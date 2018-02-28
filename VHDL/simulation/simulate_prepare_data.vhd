--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   13:24:50 02/19/2018
-- Design Name:   
-- Module Name:   /neuromorphic/home_dirs/gorchard/Desktop/regado_motion/VHDL/ATIS_FPGA/simulate_prepare_data.vhd
-- Project Name:  ATIS_ISL
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: prepare_data
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
library IEEE;
use std.textio.all;
use IEEE.STD_LOGIC_textio.ALL;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_arith.ALL;
--use IEEE.NUMERIC_STD.all;
use IEEE.std_logic_unsigned.all;

use work.ATISpackage.all;
--use work.utils_pack.all;

 
ENTITY simulate_prepare_data IS
END simulate_prepare_data;
 
ARCHITECTURE behavior OF simulate_prepare_data IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT prepare_data
    PORT(
         OLD_PIXELS_THRESHOLD : IN  std_logic_vector(17 downto 0);
         clk : IN  std_logic;
         reset : IN  std_logic;
         input_valid : IN  std_logic;
         X_address : IN  std_logic_vector(8 downto 0);
         Y_address : IN  std_logic_vector(7 downto 0);
         region5x5_in : IN  region5x5signed_type;
         output_valid : OUT  std_logic;
         X_out : OUT  std_logic_vector(8 downto 0);
         Y_out : OUT  std_logic_vector(7 downto 0);
         region5x5 : OUT  region5x5_type;
         valid5x5 : OUT  valid5x5_type
        );
    END COMPONENT;
    

   --Inputs
   signal OLD_PIXELS_THRESHOLD : std_logic_vector(17 downto 0) := conv_std_logic_vector(200000,18);
   signal clk : std_logic := '0';
   signal reset : std_logic := '0';
   signal input_valid : std_logic := '0';
   signal X_address : std_logic_vector(8 downto 0) := (others => '0');
   signal Y_address : std_logic_vector(7 downto 0) := (others => '0');
   signal region5x5_in : region5x5signed_type	:=	(others => (others => (others => '0')));

 	--Outputs
   signal output_valid : std_logic;
   signal X_out : std_logic_vector(8 downto 0);
   signal Y_out : std_logic_vector(7 downto 0);
   signal region5x5 	: region5x5_type				:=	(others => (others => (others => '0')));
   signal valid5x5 	: valid5x5_type				:=	(others => (others => '0'));

   -- Clock period definitions
   constant clk_period : time := 10 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: prepare_data PORT MAP (
          OLD_PIXELS_THRESHOLD => OLD_PIXELS_THRESHOLD,
          clk => clk,
          reset => reset,
          input_valid => input_valid,
          X_address => X_address,
          Y_address => Y_address,
          region5x5_in => region5x5_in,
          output_valid => output_valid,
          X_out => X_out,
          Y_out => Y_out,
          region5x5 => region5x5,
          valid5x5 => valid5x5
        );

   -- Clock process definitions
   clk_process :process
   begin
		clk <= '0';
		wait for clk_period/2;
		clk <= '1';
		wait for clk_period/2;
   end process;
 

   -- Stimulus process
   stim_proc: process
	
	file 			file_handler			:	text open read_mode is "../simulation/data/Filter_RAM_output.dat";
	variable 	row						:	line;
	variable		v_data_read				:	integer;
	
   begin		
      -- hold reset state for 100 ns.
      wait for 100 ns;	

      wait for clk_period*10;

 
		
		-- insert stimulus here 
		while not endfile(file_handler) loop
			
				readline(file_handler, row);
				read(row, v_data_read);
				X_address	<=	conv_std_logic_vector(v_data_read, 9);
				read(row, v_data_read);
				Y_address	<=	conv_std_logic_vector(v_data_read, 8);
				read(row, v_data_read);
				read(row, v_data_read);
				for xx in -2 to 2 loop
					for yy in -2 to 2 loop
						read(row, v_data_read);
						region5x5_in(yy)(xx)	<=	conv_std_logic_vector(v_data_read, 19);
					end loop;
				end loop;
				input_valid	<= '1';
				wait for clk_period;
				input_valid	<= '0';
			
			wait for clk_period*2;
		end loop;
		
      wait;
   end process;
	
	
	recording_proc: process
	
	file 			output_file			: text open write_mode is "../simulation/data/prepare_data_output.dat";
	variable 	output_file_line 	: line;
	
	begin		
      -- hold reset state for 100 ns.
      wait for 100 ns;	

      wait for clk_period*10;
		
		
		
		loop 
			if output_valid = '1' then
				write(output_file_line, conv_integer(unsigned(X_out)));
				write(output_file_line, string'(" "));
				write(output_file_line, conv_integer(unsigned(Y_out)));
				for xx in -2 to 2 loop
					for yy in -2 to 2 loop
						write(output_file_line, string'(" "));
						if valid5x5(yy)(xx) = '1' then
							write(output_file_line, 1);
						else
							write(output_file_line, 0);
						end if;
						write(output_file_line, string'(" "));
						write(output_file_line, conv_integer(unsigned(region5x5(yy)(xx))));
					end loop;
				end loop;
				writeline(output_file, output_file_line);
			end if;
			
			wait for clk_period;
		end loop;
		
      wait;
   end process;
	

END;
