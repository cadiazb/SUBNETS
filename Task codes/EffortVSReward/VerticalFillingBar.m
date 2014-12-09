function [Params, dat, b5] = VerticalFillingBar(Params, dat, b5)

% FOR DRAWING OBJECTS
DRAW_NONE     = 0;
DRAW_SUBJECT  = 1;
DRAW_OPERATOR = 2;
DRAW_BOTH     = 3;

%% Initial sync of hand
% [Params, dat, b5] = UpdateCursor(Params, dat, b5); % this syncs b5 twice

%% Generate a StartTarget position
b5.StartTarget_pos = Params.WsCenter - [0, b5.Frame_scale(2)/2]; 

%% Draw rewards from vector
dat.ProbeReward = DrawFromVec(Params.RewardSampleSpace);

tmpString = sprintf('%d ¢',Params.RewardsVector(dat.ProbeReward));
tmpStringZeros = numel(b5.Reward_v) - numel(double(tmpString));
b5.Reward_v = [double(tmpString) zeros(1,tmpStringZeros)]';
clear tmpStringZeros tmpString

% Init positions
b5.RewardCircle_pos = Params.WsCenter;
b5.Reward_pos = Params.WsCenter - [20, 0];
b5.RewardCircleFeedback_pos = Params.WsCenter - [60, b5.Frame_scale(2)/2];
b5.RewardFeedback_pos = b5.RewardCircleFeedback_pos - [70,0];
b5.RewardFeedback_v = [double('0.0 ¢') zeros(1,numel(b5.RewardFeedback_v) - 5)]';
b5.PassRewardCircle_pos = b5.Pass_pos - [60, 0];
b5.PassReward_pos = b5.PassRewardCircle_pos - [60, 0];

%% Misc stuff
dat.OutcomeID 	= 0;
dat.OutcomeStr 	= 'Success';

%% Hide all screen objects
b5.StartTarget_draw             = DRAW_NONE;
b5.Frame_draw                   = DRAW_NONE;
b5.BarOutline_draw              = DRAW_NONE;
b5.FillingEffort_draw           = DRAW_NONE;
b5.Pass_draw                    = DRAW_NONE;
b5.RewardCircle_draw            = DRAW_NONE;
b5.RewardCircleFeedback_draw    = DRAW_NONE;
b5.PassRewardCircle_draw        = DRAW_NONE;
b5.Cursor_draw                  = DRAW_NONE;
for ii = 1:Params.NumEffortTicks
    b5.(sprintf('effortTick%d_draw',ii))   = DRAW_NONE;
end

b5.Reward_draw                  = DRAW_NONE;
b5.RewardFeedback_draw          = DRAW_NONE;
b5.PassReward_draw              = DRAW_NONE;
b5.PassString_draw              = DRAW_NONE;

%% Always show points ON/OFF
b5.TotalPoints_draw             = DRAW_NONE;
b5.PointsBox_draw               = DRAW_NONE;

b5 = bmi5_mmap(b5);
%% 1. ACQUIRE START TARGET
b5.StartTarget_draw = DRAW_NONE;
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
    b5 = bmi5_mmap(b5);
    t_start = b5.time_o;
    
    b5.RewardCircle_draw = DRAW_BOTH;
    b5.Reward_draw = DRAW_BOTH;

    done = false;
	
    while ((b5.time_o - t_start) < Params.ReachDelay) && ~done

        pos = b5.Cursor_pos;

        posOk = TrialInBox(pos,b5.StartTarget_pos,Params.StartTarget.Win);

        if ~posOk && ~Params.AllowEarlyReach
            done            = true;
            dat.OutcomeID   = 2;
            dat.OutcomeStr 	= 'cancel @ hold';
        end
        
        % update hand
        [Params, dat, b5] = UpdateCursorOnLine(Params, dat, b5); % syncs b5 twice
    end
end
%% 3. REACHING PHASE (reach to target and hold)
if ~dat.OutcomeID
    
    [Params, b5] = moveShape(Params, b5, {'RewardCircle', 'Reward'}, ...
        [Params.WsCenter;Params.WsCenter] + [-60, b5.Frame_scale(2)/2; -60, b5.Frame_scale(2)/2], [0 0;-20 0],[0 0;-70 0]);

    b5.BarOutline_draw  = DRAW_BOTH;
    b5.FillingEffort_draw  = DRAW_BOTH;
    b5.Pass_draw            =DRAW_BOTH;
    b5.RewardCircleFeedback_draw         = DRAW_BOTH;
    b5.PassRewardCircle_draw             = DRAW_BOTH;
    for ii = 1:Params.NumEffortTicks
        b5.(sprintf('effortTick%d_draw',ii))   = DRAW_BOTH;
    end
    b5.RewardFeedback_draw          = DRAW_BOTH;
    b5.PassReward_draw              = DRAW_BOTH;
    b5.PassString_draw              = DRAW_BOTH;
    
    b5.GoTone_play_io = 1;
    b5.FillingEffort_scale(2) = 0;
    b5.FillingEffort_pos       = Params.WsCenter - [0, b5.Frame_scale(2)/2];
    b5 = bmi5_mmap(b5);

	done            = false;
    dat.FinalCursorPos = b5.StartTarget_pos;

	t_start = b5.time_o;
	while ~done
        
        [Params, dat, b5] = UpdateCursorOnLine(Params, dat, b5); % syncs b5 twice
        pos = b5.Cursor_pos;
        dat.FinalCursorPos = [max(dat.FinalCursorPos(1), pos(1)), 0];
        b5.FillingEffort_scale = [b5.BarOutline_scale(1),...
            max(dat.FinalCursorPos(1)-b5.StartTarget_pos(1),0)];
        b5.FillingEffort_pos       = Params.WsCenter - [0, b5.Frame_scale(2)/2] + ...
                    [0, b5.FillingEffort_scale(2)/2];
        b5.RewardCircleFeedback_pos = Params.WsCenter - [60, b5.Frame_scale(2)/2] + ...
                    [0, b5.FillingEffort_scale(2)];
        b5.RewardFeedback_pos(2) = b5.RewardCircleFeedback_pos(2);
        tmpString = sprintf('%.01f ¢', Params.RewardsVector(dat.ProbeReward) * ...
            (b5.FillingEffort_scale(2)/b5.Frame_scale(2)));
        b5.RewardFeedback_v = [double(tmpString) zeros(1, numel(b5.RewardFeedback_v) - numel(double(tmpString)))]';
        b5 = bmi5_mmap(b5);
        
        posOk = TrialInBox(pos,b5.StartTarget_pos,Params.StartTarget.Win);
        
        if ~posOk && isempty(dat.ReactionTime)
            dat.ReactionTime = b5.time_o - t_start;
        end
        if ~isempty(dat.ReactionTime)
            if (pos(1) - b5.StartTarget_pos(1)) < -Params.NoGoTap
                dat.TrialChoice = 'Pass';
                done = true;
                dat.OutcomeID 	= 0;
                dat.OutcomeStr 	= 'success';
            end
        end
        
        if ~isempty(dat.ReactionTime)
            if (b5.time_o - (dat.ReactionTime + t_start)) > Params.MovementWindow
                dat.MovementTime = NaN;
                dat.ActualEffort = (pos(2) - b5.StartTarget_pos(2)) /...
                                        b5.Frame_scale(2); % Force as %of Max
                dat.TrialChoice = 'Probe Effort';
                done            = true;
                dat.OutcomeID 	= 0;
                dat.OutcomeStr 	= 'success';
            end
        end
        
        if isempty(dat.ReactionTime)
            if (b5.time_o - t_start) > Params.ReactionTimeDelay
                done = true;
                dat.ReactionTime = NaN;
                dat.OutcomeID 	= 4;
                dat.OutcomeStr 	= 'cancel @ reaction';
            end
        end
	end
end
%% Graphical feedback
if dat.OutcomeID == 0
    b5.TotalPoints_draw             = DRAW_BOTH;
    b5.PointsBox_draw               = DRAW_BOTH;
    switch dat.TrialChoice
        case 'Probe Effort'
            [Params, b5] = blinkShape(Params, b5, {'RewardCircleFeedback', 'RewardFeedback'}, [10, 10], 0.5);
            [Params, b5] = moveShape(Params, b5, {'RewardCircleFeedback', 'RewardFeedback'}, ...
                [Params.WsBounds(1,:);Params.WsBounds(1,:)],[0 0; -70 0], [0 0; -100 0]);
            b5.RewardCircleFeedback_draw    = DRAW_NONE;
            b5.RewardFeedback_draw          = DRAW_NONE;
        case 'Pass'
            [Params, b5] = blinkShape(Params, b5, {'Pass', 'PassRewardCircle', 'PassReward'}, [10, 10, 10], 0.5);
            [Params, b5] = moveShape(Params, b5, {'PassRewardCircle', 'PassReward'}, ...
                [Params.WsBounds(1,:);Params.WsBounds(1,:)],[0 0; -60 0], [0 0; -100 0]);
            b5.PassRewardCircle_draw        = DRAW_NONE;
            b5.PassReward_draw              = DRAW_NONE;
    end
end
%% Trial outcome and variable adaptation
b5.StartTarget_draw             = DRAW_NONE;
b5.Frame_draw                   = DRAW_NONE;
b5.BarOutline_draw              = DRAW_NONE;
b5.FillingEffort_draw           = DRAW_NONE;
b5.Pass_draw                    = DRAW_NONE;
b5.RewardCircle_draw            = DRAW_NONE;
b5.RewardCircleFeedback_draw    = DRAW_NONE;
b5.PassRewardCircle_draw        = DRAW_NONE;
b5.Cursor_draw                  = DRAW_NONE;
for ii = 1:Params.NumEffortTicks
    b5.(sprintf('effortTick%d_draw',ii))   = DRAW_NONE;
end

b5.Reward_draw                  = DRAW_NONE;
b5.RewardFeedback_draw          = DRAW_NONE;
b5.PassReward_draw              = DRAW_NONE;
b5.PassString_draw              = DRAW_NONE;


if dat.OutcomeID == 0
    if strcmp(dat.TrialChoice, 'Probe Effort')
        tmpTrialPoints = Params.RewardsVector(dat.ProbeReward) * ...
            (b5.FillingEffort_scale(2)/b5.Frame_scale(2));
    end
    if strcmp(dat.TrialChoice, 'Pass')
        tmpTrialPoints = Params.PassReward;
    end
    
    dat.TotalPoints = dat.TotalPoints + tmpTrialPoints;
    
    tmpString = sprintf('%0.1f ¢',dat.TotalPoints);
    tmpStringZeros = numel(b5.TotalPoints_v) - numel(double(tmpString));
    b5.TotalPoints_v = [double(tmpString) zeros(1,tmpStringZeros)]';

    fprintf('Trial Choice\t\t%s \n',dat.TrialChoice);
    fprintf('Effort\t\t%f \n',dat.ActualEffort);
    fprintf('Total points\t\t%d \n',dat.TotalPoints);
	
    b5.RewardTone_play_io = 1;
    Params.RewardSampleSpace(find(Params.RewardSampleSpace == dat.ProbeReward, 1)) = [];
else
    tmpString = sprintf('%0.1f ¢',dat.TotalPoints);
    tmpStringZeros = numel(b5.TotalPoints_v) - numel(double(tmpString));
    b5.TotalPoints_v = [double(tmpString) zeros(1,tmpStringZeros)]';  
end

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
    b5 = bmi5_mmap(b5);
end

b5.PointsBox_draw               = DRAW_NONE;
b5.TotalPoints_draw             = DRAW_NONE;

%%% XXX TODO: NEED WAY TO LOG (MORE) INTERESTING TRIAL EVENTS

end