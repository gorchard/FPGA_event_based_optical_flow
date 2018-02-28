function prepared = simulate_prepare_data(FRAM, plane_fit_params)

%x and y addresses are not modified, but should be checked to make sure
%they are buffered correctly between input and output in simulation
prepared.x = FRAM.x';
prepared.y = FRAM.y';
prepared.ts = FRAM.ts';

%output should be same size as input, pre-allocate
prepared.region5x5 = zeros(size(FRAM.region5x5));

%loop through and subtract the value of the center pixel from each region
%(since we only want relative time since the last event).
for n = 1:size(FRAM.region5x5,3)
    prepared.region5x5(:,:,n) = FRAM.region5x5(3,3,n) - FRAM.region5x5(:,:,n);
end

%bring all times to be mod 2^(plane_fit_params.time_bits-1)
prepared.region5x5(prepared.region5x5>=2^(plane_fit_params.time_bits-1)) = prepared.region5x5(prepared.region5x5>=2^(plane_fit_params.time_bits-1)) - 2^(plane_fit_params.time_bits-1);

%any events "in the future" are due to timer overflow. Bring them back to
%the past.
while sum(prepared.region5x5(:)<0)>0
    prepared.region5x5(prepared.region5x5<0) = prepared.region5x5(prepared.region5x5<0) + 2^(plane_fit_params.time_bits-1);
end

prepared.valid5x5 = prepared.region5x5 < plane_fit_params.old_pixel_threshold; %remove old pixels
prepared.valid5x5(FRAM.region5x5==0) =0; %any invalid pixels should be marked as invalid
prepared.valid5x5(3,3,:) = 1; %but the center pixel is always valid