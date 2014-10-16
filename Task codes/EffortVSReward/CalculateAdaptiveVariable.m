function [Params, dat] = CalculateAdaptiveVariable(Params, dat, b5)
    if Params.StepSizeAdaptive
        adaptStep = false;
        switch dat.TrialType
            case {1}
                Params.AdaptiveReward(:,3:end) = Params.AdaptiveReward(:,2:end-1);
            case {2}
                Params.AdaptiveForce(:,3:end) = Params.AdaptiveForce(:,2:end-1);
        end
    end
    switch dat.TrialType
        case {1}
            switch dat.TrialChoice
                case {'Reference Effort', 'Pass'}
                    Params.AdaptiveReward(Params.AdaptiveReward(:,1) == dat.ProbeEffort,2) ...
                        = ceil(dat.ProbeReward * Params.AdaptiveStepUp);

                case 'Probe Effort'
                    Params.AdaptiveReward(Params.AdaptiveReward(:,1) == dat.ProbeEffort,2) ...
                            = floor(dat.ProbeReward * Params.AdaptiveStepDown);
            end
        case {2}
            switch dat.TrialChoice
                case 'Reference Effort'
                    Params.AdaptiveForce(Params.AdaptiveForce(:,1) == dat.ProbeReward,2) ...
                        = dat.ProbeEffort * Params.AdaptiveStepDown;
                case 'Probe Effort'
                    Params.AdaptiveForce(Params.AdaptiveForce(:,1) == dat.ProbeReward,2) ...
                            = dat.ProbeEffort * Params.AdaptiveStepUp;
            end
        for kk = 1:size(Params.AdaptiveForce,1)
            if Params.AdaptiveForce(kk,2) < Params.ProbeEffortTarget.EffortVector(1)*Params.MaxForce * (b5.Frame_scale(2)/2)/50
                Params.AdaptiveForce(kk,2) = Params.ProbeEffortTarget.EffortVector(1)*Params.MaxForce * (b5.Frame_scale(2)/2)/50;
            end
            if Params.AdaptiveForce(kk,2) > Params.ProbeEffortTarget.EffortVector(end)*Params.MaxForce * (b5.Frame_scale(2)/2)/50
                Params.AdaptiveForce(kk,2) = Params.ProbeEffortTarget.EffortVector(end)*Params.MaxForce * (b5.Frame_scale(2)/2)/50;
            end
        end
    end