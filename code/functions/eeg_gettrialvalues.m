function trial_values = eeg_gettrialvalues(EEG)

% Extracts a table with one value per trial for each field in the EEG.epoch
% structure.
% I usually store all information about everything that happened in a
% trial in the epoch structure. Every event in an epoch gets a field with
% that information. E.g. if an epoch includes a cue, a target, and a button
% press with associated response time, the RT that was recorded during the
% experiment is stored in a new event field called RT, and the cue, target,
% and response event all get this information (this is handy for some
% EEGLAB functions). However, sometimes we just want to know: which RT
% occured on which trial, i.e. with only a single value per trial. This
% function extracts a struct with one vector for each field of the epoch
% structure, where each element of each vector represents one trial.

fields = fieldnames(EEG.epoch);

%timelock_events = ([EEG.epoch.eventlatency]) == 0;
timelock_events = cell2mat([EEG.epoch.eventlatency]) == 0;


for ifield = 2:length(fields) % Skip the boring "event" field
    thisfieldname = fields{ifield}(6:end); % remove the "event"-prefix
    
    fieldvalues = [EEG.epoch.(fields{ifield})];
    
    if ischar(fieldvalues(1))
        trial_values.(thisfieldname) = fieldvalues(timelock_events);
    else
        %trial_values.(thisfieldname) = (fieldvalues(timelock_events));
        trial_values.(thisfieldname) = cell2mat(fieldvalues(timelock_events));
    end
end