function outstruct = joinstructs(varargin)
% Join two or more struct into a single larger struct. Useful for combining
% separate substructs of the cfg structure, e.g.:
% newcfg = joinstructs(cfg.dir, cfg.chans)

fnames = [];
strctcell = [];

for istruct = 1:length(varargin)
    fnames = [fnames; fieldnames(varargin{istruct})];    
    strctcell = [strctcell; struct2cell(varargin{istruct})];
end

%%

outstruct = cell2struct(strctcell, fnames, 1);