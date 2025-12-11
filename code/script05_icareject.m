% script05_icareject.m
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
suffix_in  = 'ica';
suffix_out = 'ica_clean';
do_overwrite = true;
% ------------------------------------------------------------------------

subjects = get_list_of_subjects(cfg.dir, do_overwrite, suffix_in, suffix_out);

%% Run across subjects.
check_quality_plot = 1;
%nthreads = min([prefs.max_threads, length(subjects)]);
%parfor(isub = 1:length(subjects), nthreads) % Use this if you do NOT use manual confirmation

for isub = 2%:length(subjects) 
    
    % --------------------------------------------------------------
    % Load the dataset and initialize the list of bad ICs.
    % --------------------------------------------------------------
    EEG = pop_loadset('filename', subjects(isub).name, 'filepath', subjects(isub).folder);

    % Initialize bad IC vectors based on actual number of ICs
    [bad_ics_eog, bad_ics_eyetracker, bad_ics_iclabel] = deal(zeros(size(EEG.icaweights, 1), 1));
  
    % --------------------------------------------------------------
    % Reject ICs that correlate with HEOG/VEOG.
    % --------------------------------------------------------------
    if cfg.icareject.do_correlate_eog==true
        fprintf('Detecting ICs that correlate with EOG channels > %2.2f\n', ...
            cfg.icareject.thresh_correlate_eog)

        [bad_ics_eog, ~] = func_icareject_corr_ic_eog(EEG, ...
            [cfg.chans.VEOGchan cfg.chans.HEOGchan], ...
            cfg.icareject.thresh_correlate_eog);

    end

    % --------------------------------------------------------------
    % Reject ICs that correlate with eye tracker.
    % IMPORTANT: you can only use this if the data are not resampled,
    % see documentation of pop_eyetrackerica!
    %
    % We need to change the output to make it compatible with others 
    % --------------------------------------------------------------
    if cfg.icareject.do_eyetrackerica==true && cfg.prep.do_resampling==false
        fprintf('Detecting ICs that correlate with eye tracker.\n')
        [bad_ics_eyetracker] = func_icareject_eyetrackerica(EEG, cfg.icareject);
    end
    
    % --------------------------------------------------------------
    % Detect bad ICs with IC label. 
    % --------------------------------------------------------------
   
    if cfg.icareject.do_iclabel == 1
        fprintf('Detecting ICs with IClabel.\n')
        [EEG, bad_ics_iclabel] = func_icareject_iclabel(EEG, cfg.icareject, bad_ics_eog);
    end
    
    % --------------------------------------------------------------
    % Now that all detection procedures are finished, update the list
    % of bad ICs. This is important so that the manual inspection shows
    % bad ICs flagged by any of the procedures.
    % --------------------------------------------------------------

    % Combine all detection methods
    flag_ics = bad_ics_iclabel | bad_ics_eog | bad_ics_eyetracker;
    EEG.reject.gcompreject = flag_ics;
  
    
    % --------------------------------------------------------------
    % Manual inspection.
    %
    % pop_viewprops allows us to see extended  view of components
    % func_select_components provides simple selection GUI without globals
    % --------------------------------------------------------------
    if cfg.icareject.confirm_manual == 1
        % Show detailed component properties
        %pop_viewprops(EEG, 0, [find(EEG.reject.gcompreject==1)]', 'ICLabel' ) % see only flagged components 
        pop_viewprops(EEG, 0, 1:size(EEG.icaweights,1), 'ICLabel') % see all components
        % Use custom selection GUI (thanks claude)
        EEG.reject.gcompreject = func_select_components(EEG, EEG.reject.gcompreject);
        close all
    end

    % --------------------------------------------------------------
    % Finally subtract all bad components. 
    % --------------------------------------------------------------

    remove_ics = find(EEG.reject.gcompreject);
    fprintf('Removing %d components:\n', length(remove_ics))
    fprintf(' %g', remove_ics)
    fprintf('.\n')
    removed_nr_components(isub)= length(remove_ics);
    EEG_clean = pop_subcomp(EEG, remove_ics, 0);
    
    % --------------------------------------------------------------
    % Before vs after ICA 
    % The red lines are the old data and the blue lines is the data
    % corrected after the IC rejection. What to look for: check if the eye
    % blinks have been corrected, try to find alpha activity and check if
    % it's amplitude has been supressed, check if slow drifts have been corrected.
    % - Make it optional for fully automatic: Maybe put under cfg.icareject.confirm_manual ???
    % - We can do this before substracting bad components and 
    % see how the data changes before we commit to it?
    % --------------------------------------------------------------

    figs_before = get(0, 'Children');  
    fprintf('Close the visualization window when done reviewing.\n');
    vis_artifacts(EEG_clean, EEG);
    %pop_eegplot(EEG_clean, 0, 0, 0)
    pause(0.5);
    new_figs = setdiff(get(0, 'Children'), figs_before);
    if ~isempty(new_figs)
        waitfor(new_figs(1));
    end
         
    % --------------------------------------------------------------
    % Save clean data.
    % --------------------------------------------------------------
    EEG = func_saveset(EEG_clean, subjects(isub));

end

disp('Done.')


if ~exist(cfg.dir.qualitycheck, 'dir')
    mkdir(cfg.dir.qualitycheck)
end

if check_quality_plot
    script_nr=5;
   
    get_quality_check(script_nr,{subjects.name},[], removed_nr_components, cfg)
end
