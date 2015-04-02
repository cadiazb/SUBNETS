function [Params, dat, b5] = joystickTraining(Params, dat, b5, controlWindow)

global DEBUG
global SolenoidEnable QUIT_FLAG;

% FOR DRAWING OBJECTS
DRAW_NONE     = 0;
DRAW_SUBJECT  = 1;
DRAW_OPERATOR = 2;
DRAW_BOTH     = 3;

%% Generate a StartTarget position
b5.StartTarget_pos = Params.WsCenter - [0, b5.Frame_scale(2)/2]; 

%% Draw Probe effort from vector
% Draw reward from 'Training vector' or from Adaptive Vector
dat.ProbeEffort         = DrawFromVec(Params.EffortVector);

%% Generate ProbeTarget position
b5.ProbeTarget_pos 		= b5.StartTarget_pos + ...
                                [0,dat.ProbeEffort * b5.Frame_scale(2)] ...
                                + [100,0];

%% Generate the amounts of reward
dat.ProbeReward = DrawFromVec(Params.RewardsVector);

%% Misc stuff
dat.OutcomeID 	= 0;
dat.OutcomeStr 	= 'Success';

%% Hide all screen objects
b5.StartTarget_draw             = DRAW_NONE;
b5.Frame_draw                   = DRAW_NONE;
b5.BarOutline_draw              = DRAW_NONE;
b5.FillingEffort_draw           = DRAW_NONE;
b5.Pass_draw                    = DRAW_NONE;
b5.Cursor_draw                  = DRAW_NONE;
b5.ProbeTarget_draw             = DRAW_NONE;

b5 = bmi5_mmap(b5);
%% 1. ACQUIRE START TARGET
b5.StartTarget_draw = DRAW_NONE;
b5 = bmi5_mmap(b5);

done   = true;
gotPos = false;

t_start = b5.time_o;
while ~done

%     pos = b5.Cursor_pos;
    [Params, dat, b5] = UpdateCursorOnLine(Params, dat, b5); % syncs b5 twice
        pos = b5.Cursor_pos;
        dat.FinalCursorPos = [0,pos(2)];
        if (dat.FinalCursorPos(2)-b5.StartTarget_pos(2)) >= 0
            b5.FillingEffort_scale = [b5.BarOutline_scale(1),...
                dat.FinalCursorPos(2)-b5.StartTarget_pos(2)];
            b5.FillingEffort_pos       = Params.WsCenter - [0, b5.Frame_scale(2)/2] + ...
                    [0, b5.FillingEffort_scale(2)/2];
        else
            b5.FillingEffort_scale = [b5.BarOutline_scale(1),...
                -max((dat.FinalCursorPos(2)-b5.StartTarget_pos(2)), ...
                (b5.Pass_pos(2) - b5.StartTarget_pos(2)))];
            b5.FillingEffort_pos       = Params.WsCenter - [0, b5.Frame_scale(2)/2] - ...
                    [0, b5.FillingEffort_scale(2)/2];
        end
        
	% Check for acquisition of start target
  	posOk = TrialInBox(pos, b5.StartTarget_pos, Params.StartTarget.Win);

    if posOk
        if ~gotPos
            gotPos = true;
            starthold = b5.time_o;
        end
        if (b5.time_o - starthold) > Params.StartTarget.Hold
			done = true;   % Reach to start target OK
        end
    end

	% Once start target is acquired, it must remain acquired
    if ~posOk  
        gotPos = false;
        if (b5.time_o - t_start) > Params.TimeoutReachStartTarget
            done            = true;
            dat.OutcomeID   = 1;
            dat.OutcomeStr	= 'cancel @ start';
        end
    end
    
    % update hand
    [Params, dat, b5] = UpdateCursorOnLine(Params, dat, b5); % syncs b5 twice

end

%% 2. CHECK FOR Y-AXIS MOVEMENT ON LOAD CELL
if ~dat.OutcomeID
    b5.BarOutline_draw          = DRAW_BOTH;
    b5.FillingEffort_draw       = DRAW_BOTH;
    b5.FillingEffortHor_draw       = DRAW_BOTH;
%     b5.Pass_draw                = DRAW_BOTH;
%     b5.ProbeTarget_draw         = DRAW_BOTH;
    
    b5.GoTone_play_io = 1;
    b5.FillingEffort_scale(2) = 0;
    b5.FillingEffort_pos       = Params.WsCenter - [0, b5.Frame_scale(2)/2];
    b5 = bmi5_mmap(b5);
    
    b5.FillingEffortHor_scale(1) = 0;
    b5.FillingEffortHor_pos       = Params.WsCenter - [0, b5.Frame_scale(2)/2];
    b5 = bmi5_mmap(b5);
    
    dat.GoCue_time_o = b5.GoTone_time_o;

	done            = false;
    dat.FinalCursorPos = b5.StartTarget_pos;
    tmpJuiceState = 'off';
    tmpJuiceMin = 0.05; %[s]
    tmpJuiceMax = 0.1; %[s]
    tmpJuice_start = b5.time_o;
    tmpJuice_stop = b5.time_o;
    tmpJuice_NextStart = b5.time_o;
    
	t_start = b5.time_o;
    [Params.StartTarget.Win(1), Params.StartTarget.Win(2)] = controlWindow.GetSensitivity();
	while ~done
        drawnow;
        [Params.StartTarget.Win(1), Params.StartTarget.Win(2)] = controlWindow.GetSensitivity();
        [Params, dat, b5] = UpdateCursorOnLine(Params, dat, b5); % syncs b5 twice
        pos = b5.Cursor_pos;
        dat.FinalCursorPos = [0,pos(2)];
        % Observe Y-axis force
        if (dat.FinalCursorPos(2)-b5.StartTarget_pos(2)) >= 0
            b5.FillingEffort_scale = [b5.BarOutline_scale(1),...
                dat.FinalCursorPos(2)-b5.StartTarget_pos(2)];
            b5.FillingEffort_pos       = Params.WsCenter - [0, b5.Frame_scale(2)/2] + ...
                    [0, b5.FillingEffort_scale(2)/2];
        else
            b5.FillingEffort_scale = [b5.BarOutline_scale(1),...
                -max((dat.FinalCursorPos(2)-b5.StartTarget_pos(2)), ...
                (b5.Pass_pos(2) - b5.StartTarget_pos(2)))];
            b5.FillingEffort_pos       = Params.WsCenter - [0, b5.Frame_scale(2)/2] - ...
                    [0, b5.FillingEffort_scale(2)/2];
        end
        
        % Observe X-axis force
        if (pos(1)-b5.StartTarget_pos(1)) >= 0
            b5.FillingEffortHor_scale = [pos(1)-b5.StartTarget_pos(1),... 
                b5.FillingEffortHor_scale(2)];
            b5.FillingEffortHor_pos(1) = Params.WsCenter(1) + ...
                    b5.FillingEffortHor_scale(1)/2;
        else
            b5.FillingEffortHor_scale = [-(pos(1)-b5.StartTarget_pos(1)),...
                b5.FillingEffortHor_scale(2)];
            b5.FillingEffortHor_pos(1)       = Params.WsCenter(1) - ...
                    b5.FillingEffortHor_scale(1)/2;
        end
%         if b5.FillingEffort_scale(2) < 25
%             b5.FillingEffort_scale(2) = 0;
%             b5.FillingEffort_pos       = Params.WsCenter - [0, b5.Frame_scale(2)/2] + ...
%                     [0, b5.FillingEffort_scale(2)/2];
%         end
        
        b5 = bmi5_mmap(b5);
        
		% Check for acquisition of a reach target
        posOk = TrialInBox(pos,b5.StartTarget_pos,Params.StartTarget.Win);
        posProbeOk 	= (pos(2) >= b5.ProbeTarget_pos(2));
        posPassOk 	= ((pos(2) - b5.StartTarget_pos(2)) <=...
            -(b5.ProbeTarget_pos(2) - b5.StartTarget_pos(2)));
        
        if ~posOk
            if abs(pos(1) - b5.StartTarget_pos(1)) > Params.StartTarget.Win(1) 
                posOk = ~posOk;
            end
        end
        
        if ~posOk && isempty(dat.ReactionTime)
            dat.ReactionTime = b5.time_o - t_start;
        end
        if ~posOk
            b5.ProbeTarget_draw         = DRAW_BOTH;
%             if ((b5.time_o - tmpJuice_stop) > tmpJuiceMin) && strcmp(tmpJuiceState, 'off')
            if strcmp(tmpJuiceState, 'off')
                tmpJuiceState = 'on';
%                 if (b5.time_o - tmpJuice_start) > (tmpJuiceMax+1)
                    tmpJuice_start = b5.time_o;
%                 end
            end
        else
            b5.ProbeTarget_draw         = DRAW_NONE;
%             if ((b5.time_o - tmpJuice_start) > tmpJuiceMin)
                tmpJuiceState = 'off';
%                 if (b5.time_o - tmpJuice_start) > (tmpJuiceMax+2)
                    tmpJuice_stop = b5.time_o;
%                 end
%             end
        end
        
        if ~isempty(dat.ReactionTime) && (posPassOk || ~posOk)
%             dat.TrialChoice = 'Pass';
%             done = true;
%             dat.OutcomeID 	= 0;
%             dat.OutcomeStr 	= 'success';
        end
        
        if ~isempty(dat.ReactionTime) && (posProbeOk || posOk)
%             done = true;
%             dat.TrialChoice = 'Probe Effort';
%             dat.OutcomeID 	= 0;
%             dat.OutcomeStr 	= 'Succes';
        end

		% check for TIMEOUT
        if ~isempty(dat.ReactionTime) && ~done
            if (b5.time_o - t_start - dat.ReactionTime) > Params.TimeoutReachTarget
%                 dat.MovementTime = b5.time_o - t_start - dat.ReactionTime;
%                 dat.TrialChoice = '';
%                 done            = true;
%                 dat.OutcomeID 	= 4;
%                 dat.OutcomeStr 	= 'cancel @ reach movement timeout';
            end
        end
        
%         if isempty(dat.ReactionTime)
%             if (b5.time_o - t_start) > Params.ReactionTimeDelay
            if QUIT_FLAG
                dat.ReactionTime = b5.time_o - t_start;
                dat.TrialChoice = '';
                dat.MovementTime = NaN;
                done            = true;
                dat.OutcomeID 	= 4;
                dat.OutcomeStr 	= 'cancel @ reaction';
            end
%         end
        % Temporarily give juice right away
        if ~SolenoidEnable
            tmpJuiceState = 'off';
            b5.ProbeTarget_draw         = DRAW_NONE;
        end
        b5 = LJJuicer(Params, b5, tmpJuiceState);
        if SolenoidEnable
            while ((b5.time_o - tmpJuice_start) < tmpJuiceMax)
                b5 = bmi5_mmap(b5);
            end
        end
        tmpJuiceState = 'off';
        b5.ProbeTarget_draw         = DRAW_NONE;
        b5 = LJJuicer(Params, b5, tmpJuiceState);
        tmpJuice_stop = b5.time_o;
        
        % Pause controlled by force applied on load cell
        if ~posOk && SolenoidEnable
%             if abs(pos(1) - b5.StartTarget_pos(1))>abs(pos(2) - b5.StartTarget_pos(2))
% %                 tmpForce = sqrt((pos(1) - b5.StartTarget_pos(1))^2 + (pos(2)- b5.StartTarget_pos(2))^2);
%                 tmpForce = abs((pos(1) - b5.StartTarget_pos(1)));
%                 tmpJuice_Freq = (tmpForce * 10 /300) + 0;
%             end
            
%             if abs(pos(2) - b5.StartTarget_pos(2))>abs(pos(1)- b5.StartTarget_pos(1))
%                 tmpForce = sqrt((pos(1) - b5.StartTarget_pos(1))^2 + (pos(2)- b5.StartTarget_pos(2))^2);
                tmpForce = abs((pos(2)- b5.StartTarget_pos(2)));
                tmpJuice_Freq = (tmpForce * 40 /300) + 0;
%             end
            
            while((b5.time_o - tmpJuice_stop) < (1/tmpJuice_Freq))
                b5 = bmi5_mmap(b5);
            end
        end
        
%         if strcmp(tmpJuiceState, 'on') && SolenoidEnable && ((b5.time_o - tmpJuice_start) > tmpJuiceMax)
%             controlWindow.SolenoidEnable();
%         end
	end
end

%% Trial outcome and variable adaptation

if dat.OutcomeID == 0
    dat.ActualReward = dat.ProbeReward;
    
    fprintf('Choice\t\t%s \n',dat.TrialChoice);
    fprintf('Trial reward\t\t%d \n',dat.ActualReward);
	
    b5.RewardTone_play_io = 1;
    
    % Give juice reward
    b5 = LJJuicer(Params, b5, 'on');
    b5 = bmi5_mmap(b5);
    juiceStart = b5.time_o;
    while (b5.time_o - juiceStart) < (dat.ActualReward / 1000)
        b5 = bmi5_mmap(b5);
    end
    b5 = LJJuicer(Params, b5, 'off');
    dat.JuiceON = juiceStart;
    dat.JuiceOFF = b5.time_o;
end

b5 = bmi5_mmap(b5);

%Clean screen
% b5.StartTarget_draw             = DRAW_NONE;
% b5.Frame_draw                   = DRAW_NONE;
% b5.BarOutline_draw              = DRAW_NONE;
% b5.FillingEffort_draw           = DRAW_NONE;
% b5.Pass_draw                    = DRAW_NONE;
% b5.Cursor_draw                  = DRAW_NONE;
% b5.ProbeTarget_draw             = DRAW_NONE;

%%% XXX TODO: NEED WAY TO LOG (MORE) INTERESTING TRIAL EVENTS

end