function [condition_names, condition_labels] = get_condition_names(D, DINFO)

% Helper function that returns for a given EEG set file trial indices
% corresponding to each of the conditions of a design.



% Loop across all conditions.
for icondition = 1:length(DINFO.design_matrix)
    
    condition_names{icondition} = DINFO.design_name;
    
    % Loop over all factors in the design.
    for ifactor = 1:DINFO.nfactors
        
        % Determine current factor name and factor level.
        factor_name  = char(D.factor_names(ifactor));
        factor_level = DINFO.design_matrix(icondition, ifactor);
        
        % Put together a string containing the factor values, or '*' in
        % case this is a main effect.
        if factor_level <= length(D.factor_values{ifactor}) % wrong if this is a main effect, i.e. the last factor level.
            factor_value = D.factor_values{ifactor}{factor_level};
            
            if ischar(factor_value) % single string
                factor_level_string = factor_value;
            elseif isa(factor_value, 'function_handle') % function handle
                factor_level_string = char(factor_value);
            else
                if length(factor_value) < 3 %up to 3 values still make sense in the string
                    factor_level_string = mat2str(factor_value);
                else % if more, insert a colon to indicate range
                    factor_level_string = [mat2str(factor_value(1)) ':' mat2str(factor_value(end))];
                end
            end
            
            condition_names{icondition} = [condition_names{icondition} '-' ...
                factor_name '_' factor_level_string];
            
        else
            condition_names{icondition} = [condition_names{icondition} ...
                '-' factor_name '_' '#']; %* character is forbidden.                       
        end
        
    end
    
end

