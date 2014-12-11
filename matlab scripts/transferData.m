% Transfer data to servers

%% Copy to Dropbox
system('cp --update --recursive /home/motorlab/Data/SUBNETS/EffortVSReward/ /home/motorlab/Dropbox/Sabes\ Lab/SUBNETS/task2go_Data/')

%% Copy to minnie
system('sudo cp --update --recursive /home/motorlab/Data/SUBNETS/EffortVSReward/ /home/motorlab/minnie/Camilo/SUBNETS/task2go_Data/')

%% Move to trasferedData folder to avoid copying several copy in servers
system('mv -u /home/motorlab/Data/SUBNETS/EffortVSReward/ /home/motorlab/txData/SUBNETS/EffortVSReward/')