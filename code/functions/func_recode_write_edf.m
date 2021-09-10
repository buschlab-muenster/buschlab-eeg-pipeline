function func_recode_write_edf(EEG, cfg, isub)


% Write relevant data to CSV file.
edfname  = ['EMP', sprintf('%02d', isub), '_eeg_data.', ...
    lower(cfg.eeg_export_format)];
fullname = fullfile(cfg.dir_out, edfname);
fprintf('Exporting EEG data to %s format: %s\n.', cfg.eeg_export_format,fullname)

pop_writeeeg(EEG, fullname, 'TYPE', cfg.eeg_export_format);
disp('Done.')
