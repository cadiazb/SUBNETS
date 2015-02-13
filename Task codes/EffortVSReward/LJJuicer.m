function [b5] = LJJuicer(b5, juicerState)
% LJJuicer uses the digiatl outputs of LabJack to control the solenoid vale.
% Make sure to initialize LJ's digital outputs for this function to work.
    %% Sync
    b5 = bmi5_mmap(b5);
    
    %% Turn juicer ON/OFF based on input argument
    b5.isometricDOUT_channels(Params.LJJuicerDOUT) = logical(juicerState);
    
    %% Sync
    b5 = bmi5_mmap(b5);
end
