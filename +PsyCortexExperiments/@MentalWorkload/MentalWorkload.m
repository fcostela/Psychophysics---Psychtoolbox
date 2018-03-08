classdef MentalWorkload < PsyCortexExperiments.PsyCortexExperiment
    %MentalWorkload Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        
        
    end
    
    methods
        
        function this = MentalWorkload( )
            this.Name = 'MentalWorkload';
            this.Config.HitKeyBeforeTrial = 0;
        end
        
        function this = changeEyeTrackerFiles(this, newFileName, newCode, newEyeTrackerFileName)%newEyeTrackerFiles, newFileName)
            
                 this.EyeTrackerFiles{1}= newEyeTrackerFileName;
                 this.EyeTracker.edfFileName = newEyeTrackerFileName;
            this.Filename = newFileName;            
            this.SubjectCode = newCode;
        end
        
    end
    
    methods (Access=protected)
        
        %% getParameters
        function parameters = getParameters( this, parameters  )
            % --------------------------------------------------------------------
            %                           FIXED PARAMETERS
            % --------------------------------------------------------------------
            
            %%-- fixed parameters that every experiments need to complete            
            parameters.fixColor                     = [0 0 0];
            
            parameters.trialsBeforeCalibration      = 20;
            parameters.trialsBeforeDriftCorrection  = 5000;
            parameters.trialsBeforeBreak            = 3;            
            
            parameters.trialSequence    = 'Sequential';	% Sequential, Random, Random with repetition, ...
            parameters.trialAbortAction = 'Repeat';     % Repeat, Delay, Drop            
            
            parameters.trialsPerSession = 18;            
            %Durations            
            parameters.trialDuration = 30; 
                        
            parameters.calibDriftBackgroundColor = 'black'; %can only be 'black' or 'white'
            parameters.dlgTextColor = 255*[1 1 1];
            parameters.dlgBackgroundScreenColor = 255*[0.5 0.5 0.5];            
            parameters.backgroundColor = 255*[0.5 0.5 0.5];
                        
            %instructions            
            parameters.instructionControl = 'Look at the point';
            parameters.instructionEasy = 'Look at the point and count FORWARD in steps of 2 starting at';
            parameters.instructionDifficult = 'Look at the point and count BACKWARDS in steps of 17 starting at';
            parameters.question = 'Enter the number that you have reached so far';
            parameters.questionControl = 'Enter any number';
            parameters.experEndMessage = 'Experiment Finished! Thank You For Your Participation!';
            
            path = fileparts(mfilename('fullpath'));
            rootDirForPictures = path;
            parameters.dataPath = 'C:\secure\psycortex_data\mentalworkload_data';
            parameters.keypad = [path '\stim\keypadC.jpg'];
            parameters.SAM = [path '\stim\SAM.bmp'];
            parameters.next = [path '\stim\next.bmp' ];
            % --------------------------------------------------------------------
            % -------------------- Optional parameters ---------------------------
            % --------------------------------------------------------------------
            % each experiment can add any information to the parameteres extructure.
            % then they can be modified in this file
            parameters.numBreaks = 4; %4
      
            % For the last 3 control breaks I reuse the first 3 breaks
            parameters.controlBreaks = { {15,135,150, 179}, {22, 99,125, 179}, {23, 65, 160, 179},  {78,115,150, 179}, {34, 99,125, 179}, {23, 65, 160, 179}};
            parameters.easyBreaks = {{14, 51, 97, 179 }, {18, 102, 133, 179}, {29, 60, 92, 179}, {13, 40, 79, 179}, {47, 86, 129, 179}, {13, 37, 58, 179}};
            parameters.hardBreaks = {{12, 79, 130, 179}, {16, 116, 133, 179}, { 30, 90, 126, 179}, {49, 102, 125, 179}, {27, 95, 121, 179}, {41, 62, 1, 179}} ;
            
            parameters.easyStarts = [744, 268, 728, 124, 492, 766];            
            parameters.hardStarts = [3292, 3344, 2110, 2022, 4439, 3571];
            
        end
        %% getVariables
        function [conditionVars randomVars] = getVariables( this  )
            
            %-- condition variables ---------------------------------------
            j= 0;
            
            j = j+1;
            conditionVars{j}.name   = 'MainTask';
            
            %First we list a structure with a balanced order
            parameters.list = { [1,2], [2,1], [1,2], [2,1], [1,2], [2,1] };            
            % and we use randperm to randomize the order of showing each
            % block
            parameters.order = randperm(6);
            
            num = 0;
            for i=1:18
                if mod(i,3)==1
                     values{i} = 'Control';
                else
                    if mod(i,3)==2
                        num = num+1;
                        index = 1;
                    else                        
                        index = 2;
                    end
                    
                    difficulty = parameters.list{parameters.order(num)}(index);
                    switch difficulty
                        case 1
                        values{i} = 'Easy';
                        case 2
                        values{i} = 'Difficult';
                    end
                    
                end
            end            
            
            conditionVars{1}.values = values;
            
            %-- Random variables ------------------------------------------
            i= 0;
            randomVars = [];
        end
              %% runPreTrial
        function [trial ] = runPreTrial( this, variables )
            global Enum;
            
            graph = this.Graph;
            parameters = this.ExperimentInfo.Parameters;
            data = this.CurrentRun.Data;
                      
            
            %-- commit variables to trial struct to have them available
            % during the actual trial
            trial = [];

            %-- convert to degrees of visual angle
            trial.fixRadio	= graph.dva2pix( .025 );
            trial.fixWindowRadio	= graph.dva2pix( 3 );
            
            trial.fixColor = [0 0 0];
            trial.numBreaks = parameters.numBreaks;
            trial.currentBlockID = this.CurrentRun.futureConditions(1, Enum.futureConditions.blockid );%which block are we in right now
            trial.currentBlockNumber = this.CurrentRun.futureConditions(1,  Enum.futureConditions.blocknumber ); %how many blocks have been run
            if ( ~isempty(this.CurrentRun.pastConditions) )           
                trial.trialsDone = sum(this.CurrentRun.pastConditions(:,Enum.pastConditions.trialResult)==Enum.trialResult.CORRECT);
            else
                trial.trialsDone = 0;
            end
            trial.typeOfTask = variables.MainTask; 
          
            [x,y,buttons] = GetMouse;     
            
            while(buttons(1))
                [x,y,buttons] = GetMouse;     
            end
            
            switch(variables.MainTask)
                case 'Control'
                    trial.question = parameters.questionControl;
                    switch trial.trialsDone
                        case 0
                            trial.break = parameters.controlBreaks{1};
                        case 3
                            trial.break = parameters.controlBreaks{2};
                        case 6
                            trial.break = parameters.controlBreaks{3};
                        case 9
                            trial.break = parameters.controlBreaks{4};
                        case 12
                            trial.break = parameters.controlBreaks{5};
                        case 15
                            trial.break = parameters.controlBreaks{6};
                    end                    
                    this.Graph.DlgHitMouse( [parameters.instructionControl '\nClick to start'], [], []); 
                        
                 case 'Easy'
                     trial.question = parameters.question;
                     
                     switch trial.trialsDone
                         case {1, 2}
                             trial.starting = parameters.easyStarts(1);
                             trial.break = parameters.easyBreaks{1};
                         case {4,5}
                             trial.starting = parameters.easyStarts(2);
                             trial.break = parameters.easyBreaks{2};
                         case {7,8}
                             trial.starting = parameters.easyStarts(3);
                             trial.break = parameters.easyBreaks{3};
                         case {10,11}
                             trial.starting = parameters.easyStarts(4);
                             trial.break = parameters.easyBreaks{4};
                         case {13,14}
                             trial.starting = parameters.easyStarts(5);
                             trial.break = parameters.easyBreaks{5};
                         case {16,17}
                             trial.starting = parameters.easyStarts(6);
                             trial.break = parameters.easyBreaks{6};
                     end                    
                   
                    this.Graph.DlgHitMouse( [parameters.instructionEasy ' ' num2str(trial.starting) ' \nClick to start'], [], []); 
                    
                case 'Difficult'
                    trial.question = parameters.question;
                   
                     switch trial.trialsDone
                         case {1, 2}
                             trial.starting = parameters.hardStarts(1);
                             trial.break = parameters.hardBreaks{1};
                         case {4,5}
                             trial.starting = parameters.hardStarts(2);
                             trial.break = parameters.hardBreaks{2};
                         case {7,8}
                             trial.starting = parameters.hardStarts(3);
                             trial.break = parameters.hardBreaks{3};
                         case {10,11}
                             trial.starting = parameters.hardStarts(4);
                             trial.break = parameters.hardBreaks{4};
                         case {13,14}
                             trial.starting = parameters.hardStarts(5);
                             trial.break = parameters.hardBreaks{5};
                         case {16,17}
                             trial.starting = parameters.hardStarts(6);
                             trial.break = parameters.hardBreaks{6};
                     end  
                     
                    this.Graph.DlgHitMouse( [parameters.instructionDifficult ' ' num2str(trial.starting) '\nClick to start'], [], []); 
            end
            
            if trial.trialsDone == 12
                parameters.trialsBeforeBreak = 10;
            end
    
        end           
        
        %-- psycortex will start recording data just before calling this
        %function
        function [trialResult trial] = runTrial( this, variables, trial )
            
            global Enum;
            graph = this.Graph;
            trial.break
          
            parameters = this.ExperimentInfo.Parameters;

            trialResult = Enum.trialResult.CORRECT;
            trial.finalNumber = [];
            %-- add here the trial code
            
            lastFlipTime        = Screen('Flip', graph.window);
            secondsRemaining    = parameters.trialDuration;

            startLoopTime = lastFlipTime;
            
            trial.lastFixationTime = startLoopTime;            
          
            if (~isempty( this.EyeTracker ) )
                this.EyeTracker.SendMessage( 'START_LOOP: t=%d', round(startLoopTime*1000) );
            end
            
             trial.clock = fix(clock);
        
            [rx, ry] = RectCenter(graph.wRect); % gives screen rect center
            trial.fixRect = [rx-trial.fixRadio ry-trial.fixRadio rx+trial.fixRadio ry+trial.fixRadio];
            trial.fixWindowRect = [rx-trial.fixWindowRadio ry-trial.fixWindowRadio rx+trial.fixWindowRadio ry+trial.fixWindowRadio];
            
            currentStop = 1;
            while secondsRemaining > 0
                
                trial.lastFixationTime = checkFixation(this, trial);
                
                secondsElapsed      = GetSecs - startLoopTime;
                secondsRemaining    = parameters.trialDuration - secondsElapsed;
                
                if (currentStop < trial.numBreaks+1) 
                    
                    if (secondsElapsed > cell2mat(trial.break(currentStop)))
                        
                        if (~isempty( this.EyeTracker ) )
                            this.EyeTracker.SendMessage( 'START_KEYPAD: t=%d', round(startLoopTime*1000) );
                        end
                       
                        [result elapsed] = graph.DlgKeypad(trial.question, 3, 4, parameters.keypad , 9);
                        trial.lastFixationTime = GetSecs;
                        if strcmp(result,'-2')
                            throw(MException('PSYCORTEX:USERQUIT', ''));
                            return;
                        else
                            trial.finalNumber(currentStop) = str2double(result);
                            trial.timing(currentStop) = secondsElapsed+ elapsed;
                        end
                        currentStop = currentStop +1;
                        if (~isempty( this.EyeTracker ) )
                            this.EyeTracker.SendMessage( 'STOP_KEYPAD: t=%d', round(startLoopTime*1000) );
                        end
                      
                    end
                end
                % -----------------------------------------------------------------
                % --- Drawing of stimulus -----------------------------------------
                % -----------------------------------------------------------------
                
                Screen('FillOval', graph.window, trial.fixColor, trial.fixRect);
                
                % -----------------------------------------------------------------
                % --- END Drawing of stimulus -------------------------------------
                % -----------------------------------------------------------------
                
                % -----------------------------------------------------------------
                % -- Flip buffers to refresh screen -------------------------------
                % -----------------------------------------------------------------
                lastFlipTime = this.Graph.Flip();
                % -----------------------------------------------------------------
            end
            
            
            trial.clockF = fix(clock);
            
            
            if (~isempty( this.EyeTracker ) )
                this.EyeTracker.SendMessage( 'STOP_LOOP: t=%d', round(startLoopTime*1000) );
            end
            
            rates = { 'Mental Demand - How mentally demanding was the task?' 'Physical demand - How physically demanding was the task?' ...
                'Temporal demand - How hurried or rushed was the pace of the task?' 'Performance - How succesful were you in acomplishing what you were asked to do?' ...
                'Effort - How hard did you have to work to accomplish your level of performance?' 'Frustration - How insecure, discouraged, stressed, and annoyed were you?'};
            trial.rates = graph.DlgScales('Please use the following scale to rate each category',rates, 9,parameters.next,1,{'Very Low', '', 'Very High'}, [0 0 0]);
            if trial.rates == -1
                throw(MException('PSYCORTEX:USERQUIT', ''));
                return;
            end
            
            [trial.happy trial.shocked ] = graph.DlgSAM('', ...
                9, 2, parameters.SAM ,parameters.next  );
            if trial.happy == -1
                throw(MException('PSYCORTEX:USERQUIT', ''));
                return;
            end
            
            if length(this.CurrentRun.futureConditions(:,1)) == 1
                result = 1;
                while(result)
                    message = parameters.experEndMessage;
                    varargin{1} = 'center';
                    varargin{2} = 'center';
                    varargin{3} = 255*[1 1 1];
                    
                    % remove previous key presses
                    FlushEvents('keyDown');
                    
                    DrawFormattedText( this.Graph.window, message, varargin{:} );
                    Screen('Flip', this.Graph.window);
                    
                    char = GetChar;
                    result = ~char;
                    
                   
                end
            end
        end
        
        %% runPostTrial
        function [trialOutput ] = runPostTrial( this, trial )
            trialOutput = trial;
            FlushEvents('mouseDown');
            FlushEvents('keyDown');
        end
        
         %% make crosshairs
        function makeCrossHairs(this, trial, center_x, center_y, left_dist, right_dist, top_dist, bottom_dist, color, penWidth)
            Left = center_x - left_dist;
            Bottom = center_y + bottom_dist;
            Right = center_x + right_dist;
            Top = center_y - top_dist;
            
            Screen('DrawLine', this.Graph.window, color, center_x, Bottom, center_x, Top, penWidth);
            Screen('DrawLine', this.Graph.window, color, Left, center_y, Right, center_y, penWidth);
        end
        
        %%function to check fixation
        function lastFixationTime = checkFixation(this, trial)
            
            
            lastFixationTime = trial.lastFixationTime;
            if (~isempty( this.EyeTracker ) )
                [x y] = this.EyeTracker.GetCurrentPosition();
                if IsInRect(x,y,trial.fixWindowRect)
                    lastFixationTime = GetSecs;
                    
                else
                    
                    if GetSecs - trial.lastFixationTime > 3
                        Beeper('med', 0.3);
                        lastFixationTime = GetSecs;
                        
                        
                    end
                end
            end
            
        end
end

end
