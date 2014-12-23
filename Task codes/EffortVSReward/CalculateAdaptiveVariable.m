function [Params, Data] = CalculateAdaptiveVariable(Params, Data, trial)
    dat = Data(trial);
    if isempty(dat.TrialChoice)
        display('No trial choice recorded')
        return
    end
iTrialSucces = ([Data(1:trial).ProbeEffort] == dat.ProbeEffort) & ...
    ~[Data(1:trial).OutcomeID]; % Get indeces for trials with same probe effort and success outcome
tmpChoseProbe = strcmp({Data(iTrialSucces).TrialChoice}, 'Probe Effort');
tmpChosePass = strcmp({Data(iTrialSucces).TrialChoice}, 'Pass');
if isempty(Params.InitialSampling)
    if ~dat.ProbesAdaptationState(dat.ProbesAdaptationState(:,1) == dat.ProbeEffort,2) && all(tmpChoseProbe)
        tmpEffortIndex = find(Params.EffortVector == dat.ProbeEffort,1,'first');
        Params.RewardRange(tmpEffortIndex) = Params.RewardRange(tmpEffortIndex) - 1;
        Params.MaxRewardVector(tmpEffortIndex) = Params.MaxRewardVector(tmpEffortIndex) * 1.5^Params.RewardRange(tmpEffortIndex);
        Params.InitialSamplingRewards(tmpEffortIndex, 2:(Params.RewardGradients+1)) = ...
                    Params.MaxRewardVector(tmpEffortIndex) .* [1:Params.RewardGradients]/Params.RewardGradients;
        return
    end
    if ~dat.ProbesAdaptationState(dat.ProbesAdaptationState(:,1) == dat.ProbeEffort,2) && all(tmpChosePass)
        tmpEffortIndex = find(Params.EffortVector == dat.ProbeEffort,1,'first');
        if ~Params.RewardRange(tmpEffortIndex) || dat.ProbeReward == Params.MaxRewardVector(tmpEffortIndex)
            Params.RewardRange(tmpEffortIndex) = Params.RewardRange(tmpEffortIndex) + 1;
        end
        Params.MaxRewardVector(tmpEffortIndex) = min(Params.AbsoluteMaxReward,Params.MaxRewardVector(tmpEffortIndex) * 1.5^Params.RewardRange(tmpEffortIndex));
        Params.InitialSamplingRewards(tmpEffortIndex, 2:(Params.RewardGradients+1)) = ...
                    Params.MaxRewardVector(tmpEffortIndex) .* [1:Params.RewardGradients]/Params.RewardGradients;
        return
    end
    
    if ~dat.ProbesAdaptationState(dat.ProbesAdaptationState(:,1) == dat.ProbeEffort,2)
        dat.ProbesAdaptationState(dat.ProbesAdaptationState(:,1) == dat.ProbeEffort,2) = 1;
        Data(trial).ProbesAdaptationState = dat.ProbesAdaptationState;
    end
    % Adaptation
    tmpEffortIndex = find(Params.EffortVector == dat.ProbeEffort,1,'first');
    if isempty(Params.ProbeModels.(['Effort' num2str(tmpEffortIndex)]))
        [tmpReward, Params.ProbeModels.(['Effort' num2str(tmpEffortIndex)])] = ...
            AdaptiveSampling([Data(iTrialSucces).ProbeReward],tmpChoseProbe);
    else
        [tmpReward, Params.ProbeModels.(['Effort' num2str(tmpEffortIndex)])] = ...
            AdaptiveSampling([Data(iTrialSucces).ProbeReward],tmpChoseProbe, Params.ProbeModels.(['Effort' num2str(tmpEffortIndex)]));
    end
    Params.RewardAdaptation(Params.RewardAdaptation(:,1) == ...
        dat.ProbeEffort, 2) = min(max(floor(10*tmpReward)/10,0), Params.AbsoluteMaxReward);
end