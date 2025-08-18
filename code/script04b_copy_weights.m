%% Set preferences, configuration and load list of subjects.
clear; clc; close all

restoredefaultpath
%prefs = get_prefs('eeglab_all', 1);
cfg   = get_cfg;

eeglab nogui


% ------------------------------------------------------------------------
% **Important**: these variables determine which data files are used as
% input and output.

suffix_in  = 'prep';
suffix_in2  = 'ica';

suffix_out = 'ica_weighted';
do_overwrite = true;
% ------------------------------------------------------------------------

subjects_min_process= get_list_of_subjects(cfg.dir, do_overwrite, suffix_in, suffix_out);

subjects_ica = get_list_of_subjects(cfg.dir, do_overwrite, suffix_in2, suffix_out);


%% Run across subjects.
%nthreads = min([prefs.max_threads, length(subjects)]);
%parfor(isub = 1:length(subjects), nthreads) % set nthreads to 0 for normal for loop, parfor is parallel for loop
for isub = 1:length(subjects_ica)

    % --------------------------------------------------------------
    % Load the minimally processed EEG dataset. This is the dataset that
    % the weights will be copied. 
    % --------------------------------------------------------------
    EEG = pop_loadset('filename', subjects_min_process(isub).name, 'filepath', subjects_min_process(isub).folder);

    % --------------------------------------------------------------
    % Load the dataset that was obtained though Script04_runica.m. This
    % data set was further procssed for ica. This is the source of weights.
    % --------------------------------------------------------------
    EEG_ica = pop_loadset('filename', subjects_ica(isub).name, 'filepath', subjects_ica(isub).folder);

    % --------------------------------------------------------------
    % copy weights + sphere 
    % --------------------------------------------------------------
    % 
    EEG.icaweights  = EEG_ica.icaweights;
    EEG.icasphere   = EEG_ica.icasphere;
    EEG.icachansind = EEG_ica.icachansind;
    EEG = eeg_checkset(EEG); %let EEGLAB re-compute EEG.icaact & EEG.icawinv

    % --------------------------------------------------------------
    % Save data.
    % --------------------------------------------------------------
    EEG = func_saveset(EEG, subjects_min_process(isub));

end

disp('Done.')