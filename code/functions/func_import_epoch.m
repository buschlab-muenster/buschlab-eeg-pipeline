function EEG = func_import_epoch(EEG, cfg, coregister_Eyelink)
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


%% actual epoching
[EEG, ~, com] = pop_epoch( EEG, strread(num2str(cfg.trig_target),'%s')',...
    [cfg.tlims(1) cfg.tlims(2)], ...
    'newname', 'BDF file epochs', 'epochinfo', 'yes');
EEG = eegh(com, EEG);

%% remove all epochs containing triggers specified in CFG.trig_omit
% or not containing all triggers in CFG.trig_omit_inv
if ~isempty(cfg.trig_omit) || ~isempty(cfg.trig_omit_inv)
    rejidx = zeros(1,length(EEG.epoch));
    if coregister_Eyelink %coregistered triggers contain strings
        for i=1:length(EEG.epoch)
            switch cfg.trig_omit_inv_mode
                case {'AND', 'and', 'And'}
                    if sum(ismember(num2str(cfg.trig_omit(:)),...
                            EEG.epoch(i).eventtype(:)))>=1 ||...
                            ismember(i,[cfg.trial_omit]) ||...
                            (~isempty(cfg.trig_omit_inv) &&...
                            ~all(ismember(num2str(cfg.trig_omit_inv(:)),...
                            EEG.epoch(i).eventtype(:))))
                        rejidx(i) =  1;
                    end
                case {'OR', 'or', 'Or'}
                    if sum(ismember(num2str(cfg.trig_omit(:)),...
                            EEG.epoch(i).eventtype(:)))>=1 ||...
                            ismember(i,[cfg.trial_omit]) ||...
                            (~isempty(cfg.trig_omit_inv) &&...
                            ~any(ismember(num2str(cfg.trig_omit_inv(:)),...
                            EEG.epoch(i).eventtype(:))))
                        rejidx(i) =  1;
                    end
            end
        end
    else
        for i=1:length(EEG.epoch)
            switch cfg.trig_omit_inv_mode
                case {'AND', 'and', 'And'}
                    if sum(ismember(cfg.trig_omit,[EEG.epoch(i).eventtype{:}]))>=1 ||...
                            ismember(i,[cfg.trial_omit]) ||...
                            (~isempty(cfg.trig_omit_inv) &&...
                            ~all(ismember(cfg.trig_omit_inv,[EEG.epoch(i).eventtype{:}])))
                        rejidx(i) =  1;
                    end
                case {'OR','Or','or'}
                    if sum(ismember(cfg.trig_omit,[EEG.epoch(i).eventtype{:}]))>=1 ||...
                            ismember(i,[cfg.trial_omit]) ||...
                            (~isempty(cfg.trig_omit_inv) &&...
                            ~any(ismember(cfg.trig_omit_inv,[EEG.epoch(i).eventtype{:}])))
                        rejidx(i) =  1;
                    end
            end
        end
    end
    
    EEG = pop_rejepoch(EEG, rejidx, 0);
    EEG = eegh(com, EEG);
end

end