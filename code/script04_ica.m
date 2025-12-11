% script04_ica
%% Set preferences, configuration and load list of subjects.
clear; clc; close all
restoredefaultpath
cfg   = get_cfg;

addpath(fullfile(cfg.dir.eeglab,'plugins','erplab', 'pop_functions'))
addpath(fullfile(cfg.dir.eeglab,'plugins','erplab', 'functions'))

eeglab nogui
% ------------------------------------------------------------------------
% **Important**: these variables determine which data files are used as
% input and output.
suffix_in  = 'artifact_free';
suffix_out = 'ica';
do_overwrite = true;
% ------------------------------------------------------------------------

subjects = get_list_of_subjects(cfg.dir, do_overwrite, suffix_in, suffix_out);
% ------------------------------------------------------------------------
% Set the random seed of the random number generator. Doing it this way is
% recommended instead of "rng" for parfor loops.
% ------------------------------------------------------------------------
%sc = parallel.pool.Constant(RandStream('Threefry'));

%% Run across subjects.
check_quality_plot = 1;
%nthreads = min([prefs.max_threads, length(subjects)]);
%parfor(isub = 1:length(subjects), nthreads) % set nthreads to 0 for normal for loop, parfor is parallel for loop
for isub = 2%:length(subjects)

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
    %stream = sc.Value;        % Extract the stream from the Constant
    %stream.Substream = 1; % Set stream to constant value so that each parfor iteration uses same seed.

    % --------------------------------------------------------------
    % If requested, overweight brief saccade intervals containing spike
    % potentials (see Dimigen's OPTICAT) - micro saccade artifacts
    % --------------------------------------------------------------
    % if cfg.ica.ica_overweight_sp
    %     % Mark Eyetracking based occular artifacts
    %     % try to guess what saccades are called in our dataset
    %     types = unique({EEG.event.type});
    %     sacdx = cellfun(@(x) endsWith(x, 'saccade') ||...
    %         startsWith(x, 'saccade'), types);
    %     if sum(sacdx) ~= 1
    %         error(['Could not determine unique saccade',...
    %             ' identifier event. Consider renaming in EEG.event.type']);
    %     end
    %     
    % EEG = pop_overweightevents(EEG, types{sacdx},...
    %         [cfg.ica.opticat_saccade_before, cfg.ica.opticat_saccade_after],...
    %         cfg.ica.opticat_ow_proportion, cfg.ica.opticat_rm_epochmean);
    %     % pop_overweightevents has an issue with the recent version of
    %     % eeglab's pop_rmbase - edit overweightevents.m to use
    %     % sac = pop_rmbase(sac,[], []);
    %     % instead of sac = pop_rmbase(sac,[]);
    % 
    %     % retin information on rank reduction
    %     EEG.etc = nonhpEEG.etc;
    % end
                                                      
    % --------------------------------------------------------------
    % High Pass Filter or Baseline Removal
    % --------------------------------------------------------------

    if cfg.ica.do_ICA_hp_filter == 1
        
        nonhpEEG = EEG;

        switch(cfg.ica.hp_ICA_filter_type)
            case('butterworth')
                EEG  = pop_basicfilter(EEG, cfg.chans.EEGchans, ...
                    'Cutoff',  cfg.ica.hp_ICA_filter_limit, ...
                    'Design', 'butter', 'Filter', 'highpass', 'Order',  2 );
        end

    end 

    % Do we apply baseline removal to the eye channels? 
    % We need to transfer weights for this version as well?

    %if cfg.ica.do_baseline_removal
    %   EEG_modified = pop_rmbase(EEG, [], [], cfg.chans.brain);
    % end


    % --------------------------------------------------------------
    % Run ICA.
    % --------------------------------------------------------------

    % When we run fast ica it reduces the rank by 1, which is correct due to
    % referencing.
    % It should be the same for infomax ica 

    if cfg.ica.ica_ncomps == 0
        %[EEG, com] = pop_runica(EEG, 'icatype', 'runica', ...
        %    'extended', 1, 'chanind', cfg.chans.EEGchans);
        [EEG, com] = pop_runica(EEG, 'icatype', 'fastica', 'chanind', cfg.chans.EEGchans);
    else
        [EEG, com] = pop_runica(EEG, 'icatype', 'runica','extended', 1, ...
            'chanind', cfg.chans.EEGchans, 'pca', cfg.ica.ica_ncomps);
    end

    % --------------------------------------------------------------
    % If ICA was run on HP filtered data, copy weights + sphere to
    % original, unfiltered data.
    % --------------------------------------------------------------
    if cfg.ica.do_ICA_hp_filter == 1
        nonhpEEG.icaweights  = EEG.icaweights;
        nonhpEEG.icasphere   = EEG.icasphere;
        nonhpEEG.icachansind = EEG.icachansind;
        EEG = nonhpEEG;
        EEG = eeg_checkset(EEG); %let EEGLAB re-compute EEG.icaact & EEG.icawinv
        disp('Weights + sphere were copied to the original, unfiltered data.')
    end

    % --------------------------------------------------------------
    % Inspect ICA components 
    % --------------------------------------------------------------

    if cfg.ica.check_components == 1
        figs_before = get(0, 'Children');
        fprintf('Close the visualization window when done reviewing.\n');
        pop_viewprops(EEG, 0);
        pause(0.5);
        new_figs = setdiff(get(0, 'Children'), figs_before);
        if ~isempty(new_figs)
            waitfor(new_figs(1));
        end
    end

    disp('Done.')

    % --------------------------------------------------------------
    % Save data.
    % --------------------------------------------------------------
    EEG = func_saveset(EEG, subjects(isub));

end

disp('Done.')

if ~exist(cfg.dir.qualitycheck, 'dir')
    mkdir(cfg.dir.qualitycheck)
end

if check_quality_plot
    script_nr=4;
    get_quality_check(script_nr,{subjects.name},[], [], cfg)
    % add plots
end