function EEG = func_import_reref(EEG, cfg)

% --------------------------------------------------------------
% Biosemi is recorded reference-free. We apply rereferincing in
% software.
% --------------------------------------------------------------
if cfg.do_rereference
    EEG = pop_reref( EEG, cfg.reref_chan, 'keepref', 'on');
end
