%% Set preferences, configuration and load list of subjects.
clear; clc; close all
restoredefaultpath
prefs = get_prefs('eeglab_all', 0);
cfg   = get_cfg;

% Run FFT on a time window of the data, as defined in cfg.fft.twin.
% You can run the analysis for several time windows, which will be saved to
% separate EEG output files.
suffix_in  = 'final';
do_overwrite = true;
% ------------------------------------------------------------------------

for iwin = 1:length(cfg.fft)
    suffix_out = ['fft_' ...
        num2str(cfg.fft(iwin).twin(1)) '_' ...
        num2str(cfg.fft(iwin).twin(2))];
    subjects{iwin} = get_list_of_subjects(cfg.dir, do_overwrite, suffix_in, suffix_out);
end

%% Run across subjects.
nthreads = min([prefs.max_threads, length(subjects{1})]);
parfor(isub = 1:length(subjects{1}), nthreads)
% for isub = 1%:length(subjects{1})
    
    % --------------------------------------------------------------
    % Load the dataset.
    % --------------------------------------------------------------
    EEGin = pop_loadset('filename', subjects{1}(isub).name, ...
        'filepath', subjects{1}(isub).folder);    
    
    % --------------------------------------------------------------
    % For every time window, run FFT and save data.
    % --------------------------------------------------------------       
    for iwin = 1:length(cfg.fft)        
        EEGout = func_fft(EEGin, cfg.fft(iwin));
        EEGout = func_saveset(EEGout, subjects{iwin}(isub));
    end
    
end

disp('Done.')
