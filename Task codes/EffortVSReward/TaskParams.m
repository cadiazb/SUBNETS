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
bmi5_cmd('make square FillingEffortHor');
bmi5_cmd('make square xSensitivity');
bmi5_cmd('make square ySensitivity');
bmi5_cmd('make square Pass');
bmi5_cmd('make circle Cursor');
bmi5_cmd('make circle SolenoidOpen');

bmi5_cmd('make labjack isometric 4 2 2');
bmi5_cmd('make tone GoTone');
bmi5_cmd('make tone RewardTone');
bmi5_cmd('make store int 1 Trial');

% Go/NoGo
bmi5_cmd('make square ProbeTarget');
bmi5_cmd('make square ProbeTargetTop');

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
if ~exist(d,'dir'),     mkdir(d);   end

d = fullfile(d,num2str(yr));
if ~exist(d,'dir'),     mkdir(d);   end

d = fullfile(d,num2str(mo));
if ~exist(d,'dir'),     mkdir(d);   end

d = fullfile(d,today);
if ~exist(d,'dir'),     mkdir(d);   end

d = fullfile(d,HourMinute);
if ~exist(d,'dir'),     mkdir(d);   end

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
% 4. Joystick Traning. file = joystickTraining.m

tmpTrialType = 4;
switch tmpTrialType
    case 1
        Params.TrialTypeProbs 			= [1 0 0 0];
    case 2
        Params.TrialTypeProbs 			= [0 1 0 0];
    case 3
        Params.TrialTypeProbs 			= [0 0 1 0];
    case 4
        Params.TrialTypeProbs 			= [0 0 0 1];
end
Params.TrialTypeProbs           = Params.TrialTypeProbs/sum(Params.TrialTypeProbs);

clear tmpTrialType

%% Set total number of trials and expected correct trials
Params.NumTrials 				= 100000; % Choose a big number so task doesn't finish before hand
if Params.TrialTypeProbs(1)
    Params.NumCorrectTrials         = 20;
elseif Params.TrialTypeProbs(2)
    Params.NumCorrectTrials         = 1000; % Go/NoGo correct trials after initial sampling
elseif Params.TrialTypeProbs(3)
    Params.NumCorrectTrials         = 1000; % Continuous reward
else
    Params.NumCorrectTrials         = 100000; % Joystick training
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
Params.TimeoutReachStartTarget  = 2; % max time to acquire start target
Params.StartTarget.Hold       	= 0.5;

% Reaching phase
Params.ReactionTimeDelay      	= 2; % Max time to initiate movement

% Go/NoGo
Params.TimeoutReachTarget       = 1.5; % max time to reach reaching target

% Other
Params.TrialLength              = 2;   % Fixed trial length [s]
Params.InterTrialDelay 			= 2;  % delay between each trial [sec]
Params.WrongChoiceDelay         = 5; % Delay when wrong target is chosen [sec]

%% Callibrate Load Cell
[Params, b5] = CallibrateLoadCell(Params, b5);

%%  WORKSPACE, in mm
Params.WsBounds             	= [-150 -150 ; 150 150]; % [Xmin Ymin; Xmax Ymax]
Params.WsCenter 				= mean(Params.WsBounds,1) + [0, 0];


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
Params.StartTarget.Win  		= [200 40]; % radius
Params.StartTarget.Locations 	= {Params.WsCenter + [-40 -40]}; % cell array of locations

%% Solenoid Open
b5.SolenoidOpen_color			= [0 0 1 0.2];
b5.SolenoidOpen_scale 			= [20 20];
b5.SolenoidOpen_pos 			= Params.WsBounds(2,:);

%% Rewards
Params.RewardsVector        = 200; %[ms]
Params.BiasingMulti         = 0.1;

%Model for adaptation of reward
Params.RewardModel.xo          = 75;
Params.RewardModel.w            = 1.5e3;

%% Effort
Params.LoadCellMax                  = 50;
Params.MaxForce = 10; % Measured max force per subject [N]

% Vertical bar outline
b5.BarOutline_color     = [0 0 1 1];
b5.BarOutline_scale     = b5.Frame_scale.* [0.25, 1];
b5.BarOutline_pos       = Params.WsCenter;

% Vertical filling
b5.FillingEffort_color     = [1 1 0 1];
b5.FillingEffort_scale     = b5.Frame_scale .* [0.25, 1];
b5.FillingEffort_pos       = Params.WsCenter - [0, 0] + ...
                    [0, b5.FillingEffort_scale(2)/2];
                
% Horizontal filling
b5.FillingEffortHor_color     = [1 1 0 1];
b5.FillingEffortHor_scale     = b5.Frame_scale .* [1, 0.1];
b5.FillingEffortHor_pos       = Params.WsCenter - [0, 0] + ...
                    [b5.FillingEffortHor_scale(1)/2,0];
                
% ySensitivity
b5.ySensitivity_color     = [1 1 0 0.05];
b5.ySensitivity_scale     = b5.Frame_scale .* [0.25, 1];
b5.ySensitivity_pos       = Params.WsCenter - [0, 0] + ...
                    [0, b5.ySensitivity_scale(2)/2];     
                
% ySensitivity
b5.xSensitivity_color     = [1 1 0 0.05];
b5.xSensitivity_scale     = b5.Frame_scale .* [1, 0.1];
b5.xSensitivity_pos       = Params.WsCenter - [0, 0] + ...
                    [b5.xSensitivity_scale(1)/2,0];                

% Go/NoGo
b5.ProbeTarget_color = [0.8 1 0 1];
b5.ProbeTarget_scale = [1000, 180];
b5.ProbeTarget_pos = Params.WsCenter ;

b5.ProbeTargetTop_color = [0.8 1 0 1];
b5.ProbeTargetTop_scale = b5.ProbeTarget_scale;
b5.ProbeTargetTop_pos = Params.WsCenter ;

Params.EffortVector     = [-0.2];
Params.EffortVectorTop  = [0.2];

Params.TopTargetProbability = 0.50;

%% Pass
Params.PassSensitivity  = 5;
Params.NoGoTap    = 0.025 * b5.Frame_scale(2);

b5.Pass_color     = b5.ProbeTarget_color;
b5.Pass_scale     = b5.ProbeTarget_scale;
b5.Pass_pos       = Params.WsCenter - [0,0 + b5.Pass_scale(2)/2] - ...
                       [0, 150];

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

%% LJJuicer parameters
Params.Solenoid = 'off'; % Global variable for bypass

Params.LJJuicerDOUT = 1; % Which digital output connected to solenoid [1-2]
b5 = LJJuicer(Params, b5, 'off');

%% OTHER
Params.UseCorrectionTrials          = false; % { both of these
Params.UseAdaptiveProbability       = false; % { cannot be true
Params.AdaptiveLookbackLength       = 10;    % num trials to look back
Params.FixedTrialLength             = false;
Params.AllowEarlyReach              = true; % { allow subject to start
                                           % { reach before end of delay
Params.OpeningSound.Enable          = true;
Params.OpeningSound.Next            = 0;
Params.OpeningSound.Counter         = 0;
Params.OpeningSound.Repeats         = 5;
Params.OpeningSound.Intervals         = [10 20]; %(1) wait between repeats [s], (2) wait between groups of repeats [min]


%% SYNC
b5 = bmi5_mmap(b5);
                                           
end
