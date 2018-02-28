--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   18:04:00 02/12/2016
-- Design Name:   
-- Module Name:   D:/Dropbox/Work/ATIS/VHDLandGUI/ATISv6/VHDL_v6.0/simulate_ATIS_dummy.vhd
-- Project Name:  ATIS_V6.0
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: ATIS_dummy
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

ENTITY simulate_ATIS_dummy IS
END simulate_ATIS_dummy;
 
ARCHITECTURE behavior OF simulate_ATIS_dummy IS 
    -- Component Declaration for the Unit Under Test (UUT)
 
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
   signal reset : std_logic := '0';
	signal enable : std_logic := '0';
   signal data_in_type	  : STD_LOGIC_VECTOR (7 downto 0) := (others => '0');
   signal data_in_subtype : STD_LOGIC_VECTOR (7 downto 0) := (others => '0');
   signal data_in_x       : STD_LOGIC_VECTOR (15 downto 0) := (others => '0');
   signal data_in_y       : STD_LOGIC_VECTOR (15 downto 0) := (others => '0');
   signal data_in_ts      : STD_LOGIC_VECTOR (15 downto 0) := (others => '0');
   signal data_in_valid : std_logic := '0';

 	--Outputs
   signal data_in_read : std_logic;
   
	signal evt_x : std_logic_vector(15 downto 0);
   signal evt_y : std_logic_vector(15 downto 0);
   signal evt_sub_type : std_logic_vector(7 downto 0);
   signal evt_ts : std_logic_vector(15 downto 0);
   signal evt_type : std_logic_vector(7 downto 0);
   signal evt_valid : std_logic;

   -- Clock period definitions
   constant clk_period : time := 10 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: ATIS_dummy 
   generic map(
           evt_type_TimerOverflow => 2  
   )
   PORT MAP (
          clk => clk,
          reset => reset,
		  enable => enable,
          --data_in => data_in,
          data_in_type     => data_in_type,
          data_in_subtype  => data_in_subtype,
          data_in_x        => data_in_x,      
          data_in_y        => data_in_y,    
          data_in_ts       => data_in_ts,     
          data_in_valid    => data_in_valid,
          data_in_read => data_in_read,
          evt_x => evt_x,
          evt_y => evt_y,
          evt_sub_type => evt_sub_type,
          evt_ts => evt_ts,
          evt_type => evt_type,
          evt_valid => evt_valid
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
      reset   <= '1';
      wait for clk_period*10;
      reset   <= '0';
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
	
	file 			output_file		: text open write_mode is "../simulation/data/sim_dummy_output.dat";
	variable 	output_file_line 	: line;
	
	begin		
      -- hold reset state for 100 ns.
      wait for 100 ns;	

      wait for clk_period*10;
		
		loop 
			if evt_valid = '1' then
				write(output_file_line, conv_integer(evt_type));
				write(output_file_line, string'(","));
				write(output_file_line, conv_integer(evt_sub_type));
				write(output_file_line, string'(","));
				write(output_file_line, conv_integer(evt_x));
				write(output_file_line, string'(","));
				write(output_file_line, conv_integer(evt_y));
				write(output_file_line, string'(","));
				write(output_file_line, conv_integer(evt_ts));
				writeline(output_file, output_file_line);
			end if;
			
			wait for clk_period;
		end loop;
		
      wait;
   end process;
  
END;
