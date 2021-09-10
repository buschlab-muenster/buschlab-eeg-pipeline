function [condinfo] = get_design_trials(EEG, DINFO)

% Helper function that returns for a given EEG set file trial indices
% corresponding to each of the conditions of a design.

%%
% Loop across all conditions.
for icondition = 1:length(DINFO.design_matrix)
    
%     fprintf('Finding trials for condition %d of %d. ', ...
%         icondition, length(DINFO.design_matrix))
    
    % Loop over all factors in the design and get the trials for the levels
    % that define the current condition
    eegevents = zeros(DINFO.nfactors, size(EEG.event,2)); %preallocate
    for ifactor = 1:DINFO.nfactors
        
        % Determine current factor name and factor level.
        factor_name  = char(DINFO.factor_names(ifactor));
        factor_level = DINFO.design_matrix(icondition, ifactor);
        
        % Determine which events correspond to the desired factor level.
        if factor_level <= length(DINFO.factor_values{ifactor}) % wrong if this is a main effect.
            factor_value = DINFO.factor_values{ifactor}{factor_level};
            its_char     = ischar(factor_value);
            its_fun      = isa(factor_value, 'function_handle');
            its_main     = false;
        else %...for main effects:
            factor_value = DINFO.factor_values{ifactor};
            its_char     = cellfun(@ischar, factor_value);
            its_fun      = cellfun(@(x) isa(x, 'function_handle'), factor_value);
            its_main     = true;
        end
        
        if ~its_main
            if its_char %single string to be matched
                eegevents(ifactor,:) = strget(EEG, factor_name, factor_value);
            elseif its_fun %single function handle to be matched
                eegevents(ifactor,:) = funget(EEG, factor_name, factor_value);
            else %number(s) to be matched
                eegevents(ifactor,:) = numget(EEG, factor_name, factor_value);
            end
        elseif its_main %if it's a main effect, we need to match all levels
            for ilevel = 1:length(factor_value)
                clear foo
                if its_char(ilevel) %single string to be matched
                    foo = strget(EEG, factor_name, factor_value{ilevel});
                elseif its_fun(ilevel) %single function handle to be matched
                    foo = funget(EEG, factor_name, factor_value{ilevel});
                else %number(s) to be matched
                    foo = numget(EEG, factor_name, factor_value{ilevel});
                end
                eegevents(ifactor,:) = eegevents(ifactor,:) | foo;
            end
        end
        sanitycheck(eegevents, EEG, factor_name, factor_level, ifactor);
        condinfo(icondition).level{ifactor} = factor_level;
    end
    
    % in case we have more than two factors, the detected events are split
    % into
    if DINFO.nfactors > 1
        eegevents = all(eegevents);
    end
    
    condinfo(icondition).trials = unique([EEG.event(eegevents).epoch]);
    
%     fprintf('%d trials found\n', length(condinfo(icondition).trials));
    
    
end
end

function [eegevents] = strget(EEG, factor_name, factor_value)
try
    eegevents = ismember({EEG.event.(factor_name)}, factor_value);
catch
    eegevents = ismember([EEG.event.(factor_name)], factor_value);
end
end

function [eegevents] = funget(EEG, factor_name, factor_value)
eegevents = cellfun(factor_value, {EEG.event.(factor_name)});
end

function [eegevents] = numget(EEG, factor_name, factor_value)
%NB: I round the values in the EEG.event structure in case we
% are daling with response times, etc. E.G. if the design
% defines a factor level with values [1:200] meaning
% response times <= 200 ms, we want to include RTs of
% 105.004, although that value is not included in the 1:200
% vector, which has only integer numbers.
%WM: this is dangerous. In a preliminary analysis with hitrates
%istead of RTs, it led to very unexpected behavior without
%hints. So let's warn about that!
preelem = numel(unique([EEG.event.(factor_name)]));
roundelem = numel(unique(round([EEG.event.(factor_name)])));
if preelem ~= roundelem
    msg = sprintf(['\nIn your get_design.m, you specified '...
        '(a range of) numbers to be used to index variable'...
        ' %s.\nElektro-Pipe internally rounds this variable'...
        ' to integers, to match ranges.\nThis might not be '...
        'what you want (e.g., hitrates from 0-1 will become'...
        ' binary).\nIn fact, rounding reduced the amount of '...
        'unique elements in your variable from %i to %i!\n'...
        'Consider using a function handle instead.'],...
        factor_name, preelem, roundelem);
    warning(msg);
end

eegevents = ismember(round([EEG.event.(factor_name)]), factor_value);
end

function [] = sanitycheck(eegevents, EEG, factor_name, factor_level, ifactor)
percIncl = (sum(eegevents(ifactor,:))/EEG.trials)*100;
if percIncl < 5
    wrn = sprintf(['\n#####!DANGERZONE!########'...
        '\n###################################'...
        '\n###################################'...
        '\nFactor %s, level %i is just %.2f%% of'...
        ' trials. Is that intended?'...
        '\n###################################'...
        '\n###################################'...
        '\n###################################'],...
        factor_name, factor_level, percIncl);
    warning(wrn);
end
end