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


entity format_output is
port(
	rst							: in std_logic;
	clk							: in std_logic;

	a								: in std_logic_vector(21 downto 0);
	b								: in std_logic_vector(21 downto 0);
	x_in							: in std_logic_vector(8 downto 0);
	y_in							: in std_logic_vector(7 downto 0);
	ab_valid						: in STD_LOGIC;
	
	vx_out						: out std_logic_vector(15 downto 0) := (others => '0'); --magnitude will never be above 2^24 (i.e. 24 bits, 25 with sign)
	vy_out						: out std_logic_vector(15 downto 0) := (others => '0');
	x_out							: out std_logic_vector(8 downto 0) := (others => '0');
	y_out							: out std_logic_vector(7 downto 0) := (others => '0');
	output_valid				: out STD_LOGIC
	);
end entity ; 
--A shift of 22 bits would allow velocities with a granularity of 2^-22pix/usec ~= 0.25 pix/sec
--A shift of 22 bits with 16 bit signed precision would allow a max velocity of approx 2^15*0.25 pix/sec = 8192 pix/sec
--practically, flow greater than about 3000 pix/sec can be considered an outlier


architecture rtl of format_output is

signal	a_squared,  b_squared						:	STD_LOGIC_VECTOR(31 downto 0)	:= (others => '0');
signal	ab_squared										:	STD_LOGIC_VECTOR(31 downto 0)	:= (others => '0');

signal	div_input_valid 								:	STD_LOGIC	:= '0';
signal 	div_output_valid								:	STD_LOGIC;
signal	inv_ab_squared									:	STD_LOGIC_VECTOR(17 downto 0) := (others => '0');

signal	add_ab											:	STD_LOGIC	:= '0';

signal	a_fifo_out, b_fifo_out, a_fifo_in, b_fifo_in		:	STD_LOGIC_VECTOR(17 downto 0);
signal	x_fifo_in, x_fifo_out									:	STD_LOGIC_VECTOR(8 downto 0);
signal	y_fifo_in, y_fifo_out									:	STD_LOGIC_VECTOR(7 downto 0);

signal	vx_out_internal, vy_out_internal			:	STD_LOGIC_VECTOR(23 downto 0) := (others => '0');

COMPONENT ab_fifo
  PORT (
    clk : IN STD_LOGIC;
    rst : IN STD_LOGIC;
    din : IN STD_LOGIC_VECTOR(52 DOWNTO 0);
    wr_en : IN STD_LOGIC;
    rd_en : IN STD_LOGIC;
    dout : OUT STD_LOGIC_VECTOR(52 DOWNTO 0);
    full : OUT STD_LOGIC;
    empty : OUT STD_LOGIC
  );
END COMPONENT;


COMPONENT output_format_divider
  PORT (
    aclk : IN STD_LOGIC;
    s_axis_divisor_tvalid : IN STD_LOGIC;
    s_axis_divisor_tdata : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    s_axis_dividend_tvalid : IN STD_LOGIC;
    s_axis_dividend_tdata : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    m_axis_dout_tvalid : OUT STD_LOGIC;
    m_axis_dout_tdata : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
  );
END COMPONENT;

signal dummy :	STD_LOGIC_VECTOR(14 downto 0);

begin
vx_out <= vx_out_internal(23 downto 8); 
vy_out <= vy_out_internal(23 downto 8); 
	
output_divider_inst : output_format_divider
  PORT MAP (
    aclk => clk,
    s_axis_divisor_tvalid => div_input_valid,
	 s_axis_divisor_tdata => ab_squared,
    s_axis_dividend_tvalid => div_input_valid,
    s_axis_dividend_tdata(15 downto 14) => "00",
	 s_axis_dividend_tdata(13) => '1',
	 s_axis_dividend_tdata(12 downto 0) => (others => '0'),
    m_axis_dout_tvalid => div_output_valid,
	 m_axis_dout_tdata(31 downto 17) => dummy,
    m_axis_dout_tdata(16 downto 0) => inv_ab_squared(16 downto 0)
  );

	 
ab_fifo_inst : ab_fifo
  PORT MAP (
    clk => clk,
    rst => rst,
    din(52 downto 45) => y_fifo_in,
	 din(44 downto 36) => x_fifo_in,
	 din(35 downto 18) => a_fifo_in,
	 din(17 downto 0)  => b_fifo_in,
    wr_en => add_ab,
    rd_en => div_output_valid,
    dout(52 downto 45) => y_fifo_out,
	 dout(44 downto 36) => x_fifo_out,
	 dout(35 downto 18) => a_fifo_out,
	 dout(17 downto 0)  => b_fifo_out,
    full => open,
    empty => open
  );

mul_add_proc : process(clk)
begin
	if rising_edge(clk) then

		--first step square a and b while checking their range. 
		--Magnitude of vector is 1/sqrt(a^2+b^2)
		--Speeds from 25 pixels/sec to 2000 pixels/sec
		--same as (1e6/25) = 40000  pixels/usec to (1e6/2000) = 500 pixels/usec
		-- 40000^2 > (a^2+b^2) > 500^2
		if ab_valid = '1' then
			a_squared 			<= conv_std_logic_vector(signed(a(17 downto 0)) * signed(a(17 downto 0)), 32);
			b_squared 			<= conv_std_logic_vector(signed(b(17 downto 0)) * signed(b(17 downto 0)), 32);
			a_fifo_in			<= a(17 downto 0);
			b_fifo_in			<= b(17 downto 0);
			x_fifo_in			<= x_in;
			y_fifo_in			<= y_in;
			if ((abs(signed(a)) > 500) or (abs(signed(b)) > 500)) and (abs(signed(a)) < 40000) and (abs(signed(b)) < 40000) then
				add_ab	<= '1';
			else
				add_ab	<= '0';
			end if;
		else
			add_ab	<= '0';
		end if;
		
		--adds the results to get (a^2 + b^2)(2^-4)
		if add_ab = '1' then
			ab_squared 			<=	a_squared + b_squared;
			div_input_valid	<= '1';
		else
			div_input_valid	<= '0';
		end if;


		-- multiplies the result of division:
		if div_output_valid = '1' then
			vx_out_internal <= conv_std_logic_vector(signed(inv_ab_squared)*signed(a_fifo_out), 24); --up to 24 bit signed
			vy_out_internal <= conv_std_logic_vector(signed(inv_ab_squared)*signed(b_fifo_out),	24);
			x_out	 <= x_fifo_out;
			y_out	 <= y_fifo_out;
			output_valid <= '1';
		else
			output_valid <= '0';
		end if;
	
	end if;
end process;
end rtl;


