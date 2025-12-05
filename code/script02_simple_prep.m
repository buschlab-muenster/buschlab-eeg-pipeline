% script02_simple_prep

% This script loads data in the EEGLAB format, filters it (except VEOG/HEOG
% channels), and downsamples.

%% Set preferences, configuration and load list of subjects.

clear; clc; close all
restoredefaultpath
cfg = get_cfg;
eeglab nogui

% ------------------------------------------------------------------------
% **Important**: these variables determine which data files are used as
% input and output.
suffix_in  = 'import';
suffix_out = 'simple_prep';
do_overwrite = true;
% ------------------------------------------------------------------------

subjects = get_list_of_subjects(cfg.dir, do_overwrite, suffix_in, suffix_out);

%% Run across subjects.
%nthreads = min([cfg.system.max_threads, length(subjects)]);
% parfor(isub = 1:length(subjects), nthreads) % set nthreads to 0 for normal for loop.

for isub = 1%1:length(subjects)

    % ----------------------------------------------------------
    % Load the dataset.
    % ----------------------------------------------------------
    EEG = pop_loadset('filename', subjects(isub).name, 'filepath', subjects(isub).folder);

    % --------------------------------------------------------------
    % Filter the data.
    % --------------------------------------------------------------
    % Filters should happen before epoching. Also: we want to keep the
    % VEOG/HEOG and eye tracking data unfiltered to make sure they are not
    % distorted by the filter. We keep a copy here and then put it back
    % after filtering. WE FILTER REST OF THE EYE CHANNELS? 
   
    tmp = EEG.data;
    nofilt_chans = [cfg.chans.VEOGchan cfg.chans.HEOGchan]; %indx of channels that should not be filtered
                                                  
    % filter 
    EEG = func_import_filter(EEG, cfg.prep, cfg.dir);

    % put unfiltered channels back 
    EEG.data(nofilt_chans,:) = tmp(nofilt_chans,:);

    clear tmp

    % --------------------------------------------------------------
    % Downsample data if required. IMPORTANT: use resampling only after
    % importing the eye tracking data, or else the ET data will not be in
    % sync with EEG data.
    % --------------------------------------------------------------
    EEG = func_import_downsample(EEG, cfg.prep);

    % --------------------------------------------------------------
    % Save the new EEG file in EEGLAB format.
    % --------------------------------------------------------------
    EEG = func_saveset(EEG, subjects(isub));

end

%% Create a report %%
% --------------------------------------------------------------

% If the qualitycheck folder  doesn't exist, we create it 

if ~exist(cfg.dir.qualitycheck, 'dir')
    mkdir(cfg.dir.qualitycheck)
end

text = sprintf(['\n%s\n report from script02_simple_prep\n' ...
    'Data directory: %s\n' ...
    'Processed subjects: %s\n' ...
    'These channels are not filtered: %s\n' ...
    'High pass filter (yes/no): %s\n' ...
    'High pass filter type: %s\n' ...
    'High pass filter limit: %s\n' ...
    'Low pass filter (yes/no): %s\n' ...
    'Low pass filter limit: %s\n' ...
    'Low pass filter bandwidth: %s\n' ...
    'Notch filter (yes/no): %s\n' ...
    'Downsample(yes/no): %s\n'], ...
    datestr(datetime), ...
    cfg.dir.main, ...
    strjoin({subjects.name}, ', '), ...
    num2str(nofilt_chans), ...
    num2str(cfg.prep.do_hp_filter), ...
    cfg.prep.hp_filter_type, ...
    num2str(cfg.prep.hp_filter_limit), ...
    num2str(cfg.prep.do_lp_filter), ...
    num2str(cfg.prep.lp_filter_limit), ...
    num2str(cfg.prep.lp_filter_tbandwidth), ...
    num2str(cfg.prep.do_notch_filter), ...
    num2str(cfg.prep.do_resampling));

fileID = fopen([cfg.dir.qualitycheck, 'project_report.txt'],'a+');
fprintf(fileID,'%s',text);
fclose(fileID);

if cfg.prep.do_resampling == 1
    msg2 = sprintf('Downsampled to: %s\n', ...
        num2str(cfg.prep.new_sampling_rate));
    fileID = fopen([cfg.dir.qualitycheck, 'project_report.txt'],'a+');
    fprintf(fileID,'%s',msg2);
    fclose(fileID);
end

clear text msg2

% add plots

% checking results of filtering
% this plot does not include the reference channel so there is one less
% channel. 

f = figure('Visible','off');  % create figure

spectopo(EEG.data, 0, EEG.srate, 'freqrange', [1 cfg.prep.lp_filter_limit+10], 'plot', 'off');
                  
saveas(f, fullfile(cfg.dir.qualitycheck, ...
    [subjects(isub).namestr '_spectopo_plot_after_filter.png']));

close(f);


disp('Script02: Simple prep is done.')