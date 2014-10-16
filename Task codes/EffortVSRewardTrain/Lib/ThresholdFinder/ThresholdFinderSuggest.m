function t=ThresholdFinderSuggest(o)
%t=ThresholdFinderSuggest(o)
%
% Suggest a threshold t given the priors contained in the struct o
% 
% Uses the mean

t = o.tMax.*exp(QuestMean(o.q));