function output = format_output(result, params)

%calculates which results will be used, and which will be discarded
invalid = abs(result.a)>params.maxval | abs(result.b)>params.maxval | (abs(result.a)<params.minval & abs(result.b)<params.minval);

%pre-allocate memory
temp.a = result.a(invalid==0);
temp.b = result.b(invalid==0);
output.x = result.x(invalid==0);
output.y = result.y(invalid==0);
output.ts = result.ts(invalid==0);

%full precision result have been?
output.vx = temp.a./(temp.a.^2+temp.b.^2);
output.vy = temp.b./(temp.a.^2+temp.b.^2);