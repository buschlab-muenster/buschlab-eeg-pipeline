function [bad_ics, vartable] = func_icareject_eyetrackerica(EEG, cfg)

types = unique({EEG.event.type});
fixdx = cellfun(@(x) endsWith(x, 'fixation') ||...
    startsWith(x, 'fixation'), types);
sacdx = cellfun(@(x) endsWith(x, 'saccade') ||...
    startsWith(x, 'saccade'), types);
if sum(fixdx) ~= 1 || sum(sacdx) ~= 1
    error(['Could not determine unique fixation and or saccade',...
        ' identifier event. Consider renaming in EEG.event.type']);
end

% make all latencies integers to avoid index warning in
% geticavariance.m
if all(arrayfun(@isscalar, [EEG.event.latency]))
    tmp = cellfun(@int64, {EEG.event.latency}, 'UniformOutput', 0);
    [EEG.event.latency] = tmp{:};
end

flag_mode = 3;
plotfig = 0;
topomode = 4;

[EEG, vartable] = pop_eyetrackerica(EEG, types{sacdx},...
    types{fixdx}, cfg.eyetracker_ica_sactol, ...
    cfg.eyetracker_ica_varthresh, ...
    flag_mode, plotfig, topomode);

bad_ics = find(EEG.reject.gcompreject);
