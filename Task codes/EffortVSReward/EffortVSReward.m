function [Params, dat, b5] = EffortVSReward(Params, dat, b5)

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

%% Draw Small and Big efforts from vector or reward in case of trial 9
if dat.TrialType ~= 9
    dat.SmallEffort         = DrawFromVec(Params.SmallEffortTarget.EffortVector) * ...
                                    Params.MaxForce * (b5.Frame_scale(2)/2)/50;
    dat.BigEffort           = DrawFromVec(Params.BigEffortTarget.EffortVector) * ...
                                    Params.MaxForce * (b5.Frame_scale(2)/2)/50;
else
    dat.SmallReward         = DrawFromVec(Params.SmallEffortTarget.RewardVector);
    dat.BigReward           = DrawFromVec(Params.BigEffortTarget.RewardVector);
    
    dat.SmallEffort = ...
        Params.AdaptiveForce(Params.AdaptiveForce(:,1) == dat.SmallReward,2);
    dat.BigEffort = ...
        Params.AdaptiveForce(Params.AdaptiveForce(:,1) == dat.BigReward,2);
end

dat.ReferenceEffort     = Params.ReferenceTarget.EffortReference * ...
                                Params.MaxForce * (b5.Frame_scale(2)/2)/50;

dat.SmallEffortUp       = DrawFromVec([0 1]); % Randomize small effort direction

%% For trial 6 - 9 randomize RefvsSmall and RefvsBig
switch dat.TrialType
    case {6 7 8 9}
        dat.ShowSmallEffort     = DrawFromVec([0 1]); % =1 is RefvsSmall
    otherwise
        dat.ShowSmallEffort     = 1;
end

%% Generate SmallEffortTarget, BigEffortTarget and Reference Target positions
b5.SmallEffortTarget_pos 		= b5.StartTarget_pos;
b5.BigEffortTarget_pos          = b5.StartTarget_pos;
b5.ReferenceTarget_pos          = b5.StartTarget_pos;

switch dat.TrialType
    case {1 2 3 7}
        b5.SmallEffortTarget_pos(2) 	= b5.SmallEffortTarget_pos(2) - ...
                                        (-1)^dat.SmallEffortUp...
                                                * (dat.SmallEffort + b5.SmallEffortTarget_scale(2)/2);

        b5.BigEffortTarget_pos(2)       = b5.BigEffortTarget_pos(2) + ...
                                        (-1)^dat.SmallEffortUp...
                                                * (dat.BigEffort + b5.BigEffortTarget_scale(2)/2);
                                            
        b5.ReferenceTarget_pos(2)       = b5.ReferenceTarget_pos(2) - ...
                                        (-1)^(dat.SmallEffortUp+dat.ShowSmallEffort)...
                                                * (dat.ReferenceEffort + b5.ReferenceTarget_scale(2)/2);
    case {4 5 6 8 9}
        b5.SmallEffortTarget_pos(2) 	= b5.SmallEffortTarget_pos(2) - ...
                                        (-1)^dat.SmallEffortUp...
                                                * 50;

        b5.BigEffortTarget_pos(2)       = b5.BigEffortTarget_pos(2) + ...
                                        (-1)^dat.SmallEffortUp...
                                                * 50;
                                            
        b5.ReferenceTarget_pos(2)       = b5.ReferenceTarget_pos(2) - ...
                                        (-1)^(dat.SmallEffortUp+dat.ShowSmallEffort)...
                                                * 50;
    otherwise
        b5.SmallEffortTarget_pos(2) 	= b5.SmallEffortTarget_pos(2) - ...
                                        (-1)^dat.SmallEffortUp...
                                                * (dat.SmallEffort + b5.SmallEffortTarget_scale(2)/2);

        b5.BigEffortTarget_pos(2)       = b5.BigEffortTarget_pos(2) + ...
                                        (-1)^dat.SmallEffortUp...
                                                * (dat.BigEffort + b5.BigEffortTarget_scale(2)/2);
end
b5.SmallEffortAxis_pos  = b5.SmallEffortTarget_pos;
b5.BigEffortAxis_pos    = b5.BigEffortTarget_pos;
b5.ReferenceAxis_pos    = b5.ReferenceTarget_pos;
%% Update target bar X scale according to trial type
switch dat.TrialType
    case 1
         b5.SmallEffortTarget_scale             = [300 10];
         b5.BigEffortTarget_scale               = [300 10];
    case {2 3 4 5 6 7 8 9}
         b5.SmallEffortTarget_scale             = [dat.SmallEffort + 20, 15];
         b5.BigEffortTarget_scale               = [dat.BigEffort + 20, 15];
         b5.ReferenceTarget_scale               = [dat.ReferenceEffort + 20, 15];
    otherwise
         b5.SmallEffortTarget_scale             = [395 10];
         b5.BigEffortTarget_scale               = [395 10];
end
         

%% Calculate effort bar sizes
b5.SmallEffortBar_scale(1)  = dat.SmallEffort ;
b5.BigEffortBar_scale(1)    = dat.BigEffort ;

b5.SmallEffortBar_pos      = [Params.WsBounds(1,1) - dat.SmallEffort/2, ...
                                Params.WsCenter(2) - (-1)^dat.SmallEffortUp * 10];
b5.BigEffortBar_pos      = [Params.WsBounds(1,1) - dat.BigEffort/2, ...
                                Params.WsCenter(2) + (-1)^dat.SmallEffortUp * 10];
%% Calculate Max Force bar size
b5.MaxForceBar_scale(1)    = Params.MaxForce * (b5.Frame_scale(2)/2)/50;
b5.MaxForceBar_pos         = b5.StartTarget_pos;
% b5.MaxForceBar_pos         = [Params.WsBounds(1) - b5.MaxForceBar_scale(1)/2 , ...
%                                 Params.WsCenter(2)];
%% Generate the amounts of reward
switch dat.TrialType
    case {1 2 3 4 5 6 7}
        dat.SmallReward = DrawFromVec(Params.SmallEffortTarget.RewardVector);
        dat.BigReward = DrawFromVec(Params.BigEffortTarget.RewardVector);
        dat.ReferenceReward = Params.ReferenceTarget.RewardReference;
    case {8}
        dat.ReferenceReward = Params.ReferenceTarget.RewardReference;
        dat.SmallReward = Params.AdaptiveReward(Params.AdaptiveReward(:,1) == dat.SmallEffort,2);
        dat.BigReward = Params.AdaptiveReward(Params.AdaptiveReward(:,1) == dat.BigEffort,2);
    case {9}
        dat.ReferenceReward = Params.ReferenceTarget.RewardReference;
end


%% Set reward circles size and position
try
b5.SmallRewardCircle_scale      = [1 1] * dat.SmallReward/5;
b5.BigRewardCircle_scale      = [1 1] * dat.BigReward/5;
b5.ReferenceRewardCircle_scale      = [1 1] * dat.ReferenceReward/5;
catch
    dat.SmallReward;
end

switch dat.TrialType
    case {2 4}
        b5.SmallRewardCircle_pos        = b5.SmallEffortTarget_pos - ...
                                    (-1)^dat.SmallEffortUp * [0 25];
                               
        b5.BigRewardCircle_pos          = b5.BigEffortTarget_pos + ...
                                    (-1)^dat.SmallEffortUp * [0 25];
    case {3 5}
        b5.SmallRewardCircle_pos        = b5.SmallEffortTarget_pos + [80 0];
                               
        b5.BigRewardCircle_pos          = b5.BigEffortTarget_pos + [80 0];
    case {6 7 8 9}
        b5.SmallRewardCircle_pos        = b5.SmallEffortTarget_pos - ...
                                    (-1)^dat.SmallEffortUp * [0 25];
                               
        b5.BigRewardCircle_pos          = b5.BigEffortTarget_pos + ...
                                    (-1)^dat.SmallEffortUp * [0 25];
                                
        b5.ReferenceRewardCircle_pos    = b5.ReferenceTarget_pos - ...
                                    (-1)^(dat.SmallEffortUp+dat.ShowSmallEffort) * [0 25];
        
    otherwise
        b5.SmallRewardCircle_pos        = b5.SmallEffortTarget_pos - ...
                                    (-1)^dat.SmallEffortUp * [0 25];
                               
        b5.BigRewardCircle_pos          = b5.BigEffortTarget_pos + ...
                                    (-1)^dat.SmallEffortUp * [0 25];
end
                                
%% Set reward strings and positions
b5.SmallRewardString_v = [double(sprintf('%03d',dat.SmallReward)) zeros(1,29)]';
b5.SmallRewardString_pos = b5.SmallRewardCircle_pos + [120 65];


b5.BigRewardString_v = [double(sprintf('%03d',dat.BigReward)) zeros(1,29)]';
b5.BigRewardString_pos = b5.BigRewardCircle_pos + [120 65];

b5.ReferenceRewardString_v = [double(sprintf('%03d',dat.ReferenceReward)) zeros(1,29)]';
b5.ReferenceRewardString_pos = b5.ReferenceRewardCircle_pos + [120 65];

b5 = bmi5_mmap(b5);

fprintf('Small Effort \t\t%d\n',dat.SmallEffort);
fprintf('Big Effort \t\t%d\n',dat.BigEffort);
fprintf('Small reward \t\t%d\n',dat.SmallReward);
fprintf('Big reward \t\t%d\n',dat.BigReward);

%% Set effort strings and positions
b5.SmallEffortString_v      = [double(sprintf('%02d Lb',...
    round(dat.SmallEffort / ((b5.Frame_scale(2)/2)/50))...
    )) zeros(1,27)]';
b5.BigEffortString_v        = [double(sprintf('%02d Lb',...
    round(dat.BigEffort / ((b5.Frame_scale(2)/2)/50))...
    )) zeros(1,27)]';
b5.ReferenceEffortString_v  = [double(sprintf('%02d Lb',...
    round(dat.ReferenceEffort / ((b5.Frame_scale(2)/2)/50))...
    )) zeros(1,27)]';

b5.SmallEffortString_pos        = b5.SmallEffortTarget_pos + [120, 64];
b5.BigEffortString_pos          = b5.BigEffortTarget_pos + [120, 64];
b5.ReferenceEffortString_pos    = b5.ReferenceTarget_pos + [120, 64];

%% Calculate size of big effort target
% b5.BigEffortTarget_scale     = [20 20]*...
%             (dat.BigReward/dat.SmallReward);
% 
% b5 = bmi5_mmap(b5);
    
% if dat.RewardedTargetID == 0
% 	dat.RewardedTargetStr = 'left';
% else
% 	dat.RewardedTargetStr = 'right';
% end



    
% if dat.RewardedTargetID == 0
%     b5.CheatTarget_pos = b5.SmallEffortTarget_pos;
% else
%     b5.CheatTarget_pos = b5.BigEffortTarget_pos;
% end

%% Generate delay interval
dat.ReachDelay = DrawFromInterval(Params.ReachDelayRange);
fprintf('Delay\t\t\t%.2f\n',dat.ReachDelay);

%% Push ICMS settings to TDT here
% b5 = ICMS_SetParams(b5, dat.ICMS);
% fprintf('Laser Power Current\t\t%.2f mW\n',dat.ICMS.AmpUA);
% fprintf('ICMS Cathode Chans\t[ ');
% for ch=1:length(dat.ICMS.CathodeVec)
%     fprintf('%01i ',dat.ICMS.CathodeVec(ch));
% end
% fprintf(']\n');
% fprintf('ICMS Anode Chans\t[ ');
% for ch=1:length(dat.ICMS.AnodeVec)
%     fprintf('%01i ',dat.ICMS.AnodeVec(ch));
% end
% fprintf(']\n');

%% Misc stuff
dat.OutcomeID 	= 0;
dat.OutcomeStr 	= 'Success';

%% Hide all screen objects
b5.Cursor_draw 		= DRAW_NONE;
b5.StartTarget_draw = DRAW_NONE;
b5.StartAxis_draw = DRAW_NONE;
b5.SmallEffortTarget_draw 	= DRAW_NONE;
b5.BigEffortTarget_draw = DRAW_NONE;
b5.Frame_draw = DRAW_NONE;
b5.SmallRewardString_draw = DRAW_NONE; 
b5.BigRewardString_draw = DRAW_NONE;
b5.SmallEffortString_draw = DRAW_NONE; 
b5.BigEffortString_draw = DRAW_NONE;
b5.ReferenceEffortString_draw = DRAW_NONE;
b5.SmallEffortBar_draw = DRAW_NONE; 
b5.BigEffortBar_draw = DRAW_NONE;
b5.MaxForceBar_draw = DRAW_NONE;
b5.SmallEffortAxis_draw = DRAW_NONE; 
b5.BigEffortAxis_draw = DRAW_NONE;
b5.SmallRewardCircle_draw = DRAW_NONE; 
b5.BigRewardCircle_draw = DRAW_NONE;
b5.ReferenceTarget_draw = DRAW_NONE;
b5.ReferenceAxis_draw = DRAW_NONE;
b5.ReferenceRewardCircle_draw = DRAW_NONE;
b5.ReferenceRewardString_draw = DRAW_NONE;

%% Always show points
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
    b5.MaxForceBar_draw = DRAW_NONE;
    switch dat.TrialType
        case {2 3 4 5}
            b5.SmallEffortTarget_draw 	= DRAW_BOTH;
            b5.BigEffortTarget_draw = DRAW_BOTH;
%             b5.SmallRewardString_draw = DRAW_BOTH; 
            b5.BigRewardString_draw = DRAW_BOTH;
            b5.SmallEffortAxis_draw = DRAW_BOTH; 
            b5.BigEffortAxis_draw = DRAW_BOTH;
            b5.SmallRewardCircle_draw = DRAW_BOTH; 
            b5.BigRewardCircle_draw = DRAW_BOTH;
        case {6 7 8 9}
            b5.ReferenceTarget_draw = DRAW_BOTH;
            b5.ReferenceAxis_draw = DRAW_BOTH;
%             b5.ReferenceRewardCircle_draw = DRAW_BOTH;
%             b5.ReferenceRewardString_draw = DRAW_BOTH;
            b5.ReferenceEffortString_draw = DRAW_BOTH;
            if dat.ShowSmallEffort
                b5.SmallEffortTarget_draw 	= DRAW_BOTH;
                b5.SmallRewardString_draw = DRAW_BOTH; 
                b5.SmallEffortAxis_draw = DRAW_BOTH; 
%                 b5.SmallRewardCircle_draw = DRAW_BOTH;
                b5.SmallEffortString_draw = DRAW_BOTH;
            else
                b5.BigEffortTarget_draw = DRAW_BOTH;
                b5.BigRewardString_draw = DRAW_BOTH;
                b5.BigEffortAxis_draw = DRAW_BOTH;
%                 b5.BigRewardCircle_draw = DRAW_BOTH;
                b5.BigEffortString_draw = DRAW_BOTH;
            end
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
%             b5.SmallEffortTarget_draw 	= DRAW_NONE;
%             b5.SmallEffortTarget_draw 	= DRAW_BOTH;
%         end
        % update hand
        [Params, dat, b5] = UpdateCursor(Params, dat, b5); % syncs b5 twice
    end
end
% if dat.RewardedTargetID == dat.ICMS.TargetID
%     b5.CheatTarget_draw = DRAW_NONE;
%     b5.SmallEffortTarget_draw 	= DRAW_NONE;
%     b5.SmallEffortTarget_draw 	= DRAW_BOTH;
% end


%% 3. REACHING PHASE (reach to target and hold)
if ~dat.OutcomeID
    
    b5.StartTarget_draw = DRAW_NONE;
    b5.GoTone_play_io = 1;
    b5 = bmi5_mmap(b5);

	done            = false;
	gotPos          = false;
    gotIntention    = 0;
    posStartOk      = 1;

	t_start = b5.time_o;
	while ~done

        pos = b5.Cursor_pos;
        
        % Check for Reaction Time
        
        posStartOk = TrialInBox(pos,b5.StartTarget_pos,Params.StartTarget.Win);
        
		% Check for acquisition of a reach target
        switch dat.TrialType
            case {6 7 8 9}
                if dat.ShowSmallEffort
                    posSmallOk 	= EffortInBox(pos, b5.StartTarget_pos, b5.SmallEffortTarget_pos, b5.SmallEffortTarget_scale);
                    posBigOk 	= EffortInBox(pos, b5.StartTarget_pos, b5.ReferenceTarget_pos, b5.ReferenceTarget_scale);
                else
                    posSmallOk 	= EffortInBox(pos, b5.StartTarget_pos, b5.ReferenceTarget_pos, b5.ReferenceTarget_scale);
                    posBigOk 	= EffortInBox(pos, b5.StartTarget_pos, b5.BigEffortTarget_pos, b5.BigEffortTarget_scale);
                end
                if dat.ShowSmallEffort
                    intentionSmall 	= EffortInBox(pos, b5.StartTarget_pos, b5.SmallEffortTarget_pos/2, b5.SmallEffortTarget_scale);
                    intentionBig 	= EffortInBox(pos, b5.StartTarget_pos, b5.ReferenceTarget_pos/2, b5.ReferenceTarget_scale);
                else
                    intentionSmall 	= EffortInBox(pos, b5.StartTarget_pos, b5.ReferenceTarget_pos/2, b5.ReferenceTarget_scale);
                    intentionBig 	= EffortInBox(pos, b5.StartTarget_pos, b5.BigEffortTarget_pos/2, b5.BigEffortTarget_scale);
                end
            otherwise
                posSmallOk 	= EffortInBox(pos, b5.StartTarget_pos, b5.SmallEffortTarget_pos, b5.SmallEffortTarget_scale);
                posBigOk 	= EffortInBox(pos, b5.StartTarget_pos, b5.BigEffortTarget_pos, b5.BigEffortTarget_scale);
                intentionSmall 	= EffortInBox(pos, b5.StartTarget_pos, b5.SmallEffortTarget_pos/2, b5.SmallEffortTarget_scale);
                intentionBig 	= EffortInBox(pos, b5.StartTarget_pos, b5.BigEffortTarget_pos/2, b5.BigEffortTarget_scale);
        end

        if ~posStartOk && isempty(dat.ReactionTime)
            dat.ReactionTime = b5.time_o - t_start;
        elseif (b5.time_o - t_start) > Params.ReactionTimeDelay
            dat.ReactionTime = b5.time_o - t_start;
            dat.MovementTime = NaN;
            done            = true;
            dat.OutcomeID 	= 4;
            dat.OutcomeStr 	= 'cancel @ reaction';
        end
            
        if ~posBigOk && ~posSmallOk
            gotPos = false;
        end
        
        if ~gotIntention
            if intentionSmall
                gotIntention = 1; %Small effort
            end
            if intentionBig
                gotIntention = 2; %Big effort
            end
        else
            if intentionSmall && (gotIntention == 2)
                dat.MovementTime = b5.time_o - t_start - dat.ReactionTime;
                done            = true;
                dat.OutcomeID 	= 4;
                dat.OutcomeStr 	= 'cancel @ Backtrack for big';
            end
            if intentionBig && (gotIntention == 1)
                dat.MovementTime = b5.time_o - t_start - dat.ReactionTime;
                done            = true;
                dat.OutcomeID 	= 4;
                dat.OutcomeStr 	= 'cancel @ Backtrack for small';
            end
        end
        
		if posSmallOk && (gotIntention == 1)
			if ~gotPos
				gotPos    = true;
				starthold = b5.time_o;
			end
			if (b5.time_o - starthold) > Params.SmallEffortTarget.Hold
				done = true;
                switch dat.TrialType
                    case {6 7 8 9}
                        if dat.ShowSmallEffort
                            dat.TrialChoice = 'Small Effort';
                        else
                            dat.TrialChoice = 'Reference Effort';
                        end
                    otherwise
                        dat.TrialChoice = 'Small Effort';
                end
                dat.MovementTime = b5.time_o - t_start - dat.ReactionTime;
                dat.OutcomeID 	= 0;
                dat.OutcomeStr 	= 'Succes';
                    
			end
		end

		if posBigOk && (gotIntention == 2)
            if ~gotPos
				gotPos    = true;
				starthold = b5.time_o;
            end
			if (b5.time_o - starthold) > Params.BigEffortTarget.Hold
				done = true;
                switch dat.TrialType
                    case {6 7 8 9}
                        if dat.ShowSmallEffort
                            dat.TrialChoice = 'Reference Effort';
                        else
                            dat.TrialChoice = 'Big Effort';
                        end
                    otherwise
                        dat.TrialChoice = 'Big Effort';
                end
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
b5.SmallEffortTarget_draw 	= DRAW_NONE;
b5.BigEffortTarget_draw = DRAW_NONE;
b5.SmallRewardString_draw = DRAW_NONE; 
b5.BigRewardString_draw = DRAW_NONE;
b5.SmallEffortBar_draw = DRAW_NONE; 
b5.BigEffortBar_draw = DRAW_NONE;
b5.MaxForceBar_draw = DRAW_NONE;
b5.SmallEffortAxis_draw = DRAW_NONE; 
b5.BigEffortAxis_draw = DRAW_NONE;
b5.SmallRewardCircle_draw = DRAW_NONE; 
b5.BigRewardCircle_draw = DRAW_NONE;
b5.ReferenceTarget_draw = DRAW_NONE;
b5.ReferenceAxis_draw = DRAW_NONE;
b5.ReferenceRewardCircle_draw = DRAW_NONE;
b5.ReferenceRewardString_draw = DRAW_NONE;
b5.SmallEffortString_draw = DRAW_NONE; 
b5.BigEffortString_draw = DRAW_NONE;
b5.ReferenceEffortString_draw = DRAW_NONE;

if dat.OutcomeID == 0
%     Params.RewardActual=Params.Reward*(1+(dat.ReachDelay-Params.ReachDelayRange(1))/(Params.ReachDelayRange(2)-Params.ReachDelayRange(1)))/2;

    Params.RewardActual=Params.Reward*Params.TempPerf+Params.Reward/6;
    if strcmp(dat.TrialChoice, 'Small Effort')
        dat.TotalPoints = dat.TotalPoints + dat.SmallReward;
    end
    if strcmp(dat.TrialChoice, 'Big Effort')
        dat.TotalPoints = dat.TotalPoints + dat.BigReward;
    end
    if strcmp(dat.TrialChoice, 'Reference Effort')
        dat.TotalPoints = dat.TotalPoints + dat.ReferenceReward;
    end
    
    b5.TotalPoints_v = [double(sprintf('You got it! Points = %05d',dat.TotalPoints)) zeros(1,6)]';

    [Params, dat] = CalculateAdaptiveVariable(Params, dat, b5);
    
    fprintf('Reward\t\t%.2f mSec\n',Params.RewardActual);
    fprintf('Choice\t\t%s \n',dat.TrialChoice);
    fprintf('Total points\t\t%d \n',dat.TotalPoints);
%     b5 = JuiceStart(b5,Params.RewardActual);
	
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
    [Params, dat, b5] = UpdateCursor(Params, dat, b5); % syncs b5 twice
end
% b5.CheatTarget_draw = DRAW_NONE;

%%% XXX TODO: NEED WAY TO LOG (MORE) INTERESTING TRIAL EVENTS

end