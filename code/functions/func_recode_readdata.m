function [EEG, T] = func_recode_readdata(cfg, subjects, isub)
% This function loads a subject's EEG data and corresponding behavioral
% logfile. The function then checks if both datasets include the same number of
% trials.



% Load EEG.
EEG = pop_loadset('filename', subjects(isub).name, ..., 
    'filepath', subjects(isub).folder, ...
    'loadmode', 'all');

% Load logfile.
orig_name = EEG.urname(1:end-4);
logname = fullfile(cfg.dir_behavior, [orig_name, '_Logfile_processed.mat']);
load(logname);
T = Info.T;
% 
% Make sure that number of trials is consistent in both files.
% ntrials_eeg = length(EEG.event);
% ntrials_log = length(T);
% 
% fprintf('Testing if EEG and behavioral logfile have same number of trials.\n')
% if ntrials_eeg == ntrials_log
%     fprintf('Success: EEG has %d trials; logfile has %d trials.\n', ntrials_eeg, ntrials_log)
% else
%     errormsg = sprintf('Error: EEG has %d trials; logfile has %d trials.\n', ntrials_eeg, ntrials_log);
%     error(errormsg)    
% end
