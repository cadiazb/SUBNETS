function smoothTrace = loadCellFilter(forceTrace)


FT = forceTrace(1:find(~isnan(forceTrace(:,1)),1,'last'),:);
y  = FT(:,3);
x  = FT(:,2);
N  = length(y);

%% Filter
ORD = 2;      % Order of the filter (dimensionality of the "state")
filtB = [0.0200833655642113    0.0401667311284225    0.0200833655642113];
filtA = [1.0000   -1.56101807580072    0.641351538057563];
% Flo = 0.1;  % Where 1 is SamplingFreq/(2*(N/2+1));
% [filtB,filtA] = butter(ORD,Flo); % A butterworth filter


%% ONLINE WITH A FIX FOR AMPLIFICATION near ZERO
% ORD - filter order defined above
% b,a - filter parameters defined above
ysmooth = nan(N,1);
xsmooth = nan(N,1);
THRESH = 40e-3;  % 40e-3 default, or 50e-3 for more aggressive squashing
SQUASH_EXP = 2;  % 2 default, or 3 for more aggressive squashing 

% Filter y
for i=1:length(y),
    % fix expansion at zero
    if( abs(y(i)) < THRESH )
        y(i) = THRESH * sign(y(i)) * (abs(y(i))/THRESH).^SQUASH_EXP;
    end
    
    if(i<ORD),
        % Not enough data to perform filter
        % For now, just don't smooth
        ysmooth(i) = y(i);
    elseif(i==ORD),
        % Now you have enough data to estimate state
        % To avoid a transient, just set these values to the mean of the
        % first ORD timesteps
        ysmooth(1:i) = mean(y(1:i));
    else
        ysmooth(i) = filtB*y(i-[0:ORD]) - filtA(2:end)*ysmooth(i-[1:ORD]);
    end
end

% Filter x
for i=1:length(x),
    % fix expansion at zero
    if( abs(x(i)) < THRESH )
        x(i) = THRESH * sign(x(i)) * (abs(x(i))/THRESH).^SQUASH_EXP;
    end
    
    if(i<ORD),
        % Not enough data to perform filter
        % For now, just don't smooth
        xsmooth(i) = x(i);
    elseif(i==ORD),
        % Now you have enough data to estimate state
        % To avoid a transient, just set these values to the mean of the
        % first ORD timesteps
        xsmooth(1:i) = mean(x(1:i));
    else
        xsmooth(i) = filtB*x(i-[0:ORD]) - filtA(2:end)*xsmooth(i-[1:ORD]);
    end
end


%% Create output variable
smoothTrace = forceTrace;
smoothTrace(1:numel(y),3) = ysmooth;
smoothTrace(1:numel(x),2) = xsmooth;
