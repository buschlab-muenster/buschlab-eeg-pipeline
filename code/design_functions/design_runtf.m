function [TF] = design_runtf(EP)
% TF = DESIGN_RUNTF(EP)
%
% Compute a time frequency analysis for all conditions specified in EP.
% The function computes for every design a struct "TF".
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
%  TF(lvlF1,...,lvlFn).pow      : 4D power freqs x times x channels x subject
%  TF(lvlF1,...,lvlFn).itc      : 4D phase-locking similar to pow
%
% further information fields
%  TF(lvlF1,...,lvlFn).times; TF(lvlF1,...,lvlFn).freqs;
%  TF(lvlF1,...,lvlFn).cycles; TF(lvlF1,...,lvlFn).freqsol;
%  TF(lvlF1,...,lvlFn).timeresol; TF(lvlF1,...,lvlFn).wavelet;
%  TF(lvlF1,...,lvlFn).old_srate; TF(lvlF1,...,lvlFn).new_srate;
%  TF(lvlF1,...,lvlFn).chanlocs; TF(lvlF1,...,lvlFn).condition
%
% By default, results will be averaged across trials, we do not save single trials.
% You can change this behavior by EP.singletrialTF to true. This will still
% produce the averaged data, but creates an additional subfolder with one
% file per subject containing the single data and this subject's average.
%
% The low-level timefreq function uses all cores available on a computer.
% So having many cores makes this function *much* faster. Keep in mind,
% that this needs a lot of RAM.
%
% In case Matlab just randomly disappears without error message: This could
% be related to GPU-drivers. You can thus try to avoid this by running
% Matlab without java/gui.
%
% Input:
% struct 'EP', as outlined in design_master. Uses the following fields:
%
% EP.design_idx: which designs specified in get_design. Default is all designs.
% EP.cfgfile: get_cfg.m that should be used
% EP.S: Table with processing information
% EP.D: result of get_design.m/design struct
% EP.filename_in: common suffix of files to be used as input
% EP.project_name: Name for the current adventure. e.g., 'ER-TFA'
% EP.verbose: massive debugging output or not.
% EP.dir_out: master-folder in which subfolders per design will be saved.
%
% Optional input:
% EP.keepdouble: if 1, data are kept as double. if 0 (default) data are
%                converted to single.
% EP.who: Optional. can define which subjects to use. Default is all subjects.
% EP.design_idx: which designs specified in get_design. Default is all designs.
% EP.singletrialTF: Store single-trial data per subject (in addition to
%                   normal data)? default is false.
%
% Output:
% Always the TF-struct of the last Design. So if your get_design has 3
% designs, TF for all Designs is computed and saved but only design 3 will
% be provided via the direct output parameter. Everything else would use
% way too much RAM.
%
% Written by Niko Busch (niko.busch@wwu.de)
% and adjusted for parallel computing and use in Elektro-Pipe by
% Wanja Moessing (moessing@wwu.de). University of Muenster - Dec 6, 2016
% WM: remove parfor and include single-trial output. Dec 2017 

%% Starting Info
fprintf(['\n-----------------------------------------\n',...
    'design_runtf: Preparing time-frequency analysis\n',...
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
    disp('design_runtf: Will store data in single precision to preserve space.');
elseif EP.keepdouble && EP.verbose
    disp('design_runtf: Keeping data in double precision. Are you sure that''s necessary?');
end

%% store single-trial data?
if ~isfield(EP, 'singletrialTF') || isempty(EP.singletrialTF)
    EP.singletrialTF = false;    
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
            'design_runtf: Now processing subject %i of %i in Design %i of %i\n',...
            '-----------------------------------------\n'],...
            isub,length(subjects_idx),idesign,length(EP.design_idx));
        
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
        nchans = length(CFG.tf_chans);
        nconds = length(DINFO.design_matrix);
        
        %-----------------------------------------------------------------
        % CFG.tf_verbose should be preferred over EP.verbose.
        % In case no CFG.tf_verbose is set, set it automatically.
        %-----------------------------------------------------------------
        useEPverbose = true;
        if isfield(CFG,'tf_verbose')
            if any(strcmpi(CFG.tf_verbose,{'on','off'}))
                useEPverbose = false;
            end
        end
        
        if useEPverbose && EP.verbose
            CFG.tf_verbose = 'on';
        else
            CFG.tf_verbose = 'off';
        end
        
        %-----------------------------------------------------------
        % Run TF analysis once across all trials per channel.
        %-----------------------------------------------------------
        if EP.verbose
            disp('design_runtf: computing tf...');
        end
		
        for ichan = 1:nchans
            fprintf('design_runtf: Computing channel %i/%i\n', ichan, nchans);
            if strcmp(CFG.tf_verbose,'on')
                fprintf('\nComputing TF for channel %d ', ichan);
            end
            thischan = CFG.tf_chans(ichan);
            
            %--------------------------------------------------------------
            % Run the actual TF for this channel
            %--------------------------------------------------------------
            [tf, tffreqs, tftimes, wavelet, freqresol, timeresol] = runtf(EEG, CFG, thischan);
            
            %--------------------------------------------------------------
            % Loop over conditions and extract tf data from corresponding
            % trials. We have to do this within the channel-loop so that we
            % can immediately overwrite the tf variable lest it gets to
            % huge.
            %--------------------------------------------------------------
            for icond = 1:nconds
                trialidx = condinfo(icond).trials;
                if isempty(trialidx)
                    warning('design_run_tf: no trials found for condition %i: ''%s''',...
                        icond,condition_names{icond});
                end
                
                thistf   = tf(:,:,trialidx);
                
                idx = condinfo(icond).level;
                
                %----------------------------------------------------------
                % Store single trial data
                %----------------------------------------------------------
                if EP.singletrialTF
                    % If storing single trials: Which subset of data?
                    if isfield(CFG.single,'tf_chans') && ~isempty(CFG.single.tf_chans)
                        if iscell(CFG.single.tf_chans) %specified as name
                            ch = ismember({EEG.chanlocs.labels}, CFG.single.tf_chans);
                        elseif isnumeric(CFG.single.tf_chans)
                            ch = zeros(1, nchans);
                            ch(CFG.single.tf_chans) = 1;
                        end
                    else
						ch = ones(1, nchans);
                    end
                    
                    if isfield(CFG.single,'tf_freqlimits') && ~isempty(CFG.single.tf_freqlimits)
                        hz = (tffreqs >= CFG.single.tf_freqlimits(1) &...
                            tffreqs <= CFG.single.tf_freqlimits(end));
                    else
						hz = true(1, length(tffreqs));
                    end
                    if isfield(CFG.single,'tf_timelimits') && ~isempty(CFG.single.tf_timelimits)
                        t  = (tftimes >= CFG.single.tf_timelimits(1) &...
                            tftimes <= CFG.single.tf_timelimits(end));
                    else
						t = true(1, length(tftimes));
                    end
                    
                    % store information
                    TF(idx{:}).single.chanlocs = EEG.chanlocs(find(ch));
                    TF(idx{:}).single.times    = tftimes(t);
                    TF(idx{:}).single.freqs    = tffreqs(hz);
                    TF(idx{:}).single.subject  = CFG.subject_name;
                    
                    % extract data
                    if ch(ichan)
                        nth_chan = sum(ch(1:ichan));
                        TF(idx{:}).single.chanlocs(nth_chan) = EEG.chanlocs(ichan);
                        if ~EP.keepdouble
                            TF(idx{:}).single.pow(:,:,:,nth_chan) = ...
                                single(abs(thistf(hz, t, :)).^2);
                            TF(idx{:}).single.itc(:,:,:,nth_chan) = ...
                                single(abs(exp(angle(thistf(hz, t, :)) * sqrt(-1))));
                        else
                            TF(idx{:}).single.pow(:,:,:,nth_chan) = ...
                                abs(thistf(hz, t, :)).^2;
                            TF(idx{:}).single.itc(:,:,:,nth_chan) = ...
                                abs(exp(angle(thistf(hz, t, :)) * sqrt(-1)));
                        end
                    end
                end
                if ~EP.keepdouble
                    TF(idx{:}).pow(:,:,ichan,isub) = single(mean(abs(thistf).^2,3));
                    TF(idx{:}).itc(:,:,ichan,isub) = single(abs(mean(exp(angle(thistf) * sqrt(-1)),3)));
                    TF(idx{:}).medianpow(:,:,ichan,isub) = single(median(abs(thistf).^2,3));
                else
                    TF(idx{:}).pow(:,:,ichan,isub) = mean(abs(thistf).^2,3);
                    TF(idx{:}).itc(:,:,ichan,isub) = abs(mean(exp(angle(thistf) * sqrt(-1)),3));
                    TF(idx{:}).medianpow(:,:,ichan,isub) = median(abs(thistf).^2,3);
                end
                TF(idx{:}).times               = tftimes;
                TF(idx{:}).freqs               = tffreqs;
                TF(idx{:}).cycles              = CFG.tf_cycles;
                TF(idx{:}).freqsol             = freqresol;
                TF(idx{:}).timeresol           = timeresol;
                TF(idx{:}).wavelet             = wavelet;
                TF(idx{:}).old_srate           = EEG.srate;
                TF(idx{:}).new_srate           = 1/mean(diff(tftimes));
                TF(idx{:}).chanlocs            = EEG.chanlocs(CFG.tf_chans);
                TF(idx{:}).condition           = condition_names{icond};
                TF(idx{:}).DINFO               = DINFO;
                TF(idx{:}).trials              = condinfo(icond).trials;
                TF(idx{:}).factor_names        = DINFO.factor_names;
                TF(idx{:}).subject{isub}       = CFG.subject_name;
                % extract information on factor values so they are easily
                % accessible in later stages.
                for ifactor = 1:length(DINFO.factor_values)
                    if condinfo(icond).level{ifactor}==length(DINFO.factor_values{1,ifactor})+1
                        TF(idx{:}).factor_values{1,ifactor} = '*';
                    else
                        TF(idx{:}).factor_values{1,ifactor} = ...
                            DINFO.factor_values{1,ifactor}{condinfo(icond).level{ifactor}};
                    end
                end
                
%                 % you can manipulate the following lines of code to extract
%                 % Info about the trial circumstances. This might be useful
%                 % for analyzing behavior*eeg.
%                 k = 0;
%                 Info = struct;
%                 for i = trialidx
%                     k = k + 1;
%                     Info(k).validity = unique([EEG.epoch(i).eventvalidity{:}]);
%                     Info(k).BehavTrial = unique([EEG.epoch(i).eventtrialnumber{:}]);
%                     Info(k).RespDiff = unique([EEG.epoch(i).eventRespDiff{:}]);
%                     Info(k).Session = unique([EEG.epoch(i).eventSession{:}]);
%                 end
%                 TF(idx{:}).Info{isub} = Info;
            end
        end
        fprintf('\n')
        % in the single-trial case, we need to store temporary files to
        % avoid filled-up RAM
        if EP.singletrialTF
            tmpFol = [EP.dir_out, filesep, DINFO.design_name, filesep,...
                'singletrl_files'];
            [~,~] = mkdir(tmpFol);
            
            % don't save average data of all subjects in each file
            % Copying TF is quite stupid in terms of RAM management. Should
            % find a more elegant solution for that in the future.
            % It's really just a RAM concern, however, as it takes just
            % <1s per Subject. (WM)
            backTF = TF;
            cells = fullfact(size(TF));
            for icell = 1:length(cells)
                C = cells(icell,:);
                TF(C(1), C(2), C(3)).pow = squeeze(TF(C(1), C(2), C(3)).pow(:,:,:,isub));
                TF(C(1), C(2), C(3)).itc = squeeze(TF(C(1), C(2), C(3)).itc(:,:,:,isub));
            end
            save([tmpFol, filesep, 'Subj_', num2str(isub), '_singletrial.mat'], 'TF');
%             system(['echo "Elektro-Pipe: finished tf-decomposition of subject ',...
%                 num2str(isub), '/',num2str(length(subjects_idx)),...
%                 '" | mail -s "Elektropipe notification" moessing@wwu.de']);
            TF = backTF;
            clear Info tf thistf EEG backTF;
            %delete single trial data but keep average.
            TF = rmfield(TF, 'single');
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
    save(savefile, 'TF', '-v7.3');
    if idesign ~= length(EP.design_idx) %don't clear if it's the last one.
        clear TF C tmp;
    end
end

end
