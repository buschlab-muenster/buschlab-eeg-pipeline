function outstruct = joinstructs(varargin)

names = [fieldnames(struct1); fieldnames(struct2)];
struct3 = cell2struct([struct2cell(struct1); struct2cell(struct2)], names, 1);