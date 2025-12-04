%script03_artifact_rejection

% 1. Handle flat channels 
% 2. Handle bad segments 
% 3. Average reference
% 4. (Optional) High-pass filter

% Set preferences, configuration and load list of subjects.
clear; clc; close all

restoredefaultpath
cfg = get_cfg;

eeglab nogui

addpath(fullfile(cfg.dir.eeglab,'plugins','erplab', 'pop_functions'))
addpath(fullfile(cfg.dir.eeglab,'plugins','erplab', 'functions'))

% ------------------------------------------------------------------------
% **Important**: these variables determine which data files are used as
% input and output.
suffix_in  = 'simple_prep';
do_overwrite = true;
suffix_out = 'artifact_free';

%% ------------------------------------------------------------------------

subjects = get_list_of_subjects(cfg.dir, do_overwrite, suffix_in, suffix_out);

%% Run across subjects.

%nthreads = min([prefs.max_threads, length(subjects)]);

%parfor(isub = 1:length(subjects), nthreads) % set nthreads to 0 for normal for loop.

for isub = 1%1:length(subjects1)

    % ----------------------------------------------------------
    % Load the dataset. This data was filtered and downsampled in
    % script02_simple_prep.m
    % ----------------------------------------------------------
    EEG = pop_loadset('filename', subjects(isub).name, 'filepath', subjects(isub).folder);
    
    % ----------------------------------------------------------
    % Detect & Remove Flat Channels
    % ----------------------------------------------------------
    % https://github.com/sccn/clean_rawdata/blob/master/clean_flatlines.m
    % max duration (by default 5s) of too little variation 

    % Run clean_flatlines. Ignore the command output. We don't remove any
    % channels at this stage.
    [~, flat_channels_ind] = clean_flatlines(EEG);
    
    % Get channel numbers
    flat_channels = find(flat_channels_ind);
    
    % Find the index of the reference channel
    ref_chan_idx = find(strcmp({EEG.chanlocs.labels}, EEG.ref));
    
    % Keep the reference channel by removing it from flat_channels
    flat_channels_to_remove = setdiff(flat_channels, ref_chan_idx);
    
    % Remove only the flat channels that are NOT the reference
    EEG_chan_rmv = pop_select(EEG, 'nochannel', flat_channels_to_remove);
   
    % visualise - Ekin change default plotting settings of vis_artifacts to
    % 30s window length and scale to  2 SD
    % distance of the channel time series from each other in std. deviations
    % still need to change x-axis tick labels

    vis_artifacts(EEG_chan_rmv, EEG);

    % ----------------------------------------------------------
    % Detect Bad Segments
    % ---------------------------------------------------------

    % The sliding window part
    % apply highpass of 20 for sliding window
    EEG_temp = pop_eegfiltnew(EEG_chan_rmv, 'locutoff',25);
    
    % apply sliding window
    [~, cleaned_mask] = clean_windows(EEG_temp,0.25,[-10 10]);

    % get removed time intervals from cleaned mask
    retain_data_intervals = reshape(find(diff([false cleaned_mask false])),2,[])';
    retain_data_intervals(:,2) = retain_data_intervals(:,2)-1;
    
    % apply removed intervals to EEG data
    EEG_clean = pop_select(EEG,'point',retain_data_intervals);
    EEG_clean.etc.clean_sample_mask = cleaned_mask;
    
    % visualize
    vis_artifacts(EEG_clean, EEG);

    % ask
 

    % ----------------------------------------------------------
    % Re-reference to average
    % ----------------------------------------------------------
   
    EEG_clean = pop_reref(EEG_clean, [], 'keepref','on', 'exclude', [cfg.chans.VEOGchan cfg.chans.HEOGchan]);

    % ----------------------------------------------------------
    % Save:
    % ----------------------------------------------------------
    EEG_clean = func_saveset(EEG_clean, subjects(isub));

    % Length of recording in minutes for each subject
    rec_length_before(isub)=size(EEG.data,2)/EEG.srate/60;

    rec_length_after(isub)=size(EEG_clean.data,2)/EEG_clean.srate/60;

end

% If the qualitycheck folder  doesn't exist, we create it 

if ~exist(cfg.dir.qualitycheck, 'dir')
    mkdir(cfg.dir.qualitycheck)
end


msg = sprintf(['\n%s\nreport from script03_artifact_rejection\n' ...
    'Data directory: %s\n' ...
    'Processed subjects: %s\n' ...
    'Flat channels: %s\n' ...
    'Number of flat channels: %d\n' ...
    'Duration before artifact rejection (minutes): %.4f\n' ...
    'Duration after artifact rejection (minutes): %.4f\n' ...
    'Keeping %.1f%% of the data.\n'], ...
    datestr(datetime), ...
    cfg.dir.main, ...
    strjoin({subjects.name}, ', '), ...
    num2str(flat_channels_to_remove), ...
    length(flat_channels_to_remove), ...
    rec_length_before, ...
    rec_length_after, ...
    rec_length_after/rec_length_before*100);

fileID = fopen([cfg.dir.qualitycheck, 'project_report.txt'], 'a+');
fprintf(fileID, '%s', msg);
fclose(fileID);

removed = rec_length_before - rec_length_after;

% Each row = participant
data = [rec_length_after(:),removed(:)];  % N x 2

if length(subjects) == 1
    data = [data;NaN NaN];
end 

fig_length = figure('Visible','off');
b = bar(data, 'stacked');  % stacked bars
xlabel('Participants', 'FontSize', 14)
ylabel('Recording length (min)', 'FontSize', 14)

% Save figure
saveas(fig_length, fullfile(cfg.dir.qualitycheck, 'recording_length_before_after_artifact_rejection.png'))

disp('Script03: ICA prep is done.')
