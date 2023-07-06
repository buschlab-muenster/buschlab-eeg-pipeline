function EEG = func_import_selectchans(EEG, cfg)


% Remove empty channels, i.e. channels that are not in the list of
% EEGchans.
EEG = pop_select(EEG, 'channel', cfg.EEGchans);

% Import standard 10/20 channel locations. This will only work for external
% channels for which you have set the channel label manually. It will not
% find valid locations for our custom channels on thecap that are labeled
% A1-A32 and B1-B32.
fprintf('Loading standard 10/20 coordinates from %s.\n', cfg.chanlocfile_standard)
EEG_standard = pop_chanedit(EEG, 'lookup', cfg.chanlocs_standard);

% Import channel locations for our custom electrode cap.
fprintf('Loading custom coordinates from %s.\n', cfg.chanlocfile_custom)
EEG_custom = pop_chanedit(EEG, 'lookup', cfg.chanlocs_custom);

% Now integrate these locations: use 10/20 locs for the external channels
% and the custom locs for channels on the cap.
disp('Integrating custom channel locations with standard 10/20 locations.')
EEG.chanlocs(1:64)   = EEG_custom.chanlocs(1:64);
EEG.chanlocs(65:end) = EEG_standard.chanlocs(65:end);

fprintf('\nDone.\n')
