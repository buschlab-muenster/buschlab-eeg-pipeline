%% Set preferences, configuration and load list of subjects.
clear; clc; close all

restoredefaultpath
cfg   = get_cfg;

eeglab nogui

addpath(fullfile(cfg.dir.eeglab,'plugins','erplab', 'pop_functions'))
addpath(fullfile(cfg.dir.eeglab,'plugins','erplab', 'functions'))

% ------------------------------------------------------------------------
% **Important**: these variables determine which data files are used as
% input and output. 
suffix_in  = 'prep';
suffix_out = 'ICA_prep';
do_overwrite = false;
% ------------------------------------------------------------------------

subjects = get_list_of_subjects(cfg.dir, do_overwrite, suffix_in, suffix_out);

%% Run across subjects.

%nthreads = min([prefs.max_threads, length(subjects)]);

%parfor(isub = 1:length(subjects), nthreads) % set nthreads to 0 for normal for loop.

for isub = 3%:length(subjects)    
    
    % ----------------------------------------------------------
    % Load the dataset.
    % ----------------------------------------------------------
    EEG = pop_loadset('filename', subjects(isub).name, 'filepath', subjects(isub).folder);


    % ----------------------------------------------------------
    % Remove eye channels 
    % ----------------------------------------------------------

    EEG = pop_select(EEG, 'channel', setdiff(1:EEG.nbchan, [cfg.chans.VEOGchan, cfg.chans.HEOGchan]));


    % ----------------------------------------------------------
    % Add channel layout for the example data 
    % ----------------------------------------------------------
     
    EEG = pop_chanedit(EEG, 'lookup', cfg.chans.chanlocs_standard);

    % --------------------------------------------------------------
    % High Pass Filter
    % 
    % If requested, perform ICA on strongly HP filtered data ==> more
    % stable results. We make a backup of the original data. We'll only
    % save the ICA weights produced with the hp-filtered data.
    % ---------------------------------------------------------------
    
    if cfg.ica.do_ICA_hp_filter
        nonhpEEG = EEG;
        switch(cfg.ica.hp_ICA_filter_type)
            case('butterworth')
                EEG  = pop_basicfilter( EEG, cfg.chans.EEGchans, ...
                    'Cutoff',  cfg.ica.hp_ICA_filter_limit, ...
                    'Design', 'butter', 'Filter', 'highpass', 'Order',  2 );

        end
    end


    % ----------------------------------------------------------
    % Correlation-based bad-channel rejection (CleanRawData)
    % Requirements: data should be high-passed (~0.5–1 Hz), chanlocs must
    % have X/Y/Z & continous data 
    % 
    % Sanity check for later channel rejection step
    % ----------------------------------------------------------

    corr_threshold  = 0.80;   % correlation cutoff
    noise_threshold = 4;      % SD above median
    window_len      = 5;      % seconds
    max_broken_time = 0.40;   % fraction of recording
    num_samples     = 50;
    subset_size     = 0.25;
    
    % Run clean_channels but capture output without modifying EEG
    [~, removed_channels] = clean_channels(EEG, ...
        corr_threshold, noise_threshold, window_len, ...
        max_broken_time, num_samples, subset_size);
    
    % Store the flags for later inspection
    badchans_cor = removed_channels;

    % --------------------------------------------------------------
    % Visualize bad channels 
    % --------------------------------------------------------------








    % --------------------------------------------------------------
    % "Epoching"
    % --------------------------------------------------------------
    
    EEG = eeg_regepochs(EEG, 'recurrence',2, 'limits', [0 2]);

    % ----------------------------------------------------------
    % Channel rejection 
    % 
    % at epoch level ( > 2 SD, > 30% epochs) 
    % ----------------------------------------------------------
    
    % z-score across channels, time points, and epochs
    zdat = zscore(EEG.data(:));
    zdat = reshape(zdat, [size(EEG.data,1), size(EEG.data,2), size(EEG.data,3)]);
    
    % SD (per channel, within each epoch)
    epoch_sd = squeeze(std(zdat, 0, 2));            
    
    % Thresholds
    thresh_sd     = 2;       % e.g., 2 SD
    thresh_epoch  = 0.30;    % 30% epochs
    
    % Proportion of "bad" epochs per channel
    bad_prop = mean(epoch_sd > thresh_sd, 2);          % [nCh x 1]
    
    % Bad channels to reject
    badchans_z = find(bad_prop > propThresh);


    % ----------------------------------------------------------
    %  Visualize
    % ----------------------------------------------------------












    % ----------------------------------------------------------
    %  Interpolate
    % ----------------------------------------------------------




    EEG = eeg_interp(EEG, badchans, 'spherical');




    % ----------------------------------------------------------
    %  Visualize
    % ----------------------------------------------------------






    % ----------------------------------------------------------
    % Epoch rejection
    % ----------------------------------------------------------
    



    % ----------------------------------------------------------
    %  Visualize
    % ---------------------------------------------------------




    % I do a temorary baseline correction, otherwise the rejection by
    % extreme amplitudes gets confused if there are still some DC
    % shifts in the raw data. However, we apply the trial rejection to
    % the un-baseline corrected data, because ICA likes that better.
    tmpeeg = pop_rmbase(EEG, [], [], cfg.chans.EEGchans);
    
    % Reject trials with extreme amplitude values.
    [EEg2, ~] = pop_eegthresh(EEG, 1, cfg.chans.EEGchans, ...
        -cfg.rej.rejthresh_pre_ica, cfg.rej.rejthresh_pre_ica, EEG.xmin, EEG.xmax, 1, 0);
    
    % Temporary average reference. Necessary because joint prob. cannot
    % handle empty reference channel.
    if ~strcmp(tmpeeg.ref, 'averef')
        tmpeeg = pop_reref( tmpeeg, [], 'keepref','on','exclude');
    end
    
    tmpeeg = pop_jointprob(tmpeeg, 1, cfg.chans.EEGchans, ...
        cfg.rej.rej_jp_singchan, cfg.rej.rej_jp_allchans, 1, 0, 0);
    
    rejinds = find(tmpeeg.reject.rejthresh | tmpeeg.reject.rejjp);
    
    % Reject those bad trials from the raw data.
    EEGbad = eeg_emptyset; % Initialize with an empyt set in case no bad trials are found.
    if ~isempty(rejinds)
        EEGbad = pop_select( EEG, 'trial',   rejinds);
        EEG    = pop_select( EEG, 'notrial', rejinds);
    end
   
    EEG.rejected_trials = rejinds;
        
    % ----------------------------------------------------------
    % Change the EEG.setname and save the data to disk under a new name.
    % ----------------------------------------------------------
    EEG = func_saveset(EEG, subjects(isub));

    EEGbad = pop_editset(EEGbad, 'setname', [subjects(isub).namestr ' prep1 BAD TRIALS']);
    pop_saveset(EEGbad, 'filename', ['bad' subjects(isub).outfile], 'filepath', subjects(isub).outdir);
    
end

disp('Done.')
