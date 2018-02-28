----------------------------------------------------------------------------------
-- Company:
-- Author:
-- 
-- Create Date:    
-- Design Name: 
-- Module Name:    
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
-- takes in a 5x5 pixel region, along with a 5x5 valid (1 bit) array
-- returns 3x3 pixel subregions, along with 3x3 subregion valid array
-- can output up to 1 subregion per clock cycle (assumes later stages are fully pipelined)

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.STD_LOGIC_arith.ALL;
use IEEE.std_logic_misc.all;

library WORK ;
--use work.utils_pack.all;
use work.ATISpackage.all;


entity region_3x3_fifo_wrapper is
port(
	rst							: in std_logic;
	clk							: in std_logic;

	-- new 5x5 regions being passed in
	new_input_valid			: in std_logic;
	new_which_valid_in		: in valid3x3_type;
	new_z_in						: in region3x3_type;
	new_x_in						: in std_logic_vector(8 downto 0);
	new_y_in						: in std_logic_vector(7 downto 0);
	read_en						: in STD_LOGIC;
	
	-- 3x3 regions for fitting being passed out
	which_valid_output		: out valid3x3_type;
	z_output						: out region3x3_type;
	x_output						: out std_logic_vector(8 downto 0);
	y_output						: out std_logic_vector(7 downto 0);
	data_valid					: out std_logic
	
	);
end entity ; 



architecture rtl of region_3x3_fifo_wrapper is

--fifo vectors
signal	fifo_din_vector, fifo_dout_vector	: STD_LOGIC_VECTOR(9+8+3*3*(time_resolution_bits+1)-1  downto 0);

begin

-- hides away the mapping from array to a std_logic_vector for the fifo
map_3x3_input_to_vec_inst : entity work.map_3x3_input_to_vec
port map(
	-- new 5x5 regions being passed in
	din_z 				=> new_z_in,
	din_x 				=> new_x_in,
	din_y 				=> new_y_in,
	din_which_valid 	=> new_which_valid_in,
	dout_std_logic		=> fifo_din_vector,
	
	din_std_logic		=> fifo_dout_vector,
	dout_which_valid	=>	which_valid_output,
	dout_z				=>	z_output,
	dout_x				=> x_output,
	dout_y				=> y_output
	);

fifo_3x3_region_inst : entity work.fifo_3x3_region
  PORT MAP (
    clk 					=> clk,
    rst 					=> rst,
    din 					=> fifo_din_vector,
    wr_en 				=> new_input_valid,
    rd_en 				=> read_en,
    dout 				=> fifo_dout_vector,
    full 				=> open,
    empty 				=> open,
    valid 				=> data_valid
  );

end rtl;

