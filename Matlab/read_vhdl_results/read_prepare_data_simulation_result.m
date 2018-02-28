function prepared_vhdl = read_prepare_data_simulation_result(filename)

%read data from file
data_raw = int32(dlmread(filename, ' ')');

%calculate number of outputs
num_results = size(data_raw,2);

%x and y are first 2 columns
prepared_vhdl.x = data_raw(1,:);
prepared_vhdl.y = data_raw(2,:);

%rest of columns are the time regions and validity. Order of reading must
%match order of writing in vhdl simulation
n = 3;
prepared_vhdl.region5x5 = zeros(5,5,num_results);
prepared_vhdl.valid5x5 = zeros(5,5,num_results);
for xx = 1:5
    for yy = 1:5
        prepared_vhdl.valid5x5(yy,xx,:) = data_raw(n,:);
        n = n+1;
        prepared_vhdl.region5x5(yy,xx,:) = data_raw(n,:);
        n = n+1;
    end
end
