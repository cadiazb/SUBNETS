function [Params, dat] = CalculateAdaptiveVariable(Params, dat, b5)
stairCaseUp = 2;
stairCaseSlowUp = 1;
stairCaseDown = 1;

if dat.TrialNum > 5
    if dat.OutcomeID == 0 % Adapt reward down
        if floor((0.05+b5.FillingEffort_scale(2)/b5.Frame_scale(2)/0.25))>=3
            Params.VerticalRewardsMatrix(dat.ProbeReward, end) = ...
                Params.VerticalRewardsMatrix(dat.ProbeReward, end) - stairCaseDown;
        end
        if floor((0.05+b5.FillingEffort_scale(2)/b5.Frame_scale(2)/0.25))< 2
            Params.VerticalRewardsMatrix(dat.ProbeReward, end) = ...
                Params.VerticalRewardsMatrix(dat.ProbeReward, end) + stairCaseSlowUp;
        end
    elseif dat.OutcomeID == 4 % Adapt reward up. Trial cancelled @ reach
        Params.VerticalRewardsMatrix(dat.ProbeReward, end) = ...
            Params.VerticalRewardsMatrix(dat.ProbeReward, end) + stairCaseUp;
    end
elseif dat.TrialNum > 0
    if dat.OutcomeID == 4 % Adapt reward up. Trial cancelled @ reach
        Params.VerticalRewardsMatrix(dat.ProbeReward, end) = ...
            Params.VerticalRewardsMatrix(dat.ProbeReward, end) + stairCaseUp;
    end
end
end