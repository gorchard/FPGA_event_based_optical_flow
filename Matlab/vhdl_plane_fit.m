%%
%This script performs the plane fitting process with results exactly as
%expected from vhdl
clear all
%% Set the parameters to use
% source data file containing a struct "TD" with fields:
%   TD.x: x-address (1 to 304 for ATIS)
%   TD.y: y-address (1 to 240 for ATIS)
%   TD.ts: timestamp in microseconds
source_file = 'TD';

% pre_processing parameters
pre_process_params.noise_filter_threshold = []; %should probably be 1/max_velocity
pre_process_params.refractory_period = 50e3; % should probably be 3/max_velocity

% processing parameters

plane_fit_params.refractory_period = 50e3;
plane_fit_params.old_pixel_threshold = 200e3; %what is the time/age beyond which we start to consider a pixel no longer valid for computation (should probably be 3/max_velocity)
plane_fit_params.num_pixels_threshold = 6; %what is the minimum number of pixels required for a fit
plane_fit_params.fit_distance_threshold = 4e3 ; % ;=1e3; %what is the distance (in microseconds) beyond which a point is considered an outlier?
plane_fit_params.dim_x = 304; % sensor x dimension
plane_fit_params.dim_y = 240; % sensor y dimension
plane_fit_params.time_bits = 19;

%parameters for the output
output_format_params.minval = 500; %corresponds to max speed of 2000 pixels per second (1e6/2000)
output_format_params.maxval = 40000; %corresponds to min speed of 25 pixels per second (1e6/(40000))
output_format_params.div_scale_bits = 30;
output_format_params.truncate_bits = 8;

addpath(genpath('.')); % add functions to the path

%add the matlab aer vision functions to the path
addpath(genpath('../Matlab_AER_vision_functions')); % add functions to the path
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

%% full precision functions are called below

%extract 5x5 regions for plane fitting
FRAM = simulate_Filtering_RAM(TD, plane_fit_params);

%change times to be relative to center pixel
prepared = simulate_prepare_data(FRAM, plane_fit_params);

%split 5x5 region into 3x3 subregions
fit_arbiter_output = simulate_fit_arbiter(prepared, plane_fit_params);

%perform the plane fitting. Keep looping until there are not fits left for
%refitting
[refit, result] = simulate_plane_fit_wrapper(fit_arbiter_output, plane_fit_params);
ii =0;
while ~isempty(refit.ts)
    ii = ii+1;
    fprintf('finished processing iteration %i\n', ii); %give some encouraging feedback
    [refit, result_refit] = simulate_plane_fit_wrapper(refit, plane_fit_params);
    result = CombineStreams(result_refit, result);
end

%extract the velocities from the plane fit results
output_scaled = simulate_format_output(result, output_format_params);

%this is how to interpret the vhdl results
output = output_scaled;
output.vx = output.vx./(2^(output_format_params.div_scale_bits-output_format_params.truncate_bits));
output.vy = output.vy./(2^(output_format_params.div_scale_bits-output_format_params.truncate_bits));

%% show output
%magnitude
speed = output;
speed.p = round(1e6*sqrt(speed.vx.^2+speed.vy.^2));
ShowTD(speed)

%direction
direction = output;
direction.p = round(atan2d(direction.vx, direction.vy)+181);
ShowTD(direction)

% %pos x velocity
% speed = output;
% speed.p = round(1e6*speed.vx);
% speed = RemoveNulls(speed, speed.p<=0);
% ShowTD(speed)
% 
% %neg x velocity
% speed = output;
% speed.p = -round(1e6*speed.vx);
% speed = RemoveNulls(speed, speed.p<=0);
% ShowTD(speed)
% 
% %pos y velocity
% speed = output;
% speed.p = round(1e6*speed.vy);
% speed = RemoveNulls(speed, speed.p<=0);
% ShowTD(speed)
% 
% %neg x velocity
% speed = output;
% speed.p = -round(1e6*speed.vy);
% speed = RemoveNulls(speed, speed.p<=0);
% ShowTD(speed)
