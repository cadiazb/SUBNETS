function [Params, dat, b5] = UpdateCursorOnLine(Params, dat, b5)
    global DEBUG
    if ~DEBUG    
        %% Sync
        b5 = bmi5_mmap(b5);

        %% Retreive readings form Labjack
        n = 1; %number of samples read from labjack
        Vin = 5; % Power supply [V]
        ZeroBalance = Vin*2e-3*0.6;
        Polarity = [1 1 1 1]';
        tao = 50;
        itmp = zeros(size(b5.isometricAIN_sensors_o,1), 1);

%         for ii = 1:n
            b5 = bmi5_mmap(b5); 
            itmp =  b5.isometricAIN_sensors_o;
%         end
        itmp = ((itmp./n) - Params.LoadCell.ZeroOffset) .* Polarity;
        itmp = itmp ./(Vin*2e-3);

    %     newForce = [itmp(1), itmp(3)];
        newForce(1) =  sign(itmp(1))*(log(1+abs(itmp(1))/tao)*1/log(1+1/tao));
        newForce(2) =  sign(itmp(3))*(log(1+abs(itmp(3))/tao)*1/log(1+1/tao));


        newPosX = min((b5.Frame_scale(1))*newForce(1)*(Params.LoadCellMax/Params.MaxForce) + b5.StartTarget_pos(1), ...
            b5.Frame_scale(1) + b5.StartTarget_pos(1));

        
        newPosY = min((b5.Frame_scale(2))*newForce(2)*(Params.LoadCellMax/Params.MaxForce) + b5.StartTarget_pos(2), ...
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
    else
        global forceTraces
        %% Sync
        b5 = bmi5_mmap(b5);
        
        Vin = 5; % Power supply [V]
        ZeroBalance = Vin*2e-3*0.6;
        tao = 50;
        
        n = 1; %number of samples read from labjack
        Polarity = [1 1 1 1]';
        
        itmp =  b5.isometricAIN_sensors_o;
        itmp = ((itmp./n) - Params.LoadCell.ZeroOffset) .* Polarity;
        itmp = itmp ./(Vin*2e-3);
        
        tmpIndex = find(forceTraces(1).ForceTrace(:,1) <= (b5.time_o - dat.TimeStart), 1, 'last');
        if tmpIndex>1
            tmpSmoothTrace = loadCellFilter(forceTraces(1).ForceTrace(1:tmpIndex, :)); %%%%%% FILTER
            newForce(1) =  sign(tmpSmoothTrace(tmpIndex,2))*(log(1+abs(tmpSmoothTrace(tmpIndex,2))/tao)*1/log(1+1/tao));
            newForce(2) =  sign(tmpSmoothTrace(tmpIndex,3))*(log(1+abs(tmpSmoothTrace(tmpIndex,3))/tao)*1/log(1+1/tao));
        else
            
            newForce(1) =  sign(itmp(1))*(log(1+abs(itmp(1))/tao)*1/log(1+1/tao));
            newForce(2) =  sign(itmp(3))*(log(1+abs(itmp(3))/tao)*1/log(1+1/tao));
        end
        
        newPosX = min((b5.Frame_scale(1))*newForce(1)*(Params.LoadCellMax/Params.MaxForce) + b5.StartTarget_pos(1), ...
            b5.Frame_scale(1) + b5.StartTarget_pos(1));

        
        newPosY = min((b5.Frame_scale(2))*newForce(2)*(Params.LoadCellMax/Params.MaxForce) + b5.StartTarget_pos(2), ...
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
end
