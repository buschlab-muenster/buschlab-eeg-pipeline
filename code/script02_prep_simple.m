%% Set preferences, configuration and load list of subjects.
clear; clc; close all

restoredefaultpath
prefs = get_prefs('eeglab_all', 1);
cfg   = get_cfg;

% ------------------------------------------------------------------------
% **Important**: these variables determine which data files are used as
% input and output. 
suffix_in  = 'import';
suffix_out = 'prep1';
do_overwrite = false;
% ------------------------------------------------------------------------

subjects = get_list_of_subjects(cfg.dir, do_overwrite, suffix_in, suffix_out);

%% Run across subjects.
nthreads = min([prefs.max_threads, length(subjects)]);
parfor(isub = 1:length(subjects), nthreads) % set nthreads to 0 for normal for loop.
% for isub = 1%:length(subjects)    
    
    % ----------------------------------------------------------
    % Load the dataset.
    % ----------------------------------------------------------
    EEG = pop_loadset('filename', subjects(isub).name, 'filepath', subjects(isub).folder);
        
    % --------------------------------------------------------------
    % Downsample data if required. IMPORTANT: use resampling only after
    % importing the eye tracking data, or else the ET data will not be in
    % sync with EEG data.
    % --------------------------------------------------------------
    EEG = func_import_downsample(EEG, cfg.prep);
               
    % ----------------------------------------------------------
    % Artifact rejection.
    % ----------------------------------------------------------
    
    % I do a temorary baseline correction, otherwise the rejection by
    % extreme amplitudes gets confused if there are still some DC
    % shifts in the raw data. However, we apply the trial rejection to
    % the un-baseline corrected data, because ICA likes that better.
    tmpeeg = pop_rmbase(EEG, [], [], cfg.chans.EEGchans);
    
    % Reject trials with extreme amplitude values.
    [tmpeeg, ~] = pop_eegthresh(tmpeeg, 1, cfg.chans.EEGchans, ...
        -cfg.rej.rejthresh_pre_ica, cfg.rej.rejthresh_pre_ica, EEG.xmin, EEG.xmax, 1, 0);
    
    % Temporary average reference. Necessary because joint prob. cannot
    % handle empty reference channel.
    if ~strcmp(tmpeeg.ref, 'averef')
        tmpeeg = pop_reref( tmpeeg, [], 'keepref','on','exclude', [max(cfg.chans.EEGchans)+1:EEG.nbchan]);
    end
    
    tmpeeg = pop_jointprob(tmpeeg, 1, cfg.chans.EEGchans, ...
        cfg.rej.rej_jp_singchan, cfg.rej.rej_jp_allchans, 1, 0, 0);
    
    rejinds = find(tmpeeg.reject.rejthresh | tmpeeg.reject.rejjp);
    
    % Reject those bad trials from the raw data.
    EEGbad = eeg_emptyset; % Initialize with an empyt set in case no bad trials are found.
    if ~isempty(rejinds)
        EEGbad = pop_select( EEG, 'trial',   rejinds);
        EEG    = pop_select( EEG, 'notrial', rejinds);
    end
    EEG.rejected_trials = rejinds;
        
    % ----------------------------------------------------------
    % Change the EEG.setname and save the data to disk under a new name.
    % ----------------------------------------------------------
    EEG = func_saveset(EEG, subjects(isub));

    EEGbad = pop_editset(EEGbad, 'setname', [subjects(isub).namestr ' prep1 BAD TRIALS']);
    pop_saveset(EEGbad, 'filename', ['bad' subjects(isub).outfile], 'filepath', subjects(isub).outdir);
    
end

disp('Done.')
