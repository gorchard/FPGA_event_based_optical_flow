----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    13:19:20 02/14/2018 
-- Design Name: 
-- Module Name:    inverse_A_Atranspose - Behavioral 
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
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library WORK ;
--use work.utils_pack.all;
use work.ATISpackage.all;

--calculates inv(A'A) using a lookup table

entity inverse_Atranspose_A is
Port ( 
	 rst 					: in  STD_LOGIC;
	 clk 					: in  STD_LOGIC;
	 
	 input_valid		: in 	STD_LOGIC;
	 which_A_valid		: in  valid3x3_type;
	 
	 AtA_inv_valid 	: out std_logic ;
	 AtA_inv				: out AtA_inv_type
);
end inverse_Atranspose_A;

architecture Behavioral of inverse_Atranspose_A is

signal	LUT_a_inverse_addr_valid	:	STD_LOGIC;
signal	LUT_a_inverse_addr			:	STD_LOGIC_VECTOR(7 downto 0);

begin
-- address for inverse(A.A')  LUT
inst_valid_LUT: entity work.valid_LUT 
port map(
	rst						=> rst ,
	clk						=> clk ,
	                     
	region_valid			=> input_valid,
	which_cell_valid		=> which_A_valid,
	                     
	LUT_addr_valid			=> LUT_a_inverse_addr_valid,
	LUT_addr					=> LUT_a_inverse_addr
	);
 
 
-- inverse(A.A') 
inst_a_inverse_lut_rom : entity work.a_inverse_lut_rom
port map(
	rst						=> rst ,
	clk						=> clk ,
	
	address_rdy				=> LUT_a_inverse_addr_valid,
	address					=> LUT_a_inverse_addr ,
	
	data_out_valid			=> AtA_inv_valid,
	data_out					=> AtA_inv
	);

end Behavioral;

