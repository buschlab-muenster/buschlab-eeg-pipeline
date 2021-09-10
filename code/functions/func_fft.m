function EEG = func_fft(EEG, cfg)

EEG = EEG;
EEG.data = double(EEG.data);

% --------------------------------------------------------------
% Run FFT.
% --------------------------------------------------------------
EEG.fft_twin = cfg.twin;
EEG.fft_xwin = dsearchn(EEG.times', EEG.fft_twin');

[EEG.fft_amps, EEG.fft_freqs] = my_fft(...
    EEG.data(:,EEG.fft_xwin(1):EEG.fft_xwin(end),:), 2, ...
    EEG.srate, cfg.fft_npoints, 0);

EEG.data = single(EEG.data);

fprintf('Running FFT on time window %2.2f to %2.2f.\n', EEG.fft_twin(1), EEG.fft_twin(2))
