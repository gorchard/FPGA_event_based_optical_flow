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


entity map_5x5_input_to_vec is
port(
	-- new 5x5 regions being passed in
	din_which_valid		: in valid5x5_type;
	din_z						: in region5x5_type;
	din_x						: in std_logic_vector(8 downto 0);
	din_y						: in std_logic_vector(7 downto 0);
	
	dout_std_logic			: out std_logic_vector(9+8+5*5*(time_resolution_bits+1)-1 downto 0);
	
	
	din_std_logic			: in std_logic_vector(9+8+5*5*(time_resolution_bits+1)-1 downto 0);
	dout_which_valid		: out valid3x3_vector_type;
	dout_z					: out region3x3_vector_type;
	dout_x					: out std_logic_vector(8 downto 0);
	dout_y					: out std_logic_vector(7 downto 0)
	
	);
end entity ; 



architecture rtl of map_5x5_input_to_vec is

constant valid_offset	:	integer := 5*5*time_resolution_bits;
constant x_offset			:	integer := valid_offset+5*5;
constant y_offset			:	integer := x_offset+9;

signal d_internal_which_valid : valid5x5_type;
signal d_internal_z 				: region5x5_type;

begin
--map inputs to std_logic_vector
i_x : for outer_x in -2 to 2 generate
	i_y : for outer_y in -2 to 2 generate
			dout_std_logic(((outer_y+2)*5+(outer_x+2)+1)*time_resolution_bits-1 downto ((outer_y+2)*5+(outer_x+2))*time_resolution_bits)	<= din_z(outer_y)(outer_x);
			dout_std_logic(valid_offset+(outer_x+2)*5+(outer_y+2)) <= din_which_valid(outer_y)(outer_x);
			dout_std_logic(x_offset+8 downto x_offset) <= din_x;
			dout_std_logic(y_offset+7 downto y_offset) <= din_y;
	end generate i_y;
end generate i_x;

--map std_logic_vector back to 5x5 region
o_x : for outer_x in -2 to 2 generate
	o_y : for outer_y in -2 to 2 generate
			d_internal_z(outer_y)(outer_x) <= din_std_logic(((outer_y+2)*5+(outer_x+2)+1)*time_resolution_bits-1 downto ((outer_y+2)*5+(outer_x+2))*time_resolution_bits);
			d_internal_which_valid(outer_y)(outer_x) <= din_std_logic(valid_offset+(outer_x+2)*5+(outer_y+2));
			dout_x <= din_std_logic(x_offset+8 downto x_offset);
			dout_y <= din_std_logic(y_offset+7 downto y_offset);
	end generate o_y;
end generate o_x;

--map 5x5 region to linear vector
o_xx : for ox in -1 to 1 generate
	o_yy : for oy in -1 to 1 generate
		i_xx : for ix in -1 to 1 generate
			i_yy : for iy in -1 to 1 generate
				dout_which_valid((oy+1)*3+(ox+1))(iy)(ix)		<= d_internal_which_valid(oy+iy)(ox+ix);
				dout_z((oy+1)*3+(ox+1))(iy)(ix)					<= d_internal_z(oy+iy)(ox+ix);
			end generate i_yy;
		end generate i_xx;
	end generate o_yy;
end generate o_xx;

end rtl;

