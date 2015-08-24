function [Params, dat, b5] = rewardEffortTracking(Params, dat, b5, controlWindow)

global DEBUG
global SolenoidEnable QUIT_FLAG Solenoid_open;

% FOR DRAWING OBJECTS
DRAW_NONE     = 0;
DRAW_SUBJECT  = 1;
DRAW_OPERATOR = 2;
DRAW_BOTH     = 3;

%% Generate a StartTarget position
% b5.StartTarget_pos = Params.WsCenter - [0, b5.Frame_scale(2)/2];
b5.StartTarget_pos = Params.WsCenter - [0, 0];

%% Draw Probe effort from vector
% Draw reward from 'Training vector' or from Adaptive Vector
% dat.ProbeEffort         = controlWindow.GetDownTarget_pos() / b5.Frame_scale(2);
dat.ProbeEffort         = DrawFromVec(Params.DownEffort);




%% Generate DownTarget position
b5.DownTarget_pos 		= b5.StartTarget_pos + ...
                                [0,Params.DownEffort * b5.Frame_scale(2)] ...
                                + [0,-b5.DownTarget_scale(2)/2];
                            
b5.UpTarget_pos 		= b5.StartTarget_pos + ...
                                [0,Params.UpEffort * b5.Frame_scale(2)] ...
                                + [0,b5.UpTarget_scale(2)/2];                            
%% Generate the amounts of reward
dat.ProbeReward = DrawFromVec(Params.RewardsVector);
% dat.ProbeReward = 2000 * controlWindow.GetEarnedReward(); %[ms]
%% Misc stuff
dat.OutcomeID 	= 0;
dat.OutcomeStr 	= 'Success';

%% Hide all screen objects
b5.StartTarget_draw             = DRAW_NONE;
b5.Frame_draw                   = DRAW_NONE;
b5.BarOutline_draw              = DRAW_NONE;
b5.Cursor_draw                  = DRAW_NONE;
b5.DownTarget_draw              = DRAW_NONE;
b5.UpTarget_draw                = DRAW_NONE;


b5 = bmi5_mmap(b5);

%% 1. ACQUIRE START TARGET
b5.StartTarget_draw = DRAW_BOTH;
b5.Cursor_draw      = DRAW_BOTH;
b5 = bmi5_mmap(b5);

done   = false;
gotPos = false;
b5.BarOutline_draw              = DRAW_NONE;

t_start = b5.time_o;
while ~done
    
    %pos = b5.Cursor_pos;
    [Params, dat, b5] = UpdateCursorOnLine(Params, dat, b5); % syncs b5 twice
    pos = b5.Cursor_pos;
    dat.FinalCursorPos = [0,pos(2)];
    
    % Check for acquisition of start target
    posOk = TrialInBox(pos, b5.Cursor_scale, b5.StartTarget_pos, Params.StartTarget.Win);
    
    
    if posOk
        if ~gotPos
            gotPos = true;
            starthold = b5.time_o;
        end
        
        %Show features on screen when MP lets go
        b5.StartTarget_draw             = DRAW_BOTH;
        b5.BarOutline_draw              = DRAW_BOTH;
        b5.xSensitivity_draw            = DRAW_BOTH;
        b5.ySensitivity_draw            = DRAW_BOTH;
        
        if (b5.time_o - starthold) > Params.StartTarget.Hold
            done = true;   % Reach to start target OK
        end
    end

	% Once start target is acquired, it must remain acquired
    if ~posOk
        if gotPos
            gotPos = false;
            done            = true;
            dat.OutcomeID   = 2;
            dat.OutcomeStr	= 'cancel @ start hold';
            b5 = b5ObjectsOff(b5);
        else
            if (b5.time_o - t_start) > Params.TimeoutReachStartTarget
                done            = true;
                dat.OutcomeID   = 1;
                dat.OutcomeStr	= 'cancel @ start';
            end
        end
    end
    
    % update hand
    [Params, dat, b5] = UpdateCursorOnLine(Params, dat, b5); % syncs b5 twice

end

%% 2. CHECK FOR Y-AXIS MOVEMENT ON LOAD CELL
if ~dat.OutcomeID
    b5.BarOutline_draw          = DRAW_BOTH;
    b5.Cursor_draw              = DRAW_BOTH;
    b5.StartTarget_draw             = DRAW_NONE;
    b5.xSensitivity_draw       = DRAW_BOTH;
    b5.ySensitivity_draw       = DRAW_BOTH;
%     b5.SolenoidOpen_draw       = DRAW_NONE;
    b5.UpTarget_draw         = DRAW_BOTH;
    b5.DownTarget_draw      = DRAW_BOTH;
    

	done            = false;
    dat.FinalCursorPos = b5.StartTarget_pos;
    tmpJuiceState = 'off';

    
	t_start = b5.time_o;
%     [Params.StartTarget.Win(1), Params.StartTarget.Win(2)] = controlWindow.GetSensitivity();
	while ~done
        drawnow;
%         [Params.StartTarget.Win(1), Params.StartTarget.Win(2)] = controlWindow.GetSensitivity();
        [Params, dat, b5] = UpdateCursorOnLine(Params, dat, b5); % syncs b5 twice
        pos = b5.Cursor_pos;
        dat.FinalCursorPos = [0,pos(2)];
        
        % Update sensitivites rectangle
        b5.ySensitivity_scale = [b5.BarOutline_scale(1),...
                2*Params.StartTarget.Win(2)];
        b5.ySensitivity_pos       = Params.WsCenter - [0, 0];
        
        b5.xSensitivity_scale = [2*Params.StartTarget.Win(1),... 
                b5.xSensitivity_scale(2)];
        b5.xSensitivity_pos(1) = Params.WsCenter(1);       
        
        
        b5 = bmi5_mmap(b5);
        
		% Check for acquisition of a reach target
        posOk = TrialInBox(pos,b5.Cursor_scale,b5.StartTarget_pos,Params.StartTarget.Win);
        posUpOk = TrialInBox(pos,b5.Cursor_scale,b5.UpTarget_pos,b5.UpTarget_scale/2);
        posDownOk = TrialInBox(pos,b5.Cursor_scale,b5.DownTarget_pos,b5.DownTarget_scale/2);

%         if ~posOk
%             if (abs(pos(1) - b5.StartTarget_pos(1)) > Params.StartTarget.Win(1)) %|| ((pos(2) - b5.StartTarget_pos(2)) < 0)
%                 posOk = ~posOk;
%             end     
%         end
          
        if ~posOk && isempty(dat.ReactionTime)
            dat.ReactionTime = b5.time_o - t_start;
        end
        
        if ~isempty(dat.ReactionTime) && (posDownOk)   && ...
                 (abs(pos(1) - b5.StartTarget_pos(1)) < Params.StartTarget.Win(1))
            dat.TrialChoice = 'Down';
            dat.TrialChoiceID = 0; %0 means reached down
            done = true;
            dat.MovementTime = b5.time_o - t_start - dat.ReactionTime;
            dat.OutcomeID 	= 0;
            dat.OutcomeStr 	= 'Success';
        end
        
        if ~isempty(dat.ReactionTime) && (posUpOk) && ...
                (abs(pos(1) - b5.StartTarget_pos(1)) < Params.StartTarget.Win(1))
            done = true;
            dat.MovementTime = b5.time_o - t_start - dat.ReactionTime;
            dat.TrialChoice = 'Up';
            dat.TrialChoiceID = 1; %1 means reached up
            dat.OutcomeID 	= 0;
            dat.OutcomeStr 	= 'Succes';
        end

		% check for TIMEOUT
        if ~isempty(dat.ReactionTime) && ~done
            if (b5.time_o - t_start - dat.ReactionTime) > Params.TimeoutReachTarget
%                 dat.MovementTime = b5.time_o - t_start - dat.ReactionTime;
%                 dat.TrialChoice = '';
%                 done            = true;
%                 dat.OutcomeID 	= 4;
%                 dat.OutcomeStr 	= 'cancel @ reach movement timeout';
            end
        end
        
%         if isempty(dat.ReactionTime)
            if QUIT_FLAG || ((b5.time_o - t_start) > Params.ReactionTimeDelay)
                dat.ReactionTime = b5.time_o - t_start;
                dat.TrialChoice = '';
                dat.MovementTime = NaN;
                done            = true;
                dat.OutcomeID 	= 4;
                dat.OutcomeStr 	= 'Cancel @ reaction';
            end

        if ~SolenoidEnable
            tmpJuiceState = 'off';
        end


        if Solenoid_open
            b5 = LJJuicer(Params, b5, 'on');
        elseif strcmp(tmpJuiceState, 'off')
            b5 = LJJuicer(Params, b5, tmpJuiceState);
        end
	end
end

%% Trial outcome and variable adaptation

if dat.OutcomeID == 0 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    if strcmp(dat.TrialChoice, 'Up')
        dat.ActualReward = dat.ProbeReward*Params.BiasingMulti;
    else
        dat.ActualReward = dat.ProbeReward*(1.0-Params.BiasingMulti);
    end
    
    fprintf('Choice\t\t%s \n',dat.TrialChoice);
    fprintf('Trial reward\t\t%.0f [ms]\n',dat.ActualReward);
    
    % Give juice reward
%     [Params, b5] = blinkShape(Params, b5, {'FillingEffort', 'DownTarget', 'UpTarget'}, [12 12 12], [0.75 0.75 0.75]);
    b5 = LJJuicer(Params, b5, 'on');
    [Params, dat, b5] = UpdateCursorOnLine(Params, dat, b5); %b5 = bmi5_mmap(b5);
    juiceStart = b5.time_o;
    while (b5.time_o - juiceStart) < (dat.ActualReward / 1000)
        [Params, dat, b5] = UpdateCursorOnLine(Params, dat, b5); %b5 = bmi5_mmap(b5);
    end
    if ~Solenoid_open
        b5 = LJJuicer(Params, b5, 'off');
    end
    dat.JuiceON = juiceStart;
    dat.JuiceOFF = b5.time_o;
    controlWindow.message(['Last reward ' datestr(now)]);
    
%     % Turn objects on screen off
    b5 = b5ObjectsOff(b5);
    b5 = bmi5_mmap(b5);
%     % Pause after reward
%     startPause = b5.time_o;
%     %if dat.FinalCursorPos(2) < b5.UpTarget_pos(2)
%         while (b5.time_o - startPause) < (Params.InterTrialDelay)
%             [Params, dat, b5] = UpdateCursorOnLine(Params, dat, b5); %b5 = bmi5_mmap(b5);
%         end
%     %end
    


else
    %Clean screen
    % Turn objects on screen off
    b5 = b5ObjectsOff(b5);
    b5 = bmi5_mmap(b5);
    % Pause after fail reach
    if dat.OutcomeID == 5 %Wrong choice
        startPause = b5.time_o;
        while (b5.time_o - startPause) < (Params.WrongChoiceDelay)
            [Params, dat, b5] = UpdateCursorOnLine(Params, dat, b5); %b5 = bmi5_mmap(b5);
        end
    end
    
    if dat.OutcomeID == 4 %Cancel @ reach
        startPause = b5.time_o;
        while (b5.time_o - startPause) < (Params.InterTrialDelay)
            [Params, dat, b5] = UpdateCursorOnLine(Params, dat, b5); %b5 = bmi5_mmap(b5);
        end
    end
    
    if (dat.OutcomeID == 1) || (dat.OutcomeID == 2) %Cancel @ start || Cancel @ start hold
        startPause = b5.time_o;
        while (b5.time_o - startPause) < (Params.InterTrialDelay)
            [Params, dat, b5] = UpdateCursorOnLine(Params, dat, b5); %b5 = bmi5_mmap(b5);
        end
    end


end

b5 = bmi5_mmap(b5);

%Clean screen
% b5.StartTarget_draw             = DRAW_NONE;
% b5.Frame_draw                   = DRAW_NONE;
% b5.BarOutline_draw              = DRAW_NONE;
b5.Cursor_draw                  = DRAW_NONE;
b5.DownTarget_draw             = DRAW_NONE;
b5.UpTarget_draw             = DRAW_NONE;

%%% XXX TODO: NEED WAY TO LOG (MORE) INTERESTING TRIAL EVENTS

end