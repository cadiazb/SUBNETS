function [Params, dat, b5] = VerticalFillingBar(Params, dat, b5)

% FOR DRAWING OBJECTS
DRAW_NONE     = 0;
DRAW_SUBJECT  = 1;
DRAW_OPERATOR = 2;
DRAW_BOTH     = 3;

%% Initial sync of hand
% [Params, dat, b5] = UpdateCursor(Params, dat, b5); % this syncs b5 twice

%% Generate a StartTarget position
b5.StartTarget_pos = Params.WsBounds(1,:);

%% Set initial timer bar length
b5.TimerBar_scale(1) = b5.Frame_scale(1);

b5.TimerBar_pos(1) = Params.WsCenter(1) - b5.Frame_scale(1)/2 + ...
                        b5.TimerBar_scale(1)/2;
         

%% Generate the amounts of reward
% dat.ReferenceReward = Params.ReferenceTarget.RewardReference;
% dat.ProbeReward = Params.AdaptiveReward(Params.AdaptiveReward(:,1) == dat.ProbeEffort,2);        
                                
%% Draw rewards from vector
dat.ProbeReward = DrawFromVec(Params.RewardSampleSpace);

tmpStringZeros = 9 - numel(double(sprintf('%d cents',max(Params.VerticalRewardsMatrix(dat.ProbeReward,:)))));
b5.Reward_v = [double(sprintf('%d cents',max(Params.VerticalRewardsMatrix(dat.ProbeReward,:)))) zeros(1,tmpStringZeros)]';

% %% Set coins Y position and initizlize X position
% for ii = 1:5
%     for jj = 1:6
%         b5.(sprintf('Coin0%d_0%d_pos', ii, jj))(2) = ...
%             Params.WsCenter(2) -  b5.Frame_scale(2)/2 + ii*b5.Frame_scale(2)/5;
%         b5.(sprintf('Coin0%d_0%d_pos', ii, jj))(1) = ...
%             Params.WsCenter(1) - 70;
%     end
% end
% 
% for jj = 1:6
%     b5.(sprintf('Coin0%d_0%d_pos', 6, jj))(2) = ...
%         Params.WsCenter(2) -  b5.Frame_scale(2)/2 - 50;
%     b5.(sprintf('Coin0%d_0%d_pos', 6, jj))(1) = ...
%         Params.WsCenter(1) + 40;
% end
% 
% b5.BlackSquare_color = [0 0 0 1];
% b5.BlackSquare_scale = [10 b5.Frame_scale(2)];
% b5.BlackSquare_pos   = Params.WsCenter - [50,0];
% b5.BlackSquare_draw  = DRAW_BOTH;


%% Set effort strings and positions
for ii = [25 100]
    b5.(['EffortLabel' num2str(ii) '_v'])      = [double([num2str(ii) '%']), zeros(1,13)]';
    b5.(['EffortLabel' num2str(ii) '_pos'])  = Params.WsCenter -  [0,b5.Frame_scale(2)/2] + [65, ii*b5.Frame_scale(2)/100];
end


%% Generate delay interval
dat.ReachDelay = DrawFromInterval(Params.ReachDelayRange);
fprintf('Delay\t\t\t%.2f\n',dat.ReachDelay);

%% Misc stuff
dat.OutcomeID 	= 0;
dat.OutcomeStr 	= 'Success';

%% Hide all screen objects
b5.Cursor_draw 		= DRAW_NONE;
b5.StartTarget_draw = DRAW_NONE;
b5.Frame_draw = DRAW_NONE;

for ii = [25 100]
    b5.(['EffortLabel' num2str(ii) '_draw'])      = DRAW_NONE;
end
for ii = 1:3
    b5.(sprintf('effortTick%d_draw',ii))   = DRAW_NONE;
end

b5.Reward_draw      = DRAW_NONE; 

% for ii = 1:5
%     for jj = 1:6
%         b5.(sprintf('Coin0%d_0%d_draw', ii, jj)) = ...
%             DRAW_NONE;
%     end
% end

b5.TimerBar_draw = DRAW_NONE;
b5.ReachTimeout_draw = DRAW_NONE;

b5.EffortLine_draw  = DRAW_NONE;
b5.FillingEffort_draw  = DRAW_NONE;

b5 = bmi5_mmap(b5);
%% Always show points ON/OFF
b5.TotalPoints_draw = DRAW_NONE;

%% Timer off
Params.TimerOn = false;

%% 1. ACQUIRE START TARGET
b5.StartTarget_draw = DRAW_BOTH;
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
    
    for ii = [  100]
        b5.(['EffortLabel' num2str(ii) '_draw'])      = DRAW_BOTH;
    end
    for ii = 1:3
        b5.(sprintf('effortTick%d_draw',ii))   = DRAW_BOTH;
    end
    
    b5.Reward_draw      = DRAW_BOTH;
    
    % Get and draw coins
%     b5 = CoinLookUp([Params.VerticalRewardsMatrix(dat.ProbeReward,:), 41],b5);
    
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
    b5.FillingEffort_draw  = DRAW_BOTH;
    
    b5.GoTone_play_io = 1;
    b5.FillingEffort_scale(2) = 0;
    b5.FillingEffort_pos       = Params.WsCenter - [0, b5.Frame_scale(2)/2] + ...
                    [0, b5.FillingEffort_scale(2)/2];
    b5 = bmi5_mmap(b5);
    system('beep');

	done            = false;
    dat.FinalCursorPos = b5.StartTarget_pos;

	t_start = b5.time_o;
	while ~done
        
        [Params, dat, b5] = UpdateCursorOnLine(Params, dat, b5); % syncs b5 twice
        pos = b5.Cursor_pos;
        dat.FinalCursorPos(1) = max(dat.FinalCursorPos(1), pos(1));
        dat.FinalCursorPos(2) = 0;
        b5.FillingEffort_scale(1) = b5.EffortLine_scale(1);
        b5.FillingEffort_scale(2) = max(dat.FinalCursorPos(1)-Params.WsCenter(1) + b5.Frame_scale(1)/2,...
            0);
        b5.FillingEffort_pos       = Params.WsCenter - [0, b5.Frame_scale(2)/2] + ...
                    [0, b5.FillingEffort_scale(2)/2];
        
        if Params.TimerOn
            AdjustTimerBar;
        end
        
        posOk = TrialInBox(pos,b5.StartTarget_pos,Params.StartTarget.Win);
        
        if ~posOk && isempty(dat.ReactionTime)
            dat.ReactionTime = b5.time_o - t_start;
        end
%         if ~isempty(dat.ReactionTime)
%             if abs(abs(pos(2)) - abs(b5.StartTarget_pos(2))) > Params.NoGoTap
%                 dat.TrialChoice = 'Pass';
%                 done = true;
%                 dat.OutcomeID 	= 0;
%                 dat.OutcomeStr 	= 'success';
%             end
%         end
        
        if ~isempty(dat.ReactionTime)
            if (b5.time_o - (dat.ReactionTime + t_start)) > Params.MovementWindow
%                 dat.MovementTime = NaN;
                dat.ActualEffort = (pos(1) - b5.StartTarget_pos(1)) /...
                                        b5.Frame_scale(1); % Force as %of Max
    %             dat.FinalCursorPos = pos;
                dat.TrialChoice = 'Probe Effort';
                done            = true;
                dat.OutcomeID 	= 0;
                dat.OutcomeStr 	= 'success';
            end
        else
            if (b5.time_o - t_start) > Params.ReactionTimeDelay
                done = true;
                dat.ReactionTime = NaN;
                dat.OutcomeID 	= 4;
                dat.OutcomeStr 	= 'cancel @ reaction';
            end
        end
            
        
        % update hand
	end
end

%% Trial outcome and variable adaptation
b5.Cursor_draw 		= DRAW_NONE;
b5.StartTarget_draw = DRAW_NONE;
b5.Frame_draw = DRAW_NONE;

for ii = [25 100]
    b5.(['EffortLabel' num2str(ii) '_draw'])      = DRAW_NONE;
end
for ii = 1:3
    b5.(sprintf('effortTick%d_draw',ii))   = DRAW_NONE;
end

b5.Reward_draw      = DRAW_NONE;

% for ii = 1:6
%     for jj = 1:6
%         b5.(sprintf('Coin0%d_0%d_draw', ii, jj)) = ...
%             DRAW_NONE;
%     end
% end

b5.EffortLine_draw  = DRAW_NONE;
b5.FillingEffort_draw  = DRAW_NONE;

if dat.OutcomeID == 0
%     if floor(0.05+b5.FillingEffort_scale(2)/b5.Frame_scale(2)*5)
    if strcmp(dat.TrialChoice, 'Probe Effort')
        tmpTrialPoints = (max(Params.VerticalRewardsMatrix(dat.ProbeReward,:))) * ...
            ((0.05+b5.FillingEffort_scale(2)/b5.Frame_scale(2)));
    else
        tmpTrialPoints = 0;
    end
%         b5 = CoinLookUp([0 0 0 0 0 tmpTrialPoints], b5);
%         for jj = 1:6
%             b5.(sprintf('Coin0%d_0%d_pos', 6, jj))(2) = ...
%                 Params.WsCenter(2) - 20;
%         end
%     else
%         tmpTrialPoints = 0;
%     end
    
    dat.TotalPoints = dat.TotalPoints + tmpTrialPoints;
    
    tmpStringZeros = 32 - numel(double(sprintf('Earned = %0.1f cents',tmpTrialPoints)));
    b5.TotalPoints_v = [double(sprintf('Earned = %0.1f cents',tmpTrialPoints)) zeros(1,tmpStringZeros)]';

    fprintf('Trial Choice\t\t%s \n',dat.TrialChoice);
    fprintf('Effort\t\t%f \n',dat.ActualEffort);
    fprintf('Total points\t\t%d \n',dat.TotalPoints);
	
    b5.RewardTone_play_io = 1;
    Params.RewardSampleSpace(find(Params.RewardSampleSpace == dat.ProbeReward, 1)) = [];
else
    tmpStringZeros = 32 - numel(double(sprintf('Earned =%0.1f',0)));
    b5.TotalPoints_v = [double(sprintf('Earned =%0.1f',0)) zeros(1,tmpStringZeros)]';  
end

if Params.UseRewardAdaptation
    [Params, dat] = CalculateAdaptiveVariable(Params, dat, b5);
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
% for jj = 1:6
%     b5.(sprintf('Coin0%d_0%d_draw', 6, jj)) = ...
%             DRAW_NONE;
% end
% b5.CheatTarget_draw = DRAW_NONE;

%%% XXX TODO: NEED WAY TO LOG (MORE) INTERESTING TRIAL EVENTS

end