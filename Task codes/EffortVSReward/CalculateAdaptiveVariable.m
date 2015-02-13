function [Params, Data] = CalculateAdaptiveVariable(Params, Data, trial)
dat = Data(trial);
if isempty(dat.TrialChoice)
    display('No trial choice recorded')
    return
end

tmpPracticeTrials(1:trial) = true;
tmpPracticeTrials(1:(max(find(~[Data(1:trial).OutcomeID], numel(Params.EffortVector), 'first')))) = false;

iTrialSucces = ...
    ([Data(1:trial).ProbeEffort] == dat.ProbeEffort) & ...
    ~[Data(1:trial).OutcomeID] & tmpPracticeTrials; % Get indeces for trials with same probe effort and success outcome, Discard initial trials because S is presumably learning the task

tmpChoseProbe = strcmp({Data(iTrialSucces).TrialChoice}, 'Probe Effort');
tmpChosePass = strcmp({Data(iTrialSucces).TrialChoice}, 'Pass');

tmpEffortIndex = ...
            find(Params.EffortVector == dat.ProbeEffort,1,'first');
        
if dat.ProbesAdaptationState(tmpEffortIndex,2) || isempty(Params.InitialSampling)
    % Check if adaptation for this probe is OFF and S has always chosen
    % probe
    if ~dat.ProbesAdaptationState(dat.ProbesAdaptationState(:,1) == dat.ProbeEffort,2) && all(tmpChoseProbe)
        
        Params.RewardRange(tmpEffortIndex) = ...
            Params.RewardRange(tmpEffortIndex) - 1;
        
        Params.MaxRewardVector(tmpEffortIndex) = ...
            Params.MaxRewardVector(tmpEffortIndex) * 1.5^Params.RewardRange(tmpEffortIndex);
        
        Params.InitialSamplingRewards(tmpEffortIndex, 2:(Params.RewardGradients+1)) = ...
                    Params.MaxRewardVector(tmpEffortIndex) .* [1:Params.RewardGradients]/Params.RewardGradients;
        return
    end
    % Check if adaptation for this probe is OFF and S has always chosen
    % pass
    if ~dat.ProbesAdaptationState(dat.ProbesAdaptationState(:,1) == dat.ProbeEffort,2) && all(tmpChosePass)
        
        if ~Params.RewardRange(tmpEffortIndex) || (dat.ProbeReward == Params.MaxRewardVector(tmpEffortIndex))
            Params.RewardRange(tmpEffortIndex) = ...
                Params.RewardRange(tmpEffortIndex) + 1;
        end
        
        Params.MaxRewardVector(tmpEffortIndex) = ...
            min(Params.AbsoluteMaxReward,Params.MaxRewardVector(tmpEffortIndex) * 1.5^Params.RewardRange(tmpEffortIndex));
        
        Params.InitialSamplingRewards(tmpEffortIndex, 2:(Params.RewardGradients+1)) = ...
                    linspace(max([Data(tmpChosePass).ProbeReward]), Params.MaxRewardVector(tmpEffortIndex), Params.RewardGradients);
        
        return
    end
    
    if ~dat.ProbesAdaptationState(dat.ProbesAdaptationState(:,1) == dat.ProbeEffort,2)
        dat.ProbesAdaptationState(dat.ProbesAdaptationState(:,1) == dat.ProbeEffort,2) = 1;
        Data(trial).ProbesAdaptationState = dat.ProbesAdaptationState;
    end
    
    % Adaptation
    
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