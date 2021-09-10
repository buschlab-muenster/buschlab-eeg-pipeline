function EEG = func_import_selectchans(EEG, cfg)

% We have to make sure that we add the path to the dipfit plugin, otherwise
% we may get problems loading 'dipfitdefs'.

eeglabdir = fileparts(which('eeglab'));
addpath([eeglabdir, '/plugins/dipfit/'])

EEG = pop_select(EEG, 'channel', cfg.EEGchans);

fprintf('Loading standard 10/20 coordinates from %s.\n', cfg.chanlocfile_standard)
EEG = pop_chanedit(EEG, 'lookup', cfg.chanlocfile_standard);

fprintf('Loading custom coordinates from %s.\n', cfg.chanlocfile_custom)
EEG = pop_chanedit(EEG, 'lookup', cfg.chanlocfile_custom);
