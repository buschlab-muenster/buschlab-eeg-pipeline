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

% ------------------------------------------------------------------------
% This is for the data quality check
% Prepare types of events
check_quality_plot = 1 % or 0
figDir = '/data4/BuschlabPipeline/AlphaIcon/Figures/'  %could be part fo the cfg file
eventType = cfg.epoch.image_onset_triggers; %
N = numel(eventType); %number of trigger types
events(:,1) = eventType; %prepare for loading the number of occuraces for each trigger

disp(['Will check data for triggers: ', num2str(eventType)])
% ------------------------------------------------------------------------

textDir = '/data4/BuschlabPipeline/AlphaIcon/report/'%could go tot he cfg fil

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
    %     nsecs = 5;
    %     EEG = func_import_patchdata(EEG, nsecs);

    % --------------------------------------------------------------
    % Select data channels.
    % --------------------------------------------------------------
    EEG = func_import_selectchans(EEG, cfg.chans);

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
    EEG = func_import_importEye(EEG, subjects(isub).namestr, cfg.dir, cfg.eyetrack);    %Elena document that .asc file has to be named in the same way as subjects(isub).namestr

    % --------------------------------------------------------------
    % Import behavioral data.
    % --------------------------------------------------------------
    %? EEG = func_importBehavior(EEG, subjects(isub).namestr, cfg.dir, cfg.epoch);%Elena document that logfile has to be named in the same way as subjects(isub).namestr

    % --------------------------------------------------------------
    % Save the new EEG file in EEGLAB format.
    % --------------------------------------------------------------
    EEG = func_saveset(EEG, subjects(isub));

    % --------------------------------------------------------------
    % Inspect data quality.
    % --------------------------------------------------------------

    % Length of recoding in minutes
    rec_length(isub)=size(EEG.data,2)/EEG.srate/60

    %count occurances of the events
    for k = 1:N
        events(k,isub+1) = sum([EEG.event.type]==eventType(k));
    end


end

% --------------------------------------------------------------
% Create a report.
% --------------------------------------------------------------

fileID = fopen([textDir, 'project_report.txt'],'a+'); %do not overwrite
fprintf(fileID,'\n %s%s \n %s%s \n %s%d \n %s%d%s%s ',datestr(datetime),'report from script01_import ', 'Data directory: ',cfg.dir.main,...
    'New sampling rate: ', cfg.prep.new_sampling_rate,...
    'New reference: ', cfg.prep.do_rereference,', ', cfg.prep.reref_chan);
fclose(fileID);

% ------------------------------------------------------------------------
% Makes data quality plots based on the collected info on the sample
% ------------------------------------------------------------------------

if check_quality_plot
    %plot and save figure for the recording length
    bar(rec_length), xlabel('Participants', 'FontSize', 14), ylabel('Length of recordings (min)', 'FontSize', 14)
    saveas(gcf, [figDir, 'recording length.png'])

    %plot and save figure for the number of event types. Subjects are color coded
    bar(events(:,1),events(:,2:end)), xlabel('Events', 'FontSize', 12), ylabel('Number of occurances', 'FontSize', 12),...
        legend(string([1:33]), 'Location','southoutside', 'Orientation','horizontal','NumColumns',6, 'FontSize',5)
    saveas(gcf, [figDir,'events per participant.png'])
end

disp('Done.')
