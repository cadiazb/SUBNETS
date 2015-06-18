function [Params, dat, b5] = joystickTraining(Params, dat, b5, controlWindow)

global DEBUG
global SolenoidEnable QUIT_FLAG Solenoid_open;

% FOR DRAWING OBJECTS
DRAW_NONE     = 0;
DRAW_SUBJECT  = 1;
DRAW_OPERATOR = 2;
DRAW_BOTH     = 3;

%% Generate a StartTarget position
b5.StartTarget_pos = Params.WsCenter - [0, b5.Frame_scale(2)/2]; 

%% Draw Probe effort from vector
% Draw reward from 'Training vector' or from Adaptive Vector
% dat.ProbeEffort         = controlWindow.GetProbeTarget_pos() / b5.Frame_scale(2);
dat.ProbeEffort         = DrawFromVec(Params.EffortVector);

%% Generate ProbeTarget position
b5.ProbeTarget_pos 		= b5.StartTarget_pos + ...
                                [0,dat.ProbeEffort * b5.Frame_scale(2)] ...
                                + [0,0];
                            
b5.ProbeTargetTop_pos 		= b5.StartTarget_pos + ...
                                [0,Params.EffortVectorTop * b5.Frame_scale(2)] ...
                                + [0,0];                            
%% Generate the amounts of reward
% dat.ProbeReward = DrawFromVec(Params.RewardsVector);
dat.ProbeReward = 1000 * controlWindow.GetEarnedReward(); %[ms]
%% Misc stuff
dat.OutcomeID 	= 0;
dat.OutcomeStr 	= 'Success';

%% Hide all screen objects
b5.StartTarget_draw             = DRAW_NONE;
b5.Frame_draw                   = DRAW_NONE;
b5.BarOutline_draw              = DRAW_BOTH;
b5.FillingEffort_draw           = DRAW_BOTH;
b5.Pass_draw                    = DRAW_NONE;
b5.Cursor_draw                  = DRAW_NONE;
b5.ProbeTarget_draw             = DRAW_BOTH;
b5.ProbeTargetTop_draw          = DRAW_BOTH;

b5 = bmi5_mmap(b5);
%% 0. Temp play 'Opening' sound effect
if Params.OpeningSound.Enable && (Params.OpeningSound.Next < b5.time_o)
    [~, b5] = controlWindow.PlayCueandReward(Params, b5);
    b5 = LJJuicer(Params, b5, 'off');
    Params.OpeningSound.Counter = Params.OpeningSound.Counter + 1;
    
    if Params.OpeningSound.Counter < Params.OpeningSound.Repeats
        Params.OpeningSound.Next = b5.time_o + Params.OpeningSound.Intervals(1);
    else
        Params.OpeningSound.Next = b5.time_o + 60*Params.OpeningSound.Intervals(2);
        Params.OpeningSound.Counter = 0;
    end
end
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
    b5.FillingEffortHor_draw   = DRAW_BOTH;
    b5.xSensitivity_draw       = DRAW_BOTH;
    b5.ySensitivity_draw       = DRAW_BOTH;
%     b5.SolenoidOpen_draw       = DRAW_NONE;
%     b5.Pass_draw                = DRAW_BOTH;
    b5.ProbeTarget_draw         = DRAW_BOTH;
    b5.ProbeTargetTop_draw      = DRAW_BOTH;
    
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
        
        % Update sensitivites rectangle
        b5.ySensitivity_scale = [b5.BarOutline_scale(1),...
                2*Params.StartTarget.Win(2)];
        b5.ySensitivity_pos       = Params.WsCenter - [0, b5.Frame_scale(2)/2];
        
        b5.xSensitivity_scale = [2*Params.StartTarget.Win(1),... 
                b5.xSensitivity_scale(2)];
        b5.xSensitivity_pos(1) = Params.WsCenter(1);       
        
        
        b5 = bmi5_mmap(b5);
        
		% Check for acquisition of a reach target
        posOk = TrialInBox(pos,b5.StartTarget_pos,Params.StartTarget.Win);
        posProbeOk 	= pos(2) >= b5.ProbeTargetTop_pos(2);
        posPassOk 	= pos(2) <= b5.ProbeTarget_pos(2);
        
        if ~posOk
            if (abs(pos(1) - b5.StartTarget_pos(1)) > Params.StartTarget.Win(1)) %|| ((pos(2) - b5.StartTarget_pos(2)) < 0)
                posOk = ~posOk;
            end     
        end
        
%         if ~posOk
%             if (b5.ProbeTarget_pos(2) > b5.StartTarget_pos(2)) && (b5.ProbeTarget_pos(2) > pos(2))
%                 posOk = ~posOk;
%             end     
%         end
%         
%         if ~posOk
%             if (b5.ProbeTarget_pos(2) < b5.StartTarget_pos(2)) && (b5.ProbeTarget_pos(2) < pos(2))
%                 posOk = ~posOk;
%             end     
%         end
        
        if ~posOk && isempty(dat.ReactionTime)
            dat.ReactionTime = b5.time_o - t_start;
        end
        
        if ~isempty(dat.ReactionTime) && (posPassOk) && ...
                (abs(pos(1) - b5.StartTarget_pos(1)) < Params.StartTarget.Win(1))
            dat.TrialChoice = 'Pass';
            done = true;
            dat.MovementTime = b5.time_o - t_start - dat.ReactionTime;
            dat.OutcomeID 	= 0;
            dat.OutcomeStr 	= 'success';
        end
        
        if ~isempty(dat.ReactionTime) && (posProbeOk) && ...
                (abs(pos(1) - b5.StartTarget_pos(1)) < Params.StartTarget.Win(1))
            done = true;
            dat.MovementTime = b5.time_o - t_start - dat.ReactionTime;
            dat.TrialChoice = 'Probe Effort';
            dat.OutcomeID 	= 0;
            dat.OutcomeStr 	= 'Succes';
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
            if QUIT_FLAG || ((b5.time_o - t_start) > Params.ReactionTimeDelay)
                dat.ReactionTime = b5.time_o - t_start;
                dat.TrialChoice = '';
                dat.MovementTime = NaN;
                done            = true;
                dat.OutcomeID 	= 4;
                dat.OutcomeStr 	= 'cancel @ reaction';
            end

        if ~SolenoidEnable
            tmpJuiceState = 'off';
        end


        if Solenoid_open
            b5 = LJJuicer(Params, b5, 'on');
        elseif strcmp(tmpJuiceState, 'off')
            b5 = LJJuicer(Params, b5, tmpJuiceState);
        end
	end
end

%% Trial outcome and variable adaptation

if dat.OutcomeID == 0
    if strcmp(dat.TrialChoice, 'Probe Effort')
        dat.ActualReward = dat.ProbeReward*Params.BiasingMulti;
    else
        dat.ActualReward = dat.ProbeReward;
    end
    
    fprintf('Choice\t\t%s \n',dat.TrialChoice);
    fprintf('Trial reward\t\t%.0f [ms]\n',dat.ActualReward);
    
    % Give juice reward
    [Params, b5] = blinkShape(Params, b5, {'FillingEffort', 'ProbeTarget', 'ProbeTargetTop'}, [12 12 12], [0.75 0.75 0.75]);
    b5.RewardTone_play_io = 1;
    b5 = LJJuicer(Params, b5, 'on');
    [Params, dat, b5] = UpdateCursorOnLine(Params, dat, b5); %b5 = bmi5_mmap(b5);
    juiceStart = b5.time_o;
    while (b5.time_o - juiceStart) < (dat.ActualReward / 1000)
        [Params, dat, b5] = UpdateCursorOnLine(Params, dat, b5); %b5 = bmi5_mmap(b5);
    end
    if ~Solenoid_open
        b5 = LJJuicer(Params, b5, 'off');
    end
    dat.JuiceON = juiceStart;
    dat.JuiceOFF = b5.time_o;
    controlWindow.message(['Last reward ' datestr(now)]);
    
    % Turn objects on screen off
    b5 = b5ObjectsOff(b5);
    b5 = bmi5_mmap(b5);
    % Pause after reward
    startPause = b5.time_o;
    %if dat.FinalCursorPos(2) < b5.ProbeTargetTop_pos(2)
        while (b5.time_o - startPause) < (Params.InterTrialDelay)
            [Params, dat, b5] = UpdateCursorOnLine(Params, dat, b5); %b5 = bmi5_mmap(b5);
        end
    %end
    
    % Reset Opening sound effect
    Params.OpeningSound.Next = b5.time_o + 60*Params.OpeningSound.Intervals(2);
    Params.OpeningSound.Counter = 0;
    
    % Make next trial a bit harder
    if strcmp(dat.TrialChoice, 'Pass')
        Params.EffortVector = ...
            max(-0.6,(b5.ProbeTarget_pos(2)-b5.StartTarget_pos(2)-1)/b5.Frame_scale(2));
    end
    if strcmp(dat.TrialChoice, 'Probe Effort')
        Params.EffortVectorTop = ...
            min(1,(b5.ProbeTargetTop_pos(2)-b5.StartTarget_pos(2)+1)/b5.Frame_scale(2));
        
        b5.xSensitivity_scale(1) = max(60,b5.xSensitivity_scale(1) - 10);
        controlWindow.SetSensitivity(b5.xSensitivity_scale(1)/2,b5.ySensitivity_scale(2)/2);
    end
else
    Params.EffortVector = ...
        min(-0.3,(b5.ProbeTarget_pos(2)-b5.StartTarget_pos(2)+2)/b5.Frame_scale(2));
    Params.EffortVectorTop = ...
        max(0.15,(b5.ProbeTargetTop_pos(2)-b5.StartTarget_pos(2)-2)/b5.Frame_scale(2));
    
    b5.xSensitivity_scale(1) = min(300,b5.xSensitivity_scale(1) + 5);
    controlWindow.SetSensitivity(b5.xSensitivity_scale(1)/2,b5.ySensitivity_scale(2)/2);
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