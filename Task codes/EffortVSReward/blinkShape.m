function [Params, b5] = blinkShape(Params, b5, shapeName, freq, duration)
% Use this function to make shapes blink on the screen
% shapeNames = Cell of strings with names of shapes exactly as fields in b5
% freq = Vector with blinking frequencies.
% duration = time in seconds of shape blinking

if ~exist('shapeName', 'var') || isempty(shapeName)
    warning('shapeName is required. No changes implemented')
    return
end
if ~exist('freq', 'var') || isempty(freq)
    warning('freq is required. No changes implemented')
    return
end

% FOR DRAWING OBJECTS
DRAW_NONE     = 0;
DRAW_SUBJECT  = 1;
DRAW_OPERATOR = 2;
DRAW_BOTH     = 3;

b5 = bmi5_mmap(b5);
tPrevBlink = zeros(1, numel(freq));
tPrevBlink(:) = b5.time_o;
tStart = b5.time_o;
while (b5.time_o - tStart) < duration
    b5 = bmi5_mmap(b5);
    for ii = 1:numel(shapeName)
        if (b5.time_o - tPrevBlink(ii)) >= 1/freq(ii)
            if b5.([shapeName{ii} '_draw'])
                b5.([shapeName{ii} '_draw']) = DRAW_NONE;
            else
                b5.([shapeName{ii} '_draw']) = DRAW_BOTH;
            end
            tPrevBlink(ii) = b5.time_o;
        end
    end
end
for ii = 1:numel(shapeName)
    b5.([shapeName{ii} '_draw']) = DRAW_BOTH;
end
b5 = bmi5_mmap(b5);
end