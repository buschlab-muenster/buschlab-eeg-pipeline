%script03_ica_prep

% Set preferences, configuration and load list of subjects.
clear; clc; close all

restoredefaultpath
cfg = get_cfg;

eeglab nogui

addpath(fullfile(cfg.dir.eeglab,'plugins','erplab', 'pop_functions'))
addpath(fullfile(cfg.dir.eeglab,'plugins','erplab', 'functions'))

% Steps in the script:
% 1. Optional high-pass filter
% 2. Epoching 
% 3. Handle bad channels 
% 4. Handle bad segments 

% ------------------------------------------------------------------------
% **Important**: these variables determine which data files are used as
% input and output.
suffix_in  = 'simple_prep';
do_overwrite = true;

% ------------------------------------------------------------------------
% Question: What about the reference channel?

%% -------------------------------------------------------------------------------------------------------------------------
channel_rejection = 0; % TODO: 0 - do nothing with channels, 1 - remove channels, 2 - interpolate channels

if channel_rejection == 0
   suffix_out = 'ICA_ready';
elseif channel_rejection == 1
   suffix_out = 'ICA_ready_channels_rejected';
elseif channel_rejection == 2
   suffix_out = 'ICA_ready_channels_interpolated';
end

%% ------------------------------------------------------------------------

subjects = get_list_of_subjects(cfg.dir, do_overwrite, suffix_in, suffix_out);

%% Run across subjects.

%nthreads = min([prefs.max_threads, length(subjects)]);

%parfor(isub = 1:length(subjects), nthreads) % set nthreads to 0 for normal for loop.

for isub = 1%4%1:length(subjects)

    % ----------------------------------------------------------
    % Load the dataset. This data was filtered and downsampled in
    % script02_simple_prep.m
    % ----------------------------------------------------------
    EEG = pop_loadset('filename', subjects(isub).name, 'filepath', subjects(isub).folder);

    % ----------------------------------------------------------
    % Remove channels that were NOT specified in cfg.chans.EEGchans
    % ----------------------------------------------------------

    cfg.chans.EEGchans = 1:30;
    EEG = pop_select(EEG, 'channel', cfg.chans.EEGchans);

    % ----------------------------------------------------------
    % Add channel layout for the example data (this step will be later
    % removed) - DO we add layout anywhere? Do we need to?
    % ----------------------------------------------------------

    EEG = pop_chanedit(EEG, 'lookup', cfg.chans.chanlocs_standard);

    % --------------------------------------------------------------
    % High Pass Filter
    %
    % If requested, perform ICA on strongly HP filtered data ==> more
    % stable results. 
    % 10.1109/EMBC.2015.7319296
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

    %%
    % % ----------------------------------------------------------
    % Channel interpolation - criteria: at epoch level ( > 2 SD, > 30% epochs)
    % Problem with interpolating epoched data? 

    % % ----------------------------------------------------------

    if channel_rejection == 0

        disp('Bad channels will remain.')

    elseif channel_rejection == 1 % TODO ADD ACTUALY REMOVAL

        disp('Bad channels will be removed.')

        % Thresholds
        thresh_sd = 2;       % e.g., 2 SD
        thresh_epoch  = 0.30;    % 30% epochs -> If more than 30% of epochs exceed the threshold

        % z-score across channels, time points, and epochs
        % each sample is standardized relative to all data
        zdat = zscore(EEGep.data(:));
        zdat = reshape(zdat, [size(EEGep.data,1), size(EEGep.data,2), size(EEGep.data,3)]);

        % SD (For each channel × epoch, across time points)
        % channel variability within epochs
        epoch_sd = squeeze(std(zdat, 0, 2)); 

        % Proportion of "bad" epochs per channel
        bad_prop = mean(epoch_sd > thresh_sd, 2);

        % Bad channels to reject
        badchans = find(bad_prop > thresh_epoch); %TODO save 

        % -------------------------------------------------------------------------------------
        % Visualize bad channels - %TODO - this doesn't work because of the reference channels 
        % -------------------------------------------------------------------------------------
        %EEG = pop_select(EEG, 'channel', [1:31,33:length(cfg.chans.EEGchans)]); % This shifts of course indices - bad channels are different now

        [windowTimes, windowData] = visualize_random_windows(EEG, badchans, 5, 9, 2, 40, 'generate', [], 42);
 
    elseif channel_rejection == 2
           
        disp('Bad channels will be interpolated.')


         % Interpolate
        EEGep = eeg_interp(EEGep, badchans, 'spherical');

    end 

    %%
    % ----------------------------------------------------------
    % Bad segment rejection - criteria: Amplitude
    % ----------------------------------------------------------

    % Remove the mean of the epoch.

    % Niko: I do a temorary baseline correction, otherwise the rejection by
    % extreme amplitudes gets confused if there are still some DC
    % shifts in the raw data. However, we apply the trial rejection to
    % the un-baseline corrected data, because ICA likes that better.

    % However, high-pass filtering data is also a form of baseline correction,
    % rendering the current step optional - eeglab tutorial ??

    EEGep_rm = pop_rmbase(EEGep, [], []);

    % Find epoch to reject based on extreme amplitude values.

    % checks every time point in the epoch, 
    % if any single data point in any of channels exceeds threshold (>|500 µV| 
    % flags that epoch 

    [~, bad_by_amplitude_epochs] = pop_eegthresh(EEGep_rm, 1, cfg.chans.EEGchans, ...
        -cfg.rej.rejthresh_pre_ica, cfg.rej.rejthresh_pre_ica, EEGep.xmin, EEGep.xmax, 1, 0); % cfg.rej.rejthresh_pre_ica = 500

    % --------------------------------------------------------------
    % Visualize bad epochs % TODO
    % --------------------------------------------------------------
    % for e = 1:length(bad_by_amplitude)
    %     %Extract data for that epoch
    %     epochData = squeeze(EEGep.data(cfg.chans.EEGchans,:,bad_by_amplitude(e))); % channels x timepoints
    %     timeVec = linspace(EEGep.xmin*1000, EEGep.xmax*1000, EEGep.pnts); % in ms
    %     figure;
    %     plot(timeVec, epochData');
    %     xlabel('Time (ms)');
    %     ylabel('Amplitude (µV)');
    %     title(sprintf('Epoch %d', bad_by_amplitude(e)));
    %     grid on;
    % end

  %%
    % Reject those bad epochs from the data which was not baseline corrected.

    EEGbad = []; % Initialize empty in case no bad epochs are found.

    if ~isempty(bad_by_amplitude_epochs)
        EEGbad = pop_select(EEGep, 'trial',   bad_by_amplitude_epochs);   % Keep only bad trials

        % Save bad trials (IF EXISTS)

        EEGbad.setname = [subjects(isub).namestr ' BAD_TRIALS']; 
        
        pop_saveset(EEGbad, ...
            'filename', ['bad_' subjects(isub).outfile], ...
            'filepath', subjects(isub).outdir);

        EEGep = pop_select(EEGep, 'notrial', bad_by_amplitude_epochs);   % Remove bad trials (Keep only good trials)

    end

    EEGep.rejected_epochs = bad_by_amplitude_epochs; % Add rejected epoch indices to EEG struct

    % TODO - Add manual segment rejection
    if strcmpi(cfg.prep.bad_segment_reject, 'manual')
        % Launch EEGPLOT with manual rejection enabled
        pop_eegplot(EEG, 1, 1, 1);

        uiwait(gcf);   % pauses execution until eegplot is closed

        % Retrieve manually rejected epochs - What is TMPREJ? indices? time
        % stamps?
        bad_by_eye_epochs = TMPREJ;
    end

    % ----------------------------------------------------------
    % Save data 
    % ----------------------------------------------------------

    EEGep = func_saveset(EEGep, subjects(isub));

end

disp('Script03: ICA prep is done.')
