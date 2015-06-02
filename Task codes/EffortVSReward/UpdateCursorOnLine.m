function [Params, dat, b5] = UpdateCursorOnLine(Params, dat, b5)
    
    %% Sync
    b5 = bmi5_mmap(b5);
    
    %% Retreive readings form Labjack
    n = 100; %number of samples read from labjack
    Vin = 5; % Power supply [V]
    ZeroBalance = Vin*2e-3*0.002;
    tao = 50;
    itmp = zeros(size(b5.isometricAIN_sensors_o,1), 1);
    
    for ii = 1:n
        b5 = bmi5_mmap(b5); 
        itmp = itmp - b5.isometricAIN_sensors_o;
    end
    itmp = ((itmp./n) - Params.LoadCell.ZeroOffset)./(Vin*2e-3);
    
%     newForce = [itmp(1), itmp(3)];
    newForce(2) = -sign(itmp(1))*(log(1+abs(itmp(1))/tao)*1/log(1+1/tao));
    newForce(1) =  sign(itmp(3))*(log(1+abs(itmp(3))/tao)*1/log(1+1/tao));

    if newForce(1) >= 0
        newPosX = min((b5.Frame_scale(1))*newForce(1)*(Params.LoadCellMax/Params.MaxForce) + b5.StartTarget_pos(1), ...
            b5.Frame_scale(1) + b5.StartTarget_pos(1));
    else
        newPosX = min((b5.Frame_scale(1))*newForce(1)*(Params.LoadCellMax/Params.PassSensitivity) + b5.StartTarget_pos(1), ...
            b5.Frame_scale(1) + b5.StartTarget_pos(1));
    end

    newPosY = min((b5.Frame_scale(2))*newForce(2) + b5.StartTarget_pos(2), ...
        b5.Frame_scale(2) + b5.StartTarget_pos(2));
    %% Update cursor position
    if abs(newPosX - b5.Cursor_pos(1)) > ZeroBalance
        b5.Cursor_pos(1) = newPosX;
    elseif abs(newPosX) < ZeroBalance
         b5.Cursor_pos(1) = 0;
    end

    if abs(newPosY - b5.Cursor_pos(2)) > ZeroBalance
        b5.Cursor_pos(2) = newPosY;
    elseif abs(newPosY) < ZeroBalance
        b5.Cursor_pos(2) = 0;
    end
    
    %% Collect kinematics
    
    tmpIndex = find(isnan(dat.ForceTrace(:,1)), 1, 'first');
    dat.ForceTrace(tmpIndex,1)   = b5.isometricAIN_time_o;
    dat.ForceTrace(tmpIndex,2)   = itmp(1);
    dat.ForceTrace(tmpIndex,3)   = itmp(3);
    dat.ForceTrace(tmpIndex,4:5) = newForce; 

    
    %% Sync
    b5 = bmi5_mmap(b5);
end
