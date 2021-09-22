function EEGout = func_final_channelinterp(EEG, cfg)
% Interpolate bad channels.
% Definition of bad channels is: a channel with larger variability across
% time compared to all other EEG channels.

% z-score the EEG data according to mean and std of all data from all
% channels concatenated. This preserves differences in variability between
% channels.
dat = EEG.data(cfg.EEGchans, :);
dat = zscore(dat(:));
dat = reshape(dat, [length(cfg.EEGchans), EEG.pnts*EEG.trials]);

% Find channels whos standard deviation (in z-score units) is above
% threshold and interpolate them.
channel_std = std(dat, [], 2);
badchans = find(channel_std > cfg.channel_interp_zthresh);

EEGout = eeg_interp(EEG, badchans, cfg.channel_interp_method);
EEGout.interp_chans = badchans;

% ------------------------------------------------------------------------
fprintf('Found %d bad channels with standard deviation > %2.2f:\n', ...
    length(badchans), cfg.channel_interp_zthresh)
fprintf('%g ', badchans)
fprintf('\n')