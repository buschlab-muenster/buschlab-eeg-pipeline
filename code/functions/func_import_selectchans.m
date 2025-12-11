function EEG = func_import_selectchans(EEG, cfg)


% Remove empty channels, i.e. channels that are not in the list of
% EEGchans.
EEG = pop_select(EEG, 'channel', cfg.EEGchans);

% Import standard 10/20 channel locations. This will only work for external
% channels for which you have set the channel label manually. It will not
% find valid locations for our custom channels on thecap that are labeled
% A1-A32 and B1-B32.
fprintf('Loading standard 10/20 coordinates from %s.\n', cfg.chanlocs_standard)
EEG_standard = pop_chanedit(EEG, 'lookup', cfg.chanlocs_standard); 

% Import channel locations for our custom electrode cap.
fprintf('Loading custom coordinates from %s.\n', cfg.chanlocs_custom)
EEG_custom = pop_chanedit(EEG, 'lookup', cfg.chanlocs_custom); 

% Now integrate these locations: use 10/20 locs for the external channels
% and the custom locs for channels on the cap.
disp('Integrating custom channel locations with standard 10/20 locations.')
EEG.chanlocs(1:64)   = EEG_custom.chanlocs(1:64);
EEG.chanlocs(65:end) = EEG_standard.chanlocs(65:end);

% change labels to standard
% BioSemi 64+3 channel system to standard 10-20/10-10 mapping
% custom_labels = {'A1', 'A2', 'A3', 'A4', 'A5', 'A6', 'A7', 'A8', 'A9', 'A10', ...
%                  'A11', 'A12', 'A13', 'A14', 'A15', 'A16', 'A17', 'A18', 'A19', 'A20', ...
%                  'A21', 'A22', 'A23', 'A24', 'A25', 'A26', 'A27', 'A28', 'A29', 'A30', ...
%                  'A31', 'A32', 'B1', 'B2', 'B3', 'B4', 'B5', 'B6', 'B7', 'B8', ...
%                  'B9', 'B10', 'B11', 'B12', 'B13', 'B14', 'B15', 'B16', 'B17', 'B18', ...
%                  'B19', 'B20', 'B21', 'B22', 'B23', 'B24', 'B25', 'B26', 'B27', 'B28', ...
%                  'B29', 'B30', 'B31', 'B32', 'IO1', 'Afp9', 'Afp10'};
% 
% standard_labels = {'AF8', 'F6', 'FC4', 'FC6', 'F8', 'AF4', 'F4', 'FT8', 'FT10', 'T8', ...
%                    'C4', 'TP8', 'TP10', 'CP6', 'C6', 'C2', 'CP4', 'P6', 'PO8', 'PO4', ...
%                    'O2', 'PO6', 'POz', 'Oz', 'Iz', 'Oz', 'POz', 'PO3', 'PO7', 'CPz', ...
%                    'P7', 'Pz', 'Fpz', 'AFz', 'Fz', 'FC2', 'CP2', 'Cz', 'FCz', 'Fz', ...
%                    'AFz', 'AF7', 'AF3', 'F3', 'FC1', 'CP1', 'TP7', 'C3', 'FT7', 'F7', ...
%                    'F5', 'FC3', 'FC5', 'FT9', 'TP9', 'C5', 'CP5', 'C1', 'PO5', 'CP3', ...
%                    'P5', 'CP5', 'C5', 'C1', 'VEOG', 'Fp1', 'Fp2'};
% 
% % Apply the mapping to your EEG structure
% for i = 1:length(EEG.chanlocs)
%     current_label = EEG.chanlocs(i).labels;
%     idx = find(strcmp(custom_labels, current_label));
%     if ~isempty(idx)
%         EEG.chanlocs(i).labels = standard_labels{idx};
%     end
% end
% 
% % Display the relabeled channels
% disp('Channels relabeled successfully:');
% {EEG.chanlocs.labels}'

done();
