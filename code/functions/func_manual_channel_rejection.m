function EEG_out = func_manual_channel_rejection(EEG, flat_channels_to_remove)
% FUNC_MANUAL_CHANNEL_REJECTION - Interactive channel rejection review
%
% Usage:
%   EEG_out = func_manual_channel_rejection(EEG, flat_channels_to_remove)
%
% Inputs:
%   EEG                     - EEGLAB dataset structure
%   flat_channels_to_remove - Vector of channel indices already flagged for removal
%
% Output:
%   EEG_out                 - Dataset with bad channels removed
%
% This function visualizes the data, shows which channels are flagged for
% removal, and allows you to add more channels via command line input.

% Display summary
fprintf('\n========================================\n');
fprintf('CHANNEL REJECTION REVIEW\n');
fprintf('========================================\n');
fprintf('Total channels: %d\n', EEG.nbchan);
fprintf('Flagged for removal: %d channels\n', length(flat_channels_to_remove));

if ~isempty(flat_channels_to_remove)
    fprintf('Flagged channels: ');
    for i = 1:length(flat_channels_to_remove)
        fprintf('%s ', EEG.chanlocs(flat_channels_to_remove(i)).labels);
    end
    fprintf('\n');
end
fprintf('========================================\n\n');

% Show visualization
fprintf('Opening visualization...\n');
vis_artifacts(EEG, EEG);

%print channel names and numbers
for i = 1:EEG.nbchan
    fprintf('  %d: %s\n', i, EEG.chanlocs(i).labels);
end

% Wait for figure to be closed
fprintf('Close the visualization window when done reviewing.\n');
h = gcf;
if ishandle(h)
    uiwait(h);
end

% Ask user if they want to add more channels
user_response = input('\nDoes everything look good? (y/n): ', 's');

additional_channels = [];
if strcmpi(user_response, 'n') || strcmpi(user_response, 'no')
    fprintf('\nEnter additional channel numbers or labels to remove.\n');
    fprintf('Available channels:\n');
    for i = 1:EEG.nbchan
        fprintf('  %d: %s\n', i, EEG.chanlocs(i).labels);
    end
    fprintf('\n');

    while true
        user_input = input('Channel (number/label) or Enter to finish: ', 's');
        if isempty(user_input)
            break;
        end

        % Try to parse as number first
        chan_num = str2double(user_input);
        if ~isnan(chan_num) && chan_num >= 1 && chan_num <= EEG.nbchan
            additional_channels = [additional_channels; chan_num];
            fprintf('  Added: %d (%s)\n', chan_num, EEG.chanlocs(chan_num).labels);
        else
            % Try to find by label
            chan_idx = find(strcmpi({EEG.chanlocs.labels}, user_input));
            if ~isempty(chan_idx)
                additional_channels = [additional_channels; chan_idx(1)];
                fprintf('  Added: %d (%s)\n', chan_idx(1), EEG.chanlocs(chan_idx(1)).labels);
            else
                fprintf('  Channel not found: %s\n', user_input);
            end
        end
    end
end

% Combine flagged and manual channels
all_channels_to_remove = unique([flat_channels_to_remove(:); additional_channels(:)]);

% Remove channels
if ~isempty(all_channels_to_remove)
    fprintf('\n========================================\n');
    fprintf('Removing %d channels:\n', length(all_channels_to_remove));
    for i = 1:length(all_channels_to_remove)
        fprintf('  %d: %s\n', all_channels_to_remove(i), EEG.chanlocs(all_channels_to_remove(i)).labels);
    end
    fprintf('========================================\n\n');

    EEG_out = pop_select(EEG, 'nochannel', all_channels_to_remove);
else
    fprintf('\nNo channels removed.\n\n');
    EEG_out = EEG;
end

end
