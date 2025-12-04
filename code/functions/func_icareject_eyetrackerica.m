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

% Return logical vector (not indices) for consistency with other functions
bad_ics = EEG.reject.gcompreject;
bad_ics = logical(bad_ics(:));  % Force column vector and ensure logical
% Ensure output size matches number of ICs
n_components = size(EEG.icaweights, 1);
if length(bad_ics) ~= n_components
    badics_temp = zeros(n_components, 1);
    badics_temp(1:length(bad_ics)) = bad_ics;
    bad_ics = logical(badics_temp);
end

fprintf('Found %d bad ICs (eyetracker correlation).\n', sum(bad_ics));
