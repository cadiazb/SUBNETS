function ExperimentStart()

global bmi5_in bmi5_out sort_in sort_out binmap binned;

ExperimentConfig;

% for signaling with bmi5
bmi5_in  = fopen(BMI5FifoInFile,  'w');
bmi5_out = fopen(BMI5FifoOutFile, 'r');

% for signaling with gtkclient
sort_in    = fopen(SortFifoInFile,  'w'); 
sort_out   = fopen(SortFifoOutFile, 'r');

% mmap memory that holds binned neurons.
%binmap = memmapfile(BinFile, 'Format', {'uint16' [10 194] 'x'});
%binned = binmap.Data(1).x;

stream0 = RandStream('mt19937ar','Seed',sum(100*clock));
RandStream.setGlobalStream(stream0); % Matlab >= 2011b

end