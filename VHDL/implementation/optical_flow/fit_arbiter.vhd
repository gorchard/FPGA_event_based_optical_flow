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


entity fit_arbiter is
port(
	rst							: in std_logic;
	clk							: in std_logic;
	
	NUM_PIXELS_THRESHOLD 	: in std_logic_vector(3 downto 0);
	
	-- new 5x5 regions being passed in
	new_input_valid			: in std_logic;
	new_which_valid_in		: in valid5x5_type;
	new_z_in						: in region5x5_type;
	new_x_in						: in std_logic_vector(8 downto 0);
	new_y_in						: in std_logic_vector(7 downto 0);
	
	-- 3x3 refit regions being passed in
	refit_input_valid			: in std_logic;
	refit_which_valid_in		: in valid3x3_type;
	refit_z_in					: in region3x3_type;
	refit_x_in					: in std_logic_vector(8 downto 0);
	refit_y_in					: in std_logic_vector(7 downto 0);
	
	-- 3x3 regions for fitting being passed out
	which_valid_output		: out valid3x3_type;
	z_output						: out region3x3_type;
	x_output						: out std_logic_vector(8 downto 0);
	y_output						: out std_logic_vector(7 downto 0);
	output_valid				: out std_logic
	
	);
end entity ; 



architecture rtl of fit_arbiter is

signal	which_valid_output_internal1	:	valid3x3_type 	:= (others => (others => '0'));
signal	z_output_internal1				:	region3x3_type	:= (others => (others => (others => '0')));
signal	x_output_internal1				:	std_logic_vector(8 downto 0) := (others => '0');
signal	y_output_internal1				:	std_logic_vector(7 downto 0) := (others => '0');
signal	output_valid_internal1			:	std_logic := '0';

signal	which_valid_output_internal2	:	valid3x3_type := (others => (others => '0'));
signal	z_output_internal2				:	region3x3_type := (others => (others => (others => '0')));
signal	x_output_internal2				:	std_logic_vector(8 downto 0)  := (others => '0');
signal	y_output_internal2				:	std_logic_vector(7 downto 0)  := (others => '0');
signal	refit_fifo_valid					:	std_logic := '0';
signal	refit_fifo_read_en				:	std_logic := '0';

begin

Inst_serialize_fifo_wrapper: entity work.serialize_fifo_wrapper 
PORT MAP(
		rst 						=> rst,
		clk 						=> clk,
		NUM_PIXELS_THRESHOLD => NUM_PIXELS_THRESHOLD,
		new_input_valid 		=> new_input_valid,
		new_which_valid_in 	=> new_which_valid_in,
		new_z_in 				=> new_z_in,
		new_x_in 				=> new_x_in,
		new_y_in 				=> new_y_in,
		which_valid_output 	=> which_valid_output_internal1,
		z_output 				=> z_output_internal1,
		x_output 				=> x_output_internal1,
		y_output 				=> y_output_internal1,
		output_valid 			=> output_valid_internal1
);

region_3x3_fifo_wrapper_inst : entity work.region_3x3_fifo_wrapper 
port map(
		rst 						=> rst,
		clk 						=> clk,
		
		-- refit 3x3 regions being passed in
		new_input_valid		=> refit_input_valid,
		new_which_valid_in	=> refit_which_valid_in,
		new_z_in					=> refit_z_in,
		new_x_in					=> refit_x_in,
		new_y_in					=> refit_y_in,
		read_en					=> refit_fifo_read_en,
		
		-- 3x3 regions for fitting being passed out
		which_valid_output	=> which_valid_output_internal2,
		z_output					=> z_output_internal2,
		x_output					=> x_output_internal2,
		y_output					=> y_output_internal2,
		data_valid				=> refit_fifo_valid
	
	);
	
refit_or_output_prc : process(clk)
begin
	if rising_edge(clk) then
		if output_valid_internal1 = '1' then
			which_valid_output 	<= which_valid_output_internal1;
			z_output 				<= z_output_internal1;
			x_output 				<= x_output_internal1;
			y_output 				<= y_output_internal1;
			output_valid 			<= '1';
			refit_fifo_read_en 	<= '0';
		elsif refit_fifo_valid = '1' then
			if refit_fifo_read_en = '0' then
				which_valid_output 	<= which_valid_output_internal2;
				z_output 				<= z_output_internal2;
				x_output 				<= x_output_internal2;
				y_output 				<= y_output_internal2;
				output_valid 			<= '1';
				refit_fifo_read_en 	<= '1';
			else
				output_valid 		 <= '0';
				refit_fifo_read_en <= '0';
			end if;
		else
				which_valid_output 	<= (others => (others => '0'));
				z_output 				<= (others => (others => (others => '0')));
				x_output 				<= (others => '0');
				y_output 				<= (others => '0');
				output_valid 		 <= '0';
			refit_fifo_read_en <= '0';
		end if;
		
	end if;
end process;
end rtl;

