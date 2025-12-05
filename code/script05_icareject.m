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
%nthreads = min([prefs.max_threads, length(subjects)]);
%parfor(isub = 1:length(subjects), nthreads) % Use this if you do NOT use manual confirmation

for isub = 1%:length(subjects) 
    
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
        %pop_viewprops(EEG, 0, [find(EEG.reject.gcompreject==1)]', 'ICLabel' ) % inspection of flagged components
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

    EEG_clean = pop_subcomp(EEG, remove_ics, 0);
    
    % --------------------------------------------------------------
    % Before vs after ICA - Make it optional for fully automatic
    %
    % Future - we can do this before substracting bad components and 
    % see how the data changes before we commit to it?
    % --------------------------------------------------------------

    figs_before = get(0, 'Children');
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

msg = sprintf(['\n%s\nreport from script05_icareject\n' ...
    'Data directory: %s\n' ...
    'Processed subjects: %s\n' ...
    'Number of components rejected: %d\n'], ...
    datestr(datetime), ...
    cfg.dir.main, ...
    strjoin({subjects.name}, ', '), ...
    sum(EEG.reject.gcompreject));

fileID = fopen([cfg.dir.qualitycheck, 'project_report.txt'],'a+');
fprintf(fileID,'%s',msg);
fclose(fileID);
