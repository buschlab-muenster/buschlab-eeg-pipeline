% function script06_grandaverage

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

%%
eeginfo = pop_loadset('filename', subjects(1).name, ...
    'filepath', subjects(1).folder, ...
    'loadmode', 'info');

grand.data = nan(eeginfo.nbchan, eeginfo.pnts, length(subjects), size(cfg.conditions,1), 2);


for isub = 1:length(subjects)
    
    name = num2str(isub, '%02d'); % subject index with trailing zero
    out_eeg_name = ['EMP', name, '_clean'];
    
    % Load the dataset.
    EEG = pop_loadset('filename', subjects(isub).name, 'filepath', subjects(isub).folder);
    EEG = pop_rmbase(EEG, [EEG.times(1) 0]);
    
    % Remove trials from the logfile that were rejected during
    % preprocessing.
    valid_trials = [EEG.epoch.eventtrial_no];
    EEG.logfile_valid = EEG.logfile(valid_trials,:);
    cond_trials = get_trials(cfg, EEG.logfile_valid);
        
    for icond = 1:size(cfg.conditions,1)
        for ilevel = 1:length(cfg.conditions(icond,:))
            grand.data(:, :, isub, icond, ilevel) = mean(EEG.data(:,:,cond_trials{icond, ilevel}),3);
        end
    end

    grand.hit_rate(isub) = sum(strcmp(EEG.logfile.recognition, 'hit'))        / sum(EEG.logfile.is_old);
    grand.fal_rate(isub) = sum(strcmp(EEG.logfile.recognition, 'falsealarm')) / sum(~EEG.logfile.is_old);
    grand.dprime(isub)   = norminv(grand.hit_rate(isub)) - norminv(grand.fal_rate(isub));
    
end

grand.chanlocs = EEG.chanlocs;
grand.times = EEG.times;
grand.srate = EEG.srate;
save('grandaverage.mat', 'grand')

disp('Done.')