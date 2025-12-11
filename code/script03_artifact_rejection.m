%script03_artifact_rejection

% 1. Handle flat channels
% 2. Handle bad segments
% 3. Average reference
% 4.(Optional) High-pass filter
% 5.(Optional) Baseline removal


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
check_quality_plot = 1;
%nthreads = min([prefs.max_threads, length(subjects)]);

%parfor(isub = 1:length(subjects), nthreads) % set nthreads to 0 for normal for loop.

for isub = 2%1:length(subjects1)

    % ----------------------------------------------------------
    % Load the dataset. This data was filtered and downsampled in
    % script02_simple_prep.m
    % ----------------------------------------------------------
    EEG = pop_loadset('filename', subjects(isub).name, 'filepath', subjects(isub).folder);
    EEG_orig = EEG;
        % ----------------------------------------------------------
    % Detect Bad Segments
    %
    % TO-DO: Setting the parameteres in cgf file ??
    %
    % ---------------------------------------------------------

    % The sliding window part
    % apply highpass of 25 for sliding window
    EEG_temp = pop_eegfiltnew(EEG, 'locutoff',25);

    % apply clean windows
    [~, cleaned_mask] = clean_windows(EEG_temp,0.25,[-12 12]);

    % ----------------------------------------------------------
    % Manual Review of Segment Rejection - under construction
    % ---------------------------------------------------------

    if cfg.rej.manual_segment_review == 1
        % Interactive manual review and modification of bad segments
        [cleaned_mask, rejected_segments] = func_manual_segment_rejection(EEG, cleaned_mask);
    end

    % ----------------------------------------------------------
    % Apply Final Segment Rejection Mask
    % ---------------------------------------------------------

    % get retained time intervals from cleaned mask
    retain_data_intervals = reshape(find(diff([false cleaned_mask false])),2,[])';
    retain_data_intervals(:,2) = retain_data_intervals(:,2)-1;

    % apply retained intervals to EEG data
    EEG_clean = pop_select(EEG,'point',retain_data_intervals);
    EEG_clean.etc.clean_sample_mask = cleaned_mask;

    % ----------------------------------------------------------
    % Detect & Remove Flat Channels
    % ----------------------------------------------------------
    % https://github.com/sccn/clean_rawdata/blob/master/clean_flatlines.m
    % max duration (by default 5s) of too little variation

    % Run clean_flatlines. Ignore the command output. We don't remove any
    % channels at this stage.
    [~, flat_channels_ind] = clean_flatlines(EEG_clean);

    % Get channel numbers: finds a reference channel
    flat_channels = find(flat_channels_ind);

    % Find the index of the reference channel
    ref_chan_idx = find(strcmp({EEG_clean.chanlocs.labels}, EEG_clean.ref));

    % Keep the reference channel by removing it from flat_channels
    flat_channels_to_remove = setdiff(flat_channels, ref_chan_idx);

    % ----------------------------------------------------------
    % Manual Channel Review
    %
    % Under construction - you can only remove additional channels
    % Claude
    % ---------------------------------------------------------

    if cfg.rej.manual_channel_review == 1
        % Interactive review: visualize and allow manual channel removal
        % base your decision on visual inspection of the PSD and time
        % series data
        figure,spectopo(EEG_clean.data(1:66,:), 0, EEG_clean.srate, 'freqrange', [1 cfg.prep.lp_filter_limit]);
        EEG_new = func_manual_channel_rejection(EEG_clean, flat_channels_to_remove);
    else
        % Automatic only: remove flagged flat channels
        EEG_new = pop_select(EEG_clean, 'nochannel', flat_channels_to_remove);
    end

    % ----------------------------------------------------------
    % Re-reference to average excluding eye channels
    % ----------------------------------------------------------

    EEG_new = pop_reref(EEG_new, [], 'keepref','on', 'exclude', [cfg.chans.VEOGchan cfg.chans.HEOGchan]);

    % ----------------------------------------------------------
    % Save:
    % ----------------------------------------------------------
    EEG_new = func_saveset(EEG_new, subjects(isub));

    % Length of recording in minutes for each subject
    rec_length_before(isub)=size(EEG_orig.data,2)/EEG_orig.srate/60;

    rec_length_after(isub)=size(EEG_new.data,2)/EEG_new.srate/60;

end

% If the qualitycheck folder  doesn't exist, we create it

if ~exist(cfg.dir.qualitycheck, 'dir')
    mkdir(cfg.dir.qualitycheck)
end

if check_quality_plot
    script_nr=3;
    rec_length.before = rec_length_before;
    rec_length.after = rec_length_after;
    get_quality_check(script_nr,{subjects.name},rec_length, flat_channels_to_remove, cfg)
    % add plots

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
end
disp('Script03: ICA prep is done.')
