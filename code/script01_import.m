% script01_import
% This script imports the EEG data from the Biosemi .bdf files and stores
% them in EEGLAB format. We also remove empty EEG channels and import the
% channel coordinates. We also import the Eyelink .edf files and
% integrates the eyetracking data with the EEG data. Beyond that, this
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

subjects = get_list_of_subjects(cfg.dir, do_overwrite, suffix_in, suffix_out);



%% Run across subjects.
nthreads = min([cfg.system.max_threads, length(subjects)]);
% parfor(isub = 1:length(subjects), nthreads) % set nthreads to 0 for normal for loop.
for isub = 6:length(subjects)

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
    EEG = func_import_importEye(EEG, subjects(isub).namestr, cfg.dir, cfg.eyetrack);

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

end

done();
