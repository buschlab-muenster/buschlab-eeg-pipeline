%script03_ica_prep

% Set preferences, configuration and load list of subjects.
clear; clc; close all

restoredefaultpath
cfg = get_cfg;

eeglab nogui

addpath(fullfile(cfg.dir.eeglab,'plugins','erplab', 'pop_functions'))
addpath(fullfile(cfg.dir.eeglab,'plugins','erplab', 'functions'))

% Steps in the script:
% 1. Handle bad channels 
% 2. Handle bad segments 
% 3. Optional high-pass filter

% Keep the data continuous 

% ------------------------------------------------------------------------
% **Important**: these variables determine which data files are used as
% input and output.
suffix_in  = 'simple_prep';
do_overwrite = true;
suffix_out = 'ica_prep';


%% ------------------------------------------------------------------------

subjects = get_list_of_subjects(cfg.dir, do_overwrite, suffix_in, suffix_out);

%% Run across subjects.

%nthreads = min([prefs.max_threads, length(subjects)]);

%parfor(isub = 1:length(subjects), nthreads) % set nthreads to 0 for normal for loop.

for isub = 5%1:length(subjects)

    % ----------------------------------------------------------
    % Load the dataset. This data was filtered and downsampled in
    % script02_simple_prep.m
    % ----------------------------------------------------------
    EEG = pop_loadset('filename', subjects(isub).name, 'filepath', subjects(isub).folder);

    EEG = pop_select(EEG, 'nochannel', [68:80]);

    pop_eegplot(EEG)

    % ----------------------------------------------------------
    % Detect Bad Channels:
    % Ekin had to make a small change to the function so it can output flagged channels 
    % ----------------------------------------------------------
    % https://github.com/sccn/clean_rawdata/blob/master/clean_flatlines.m

    % max duration (by default 5s) of too little variation 

    [EEG_chan_rmv, flat_channels] = clean_flatlines(EEG);

    % visualise 
    vis_artifacts(EEG_chan_rmv, EEG);

   

    % ask 

    % remove

    EEG = EEG_chan_rmv;

    % ----------------------------------------------------------
    % Detect Bad Segments
    % ---------------------------------------------------------


    %% The sliding window part
    % apply highpass of 20 for sliding window
    EEG_temp = pop_eegfiltnew(EEG, 'locutoff',20);
    
    % apply sliding window
    [~, cleaned_mask] = clean_windows(EEG_temp,0.25,[-12 12]);

    % get removed time intervals from cleaned mask
    retain_data_intervals = reshape(find(diff([false cleaned_mask false])),2,[])';
    retain_data_intervals(:,2) = retain_data_intervals(:,2)-1;
    
    % apply removed intervals to EEG data
    EEG_clean = pop_select(EEG,'point',retain_data_intervals);
    EEG_clean.etc.clean_sample_mask = cleaned_mask;
    
    % visualize
    vis_artifacts(EEG_clean, EEG);

    % ask
  

    % remove


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

disp('Script03: ICA prep is done.')
