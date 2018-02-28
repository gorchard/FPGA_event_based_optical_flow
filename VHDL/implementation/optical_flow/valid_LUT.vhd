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

-- moduel to generate address of look up table for inverse(A.A')
-- input signal is which cells are vailid within 3x3 region 
-- minimum number of valid cells is 6

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

library WORK ;
--use work.utils_pack.all;
use work.ATISpackage.all;


entity valid_LUT is
port(
	rst						: in std_logic;
	clk						: in std_logic;
	
	region_valid			: in std_logic ;
	which_cell_valid		: in valid3x3_type;
	
	LUT_addr_valid			: out std_logic ;
	LUT_addr					: out std_logic_vector(7 downto 0)
);
end entity ; 


architecture rtl of valid_LUT is

signal region_valid_int			: std_logic ;	
signal which_cell_valid_linear	: std_logic_vector(8 downto 0);
signal LUT_addr_rdy_int, LUT_addr_valid_delay			: std_logic ;
signal LUT_addr_int				: std_logic_vector(7 downto 0);



		
begin

-- register in/out signals
register_in_out: process(clk)
begin
   if rising_edge(clk) then
      if rst = '1' then
			region_valid_int 		<= '0';	
			LUT_addr_valid			<= '0';
         which_cell_valid_linear	<= (others=> '0');
		else
			region_valid_int		<= region_valid;
			LUT_addr_valid_delay	<= LUT_addr_rdy_int;
         LUT_addr_valid			<= LUT_addr_valid_delay;
			
			which_cell_valid_linear(0)	<= which_cell_valid(-1)(-1);
			which_cell_valid_linear(1)	<= which_cell_valid(0)(-1);
			which_cell_valid_linear(2)	<= which_cell_valid(1)(-1);
			which_cell_valid_linear(3)	<= which_cell_valid(-1)(0);
			which_cell_valid_linear(4)	<= which_cell_valid(0)(0);
			which_cell_valid_linear(5)	<= which_cell_valid(1)(0);
			which_cell_valid_linear(6)	<= which_cell_valid(-1)(1);
			which_cell_valid_linear(7)	<= which_cell_valid(0)(1);
			which_cell_valid_linear(8)	<= which_cell_valid(1)(1);
		end if;
	end if ;
end process ;



-- LUT, input is valid vector, output is address for a_inverse LUT
look_up_address: process(clk)
begin
   if rising_edge(clk) then
		
		LUT_addr	<= LUT_addr_int;
		
      if rst = '1' then
			LUT_addr_rdy_int 	<= '0' ;	
		   LUT_addr_int		<= (others =>'0') ;	
		else		
		  LUT_addr_rdy_int <= region_valid ;
		  if region_valid_int = '1' then
			case which_cell_valid_linear is
				when "111111111"	=> LUT_addr_int <= "00000000";
				when "111111110"	=> LUT_addr_int <= "00000001";
				when "111111101"	=> LUT_addr_int <= "00000010";
				when "111111011"	=> LUT_addr_int <= "00000011";
				when "111110111"	=> LUT_addr_int <= "00000100";
				when "111101111"	=> LUT_addr_int <= "00000101";
				when "111011111"	=> LUT_addr_int <= "00000110";
				when "110111111"	=> LUT_addr_int <= "00000111";
				when "101111111"	=> LUT_addr_int <= "00001000";	
				when "011111111"	=> LUT_addr_int <= "00001001";	
				when "111111100"	=> LUT_addr_int <= "00001010";	
				when "111111010"	=> LUT_addr_int <= "00001011";	
				when "111110110"	=> LUT_addr_int <= "00001100";	
				when "111101110"	=> LUT_addr_int <= "00001101";	
				when "111011110"	=> LUT_addr_int <= "00001110";	
				when "110111110"	=> LUT_addr_int <= "00001111";	
				when "101111110"	=> LUT_addr_int <= "00010000";	
				when "011111110"	=> LUT_addr_int <= "00010001";	
				when "111111001"	=> LUT_addr_int <= "00010010";	
				when "111110101"	=> LUT_addr_int <= "00010011";	
				when "111101101"	=> LUT_addr_int <= "00010100";	
				when "111011101"	=> LUT_addr_int <= "00010101";	
				when "110111101"	=> LUT_addr_int <= "00010110";	
				when "101111101"	=> LUT_addr_int <= "00010111";	
				when "011111101"	=> LUT_addr_int <= "00011000";	
				when "111110011"	=> LUT_addr_int <= "00011001";	
				when "111101011"	=> LUT_addr_int <= "00011010";	
				when "111011011"	=> LUT_addr_int <= "00011011";	
				when "110111011"	=> LUT_addr_int <= "00011100";	
				when "101111011"	=> LUT_addr_int <= "00011101";	
				when "011111011"	=> LUT_addr_int <= "00011110";	
				when "111100111"	=> LUT_addr_int <= "00011111";	
				when "111010111"	=> LUT_addr_int <= "00100000";	
				when "110110111"	=> LUT_addr_int <= "00100001";	
				when "101110111"	=> LUT_addr_int <= "00100010";	
				when "011110111"	=> LUT_addr_int <= "00100011";	
				when "111001111"	=> LUT_addr_int <= "00100100";	
				when "110101111"	=> LUT_addr_int <= "00100101";	
				when "101101111"	=> LUT_addr_int <= "00100110";	
				when "011101111"	=> LUT_addr_int <= "00100111";	
				when "110011111"	=> LUT_addr_int <= "00101000";	
				when "101011111"	=> LUT_addr_int <= "00101001";	
				when "011011111"	=> LUT_addr_int <= "00101010";	
				when "100111111"	=> LUT_addr_int <= "00101011";	
				when "010111111"	=> LUT_addr_int <= "00101100";	
				when "001111111"	=> LUT_addr_int <= "00101101";	
				when "111111000"	=> LUT_addr_int <= "00101110";	
				when "111110100"	=> LUT_addr_int <= "00101111";	
				when "111101100"	=> LUT_addr_int <= "00110000";	
				when "111011100"	=> LUT_addr_int <= "00110001";	
				when "110111100"	=> LUT_addr_int <= "00110010";	
				when "101111100"	=> LUT_addr_int <= "00110011";	
				when "011111100"	=> LUT_addr_int <= "00110100";	
				when "111110010"	=> LUT_addr_int <= "00110101";	
				when "111101010"	=> LUT_addr_int <= "00110110";	
				when "111011010"	=> LUT_addr_int <= "00110111";	
				when "110111010"	=> LUT_addr_int <= "00111000";	
				when "101111010"	=> LUT_addr_int <= "00111001";	
				when "011111010"	=> LUT_addr_int <= "00111010";	
				when "111100110"	=> LUT_addr_int <= "00111011";	
				when "111010110"	=> LUT_addr_int <= "00111100";	
				when "110110110"	=> LUT_addr_int <= "00111101";	
				when "101110110"	=> LUT_addr_int <= "00111110";	
				when "011110110"	=> LUT_addr_int <= "00111111";	
				when "111001110"	=> LUT_addr_int <= "01000000";	
				when "110101110"	=> LUT_addr_int <= "01000001";	
				when "101101110"	=> LUT_addr_int <= "01000010";	
				when "011101110"	=> LUT_addr_int <= "01000011";	
				when "110011110"	=> LUT_addr_int <= "01000100";	
				when "101011110"	=> LUT_addr_int <= "01000101";	
				when "011011110"	=> LUT_addr_int <= "01000110";	
				when "100111110"	=> LUT_addr_int <= "01000111";	
				when "010111110"	=> LUT_addr_int <= "01001000";	
				when "001111110"	=> LUT_addr_int <= "01001001";	
				when "111110001"	=> LUT_addr_int <= "01001010";	
				when "111101001"	=> LUT_addr_int <= "01001011";	
				when "111011001"	=> LUT_addr_int <= "01001100";	
				when "110111001"	=> LUT_addr_int <= "01001101";	
				when "101111001"	=> LUT_addr_int <= "01001110";	
				when "011111001"	=> LUT_addr_int <= "01001111";	
				when "111100101"	=> LUT_addr_int <= "01010000";	
				when "111010101"	=> LUT_addr_int <= "01010001";	
				when "110110101"	=> LUT_addr_int <= "01010010";	
				when "101110101"	=> LUT_addr_int <= "01010011";	
				when "011110101"	=> LUT_addr_int <= "01010100";	
				when "111001101"	=> LUT_addr_int <= "01010101";	
				when "110101101"	=> LUT_addr_int <= "01010110";	
				when "101101101"	=> LUT_addr_int <= "01010111";	
				when "011101101"	=> LUT_addr_int <= "01011000";	
				when "110011101"	=> LUT_addr_int <= "01011001";	
				when "101011101"	=> LUT_addr_int <= "01011010";	
				when "011011101"	=> LUT_addr_int <= "01011011";	
				when "100111101"	=> LUT_addr_int <= "01011100";	
				when "010111101"	=> LUT_addr_int <= "01011101";
				when "001111101"	=> LUT_addr_int <= "01011110";
				when "111100011"	=> LUT_addr_int <= "01011111";
				when "111010011"	=> LUT_addr_int <= "01100000";
				when "110110011"	=> LUT_addr_int <= "01100001";
				when "101110011"	=> LUT_addr_int <= "01100010";
				when "011110011"	=> LUT_addr_int <= "01100011";
				when "111001011"	=> LUT_addr_int <= "01100100";
				when "110101011"	=> LUT_addr_int <= "01100101";
				when "101101011"	=> LUT_addr_int <= "01100110";
				when "011101011"	=> LUT_addr_int <= "01100111";
				when "110011011"	=> LUT_addr_int <= "01101000";
				when "101011011"	=> LUT_addr_int <= "01101001";
				when "011011011"	=> LUT_addr_int <= "01101010";
				when "100111011"	=> LUT_addr_int <= "01101011";
				when "010111011"	=> LUT_addr_int <= "01101100";
				when "001111011"	=> LUT_addr_int <= "01101101";
				when "111000111"	=> LUT_addr_int <= "01101110";
				when "110100111"	=> LUT_addr_int <= "01101111";
				when "101100111"	=> LUT_addr_int <= "01110000";
				when "011100111"	=> LUT_addr_int <= "01110001";
				when "110010111"	=> LUT_addr_int <= "01110010";
				when "101010111"	=> LUT_addr_int <= "01110011";
				when "011010111"	=> LUT_addr_int <= "01110100";
				when "100110111"	=> LUT_addr_int <= "01110101";
				when "010110111"	=> LUT_addr_int <= "01110110";
				when "001110111"	=> LUT_addr_int <= "01110111";
				when "110001111"	=> LUT_addr_int <= "01111000";
				when "101001111"	=> LUT_addr_int <= "01111001";
				when "011001111"	=> LUT_addr_int <= "01111010";
				when "100101111"	=> LUT_addr_int <= "01111011";
				when "010101111"	=> LUT_addr_int <= "01111100";
				when "001101111"	=> LUT_addr_int <= "01111101";
				when "100011111"	=> LUT_addr_int <= "01111110";
				when "010011111"	=> LUT_addr_int <= "01111111";
				when "001011111"	=> LUT_addr_int <= "10000000";
				when "000111111"	=> LUT_addr_int <= "10000001";
				when others      => LUT_addr_int  <= "00000000";
 			end case;  
 			end if;                              
		end if ;                                    
	end if ;
end process ;



end rtl;
