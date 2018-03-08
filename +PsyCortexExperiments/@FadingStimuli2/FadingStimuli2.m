classdef FadingStimuli2 < PsyCortexExperiments.PsyCortexExperiment

 methods
        function this = FadingStimuli2( )
            this.Name = 'FadingStimuli2';
            this.Config.HitKeyBeforeTrial = 1;
          
        end
    end
    
    methods (Access=protected)

      
      
    function parameters = getParameters( this, parameters  )
    % --------------------------------------------------------------------
    % -------------------- FIXED PARAMETERS ------------------------------
    % --------------------------------------------------------------------  


    %%-- Blocking
    parameters.trialSequence = 'Random';        % Sequential, Random, Random with repetition, ...

    parameters.trialAbortAction = 'Delay';     % Repeat, Delay
    parameters.trialsBeforeBreak            = 14;
    % TODO: blocks
    parameters.blockSequence = 'Random';    % Sequential, Random, Random with repetition, Mixed ...
    parameters.blocksToRun              = 40;
    parameters.trialsPerSession = 40;%
    parameters.trialsBeforeCalibration      = 15;
    parameters.trialsBeforeDriftCorrection  = 60;
    parameters.blocks{1}.fromCondition  = 1;
    parameters.blocks{1}.toCondition    = 4;
    parameters.blocks{1}.trialsToRun    = 4;
  
      path = fileparts(mfilename('fullpath'));
      parameters.dataPath = 'C:\secure\psycortex_data\fadingstimuli2_data';
       

    % --------------------------------------------------------------------
    % -------------------- Optional parameters ---------------------------
    % --------------------------------------------------------------------
    % each experiment can add any information to the parameteres extructure.
    % then they can be modified in this file

    parameters.trialDuration = 10;%seconds

    parameters.fixRad       = .05;
    parameters.fixColor     = [255 0 0];
    parameters.Xgauss = 1.5; %deg
    parameters.Ygauss = 1; %deg
    parameters.levels_to_use = [1 2 3 4 5 6 7 8]; %1 corresponds to 0% contrast, 5 to 40%
    parameters.type_of_fading = 'step'; %can be step or linear (final experiment used step fading)
    parameters.turning_radius = 1.25; %degrees radius the circle trace the center of gabor makes when moving
    parameters.turning_speed = 1/10; %turns of gabor per second
    parameters.movement_type = 'drift'; %can be drift or grating (need to fix grating code though due to contrast issues) used drift for final experiment


    end      
    %%
    
    function [conditionVars randomVars] = getVariables( this  )
        conditionVars = {};
            randomVars = {};
        i= 0;   
        i = i+1;
        conditionVars{i}.name   = 'Size';
        conditionVars{i}.values = [0.6];
        i = i+1;
        conditionVars{i}.name   = 'Frequency';
        conditionVars{i}.values = [.1 .5 2 6]
           
        i = i+1;
        conditionVars{i}.name   = 'Eccentricity';
       conditionVars{i}.values = [ 9 ];
        
        i = i+1; 
        conditionVars{i}.name   = 'Contrast';
        conditionVars{i}.values = [40];       

        i = i+1;
        conditionVars{i}.name   = 'Fading_Condition';
        conditionVars{i}.values = { 'Illusory' };

        randomVars = {};
        i = 0;
         i = i+1;
        randomVars{i}.name   = 'Angle';
        randomVars{i}.type = 'List';
        randomVars{i}.values = [0:45:325];    
    end

function [trial ] = runPreTrial( this, variables )

    graph = this.Graph;
     parameters = this.ExperimentInfo.Parameters;
global Enum;

trial = [];
dva2pix(graph, 1)
% change gabor props to pixels
trial.frequency = variables.Frequency;
trial.sinPeriod = dva2pix( graph, 1/variables.Frequency);%variables.Frequency );
trial.Xgauss = dva2pix( graph, parameters.Xgauss );
trial.Ygauss = dva2pix( graph, parameters.Ygauss );
trial.gaborSize = dva2pix(graph,  variables.Size );
trial.gabor_window_size = dva2pix(graph, 8*variables.Size);
trial.gaborEccentricity = dva2pix( graph, variables.Eccentricity );
trial.fixRadio = dva2pix( graph, parameters.fixRad );
trial.displayAngle = variables.Angle;
trial.numLevels = length(parameters.levels_to_use);
trial.turning_radius = dva2pix(graph,parameters.turning_radius);
trial.saveContrast = variables.Contrast;
%Make random orientation of gabor from 0 to 360 deg in 10 deg steps
aa = randperm(36);
trial.Orientation = aa(1)*10;

%-- Is this a real fading condition?
switch(variables.Fading_Condition)
    case 'Illusory'
        trial.realFading = 0;
    case 'Real'
        trial.realFading = 1;
end

black = BlackIndex(graph.window);  % Retrieves the CLUT color code for black.
white = WhiteIndex(graph.window);  % Retrieves the CLUT color code for white.
gray = (black + white) / 2;  % Computes the CLUT color code for gray.

if round(gray)==white
    gray=black;
end

gray = ceil(gray);
trial.diffBetweenWhiteandGray = abs(white - gray);
trial.gray = gray; %save gray
trial.white =  white;

% Make Screen gray
Screen('FillRect', graph.window, trial.gray);
Screen('Flip', graph.window);
[gabor] = make_gabor(trial); %make standard gabor
gabor = gabor / max(abs(gabor(:)));
gabor = gabor * (variables.Contrast/100);
Gabor = gray + round(trial.diffBetweenWhiteandGray * gabor);
trial.gabor = Gabor;

trial.calcContrast = (max(Gabor(:) - min(Gabor(Gabor~=0))))/ white;

trial.gaborTexture1 = Screen('MakeTexture', graph.window, trial.gabor, 1,[],[]);
% 
 contraste = [0 1.56 3.13 6.25 12.5 25 50 100]; %contrast levels 
 trial.contrast = contraste(parameters.levels_to_use);

trial.alphaFactors = 0:1/10:1; %alpha factor to use in alpha channel to get corresponding contrast in trial.contrast for any given level when
%the initial gabor has 100% contrast (or at least as close as I could get
%it to 100% contrast
trial.alphaFactors = variables.Contrast;%trial.alphaFactors(parameters.levels_to_use);

clear gabor x y Gabor a

% Query duration of monitor refresh interval:
ifi=Screen('GetFlipInterval', graph.window);

waitframes = 1;
trial.waitduration = waitframes * ifi;


trial.buttonTimes(1) = 0; % save times of button press and release
trial.fadingTimes(1) = 0; % save times of fading changes


trial.fliptimes = zeros(ceil(parameters.trialDuration/trial.waitduration),1);
size(trial.fliptimes);

%Get button times from a random prior illusory fading trial if this is a
%real fading trial
t=0;
if ( trial.realFading )
    %     find button presses from a previous trial
    trial.buttonTimesToUse = [];
    for i=length(data.trialOutput):-1:1
        if (isfield(data.trialOutput{i},'buttonTimes') && ~data.trialOutput{i}.realFading)
            t=t+1;
            buttonTimesToUse{t} = data.trialOutput{i}.buttonTimes;
        end
    end
    aa = randperm(t);
    if (isempty(aa))
        trialResult = Enum.trialResult.SOFT_ABORT;
        disp('ABORTING because there are no button times')
        return;
    else
        trial.buttonTimesToUse = buttonTimesToUse{aa(1)};
        
        if length(trial.buttonTimesToUse) <= 1
            idx_longer_than2 = [];
            for i=1:length(buttonTimesToUse)
                if length(buttonTimesToUse{i}) >= 2
                    idx_longer_than2 = [idx_longer_than2; i];
                end
            end
            t = length(idx_longer_than2);
            if t > 0
                aa = randperm(t);
                trial.buttonTimesToUse = buttonTimesToUse{idx_longer_than2(aa(1))};
            end
        end
        
        
    end
end

  trial.currentCondition    = this.CurrentRun.futureConditions(1,Enum.futureConditions.condition);
            
            if ( ~isempty(this.CurrentRun.pastConditions) )
                trial.trialNumInSession = sum(this.CurrentRun.pastConditions(:,Enum.pastConditions.trialResult)==Enum.trialResult.CORRECT)+1;
            else
                trial.trialNumInSession = 1;
            end
% Query duration of monitor refresh interval:
ifi=Screen('GetFlipInterval', graph.window);

waitframes = 1;
trial.waitduration = waitframes * ifi;

trial.buttonTimes(1) = 0; % save times of button press and release
trial.fadingTimes(1) = 0; % save times of movement changing
trial.intensifyingTimes(1) = 0;

trial.fliptimes = zeros(ceil(parameters.trialDuration/trial.waitduration),1);
size(trial.fliptimes);


end
% ---------------------------------------------------------------------- %%
%% -----------------            TRIAL                  ----------------- %%
% ---------------------------------------------------------------------- %%

 function [trialResult trial] = runTrial( this, variables, trial )

global Enum;
   parameters = this.ExperimentInfo.Parameters;
graph = this.Graph;

Screen('BlendFunction', graph.window, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA); %this is to use the alpha channel


%alpha factors to use in alpha channel to get corresponding contrast
alphaFactors = trial.alphaFactors;

white = trial.white;
%contrast = trial.contrast; %contrast levels
trialResult = Enum.trialResult.CORRECT;

framesIntensifying = 0; % must be initialized to 0
framesFading    = 0; % must be initialized to 0
buttonPressed   = 0;% must be initialized to 0
nowFading       = 1;% must be initialized to 1
currentLevel    = trial.numLevels; %initial contrast level set to 40% (there are 5 levels, higher levels = higher contrast)
begIntensifyAmount  = 1; %Must be initialized to 1
begFadeAmount = 0; %Must be initialized to 0
total_frames = 0;
phase = 0;
turningangle = 0;

oldDefaultColor = Screen( 'TextColor', graph.window);
Screen( 'TextColor', graph.window, graph.dlgTextColor);
[mx, my] = RectCenter(graph.wRect);
% 
% DrawFormattedText(graph.window, ['Press the button to start the trial'], mx/2+80, my);
% Screen('Flip', graph.window);

% Screen( 'TextColor', graph.window, oldDefaultColor); % recover pr

lastFlipTime        = Screen('Flip', graph.window);
secondsRemaining    = parameters.trialDuration;
secondsElapsed      = 0;


startLoopTime = lastFlipTime;
if (~isempty( this.EyeTracker ) )
    this.EyeTracker.SendMessage( 'TRIAL_BEGIN: N=%d Cond=%d t=%d', trial.trialNumInSession, trial.currentCondition, round(lastFlipTime*1000) );
end


while secondsRemaining > 0
    
    secondsElapsed      = GetSecs - startLoopTime;
    secondsRemaining    = parameters.trialDuration - secondsElapsed;
    
    % -----------------------------------------------------------------
    % --- Drawing of stimulus -----------------------------------------
    % -----------------------------------------------------------------
    
    %-- Find the center of the screen
    [mx, my] = RectCenter(graph.wRect);
    
    %-- Center and rectangles for the gabor
    gaborRect = [0 0 trial.gabor_window_size trial.gabor_window_size];
    
    if trial.realFading
        
        switch parameters.movement_type
            
            case 'grating'
                
                x1 = mx + cos(trial.displayAngle/180*pi)*trial.gaborEccentricity;
                y1 = my + sin(trial.displayAngle/180*pi)*trial.gaborEccentricity ;
                %         curphasepix = dva2pix(graph,phase);
                [gabor] = make_gabor(trial,phase); %make standard gabor with given phase
                
                gabor = trial.gray + trial.diffBetweenWhiteandGray * gabor/parameters.contrast_factors(end);
                trial.gaborTexture2 = Screen('MakeTexture', graph.window, gabor, 1,[],[]);
                
                trial.gaborTexture = trial.gaborTexture2;
                phaseConstant = .1; %pixels/frame
                phase = phaseConstant + phase;
                
            case 'drift'
                
                x1 = mx + cos(trial.displayAngle/180*pi)*trial.gaborEccentricity + ...
                    trial.turning_radius*cos(turningangle);
                y1 = my + sin(trial.displayAngle/180*pi)*trial.gaborEccentricity + ...
                    trial.turning_radius*sin(turningangle);
                turningangle = turningangle + parameters.turning_speed*2*pi/60;
                trial.gaborTexture = trial.gaborTexture1;
                
        end
        
    else
        
        %-- calculate the center of the gabor given the angle
        x1 = mx + cos(trial.displayAngle/180*pi)*trial.gaborEccentricity;
        y1 = my + sin(trial.displayAngle/180*pi)*trial.gaborEccentricity;
        
        trial.gaborTexture = trial.gaborTexture1;
        
    end
    
    gaborRect1 = CenterRectOnPointd( gaborRect, x1, y1 );
    
    switch parameters.type_of_fading
        
        
        case 'step'
            
            if ( trial.realFading)
                
                % find if it should fade
                nowFading = ~timeToFade( trial.buttonTimesToUse, secondsElapsed);
                
                if ~nowFading
                    %             if beginning of intensifying period increase contrast to a
                    %             random level above current level
                    if framesIntensifying == 0 && framesFading > 0
                        aa = randperm(trial.numLevels);
                        bb = aa(aa > currentLevel);
                        if isempty(bb)
                            bb = trial.numLevels;
                        end
                        currentLevel = bb(1);
                    end
                    framesIntensifying=framesIntensifying+1;
                    %reset frames fading to 0
                    framesFading=0;
                end
                
                if  nowFading
                    %             if beginning of fading period increase contrast to a
                    %             random level below current level
                    
                    if framesFading == 0 && framesIntensifying > 0
                        aa = randperm(trial.numLevels);
                        bb = aa(aa < currentLevel);
                        if isempty(bb)
                            bb = 1;
                        end
                        currentLevel = bb(1);
                    end
                    framesIntensifying=0;
                    framesFading=framesFading+1;
                end
                currentContrast = trial.contrast(currentLevel);
            else
                %         if this is an illusory trial, the contrast level is always 5
                currentLevel = length(trial.contrast);
                currentContrast = variables.Contrast;%contrast(currentLevel);
            end
            
            Screen('DrawTexture', graph.window, trial.gaborTexture, [], gaborRect1,trial.Orientation,[]);%variables.Contrast);
            
        case 'linear'
            
            %-- calculate the gabor fading 'speed'
            if ( trial.realFading)
                nowFading = ~timeToFade( trial.buttonTimesToUse, secondsElapsed);
                if ~nowFading

                    if framesIntensifying==0 && framesFading > 0
                        aa = randperm(trial.numLevels);
                        bb = aa(aa > currentLevel);
                        if isempty(bb)
                            bb = trial.numLevels;
                        end
                        currentLevel = bb(1);
                        framesFading = 0;
                        begIntensifyAmount = fadeAmount;
                    end
                    
                    intensifyAmount = min(alphaFactors(currentLevel),1/90*framesIntensifying + begIntensifyAmount);%how much to intensify
                    %must stop once at currentLevel for this intensification
                    
                    Screen('DrawTexture', graph.window, trial.gaborTexture, [], gaborRect1 ,trial.Orientation ,[], intensifyAmount);
                    
                    framesIntensifying=framesIntensifying+1;
                    currentContrast = contraste(currentLevel);
                    
                end
                
                if nowFading
                    
                    if framesFading==0 && framesIntensifying > 0
                        aa = randperm(trial.numLevels);
                        bb = aa(aa < currentLevel);
                        if isempty(bb)
                            bb = 1;
                        end
                        currentLevel = bb(1);
                        framesIntensified = max(240,framesIntensifying);
                        framesIntensifying = 0;
                        begFadeAmount = intensifyAmount;
                    end
                    fadeAmount = max(alphaFactors(currentLevel),-1/90*framesFading + begFadeAmount); %how much to fade
                    %must stop once at currentLevel for this fade
                    
                    Screen('DrawTexture', graph.window, trial.gaborTexture, [], gaborRect1 ,trial.Orientation ,[], fadeAmount);
                    framesFading = framesFading + 1;
                    currentContrast = trial.contrast(currentLevel);
                end
            else
                currentLevel = trial.numLevels;
                
                %         if an illusory case, the gabor never changes and has 40% contrast
                Screen('DrawTexture', graph.window, trial.gaborTexture, [], gaborRect1,trial.Orientation,[],alphaFactors(currentLevel));
                currentContrast = trial.contrast(currentLevel);
            end
    end
    
    
    %-- Center and rectangles for the fixation spot
    fixRect = [0 0 trial.fixRadio*2 trial.fixRadio*2];
    fixRect = CenterRectOnPointd( fixRect, mx, my );
    
    %-- Draw Fixation spot
    Screen('FillOval', graph.window, parameters.fixColor, fixRect);
    
    
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
            s = '';
            if ( isstr(variables.(vNames{iVar})) )
                s = sprintf( '%s = %s',vNames{iVar},variables.(vNames{iVar}) );
            else
                s = sprintf( '%s = %s',vNames{iVar},num2str(variables.(vNames{iVar})) );
            end
            Screen('DrawText', graph.window, s, 20, currentline, graph.black);
            
            currentline = currentline + 25;
        end
         Screen('DrawText', graph.window, num2str(trial.calcContrast), 20, currentline, graph.black);
          currentline = currentline + 25;
        s = sprintf( '%s = %s', 'orientation', num2str( trial.Orientation) );
        Screen('DrawText', graph.window, s, 20, currentline, graph.black);
        
        if ( buttonPressed )
            Screen('DrawText', graph.window, 'Button pressed', 20, graph.wRect(4)-100, graph.black);
        else
            Screen('DrawText', graph.window, 'Button released', 20, graph.wRect(4)-100, graph.black);
        end
       
        Screen('DrawText', graph.window, sprintf('Contrast %i...', round(currentContrast)), 20, graph.wRect(4)-50, graph.black);
        
        if ( trial.realFading )
            if ( framesFading >= 1 && total_frames > 1)
                
                Screen('DrawText', graph.window, sprintf('Faded %i...', round(currentContrast)), 20, graph.wRect(4)-200, graph.black);
                
                
            end
            
            
            if  framesIntensifying >= 1 && total_frames > 1
                
                Screen('DrawText', graph.window, sprintf('Intensified %i...', round(currentContrast)), 20, graph.wRect(4)-200, graph.black);
                
                
            end
            
        end
        
    end
    % -----------------------------------------------------------------
    % END DEBUG
    % -----------------------------------------------------------------
    
    % -----------------------------------------------------------------
    % -- Flip buffers to refresh screen -------------------------------
    % -----------------------------------------------------------------
    lastFlipTime = graph.Flip();
    trial.fliptimes(sum(trial.fliptimes>0)+1)  = lastFlipTime;
    % -----------------------------------------------------------------
    
    
    % -----------------------------------------------------------------
    % --- Collecting responses  ---------------------------------------
    % -----------------------------------------------------------------
    
    
    % -- Check if in this frame there was a contrast change
    if ( trial.realFading )
        if ( framesFading == 1 && total_frames > 1)
            trial.fadingTimes(end+1) = lastFlipTime - startLoopTime;
            if (~isempty( this.EyeTracker ) )
                result = this.EyeTracker.SendMessage( 'Message', 'FADING: contrast=%d t=%d', round(currentContrast), round(lastFlipTime*1000));
                
                if result
                    error('Error in eyelink message');
                end
            end
        end
        
        
        if ( framesIntensifying == 1 && total_frames > 1)
            trial.intensifyingTimes(end+1) = lastFlipTime - startLoopTime;
           if (~isempty( this.EyeTracker ) )
                result = this.EyeTracker.SendMessage( 'Message', 'INTENSIFYING: contrast=%d t=%d', round(currentContrast), round(lastFlipTime*1000));

                if result
                    error('Error in eyelink message');
                end
            end
        end
        
    end
    % -----------------------------------------------------------------
    % --- END Collecting responses  -----------------------------------
    % -----------------------------------------------------------------
    
    total_frames = total_frames +1;
     
end % main loop
mean(diff(trial.fliptimes(trial.fliptimes>0)))

%
% ---------------------------------------------------------------------- %%
  end
%% -----------------           POST TRIAL              ----------------- %%
% ---------------------------------------------------------------------- %%

 function [trialOutput ] = runPostTrial( this, trial )

global Enum;
   parameters = this.ExperimentInfo.Parameters;
 trialOutput = [];
trialOutput.trialEvents = [];
%-- Prepare output
trialOutput.buttonTimes = trial.buttonTimes;
trialOutput.realFading = trial.realFading;
trialOutput.fliptimes = trial.fliptimes;
trialOutput.trialOrientation = trial.Orientation;
trialOutput.parameters = parameters;

 end


    end
end



function pix = dva2pix( graph, dva )

horPixPerDva = graph.pxWidth/2 / (atan(graph.mmWidth/2/graph.distanceToMonitor)*180/pi);
verPixPerDva = graph.pxHeight/2 / (atan(graph.mmHeight/2/graph.distanceToMonitor)*180/pi);

pix = round( horPixPerDva * dva );
end



function [x y] = rotatePointCenter( graph, point, angle )

[mx, my] = RectCenter(graph.wRect);


p = rotatePoint( point, angle/180*pi, [mx my]);

x = p(1);
y = p(2);
end

function fade = timeToFade( buttonTimesToUse, secondsElapsed)
fade = mod(sum(buttonTimesToUse<secondsElapsed),2);
end


function [gabor,x,y] = make_gabor(params,phase)

if ~exist('phase','var')
    phase = 0;
end


xmax = floor(params.gabor_window_size /2);
xmin = -xmax;
ymax = xmax;
ymin = xmin;

[x,y] = meshgrid(xmin:xmax,ymin:ymax);

% *** To lengthen the period of the grating, increase pixelsPerPeriod.
pixelsPerPeriod = params.sinPeriod ; % How many pixels will each period/cycle occupy?
spatialFrequency = 1 / pixelsPerPeriod; % How many periods/cycles are there in a pixel?
radiansPerPixel = spatialFrequency * (2 * pi); % = (periods per pixel) * (2 pi radians per period)

a=radiansPerPixel;

% Converts meshgrid into a sinusoidal grating, where elements
% along a line with angle theta have the same value and where the
% period of the sinusoid is equal to "pixelsPerPeriod" pixels.
gratingMatrix = sin(a*x + phase);

idx = (x/(2*params.gaborSize)).^2 + (y/(2.5*params.gaborSize)).^2 > 1;
idx1 =  abs(x) > pi/a + 1;

% Creates a circular Gaussian mask centered at the origin, where the number
% of pixels covered by one standard deviation of the radius is
% approximately equal to "gaussianSpaceConstant."
gaussMatrix = exp(-.5*((x/params.gaborSize) .^ 2 +...
    (y/params.gaborSize) .^ 2));

 %gratingMatrix(idx | idx1) = gaussMatrix(idx|idx1).^4;

% Create gabor
gabor = gratingMatrix .* gaussMatrix;
end

