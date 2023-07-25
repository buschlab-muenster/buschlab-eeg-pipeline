function EEG = func_importBehavior(EEG, subject_name, cfgdir, cfgepoch)
%
% wm: THIS FUNCTION STILL NEEDS A PROPER DOCUMENTATION!

% (c) Niko Busch & Wanja Mössing
% (contact: niko.busch@gmail.com, w.a.moessing@gmail.com)
%
%  This program is free software: you can redistribute it and/or modify
%  it under the terms of the GNU General Public License as published by
%  the Free Software Foundation, either version 3 of the License, or
%  (at your option) any later version.
%
%  This program is distributed in the hope that it will be useful,
%  but WITHOUT ANY WARRANTY; without even the implied warranty of
%  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%  GNU General Public License for more details.
%
%  You should have received a copy of the GNU General Public License
%  along with this program. If not, see <http://www.gnu.org/licenses/>.

% This function includes the behavioral data as recorded by Psychtoolbox in
% the EEG structure.
% Problem: some recording were started too late or terminated too early, so
% that the EEG structure lacks a few trials. This function matches the EEG
% triggers with the corresponding information in the behavioral data to
% find out which information about which trials to merge.

% Load the logfile.
load([cfgdir.behavior subject_name '_Logfile.mat']);


% This code assumes that the "logfile" is a Matlab struct called Info.T,
% where T is a struct of length ntrials, such that T(17) contains all the
% info for the 17th trial. We want to automatically include all fields in
% Info.T in our new EEG structure, but we can do this only for fields that
% have scalar values.

% Change these lines accordingly if your structure has a different name.
if isfield(cfgepoch, 'trial_struct_name')
    if isempty(cfgepoch.trial_struct_name)
        Trials = Info.T;
    else
        Trials = eval(cfgepoch.trial_struct_name);
    end
else
    Trials = INFO.T;
end

fields = fieldnames(Trials);
TrialsOut = [];

% Exclude trials where the eye tracker detected bad gaze.
if isfield(Trials, cfgepoch.badgaze_fieldname)
    badtrials = [Trials.(cfgepoch.badgaze_fieldname)] == 1 | [Trials.badpress] == 1;
    Trials(badtrials) = [];
end

ntrials = length(Trials);

% loop over each field of the trial structure. Check if all values are
% scalar. Strings are not considered scalar, but as soon as it's a string
% array or cell of strings, ischar is false.
for ifield = fields'
    res = arrayfun(@(x)(isscalar(x) | ischar(x)), [Trials.(ifield{:})]);
    if ~all(res)
        Trials = rmfield(Trials, ifield{:});
    end
end


outfields = fieldnames(Trials);


%% Run through all events and import the behavioral data. The important
% assumption is that each epoch of the EEG data set corresponds to one
% trial in the logfile and the first trials in both data structures
% correspond to the same trial!
nowarn_finames = {};
for ievent = 1:length(EEG.event)
    
    thisepoch = EEG.event(ievent).epoch;
    
    for ifield = 1:length(outfields)
        
        % Check if the field in the log file is empty. If yes, fill with
        % arbitrary value.
        try
            new_event_value = Trials(thisepoch).(outfields{ifield});
        catch ME
            fprintf(2,['If you''re getting caught here, probably some trial(s) '...
                'weren''t deleted in the EEG but in the logfile data.\n'...
                'This error was thrown while processing subject',...
                subject_name]);
            error(['If you''re getting caught here, probably some trial(s) '...
                'weren''t deleted in the EEG but in the logfile data.\n'...
                'This error was thrown while processing subject',...
                subject_name]);
        end
        if isempty(new_event_value)
            fillvalue = 666;
            if ~ismember(outfields{ifield}, nowarn_finames)
                fprintf('Empty event field found on trial %d in event field %s!\n',...
                    thisepoch, outfields{ifield});
                fprintf('Filling this field with arbitrary value of %d\n', fillvalue);
                n_affected = sum(cellfun(@isempty, {Trials.(outfields{ifield})}));
                if n_affected > 1
                    prct_affected = n_affected / length(Trials) * 100;
                    fprintf(['Only informing you once, though this is the '...
                        'case for %.1f%% of trials (%i trials in total).\n'],...
                        prct_affected, n_affected);
                    nowarn_finames = [nowarn_finames, outfields(ifield)];
                end
            end
            new_event_value = fillvalue;
        end
        EEG.event(ievent).(outfields{ifield}) = new_event_value;
    end
end


%% Issue a warning if the number of trials in the Logfile does not match the
% number in the EEG file.
if length(EEG.epoch) ~= ntrials
    w = sprintf('\nEEG file has %d trials, but Logfile has %d trials.\nYou should check this!', ...
        length(EEG.epoch), ntrials);
    fid = fopen([cfgdir.eeg,'ErrorInImportBehavior.txt'], 'wt');
    fprintf(fid, w);
    fclose(fid);
    warning(w)
    error(w)
end


%% If specified in get_cfg, use latency checks to delete trials where a
%trigger differed more than 3ms from the median latency of that kind of
%trigger.
if cfgepoch.deletebadlatency
    rejidx=zeros(1,length(EEG.epoch));
    rejidx(EEG.latencyBasedRejection)=1;
    if any(rejidx)
        warning(['Deleting %i trials because they included triggers that had',...
            ' weird latency glitches for some triggers.\nYou should check',...
            ' your code and/or setup!'],sum(rejidx));
        fid = fopen([cfgdir_eeg,'TrialsWithBadLatency.txt'], 'wt');
        fprintf( fid, ['The following trials where deleted after\n',...
            'coregistration with behavioral data. That is because\n',...
            'one of the triggers %s differed by more than CFG.allowedlatency ms from the\n',...
            'median latency of this trigger across all trials.\n\n',...
            'Trials: %s\n'], num2str(cfg.checklatency), num2str(find(rejidx)));
        fclose(fid);
        [EEG, com] = pop_rejepoch(EEG,rejidx,0);
        EEG = eegh(com, EEG);
    end
end

%% Update the EEG.epoch structure.
EEG = eeg_checkset(EEG, 'eventconsistency');

% Include the full trials structure in the EEG strucutre. You never know
% when it might be useful, especially for the more complex fields that
% could not be included in the EPOCH structure.
EEG.trialinfo = Trials;

% if cfg.keep_continuous
%     CONTEEG.prep01epoch = EEG.epoch;
%     CONTEEG.contevent = CONTEEG.event;
%     CONTEEG.epochevent = EEG.event;
%     CONTEEG.trialinfo = EEG.trialinfo;
% end
end
