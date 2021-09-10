function EEG = funcrecode_selectevents(EEG, cfg)

% --------------------------------------------------------------
% Remove all events/triggers that are not image onsets. Purpose:
% simplify the dataset and make it easier to match triggers to specific
% trials in the logfile without epoching the data.
% --------------------------------------------------------------
is_image_onset = ismember([EEG.event.type], cfg.image_onset_triggers);
EEG = pop_selectevent(EEG, 'event', find(is_image_onset), 'deleteevents','on');

% The files recorded in Muenster accidentally included 80 training
% trials + the regular 1200 real trials. We have to remove the
% training trials to match the EEG file with the logfile, which
% only includes the last 1200 real trials.
% if length(EEG.event) > 1200
%     disp('Removing the first 80 training trials.')
%     EEG = pop_selectevent( EEG, 'omitevent',[1:80] ,'deleteevents','on');
% 
% end
