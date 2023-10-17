function EEG = func_filtbert(EEG, cfg, iband)

EEG.data = double(EEG.data);
EEG.filtbert_fband = cfg.fbands{iband};

fprintf('Running filter-Hilbert on frequency band %2.2f to %2.2f.\n', ...
    EEG.filtbert_fband(1), EEG.filtbert_fband(2))


% EEG = pop_eegfiltnew(EEG, ...
%     'locutoff', EEG.filtbert_fband(1), ...
%     'hicutoff', EEG.filtbert_fband(2), ...
%     'plotfreqz', 0);

% pop_firws does not allow filtering only a subset of trials, but we do not
% want to filter the EOG and eye tracking channels. We make a temporary
% copy of these channels.
non_eeg_chans = max(cfg.EEGchans)+1:EEG.nbchan;
tmp_data = EEG;

m = pop_firwsord(cfg.wintype, EEG.srate, cfg.transbw);

EEG = pop_firws(EEG, 'fcutoff', EEG.filtbert_fband, 'ftype', 'bandpass', ...
    'wtype', cfg.wintype, 'forder', m, 'minphase', 0, 'usefftfilt', 0, ...
    'plotfresp', 0, 'causal', 0);


% 
% tic
% for ichan = 1:size(EEG.data,1)
%     for itrial = 1:size(EEG.data,3)
%         EEG.data(ichan,:,itrial) = abs(hilbert(EEG.data(ichan,:,itrial))).^2;
%     end
% end
% toc

% We have to permute the data because hilbert always works along the
% columns. Permuting is a lot faster than looping across channels and
% trials.
% tic
EEG.data = permute(EEG.data, [2 1 3]);
EEG.data = abs(hilbert(EEG.data));
% EEG.data = abs(hilbert(EEG.data)).^2;
EEG.data = ipermute(EEG.data, [2 1 3]);


% Paste our temporary copy of unfiltered EOG/eye tracking channels.
EEG.data(non_eeg_chans,:,:) = tmp_data.data(non_eeg_chans,:,:);
% toc

EEG.data = single(EEG.data);
