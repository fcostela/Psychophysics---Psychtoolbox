classdef AgingSnakes < PsyCortexExperiments.PsyCortexExperiment
    %MiniExplore Summary of this class goes here
    %   Detailed explanation goes here
    
    
    methods
        function this = AgingSnakes( )
            this.Name = 'AgingSnakes';
        end
    end
    

    
     methods (Access=protected)     
        %% getParameters
        function parameters = getParameters( this, parameters  )
            % --------------------------------------------------------------------
            % -------------------- FIXED PARAMETERS ------------------------------
            % --------------------------------------------------------------------
              parameters.fixRad       = .125;
            parameters.fixColor     = [255 0 0];
            
            parameters.trialsBeforeCalibration      = 4;
            parameters.trialsBeforeDriftCorrection  = 10000;
            parameters.trialsBeforeBreak            = 4;
            
            %%-- Blocking
            parameters.trialSequence = 'Random';	% Sequential, Random, Random with repetition, ...
            parameters.trialAbortAction = 'Delay';     % Repeat, Delay, Drop
            parameters.trialsPerSession = 8; 
            path = fileparts(mfilename('fullpath'));
            parameters.dataPath = 'C:\secure\psycortex_data\AgingSnakes';
            parameters.folder = [path '\stim\'];
            % --------------------------------------------------------------------
            % -------------------- Optional parameters ---------------------------
            % --------------------------------------------------------------------
            % each experiment can add any information to the parameteres extructure.
            % then they can be modified in this file
            parameters.trialDuration = 10;
            parameters.rotatingSpeed = .01; %cycles/sec
            
        end
        
        %% getVariables
        function [conditionVars randomVars] = getVariables( this  )
            
            conditionVars = {};
            randomVars = {};            
            %-- condition variables ---------------------------------------
            i= 0;            
            i = i+1;
            conditionVars{i}.name   = 'Task';
            conditionVars{i}.values   = {'Fixation' 'Control' 'Freeviewing'};            
            i = i+1;
            conditionVars{i}.name   = 'Color';
            conditionVars{i}.values   = {'BW' 'Original'};
            i = i+1;
            conditionVars{i}.name   = 'Direction_of_motion';
            conditionVars{i}.values = { 'Clockwise' 'Counterclockwise'};            
            i = i+1;
            conditionVars{i}.name   = 'Snake_Size';
            conditionVars{i}.values = [8];            
            i = i+1;
            conditionVars{i}.name   = 'Eccentricity';
            conditionVars{i}.values = [9];
            i = i+1;
            conditionVars{i}.name   = 'Angle';
            conditionVars{i}.values = [0:30:165];
            
        end
        
        %% runPreTrial
        function [trial ] = runPreTrial( this, variables )
             global Enum;
            graph = this.Graph;
            trialResult = Enum.trialResult.CORRECT;
            
            disp(variables.Task);
            switch(variables.Task)
                case 'Fixation'
                     trial.realMotion = 0;
                    if strcmp(variables.Color,'BW')
                        trial.image = [this.ExperimentInfo.Parameters.folder 'single_snake_illusory_bw.bmp'];
                    else
                        trial.image = [this.ExperimentInfo.Parameters.folder 'single_snake_illusory.bmp'];
                    end
                case 'Freeviewing'
                     trial.realMotion = 0;
                    if strcmp(variables.Color,'BW')
                        trial.image = [this.ExperimentInfo.Parameters.folder 'BW_Snakes.bmp'];
                    else
                        trial.image = [this.ExperimentInfo.Parameters.folder 'Snakes.bmp'];
                    end
                case 'Control'
                     trial.realMotion = 1;
                    if strcmp(variables.Color,'BW')
                        trial.image = [this.ExperimentInfo.Parameters.folder 'single_snake_non_illusory_bw.bmp'];
                    else
                        trial.image = [this.ExperimentInfo.Parameters.folder 'single_snake_non_illusory.bmp'];
                    end
            end            
            
            trial.buttonTimes(1) = 0; % save times of button press and release
            trial.movingTimes(1) = 0; % save times of movement changing
            
          
            I = imread( trial.image );
            
             % Query duration of monitor refresh interval:
            ifi=Screen('GetFlipInterval', graph.window);
            
            waitframes = 1;
            trial.waitduration = waitframes * ifi;
            
            
            %-- direction of illusory motion, invert stimulus if it is counter clock wise
            switch(variables.Direction_of_motion)
                case 'Clockwise'
                    I = I(:,end:-1:1,:);
                    trial.turnPerFrame = this.ExperimentInfo.Parameters.rotatingSpeed * 360 * trial.waitduration;
                    trial.turnPerSecond = this.ExperimentInfo.Parameters.rotatingSpeed * 360;
                case 'Counterclockwise'
                    I = I;
                    trial.turnPerFrame = -this.ExperimentInfo.Parameters.rotatingSpeed * 360 * trial.waitduration;
                    trial.turnPerSecond = -this.ExperimentInfo.Parameters.rotatingSpeed * 360;
            end
            
            switch(variables.Task)
                case {'Freeviewing'}
                    dlgResult = this.Graph.DlgHitKey( 'Please explore the image and press the button as soon as you perceive the motion.\n Press any key to continue', [], []);
                otherwise
                    dlgResult = this.Graph.DlgHitKey( 'Please fixate at the red point and press the button as soon as you perceive the motion.\n Press any key to continue', [], []);
            end            
           
%             -- make texture                        
            trial.snakeTexture = Screen('MakeTexture', graph.window, I, 1);            
            
            %-- convert to degrees of visual angle
            trial.snakeSize           = dva2pix( graph, variables.Snake_Size );
            trial.snakeEccentricity   = dva2pix( graph, variables.Eccentricity );
            trial.fixRadio = dva2pix( graph, this.ExperimentInfo.Parameters.fixRad );
            %
            trial.rotatingSpeed       = this.ExperimentInfo.Parameters.rotatingSpeed; % cycles per second            
            trial.displayAngle        = variables.Angle;
            buttonTimesToUse = [];
            
            t = 0;
            if ( trial.realMotion )
                % find button presses from a previous trial
                trial.buttonTimesToUse = [];
                disp('//////////////////////////////////////////////////////////////////////////////////////////////////////////////////');
                disp(length(this.CurrentRun));
                
                for i=1:1:length(this.CurrentRun)
                    
                    for j=1:1:length(this.CurrentRun(i).Data)
                        
                        if (isfield(this.CurrentRun(i).Data{j}.trialOutput,'buttonTimes') && ~this.CurrentRun(i).Data{j}.trialOutput.realMotion)    
                            
                            t=t+1;
                            buttonTimesToUse{t} = this.CurrentRun(i).Data{j}.trialOutput.buttonTimes;                            
                            
                        end
                    end
                end
                
                disp(buttonTimesToUse);
                aa = randperm(t);              
                if (isempty(aa))
                    trial.trialResult = Enum.trialResult.SOFT_ABORT;
                    disp('ABORTING because there are no button times');                   
                    return;
                else
                    trial.buttonTimesToUse = buttonTimesToUse{aa(1)};
                end
            end
                            
            
            % Translate requested speed of rotation (in cycles per second)
            % into a turn value in "degrees per frame", assuming given
            % waitduration: This is the amount of degrees to turn the snake
            % each redraw:
            
            disp(trial.turnPerFrame);
            
            trial.fliptimes = zeros(ceil(this.ExperimentInfo.Parameters.trialDuration/trial.waitduration),1);
            size(trial.fliptimes);
        end
        
        %% runTrial
        %-- psycortex will start recording data just before calling this
        %function
        function [trialResult trial] = runTrial( this, variables, trial )
            
             global Enum;
             disp('starting...');
             graph = this.Graph;
            trialResult = Enum.trialResult.CORRECT;
           
            buttonPressed   = 0;
            nowMoving       = 1;
            
            
            lastFlipTime        = Screen('Flip', graph.window);
            secondsRemaining    = this.ExperimentInfo.Parameters.trialDuration;
            secondsElapsed      = 0;
            framesMoving        = 0;
            
            startLoopTime = lastFlipTime;
            
            if (~isempty( this.EyeTracker ) )                
                this.EyeTracker.SendMessage( 'START_LOOP: t=%d', round(startLoopTime*1000) );        
            end
            
            if ( trial.realMotion)
                    disp('realmotion');
            end
            
            while secondsRemaining > 0
                
                secondsElapsed      = GetSecs - startLoopTime;
                secondsRemaining    = this.ExperimentInfo.Parameters.trialDuration - secondsElapsed;
                
                % -----------------------------------------------------------------
                % --- Drawing of stimulus -----------------------------------------
                % -----------------------------------------------------------------
                
                %-- Find the center of the screen
                [mx, my] = RectCenter(graph.wRect);
                
                %-- Center and rectangles for the snakes
                snakeRect = [0 0 trial.snakeSize trial.snakeSize];
                
                %-- calculate the center of the snakes given the angle
                x1 = mx + cos(trial.displayAngle/180*pi)*trial.snakeEccentricity;
                x2 = mx - cos(trial.displayAngle/180*pi)*trial.snakeEccentricity;
                y1 = my + sin(trial.displayAngle/180*pi)*trial.snakeEccentricity;
                y2 = my - sin(trial.displayAngle/180*pi)*trial.snakeEccentricity;
                
                snakeRect1 = CenterRectOnPointd( snakeRect, x1, y1 );
                snakeRect2 = CenterRectOnPointd( snakeRect, x2, y2 );
                
                %-- calculate the snake rotation in case it is moving
                if ( trial.realMotion)
                  
                    wasMoving = nowMoving;                    
                     
                     nowMoving = ~mod(sum(trial.buttonTimesToUse<secondsElapsed)+1,2);
                    if ( nowMoving )
                        framesMoving = framesMoving + 1;
                    end
                   % disp(trial.turnPerFrame);                    
                    turnangle = mod(framesMoving*trial.turnPerFrame,360);
                else
                     turnangle = [];
                end
                
                %-- Draw Snakes
                switch(variables.Task)
                    
                    case 'Freeviewing'
                        %-- Center and rectangles for the fixation spot
                        
                        imageRect = Screen('Rect', trial.snakeTexture );
                        imageRect = CenterRect(imageRect, graph.wRect);
                        Screen('DrawTexture', graph.window, trial.snakeTexture, [], imageRect, []);
                        
                    otherwise
                        
                        fixRect = [0 0 trial.fixRadio*2 trial.fixRadio*2];
                        fixRect = CenterRectOnPointd( fixRect, mx, my );
                        %-- Draw Fixation spot
                        Screen('FillOval', graph.window, this.ExperimentInfo.Parameters.fixColor, fixRect);
                        Screen('DrawTexture', graph.window, trial.snakeTexture, [], snakeRect1, turnangle);
                        Screen('DrawTexture', graph.window, trial.snakeTexture, [], snakeRect2, turnangle);
                        
                end
                
                    
               
                
                % -----------------------------------------------------------------
                % --- END Drawing of stimulus -------------------------------------
                % -----------------------------------------------------------------
                
                
                
                
                % -----------------------------------------------------------------
                % DEBUG
                % -----------------------------------------------------------------
                if (0)
                    % TODO: it would be nice to have some call back system here
                    Screen('DrawText', graph.window, sprintf('%i seconds remaining...', round(secondsRemaining)), 20, 50, graph.black);
                    currentline = 50 + 25;
                    vNames = fieldnames(variables);
                    for iVar = 1:length(vNames)
                        if ( ischar(variables.(vNames{iVar})) )
                            s = sprintf( '%s = %s',vNames{iVar},variables.(vNames{iVar}) );
                        else
                            s = sprintf( '%s = %s',vNames{iVar},num2str(variables.(vNames{iVar})) );
                        end
                        Screen('DrawText', graph.window, s, 20, currentline, graph.black);
                        
                        currentline = currentline + 25;
                    end
                    
                      Screen('DrawText', graph.window, num2str(this.CurrentRun.futureConditions(1,1)), 20, currentline, graph.black);
                      
                    if ( ~isempty( this.EyeTracker ) )
                        draweye( this.EyeTracker.eyelink, graph);
                    else
                        draweye( [], graph);
                    end
                end
                % -----------------------------------------------------------------
                % END DEBUG
                % -----------------------------------------------------------------
                
                
                
                % -----------------------------------------------------------------
                % -- Flip buffers to refresh screen -------------------------------
                % -----------------------------------------------------------------
                lastFlipTime            = Screen('Flip', graph.window);     
%                 trial.fliptimes(sum(trial.fliptimes>0)+1)  = lastFlipTime;
                % -----------------------------------------------------------------
                
                
                
                
                % -----------------------------------------------------------------
                % --- Collecting responses  ---------------------------------------
                % -----------------------------------------------------------------
                
                % -- Check button pressed or released
                if ( ~isempty(this.EyeTracker) )
                    % if eyelink is active we use the eyelink game pad
                    result = Eyelink('ButtonStates');
                    if ~( buttonPressed == (bitand(result, 64) > 0) )
                        trial.buttonTimes(end+1) = lastFlipTime - startLoopTime;
                        buttonPressed = (bitand(result, 64) > 0);
                        if (~isempty( this.EyeTracker ) )
                            this.EyeTracker.SendMessage( 'BUTTON: pressed=%d t=%d', 1*buttonPressed, round(lastFlipTime*1000));
                         
                        end
                    end
                else
                    % if eyelink is not active we use the SPACE key
                    [keyIsDown,secs,keyCode] = KbCheck;
                    
                    if ~( buttonPressed == keyCode(Enum.keys.SPACE) )
                        
                        trial.buttonTimes(end+1) = lastFlipTime - startLoopTime;                        
                        buttonPressed = keyCode(Enum.keys.SPACE);                        
                        
                    else
                        
                        if keyCode(Enum.keys.ESCAPE)
                            throw(MException('PSYCORTEX:USERQUIT', ''));
                        end
                    end
                end
                
                
                %-- Check if in this frame there was a movement change
                if ( trial.realMotion)
                    if ( wasMoving ~= nowMoving )
                        trial.movingTimes(end+1) = lastFlipTime - startLoopTime;
                        if (~isempty( this.EyeTracker ) )
                             this.EyeTracker.SendMessage( 'MOVEMENT: moving=%d t=%d', 1*nowMoving, round(lastFlipTime*1000));
                         
                        end
                    end
                end
                % -----------------------------------------------------------------
                % --- END Collecting responses  -----------------------------------
                % -----------------------------------------------------------------
                
                
            end % main loop
        end
        
        %% runPostTrial
        function [trialOutput ] = runPostTrial( this, trial )
             global Enum;
%             
%             output = [];
%             output.trialEvents = [];
            
            
            
            %% TRIAL
             
            %-- Prepare output
            trialOutput.buttonTimes = trial.buttonTimes;
            trialOutput.realMotion = trial.realMotion;
%             trialOutput.fliptimes = trial.fliptimes;
            
            
        end
     
     end
end


