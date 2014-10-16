function [p x]=ThresholdFinderPdf(o,n)
%[p x] =ThresholdFinderPdf(o)
%
% Get the normalized probability density of the candidate threshold
%
% n - number of points over which to discretize the pdf
%
% p - the pdf over the range from [0.01, 2] * tMax
%     where tMax was defined when the struct o was created.
% x - the values at which the pdf is evaluated

t = linspace(log(0.01),log(2),n);
p = QuestPdf(o.q,t);
x = o.tMax.*exp(t);
