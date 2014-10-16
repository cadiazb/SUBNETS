function sd=ThresholdFinderSd(o)
%sd=ThresholdFinderSd(o)
%
% Returns the threshold s.d. given the priors contained in the struct o

[p, x] = ThresholdFinderPdf(o,512);
mu = ThresholdFinderSuggest(o);

sd = 0;
for i=1:length(x)
    sd = sd + ((x(i) - mu).^2 .* p(i));
end

sd = sqrt(sd);