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
--Module Description

-- C = (A'*A)^-1 *A'*B

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.STD_LOGIC_arith.ALL;
use IEEE.std_logic_misc.all;


library WORK ;
--use work.utils_pack.all;
use work.ATISpackage.all;


entity a_b_d_result is
port(
   rst                  : in std_logic;
   clk                  : in std_logic;
	
	AtA_inv					: in AtA_inv_type;	-- (A'*A)^-1		
	
	s_valid       			: in std_logic ;
	s1							: in std_logic_vector(time_resolution_bits-1 downto 0);	--\ A'*B
	s2							: in std_logic_vector(time_resolution_bits-1 downto 0);	--|	s1,s2 are 15 bit signed
	s3							: in std_logic_vector(time_resolution_bits-1 downto 0);	--/	
	
	a_b_d_rdy   			: out std_logic ;
	a							: out std_logic_vector(21 downto 0);
	b							: out std_logic_vector(21 downto 0);
	d							: out std_logic_vector(21 downto 0)
	);
	
	
end entity ;



architecture rtl of a_b_d_result is

--type coefficient_int is array (0 to 5) of std_logic_vector(time_resolution_bits + AtA_scale -1 downto 0);
--suspect overflow here
type coefficient_int is array (0 to 5) of std_logic_vector(time_resolution_bits + AtA_bits-2 downto 0);

signal AtA_inv_internal 		:	AtA_inv_type;

signal a_int		: coefficient_int;
signal b_int		: coefficient_int;
signal d_int		: coefficient_int;

signal s_valid_sr : std_logic_vector(1 downto 0);

begin

AtA_inv_internal <= AtA_inv;

mul_add_proc : process(clk)
begin
	if rising_edge(clk) then
		if rst = '1' then
			a_int 	<= (others=>(others=>'0'));
			b_int 	<= (others=>(others=>'0'));
			d_int		<= (others=>(others=>'0'));
			--AtA_inv_internal 	<= (others=> (others=> (others=> '0')));
			s_valid_sr <= (others=>'0');
		else
			s_valid_sr(1) <= s_valid_sr(0);
			s_valid_sr(0) <= s_valid;
			
			--timing?
			--
			
			if s_valid = '1' then	
				a_int(0)	<= conv_std_logic_vector(signed(AtA_inv_internal(-1)(-1))* signed(s1), time_resolution_bits + AtA_bits-1);
				a_int(1)	<= conv_std_logic_vector(signed(AtA_inv_internal(-1)(0)) * signed(s2), time_resolution_bits + AtA_bits-1);
				a_int(2)	<= conv_std_logic_vector(signed(AtA_inv_internal(-1)(1)) * signed('0' & s3(17 downto 0)), time_resolution_bits + AtA_bits-1);
			
				b_int(0)	<= conv_std_logic_vector(signed(AtA_inv_internal( 0)(-1))* signed(s1), time_resolution_bits + AtA_bits-1);
				b_int(1)	<= conv_std_logic_vector(signed(AtA_inv_internal( 0)(0)) * signed(s2), time_resolution_bits + AtA_bits-1);
				b_int(2)	<= conv_std_logic_vector(signed(AtA_inv_internal( 0)(1)) * signed('0' & s3(17 downto 0)), time_resolution_bits + AtA_bits-1);

				d_int(0)	<= conv_std_logic_vector(signed(AtA_inv_internal( 1)(-1))* signed(s1), time_resolution_bits + AtA_bits-1);
				d_int(1)	<= conv_std_logic_vector(signed(AtA_inv_internal( 1)(0)) * signed(s2), time_resolution_bits + AtA_bits-1);
				d_int(2)	<= conv_std_logic_vector(signed(AtA_inv_internal( 1)(1)) * signed('0' & s3(17 downto 0)), time_resolution_bits + AtA_bits-1);
			end if;
      
      	if s_valid_sr(0) = '1' then
				a_int(3)	<= a_int(0) + a_int(1);
				a_int(4) <= a_int(2);
				--a_int(4) <= a_int(2)(time_resolution_bits + AtA_bits-3 downto 0) & '0';
			
				b_int(3)	<= b_int(0) + b_int(1);
				b_int(4) <= b_int(2);
				--b_int(4) <= b_int(2)(time_resolution_bits + AtA_bits-3 downto 0) & '0';
			
				d_int(3)	<= d_int(0) + d_int(1);
				d_int(4) <= d_int(2);
				--d_int(4) <= d_int(2)(time_resolution_bits + AtA_bits-3 downto 0) & '0';
			end if ;
			
			if s_valid_sr(1) = '1' then
				a_b_d_rdy <= '1';
				a_int(5) <= a_int(3) + a_int(4) ;
				b_int(5) <= b_int(3) + b_int(4) ; 
				d_int(5) <= d_int(3) + d_int(4) ;
			else
				a_b_d_rdy <= '0';
			end if;				
		end if ;
	end if ;
end process;


----a <= SHIFT_RIGHT(a_int(5),11)(9 downto 0);	--\ rescale by 2048
----b <= SHIFT_RIGHT(b_int(5),11)(9 downto 0);	--|
----d <= SHIFT_RIGHT(d_int(5),11)(9 downto 0);	--/
--a <= a_int(5)(20 downto 11);	--\ rescale by 2048
--b <= b_int(5)(20 downto 11);	--|
--d <= d_int(5)(20 downto 11);

a <= a_int(5)(time_resolution_bits + AtA_bits - 2 downto time_resolution_bits  + AtA_bits -2  -17 - 4);	--\ rescale by 2048
b <= b_int(5)(time_resolution_bits + AtA_bits - 2 downto time_resolution_bits  + AtA_bits -2  -17 - 4);	--|29 bits signed would be enough for a, b
d <= d_int(5)(time_resolution_bits + AtA_bits - 2 downto time_resolution_bits  + AtA_bits -2  -17 - 4); -- d requires 29 bits
	
end rtl;
