function FRAM = Filtering_RAM(TD, params)


%RAM holding the latest spike time for each event. Start with large
%negative numbers to prevent refractory filtering
mem_array = ones(params.dim_y, params.dim_x)*-params.old_pixel_threshold;

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
    
    t_diff = TD.ts(event_num) - old_time; %otherwise calculate time difference since last event
    
    if t_diff > params.refractory_period %if the time difference is longer than the refractory period (i.e. pixel is not in refraction)
        
        %write new event time to memory
        mem_array(TD.y(event_num), TD.x(event_num)) = TD.ts(event_num);
        
        
        % only use the event if a 5x5 pixel region around it does not
        % overlap with the edge of the scene
        if TD.x(event_num)>2 && TD.y(event_num)>2 && TD.x(event_num)<params.dim_x-1 && TD.y(event_num)<params.dim_y-1
            %extract a 5x5 region around the current pixel
            temp_region = (mem_array(TD.y(event_num) + (-2:2), TD.x(event_num) + (-2:2)));
            
            %set any pixels older than the "old_pixel_threshold" to zero
            temp_region((temp_region(3,3)-temp_region) >= params.old_pixel_threshold) = 0;
            
            %store the result in our output struct
            FRAM.region5x5(:,:,output_num) = temp_region;
            FRAM.x(output_num) = TD.x(event_num); 
            FRAM.y(output_num) = TD.y(event_num);
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