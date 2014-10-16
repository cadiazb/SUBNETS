function [Params, dat] = CalculateAdaptiveVariable(Params, dat, b5)
    if Params.StepSizeAdaptive
        adaptStep = false;
        switch dat.TrialType
            case {8}
                Params.AdaptiveReward(:,3:end) = Params.AdaptiveReward(:,2:end-1);
            case {9}
                Params.AdaptiveForce(:,3:end) = Params.AdaptiveForce(:,2:end-1);
        end
    end
    switch dat.TrialType
        case {8}
            switch dat.TrialChoice
                case 'Reference Effort'
                    if dat.ShowSmallEffort
                        Params.AdaptiveReward(Params.AdaptiveReward(:,1) == dat.SmallEffort,2) ...
                            = floor(dat.SmallReward * Params.AdaptiveStepUp);
                    else
                        Params.AdaptiveReward(Params.AdaptiveReward(:,1) == dat.BigEffort,2) ...
                            = floor(dat.BigReward * Params.AdaptiveStepUp);
                    end
                case 'Small Effort'
                    Params.AdaptiveReward(Params.AdaptiveReward(:,1) == dat.SmallEffort,2) ...
                            = ceil(dat.SmallReward * Params.AdaptiveStepDown);
                case 'Big Effort'
                    Params.AdaptiveReward(Params.AdaptiveReward(:,1) == dat.BigEffort,2) ...
                            = ceil(dat.BigReward * Params.AdaptiveStepDown);
            end
        case {9}
            switch dat.TrialChoice
                case 'Reference Effort'
                    if dat.ShowSmallEffort
                        Params.AdaptiveForce(Params.AdaptiveForce(:,1) == dat.SmallReward,2) ...
                            = dat.SmallEffort * Params.AdaptiveStepDown;
                    else
                        Params.AdaptiveForce(Params.AdaptiveForce(:,1) == dat.BigReward,2) ...
                            = dat.BigEffort * Params.AdaptiveStepDown;
                    end
                case 'Small Effort'
                    Params.AdaptiveForce(Params.AdaptiveForce(:,1) == dat.SmallReward,2) ...
                            = dat.SmallEffort * Params.AdaptiveStepUp;
                case 'Big Effort'
                    Params.AdaptiveForce(Params.AdaptiveForce(:,1) == dat.BigReward,2) ...
                            = dat.BigEffort * Params.AdaptiveStepUp;
            end
        for kk = 1:size(Params.AdaptiveForce,1)
            if Params.AdaptiveForce(kk,2) < Params.SmallEffortTarget.EffortVector(1)*Params.MaxForce * (b5.Frame_scale(2)/2)/50
                Params.AdaptiveForce(kk,2) = Params.SmallEffortTarget.EffortVector(1)*Params.MaxForce * (b5.Frame_scale(2)/2)/50;
            end
            if Params.AdaptiveForce(kk,2) > Params.BigEffortTarget.EffortVector(end)*Params.MaxForce * (b5.Frame_scale(2)/2)/50
                Params.AdaptiveForce(kk,2) = Params.BigEffortTarget.EffortVector(end)*Params.MaxForce * (b5.Frame_scale(2)/2)/50;
            end
        end
    end