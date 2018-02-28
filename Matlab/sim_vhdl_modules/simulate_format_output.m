function output = simulate_format_output(result, params)

%calculates which results will be used, and which will be discarded
invalid = abs(result.a)>params.maxval | abs(result.b)>params.maxval | (abs(result.a)<params.minval & abs(result.b)<params.minval);

%pre-allocate memory
temp.a = result.a(invalid==0);
temp.b = result.b(invalid==0);
output.x = result.x(invalid==0);
output.y = result.y(invalid==0);
output.ts = result.ts(invalid==0);

% %what would the full precision result have been?
% output_full.vx = temp.a./(temp.a.^2+temp.b.^2);
% output_full.vy = temp.b./(temp.a.^2+temp.b.^2);

%these are the steps as performed in FPGA to obtain 1/(a^2+b^2)
ab2 = floor(temp.a.^2 + temp.b.^2);
inv_ab2 = floor(2^params.div_scale_bits./ab2);

%these are the steps as performed in FPGA to obtain (a)(1/(a^2+b^2)) and (b)(1/(a^2+b^2))
%the results will be very small fractions, which are represented by scaling
%by "params.div_scale_bits" and using integers
output.vx = temp.a.*inv_ab2;%/2^div_scale_bits
output.vy = temp.b.*inv_ab2;%/2^div_scale_bits

output.vx = floor(output.vx/2^params.truncate_bits);
output.vy = floor(output.vy/2^params.truncate_bits);