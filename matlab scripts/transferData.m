% Transfer data to servers

%% Copy to Dropbox
system('cp --update --recursive /home/motorlab/Data/SUBNETS/EffortVSReward/ /home/motorlab/Dropbox/Sabes\ Lab/SUBNETS/task2go_Data/')

%% Copy to minnie
% mount minnie if not mounted already. Need CIN login
% system('sudo mount.cifs //minnie.cin.ucsf.edu/data1/ /home/motorlab/minnie/ -o username=cadiaz, domain=KECK-CENTER, uid=motorlab, gid=motorlab')
system('sudo cp --update --recursive /home/motorlab/Data/SUBNETS/EffortVSReward/ /home/motorlab/minnie/Camilo/SUBNETS/task2go_Data/')

%% Move to trasferedData folder to avoid copying several copy in servers
system('mv -u /home/motorlab/Data/SUBNETS/EffortVSReward/* -t /home/motorlab/txData/SUBNETS/EffortVSReward/')