%% Set preferences, configuration and load list of subjects.
clear; clc; close all

restoredefaultpath
prefs = get_prefs('eeglab_all', 1);
cfg   = get_cfg_new;

% ------------------------------------------------------------------------
% **Important**: these variables determine which data files are used as
% input and output.
suffix_in  = '';
suffix_out = 'import';
do_overwrite = false;
% ------------------------------------------------------------------------

subjects = get_list_of_subjects(cfg.dir, do_overwrite, suffix_in, suffix_out);
figDir = '/data4/BuschlabPipeline/AlphaIcon/Figures/' %directory where data quality figures are saved -> put it into the cfg

%prepare types of events
eventType = cfg.epoch.image_onset_triggers %unique([EEG.event.type])
N = numel(eventType);
events(:,1) = eventType
%% Run across subjects.

for isub = 1:length(subjects)
    % --------------------------------------------------------------
    % Import Biosemi raw data.
    % --------------------------------------------------------------
    EEG = func_import_readbdf(cfg.dir, subjects(isub).name);

    % length of recoding in minutes
    rec_length(isub)=size(EEG.data,2)/EEG.srate/60

    %count occurances of the events
    for k = 1:N
        events(k,isub+1) = sum([EEG.event.type]==eventType(k));
    end
    %events.(subjects(isub).name(1:end-4)) = [eventType; count]'
end
%plot and save figure for the recording length
bar(rec_length), xlabel('Participants', 'FontSize', 14), ylabel('Length of recordings (min)', 'FontSize', 14)
saveas(gcf, [figDir, 'recording length.png'])

%plot and save figure for the number of event types. Color coded are
%subejcts

bar(events(:,1),events(:,2:end)), xlabel('Events', 'FontSize', 12), ylabel('Number of occurances', 'FontSize', 12), legend(string([1:33]), 'Location','southoutside',...
    'Orientation','horizontal','NumColumns',6, 'FontSize',5)
saveas(gcf, [figDir,'events per participant.png'])