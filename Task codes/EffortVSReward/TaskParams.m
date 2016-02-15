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
PathAdder('Lib/Sounds')

%% First, we connect to BMI5 and create the necessary objects
% We'll populate their values below
bmi5_cmd('clear_all');
bmi5_cmd('delete_all');

% Common objects to both tasks
bmi5_cmd('make square DownTarget');
bmi5_cmd('make square UpTarget');
bmi5_cmd('make square OneTarget');
bmi5_cmd('make square StartTarget');
bmi5_cmd('make open_square Frame 0.01');
bmi5_cmd('make open_square BarOutline 0.03');
% bmi5_cmd('make square xSensitivity');
% bmi5_cmd('make square ySensitivity');
bmi5_cmd('make circle Cursor');

bmi5_cmd('make labjack isometric 4 2 2');
bmi5_cmd('make store int 1 Trial');

% For joystickTraining mode
bmi5_cmd('make square WrongWay');


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
% 1. Reward adapt to center
% 2. Effort adapt to center
% 3. Reward tracking with fixed effort
% 4. Effort tracking with fixed reward
% 5. Reward and effort tracking
% 6. One target (@ stdR & stdE)

Params.TrialTypeBlocks          = [3 5 ]; % sequence of trial types
Params.LoopBlocks               = true; % if false, continue with last trial type forever
Params.BlockLength              =30; % number of successes per block
Params.NumTrials 				= 100000; % Choose a big number so task doesn't finish before hand

% extend Params.TrialTypeBlocks to last until we reach NumTrials
m=ceil(Params.NumTrials/Params.BlockLength);
if Params.LoopBlocks
    pattern=Params.TrialTypeBlocks;
    n=numel(pattern);
    for i=n+1:n:m-n
        Params.TrialTypeBlocks(i:i+n-1)=pattern;
    end
else
    n=Params.TrialTypeBlocks(end);
    for i=numel(Params.TrialTypeBlocks):m
        Params.TrialTypeBlocks(i)=n;
    end
end
clear m n i pattern

%% DELAYS, PENALTIES and TIMEOUTS [sec]
% Start trial
Params.TimeoutReachStartTarget  = 2.5; % max time to acquire start target
Params.StartTarget.Hold       	= 0.6; %0.5

% Reaching phase
Params.HoldDown                 = 0.5; % required min hold time
Params.HoldUp                   = 0.48;
Params.ReactionTimeDelay      	= 2; % Max time to initiate movement
Params.TimeoutReachTarget       = 1.6; % max time to reach reaching target

% Other
Params.TrialLength              = 15;   % Fixed trial length [s]
Params.InterTrialDelay 			= 3;  % delay between each trial [sec]
Params.WrongChoiceDelay         = 4; % Delay when wrong target is chosen [sec]

%% Callibrate Load Cell
[Params, b5]                    = CallibrateLoadCell(Params, b5);

%%  WORKSPACE, in mm
Params.WsBounds             	= [-150 -150 ; 150 150]; % [Xmin Ymin; Xmax Ymax]
Params.WsCenter 				= mean(Params.WsBounds,1) + [0, 0];


b5.Frame_color                  = [1 1 1 1];
b5.Frame_scale                  = range(Params.WsBounds);
b5.Frame_pos                    = Params.WsCenter;

%% Cursor
b5.Cursor_color 				= [1 1 0 1]; % RGBA 
b5.Cursor_scale 				= [35 17.5];        % [mm] % note: diameter!

%% Start Target
b5.StartTarget_color			= [0 1 0 1];
b5.StartTarget_scale 			= [0.25*b5.Frame_scale(1) 40];
Params.StartTarget.Win  		= 0.5*b5.StartTarget_scale; % [75 30]; % radius
Params.StartTarget_pos          = Params.WsCenter;
% Params.StartTarget.Locations 	= {Params.WsCenter + [-40 -40]}; % cell array of locations

%% Targets
b5.UpTarget_color               = [0 1 0 1];
b5.UpTarget_scale               = [120 50];
Params.UpTarget_pos             = Params.StartTarget_pos + ...
                                    [0,0.1 * b5.Frame_scale(2)] ...
                                    + [0,b5.UpTarget_scale(2)/2];

b5.DownTarget_color             = b5.UpTarget_color;
b5.DownTarget_scale             = b5.UpTarget_scale;
Params.DownTarget_pos           = Params.StartTarget_pos + ...
                                    [0,-0.1 * b5.Frame_scale(2)] ...
                                    + [0,-b5.DownTarget_scale(2)/2];

Params.UpTargetProbability      = 0.5; % for joystickTraining mode

% Rewards
Params.StdReward                = 180; %[ms]
% multipliers for StdReward
Params.UpReward                 = [rand(1,100)*0.8+0.1]; 
Params.DownReward               = 1.0-Params.UpReward;
Params.UpReward=2*Params.UpReward;
Params.DownReward=2*Params.DownReward;


% Effort
Params.LoadCellMax              = 50;
Params.MaxForce                 = 10; % Measured max force per subject 
Params.StdEffort                = 0.9;
Params.UpEScale                 = 2.25;
Params.DownEScale               = 1.0;
Params.UpEffort                 = round(rand(1,100));
Params.DownEffort               = [((1.0-Params.UpEffort)*(0.25) + (0.75))];
Params.UpEffort                 = [Params.UpEffort*0.25+0.75];

% Changing rewards & effort
Params.BiasingMulti             = 0.5; % for shifting reward or effort
Params.AvgOver                  = 10;
Params.AdaptStep                = 15; % can't be smaller than Params.AvgOver
Params.TrialsSinceAdapt         = 2*Params.AdaptStep;
Params.RandDist                 = makedist('Normal',0,1.0);

% For one target trials
b5.OneTarget_color              = [0 1 0 1];
b5.OneTarget_scale              = b5.UpTarget_scale;
b5.OneTarget_pos                = Params.WsCenter;  % in one target trials we will move it on each trial
b5.OneTarget_draw               = DRAW_NONE;

%% Other visuals
% Vertical bar outline
b5.BarOutline_color             = [0 0 1 0];
b5.BarOutline_scale             = b5.Frame_scale.* [0.25, 1];
b5.BarOutline_pos               = Params.WsCenter;
                
% % ySensitivity
% b5.ySensitivity_color           = [1 1 0 0.05];
% b5.ySensitivity_scale           = b5.Frame_scale .* [0.25, 1];
% b5.ySensitivity_pos             = Params.WsCenter - [0, 0] + ...
%                                     [0, b5.ySensitivity_scale(2)/2];     
%                 
% % ySensitivity
% b5.xSensitivity_color           = [1 1 0 0.05];
% b5.xSensitivity_scale           = b5.Frame_scale .* [1, 0.1];
% b5.xSensitivity_pos             = Params.WsCenter - [0, 0] + ...
%                                     [b5.xSensitivity_scale(1)/2,0];                

% % Wrong way
b5.WrongWay_color               = [1 0 0 0.5];
b5.WrongWay_scale               = [1000 100];
b5.WrongWay_pos                 = Params.WsCenter; % in one target trials we will move it on each trial
b5.WrongWay_draw                = DRAW_NONE; % default is don't draw

%% Sounds
[Params.goCue.Y,Params.goCue.Fs] = audioread(fullfile('Lib/Sounds/beep.wav'));
[Params.badCue.Y,Params.badCue.Fs] = audioread(fullfile('Lib/Sounds/buzz.wav'));

%% LJJuicer parameters
Params.Solenoid = 'off'; % Global variable for bypass

Params.LJJuicerDOUT = 1; % Which digital output connected to solenoid [1-2]
b5 = LJJuicer(Params, b5, 'off');

%% SYNC
b5 = bmi5_mmap(b5);
                                           
end
