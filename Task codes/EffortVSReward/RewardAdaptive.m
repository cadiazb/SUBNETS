function [Params, dat, b5] = RewardAdaptive(Params, dat, b5)

global DEBUG

% FOR DRAWING OBJECTS
DRAW_NONE     = 0;
DRAW_SUBJECT  = 1;
DRAW_OPERATOR = 2;
DRAW_BOTH     = 3;

%% Initial sync of hand
% [Params, dat, b5] = UpdateCursor(Params, dat, b5); % this syncs b5 twice

%% Generate a StartTarget position
b5.StartTarget_pos = Params.WsCenter;

%% Set initial timer bare length
b5.TimerBar_scale(1) = b5.Frame_scale(1);

b5.TimerBar_pos(1) = Params.WsCenter(1) - b5.Frame_scale(1)/2 + ...
                        b5.TimerBar_scale(1)/2;
%% Draw Probe effort from vector

dat.ProbeEffort         = DrawFromVec(Params.EffortSampleSpace);


dat.ReferenceEffort     = Params.ReferenceTarget.EffortReference * ...
                                Params.MaxForce * (b5.Frame_scale(2)/2)/50;

dat.ProbeEffortUp       = DrawFromVec([0 1]); % Randomize Probe effort direction

%% Generate ProbeEffortTarget and Reference Target positions
b5.ProbeEffortTarget_pos 		= b5.StartTarget_pos;
b5.ReferenceTarget_pos          = b5.StartTarget_pos;


b5.ProbeEffortTarget_pos(2) 	= b5.ProbeEffortTarget_pos(2) - ...
                                (-1)^dat.ProbeEffortUp...
                                        * 50;

b5.ReferenceTarget_pos(2)       = b5.ReferenceTarget_pos(2) + ...
                                (-1)^dat.ProbeEffortUp...
                                        * 50;

b5.ProbeEffortAxis_pos  = b5.ProbeEffortTarget_pos;
b5.ReferenceAxis_pos    = b5.ReferenceTarget_pos;
%% Update target width according

 b5.ProbeEffortTarget_scale             = [dat.ProbeEffort + 20, 15];
 b5.ReferenceTarget_scale               = [dat.ReferenceEffort + 20, 15];
         

%% Generate the amounts of reward
dat.ReferenceReward = Params.ReferenceTarget.RewardReference;
dat.ProbeReward = Params.AdaptiveReward(Params.AdaptiveReward(:,1) == dat.ProbeEffort,2);


%% Set reward string position
b5.ProbeRewardString_pos        = (b5.ProbeEffortTarget_pos - ...
                            (-1)^dat.ProbeEffortUp * [0 25]) + ...
                            [0 5];

b5.ReferenceRewardString_pos    = (b5.ReferenceTarget_pos + ...
                            (-1)^dat.ProbeEffortUp * [0 25]) + ...
                            [0 5];
        
                                
%% Set reward strings
b5.ProbeRewardString_v = [double(sprintf('%03d',dat.ProbeReward)) zeros(1,29)]';


b5.ReferenceRewardString_v = [double(sprintf('%03d',dat.ReferenceReward)) zeros(1,29)]';

b5 = bmi5_mmap(b5);

fprintf('Probe Effort \t\t%d\n',dat.ProbeEffort);
fprintf('Probe reward \t\t%d\n',dat.ProbeReward);

%% Set effort strings and positions
b5.ProbeEffortString_v      = [double(sprintf('%02d Lb',...
    round(dat.ProbeEffort / ((b5.Frame_scale(2)/2)/50))...
    )) zeros(1,27)]';

b5.ReferenceEffortString_v  = [double(sprintf('%02d Lb',...
    round(dat.ReferenceEffort / ((b5.Frame_scale(2)/2)/50))...
    )) zeros(1,27)]';

b5.ProbeEffortString_pos        = b5.ProbeEffortTarget_pos + [0, 2];
b5.ReferenceEffortString_pos    = b5.ReferenceTarget_pos + [0, 2];


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

b5.ReferenceTarget_draw = DRAW_NONE;
b5.ReferenceAxis_draw = DRAW_NONE;
b5.ReferenceRewardString_draw = DRAW_NONE;
b5.ReferenceEffortString_draw = DRAW_NONE;

b5.TimerBar_draw = DRAW_NONE;
b5.ReachTimeout_draw = DRAW_NONE;

%% Always show points ON/OFF
b5.TotalPoints_draw = DRAW_NONE;

%% 1. ACQUIRE START TARGET
b5.StartTone_play_io = 1;
b5.Cursor_draw = DRAW_BOTH;
b5.StartTarget_draw = DRAW_BOTH;
b5.StartAxis_draw = DRAW_BOTH;
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
    [Params, dat, b5] = UpdateCursor(Params, dat, b5); % syncs b5 twice

end

%% 2. INSTRUCTED DELAY PHASE
if ~dat.OutcomeID
% b5 = JuiceStart(b5,Params.Reward/10);
    b5.ReferenceTarget_draw = DRAW_BOTH;
    b5.ReferenceAxis_draw = DRAW_BOTH;
    b5.ReferenceEffortString_draw = DRAW_BOTH;
    b5.ReferenceRewardString_draw = DRAW_BOTH; 
    
    b5.ProbeEffortTarget_draw 	= DRAW_BOTH;
    b5.ProbeEffortAxis_draw = DRAW_BOTH; 
    b5.ProbeEffortString_draw = DRAW_BOTH;
    b5.ProbeRewardString_draw = DRAW_BOTH;
    
    if Params.TimerOn
        b5.TimerBar_draw = DRAW_BOTH;
        b5.ReachTimeout_draw = DRAW_BOTH;
    end
   
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
        [Params, dat, b5] = UpdateCursor(Params, dat, b5); % syncs b5 twice
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
    b5.StartAxis_draw = DRAW_NONE;
    b5.GoTone_play_io = 1;
    b5 = bmi5_mmap(b5);

	done            = false;
	gotPos          = false;
    gotIntention    = 0;

	t_start = b5.time_o;
	while ~done

        pos = b5.Cursor_pos;
        if Params.TimerOn
            AdjustTimerBar;
        end
        
        % Check for Reaction Time
        
        posStartOk = TrialInBox(pos,b5.StartTarget_pos,Params.StartTarget.Win);
        
		% Check for acquisition of a reach target

        posProbeOk 	= EffortInBox(pos, b5.StartTarget_pos, b5.ProbeEffortTarget_pos, b5.ProbeEffortTarget_scale);
        posRefOk 	= EffortInBox(pos, b5.StartTarget_pos, b5.ReferenceTarget_pos, b5.ReferenceTarget_scale);


        intentionProbe 	= EffortInBox(pos, b5.StartTarget_pos, b5.ProbeEffortTarget_pos/2, b5.ProbeEffortTarget_scale);
        intentionRef 	= EffortInBox(pos, b5.StartTarget_pos, b5.ReferenceTarget_pos/2, b5.ReferenceTarget_scale);



        if ~posStartOk && isempty(dat.ReactionTime)
            dat.ReactionTime = b5.time_o - t_start;
        elseif (b5.time_o - t_start) > Params.ReactionTimeDelay && posStartOk
            dat.ReactionTime = b5.time_o - t_start;
            dat.MovementTime = NaN;
            done            = true;
            dat.OutcomeID 	= 4;
            dat.OutcomeStr 	= 'cancel @ reaction';
        end
            
        if ~posRefOk && ~posProbeOk
            gotPos = false;
        end
        
        if ~gotIntention
            if intentionProbe
                gotIntention = 1; %Probe effort
            end
            if intentionRef
                gotIntention = 2; %Ref effort
            end
        else
            if intentionProbe && (gotIntention == 2)
                dat.MovementTime = b5.time_o - t_start - dat.ReactionTime;
                done            = true;
                dat.OutcomeID 	= 4;
                dat.OutcomeStr 	= 'cancel @ Backtrack for Ref';
            end
            if intentionRef && (gotIntention == 1)
                dat.MovementTime = b5.time_o - t_start - dat.ReactionTime;
                done            = true;
                dat.OutcomeID 	= 4;
                dat.OutcomeStr 	= 'cancel @ Backtrack for Probe';
            end
        end
        
		if posProbeOk && (gotIntention == 1)
			if ~gotPos
				gotPos    = true;
				starthold = b5.time_o;
			end
			if (b5.time_o - starthold) > Params.ProbeEffortTarget.Hold
				done = true;

                dat.TrialChoice = 'Probe Effort';
                dat.MovementTime = b5.time_o - t_start - dat.ReactionTime;
                dat.OutcomeID 	= 0;
                dat.OutcomeStr 	= 'Succes';
                    
			end
		end

		if posRefOk && (gotIntention == 2)
            if ~gotPos
				gotPos    = true;
				starthold = b5.time_o;
            end
			if (b5.time_o - starthold) > Params.BigEffortTarget.Hold
				done = true;

                dat.TrialChoice = 'Reference Effort';
                dat.MovementTime = b5.time_o - t_start - dat.ReactionTime;
                dat.OutcomeID 	= 0;
                dat.OutcomeStr 	= 'Succes'; 
			end
		end

		% check for TIMEOUT
        if ~isempty(dat.ReactionTime)
            if (b5.time_o - t_start - dat.ReactionTime) > Params.TimeoutReachTarget
                dat.MovementTime = b5.time_o - t_start - dat.ReactionTime;
                done            = true;
                dat.OutcomeID 	= 4;
                dat.OutcomeStr 	= 'cancel @ reach movement timeout';
            end
        end
        
        % update hand
        [Params, dat, b5] = UpdateCursor(Params, dat, b5); % syncs b5 twice
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

b5.ReferenceTarget_draw = DRAW_NONE;
b5.ReferenceAxis_draw = DRAW_NONE;
b5.ReferenceRewardString_draw = DRAW_NONE;
b5.ReferenceEffortString_draw = DRAW_NONE;

if dat.OutcomeID == 0

    if strcmp(dat.TrialChoice, 'Probe Effort')
        dat.TotalPoints = dat.TotalPoints + dat.ProbeReward;
    end

    if strcmp(dat.TrialChoice, 'Reference Effort')
        dat.TotalPoints = dat.TotalPoints + dat.ReferenceReward;
    end
    
    b5.TotalPoints_v = [double(sprintf('You got it! Points = %05d',dat.TotalPoints)) zeros(1,6)]';

    [Params, dat] = CalculateAdaptiveVariable(Params, dat, b5);
    
    Params.EffortSampleSpace(find(Params.EffortSampleSpace == dat.ProbeEffort, 1)) = [];
    
    fprintf('Choice\t\t%s \n',dat.TrialChoice);
    fprintf('Total points\t\t%d \n',dat.TotalPoints);
	
    b5.RewardTone_play_io = 1;

else
    b5.TotalPoints_v = [double(sprintf('Let''s try again. Points = %05d',dat.TotalPoints)) zeros(1,1)]';
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
%     [Params, dat, b5] = UpdateCursor(Params, dat, b5); % syncs b5 twice
end
b5.TimerBar_draw = DRAW_NONE;
b5.ReachTimeout_draw = DRAW_NONE;
% b5.CheatTarget_draw = DRAW_NONE;

%%% XXX TODO: NEED WAY TO LOG (MORE) INTERESTING TRIAL EVENTS

end