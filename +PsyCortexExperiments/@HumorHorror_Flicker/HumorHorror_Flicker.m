classdef HumorHorror_Flicker < PsyCortexExperiments.PsyCortexExperiment
    %MiniExplore Summary of this class goes here
    %   Detailed explanation goes here
    
    
    methods
        function this = HumorHorror_Flicker( )
            this.Name = 'HumorHorror_Flicker';
        end
    end
    

    
     methods (Access=protected)     
        %% getParameters
        function parameters = getParameters( this, parameters  )
            % --------------------------------------------------------------------
            % -------------------- FIXED PARAMETERS ------------------------------
            % --------------------------------------------------------------------
            
            % fixed parameters that every experiments need to complete
            
            parameters.fixRad                       = .05;
            parameters.fixColor                     = [255 0 0];
           
            parameters.trialsBeforeCalibration      = 85;
            parameters.trialsBeforeDriftCorrection  = 15000;
            parameters.trialsBeforeBreak            = 85;
            
            %%-- Blocking
            parameters.trialSequence    = 'Random';	% Sequential, Random, Random with repetition, ...
            parameters.trialAbortAction = 'Delay';     % Repeat, Delay, Drop
            parameters.trialsPerSession = 408;
            
            parameters.trialDuration = 1; %seconds
            parameters.trialLength = 30;            
            
            parameters.flickerDuration = 0.240;%240; increase/dercrease
            parameters.greyDuration = 0.075; %changing to 0.084
            
            
            path = fileparts(mfilename('fullpath'));
            parameters.dataPath = 'C:\secure\psycortex_data\humorhorror_flicker_data';
            parameters.imageFolder = [path '\stim\'];
            
            % --------------------------------------------------------------------
            % -------------------- Optional parameters ---------------------------
            % --------------------------------------------------------------------
            % each experiment can add any information to the parameteres extructure.
            % then they can be modified in this file
            
        end
        
        %% getVariables
        function [conditionVars randomVars] = getVariables( this  )
            conditionVars = {};
            randomVars = {};
            path = fileparts(mfilename('fullpath'));            
            parameters.imageFolder = [path '\stim\'];
            
            %-- condition variables ---------------------------------------
            i= 0;
            i = i+1;
            conditionVars{i}.name   = 'Stim';
            dircontent=dir([path '\stim']);
            files = [];
            for j=3:length(dircontent)
                tempfiles = dir([path '\stim\' dircontent(j).name '\*a*']);
                files = cat(1, files, tempfiles);
            end
            
            disp ('length of files');
            disp(length(files));
            
            conditionVars{i}.values = files;

        end
        
        %% runPreTrial
        function [trial ] = runPreTrial( this, variables )
            global Enum;
            
            trial = [];
             trial.im = variables.Stim.name
             im2 = trial.im;
             position = strfind(im2,'a');
             im2(position) = 'b';                                   
             trial.im
             im2
             trial.I1 = imread( [this.ExperimentInfo.Parameters.imageFolder trial.im(1:2) '\' trial.im] );
             trial.I2 = imread( [this.ExperimentInfo.Parameters.imageFolder trial.im(1:2) '\' im2] );
             trial.width = size(trial.I1,2);
             trial.height = size(trial.I1,1);
             trial.gray = 128; %save gray
        end
        
        %% runTrial
        %-- psycortex will start recording data just before calling this
        %function
        function [trialResult trial] = runTrial( this, variables, trial )
            
            global Enum;
            graph = this.Graph;
            parameters = this.ExperimentInfo.Parameters;
            ESCAPE = 27;
            trialResult = Enum.trialResult.CORRECT;           
            %-- add here the trial code
            Screen('FillRect', graph.window, trial.gray);
            startLoopTime        = Screen('Flip', graph.window);
       
            secondsRemaining    = parameters.trialLength;
            secondsImages = parameters.flickerDuration;
            first = 0;
            
            [mx, my] = RectCenter(graph.wRect);
            trial.corner = [mx-trial.width/2 my-trial.height/2]  ;                  
            
            flickTime = 0;
            timing = 1;
            pushed = 0;
            HideCursor;
            imageA = 1;
            dlgResult = this.Graph.DlgHitKey( 'Press any key as soon as you notice the change.\n Press any key to continue', [], []);
            FlushEvents('mouseDown');
            FlushEvents('keyDown');    
            
            if (~isempty( this.EyeTracker ) )
                this.EyeTracker.SendMessage( 'START_LOOP: t=%d', round(startLoopTime*1000) );
            end
            
            
            trial.imageTexture1 = Screen('MakeTexture', graph.window, trial.I1, 1);
            trial.imageTexture2 = Screen('MakeTexture', graph.window, trial.I2, 1);
            
            while (secondsRemaining > 0) && (~pushed)                
                
                if imageA                                               
                   imageA = 0;                       
                   I = trial.imageTexture1;
                else                                        
                   I = trial.imageTexture2;
                   imageA = 1;
                   first = 1;
                end
                
                
                trial.imageRect =Screen('Rect', I );                    
                [trial.center] = CenterRect(trial.imageRect, this.Graph.wRect);
                Screen('Close',trial.imageRect);
              %  Screen('DrawTexture', graph.window, trial.imageTexture, [], trial.imageRect, 0);                                        
                secondsImages = parameters.flickerDuration;
                [keyIsDown,secs,keyCode] = KbCheck; 
                
                
                
                if keyIsDown
                    if keyCode(Enum.keys.ESCAPE)
                         throw(MException('PSYCORTEX:USERQUIT', ''));
                        throw(MException('PSYCORTEX:USERQUIT', ''));
                    end
                     
                     if first
                         pushed = 1;
                         trial.pos(3) = secondsElapsed;
                         break;
                     end
                    
                end
                

                 Screen('DrawTexture', graph.window, I, [], trial.center, 0);
                 variable = Screen('Flip', graph.window);
                     
                while (secondsImages > 0) && (~pushed) 
                    %-- Find the center of the screen

                    seconds = GetSecs - variable; 
                    secondsImages = parameters.flickerDuration - seconds;
                    [keyIsDown,secs,keyCode] = KbCheck;  
                    if keyIsDown                    
                        if keyCode(Enum.keys.ESCAPE)
                             throw(MException('PSYCORTEX:USERQUIT', ''));
                        end
                        if first
                            pushed = 1;                       
                            trial.pos(3) = secondsElapsed;

                            break;
                        end
                    end 
                   

                end      
                
                if (~pushed)                                                         
                    
                    secondsFlicker = parameters.greyDuration;%parameters.flickerDuration;
                    Screen('FillRect', graph.window, trial.gray);
                    flickTime = Screen('Flip', graph.window);                    
                    
                    
                    while (secondsFlicker > 0 )                        
                        
                       
                        seconds = GetSecs - flickTime;                                            
                        secondsFlicker = parameters.greyDuration - seconds; 
                        [keyIsDown,secs,keyCode] = KbCheck; 
                        if keyIsDown
                            if keyCode(Enum.keys.ESCAPE)
                             throw(MException('PSYCORTEX:USERQUIT', ''));
                            end                            
                            if first
                                pushed = 1;
                                trial.pos(3) = secondsElapsed;
                                break;
                            end
                        end
%                       
                    end; 
                    
                end
                
                secondsElapsed      = GetSecs - startLoopTime;
                secondsRemaining    = parameters.trialLength - secondsElapsed;                
                secondsImages = parameters.flickerDuration;
            end
            
            if pushed                
                ShowCursor('Hand');

                while(1)                                      
                    DrawFormattedText( graph.window, 'Please click on the area of the screen that changed', 300, 200 );                
                    Screen('DrawTexture', graph.window, trial.imageTexture2, [], trial.center, 0);                                                           
                    Screen('Flip', graph.window);                   
                    [x,y,buttons] = GetMouse;
                    if buttons(1)
                        trial.pos(1) = x;
                        trial.pos(2) = y;                                                                                        
                        break;
                    end
                end
                
            else
                trial.pos(1) = -1;
                trial.pos(2) = -1;
                trial.pos(3) = -1;

                
            end
            trial.time = secondsElapsed;

            Screen('Close', trial.imageTexture1);
            Screen('Close', trial.imageTexture2);

            HideCursor;
            
            
            if (~isempty( this.EyeTracker ) )
                this.EyeTracker.SendMessage( 'STOP_LOOP: t=%d', round(startLoopTime*1000) );
            end
            
            % -----------------------------------------------------------------
            % DEBUG
            % -----------------------------------------------------------------
            if (0)
                
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
                
                if ( ~isempty( this.EyeTracker ) )
                    draweye( this.EyeTracker.eyelink, graph)
                end
            end
            % -----------------------------------------------------------------
            % END DEBUG
            % -----------------------------------------------------------------
            
            
            
                % -----------------------------------------------------------------
                % -- Flip buffers to refresh screen -------------------------------
                % -----------------------------------------------------------------

                % -----------------------------------------------------------------
                
                
                
                
                % -----------------------------------------------------------------
                % --- Collecting responses  ---------------------------------------
                % -----------------------------------------------------------------
                
                % -----------------------------------------------------------------
                % --- END Collecting responses  -----------------------------------
                % -----------------------------------------------------------------
                
          
            
            
        end
        
        %% runPostTrial
        function [trialOutput ] = runPostTrial( this, trial )

            trialOutput.pos = trial.pos;
            trialOutput.time = trial.time;

            trialOutput.corner = trial.corner;

        end
        
     end
end


