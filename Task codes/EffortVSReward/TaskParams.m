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

bmi5_cmd('make circle StartTarget');

bmi5_cmd('make open_square Frame 0.01');
bmi5_cmd('make open_square EffortLine 0.01');
bmi5_cmd('make square FillingEffort');

bmi5_cmd('make circle Cursor');
bmi5_cmd('make labjack isometric 4');
bmi5_cmd('make tone GoTone');
bmi5_cmd('make tone RewardTone');
bmi5_cmd('make store int 1 Trial');


bmi5_cmd('make text TotalPoints 32');

bmi5_cmd('make text EffortLabel10 16');
bmi5_cmd('make text EffortLabel100 17');

for ii = 1:6
    for jj = 1:6
        bmi5_cmd(sprintf('make circle Coin0%d_0%d', ii,jj));
    end
end
bmi5_cmd('make square BlackSquare');

% timer
bmi5_cmd('make square TimerBar');
bmi5_cmd('make square ReachTimeout');

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

Params.NumTrials 				= 2000;

%%  Trial Type Function Selection
% do not modify

Params.TrialTypeProbs 			= [0 0 1];
Params.TrialTypeProbs           = Params.TrialTypeProbs/sum(Params.TrialTypeProbs);

%% BLOCKS OF TRIALS
% 1. "regular"/training trials  (2afc)
% 2. psychometric-current-basic (2afc)
% 3. psychometric-current-quest (2afc)
% 4. psychometric-current-quest (yes/no)

Params.BlockTypes = {
'regular/training (2afc)'
'basic psychometric-current (2afc)'
'quest psychometric-current (2afc)'
'quest psychometric-current (yes/no)'
};
Params.DoSequentialBlocks       = true; % 0 - Probabalistic; 1 - Sequential
Params.BlockSequence            = [1 ]; % overflows to start
Params.BlockProbs 				= [0 0 1 0]; % make sure these add to 1 exactly

% this option forces the first block to be type-1 (irrespective of prob)
Params.FirstBlockIsType1 		= false;

% This triggers a keyboard at the end of a block so that paramters can
% be adjusted (will also play an alarm to notify the operator)
Params.KeyboardAtBlockEnd 		= true;

%% DELAYS, PENALTIES and TIMEOUTS [sec]
Params.StartTarget.Hold       	= 0.1;      
Params.ReachDelayRange       	= [0.5 0.5];	% draw from this interval
Params.ReactionTimeDelay      	= 2;
Params.ErrPenalty               = 0;
Params.TimeoutReachStartTarget  = 0.1; % max time to acquire start target
Params.TimeoutReachTarget       = 1.3; % max time to reach reaching target
Params.MovementWindow           = 0.3; % For effort line, time to move [s]
Params.TrialLength              = 3;   % Fixed trial length [s]

%%  Inter-trial Stuff
Params.InterTrialDelay 			= 0.5;  % delay between each trial [sec]

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
b5.Cursor_scale 				= [6 6];        % [mm] % note: diameter!

%% Start Target
b5.StartTarget_color			= [1 0 0 1];
b5.StartTarget_scale 			= [20 20];
Params.StartTarget.Win  		= 20; % radius
Params.StartTarget.Locations 	= {Params.WsCenter + [-40 -40]}; % cell array of locations

%% Probe Effort Target
% Each row corresponds to the gradiention of reward offer per trial
Params.VerticalRewardsMatrix = ...
    [0      0       0.5         0       1;
     0.5    0       1           0       2;
     0.5    1       2           3       4;
     1      2       3           4       5;
     1      2       3           5       6;
     1      2       4           5       7;
     1      2       4           6       8;
     2      4       6           8       10;
     1      3       6           9       12;
     3      6       9           12      14;
     2      6       10          14      18;
     4      8       12          16      20;
     3      8       13          18      23;
     5      10      15          20      25];

%% Effort Line
b5.EffortLine_color     = [0 0 1 1];
b5.EffortLine_scale     = b5.Frame_scale.* [0.25, 1];
b5.EffortLine_pos       = Params.WsCenter;

%% Filling Effort
b5.FillingEffort_color     = [1 1 0 1];
b5.FillingEffort_scale     = b5.Frame_scale .* [0.25, 1];
b5.FillingEffort_pos       = Params.WsCenter - [0, b5.Frame_scale(2)/2] + ...
                    [0, b5.FillingEffort_scale(2)/2];

%% Timer bar
b5.TimerBar_color             	= [0.8 0.8 0.8 1];
b5.TimerBar_scale           	= [b5.Frame_scale(1) 10];
b5.TimerBar_pos                 = [Params.WsCenter(1), ...
                            Params.WsBounds(2,2)+b5.TimerBar_scale(2)/2];

b5.ReachTimeout_color        	= [0.8 0 0 1];
b5.ReachTimeout_scale          	= [2 10];
b5.ReachTimeout_pos = [b5.Frame_scale(1)*...
    (Params.TrialLength - Params.ReactionTimeDelay) / Params.TrialLength ...
    + Params.WsCenter(1) - b5.Frame_scale(1)/2, ...
                            Params.WsBounds(2,2)+b5.ReachTimeout_scale(2)/2];


%% Effort labels
b5.EffortLabel10_color              = [1 1 1 1];
b5.EffortLabel100_color              = [1 1 1 1];

%% Total Points String
b5.TotalPoints_color        = [1 1 1 1];
b5.TotalPoints_pos          = Params.WsCenter;
b5.TotalPoints_v            = [double(sprintf('Points = %04d',0)) zeros(1,19)]';

%% TONES
b5.GoTone_freq 				= 1000;  % (Hz)
b5.GoTone_duration          = 0.3;  % (sec)
b5.GoTone_scale             = 1;    % (units?)

b5.RewardTone_freq 			= 1500; % (Hz)
b5.RewardTone_duration      = 0.3;  % (sec)
b5.RewardTone_scale         = 1;    % (units?)

% REWARD
Params.Reward 				=300;  %(msec)
Params.TempPerf				=0.5;  %(msec)

%% FOR CONVENIENCE DEFINE BLOCKSIZE HERE
% Params.BlockSize 				= 35;
Params.BlockSize 				=1000;

%% OTHER
Params.UseCorrectionTrials          = false; % { both of these
Params.UseAdaptiveProbability       = false; % { cannot be true
Params.AdaptiveLookbackLength       = 10;    % num trials to look back
Params.FixedTrialLength             = true;
Params.TimerOn                      = true;
Params.AllowEarlyReach              = false; % { allow subject to start
                                           % { reach before end of delay

Params.MaxForce                     = 40; % Measured max force per subject [N]

Params.RewardSampleSpace = repmat(1:size(Params.VerticalRewardsMatrix,1), ...
                            1, round(400/size(Params.VerticalRewardsMatrix,1)));
%% SYNC
b5 = bmi5_mmap(b5);
                                           
end
