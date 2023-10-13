% script01_import
% This script imports the EEG data from the Biosemi .bdf files and stores
% them in EEGLAB format. We also remove empty EEG channels, import the
% channel coordinates, re-reference data, import the Eyelink .edf files and
% integrate the eyetracking data with the EEG data. Beyond that, this
% script does not apply any signal processing or manipulation of the data
% yet.

%% Set preferences, configuration and load list of subjects.
clear; clc; close all
restoredefaultpath
cfg = get_cfg;
eeglab nogui


% ------------------------------------------------------------------------
% **Important**: these variables determine which data files are used as
% input and output.
suffix_in  = '';
suffix_out = 'import';
do_overwrite = true;

% ------------------------------------------------------------------------
% ------------------------------------------------------------------------
% Set variables for data quality check and prepare matrices
check_quality_plot = 1;
rec_length = [];
nevent = numel(cfg.epoch.trig_target); %number of trigger types
events(:,1) = cfg.epoch.trig_target; %here we will store the number of occuraces for each trigger
disp(['Will check data for triggers: ', num2str(cfg.epoch.trig_target)])
% ------------------------------------------------------------------------

subjects = get_list_of_subjects(cfg.dir, do_overwrite, suffix_in, suffix_out);

%% Run across subjects.
nthreads = min([cfg.system.max_threads, length(subjects)]);
% parfor(isub = 1:length(subjects), nthreads) % set nthreads to 0 for normal for loop.
for isub = 1:length(subjects)

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
    % software. For preprocessing, I recommend using a single reference
    % channel and NOT average reference. A channel near CMS/DRL usually
    % works fine.
    % --------------------------------------------------------------
    EEG = func_import_reref(EEG, joinstructs(cfg.prep, cfg.chans));

    % --------------------------------------------------------------
    % Compute VEOG and HEOG.
    % --------------------------------------------------------------
    EEG = func_import_eyechans(EEG, cfg.chans);

    %---------------------------------------------------------------
    % Remove all events from non-configured trigger devices
    %---------------------------------------------------------------
    EEG = func_import_remove_triggers(EEG, cfg.epoch);

    % --------------------------------------------------------------
    % Import Eyetracking data.
    % --------------------------------------------------------------
    EEG = func_import_importEye(EEG, subjects(isub).namestr, cfg.dir, cfg.eyetrack); %function breaks matlab by looking for eegplugin_eye_eeg.m

    % Hack for AlphaICon: the first subjects were recorded with incomplete
    % triggers in the eyetracking files. As a result, the import_eyelink
    % function is not able to sync EEG and eyetracking data. To make the
    % data structure compatible with complete data in the future, I am
    % inserting 3 empty channels with the appropriate channel labels.
    lastchan = EEG.nbchan;
    dummydat = zeros(size(EEG.data(lastchan,:)));
    EEG.data(lastchan+1,:) = dummydat;
    EEG.data(lastchan+2,:) = dummydat;
    EEG.data(lastchan+3,:) = dummydat;
    EEG.nbchan = size(EEG.data,1);

    EEG.chanlocs(lastchan+1).labels = 'Eyegaze-X';
    EEG.chanlocs(lastchan+2).labels = 'Eyegaze-Y';
    EEG.chanlocs(lastchan+3).labels = 'Pupil-Dilation';

    EEG = eeg_checkset(EEG, 'chanlocsize', 'chanlocs_homogeneous');

    % --------------------------------------------------------------
    % Save the new EEG file in EEGLAB format.
    % --------------------------------------------------------------
    if ~exist(subjects(isub).outdir, 'dir')
        mkdir(subjects(isub).outdir)
    end

    EEG = func_saveset(EEG, subjects(isub));

    % --------------------------------------------------------------
    % Create variables that will be used to inspect data quality.
    % --------------------------------------------------------------

    % Length of recoding in minutes for each subject
    rec_length(isub)=size(EEG.data,2)/EEG.srate/60;

    %count occurances of the events
    for k = 1:nevent
        events(k,isub+1) = sum([EEG.event.type]==cfg.epoch.trig_target(k));
    end

end

%% Create a report %%
% --------------------------------------------------------------

% If the qualitycheck folder  doesn't exist, we create it 

if ~exist(cfg.dir.qualitycheck, 'dir')
    mkdir(cfg.dir.qualitycheck)
end

fileID = fopen([cfg.dir.qualitycheck, 'project_report.txt'],'a+'); 
fprintf(fileID,'\n %s',datestr(datetime),'report from script01_import ', ['Data directory: ',cfg.dir.main],...
    ['Processed subjects: ', strjoin({subjects.name}, ', ')], ['New reference (yes/no): ', num2str(cfg.prep.do_rereference)],...
    ['Reference channel: ', EEG.chanlocs(cfg.prep.reref_chan).labels]);
fclose(fileID);

% ------------------------------------------------------------------------
% Makes data quality plots based on the collected info on the sample
% ------------------------------------------------------------------------
if check_quality_plot
    get_quality_check(subjects, rec_length, events, cfg) % if the folder data -> quality doesn't exist, the code creates it
end

done();
