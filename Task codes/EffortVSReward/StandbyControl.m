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

% Open figure and get all handles to GUI objects
figH = openfig(fullfile(myFolder, myTag));
uiH = getHandles(figH);
set(figH, 'Name', myName, 'Tag', myTag);
defaultBackgroundColor = get(0,'defaultUicontrolBackgroundColor');

% Set Callbacks for new GUI
set(uiH.RewardNow, 'Callback',      @RewardNow_Callback);
set(uiH.PurgeLine, 'Callback',      @PurgeLine_Callback);
set(uiH.RewardTime, 'Callback',     @RewardTime_Callback);
set(uiH.RewardTimeMin, 'Callback',  @RewardTimeMin_Callback);
set(uiH.RewardTimeMax, 'Callback',  @RewardTimeMax_Callback);
set(uiH.PurgeTime, 'Callback',      @PurgeTime_Callback);
set(uiH.PurgeTimeMin, 'Callback',   @PurgeTimeMin_Callback);
set(uiH.PurgeTimeMax, 'Callback',   @PurgeTimeMax_Callback);
set(uiH.About, 'Callback',          @About_Callback);
set(uiH.Quit, 'Callback',           @Quit_Callback);
set(uiH.QuitButton, 'Callback',     @Quit_Callback);
set(figH, 'CloseRequestFcn',        @Quit_Callback);

if exist('standAlone', 'var') && ~standAlone
    set(uiH.Quit, 'enable', 'off')
    set(uiH.QuitButton, 'enable', 'off')
    set(figH, 'CloseRequest', 'off');
end

% Make figure visible
set(figH, 'Visible', 'on');

% Initialize GUI
ParamsGUI = [];
standbyControlInit();

% Create global bmi5 fifo
global bmi5_in bmi5_out;

% Initialize output data structure
controlWindow = [];

% Methods
controlWindow.getTag = @getTag;
controlWindow.getFolder = @getFolder;
controlWindow.rewardNow = @RewardNow;
controlWindow.purgeLine = @PurgeLine;
controlWindow.setRewardTime = @SetRewardTime;
controlWindow.setPurgeTime = @SetPurgeTime;
controlWindow.quit = @Quit_Callback;
controlWindow.message = @message;
controlWindow.doSomething = @doSomething;


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
            sprintf('Rewarded %.0f ms', 1000*(b5.time_o - juiceStart)));
    end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function PurgeLine_Callback(hObject, ~)
        
        b5.isometricDOUT_channels = 1;
        b5 = bmi5_mmap(b5);
        juiceStart = b5.isometricDOUT_time_o;

        while (b5.time_o - juiceStart) < ParamsGUI.PurgeTime.Value
            set(uiH.Msg,'String',...
                sprintf('%.01f', ParamsGUI.PurgeTime.Value - (b5.time_o - juiceStart)));
            b5 = bmi5_mmap(b5);
        end
        set(uiH.Msg,'String', 'Line Purged');
        b5.isometricDOUT_channels = 0;
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
            if ParamsGUI.RewardTime.Value < str2double(hObject.String)
                set(hObject, 'String', num2str(ParamsGUI.RewardTime.Range(1)));
                message('Current reward time is shorter that new min')
            else
                set(uiH.RewardTime, 'Min', str2double(hObject.String'))
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
            if ParamsGUI.RewardTime.Value > str2double(hObject.String)
                set(hObject, 'String', num2str(ParamsGUI.RewardTime.Range(2)));
                message('Current reward time is longer that new max')
            else
                set(uiH.RewardTime, 'Max', str2double(hObject.String))
                UpdateParams();
            end
        else
            set(hObject, 'String', num2str(ParamsGUI.RewardTime.Range(2)));
            message('Value entered is not numeric')
        end
        
    end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function PurgeTimeMin_Callback(hObject, ~)
        
        if ~isnan(str2double(get(hObject,'string')))
            if ParamsGUI.PurgeTime.Value < str2double(hObject.String)
                set(hObject, 'String', num2str(ParamsGUI.PurgeTime.Range(1)));
                message('Current purge time is shorter that new min')
            else
                set(uiH.PurgeTime, 'Min', str2double(hObject.String))
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
            if ParamsGUI.PurgeTime.Value > str2double(hObject.String)
                set(hObject, 'String', num2str(ParamsGUI.PurgeTime.Range(2)));
                message('Current purge time is longer that new max')
            else
                set(uiH.PurgeTime, 'Max', str2double(hObject.String))
                UpdateParams();
            end
        else
            set(hObject, 'String', num2str(ParamsGUI.PurgeTime.Range(2)));
            message('Value entered is not numeric')
        end
        
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
        try
            tmpParams = load(paramsFile);
            ParamsGUI = tmpParams.ParamsGUI;
            clear tmpParams
        catch
            ParamsGUI.RewardTime.Range = [0, 1000]; % [ms]
            ParamsGUI.RewardTime.Value = 300; % [ms]
            ParamsGUI.PurgeTime.Range = [0, 5]; % [s]
            ParamsGUI.PurgeTime.Value = 2; % [s]
        end
        
        set(uiH.RewardTimeMin, 'String', num2str(ParamsGUI.RewardTime.Range(1)));
        set(uiH.RewardTimeMax, 'String', num2str(ParamsGUI.RewardTime.Range(2)));
        set(uiH.RewardTimeText, 'String', ...
            sprintf('%.0fms',ParamsGUI.RewardTime.Value));
        set(uiH.RewardTime, 'Min', ParamsGUI.RewardTime.Range(1));
        set(uiH.RewardTime, 'Max', ParamsGUI.RewardTime.Range(2));
        set(uiH.RewardTime, 'Value', ParamsGUI.RewardTime.Value);
        
        set(uiH.PurgeTimeMin, 'String', num2str(ParamsGUI.PurgeTime.Range(1)));
        set(uiH.PurgeTimeMax, 'String', num2str(ParamsGUI.PurgeTime.Range(2)));
        set(uiH.PurgeTimeText, 'String', ...
            sprintf('%.2fs',ParamsGUI.PurgeTime.Value));
        set(uiH.PurgeTime, 'Min', ParamsGUI.PurgeTime.Range(1));
        set(uiH.PurgeTime, 'Max', ParamsGUI.PurgeTime.Range(2));
        set(uiH.PurgeTime, 'Value', ParamsGUI.PurgeTime.Value);
        
        
    end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function UpdateParams()
        
        ParamsGUI.RewardTime.Range = [str2double(get(uiH.RewardTimeMin,'string')), ...
            str2double(get(uiH.RewardTimeMax,'string'))];
        
        ParamsGUI.PurgeTime.Range = [str2double(get(uiH.PurgeTimeMin,'string')), ...
            str2double(get(uiH.PurgeTimeMax,'string'))];
        
        ParamsGUI.RewardTime.Value = get(uiH.RewardTime,'Value');
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
