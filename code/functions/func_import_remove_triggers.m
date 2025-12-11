function EEG = func_import_remove_triggers(EEG, cfg)

disp("Removing unwanted triggers.")

if isfield(EEG.event,'device') && ~isempty(cfg.trigger_device)
    fprintf('\nRemoving all event markers not sent by %s...\n',cfg.trigger_device);
    [EEG, ~, com] = pop_selectevent( EEG, 'device', cfg.trigger_device, 'deleteevents','on');
    EEG = eegh(com, EEG);
end

done();