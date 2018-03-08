classdef BarAcuity < PsyCortexExperiments.PsyCortexExperiment
    %Fixation Summary of this class goes here
    %   Detailed explanation goes here
    
    methods
        function this = BarAcuity( )
            this.Name = 'BarAcuity';
        end
    end
    
    methods (Access=protected)
        
        
        %% getParameters
        function parameters = getParameters( this, parameters  ) 
            % --------------------------------------------------------------------
            % -------------------- FIXED PARAMETERS ------------------------------
            % --------------------------------------------------------------------
            
            % fixed parameters that every experiments need to complete
            
            parameters.fixRad       = .125; %dva
            parameters.fixColor     = [255 0 0];
            parameters.fixWindowSize = 4;
            
            %%-- Blocking
            parameters.trialSequence = 'Random';	% Sequential, Random, Random with repetition, ...
            parameters.trialAbortAction = 'Delay';     % Repeat, Delay, Drop
            parameters.trialsPerSession = 1080;
            
            parameters.trialsBeforeCalibration      = 270;
            parameters.trialsBeforeBreak            = 270;
            parameters.trialsBeforeDriftCorrection  = 10000;
            
            %%-- Blocking
            parameters.blockSequence = 'Random';	% Sequential, Random, Random with repetition, ...
            parameters.blocksToRun              = 10;
            parameters.blocks{1}.fromCondition  = 1;
            parameters.blocks{1}.toCondition    = 108;
            parameters.blocks{1}.trialsToRun    = 108;
            
            
            parameters.dlgTextColor = 255*[0 0 0];
            
            path = fileparts(mfilename('fullpath'));
            parameters.dataPath = ['C:\secure\psycortex_data\GaborAcuity'];
            
            
            % --------------------------------------------------------------------
            % -------------------- Optional parameters ---------------------------
            % --------------------------------------------------------------------
            % each experiment can add any information to the parameteres structure.
            % then they can be modified in this file
            
            parameters.eccentricity = 9; %dva
            parameters.spatialFrequency = 2; %dva
            
            %parameters.frameDuration = 1/60; %seconds
            parameters.barColor = [0 0 0];
            parameters.barWidth = 0.1;
            parameters.barHeight = 6;
            parameters.barGap = 0.6;
            parameters.maxDuration = 600;
            parameters.gap = 16;
            
        end
        
        %% getVariables
        function [conditionVars randomVars] = getVariables( this  ) %#ok<MANU>
            conditionVars = {};
            randomVars = {};
            %-- condition variables ---------------------------------------
            i= 0;
            
            i = i+1;
            conditionVars{i}.name   = 'Offset';
            conditionVars{i}.values = [-12 -8 -4 -3 -2 -1 1 2 3 4 8 12]; %pixels
            
            i = i+1;
            conditionVars{i}.name = 'Duration';
            conditionVars{i}.values =  [17 50 67 84 100 150 200 300 600]/1000;%[30000 30000];%milliseconds
            
            randomVars{1}.name = 'Position'; %Left or Right
            randomVars{1}.type = 'List';
            randomVars{1}.values = [-1 1];
            
        end
        
        
        %% runPreTrial
        function [trial ] = runPreTrial( this, variables )
            %-- add stuff here necessary to prepare the trial
            
            %
            
            %-- commit variables to trial struct to have them available
            % during the actual trial
            trial = [];
            
            params = this.ExperimentInfo.Parameters;
            
            graph = this.Graph;
            
            xOrig = graph.pxWidth/2;
            yOrig = graph.pxHeight/2;
            
            
            trial.fixColor = params.fixColor;
            trial.fixRadius = this.Graph.dva2pix( params.fixRad );
            trial.fixRect = CenterRectOnPointd([0 0 trial.fixRadius*2 trial.fixRadius*2], xOrig, yOrig);
            trial.fixWindowSize = this.Graph.dva2pix(params.fixWindowSize);
            trial.fixWindow = CenterRectOnPointd([0 0 (trial.fixWindowSize) (trial.fixWindowSize)], xOrig, yOrig);
            
            trial.duration = variables.Duration;
            
            %Get positions
            dvaX = params.eccentricity;
            trial.x = this.Graph.dva2pix(dvaX)*variables.Position;
            trial.y = this.Graph.dva2pix(params.barGap/2);
            
            trial.widthPixels = this.Graph.dva2pix(params.barWidth);
            trial.heightPixels = this.Graph.dva2pix(params.barHeight);
            %             trial.offset = this.Graph.dva2pix(variables.Offset/3600)*variables.ShiftSide;
            trial.offset = variables.Offset;
            variables.Offset
            
            X = xOrig + trial.x;
            
            trial.widthPixels = this.Graph.dva2pix(params.barWidth);
            
            trial.bars.Top = [X-trial.widthPixels/2, yOrig - trial.y-trial.heightPixels,...
                X+trial.widthPixels/2, yOrig - trial.y];
            trial.bars.Bottom = [X-trial.widthPixels/2+trial.offset, yOrig + trial.y,...
                X+trial.widthPixels/2+trial.offset, yOrig + trial.y + trial.heightPixels];
            
            trial.maxDuration = params.maxDuration;
            trial.gap = params.gap;
            
        end
        
        
        
        %% runTrial
        %-- psycortex will start recording data just before calling this
        %function
        function [trialResult trial] = runTrial( this, variables, trial )
            
            global Enum;
            
            [success, trial] = mainLoop(this, variables, trial);
            
            varargin{1} = 'center';
            varargin{2} = 'center';
            varargin{3} = 'Fixation broken. Hit any key.';
            
            % remove previous key presses           
            
            varargin{1} = 'center';
            varargin{2} = 'center';
            varargin{3} = [.25 .25 .25 ];
            
            if ~success %If fixation broken, finish now with an error
                Screen('TextSize', this.Graph.window, 24);
                
                message = 'Fixation broken. Hit any key.';
                DrawFormattedText( this.Graph.window, message, varargin{:} );
                
                Screen('Flip', this.Graph.window);
                KbWait();
                trialResult = Enum.trialResult.ABORT;
                trial.response = NaN;
                return;
            end
            FlushEvents();
            
            %Show subject screen to select stimuli
            Screen('TextSize', this.Graph.window, 24);            

            message = 'Choose bottom offset direction: left or right';
            DrawFormattedText( this.Graph.window, message, varargin{:} );
            Screen('Flip', this.Graph.window);
            
            [secs, code] = KbStrokeWait();
            
            code = find(code);
            trial.response = [];
            switch code
                case 37
                    trial.response = -1; %left
                case 39
                    trial.response = 1; %right
                otherwise
                    trial.response = [];
            end
            
            if isempty(trial.response) || (trial.response ~= -1 && trial.response ~= 1)
                Screen('TextSize', this.Graph.window, 24);
                
                %                 Screen('DrawText', this.Graph.window, 'Wrong key pressed. Hit any key.', x, y);
                message = 'Wrong key pressed. Hit any key.';
                DrawFormattedText( this.Graph.window, message, varargin{:} );
                Screen('Flip', this.Graph.window);
                KbWait();
                trialResult = Enum.trialResult.ABORT;
                trial.response = NaN;
            else
                trialResult = Enum.trialResult.CORRECT;
            end
            
            if ~this.checkTrialTiming(trial)
                trialResult = Enum.trialResult.ABORT; %%I don't want to give feedback to the subject about the timing problem
                trial.response = NaN;
            end
            
        end
        
        %% runPostTrial
        function [trialOutput ] = runPostTrial( this, trial ) 
            trialOutput = trial;
            FlushEvents(); %%Sometimes it chokes at subjects response, flush the events so it does not start the trial inmediately.
            %clear textures from memory
            
        end
        
    end
    
    methods (Access = private)
        
        function [success trial] = mainLoop( this, variables, trial )
            
            
            trial.flips = [];
            
            
            Screen('FillOval', this.Graph.window, trial.fixColor, trial.fixRect);
            Screen('Flip', this.Graph.window);
            while ~this.checkFixation(trial)
                WaitSecs(0.05);
            end
            WaitSecs(0.2)
            
            success = 1;
            Screen('FillOval', this.Graph.window, trial.fixColor, trial.fixRect);
            trial.tStart = Screen('Flip', this.Graph.window);
            if (~isempty( this.EyeTracker ) )
                this.EyeTracker.SendMessage( 'START_LOOP: t=%d', round(trial.tStart*1000) );
            end
            WaitSecs(0.1 + rand*0.2);
            
            timeFirstFlip = -1;
            timeLastFlip = -1;
            numberOfFlips = 2*ceil(trial.maxDuration/(trial.duration*1000 + trial.gap));
            t = nan(numberOfFlips, 1);
            n = 0;
            
            while timeLastFlip < timeFirstFlip + trial.maxDuration
                
                
                n = n + 1;
                Screen('FillOval', this.Graph.window, trial.fixColor, trial.fixRect);
                Screen('FillRect', this.Graph.window, [0 0 0], trial.bars.Top);
                Screen('FillRect', this.Graph.window, [0 0 0], trial.bars.Bottom);
                t(n) = Screen('Flip', this.Graph.window);
                
                
                if n == 1
                    timeFirstFlip = t(1)*1000
                end
                
                while GetSecs*1000 < t(n) + trial.duration-0.02;
                    if ~this.checkFixation(trial)
                        if (~isempty( this.EyeTracker ) )
                            this.EyeTracker.SendMessage( 'END_LOOP: t=%d', round(trial.tEnd*1000) );
                        end
                        success = 0;
                        return;
                    end
                end
                
                n = n + 1;
                Screen('FillOval', this.Graph.window, trial.fixColor, trial.fixRect);
                t(n) = Screen('Flip', this.Graph.window, t(n-1)+trial.duration-0.01);
                timeLastFlip = t(n)*1000;
                
            end
            
            WaitSecs(0.3);
            
            
            if (~isempty( this.EyeTracker ) )
                this.EyeTracker.SendMessage( 'END_LOOP: t=%d', round(trial.tEnd*1000) );
            end
            
            trial.t = t;
        end
        
        function goodTiming = checkTrialTiming(this, trial) 
            
            df = diff(trial.t);
            goodTiming = 1;
            tol = 5e-3;
            if numel(df) > 1
                goodTiming = all(abs(df(1:2:end)-trial.duration) < tol) & all(abs(df(2:2:end)-trial.gap) < tol);
            else
                goodTiming = abs(df-trial.duration) < tol;
            end
        end
        function fixating = checkFixation(this, trial)
            
            if isempty(this.EyeTracker)%For testing purposes
                fixating = 1;
                return
            end
            
            [x y] = this.EyeTracker.GetCurrentPosition();
            if IsInRect(x,y,trial.fixWindow)
                fixating = 1;
            else
                fixating = 0;
            end
            
        end
        
    end
    
end
