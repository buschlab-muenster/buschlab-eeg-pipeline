%% Set preferences, configuration and load list of subjects.
clear; clc; %close all

restoredefaultpath
prefs = get_prefs('eeglab_all', 0); 
cfg   = get_cfg;

% ------------------------------------------------------------------------
% **Important**: these variables determine which data files are used as
% input and output. 
suffix_in  = 'final2';
suffix_out = 'final2';
do_overwrite = true;
subjects = get_list_of_subjects(cfg.dir, do_overwrite, suffix_in, suffix_out);

%% Run across subjects.
T = struct();

for isub = 1:length(subjects)
    
    % --------------------------------------------------------------
    % Load the dataset and initialize the list of bad ICs.
    % --------------------------------------------------------------
    EEG = pop_loadset('filename', subjects(isub).name, ...
        'filepath', subjects(isub).folder, ...
        'loadmode', 'info');       
     
   T(isub).id          =  isub;
   T(isub).name        =  subjects(isub).name;
   T(isub).ntrials     = EEG.trials;
   T(isub).ntrials_rej = length(EEG.rejected_trials);
   T(isub).nics        = size(EEG.icaweights,1);
   T(isub).nics_rej    = cfg.ica.ica_ncomps - T(isub).nics;
   T(isub).ninterchans = length(EEG.interp_chans);   
    
end

T = struct2table(T);

disp('Done.')
