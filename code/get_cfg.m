function cfg = get_cfg

%% On which machine is this running and who is using it?
% Set relevant directories to the path based on the user name and machine.

% This can be useful if you are using this code on different machines, e.g.
% on labserver1 but also on your local machine.
[~, cfg.system.computername] = system('hostname');

% get user name to set paths correctly
username = char(java.lang.System.getProperty('user.name'));

% Top level directories of this project.
if strcmp(username,'ecesnait')

    switch(strip(cfg.system.computername))
        case 'LABSERVER1'
            rootdir = '/data4/';
            cfg.dir.main     = fullfile(rootdir, 'BuschlabPipeline/AlphaIcon/');% will change if I use more machines in future
        case 'busch01'
            cfg.dir.main     = 'C:\Users\ecesnait\Desktop\BUSCHLAB\Buschlab pipeline\';;
    end
            cfg.system.max_threads = 10;

elseif strcmp(username,'nbus')

    switch(strip(cfg.system.computername))
        case 'LABSERVER1'
            rootdir = '/data3/';
            cfg.system.max_threads = 10;
        case 'busch02'
            rootdir = 'Y:\Niko\';
        case 'busch-x1-2021'
            rootdir = 'C:\Users\nbusch\OneDrive\Desktop\';
    end
    cfg.dir.main     = fullfile(rootdir, '/Niko/buschlab-pipeline-dev/');
elseif strcmp(username, 'p_smit01')
    rootdir = '/data3/';
    cfg.dir.main = fullfile(rootdir, 'AlphaIcon/');
end

% Subfolder with raw data.
cfg.dir.raw      = fullfile(cfg.dir.main, 'data/raw/');
cfg.dir.bdf      = fullfile(cfg.dir.raw, 'bdf/'); % Biosemi bdf files.
cfg.dir.raweye   = fullfile(cfg.dir.raw, 'edf/'); % Eyelink edf files.
cfg.dir.behavior = fullfile(cfg.dir.raw, 'behavioral/'); % Behavioral data from Psychtoolbox.

% Output directories where data are stored after import.
cfg.dir.eye      = fullfile(cfg.dir.main, 'data', 'eye/');
cfg.dir.eeg      = fullfile(cfg.dir.main, 'data', 'eeg/');
cfg.dir.tf       = fullfile(cfg.dir.main, 'data', 'tf/');
cfg.dir.grand    = fullfile(cfg.dir.main, 'data', 'grand/');
cfg.dir.qualitycheck = fullfile(cfg.dir.main, 'data', 'quality/');

% Where is the EEGLAB toolbox located?
cfg.dir.eeglab   = fullfile(cfg.dir.main, 'buschlab-eeg-pipeline/tools/eeglab2023.1/'); % EEGLAB in buschlab pipeline for git share

addpath('./functions')
addpath('./files')
addpath(cfg.dir.eeglab)


%% Information about channel structure.

% These channels were actually recorded.
cfg.chans.EEGchans = 1:67;

% We will add additional channels for VEOG and HEOG, which are based on
% subtracting a set of electrodes above/below and left/right of the eyes.
cfg.chans.VEOGchan = 68;
cfg.chans.HEOGchan = 69;
cfg.chans.VEOGin = {[42], [65]};
cfg.chans.HEOGin = {[66], [67]};

% We use these files to import the channel coordinates. The "custom" file
% is for the electrodes on the cap with Axx/Bxx labels. We use the
% "standard" file for any remaining channels with 10/20 labels, e.g. the
% electrodes around the eye (e.g. IO1, AFp10) or mastoids (M1, M2).
% cfg.chans.chanlocfile_custom   = 'Custom_M34_V3_Easycap_Layout_3eog_chans.ced';
cfg.chans.chanlocs_custom   = 'Custom_M34_V3_Easycap_Layout_EEGlab.sfp';
cfg.chans.chanlocs_standard = 'standard-10-5-cap385.elp'; %This is EEGLAB's standard lookup table.


%% Eyelink related input
% Do you want to coregister eyelink eyetracking data?
cfg.eyetrack.coregister_Eyelink = true;% CFG.coregister_Eyelink = 1; %0=don't coregister

% Coregistration is done by using the first instance of the first value and
% the last instance of the second value. Everything inbetween is downsampled
% and interpolated.
cfg.eyetrack.eye_startEnd = [40 50];% CFG.eye_startEnd       = []; % e.g., [10,20]

% After data has been coregistered, eyetracking data will be included in
% the EEG struct. Do you want to keep the eyetracking-only files (ASCII &
% mat)? This would speed up the data importing if you need to run
% script01_import once again.
cfg.eyetrack.eye_keepfiles = [1 1];% CFG.eye_keepfiles      = [0 0];


%% Preprocessing raw data.
cfg.prep.do_resampling = 1;
cfg.prep.new_sampling_rate = 256;
cfg.prep.do_rereference = 1;
cfg.prep.reref_chan = 32; % used in script 01, first re-referencing; 48=channel CZ. 31=Pz. []=average ref

cfg.prep.do_hp_filter = true;% CFG.do_hp_filter = 1;
cfg.prep.hp_filter_type = 'butter';% CFG.hp_filter_type = 'eegfiltnew'; % or 'butterworth', 'eegfiltnew' or kaiser - not recommended
cfg.prep.hp_filter_limit = 0.01;% CFG.hp_filter_limit = 0.1;
% CFG.hp_filter_tbandwidth = 0.1;% CFG.hp_filter_tbandwidth = 0.2;% only used for kaiser
% CFG.hp_filter_pbripple = 0.02;% CFG.hp_filter_pbripple = 0.01;% only used for kaiser

% Do you want to low-pass filter the data?
cfg.prep.do_lp_filter = true;% CFG.do_lp_filter = 1;
cfg.prep.lp_filter_limit = 40;% CFG.lp_filter_limit = 45;
cfg.prep.lp_filter_tbandwidth = 5;% CFG.lp_filter_tbandwidth = 5;

cfg.prep.do_notch_filter = false;

%% Triggers and epochs
cfg.epoch.tlims = [-1.5 1];
cfg.epoch.trig_target = [21:29];% CFG.trig_target = []; %e.g., [21:29, 200:205]
cfg.epoch.trigger_device = 'lowbyte-PC';% CFG.trigger_device = 'lowbyte-PC'; % can be [],'lowbyte-PC' or 'highbyte-VPixx'
cfg.epoch.keep_continuous = false;

% If you already removed faulty trials (e.g., when a subject looked away)
% from your logfile, then the amount of trials in the logfile does not
% match the amount of trials in the EEGdata. If you sent special triggers
% that mark faulty trials in the EEGdata, enter them here to remove all
% epochs containing these triggers from your EEGdata. The result should be
% that EEGdata and Logfile match again.
% NOTE: See below for unfold/GLM/continuous (CFG.trig_trial_onset)
cfg.epoch.trig_omit = [];% CFG.trig_omit = [];

% you may also want to delete just a few specific trials; e.g., the training
% trials at the beginning. Be cautios, this omits trials solely in EEG and may
% result in different trial orders in logfiles and EEG. Only use this parameter
% to delete trials that are in the EEG but not in the logfiles.
cfg.epoch.trial_omit = [];% CFG.trial_omit  = [];
% remove epochs, that contain the target-trigger but not all of the triggers
% specified here. Currently this can result in problems with the
% coregistration of behavioral data. So think about what you're doing!
cfg.epoch.trig_omit_inv_mode = 'AND';% CFG.trig_omit_inv_mode = 'AND'; % 'AND' or 'OR'. Should trials that do not include all of these triggers (AND) or trials that do not include any of these triggers be removed?
cfg.epoch.trig_omit_inv = [];% CFG.trig_omit_inv = [];

% Important for matching EEG data and behavioral log files.
% Did you use online-eyetracking to mark bad trials in your logfile?
% specify the fieldname of the field in your logfile struct that contains
% this information. Check func_importbehavior for more information.
cfg.epoch.badgaze_fieldname = 'badgaze';% CFG.badgaze_fieldname = '';
cfg.epoch.deletebadlatency = 0;


%% Trial rejection before ICA.
% cfg.use_asr = 0;
cfg.rej.rejthresh_pre_ica  = 500;
cfg.rej.rej_jp_singchan = 9;
cfg.rej.rej_jp_allchans = 5;


%% ICA parameters
% % ------------------------------------------
cfg.ica.ica_chans = cfg.chans.EEGchans; % Typicaly, ICA is computed on all channels, unless one channel is not really EEG.
cfg.ica.ica_ncomps = numel(cfg.chans.EEGchans)-2;% CFG.ica_ncomps = numel(CFG.data_chans) - 3; % if ica_ncomps==0, determine data rank from the ...
% data (EEGLAB default). Otherwise, use a fixed number of components. Note:
% subject-specific settings will override this parameter.

% Do you want to do an extra run of high-pass filtering before ICA (i.e.,
% after segmentation)? see Olaf Dimigen's OPTICAT. The data as filtered
% below are only used to compute the ICA. The activation is then
% reprojected to the original data filtered as indicated % above in the
% section 'filters'.
cfg.ica.do_ICA_hp_filter = true;% CFG.do_ICA_hp_filter = 1;
cfg.ica.hp_ICA_filter_type = 'butterworth';% CFG.hp_ICA_filter_type = 'eegfiltnew'; % 'butterworth' or 'eegfiltnew' or kaiser - not recommended
cfg.ica.hp_ICA_filter_limit = 2;% CFG.hp_ICA_filter_limit = 2.5;
% cfg.ica.hp_ICA_filter_tbandwidth = 0.2;% CFG.hp_ICA_filter_tbandwidth = 0.2;% only used for kaiser
% cfg.ica.hp_ICA_filter_pbripple = 0.01;% CFG.hp_ICA_filter_pbripple = 0.01;% only used for kaiser
%
% % Olaf Dimigen recommends to overweight spike potentials using his OPTICAT
% % approach. Do you want to do this prior to computung ICA?
cfg.ica.ica_overweight_sp = true;% CFG.ica_overweight_sp = 1;
cfg.ica.opticat_saccade_before = -0.02;% CFG.opticat_saccade_before = -0.02; % time window to overweight (-20 to 10 ms)
cfg.ica.opticat_saccade_after = 0.01;% CFG.opticat_saccade_after = 0.01;
cfg.ica.opticat_ow_proportion = 0.5;% CFG.opticat_ow_proportion = 0.5; % overweighting proportion
cfg.ica.opticat_rm_epochmean = true;% CFG.opticat_rm_epochmean = true; % subtract mean from overweighted epochs? (recommended)
%
%% ------------------------------------------
% ICA rejection parameters
% ------------------------------------------
cfg.icareject.confirm_manual   = false;
cfg.icareject.do_correlate_eog = true;
cfg.icareject.do_eyetrackerica = true;
cfg.icareject.do_iclabel       = true; % Select components based on IClabel classifier?

cfg.icareject.thresh_correlate_eog = 0.7;


cfg.icareject.eyetracker_ica_varthresh = 1.1;% CFG.eyetracker_ica_varthresh = 1.3; % variance ratio threshold (var(sac)/var(fix))
cfg.icareject.eyetracker_ica_sactol = [5, 0];% CFG.eyetracker_ica_sactol    = [5 10]; % Extra temporal tolerance around saccade onset and offset
cfg.icareject.eyetracker_ica_feedback = 4;% CFG.eyetracker_ica_feedback  = 4; % do you want to see plots of (1) all selected bad components (2) all good (3) bad & good or (4) no plots?


% cfg.rejthresh_post_ica = 250;
% cfg.corrthreshold = 0.7; % max correlation between EOG and ICA activity.
% cfg.reref_analysis = []; %leave empty brackets to apply average reference.

% IC LabeL:
% What types of ICs do you want to remove? Classes are:
% 'Brain', 'Muscle', 'Eye', 'Heart', 'Line Noise', 'Channel Noise', 'Other'
% IMPORTANT: we should not include "brain" here.
cfg.icareject.iclabel_rm_ICtypes = {'Eye','Muscle', 'Heart','Channel Noise','Other','Line Noise'}; %was: eye muscle heart {'Eye', 'Muscle', 'heart'};%
% Minimum classification accuracy to believe an ICs assigned label is true.
% Can be a vector with one accuracy per category or a single value for all
% categories.
cfg.icareject.iclabel_min_acc = 0.5;% 0.75;%was: 0.75; %50% is not chance, but seems realistic based on inspectio


%% ------------------------------------------
% Final preprocessing after ICA.
% ------------------------------------------
cfg.final.rejthresh_post_ica = 150;
cfg.final.do_channel_interp = true;
cfg.final.channel_interp_zthresh = 3.5;
cfg.final.channel_interp_method = 'spherical';

%% ------------------------------------------
% Parameters for filter-hilbert.
% ------------------------------------------
cfg.filtbert.fbands{1} = [8 12];
cfg.filtbert.fbands{2} = [7 13];
cfg.filtbert.wintype = 'hamming';
cfg.filtbert.transbw = 1;


%% ------------------------------------------
% Parameters for FFT.
% ------------------------------------------
cfg.fft(1).twin = [-1000  -2]; cfg.fft(1).fft_npoints = 512;
cfg.fft(2).twin = [1000 1998]; cfg.fft(2).fft_npoints = 512;
cfg.fft(3).twin = [3000 3998]; cfg.fft(3).fft_npoints = 512;


%% TF parameters.
% cfg.min_freq =  3;
% cfg.max_freq = 30;
% cfg.num_frex = 28;
% cfg.frex = linspace(cfg.min_freq, cfg.max_freq, cfg.num_frex);
% cfg.fwhm_t = 2 .* 1./cfg.frex;
%
% %% Experimental design.
% cfg.conditions = {
%     {'scene_man', 1}, {'scene_man', 2};
%     {'is_old', 0}, {'is_old', 1};
%     {'subscorrect', 0}, {'subscorrect', 1};
%     {'recognition', 'hit'}, {'recognition', 'miss'};
%     };
%
% %%
%

