function [badics, corr_ic_eeg] = find_bad_ics(EEG, eog_chans, corrthreshold)
% function [badics] = find_bad_ics(EEG, eog_chans, corrthreshold)
% This function automatically determines "bad" independent components.
% "Bad" ist defined as a component that correlates strongly with any of the
% EOG channels.
% 
% Inputs:
% EEG: eeglab dataset.
% eog_chans: indices of channels representingeog channels.
% corrthreshold: ICs are defined as bad if their corrlation with eog_chans
% exceeds this threshold.

% Recompute ICA timecourses
clear EEG.icaact;
EEG = eeg_checkset(EEG, 'ica');

%%
% Loop over ICs, compute their correlation with the EOG channels and test
% if the correlation exceeds the threshold.
n_eog = length(eog_chans);
n_ics = size(EEG.icaact,1);
badics = zeros(n_ics, 1);
corr_ic_eeg = nan(n_ics, n_eog);

for ieogchan = 1:n_eog    
    eeg = EEG.data(eog_chans(ieogchan),:);
    
    for icomp = 1:n_ics        
        ic = EEG.icaact(icomp,:);        
        corr_tmp = corrcoef(ic, eeg);
        corr_ic_eeg(icomp, ieogchan) = corr_tmp(1,2);        
    end
end

badics = any(abs(corr_ic_eeg) > corrthreshold, 2);

% Print result to command line.
fprintf('Found %d bad ICs.\n', sum(badics))

bad_idx = find(badics);
for ibad = 1:length(bad_idx)
    
    fprintf('IC %02d: correlates with channels ', bad_idx(ibad));    
    
    for ieogchan = 1:n_eog
        fprintf('%d (%s): %2.2f. ', eog_chans(ieogchan), EEG.chanlocs(eog_chans(ieogchan)).labels, corr_ic_eeg(bad_idx(ibad), ieogchan))
        
    end
    fprintf('\n')
end
