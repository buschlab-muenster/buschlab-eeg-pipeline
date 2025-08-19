function [windowTimes, windowData] = visualize_random_windows_raw(EEG, badChans, win_length_sec, n_windows, mode, windowTimes, rng_seed)
% VISUALIZE_RANDOM_WINDOWS_RAW
% Plot raw EEG traces from random or pre-defined windows and return data.
%
% Inputs:
%   EEG            - EEGLAB EEG struct (continuous data)
%   badChans       - vector of bad channel indices
%   win_length_sec - window length in seconds (for 'generate')
%   n_windows      - number of windows (for 'generate')
%   mode           - 'generate' or 'use'
%   windowTimes    - Nx2 matrix [start_sec end_sec] (for 'use')
%   rng_seed       - optional random seed (for 'generate')
%
% Outputs:
%   windowTimes    - Nx2 matrix [start_sec end_sec]
%   windowData     - EEG segments (channels × points × windows)

    % --- Diagnostics ---
    fprintf('\n--- EEG Info ---\n');
    fprintf('Samples (pnts): %d\n', EEG.pnts);
    fprintf('Sampling rate: %.2f Hz\n', EEG.srate);
    fprintf('Duration: %.2f sec\n', EEG.pnts / EEG.srate);
    fprintf('Requested window length: %.2f sec\n', win_length_sec);
    fprintf('Mode: %s\n', mode);
    fprintf('----------------\n');

    % --- Mode handling (same as your original function) ---
    switch lower(mode)
        case 'generate'
            if nargin < 7, rng_seed = []; end
            win_length_pts = round(win_length_sec * EEG.srate);
            n_points       = EEG.pnts;
            max_start      = n_points - win_length_pts + 1;

            if max_start < 1
                error('Window length (%.2f s) too long. Max possible: %.2f s.', ...
                      win_length_sec, n_points / EEG.srate);
            end

            if ~isempty(rng_seed)
                rng(rng_seed, 'twister');
            end

            ideal_starts = round(linspace(1, max_start, n_windows)');
            jitter_amount = round(0.1 * win_length_pts);
            jitter = randi([-jitter_amount, jitter_amount], n_windows, 1);

            windowStarts = ideal_starts + jitter;
            windowStarts = max(windowStarts, 1);
            windowStarts = min(windowStarts, max_start);
            windowStarts = sort(windowStarts);

            windowEnds = windowStarts + win_length_pts - 1;
            windowTimes = [windowStarts, windowEnds] / EEG.srate;

        case 'use'
            if isempty(windowTimes)
                error('In "use" mode, provide windowTimes.');
            end
            win_length_sec = windowTimes(1,2) - windowTimes(1,1);
            win_length_pts = round(win_length_sec * EEG.srate);
            n_windows      = size(windowTimes, 1);

        otherwise
            error('Mode must be "generate" or "use".');
    end

    % --- Extract windows ---
    windowData = zeros(EEG.nbchan, win_length_pts, n_windows, 'like', EEG.data);
    idxMat = (0:win_length_pts-1)';

    for i = 1:n_windows
        start_idx = round(windowTimes(i,1) * EEG.srate);
        inds = start_idx + idxMat;

        if inds(end) > EEG.pnts
            error('Window %d exceeds data length.', i);
        end

        windowData(:,:,i) = EEG.data(:, inds);
    end

    % --- Plot ---
    figure;
    tileDim = ceil(sqrt(n_windows));

    if ~isempty(badChans)
        bad_colors = autumn(numel(badChans));
    else
        bad_colors = [];
    end

    for i = 1:n_windows
        seg_data = windowData(:,:,i);
        tvec = linspace(windowTimes(i,1), windowTimes(i,2), size(seg_data,2));

        nexttile;

        % Plot good channels (blue, stacked vertically)
        offset = 0;
        for ch = 1:EEG.nbchan
            if ismember(ch, badChans)
                thisColor = bad_colors(find(badChans==ch,1),:);
            else
                thisColor = [0 0 1]; % blue
            end
            plot(tvec, seg_data(ch,:) + offset, 'Color', thisColor); hold on;
            offset = offset + max(abs(seg_data(ch,:))) * 2; % spacing
        end

        xlabel('Time (s)'); ylabel('Amplitude + offset');
        title(sprintf('Win %d: %.2f–%.2f s', i, windowTimes(i,1), windowTimes(i,2)));
        grid on;
    end

    sgtitle(sprintf('%d Windows (%.1f sec each) - Blue=Good, Red=Bad', ...
            n_windows, win_length_sec));
end
