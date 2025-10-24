%script03_ica_prep

% Set preferences, configuration and load list of subjects.
clear; clc; close all

restoredefaultpath
cfg = get_cfg;

eeglab nogui

addpath(fullfile(cfg.dir.eeglab,'plugins','erplab', 'pop_functions'))
addpath(fullfile(cfg.dir.eeglab,'plugins','erplab', 'functions'))

% Steps in the script:
% 1. Optional high-pass filter
% 2. Handle bad channels 
% 3. Handle bad segments 

% Keep the data continuous 

% ------------------------------------------------------------------------
% **Important**: these variables determine which data files are used as
% input and output.
suffix_in  = 'simple_prep';
do_overwrite = true;
suffix_out = 'ICA_ready';

% ------------------------------------------------------------------------
% Question: What about the reference channel?



%% ------------------------------------------------------------------------

subjects = get_list_of_subjects(cfg.dir, do_overwrite, suffix_in, suffix_out);

%% Run across subjects.

%nthreads = min([prefs.max_threads, length(subjects)]);

%parfor(isub = 1:length(subjects), nthreads) % set nthreads to 0 for normal for loop.

for isub = 1%4%1:length(subjects)

    % ----------------------------------------------------------
    % Load the dataset. This data was filtered and downsampled in
    % script02_simple_prep.m
    % ----------------------------------------------------------
    EEG = pop_loadset('filename', subjects(isub).name, 'filepath', subjects(isub).folder);

    % ----------------------------------------------------------
    % Remove channels that were NOT specified in cfg.chans.EEGchans
    % ----------------------------------------------------------

    %cfg.chans.EEGchans = 1:30;
    %EEG = pop_select(EEG, 'channel', cfg.chans.EEGchans);

    % ----------------------------------------------------------
    % Add channel layout for the example data (this step will be later
    % removed) - DO we add layout anywhere? Do we need to?
    % ----------------------------------------------------------

    %EEG = pop_chanedit(EEG, 'lookup', cfg.chans.chanlocs_standard);

    % ----------------------------------------------------------
    % I had to make a small change to the function so it can output flagged
    % channels - for sanity check - it detects the reference channel
    % ----------------------------------------------------------

    % https://github.com/sccn/clean_rawdata/blob/master/clean_flatlines.m

    % max duration (by default 5s) of too little variation 

    [~, removed_channels] = clean_flatlines(EEG);

    find(removed_channels==1)
    
    cfg.prep.reref_chan

    [windowTimes, windowData] = visualize_random_windows(EEG, find(removed_channels==1), 100, 9, 42);

    % ----------------------------------------------------------
    % Detecting bad segments
    % ----------------------------------------------------------

    [newEEG,sample_mask] = clean_windows(EEG);

    % ----------------------------------------------------------
    % Visualisation
    % ----------------------------------------------------------
  
     [h_old,h_new] = vis_artifacts(newEEG,EEG);

     pop_eegplot(newEEG)

    % --------------------------------------------------------------
    % High Pass Filter
    %
    % If requested, perform ICA on strongly HP filtered data ==> more
    % stable results. 
    % 10.1109/EMBC.2015.7319296
    % ---------------------------------------------------------------

    if cfg.ica.do_ICA_hp_filter
        switch(cfg.ica.hp_ICA_filter_type)
            case('butterworth')
                EEG  = pop_basicfilter(EEG, cfg.chans.EEGchans, ...
                    'Cutoff',  1, ... %cfg.ica.hp_ICA_filter_limit, ... %  2 hz 
                    'Design', 'butter', 'Filter', 'highpass', 'Order',  2 );
        end
    end

end

    % ----------------------------------------------------------
    % Remove reference channel - which is all zeros now
    % 
    % ----------------------------------------------------------

    EEG = pop_select(EEG, 'nochannel', cfg.prep.reref_chan);

disp('Script03: ICA prep is done.')
