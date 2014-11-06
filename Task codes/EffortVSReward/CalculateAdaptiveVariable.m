function [Params, dat] = CalculateAdaptiveVariable(Params, Data, b5, trial)
    dat = Data(trial);
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
            iTrialSucces = ([Data(1:trial).ProbeEffort] == dat.ProbeEffort) & ...
                ~[Data(1:trial).OutcomeID]; % Get indeces for trials with same probe effort and success outcome
            tmpChoseProbe = strcmp({Data(iTrialSucces).TrialChoice}, 'Probe Effort');
            tmpChosePass = strcmp({Data(iTrialSucces).TrialChoice}, 'Pass');
            if isempty(Params.InitialSampling)
                if all(tmpChoseProbe)
                tmpEffortIndex = find(Params.ProbeEffortTarget.EffortVector == (dat.ProbeEffort / ...
                                (Params.MaxForce * (b5.Frame_scale(2)/2)/50)),1,'first');
                Params.RewardRange(tmpEffortIndex) = Params.RewardRange(tmpEffortIndex) - 1;
                Params.MaxReward(tmpEffortIndex) = Params.MaxReward(tmpEffortIndex) * 1.5^Params.RewardRange(tmpEffortIndex);
                Params.InitialSampling      = dat.ProbeEffort;
                Params.InitialSampling(:, 2:(Params.RewardGradients+1)) = ...
                            Params.MaxReward(tmpEffortIndex) .* [1:Params.RewardGradients]/Params.RewardGradients;
                return
                end
                if  all(tmpChosePass)
                tmpEffortIndex = find(Params.ProbeEffortTarget.EffortVector == (dat.ProbeEffort / ...
                                (Params.MaxForce * (b5.Frame_scale(2)/2)/50)),1,'first');
                if ~Params.RewardRange(tmpEffortIndex) || dat.ProbeReward == Params.MaxReward(tmpEffortIndex)
                    Params.RewardRange(tmpEffortIndex) = Params.RewardRange(tmpEffortIndex) + 1;
                end
                Params.MaxReward(tmpEffortIndex) = Params.MaxReward(tmpEffortIndex) * 1.5^Params.RewardRange(tmpEffortIndex);
                Params.InitialSampling      = dat.ProbeEffort;
                Params.InitialSampling(:, 2:(Params.RewardGradients+1)) = ...
                            Params.MaxReward(tmpEffortIndex) .* [1:Params.RewardGradients]/Params.RewardGradients;
                return
                end
                
                % Adaptation
                tmpEffortIndex = find(Params.ProbeEffortTarget.EffortVector == (dat.ProbeEffort / ...
                                (Params.MaxForce * (b5.Frame_scale(2)/2)/50)),1,'first');
            if isempty(Params.ProbeModels.(['Effort' num2str(tmpEffortIndex)]))
                [tmpReward, Params.ProbeModels.(['Effort' num2str(tmpEffortIndex)])] = ...
                    AdaptiveSampling([Data(iTrialSucces).ProbeReward],tmpChoseProbe);
            else
                [tmpReward, Params.ProbeModels.(['Effort' num2str(tmpEffortIndex)])] = ...
                    AdaptiveSampling([Data(iTrialSucces).ProbeReward],tmpChoseProbe, Params.ProbeModels.(['Effort' num2str(tmpEffortIndex)]));
            end
                Params.RewardAdaptation(Params.RewardAdaptation(:,1) == ...
    (dat.ProbeEffort/(Params.MaxForce * (b5.Frame_scale(2)/2)/50)), 2) = floor(10*tmpReward)/10;
            end
        case 4
            display('No adaptation in this trial')
    end