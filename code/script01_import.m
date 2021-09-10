%% Set preferences, configuration and load list of subjects.
clear; clc; close all

restoredefaultpath
prefs = get_prefs('eeglab_all', 1);
cfg   = get_cfg;

% ------------------------------------------------------------------------
% **Important**: these variables determine which data files are used as
% input and output. 
suffix_in  = '';
suffix_out = 'import';
do_overwrite = false;
% ------------------------------------------------------------------------

subjects = get_list_of_subjects(cfg.dir, do_overwrite, suffix_in, suffix_out);

%% Run across subjects.
nthreads = min([prefs.max_threads, length(subjects)]);
parfor(isub = 1:length(subjects), nthreads) % set nthreads to 0 for normal for loop.
% for isub = 1:length(subjects)
    
    if ~exist(subjects(isub).outdir, 'dir')
        mkdir(subjects(isub).outdir)
    end
    
    % --------------------------------------------------------------
    % Import Biosemi raw data.
    % --------------------------------------------------------------
    EEG = func_import_readbdf(cfg.dir, subjects(isub).name);
    
    % !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    % This is a patch for ROSA3: for some subjects, the time lag between
    % recording start and first trial onset is too short for the long
    % baseline we require for epoching, so the first trials is dropped.
    % This creates a huge headache because then the numbers of trials in
    % EEG and logfile do not match. To fix this, I append a little bit of
    % data at the beginning of each file.
    % !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    nsecs = 5;
    EEG = func_import_patchdata(EEG, nsecs);
    
    % --------------------------------------------------------------
    % Select data channels.
    % --------------------------------------------------------------
    EEG = func_import_selectchans(EEG, cfg.chans);
    
    % --------------------------------------------------------------
    % Compute VEOG and HEOG.
    % --------------------------------------------------------------
    EEG = func_import_eyechans(EEG, cfg.chans);
    
    % --------------------------------------------------------------
    % Downsample data if required.
    % --------------------------------------------------------------
    EEG = func_import_downsample(EEG, cfg.prep);
    
    % --------------------------------------------------------------
    % Biosemi is recorded reference-free. We apply rereferencing in
    % software.
    % --------------------------------------------------------------
    EEG = func_import_reref(EEG, cfg.prep);
    
    % --------------------------------------------------------------
    % Filter the data.
    % --------------------------------------------------------------
    % We want to keep the VEOG/HEOG data unfiltered to make sure they
    % are not distorted by the filter. We keep a copy here and then put
    % it back after filtering.
    tmp = EEG.data;
    EEG = func_import_filter(EEG, cfg.prep);
    EEG.data(cfg.chans.VEOGchan,:) = tmp(cfg.chans.VEOGchan,:);
    EEG.data(cfg.chans.HEOGchan,:) = tmp(cfg.chans.HEOGchan,:);
    
    %---------------------------------------------------------------
    % Remove all events from non-configured trigger devices
    %---------------------------------------------------------------
    EEG = func_import_remove_triggers(EEG, cfg.epoch);
    
    % --------------------------------------------------------------
    % Import Eyetracking data.
    % --------------------------------------------------------------
    EEG = func_import_importEye(EEG, subjects(isub).namestr, cfg.dir, cfg.eyetrack);
    
    % -------------------------------------------------------------
    % Epoch data.
    % --------------------------------------------------------------
    EEG = func_import_epoch(EEG, cfg.epoch, cfg.eyetrack.coregister_Eyelink);
    EEG = pop_rmbase(EEG, [], []);
    
    % --------------------------------------------------------------
    % Import behavioral data.
    % --------------------------------------------------------------
    EEG = func_importBehavior(EEG, subjects(isub).namestr, cfg.dir, cfg.epoch);
    
    % --------------------------------------------------------------
    % Save the new EEG file in EEGLAB format.
    % --------------------------------------------------------------
    EEG = func_saveset(EEG, subjects(isub));
    
end

disp('Done.')
