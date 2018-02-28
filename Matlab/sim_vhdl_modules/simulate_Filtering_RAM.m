function FRAM = simulate_Filtering_RAM(TD, params)

%the BRAM holding the latest spike time for each event
mem_array = zeros(params.dim_y, params.dim_x);

%how many events are we processing
num_evts = length(TD.ts);

%pre-allocate large memory to save time
FRAM.region5x5 = zeros(5,5,num_evts);
FRAM.x = zeros(num_evts,1);
FRAM.y = zeros(num_evts,1);
FRAM.ts = zeros(num_evts,1);
            
output_num = 1;
for event_num = 1:length(TD.ts) %loop through all events
    old_time = mem_array(TD.y(event_num), TD.x(event_num)); %read old event from BRAM
    
    if old_time == 0 %check if 0 (reserved to indicate expired data)
        t_diff = 2^params.time_bits; %if expired, set t_diff to arbitrary large value
    else
        t_diff = TD.ts(event_num) - old_time; %otherwise calculate time difference since last event
    end
    
    
    if t_diff > params.refractory_period %if the time difference is longer than the refractory period (i.e. pixel is not in refraction)
        
        %write new event time to memory, taking care not to write a value
        %of zero (reserved to indicate expired data)
        if rem(TD.ts(event_num), 2^params.time_bits) == 0
            mem_array(TD.y(event_num), TD.x(event_num)) = TD.ts(event_num)+1;
        else
            mem_array(TD.y(event_num), TD.x(event_num)) = TD.ts(event_num);
        end
        
        % only use the event if a 5x5 pixel region around it does not
        % overlap with the edge of the scene
        if TD.x(event_num)>2 && TD.y(event_num)>2 && TD.x(event_num)<params.dim_x-1 && TD.y(event_num)<params.dim_y-1
            %extract a 5x5 region around the current pixel
            temp_region = (mem_array(TD.y(event_num) + (-2:2), TD.x(event_num) + (-2:2)));
            
            %set any pixels older than the "old_pixel_threshold" to zero
            temp_region((temp_region(3,3)-temp_region) >= params.old_pixel_threshold) = 0;
            
            %store the result in our output struct
            FRAM.region5x5(:,:,output_num) = temp_region;
            FRAM.x(output_num) = TD.x(event_num)-1; %-1 difference between Matlab and VHDL/C++
            FRAM.y(output_num) = TD.y(event_num)-1;
            FRAM.ts(output_num) = TD.ts(event_num);
            output_num = output_num+1;
        end
    end
end

%remove any additional memory allocated which wasn't used
FRAM.region5x5(:,:,output_num:end) = [];
FRAM.x(output_num:end) = [];
FRAM.y(output_num:end) = [];
FRAM.ts(output_num:end) = [];

%handle time overflows
FRAM.region5x5 = rem(FRAM.region5x5, 2^params.time_bits);

%mat_ts = squeeze(mat_region5x5(3,3,:)); %optionally calculate the times