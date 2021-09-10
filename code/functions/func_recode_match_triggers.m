function [EEG, T] = func_recode_match_triggers(EEG, T)

eeg_triggers = [EEG.event.type];

trig_table(1,:) = [18, 19, 20]; % beach
trig_table(2,:) = [21, 22, 23]; % building
trig_table(3,:) = [24, 25, 26]; % forest
trig_table(4,:) = [27, 28, 29]; % highway

for i_log_event = 1:length(T)
    log_triggers(i_log_event) = trig_table(T(i_log_event).category_index, T(i_log_event).presentation_no);
end


% Make sure that number of trials is consistent in both files.
ntrials_eeg = length(eeg_triggers);
ntrials_log = length(log_triggers);

fprintf('Testing if EEG and behavioral logfile have same number of trials.\n')
%%
if ntrials_eeg == ntrials_log
    fprintf('Success: EEG has %d trials; logfile has %d trials.\n', ntrials_eeg, ntrials_log)
else
    errormsg = sprintf('Error: EEG has %d trials; logfile has %d trials.', ntrials_eeg, ntrials_log);
    warning(errormsg)
    
    % More EEG trials than logfile trials, i.e. EEG includes training
    % trials.
    if ntrials_eeg > ntrials_log
        
        first_match_idx = strfind(eeg_triggers, log_triggers);
        EEG = pop_selectevent( EEG, 'omitevent',[1:(first_match_idx-1)] ,'deleteevents','on');
        
        % More logfile trials than EEG trials, e.g. EEG recording was started
        % too late.
    elseif ntrials_eeg < ntrials_log
        
        first_match_idx = strfind(log_triggers, eeg_triggers);
        T = T([1:(first_match_idx-1)], :);
        
    end
    
    if length(EEG.event) == length(T)
        msg = sprintf('Corrected. EEG has %d events. Logfile has %d events.', length(EEG.event), length(T));
        warning(msg)
    else
        msg = sprintf('Uncorrectable. EEG has %d events. Logfile has %d events.', length(EEG.event), length(T));
        error(msg)
    end
    
end






