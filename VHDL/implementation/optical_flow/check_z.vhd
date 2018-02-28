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

-- calculate z estimate, takes 2 clock cycles

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.STD_LOGIC_arith.ALL;
use IEEE.std_logic_misc.all;

library WORK ;
--use work.utils_pack.all;
use work.ATISpackage.all;


entity check_z is
port(
	rst						: in std_logic;
	clk						: in std_logic;
	FIT_DISTANCE_THRESHOLD	: in std_logic_vector(17 downto 0);
	NUM_PIXELS_THRESHOLD		: in std_logic_vector(3 downto 0);

	input_valid				: in std_logic;
	a							: in std_logic_vector(21 downto 0);
	b							: in std_logic_vector(21 downto 0);
	d							: in std_logic_vector(21 downto 0);
	
	x							: in std_logic_vector(8 downto 0);
	y							: in std_logic_vector(7 downto 0);
	z_data					: in region3x3_type;
	which_valid_in			: in valid3x3_type;

	refit						: out std_logic;
	x_out						: out std_logic_vector(8 downto 0);
	y_out						: out std_logic_vector(7 downto 0);
	z_out						: out region3x3_type;
	which_valid_output	: out valid3x3_type;
	
	output_valid			: out std_logic;
	a_out						: out std_logic_vector(21 downto 0);
	b_out						: out std_logic_vector(21 downto 0)

	);
end entity ; 


architecture rtl of check_z is

signal a1, a2, a3, a4, a5, b1, b2, b3, b4, b5	: std_logic_vector(21 downto 0) := (others => '0');

signal process_chain								: std_logic_vector(3 downto 0) := (others => '0');
signal refit_vector								: std_logic_vector(8 downto 0) := (others => '0');
signal refit_chain								: std_logic_vector(1 downto 0) := (others => '0');

signal z_estimate_int, z_estimate_int2		: region3x3_estimate_type := (others => (others => (others => '0')));

signal which_cell_valid_int 					: valid3x3_type := (others => (others => '0'));
signal which_cell_valid2					 	: valid3x3_type := (others => (others => '0'));
signal which_cell_valid3					 	: valid3x3_type := (others => (others => '0'));
signal which_cell_valid4					 	: valid3x3_type := (others => (others => '0'));

signal no_of_valid_pixels						: std_logic_vector(3 downto 0)	:= (others => '0');

signal z_diff										: region3x3_estimate_type		:= (others => (others => (others => '0')));

signal	fifo_read					:	STD_LOGIC	:= '0';
signal	pre_refit					:	STD_LOGIC	:= '0';

begin

region_3x3_fifo_wrapper_inst : entity work.region_3x3_fifo_wrapper
port map (
	rst							=> rst,
	clk							=> clk,

	-- new 3x3 regions being passed in
	new_input_valid			=> input_valid,
	new_which_valid_in		=> which_valid_in, --not used
	new_z_in						=> z_data,
	new_x_in						=> x,
	new_y_in						=> y,
	
	read_en						=> fifo_read,
	
	-- 3x3 regions for fitting being passed out
	which_valid_output		=> open,
	z_output						=> z_out,
	x_output						=> x_out,
	y_output						=> y_out,
	data_valid					=> open
	);
	
	
inst_ones_LUT_1 : entity work.ones_LUT
  PORT MAP (
    a(0) => which_cell_valid3(-1)(-1),
	 a(1) => which_cell_valid3(-1)(0),
	 a(2) => which_cell_valid3(-1)(1),
	 a(3) => which_cell_valid3(0)(-1),
	 a(4) => which_cell_valid3(0)(0),
	 a(5) => which_cell_valid3(0)(1),
	 a(6) => which_cell_valid3(1)(-1),
	 a(7) => which_cell_valid3(1)(0),
	 a(8) => which_cell_valid3(1)(1),
    d => "0000",
    dpra => "000000000",
    clk => clk,
    we => '0',
    qspo_ce => process_chain(2),
    qspo => no_of_valid_pixels,
    qdpo => open
  );
  

check_z_process: process(clk)
begin
	if rising_edge(clk) then



		if input_valid	= '1' then
			--negate a and b (since we kept negative times positive, a and b must also change)
			a1 <= conv_std_logic_vector(-signed(a), 22);
			b1 <= conv_std_logic_vector(-signed(b), 22);
			which_cell_valid_int	<= which_valid_in;
			z_estimate_int(-1)(-1) <= conv_std_logic_vector(-signed(b) - signed(a), 23);
			z_estimate_int(-1)(0)  <= conv_std_logic_vector(-signed(b) 				, 23);
			z_estimate_int(-1)(1)  <= conv_std_logic_vector(-signed(b) + signed(a), 23);
			z_estimate_int(0)(-1) <= conv_std_logic_vector(			  	 - signed(a), 23);
			z_estimate_int(0)(0)  <= conv_std_logic_vector(0				 				, 23);
			z_estimate_int(0)(1)  <= conv_std_logic_vector(	 			   signed(a), 23);
			z_estimate_int(1)(-1) <= conv_std_logic_vector(signed(b)   - signed(a), 23);
			z_estimate_int(1)(0)  <= conv_std_logic_vector(signed(b) 				   , 23);
			z_estimate_int(1)(1)  <= conv_std_logic_vector(signed(b)   + signed(a), 23);
			
			for x in -1 to 1 loop
				for y in -1 to 1 loop
					z_estimate_int2(y)(x)	<= conv_std_logic_vector(signed(d)-signed('0' & z_data(y)(x)), 23); --z data is not signed!!!
				end loop;
			end loop;
			
			process_chain(0)	<= '1';
		else
			process_chain(0)	<= '0';
		end if;
		
		
		
		
		if process_chain(0)	= '1' then
			a2 <= a1;
			b2 <= b1;
			for x in -1 to 1 loop
				for y in -1 to 1 loop
					if which_cell_valid_int(y)(x) = '1' then
						z_diff(y)(x)	<= conv_std_logic_vector(signed(z_estimate_int(y)(x)) + signed(z_estimate_int2(y)(x)), 23);
					else
						z_diff(y)(x)	<= (others => '0');
					end if;
				end loop;
			end loop;
			which_cell_valid2		<= which_cell_valid_int;
			process_chain(1)	<= '1';
		else
			process_chain(1)	<= '0';
		end if;
		
		
		
		
		if process_chain(1)	= '1' then
			a3 <= a2;
			b3 <= b2;
			for x in -1 to 1 loop
				for y in -1 to 1 loop
					if (abs(signed(z_diff(y)(x))) > signed(FIT_DISTANCE_THRESHOLD)) or (which_cell_valid2(y)(x) = '0') then
						if which_cell_valid2(y)(x) = '1' then
							--if the pixel was valid, but now the error is too high (error>fit_distance_threshold)
							refit_vector(x+1+(y+1)*3) <= '1';
						else
							refit_vector(x+1+(y+1)*3) <= '0';
						end if;
						which_cell_valid3(y)(x) <= '0';
					else
						refit_vector(x+1+(y+1)*3) <= '0';
						which_cell_valid3(y)(x) <= '1';
					end if;
				end loop;
			end loop;

			process_chain(2)	<= '1';
		else
			process_chain(2)	<= '0';
		end if;
		



		if process_chain(2)	= '1' then
			a4 <= a3;
			b4 <= b3;
			which_cell_valid4 <= which_cell_valid3;
			if unsigned(refit_vector) >0 then
				pre_refit	<= '1';
			else
				pre_refit <= '0';
			end if;

			process_chain(3) <= '1';
		else
			process_chain(3) <= '0';
		end if;	



		
		if process_chain(3)	= '1' then
			a_out <= a4;
			b_out <= b4;
			which_valid_output <= which_cell_valid4;
			if unsigned(no_of_valid_pixels) >= unsigned(NUM_PIXELS_THRESHOLD) then
				if pre_refit = '1' then
					refit 			<= '1'; 
					output_valid 	<= '0';
				else
					refit 			<= '0'; 
					output_valid 	<= '1';
				end if;
			else
				refit 			<= '0'; 
				output_valid 	<= '0';
			end if;
		--read data to clear the fifo
			fifo_read <= '1';
		else
			which_valid_output <= (others => (others => '0'));
			refit 	 <= '0'; 
			output_valid 	<= '0';
			fifo_read <= '0';
		end if;	


	end if ;
end process;
end rtl;
