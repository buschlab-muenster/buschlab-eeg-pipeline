function [DT] = EEG_to_Longtable(EEG, outfile, datafieldname)
% EEG_TO_LONGTABLE(EEG, outfile) converts EEG to 2d Longtable for export
%
% This function is useful for converting the typical EEG structure 
% produced by Elektro-Pipe or eeglab to a 2d table which can be exported to
% csv and read by other programs such as R. writes a csv if filname
% provided.
%
% Currently supports: 3D ERP, 3D FFT, single-trial FFT (N cells with 3D
% FFT)
%
% Input:
%       EEG: structure with fields 'data', 'nbchan', 'pnts',
%            'chanlocs.labels', and 'times'
%       outfile: (path+)name of the file. default does not write a csv.
%
% Author: Wanja Moessing, moessing@wwu.de, May 2019

if nargin > 2
    if ~isempty(datafieldname)
        data = datafieldname;
    elseif isfield(EEG, 'data')
        data = 'data';
    elseif isfield(EEG, 'avgfft')
        data = 'avgfft';
    end
end

if isnumeric(EEG.(data))
% detect dimensions of data
switch ndims(EEG.(data))
    case 3 
        if isfield(EEG, 'avgfft') 
            % assert that order of dimensions is exactly: channel*pnts*id
            sz = size(EEG.(data));
            chandim = find(sz == length(EEG.chans));
            freqdim = find(sz == length(EEG.freqs{1}));
            alldims = 1:3;
            subjdim = alldims(~ismember(alldims, [chandim, freqdim]));
            EEG.(data) = permute(EEG.(data), [chandim, freqdim, subjdim]);
            TimesOrFreqs = EEG.freqs{1};
        else
            % assert that order of dimensions is exactly: channel*pnts*id
            sz = size(EEG.(data));
            chandim = find(sz == EEG.nbchan);
            timedim = find(sz == EEG.pnts);
            alldims = 1:3;
            subjdim = alldims(~ismember(alldims, [chandim, timedim]));
            EEG.(data) = permute(EEG.(data), [chandim, timedim, subjdim]);
            TimesOrFreqs = EEG.times;
        end
        % preallocate ram
        [TimeOrFreq, value] = deal(zeros(numel(EEG.(data)), 1));
        ID = zeros(numel(EEG.(data)), 1, 'int8');
        Channel = cell(numel(EEG.(data)), 1);
        
        % loop over electrodes and subjects and flatten stuff
        % Should be faster with reshape(). However, if ram has been 
        % preallocated, this is quite fast and much better readable.
        pnts = size(EEG.(data), 2);
        k = 1;
        for id = 1:size(EEG.(data), 3)
            fprintf('Subject %i\n', id);
            for ich = 1:size(EEG.(data), 1)
                kk = k - 1 + pnts;
                value(k:kk) = squeeze(EEG.(data)(ich, :, id));
                ID(k:kk) = repmat(id, 1, pnts);
                Channel(k:kk) = repmat({EEG.chanlocs(ich).labels}, 1, pnts);
                TimeOrFreq(k:kk) = TimesOrFreqs;
                k = kk + 1;
            end
        end
        
        DT = table(ID, Channel, TimeOrFreq, value);
    case 4
       
    otherwise
        error('Cannot handle %i dimensions yet', ndims(EEG.(data)));
end
elseif iscell(EEG.(data)) %like for single trial FFT, where we cannot concatenate because the trial dimension might differ
    switch ndims(EEG.(data){1})
        case 3
            sz = size(EEG.(data){1});
            chandim = find(sz == length(EEG.chans));
            freqdim = find(sz == length(EEG.freqs{1}));
            alldims = 1:3;
            trldim = alldims(~ismember(alldims, [chandim, freqdim]));
            EEG.(data) = cellfun(@(x) permute(x, [chandim, freqdim, trldim]), EEG.(data), 'UniformOutput', false);
            TimesOrFreqs = EEG.freqs{1};
            
            % preallocate ram
            n_elem = sum(cellfun(@numel, EEG.(data)));
            [TimeOrFreq, value] = deal(zeros(n_elem, 1));
            ID = zeros(n_elem, 1, 'int8');
            Trial = zeros(n_elem, 1, 'int16');
            Channel = cell(n_elem, 1);
            
            % loop over electrodes and subjects and flatten stuff
            % Should be faster with reshape(). However, if ram has been
            % preallocated, this is quite fast and much better readable.
            
            nbchan = size(EEG.(data){1}, chandim);
            k = 1;
            for id = 1:numel(EEG.(data))
                fprintf('Subject %i\n', id);
                pnts = size(EEG.(data){id}, freqdim);
                for ich = 1:nbchan
                    for itrl = 1:size(EEG.(data){id}, trldim)
                        kk = k - 1 + pnts;
                        value(k:kk) = squeeze(EEG.(data){id}(ich, :, itrl));
                        ID(k:kk) = repmat(id, 1, pnts);
                        Trial(k:kk) = repmat(itrl, 1, pnts);
                        Channel(k:kk) = repmat({EEG.chanlocs(ich).labels}, 1, pnts);
                        TimeOrFreq(k:kk) = TimesOrFreqs;
                        k = kk + 1;
                    end
                end
            end
            
            DT = table(ID, Trial, Channel, TimeOrFreq, value);
            
            
        otherwise
            error('Cannot handle cells with %i-D substructures yet', ndims(EEG.(data){1}));
    end
end

% write table to csv if desired
if nargin > 1
    if ~isempty(outfile)
        writetable(DT, outfile);
    end
end

end
