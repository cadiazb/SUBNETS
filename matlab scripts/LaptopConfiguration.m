%% Laptop specific cofiguration

% task2go
system('xrandr --output DP1 --right-of eDP1')
system('xbacklight -dec 10')
system('xbacklight -inc 70')
system('sudo mount.cifs //minnie.cin.ucsf.edu/data1/ /home/motorlab/minnie/ -o username=cadiaz, domain=KECK-CENTER, uid=motorlab, gid=motorlab')

% Delete tmp files
system('rm -r /tmp/2014-*')
