function EEG = func_icareject_manualinspect(EEG)

% assignin('base', 'EEG', EEG);
[EEG] = mypop_selectcomps(EEG);

% wait for decision
comp_handles = findobj('-regexp', 'tag', '^selcomp.*');
while true %
    try
        waitforbuttonpress
    catch
        if ~any(isgraphics(comp_handles))
            break
        end
    end
end
% EEG.reject.gcompreject = evalin('base', 'ALLEEG(end).reject.gcompreject');


%% 09: reconstruct signal without ICs and store output
fprintf('Removing %i components (%s)', sum(EEG.reject.gcompreject),...
    num2str(find(EEG.reject.gcompreject)));
