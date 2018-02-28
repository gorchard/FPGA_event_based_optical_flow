--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   19:44:39 02/18/2018
-- Design Name:   
-- Module Name:   /neuromorphic/home_dirs/gorchard/Desktop/regado_motion/VHDL/ATIS_FPGA/simulate_fit_arbiter_inst.vhd
-- Project Name:  ATIS_ISL
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: fit_arbiter
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

ENTITY simulate_fit_arbiter_inst IS
END simulate_fit_arbiter_inst;
 
ARCHITECTURE behavior OF simulate_fit_arbiter_inst IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT fit_arbiter
    PORT(
         rst : IN  std_logic;
         clk : IN  std_logic;
         NUM_PIXELS_THRESHOLD : IN  std_logic_vector(3 downto 0);
         new_input_valid : IN  std_logic;
         new_which_valid_in : IN  valid5x5_type;
         new_z_in : IN  region5x5_type;
         new_x_in : IN  std_logic_vector(8 downto 0);
         new_y_in : IN  std_logic_vector(7 downto 0);
         refit_input_valid : IN  std_logic;
         refit_which_valid_in : IN  valid3x3_type;
         refit_z_in : IN  region3x3_type;
         refit_x_in : IN  std_logic_vector(8 downto 0);
         refit_y_in : IN  std_logic_vector(7 downto 0);
         which_valid_output : OUT  valid3x3_type;
         z_output : OUT  region3x3_type;
         x_output : OUT  std_logic_vector(8 downto 0);
         y_output : OUT  std_logic_vector(7 downto 0);
         output_valid : OUT  std_logic
        );
    END COMPONENT;
    

   --Inputs
   signal rst : std_logic := '0';
   signal clk : std_logic := '0';
   signal NUM_PIXELS_THRESHOLD : std_logic_vector(3 downto 0);
   signal new_input_valid : std_logic := '0';
   signal new_which_valid_in : valid5x5_type := (others => (others => '0'));
   signal new_z_in : region5x5_type := (others => (others => (others => '0')));
   signal new_x_in : std_logic_vector(8 downto 0) := (others => '0');
   signal new_y_in : std_logic_vector(7 downto 0) := (others => '0');
   signal refit_input_valid : std_logic := '0';
   signal refit_which_valid_in : valid3x3_type := (others => (others => '0'));
   signal refit_z_in : region3x3_type := (others => (others => (others => '0')));
   signal refit_x_in : std_logic_vector(8 downto 0) := (others => '0');
   signal refit_y_in : std_logic_vector(7 downto 0) := (others => '0');

 	--Outputs
   signal which_valid_output : valid3x3_type;
   signal z_output : region3x3_type := (others => (others => (others => '0')));
   signal x_output : std_logic_vector(8 downto 0);
   signal y_output : std_logic_vector(7 downto 0);
   signal output_valid : std_logic;

   -- Clock period definitions
   constant clk_period : time := 10 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: fit_arbiter PORT MAP (
          rst => rst,
          clk => clk,
          NUM_PIXELS_THRESHOLD => NUM_PIXELS_THRESHOLD,
          new_input_valid => new_input_valid,
          new_which_valid_in => new_which_valid_in,
          new_z_in => new_z_in,
          new_x_in => new_x_in,
          new_y_in => new_y_in,
          refit_input_valid => refit_input_valid,
          refit_which_valid_in => refit_which_valid_in,
          refit_z_in => refit_z_in,
          refit_x_in => refit_x_in,
          refit_y_in => refit_y_in,
          which_valid_output => which_valid_output,
          z_output => z_output,
          x_output => x_output,
          y_output => y_output,
          output_valid => output_valid
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
   
	file 			file_handler			:	text open read_mode is "../simulation/data/prepare_data_output.dat";
	variable 	row						:	line;
	variable		v_data_read				:	integer;
	
   begin		
      -- hold reset state for 100 ns.
      wait for 100 ns;	
		NUM_PIXELS_THRESHOLD	<= "0110";
      wait for clk_period*10;
		-- Stimulus process

      -- insert stimulus here 
		while not endfile(file_handler) loop
			
				readline(file_handler, row);
				read(row, v_data_read);
				new_x_in	<=	conv_std_logic_vector(v_data_read, 9);
				read(row, v_data_read);
				new_y_in	<=	conv_std_logic_vector(v_data_read, 8);
				for xx in -2 to 2 loop
					for yy in -2 to 2 loop
						read(row, v_data_read);
						if v_data_read = 1 then
							new_which_valid_in(yy)(xx)	<=	'1';
						else
							new_which_valid_in(yy)(xx)	<=	'0';
						end if;
						read(row, v_data_read);
						new_z_in(yy)(xx)	<=	conv_std_logic_vector(v_data_read, 18);
					end loop;
				end loop;
				new_input_valid	<= '1';
				wait for clk_period;
				new_input_valid	<= '0';
			
			wait for clk_period*10;
		end loop;

      wait;
   end process;


recording_proc: process
	
	file 			output_file			: text open write_mode is "../simulation/data/fit_arbiter_output.dat";
	variable 	output_file_line 	: line;
	
	begin		
      -- hold reset state for 100 ns.
      wait for 100 ns;	

      wait for clk_period*10;
		 
		loop 
			if output_valid = '1' then
				write(output_file_line, conv_integer(unsigned(x_output)));
				write(output_file_line, string'(" "));
				write(output_file_line, conv_integer(unsigned(y_output)));
				for xx in -1 to 1 loop
					for yy in -1 to 1 loop
						write(output_file_line, string'(" "));
						if which_valid_output(yy)(xx) = '1' then
							write(output_file_line, 1);
						else
							write(output_file_line, 0);
						end if;
						write(output_file_line, string'(" "));
						write(output_file_line, conv_integer(unsigned(z_output(yy)(xx))));
					end loop;
				end loop;
				writeline(output_file, output_file_line);
			end if;
			
			wait for clk_period;
		end loop;
		
      wait;
   end process;
	
END;
