function t=ThresholdFinderSuggestQuantile(o)
%t=ThresholdFinderSuggestQuantile(o)
%
% Suggest a threshold t given the priors contained in the struct o
% 
% Uses the "optimal" Quantile.

t = o.tMax.*exp(QuestQuantile(o.q));