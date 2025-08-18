%% ------------------------------------------------------------------------
% /\/\/\ WORK IN PROGRESS /\/\/\
%--------------------------------------------------------------------------

%% Set preferences, configuration and load list of subjects.
clear; clc; close all

restoredefaultpath
cfg = get_cfg;

eeglab nogui

addpath(fullfile(cfg.dir.eeglab,'plugins','erplab', 'pop_functions'))
addpath(fullfile(cfg.dir.eeglab,'plugins','erplab', 'functions'))

% ------------------------------------------------------------------------
% **Important**: these variables determine which data files are used as
% input and output.
suffix_in  = 'simple_prep';
do_overwrite = true;

%% -------------------------------------------------------------------------------------------------------------------------
channel_interpolate = 0; % TODO
%% -------------------------------------------------------------------------------------------------------------------------

if channel_interpolate
    suffix_out = 'ICA_ready_interpolated';
else
    suffix_out = 'ICA_ready';
end

% ------------------------------------------------------------------------

subjects = get_list_of_subjects(cfg.dir, do_overwrite, suffix_in, suffix_out);

%% Run across subjects.

%nthreads = min([prefs.max_threads, length(subjects)]);

%parfor(isub = 1:length(subjects), nthreads) % set nthreads to 0 for normal for loop.

for isub = 1:length(subjects)

    % ----------------------------------------------------------
    % Load the dataset. This data was filtered and downsampled in
    % script02_simple_prep.m
    % ----------------------------------------------------------
    EEG = pop_loadset('filename', subjects(isub).name, 'filepath', subjects(isub).folder);

    % ----------------------------------------------------------
    % Remove channels that were NOT specified in cfg.chans.EEGchans
    % ----------------------------------------------------------

    EEG = pop_select(EEG, 'channel', cfg.chans.EEGchans);

    % ----------------------------------------------------------
    % Add channel layout for the example data (this step will be later
    % removed)
    % ----------------------------------------------------------

    EEG = pop_chanedit(EEG, 'lookup', cfg.chans.chanlocs_standard);

    % --------------------------------------------------------------
    % High Pass Filter
    %
    % If requested, perform ICA on strongly HP filtered data ==> more
    % stable results. 
    % ---------------------------------------------------------------

    if cfg.ica.do_ICA_hp_filter
        switch(cfg.ica.hp_ICA_filter_type)
            case('butterworth')
                EEG  = pop_basicfilter(EEG, cfg.chans.EEGchans, ...
                    'Cutoff',  cfg.ica.hp_ICA_filter_limit, ... %  2 hz 
                    'Design', 'butter', 'Filter', 'highpass', 'Order',  2 );

        end
    end

    % ----------------------------------------------------------
    % Epoching at fixed length
    % ----------------------------------------------------------

    epoch_length_s = 2;

    EEGep = eeg_regepochs(EEG, 'recurrence', epoch_length_s, 'limits', [0 epoch_length_s]);

    % % ----------------------------------------------------------
    % Channel interpolation - criteria: at epoch level ( > 2 SD, > 30% epochs)
    % Problem with interpolating epoched data? 

    % % ----------------------------------------------------------
    
    if channel_interpolate

        disp('Bad channels will be interpolated.')

        % Thresholds
        thresh_sd = 2;       % e.g., 2 SD
        thresh_epoch  = 0.30;    % 30% epochs

        % z-score across channels, time points, and epochs
        zdat = zscore(EEGep.data(:));
        zdat = reshape(zdat, [size(EEGep.data,1), size(EEGep.data,2), size(EEGep.data,3)]);

        % SD (per channel, within each epoch)
        epoch_sd = squeeze(std(zdat, 0, 2));

        % Proportion of "bad" epochs per channel
        bad_prop = mean(epoch_sd > thresh_sd, 2);

        % Bad channels to reject
        badchans_z = find(bad_prop > thresh_epoch); %TODO save 

        % --------------------------------------------------------------
        % Visualize bad channels - z-score measure output - %TODO save the
        % output 
        % --------------------------------------------------------------
        [windowTimes, windowData] = visualize_random_windows(EEG, badchans_z, 5, 9, 1, 40, 'generate', [], 42);
         % saveas(gcf, 'random_windows.png');

        % Interpolate
        EEGep = eeg_interp(EEGep, badchans_z, 'spherical');

    else 

        disp('No channel interpolation.')

    end


    % ----------------------------------------------------------
    % Bad segment rejection - criteria: Amplitude
    % ----------------------------------------------------------

    % Remove the mean of the epoch.

    EEGep_rm = pop_rmbase(EEGep, [], []);

    % Find epoch to reject based on extreme amplitude values.

    [~, rej_inds] = pop_eegthresh(EEGep_rm, 1, cfg.chans.EEGchans, ...
        -cfg.rej.rejthresh_pre_ica, cfg.rej.rejthresh_pre_ica, EEGep.xmin, EEGep.xmax, 1, 0); % cfg.rej.rejthresh_pre_ica = 500


    % --------------------------------------------------------------
    % Visualize bad epochs % TODO - axis format, add good examples for
    % comparison, add an upper limit / or suppress output
    % --------------------------------------------------------------

    for e = 1:length(rej_inds)
        %Extract data for that epoch
        epochData = squeeze(EEGep.data(cfg.chans.EEGchans,:,rej_inds(e))); % channels x timepoints
        timeVec = linspace(EEGep.xmin*1000, EEGep.xmax*1000, EEGep.pnts); % in ms

        figure;
        plot(timeVec, epochData');
        xlabel('Time (ms)');
        ylabel('Amplitude (µV)');
        title(sprintf('Epoch %d', rej_inds(e)));
        grid on;
    end

    %% 
    % Reject those bad epochs from the data (version - baseline not removed).

    EEGbad = []; % Initialize empty in case no bad epochs are found.

    if ~isempty(rej_inds)
        EEGbad = pop_select(EEGep, 'trial',   rej_inds);   % Keep only bad trials

        % Save bad trials (IF EXISTS)

        EEGbad.setname = [subjects(isub).namestr ' BAD_TRIALS']; 
        
        pop_saveset(EEGbad, ...
            'filename', ['bad_' subjects(isub).outfile], ...
            'filepath', subjects(isub).outdir);

        EEGep = pop_select(EEGep, 'notrial', rej_inds);   % Remove bad trials (Keep only good trials)

    end

    EEGep.rejected_epochs = rej_inds; % Add rejected epoch indices to EEG struct

    % ----------------------------------------------------------
    % Save data 
    % ----------------------------------------------------------

    EEGep = func_saveset(EEGep, subjects(isub));

end

disp('Script03: ICA prep is done.')
