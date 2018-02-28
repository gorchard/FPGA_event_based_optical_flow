function output = read_format_output_simulation_result(filename)
data_raw = int32(dlmread(filename, ' ')');
output.x = data_raw(1,:);
output.y = data_raw(2,:);
output.vx = data_raw(3,:);
output.vy = data_raw(4,:);
