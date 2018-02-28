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
-- Module Description

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.STD_LOGIC_arith.ALL;
use IEEE.std_logic_misc.all;

library WORK ;
--use work.utils_pack.all;
use work.ATISpackage.all;


entity map_3x3_input_to_vec is
port(
	-- new 5x5 regions being passed in
	din_which_valid		: in valid3x3_type;
	din_z						: in region3x3_type;
	din_x						: in std_logic_vector(8 downto 0);
	din_y						: in std_logic_vector(7 downto 0);
	
	dout_std_logic			: out std_logic_vector(9+8+3*3*(time_resolution_bits+1)-1 downto 0);
	
	
	din_std_logic			: in std_logic_vector(9+8+3*3*(time_resolution_bits+1)-1 downto 0);
	dout_which_valid		: out valid3x3_type;
	dout_z					: out region3x3_type;
	dout_x					: out std_logic_vector(8 downto 0);
	dout_y					: out std_logic_vector(7 downto 0)
	
	);
end entity ; 

architecture rtl of map_3x3_input_to_vec is

constant valid_offset	:	integer := 3*3*time_resolution_bits;
constant x_offset			:	integer := valid_offset+3*3;
constant y_offset			:	integer := x_offset+9;

begin
--map inputs to std_logic_vector
i_x : for outer_x in -1 to 1 generate
	i_y : for outer_y in -1 to 1 generate
			dout_std_logic(((outer_y+1)*3+(outer_x+1)+1)*time_resolution_bits-1 downto ((outer_y+1)*3+(outer_x+1))*time_resolution_bits)	<= din_z(outer_y)(outer_x);
			dout_std_logic(valid_offset+(outer_x+1)*3+(outer_y+1)) <= din_which_valid(outer_y)(outer_x);
			dout_std_logic(x_offset+8 downto x_offset) <= din_x;
			dout_std_logic(y_offset+7 downto y_offset) <= din_y;
	end generate i_y;
end generate i_x;

--map std_logic_vector back to 3x3 region
o_x : for outer_x in -1 to 1 generate
	o_y : for outer_y in -1 to 1 generate
			dout_z(outer_y)(outer_x) <= din_std_logic(((outer_y+1)*3+(outer_x+1)+1)*time_resolution_bits-1 downto ((outer_y+1)*3+(outer_x+1))*time_resolution_bits);
			dout_which_valid(outer_y)(outer_x) <= din_std_logic(valid_offset+(outer_x+1)*3+(outer_y+1));
			dout_x <= din_std_logic(x_offset+8 downto x_offset);
			dout_y <= din_std_logic(y_offset+7 downto y_offset);
	end generate o_y;
end generate o_x;


end rtl;

