%this file creates a LUT .coe where each address holds a value which
%indicates the number of '1's in the address
numfile = fopen(['ones', '.coe'], 'w');
fwrite(numfile, 'memory_initialization_radix = 10;');
fwrite(numfile, 10);
fwrite(numfile, 'memory_initialization_vector= ');
fwrite(numfile, 10);

for ii = 0:(2^9-1)
    binary = dec2bin(ii, 9);
    num_ones = sum(binary == '1');
    fwrite(numfile, num2str(num_ones));
    fwrite(numfile, ',');
    fwrite(numfile, 10);
end


fclose(numfile);
