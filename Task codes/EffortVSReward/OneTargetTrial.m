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

%% save effort, add noise here if wanted
dat.ActualEffort(1)     = dat.UpEffort;
dat.ActualEffort(2)     = dat.DownEffort;

%% Generate reach target position

% choose which target to draw and assign position to OneTarget and WrongWay
dat.TrialChoiceID       = randi([0 1]);
%dat.TrialChoiceID           =1;

if dat.TrialChoiceID==0 % 0 means down
    b5.OneTarget_pos 		= Params.DownTarget_pos;
    b5.WrongWay_pos         = b5.StartTarget_pos + [0 (b5.StartTarget_scale(2)+b5.WrongWay_scale(2))/2];
    TargetHoldTime          = Params.HoldDown;
else
    b5.OneTarget_pos 		= Params.UpTarget_pos;
    b5.WrongWay_pos         = b5.StartTarget_pos - [0 (b5.StartTarget_scale(2)+b5.WrongWay_scale(2))/2];
    TargetHoldTime          = Params.HoldUp;
end

%% Initialize outcomes and timestamps
dat.OutcomeID 	= 0;
dat.OutcomeStr 	= 'Success';

t_start_get           = NaN;
t_start_cancel        = NaN;
t_starthold_met       = NaN;
t_starthold_cancel    = NaN;
t_reach_draw          = NaN;
t_react               = NaN;
t_react_cancel        = NaN;
t_wrongway            = NaN;
t_reach_get           = NaN;
t_reach_cancel        = NaN;
t_reachhold_met       = NaN;
t_reachhold_cancel    = NaN;
t_rewardstart         = NaN;
t_rewardend           = NaN;

%% Hide all screen objects
b5.StartTarget_draw             = DRAW_NONE;
b5.Frame_draw                   = DRAW_NONE;
b5.BarOutline_draw              = DRAW_NONE;
b5.Cursor_draw                  = DRAW_NONE;
b5.OneTarget_draw              = DRAW_NONE;
b5.WrongWay_draw                = DRAW_NONE;

b5 = bmi5_mmap(b5);

%% 1. ACQUIRE START TARGET
b5.StartTarget_draw = DRAW_BOTH;
b5.Cursor_draw      = DRAW_BOTH;
b5.BarOutline_draw  = DRAW_NONE;

b5 = bmi5_mmap(b5);
t_start_draw = b5.time_o;

done   = false;
gotStart = false;

while ~done
    % update cursor and b5
    [Params, dat, b5] = UpdateCursorEffort(Params, dat, b5); % syncs b5 twice
    pos = b5.Cursor_pos;
    dat.FinalCursorPos = [0,pos(2)];
    timecheck=b5.time_o;
    
    % Check for acquisition of start target
    posOk = TrialInBox(pos, b5.Cursor_scale, b5.StartTarget_pos, Params.StartTarget.Win);
    
    if posOk
        if ~gotStart
            gotStart = true;
            t_start_get = timecheck;
        end
        
        if (timecheck - t_start_get) > Params.StartTarget.Hold
            done = true;   % Reach to start target OK
            t_starthold_met = timecheck;
        end
    end

	% Once start target is acquired, it must remain acquired
    if ~posOk
        if gotStart
            t_starthold_cancel = timecheck;
            gotStart = false;
            done            = true;
            dat.OutcomeID   = 2;
            dat.OutcomeStr	= 'cancel @ start hold';
            b5 = b5ObjectsOff(b5);
        else
            if (timecheck - t_start_draw) > Params.TimeoutReachStartTarget
                done            = true;
                dat.OutcomeID   = 1;
                dat.OutcomeStr	= 'cancel @ start';
                t_start_cancel = timecheck;
            end
        end
    end
end

%% 2. CHECK FOR Y-AXIS MOVEMENT ON LOAD CELL
if ~dat.OutcomeID
    b5.BarOutline_draw          = DRAW_BOTH;
    b5.Cursor_draw              = DRAW_BOTH;
    b5.StartTarget_draw         = DRAW_NONE;
    b5.OneTarget_draw           = DRAW_BOTH;
    b5.WrongWay_draw            = DRAW_NONE;
    
    b5 = bmi5_mmap(b5);
    t_reach_draw = b5.time_o;
    
    
    done = false;
    dat.FinalCursorPos = b5.StartTarget_pos;
    tmpJuiceState = 'off';
    gotTarget = false;
    
    while ~done
        % update cursor and b5
        drawnow;
        [Params, dat, b5] = UpdateCursorEffort(Params, dat, b5); % syncs b5 twice
        pos = b5.Cursor_pos;
        dat.FinalCursorPos = [0,pos(2)];
        timecheck=b5.time_o;
        
        b5 = bmi5_mmap(b5);
        
        % check which (if any) target cursor is in & set flags & timestamps
        posOk = TrialInBox(pos,b5.Cursor_scale,b5.StartTarget_pos,Params.StartTarget.Win);
        posTargetOk = TrialInBox(pos,b5.Cursor_scale,b5.OneTarget_pos,b5.OneTarget_scale/2);
        posWrongWay = TrialInBox(pos,b5.Cursor_scale,b5.WrongWay_pos,b5.WrongWay_scale/2);
        
         if ~posOk && isnan(t_react)
            t_react = timecheck;
        end
        
        if ~gotTarget && posTargetOk
            t_reach_get = timecheck;
            gotTarget=true;
        end
        
        % POSSIBLE ENDPOINTS
        if posWrongWay % check if wrong way
            dat.OutcomeID = 5;
            dat.OutcomeStr = 'Wrong way';
            done = true;
            gotTarget = false;
            t_wrongway = timecheck;
            
        elseif ~isnan(t_react) && (dat.TrialChoiceID==0) && (posTargetOk)
            dat.TrialChoice = 'Down';
            if (timecheck - t_reach_get) > TargetHoldTime
                done = true;   % Reach to target OK
                dat.OutcomeID 	= 0;
                dat.OutcomeStr 	= 'Success';
                t_reachhold_met = timecheck;
            end
            
        elseif ~isnan(t_react) && (dat.TrialChoiceID==1) && (posTargetOk)
            dat.TrialChoice = 'Up';
            if (timecheck - t_reach_get) > TargetHoldTime
                done = true;   % Reach to target OK
                dat.OutcomeID 	= 0;
                dat.OutcomeStr 	= 'Succes';
                t_reachhold_met = timecheck;
            end
            
        elseif gotTarget && ~done && ~(posTargetOk) % check if lost target
            dat.OutcomeID = 6;
            dat.OutcomeStr = 'Failed to hold target';
            done = true;
            gotTarget = false;
            t_reachhold_cancel = timecheck;
            
        elseif QUIT_FLAG || (((timecheck - t_reach_draw) > Params.ReactionTimeDelay) && isnan(t_react))
            dat.TrialChoice = '';
            done            = true;
            dat.OutcomeID 	= 3;
            dat.OutcomeStr 	= 'Cancel @ reaction';
            t_react_cancel = timecheck;
            
        elseif ~gotTarget && ((timecheck-t_react)>Params.TimeoutReachTarget)
            dat.TrialChoice     = ' ';
            done                = true;
            dat.OutcomeID       = 4;
            dat.OutcomeStr      = 'Cancel @ reach';
            t_reach_cancel        = timecheck;
        end
        
        % do stuff with solenoid
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
    % Turn objects on screen off
    b5 = b5ObjectsOff(b5);
    b5 = bmi5_mmap(b5);
    t_blank = b5.time_o;
    
    % Give juice reward
    if strcmp(dat.TrialChoice, 'Up')
        dat.ActualReward = dat.UpReward + random(Params.RandDist);
    else
        dat.ActualReward = dat.DownReward + random(Params.RandDist);
    end
    
    b5 = LJJuicer(Params, b5, 'on');
    [Params, dat, b5] = UpdateCursorEffort(Params, dat, b5); %b5 = bmi5_mmap(b5);
    t_rewardstart = b5.time_o;
    
    while (b5.time_o - t_rewardstart) < (dat.ActualReward / 1000)
        [Params, dat, b5] = UpdateCursorEffort(Params, dat, b5); %b5 = bmi5_mmap(b5);
    end
    if ~Solenoid_open
        b5 = LJJuicer(Params, b5, 'off');
    end
    
    t_rewardend = b5.time_o;
    controlWindow.message(['Last reward ' datestr(now)]);
    
    fprintf('Choice\t\t\t%s \n',dat.TrialChoice);
    %fprintf('Trial reward\t\t%.0f [ms]\n',dat.ActualReward);
    
else
    % Turn objects on screen off
    b5 = b5ObjectsOff(b5);
    b5 = bmi5_mmap(b5);
    t_blank = b5.time_o;
    
    % Pause after fail reach
    if dat.OutcomeID == 5 %Wrong choice
        while (b5.time_o - t_blank) < (Params.WrongChoiceDelay)
            [Params, dat, b5] = UpdateCursorEffort(Params, dat, b5);
        end
    else % cancel @ start, start hold, react, reach, reach hold
        while (b5.time_o - t_blank) < (Params.InterTrialDelay)
            [Params, dat, b5] = UpdateCursorEffort(Params, dat, b5);
        end
    end
end

b5 = bmi5_mmap(b5);

%% record timestamps
dat.TimeStartDraw           = t_start_draw;
dat.TimeStartGet            = t_start_get;
dat.TimeStartCancel         = t_start_cancel;
dat.TimeStartHoldMet        = t_starthold_met;
dat.TimeStartHoldCancel     = t_starthold_cancel;
dat.TimeReachDraw           = t_reach_draw;
dat.TimeReact               = t_react;
dat.TimeReactCancel         = t_react_cancel;
dat.TimeWrongWay            = t_wrongway;
dat.TimeReachGet            = t_reach_get;
dat.TimeReachCancel         = t_reach_cancel;
dat.TimeReachHoldMet        = t_reachhold_met;
dat.TimeReachHoldCancel     = t_reachhold_cancel;
dat.TimeBlank               = t_blank;
dat.TimeRewardStart         = t_rewardstart;
dat.TimeRewardEnd           = t_rewardend;

end
