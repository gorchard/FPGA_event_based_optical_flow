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


entity optical_flow is
port(
	NUM_PIXELS_THRESHOLD		: in std_logic_vector(3 downto 0);
	OLD_PIXELS_THRESHOLD		: in std_logic_vector(17 downto 0); --in microseconds
   FIT_DISTANCE_THRESHOLD	: in std_logic_vector(17 downto 0); --in microseconds
	REFRACTORY_PERIOD			: in std_logic_vector(17 downto 0); --in microseconds

	-- end user input parameters
	rst							: in std_logic;
	clk							: in std_logic;

	--input events
	event_valid_in				: in std_logic;
	x_in							: in std_logic_vector(8 downto 0);
	y_in							: in std_logic_vector(7 downto 0);
	current_time				: in std_logic_vector(18 downto 0);
	
	--output motion events
	event_valid_out			: out std_logic;
	x_out							: out std_logic_vector(8 downto 0);
	y_out							: out std_logic_vector(7 downto 0);
	vx_out						: out std_logic_vector(15 downto 0);
	vy_out						: out std_logic_vector(15 downto 0)
	);
end entity;



architecture rtl of optical_flow is


signal	new_valid					:	STD_LOGIC;
signal	new_x							:	STD_LOGIC_VECTOR(8 downto 0);
signal	new_y							:	STD_LOGIC_VECTOR(7 downto 0);
signal	new_region5x5				:	region5x5signed_type;
			
			
signal	prepared_output_valid		:	STD_LOGIC;
signal	prepared_x						:	STD_LOGIC_VECTOR(8 downto 0);
signal	prepared_y						:	STD_LOGIC_VECTOR(7 downto 0);
signal	prepared_region5x5			:	region5x5_type;
signal	prepared_valid5x5				:	valid5x5_type;
			

signal	refit_valid						:	STD_LOGIC;
signal	refit_which_valid				:	valid3x3_type;
signal	refit_z							:	region3x3_type;
signal	refit_x							:	STD_LOGIC_VECTOR(8 downto 0);
signal	refit_y							:	STD_LOGIC_VECTOR(7 downto 0);


signal	fit_in_valid					:	STD_LOGIC;
signal	fit_in_which_valid			:	valid3x3_type;
signal	fit_in_z							:	region3x3_type;
signal	fit_in_x							:	STD_LOGIC_VECTOR(8 downto 0);
signal	fit_in_y							:	STD_LOGIC_VECTOR(7 downto 0);

signal 	a									:	STD_LOGIC_VECTOR(21 downto 0);
signal 	b									:	STD_LOGIC_VECTOR(21 downto 0);
signal	ab_x								:	STD_LOGIC_VECTOR(8 downto 0);
signal	ab_y								:	STD_LOGIC_VECTOR(7 downto 0);
signal	ab_valid							:	STD_LOGIC;
	
begin

inst_filtering_RAM : entity work.Filtering_RAM_wrapper
    Port map( 	
			REFRACTORY_PERIOD 	=> REFRACTORY_PERIOD,
			OLD_PIXELS_THRESHOLD => OLD_PIXELS_THRESHOLD,
			
			clk 						=> clk,
			reset 					=> rst,
			
			X_address				=> x_in,
			Y_address				=> y_in,
			input_valid				=> event_valid_in,
			current_time			=> current_time,
			
			--to the plane fit arbiter
			X_out						=> new_x,
			Y_out						=> new_y,
			output_valid			=> new_valid,
			fifo_error				=> open,
			fifo_full				=> open,
			region5x5				=> new_region5x5
);

prepare_data_inst : entity work.prepare_data
    Port map ( 	
			OLD_PIXELS_THRESHOLD => OLD_PIXELS_THRESHOLD,
			
			clk 						=> clk,
			reset 					=> rst,
			
			--input event interface
			input_valid				=> new_valid,
			X_address				=> new_x,
			Y_address				=> new_y,
			region5x5_in			=> new_region5x5,

			--output event interface
			output_valid			=> prepared_output_valid,
			X_out						=> prepared_x,
			Y_out						=> prepared_y,
			region5x5				=> prepared_region5x5,
			valid5x5					=> prepared_valid5x5
);

fit_arbiter_inst : entity work.fit_arbiter 
port map(
	NUM_PIXELS_THRESHOLD 	=> NUM_PIXELS_THRESHOLD,

	rst							=> rst,
	clk							=> clk,

	-- new 5x5 regions being passed in
	new_input_valid			=> prepared_output_valid,
	new_which_valid_in		=> prepared_valid5x5,
	new_z_in						=> prepared_region5x5,
	new_x_in						=> prepared_x,
	new_y_in						=> prepared_y,
	
	-- 3x3 refit regions being passed in
	refit_input_valid			=> refit_valid,
	refit_which_valid_in		=> refit_which_valid,
	refit_z_in					=> refit_z,
	refit_x_in					=> refit_x,
	refit_y_in					=> refit_y,
	
	-- 3x3 regions for fitting being passed out
	which_valid_output		=> fit_in_which_valid,
	z_output						=> fit_in_z,
	x_output						=> fit_in_x,
	y_output						=> fit_in_y,
	output_valid				=> fit_in_valid
);

 
plane_fitting_wrapper_inst : entity work.plane_fitting_wrapper 
port map(
	NUM_PIXELS_THRESHOLD		=> NUM_PIXELS_THRESHOLD,
   FIT_DISTANCE_THRESHOLD	=> FIT_DISTANCE_THRESHOLD,

	-- end user input parameters
	rst							=> rst,
	clk							=> clk,

	--input data for fitting
	fit_in_valid				=> fit_in_valid,
	fit_in_which_valid		=> fit_in_which_valid,
	fit_in_x						=> fit_in_x,
	fit_in_y						=> fit_in_y,
	fit_in_z						=> fit_in_z,

	--send data back to refit module if necessary
	refit_out_valid			=> refit_valid,
	refit_out_which_valid	=> refit_which_valid,
	refit_out_x					=> refit_x,
	refit_out_y					=> refit_y,
	refit_out_z					=> refit_z,
	
	-- this output would go to a formatting module which would extract velocities from a and b
	a								=> a,
	b								=> b,
	x_out							=> ab_x, --same as refit x and refit y
	y_out							=> ab_y,
	ab_valid						=> ab_valid
);

format_output_inst : entity work.format_output 
port map(
	
	rst							=> rst,
	clk							=> clk,

	a								=> a,
	b								=> b,
	x_in							=> ab_x, --same as refit x and refit y
	y_in							=> ab_y,
	ab_valid						=> ab_valid,
	
	vx_out						=> vx_out,
	vy_out						=> vy_out,
	x_out							=> x_out,
	y_out							=> y_out,
	output_valid				=> event_valid_out
	);

end rtl;

