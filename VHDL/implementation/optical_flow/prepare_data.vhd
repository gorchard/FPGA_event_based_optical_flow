----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    12:51:35 02/06/2014 
-- Design Name: 
-- Module Name:    IBGhandler - Behavioral 
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
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_misc.all;
use IEEE.std_logic_unsigned.all;
use work.ATISpackage.all;
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity prepare_data is
    Port ( 	
			OLD_PIXELS_THRESHOLD	: in std_logic_vector(17 downto 0);
			
			clk 				: in  STD_LOGIC;
			reset 			: in  STD_LOGIC;
			
			--input event interface
			input_valid		: in  STD_LOGIC;
			X_address		: in 	STD_LOGIC_VECTOR(8 downto 0);
			Y_address		: in 	STD_LOGIC_VECTOR(7 downto 0);
			region5x5_in	: in region5x5signed_type;

			--output event interface
			output_valid	: out STD_LOGIC;
			X_out				: out	STD_LOGIC_VECTOR(8 downto 0);
			Y_out				: out	STD_LOGIC_VECTOR(7 downto 0);
			region5x5		: out region5x5_type;
			valid5x5			: out valid5x5_type
			
);
end prepare_data;


architecture Behavioral of prepare_data is

signal 	X_address_internal		: STD_LOGIC_VECTOR(8 downto 0)   := (others => '0');
signal	Y_address_internal		: STD_LOGIC_VECTOR(7 downto 0)	:= (others => '0');
signal	region5x5_internal		: region5x5_type := (others => (others => (others => '0')));

signal 	pre_valid					: valid5x5_type	:= (others => (others => '0'));

signal	check_valid					:	STD_LOGIC	:= '0';

begin


process (clk) begin
	if rising_edge(clk) then
		if input_valid = '1' then
			X_address_internal <= X_address;
			Y_address_internal <= Y_address;
			for x in -2 to 2 loop
				for y in -2 to 2 loop
					region5x5_internal(y)(x)	<= conv_std_logic_vector(signed(region5x5_in(0)(0)) - signed(region5x5_in(y)(x)), time_resolution_bits);
					
					if x = 0 and y =0 then --a value of 0 is reserved to mean expired data
						pre_valid(y)(x)	<= '1';
					elsif signed(region5x5_in(y)(x)) = 0 then
						pre_valid(y)(x)	<= '0';
					else
						pre_valid(y)(x)	<= '1';
					end if;
				end loop;
			end loop;
			check_valid	<= '1';
		else
			region5x5_internal	<= (others => (others => (others => '0')));
			check_valid	<= '0';
		end if;
		
		if check_valid = '1' then
			X_out  			<= X_address_internal;
			Y_out  			<= Y_address_internal;
			region5x5 		<= region5x5_internal;
			
			for x in -2 to 2 loop
				for y in -2 to 2 loop
					if unsigned(region5x5_internal(y)(x)) >= unsigned(OLD_PIXELS_THRESHOLD) or pre_valid(y)(x) = '0' then
						valid5x5(y)(x)	<= '0';
					else
						valid5x5(y)(x)	<= '1';
					end if;
				end loop;
			end loop;
			
			output_valid	<= '1';
		else
			valid5x5			<= (others => (others => '0'));
			output_valid	<= '0';
		end if;
		
	end if;
end process;

end Behavioral;