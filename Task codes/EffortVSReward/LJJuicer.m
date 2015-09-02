function [b5] = LJJuicer(Params, b5, juicerState)
% LJJuicer uses the digiatl outputs of LabJack to control the solenoid vale.
% Make sure to initialize LJ's digital outputs for this function to work.

% FOR DRAWING OBJECTS
DRAW_NONE     = 0;
DRAW_SUBJECT  = 1;
DRAW_OPERATOR = 2;
DRAW_BOTH     = 3;

    %% Sync
    b5 = bmi5_mmap(b5);
    
    %% Turn juicer ON/OFF based on input argument
    switch lower(juicerState)
        case 'on'
            b5.isometricDOUT_channels(Params.LJJuicerDOUT) = 1;
            b5.SolenoidOpen_draw       = DRAW_NONE;
        case 'off'
            b5.isometricDOUT_channels(Params.LJJuicerDOUT) = 0;
            b5.SolenoidOpen_draw       = DRAW_NONE;
        otherwise
            b5.isometricDOUT_channels(Params.LJJuicerDOUT) = 0;
            b5.SolenoidOpen_draw       = DRAW_NONE;
    end
    
    %% Sync
    b5 = bmi5_mmap(b5);
end
