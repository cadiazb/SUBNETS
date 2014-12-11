%% Laptop specific cofiguration

% task2go
system('xrandr --output DP1 --right-of eDP1')
system('xbacklight -dec 10')
system('xbacklight -inc 70')

% Delete tmp files
system('rm -r /tmp/2014-*')
