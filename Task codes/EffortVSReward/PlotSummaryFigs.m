function PlotSummaryFigs(Params, Data)

% % Make 'TrialChoiceID' = -1 for No choice
% for ii = 1:numel(Data)
%     if isempty(Data(ii).TrialChoiceID)
%         Data(ii).TrialChoiceID = -1;
%     end
% end

% get just the sucesses
anyChoice=Data([Data.OutcomeID]==0);


% compute moving average of each choice
if numel(anyChoice)>9
    choseTop=[];
    choseBottom=[];
    x=[];
    UpMulti=[];
    DownMulti=[];
    
    for i=10:numel(anyChoice)
        choseTop(i-9)=sum([anyChoice(i-9:i).TrialChoiceID]==1)/10;
        choseBottom(i-9)=1.0-choseTop(i-9);
        
        x(i-9)=i;
        
        UpMulti(i-9)=anyChoice(i).Params.BiasingMulti;
        DownMulti(i-9)= 1 - anyChoice(i).Params.BiasingMulti;
        
    end
    
    
    % plot % choice and multipliers
    figure(20)
    clf  
    if Data(1).TrialType==5
        plot(x,choseTop,'b',x,choseBottom,'r',x,UpMulti,'c',x,DownMulti,'m')
        title(['Reward tracking'])
        legend({'Chose top target','Chose bottom target', 'Top reward multiplier','Bottom reward multiplier'})
        ylabel('Proportion of target choices || Reward multiplier value')
    elseif Data(1).TrialType==6
        plot(x,choseTop,'b',x,choseBottom,'r',x,UpMulti,'c',x,DownMulti,'m')
        title(['Effort tracking'])
        legend({'Chose top target','Chose bottom target', 'Top effort multiplier','Bottom effort multiplier'})
        ylabel('Proportion of target choices || Effort multiplier value')
    else
        plot(x,choseTop,'b',x,choseBottom,'r')
        title(['Proportion of Up vs. Down Target Choices'])
        legend({'Chose top target','Chose bottom target'})
        ylabel('Proportion of target choices')
        
    end
    ylim([0 1]);
    xlabel('Trial #')
    
end
end