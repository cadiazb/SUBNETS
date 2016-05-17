% Transfer data to servers

%% Copy to Dropbox
system('cp --update --recursive /home/motorlab/Data/SUBNETS/EffortVSReward/ /home/motorlab/Dropbox/Sabes\ Lab/SUBNETS/task2go_Data/')

%% Copy to minnie
% mount minnie if not mounted already. Need CIN login
system('sudo mount.cifs //minnie.cin.ucsf.edu/data4/ /home/motorlab/minnie/data4 -o username=kderosier, domain=KECK-CENTER, uid=motorlab, gid=motorlab')
system('sudo cp --update --recursive /home/motorlab/Data/SUBNETS/inCage/MP/2015/10/* /home/motorlab/minnie/kderosier/inCage/MP/2015/10/')

%% Move to trasferedData folder to avoid copying several copy in servers
system('mv -u /home/motorlab/Data/SUBNETS/EffortVSReward/* -t /home/motorlab/txData/SUBNETS/EffortVSReward/')