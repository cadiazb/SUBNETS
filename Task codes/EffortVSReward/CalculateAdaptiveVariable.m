function [Params, dat] = CalculateAdaptiveVariable(Params, dat, ~)
    
    switch randi([1,3],1,1)
        case 1
            switch dat.TrialChoice
                case {'Reference Effort', 'Pass'}
                    Params.RewardAdaptation(Params.RewardAdaptation(:,1) == dat.ProbeEffort,2) ...
                        = min(Params.MaxReward,...
                        dat.ProbeReward + Params.RewardStepUp);

                case 'Probe Effort'
                    Params.RewardAdaptation(Params.RewardAdaptation(:,1) == dat.ProbeEffort,2) ...
                        = max(Params.MinReward,...
                        dat.ProbeReward - Params.RewardStepDown);
            end
        case 2
            switch dat.TrialChoice
                case {'Reference Effort', 'Pass'}
                    Params.RewardAdaptation(Params.RewardAdaptation(:,1) == dat.ProbeEffort,2) ...
                        = min(Params.MaxReward,...
                        ceil(dat.ProbeReward * normrnd(1+Params.RewardRandDist(1), Params.RewardRandDist(2),1)));

                case 'Probe Effort'
                    Params.RewardAdaptation(Params.RewardAdaptation(:,1) == dat.ProbeEffort,2) ...
                        = max(Params.MinReward,...
                        floor(dat.ProbeReward * normrnd(1-Params.RewardRandDist(1), Params.RewardRandDist(2),1)));
            end
        case 3
            display('No adaptation in this trial')
    end