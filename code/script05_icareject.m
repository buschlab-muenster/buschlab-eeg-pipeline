%% Set preferences, configuration and load list of subjects.
clear; clc; close all
restoredefaultpath
cfg   = get_cfg;
eeglab nogui


addpath(fullfile(cfg.dir.eeglab,'plugins','ICLabel'))
%%
% ------------------------------------------------------------------------
% **Important**: these variables determine which data files are used as
% input and output. 
suffix_in  = 'ica_weighted';
suffix_out = 'ica_clean';
do_overwrite = true;
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
%nthreads = min([prefs.max_threads, length(subjects)]);
%parfor(isub = 1:length(subjects), nthreads) % Use this if you do NOT use manual confirmation

for isub = 3%:length(subjects) 
    
    % --------------------------------------------------------------
    % Load the dataset and initialize the list of bad ICs.
    % --------------------------------------------------------------
    EEG = pop_loadset('filename', subjects(isub).name, 'filepath', subjects(isub).folder);
   

    % Baseline correction? 
   
    %EEG = pop_rmbase(EEG, [], []);

    [bad_ics_eog, bad_ics_eyetracker, bad_ics_iclabel] = deal(zeros(length(EEG.reject.gcompreject), 1));
   
   
    % --------------------------------------------------------------
    % Reject ICs that correlate with HEOG/VEOG.
    % --------------------------------------------------------------
    if cfg.icareject.do_correlate_eog==true
        fprintf('Detecting ICs that correlate with EOG channels > %2.2f\n', ...
            cfg.icareject.thresh_correlate_eog)
        
        [bad_ics_eog, ~] = func_icareject_corr_ic_eog(EEG, ...
            [cfg.chans.HEOGchan cfg.chans.VEOGchan], ...
            cfg.icareject.thresh_correlate_eog);
    end
    
    % --------------------------------------------------------------
    % Reject ICs that correlate with eye tracker.
    % IMPORTANT: you can only use this if the data are not resampled,
    % see documentation of pop_eyetrackerica!
    % --------------------------------------------------------------
    if cfg.icareject.do_eyetrackerica==true && cfg.prep.do_resampling==false
        fprintf('Detecting ICs that correlate with eye tracker.\n')
        [bad_ics_eyetracker] = func_icareject_eyetrackerica(EEG, cfg.icareject);
    end
    
    
    % --------------------------------------------------------------
    % Detect bad ICs with IC label. %TODO more explanation here
    % --------------------------------------------------------------
    
    EEG = pop_select(EEG, 'channel', cfg.chans.EEGchans);

    EEG = pop_chanedit(EEG, 'lookup', cfg.chans.chanlocs_standard);

    if cfg.icareject.do_iclabel==true
   
        fprintf('Detecting ICs with IClabel.\n')
        [EEG, bad_ics_iclabel] = func_icareject_iclabel(EEG, cfg.icareject, bad_ics_eog);
    end
    
    
    % --------------------------------------------------------------
    % Now that all detection procedures are finished, update the list 
    % of bad ICs. This is important so that the manual inspection shows 
    % bad ICs flagged by any of the procedures.
    % --------------------------------------------------------------
    
    %flag_ics = [bad_ics_iclabel | bad_ics_eog | bad_ics_eyetracker];
    flag_ics = bad_ics_iclabel;
    EEG.reject.gcompreject = flag_ics;
    
    
    % --------------------------------------------------------------
    % Manual inspection.
    % --------------------------------------------------------------
    if cfg.icareject.confirm_manual
       pop_viewprops( EEG, 0, [1:length(EEG.reject.gcompreject)], {'freqrange', [2 80]}, {}, 1, 'ICLabel' )
       % TO-DO store component information or remove directly? 
    end      


    % --------------------------------------------------------------
    % Finally subtract all bad components.
    % --------------------------------------------------------------
    remove_ics = find(EEG.reject.gcompreject);
    fprintf('Removing %d components:\n', length(remove_ics))
    fprintf(' %g', remove_ics)
    fprintf('.\n')
    
    if cfg.icareject.confirm_manual        
        EEG = pop_subcomp(EEG, [], 1);
    else
        EEG = pop_subcomp(EEG, remove_ics, 0);
    end
        
    
    % --------------------------------------------------------------
    % Save clean data.
    % --------------------------------------------------------------
    EEG = func_saveset(EEG, subjects(isub));

end

disp('Done.')
