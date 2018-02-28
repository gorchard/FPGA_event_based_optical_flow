function FRAM = read_FRAM_simulation_result(filename)

%read data in from file, with spaces used as the separator
data_raw = int32(dlmread(filename, ' ')');

%first two columns are the x and y address
FRAM.x = data_raw(1,:);
FRAM.y = data_raw(2,:);

%next 25 columns are the 5x5 pixel regions
n = 5;
FRAM.region5x5 = zeros(5,5,length(FRAM.x));
for xx = 1:5
    for yy = 1:5
        FRAM.region5x5(yy,xx,:) = data_raw(n,:);
        n = n+1;
    end
end
