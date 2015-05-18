function [b5, controlWindow] = StandbyControl(Params, b5, standAlone)
% Standby control for in cage training
%
% [b5, controlWindow] = StandbyControl(b5)
%
% b5  = bmi5 object
%
% Camilo Diaz-Botia, 2015/02/24

myName = 'Standby Control';
myTag = 'StandbyControl';

% Where am I?
myFolder = fileparts(which([myTag '.m']));

% Params file
paramsFile = fullfile(myFolder, 'standbyControl_lastParams.mat');

% Load Opening sound effect
[audioCue.Y, audioCue.Fs] = audioread(fullfile(myFolder, 'Opening'));

% Open figure and get all handles to GUI objects
figH = openfig(fullfile(myFolder, myTag));
set(1, 'position', [0   905   762    73]);
uiH = getHandles(figH);
set(figH, 'Name', myName, 'Tag', myTag);
defaultBackgroundColor = get(0,'defaultUicontrolBackgroundColor');

% Set Callbacks for new GUI
set(uiH.RewardNow, 'Callback',      @RewardNow_Callback);
set(uiH.PurgeLine, 'Callback',      @PurgeLine_Callback);
set(uiH.RewardTime, 'Callback',     @RewardTime_Callback);
set(uiH.RewardTimeMin, 'Callback',  @RewardTimeMin_Callback);
set(uiH.RewardTimeMax, 'Callback',  @RewardTimeMax_Callback);
set(uiH.EarnedRewardSlider, 'Callback',     @EarnedRewardSlider_Callback);
set(uiH.EarnedRewardMax, 'Callback',  @EarnedRewardMax_Callback);
set(uiH.EarnedRewardMin, 'Callback',  @EarnedRewardMin_Callback);
set(uiH.PurgeTime, 'Callback',      @PurgeTime_Callback);
set(uiH.PurgeTimeMin, 'Callback',   @PurgeTimeMin_Callback);
set(uiH.PurgeTimeMax, 'Callback',   @PurgeTimeMax_Callback);
set(uiH.OpenButton, 'Callback',     @OpenButton_Callback);
set(uiH.SolenoidButton, 'Callback',     @SolenoidButton_Callback);
set(uiH.CueButton, 'Callback',      @CueButton_Callback);
set(uiH.CueRewardButton, 'Callback',@CueRewardButton_Callback);
set(uiH.CueRewardDelay, 'Callback', @CueRewardDelay_Callback);
set(uiH.CueOn, 'Callback',          @CueOn_Callback);
set(uiH.About, 'Callback',          @About_Callback);
set(uiH.Quit, 'Callback',           @Quit_Callback);
set(uiH.QuitButton, 'Callback',     @Quit_Callback);
set(figH, 'CloseRequestFcn',        @Quit_Callback);

set(uiH.xSensitivitySlider, 'Callback', @SensitivitySlider_Callback);
set(uiH.ySensitivitySlider, 'Callback', @SensitivitySlider_Callback);

if exist('standAlone', 'var') && ~standAlone
    set(uiH.Quit, 'Callback', @bmi5Quit_Callback)
    set(uiH.QuitButton, 'Callback', @bmi5Quit_Callback)
    set(figH, 'CloseRequest', 'off');
end

% Make figure visible
set(figH, 'Visible', 'on');

% Initialize GUI
        DRAW_NONE = 0;
        DRAW_BOTH = 3;
ParamsGUI = [];
standbyControlInit();

% Create global bmi5 fifo
global bmi5_in bmi5_out;
global SolenoidEnable Solenoid_open;

% Initialize output data structure
controlWindow = [];

% Methods
controlWindow.getTag = @getTag;
controlWindow.getFolder = @getFolder;
controlWindow.rewardNow = @RewardNow_Callback;
controlWindow.purgeLine = @PurgeLine;
controlWindow.setRewardTime = @SetRewardTime;
controlWindow.setPurgeTime = @SetPurgeTime;
controlWindow.quit = @Quit_Callback;
controlWindow.message = @message;
controlWindow.doSomething = @doSomething;
controlWindow.SolenoidEnable = @SolenoidButton;
controlWindow.GetSensitivity =  @handleSensitivity;
controlWindow.GetProbeTarget_pos =  @GetProbeTarget_pos;
controlWindow.UpdateRewardFreq =  @UpdateRewardFreq;
controlWindow.GetVisibleCheckbutton = @GetVisibleCheckbutton;
controlWindow.GetEarnedReward = @GetEarnedReward;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Do anything we want by editing this function
    function a = doSomething
        
        a = uiH;
        set(uiH.Quit, 'Callback', @Quit_Callback);
        set(figH, 'CloseRequestFcn', @Quit_Callback);
    end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Returns the folder where this m file is stored
    function tag = getTag
        tag = myTag;
    end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Returns the folder where this m file is
    function folder = getFolder
        
        folder = myFolder;
    end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function RewardNow_Callback(hObject, ~)
        
        b5 = LJJuicer(Params, b5, 'on');
        b5 = bmi5_mmap(b5);
        
        juiceStart = b5.isometricDOUT_time_o;

        while (b5.time_o - juiceStart) < (ParamsGUI.RewardTime.Value/1000)
            b5 = bmi5_mmap(b5);
        end
        
        b5 = LJJuicer(Params, b5, 'off');
        b5 = bmi5_mmap(b5);
        
        set(uiH.Msg,'String',...
            sprintf('Rewarded %.0f ms on %s', 1000*(b5.time_o - juiceStart), datestr(now)));
    end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function SensitivitySlider_Callback(~, ~)
        
        set(uiH.xSensitivityText, 'String', sprintf('%.2f',get(uiH.xSensitivitySlider, 'Value')));
        set(uiH.ySensitivityText, 'String', sprintf('%.2f',get(uiH.ySensitivitySlider, 'Value')));
    end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function PurgeLine_Callback(hObject, ~)
        
        b5 = LJJuicer(Params, b5, 'on');
        b5 = bmi5_mmap(b5);
        set(hObject, 'background', [0 1 0]);
        juiceStart = b5.isometricDOUT_time_o;

        while (b5.time_o - juiceStart) < ParamsGUI.PurgeTime.Value
            set(uiH.Msg,'String',...
                sprintf('%.01f', ParamsGUI.PurgeTime.Value - (b5.time_o - juiceStart)));
            b5 = bmi5_mmap(b5);
        end
        set(uiH.Msg,'String', 'Line Purged');
        b5 = LJJuicer(Params, b5, 'off');
        b5 = bmi5_mmap(b5);
        
        set(hObject, 'background', [0.94 0.94 0.94]);
        
    end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function OpenButton_Callback(hObject, ~)
        tmpString = get(hObject, 'string');
        
        if strcmp(tmpString, 'Open')
            Solenoid_open = true;
            set(hObject, 'String', 'Close')
        end
        
        if strcmp(tmpString, 'Close')
            b5 = LJJuicer(Params, b5, 'off');
            b5 = bmi5_mmap(b5);
            Solenoid_open = false;
            set(hObject, 'String', 'Open')
        end
        
    end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function SolenoidButton()
        SolenoidButton_Callback(uiH.SolenoidButton,[])
    end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function SolenoidButton_Callback(hObject, ~)
        tmpSolenoidState = SolenoidEnable;
        
        if ~tmpSolenoidState
            Params.Solenoid = 'on';
            SolenoidEnable = 1;
            set(hObject, 'string', '<html>Solenoid<br>Enabled')
        end
        if tmpSolenoidState
            Params.Solenoid = 'off';
            SolenoidEnable = 0;
            set(hObject, 'string', '<html>Solenoid<br>Disabled')
        end
    end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function CueButton_Callback(hObject, ~)
        
        sound(audioCue.Y, audioCue.Fs)
%         b5 = bmi5_mmap(b5);
%         if ParamsGUI.CueOn == 0
%             tmpCueOn = b5.CueTarget_draw;
%             if tmpCueOn == DRAW_BOTH
%                 b5.CueTarget_draw = DRAW_NONE;
%                 set(hObject, 'background', [0.94 0.94 0.94])
%             end
% 
%             if tmpCueOn == DRAW_NONE
%                 b5.CueTarget_draw = DRAW_BOTH;
%                 set(hObject, 'background', [0 1 0])
%             end
% 
%             b5 = bmi5_mmap(b5);
%         elseif b5.CueTarget_draw == DRAW_NONE
%             
%             b5.CueTarget_draw = DRAW_BOTH;
%             set(hObject, 'background', [0 1 0])
%             b5 = bmi5_mmap(b5);
%             
%             cueStart = b5.time_o;
%             
%             while (b5.time_o - cueStart) <= ParamsGUI.CueOn
%                 b5 = bmi5_mmap(b5);
%             end
%             
%             b5.CueTarget_draw = DRAW_NONE;
%             set(hObject, 'background', [0.94 0.94 0.94])
%             b5 = bmi5_mmap(b5);
%             
%         end
    end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function CueRewardButton_Callback(hObject, ~)
        
        sound(audioCue.Y, audioCue.Fs);
%         b5 = bmi5_mmap(b5);
%         b5.CueTarget_draw = DRAW_BOTH;
%         set(hObject, 'background', [0 1 0])
        b5 = bmi5_mmap(b5);
        
        cueStart = b5.time_o;
        
        while (b5.time_o - cueStart) <= ParamsGUI.CueRewardDelay
            b5 = bmi5_mmap(b5);
        end
        
        controlWindow.rewardNow();
%         b5.CueTarget_draw = DRAW_NONE;
%         set(hObject, 'background', [0.94 0.94 0.94])
        b5 = bmi5_mmap(b5);  
        
    end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function RewardTime_Callback(hObject, ~)
        
        UpdateParams();
        set(uiH.RewardTimeText, 'string', sprintf('%.0fms',ParamsGUI.RewardTime.Value));
        
    end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function PurgeTime_Callback(hObject, ~)
        
        UpdateParams();
        set(uiH.PurgeTimeText, 'string', sprintf('%.2fs',ParamsGUI.PurgeTime.Value));
    end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function RewardTimeMin_Callback(hObject, ~)
        
        if ~isnan(str2double(get(hObject,'string')))
            if ParamsGUI.RewardTime.Value < str2double(get(hObject,'string'))
                set(hObject, 'String', num2str(ParamsGUI.RewardTime.Range(1)));
                message('Current reward time is shorter that new min')
            else
                set(uiH.RewardTime, 'Min', str2double(get(hObject,'string')'))
                UpdateParams();
            end
        else
            set(hObject, 'String', num2str(ParamsGUI.RewardTime.Range(1)));
            message('Value entered is not numeric')
        end
        
    end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function RewardTimeMax_Callback(hObject, ~)
        
        if ~isnan(str2double(get(hObject,'string')))
            if ParamsGUI.RewardTime.Value > str2double(get(hObject,'string'))
                set(hObject, 'String', num2str(ParamsGUI.RewardTime.Range(2)));
                message('Current reward time is longer that new max')
            else
                set(uiH.RewardTime, 'Max', str2double(get(hObject,'string')))
                UpdateParams();
            end
        else
            set(hObject, 'String', num2str(ParamsGUI.RewardTime.Range(2)));
            message('Value entered is not numeric')
        end
        
    end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function EarnedRewardSlider_Callback(~, ~)
        
        UpdateParams();
        set(uiH.EarnedRewardText, 'string', sprintf('%.1fms',ParamsGUI.EarnedReward.Value));
        
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function EarnedRewardMax_Callback(hObject, ~)
        
        if ~isnan(str2double(get(hObject,'string')))
            if ParamsGUI.EarnedReward.Value > str2double(get(hObject,'string'))
                set(uiH.EarnedRewardSlider, 'Value', str2double(get(hObject,'string')))
                message('Current earned reward adjusted to new max')
            end
            set(uiH.EarnedRewardSlider, 'Max', str2double(get(hObject,'string')))
            UpdateParams();
            EarnedRewardSlider_Callback(uiH.EarnedRewardSlider,[]);
        else
            set(hObject, 'String', num2str(ParamsGUI.EarnedReward.Range(2)));
            message('Value entered is not numeric')
        end
        
    end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function EarnedRewardMin_Callback(hObject, ~)
        
        if ~isnan(str2double(get(hObject,'string')))
            if ParamsGUI.EarnedReward.Value < str2double(get(hObject,'string'))
                set(uiH.EarnedRewardSlider, 'Value', str2double(get(hObject,'string')))
                message('Current earned reward adjusted to new min')
            end
            set(uiH.EarnedRewardSlider, 'Min', str2double(get(hObject,'string')))
            UpdateParams();
            EarnedRewardSlider_Callback(uiH.EarnedRewardSlider,[]);
        else
            set(hObject, 'String', num2str(ParamsGUI.EarnedReward.Range(1)));
            message('Value entered is not numeric')
        end
        
    end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function PurgeTimeMin_Callback(hObject, ~)
        
        if ~isnan(str2double(get(hObject,'string')))
            if ParamsGUI.PurgeTime.Value < str2double(get(hObject,'string'))
                set(hObject, 'String', num2str(ParamsGUI.PurgeTime.Range(1)));
                message('Current purge time is shorter that new min')
            else
                set(uiH.PurgeTime, 'Min', str2double(get(hObject,'string')))
                UpdateParams();
            end
        else
            set(hObject, 'String', num2str(ParamsGUI.PurgeTime.Range(1)));
            message('Value entered is not numeric')
        end
        
    end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function PurgeTimeMax_Callback(hObject, ~)
        
        if ~isnan(str2double(get(hObject,'string')))
            if ParamsGUI.PurgeTime.Value > str2double(get(hObject,'string'))
                set(hObject, 'String', num2str(ParamsGUI.PurgeTime.Range(2)));
                message('Current purge time is longer that new max')
            else
                set(uiH.PurgeTime, 'Max', str2double(get(hObject,'string')))
                UpdateParams();
            end
        else
            set(hObject, 'String', num2str(ParamsGUI.PurgeTime.Range(2)));
            message('Value entered is not numeric')
        end
        
    end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function CueOn_Callback(hObject, ~)
        
        if ~isnan(str2double(get(hObject,'string')))
            if str2double(get(hObject,'string')) < 0
                set(hObject, 'String', sprintf('%.2f',ParamsGUI.CueOn));
                message('Enter value >= 0')
            else
                ParamsGUI.CueOn = str2double(get(hObject,'string'));
            end
        else
            set(hObject, 'String', sprintf('%.2f',ParamsGUI.CueOn));
            message('Value entered is not numeric')
        end
        
    end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function CueRewardDelay_Callback(hObject, ~)
        
        if ~isnan(str2double(get(hObject,'string')))
            if str2double(get(hObject,'string')) < 0
                set(hObject, 'String', sprintf('%.2f',ParamsGUI.CueRewardDelay));
                message('Enter value >= 0')
            else
                ParamsGUI.CueRewardDelay = str2double(get(hObject,'string'));
            end
        else
            set(hObject, 'String', sprintf('%.2f',ParamsGUI.CueRewardDelay));
            message('Value entered is not numeric')
        end
        
    end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function [tmpX, tmpY] = handleSensitivity()
        
        tmpX = get(uiH.xSensitivitySlider, 'value');
        tmpY = get(uiH.ySensitivitySlider, 'value');
        
    end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function pos = GetProbeTarget_pos()
        
        pos = get(uiH.ProbeTargetSlider, 'value');
        
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function EarnedReward = GetEarnedReward()
        
        EarnedReward = ParamsGUI.EarnedReward.Value;
        
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function visibleON = GetVisibleCheckbutton()
        
        visibleON = get(uiH.VisibleCheckbutton, 'value');
        
    end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function UpdateRewardFreq(frequency)
        
        set(uiH.RewardFreqText, 'string', sprintf('Reward frequency = %.0fHz',frequency));
        
    end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% --- Executes on menu select in About.
    function About_Callback(hObject, ~)
        
        str = {'In cage standby control'; 'February 2015'; ' '; ...
            'Camilo Diaz-Botia';'Sabes Lab'; 'UCSF'};
%         img = imread('about_pic3.bmp');
%         aboutdlg('Title', 'Cell Culture Chip', 'String', str, 'Image', img);
        aboutdlg('Title', 'In cage training', 'String', str);
        
    end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% --- Executes on menu select in Quit or close request.
    function Quit_Callback(hObject, ~)

        standbyControlClose();
        
    end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% --- Executes on menu select in Quit or close request.
    function bmi5Quit_Callback(hObject, ~)

        global QUIT_FLAG
        QUIT_FLAG=true;
        
    end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Close standby control window
    function standbyControlClose
        
        try
            bmi5_cmd('delete_all')
            clear b5;
            
            save(paramsFile, 'ParamsGUI')
            
            clear('standbyControl');
        end
        
        delete(figH);
        
    end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Initialize standby control window
    function standbyControlInit
        Solenoid_open = false;
        try
            tmpParams = load(paramsFile);
            ParamsGUI = tmpParams.ParamsGUI;
            clear tmpParams
        catch
            ParamsGUI.RewardTime.Range = [0, 1000]; % [ms]
            ParamsGUI.RewardTime.Value = 300; % [ms]
            ParamsGUI.EarnedReward.Range = [0, 5]; % [s]
            ParamsGUI.EarnedReward.Value = 0.5; % [s]
            ParamsGUI.PurgeTime.Range = [0, 5]; % [s]
            ParamsGUI.PurgeTime.Value = 2; % [s]
            ParamsGUI.CueOn             = 0; %[s]
            ParamsGUI.CueRewardDelay    = 1; %[s]
        end
        
        if ~exist('ParamsGUI', 'var') || isempty(ParamsGUI)
            ParamsGUI.RewardTime.Range = [0, 1000]; % [ms]
            ParamsGUI.RewardTime.Value = 300; % [ms]
            ParamsGUI.EarnedReward.Range = [0, 5]; % [s]
            ParamsGUI.EarnedReward.Value = 0.5; % [s]
            ParamsGUI.PurgeTime.Range = [0, 5]; % [s]
            ParamsGUI.PurgeTime.Value = 2; % [s]
            ParamsGUI.CueOn             = 0; %[s]
            ParamsGUI.CueRewardDelay    = 1; %[s]
        end
        if ~isfield(ParamsGUI, 'RewardTime')
            ParamsGUI.RewardTime.Range = [0, 1000]; % [ms]
            ParamsGUI.RewardTime.Value = 300; % [ms]
        end
        if ~isfield(ParamsGUI, 'EarnedReward')
            ParamsGUI.EarnedReward.Range = [0, 5]; % [s]
            ParamsGUI.EarnedReward.Value = 0.5; % [s]
        end
        if ~isfield(ParamsGUI, 'PurgeTime')
            ParamsGUI.PurgeTime.Range = [0, 5]; % [s]
            ParamsGUI.PurgeTime.Value = 2; % [s]
        end
        if ~isfield(ParamsGUI, 'CueOn')
            ParamsGUI.CueOn             = 0; %[s]
        end
        if ~isfield(ParamsGUI, 'CueRewardDelay')
            ParamsGUI.CueRewardDelay    = 1; %[s]
        end
        
        
        set(uiH.RewardTimeMin, 'String', num2str(ParamsGUI.RewardTime.Range(1)));
        set(uiH.RewardTimeMax, 'String', num2str(ParamsGUI.RewardTime.Range(2)));
        set(uiH.RewardTimeText, 'String', ...
            sprintf('%.0fms',ParamsGUI.RewardTime.Value));
        set(uiH.RewardTime, 'Min', ParamsGUI.RewardTime.Range(1));
        set(uiH.RewardTime, 'Max', ParamsGUI.RewardTime.Range(2));
        set(uiH.RewardTime, 'Value', ParamsGUI.RewardTime.Value);
        
        set(uiH.EarnedRewardMin, 'String', num2str(ParamsGUI.EarnedReward.Range(1)));
        set(uiH.EarnedRewardMax, 'String', num2str(ParamsGUI.EarnedReward.Range(2)));
        set(uiH.EarnedRewardText, 'String', ...
            sprintf('%.1fms',ParamsGUI.EarnedReward.Value));
        set(uiH.EarnedRewardSlider, 'Min', ParamsGUI.EarnedReward.Range(1));
        set(uiH.EarnedRewardSlider, 'Max', ParamsGUI.EarnedReward.Range(2));
        set(uiH.EarnedRewardSlider, 'Value', ParamsGUI.EarnedReward.Value);
        
        set(uiH.PurgeTimeMin, 'String', num2str(ParamsGUI.PurgeTime.Range(1)));
        set(uiH.PurgeTimeMax, 'String', num2str(ParamsGUI.PurgeTime.Range(2)));
        set(uiH.PurgeTimeText, 'String', ...
            sprintf('%.2fs',ParamsGUI.PurgeTime.Value));
        set(uiH.PurgeTime, 'Min', ParamsGUI.PurgeTime.Range(1));
        set(uiH.PurgeTime, 'Max', ParamsGUI.PurgeTime.Range(2));
        set(uiH.PurgeTime, 'Value', ParamsGUI.PurgeTime.Value);
        
        set(uiH.CueOn, 'String', num2str(ParamsGUI.CueOn));
        set(uiH.CueRewardDelay, 'String', num2str(ParamsGUI.CueRewardDelay));
        
        Params.Solenoid = 'off';
        SolenoidEnable = 0;
        set(uiH.SolenoidButton, 'String', '<html>Solenoid<br>Disabled');
        
        % Get X and Y sensitivity to trigger reward
        set(uiH.xSensitivitySlider, 'value', Params.StartTarget.Win(1));
        set(uiH.ySensitivitySlider, 'value', Params.StartTarget.Win(2));
        SensitivitySlider_Callback([],[])
    end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function UpdateParams()
        
        ParamsGUI.RewardTime.Range = [str2double(get(uiH.RewardTimeMin,'string')), ...
            str2double(get(uiH.RewardTimeMax,'string'))];
        
        ParamsGUI.EarnedReward.Range = [str2double(get(uiH.EarnedRewardMin,'string')), ...
            str2double(get(uiH.EarnedRewardMax,'string'))];
        
        ParamsGUI.PurgeTime.Range = [str2double(get(uiH.PurgeTimeMin,'string')), ...
            str2double(get(uiH.PurgeTimeMax,'string'))];
        
        ParamsGUI.RewardTime.Value = get(uiH.RewardTime,'Value');
        ParamsGUI.EarnedReward.Value = get(uiH.EarnedRewardSlider,'Value');
        ParamsGUI.PurgeTime.Value = get(uiH.PurgeTime,'Value');
        
    end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Display message on message window
    function message(msg)
        
        try
            set(uiH.Msg, 'String', msg);
        catch ME
        end
        
    end

end
