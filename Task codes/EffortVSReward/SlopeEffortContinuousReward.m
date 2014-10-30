function [Params, dat, b5] = SlopeEffortContinuousReward(Params, dat, b5)

% FOR DRAWING OBJECTS
DRAW_NONE     = 0;
DRAW_SUBJECT  = 1;
DRAW_OPERATOR = 2;
DRAW_BOTH     = 3;

%% Initial sync of hand
% [Params, dat, b5] = UpdateCursor(Params, dat, b5); % this syncs b5 twice

%% Generate a StartTarget position
b5.StartTarget_pos = Params.WsBounds(1,:);

%% Set initial timer bare length
b5.TimerBar_scale(1) = b5.Frame_scale(1);

b5.TimerBar_pos(1) = Params.WsCenter(1) - b5.Frame_scale(1)/2 + ...
                        b5.TimerBar_scale(1)/2;

%% Draw Probe effort from vector

dat.ProbeEffort         = DrawFromVec(Params.SlopeSampleSpace);

%% Generate ProbeEffortTarget and Reference Target positions

dat.EffortLine = zeros(2,2*ceil(sqrt(sumsqr(b5.Frame_scale)))); %Array for line coordinates
dat.EffortLine(1,:) = 1:size(dat.EffortLine,2);
m = tan(dat.ProbeEffort * Params.MaxSlope * pi() / 180);
dat.EffortLine(2,:) = m .* dat.EffortLine(1,:);

% Translate line to bottom left corner of b5.frame
dat.EffortLine(1,:) = dat.EffortLine(1,:) + Params.WsCenter(1) - b5.Frame_scale(1)/2;
dat.EffortLine(2,:) = dat.EffortLine(2,:) + ...
    Params.WsCenter(2) - b5.Frame_scale(2)/2;

dat.EffortLine(1,:) = dat.EffortLine(1,:) + Params.ZeroEffortOffset;

if dat.ProbeEffort * Params.MaxSlope <= 45
    b5.EffortLine_scale(1) = b5.Frame_scale(1) - Params.ZeroEffortOffset;
    b5.EffortLine_scale(2) = ...
        tan(dat.ProbeEffort * Params.MaxSlope * pi() / 180) * ...
        b5.EffortLine_scale(1);
else
    b5.EffortLine_scale(2) = b5.Frame_scale(2);
    b5.EffortLine_scale(1) = b5.EffortLine_scale(2) / ...
        tan(dat.ProbeEffort * Params.MaxSlope * pi() / 180);
end

b5.EffortLine_pos = [Params.ZeroEffortOffset, 0];
b5.EffortLine_pos = b5.EffortLine_pos - b5.Frame_scale/2;

clear m

%% Update target width according

%  b5.ProbeEffortTarget_scale             = [dat.ProbeEffort + 20, 15];
%  b5.ReferenceTarget_scale               = [dat.ReferenceEffort + 20, 15];
         

%% Generate the amounts of reward
% dat.ReferenceReward = Params.ReferenceTarget.RewardReference;
% dat.ProbeReward = Params.AdaptiveReward(Params.AdaptiveReward(:,1) == dat.ProbeEffort,2);        
                                
%% Set reward strings and position
b5.ProbeRewardString_v = [double(sprintf('1c')) zeros(1,30)]';
b5.ReferenceRewardString_v = [double(sprintf('5c')) zeros(1,30)]';

b5.ProbeRewardString_pos = ...
    Params.WsCenter - [1 0.75] .* b5.Frame_scale/2 - [130,-20];
b5.ReferenceRewardString_pos = ...
    Params.WsCenter + [-1 0.95].* b5.Frame_scale/2 - [130,0];

b5 = bmi5_mmap(b5);

%% Set effort strings and positions
b5.ProbeAxisLabel_v      = ...
[double(sprintf('0%%            10%%            30%%            50%%            70%%            90%%            100%%' ...
    )), 0]';

b5.ProbeAxisLabel_pos  = Params.WsCenter -  b5.Frame_scale/2 - [90, 20];


%% Generate delay interval
dat.ReachDelay = DrawFromInterval(Params.ReachDelayRange);
fprintf('Delay\t\t\t%.2f\n',dat.ReachDelay);

%% Misc stuff
dat.OutcomeID 	= 0;
dat.OutcomeStr 	= 'Success';

%% Hide all screen objects
b5.Cursor_draw 		= DRAW_NONE;
b5.StartTarget_draw = DRAW_NONE;
b5.StartAxis_draw = DRAW_NONE;
b5.Frame_draw = DRAW_NONE;

b5.ProbeEffortTarget_draw 	= DRAW_NONE;
b5.ProbeEffortAxis_draw = DRAW_NONE; 
b5.ProbeRewardString_draw = DRAW_NONE; 
b5.ProbeEffortString_draw = DRAW_NONE; 
b5.ProbeAxisLabel_draw = DRAW_NONE;

b5.ReferenceTarget_draw = DRAW_NONE;
b5.ReferenceAxis_draw = DRAW_NONE;
b5.ReferenceRewardString_draw = DRAW_NONE;
b5.ReferenceEffortString_draw = DRAW_NONE;

b5.TimerBar_draw = DRAW_NONE;
b5.ReachTimeout_draw = DRAW_NONE;

b5.EffortLine_draw  = DRAW_NONE;

%% Always show points ON/OFF
b5.TotalPoints_draw = DRAW_NONE;

%% Don't allow early reach
Params.AllowEarlyReach              = false;

%% Timer off
Params.TimerOn = false;

%% 1. ACQUIRE START TARGET
b5.StartTone_play_io = 1;
b5.Cursor_draw = DRAW_BOTH;
b5.StartTarget_draw = DRAW_BOTH;
% b5.StartAxis_draw = DRAW_BOTH;
b5 = bmi5_mmap(b5);

done   = false;
gotPos = false;

t_start = b5.time_o;
while ~done

    pos = b5.Cursor_pos;

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

%% 2. INSTRUCTED DELAY PHASE
if ~dat.OutcomeID
% b5 = JuiceStart(b5,Params.Reward/10);
    b5.ReferenceRewardString_draw = DRAW_BOTH; 
    
    b5.ProbeAxisLabel_draw = DRAW_BOTH;
    b5.ProbeRewardString_draw = DRAW_BOTH;
    
    b5.Frame_draw = DRAW_BOTH;
    
    if Params.TimerOn
        b5.TimerBar_draw = DRAW_BOTH;
        b5.ReachTimeout_draw = DRAW_BOTH;
    end
    
    b5.EffortLine_draw  = DRAW_BOTH;
   
	b5 = bmi5_mmap(b5);

	% trigger ICMS
%     if dat.RewardedTargetID == dat.ICMS.TargetID
%         b5 = ICMS_Start(b5);
%         b5.PairTone_play_io = 1;
%          b5.CheatTarget_draw = DRAW_OPERATOR;
%     end
    

    done = false;
	t_start = b5.time_o;
    while ((b5.time_o - t_start) < dat.ReachDelay) && ~done

        pos = b5.Cursor_pos;

        posOk = TrialInBox(pos,b5.StartTarget_pos,Params.StartTarget.Win);

        if ~posOk && ~Params.AllowEarlyReach
            done            = true;
            dat.OutcomeID   = 2;
            dat.OutcomeStr 	= 'cancel @ hold';
        end
        
%         if (b5.time_o - t_start)>b5.PairTone_duration/32
% %             b5.CheatTarget_draw = DRAW_NONE;
%             b5.ProbeEffortTarget_draw 	= DRAW_NONE;
%             b5.ProbeEffortTarget_draw 	= DRAW_BOTH;
%         end
        % update hand
        [Params, dat, b5] = UpdateCursorOnLine(Params, dat, b5); % syncs b5 twice
    end
end
% if dat.RewardedTargetID == dat.ICMS.TargetID
%     b5.CheatTarget_draw = DRAW_NONE;
%     b5.ProbeEffortTarget_draw 	= DRAW_NONE;
%     b5.ProbeEffortTarget_draw 	= DRAW_BOTH;
% end


%% 3. REACHING PHASE (reach to target and hold)
if ~dat.OutcomeID
    
    b5.StartTarget_draw = DRAW_NONE;
%     b5.StartAxis_draw = DRAW_NONE;
    b5.GoTone_play_io = 1;
    b5 = bmi5_mmap(b5);

	done            = false;
	gotPos          = false;
    gotIntention    = 0;
    dat.FinalCursorPos = b5.StartTarget_pos;

	t_start = b5.time_o;
	while ~done

        pos = b5.Cursor_pos;
        dat.FinalCursorPos(1) = max(dat.FinalCursorPos(1), pos(1));
        if Params.TimerOn
            AdjustTimerBar;
        end
        
        posOk = TrialInBox(pos,b5.StartTarget_pos,Params.StartTarget.Win);
        
        if ~posOk && isempty(dat.ReactionTime)
            dat.ReactionTime = b5.time_o - t_start;
        end
        
        if (b5.time_o - t_start) > Params.MovementWindow
            if isempty(dat.ReactionTime)
                dat.ReactionTime = NaN;
                dat.OutcomeID 	= 4;
                dat.OutcomeStr 	= 'cancel @ reaction';
            end
            dat.MovementTime = NaN;
            dat.ActualEffort = (pos(1) - b5.StartTarget_pos(1)) /...
                                    b5.Frame_scale(1); % Force as %of Max
%             dat.FinalCursorPos = pos;
            done            = true;
            dat.OutcomeID 	= 0;
            dat.OutcomeStr 	= 'success';
        end
            
        
        % update hand
        [Params, dat, b5] = UpdateCursorOnLine(Params, dat, b5); % syncs b5 twice
	end
end

%% Trial outcome and variable adaptation
b5.Cursor_draw 		= DRAW_NONE;
b5.StartTarget_draw = DRAW_NONE;
b5.StartAxis_draw = DRAW_NONE;
b5.Frame_draw = DRAW_NONE;

b5.ProbeEffortTarget_draw 	= DRAW_NONE;
b5.ProbeEffortAxis_draw = DRAW_NONE; 
b5.ProbeRewardString_draw = DRAW_NONE; 
b5.ProbeEffortString_draw = DRAW_NONE; 
b5.ProbeAxisLabel_draw = DRAW_NONE;

b5.ReferenceTarget_draw = DRAW_NONE;
b5.ReferenceAxis_draw = DRAW_NONE;
b5.ReferenceRewardString_draw = DRAW_NONE;
b5.ReferenceEffortString_draw = DRAW_NONE;

b5.Frame_draw = DRAW_NONE;
b5.EffortLine_draw  = DRAW_NONE;

if dat.OutcomeID == 0
    
    dat.FinalCursorPos(2) = min(dat.EffortLine(2,find(dat.EffortLine(1,:) >= dat.FinalCursorPos(1),1,'first')),...
        Params.WsBounds(2,2));
    tmpTrialPoints = (dat.FinalCursorPos(2) -Params.WsCenter(2) + b5.Frame_scale(2)/2)*5/b5.Frame_scale(2);
    dat.TotalPoints = dat.TotalPoints + ...
        tmpTrialPoints;
    
    tmpStringZeros = 32 - numel(double(sprintf('Earned = %04.2f',tmpTrialPoints)));
    b5.TotalPoints_v = [double(sprintf('Earned = %04.2f',tmpTrialPoints)) zeros(1,tmpStringZeros)]';
    
    Params.SlopeSampleSpace(...
        find(Params.SlopeSampleSpace == dat.ProbeEffort, 1)) = [];
    
    fprintf('Effort\t\t%f \n',dat.ActualEffort);
    fprintf('Total points\t\t%d \n',dat.TotalPoints);
	
    b5.RewardTone_play_io = 1;

else
    tmpStringZeros = 32 - numel(double(sprintf('Earned =%04.2f',0)));
    b5.TotalPoints_v = [double(sprintf('Earned =%04.2f',0)) zeros(1,tmpStringZeros)]';
    Params.NumTrials 		= Params.NumTrials + 1;
    
end

b5.TotalPoints_draw = DRAW_BOTH;
b5 = bmi5_mmap(b5);

% Pause at end of trials
if Params.FixedTrialLength
    the_delay = Params.InterTrialDelay + ...
            Params.TrialLength - (b5.time_o - dat.TimeStart);
else
    the_delay = Params.InterTrialDelay;
end

startpause = b5.time_o;
while (b5.time_o - startpause) < the_delay
    if Params.TimerOn
        AdjustTimerBar;
    end
    b5 = bmi5_mmap(b5);
end
b5.TimerBar_draw = DRAW_NONE;
b5.ReachTimeout_draw = DRAW_NONE;
% b5.CheatTarget_draw = DRAW_NONE;

%%% XXX TODO: NEED WAY TO LOG (MORE) INTERESTING TRIAL EVENTS

end