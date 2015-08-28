function TaskLoop(Params, b5)
% Switch workspace to bmi5 subject view
% system('wmctrl -a "subject view"');
global DEBUG;
global PAUSE_FLAG KEYBOARD_FLAG QUIT_FLAG;

PAUSE_FLAG      = false;
KEYBOARD_FLAG   = false;
QUIT_FLAG       = false;

NoFigsFlag = false;

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
    'UpReward'
    'DownReward'
    'UpEffort'
    'DownEffort'
    'UpTargetOn'
    'TrialChoice'
    'TrialChoiceID'
    'RecentAvgChoice'
    'ReactionTime'
    'MovementTime'
    'AlwaysReward'
    'ActualEffort'
    'ActualReward' 
    'FinalCursorPos'
    'ForceTrace'
    'GoCue_time_o'
    'JuiceON'
    'JuiceOFF'
};
dinit = cell(size(dfields));
dtmp  = cell2struct(dinit,dfields,1);

Data = dtmp;
Data(Params.NumTrials) = dtmp;

SetupGUI();
[b5, controlWindow] = StandbyControl(Params,b5,0);
drawnow;

%Close Solenoid at beginning of experiment
b5 = LJJuicer(Params, b5, 'off');

%% TRIAL LOOP

trial 	= 0;
done  	= false; 

startTrial = 1;
for itrial = startTrial : Params.NumTrials
% system('wmctrl -a "subject view"');
    
    % TRIAL INFO
	trial = trial + 1;
    Data(trial).TrialNum = trial;
    
    Data(trial).Params          = Params;
    
	Data(trial).TrialType = DrawFromProbVec(Params.TrialTypeProbs);
    
    if trial == 1
    	Data(trial).BlockNum 	= 1;
    	Data(trial).TotalBlocks = 1;
        Data(trial).TotalPoints = 0;
        Data(trial).ProbesAdaptationState = Params.DownEffort';
        Data(trial).ProbesAdaptationState(:,2) = false;
    else
        Data(trial).BlockNum = Data(trial-1).BlockNum;
        Data(trial).TotalBlocks = Data(trial-1).TotalBlocks;
        Data(trial).TotalPoints = Data(trial-1).TotalPoints;
        Data(trial).ProbesAdaptationState = Data(trial-1).ProbesAdaptationState;
        if Data(trial-1).OutcomeID == 0
            Data(trial).BlockNum = Data(trial).BlockNum + 1;
        end
    end
    
    Data(trial).AlwaysReward = false;

	fprintf('\nTrial num\t\t%i\n',trial);
	fprintf('Trial type\t\t%i\n',Data(trial).TrialType);
	fprintf('Total Blocks\t\t%i\n',Data(trial).BlockNum);
    
    %% Initialize force trace
    Data(trial).ForceTrace = NaN(200 * Params.TrialLength / 0.01 , 5);

	%% - - - - - - RUN TRIAL - - - - - -
	b5.Trial_v = trial;
	b5 = bmi5_mmap(b5);
	Data(trial).TimeStart = b5.time_o; % grab time at start of trial
	% TRIAL SELECTION
	switch Data(trial).TrialType
	case 1
        Params.UseRewardAdaptation          = false;
        if trial > 1 && ~isempty(max([Data(~[Data().OutcomeID]).ActualEffort]))
            b5.DownTarget_pos 		= [0,max([Data(~[Data().OutcomeID]).ActualEffort]) * b5.Frame_scale(2)];
        else
            b5.DownTarget_pos 		= [0,0];
        end
		[Params, Data(trial), b5] = ...
        SubjectCallibration( Params, Data(trial), b5 );
    case 2
        Params.UseRewardAdaptation          = true;
		[Params, Data(trial), b5] = ...
        ProbeOnlyAdaptation( Params, Data(trial), b5 );
    case 3
        Params.UseRewardAdaptation          = false;
		[Params, Data(trial), b5] = ...
        VerticalFillingBar( Params, Data(trial), b5 );
    case 4
        Params.UseRewardAdaptation          = false;
		[Params, Data(trial), b5] = ...
        joystickTraining( Params, Data(trial), b5, controlWindow);
    case 5
        Params.UseRewardAdaptation          = false;
		[Params, Data(trial), b5] = ...
        rewardTracking( Params, Data(trial), b5, controlWindow);
    case 6
        Params.UseRewardAdaptation          = false;
		[Params, Data(trial), b5] = ...
        effortTracking( Params, Data(trial), b5, controlWindow);
	otherwise
		error('Unknown Trial Type');
	end
	b5 = bmi5_mmap(b5);
	Data(trial).TimeEnd = b5.time_o; % grab time at end of trial
	%%  - - - - - - END TRIAL  - - - - - - 
    
    %% Clean remaining of force trace
    Data(trial).ForceTrace(isnan(Data(trial).ForceTrace(:,1)),:) = [];
    
    
	%% TRIAL SUMMARY INFO DISPLAY
	fprintf('Outcome\t\t\t%d (%s)\n',Data(trial).OutcomeID,Data(trial).OutcomeStr);
    fprintf('Reaction time\t\t%d \n', Data(trial).ReactionTime);
    fprintf('Movement time\t\t%d \n', Data(trial).MovementTime);
    fprintf('BiasingMulti\t\t%d \n', Params.BiasingMulti);
    %fprintf('TrialsSinceAdapt\t\t%d \n', Params.TrialsSinceAdapt);
    
    %Update earned rewards on GUI
    controlWindow.SetEarnedRewards(sum([Data(1:trial).OutcomeID] == 0));
  
    %% adapt BiasingMulti to try to find indifference point in reward or effort tracking mode
    
    if Params.AdaptToCenterFlag 
       [Params, Data] = AdaptToCenter(Params,Data,trial);  
    elseif ~isempty(Params.BMSequence)
        [Params, Data] = SetSequence(Params,Data,trial);
    end
    
        %% SUMMARY FIGURES
    if ~NoFigsFlag
        PlotSummaryFigs(Params, Data(1:trial));
    end

    %% Save Data
    if QUIT_FLAG
        done = true;
    end
    if itrial == Params.NumTrials
        done = true;
    end
    
	% NOTE NOTE NOTE * this overwrites any existing file! * NOTE NOTE NOTE
    % Save full data structure after each block
%     if Data(trial).BlockNum == Params.BlockSize
    if done
        DATA = Data;
        DATA(trial+1:end) = []; % kill excess
        fprintf('-> saving DATA structure\n'); 
        save(Params.DataFileName, 'DATA');
        clear DATA;
    end

    % save per-trial data structure after each trial
    eval(sprintf('DATA_%03d = Data(%d);',trial,trial));
    tmpdata = sprintf('DATA_%03d',trial);
    tmpfile = fullfile(Params.DataTrialDir,tmpdata);
    fprintf('-> saving DATA structure (partial)\n');
    save(tmpfile, tmpdata);
    clear(tmpdata);
    
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
        controlWindow.quit();
        close(1)
        break;
    end

end % end-loop-over-NumTrials

return

end

%% - - - - - - -   Subroutines   - - - - - - - -

function SetupGUI()
  global PAUSE_FLAG KEYBOARD_FLAG QUIT_FLAG;
  PAUSE_FLAG = false;
  KEYBOARD_FLAG = false;
  QUIT_FLAG = false;
  figure(1);
  clf
  %screen_sz = get(0,'ScreenSize');
  set(gcf,'position', [398     5   370   150]);
  uicontrol(gcf, 'style', 'toggle', 'units', 'normalized', 'position', [.1 .6 .8 .2], ...
    'string', 'KEYBOARD',    'callback', @KeyboardCallback);
  uicontrol(gcf, 'style', 'push',   'units', 'normalized', 'position', [.1 .4 .8 .2], ...
    'string', 'PAUSE', 'callback', @PauseCallback);
  uicontrol(gcf, 'style', 'push',   'units', 'normalized', 'position', [.1 .1 .8 .2], ...
    'string', 'QUIT', 'callback', @QuitCallback);
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

function QuitCallback(~, ~, ~)
  global QUIT_FLAG
  QUIT_FLAG=true;
end

function [Params, b5] = DoKeyboard(Params, b5)
    % sound the alarm
    beep; pause(0.1); beep; pause(0.1); beep;
    disp('Adjust Params or b5 and type ''return''');
    keyboard;
end

function [Params, Data] = SetSequence(Params,Data,trial)
    % record average choices
    if (sum([Data.OutcomeID] == 0) > 9 )
        % find 10 most recent & compute local average
        tmpIdx = find([Data.OutcomeID]==0,10,'last');
        Data(trial).RecentAvgChoice=sum([Data(tmpIdx).TrialChoiceID]==1)/10;
    else
        Data(trial).RecentAvgChoice=NaN;
    end

    % get next BM value
    Params.BiasingMulti = DrawSequentially(Params.BMSequence,ceil(trial/Params.BMBlock));
end

function [Params,Data] = AdaptToCenter(Params, Data,trial)
    if (sum([Data.OutcomeID] == 0) > 9 )
        % find 10 most recent & compute local average
        tmpIdx = find([Data.OutcomeID]==0,10,'last');
        Data(trial).RecentAvgChoice=sum([Data(tmpIdx).TrialChoiceID]==1)/10;

        % don't change anything unless he's working now
        if (Data(trial).OutcomeID==0) && (sum([Data.OutcomeID]==0) > 39)
            tmpIdx = find([Data.OutcomeID]==0,40,'last'); % check stability over a larger window
            % if recent average seems stable & it's been a while since we
            % adapted, then change BiasingMulti
            if ( std([Data(tmpIdx).RecentAvgChoice]) < 0.2 ) && (Params.TrialsSinceAdapt > 39)
                if sum([Data(tmpIdx).RecentAvgChoice])/50 > 0.5
                    Params.BiasingMulti = max(0, 0.8*Params.BiasingMulti);
                elseif sum([Data(tmpIdx).RecentAvgChoice])/50 < 0.5
                    Params.BiasingMulti = min(1,1.2*Params.BiasingMulti);
                end
                Params.TrialsSinceAdapt = 0;

            else
                Params.TrialsSinceAdapt = Params.TrialsSinceAdapt + 1;
            end
        end
    else
        Data(trial).RecentAvgChoice=NaN;
    end
end
