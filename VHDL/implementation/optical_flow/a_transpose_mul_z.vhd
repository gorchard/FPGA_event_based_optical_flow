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
-- A'.B operation 

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_misc.all;
use IEEE.std_logic_unsigned.all;

library WORK ;
--use work.utils_pack.all;
use work.ATISpackage.all;


entity a_transpose_mul_z is
port(
   rst                              : in std_logic;
   clk                              : in std_logic;
	
	region_valid							: in std_logic;
	which_cell_valid						: in valid3x3_type;
	z_data									: in region3x3_type;

	s_valid               				: out std_logic;
	s1											: out std_logic_vector(time_resolution_bits-1 downto 0);
	s2											: out std_logic_vector(time_resolution_bits-1 downto 0);
	s3											: out std_logic_vector(time_resolution_bits-1 downto 0)
	);	
end entity ;

architecture rtl of a_transpose_mul_z is

signal	z_data_internal 	: region3x3_type;

signal	s1_internal, s2_internal, s3_internal : 	std_logic_vector(time_resolution_bits+3 downto 0);


type stage_xy1_type is array (-1 to 1) of std_logic_vector(time_resolution_bits downto 0);
signal	x_stage1, y_stage1				:	stage_xy1_type;

constant stage_xy2_bits : integer := time_resolution_bits+2;
type stage_xy2_type is array (1 downto 0) of std_logic_vector(stage_xy2_bits-1 downto 0);
signal	x_stage2, y_stage2				:	stage_xy2_type;

signal	x_stage3, y_stage3				:	std_logic_vector(time_resolution_bits+2 downto 0);



type stage_z1_type is array (4 downto 0) of std_logic_vector(time_resolution_bits downto 0);
signal	z_stage1								:	stage_z1_type;

type stage_z2_type is array (2 downto 0) of std_logic_vector(time_resolution_bits+1 downto 0);
signal	z_stage2								:	stage_z2_type;

type stage_z3_type is array (1 downto 0) of std_logic_vector(time_resolution_bits+2 downto 0);
signal	z_stage3								:	stage_z3_type;


--signal s1_int						: sum_mul_result 	:= (others => (others => '0'));
--signal s2_int						: sum_mul_result 	:= (others => (others => '0'));
--signal s3_int						: sum_mul_result 	:= (others => (others => '0'));

signal	process_chain			:	STD_LOGIC_VECTOR(3 downto 0) := (others => '0');

begin

--here 4 bits are removed from the output
s1	<=  	s1_internal(time_resolution_bits+3 downto 4);
s2	<= 	s2_internal(time_resolution_bits+3 downto 4);
s3	<= 	s3_internal(time_resolution_bits+3 downto 4);

-- mask the invalid cells
mult_proc : process(clk)
begin
	if rising_edge(clk) then
		if rst = '1' then
			z_data_internal 			<= (others=>(others=>(others=>'0')));
		else
			
			--first step, internalize the data removing any invalid data
			if region_valid = '1' then
				for x in -1 to 1 loop
					for y in -1 to 1 loop
						if (which_cell_valid(y)(x) = '1') then
							z_data_internal(y)(x)	<=	z_data(y)(x);
						else
							z_data_internal(y)(x)	<=	(others => '0');
						end if;						
					end loop;
				end loop;
				process_chain(0)	<= '1';
			else
				process_chain(0)	<= '0';
			end if;	
			
			--first stage of adder chain
			if process_chain(0) = '1' then
				for index in -1 to 1 loop
					-- these are now signed
					x_stage1(index) 	<= conv_std_logic_vector(signed('0' & z_data_internal(index)(1)) - signed('0' & z_data_internal(index)(-1)), time_resolution_bits+1);
					y_stage1(index) 	<= conv_std_logic_vector(signed('0' & z_data_internal(1)(index)) - signed('0' & z_data_internal(-1)(index)), time_resolution_bits+1);
				end loop;	
				
				-- these are now unsigned
				z_stage1(0) 	<= conv_std_logic_vector(signed('0' & z_data_internal(-1)(-1)) + signed('0' & z_data_internal(-1)(0)), time_resolution_bits+1);
				z_stage1(1) 	<= conv_std_logic_vector(signed('0' & z_data_internal(-1)(1)) + signed('0' & z_data_internal(0)(-1)), time_resolution_bits+1);
				z_stage1(2) 	<= conv_std_logic_vector(signed('0' & z_data_internal(0)(0)) + signed('0' & z_data_internal(0)(1)), time_resolution_bits+1);
				z_stage1(3) 	<= conv_std_logic_vector(signed('0' & z_data_internal(1)(-1)) + signed('0' & z_data_internal(1)(0)), time_resolution_bits+1);
				z_stage1(4) 	<= conv_std_logic_vector(signed('0' & z_data_internal(1)(1)), time_resolution_bits+1);
				
				process_chain(1) <= '1';
			else
				process_chain(1) <= '0';
			end if;
			
			--second stage of adder chain
			if process_chain(1) = '1' then
				--signed, need one more bit when adding two together
				x_stage2(0) 	<= conv_std_logic_vector(signed(x_stage1(0)), time_resolution_bits+2);
				y_stage2(0) 	<= conv_std_logic_vector(signed(y_stage1(0)), time_resolution_bits+2);
				
				--buffer this stage with an extra bit before addition
--				--x_stage2(1) 	<= conv_std_logic_vector(signed(x_stage1(1)) + signed(x_stage1(-1)), time_resolution_bits+2); --an overflow is happening here, but why?
--				x_stage2(1) 	<= conv_std_logic_vector(signed(x_stage1(1)(time_resolution_bits) & x_stage1(1)) + signed(x_stage1(-1)(time_resolution_bits) & x_stage1(-1)), time_resolution_bits+2); --an overflow is happening here, but why?
--				y_stage2(1) 	<= conv_std_logic_vector(signed(y_stage1(1)(time_resolution_bits) & y_stage1(1)) + signed(y_stage1(-1)(time_resolution_bits) & y_stage1(-1)), time_resolution_bits+2);
				x_stage2(1) 	<= conv_std_logic_vector(signed(x_stage1(1)(time_resolution_bits) & x_stage1(1)) + signed(x_stage1(-1)), stage_xy2_bits); --an overflow is happening here, but why?
				y_stage2(1) 	<= conv_std_logic_vector(signed(y_stage1(1)(time_resolution_bits) & y_stage1(1)) + signed(y_stage1(-1)), stage_xy2_bits);

				--still unsigned, one more bit added to allow extra range
				z_stage2(0) 	<= conv_std_logic_vector(signed('0' & z_stage1(0)) + signed('0' & z_stage1(1)), time_resolution_bits+2);
				z_stage2(1) 	<= conv_std_logic_vector(signed('0' & z_stage1(2)) + signed('0' & z_stage1(3)), time_resolution_bits+2);
				z_stage2(2) 	<= conv_std_logic_vector(signed('0' & z_stage1(4)), time_resolution_bits+2);
				
				process_chain(2) <= '1';
			else
				process_chain(2) <= '0';
			end if;
			
			--third stage of adder chain
			if process_chain(2) = '1' then
				--signed
				x_stage3		<= conv_std_logic_vector(signed(x_stage2(0)(time_resolution_bits+1) & x_stage2(0)) + signed(x_stage2(1)), time_resolution_bits+3);
				y_stage3		<= conv_std_logic_vector(signed(y_stage2(0)(time_resolution_bits+1) & y_stage2(0)) + signed(y_stage2(1)), time_resolution_bits+3);
				
				--unsigned
				z_stage3(0) 	<= conv_std_logic_vector(signed('0' & z_stage2(0)) + signed('0' & z_stage2(1)), time_resolution_bits+3);
				z_stage3(1) 	<= conv_std_logic_vector(signed('0' & z_stage2(2)), time_resolution_bits+3);
				process_chain(3) <= '1';
			else
				process_chain(3) <= '0';
			end if;

			if process_chain(3) = '1' then
				--signed
				s1_internal 	<= conv_std_logic_vector(signed(x_stage3), time_resolution_bits + 4);
				s2_internal		<= conv_std_logic_vector(signed(y_stage3), time_resolution_bits + 4);
				--unsigned
				s3_internal		<= conv_std_logic_vector(signed('0' & z_stage3(0)) + signed('0' & z_stage3(1)), time_resolution_bits+4);
				s_valid	<= '1';
			else
				s_valid	<= '0';
			end if;

		end if;
	end if;
end process ;

end rtl;
	




