
%% ------------------------------------------------------------------------
% Decode which condition we are interested in.
% ------------------------------------------------------------------------
function cond_idx = get_condition_index(thecondition, G)

for ifactor = 1:size(thecondition, 1)
    factor_idx   = find(strcmp(G.DINFO.factor_names, thecondition{ifactor, 1}));
    
    if isnumeric(thecondition{ifactor, 2})
        factor_level = thecondition{ifactor, 2};
        
    elseif strcmp(thecondition{ifactor, 2},  '*')
        factor_level = G.DINFO.nlevels(factor_idx)+1;
        
    else
        factor_level = find(strcmp(G.DINFO.factor_values{factor_idx}, thecondition{ifactor, 2}));
    end
    
    cond_idx(ifactor) = factor_level;
end
