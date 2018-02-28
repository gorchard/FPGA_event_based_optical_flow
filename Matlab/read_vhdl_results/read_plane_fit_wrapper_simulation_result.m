function [refit, result] = read_plane_fit_wrapper_simulation_result(filename)

data_raw = int32(dlmread(filename, ' ')');
channel = data_raw(1,:);
refit.x = data_raw(2,channel==0);
refit.y = data_raw(3,channel==0);
n = 4;
refit.valid3x3 = zeros(3,3,sum(channel==0));
refit.region3x3 = zeros(3,3,sum(channel==0));
for xx = 1:3
    for yy = 1:3
        refit.valid3x3(yy,xx,:) = data_raw(n,channel==0);
        n = n+1;
        refit.region3x3(yy,xx,:) = data_raw(n,channel==0);
        n = n+1;
    end
end

result.x = data_raw(2,channel==1);
result.y = data_raw(3,channel==1);
result.a = data_raw(4,channel==1);
result.b = data_raw(5,channel==1);