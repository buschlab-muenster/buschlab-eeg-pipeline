function [EEG, bad_ics_iclabel] = func_icareject_iclabel(EEG, cfg, old_badics)

% % Add path to ICLabel plugin.
% eeglabdir = fileparts(which('eeglab'));
% iclabeldir = dir([eeglabdir, '/plugins/ICLabel*']);
% addpath(genpath([iclabeldir.folder, filesep, iclabeldir.name, filesep]));

% Run ICLabel classification.
EEG = iclabel(EEG);

% The 6 categories are (in order):
% Brain, Muscle, Eye, Heart, Line Noise, Channel Noise, Other.

nclasses = length(EEG.etc.ic_classification.ICLabel.classes);
threshold = zeros(nclasses, 2);

bad_classes = ismember( EEG.etc.ic_classification.ICLabel.classes, cfg.iclabel_rm_ICtypes);

threshold(bad_classes, 1) = cfg.iclabel_min_acc;
threshold(bad_classes, 2) = 1;

EEG = pop_icflag(EEG, threshold);

if ~isempty(old_badics)
%     EEG = func_icareject_combine_badics(EEG, old_badics);
end

bad_ics_iclabel = EEG.reject.gcompreject;

fprintf('Found %i bad components belonging with p >= %2.2f \nto classes: %s.\n',...
    sum(bad_ics_iclabel), ...
    cfg.iclabel_min_acc, ...
    strjoin(EEG.etc.ic_classification.ICLabel.classes(bad_classes), ', '));



