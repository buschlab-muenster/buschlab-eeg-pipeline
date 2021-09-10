function EEGout = func_import_eyechans(EEGin, cfg)

% --------------------------------------------------------------
% Compute VEOG and HEOG.
% --------------------------------------------------------------
EEGout = EEGin;

EEGout.data(cfg.VEOGchan,:,:) = mean(EEGout.data(cfg.VEOGin{1},:),1) - mean(EEGout.data(cfg.VEOGin{2},:),1); % VEOG
EEGout.data(cfg.HEOGchan,:,:) = mean(EEGout.data(cfg.HEOGin{1},:),1) - mean(EEGout.data(cfg.HEOGin{2},:),1); % HEOG

EEGout.chanlocs(cfg.VEOGchan).labels = 'VEOG';
EEGout.chanlocs(cfg.HEOGchan).labels = 'HEOG';

EEGout.nbchan = size(EEGout.data,1);
EEGout = eeg_checkset(EEGout, 'chanlocsize', 'chanlocs_homogeneous');
