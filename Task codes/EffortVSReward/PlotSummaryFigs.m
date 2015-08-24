function PlotSummaryFigs(Params, Data)

% Make 'TrialChoiceID' = -1 for No choice
for ii = 1:numel(Data)
    if isempty(Data(ii).TrialChoiceID)
        Data(ii).TrialChoiceID = -1;
    end
end

% get just the sucesses
anyChoice=Data([Data.OutcomeID]==0);


% compute moving average of each choice
if numel(anyChoice)>9
    choseTop=[];
    choseBottom=[];
    x=[];
    topReward=[];
    bottomReward=[];
    
    for i=1:numel(anyChoice)-9
        choseTop(i)=sum([anyChoice(i:i+9).TrialChoiceID]==1)/10;
        choseBottom(i)=sum([anyChoice(i:i+9).TrialChoiceID]==0)/10;
        
        x(i)=i;
        
        topReward(i)=anyChoice(i).Params.BiasingMulti;
        bottomReward(i)= 1 - anyChoice(i).Params.BiasingMulti;
        
    end
    
    
    % plot % choice and multipliers
    figure(20)
    clf
    plot(x,choseTop,'b',x,choseBottom,'r',x,topReward,'c',x,bottomReward,'m')
    ylim([0 1]);
    title(['Cost tracking'])
    legend({'Chose top target','Chose bottom target', 'Top reward multiplier','Bottom reward multiplier'})
    ylabel('Probability of choosing target || Reward multiplier value')
    xlabel('Trial #')
else
    figure(20)
    clf
    text(0.1,0.5,'Not enough successes yet for plotting. Please check later');
end
end