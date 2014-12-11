function [Params, b5] = TaskParams(Params)

global DEBUG;
DEBUG = false;

% FOR DRAWING OBJECTS
DRAW_NONE     = 0;
DRAW_SUBJECT  = 1;
DRAW_OPERATOR = 2;
DRAW_BOTH     = 3;

ExperimentConfig;

%% Adding paths
PathAdder('Lib');
PathAdder('Lib/Quest');
PathAdder('Lib/ThresholdFinder');

%% First, we connect to BMI5 and create the necessary objects
%% We'll populate their values below
bmi5_cmd('clear_all');
bmi5_cmd('delete_all');

% Common objects to both tasks
bmi5_cmd('make circle StartTarget');

bmi5_cmd('make open_square Frame 0.01');
bmi5_cmd('make open_square BarOutline 0.03');
bmi5_cmd('make square FillingEffort');
bmi5_cmd('make square Pass');
bmi5_cmd('make square PointsBox');
bmi5_cmd('make circle RewardCircle');
bmi5_cmd('make circle RewardCircleFeedback');
bmi5_cmd('make circle PassRewardCircle');
bmi5_cmd('make circle Cursor');
Params.NumEffortTicks = 3;
for ii = 1:Params.NumEffortTicks
    bmi5_cmd(sprintf('make square effortTick%d',ii));
end

bmi5_cmd('make labjack isometric 4 4');
bmi5_cmd('make tone GoTone');
bmi5_cmd('make tone RewardTone');
bmi5_cmd('make store int 1 Trial');

bmi5_cmd('make text TotalPoints 10');

bmi5_cmd('make text Reward 9');
bmi5_cmd('make text RewardFeedback 9');
bmi5_cmd('make text PassReward 9');
bmi5_cmd('make text PassString 5');

% Go/NoGo
bmi5_cmd('make square ProbeTarget');

eval(bmi5_cmd('mmap structure'));

%% Calibrate Display
c = load(CalibrationFile); 
qp = c.q';
q2 = eye(4); 
q2(1:2, 1:2) = qp(1:2, 1:2); 
q2(1:2, 4) = qp(1:2, 4); 
b5.affine_m44 = q2;
b5 = bmi5_mmap(b5);
Params.pm = c.pm;

Params.TaskName = 'EffortVSReward';

%% Set Save file
tmp = datevec(date);
yr    = sprintf('%04d',tmp(1));
mo    = sprintf('%02d',tmp(2));
dy    = sprintf('%02d',tmp(3));
today = strcat(yr,mo,dy);
TimeNow=clock;
Hour=sprintf('%02d',TimeNow(4));
Minute=sprintf('%02d',TimeNow(5));
HourMinute=strcat(Hour,Minute);

d = fullfile(SaveDirectory,Params.SubjectID);
if ~exist(d,'dir')
	mkdir(d);
end
d = fullfile(d,num2str(yr));
if ~exist(d,'dir')
	mkdir(d);
end
d = fullfile(d,num2str(mo));
if ~exist(d,'dir')
	mkdir(d);
end
d = fullfile(d,today);
if ~exist(d,'dir')
	mkdir(d);
end

d = fullfile(d,HourMinute);
if ~exist(d,'dir')
	mkdir(d);
end

ct = 1;
tn = Params.TaskName;
id = Params.SubjectID;

% datafile
fname = fullfile(d, sprintf('%s_%s_data_%s_%d.mat',tn,id,today,ct));
while exist(fname,'file')
	ct = ct+1;
	fname = fullfile(d, sprintf('%s_%s_data_%s_%d.mat',tn,id,today,ct));
end
fprintf('Trial structure data will be stored to %s\n\n',fname);
Params.DataFileName = fname;

% per-trial data dir
dname = fullfile(d,sprintf('trials_%d',ct));
if ~exist(dname,'dir')
	mkdir(dname);
end
Params.DataTrialDir = dname;

% bmifile
fname = fullfile(d, sprintf('%s_%s_bmi5_%s_%d.mat',tn,id,today,ct));
fprintf('BMI5 structure data will be stored to %s\n\n',fname);
Params.BMI5FileName = fname;
Params.SessionCount = ct;

%%  Trial Type Function Selection
% do not modify
% 1. SubjectCallibration: Use this task to find max force for each subject
% 2. Go/NoGo with reward adaptaion. file = ProbeOnlyAdaptation.m
% 3. Continous reward. file = VerticalFillingBar.m

tmpTrialOK = 0;
tmpGetTrialType = 0;
tmpDlgOpt.Position = [990   304   350   150];
while ~tmpTrialOK && (tmpGetTrialType < 3)
    tmpGetTrialType = tmpGetTrialType + 1;
    [tmpTrialType, tmpTrialOK] = mylistdlg('PromptString', 'Select trial type', ...
        'SelectionMode','single', 'ListString', ...
        {'Subject Callibration', 'Go/NoGo', 'Continous Reward'},...
        'Position', tmpDlgOpt.Position);
end
if ~tmpTrialOK
    error('Could not get trial type')
end
switch tmpTrialType
    case 1
        Params.TrialTypeProbs 			= [1 0 0];
    case 2
        Params.TrialTypeProbs 			= [0 1 0];
    case 3
        Params.TrialTypeProbs 			= [0 0 1];
end
Params.TrialTypeProbs           = Params.TrialTypeProbs/sum(Params.TrialTypeProbs);

clear tmpTrialOK tmpTrialType tmpDlgOpt

%% Set total number of trials and expected correct trials
Params.NumTrials 				= 2000; % Choose a big number so task doesn't finish before hand
if Params.TrialTypeProbs(1)
    Params.NumCorrectTrials         = 4;
elseif Params.TrialTypeProbs(2)
    Params.NumCorrectTrials         = 200; % Go/NoGo correct trials after initial sampling
else
    Params.NumCorrectTrials         = 225; % Continuous reward
end

%% BLOCKS OF TRIALS
% 1. "regular"/training trials  (2afc)
% 2. psychometric-current-basic (2afc)
% 3. psychometric-current-quest (2afc)
% 4. psychometric-current-quest (yes/no)

% Params.BlockTypes = {
% 'regular/training (2afc)'
% 'basic psychometric-current (2afc)'
% 'quest psychometric-current (2afc)'
% 'quest psychometric-current (yes/no)'
% };
% Params.DoSequentialBlocks       = true; % 0 - Probabalistic; 1 - Sequential
% Params.BlockSequence            = [1 ]; % overflows to start
% Params.BlockProbs 				= [0 0 1 0]; % make sure these add to 1 exactly
% 
% % this option forces the first block to be type-1 (irrespective of prob)
% Params.FirstBlockIsType1 		= false;

% This triggers a keyboard at the end of a block so that paramters can
% be adjusted (will also play an alarm to notify the operator)
Params.KeyboardAtBlockEnd 		= true;

%% DELAYS, PENALTIES and TIMEOUTS [sec]
% Start trial
Params.TimeoutReachStartTarget  = 0.1; % max time to acquire start target
Params.StartTarget.Hold       	= 0.1;
% Instructed delay
Params.ReachDelay               = 1;	% draw from this interval
% Reaching phase
Params.ReactionTimeDelay      	= 2; % Max time to initiate movement

% Go/NoGo
Params.TimeoutReachTarget       = 0.6; % max time to reach reaching target

% Continuous reward
Params.MovementWindow           = 0.3; % For effort line, time to move [s]

% Other
Params.TrialLength              = 3.6;   % Fixed trial length [s]
Params.InterTrialDelay 			= 0.4;  % delay between each trial [sec]

%%  WORKSPACE, in mm
Params.WsBounds             	= [-150 -150 ; 150 150]; % [Xmin Ymin; Xmax Ymax]
Params.WsCenter 				= mean(Params.WsBounds,1);
% Params.WsCenter 				= [0 0];


b5.Frame_color  = [1 1 1 1];
b5.Frame_scale  = range(Params.WsBounds);
b5.Frame_pos    = Params.WsCenter;
if DEBUG
    b5.Frame_draw   = DRAW_BOTH;
else
    b5.Frame_draw   = DRAW_NONE;
end

%% Cursor
b5.Cursor_color 				= [1 1 1 0.75]; % RGBA 
b5.Cursor_scale 				= [0 0];        % [mm] % note: diameter!

%% Start Target
b5.StartTarget_color			= [1 0 0 1];
b5.StartTarget_scale 			= [20 20];
Params.StartTarget.Win  		= 20; % radius
Params.StartTarget.Locations 	= {Params.WsCenter + [-40 -40]}; % cell array of locations

%% Rewards
Params.MaxReward    = 30;
Params.PassReward   = 1;
Params.RewardsVector = [2:2:Params.MaxReward];

if ~Params.TrialTypeProbs(1)
    Params.RewardSampleSpace = repmat(1:numel(Params.RewardsVector), ...
                            1, round(Params.NumCorrectTrials/numel(Params.RewardsVector)));
else
    Params.RewardSampleSpace = ones(1, Params.NumCorrectTrials);
end

b5.Reward_color = [0 0 0 1];
b5.Reward_pos = Params.WsCenter + [-25, b5.Frame_scale(2)/2 + 10];

b5.RewardCircle_color = [0 1 0 0.75];
b5.RewardCircle_scale = [35 35];

b5.RewardCircleFeedback_color = [0 1 0 0.75];
b5.RewardCircleFeedback_scale = [35 35];
b5.RewardCircleFeedback_pos = Params.WsCenter - [60, b5.Frame_scale(2)/2];

b5.RewardFeedback_color = [0 0 0 0.75];
b5.RewardFeedback_pos = b5.RewardCircleFeedback_pos - [45,0];

b5.PointsBox_color = [0 1 0 0.75];
b5.PointsBox_scale = [50 40];
b5.PointsBox_pos = Params.WsBounds(1,:);

%% Effort
Params.LoadCellMax                  = 50;
if Params.TrialTypeProbs(1)
    Params.MaxForce                 = 50;
else
    tmpInput = {NaN};
    tmpDlgOpt.Position = [990   304   200   150];
    while isnan(str2double(tmpInput{1})) || (str2double(tmpInput{1}) < 20)
        tmpInput = myinputdlg('Measured max force (>20N) =', 'Subject max force',...
            1,{'30'}, tmpDlgOpt);
    end
    Params.MaxForce = ceil(str2double(tmpInput{1})); % Measured max force per subject [N]
    
    clear tmpInput tmpDlgOpt
end

% Vertical bar outline
b5.BarOutline_color     = [0 0 1 1];
b5.BarOutline_scale     = b5.Frame_scale.* [0.25, 1];
b5.BarOutline_pos       = Params.WsCenter;

% Vertical filling
b5.FillingEffort_color     = [1 1 0 1];
b5.FillingEffort_scale     = b5.Frame_scale .* [0.25, 1];
b5.FillingEffort_pos       = Params.WsCenter - [0, b5.Frame_scale(2)/2] + ...
                    [0, b5.FillingEffort_scale(2)/2];
                
% Vertical bar ticks
for ii = 1:Params.NumEffortTicks
    b5.(sprintf('effortTick%d_color',ii))   = b5.BarOutline_color;
    b5.(sprintf('effortTick%d_scale',ii))   = [6,2];
    b5.(sprintf('effortTick%d_pos',ii))(1)     = ...
        Params.WsCenter(1) + b5.BarOutline_scale(1)/2 - b5.(sprintf('effortTick%d_scale',ii))(1)/2;
    b5.(sprintf('effortTick%d_pos',ii))(2)     = ...
        Params.WsCenter(2) - b5.BarOutline_scale(2)/2 + ii*b5.BarOutline_scale(2)/(1+ Params.NumEffortTicks);
end

% Go/NoGo
b5.ProbeTarget_color = [1 1 0 1];
b5.ProbeTarget_scale = [b5.BarOutline_scale(1), 2];
b5.ProbeTarget_pos = Params.WsCenter ;

Params.EffortVector = [0.1:0.12:1];

%% Pass
Params.PassSensitivity  = 20;
Params.NoGoTap    = 0.025 * b5.Frame_scale(2);

b5.Pass_color     = [0 0 1 1];
b5.Pass_scale     = b5.BarOutline_scale .* [1, 0.1];
b5.Pass_pos       = Params.WsCenter - [0,b5.Frame_scale(2)/2 + b5.Pass_scale(2)/2] - ...
                       [0, 30];
                   
b5.PassRewardCircle_color = [0 1 0 0.75];
b5.PassRewardCircle_scale = [35 35];
b5.PassRewardCircle_pos = b5.Pass_pos - [60, 0];

b5.PassReward_color = [0 0 0 0.75];
b5.PassReward_pos = b5.PassRewardCircle_pos - [55, 0];
b5.PassReward_v = [double(sprintf('%.0f ¢', Params.PassReward)) 0 0 0 0 0 0]';

b5.PassString_v = [double('Pass') 0]';
b5.PassString_pos = b5.Pass_pos - [15, 0];
b5.PassString_color = [1 1 1 1];

%% Adaptive sampling parameters
Params.UseRewardAdaptation      = false;
Params.MaxRewardVector          = floor(linspace(Params.PassReward+1,Params.MaxReward,numel(Params.EffortVector )))';
Params.RewardAdaptation         = [Params.EffortVector;...
                                        floor(linspace(Params.PassReward+1,Params.MaxReward,numel(Params.EffortVector )))]';
Params.Npre                     = 3; % Max number of samples per probe before increasing MaxReward
Params.RewardRange              = zeros(1,numel(Params.EffortVector));
Params.RewardGradients          = 10;
Params.InitialSampling          = Params.EffortVector';
Params.InitialSampling(:, 2:(Params.RewardGradients+1)) = ...
                repmat(Params.MaxRewardVector, 1,numel(1:Params.RewardGradients)) .* ...
                repmat([1:Params.RewardGradients]/Params.RewardGradients, numel(Params.MaxRewardVector), 1);
Params.InitialSampling          = repmat(Params.InitialSampling,1,1, Params.Npre);

for ii = 1:numel(Params.EffortVector)
    Params.ProbeModels.(['Effort' num2str(ii)]) = [];
end

% Sampling space for the rest of the experiment
Params.EffortSampleSpace    = repmat(Params.EffortVector, ...
    1, ceil(Params.NumCorrectTrials/size(Params.EffortVector,2)));
%% Total Points String
b5.TotalPoints_color        = [0 0 0 1];
b5.TotalPoints_pos          = b5.PointsBox_pos - [110, 0];
b5.TotalPoints_v            = [double(sprintf('%.01f ',0)) 162 zeros(1,numel(b5.TotalPoints_v) - 5)]';

%% TONES
b5.GoTone_freq 				= 1000;  % (Hz)
b5.GoTone_duration          = 0.3;  % (sec)
b5.GoTone_scale             = 1;    % (units?)

b5.RewardTone_freq 			= 1500; % (Hz)
b5.RewardTone_duration      = 0.3;  % (sec)
b5.RewardTone_scale         = 1;    % (units?)

%% FOR CONVENIENCE DEFINE BLOCKSIZE HERE
% Params.BlockSize 				= 35;
Params.BlockSize 				=1000;

%% OTHER
Params.UseCorrectionTrials          = false; % { both of these
Params.UseAdaptiveProbability       = false; % { cannot be true
Params.AdaptiveLookbackLength       = 10;    % num trials to look back
Params.FixedTrialLength             = true;
Params.AllowEarlyReach              = false; % { allow subject to start
                                           % { reach before end of delay

%% SYNC
b5 = bmi5_mmap(b5);
                                           
end
