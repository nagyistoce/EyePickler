% Example of importing eye data and syncing times
% This script uses loadGaze2, which handles gaze and surface data (from 
% EyeTracker.processSurface()) only

clear
close all


%% Import Eye data
% Assuming running in EyePickler/MATLABAnalysis/ and data is in
% EyePicker/EyeTrackerServer/Data/
% Example here is shortened to reduce file size

% Set file name
fn = [fileparts(pwd), '\EyeTrackerServer\Data\surfaceExample_eye.mat'];

% Load gaze/surface data into eye object
eyes = Eye(fn);


%% Load trial data
% Load trial data, assuming this is also in 
% EyePicker/EyeTrackerServer/Data/
% This file is just an example containing trial times and parameters file
% with exchanged time information

fn = [fileparts(pwd), '\EyeTrackerServer\Data\surfaceExample_trials.mat'];
a = load(fn);
stimLog = a.stimLog;
nT = height(stimLog);

% Convert time 
stimLog.sTime = datetime(stimLog.startClock);
stimLog.eTime = datetime(stimLog.endClock);


%% Fix offset
% If data is available
% Get the MATLAB time and convert it to posix.
% Calculate the offset between the two
% Stimlog contains .timeStamp containing times of trials in MATLAB time
% gaze contains TS in posixtime (and TS2 in readable format)
% Add a column to gaze with the offset corrected, and converted to MATLAB
% time

eyes = eyes.fixOffset(a.params);


%% Preprocess gaze data
% Removed empty rows, convert time

eyes = eyes.PPGaze();


%% Plot outcome

close all

% Plot surface on/off agaist time
eyes.plotSurfTime()

% Plot normals coloured by on/off surface
eyes.plotGaze()


%% Process gaze data
% Remove low frequency drift from eye data - not generally necessary
% Creates property .gazeCorrected

eyes = eyes.processGaze();


%% Replay gaze comaprison
% Replay gaze comparison comparing gaze and gazeCorrected
if 1
    eyes.replayGaze()
end


%% Plot trials and raw gaze
% Plot during trial (black) and outside trial (red) on-surface proportions
% Join with lines coloured to indicate eye trajectory.
% If line is blue, the eyes move away from the surface after trial (good
% behaviour)
% If line is yellow, eyes spent more time on surface AFTER trial eneded
% than during trial (bad behaviour)

figure
hold on
% Add gaze data to stimLog
stimLog.onSurf = NaN(nT,1);
stimLog.nGazeSamples = NaN(nT,1);
stimLog.onSurfProp = NaN(nT,1);
stimLog.nGazeSamplesAfterThisTrial = NaN(nT,1);
stimLog.onSurfPropAfterThisTrial = NaN(nT,1);
% For each trial
% Get gaze prop during trial, and gaze prop after trial
for r = 1:nT
    
    ts = stimLog.sTime(r);
    te = stimLog.eTime(r);
    if r == nT
        tsNext = stimLog.sTime(r)+0.0000001;
    else
        tsNext = stimLog.sTime(r+1);
    end
    
    tIdx = eyes.gaze.TS4>=ts & eyes.gaze.TS4<=te;
    tNextIdx = eyes.gaze.TS4>te & eyes.gaze.TS4<tsNext;
    
    % gs = gazeCorrected.onSurfED(tIdx);
    gs = eyes.gaze.onSurf(tIdx);
    gsGap = eyes.gaze.onSurf(tNextIdx);
    
    stimLog.nGazeSamples(r) = numel(gs);
    stimLog.onSurfProp(r) = nanmean(gs);
    stimLog.nGazeSamplesAfterThisTrial(r) = numel(gsGap);
    stimLog.onSurfPropAfterThisTrial(r) = nanmean(gsGap);

    % Trial indicator
    plot([ts,te], ...
        [1.001, 1.001], ...
        'LineWidth', 3)
    
    % During trial eye prop
    plot([ts,te], ...
        [stimLog.onSurfProp(r), ...
        stimLog.onSurfProp(r)], ...
        'LineWidth', 3, 'Color',  'k')
    
    % Prop-direction indicator line
    if stimLog.onSurfProp(r) > stimLog.onSurfPropAfterThisTrial(r)
        col = 'b';
        % If everything is working and subject is behaving,
        % expecting higher on target prop during trials, and less
        % when subject looks down to respond.
    else
        % Yellow if surface proportion is higher off trial than it
        % was during trial - will indicate spatial or temporal
        % drift, or subject errors.
        col = 'y';
    end
    
    plot([te,te], ...
        [stimLog.onSurfProp(r), ...
        stimLog.onSurfPropAfterThisTrial(r)], ...
        'LineWidth', 1, 'Color',  col)
    
    % Outside trial eye prop
    plot([te,tsNext], ...
        [stimLog.onSurfPropAfterThisTrial(r), ...
        stimLog.onSurfPropAfterThisTrial(r)], ...
        'LineWidth', 3, 'Color',  'r')
end
