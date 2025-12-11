function [final_mask, rejected_segments] = func_manual_segment_rejection(EEG, auto_cleaned_mask)
% FUNC_MANUAL_SEGMENT_REJECTION - Interactive segment rejection review
%
% Usage:
%   [final_mask, rejected_segments] = func_manual_segment_rejection(EEG, auto_cleaned_mask)
%
% Inputs:
%   EEG               - EEGLAB dataset structure
%   auto_cleaned_mask - Logical vector (1=keep, 0=reject) from automatic detection
%
% Outputs:
%   final_mask         - Updated logical vector after manual review
%   rejected_segments  - Nx2 matrix of [start_sample end_sample] for rejected segments
%
% This function shows automatically flagged segments in red and allows you to
% add more by clicking and dragging in eegplot, then clicking "REJECT".

    % Get rejected segments from automatic detection
    rejected_intervals = get_rejected_intervals(~auto_cleaned_mask);

    % Display summary
    fprintf('\n========================================\n');
    fprintf('SEGMENT REJECTION REVIEW\n');
    fprintf('========================================\n');
    fprintf('Samples to REJECT (automatic): %d (%.1f%%)\n', sum(~auto_cleaned_mask), 100*sum(~auto_cleaned_mask)/length(auto_cleaned_mask));
    fprintf('Number of rejected segments: %d\n', size(rejected_intervals, 1));
    fprintf('========================================\n');
    fprintf('Instructions:\n');
    fprintf('  - Red regions = automatically flagged\n');
    fprintf('  - Click and drag to mark additional bad segments\n');
    fprintf('  - Click "REJECT" button to add them\n');
    fprintf('  - Close window when done\n');
    fprintf('========================================\n\n');

    % Prepare rejection marks for eegplot
    winrej_auto = intervals_to_winrej(rejected_intervals, EEG.nbchan);

    % Store TMPREJ in base workspace for eegplot callback
    if ~isempty(winrej_auto)
        assignin('base', 'TMPREJ', winrej_auto);
    else
        assignin('base', 'TMPREJ', []);
    end

    % Open eegplot with rejection capability
    eegplot(EEG.data, 'srate', EEG.srate, ...
            'winlength', 20, ...
            'dispchans', 35, ...
            'eloc_file', EEG.chanlocs, ...
            'events', EEG.event, ...
            'winrej', winrej_auto, ...
            'command', 'TMPREJ = TMPREJ;');  % Store rejections

    % Wait for window to close
    uiwait(gcf);

    % Retrieve manual rejections from base workspace
    if evalin('base', 'exist(''TMPREJ'', ''var'')')
        winrej_combined = evalin('base', 'TMPREJ');
        evalin('base', 'clear TMPREJ');
    else
        winrej_combined = winrej_auto;
    end

    % Convert winrej back to mask
    final_mask = auto_cleaned_mask;
    if ~isempty(winrej_combined)
        for i = 1:size(winrej_combined, 1)
            start_idx = round(winrej_combined(i, 1));
            end_idx = round(winrej_combined(i, 2));
            final_mask(start_idx:end_idx) = false;
        end
    end

    rejected_segments = get_rejected_intervals(~final_mask);

    % Final summary
    fprintf('\n========================================\n');
    fprintf('FINAL SUMMARY\n');
    fprintf('========================================\n');
    fprintf('Rejecting %.1f%% of data\n', 100*sum(~final_mask)/length(final_mask));
    fprintf('Total rejected segments: %d\n', size(rejected_segments, 1));
    fprintf('========================================\n\n');

end


function intervals = get_rejected_intervals(reject_mask)
    % Convert logical mask to intervals [start end]
    % reject_mask: 1=reject, 0=keep

    if ~any(reject_mask)
        intervals = [];
        return;
    end

    % Find transitions
    diff_mask = diff([false reject_mask false]);
    starts = find(diff_mask == 1);
    ends = find(diff_mask == -1) - 1;

    intervals = [starts(:) ends(:)];
end


function winrej = intervals_to_winrej(intervals, nbchan)
    % Convert intervals to EEGLAB winrej format for eegplot
    % winrej format: [start end R G B channel1 channel2 ...]

    if isempty(intervals)
        winrej = [];
        return;
    end

    nrej = size(intervals, 1);
    winrej = zeros(nrej, 5 + nbchan);

    winrej(:, 1:2) = intervals;
    winrej(:, 3:5) = repmat([1 0.5 0.5], nrej, 1); % Light red color
    winrej(:, 6:end) = 1; % All channels
end
