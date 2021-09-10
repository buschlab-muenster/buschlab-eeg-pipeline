function EEG = func_recode_eegtrigs(EEG, LOG)
% Generate new triggers coding the conditions of interest for
% EEGManyPipelines. Check that information about scene category matches in
% old EEG triggers and new behavioral logfile, as a sanity check that the
% trial order is consistent.

triggers_new = ...
    10000 * LOG.scene_cat + ...
    1000  * LOG.scene_man + ...
    100   * LOG.is_old + ...
    10    * LOG.recog_cat + ...
    1     * LOG.subscorrect;

% Make a sanity check: information about scene category in EEG triggers and
% behavioral logfile should match.
triggers_old = [EEG.event.type];
error_beach = sum(strcmp(LOG.scene_name, 'beaches')'   & ~ismember(triggers_old, [18, 19, 20]));
error_build = sum(strcmp(LOG.scene_name, 'buildings')' & ~ismember(triggers_old, [21, 22, 23]));
error_highw = sum(strcmp(LOG.scene_name, 'highways')'  & ~ismember(triggers_old, [24, 25, 26]));
error_forst = sum(strcmp(LOG.scene_name, 'forests')'   & ~ismember(triggers_old, [27, 28, 29]));

error_sum = sum([error_beach, error_build, error_highw, error_forst]);

if error_sum == 0
    fprintf('Testing if information in EEG matches information in behavioral logfile (based on scene categories.\n')
    fprintf('Success: information is consistent!\n')
    
    % If the trigger information matches, write the new triggers into the
    % EEG structure, replacing the old triggers.
    for ievent = 1:length(EEG.event)
        EEG.event(ievent).type = triggers_new(ievent);
    end
        
else
    errormsg = sprintf('Error: EEG triggers do not match LOG info!\n');
    error(errormsg)
end


