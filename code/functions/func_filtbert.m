function EEG = func_filtbert(EEG, cfg)

EEG.data = double(EEG.data);
EEG.filtbert_fband = cfg.fbands;

EEG = pop_eegfiltnew(EEG, ...
    'locutoff', EEG.filtbert_fband(1), ...
    'hicutoff', EEG.filtbert_fband(2), ...
    'plotfreqz', 0);
% 
% tic
% for ichan = 1:size(EEG.data,1)
%     for itrial = 1:size(EEG.data,3)
%         EEG.data(ichan,:,itrial) = abs(hilbert(EEG.data(ichan,:,itrial))).^2;
%     end
% end
% toc

% We have to permute the data because hilbert always works along the
% columns. Permuting is a lot faster than looping across channels and
% trials.
% tic
EEG.data = permute(EEG.data, [2 1 3]);
EEG.data = abs(hilbert(EEG.data)).^2;
EEG.data = ipermute(EEG.data, [2 1 3]);
% toc

EEG.data = single(EEG.data);

fprintf('Running filter-Hilbert on frequency band %2.2f to %2.2f.\n', ...
    EEG.filtbert_fband(1), EEG.filtbert_fband(2))
