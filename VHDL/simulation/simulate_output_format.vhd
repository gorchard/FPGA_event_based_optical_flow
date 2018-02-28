--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   17:12:40 02/26/2018
-- Design Name:   
-- Module Name:   /neuromorphic/home_dirs/gorchard/Desktop/regado_motion/VHDL/ATIS_FPGA/simulate_format_output.vhd
-- Project Name:  ATIS_ISL
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: format_output
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
 
ENTITY simulate_format_output IS
END simulate_format_output;
 
ARCHITECTURE behavior OF simulate_format_output IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT format_output
    PORT(
         rst : IN  std_logic;
         clk : IN  std_logic;
         a : IN  std_logic_vector(21 downto 0);
         b : IN  std_logic_vector(21 downto 0);
         x_in : IN  std_logic_vector(8 downto 0);
         y_in : IN  std_logic_vector(7 downto 0);
         ab_valid : IN  std_logic;
         vx_out : OUT  std_logic_vector(15 downto 0);
         vy_out : OUT  std_logic_vector(15 downto 0);
         x_out : OUT  std_logic_vector(8 downto 0);
         y_out : OUT  std_logic_vector(7 downto 0);
         output_valid : OUT  std_logic
        );
    END COMPONENT;
    

   --Inputs
   signal rst : std_logic := '0';
   signal clk : std_logic := '0';
   signal a : std_logic_vector(21 downto 0) := (others => '0');
   signal b : std_logic_vector(21 downto 0) := (others => '0');
   signal x_in : std_logic_vector(8 downto 0) := (others => '0');
   signal y_in : std_logic_vector(7 downto 0) := (others => '0');
   signal ab_valid : std_logic := '0';

 	--Outputs
   signal vx_out : std_logic_vector(15 downto 0);
   signal vy_out : std_logic_vector(15 downto 0);
   signal x_out : std_logic_vector(8 downto 0);
   signal y_out : std_logic_vector(7 downto 0);
   signal output_valid : std_logic;

   -- Clock period definitions
   constant clk_period : time := 10 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: format_output PORT MAP (
          rst => rst,
          clk => clk,
          a => a,
          b => b,
          x_in => x_in,
          y_in => y_in,
          ab_valid => ab_valid,
          vx_out => vx_out,
          vy_out => vy_out,
          x_out => x_out,
          y_out => y_out,
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
   
	file 			file_handler			:	text open read_mode is "../simulation/data/plane_fitting_wrapper_out.dat";
	variable 	row						:	line;
	variable		v_data_read				:	integer;
	
   begin		
      -- hold reset state for 100 ns.
      wait for 100 ns;	
				
      wait for clk_period*100;
		rst	<= '0';
		-- Stimulus process


--		--skip a number of samples before beginning simulation to allow us to hop straight to a problematic sample
--		for ii in 770167 downto 2 loop
--			readline(file_handler, row);
--		end loop;
		
      -- insert stimulus here 
		while not endfile(file_handler) loop
				readline(file_handler, row);
				read(row, v_data_read);
				while v_data_read = 0 and not endfile(file_handler) loop --0 means refit
					readline(file_handler, row);
					read(row, v_data_read);
				end loop;
				
				read(row, v_data_read);
				x_in	<=	conv_std_logic_vector(v_data_read, 9);
				read(row, v_data_read);
				y_in	<=	conv_std_logic_vector(v_data_read, 8);
				read(row, v_data_read);
				a		<=	conv_std_logic_vector(v_data_read, 22);
				read(row, v_data_read);
				b		<=	conv_std_logic_vector(v_data_read, 22);

				ab_valid	<= '1';
				wait for clk_period;
		end loop;
		ab_valid	<= '0';
		
      wait;
   end process;


recording_proc: process
	
	file 			output_file			: text open write_mode is "../simulation/data/format_output_out.dat";
	variable 	output_file_line 	: line;
	
	begin		
      -- hold reset state for 100 ns.
      wait for 100 ns;	
		
		
      wait for clk_period*10;
		 
		loop 
			if output_valid = '1' then
				write(output_file_line, conv_integer(unsigned(x_out)));
				write(output_file_line, string'(" "));
				write(output_file_line, conv_integer(unsigned(y_out)));
				write(output_file_line, string'(" "));
				write(output_file_line, conv_integer(signed(vx_out)));
				write(output_file_line, string'(" "));
				write(output_file_line, conv_integer(signed(vy_out)));
				write(output_file_line, string'(" "));
				writeline(output_file, output_file_line);
			end if;
			wait for clk_period;
		end loop;
		
      wait;
   end process;

END;
