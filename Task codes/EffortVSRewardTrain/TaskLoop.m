function TaskLoop(Params, b5)

%global DEBUG;
global PAUSE_FLAG KEYBOARD_FLAG;

PAUSE_FLAG      = false;
KEYBOARD_FLAG   = false;

NoFigsFlag = true;

%% Define the fields of the Data structure

dfields = {
	'Params'
	'TimeStart'
	'TimeEnd'
	'TrialNum'
	'TrialType'
	'BlockNum'
	'BlockType'
	'TotalBlocks'
	'OutcomeID'
	'OutcomeStr'
	'ReachDelay'
	'ICMS'
	'IsCorrectionTrial'
	'QuestState'
	'TargetProb'
	'RecentReachesLeft'
	'RecentReachesRight'
    'SmallReward'
    'BigReward'
    'ReferenceReward'
    'SmallEffort'
    'BigEffort'
    'ReferenceEffort'
    'SmallEffortUp'
    'ShowSmallEffort'
    'TrialChoice'
    'TotalPoints'
    'ReactionTime'
    'MovementTime'
    'AlwaysReward' % for yes/no trials
};
dinit = cell(size(dfields));
dtmp  = cell2struct(dinit,dfields,1);

Data = dtmp;
Data(Params.NumTrials) = dtmp;

SetupGUI();

%% TRIAL LOOP

trial 	= 0;
done  	= false; 

startTrial = 1;
for itrial = startTrial : Params.NumTrials

    % TRIAL INFO
	trial = trial + 1;
    Data(trial).TrialNum = trial;
    
    Data(trial).Params          = Params;
    
	Data(trial).TrialType = DrawFromProbVec(Params.TrialTypeProbs);
    
    if trial == 1
    	Data(trial).BlockNum 	= 1;
    	Data(trial).TotalBlocks = 1;
	    if Params.FirstBlockIsType1
	        Data(trial).BlockType = 1;
        elseif Params.DoSequentialBlocks
            Data(trial).BlockType = DrawSequentially(Params.BlockSequence, Data(trial).TotalBlocks);
        else
	        Data(trial).BlockType = DrawFromProbVec(Params.BlockProbs);
        end
        Data(trial).TotalPoints = 0;
    else
        Data(trial).BlockNum = Data(trial-1).BlockNum;
        Data(trial).TotalBlocks = Data(trial-1).TotalBlocks;
        Data(trial).TotalPoints = Data(trial-1).TotalPoints;
        if Data(trial-1).OutcomeID == 0 || Data(trial-1).OutcomeID == 3
            Data(trial).BlockNum = Data(trial).BlockNum + 1;
        end
        if Data(trial).BlockNum > Params.BlockSize
            if Params.KeyboardAtBlockEnd
                [Params, b5] = DoKeyboard(Params, b5);
            end
            Data(trial).BlockNum 	= 1;
            Data(trial).TotalBlocks = Data(trial).TotalBlocks + 1;
            if Params.DoSequentialBlocks
                Data(trial).BlockType = DrawSequentially(Params.BlockSequence, Data(trial).TotalBlocks);
            else
                Data(trial).BlockType = DrawFromProbVec(Params.BlockProbs);
            end
        else
            Data(trial).BlockType = Data(trial-1).BlockType;
        end
    end
    
    Data(trial).AlwaysReward = false;

	% ICMS
	% we may overwrite some parameters here below.
% 	Data(trial).ICMS = Params.ICMS;

	LEFT  = 0;
	RIGHT = 1;

	Data(trial).TargetProb = 0.5; % the default

	Data(trial).IsCorrectionTrial = false;

	if Params.UseAdaptiveProbability && Params.UseCorrectionTrials
		error('cannot set both correction trials and adaptive probability true');
	end

	if Params.UseCorrectionTrials && trial > 1
		if Data(trial-1).OutcomeID ~= 0
		    Data(trial).IsCorrectionTrial = true;
		    if Data(trial-1).RewardedTargetID == 0
		        Data(trial).TargetProb = 1.0;
		    else
		        Data(trial).TargetProb = 0.0;
		    end
		end
	end

	if Params.UseAdaptiveProbability && trial >= 2*Params.AdaptiveLookbackLength
		tmplookback      = 1:(trial-1);
		tmpHistErr       = [Data(tmplookback).OutcomeID];
		lookbackgood     = tmplookback(tmpHistErr == 0 | tmpHistErr == 3);
		lookback         = lookbackgood(end-Params.AdaptiveLookbackLength+1:end);
		historyErr       = [Data(lookback).OutcomeID];
		historyID        = [Data(lookback).RewardedTargetID];
		nLeft            = sum((historyID==LEFT  & historyErr==0) | ...
		                       (historyID==RIGHT & historyErr==3));   
		nRight           = sum((historyID==RIGHT & historyErr==0) | ...
		                       (historyID==LEFT  & historyErr==3)); 
		Data(trial).TargetProb 			= nRight./(nLeft+nRight);
		Data(trial).RecentReachesLeft 	= nLeft;
		Data(trial).RecentReachesRight 	= nRight;
	end  

	reset_q = false;

    chance_level = 0.05; 
    
% 	if (trial == 1) ||Data(trial).BlockNum == 1
% 		(Params.ICMSQUEST.ResetQOnNewBlock && Data(trial).BlockNum == 1)
% 		reset_q = true;
%     end

    if Data(trial).BlockType == 4
        chance_level = 0.05;    % for yes/no trials
    end
    
% 	if reset_q
% 		Data(trial).QuestState = ThresholdFinderCreate( ...
% 			Params.ICMSQUEST.InitialGuessUA, ...
% 			Params.ICMSQUEST.MaxAmpUA, ...
% 			Params.ICMSQUEST.ThreshLevel, ...
% 			1.3, 0.95, chance_level);
% 	else
% 		Data(trial).QuestState = Data(trial-1).QuestState;
% 	end

	% Block specific paramters / function calls
	% 1. "regular"/training trials
	% 2. psychometric-current-basic
	% 3. psychometric-current-quest
    % 4. psychometric-current-quest (yes/no)
	switch Data(trial).BlockType
	case 1
		% dont need to do anything special for regular trials
	case 2
		Data(trial).ICMS.AmpUA = DrawFromVec(Params.ICMSQUEST.AmpVecUA);
	case 3
		thresh_guess = ThresholdFinderSuggestQuantile(Data(trial).QuestState);
		if Params.ICMSQUEST.RoundNearestUA
	  		thresh_guess = round(thresh_guess);
		end
		if Params.ICMSQUEST.ClampToVec
			nearest_i = nearestpoint(thresh_guess, Params.ICMSQUEST.AmpVecUA);
			thresh_guess = Params.ICMSQUEST.AmpVecUA(nearest_i);
		end
		thresh_guess = min(thresh_guess, Params.ICMSQUEST.MaxAmpUA);
		Data(trial).ICMS.AmpUA = thresh_guess;
    case 4
        % everything from case-3
        thresh_guess = ThresholdFinderSuggestQuantile(Data(trial).QuestState);
		if Params.ICMSQUEST.RoundNearestUA
	  		thresh_guess = round(thresh_guess);
		end
		if Params.ICMSQUEST.ClampToVec
			nearest_i = nearestpoint(thresh_guess, Params.ICMSQUEST.AmpVecUA);
			thresh_guess = Params.ICMSQUEST.AmpVecUA(nearest_i);
		end
		thresh_guess = min(thresh_guess, Params.ICMSQUEST.MaxAmpUA);
		Data(trial).ICMS.AmpUA = thresh_guess;
        % but also...
        Data(trial).AlwaysReward = true;
	otherwise
		error('Unknown blocktype!');
	end

	fprintf('\nTrial num\t\t%i\n',trial);
	fprintf('Trial type\t\t%i\n',Data(trial).TrialType);
    fprintf('Block type\t\t%s\n',Params.BlockTypes{Data(trial).BlockType});
    fprintf('Block num\t\t(%i of %i)\n',Data(trial).BlockNum,Params.BlockSize);
	fprintf('Total Blocks\t\t%i\n',Data(trial).TotalBlocks);

	%% - - - - - - RUN TRIAL - - - - - -
	b5.Trial_v = trial;
	b5 = bmi5_mmap(b5);
	Data(trial).TimeStart = b5.time_o; % grab time at start of trial
	% TRIAL SELECTION
	% 1. detectStimCue_Trial
	% 2. -- Nothing yet
	switch Data(trial).TrialType
	case {1 2 3 4 5 6 7 8 9} 
		[Params, Data(trial), b5] = ...
        EffortVSReward( Params, Data(trial), b5 );
	otherwise
		error('Unknown Trial Type');
	end
	b5 = bmi5_mmap(b5);
	Data(trial).TimeEnd = b5.time_o; % grab time at end of trial
	%%  - - - - - - END TRIAL  - - - - - - 

	%% TRIAL SUMMARY INFO DISPLAY
	fprintf('Outcome\t\t\t\t%d (%s)\n',Data(trial).OutcomeID,Data(trial).OutcomeStr);
    fprintf('Reaction time\t\t%d \n', Data(trial).ReactionTime);
    fprintf('Movement time\t\t%d \n', Data(trial).MovementTime);
  
	%% Update Threshold Quest
% 	if (Data(trial).OutcomeID == 0 || Data(trial).OutcomeID == 3) && ...
% 		Data(trial).RewardedTargetID == Data(trial).ICMS.TargetID && ...
%         Data(trial).IsCorrectionTrial == false && ...
%         (Data(trial).TargetProb == 0.5 || Data(trial).BlockType == 4);
% 
% 		if Data(trial).OutcomeID == 0
% 			outcome = 1;
% 		else
% 			outcome = 0;
% 		end
% 		Data(trial).QuestState = ThresholdFinderUpdate( ...
% 			Data(trial).QuestState,...
% 			Data(trial).ICMS.AmpUA, ...
% 			outcome);
% 	end
% 
% 	testimate = ThresholdFinderSuggest(Data(trial).QuestState);
% 	fprintf('ICMS thresh (est)\t%0.1f uA\n',testimate);

	%% SUMMARY FIGURES
	if ~NoFigsFlag
		PlotSummaryFigs(Params, b5, Data(1:trial));
    end

    %% calculate the reward based on the short-term performance
        if trial>10
            
            PTrialIDs=[Data(trial-9:trial).OutcomeID];
%     NtrialsP=max(find( PTrialIDs==0));


errlistP = [Data(trial-9:trial).OutcomeID];
NerrorsP = sum(errlistP~=0);
NcorrectP = 10 - NerrorsP;
    
    Params.TempPerf=NcorrectP/10;
    end
    
    %% Save Data
	% NOTE NOTE NOTE * this overwrites any existing file! * NOTE NOTE NOTE
    % Save full data structure after each block
    if Data(trial).BlockNum == Params.BlockSize
        DATA = Data;
        DATA(trial+1:end) = []; % kill excess
        fprintf('-> saving DATA structure\n'); 
%         save(Params.DataFileName, 'DATA');
        clear DATA;
    end

    % save per-trial data structure after each trial
    eval(sprintf('DATA_%03d = Data(%d);',trial,trial));
    tmpdata = sprintf('DATA_%03d',trial);
    tmpfile = fullfile(Params.DataTrialDir,tmpdata);
    fprintf('-> saving DATA structure (partial)\n');
%     save(tmpfile, tmpdata);
    clear(tmpdata);
  
    % trigger bmi5 save event
    fprintf('-> saving BMI5 data\n');
    s = sprintf('save %s', Params.BMI5FileName);
%     bmi5_cmd(s);
    
	% GUI
	drawnow;
	while PAUSE_FLAG || KEYBOARD_FLAG
		if KEYBOARD_FLAG
			[Params, b5] = DoKeyboard(Params, b5);
			KEYBOARD_FLAG = false;
		end
		pause(.1);
	end

	if done
		break;
	end

end % end-loop-over-NumTrials

return

end

%% - - - - - - -   Subroutines   - - - - - - - -

function SetupGUI()
  global PAUSE_FLAG KEYBOARD_FLAG;
  PAUSE_FLAG = false;
  KEYBOARD_FLAG = false;
  figure(1);
  %screen_sz = get(0,'ScreenSize');
  set(gcf,'position', [1485 5  350 150]);
  uicontrol(gcf, 'style', 'toggle', 'units', 'normalized', 'position', [.1 .4 .3 .2], ...
    'string', 'PAUSE',    'callback', @PauseCallback);
  uicontrol(gcf, 'style', 'push',   'units', 'normalized', 'position', [.6 .4 .3 .2], ...
    'string', 'KEYBOARD', 'callback', @KeyboardCallback);
end

function PauseCallback(hObject, ~, ~)
  global PAUSE_FLAG
  PAUSE_FLAG = false;
  if get(hObject,'Value') == get(hObject,'Max')
    PAUSE_FLAG = true;
  end
end

function KeyboardCallback(~, ~, ~)
  global KEYBOARD_FLAG
  KEYBOARD_FLAG=true;
end

function [Params, b5] = DoKeyboard(Params, b5)
    % sound the alarm
    beep; pause(0.1); beep; pause(0.1); beep;
    disp('Adjust Params or b5 and type ''return''');
    keyboard;
end
