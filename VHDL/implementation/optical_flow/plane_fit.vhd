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

-- 3x3 least square plane fit, minimum six points required
-- a,b,d ten clock cycle from cell valid signal

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;


library WORK ;
--use work.utils_pack.all;
use work.ATISpackage.all;

entity plane_fit is
port(
	rst							: in std_logic;
	clk							: in std_logic;
	
	region_valid				: in std_logic;
	which_cell_valid			: in valid3x3_type;
	z_data						: in region3x3_type;
	
	a_b_d_rdy     				: out std_logic ;
	a								: out std_logic_vector(21 downto 0);
	b								: out std_logic_vector(21 downto 0);
	d								: out std_logic_vector(21 downto 0)
	);
end entity ; 


architecture rtl of plane_fit is

signal AtA_inv					: AtA_inv_type;
signal AtA_inv_valid	:	STD_LOGIC;

signal s_valid  : std_logic ;
signal s1							: std_logic_vector(time_resolution_bits-1 downto 0);
signal s2							: std_logic_vector(time_resolution_bits-1 downto 0);
signal s3							: std_logic_vector(time_resolution_bits-1 downto 0);


		
begin
inst_inverse_Atranspose_A : entity work.inverse_Atranspose_A
Port map(
	 rst 					=> rst,
	 clk 					=> clk,
	 
	 input_valid		=> region_valid,
	 which_A_valid		=> which_cell_valid,
	 
	 AtA_inv_valid 	=> AtA_inv_valid,
	 AtA_inv				=> AtA_inv
);

-- A'.B	
inst_a_transpose_mul_z:  entity work.a_transpose_mul_z 
port map(
   rst						=> rst ,
   clk 						=> clk ,
	
	region_valid			=> region_valid,
	which_cell_valid		=> which_cell_valid,
	z_data					=>	z_data,
  
	s_valid       			=> s_valid ,
	s1							=> s1 ,
	s2							=> s2 ,
	s3							=> s3
	);	

	
inst_a_b_d_result : entity work.a_b_d_result
port map(
   rst						=> rst ,
   clk                  => clk ,
	
	AtA_inv					=> AtA_inv,			
	 
	s_valid       			=> s_valid,                     
	s1							=> s1 ,
	s2							=> s2 ,
	s3							=> s3 , 
	
	a_b_d_rdy  				=> a_b_d_rdy ,                     
	a							=> a ,
	b							=> b ,
	d							=> d
	);
	
	


end rtl;
