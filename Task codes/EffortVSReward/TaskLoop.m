function TaskLoop(Params, b5)
% Switch workspace to bmi5 subject view
% system('wmctrl -a "subject view"');
global DEBUG;
global PAUSE_FLAG KEYBOARD_FLAG QUIT_FLAG;

PAUSE_FLAG      = false;
KEYBOARD_FLAG   = false;
QUIT_FLAG       = false;

NoFigsFlag = true;

%% Define the fields of the Data structure

dfields = {
	'Params'
	'TrialNum'
	'TrialType'
	'BlockNum'
    'NumSuccess'
    'UpReward'
    'DownReward'
    'UpEffort'
    'DownEffort'
	'OutcomeID'
	'OutcomeStr'
    'TrialChoice'
    'TrialChoiceID'
    'RecentAvgChoice'
    'ActualReward'
    'ActualEffort'
    'FinalCursorPos'
    'ForceTrace'
    'TimeStart'
    'TimeStartDraw'
    'TimeStartGet'
    'TimeStartCancel'
    'TimeStartHoldMet'
    'TimeStartHoldCancel'
    'TimeReachDraw'
    'TimeReact'
    'TimeReactCancel'
    'TimeReachGet'
    'TimeReachCancel'
    'TimeReachHoldMet'
    'TimeReachHoldCancel'
    'TimeBlank'
    'TimeRewardStart'
    'TimeRewardEnd'
    'TimeEnd'
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
    
    % update BlockNum & NumSuccess based on outcome of prev trial
    if trial == 1
    	Data(trial).BlockNum 	= 1;
        Data(trial).NumSuccess  = 0;
    else
        if Data(trial-1).OutcomeID == 0
            Data(trial).NumSuccess = Data(trial-1).NumSuccess + 1;
        else
            Data(trial).NumSuccess = Data(trial-1).NumSuccess;
        end
        
        if Data(trial-1).OutcomeID == 0 && mod(Data(trial).NumSuccess,Params.BlockLength)==0
            Data(trial).BlockNum = Data(trial-1).BlockNum + 1;
        else
            Data(trial).BlockNum = Data(trial-1).BlockNum;
        end
    end
    
    Data(trial).TrialType = Params.TrialTypeBlocks(Data(trial).BlockNum);
    [Params, Data] = AvgChoice(Params,Data,trial);

	%fprintf('\nTrial num\t\t%i\n',trial);
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
        case 1 % reward adapt to center
            Data(trial).UpReward                = 2*Params.BiasingMulti*Params.StdReward;
            Data(trial).DownReward              =2*(1.0-Params.BiasingMulti)*Params.StdReward;
            Data(trial).UpEffort                = Params.StdEffort;
            Data(trial).DownEffort              = Params.StdEffort;
            
            fprintf('Up Reward\t\t%d \n', Data(trial).UpReward);
            fprintf('Down Reward\t\t%d \n', Data(trial).DownReward);
            fprintf('Up Effort\t\t%d \n', Data(trial).UpEffort);
            fprintf('Down Effort\t\t%d \n', Data(trial).DownEffort);
            
            [Params, Data(trial), b5]           = RewardEffortTrial(Params, Data(trial), b5, controlWindow);
            [Params, Data]                      = AdaptToCenter(Params,Data,trial);
            
        case 2 % effort adapt to center
            Data(trial).UpReward                = Params.StdReward;
            Data(trial).DownReward              = Params.StdReward;
            Data(trial).UpEffort                = min(2.0*Params.BiasingMulti,1)*Params.StdEffort;
            Data(trial).DownEffort              = min(2.0*(1.0-Params.BiasingMulti),1)*Params.StdEffort;
            
            fprintf('Up Reward\t\t%d \n', Data(trial).UpReward);
            fprintf('Down Reward\t\t%d \n', Data(trial).DownReward);
            fprintf('Up Effort\t\t%d \n', Data(trial).UpEffort);
            fprintf('Down Effort\t\t%d \n', Data(trial).DownEffort);
            
            [Params, Data(trial), b5]           = RewardEffortTrial(Params, Data(trial), b5, controlWindow);
            [Params, Data]                      = AdaptToCenter(Params,Data,trial);
            
        case 3 % reward tracking w/ fixed effort
            Data(trial).UpReward                = Params.UpReward(mod(Data(trial).BlockNum,numel(Params.UpReward)))*Params.StdReward;
            Data(trial).DownReward              = Params.DownReward(mod(Data(trial).BlockNum,numel(Params.DownReward)))*Params.StdReward;
            Data(trial).UpEffort                = Params.StdEffort;
            Data(trial).DownEffort              = Params.StdEffort;
            
            fprintf('Up Reward\t\t%d \n', Data(trial).UpReward);
            fprintf('Down Reward\t\t%d \n', Data(trial).DownReward);
            fprintf('Up Effort\t\t%d \n', Data(trial).UpEffort);
            fprintf('Down Effort\t\t%d \n', Data(trial).DownEffort);
            
            [Params, Data(trial), b5]           = RewardEffortTrial(Params,Data(trial),b5,controlWindow);
            
        case 4 % effort tracking w/ fixed reward
            Data(trial).UpReward                = Params.StdReward;
            Data(trial).DownReward              = Params.StdReward;
            Data(trial).UpEffort                = Params.UpEffort(mod(Data(trial).BlockNum,numel(Params.UpEffort)))*Params.StdEffort;
            Data(trial).DownEffort              = Params.DownEffort(mod(Data(trial).BlockNum,numel(Params.DownEffort)))*Params.StdEffort;
            
            fprintf('Up Reward\t\t%d \n', Data(trial).UpReward);
            fprintf('Down Reward\t\t%d \n', Data(trial).DownReward);
            fprintf('Up Effort\t\t%d \n', Data(trial).UpEffort);
            fprintf('Down Effort\t\t%d \n', Data(trial).DownEffort);
            
            [Params, Data(trial), b5]           = RewardEffortTrial(Params,Data(trial),b5,controlWindow);
            
        case 5 % reward and effort tracking
            Data(trial).UpReward                = Params.UpReward(mod(Data(trial).BlockNum,numel(Params.UpReward)))*Params.StdReward;
            Data(trial).DownReward              = Params.DownReward(mod(Data(trial).BlockNum,numel(Params.DownReward)))*Params.StdReward;
            Data(trial).UpEffort                = Params.UpEffort(mod(Data(trial).BlockNum,numel(Params.UpEffort)))*Params.StdEffort;
            Data(trial).DownEffort              = Params.DownEffort(mod(Data(trial).BlockNum,numel(Params.DownEffort)))*Params.StdEffort;
            
            fprintf('Up Reward\t\t%d \n', Data(trial).UpReward);
            fprintf('Down Reward\t\t%d \n', Data(trial).DownReward);
            fprintf('Up Effort\t\t%d \n', Data(trial).UpEffort);
            fprintf('Down Effort\t\t%d \n', Data(trial).DownEffort);
            
            [Params, Data(trial), b5]           = RewardEffortTrial(Params,Data(trial),b5,controlWindow);
            
        case 6
            Data(trial).UpReward                = Params.StdReward;
            Data(trial).DownReward              = Params.StdReward;
            Data(trial).UpEffort                = Params.StdEffort;
            Data(trial).DownEffort              = Params.StdEffort;
            
            fprintf('Up Reward\t\t%d \n', Data(trial).UpReward);
            fprintf('Down Reward\t\t%d \n', Data(trial).DownReward);
            fprintf('Up Effort\t\t%d \n', Data(trial).UpEffort);
            fprintf('Down Effort\t\t%d \n', Data(trial).DownEffort);
            
            [Params, Data(trial), b5]           = OneTargetTrial(Params,Data(trial),b5,controlWindow);
            %[Params, Data]                      = AdaptUpHold(Params,Data);
            
        otherwise
            error('Unknown Trial Type');
    end
	b5 = bmi5_mmap(b5);
	Data(trial).TimeEnd = b5.time_o; % grab time at end of trial
	
    %  - - - - - - END TRIAL  - - - - - - 
    
    %% Clean remaining of force trace
    Data(trial).ForceTrace(isnan(Data(trial).ForceTrace(:,1)),:) = [];
    
    
	%% TRIAL SUMMARY INFO DISPLAY
	fprintf('Outcome\t\t\t%d (%s)\n',Data(trial).OutcomeID,Data(trial).OutcomeStr);
    
    %Update earned rewards on GUI
    controlWindow.SetEarnedRewards(sum([Data(1:trial).OutcomeID] == 0));
    
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

function [Params, Data] = AdaptUpHold(Params,Data)
attempt=Data([Data.OutcomeID]==0 | [Data.OutcomeID]==6); % get all attempts
n=length(attempt);
if n<30
    Params.TrialsSinceAdapt = 1+Params.TrialsSinceAdapt;
elseif Params.TrialsSinceAdapt>=10
    attempt = attempt(n-29:end); % pull out just last 30
    m=length(attempt([attempt.OutcomeID]==0)); % how many of those were successes
    if ((m/30)>0.6) && (Params.HoldUp<=1.0)
        Params.HoldUp = 0.02+Params.HoldUp;
        Params.TrialsSinceAdapt=0;
    elseif ((m/30)<0.1) && (Params.HoldUp>0.3)
        Params.HoldUp = -0.01+Params.HoldUp;
        Params.TrialsSinceAdapt=0;
    end
else
    Params.TrialsSinceAdapt=1+Params.TrialsSinceAdapt;
end

end

function [Params, Data] = AvgChoice(Params,Data,trial)
    if ( Data(trial).NumSuccess >= Params.AvgOver )
        tmpIdx = find([Data.OutcomeID]==0,Params.AvgOver,'last');
        Data(trial).RecentAvgChoice=sum([Data(tmpIdx).TrialChoiceID]==1)/Params.AvgOver;
    else
        Data(trial).RecentAvgChoice=NaN;
    end
end

function [Params,Data] = AdaptToCenter(Params, Data,trial)
    if (Data(trial).OutcomeID==0) && (Data(trial).NumSuccess >= Params.AdaptStep)
        tmpIdx = find([Data.OutcomeID]==0,Params.AdaptStep,'last'); 
        
        if Params.TrialsSinceAdapt >= 2*Params.AdaptStep
            if sum([Data(tmpIdx).RecentAvgChoice])/Params.AdaptStep > 0.55
                Params.BiasingMulti = max(0, 0.8*Params.BiasingMulti);
                Params.TrialsSinceAdapt = 0;
            elseif sum([Data(tmpIdx).RecentAvgChoice])/Params.AdaptStep < 0.45
                Params.BiasingMulti = min(1,1.2*Params.BiasingMulti);
                Params.TrialsSinceAdapt = 0;
            end
            
        else
            Params.TrialsSinceAdapt = Params.TrialsSinceAdapt + 1;
        end
    end

end
