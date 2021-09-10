function EEG = func_import_patchdata(EEG, nsecs)

% !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!1
% This is a patch for ROSA3: for some subjects, the time lag between
% recording start and first trial onset is too short for the long
% baseline we require for epoching, so the first trials is dropped.
% This creates a huge headache because then the numbers of trials in
% EEG and logfile do not match. To fix this, I append a little bit of
% data at the beginning of each file.
patchEEG = pop_select( EEG, 'point',[1 EEG.srate*nsecs] );

% Flip the data so that the boundary between appended and original data
% matches.
patchEEG.data = fliplr(patchEEG.data);
patchEEG.event = [];
EEG = pop_mergeset(patchEEG, EEG);

% Remove the first event, which marks the boundary between the appended
% data. Otherwise eeglab will refuse to include the first epoch if it
% contains a boundary event. 
EEG.event(1) = [];