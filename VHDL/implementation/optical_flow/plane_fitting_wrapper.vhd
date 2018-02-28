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


entity plane_fitting_wrapper is
port(
	NUM_PIXELS_THRESHOLD		: in std_logic_vector(3 downto 0);
   FIT_DISTANCE_THRESHOLD	: in std_logic_vector(17 downto 0); --in microseconds

	-- end user input parameters
	rst							: in std_logic;
	clk							: in std_logic;

	fit_in_valid				: in std_logic;
	fit_in_which_valid		: in valid3x3_type;
	fit_in_x						: in std_logic_vector(8 downto 0);
	fit_in_y						: in std_logic_vector(7 downto 0);
	fit_in_z						: in region3x3_type;

	refit_out_valid			: out std_logic;
	refit_out_which_valid	: out valid3x3_type;
	refit_out_x					: out std_logic_vector(8 downto 0);
	refit_out_y					: out std_logic_vector(7 downto 0);
	refit_out_z					: out region3x3_type;
	
	a								: out std_logic_vector(21 downto 0);
	b								: out std_logic_vector(21 downto 0);
	x_out							: out std_logic_vector(8 downto 0);
	y_out							: out std_logic_vector(7 downto 0);
	ab_valid						: out STD_LOGIC
	);
end entity ; 



architecture rtl of plane_fitting_wrapper is

signal	a_b_d_valid_internal	:	STD_LOGIC := '0';
signal	a_internal, b_internal, d_internal	:	STD_LOGIC_VECTOR(21 downto 0) := (others => '0');

signal	which_valid_internal	: valid3x3_type  := (others => (others => '0'));
signal	z_internal				: region3x3_type := (others => (others => (others => '0')));
signal	x_internal				: STD_LOGIC_VECTOR(8 downto 0) := (others => '0');
signal	y_internal				: STD_LOGIC_VECTOR(7 downto 0) := (others => '0');

signal	x_out_internal			: STD_LOGIC_VECTOR(8 downto 0) := (others => '0');
signal	y_out_internal			: STD_LOGIC_VECTOR(7 downto 0) := (others => '0');

begin

refit_out_x <= x_out_internal;
x_out 		<= x_out_internal;
refit_out_y <= y_out_internal;
y_out 		<= y_out_internal;

--this module buffers z_data, x, y, and which_valid while the plane fitting module does its job.
--first word fall-through, data is read when a_b_d_valid_internal = '1'
region_3x3_fifo_wrapper_inst : entity work.region_3x3_fifo_wrapper
port map (
	rst							=> rst,
	clk							=> clk,

	-- new 3x3 regions being passed in
	new_input_valid			=> fit_in_valid,
	new_which_valid_in		=> fit_in_which_valid,
	new_z_in						=> fit_in_z,
	new_x_in						=> fit_in_x,
	new_y_in						=> fit_in_y,
	
	-- 3x3 regions for fitting being passed out
	read_en						=> a_b_d_valid_internal,
	which_valid_output		=> which_valid_internal,
	z_output						=> z_internal,
	x_output						=> x_internal,
	y_output						=> y_internal,
	data_valid					=> open
	);
	
plane_fit_inst : entity work.plane_fit
port map(
	rst							=> rst,
	clk							=> clk,
	
	region_valid				=> fit_in_valid,
	which_cell_valid			=> fit_in_which_valid,
	z_data						=> fit_in_z,
--	x								=> fit_in_x,
--	y								=> fit_in_y,
	
	a_b_d_rdy     				=> a_b_d_valid_internal,
	a								=> a_internal,
	b								=> b_internal,
	d								=> d_internal
	);	
	

	
check_z_inst : entity work.check_z
port map(
	rst							=> rst,
	clk							=> clk,
	FIT_DISTANCE_THRESHOLD	=> FIT_DISTANCE_THRESHOLD,
	NUM_PIXELS_THRESHOLD		=> NUM_PIXELS_THRESHOLD,

	input_valid					=> a_b_d_valid_internal,
	a								=> a_internal,
	b								=> b_internal,
	d								=> d_internal,
	
	-- must come from a fifo
	which_valid_in				=> which_valid_internal,
	z_data						=> z_internal,
	x								=> x_internal,
	y								=> y_internal,

	z_out							=> refit_out_z,
	x_out							=> x_out_internal,
	y_out							=> y_out_internal,
	which_valid_output		=> refit_out_which_valid,
	refit							=> refit_out_valid,
	
	output_valid				=> ab_valid,
	a_out							=> a,
	b_out							=> b
);

end rtl;

