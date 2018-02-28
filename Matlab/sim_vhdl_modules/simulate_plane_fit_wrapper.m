function [refit, result] = simulate_plane_fit_wrapper(fit_arbiter, params)


%create pixel relative addresses to construct A matrix
[x,y] = meshgrid(-1:1,-1:1); 
A_back = [x(:),y(:),ones(9,1)];

%pre-allocation if memory to save time
num_items = length(fit_arbiter.x);
result.a = zeros(1,num_items);
result.b = zeros(1,num_items);
result.x = zeros(1,num_items);
result.y = zeros(1,num_items);
result.ii = zeros(1,num_items);
result.ts = zeros(1,num_items);


refit.ii = zeros(1,num_items);
refit.x = zeros(1,num_items);
refit.y = zeros(1,num_items);
refit.region3x3 = zeros(3,3,num_items);
refit.valid3x3 = zeros(3,3,num_items);
refit.ts = zeros(1,num_items);

%indices keeping track of how many outputs are sent to each bus
result_index = 1; 
refit_index = 1;

for ii = 1:num_items
    %which pixels in this 3x3 region are valid?
    temp_valid = fit_arbiter.valid3x3(:,:,ii)==1;
    
    %what are the pixel relative time values?
    temp_region = fit_arbiter.region3x3(:,:,ii);
    
    %construct the A matrix
    A = A_back(temp_valid(:), :); %pixel locations
    
    %extract the valid pixels
    Z = temp_region(temp_valid); %pixel times
    
    %compute the result of (A'A)^-1 (a LUT in hardware)
    AtA_inv = floor(inv(A'*A)*2^11); %can be changed to "round" if the LUT is updated accordingly scale is 2^11
    %AtA_inv_full = inv(A'*A);
    
    %compute A'Z
    AtZ = A'*Z; %the a,b,d values of the 
    AtZ = floor(AtZ/2^4); %remove 4 bits to fit in a single multiplier scale is 2^-4
    %AtZ_full = A'*Z;
    
    %multiply the two to get the a,b,d values for the plane fit
    x = floor(AtA_inv*AtZ); %x holds [a, b, d] scale is 2^11 + 2^-4 = 2^7
    x = floor(x./2^7); %remove 7 bits to bring it back to scale 2^0
    %x_full = AtA_inv_full*AtZ_full;
    
    %use the plane parameters to estimate the times
    z = A*x; %estimated pixel values
    %z_full = A*x_full;

    %partial computations done in FPGA
    %z_estimate1 = reshape(A_back(:,1:2)*x(1:2), [3,3]);
    %z_estimate2 = x(3)-fit_arbiter.region3x3(:,:,ii);
    
    %find the error in the time estimates
    zdiff = z-Z;
    %zdiff_full = z_full-Z;
    
    %z_diff_all =  (reshape(A_back*x,[3,3])-fit_arbiter.region3x3(:,:,ii)).*fit_arbiter.valid3x3_in(:,:,ii);
    
% %     %used to debug a particular vhdl simulation
%      if ii == 770167 
%         keyboard()
%      end
    
    %calculate how many pixels are valid
    num_valid_pixels = sum(abs(zdiff)<=params.fit_distance_threshold);
    
    %calculate whether there are any NEW invalid pixels
    num_INvalid_pixels = length(z) - num_valid_pixels;
    
    %if there are enough valid pixels remaining... then
    if num_valid_pixels >= params.num_pixels_threshold
        
        %if there are no new invalid pixels, output the result
        if num_INvalid_pixels == 0
            result.a(result_index) = x(1);
            result.b(result_index) = x(2);
            result.x(result_index) = fit_arbiter.x(ii);
            result.y(result_index) = fit_arbiter.y(ii);
            result.ii(result_index) = ii;
            result.ts(result_index) = fit_arbiter.ts(ii);
            result_index = result_index +1;
        else %else means more pixels have been marked invalid, but there are still enough pixels to do a new plane fit
            %calculate which pixels are now valid
            temp_valid = (abs((reshape(A_back*x,[3,3])-temp_region))<=params.fit_distance_threshold).*temp_valid; %estimated pixel values
            
            %output the result on the refit bus
            refit.x(refit_index) = fit_arbiter.x(ii);
            refit.y(refit_index) = fit_arbiter.y(ii);
            refit.region3x3(:,:,refit_index) = temp_region;
            refit.valid3x3(:,:,refit_index) = temp_valid;
            refit.ii(refit_index) = ii;
            refit.ts(refit_index) = fit_arbiter.ts(ii);
            refit_index = refit_index +1;
        end
    end
end

%remove any extra allocated memory
refit.x(refit_index:end) = [];
refit.y(refit_index:end) = [];
refit.ii(refit_index:end) = [];
refit.ts(refit_index:end) = [];
refit.region3x3(:,:,refit_index:end) = [];
refit.valid3x3(:,:,refit_index:end) = [];

result.a(result_index:end) = [];
result.b(result_index:end) = [];
result.x(result_index:end) = [];
result.y(result_index:end) = [];
result.ts(result_index:end) = [];
result.ii(result_index:end) = [];

%negate the result (we negated time to work with positive values, so we
%must also negate a and b)
result.a = -result.a;
result.b = -result.b;