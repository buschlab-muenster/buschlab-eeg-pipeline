% function script07_wavelet

%%
% Silently load EEGLAB once to load all necessary paths. Then wipe all the
% unnessesary variables.
% addpath('/data3/Niko/EEG-Many-Pipelines/toolboxes/eeglab2021.0/');
% addpath('./functions')
% eeglab nogui
% clear
% close all
% clc

%% Set configuration.
cfg = getcfg;
subjects = dir([cfg.dir_eeg '*clean.set']);

%% Run across subjects.
tic
for isub = 1:length(subjects)
    
    name = num2str(isub, '%02d'); % subject index with trailing zero
    out_eeg_name = ['EMP', name, '_TF.mat'];
    
    % Skip files that have already been analyzed.
    if exist(fullfile(cfg.dir_tf, out_eeg_name), 'file') && cfg.overwrite_tf == false
        continue
    else
        
        % Load the dataset.
        EEG = pop_loadset('filename', subjects(isub).name, 'filepath', subjects(isub).folder);
        EEG = pop_reref( EEG, cfg.reref_analysis, 'keepref','on','exclude',[cfg.VEOGchan, cfg.HEOGchan] );
        
        % Run wavelet convolution.
        TF = optimized_wavelet(EEG.data, EEG.srate, cfg);
        
        % Store some relevant information from EEG file in TF file.
        TF.times    = EEG.times;
        TF.chanlocs = EEG.chanlocs;
        TF.logfile  = EEG.logfile;
        TF.frex     = cfg.frex;
        TF.hit_rate(isub) = sum(strcmp(TF.logfile.recognition, 'hit'))        / sum(TF.logfile.is_old);
        TF.fal_rate(isub) = sum(strcmp(TF.logfile.recognition, 'falsealarm')) / sum(~TF.logfile.is_old);
        TF.dprime(isub)   = norminv(TF.hit_rate(isub)) - norminv(TF.fal_rate(isub));
        
        % Remove trials from the logfile that were rejected during
        % preprocessing.
        valid_trials = [EEG.epoch.eventtrial_no];
        EEG.logfile_valid = EEG.logfile(valid_trials,:);
        cond_trials = get_trials(cfg, EEG.logfile_valid);
        
        % Average power from relevant conditions.
        TF.pow = zeros([size(TF.mn_pow) size(cfg.conditions)]);
        
        for icond = 1:size(cfg.conditions,1)
            for ilevel = 1:length(cfg.conditions(icond,:))
                TF.pow(:,:,:,icond,ilevel) = mean(TF.st_pow(:,:,:,cond_trials{icond, ilevel}),4);
            end
        end
        TF.pow = single(TF.pow);
        
        % Remove unnecessary single trial data.
        TF.st_pow = [];
        TF.mn_pow = [];
        
        % Save TF data.
        save(fullfile(cfg.dir_tf, out_eeg_name), 'TF', '-v7.3')
    end
end
toc
disp('Done.')

