function [ALLEEG, load_names] = eeg_load_design(cfg, d, designidx, conditions)
% function ALLEEG = eeg_load_design(cfg, d, designidx, conditions)
%
% Function for loading ERPs from one design.
%
% cfg: struct with configuration file. Important mostly for defining directories.
% d: a struct defining the statistical design.
% designidx: which of the design is to be load (must be scalar)
% conditions: OPTIONAL, cell array containing specific conditions to load.
%
% Example:
% [ALLEEG condition_names] = eeg_load_design(cfg, d, 1, {{0,1},{1,1},{'*',1}});

if ~isscalar(designidx)
    disp('Error: designidx must be scalar; You can only load a single design')
    return
end

addpath(cfg.dir_cfg);  

% Compose the file names of all conditions in this design.
dinfo = get_design_matrix(d(designidx));
dinfo.design_name = ['Grand_Design' num2str(designidx)];

%%
if nargin == 3
    % No conditions to load defined, so load all conditions by default.
    [condition_names] = get_condition_names(d(designidx), dinfo);
else
    nconditions = length(conditions);
    
    for icondition = 1:nconditions
        
        % Check if conditions are defined properly according to design
        % file.
        if length(conditions{icondition}) ~= dinfo.nfactors
            w = sprintf('\nYour design has %d factors, but condition %d defines only %d factors!', ...
                dinfo.nfactors, icondition, length(conditions{icondition}));
            warning(w)
            return
        end

        condition_names{icondition} = dinfo.design_name;
    
        % Loop over all factors in the design.
        for ifactor = 1:dinfo.nfactors   

            % Determine current factor name and factor level.
            factor_name  = char(d(designidx).factor_names(ifactor));
            factor_value = (cell2mat(conditions{icondition}(ifactor)));
            
            
            if length(factor_value) < 3
                if isstr(factor_value)
                    factor_level_string = factor_value;
                else
                    factor_level_string = mat2str(factor_value);
                end
            else
                factor_level_string = [mat2str(factor_value(1)) ':' mat2str(factor_value(end))];
            end
            
            condition_names{icondition} = [condition_names{icondition} '_' ...
                    factor_name factor_level_string];

        end   

    end    
    
end

%%
iEEG = 0;
for icondition = 1:length(condition_names)
    
    
    filename = [condition_names{icondition} '.set'];
    filepath = [cfg.dir_grand  'Grand_Design' num2str(designidx) '/'];
    
    if exist([filepath filename])
        iEEG = iEEG + 1;
        ALLEEG(iEEG) = pop_loadset('filename',  filename, 'filepath', filepath);
        load_names{iEEG} = condition_names{icondition};
    else        
        fprintf('\nWarning: did not find %s!\n', [filepath filename]);
    end
    
end
