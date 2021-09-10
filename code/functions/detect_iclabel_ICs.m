
function [EEG, reason] = detect_iclabel_ICs(EEG, CFG)
if CFG.do_iclabel_ica
    % run classification
    EEG = iclabel(EEG);
    
    % check if each category has a unique threshold
    if length(CFG.iclabel_min_acc) == 1
        thr = repelem(CFG.iclabel_min_acc, length(CFG.iclabel_rm_ICtypes));
    end
    
    % loop over the to-be-rejected categories and flag ICs
    rej = false(1, size(EEG.icaact, 1));
    reason = cell(1, size(EEG.icaact, 1));
    acc = EEG.etc.ic_classification.ICLabel.classifications;
    lbl = EEG.etc.ic_classification.ICLabel.classes;
    for icat = CFG.iclabel_rm_ICtypes
        class = strcmp(lbl, icat);
        thrclass = strcmp(CFG.iclabel_rm_ICtypes, icat);
        comp = acc(:, class) >= thr(thrclass);
        if any(comp)
            rej(comp) = true;
            reason(comp) = icat;
        end
    end
    fprintf('removing %i components (categories: %s)\n',...
        sum(rej), strjoin(reason(~cellfun(@isempty, reason)), ', '));
%     EEG = remember_old_ICs(EEG, rej);
else
    reason = [];
end
end