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
% Set variables for data quality check and writing method lines

check_quality_plot = 1;
make_method_section = 1;

% Prepare matrices
rec_length = [];
nevent = numel(cfg.epoch.trig_target); %number of trigger types
events(:,1) = cfg.epoch.trig_target; %here we will store the number of occuraces for each trigger
disp(['Will check data for triggers: ', num2str(cfg.epoch.trig_target)])
% ------------------------------------------------------------------------

% If the qualitycheck folder doesn't exist in the 'data' folder, we create it 
if ~exist(cfg.dir.qualitycheck, 'dir')
    mkdir(cfg.dir.qualitycheck)
end

subjects = get_list_of_subjects(cfg.dir, do_overwrite, suffix_in, suffix_out);

%% Run across subjects.
%nthreads = min([cfg.system.max_threads, length(subjects)]);
% parfor(isub = 1:length(subjects), nthreads) % set nthreads to 0 for normal for loop.

for isub = 1%:length(subjects)

    % --------------------------------------------------------------
    % Import Biosemi raw data.
    % --------------------------------------------------------------
    EEG = func_import_readbdf(cfg.dir, subjects(isub).name);

    % --------------------------------------------------------------
    % Select data channels.
    % --------------------------------------------------------------
     EEG = func_import_selectchans(EEG, cfg.chans);

    % % Use this line to verify the accuracy of channel labels and locations.
    % figure; 
    % topoplot([],EEG.chanlocs,'style','blank','electrodes','labelpoint','chaninfo',EEG.chaninfo);

    % --------------------------------------------------------------
    % Biosemi is recorded reference-free. We apply rereferencing in
    % software. For preprocessing, I recommend using a single reference
    % channel and NOT average reference. A channel near CMS/DRL usually
    % works fine.
    % --------------------------------------------------------------

    EEG = pop_reref(EEG, cfg.prep.reref_chan, 'keepref', 'on');
    disp(['The data is now referenced to: ', EEG.chanlocs(cfg.prep.reref_chan).labels])
    figure; 
    topoplot(cfg.prep.reref_chan,EEG.chanlocs,'style','blank','electrodes','numbers','chaninfo',EEG.chaninfo);

    % --------------------------------------------------------------
    % Compute VEOG and HEOG.
    % --------------------------------------------------------------
    EEG = func_import_eyechans(EEG, cfg.chans);
    
    %---------------------------------------------------------------
    % Remove all events from non-configured trigger devices
    %---------------------------------------------------------------
    EEG = func_import_remove_triggers(EEG, cfg.epoch);

    %---------------------------------------------------------------
    % Import Eyetracking data if exists
    %---------------------------------------------------------------

    if cfg.eyetrack.exist == 1

        disp('Eye-tracking data processing enabled. Eyetracking data will be loaded.')

        EEG = func_import_importEye(EEG, subjects(isub).namestr, cfg.dir, cfg.eyetrack); 

    else
         disp('Eye-tracking data processing disabled.')
    
    end 

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

    % Length of recording in minutes for each subject
    rec_length(isub)=size(EEG.data,2)/EEG.srate/60;

    %count occurances of the events
    for k = 1:nevent
        events(k,isub+1) = sum([EEG.event.type]==cfg.epoch.trig_target(k));
    end

end

%% Create a report %%

% ------------------------------------------------------------------------
% Makes data quality plots based on the collected info on the sample
% ------------------------------------------------------------------------
if check_quality_plot
    script_nr=1;
    get_quality_check(script_nr,{subjects.name}, rec_length, events, cfg) % if the folder data -> quality doesn't exist, the code creates it
    
    f = figure('Visible','off'); % create invisible figure

    topoplot([], EEG.chanlocs, 'style','blank', ...
             'electrodes','labelpoint','chaninfo',EEG.chaninfo);

    saveas(f, strcat(cfg.dir.qualitycheck, subjects(isub).namestr, '_all_channels_topoplot.png'));  % or .jpg, .svg, etc.
    close(f); % close the invisible figure
end

% ------------------------------------------------------------------------
% Writes method-section lines to file according to settings
% ------------------------------------------------------------------------

if make_method_section
    write_method_lines(cfg, 'rereferencing',cfg.prep.do_rereference)
end

disp('Script01: Data import is done.')