--	Package File Template
--
--	Purpose: This package defines supplemental types, subtypes, 
--		 constants, and functions 


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_misc.all;
use IEEE.std_logic_unsigned.all;

package ATISpackage is
constant time_resolution_bits : integer := 18; --input time resolution bits
constant AtA_scale : integer := 11; --scale of the AAt lookup table
constant AtA_bits : integer := AtA_scale+1; --scale of the AAt lookup table plus a sign bit

--Types for preprocessing
type 		region5x5_subtype			is array (2 downto -2) of STD_LOGIC_VECTOR(time_resolution_bits-1 downto 0); --one more bit
type 		region5x5_type				is array (2 downto -2) of region5x5_subtype;

type 		region5x5signed_subtype			is array (2 downto -2) of STD_LOGIC_VECTOR(time_resolution_bits downto 0); --one more bit
type 		region5x5signed_type				is array (2 downto -2) of region5x5signed_subtype;


type 		valid5_type					is array (2 downto -2) of STD_LOGIC;
type 		valid5x5_type				is array (2 downto -2) of valid5_type;

type 		valid3x3_subtype			is array (1 downto -1) of STD_LOGIC;
type 		valid3x3_type				is array (1 downto -1) of valid3x3_subtype;

type 		valid3x3_vector_type		is array (8 downto 0) of valid3x3_type;

type 		region3x3_subtype			is array (1 downto -1) of STD_LOGIC_VECTOR(time_resolution_bits-1 downto 0);
type 		region3x3_type				is array (1 downto -1) of region3x3_subtype;

type 		region3x3_vector_type		is array (8 downto 0) of region3x3_type;

--1 bit larger, allowing values up to double of the max resolution value
type 		region3x3_estimate_subtype			is array (1 downto -1) of STD_LOGIC_VECTOR(time_resolution_bits+4 downto 0);
type 		region3x3_estimate_type				is array (1 downto -1) of region3x3_estimate_subtype;




type		valid3x3_subarray			is array (1 downto -1) of valid3x3_type;
type		valid3x3_array				is array (1 downto -1) of valid3x3_subarray;

type		region3x3_subarray		is array (1 downto -1) of region3x3_type;
type		region3x3_array			is array (1 downto -1) of region3x3_subarray;

--type 	valid_pixel_count_subarray	is array (1 downto -1) of std_logic_vector(3 downto 0);
--type 	valid_pixel_count_array		is array (1 downto -1) of valid_pixel_count_subarray;
-- Declare constants

type AtA_inv_subtype					is array (1 downto -1) of std_logic_vector(11 downto 0);
type AtA_inv_type						is array (1 downto -1) of AtA_inv_subtype;

type ab_array_subtype 				is array (1 downto -1) of std_logic_vector(17 downto 0);
type ab_array_type 					is array (1 downto -1) of ab_array_subtype;

type num_pixels_array_subtype		is array (1 downto -1) of std_logic_vector(3 downto 0);
type num_pixels_array_type			is array (1 downto -1) of num_pixels_array_subtype;

type error_array_subtype			is array (1 downto -1) of std_logic_vector(time_resolution_bits+3 downto 0);
type error_array_type				is array (1 downto -1) of error_array_subtype;




-- event types
constant evt_type_TD								: 	STD_LOGIC_VECTOR(7 downto 0)	:= conv_std_logic_vector(0,8);
constant evt_type_APS							: 	STD_LOGIC_VECTOR(7 downto 0)	:= conv_std_logic_vector(1,8);
constant evt_type_TimerOverflow				: 	STD_LOGIC_VECTOR(7 downto 0)	:= conv_std_logic_vector(2,8);
constant evt_type_TD_Filtered					: 	STD_LOGIC_VECTOR(7 downto 0)	:= conv_std_logic_vector(3,8); --3 TD filtered... can become a subtype of TD
constant evt_type_APS_Filtered				: 	STD_LOGIC_VECTOR(7 downto 0)	:= conv_std_logic_vector(4,8); --4 APS filtered... can become a subtype of APS
constant evt_type_Tracker						: 	STD_LOGIC_VECTOR(7 downto 0)	:= conv_std_logic_vector(5,8);
constant evt_type_Orientation					: 	STD_LOGIC_VECTOR(7 downto 0)	:= conv_std_logic_vector(6,8);
constant evt_type_TDfeature					: 	STD_LOGIC_VECTOR(7 downto 0)	:= conv_std_logic_vector(7,8);
constant evt_type_Trigger						: 	STD_LOGIC_VECTOR(7 downto 0)	:= conv_std_logic_vector(8,8);
constant evt_type_Orientation_Filtered		: 	STD_LOGIC_VECTOR(7 downto 0)	:= conv_std_logic_vector(9,8);
constant evt_type_Tracked						: 	STD_LOGIC_VECTOR(7 downto 0)	:= conv_std_logic_vector(10,8);
constant evt_type_IMU							: 	STD_LOGIC_VECTOR(7 downto 0)	:= conv_std_logic_vector(11,8);

constant evt_type_opticalflow					: 	STD_LOGIC_VECTOR(7 downto 0)	:= conv_std_logic_vector(20,8);

constant evt_type_Reset							: 	STD_LOGIC_VECTOR(7 downto 0)	:= conv_std_logic_vector(253,8);
constant evt_type_Invalid						: 	STD_LOGIC_VECTOR(7 downto 0)	:= conv_std_logic_vector(254,8);
constant evt_type_Quit							: 	STD_LOGIC_VECTOR(7 downto 0)	:= conv_std_logic_vector(255,8);


-- TD event subtypes
constant evt_subtype_TDon						: 	STD_LOGIC_VECTOR(7 downto 0)	:= conv_std_logic_vector(0,8);
constant evt_subtype_TDoff						: 	STD_LOGIC_VECTOR(7 downto 0)	:= conv_std_logic_vector(1,8);

-- APS event subtypes
constant evt_subtype_APS_high					: 	STD_LOGIC_VECTOR(7 downto 0)	:= conv_std_logic_vector(0,8);
constant evt_subtype_APS_low					: 	STD_LOGIC_VECTOR(7 downto 0)	:= conv_std_logic_vector(1,8);

-- Optical flow event subtypes
constant evt_subtype_OF_location				: 	STD_LOGIC_VECTOR(7 downto 0)	:= conv_std_logic_vector(0,8); --specifies when and where the optical flow event occurred
constant evt_subtype_OF_values_cartesian	: 	STD_LOGIC_VECTOR(7 downto 0)	:= conv_std_logic_vector(1,8); --specifies velocity in cartesian co-ordinates (vx, vy)
constant evt_subtype_OF_values_polar		: 	STD_LOGIC_VECTOR(7 downto 0)	:= conv_std_logic_vector(2,8); --specifies velocity in polar co-ordinates (||v||, theta)



-- TRIGGER IN ADDRESSES
constant TriggerWire_address					: 	STD_LOGIC_VECTOR(7 downto 0)	:= X"40";

-- WIRE IN ADDRESSES
constant ControlWire_address					: 	STD_LOGIC_VECTOR(7 downto 0)	:= X"00";

constant v4DAC_wireLSB_address				: 	STD_LOGIC_VECTOR(7 downto 0)	:= X"01";
constant v4DAC_wireMidSB_address				: 	STD_LOGIC_VECTOR(7 downto 0)	:= X"02";
constant v4DAC_wireMSB_address				: 	STD_LOGIC_VECTOR(7 downto 0)	:= X"03";

constant EventWire_address						: 	STD_LOGIC_VECTOR(7 downto 0)	:= X"09";
constant Filter_rf_address						: 	STD_LOGIC_VECTOR(7 downto 0)	:= X"10";
constant Filter_th_address						: 	STD_LOGIC_VECTOR(7 downto 0)	:= X"11";

constant OF_config_address						: 	STD_LOGIC_VECTOR(7 downto 0)	:= X"12";
constant OF_refrac_address						: 	STD_LOGIC_VECTOR(7 downto 0)	:= X"13";
constant OF_old_pixels_address				: 	STD_LOGIC_VECTOR(7 downto 0)	:= X"14";
constant OF_fit_distance_address				: 	STD_LOGIC_VECTOR(7 downto 0)	:= X"15";
constant OF_badness_threshold_address		: 	STD_LOGIC_VECTOR(7 downto 0)	:= X"16";

-- WIRE OUT ADDRESSES
constant Event_RAM_address						: 	STD_LOGIC_VECTOR(7 downto 0)	:= X"20";
constant Simulation_RAM_address				: 	STD_LOGIC_VECTOR(7 downto 0)	:= X"25";


-- PIPE OUT ADDRESSES
constant EventPipeOut_address					: 	STD_LOGIC_VECTOR(7 downto 0)	:= X"A0";

-- PIPE IN ADDRESSES
constant BiasesPipeIn_address					: 	STD_LOGIC_VECTOR(7 downto 0)	:= X"90";
constant ROIPipeIn_address						: 	STD_LOGIC_VECTOR(7 downto 0)	:= X"91";
constant MotorPipeIn_address					: 	STD_LOGIC_VECTOR(7 downto 0)	:= X"83";
constant SimulationPipeIn_address			: 	STD_LOGIC_VECTOR(7 downto 0)	:= X"88";




-- CONTROL SIGNAL WIRE BITS
constant TDcouple_bit							: integer := 0;
constant APS_Seq_bit								: integer := 1;
constant LIFUdownB_bit							: integer := 2;
constant ROI_APS_bit								: integer := 3;
constant ROI_TD_bit								: integer := 4;
constant remove_filtered_bit					: integer := 5;
constant APS_Shutter_bit						: integer := 6;
constant OutputDriverDefault_bit				: integer := 7;
constant NOT_BGenPower_Down_bit 				: integer := 8;
constant ROI_TDinv_bit							: integer := 9;
constant Enable_AER_TD_bit						: integer := 10;
constant Enable_AER_APS_bit					: integer := 11;
constant Refraction_enable_bit				: integer := 12;
constant Filter_enable_bit						: integer := 13;
constant TN_enable_bit							: integer := 14;
constant ATIS_sim_enable_bit					: integer := 15;

-- OPTICAL FLOW CONFIG BITS
constant of_enable_bit							: integer := 0;
constant filter_badness_bit					: integer := 1;
constant cartesian_or_polar_bit				: integer := 2;
constant num_pixels_threshold_bitH			: integer := 7;
constant num_pixels_threshold_bitL			: integer := 4;




-- TRIGGER SIGNAL WIRE BITS
constant BiasReset_bit							: integer := 0;
constant v4BiasValid_bit						: integer := 1;
constant ResetROI_fifo_bit						: integer := 2;
constant v4ROIdataValid_bit					: integer := 3;
constant v4ROIprogram_bit						: integer := 4;
constant ResetFifos_bit							: integer := 7;
constant WireInEvtValid_bit					: integer := 10;



end ATISpackage;

--
package body ATISpackage is
--
---- Example 1
--  function <function_name>  (signal <signal_name> : in <type_declaration>  ) return <type_declaration> is
--    variable <variable_name>     : <type_declaration>;
--  begin
--    <variable_name> := <signal_name> xor <signal_name>;
--    return <variable_name>; 
--  end <function_name>;
--
--
---- Example 2
--  function <function_name>  (signal <signal_name> : in <type_declaration>;
--                         signal <signal_name>   : in <type_declaration>  ) return <type_declaration> is
--  begin
--    if (<signal_name> = '1') then
--      return <signal_name>;
--    else
--      return 'Z';
--    end if;
--  end <function_name>;
--
---- Procedure Example
--  procedure <procedure_name>  (<type_declaration> <constant_name>  : in <type_declaration>) is
--    
--  begin
--    
--  end <procedure_name>;
-- 
end ATISpackage;
