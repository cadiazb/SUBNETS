%% Laptop specific cofiguration

% task2go
%% Screen
system('xrandr --output DP1 --left-of eDP1')
% system('xrandr --output DP1 --mode 1920x1080')
%%
system('xbacklight -dec 10')
system('xbacklight -inc 70')
%% Mount minnie
system('sudo mount.cifs //minnie.cin.ucsf.edu/data1/ /home/motorlab/minnie/ -o username=cadiaz, domain=KECK-CENTER, uid=motorlab, gid=motorlab')

% Delete tmp files
%%
system('rm -r /tmp/2015-*')
