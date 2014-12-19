function [Params, dat, b5] = ProbeOnlyAdaptation(Params, dat, b5)

global DEBUG

% FOR DRAWING OBJECTS
DRAW_NONE     = 0;
DRAW_SUBJECT  = 1;
DRAW_OPERATOR = 2;
DRAW_BOTH     = 3;

%% Initial sync of hand
% [Params, dat, b5] = UpdateCursor(Params, dat, b5); % this syncs b5 twice

%% Generate a StartTarget position
b5.StartTarget_pos = Params.WsCenter - [0, b5.Frame_scale(2)/2]; 

%% Draw Probe effort from vector
% Draw reward from 'Training vector' or from Adaptive Vector
if ~isempty(Params.InitialSampling)
    dat.ProbeEffort = NaN;
    while isnan(dat.ProbeEffort)
    dat.ProbeEffort = DrawFromVec(Params.InitialSampling(:,1,1));
    end
else
    dat.ProbeEffort         = DrawFromVec(Params.EffortSampleSpace);
end

%% Generate ProbeTarget position
b5.ProbeTarget_pos 		= b5.StartTarget_pos + ...
                                [0,dat.ProbeEffort * b5.Frame_scale(2)];

%% Generate the amounts of reward
if ~isempty(Params.InitialSampling) || ~dat.ProbesAdaptationState(dat.ProbesAdaptationState(:,1) == dat.ProbeEffort,2)
    dat.ProbeReward = ...
        Params.InitialSamplingRewards(Params.InitialSamplingRewards(:,1,1) == dat.ProbeEffort, ...
    randi([2, size(Params.InitialSamplingRewards,2)],1), ...
    1);
else
dat.ProbeReward = ...
    Params.RewardAdaptation(Params.RewardAdaptation(:,1) == ...
    dat.ProbeEffort, 2);
end

tmpString = sprintf('%.1f ¢', dat.ProbeReward);
tmpStringZeros = numel(b5.Reward_v) - numel(double(tmpString));
b5.Reward_v = [double(tmpString) zeros(1,tmpStringZeros)]';
clear tmpString tmpStringZeros

% Init positions
b5.RewardCircle_pos = b5.ProbeTarget_pos;
b5.Reward_pos = b5.RewardCircle_pos - [20, 0];
b5.PassRewardCircle_pos = b5.Pass_pos - [60, 0];
b5.PassReward_pos = b5.PassRewardCircle_pos - [Params.StringOffset(1), 0];

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
b5.PassRewardCircle_draw        = DRAW_NONE;
b5.Cursor_draw                  = DRAW_NONE;
b5.ProbeTarget_draw             = DRAW_NONE;
for ii = 1:Params.NumEffortTicks
    b5.(sprintf('effortTick%d_draw',ii))   = DRAW_NONE;
end

b5.Reward_draw                  = DRAW_NONE;
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
        [b5.RewardCircle_pos;b5.RewardCircle_pos] + [-60, 0; -60, 0], [0 0;-20 0],[0 0;-Params.StringOffset(1) 0]);
    
    b5.BarOutline_draw          = DRAW_BOTH;
    b5.FillingEffort_draw       = DRAW_BOTH;
    b5.Pass_draw                = DRAW_BOTH;
    b5.PassRewardCircle_draw    = DRAW_BOTH;
    b5.ProbeTarget_draw         = DRAW_BOTH;
    for ii = 1:Params.NumEffortTicks
        b5.(sprintf('effortTick%d_draw',ii))   = DRAW_BOTH;
    end
    b5.PassReward_draw          = DRAW_BOTH;
    b5.PassString_draw          = DRAW_BOTH;
    
    b5.GoTone_play_io = 1;
    b5.FillingEffort_scale(2) = 0;
    b5.FillingEffort_pos       = Params.WsCenter - [0, b5.Frame_scale(2)/2];
    b5 = bmi5_mmap(b5);
    
    dat.GoCue_time_o = b5.GoTone_time_o;

	done            = false;
    tmpChoseProbe   = false;
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
        b5 = bmi5_mmap(b5);
        
		% Check for acquisition of a reach target
        posOk = TrialInBox(pos,b5.StartTarget_pos,Params.StartTarget.Win);
        posProbeOk 	= dat.ProbeEffort <=(b5.FillingEffort_scale(2) / b5.BarOutline_scale(2));
        
        if ~posOk && isempty(dat.ReactionTime)
            dat.ReactionTime = b5.time_o - t_start;
            if b5.FillingEffort_scale(2) > 0
                tmpChoseProbe = true;
            end
        end
        if ~isempty(dat.ReactionTime) && ~tmpChoseProbe
            if (pos(1) - b5.StartTarget_pos(1)) < -Params.NoGoTap
                dat.TrialChoice = 'Pass';
                done = true;
                dat.OutcomeID 	= 0;
                dat.OutcomeStr 	= 'success';
            end
        end
        
        if ~isempty(dat.ReactionTime)
            if posProbeOk
                    done = true;
                    dat.TrialChoice = 'Probe Effort';
                    dat.MovementTime = b5.time_o - t_start - dat.ReactionTime;
                    dat.OutcomeID 	= 0;
                    dat.OutcomeStr 	= 'Succes';
            end
        end

		% check for TIMEOUT
        if ~isempty(dat.ReactionTime) && ~done
            if (b5.time_o - t_start - dat.ReactionTime) > Params.TimeoutReachTarget
                dat.MovementTime = b5.time_o - t_start - dat.ReactionTime;
                dat.TrialChoice = '';
                done            = true;
                dat.OutcomeID 	= 4;
                dat.OutcomeStr 	= 'cancel @ reach movement timeout';
            end
        end
        
        if isempty(dat.ReactionTime)
            if (b5.time_o - t_start) > Params.ReactionTimeDelay
                dat.ReactionTime = b5.time_o - t_start;
                dat.TrialChoice = '';
                dat.MovementTime = NaN;
                done            = true;
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
            [Params, b5] = blinkShape(Params, b5, {'RewardCircle', 'Reward'}, [10, 10], 0.5);
            [Params, b5] = moveShape(Params, b5, {'RewardCircle', 'Reward'}, ...
                [Params.WsBounds(1,:);Params.WsBounds(1,:)],[0 0; -Params.StringOffset(1) 0], [0 0; -Params.StringOffset(2) 0]);
            b5.RewardCircle_draw    = DRAW_NONE;
            b5.Reward_draw          = DRAW_NONE;
        case 'Pass'
            [Params, b5] = blinkShape(Params, b5, {'Pass', 'PassRewardCircle', 'PassReward'}, [10, 10, 10], 0.5);
            [Params, b5] = moveShape(Params, b5, {'PassRewardCircle', 'PassReward'}, ...
                [Params.WsBounds(1,:);Params.WsBounds(1,:)],[0 0; -Params.StringOffset(1) 0], [0 0; -Params.StringOffset(2) 0]);
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
b5.PassRewardCircle_draw        = DRAW_NONE;
b5.Cursor_draw                  = DRAW_NONE;
b5.ProbeTarget_draw             = DRAW_NONE;
for ii = 1:Params.NumEffortTicks
    b5.(sprintf('effortTick%d_draw',ii))   = DRAW_NONE;
end

b5.Reward_draw                  = DRAW_NONE;
b5.PassReward_draw              = DRAW_NONE;
b5.PassString_draw              = DRAW_NONE;

if dat.OutcomeID == 0
    if strcmp(dat.TrialChoice, 'Probe Effort')
        tmpTrialPoints = dat.ProbeReward;
    end
    if strcmp(dat.TrialChoice, 'Pass')
        tmpTrialPoints = Params.PassReward;
    end
    
    dat.TotalPoints = dat.TotalPoints + tmpTrialPoints;
    
    tmpString = sprintf('%0.1f ¢',dat.TotalPoints);
    tmpStringZeros = numel(b5.TotalPoints_v) - numel(double(tmpString));
    b5.TotalPoints_v = [double(tmpString) zeros(1,tmpStringZeros)]';
    
    fprintf('Choice\t\t%s \n',dat.TrialChoice);
    fprintf('Total points\t\t%d \n',dat.TotalPoints);
	
    b5.RewardTone_play_io = 1;
    
    if ~isempty(Params.InitialSampling)
        Params.InitialSampling(Params.InitialSampling(:,1) == ...
        dat.ProbeEffort, ...
        :,1) = NaN;
        if all(isnan(Params.InitialSampling(:,:,1)))
            Params.InitialSampling(:,:,1) = [];
        end
    elseif  dat.ProbesAdaptationState(dat.ProbesAdaptationState(:,1) == dat.ProbeEffort,2)
        Params.EffortSampleSpace(find(Params.EffortSampleSpace == dat.ProbeEffort, 1)) = [];
    end

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