function EEG = func_import_reref(EEG, cfg)

% --------------------------------------------------------------
% Biosemi is recorded reference-free. We apply rereferincing in
% software. Make sure to exclude the non-EEG channels, i.e. HEOG, VEOG, and
% eyetracking data.
% --------------------------------------------------------------
if cfg.do_rereference
    EEG = pop_reref( EEG, cfg.reref_chan, 'keepref', 'on', ...
        'exclude',[max(cfg.EEGchans)+1:EEG.nbchan] );
end

done("rereferencing");
