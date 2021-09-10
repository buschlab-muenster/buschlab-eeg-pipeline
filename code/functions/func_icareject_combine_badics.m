function EEG = func_icareject_combine_badics(EEG, new_ics)

% ------------------------------------------------------------------
% combine IC detection of multiple mechanisms
% ------------------------------------------------------------------
  
ncomps = size(EEG.icaact, 1);
if isfield(EEG, 'reject')
    if isfield(EEG.reject, 'gcompreject')
        old_ics = EEG.reject.gcompreject;
    else
        old_ics = false(1, ncomps);
    end
else
    old_ics = false(1, ncomps);
end

% check if new_ICs are numeric or logical indexes
if length(new_ics) ~= ncomps || ~all(ismember(new_ics, [0, 1]))
    old_ics(new_ics) = true;
else
    old_ics = old_ics | new_ics;
end

EEG.reject.gcompreject = old_ics;
end