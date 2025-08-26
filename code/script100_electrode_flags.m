clear; clc; close all

restoredefaultpath
cfg   = get_cfg;

eeglab nogui

addpath(fullfile(cfg.dir.eeglab,'plugins','erplab', 'pop_functions'))
addpath(fullfile(cfg.dir.eeglab,'plugins','erplab', 'functions'))

% ------------------------------------------------------------------------
% **Important**: these variables determine which data files are used as
% input and output.
suffix_in  = 'simple_prep';
suffix_out = 'electrode_rej';
do_overwrite = true;
% ------------------------------------------------------------------------

subjects = get_list_of_subjects(cfg.dir, do_overwrite, suffix_in, suffix_out);


isub = 1%:length(subjects)

% ----------------------------------------------------------
% Load the dataset.
% ----------------------------------------------------------
EEG = pop_loadset('filename', subjects(isub).name, 'filepath', subjects(isub).folder);

% ----------------------------------------------------------
% Remove eye channels & eye tracking
% ----------------------------------------------------------

EEG = pop_select(EEG, 'channel', cfg.chans.EEGchans);

% ----------------------------------------------------------
% Add channel layout for the example data
% ----------------------------------------------------------

EEG = pop_chanedit(EEG, 'lookup', cfg.chans.chanlocs_standard);

% --------------------------------------------------------------
% High Pass Filter
%
% If requested, perform ICA on strongly HP filtered data ==> more
% stable results. We make a backup of the original data. We'll only
% save the ICA weights produced with the hp-filtered data.
% ---------------------------------------------------------------

if cfg.ica.do_ICA_hp_filter
    switch(cfg.ica.hp_ICA_filter_type)
        case('butterworth')
            EEG  = pop_basicfilter(EEG, cfg.chans.EEGchans, ...
                'Cutoff',  cfg.ica.hp_ICA_filter_limit, ...
                'Design', 'butter', 'Filter', 'highpass', 'Order',  2 );

    end
end

% ----------------------------------------------------------
% Correlation-based bad-channel rejection (CleanRawData with RANSAC)
% Requirements: data should be high-passed (~0.5–1 Hz), chanlocs must
% have X/Y/Z & continous data
%
% Sanity check for later channel rejection step
% ----------------------------------------------------------

corr_threshold   = 0.85;   % correlation cutoff
noise_threshold  = 4;      % SD above median
window_len       = 5;      % seconds
max_broken_time  = 0.40;   % fraction of recording
num_samples      = 50;     % RANSAC samples
subset_size      = 0.25;   % fraction of channels used in each sample

% Run clean_channels but capture output without modifying EEG
[~, removed_channels] = clean_channels(EEG, ...
    corr_threshold, noise_threshold, window_len, ...
    max_broken_time, num_samples, subset_size);

% Store the flags for later inspection
badchans_cor = find(removed_channels == 1);

% --------------------------------------------------------------
% Visualize bad channels
% --------------------------------------------------------------
%[windowTimes, windowData] = visualize_random_windows(EEG, badchans_cor, 30, 9, 1, 40, 'generate', [], 42);

% --------------------------------------------------------------
% "Epoching"
% --------------------------------------------------------------

EEG_ep = eeg_regepochs(EEG, 'recurrence',2, 'limits', [0 2]);

% ----------------------------------------------------------
% Channel rejection
%
% at epoch level ( > 2 SD, > 30% epochs)
% ----------------------------------------------------------

% z-score across channels, time points, and epochs % TODO change this
% to the robust version
zdat = zscore(EEG_ep.data(:));
zdat = reshape(zdat, [size(EEG_ep.data,1), size(EEG_ep.data,2), size(EEG_ep.data,3)]);

% SD (per channel, within each epoch)
epoch_sd = squeeze(std(zdat, 0, 2));

% Thresholds
thresh_sd     = 2;       % e.g., 2 SD
thresh_epoch  = 0.30;    % 30% epochs

% Proportion of "bad" epochs per channel
bad_prop = mean(epoch_sd > thresh_sd, 2);          % [nCh x 1]

% Bad channels to reject
badchans_z = find(bad_prop > thresh_epoch);

% --------------------------------------------------------------
% z-score measure output
% --------------------------------------------------------------
%[windowTimes, windowData] = visualize_random_windows(EEG, badchans_z, 30, 9, 1, 40, 'generate', [], 42);

%visualize_random_windows(EEG, badchans_z, 30, 9, 1, 40, 'use', windowTimes);

% ----------------------------------------------------------
% Channel rejection - Robust z.score &
%
% at epoch level ( > 2 robust SD, > 30% epochs)
% ----------------------------------------------------------

% robust z-score function: (x - median) / (1.4826 * MAD)
robust_zscore = @(x) (x - median(x(:))) ./ (1.4826 * mad(x(:),1));

% robust z-score across channels, time points, and epochs
rzdat = robust_zscore(EEG_ep.data(:));
rzdat = reshape(rzdat, [size(EEG_ep.data,1), size(EEG_ep.data,2), size(EEG_ep.data,3)]);

% robust "SD" (MAD) per channel, within each epoch
epoch_rsd = squeeze(1.4826 * mad(rzdat,1,2));   % [nCh x nEpoch]

% Thresholds
thresh_rsd     = 2;       % e.g., 2 robust SD
thresh_epoch   = 0.30;    % 30% epochs

% Proportion of "bad" epochs per channel
bad_prop_r = mean(epoch_rsd > thresh_rsd, 2);          % [nCh x 1]

% Bad channels to reject
badchans_rz = find(bad_prop_r > thresh_epoch);

% --------------------------------------------------------------
% robust z-score measure output
% --------------------------------------------------------------
%[windowTimes, windowData] = visualize_random_windows(EEG, badchans_rz, 10, 9, 1, 40, 'generate', [], 42);

%[windowTimes, windowData] = visualize_random_windows_raw(EEG, badchans_rz, 10, 9, 'generate', [], 42);


% ----------------------------------------------------------
%  Interpolate
% ----------------------------------------------------------

%badchans = badchans_z;

% Interpolate
%EEG_ep = eeg_interp(EEG_ep, badchans, 'spherical');

% ----------------------------------------------------------
%  Visualize - Interpolate output
% ----------------------------------------------------------

%[~, windowData_post] = visualize_random_windows(EEG_ep, badchans, [], [], 1, 40, 'use', windowTimes);


% ----------------------------------------------------------
%  Visualize - pop_rejchan - channel rejectin continuous data
% ----------------------------------------------------------

[~, badchans_kurtosis] = pop_rejchan(EEG, 'elec', 1:EEG.nbchan, ...
    'threshold', 5, ...
    'norm', 'on', ...
    'measure', 'kurt');

[~, badchans_thresh] = pop_rejchan(EEG, ...
    'elec', 1:EEG.nbchan, ...   % test all channels
    'threshold', 2, ...         % reject channels > 3 SD from mean
    'norm', 'on', ...           % normalize values
    'measure', 'prob');

[~, badchans_spec] = pop_rejchan(EEG, ...
    'elec', 1:EEG.nbchan, ...   % test all channels
    'threshold', 2, ...         % reject channels > 3 SD from mean
    'norm', 'on', ...           % normalize values
    'measure','spec' ,'freqrange',[2 40]);