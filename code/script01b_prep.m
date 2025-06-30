% script01b_prep
% This script loads data in the EEGLAB format, filters it (except VEOG/HEOG
% channels), and downsamples. It can detect saccades, but at the moment
% this function is specific to the ROSA study.

%% Set preferences, configuration and load list of subjects.
clear; clc; close all
restoredefaultpath
cfg = get_cfg;
detectEyeMovements = 0; % TALK:  What is this?

%addpath('./functions/')
% dir_toolboxes = '/data3/alphaicon/tools/';
% eeglab_path = [dir_toolboxes, 'eeglab2023.0' filesep];
% dir_toolboxes = '/data3/Niko/buschlab-pipeline-dev/tools/';
% eeglab_path = [dir_toolboxes, 'eeglab' filesep];
% addpath(eeglab_path)
eeglab nogui

%TALK:  Why there is data?


% ------------------------------------------------------------------------
% **Important**: these variables determine which data files are used as
% input and output.
suffix_in  = 'import';
suffix_out = ['prep'];
do_overwrite = true;
% ------------------------------------------------------------------------

subjects = get_list_of_subjects(cfg.dir, do_overwrite, suffix_in, suffix_out);

%% Run across subjects.
%nthreads = min([cfg.system.max_threads, length(subjects)]);
% parfor(isub = 1:length(subjects), nthreads) % set nthreads to 0 for normal for loop.
for isub = 1%:length(subjects)

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

    
    % ----------------------------------------------------------
    % Channel rejection
    % --------------------------------------------------------------



    % ----------------------------------------------------------
    % Artifact rejection.
    % Inputs: Signal,MaxBadChannels,PowerTolerances,WindowLength,WindowOverlap,MaxDropoutFraction,Min
    % ----------------------------------------------------------    
        
        if strcmpi(cfg.prep.bad_segment_reject, 'auto')

            % Find bad segments, do not reject?
            [EEG, EEG_bad] = clean_windows_ElenaAdjusted(EEG, 0.8);
        
        elseif strcmpi(cfg.prep.bad_segment_reject, 'manual')
           
            % Plot for manual rejection, and reject
            pop_eegplot(EEG, 1, 1, 1); 
            EEG_bad = TMPREJ; 
    
        else

            error('cfg.prep.bad_segment_reject must be ''auto'' or ''manual''.');

        end

     % Questions
     % Only save the bad segments? or directly reject
     % Turn it into a function

    % --------------------------------------------------------------
    % Save the new EEG file in EEGLAB format.
    % --------------------------------------------------------------
    EEG = func_saveset(EEG, subjects(isub));

    EEG_bad = pop_editset(EEG_bad, 'setname', [subjects(isub).namestr ' prep1 BAD TRIALS']);
    pop_saveset(EEG_bad, 'filename', ['bad' subjects(isub).outfile], 'filepath', subjects(isub).outdir);
end

disp('Done.')
