function [eegout, baseline, basemin, basemax] = my_bslcorrect(eegin, timedim, mytimes, baseint, method);
% function [eegout, baseline, basemin, basemax] = my_bslcorrect(in, timedim, times, baseint, method);
% baseline correction for time series
%
% in: input data with arbitrary size.
% timedim: which dimension in "in" represents time (i.e. sampling points)?
% mytimes: vector with time points (e.g. EEG.times). CAUTION: times vector
% must be in SECONDS!
% baseint: vector with start and end of baseline interval in SECONDS (e.g. [-.400 0]).
% method: 'sub' for baseline subtraction or 'div' for division.
%
% Output:
% eegout: baseline corrected EEG
% baseline: matrix of the same dimensions as the input/output data which was subtracted/divided from the input data to yield the output data.
% basemin, basemax: sampling points corresponding to baseline start and baseline end.

% Written by Niko Busch - Charité Berlin (niko.busch@gmail.com)
%
% 2011-05-23
% 2011-06-16 function does not use "eval" anymore. Added feature for doing baseline subjetraction and division in the same script.
% 2011-06-17 function now returns as output the baseline matrix and the sampling points corresponding to baseline start and baseline end.
% 2011-08-03 NB: using permute and ipermute. Makes the function more
% flexible and shorter, too.
%%
% Look at the mytimes vector and try to guess whether it is in seconds or
% miliseconds. If the numbers have values larger than 1000, we assume that
% the numbers represent miliseconds, and we divide by 1000 to convert the
% values to seconds.
if max(abs(mytimes(:)))>1000
    disp('Assuming times vector is in miliseconds.');
    mytimes = mytimes/1000;
end


% Calculate the sampling points in "in" that correspond to start and end of
% the baseline interval.
[~, basemin] = min(abs(mytimes-baseint(1)));
[~, basemax] = min(abs(mytimes-baseint(2)));

estring = 'baseline = mean(eegin(';

for idim = 1:ndims(eegin)
    if idim == timedim
        estring = [estring 'basemin:basemax'];
    else
        estring = [estring ':'];
    end
    
    if idim<ndims(eegin)
        estring = [estring ','];
    end
end
estring = [estring '), timedim);'];

eval(estring);

dimension2repeat = size(eegin) ./ size(baseline);
baseline = repmat(baseline, dimension2repeat);


% Do the baseline correction
if strcmp(method, 'sub')
	eegout = eegin - baseline;
elseif strcmp(method, 'div')
	eegout = eegin ./ baseline;
else
	fprintf('\n\nunknown method - use `sub` or `div`\Å†\n')
end

