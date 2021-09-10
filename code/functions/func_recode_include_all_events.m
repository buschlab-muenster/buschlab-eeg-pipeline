function EEG = func_recode_include_all_events(EEG, T)
% This function includes the behavioral data as recorded by Psychtoolbox in
% the EEG structure.

fields = fieldnames(T);
ntrials = length(T);
TrialsOut = [];


for ifield = 1:length(fields)
   fieldlength = length(getfield(T,(fields{ifield}) ));
   
   if fieldlength == 1
       
       % Test if this field has only scalar values. If yes, copy it to the
       % new "Logfile".
       for itrial = 1:ntrials
        TrialsOut(itrial).(fields{ifield}) = T(itrial).(fields{ifield});
       end       
       
   end
end

outfields = fieldnames(TrialsOut);


% Run through all events and import the behavioral data. The important
% assumption is that each epoch of the EEG data set corresponds to one
% trial in the logfile and the first trials in both data structures
% correspond to the same trial!
for ievent = 1:length(EEG.event)
    for ifield = 1:length(outfields)  
        
        % Check if the field in the log file is empty. If yes, fill with
        % arbitrary value.
        new_event_value = TrialsOut(ievent).(outfields{ifield});
        if isempty(new_event_value)
            fillvalue = 666;
            fprintf('Empty event field found on trial %d in event field %s!\n', thisepoch, outfields{ifield});
            fprintf('Filling this field with arbitrary value of %d\n', fillvalue)
            new_event_value = fillvalue;
        end
        
        EEG.event(ievent).(outfields{ifield}) = new_event_value;
    end
end


% Issue a warning if the number of trials in the Logfile does not match the
% number in the EEG file.
if length(EEG.event) ~= ntrials
    w = sprintf('\nEEG file has %d trials, but Logfile has %d trials.\nYou should check this!', ...
        length(EEG.event), ntrials);
    warning(w)
end


% Update the EEG.epoch structure.
EEG = eeg_checkset(EEG, 'eventconsistency');


% Include the full trials structure in the EEG strucutre. You never know
% when it might be useful, especially for the more complex fields that
% could not be included in the EPOCH structure.
EEG.trialinfo = T;
