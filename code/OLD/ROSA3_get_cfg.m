function [CFG, S] = ROSA3_get_cfg(idx, S)
% This function contains (almost) all parameters necessary to change EEG
% data preprocessing in any desired direction. Make sure to check *each 
% single option* in this function.

%% ------------------------------------------------------------------------
% Read info for this subject and get file names and dirctories.
% -------------------------------------------------------------------------
if isunix    
    CFG.dir_main = '/data3/Niko/ROSA3/';
else
%     CFG.dir_main = 'Z:/Wanja/git-repos/ROSA2_Analysis/preprocessing/EEG-prep/';
end
if nargin>0                
CFG.subject_name  = char(S.Name(idx));
CFG.dir_behavior  = [CFG.dir_main 'rawdata' filesep 'Logfiles' filesep];
CFG.dir_raw       = [CFG.dir_main 'rawdata' filesep 'BDF' filesep];
CFG.dir_raweye    = [CFG.dir_main 'rawdata' filesep 'EDF' filesep];
% CFG.dir_eeg       = [CFG.dir_main 'EEG' filesep CFG.subject_name filesep]; 
% CFG.dir_eye       = [CFG.dir_main 'EYE' filesep CFG.subject_name filesep]; 

CFG.dir_eye      = [CFG.dir_main 'Niko-prep/EYE/' CFG.subject_name filesep];
CFG.dir_eeg      = [CFG.dir_main 'Niko-prep/EEG/' CFG.subject_name filesep];

CFG.dir_tf        = [CFG.dir_main 'TF' filesep CFG.subject_name filesep]; 
CFG.dir_filtbert  = [CFG.dir_main 'Filtbert' filesep CFG.subject_name filesep];    
end

%% ------------------------------------------------------------------------
% Data organization and content.
% -------------------------------------------------------------------------
% Name of the structure containing the behavioral data (e.g., "Info.T")
CFG.trial_struct_name = 'INFO.T';% CFG.trial_struct_name = "Info.T";

% For GLM modelling with the unfold toolbox, you need continuous data.
CFG.keep_continuous = false;% CFG.keep_continuous = false;

% Triggers that mark stimulus onset. These events will be used for
% epoching. In case of unfold-pipe, these are just pseudo-epochs, that will
% only be used for coregistration with behavioral data and subsequently be
% deleted.
CFG.trig_target = 20;% CFG.trig_target = []; %e.g., [21:29, 200:205]
CFG.epoch_tmin = -1;% CFG.epoch_tmin  = []; %e.g., -2.000
CFG.epoch_tmax = 4.5;% CFG.epoch_tmax  = []; %e.g., 0.500

% If you already removed faulty trials (e.g., when a subject looked away) 
% from your logfile, then the amount of trials in the logfile does not 
% match the amount of trials in the EEGdata. If you sent special triggers 
% that mark faulty trials in the EEGdata, enter them here to remove all 
% epochs containing these triggers from your EEGdata. The result should be 
% that EEGdata and Logfile match again.
% NOTE: See below for unfold/GLM/continuous (CFG.trig_trial_onset)
CFG.trig_omit = [];% CFG.trig_omit = [];

% you may also want to delete just a few specific trials; e.g., the training
% trials at the beginning. Be cautios, this omits trials solely in EEG and may
% result in different trial orders in logfiles and EEG. Only use this parameter
% to delete trials that are in the EEG but not in the logfiles.
CFG.trial_omit = [];% CFG.trial_omit  = [];

% remove epochs, that contain the target-trigger but not all of the triggers
% specified here. Currently this can result in problems with the
% coregistration of behavioral data. So think about what you're doing!
CFG.trig_omit_inv_mode = 'AND';% CFG.trig_omit_inv_mode = 'AND'; % 'AND' or 'OR'. Should trials that do not include all of these triggers (AND) or trials that do not include any of these triggers be removed?
CFG.trig_omit_inv = 60;% CFG.trig_omit_inv = [];

% Optional: If you are using the file-io in WM-utilities, you might want to
% use ONLY triggers from the PC or ONLY triggers from the ViewPixx. To
% delete epochs of one of the devices prior to epoching, specify the
% to-be-kept device here.
% This is *very specific to out lab*.
CFG.trigger_device = 'lowbyte-PC';% CFG.trigger_device = 'lowbyte-PC'; % can be [],'lowbyte-PC' or 'highbyte-VPixx'

% Did you use online-eyetracking to mark bad trials in your logfile?
% specify the fieldname of the field in your logfile struct that contains
% this information. Check func_importbehavior for more information.
CFG.badgaze_fieldname = 'badgaze';% CFG.badgaze_fieldname = '';

% Do you want to check the latencies of specific triggers within each
% epoch?
CFG.checklatency = [];% CFG.checklatency = [];
CFG.allowedlatency = 5;% CFG.allowedlatency = 5;

% Do you want to delete trials that differ by more than CFG.allowedlatency ms
% from the median latency AFTER coregistration with behavoral data?
CFG.deletebadlatency = 0;% CFG.deletebadlatency = 0;

% For GLM modelling with the unfold toolbox, the trigger and/or
% latency-based rejections specified above will not make sense (continuous
% data!). You can, however, specify a trigger that defines the trial onset 
% (usually that's earlier than your target onset). The program will use all
% sampling points between a trig_target and the preceding + following 
% trig_trial_onset (which should equal the complete trial). It will then 
% create a matrix of rejected trials' latencies in 
% (CONT)EEG.uf_rej_latencies. This does currently not take care of 
% artifacts detected other than with trigger or latency. You *can* use 
% this later in unfold with, e.g., uf_continuousArtifactExclude.m
CFG.trig_trial_onset = [];% CFG.trig_trial_onset = [];

%% ------------------------------------------------------------------------
% Parameters for data import and preprocessing.
% -------------------------------------------------------------------------

% Indices of channels that contain data, including external electrodes, 
% but not bipolar channels like VEOG, HEOG.
CFG.data_urchans = [1:64,69];

% Indices of channels that contain data after rejecting the channels not
% selected in CFG.data_urchans. 
CFG.data_chans   = 1:length(CFG.data_urchans);

% Use these channels for computing bipolar HEOG and VEOG channel. (Indexes
% refer to channels *after* rejecting unused channels as above. So deleting
% channels 65:68 but keeping 69 makes 69 --> 65
CFG.heog_chans = [2 51];% CFG.heog_chans = [2 51];
CFG.veog_chans = [42 65];% CFG.veog_chans = [42 65];

% Channel location file. If you use your own custom file, you have to
% provide the full path and filename.
CFG.chanlocfile = 'Custom_M34_V3_Easycap_Layout_EEGlab.sfp';% CFG.chanlocfile = 'Custom_M34_V3_Easycap_Layout_EEGlab.sfp';%standard-10-5-cap385.elp'; %This is EEGLAB's standard lookup table.

% Import reference: Biosemi raw data are reference free. Add any
% reference directly after import, (e.g., a mastoid or other channel). 
% Otherwise the data will lose 40 dB of SNR! You can simply re-reference
% later. Leave empty to use average of data_chans (recommended).
CFG.import_reference = [];% CFG.import_reference    = []; %A16 & B32 are the mastoids in M34 layout.
% Do you want to rereference the data at the import step (recommended)?
% Since Biosemi does not record with reference, this improves signal
% quality. This does not need to be the postprocessing refrence you use for
% subsequent analyses.
CFG.do_preproc_reref = true;% CFG.do_preproc_reref    = false;
CFG.preproc_reference = [];% CFG.preproc_reference   = []; % (31=Pz@Biosemi,32=Pz@CustomM43Easycap);  'robust' for robust average. Requires PREP extension & fix in line 102 of performReference.m (interpoled -> interpolated; already filed as issue on github)
% Files produced with the prep_* functions always store data with the
% preproc ref. The functions called by the design_master rereference to the
% postproc_reference. Can be 'keep' to simply keep the preproc reference
CFG.postproc_reference = 'keep';% CFG.postproc_reference  = 'keep'; % empty = average reference; for M34: 'A16' & 'B32' = Mastoids

% Do you want to have a new sampling rate?
CFG.do_resampling = true;% CFG.do_resampling     = false;
CFG.new_sampling_rate = 256;% CFG.new_sampling_rate = [];

% Do you want to high-pass filter the data?
% You can optionally choose to apply an extreme high-pass filter to
% calculate ICA weights and apply them to your less-extreme high-pass
% filtered data. For the ICA-related high-pass filter, see below.
CFG.do_hp_filter = true;% CFG.do_hp_filter = 1;
CFG.hp_filter_type = 'butterworth';% CFG.hp_filter_type = 'eegfiltnew'; % or 'butterworth', 'eegfiltnew' or kaiser - not recommended
CFG.hp_filter_limit = 0.01;% CFG.hp_filter_limit = 0.1; 
% CFG.hp_filter_tbandwidth = 0.1;% CFG.hp_filter_tbandwidth = 0.2;% only used for kaiser
% CFG.hp_filter_pbripple = 0.02;% CFG.hp_filter_pbripple = 0.01;% only used for kaiser

% Do you want to low-pass filter the data?
CFG.do_lp_filter = true;% CFG.do_lp_filter = 1;
CFG.lp_filter_limit = 40;% CFG.lp_filter_limit = 45; 
CFG.lp_filter_tbandwidth = 5;% CFG.lp_filter_tbandwidth = 5;

% Do you want to notch-filter the data? (Cleanline should be sufficient in most cases)
CFG.do_notch_filter = false;% CFG.do_notch_filter = 0;
CFG.notch_filter_lower = 49;
CFG.notch_filter_upper = 51;

% Do you want to use cleanline to remove 50Hz noise?
CFG.do_cleanline = false;% CFG.do_cleanline = 0;

% Do you want to use linear detrending (requires Andreas Widmann's
% function).?
CFG.do_detrend = false;% CFG.do_detrend = 0;

%% Bad channel detection parameters
% NOTE: This set of settings is incompatible with the rej_cleanrawdata
% option below (as that will already take care of interpolation).
% do you want to interpolate bad channels? (happens before ICA)
CFG.do_interp = true;% CFG.do_interp = 1;

% there are (currently) three types of bad channels: those in your
% spreadsheet (column "interp_chans"), automatically detected flat channels
% and automatically detected noisy channels. Which do you want to
% interpolate?
CFG.interp_these = {'spread'};% CFG.interp_these = {'noisy', 'spread', 'flat'}; 

% show the noisy channels in an interactive plot before interpolation?
CFG.interp_plot = false;% CFG.interp_plot = true;

% ...If not interpolating, do you want to ignore those channels in
% automatic artifact detection methods? 1 = use only the other channels.
CFG.ignore_interp_chans = true;% CFG.ignore_interp_chans = 1;

%% Artifact detection parameters
% NOTE: EEGlab now ships with the fully automagic clean rawdata plugin as 
% the default artifact removal method. You can opt to use this method. As 
% it cleans the *raw*data, this obviously needs to happen in prep01, as 
% opposed to all other cleaning methods. Note that, by default, this
% includes a 0.5Hz high-pass filter (kaiser FIR, can be changed in args,
% see clean_drifts() & clean_artifacts()). If using clean_rawdata, this
% filter should always be prefered over the regular filter implementation.
% Note that they call it "raw"data, but several tutorials recommend first
% cleaning line noise (via cleanline algo) and filtering. That's the way
% it's implemented in Elektro-Pipe now: Cleanline -> filter -> clean_rawdata. 
% Clean_rawdata internally performs a reconstruction of the artifact
% subspace ("ASR"; https://doi.org/10.1109/tbme.2015.2481482) based on PCA.
% ASR + ICA = supposed to be good (). Generally, I found Makoto's
% Preprocessing pipeline linking to most relevant information on ASR. In
% general, this happens:
% 1. High-pass filter to remove drifts
% 2. Remove channels that are flat for more than 5s
% 3. Remove channels that are noisy (i.e., low correlation with adjacent channels)
% 4. Find the cleanest part of data (see algo in publication), use this as reference.
% 5. Using a moving window, compute PCA and compare window's PCs to reference signal
% 6. Remove PCs that are more than N SD's away from reference and reconstruct them (8 default, 20 "lax" criterion)
% 7. slide again, to detect windows that could not be repaired.
% 8. remove these windows (CAREFUL: this might crash behavioral/eyetrack coregistration (if relevant events are deleted)! Therefore defaults to 1 ~ "off").
CFG.rej_cleanrawdata = true;% CFG.rej_cleanrawdata = 1;
CFG.rej_cleanrawdata_args = {'WindowCriterion', 'off', ...
    'LineNoiseCriterion', 'off', 'ChannelCriterion', 0.75, 'MaxMem', 64000,...
    'BurstCriterion', 20, 'BurstCriterionRefMaxBadChns', 0.2}; %varargin passed to clean_artifacts(), "tuning should be the exception"
CFG.rej_cleanrawdata_interp = true;% CFG.rej_cleanrawdata_interp = true; % interpolate bad channels that have been removed by cleanrawdata?
CFG.rej_cleanrawdata_dont_interp = {'IO1'}; % correlation based measures dont make sense for some channels (e.g., IO1 will not be .85 correlated with scalp channels)

% set all the CFG.do_rej_* to 0 to deactivate automatic artifact
% detection/rejection in prep02.

% In case you use automatic artifact detection, do you want to
% automatically delete detected trials or inspect them after deletion?
CFG.rej_auto = true;% CFG.rej_auto = 0;

% Just for semi-automatic selection (i.e., CFG.rej_auto is false):
%  Do you want to display events in the eegplot (takes much longer to
%  plot, due to eyetracker events)?
CFG.display_events = false;% CFG.display_events = 0;

% Do you want to reject trials based on amplitude criterion? (automatic and
% manual)
CFG.do_rej_thresh = true;% CFG.do_rej_thresh   = 1;
CFG.rej_thresh = 450;% CFG.rej_thresh      = 450;
CFG.rej_thresh_tmin = -1;% CFG.rej_thresh_tmin = CFG.epoch_tmin;
CFG.rej_thresh_tmax = 4.5;% CFG.rej_thresh_tmax = CFG.epoch_tmax;

% Do you want to reject trials based on slope?
CFG.do_rej_trend = false;% CFG.do_rej_trend       = 0;
CFG.rej_trend_winsize  = CFG.new_sampling_rate * abs(CFG.epoch_tmin - CFG.epoch_tmax);
CFG.rej_trend_maxSlope = 30;
CFG.rej_trend_minR     = 0; %0 = just slope criterion

% Do you want to reject trials based on joint probability?
CFG.do_rej_prob = true;% CFG.do_rej_prob         = 1;
CFG.rej_prob_locthresh = 8;% CFG.rej_prob_locthresh  = 8;
CFG.rej_prob_globthresh = 4;% CFG.rej_prob_globthresh = 4; 

% Do you want to reject trials based on kurtosis?
CFG.do_rej_kurt = false;% CFG.do_rej_kurt         = 0;
CFG.rej_kurt_locthresh  = 6;
CFG.rej_kurt_globthresh = 3; 

%% Eyelink related input
% Do you want to coregister eyelink eyetracking data?
CFG.coregister_Eyelink = true;% CFG.coregister_Eyelink = 1; %0=don't coregister

% Coregistration is done by using the first instance of the first value and
% the last instance of the second value. Everything inbetween is downsampled
% and interpolated.
CFG.eye_startEnd = [10 125];% CFG.eye_startEnd       = []; % e.g., [10,20]

% After data has been coregistered, eyetracking data will be included in
% the EEG struct. Do you want to keep the eyetracking-only files (ASCII &
% mat)?
CFG.eye_keepfiles = [1 1];% CFG.eye_keepfiles      = [0 0];


%% Parameters for ICA.
CFG.ica_type = 'runica';% CFG.ica_type = 'binica';
CFG.ica_extended = true;% CFG.ica_extended = 1; % Run extended infomax ICA?
CFG.ica_chans = CFG.data_chans; % Typicaly, ICA is computed on all channels, unless one channel is not really EEG.
CFG.ica_ncomps = 0;% CFG.ica_ncomps = numel(CFG.data_chans) - 3; % if ica_ncomps==0, determine data rank from the ...
% data (EEGLAB default). Otherwise, use a fixed number of components. Note: subject-specific
% settings will override this parameter.

% Do you want to do an extra run of high-pass filtering before ICA (i.e., after segmentation)?
% see Olaf Dimigen's OPTICAT.
% The data as filtered below are only used to compute the ICA. The
% activation is then reprojected to the original data filtered as indicated
% above in the section 'filters'.
CFG.do_ICA_hp_filter = true;% CFG.do_ICA_hp_filter = 1;
CFG.hp_ICA_filter_type = 'eegfiltnew';% CFG.hp_ICA_filter_type = 'eegfiltnew'; % 'butterworth' or 'eegfiltnew' or kaiser - not recommended
CFG.hp_ICA_filter_limit = 2.5;% CFG.hp_ICA_filter_limit = 2.5; 
CFG.hp_ICA_filter_tbandwidth = 0.2;% CFG.hp_ICA_filter_tbandwidth = 0.2;% only used for kaiser
CFG.hp_ICA_filter_pbripple = 0.01;% CFG.hp_ICA_filter_pbripple = 0.01;% only used for kaiser

% Olaf Dimigen recommends to overweight spike potentials using his OPTICAT
% approach. Do you want to do this prior to computung ICA?
CFG.ica_overweight_sp = true;% CFG.ica_overweight_sp = 1;
CFG.opticat_saccade_before = -0.02;% CFG.opticat_saccade_before = -0.02; % time window to overweight (-20 to 10 ms)
CFG.opticat_saccade_after = 0.01;% CFG.opticat_saccade_after = 0.01;
CFG.opticat_ow_proportion = 0.5;% CFG.opticat_ow_proportion = 0.5; % overweighting proportion
CFG.opticat_rm_epochmean = true;% CFG.opticat_rm_epochmean = true; % subtract mean from overweighted epochs? (recommended)

% if CFG.keep_continuous is true, should ICA weights be backprojected to
% the continuous data?
CFG.ica_continuous = false;% CFG.ica_continuous = 0;

%% ICA rejection/detection parameters
% if CFG.keep_continuous and CFG.ica_continuous are true, do you want to
% remove components from epoched data only ('epoch') or continuous data only 
% ('cont', default)? 
CFG.ica_rm_continuous = 'epoch';% CFG.ica_rm_continuous = 'epoch'; % if you want to do both, simply change this line and run prep04 again.

% Create a plot for manual inspection after running specified algorithms?
CFG.ica_plot_ICs = true;

% Ask for confirmation to remove ICs?
CFG.ica_ask_for_confirmation = true;

% Select occular ICs based on eyetrack-data? requires EYE-ICA
% (incompatible with resampling! - see help eyetrackerica)
CFG.do_eyetrack_ica = false;% CFG.do_eyetrack_ica          = true;
CFG.eyetracker_ica_varthresh = 1.3;% CFG.eyetracker_ica_varthresh = 1.3; % variance ratio threshold (var(sac)/var(fix))
CFG.eyetracker_ica_sactol = [5, 0];% CFG.eyetracker_ica_sactol    = [5 10]; % Extra temporal tolerance around saccade onset and offset
CFG.eyetracker_ica_feedback = 4;% CFG.eyetracker_ica_feedback  = 4; % do you want to see plots of (1) all selected bad components (2) all good (3) bad & good or (4) no plots?

% select components based on IClabel classifier?
CFG.do_iclabel_ica = true;% CFG.do_iclabel_ica = true;
% what types of ICs do you want to remove? Options are:
% 'Brain', 'Muscle', 'Eye', 'Heart', 'Line Noise', 'Channel Noise', 'Other'
CFG.iclabel_rm_ICtypes = {'Eye','Muscle', 'Heart','Channel Noise','Other','Line Noise'}; %was: eye muscle heart {'Eye', 'Muscle', 'heart'};%
% minimum classification accuracy to believe an ICs assigned label is true.
% Can be a vector with one accuracy per category or a single value for all
% categories.
CFG.iclabel_min_acc = 0.5;% 0.75;%was: 0.75; %50% is not chance, but seems realistic based on inspectio

% select components based on correlation with EOG? 
CFG.do_corr_ica = false;% CFG.do_corr_ica = false;
CFG.ic_corr_bad = 0.65; %threshold for IC rejection (uses absolute values)

% select components with SASICA?
CFG.do_SASICA = false;% CFG.do_SASICA       = false;
CFG.sasica_heogchan = num2str(CFG.data_chans+1);
CFG.sasica_veogchan = num2str(CFG.data_chans+2);
CFG.sasica_autocorr = 20;
CFG.sasica_focaltopo = 'auto';

%% Stuff below this line is for experiment-specific analyses.

%% Hilbert-Filter anaylsis
CFG.hilb_flimits       = [5 12];
CFG.hilb_transbwidth   = 2;
CFG.hilb_quant_tlimits = [-0.800 0];
CFG.hilb_quant_chans   = [1:64];
CFG.hilb_quant_nbins   = 2;

%% TF analysis
% Note: In case you want to store the single trial data as well, you can specify a subset of time, frequency, and/or channels below
CFG.tf_chans       = CFG.data_chans;
CFG.tf_freqlimits  = [2 40];
CFG.tf_nfreqs      = 20;
CFG.tf_freqsout    = CFG.tf_freqlimits; %use this to specify specific frequencies and overwrite the combination of nfreqs, scale and limits
CFG.tf_cycles      = [1 10];
CFG.tf_causal      = 'off';
CFG.tf_freqscale   = 'linear';
CFG.tf_ntimesout   = 600;
CFG.tf_verbose     = 'on'; % if not specified: overwritten by EP.verbose

%% TF single-trial analysis (leave empty if you do not want a subset of the specs above)
CFG.single.tf_chans       = []; %cell with characters or vector with indeces
CFG.single.tf_freqlimits  = []; %in Hz
CFG.single.tf_timelimits  = []; %in seconds

%% FFT analysis
CFG.fft_chans   = CFG.data_chans;
CFG.fft_npoints = 'auto'; %npoints as in niko busch's 'my_fft' can be 'auto', meaning N = raw datapoints
CFG.fft_time    = [2000, 2500]; %in ms
CFG.fft_timedim = 'auto'; %usually auto is fine. will warn you if that doesn't work.
CFG.fft_chandim = 'auto'; %usually auto is fine. will warn you if that doesn't work.
CFG.fft_srate   = 'auto'; %usually auto is fine. will warn you if that doesn't work.
CFG.fft_returncomplex = 0;
CFG.fft_dobsl   = 1; %run basline subtraction? if 1, needs bsltime in seconds.
CFG.fft_bsltime = [1000, 1500]; %in ms
CFG.fft_bslnpoints = 'auto';
CFG.fft_verbose = 'on'; % if not specified: overwritten by EP.verbose

%% FFT single-trial analysis
CFG.single.fft_chans = [];%[13:32, 56:64]; %cell with characters or vector with indeces
CFG.single.fft_time  = [];%[1, 3];

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%Assertion checks for incompatible configurations
assert(~(CFG.do_eyetrack_ica & CFG.do_resampling));
assert(~(CFG.rej_cleanrawdata & ...
(CFG.do_interp & ~all(strcmp(CFG.interp_these, 'spread')))));
end
