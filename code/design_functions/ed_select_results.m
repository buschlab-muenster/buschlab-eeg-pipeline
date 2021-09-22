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
% bsl_win: optional time window for baseline correction.
% bsl_method: method for baseline correction; 'sub'= baseline subtraction,
%   'div': baseline division; 'db': 10 * log10 of division.
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

% --- Required input arguments: ---
args = inputParser;
addRequired(args, 'G', @isstruct);
addRequired(args, 'conditions');


% --- Optional input arguments: ---
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

% Optional baseline correction. Default: no baseline correction
addParameter(args, 'bsl_win', [], @isnumeric)
addParameter(args, 'bsl_method', 'sub', @isstr)


parse(args, G, conditions, varargin{:})

%%
if isempty(conditions)
    fulldesign = true;
    conditions = fullfact(G.DINFO.nlevels+1);
else
    fulldesign = false;
end


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
    
    % Baseline correction if desired.
    if ~isempty(args.Results.bsl_win)
        bsl_idx = dsearchn(G.times', args.Results.bsl_win');
        bsl = mean(alldata(:, bsl_idx(1):bsl_idx(2), :), 2);
        
        switch args.Results.bsl_method
            case 'sub'
                alldata = bsxfun(@minus, alldata, bsl);
            case 'div'
                alldata = bsxfun(@rdivide, alldata, bsl);
            case 'db'
                alldata = bsxfun(@rdivide, alldata, bsl);
                alldata = 10 .* log10(alldata);
        end
    else
%         disp('No baseline correction')
    end
        
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


																		   
											  
																		  
														

if fulldesign == true
    erpall  = reshape(erpall, G.DINFO.nlevels+1);
    erproi  = reshape(erproi, G.DINFO.nlevels+1);
										  
												
		
												 
    topo    = reshape(topo, G.DINFO.nlevels+1);
    statdat = reshape(statdat, G.DINFO.nlevels+1);
		
																														 
	   
    
									 
end

