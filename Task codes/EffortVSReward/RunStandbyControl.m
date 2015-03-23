        

% Initialize bmi5
global bmi5_in bmi5_out;

bmi5_out = fopen('/tmp/bmi5_out.fifo', 'r'); 
bmi5_in  = fopen('/tmp/bmi5_in.fifo',  'w'); 

bmi5_cmd('clear_all');
bmi5_cmd('delete_all');
bmi5_cmd('make labjack isometric 1 1');
bmi5_cmd('make circle CueTarget');
eval(bmi5_cmd('mmap'));

%% Calibrate Display
c = load('/home/motorlab/sabes-exp-ctrl/bmi5/matlab/calibration_polhemus.mat'); 
qp = c.q';
q2 = eye(4); 
q2(1:2, 1:2) = qp(1:2, 1:2); 
q2(1:2, 4) = qp(1:2, 4); 
b5.affine_m44 = q2;
b5 = bmi5_mmap(b5);
Params.pm = c.pm;
%%
Params.LJJuicerDOUT = 1;
b5 = LJJuicer(Params, b5, 'off');
b5 = bmi5_mmap(b5);

b5.CueTarget_pos = [0 0];
b5.CueTarget_scale = [480 480];
b5.CueTarget_color = [0 1 0 0.5];
b5 = bmi5_mmap(b5);
% Run GUI
[b5, controlWindow] = StandbyControl(Params,b5, 1);