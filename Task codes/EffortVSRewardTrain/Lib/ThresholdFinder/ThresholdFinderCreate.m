function o = ThresholdFinderCreate(tGuess, tMax, pThreshold, slope, pMax, pChance)
%o = ThresholdFinderCreate(tGuess, tMax, tGuessSd, pThreshold, slope, pMax, pChance)
%
% Creates a struct o with all the information necessary to measure
% threshold.
%
% tGuess     - your prior guess for the threshold value (in whatever units
%              your psychometrically varying quantity is measured).
% tMax       - the maximum quantity value that you will test
% pThreshold - the threshold probability (ie 0.75)
% slope      - the slope (steepness) of the psychometric curve that you
%              think characterizes your data. Higher numbers are steeper.
%              Try: 3.5 or so
% pMax       - the maximum response rate. 1.0 at most but realistically
%              0.99 or 0.95
% pChance    - the chance response rate. Typically 0.5 for 2AFC.

o.q = [];
o.tGuess = tGuess;
o.tMax = tMax;
t = log(o.tGuess./o.tMax);

% hardcoded
o.tGuessSd = 3;
o.grain = 0.005;
o.range = 20;

o.q=QuestCreate(t,o.tGuessSd,pThreshold,slope,1-pMax,pChance,o.grain,o.range);