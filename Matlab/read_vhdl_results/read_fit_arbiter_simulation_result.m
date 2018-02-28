function fit_arbiter = read_fit_arbiter_simulation_result(filename)

data_raw = int32(dlmread(filename, ' ')');

num_events = size(data_raw,2);

fit_arbiter.x = data_raw(1,:);
fit_arbiter.y = data_raw(2,:);


n = 3;
fit_arbiter.region3x3 = zeros(3,3,num_events);
fit_arbiter.valid3x3 = zeros(3,3,num_events);

for xx = 1:3
    for yy = 1:3
        fit_arbiter.valid3x3(yy,xx,:) = data_raw(n,:);
        n = n+1;
        fit_arbiter.region3x3(yy,xx,:) = data_raw(n,:);
        n = n+1;
    end
end