--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   14:17:09 02/19/2018
-- Design Name:   
-- Module Name:   /neuromorphic/home_dirs/gorchard/Desktop/regado_motion/VHDL/ATIS_FPGA/simulate_plane_fit_wrapper.vhd
-- Project Name:  ATIS_ISL
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: plane_fitting_wrapper
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

 
ENTITY simulate_plane_fit_wrapper IS
END simulate_plane_fit_wrapper;
 
ARCHITECTURE behavior OF simulate_plane_fit_wrapper IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT plane_fitting_wrapper
    PORT(
         NUM_PIXELS_THRESHOLD : IN  std_logic_vector(3 downto 0);
         FIT_DISTANCE_THRESHOLD : IN  std_logic_vector(17 downto 0);
         rst : IN  std_logic;
         clk : IN  std_logic;
         fit_in_valid : IN  std_logic;
         fit_in_which_valid : IN  valid3x3_type;
         fit_in_x : IN  std_logic_vector(8 downto 0);
         fit_in_y : IN  std_logic_vector(7 downto 0);
         fit_in_z : IN  region3x3_type;
         refit_out_valid : OUT  std_logic;
         refit_out_which_valid : OUT  valid3x3_type;
         refit_out_x : OUT  std_logic_vector(8 downto 0);
         refit_out_y : OUT  std_logic_vector(7 downto 0);
         refit_out_z : OUT  region3x3_type;
         a : OUT  std_logic_vector(21 downto 0);
         b : OUT  std_logic_vector(21 downto 0);
         x_out : OUT  std_logic_vector(8 downto 0);
         y_out : OUT  std_logic_vector(7 downto 0);
         ab_valid : OUT  std_logic
        );
    END COMPONENT;
    

   --Inputs
   signal NUM_PIXELS_THRESHOLD : std_logic_vector(3 downto 0) := (others => '0');
   signal FIT_DISTANCE_THRESHOLD : std_logic_vector(17 downto 0) := (others => '0');
   signal rst : std_logic := '0';
   signal clk : std_logic := '0';
   signal fit_in_valid : std_logic := '0';
   signal fit_in_which_valid : valid3x3_type := (others => (others => '0'));
   signal fit_in_x : std_logic_vector(8 downto 0) := (others => '0');
   signal fit_in_y : std_logic_vector(7 downto 0) := (others => '0');
   signal fit_in_z : region3x3_type := (others => (others => (others => '0')));

 	--Outputs
   signal refit_out_valid : std_logic;
   signal refit_out_which_valid : valid3x3_type := (others => (others => '0'));
   signal refit_out_x : std_logic_vector(8 downto 0);
   signal refit_out_y : std_logic_vector(7 downto 0);
   signal refit_out_z : region3x3_type := (others => (others => (others => '0')));
   signal a : std_logic_vector(21 downto 0);
   signal b : std_logic_vector(21 downto 0);
   signal x_out : std_logic_vector(8 downto 0);
   signal y_out : std_logic_vector(7 downto 0);
   signal ab_valid : std_logic;

   -- Clock period definitions
   constant clk_period : time := 10 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: plane_fitting_wrapper PORT MAP (
          NUM_PIXELS_THRESHOLD => NUM_PIXELS_THRESHOLD,
          FIT_DISTANCE_THRESHOLD => FIT_DISTANCE_THRESHOLD,
          rst => rst,
          clk => clk,
          fit_in_valid => fit_in_valid,
          fit_in_which_valid => fit_in_which_valid,
          fit_in_x => fit_in_x,
          fit_in_y => fit_in_y,
          fit_in_z => fit_in_z,
          refit_out_valid => refit_out_valid,
          refit_out_which_valid => refit_out_which_valid,
          refit_out_x => refit_out_x,
          refit_out_y => refit_out_y,
          refit_out_z => refit_out_z,
          a => a,
          b => b,
          x_out => x_out,
          y_out => y_out,
          ab_valid => ab_valid
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
   
	file 			file_handler			:	text open read_mode is "../simulation/data/fit_arbiter_output.dat";
	variable 	row						:	line;
	variable		v_data_read				:	integer;
	
   begin		
      -- hold reset state for 100 ns.
      wait for 100 ns;	
		NUM_PIXELS_THRESHOLD		<= conv_std_logic_vector(6,4);
		FIT_DISTANCE_THRESHOLD	<= conv_std_logic_vector(4000,18);
      wait for clk_period*10;
		-- Stimulus process


--		--skip a number of samples before beginning simulation to allow us to hop straight to a problematic sample
--		for ii in 770167 downto 2 loop
--			readline(file_handler, row);
--		end loop;
		
      -- insert stimulus here 
		while not endfile(file_handler) loop
			
				readline(file_handler, row);
				read(row, v_data_read);
				fit_in_x	<=	conv_std_logic_vector(v_data_read, 9);
				read(row, v_data_read);
				fit_in_y	<=	conv_std_logic_vector(v_data_read, 8);
				for xx in -1 to 1 loop
					for yy in -1 to 1 loop
						read(row, v_data_read);
						if v_data_read = 1 then
							fit_in_which_valid(yy)(xx)	<=	'1';
						else
							fit_in_which_valid(yy)(xx)	<=	'0';
						end if;
						read(row, v_data_read);
						fit_in_z(yy)(xx)	<=	conv_std_logic_vector(v_data_read, 18);
					end loop;
				end loop;
				
				fit_in_valid	<= '1';
				wait for clk_period;
				fit_in_valid	<= '0';
			
				wait for clk_period;
		end loop;

      wait;
   end process;


recording_proc: process
	
	file 			output_file			: text open write_mode is "../simulation/data/plane_fitting_wrapper_out.dat";
	variable 	output_file_line 	: line;
	
	begin		
      -- hold reset state for 100 ns.
      wait for 100 ns;	

      wait for clk_period*10;
		 
		loop 
			if refit_out_valid = '1' then
				write(output_file_line, string'("0 ")); -- 0 means refit
				write(output_file_line, conv_integer(unsigned(refit_out_x)));
				write(output_file_line, string'(" "));
				write(output_file_line, conv_integer(unsigned(refit_out_y)));
				for xx in -1 to 1 loop
					for yy in -1 to 1 loop
						write(output_file_line, string'(" "));
						if refit_out_which_valid(yy)(xx) = '1' then
							write(output_file_line, 1);
						else
							write(output_file_line, 0);
						end if;
						write(output_file_line, string'(" "));
						write(output_file_line, conv_integer(unsigned(refit_out_z(yy)(xx))));
					end loop;
				end loop;
				
				writeline(output_file, output_file_line);
			elsif ab_valid = '1' then
				write(output_file_line, string'("1 ")); -- 1 means valid output
				write(output_file_line, conv_integer(unsigned(x_out)));
				write(output_file_line, string'(" "));
				write(output_file_line, conv_integer(unsigned(y_out)));
				write(output_file_line, string'(" "));
				write(output_file_line, conv_integer(signed(a)));
				write(output_file_line, string'(" "));
				write(output_file_line, conv_integer(signed(b)));
				write(output_file_line, string'(" "));
				for dummy in 15 downto 0 loop --write a bunch of dummy values to keep lines the same length
					write(output_file_line, string'("0 ")); 
				end loop;
				writeline(output_file, output_file_line);
			end if;
	
		
			wait for clk_period;
		end loop;
		
      wait;
   end process;
	


END;
