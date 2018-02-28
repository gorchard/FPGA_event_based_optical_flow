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
library IEEE;
use std.textio.all;
use IEEE.STD_LOGIC_textio.ALL;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_arith.ALL;
--use IEEE.NUMERIC_STD.all;
use IEEE.std_logic_unsigned.all;

use work.ATISpackage.all;
--use work.utils_pack.all;


ENTITY simulate_Filter_RAM_wrapper IS
END simulate_Filter_RAM_wrapper;
 
ARCHITECTURE behavior OF simulate_Filter_RAM_wrapper IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    component filtering_RAM_wrapper is
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
   signal event_valid_in : std_logic := '0';
   signal x_in : std_logic_vector(15 downto 0) := (others => '0');
   signal y_in : std_logic_vector(15 downto 0) := (others => '0');
   signal current_time : std_logic_vector(18 downto 0) := (others => '0');

 	--Outputs
   signal output_valid : std_logic;
   signal x_out : std_logic_vector(8 downto 0);
   signal y_out : std_logic_vector(7 downto 0);
   signal fifo_error : std_logic;
	signal fifo_full : std_logic;
	signal region5x5		: region5x5signed_type;
			

   -- Clock period definitions
   constant clk_period : time := 10 ns;
	
	
	--internals
	signal enable		:	STD_LOGIC := '0';
	signal data_in_type		:	STD_LOGIC_VECTOR(7 downto 0)	:= (others => '0');
	signal data_in_subtype	:	STD_LOGIC_VECTOR(7 downto 0)	:= (others => '0');
	signal data_in_x			:	STD_LOGIC_VECTOR(15 downto 0)	:= (others => '0');
	signal data_in_y			:	STD_LOGIC_VECTOR(15 downto 0)	:= (others => '0');
	signal data_in_ts			:	STD_LOGIC_VECTOR(15 downto 0)	:= (others => '0');
	signal data_in_valid		:	STD_LOGIC := '0';
	signal data_in_read:	STD_LOGIC := '0';
	
	signal evt_type			:	STD_LOGIC_VECTOR(7 downto 0);
	signal evt_sub_type		:	STD_LOGIC_VECTOR(7 downto 0);
	signal evt_valid			:	STD_LOGIC := '0';
	signal evt_ts				:	STD_LOGIC_VECTOR(31 downto 0);
	
	
BEGIN

   test_help: ATIS_dummy 
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
          data_in_read 		=> data_in_read,
			 
          evt_x 			=> x_in,
          evt_y 			=> y_in,
          evt_sub_type => evt_sub_type,
          evt_ts => evt_ts(15 downto 0),
			 evt_tsMSB => evt_ts(31 downto 16),
          evt_type => evt_type,
          evt_valid => evt_valid
        );


	-- Instantiate the Unit Under Test (UUT)
   uut: filtering_RAM_wrapper PORT MAP (
			REFRACTORY_PERIOD 	=> REFRACTORY_PERIOD,
			OLD_PIXELS_THRESHOLD => OLD_PIXELS_THRESHOLD,
			
			clk 						=> clk,
			reset 					=> rst,
			
			--input event interface
			input_valid						=>event_valid_in,
			X_address						=>x_in(8 downto 0),
			Y_address						=>y_in(7 downto 0),
			current_time					=> evt_ts(18 downto 0),
			 
			--output event interface
			X_out				=> X_out,
			Y_out				=> Y_out,
			output_valid	=> output_valid,
			fifo_error		=> fifo_error,
			fifo_full		=> fifo_full,
			region5x5		=> region5x5
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
   intermediate_proc: process
   begin		
      -- hold reset state for 100 ns.
      wait for 100 ns;	

      wait for clk_period*10;
		loop
			if unsigned(evt_type) = 0 then
				event_valid_in	<= evt_valid;
			else
				event_valid_in	<= '0';
			end if;
			wait for clk_period;
		end loop;
		
      -- insert stimulus here 

      wait;
   end process;
	
	
	stim_proc: process
	type t_char_file is file of character;
	file 			input_file			: t_char_file open read_mode is "../simulation/data/sim_dummy_input.val";
	variable		file_in				: character;
	
   begin		
      -- hold reset state for 100 ns.
      wait for 100 ns;	
      rst   <= '1';
		wait for clk_period*100;
      rst   <= '0';
      wait for clk_period;
      -- insert stimulus here
		
		--- load the first event before starting on the loop
		
		-- read 8 bytes (is one event) from the file and communicate this data to the test module
		read(input_file,  file_in);
		data_in_subtype <= conv_std_logic_vector(character'POS(file_in), 8);
		read(input_file,  file_in);
		data_in_type <= conv_std_logic_vector(character'POS(file_in), 8);
		read(input_file,  file_in);
		data_in_y(7 downto 0) <= conv_std_logic_vector(character'POS(file_in), 8);
		read(input_file,  file_in);
		data_in_y(15 downto 8)	<= conv_std_logic_vector(character'POS(file_in), 8);
		read(input_file,  file_in);
		data_in_x(7 downto 0) <= conv_std_logic_vector(character'POS(file_in), 8);
		read(input_file,  file_in);
		data_in_x(15 downto 8) <= conv_std_logic_vector(character'POS(file_in), 8);
		read(input_file,  file_in);
		data_in_ts(7 downto 0) <= conv_std_logic_vector(character'POS(file_in), 8);
		read(input_file,  file_in);
		data_in_ts(15 downto 8)	<= conv_std_logic_vector(character'POS(file_in), 8);
		
		data_in_valid <= '1';
		enable	<= '1';
		loop --loop forever
		
			if data_in_read = '1' then --if the module reads the data, then get the next data point.
				wait for clk_period;
				if not endfile(input_file) then -- check each time that we have not reached the end of the file (there is no guarantee that the file length is a multiple of 4096)
					read(input_file,  file_in);
                        data_in_subtype <= conv_std_logic_vector(character'POS(file_in), 8);
                        read(input_file,  file_in);
                        data_in_type <= conv_std_logic_vector(character'POS(file_in), 8);
                        read(input_file,  file_in);
                        data_in_y(7 downto 0) <= conv_std_logic_vector(character'POS(file_in), 8);
                        read(input_file,  file_in);
                        data_in_y(15 downto 8)    <= conv_std_logic_vector(character'POS(file_in), 8);
                        read(input_file,  file_in);
                        data_in_x(7 downto 0) <= conv_std_logic_vector(character'POS(file_in), 8);
                        read(input_file,  file_in);
                        data_in_x(15 downto 8) <= conv_std_logic_vector(character'POS(file_in), 8);
                        read(input_file,  file_in);
                        data_in_ts(7 downto 0) <= conv_std_logic_vector(character'POS(file_in), 8);
                        read(input_file,  file_in);
                        data_in_ts(15 downto 8)    <= conv_std_logic_vector(character'POS(file_in), 8);
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
	



		
	recording_proc: process
	
	file 			output_file			: text open write_mode is "../simulation/data/Filter_RAM_output.dat";
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
				write(output_file_line, string'(" "));
				if fifo_error = '1' then
					write(output_file_line, 1);
				else
					write(output_file_line, 0);
				end if;
				write(output_file_line, string'(" "));
				if fifo_full = '1' then
					write(output_file_line, 1);
				else
					write(output_file_line, 0);
				end if;
				for xx in -2 to 2 loop
					for yy in -2 to 2 loop
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
