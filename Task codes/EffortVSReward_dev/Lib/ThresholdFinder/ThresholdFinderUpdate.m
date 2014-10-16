function o=ThresholdFinderUpdate(o,testedValue,response)
% o=ThresholdFinderUpdate(o,testedValue,response)
%
% Update the struct o the reflect the results of a trial
%
% testedValue - the value that was tested
% response    - the result of the trial (1 for correct; 0 for incorrect)

o.q = QuestUpdate(o.q,log(testedValue./o.tMax),response);