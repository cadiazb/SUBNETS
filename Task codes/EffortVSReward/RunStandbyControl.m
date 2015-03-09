        

% Initialize bmi5
global bmi5_in bmi5_out;

bmi5_out = fopen('/tmp/bmi5_out.fifo', 'r'); 
bmi5_in  = fopen('/tmp/bmi5_in.fifo',  'w'); 

bmi5_cmd('make labjack isometric 1 1'); 
eval(bmi5_cmd('mmap'));

b5.isometricDOUT_channels = 0;
b5 = bmi5_mmap(b5);

Params.LJJuicerDOUT = 1;

% Run GUI
[b5, controlWindow] = StandbyControl(Params,b5, 1);