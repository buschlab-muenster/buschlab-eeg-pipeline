function [badics, corr_eeg_ic] = find_bad_ics(EEG, eog_chans, corrthreshold)
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


% Loop over ICs, compute their correlation with the EOG channels and test
% if the correlation exceeds the threshold.
for ieogchan = 1:length(eog_chans)
    
    eeg = EEG.data(eog_chans(ieogchan),:);
    
    for icomp = 1:size(EEG.icaact,1)        
        ic = EEG.icaact(icomp,:);        
        corr_tmp = corrcoef(ic, eeg);
        corr_eeg_ic(icomp,ieogchan) = corr_tmp(1,2);        
    end
    
    badics{ieogchan} = find(abs(corr_eeg_ic(:,ieogchan)) >= corrthreshold)';
    badics_corr{ieogchan} = corr_eeg_ic(badics{ieogchan},ieogchan);
end

% Print result to command line.
fprintf('Found %d bad ICs.\n', length(unique([badics{:}])))

for ieogchan = 1:length(eog_chans)
    for ibad = 1:length(badics{ieogchan})
        fprintf('IC %02d: correlates with channel %d (%s): r = %2.2f.\n', ...
            badics{ieogchan}(ibad), ...
            eog_chans(ieogchan), ...
            EEG.chanlocs(eog_chans(ieogchan)).labels, ...
            badics_corr{ieogchan}(ibad))
    end
end

% Return a list with the bad ICs.
badics = unique([badics{:}]);
