% script01b_prep
% This script loads data in the EEGLAB format, filters it (except VEOG/HEOG
% channels), downsamples,

%% Set preferences, configuration and load list of subjects.
clear; clc; close all
restoredefaultpath
cfg = get_cfg;
detectEyeMovements = 0

%addpath('./functions/')
% dir_toolboxes = '/data3/alphaicon/tools/';
% eeglab_path = [dir_toolboxes, 'eeglab2023.0' filesep];
% dir_toolboxes = '/data3/Niko/buschlab-pipeline-dev/tools/';
% eeglab_path = [dir_toolboxes, 'eeglab' filesep];
% addpath(eeglab_path)
eeglab nogui

% ------------------------------------------------------------------------
% **Important**: these variables determine which data files are used as
% input and output.
suffix_in  = 'import';
suffix_out = ['prep'];
do_overwrite = true;
% ------------------------------------------------------------------------

subjects = get_list_of_subjects(cfg.dir, do_overwrite, suffix_in, suffix_out);

%% Run across subjects.
nthreads = min([cfg.system.max_threads, length(subjects)]);
% parfor(isub = 1:length(subjects), nthreads) % set nthreads to 0 for normal for loop.
for isub = 1:length(subjects)

    % ----------------------------------------------------------
    % Load the dataset.
    % ----------------------------------------------------------
    EEG = pop_loadset('filename', subjects(isub).name, 'filepath', subjects(isub).folder);

    % --------------------------------------------------------------
    % Filter the data.
    % --------------------------------------------------------------
    % Filters should happen before epoching. Also: we want to keep the
    % VEOG/HEOG and eye tracking data unfiltered to make sure they are not
    % distorted by the filter. We keep a copy here and then put it back
    % after filtering.
    tmp = EEG.data;
    nofilt_chans = max(cfg.chans.EEGchans)+1:EEG.nbchan;%indx of channels that should not be filtered
    EEG = func_import_filter(EEG, cfg.prep, cfg.dir);
    EEG.data(nofilt_chans,:) = tmp(nofilt_chans,:);
    EEG.data(nofilt_chans,:) = tmp(nofilt_chans,:);


    % --------------------------------------------------------------
    % Downsample data if required. IMPORTANT: use resampling only after
    % importing the eye tracking data, or else the ET data will not be in
    % sync with EEG data.
    % --------------------------------------------------------------
    EEG = func_import_downsample(EEG, cfg.prep);

    % --------------------------------------------------------------
    % Detect eye movements.
    % --------------------------------------------------------------

    % Saccade cue and memory cue are coded as cells, which throws an error when
    % EYE-EEG tries to update the event structure. Converting the cells to
    % simple strings.
    if detectEyeMovements
        for i = 1:length(EEG.event)
            if iscell(EEG.event(i).target_cue_w)
                EEG.event(i).target_cue_w = string(EEG.event(i).target_cue_w);
            end

            if iscell(EEG.event(i).saccade_cue_w)
                EEG.event(i).saccade_cue_w = string(EEG.event(i).saccade_cue_w);
            end
        end

        EEG = func_detect_eyemovements(EEG, cfg);
    end

    % --------------------------------------------------------------
    % Save the new EEG file in EEGLAB format.
    % --------------------------------------------------------------
    EEG = func_saveset(EEG, subjects(isub));

end

disp('Done.')
