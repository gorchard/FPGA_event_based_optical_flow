function output = simulate_fit_arbiter(input, params)

%how many data events?
num_events = length(input.x);

%pre-allocate memory
output.x = zeros(1,9*num_events);
output.y = zeros(1,9*num_events);
output.ts = zeros(1,9*num_events);
output.region3x3 = zeros(3,3,9*num_events);
output.valid3x3 = zeros(3,3,9*num_events);

%split the 5x5 region into 3x3 regions
n=1;
for ii = 1:num_events
    for sub_y = -1:1
        for sub_x = -1:1
            sub3x3valid = input.valid5x5((2:4)+sub_y, (2:4)+sub_x, ii);
            
            if sum(sub3x3valid(:)) >= params.num_pixels_threshold %only use regions which have enough valid pixels
                output.x(n) = input.x(ii) + sub_x;
                output.y(n) = input.y(ii) + sub_y;
                output.valid3x3(:,:,n) = sub3x3valid;
                output.region3x3(:,:,n) = input.region5x5((2:4)+sub_y, (2:4)+sub_x, ii);
                output.ts(n) = input.ts(ii);
                n = n +1;
            end
        end 
    end
end

%remove any extra allocated memory
output.valid3x3(:,:,n:end)=[];
output.region3x3(:,:,n:end)=[];
output.x(n:end)=[];
output.y(n:end)=[];
output.ts(n:end)=[];
