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


entity serialize_fifo_wrapper is
port(
	rst							: in std_logic;
	clk							: in std_logic;
	
	NUM_PIXELS_THRESHOLD		: in std_logic_vector(3 downto 0);
	
	-- new 5x5 regions being passed in
	new_input_valid			: in std_logic;
	new_which_valid_in		: in valid5x5_type;
	new_z_in						: in region5x5_type;
	new_x_in						: in std_logic_vector(8 downto 0);
	new_y_in						: in std_logic_vector(7 downto 0);
	
	-- 3x3 regions for fitting being passed out
	which_valid_output		: out valid3x3_type	:= (others => (others => '0'));
	z_output						: out region3x3_type	:= (others => (others => (others => '0')));
	x_output						: out std_logic_vector(8 downto 0) := (others => '0');
	y_output						: out std_logic_vector(7 downto 0) := (others => '0');
	output_valid				: out std_logic := '0'
	
	);
end entity ; 



architecture rtl of serialize_fifo_wrapper is

--fifo vectors
signal	fifo_din_vector, fifo_dout_vector	: STD_LOGIC_VECTOR(9+8+5*5*(time_resolution_bits+1)-1  downto 0);

--output of fifo
signal 	which_valid_internal						: valid3x3_vector_type;
signal 	z_internal									: region3x3_vector_type;
signal 	x_internal									: std_logic_vector(8 downto 0);
signal 	y_internal									: std_logic_vector(7 downto 0);

--fifo control
signal	fifo_valid, fifo_read					: STD_LOGIC	:=	'0';

--serialization control
signal	count_status								: std_logic_vector(3 downto 0)	:= (others => '0'); --keep track of where in the serialization we are

--buffer before output
signal	which_valid_buffer						: valid3x3_type	:= (others => (others => '0'));
signal	z_buffer										: region3x3_type	:= (others => (others => (others => '0')));
signal	x_buffer										: std_logic_vector(8 downto 0) := (others => '0');
signal	y_buffer										: std_logic_vector(7 downto 0) := (others => '0');
signal	buffer_valid								: std_logic	:= '0';

signal	num_pixels									: std_logic_vector(3 downto 0); --how many pixels are valid

signal	num_pixels_address						: valid3x3_type;

begin

-- hides away the mapping from array to a std_logic_vector for the fifo
map_5x5_input_to_vec_inst : entity work.map_5x5_input_to_vec
port map(
	-- new 5x5 regions being passed in
	din_z 				=> new_z_in,
	din_x 				=> new_x_in,
	din_y 				=> new_y_in,
	din_which_valid 	=> new_which_valid_in,
	dout_std_logic		=> fifo_din_vector,
	
	din_std_logic		=> fifo_dout_vector,
	dout_which_valid	=>	which_valid_internal,
	dout_z				=>	z_internal,
	dout_x				=> x_internal,
	dout_y				=> y_internal
	);


serialize_fits_fifo_inst : entity work.serialize_fits
  PORT MAP (
    clk 		=> clk,
    rst 		=> rst,
    din 		=> fifo_din_vector,
    wr_en 	=> new_input_valid,
    rd_en 	=> fifo_read,
    dout 	=> fifo_dout_vector,
    full 	=> open,
    empty 	=> open,
    valid 	=> fifo_valid
  );

ones_LUT_inst : entity work.ones_LUT
  PORT MAP (
    a(0) 	=> num_pixels_address(-1)(-1),
	 a(1) 	=> num_pixels_address(-1)(0),
	 a(2) 	=> num_pixels_address(-1)(1),
	 a(3) 	=> num_pixels_address(0)(-1),
	 a(4) 	=> num_pixels_address(0)(0),
	 a(5) 	=> num_pixels_address(0)(1),
	 a(6) 	=> num_pixels_address(1)(-1),
	 a(7) 	=> num_pixels_address(1)(0),
	 a(8) 	=> num_pixels_address(1)(1),
    d 		=> "0000",
    dpra 	=> "000000000",
    clk 		=> clk,
    we 		=> '0',
    qspo_ce => '1',
    qspo 	=> num_pixels,
    qdpo 	=> open
  );
  
refit_or_output_prc : process(clk)
begin
	if rising_edge(clk) then
		if fifo_valid = '1' then
			case conv_integer(unsigned(count_status)) is
				when 0 =>				
					buffer_valid			<= '0';
					num_pixels_address	<= which_valid_internal(0);
					count_status			<= count_status + "01";
				when 1 =>
					x_buffer					<= conv_std_logic_vector(unsigned(x_internal) - 1, 9);
					y_buffer					<= conv_std_logic_vector(unsigned(y_internal) - 1, 8);
					which_valid_buffer	<=	which_valid_internal(0);
					z_buffer					<= z_internal(0);
					count_status			<= count_status + "01";
					buffer_valid			<= '1';
					num_pixels_address	<= which_valid_internal(1);
				when 2 =>
					x_buffer					<= conv_std_logic_vector(unsigned(x_internal), 9);
					y_buffer					<= conv_std_logic_vector(unsigned(y_internal) - 1, 8);
					which_valid_buffer	<=	which_valid_internal(1);
					z_buffer					<= z_internal(1);
					count_status			<= count_status + "01";
					buffer_valid			<= '1';
					num_pixels_address	<= which_valid_internal(2);
				when 3 =>
					x_buffer					<= conv_std_logic_vector(unsigned(x_internal) + 1, 9);
					y_buffer					<= conv_std_logic_vector(unsigned(y_internal) - 1, 8);
					which_valid_buffer	<=	which_valid_internal(2);
					z_buffer					<= z_internal(2);
					count_status			<= count_status + "01";
					buffer_valid			<= '1';
					num_pixels_address	<= which_valid_internal(3);
				when 4 =>
					x_buffer					<= conv_std_logic_vector(unsigned(x_internal) - 1, 9);
					y_buffer					<= conv_std_logic_vector(unsigned(y_internal), 8);
					which_valid_buffer	<=	which_valid_internal(3);
					z_buffer					<= z_internal(3);
					count_status			<= count_status + "01";
					buffer_valid			<= '1';
					num_pixels_address	<= which_valid_internal(4);
				when 5 =>
					x_buffer					<= conv_std_logic_vector(unsigned(x_internal), 9);
					y_buffer					<= conv_std_logic_vector(unsigned(y_internal), 8);
					which_valid_buffer	<=	which_valid_internal(4);
					z_buffer					<= z_internal(4);
					count_status			<= count_status + "01";
					buffer_valid			<= '1';
					num_pixels_address	<= which_valid_internal(5);
				when 6 =>
					x_buffer					<= conv_std_logic_vector(unsigned(x_internal) + 1, 9);
					y_buffer					<= conv_std_logic_vector(unsigned(y_internal), 8);
					which_valid_buffer	<=	which_valid_internal(5);
					z_buffer					<= z_internal(5);
					count_status			<= count_status + "01";
					buffer_valid			<= '1';
					num_pixels_address	<= which_valid_internal(6);
				when 7 =>
					x_buffer					<= conv_std_logic_vector(unsigned(x_internal) - 1, 9);
					y_buffer					<= conv_std_logic_vector(unsigned(y_internal) + 1, 8);
					which_valid_buffer	<=	which_valid_internal(6);
					z_buffer					<= z_internal(6);
					count_status			<= count_status + "01";
					buffer_valid			<= '1';
					num_pixels_address	<= which_valid_internal(7);
				when 8 =>
					x_buffer					<= conv_std_logic_vector(unsigned(x_internal), 9);
					y_buffer					<= conv_std_logic_vector(unsigned(y_internal) + 1, 8);
					which_valid_buffer	<=	which_valid_internal(7);
					z_buffer					<= z_internal(7);
					fifo_read				<= '1';
					count_status			<= count_status + "01";
					buffer_valid			<= '1';
					num_pixels_address	<= which_valid_internal(8);
				when 9 =>
					x_buffer					<= conv_std_logic_vector(unsigned(x_internal) + 1, 9);
					y_buffer					<= conv_std_logic_vector(unsigned(y_internal) + 1, 8);
					which_valid_buffer	<=	which_valid_internal(8);
					z_buffer					<= z_internal(8);
					fifo_read				<= '0';
					count_status			<= (others => '0');
					buffer_valid			<= '1';
				when others => 
					count_status			<= (others => '0');
					fifo_read				<= '0';
					buffer_valid			<= '0';
			end case;
		else
			buffer_valid			<= '0';
		end if;
			
			
		if buffer_valid = '1' and unsigned(num_pixels) >= unsigned(NUM_PIXELS_THRESHOLD) then
			which_valid_output		<= which_valid_buffer;
			z_output						<= z_buffer;
			x_output						<= x_buffer;
			y_output						<= y_buffer;
			output_valid				<= '1';
		else 
			output_valid				<= '0';
		end if;
		
	end if;
end process;
end rtl;

