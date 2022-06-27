%% Set preferences, configuration and load list of subjects.
clear; clc; close all
restoredefaultpath
prefs = get_prefs('eeglab_all', 0);
cfg   = get_cfg;

% ------------------------------------------------------------------------
% **Important**: these variables determine which data files are used as
% input and output.
suffix_in  = 'final';
do_overwrite = true;
% ------------------------------------------------------------------------

for iband = 1:length(cfg.filtbert)
    suffix_out = ['filtbert_' ...
        num2str(cfg.filtbert.fbands{iband}(1)) '_' ...
        num2str(cfg.filtbert.fbands{iband}(2)) tag];
    subjects{iband} = get_list_of_subjects(cfg.dir, do_overwrite, suffix_in, suffix_out);

end

%% Run across subjects.
nthreads = min([prefs.max_threads, length(subjects{1})]);
parfor(isub = 1:length(subjects{1}), nthreads)
%     for isub = 1%:length(subjects)
    
    % --------------------------------------------------------------
    % Load the dataset.
    % --------------------------------------------------------------
    EEGin = pop_loadset('filename', subjects{1}(isub).name, ...
        'filepath', subjects{1}(isub).folder);
        
    % --------------------------------------------------------------
    % For each pass-band, run band-pass filter, hilbert transform, 
    % compute power, and save data.
    % --------------------------------------------------------------
    for iband = 1:length(cfg.filtbert)        
        EEGout = func_filtbert(EEGin, joinstructs(cfg.chans, cfg.filtbert), iband);           
        EEGout = func_saveset(EEGout, subjects{iband}(isub));       
    end
    
end
disp('Done.')
