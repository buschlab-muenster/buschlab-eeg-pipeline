%% Set preferences, configuration and load list of subjects.
clear; clc; close all

restoredefaultpath
prefs = get_prefs('eeglab_all', 0); 
cfg   = get_cfg;

% ------------------------------------------------------------------------
% **Important**: these variables determine which data files are used as
% input and output. 
suffix_in  = 'icaclean';
suffix_out = 'final';
do_overwrite = false;
% ------------------------------------------------------------------------

subjects = get_list_of_subjects(cfg.dir, do_overwrite, suffix_in, suffix_out);

%% Run across subjects.
nthreads = min([1, prefs.max_threads, length(subjects)]);
parfor(isub = 1:length(subjects), nthreads)
% for isub = 1%:length(subjects)
    
    % --------------------------------------------------------------
    % Load the dataset and initialize the list of bad ICs.
    % --------------------------------------------------------------
    EEG = pop_loadset('filename', subjects(isub).name, 'filepath', subjects(isub).folder);    
     
    EEG = pop_rmbase(EEG, [], [], cfg.chans.EEGchans);
    EEG = eeg_detrend(EEG);   

%     EEG = pop_reref(EEG, [], 'keepref','on', ...
%         'exclude',[max(cfg.chans.EEGchans)+1:EEG.nbchan] );

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
    % artifacts.
    % --------------------------------------------------------------
    [EEG, i] = pop_eegthresh(EEG, 1, cfg.chans.EEGchans, ...
        -cfg.final.rejthresh_post_ica, cfg.final.rejthresh_post_ica, ...
        EEG.xmin, EEG.xmax, 1, 1);
    
    EEG.rejected_trials = [EEG.rejected_trials i];
    
    
    % --------------------------------------------------------------
    % Save data.
    % --------------------------------------------------------------    
    EEG = func_saveset(EEG, subjects(isub));
    
end
disp('Done.')
