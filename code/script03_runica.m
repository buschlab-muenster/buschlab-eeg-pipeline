%% Set preferences, configuration and load list of subjects.
clear; clc; close all

restoredefaultpath
prefs = get_prefs('eeglab_all', 1);
cfg   = get_cfg;

% ------------------------------------------------------------------------
% **Important**: these variables determine which data files are used as
% input and output. 
suffix_in  = 'prep1';
suffix_out = 'ica';
do_overwrite = false;
% ------------------------------------------------------------------------

subjects = get_list_of_subjects(cfg.dir, do_overwrite, suffix_in, suffix_out);

% ------------------------------------------------------------------------
% Set the random seed of the random number generator. Doing it this way is
% recommended instead of "rng" for parfor loops.
% ------------------------------------------------------------------------
sc = parallel.pool.Constant(RandStream('Threefry'));

% ------------------------------------------------------------------------
% Add path to ERPLAB plugin for Butterworth filter.
% ------------------------------------------------------------------------
eeglabdir = fileparts(which('eeglab'));
add_dir = dir([eeglabdir, '/plugins/ERPLAB*']);
addpath(genpath([add_dir.folder, filesep, add_dir.name, filesep]));

%% Run across subjects.
nthreads = min([prefs.max_threads, length(subjects)]);
parfor(isub = 1:length(subjects), nthreads) % set nthreads to 0 for normal for loop.
    % for isub = 1%:length(subjects)
    
    
    % --------------------------------------------------------------
    % Load the dataset.
    % --------------------------------------------------------------
    EEG = pop_loadset('filename', subjects(isub).name, 'filepath', subjects(isub).folder);
    EEG.data = double(EEG.data);
    
    % --------------------------------------------------------------
    % Set the rng to a fixed value so that everybody always gets the
    % same results. The exact value does not matter, 3 is a lucky
    % number.
    % --------------------------------------------------------------
    stream = sc.Value;        % Extract the stream from the Constant
    stream.Substream = 1; % Set stream to constant value so that each parfor iteration uses same seed.
    
    % --------------------------------------------------------------
    % If requested, perform ICA on strongly HP filtered data ==> more
    % stable results. We make a backup of the original data. We'll only
    % save the ICA weights produced with the hp-filtered data.
    % --------------------------------------------------------------
    if cfg.ica.do_ICA_hp_filter
        
        
        
        nonhpEEG = EEG;
        switch(cfg.ica.hp_ICA_filter_type)
            case('butterworth')
                EEG  = pop_basicfilter( EEG, cfg.chans.EEGchans, ...
                    'Cutoff',  cfg.ica.hp_ICA_filter_limit, ...
                    'Design', 'butter', 'Filter', 'highpass', 'Order',  2 );
        end
    end
    
    % --------------------------------------------------------------
    % If requested, overweight brief saccade intervals containing spike
    % potentials (see Dimigen's OPTICAT)
    % --------------------------------------------------------------    
    if cfg.ica.ica_overweight_sp
        % Mark Eyetracking based occular artifacts
        % try to guess what saccades are called in our dataset
        types = unique({EEG.event.type});
        sacdx = cellfun(@(x) endsWith(x, 'saccade') ||...
            startsWith(x, 'saccade'), types);
        if sum(sacdx) ~= 1
            error(['Could not determine unique saccade',...
                ' identifier event. Consider renaming in EEG.event.type']);
        end
        EEG = pop_overweightevents(EEG, types{sacdx},...
            [cfg.ica.opticat_saccade_before, cfg.ica.opticat_saccade_after],...
            cfg.ica.opticat_ow_proportion, cfg.ica.opticat_rm_epochmean);
        % pop_overweightevents has an issue with the recent version of
        % eeglab's pop_rmbase - edit overweightevents.m to use
        % sac = pop_rmbase(sac,[], []);
        % instead of sac = pop_rmbase(sac,[]);
        
        % retin information on rank reduction
        EEG.etc = nonhpEEG.etc;
    end
    
    % --------------------------------------------------------------
    % Run ICA.
    % --------------------------------------------------------------
    if cfg.ica.ica_ncomps == 0
        [EEG, com] = pop_runica(EEG, 'icatype', 'runica', ...
            'extended', 1, ...
            'chanind', cfg.ica.ica_chans);
    else
        [EEG, com] = pop_runica(EEG, 'icatype', 'runica', ...
            'extended', 1, ...
            'chanind', cfg.ica.ica_chans, 'pca', cfg.ica.ica_ncomps);
    end
    
    % --------------------------------------------------------------
    % If ICA was run on HP filtered data, copy weights + sphere to
    % original, unfiltered data.
    % --------------------------------------------------------------
    if cfg.ica.do_ICA_hp_filter
        nonhpEEG.icaweights  = EEG.icaweights;
        nonhpEEG.icasphere   = EEG.icasphere;
        nonhpEEG.icachansind = EEG.icachansind;
        EEG = nonhpEEG;
        EEG = eeg_checkset(EEG); %let EEGLAB re-compute EEG.icaact & EEG.icawinv
    end
    
    % --------------------------------------------------------------
    % Save data.
    % --------------------------------------------------------------
    EEG = eegh(com, EEG);
    EEG.data = single(EEG.data);
    
    EEG = func_saveset(EEG, subjects(isub));

end

disp('Done.')