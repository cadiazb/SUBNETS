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

%% Draw left or right position for take trial
dat.TakeTrialRight = DrawFromVec([0 1]);

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

%% Bring all shapes to the center on X axes
b5.BarOutline_pos(1)        = Params.Xcenter_pos.BarOutline;
b5.Pass_pos(1)              = Params.Xcenter_pos.Pass;
b5.RewardCircle_pos(1)      = Params.Xcenter_pos.RewardCircle;
b5.PassRewardCircle_pos(1)  = Params.Xcenter_pos.PassRewardCircle;
b5.ProbeTarget_pos(1)       = Params.Xcenter_pos.ProbeTarget;
b5.Reward_pos(1)            = Params.Xcenter_pos.Reward - Params.RewardStringOffset(1);
b5.PassReward_pos(1)        = Params.Xcenter_pos.PassReward - Params.PassRewardStringOffset(1);
b5.PassString_pos(1)        = Params.Xcenter_pos.PassString - Params.PassStringOffset(1);
for ii = 1:Params.NumEffortTicks
    b5.(sprintf('effortTick%d_pos',ii))(1)     = ...
        Params.Xcenter_pos.effortTicks;
end
%% Generate ProbeTarget vertical position
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

tmpString = sprintf('%.0f¢', round(dat.ProbeReward));
tmpStringZeros = numel(b5.Reward_v) - numel(double(tmpString));
b5.Reward_v = [double(tmpString) zeros(1,tmpStringZeros)]';
clear tmpString tmpStringZeros

% Init positions
b5.RewardCircle_pos(2) = b5.ProbeTarget_pos(2);
b5.Reward_pos(2) = b5.RewardCircle_pos(2);
b5.PassRewardCircle_pos(2) = b5.Pass_pos(2) - 0;
b5.PassReward_pos(2) = b5.PassRewardCircle_pos(2) - 0;

%% Move shapes to left and right depending on trial
b5.ProbeTarget_pos(1)       = b5.ProbeTarget_pos(1) - ...
    Params.ShapeDisplacement * (-1)^dat.TakeTrialRight;
b5.BarOutline_pos(1)        = b5.BarOutline_pos(1) - ...
    Params.ShapeDisplacement * (-1)^dat.TakeTrialRight;
b5.RewardCircle_pos(1)      = b5.RewardCircle_pos(1) - ...
    Params.ShapeDisplacement * (-1)^dat.TakeTrialRight;
b5.Reward_pos(1)            = b5.Reward_pos(1) - ...
    Params.ShapeDisplacement * (-1)^dat.TakeTrialRight ...
    + Params.LeftRightRewardStringOffset(1+dat.TakeTrialRight);
for ii = 1:Params.NumEffortTicks
    b5.(sprintf('effortTick%d_pos',ii))(1)     = ...
        b5.(sprintf('effortTick%d_pos',ii))(1) - ...
        Params.ShapeDisplacement * (-1)^dat.TakeTrialRight;
end

b5.PassReward_pos(1)        = b5.PassReward_pos(1) + ...
    Params.ShapeDisplacement * (-1)^dat.TakeTrialRight ...
    + Params.LeftRightPassRewardStringOffset(1+~dat.TakeTrialRight);
b5.PassString_pos(1)        = b5.PassString_pos(1) + ...
    Params.ShapeDisplacement * (-1)^dat.TakeTrialRight ...
    + Params.LeftRightPassRewardStringOffset(1+~dat.TakeTrialRight);
b5.Pass_pos(1)              = b5.Pass_pos(1) + ...
    Params.ShapeDisplacement * (-1)^dat.TakeTrialRight;
b5.PassRewardCircle_pos(1)  = b5.PassRewardCircle_pos(1) + ...
    Params.ShapeDisplacement * (-1)^dat.TakeTrialRight;

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
b5.Warning_draw                 = DRAW_NONE;
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
%% 1. RELEASE CONTROL BUTTONS
b5.StartTarget_draw = DRAW_NONE;
b5 = bmi5_mmap(b5);

done        = false;
gotButtons  = false;

t_start = b5.time_o;
while ~done

    buttonsOK = all(b5.isometricDIN_DIN_o);

	% Check for buttons in control box not pressed
    if buttonsOK
        if ~gotButtons
            gotButtons = true;
            starthold = b5.time_o;
        end
        if (b5.time_o - starthold) > Params.StartTarget.Hold
			done = true;   % Buttons not pressed OK
            b5.Warning_draw = DRAW_NONE;
        end
    end

	% Once buttons are depressed they must remain depressed
    if ~buttonsOK  
        gotButtons = false;
        if (b5.time_o - t_start) > Params.TimeoutReachStartTarget
            done            = true;
            dat.OutcomeID   = 1;
            dat.OutcomeStr	= 'cancel @ start';
        end
        b5.Warning_draw = DRAW_BOTH;
    end
    
    % update buttons
    b5 = bmi5_mmap(b5);
end

%% 2. ENFORCED DECISION PHASE
if ~dat.OutcomeID    
    b5 = bmi5_mmap(b5);
    t_start = b5.time_o;
    
    b5.BarOutline_draw          = DRAW_BOTH;
    for ii = 1:Params.NumEffortTicks
        b5.(sprintf('effortTick%d_draw',ii))   = DRAW_BOTH;
    end    
    b5.RewardCircle_draw        = DRAW_BOTH;
    b5.Reward_draw              = DRAW_BOTH;
    b5.Pass_draw                = DRAW_BOTH;
    b5.PassRewardCircle_draw    = DRAW_BOTH;
    b5.ProbeTarget_draw         = DRAW_BOTH;
    b5.PassReward_draw          = DRAW_BOTH;
    b5.PassString_draw          = DRAW_BOTH;
    
    done = false;
    
    b5 = bmi5_mmap(b5);
    dat.Decision_time_o = b5.time_o;
    while ~done

        buttonsOK = all(b5.isometricDIN_DIN_o);
        
        if buttonsOK && ((b5.time_o - t_start) > Params.DecisionDelay)
            done            = true;
            dat.OutcomeID   = 2;
            dat.OutcomeStr 	= 'cancel @ Decision';
        end
        
        if ~buttonsOK
            done = true;
            dat.ReactionTime = b5.time_o - t_start;
            tmpChoice = ~b5.isometricDIN_DIN_o;
            if dat.TakeTrialRight
                if tmpChoice(Params.ControlBox.RightButton_DIN)
                    dat.TrialChoice = 'Probe Effort';
                elseif tmpChoice(Params.ControlBox.LeftButton_DIN)
                    dat.TrialChoice = 'Pass';
                end
            else
                if tmpChoice(Params.ControlBox.LeftButton_DIN)
                    dat.TrialChoice = 'Probe Effort';
                elseif tmpChoice(Params.ControlBox.RightButton_DIN)
                    dat.TrialChoice = 'Pass';
                end
            end
        end
        % update buttons
        b5 = bmi5_mmap(b5);
    end
end
%% 3. REACHING PHASE (reach to target and hold)
if ~dat.OutcomeID
    
    if strcmp(dat.TrialChoice, 'Probe Effort')
        b5.Pass_draw                = DRAW_NONE;
        b5.PassRewardCircle_draw    = DRAW_NONE;
        b5.PassReward_draw          = DRAW_NONE;
        b5.PassString_draw          = DRAW_NONE;
        
        clear tmpMoveShapes tmpFinalPos tmpInitOffset tmpFinalOffset
        tmpMoveShapes = {'RewardCircle', 'Reward', 'BarOutline','ProbeTarget'};
        tmpFinalPos = [Params.Xcenter_pos.RewardCircle, b5.RewardCircle_pos(2); ...
            Params.Xcenter_pos.Reward, b5.Reward_pos(2);...
            Params.Xcenter_pos.BarOutline, b5.BarOutline_pos(2);...
            Params.Xcenter_pos.ProbeTarget, b5.ProbeTarget_pos(2)];
        tmpInitOffset = [0, 0; ...
            -Params.RewardStringOffset(1)+Params.LeftRightRewardStringOffset(1+dat.TakeTrialRight), 0;
            0, 0;
            0, 0];
        tmpFinalOffset = [0, 0; ...
            -Params.RewardStringOffset(1), 0;
            0, 0;
            0, 0];
        for ii = 1:Params.NumEffortTicks
            tmpMoveShapes(end+1) = {sprintf('effortTick%d',ii)};
            
            tmpFinalPos(end+1,:) = b5.(sprintf('effortTick%d_pos',ii));
            tmpFinalPos(end,1) = Params.Xcenter_pos.effortTicks;
            
            tmpInitOffset(end+1,:) = [0,0];
            
            tmpFinalOffset(end+1,:) = [0,0];
        end
        [Params, b5] = moveShape(Params, b5, tmpMoveShapes, ...
            tmpFinalPos,...
            tmpInitOffset,...
            tmpFinalOffset);

        
        
        b5.FillingEffort_draw       = DRAW_BOTH;
        
        b5.GoTone_play_io = 1;
        b5.FillingEffort_scale(2) = 0;
        b5.FillingEffort_pos       = Params.WsCenter - [0, b5.Frame_scale(2)/2];
        b5 = bmi5_mmap(b5);

        dat.GoCue_time_o = b5.GoTone_time_o;

        done            = false;
        posProbeOk      = false;
        dat.FinalCursorPos = [0,0];

        t_start = b5.time_o;
        while ~done
            [Params, dat, b5] = UpdateCursorOnLine(Params, dat, b5);
            pos = b5.Cursor_pos;
            dat.FinalCursorPos = [max(dat.FinalCursorPos(1), pos(1)), 0];
            b5.FillingEffort_scale = [b5.BarOutline_scale(1),...
                max(dat.FinalCursorPos(1)-b5.StartTarget_pos(1),0)];
            b5.FillingEffort_pos       = Params.WsCenter - [0, b5.Frame_scale(2)/2] + ...
                        [0, b5.FillingEffort_scale(2)/2];
            b5 = bmi5_mmap(b5);

            % Check for acquisition of probe target
            posProbeOk 	= dat.ProbeEffort <=(b5.FillingEffort_scale(2) / b5.BarOutline_scale(2));

            if isempty(dat.MovementOnset) && (b5.FillingEffort_scale(1) > 0)
                dat.MovementOnset = b5.time_o;
            end
                
            if posProbeOk
                    done = true;
                    dat.MovementTime = b5.time_o - t_start;
                    dat.OutcomeID 	= 0;
                    dat.OutcomeStr 	= 'Succes';
            end

            % check for TIMEOUT
            if (b5.time_o - t_start) > Params.TimeoutReachTarget
                    dat.MovementTime = b5.time_o - t_start;
                    done            = true;
                    dat.OutcomeID 	= 4;
                    dat.OutcomeStr 	= 'cancel @ reach movement timeout';
            end
        end
    end
    if strcmp(dat.TrialChoice, 'Pass')
        b5.BarOutline_draw          = DRAW_NONE;
        for ii = 1:Params.NumEffortTicks
            b5.(sprintf('effortTick%d_draw',ii))   = DRAW_NONE;
        end    
        b5.RewardCircle_draw        = DRAW_NONE;
        b5.Reward_draw              = DRAW_NONE;
        b5.ProbeTarget_draw         = DRAW_NONE;
        
        clear tmpMoveShapes tmpFinalPos tmpInitOffset tmpFinalOffset
        tmpMoveShapes = {'PassRewardCircle', 'PassReward', 'Pass','PassString'};
        tmpFinalPos = [Params.Xcenter_pos.PassRewardCircle, b5.PassRewardCircle_pos(2); ...
            Params.Xcenter_pos.PassReward, b5.PassReward_pos(2);...
            Params.Xcenter_pos.Pass, b5.Pass_pos(2);...
            Params.Xcenter_pos.PassString, b5.PassString_pos(2)];
        tmpInitOffset = [0, 0; ...
            -Params.PassRewardStringOffset(1)+Params.LeftRightPassRewardStringOffset(1+~dat.TakeTrialRight), 0;
            0, 0;
            -Params.PassStringOffset(1)+Params.LeftRightPassRewardStringOffset(1+~dat.TakeTrialRight), 0];
        tmpFinalOffset = [0, 0; ...
            -Params.PassRewardStringOffset(1), 0;
            0, 0;
            -Params.PassStringOffset(1), 0];

        [Params, b5] = moveShape(Params, b5, tmpMoveShapes, ...
            tmpFinalPos,...
            tmpInitOffset,...
            tmpFinalOffset);
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
                [Params.WsBounds(1,:);Params.WsBounds(1,:)],[0 0; -Params.RewardStringOffset(1) 0], [0 0; -Params.RewardStringOffset(2) 0]);
            b5.RewardCircle_draw    = DRAW_NONE;
            b5.Reward_draw          = DRAW_NONE;
        case 'Pass'
            [Params, b5] = blinkShape(Params, b5, {'Pass', 'PassRewardCircle', 'PassReward'}, [10, 10, 10], 0.5);
            [Params, b5] = moveShape(Params, b5, {'PassRewardCircle', 'PassReward'}, ...
                [Params.WsBounds(1,:);Params.WsBounds(1,:)],[0 0; -Params.PassRewardStringOffset(1) 0], [0 0; -Params.PassRewardStringOffset(2) 0]);
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
    
%     tmpString = sprintf('%0.1f ¢',dat.TotalPoints);
    tmpString = sprintf('$$');
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
%     tmpString = sprintf('%0.1f ¢',dat.TotalPoints);
    tmpString = sprintf('$$');
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