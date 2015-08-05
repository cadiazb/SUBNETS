function PlotSummaryFigs(Params, Data)
    try
        %% Make 'TrialChoiceID' = -1 for No choice
        for ii = 1:numel(Data)
            if isempty(Data(ii).TrialChoiceID)
                Data(ii).TrialChoiceID = -1;
            end
        end

        %% get just the sucesses
        anyChoice=Data([Data.OutcomeID]==0);

        %% moving average of each choice

        choseTop=[];
        choseBottom=[];
        x=[];

        for i=1:numel(anyChoice)-19
            choseTop(i)=sum([anyChoice(i:i+19).TrialChoiceID]==1)/20;
            choseBottom(i)=sum([anyChoice(i:i+19).TrialChoiceID]==0)/20;
            x(i)=i;
        end
        
        %% Plot
        figure(20)
        clf
        plot(x,choseTop,x,choseBottom)
        title(['Cost tracking'])
        legend({'Chose top target','Chose bottom target'})
        ylabel('Probability of choosing target')
        xlabel('Trial #')
    catch
        figure(20)
        clf
        text(0.1,0.5,'Not enough successes yet for plotting. Please check later');
    end
end