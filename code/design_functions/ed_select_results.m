function [erpall, erproi, topo, statdat] = ed_select_results(G, conditions, varargin)
% Returns for all conditions in "conditions" data for plotting and
% for stats. 
%
% REQUIRED INPUT: 
% >>  G: a struct with grand average data, result of ed_grandaverage.
% Important: we require that erp and filtbert data have dimensions:
% channels x time x subjects; fft data have dimensions: channels x
% frequencies x subjects; time-frequency data have dimensions channels x
% frequencies x time x subjects.
%
% >> conditions: definition of the condition. Can be a numeric
% vector indicating the numerical indices of the condition of interest, or
% a cell array with pairs of "factor_name", "factor_value" pairs. A
% Factor_value '*' means collapse across all levels of this factor. E.g.
%
% cond = [3,2,3;
%         3,2,4];
%
% or
%
% cond{1} = {
%     'target_cue_w', 'MemX';
%     'saccade_cue_w', 'SaccL';
%     'response_correct', '*'};
%
% OPTIONAL INPUT (name/value pairs):
% channels: vector with indices of channels of interest. Default: all channels.
% times: 2-element vector of time window of interest in ms. Default: entire time range.
% subjects: vector with indices of subjects to process. Default: all subjects.
% frequencies: for FFT and time-frequency data, vector of frequencies in Hz. Default: all frequencies.
%
% OUTPUTS:
% All outputs are cell arrays of length n_conditions.
% >> erpall: matrix of time series for each channel and each selected subject.
% >> erproi: a time series, averaged across channels and subjects.
% >> topo: a topography averaged across a time window and subjects.
% >> statdat: a vector of subjects, averaged across channels and time window.
%
% For FFT data, averaging is across frequencies, not time.
% For time-frequency data, averaging is across both time and frequencies.

args = inputParser;
addRequired(args, 'G', @isstruct);
addRequired(args, 'conditions');

% We assume that the channel dimension is always the first dimension.
addParameter(args, 'channels', 1:size(G.data{1}, 1), @isnumeric)

% We assume that subjects is always the last dimension.
addParameter(args, 'subjects', 1:size(G.data{1}, ndims(G.data{1})), @isnumeric)

switch G.data_type
    case {'erp', 'filtbert'}
        addParameter(args, 'times', 1:size(G.data{1}, 2), @isnumeric)
        addParameter(args, 'frequencies', [])
        
    case 'fft'
        addParameter(args, 'times', [])
        addParameter(args, 'frequencies', 1:size(G.data{1}, 2), @isnumeric)
        
end

parse(args, G, conditions, varargin{:})

%%
for icond = 1:length(conditions)    
    
    if isnumeric(conditions)
        cond_idx = conditions(icond,:);
    elseif iscell(conditions)        
        cond_idx = get_condition_index(conditions{icond}, G);
    end
    
    % ------------------------------------------------------------------------
    % Get all data for that condition.
    % ------------------------------------------------------------------------
    chn = args.Results.channels;
    tim = args.Results.times;
    frq = args.Results.frequencies;
    sub = args.Results.subjects;
   
    cond_idx = num2cell(cond_idx);
    alldata = G.data{cond_idx{:}};   
        
    switch G.data_type
        case {'erp', 'filtbert'}
            
            tpoints = dsearchn(G.times', tim(1)):dsearchn(G.times', tim(2));
            
            erpall{icond}  = alldata(:, :, sub);            
            erproi{icond}  = mmean(alldata(chn, :,       sub), [1, 3]);            
            topo{icond}    = mmean(alldata(:,   tpoints, sub), [2, 3]);            
            statdat{icond} = mmean(alldata(chn, tpoints, sub), [1, 2]);
            
        case {'fft'}
            
            fpoints = dsearchn(G.fft_freqs', frq(1)):dsearchn(G.fft_freqs', frq(2));
            
            erpall{icond}  = alldata(:, :, sub);            
            erproi{icond}  = mmean(alldata(chn, :,       sub), [1, 3]);            
            topo{icond}    = mmean(alldata(:,   fpoints, sub), [2, 3]);            
            statdat{icond} = mmean(alldata(chn, fpoints, sub), [1, 2]);
    end
    
end


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
