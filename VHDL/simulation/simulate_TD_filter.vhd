--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   15:14:33 02/28/2018
-- Design Name:   
-- Module Name:   /neuromorphic/home_dirs/gorchard/Desktop/regado_motion_vhdl/VHDL/simulate_TD_filter.vhd
-- Project Name:  optical_flow
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: TD_filter
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
use IEEE.NUMERIC_STD.all;
use IEEE.std_logic_unsigned.all;
 
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--USE ieee.numeric_std.ALL;
 
ENTITY simulate_TD_filter IS
END simulate_TD_filter;
 
ARCHITECTURE behavior OF simulate_TD_filter IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT TD_filter
    PORT(
         clk : IN  std_logic;
         Filter_enable : IN  std_logic;
         Refraction_enable : IN  std_logic;
         refractory_period : IN  std_logic_vector(15 downto 0);
         threshold : IN  std_logic_vector(15 downto 0);
         evt_in_type : IN  std_logic_vector(7 downto 0);
         evt_in_sub_type : IN  std_logic_vector(7 downto 0);
         evt_in_y : IN  std_logic_vector(15 downto 0);
         evt_in_x : IN  std_logic_vector(15 downto 0);
         evt_in_ts : IN  std_logic_vector(15 downto 0);
         evt_in_valid : IN  std_logic;
         evt_out_type : OUT  std_logic_vector(7 downto 0);
         evt_out_sub_type : OUT  std_logic_vector(7 downto 0);
         evt_out_y : OUT  std_logic_vector(15 downto 0);
         evt_out_x : OUT  std_logic_vector(15 downto 0);
         evt_out_ts : OUT  std_logic_vector(15 downto 0);
         evt_out_valid : OUT  std_logic
        );
    END COMPONENT;
	 
    COMPONENT ATIS_dummy
	GENERIC
	(
	   evt_type_TimerOverflow : integer
	);
	PORT(
		clk : IN std_logic;
		reset : IN std_logic;
		enable : IN std_logic;
		--data_in : IN std_logic_vector(63 downto 0);
		data_in_type	: in  STD_LOGIC_VECTOR (7 downto 0);
        data_in_subtype : in  STD_LOGIC_VECTOR (7 downto 0);
        data_in_x       : in  STD_LOGIC_VECTOR (15 downto 0);
        data_in_y       : in  STD_LOGIC_VECTOR (15 downto 0);
        data_in_ts      : in  STD_LOGIC_VECTOR (15 downto 0);
		data_in_valid : IN std_logic;          
		data_in_read : OUT std_logic;
		evt_type : OUT std_logic_vector(7 downto 0);
		evt_sub_type : OUT std_logic_vector(7 downto 0);
		evt_y : OUT std_logic_vector(15 downto 0);
		evt_x : OUT std_logic_vector(15 downto 0);
		evt_ts : OUT std_logic_vector(15 downto 0);
		evt_valid : OUT std_logic
		);
	END COMPONENT;

   --Inputs
   signal clk : std_logic := '0';
	signal rst : std_logic := '0';
   signal Filter_enable : std_logic := '1'; --to enable filtering
   signal Refraction_enable : std_logic := '1'; --to enable refraction
   signal refractory_period : std_logic_vector(15 downto 0) := "0000000000110010"; --50ms
   signal threshold : std_logic_vector(15 downto 0) 			:= "0000000001100100"; --100ms in binary
   signal evt_in_type : std_logic_vector(7 downto 0) := (others => '0');
   signal evt_in_sub_type : std_logic_vector(7 downto 0) := (others => '0');
   signal evt_in_y : std_logic_vector(15 downto 0) := (others => '0');
   signal evt_in_x : std_logic_vector(15 downto 0) := (others => '0');
   signal evt_in_ts : std_logic_vector(15 downto 0) := (others => '0');
   signal evt_in_valid : std_logic := '0';

 	--Outputs
   signal evt_out_type : std_logic_vector(7 downto 0);
   signal evt_out_sub_type : std_logic_vector(7 downto 0);
   signal evt_out_y : std_logic_vector(15 downto 0);
   signal evt_out_x : std_logic_vector(15 downto 0);
   signal evt_out_ts : std_logic_vector(15 downto 0);
   signal evt_out_valid : std_logic;

	 --Inputs
	signal enable : std_logic := '0';
   signal data_in_type	  : STD_LOGIC_VECTOR (7 downto 0) := (others => '0');
   signal data_in_subtype : STD_LOGIC_VECTOR (7 downto 0) := (others => '0');
   signal data_in_x       : STD_LOGIC_VECTOR (15 downto 0) := (others => '0');
   signal data_in_y       : STD_LOGIC_VECTOR (15 downto 0) := (others => '0');
   signal data_in_ts      : STD_LOGIC_VECTOR (15 downto 0) := (others => '0');
   signal data_in_valid : std_logic := '0';

 	--Outputs
   signal data_in_read : std_logic;
	
   -- Clock period definitions
   constant clk_period : time := 10 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: TD_filter PORT MAP (
          clk => clk,
          Filter_enable => Filter_enable,
          Refraction_enable => Refraction_enable,
          refractory_period => refractory_period,
          threshold => threshold,
          evt_in_type => evt_in_type,
          evt_in_sub_type => evt_in_sub_type,
          evt_in_y => evt_in_y,
          evt_in_x => evt_in_x,
          evt_in_ts => evt_in_ts,
          evt_in_valid => evt_in_valid,
          evt_out_type => evt_out_type,
          evt_out_sub_type => evt_out_sub_type,
          evt_out_y => evt_out_y,
          evt_out_x => evt_out_x,
          evt_out_ts => evt_out_ts,
          evt_out_valid => evt_out_valid
        );
	
	-- Instantiate the Unit Under Test (UUT)
   helper: ATIS_dummy 
   generic map(
           evt_type_TimerOverflow => 2  
   )
   PORT MAP (
          clk => clk,
          reset => rst,
			 enable => enable,
          --data_in => data_in,
          data_in_type     => data_in_type,
          data_in_subtype  => data_in_subtype,
          data_in_x        => data_in_x,      
          data_in_y        => data_in_y,    
          data_in_ts       => data_in_ts,     
          data_in_valid    => data_in_valid,
          data_in_read => data_in_read,
          evt_x => evt_in_x,
          evt_y => evt_in_y,
          evt_sub_type => evt_in_sub_type,
          evt_ts => evt_in_ts,
          evt_type => evt_in_type,
          evt_valid => evt_in_valid
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
	type t_char_file is file of character;
	file 			input_file			: t_char_file open read_mode is "../simulation/data/sim_dummy_input.val";
	variable		file_in				: character;
	
   begin		
      -- hold reset state for 100 ns.
      wait for 100 ns;	
      wait for clk_period*100;
      rst   <= '1';
      wait for clk_period*10;
      rst   <= '0';
      wait for clk_period;
      -- insert stimulus here
		
		--- load the first event before starting on the loop
		
		-- read 8 bytes (is one event) from the file and communicate this data to the test module
		read(input_file,  file_in);
		data_in_subtype <= std_logic_vector(to_unsigned(character'POS(file_in), 8));
		read(input_file,  file_in);
		data_in_type <= std_logic_vector(to_unsigned(character'POS(file_in), 8));
		read(input_file,  file_in);
		data_in_y(7 downto 0) <= std_logic_vector(to_unsigned(character'POS(file_in), 8));
		read(input_file,  file_in);
		data_in_y(15 downto 8)	<= std_logic_vector(to_unsigned(character'POS(file_in), 8));
		read(input_file,  file_in);
		data_in_x(7 downto 0) <= std_logic_vector(to_unsigned(character'POS(file_in), 8));
		read(input_file,  file_in);
		data_in_x(15 downto 8) <= std_logic_vector(to_unsigned(character'POS(file_in), 8));
		read(input_file,  file_in);
		data_in_ts(7 downto 0) <= std_logic_vector(to_unsigned(character'POS(file_in), 8));
		read(input_file,  file_in);
		data_in_ts(15 downto 8)	<= std_logic_vector(to_unsigned(character'POS(file_in), 8));
		
		data_in_valid <= '1';
		enable	<= '1';
		loop --loop forever
		
			if data_in_read = '1' then --if the module reads the data, then get the next data point.
				wait for clk_period;
				if not endfile(input_file) then -- check each time that we have not reached the end of the file (there is no guarantee that the file length is a multiple of 4096)
					read(input_file,  file_in);
                        data_in_subtype <= std_logic_vector(to_unsigned(character'POS(file_in), 8));
                        read(input_file,  file_in);
                        data_in_type <= std_logic_vector(to_unsigned(character'POS(file_in), 8));
                        read(input_file,  file_in);
                        data_in_y(7 downto 0) <= std_logic_vector(to_unsigned(character'POS(file_in), 8));
                        read(input_file,  file_in);
                        data_in_y(15 downto 8)    <= std_logic_vector(to_unsigned(character'POS(file_in), 8));
                        read(input_file,  file_in);
                        data_in_x(7 downto 0) <= std_logic_vector(to_unsigned(character'POS(file_in), 8));
                        read(input_file,  file_in);
                        data_in_x(15 downto 8) <= std_logic_vector(to_unsigned(character'POS(file_in), 8));
                        read(input_file,  file_in);
                        data_in_ts(7 downto 0) <= std_logic_vector(to_unsigned(character'POS(file_in), 8));
                        read(input_file,  file_in);
                        data_in_ts(15 downto 8)    <= std_logic_vector(to_unsigned(character'POS(file_in), 8));
					enable	<= '1';
					data_in_valid <= '1';
				else
					data_in_valid <= '0';
				end if;
			else
				wait for clk_period;
			end if;
			
		end loop;

      wait;
   end process;
	
	--optional process to record outputs from the module
	recording_proc: process
	
	file 			output_file		: text open write_mode is "../simulation/data/TD_filter_data_out.dat";
	variable 	output_file_line 	: line;
	
	begin		
      -- hold reset state for 100 ns.
      wait for 100 ns;	

      wait for clk_period*10;
			 
		loop 
			if evt_out_valid = '1' then
				write(output_file_line, conv_integer(evt_out_type));
				write(output_file_line, string'(","));
				write(output_file_line, conv_integer(evt_out_sub_type));
				write(output_file_line, string'(","));
				write(output_file_line, conv_integer(evt_out_x));
				write(output_file_line, string'(","));
				write(output_file_line, conv_integer(evt_out_y));
				write(output_file_line, string'(","));
				write(output_file_line, conv_integer(evt_out_ts));
				writeline(output_file, output_file_line);
			end if;
			
			wait for clk_period;
		end loop;
		
      wait;
   end process;
	
END;
