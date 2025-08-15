function [windowTimes, windowData] = visualize_random_windows(EEG, badChans, win_length_sec, n_windows, freq_min, freq_max, mode, windowTimes, rng_seed)
% VISUALIZE_RANDOM_WINDOWS
% Plot spectra from random or pre-defined EEG windows and return their data.
%
% Inputs:
%   EEG            - EEGLAB EEG struct (continuous data)
%   badChans       - vector of bad channel indices
%   win_length_sec - window length in seconds (for 'generate')
%   n_windows      - number of windows (for 'generate')
%   freq_min       - min frequency for plotting
%   freq_max       - max frequency for plotting
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

    % --- Mode handling ---
    switch lower(mode)
        case 'generate'
            if nargin < 9, rng_seed = []; end
            win_length_pts = round(win_length_sec * EEG.srate);
            n_points       = EEG.pnts;
            max_start      = n_points - win_length_pts + 1;

            if max_start < 1
                error('Window length (%.2f s) is too long for this dataset. Max length possible: %.2f s.', ...
                      win_length_sec, n_points / EEG.srate);
            end

            % Robust RNG seeding
            if ~isempty(rng_seed)
                rng(rng_seed, 'twister');
            end

            % Evenly spaced start times across the dataset
            ideal_starts = round(linspace(1, max_start, n_windows)');

            % Add jitter (± 10% of win_length_pts)
            jitter_amount = round(0.1 * win_length_pts);
            jitter = randi([-jitter_amount, jitter_amount], n_windows, 1);

            % Apply jitter & keep in valid bounds
            windowStarts = ideal_starts + jitter;
            windowStarts = max(windowStarts, 1);
            windowStarts = min(windowStarts, max_start);

            % Sort for chronological progression
            windowStarts = sort(windowStarts);

            % Compute ends
            windowEnds = windowStarts + win_length_pts - 1;
            windowTimes = [windowStarts, windowEnds] / EEG.srate;

        case 'use'
            if isempty(windowTimes)
                error('In "use" mode, you must provide windowTimes.');
            end
            win_length_sec = windowTimes(1,2) - windowTimes(1,1);
            win_length_pts = round(win_length_sec * EEG.srate);
            n_windows      = size(windowTimes, 1);

        otherwise
            error('Mode must be "generate" or "use".');
    end

    % --- Precompute ---
    goodChans = setdiff(1:EEG.nbchan, badChans);
    tileDim   = ceil(sqrt(n_windows));

    % --- Extract windows ---
    windowData = zeros(EEG.nbchan, win_length_pts, n_windows, 'like', EEG.data);
    idxMat = (0:win_length_pts-1)'; % sample offsets

    for i = 1:n_windows
        start_idx = round(windowTimes(i,1) * EEG.srate);
        inds = start_idx + idxMat;

        % Bounds check
        if inds(end) > EEG.pnts
            error('Window %d exceeds data length. start_idx=%d, end_idx=%d, EEG.pnts=%d', ...
                  i, inds(1), inds(end), EEG.pnts);
        end

        windowData(:,:,i) = EEG.data(:, inds);
    end

    % --- Plot ---
    figure;
    tiledlayout(tileDim, tileDim);

    % Prepare bad channel colors (reddish colormap)
    if ~isempty(badChans)
        bad_colors = autumn(numel(badChans));  % yellow → orange → red
    else
        bad_colors = [];
    end

    for i = 1:n_windows
        seg_data = windowData(:,:,i);
        [spectra, freqs] = spectopo(seg_data, 0, EEG.srate, 'plot', 'off');
        idxFreq = freqs >= freq_min & freqs <= freq_max;

        nexttile;
        % Plot good channels in blue
        if ~isempty(goodChans)
            plot(freqs(idxFreq), spectra(goodChans, idxFreq)', 'b'); 
            hold on;
        end
        % Plot bad channels in reddish shades
        for bc = 1:numel(badChans)
            plot(freqs(idxFreq), spectra(badChans(bc), idxFreq)', 'Color', bad_colors(bc,:));
            hold on;
        end

        xlim([freq_min freq_max]);
        xlabel('Hz'); ylabel('Log power (dB)');
        title(sprintf('Win %d: %.2f–%.2f s', i, windowTimes(i,1), windowTimes(i,2)));
        grid on;
    end

    sgtitle(sprintf('%d Windows (%.1f sec each)  Blue=Good, Reddish=Bad', ...
            n_windows, win_length_sec));
end
