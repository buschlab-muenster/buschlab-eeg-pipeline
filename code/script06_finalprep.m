%% Set preferences, configuration and load list of subjects.
%% Set preferences, configuration and load list of subjects.
clear; clc; close all
restoredefaultpath
cfg   = get_cfg;
eeglab nogui

detectEyeMovements = 0;
% ------------------------------------------------------------------------
% **Important**: these variables determine which data files are used as
% input and output. 
suffix_in  = 'ica_clean';
suffix_out = 'final';
do_overwrite = false;
% ------------------------------------------------------------------------

subjects = get_list_of_subjects(cfg.dir, do_overwrite, suffix_in, suffix_out);

%% Run across subjects.
%nthreads = min([1, prefs.max_threads, length(subjects)]);
%parfor(isub = 4:length(subjects), nthreads)
for isub = 2%:length(subjects)
    
    % --------------------------------------------------------------
    % Load the dataset and initialize the list of bad ICs.
    % --------------------------------------------------------------
    EEG = pop_loadset('filename', subjects(isub).name, 'filepath', subjects(isub).folder);    

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
    
    % -------------------------------------------------------------
    % Epoch data.
    % --------------------------------------------------------------
    EEG = func_import_epoch(EEG, cfg.epoch, cfg.eyetrack.coregister_Eyelink);

    % baseline correct the data
    EEG = pop_rmbase(EEG, [-100 0], [], cfg.chans.EEGchans);
    %EEG = eeg_detrend(EEG);   

     % --------------------------------------------------------------
     % Optional interpolation of bad channels, defined as channels with
     % large standard deviation.
     % --------------------------------------------------------------
    if cfg.final.do_channel_interp
       EEG = func_final_channelinterp(EEG, joinstructs(cfg.chans, cfg.final));         
    end    

    % --------------------------------------------------------------
    % Do a last round of trial rejection to get rid of trials with huge
    % amplitudes. This important for a few datasets with strong sweat
    % artifacts. TO-DO: visualize rejected trials 
    % --------------------------------------------------------------
    [EEG, trials_rejected] = pop_eegthresh(EEG, 1, cfg.chans.EEGchans, ...
        -cfg.final.rejthresh_post_ica, cfg.final.rejthresh_post_ica, ...
        EEG.xmin, EEG.xmax, 1, 1);
    
    EEG.rejected_trials = trials_rejected;
    
    % --------------------------------------------------------------
    % Import behavioral data.
    % --------------------------------------------------------------
    EEG = func_import_behavior(EEG, subjects(isub).namestr, cfg.dir, cfg.epoch);

    % --------------------------------------------------------------
    % Save data.
    % --------------------------------------------------------------    
    EEG = func_saveset(EEG, subjects(isub));
    
end
disp('Done.')
