function edges = eqpop(X, nb, varargin)
% EQPOP Builds edges for equipopulated binning

%   Copyright (C) 2009 Cesare Magri
%   Version: 1.0.0

% -------
% LICENSE
% -------
% This software is distributed free under the condition that:
%
% 1. it shall not be incorporated in software that is subsequently sold;
%
% 2. the authorship of the software shall be acknowledged and the following
%    article shall be properly cited in any publication that uses results
%    generated by the software:
%
%      Magri C, Whittingstall K, Singh V, Logothetis NK, Panzeri S: A
%      toolbox for the fast information analysis of multiple-site LFP, EEG
%      and spike train recordings. BMC Neuroscience 2009 10(1):81;
%
% 3.  this notice shall remain in place in each source file.

uniqueX = unique(X(:));

N = length(uniqueX);
if N<nb
    error('Too many bins for the selected data.');
end;

ValsxBin = floor(N/nb); % Rounded number of values-per-bin
r = N - (ValsxBin*nb);  % Remainder

indx = 1:ValsxBin:ValsxBin*nb;
indx(1:r) = indx(1:r) + (0:(r-1));
indx(r+1:end) = indx(r+1:end) + r;

edges = zeros(nb+1,1);
edges(1:nb) = uniqueX(indx);
edges(nb+1) = uniqueX(end) + 1;