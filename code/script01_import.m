%% Set preferences, configuration and load list of subjects.
clear; clc; close all

restoredefaultpath
prefs = get_prefs;
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
% parfor(isub = 1:length(subjects), nthreads) % set nthreads to 0 for normal for loop.
for isub = 5:length(subjects)
    
    if ~exist(subjects(isub).outdir, 'dir')
        mkdir(subjects(isub).outdir)
    end
    
    % --------------------------------------------------------------
    % Import Biosemi raw data.
    % --------------------------------------------------------------
    EEG = func_import_readbdf(cfg.dir, subjects(isub).name);
    
    
    % --------------------------------------------------------------
    % Select data channels.
    % --------------------------------------------------------------
    
    % Hack for renaming incorrectly labeled channel in AlphaIcon.
    EEG.chanlocs(66).labels = 'AFp9';
    EEG.chanlocs(67).labels = 'AFp10';

    EEG = func_import_selectchans(EEG, cfg.chans);
    
    % Use this line to verify the accuracy of channel labels and locations.
    % figure; topoplot([],EEG.chanlocs,'style','blank','electrodes','labelpoint','chaninfo',EEG.chaninfo);

    % --------------------------------------------------------------
    % Biosemi is recorded reference-free. We apply rereferencing in
    % software.
    % --------------------------------------------------------------
    EEG = func_import_reref(EEG, cfg.prep);
    
    % --------------------------------------------------------------
    % Compute VEOG and HEOG.
    % --------------------------------------------------------------
    EEG = func_import_eyechans(EEG, cfg.chans);
    
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
    
    % --------------------------------------------------------------
    % Downsample data if required. IMPORTANT: use resampling only after
    % importing the eye tracking data, or else the ET data will not be in
    % sync with EEG data.
    % --------------------------------------------------------------
    EEG = func_import_downsample(EEG, cfg.prep);
               
    % -------------------------------------------------------------
    % Epoch data.
    % --------------------------------------------------------------
    EEG = func_import_epoch(EEG, cfg.epoch, cfg.eyetrack.coregister_Eyelink);
    %     EEG = pop_rmbase(EEG, [], []);
        
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
