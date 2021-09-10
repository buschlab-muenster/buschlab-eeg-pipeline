function outstruct = selectfields(instruct, varargin)
% Function to select specific fields from a bigger struct.
% Example: 
% out = selectfields(cfg, 'dir', 'prep');

outstruct = rmfield(instruct,setdiff(fieldnames(instruct),varargin )); 
