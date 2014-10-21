% This script adjusts the length and position of the timer displayed on the
% edge of the screen.

b5.TimerBar_scale(1) = max(0,b5.Frame_scale(1)*...
    (Params.TrialLength - (b5.time_o - t_start)) / Params.TrialLength);

b5.TimerBar_pos(1) = Params.WsCenter(1) - b5.Frame_scale(1)/2 + ...
                        b5.TimerBar_scale(1)/2;
                    
b5 = bmi5_mmap(b5);

