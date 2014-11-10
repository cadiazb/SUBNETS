function [xsamp,model] = AdaptiveSampling(X,Choice,model)

% function [xsamp,model] = AdaptiveSampling(X,Choice,model)
%
% X:        Nx1  independent variable (any real numbers)
% Choice:   Nx1  binary decision: {0,1}
% model:    structure:  model.xo, model.w [optional - serves as initial
%              condition for fitting]
%
% Fit a sigmoid to {X,Choice}:   
%       p(Choice==1) = 1/(1+exp(-(x-xo)/w))
% Then sample from the cdf defined by the sigmoid:
%       xsamp = xo - w*log(1/rand-1))
%


VERBOSE = 0; 


%% Fitting
% Initial condition, if needed
if(nargin<3) par = [median(X) max(X)-min(X)];
else         par = [model.xo  model.w];
end
parMin = [min(X)-0.5*(max(X)-min(X)), 0.001];
parMax = [max(X)+0.5*(max(X)-min(X)), 10*(max(X)-min(X))];

opt = optimset('fmincon');
if(VERBOSE<2), opt = optimset(opt,'Display','off'); end
opt = optimset(opt,'Algorithm','interior-point');
tic;
par = fmincon(@(par)(cost(par,X,logical(Choice))),par,[],[],[],[],parMin,parMax,[],opt);

model.xo = par(1);
model.w  = par(2);

if(VERBOSE) fprintf(1,'Fitting Time: %.2f s (N=%d)\n',toc,length(X)); end

%% Sample
xsamp = model.xo - model.w*log(1/rand-1);

% if(abs(xsamp)>20) keyboard; end

%% Functions - Sigmoid
function p=sigmoid(par,X)
p = 1./(1+exp(-(X-par(1))/par(2)));

%% Functions - Cost
function c = cost(par,X,Choice)
NormWt = 10/length(X);

p = sigmoid(par,X);
c = -sum(log(p(Choice)))-sum(log(1-p(~Choice))) + NormWt/par(2);

