function [Params, dat, b5] = RewardEffortTrial(Params, dat, b5, controlWindow)

global DEBUG
global SolenoidEnable QUIT_FLAG Solenoid_open;

% FOR DRAWING OBJECTS
DRAW_NONE     = 0;
DRAW_SUBJECT  = 1;
DRAW_OPERATOR = 2;
DRAW_BOTH     = 3;

%% Generate a StartTarget position
b5.StartTarget_pos = Params.StartTarget_pos;

%% store effort
dat.ActualEffort(1)     = dat.UpEffort;
dat.ActualEffort(2)     = dat.DownEffort;

%% Generate DownTarget position

% choose which target to draw and assign position to OneTarget and WrongWay
dat.TrialChoiceID       = randi([0 1]);
if dat.TrialChoiceID==0 % 0 means down
    b5.OneTarget_pos 		= Params.DownTarget_pos;
    b5.WrongWay_pos         = b5.StartTarget_pos + [0 (b5.StartTarget_scale(2)+b5.WrongWay_scale(2))/2];
    TargetHoldTime          = Params.HoldDown;
else
    b5.OneTarget_pos 		= Params.UpTarget_pos;
    b5.WrongWay_pos         = b5.StartTarget_pos - [0 (b5.StartTarget_scale(2)+b5.WrongWay_scale(2))/2];
    TargetHoldTime          = Params.HoldUp;
end


%% Misc stuff
dat.OutcomeID 	= 0;
dat.OutcomeStr 	= 'Success';

%% Hide all screen objects
b5.StartTarget_draw             = DRAW_NONE;
b5.Frame_draw                   = DRAW_NONE;
b5.BarOutline_draw              = DRAW_NONE;
b5.Cursor_draw                  = DRAW_NONE;
b5.DownTarget_draw              = DRAW_NONE;
b5.UpTarget_draw                = DRAW_NONE;
b5.OneTarget_draw               = DRAW_NONE;
b5.WrongWay_draw                = DRAW_NONE;


b5 = bmi5_mmap(b5);

%% 1. ACQUIRE START TARGET
b5.StartTarget_draw = DRAW_BOTH;
b5.Cursor_draw      = DRAW_BOTH;
b5 = bmi5_mmap(b5);

done   = false;
gotPos = false;
b5.BarOutline_draw              = DRAW_NONE;

t_start = b5.time_o;
while ~done
    
    %pos = b5.Cursor_pos;
    
    pos = b5.Cursor_pos;
    dat.FinalCursorPos = [0,pos(2)];
    
    % Check for acquisition of start target
    posOk = TrialInBox(pos, b5.Cursor_scale, b5.StartTarget_pos, Params.StartTarget.Win);
    
    
    if posOk
        if ~gotPos
            gotPos = true;
            starthold = b5.time_o;
        end
        
        %Show features on screen when MP lets go
        b5.StartTarget_draw             = DRAW_BOTH;
        b5.BarOutline_draw              = DRAW_BOTH;
%         b5.xSensitivity_draw            = DRAW_NONE;
%         b5.ySensitivity_draw            = DRAW_NONE;
        
        if (b5.time_o - starthold) > Params.StartTarget.Hold
            done = true;   % Reach to start target OK
        end
    end

	% Once start target is acquired, it must remain acquired
    if ~posOk
        if gotPos
            gotPos = false;
            done            = true;
            dat.OutcomeID   = 2;
            dat.OutcomeStr	= 'cancel @ start hold';
            b5 = b5ObjectsOff(b5);
        else
            if (b5.time_o - t_start) > Params.TimeoutReachStartTarget
                done            = true;
                dat.OutcomeID   = 1;
                dat.OutcomeStr	= 'cancel @ start';
            end
        end
    end
    
    % update hand
    [Params, dat, b5] = UpdateCursorEffort(Params, dat, b5); % syncs b5 twice

end

%% 2. CHECK FOR Y-AXIS MOVEMENT ON LOAD CELL
if ~dat.OutcomeID
    b5.BarOutline_draw          = DRAW_BOTH;
    b5.Cursor_draw              = DRAW_BOTH;
    b5.StartTarget_draw             = DRAW_NONE;
%     b5.xSensitivity_draw       = DRAW_NONE;
%     b5.ySensitivity_draw       = DRAW_NONE;
    b5.OneTarget_draw           = DRAW_BOTH;
    b5.WrongWay_draw            = DRAW_NONE;
    

	done            = false;
    dat.FinalCursorPos = b5.StartTarget_pos;
    tmpJuiceState = 'off';

    gotTarget = false;
    
	t_start = b5.time_o;

    while ~done
        drawnow;
        [Params, dat, b5] = UpdateCursorEffort(Params, dat, b5); % syncs b5 twice
        pos = b5.Cursor_pos;
        dat.FinalCursorPos = [0,pos(2)];
        
        b5 = bmi5_mmap(b5);
        
        % Check for acquisition of a reach target
        posOk = TrialInBox(pos,b5.Cursor_scale,b5.StartTarget_pos,Params.StartTarget.Win);
        posTargetOk = TrialInBox(pos,b5.Cursor_scale,b5.OneTarget_pos,b5.OneTarget_scale/2);
        posWrongWay = TrialInBox(pos,b5.Cursor_scale,b5.WrongWay_pos,b5.WrongWay_scale/2);
        
        if ~posOk && isempty(dat.ReactionTime)
            dat.ReactionTime = b5.time_o - t_start;
        end
        
        if ~gotTarget && (posTargetOk)
            targethold = b5.time_o;
            gotTarget=true;
        end
        
        % check if lost target
        if gotTarget && ~done && ~(posTargetOk)
            dat.OutcomeID = 6;
            dat.OutcomeStr = 'Failed to hold target';
            done = true;
            gotTarget = false;
        end
        
        % check if wrong way
        if posWrongWay
            dat.OutcomeID = 5;
            dat.OutcomeStr = 'Wrong way';
            done = true;
            gotTarget = false;
        end
        
        if ~isempty(dat.ReactionTime) && (dat.TrialChoiceID==0) && (posTargetOk)
            dat.TrialChoice = 'Down';
            if (b5.time_o - targethold) > TargetHoldTime
                done = true;   % Reach to target OK
                dat.MovementTime = b5.time_o - t_start - dat.ReactionTime;
                dat.OutcomeID 	= 0;
                dat.OutcomeStr 	= 'Success';
            end
        end
        
        if ~isempty(dat.ReactionTime) && (dat.TrialChoiceID==1) && (posTargetOk)
            dat.TrialChoice = 'Up';
            if (b5.time_o - targethold) > TargetHoldTime
                done = true;   % Reach to target OK
                dat.MovementTime = b5.time_o - t_start - dat.ReactionTime;
                dat.OutcomeID 	= 0;
                dat.OutcomeStr 	= 'Succes';
            end
        end
        
        if QUIT_FLAG || (((b5.time_o - t_start) > Params.ReactionTimeDelay) && ~gotTarget)
            dat.ReactionTime = b5.time_o - t_start;
            dat.TrialChoice = '';
            dat.MovementTime = NaN;
            done            = true;
            dat.OutcomeID 	= 4;
            dat.OutcomeStr 	= 'Cancel @ reaction';
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

if dat.OutcomeID == 0 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    if strcmp(dat.TrialChoice, 'Up')
        dat.ActualReward = dat.UpReward + random(Params.RandDist);
    else
        dat.ActualReward = dat.DownReward + random(Params.RandDist);
    end
    
    fprintf('Choice\t\t%s \n',dat.TrialChoice);
    fprintf('Trial reward\t\t%.0f [ms]\n',dat.ActualReward);
    
    % Give juice reward
    b5 = LJJuicer(Params, b5, 'on');
    [Params, dat, b5] = UpdateCursorEffort(Params, dat, b5); %b5 = bmi5_mmap(b5);
    juiceStart = b5.time_o;
    while (b5.time_o - juiceStart) < (dat.ActualReward / 1000)
        [Params, dat, b5] = UpdateCursorEffort(Params, dat, b5); %b5 = bmi5_mmap(b5);
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
%     % Pause after reward
%     startPause = b5.time_o;
%     %if dat.FinalCursorPos(2) < b5.UpTarget_pos(2)
%         while (b5.time_o - startPause) < (Params.InterTrialDelay)
%             [Params, dat, b5] = UpdateCursorEffort(Params, dat, b5); %b5 = bmi5_mmap(b5);
%         end
%     %end
    


else
    %Clean screen
    % Turn objects on screen off
    b5 = b5ObjectsOff(b5);
    b5 = bmi5_mmap(b5);
    % Pause after fail reach
    if dat.OutcomeID == 5 %Wrong choice
        startPause = b5.time_o;
        while (b5.time_o - startPause) < (Params.WrongChoiceDelay)
            [Params, dat, b5] = UpdateCursorEffort(Params, dat, b5); %b5 = bmi5_mmap(b5);
        end
    end
    
    if (dat.OutcomeID == 4) || (dat.OutcomeID ==6) %Cancel @ reach
        startPause = b5.time_o;
        while (b5.time_o - startPause) < (Params.InterTrialDelay)
            [Params, dat, b5] = UpdateCursorEffort(Params, dat, b5); %b5 = bmi5_mmap(b5);
        end
    end
    
    if (dat.OutcomeID == 1) || (dat.OutcomeID == 2) %Cancel @ start || Cancel @ start hold
        startPause = b5.time_o;
        while (b5.time_o - startPause) < (Params.InterTrialDelay)
            [Params, dat, b5] = UpdateCursorEffort(Params, dat, b5); %b5 = bmi5_mmap(b5);
        end
    end


end

b5 = bmi5_mmap(b5);

%Clean screen
% b5.StartTarget_draw             = DRAW_NONE;
% b5.Frame_draw                   = DRAW_NONE;
% b5.BarOutline_draw              = DRAW_NONE;
b5.Cursor_draw                  = DRAW_NONE;
b5.OneTarget_draw             = DRAW_NONE;
b5.WrongWay_draw             = DRAW_NONE;

end
