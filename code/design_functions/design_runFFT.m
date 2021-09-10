function [FFT] = design_runFFT(EP)
% TF = DESIGN_RUNFFT(EP)
%
% Compute fast fourier transforms for all conditions specified in EP.
% The function computes for every design a struct "FFT".
% This struct has dimensions:
% levelsFactor1+1 x levelsFactor2+1 x ... x levelsFactorN+1.
% '+1' refers to the average of each factor. So in a 2x2 design, you'll get
% a 3x3 struct where TF(1, 3) is power for level 1 of factor 1 regardless
% of the levels of factor 2.
%
% Consequently, each field contains a struct for each subject analyzed in a
% certain design. This struct contains the following fields:
%
% data fields
%  TF(lvlF1,...,lvlFn).fft      : 4D fft freq x power x channels x subject
%
% further information fields
%  TF(lvlF1,...,lvlFn).times; TF(lvlF1,...,lvlFn).freqs;
%  TF(lvlF1,...,lvlFn).cycles; TF(lvlF1,...,lvlFn).freqsol;
%  TF(lvlF1,...,lvlFn).timeresol; TF(lvlF1,...,lvlFn).wavelet;
%  TF(lvlF1,...,lvlFn).old_srate; TF(lvlF1,...,lvlFn).new_srate;
%  TF(lvlF1,...,lvlFn).chanlocs; TF(lvlF1,...,lvlFn).condition
%
% By default, results will be averaged across trials, we do not save single trials.
% You can change this behavior by EP.singletrialFFT to true. This will still
% produce the averaged data, but creates an additional subfolder with one
% file per subject containing the single data and this subject's average.
%
% Input:
% struct 'EP', as outlined in design_master. Uses the following fields:
%
% EP.design_idx: which designs specified in get_design. Default is all designs.
% EP.cfgfile: get_cfg.m that should be used
% EP.S: Table with processing information
% EP.D: result of get_design.m/design struct
% EP.filename_in: common suffix of files to be used as input
% EP.project_name: Name for the current adventure. e.g., 'FFT'
% EP.verbose: massive debugging output or not.
% EP.dir_out: master-folder in which subfolders per design will be saved.
%
% Optional input:
% EP.keepdouble: if 1, data are kept as double. if 0 (default) data are
%                converted to single.
% EP.who: Optional. can define which subjects to use. Default is all subjects.
% EP.design_idx: which designs specified in get_design. Default is all designs.
% EP.singletrialFFT: Store single-trial data per subject (in addition to
%                    normal data)? default is false.
%
% Output:
% Always the FFT-struct of the last Design. So if your get_design has 3
% designs, FFT for all Designs is computed and saved but only design 3 will
% be provided via the direct output parameter. Everything else would use
% way too much RAM.
%
% Written by Wanja Moessing (moessing@wwu.de). University of Muenster

%% Starting Info
fprintf(['\n-----------------------------------------\n',...
    'design_runFFT: Preparing fft analysis\n',...
    '-----------------------------------------\n']);

%% Decode which subjects to process.
if ~isfield(EP, 'who')
    EP.who = [];
end
subjects_idx = get_subjects(EP);

%% Decode which designs to process.
if ~isfield(EP, 'design_idx') || isempty(EP.design_idx)
    EP.design_idx = 1:length(EP.D); %default = all designs
end

%% store data in single or double precision?
if ~isfield(EP, 'keepdouble') || isempty(EP.keepdouble)
    EP.keepdouble = 0;
end

if ~EP.keepdouble && EP.verbose
    disp('design_runFFT: Will store data in single precision to preserve space.');
elseif EP.keepdouble && EP.verbose
    disp('design_runFFT: Keeping data in double precision. Are you sure that''s necessary?');
end

%% store single-trial data?
if ~isfield(EP, 'singletrialFFT') || isempty(EP.singletrialFFT)
    EP.singletrialFFT = false;
end
%--------------------------------------------------------------
% loop over designs
%--------------------------------------------------------------
for idesign = 1:length(EP.design_idx)
    thisdesign        = EP.design_idx(idesign);
    DINFO             = get_design_matrix(EP.D(thisdesign));
    DINFO.design_idx  = thisdesign;
    DINFO.design_name = [EP.project_name '_D' num2str(thisdesign)];
    
    %--------------------------------------------------------------
    % get all conditions for the current design and create labels for them
    %--------------------------------------------------------------
    [condition_names] = get_condition_names(EP.D(thisdesign), DINFO);
    
    %--------------------------------------------------------------
    % loop over subjects and process all subconditions.
    % Note: It's cumbersome to load each subject multiple times (i.e., once
    % per design). However, that's the only way to preserve some RAM while
    % creating a single file containing all data for each design.
    %--------------------------------------------------------------
    % Estimate how long it will take
    PerSubDuration = [];
    for isub = 1:length(subjects_idx)
        clear C;
        fprintf(['\n-----------------------------------------\n',...
            'design_runFFT: Now processing subject %i of %i in Design %i of %i\n',...
            '-----------------------------------------\n'],...
            isub,length(subjects_idx), idesign, length(EP.design_idx));
        
        meanDur = mean(seconds(PerSubDuration));
        eta = meanDur * (length(subjects_idx) - isub + 1)		;
        fprintf(['\n-----------------------------------------\n',...
            'Mean duration per subject is: %.0f minutes\n',...
            'Estimated time of arrival (in the current design): %s (in %.0fh %.0fmin)',...
            '\n-----------------------------------------\n'],...
            round(minutes(meanDur)), datetime('now') + eta, floor(hours(eta)),...
            mod(minutes(eta), 60))
        
        tic;
        
        %--------------------------------------------------------------
        % Load this subject's EEG data.
        %--------------------------------------------------------------
        % Load CFG file. I know, eval is evil, but this way we allow the user
        % to give the CFG function any arbitrary name, as defined in the EP
        % struct.
        [pathstr,cfgname,~] = fileparts(EP.cfgfile);
        addpath(pathstr)
        eval(['my_CFG = ' cfgname '(' num2str(subjects_idx(isub)) ', EP.S);']);
        CFG = my_CFG; %this is necessary to make CFG 'unambiguous in this context'
        EEG = pop_loadset('filename', [CFG.subject_name EP.filename_in '.set'] , ...
            'filepath', CFG.dir_eeg);
        
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
            if strcmp(cfg.preproc_reference, 'robust')
                %%settings for robust average reference
                
                % don't use channels as evaluation channels, of which we already
                % know that they are bad.
                if iscell(S.interp_chans)
                    evalChans = find(~ismember(...
                        {EEG.chanlocs(cfg.data_chans).labels},...
                        strsplit(S.interp_chans{who_idx},',')));
                else
                    evalChans = CFG.data_chans;
                end
                
                robustParams = struct('referenceChannels', evalChans,...
                    'evaluationChannels', evalChans,...
                    'rereference', cfg.data_chans,...
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
                EEG = pop_reref( EEG, CFG.postproc_reference, 'keepref','on',...
                    'exclude',[BipolarChans, Eyechans]);
            end
        end
        %--------------------------------------------------------------
        % Extract relevant trials for each condition.
        %--------------------------------------------------------------
        [condinfo] = get_design_trials(EEG, EP, DINFO);
        
        %--------------------------------------------------------------
        % Get the number of channels and conditios
        %--------------------------------------------------------------
        nchans = length(CFG.fft_chans);
        nconds = length(DINFO.design_matrix);
        condition_info_stored = zeros(1,nconds);
        %-----------------------------------------------------------------
        % CFG.fft_verbose should be preferred over EP.verbose.
        % In case no CFG.tf_verbose is set, set it automatically.
        %-----------------------------------------------------------------
        useEPverbose = true;
        if isfield(CFG,'fft_verbose')
            if any(strcmpi(CFG.tf_verbose,{'on','off'}))
                useEPverbose = false;
            end
        end
        
        if useEPverbose && EP.verbose
            CFG.fft_verbose = 'on';
        else
            CFG.fft_verbose = 'off';
        end
        
        %-----------------------------------------------------------
        % Run FFT analysis once across all trials and channels.
        %-----------------------------------------------------------
        if EP.verbose
            disp('design_runFFT: computing fft...');
        end
        
        %--------------------------------------------------------------
        % Run the actual FFT for this channel
        %--------------------------------------------------------------
        % deduce what the timedim is
        if strcmp(CFG.fft_timedim, 'auto')
            timedim = find(size(EEG.data) == length(EEG.times));
            if length(timedim) ~= 1
                error(['Can''t deduce timedim. do you have as many '...
                    'timepoints as you have trials and/or channels? '...
                    'specifiy in get_cfg!'])
            end
        else
            timedim = CFG.fft_timedim;
        end
        
        % deduce what the chandim is
        if strcmp(CFG.fft_chandim, 'auto')
            chandim = find(size(EEG.data) == length(EEG.chanlocs));
            if length(chandim) ~= 1
                error(['Can''t deduce chandim. do you have as many '...
                    'channels as you have trials and/or timepoints? '...
                    'specifiy in get_cfg!'])
            end
        else
            timedim = CFG.fft_timedim;
        end
        
        
        % deduce srate
        if strcmp(CFG.fft_srate, 'auto')
            timestime  = dist(min(EEG.times./1000), max(EEG.times./1000));
            deducsrate = round(size(EEG.data, timedim) / timestime);
            if EEG.srate == deducsrate
                srate = EEG.srate;
            else
                error(['EEG.srate not true! If you''re 100% sure, what'...
                    ' you''re doing, indicate srate in CFG.fft_srate.'])
            end
        else
            srate = CFG.fft_srate;
        end
        
        % reduce data to channels of interest
        origdims = 1:ndims(EEG.data);
        tmpdims  = [chandim, origdims(origdims ~= chandim)];
        EEG.data = permute(EEG.data,tmpdims);
        EEG.data = EEG.data(CFG.fft_chans, :, :, :, :, :, :);
        EEG.data = ipermute(EEG.data, tmpdims);
        
        % reduce data to time of interest
        % find time of interest
        [~ ,tidx(1)] = min(abs(EEG.times - CFG.fft_time(1)));
        [~ ,tidx(2)] = min(abs(EEG.times - CFG.fft_time(end)));
        tidx = tidx(1):tidx(2);
        tmpdims  = [timedim, origdims(origdims ~= timedim)];
        EEG.data = permute(EEG.data,tmpdims);
        EEG.bsldata = EEG.data;
        EEG.data = EEG.data(tidx, :, :, :, :, :, :);
        EEG.data = ipermute(EEG.data, tmpdims);
        
        % do the same for the baseline
        % find time of baseline
        if CFG.fft_dobsl
            [~ ,bslTidx(1)] = min(abs(EEG.times - CFG.fft_bsltime(1)));
            [~ ,bslTidx(2)] = min(abs(EEG.times - CFG.fft_bsltime(end)));
            bslTidx = bslTidx(1):bslTidx(2);
            EEG.bsldata = EEG.bsldata(bslTidx, :, :, :, :, :, :);
            EEG.bsldata = ipermute(EEG.bsldata, tmpdims);
        end
        
        % should npoints be equal to size of data?
        if strcmp(CFG.fft_npoints, 'auto')
            npoints = size(EEG.data, timedim);
        else
            npoints = CFG.fft_npoints;
        end

        [amps, freqs] = my_fft(EEG.data, timedim, srate, npoints,...
            CFG.fft_returncomplex);
        
        if CFG.fft_dobsl
            % should npoints be equal to size of data?
            if strcmp(CFG.fft_bslnpoints, 'auto')
                npoints = size(EEG.bsldata, timedim);
            else
                npoints = CFG.fft_bslnpoints;
            end
            
            [bslamps, bslfreqs] = my_fft(EEG.bsldata, timedim, srate, npoints,...
                CFG.fft_returncomplex);
        end
        %--------------------------------------------------------------
        % Loop over conditions and extract fft data from corresponding trials.
        %--------------------------------------------------------------
        for icond = 1:nconds
            trialidx = condinfo(icond).trials;
            if isempty(trialidx)
                warning('design_run_fft: no trials found for condition %i: ''%s''',...
                    icond,condition_names{icond});
            end
            
            thisfft = amps(:,:,trialidx);
            idx = condinfo(icond).level;
            
            %----------------------------------------------------------
            % Store information
            %----------------------------------------------------------
            if ~condition_info_stored(icond)
                % store information
                FFT(idx{:}).chans         = CFG.fft_chans;
                FFT(idx{:}).chanlocs      = EEG.chanlocs(CFG.fft_chans);
                FFT(idx{:}).times         = EEG.times(tidx);
                FFT(idx{:}).bsltime       = CFG.fft_bsltime;
                FFT(idx{:}).dobsl         = CFG.fft_dobsl;
                FFT(idx{:}).npoints       = CFG.fft_npoints;
                FFT(idx{:}).hascomplex    = CFG.fft_returncomplex;
                FFT(idx{:}).condition     = condition_names{icond};
                FFT(idx{:}).DINFO         = DINFO;
                FFT(idx{:}).trials        = condinfo(icond).trials;
                FFT(idx{:}).factor_names  = DINFO.factor_names;
                condition_info_stored(icond) = 1;
            end
            FFT(idx{:}).subject{isub} = CFG.subject_name;
            FFT(idx{:}).freqs{isub}   = freqs;
            
            if CFG.fft_dobsl
                thisbslfft = bslamps(:,:,trialidx);
                FFT(idx{:}).bslfreqs{isub}   = bslfreqs;
                if ~EP.keepdouble
                    FFT(idx{:}).bslfft{isub} = single(thisbslfft);
                    FFT(idx{:}).rawfft{isub} = single(thisfft);
                    FFT(idx{:}).fft{isub} = single(thisfft - thisbslfft);
                    FFT(idx{:}).avgbslfft(:,:,isub) = ...
                        single(squeeze(mean(thisbslfft, 3)));
                    FFT(idx{:}).avgrawfft(:,:,isub) = ...
                        single(squeeze(mean(thisfft, 3)));
                    FFT(idx{:}).avgfft(:,:,isub) = ...
                        single(squeeze(mean(FFT(idx{:}).fft{isub}, 3)));
                else
                    FFT(idx{:}).bslfft{isub} = thisbslfft;
                    FFT(idx{:}).rawfft{isub} = thisfft;
                    FFT(idx{:}).fft{isub} = thisfft - thisbslfft;
                    FFT(idx{:}).avgbslfft(:,:,isub) = ...
                        squeeze(mean(thisbslfft, 3));
                    FFT(idx{:}).avgrawfft(:,:,isub) = ...
                        squeeze(mean(thisfft, 3));
                    FFT(idx{:}).avgfft(:,:,isub) = ...
                        squeeze(mean(FFT(idx{:}).fft{isub}, 3));
                end
            else
                if ~EP.keepdouble
                    FFT(idx{:}).fft{isub} = single(thisfft);
                    FFT(idx{:}).avgfft(:,:,isub) = ...
                        single(squeeze(mean(FFT(idx{:}).fft{isub}, 3)));
                else
                    FFT(idx{:}).fft{isub} = thisfft;
                    FFT(idx{:}).avgfft(:,:,isub) = ...
                        squeeze(mean(FFT(idx{:}).fft{isub}, 3));
                end
            end
            % extract information on factor values so they are easily
            % accessible in later stages.
            for ifactor = 1:length(DINFO.factor_values)
                if condinfo(icond).level{ifactor}==length(DINFO.factor_values{1,ifactor})+1
                    FFT(idx{:}).factor_values{1,ifactor} = '*';
                else
                    FFT(idx{:}).factor_values{1,ifactor} = ...
                        DINFO.factor_values{1,ifactor}{condinfo(icond).level{ifactor}};
                end
            end
            
            % you can manipulate the following lines of code to extract
            % Info about the trial circumstances. This might be useful
            % for analyzing behavior*eeg.
            k = 0;
            Info = struct;
            for i = trialidx
                k = k + 1;
                Info(k).validity = unique([EEG.epoch(i).eventvalidity{:}]);
                Info(k).BehavTrial = unique([EEG.epoch(i).eventtrialnumber{:}]);
                Info(k).RespDiff = unique([EEG.epoch(i).eventRespDiff{:}]);
                Info(k).Session = unique([EEG.epoch(i).eventSession{:}]);
            end
            FFT(idx{:}).Info{isub} = Info;
        end
        %use this to give an indicator of how long it'll take...
        PerSubDuration = [PerSubDuration, toc];
    end
    
    %--------------------------------------------------------------
    % Save file for the current design, clear RAM, and continue
    % to next design.
    %--------------------------------------------------------------
    savepath = [EP.dir_out filesep DINFO.design_name];
    if ~exist(savepath, 'dir')
        mkdir(savepath)
    end
    savefile = fullfile(savepath, [EP.project_name, '_D', num2str(DINFO.design_idx), '.mat']);
    save(savefile, 'FFT');
    if idesign ~= length(EP.design_idx) %don't clear if it's the last one.
        clear FFT;
    end
end

end
