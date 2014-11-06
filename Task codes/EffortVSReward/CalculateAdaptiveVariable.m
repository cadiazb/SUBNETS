function [Params, dat] = CalculateAdaptiveVariable(Params, dat, b5)
    if isempty(dat.TrialChoice)
        display('No trial choice recorded')
        return
    end
%     switch randi([1,3],1,1)
    switch 3
        case 1
            display('Reward adaptation 1')
            tmpEffort = (dat.ProbeEffort/(Params.MaxForce * (b5.Frame_scale(2)/2)/50));
            switch dat.TrialChoice
                case {'Reference Effort', 'Pass'}
                    Params.RewardAdaptation(Params.RewardAdaptation(:,1) == tmpEffort,2) ...
                        = min(Params.MaxReward,...
                        dat.ProbeReward + Params.RewardStepUp);

                case 'Probe Effort'
                    Params.RewardAdaptation(Params.RewardAdaptation(:,1) == tmpEffort,2) ...
                        = max(Params.MinReward,...
                        dat.ProbeReward - Params.RewardStepDown);
            end
        case 2
            display('Reward adaptation 2')
            tmpEffort = (dat.ProbeEffort/(Params.MaxForce * (b5.Frame_scale(2)/2)/50));
            switch dat.TrialChoice
                case {'Reference Effort', 'Pass'}
                    Params.RewardAdaptation(Params.RewardAdaptation(:,1) == tmpEffort,2) ...
                        = min(Params.MaxReward,...
                        ceil(dat.ProbeReward * normrnd(1+Params.RewardRandDist(1), Params.RewardRandDist(2),1)));

                case 'Probe Effort'
                    Params.RewardAdaptation(Params.RewardAdaptation(:,1) == tmpEffort,2) ...
                        = max(Params.MinReward,...
                        floor(dat.ProbeReward * normrnd(1-Params.RewardRandDist(1), Params.RewardRandDist(2),1)));
            end
        case 3
            
        case 4
            display('No adaptation in this trial')
    end