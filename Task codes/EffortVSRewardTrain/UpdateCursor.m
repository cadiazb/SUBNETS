function [Params, dat, b5] = UpdateCursor(Params, dat, b5)
    
    %% Sync
    b5 = bmi5_mmap(b5);
    
    %% Retreive readings form Labjack
    n = 250; %number of samples read from labjack
    Vin = 5; % Power supply [V]
    maxLoad = 50; % Load cell max [N]
    ZeroBalance = Vin*2e-3*0.002;
    tao = 5;
    itmp = zeros(size(b5.isometric_sensors_o,1), 1);
    
    for ii = 1:n
        b5 = bmi5_mmap(b5); 
        itmp = itmp - b5.isometric_sensors_o;
    end
    itmp = (itmp./n)./(Vin*2e-3);
    
%     newForce = [itmp(1), itmp(3)];
    newForce(1) = sign(itmp(1))*(log(1+abs(itmp(1))/tao)*1/log(1+1/tao));
    newForce(2) = sign(itmp(3))*(log(1+abs(itmp(3))/tao)*1/log(1+1/tao));
    
    switch dat.TrialType
        case {1 2 3}
            newPosX = (b5.Frame_scale(1)/2)*newForce(1) + b5.Frame_pos(1);
            newPosY = (b5.Frame_scale(2)/2)*newForce(2) + b5.Frame_pos(2);
        case {4 5 7}
            if dat.SmallEffortUp
                if newForce(2) > 0
                    newPosX = (b5.Frame_scale(1)/2)*newForce(1) + b5.Frame_pos(1);
                    newPosY = (b5.Frame_scale(2)/2)*newForce(2)*(50/dat.SmallEffort) + b5.Frame_pos(2);
                else
                    newPosX = (b5.Frame_scale(1)/2)*newForce(1) + b5.Frame_pos(1);
                    newPosY = (b5.Frame_scale(2)/2)*newForce(2)*(50/dat.BigEffort) + b5.Frame_pos(2);
                end
            else
                if newForce(2) < 0
                    newPosX = (b5.Frame_scale(1)/2)*newForce(1) + b5.Frame_pos(1);
                    newPosY = (b5.Frame_scale(2)/2)*newForce(2)*(50/dat.SmallEffort) + b5.Frame_pos(2);
                else
                    newPosX = (b5.Frame_scale(1)/2)*newForce(1) + b5.Frame_pos(1);
                    newPosY = (b5.Frame_scale(2)/2)*newForce(2)*(50/dat.BigEffort) + b5.Frame_pos(2);
                end
            end
        case {6 8 9}
            if dat.SmallEffortUp
                if dat.ShowSmallEffort
                    if newForce(2) > 0
                        newPosX = (b5.Frame_scale(1)/2)*newForce(1) + b5.Frame_pos(1);
                        newPosY = (b5.Frame_scale(2)/2)*newForce(2)*(50/dat.SmallEffort) + b5.Frame_pos(2);
                    else
                        newPosX = (b5.Frame_scale(1)/2)*newForce(1) + b5.Frame_pos(1);
                        newPosY = (b5.Frame_scale(2)/2)*newForce(2)*(50/dat.ReferenceEffort) + b5.Frame_pos(2);
                    end
                else
                    if newForce(2) > 0
                        newPosX = (b5.Frame_scale(1)/2)*newForce(1) + b5.Frame_pos(1);
                        newPosY = (b5.Frame_scale(2)/2)*newForce(2)*(50/dat.ReferenceEffort) + b5.Frame_pos(2);
                    else
                        newPosX = (b5.Frame_scale(1)/2)*newForce(1) + b5.Frame_pos(1);
                        newPosY = (b5.Frame_scale(2)/2)*newForce(2)*(50/dat.BigEffort) + b5.Frame_pos(2);
                    end
                end
            else
                if dat.ShowSmallEffort
                    if newForce(2) < 0
                        newPosX = (b5.Frame_scale(1)/2)*newForce(1) + b5.Frame_pos(1);
                        newPosY = (b5.Frame_scale(2)/2)*newForce(2)*(50/dat.SmallEffort) + b5.Frame_pos(2);
                    else
                        newPosX = (b5.Frame_scale(1)/2)*newForce(1) + b5.Frame_pos(1);
                        newPosY = (b5.Frame_scale(2)/2)*newForce(2)*(50/dat.ReferenceEffort) + b5.Frame_pos(2);
                    end
                else
                    if newForce(2) < 0
                        newPosX = (b5.Frame_scale(1)/2)*newForce(1) + b5.Frame_pos(1);
                        newPosY = (b5.Frame_scale(2)/2)*newForce(2)*(50/dat.ReferenceEffort) + b5.Frame_pos(2);
                    else
                        newPosX = (b5.Frame_scale(1)/2)*newForce(1) + b5.Frame_pos(1);
                        newPosY = (b5.Frame_scale(2)/2)*newForce(2)*(50/dat.BigEffort) + b5.Frame_pos(2);
                    end
                end
            end
            
    end
    
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

    
    %% Sync
    b5 = bmi5_mmap(b5);
end
