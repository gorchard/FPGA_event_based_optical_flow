%%
%This script compares the output of vhdl simulations to fixed precision 
%matlab functions and ensures that there is an exact match between them

%% Set the parameters to use
% source data file containing a struct "TD" with fields:
%   TD.x: x-address (1 to 304 for ATIS)
%   TD.y: y-address (1 to 240 for ATIS)
%   TD.ts: timestamp in microseconds
source_file = 'TD';

% pre_processing parameters. Empty assumes preprocessing is already done
pre_process_params.noise_filter_threshold = []; %should probably be 1/max_velocity
pre_process_params.refractory_period = []; % should probably be 3/max_velocity

% processing parameters
plane_fit_params.refractory_period = 50e3;
plane_fit_params.old_pixel_threshold = 200e3; %what is the time/age beyond which we start to consider a pixel no longer valid for computation (should probably be 3/max_velocity)
plane_fit_params.num_pixels_threshold = 6; %what is the minimum number of pixels required for a fit
plane_fit_params.fit_distance_threshold = 4e3 ; % ;=1e3; %what is the distance (in microseconds) beyond which a point is considered an outlier?
plane_fit_params.time_bits = 19; % how many bits are used to represent time in memory
plane_fit_params.dim_x = 304; % sensor x dimension
plane_fit_params.dim_y = 240; % sensor y dimension


%what are the max and min magnitudes for a and b (set in the vhdl file).
%These are determined by the min and max expected speeds. Magnitude of the
%velocity is 1/sqrt(a^2+b^2), can work it out from there based on a
%sensible speed range
output_format_params.minval = 500; %corresponds to max speed of 2000 pixels per second (1e6/2000)
output_format_params.maxval = 40000; %corresponds to min speed of 25 pixels per second (1e6/(40000))
%how many bits is the result of division scaled by?
%the numerator (1) is shifted by 13 bits, and we use 17 fractional bits, so
%treating the fractional as an integer means it is scaled by 2^30. We then
%truncate 8 bits which brings it down to
output_format_params.div_scale_bits = 30;
output_format_params.truncate_bits = 8;


%where is the simulation working directory?
sim_dir = '../VHDL/simulation/data/';

%add the vhdl verification functions to the path
addpath(genpath('.')); % add functions to the path

%add the matlab aer vision functions to the path
addpath(genpath('Matlab_AER_vision_functions')); % add functions to the path
if ~exist('FilterTD', 'file')
    error('Matlab AER functions not found, please make sure to download the latest version from http://www.garrickorchard.com/code/matlab-AER-functions \n and add them to your path');
end

%
load(source_file)

%% preprocess data
% These steps rely on old matlab functions and common vhdl modules used in 
% many of our designs. These functions are not a precise match for the 
% vhdl, but are very close. This script focuses on verifying the optical 
% flow module.
if ~isempty(pre_process_params.noise_filter_threshold)
    TD = FilterTD(TD, pre_process_params.noise_filter_threshold);
end

if ~isempty(pre_process_params.refractory_period)
    TD = ImplementRefraction(TD, pre_process_params.refractory_period);
end

%% write the preprocessed data to file for VHDL to use in simulations
TD.p(TD.p==1) = 2;
writeAERv2(TD, [],  [sim_dir, 'sim_dummy_input.val']);

%% verify the RAM module

%matlab simulation of the results expected from the RAM module
FRAM = simulate_Filtering_RAM(TD, plane_fit_params);

%vhdl results read from vhdl simulation
FRAM_vhdl = read_FRAM_simulation_result([sim_dir, 'Filter_RAM_output.dat']);


% If the full simulation is not yet completed, the below commented code will only extract part of it

% n = length(FRAM_vhdl.x)-1; %ignore the last simulation result because it might be incomplete (simulation still running)
% FRAM.region5x5 = FRAM.region5x5(:,:,1:n);
% FRAM.x = FRAM.x(1:n);
% FRAM.y = FRAM.y(1:n);
% FRAM_vhdl.region5x5 = FRAM_vhdl.region5x5(:,:,1:n);
% FRAM_vhdl.x = FRAM_vhdl.x(1:n);
% FRAM_vhdl.y = FRAM_vhdl.y(1:n);

num_x_errors = sum(abs(FRAM.x-double(FRAM_vhdl.x'))); %x error
num_y_errors = sum(abs(FRAM.y-double(FRAM_vhdl.y'))); %y error
num_z_errors = sum(sum(sum(FRAM.region5x5~=double(FRAM_vhdl.region5x5)))); %region error
t_indices = find(squeeze(sum(sum(FRAM.region5x5~=double(FRAM_vhdl.region5x5),1),2)));

% the region may have a few "errors" due to unpredictable timing in FPGA.
% When a pixel is over "old_pixel_threshold" timesteps old, it still takes a few 
% microseconds for the old values to be removed in FPGA. These "errors" do
% not affect results because the later modules also check and remove old
% pixels
for t = 1:length(t_indices)
    temp = FRAM_vhdl.region5x5(:,:,t_indices(t));
    %check for overlap
    t_temp = temp(3,3);
    temp(temp<=(t_temp-plane_fit_params.old_pixel_threshold)) = 0; %remove old values
    temp( (temp<(t_temp+2^(plane_fit_params.time_bits)-plane_fit_params.old_pixel_threshold))  & (temp>(t_temp)) ) = 0; %and remove overflow old values
    %FRAM_vhdl.region5x5(:,:,t_indices(t)) = temp;
    FRAM_vhdl.region5x5(:,:,t_indices(t)) = temp;
end

num_z_errors_new = sum(sum(sum(FRAM.region5x5~=double(FRAM_vhdl.region5x5)))); %region error

%printout the results
fprintf('\nFILTER_RAM\n')
fprintf('%i x address errors \n', num_x_errors);
fprintf('%i y address errors \n', num_y_errors);
fprintf('%i z value small discrepancies \n', num_z_errors);
fprintf('%i of the z discrepancies are errors\n', num_z_errors_new);


%% verification of "prepare data"

%matlab simulation of the "prepare_data" module
prepared = simulate_prepare_data(FRAM, plane_fit_params);

%read in vhdl simulation results from the "prepare_data" module
prepared_vhdl = read_prepare_data_simulation_result([sim_dir, 'prepare_data_output.dat']);

%only bother with valid data. We don't care about any values marked as
%invalid
prepared.region5x5(prepared.valid5x5==0) = 0;
prepared_vhdl.region5x5(prepared_vhdl.valid5x5==0) = 0;

%identify errors
num_x_errors = sum(prepared.x ~= prepared_vhdl.x);
num_y_errors = sum(prepared.y ~= prepared_vhdl.y);
num_z_errors = sum(sum(sum(prepared.region5x5 ~= prepared_vhdl.region5x5)));
num_v_errors = sum(sum(sum(prepared.valid5x5 ~= prepared_vhdl.valid5x5)));

%print out results
fprintf('\nPREPARE DATA\n')
fprintf('%i x address errors\n', num_x_errors);
fprintf('%i y address errors\n', num_y_errors);
fprintf('%i z value errors\n', num_z_errors);
fprintf('%i validity errors\n', num_v_errors);


%% verification of "fit_arbiter"

%matlab simulation of the "fit_arbiter" module
fit_arbiter = simulate_fit_arbiter(prepared, plane_fit_params);

%read in vhdl simulation results from the "fit_arbiter" module
fit_arbiter_vhdl = read_fit_arbiter_simulation_result([sim_dir, 'fit_arbiter_output.dat']);

%set any invalid pixels to zero (we don't care about their actual value)
fit_arbiter_vhdl.region3x3(fit_arbiter_vhdl.valid3x3 == 0) = 0;

%identify errors
num_x_errors = sum(fit_arbiter.x ~= fit_arbiter_vhdl.x);
num_y_errors = sum(fit_arbiter.y ~= fit_arbiter_vhdl.y);
num_z_errors = sum(sum(sum(fit_arbiter.region3x3 ~= fit_arbiter_vhdl.region3x3)));
num_v_errors = sum(sum(sum(fit_arbiter.valid3x3 ~= fit_arbiter_vhdl.valid3x3)));

%print out results
fprintf('\nFIT ARBITER\n')
fprintf('%i x address errors\n', num_x_errors);
fprintf('%i y address errors\n', num_y_errors);
fprintf('%i z value errors\n', num_z_errors);
fprintf('%i validity errors\n', num_v_errors);


%% verification of "plane_fit_wrapper"

%matlab simulation of plane_fit_wrapper
[refit, result] = simulate_plane_fit_wrapper(fit_arbiter, plane_fit_params);

%vhdl simulation of plane_fit_wrapper
[refit_vhdl, result_vhdl] = read_plane_fit_wrapper_simulation_result([sim_dir, 'plane_fitting_wrapper_out.dat']);

if length(refit.x) ~= length(refit_vhdl.x)
    error('vhdl and matlab code return different number of samples for refitting')
end

%change invalid pixels to value '0'
refit_vhdl.region3x3(refit_vhdl.valid3x3==0) = 0;
refit.region3x3(refit.valid3x3==0) = 0;

%identify errors
num_x_errors = sum(refit.x ~= refit_vhdl.x);
num_y_errors = sum(refit.y ~= refit_vhdl.y);
num_z_errors = sum(sum(sum(refit.region3x3 ~= refit_vhdl.region3x3)));
num_v_errors = sum(sum(sum(refit.valid3x3 ~= refit_vhdl.valid3x3)));


%print out results
fprintf('\nPLANE FIT MODULE (refit bus)\n')
fprintf('%i x address refit errors\n', num_x_errors);
fprintf('%i y address refit errors\n', num_y_errors);
fprintf('%i z value refit errors\n', num_z_errors);
fprintf('%i validity refit errors\n', num_v_errors);


if length(result.x) ~= length(result_vhdl.x)
    error('vhdl and matlab code return different number of results')
end

%identify errors
num_x_errors = sum(result.x ~= result_vhdl.x);
num_y_errors = sum(result.y ~= result_vhdl.y);
num_a_errors = sum(result.a ~= result_vhdl.a);
num_b_errors = sum(result.b ~= result_vhdl.b);

%print out results
fprintf('\nPLANE FIT MODULE (result bus)\n')
fprintf('%i x address result errors\n', num_x_errors);
fprintf('%i y address result errors\n', num_y_errors);
fprintf('%i a value result errors\n', num_a_errors);
fprintf('%i b value result errors\n', num_b_errors);


%% verification of output_formatter
%matlab simulation of the output_format module
output = simulate_format_output(result, output_format_params);

%vhdl simulation results of the output_format module
output_vhdl = read_format_output_simulation_result([sim_dir, 'format_output_out.dat']);

%identify errors
num_x_errors = sum(output.x ~= output_vhdl.x);
num_y_errors = sum(output.y ~= output_vhdl.y);
num_vx_errors = sum(output.vx ~= output_vhdl.vx);
num_vy_errors = sum(output.vy ~= output_vhdl.vy);


%print out results
fprintf('\nFORMAT OUTPUT MODULE\n')
fprintf('%i x address result errors\n', num_x_errors);
fprintf('%i y address result errors\n', num_y_errors);
fprintf('%i vx value result errors\n', num_vx_errors);
fprintf('%i vy value result errors\n', num_vy_errors);