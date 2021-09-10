function ALLEEG = design_erp_grandaverage(EP)
%function eeg_grandaverage(cfg, subjectidx, filenamebase, d, designidx, inpath, outpath)
%
% This function computes the grandaverage ERP for a group of subjects. The
% design matrices that defines which factors and factor values define a
% condition are defined in a separate function "getdesign".
%
% cfg: struct with configuration file. Important mostly for defining directories.
% Important: cfg file should contain field cfg.dir_cfg describing the path
% where the cfg is located. This is important since the function needs to
% reload the cfg each time a new subject is loaded to retrieve the
% subject-specific information, e.g. the directory where the subject's data
% are stored.
%
% filenamebase: string with a suffix that is a part of the data sets to be
% loaded, e.g.: '_united_icaclean' or 'icacorr'.
%
% subjectidx: indices of EEG data sets. The values refer to the datasets defined in
% cfg.allsubjects in the getcfg.m file.
%
% d: a struct defining the statistical design.
%
% designidx: which of the designs are to be computed (can be a vector of
% indices]).
%
% inpath: where are the data located? E.g. "/data/myexperiment/EEG/". We
% still assume that every subject has an individual subfolder in inpath.
% Legacy note: we previously assumed that the data are stored in
% cfg.dir_eeg, but this was unhandy for different types of data, e.g.
% Hilbert transformed EEG data.
%
% outpath: where to store the grand average. Legacy note: we previously
% stored everything in the GRAND folder, but this makes it easier when
% dealing with more than just one set of EEG files, e.g. when we process
% standard EEG and hilbert transformed datasets.

%% Add paths to the Elektropipe toolbox.
p = fileparts(which('design_erp_grandaverage'));
addpath([p, filesep, 'design_functions']);
addpath([p, filesep, 'management_functions']);

%% Decode which subjects to process.
if ~isfield(EP, 'who')
    EP.who = [];
end
subjects_idx = get_subjects(EP);

%% Decode which designs to process.
if ~isfield(EP, 'design_idx') || isempty(EP.design_idx)
    EP.design_idx = 1:length(EP.D); %default = all designs
end

%% Loop over all designs for which you want to compute grand averages.

for idesign = 1:length(EP.design_idx)
    
    %
    clear DINFO;
    thisdesign = EP.design_idx(idesign);
    
    DINFO = get_design_matrix(EP.D(thisdesign));
    DINFO.design_idx = thisdesign;
    DINFO.design_name = [EP.project_name '_D' num2str(thisdesign)];
    
    % Compose the file names of all conditions in this design.
    DINFO.condition_names = get_condition_names(EP.D(thisdesign), DINFO);
    %single factor case
    if length(DINFO.nlevels)==1
        reshapeSz = [1,DINFO.nlevels+1];
    else
        reshapeSz = DINFO.nlevels+1;
    end
    DINFO.condition_names = reshape(DINFO.condition_names, reshapeSz);
    DINFO.n_conditions = numel(DINFO.condition_names);
    DINFO = orderfields(DINFO);
    
    %------------------------------
    % Load each subject's EEG data and compute single subject averages for
    % each condition.
    %------------------------------
    for isub = 1:length(subjects_idx)
        
        % Load CFG file. I know, eval is evil, but this way we allow the user
        % to give the CFG function any arbitrary name, as defined in the EP
        % struct.
        [pathstr, cfgname, ext] = fileparts(EP.cfgfile);
        addpath(pathstr)
        eval(['CFG = ' cfgname '(' num2str(subjects_idx(isub)) ', EP.S);']);
        
        subject_names{isub} = [CFG.subject_name EP.filename_in '.set'];
        
        EEG = pop_loadset('filename', subject_names{isub} , ...
            'filepath', [EP.dir_in filesep CFG.subject_name]);
        
        %--------------------------------------------------------------
        % don't re-ference Eye-channels & *EOG to EEG-reference
        %--------------------------------------------------------------
        Eyechans = find(strcmp('EYE',{EEG.chanlocs.type}));
        BipolarChans = find(ismember({EEG.chanlocs.labels},{'VEOG','HEOG'}));
        do_reref = true;
        if ~isempty(CFG.postproc_reference)
            if ischar(CFG.postproc_reference)
                if strcmp(CFG.postproc_reference, 'keep')
                    do_reref = false;
                end
            end
        end
        
        if do_reref
            if strcmp(CFG.postproc_reference, 'robust')
                %%settings for robust average reference
                
                % don't use channels as evaluation channels, of which we already
                % know that they are bad.
                if iscell(EP.S.interp_chans(subjects_idx(isub)))
                    evalChans = find(~ismember(...
                        {EEG.chanlocs(CFG.data_chans).labels},...
                        strsplit(EP.S.interp_chans{subjects_idx(isub)},',')));
                else
                    evalChans = CFG.data_chans;
                end
                
                robustParams = struct('referenceChannels', evalChans,...
                    'evaluationChannels', evalChans,...
                    'rereference', CFG.data_chans,...
                    'interpolationOrder', 'post-reference',...
                    'correlationThreshold', 0.1e-99,...
                    'ransacOff', true); %disable correlation threshold, as we don't want to detect half of the channels.
                
                % compute reference channel
                [~,robustRef] = performReference(EEG, robustParams);
                % add new robust reference channel to EEG
                EEG.data(end+1,:) = robustRef.referenceSignal;
                EEG.nbchan = size(EEG.data,1);
                EEG.chanlocs(end+1).labels = 'RobustRef';
                EEG.robustRef = robustRef;
                % pass this new reference to eeglab's default rereferencing
                % function. This is necessary, because PREP's performReference only
                % outputs an EEG structure where all channels are interpolated.
                [EEG, com] = pop_reref( EEG, 'RobustRef','keepref','on',...
                    'exclude', CFG.data_chans(end) + 1:EEG.nbchan-1);
            else
                EEG = pop_reref(EEG, CFG.postproc_reference, 'keepref', 'on',...
                    'exclude', [BipolarChans, Eyechans]);
            end
        end
        
        % Bandpass filter and Hilbert.
        if strcmp(EP.process, 'bp_alpha')
            dat = EEG.data;
            dat = reshape(dat, [EEG.nbchan, EEG.pnts*EEG.trials]);
            dat = eegfilt(dat, EEG.srate, 7, 13)';
            dat = abs(hilbert(dat)).^2;
            dat = reshape(dat', [EEG.nbchan, EEG.pnts, EEG.trials]);
            EEG.data = dat;
        end
        
        % Extract relevant trials for each condition.
        design_trials = get_design_trials(EEG, EP, DINFO);
        
        switch EP.process
            case {'erp', 'bp_alpha'}
                [erp(:,:,:,isub), ntrials(:,isub)] = make_erp_grandaverage(EEG, DINFO, design_trials);
        end
        
    end
    
    
    %--------------------------------
    % Compute and save grand average.
    %--------------------------------
    savepath = [EP.dir_out filesep DINFO.design_name];
    if ~exist(savepath, 'dir')
        mkdir(savepath)
    end
    
    switch EP.process
        case {'erp', 'bp_alpha'}
            ALLEEG = save_erp_grandaverage(DINFO, EP, EEG, subject_names, erp, ntrials, savepath);
    end
    
    
end

disp('Done.')
