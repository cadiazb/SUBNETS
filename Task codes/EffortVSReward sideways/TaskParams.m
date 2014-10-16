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

bmi5_cmd('make ring StartTarget 0.05');

bmi5_cmd('make square ProbeEffortTarget');
bmi5_cmd('make square ReferenceTarget');

bmi5_cmd('make square StartAxis');
bmi5_cmd('make square ProbeEffortAxis');
bmi5_cmd('make square ReferenceAxis');

bmi5_cmd('make circle Cursor');
bmi5_cmd('make labjack isometric 4');
bmi5_cmd('make tone StartTone');
bmi5_cmd('make tone GoTone');
bmi5_cmd('make tone RewardTone');
bmi5_cmd('make tone PairTone');
bmi5_cmd('make store int 1 Trial');
bmi5_cmd('make open_square Frame 0.01');

bmi5_cmd('make text ProbeRewardString 32');
bmi5_cmd('make text ReferenceRewardString 32');

bmi5_cmd('make text ProbeEffortString 32');
bmi5_cmd('make text ReferenceEffortString 32');
bmi5_cmd('make text TotalPoints 32');
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

Params.NumTrials 				= 600;

%%  Trial Type Function Selection
%  1. Reward adaptation for fixed for
%  2. Force adaptation for fixed reward

Params.TrialTypeProbs 			= [1 0];
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

%%  Inter-trial Stuff
Params.InterTrialDelay 			= 0.5;  % delay between each trial [sec]

%%  WORKSPACE, in mm
Params.WsBounds             	= [-120 -120 ; 175 175]; % [Xmin Ymin; Xmax Ymax]
Params.WsCenter 				= mean(Params.WsBounds,1);
% Params.WsCenter 				= [0 0];


b5.Frame_color  = [1 1 1 0.75];
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

%% Start Axis
b5.StartAxis_color			= [1 1 1 0.75];
b5.StartAxis_scale 			= [0.5 290];
b5.StartAxis_pos            = Params.WsCenter;

%% Start Target
b5.StartTarget_color			= [0 1 0 0.75];
b5.StartTarget_scale 			= [10 10];
Params.StartTarget.Win  		= 20; % radius
Params.StartTarget.Locations 	= {Params.WsCenter + [-40 -40]}; % cell array of locations

%% Probe Effort Target
b5.ProbeEffortTarget_color                  = [0.2 1 0 1];
b5.ProbeEffortTarget_scale                  = [395 60];
Params.ProbeEffortTarget.EffortVector       = [0.1 0.35 0.7 0.9];
Params.ProbeEffortTarget.RewardVector       = [90 95 105 110];

%% Reference Target
b5.ReferenceTarget_color                    = [0 0 1 1];
b5.ReferenceTarget_scale                    = [395 60];
Params.ReferenceTarget.EffortReference      = 0.5;
Params.ReferenceTarget.RewardReference        = 100;

%% Probe effort axis
b5.ProbeEffortAxis_color                = b5.ProbeEffortTarget_color;
b5.ProbeEffortAxis_scale                = [1 290];

%% Reference axis
b5.ReferenceAxis_color               	= b5.ReferenceTarget_color;
b5.ReferenceAxis_scale                  = [1 290];

%% Probe Reward String
b5.ProbeRewardString_color              = [1 1 1 1];

%% Reference Reward String
b5.ReferenceRewardString_color          = [1 1 1 1];

%% Probe Effort String
b5.ProbeEffortString_color              = [1 1 1 1];

%% Big Effort String
b5.ReferenceEffortString_color          = [1 1 1 1];

%% Total Points String
b5.TotalPoints_color        = [1 1 1 1];
b5.TotalPoints_pos          = Params.WsCenter;
b5.TotalPoints_v            = [double(sprintf('Points = %04d',0)) zeros(1,19)]';

%% DELAYS, PENALTIES and TIMEOUTS [sec]
Params.StartTarget.Hold                 = 0.1;
Params.ProbeEffortTarget.Hold     		= 0;         
Params.BigEffortTarget.Hold             = 0;       
Params.ReachDelayRange                  = [0 0];	% draw from this interval
Params.ReactionTimeDelay                 = 2.2;
Params.ErrPenalty                       = 0;
Params.TimeoutReachStartTarget          = 0.1; % max time to acquire start target
Params.TimeoutReachTarget               = 0.8; % max time to reach reaching target

%% TONES
b5.StartTone_freq 			= 500;  % (Hz)
b5.StartTone_duration       = 0.2;  % (sec)
b5.StartTone_scale          = 1;    % (units?)

b5.GoTone_freq 				= 1000;  % (Hz)
b5.GoTone_duration          = 0.3;  % (sec)
b5.GoTone_scale             = 1;    % (units?)

b5.RewardTone_freq 			= 1500; % (Hz)
b5.RewardTone_duration      = 0.3;  % (sec)
b5.RewardTone_scale         = 1;    % (units?)

b5.PairTone_freq 			= 2000; % (Hz)
b5.PairTone_duration      = 1;  % (sec)
b5.PairTone_scale         = 1;    % (units?)

% REWARD
Params.Reward 				=300;  %(msec)
Params.TempPerf				=0.5;  %(msec)

%% ICMS Params
% Params.ICMS.TargetID                = 0; % 0 - stim for left; 1 - right
% Params.ICMS.FreqHz                  = 0;
% Params.ICMS.PWUs                    = 1000000;%500
% Params.ICMS.AmpUA                   = 1;% 6.5 mW
% Params.ICMS.InterphaseUs            = 200;% I don't need this
% Params.ICMS.TrainLengthSec          =1;
% 
% % twelve channels; hopefully he can detect this set :-\
% % each catholde is paired with an anode 400 um away
% % see spreadhseet
% % THESE ARE 1-INDEXED!!!
% Params.ICMS.CathodeVec = [10 14 16 90 73 55 75 95 03 96 61 59];% I don't need this
% Params.ICMS.AnodeVec   = [12 18 20 49 77 53 79 83 54 57 92 65]; % I don't need this
% 
% Params.ICMS.CathodeVec = [95 03 96 61 59];% I don't need this
% Params.ICMS.AnodeVec   = [83 54 57 92 65]; % I don't need this
% 
% % The Putative-Two
% Params.ICMS.CathodeVec = [95 61];% I don't need this
% Params.ICMS.AnodeVec   = [83 92];  % I don't need this 
% 
% Params.ICMS.CathodeVec = [95];% I don't need this
% Params.ICMS.AnodeVec   = [83];  % I don't need this 

%% FOR CONVENIENCE DEFINE BLOCKSIZE HERE
% Params.BlockSize 				= 35;
Params.BlockSize 				=1000;

%% ICMS Psychometric Quest
% Params.ICMSQUEST.InitialGuessUA     = 30;
% Params.ICMSQUEST.MaxAmpUA           = 60;
% Params.ICMSQUEST.ThreshLevel        = 0.90;
% Params.ICMSQUEST.RoundNearestUA     = true;
% Params.ICMSQUEST.ClampToVec         = false;
% Params.ICMSQUEST.AmpVecUA           = [0 5 10 15 20 25 30 35 40 45 50 55 60];
% 
% Params.ICMSQUEST.ResetQOnNewBlock   = true;
% 
% % Note: the ICMSQUEST param set is used both for Questy calculation of
% %       thresholds as well as more traditional psychometric testing.
% %
% % * For all block-types, the Quest estimate of threshold is updated on
% %   completion of any trial where Pr(left) = 0.5
% % * For block-type-2 (psychometric-current-basic), the amplitude current
% %   for each trial is uniformly drawn from the ICMSQUEST.AMPVecUA vector
% % * For block-type-3 (psychometric-current-quest), the amplitude current
% %   for each trial is generated from the Quest estimate. If the boolean
% %   ICMSQUEST.RoundNearestUA is true, then the estimate is rounded to the
% %   nearest uA. If ICMSQUEST.ClampToVec is true, then the estimate is
% %   clamped to the nearest value contained in ICMSQUEST.AmpVecUA.

%% OTHER
Params.UseCorrectionTrials          = false; % { both of these
Params.UseAdaptiveProbability       = false; % { cannot be true
Params.AdaptiveLookbackLength       = 10;    % num trials to look back
Params.FixedTrialLength             = true;
Params.TrialLength                  = 3;   % Fixed trial length [s]

Params.AllowEarlyReach              = true; % { allow subject to start
                                           % { reach before end of delay

Params.MaxForce                     = 40; % Measured max force per subject [N]

Params.AdaptiveReward(:,1)       = Params.ProbeEffortTarget.EffortVector* ...
                                Params.MaxForce * (b5.Frame_scale(2)/2)/50;
for ii=2:11
Params.AdaptiveReward(:,ii)  = Params.ReferenceTarget.RewardReference + ...
                                   [-20, -10, 10, 20];
end

Params.AdaptiveForce(:,1)       = Params.ProbeEffortTarget.RewardVector;
Params.AdaptiveForce(:,2:11)  = Params.ReferenceTarget.EffortReference* ...
                                Params.MaxForce * (b5.Frame_scale(2)/2)/50;
                            
Params.StepSizeAdaptive     = false;
Params.AdaptiveStepUp       = 1.04;
Params.AdaptiveStepDown     = 0.98;

Params.EffortSampleSpace    = repmat(Params.ProbeEffortTarget.EffortVector, ...
    1, ceil(Params.NumTrials/size(Params.ProbeEffortTarget.EffortVector,2)))* ...
                                Params.MaxForce * (b5.Frame_scale(2)/2)/50;
Params.RewardSampleSpace    = repmat(Params.ProbeEffortTarget.RewardVector, ...
    1, ceil(Params.NumTrials/size(Params.ProbeEffortTarget.RewardVector,2)));

                                           
%% SYNC
b5 = bmi5_mmap(b5);
                                           
end
