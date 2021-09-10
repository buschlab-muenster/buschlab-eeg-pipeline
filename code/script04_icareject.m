%% Set preferences, configuration and load list of subjects.
clear; clc; close all

restoredefaultpath
prefs = get_prefs('eeglab_all', 1);
cfg   = get_cfg;

% ------------------------------------------------------------------------
% **Important**: these variables determine which data files are used as
% input and output. 
suffix_in  = 'ica';
suffix_out = 'icaclean';
do_overwrite = false;
% ------------------------------------------------------------------------

subjects = get_list_of_subjects(cfg.dir, do_overwrite, suffix_in, suffix_out);

% ------------------------------------------------------------------------
% Set defaults for ICA rejection fields in case they are not set in the
% cfg. This makes processing easier in the main loop.
% ------------------------------------------------------------------------
icareject_fields = {'do_correlate_eog', 'do_eyetrackerica', 'do_iclabel'};
for i = 1:length(icareject_fields)
    if ~isfield(cfg.icareject, icareject_fields{i})
        cfg.icareject = setfield(cfg.icareject, icareject_fields{i}, false);
    end
end

%% Run across subjects.
for isub = 1:length(subjects)
    
    
    % --------------------------------------------------------------
    % Load the dataset and initialize the list of bad ICs.
    % --------------------------------------------------------------    
    [ALLEEG EEG CURRENTSET ALLCOM] = eeglab;
    EEG = pop_loadset('filename', subjects(isub).name, 'filepath', subjects(isub).folder);
    [ALLEEG, EEG, CURRENTSET] = eeg_store( ALLEEG, EEG, 0 );
    
    [bad_ics_eog, bad_ics_eyetracker, bad_ics_iclabel] = deal([]);
    
    % --------------------------------------------------------------
    % Reject ICs that correlate with HEOG/VEOG..
    % --------------------------------------------------------------
    %     if cfg.icareject.do_correlate_eog==true
    %         [bad_ics_eog, ~] = func_icareject_corr_ic_eog(EEG, ...
    %             [cfg.chans.HEOGchan cfg.chans.VEOGchan], ...
    %             cfg.icareject.thresh_correlate_eog);
    %     end
    
    % --------------------------------------------------------------
    % Reject ICs that correlate with eye tracker.
    % IMPORTANT: you can only use this if the data are not resampled,
    % see documentation of pop_eyetrackerica!
    % --------------------------------------------------------------
    % if cfg.icareject.do_eyetrackerica==true && cfg.prep.do_resampling==false
    %     [bad_ics_eyetracker] = func_icareject_eyetrackerica(EEG, cfg.icareject);
    % end
    
    % --------------------------------------------------------------
    % Detect bad ICs with IC label.
    % --------------------------------------------------------------
    if cfg.icareject.do_iclabel==true
        EEG = func_icareject_iclabel(EEG, cfg.icareject, bad_ics_eog);
    end
    
    % --------------------------------------------------------------
    % Manual inspection.
    % --------------------------------------------------------------
    EEG = func_icareject_manualinspect(EEG);
    
    % --------------------------------------------------------------
    % Finally subtract all bad components.
    % --------------------------------------------------------------
    EEG = pop_subcomp(EEG, [], 1);
    
    % --------------------------------------------------------------
    % Save clean data.
    % --------------------------------------------------------------    
    EEG = func_saveset(EEG, subjects(isub));

end

disp('Done.')
