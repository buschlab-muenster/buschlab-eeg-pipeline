function G = get_design_matrix(D, G)
% function G = get_design_matrix(D)
% Helper function that reads in a design file and creates a design matrix.


% It is possible (optional) to define labels in the design file that are more
% descriptive or less ugle than the factor names and values. But if these
% do not exists, substitute with condition names and values.
if isfield(D, 'factor_names_label')
    G.factor_names_label = D.factor_names_label;
else
    G.factor_names_label = D.factor_names;
end

if isfield(D, 'factor_values_label')
    G.factor_values_label = D.factor_values_label;
else
    G.factor_values_label = D.factor_values;
end

G.factor_names  = D.factor_names;
G.factor_values = D.factor_values;
G.nfactors      = length(D.factor_names);

for ifactor = 1:G.nfactors
    G.nlevels(ifactor)  = length(D.factor_values{ifactor})+1;
end

% Genereate design matrix including all main effects and interactions. The
% +1 term will result in an additional factor level. In subesequent
% procedure, the last factor level will be interpreted as a main effect,
% i.e. all levels of this factor together.
G.design_matrix = fullfact(G.nlevels);