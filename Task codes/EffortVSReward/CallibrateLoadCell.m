function [Params, b5] = CallibrateLoadCell(Params, b5)
    %% Geat 10000 samples from labjack
    n = 10000; %number of samples read from labjack
    Params.LoadCell.ZeroOffset = [0 0 0 0]';
    
    itmp = zeros(size(b5.isometricAIN_sensors_o,1), 1);
    tic
    for ii = 1:n
        b5 = bmi5_mmap(b5); 
        itmp = itmp + b5.isometricAIN_sensors_o;
    end
    toc
    
    Params.LoadCell.ZeroOffset = itmp./n;
    
end