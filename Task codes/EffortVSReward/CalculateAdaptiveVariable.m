function [Params, dat] = CalculateAdaptiveVariable(Params, dat, b5)
stairCaseUp = 2;
stairCaseDown = 1;

if dat.TrialNum > 20
    if dat.OutcomeID == 0 % Adapt reward down
        tmpRewards = Params.VerticalRewardsMatrix(:,end);
        tmpRewards(tmpRewards >= tmpRewards(dat.ProbeEffort) - stairCaseDown) = ...
            tmpRewards(dat.ProbeEffort) - stairCaseDown;
        Params.VerticalRewardsMatrix(:,end) = tmpRewards;
    elseif dat.OutcomeID == 4 % Adapt reward up. Trial cancelled @ reach
        tmpRewards = Params.VerticalRewardsMatrix(:,end);
        tmpRewards(tmpRewards <= tmpRewards(dat.ProbeEffort) + stairCaseUp) = ...
            tmpRewards(dat.ProbeEffort) + stairCaseUp;
        Params.VerticalRewardsMatrix(:,end) = tmpRewards;
    end
elseif dat.TrialNum > 10
    if dat.OutcomeID == 4 % Adapt reward up. Trial cancelled @ reach
        tmpRewards = Params.VerticalRewardsMatrix(:,end);
        tmpRewards(tmpRewards <= tmpRewards(dat.ProbeEffort) + stairCaseUp) = ...
            tmpRewards(dat.ProbeEffort) + stairCaseUp;
        Params.VerticalRewardsMatrix(:,end) = tmpRewards;
    end
end
end