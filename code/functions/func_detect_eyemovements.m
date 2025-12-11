function EEG = func_detect_eyemovements(EEG, cfg)


    % --------------------------------------------------------------
    % EYE-EEG expects ET data relative to top-left pixel, not screen center.
    % --------------------------------------------------------------
%     EEG.data(cfg.eye.ETx,:,:) = EEG.data(cfg.eye.ETx,:,:) + 0.5*cfg.eye.screen_width;
%     EEG.data(cfg.eye.ETy,:,:) = EEG.data(cfg.eye.ETy,:,:) + 0.5*cfg.eye.screen_height;
    
    % --------------------------------------------------------------
    % Removing old ET events.
    % --------------------------------------------------------------
    removetypes = {'L_blink', 'L_saccade', 'L_fixation', ...
        'R_blink', 'R_saccade', 'R_fixation', 'saccade', 'fixation'};
    EEG = pop_selectevent( EEG, 'type',removetypes, ...
        'select','inverse','deleteevents','on','deleteepochs','on','invertepochs','off');
    
    % --------------------------------------------------------------
    % Saccade cue and memory cue are coded as cells, which throws an error when
    % EYE-EEG tries to update the event structure. Converting the cells to
    % simple strings.
    % --------------------------------------------------------------
    for i = 1:length(EEG.event)
        if iscell(EEG.event(i).target_cue_w)
            EEG.event(i).target_cue_w = string(EEG.event(i).target_cue_w);
        end
        
        if iscell(EEG.event(i).saccade_cue_w)
            EEG.event(i).saccade_cue_w = string(EEG.event(i).saccade_cue_w);
        end
    end
    
    % --------------------------------------------------------------
    % Detect eye movements.
    % --------------------------------------------------------------
    EEG = pop_detecteyemovements(EEG, [cfg.eye.ETx cfg.eye.ETy] ,[], ...
        cfg.eye.velo_thresh, cfg.eye.mindur, cfg.eye.screen_degperpixel, ...
        cfg.eye.do_smooth, cfg.eye.globalthresh, ...
        round(cfg.eye.clusterdist_sec * EEG.srate), cfg.eye.clustermode, 0, 1, 1);
    
    % --------------------------------------------------------------
    % Write all saccades and fixations into a struct for plotting.
    % --------------------------------------------------------------
    EEG.saccs = struct([]);
    sacc_events = find(strcmp({EEG.event.type}, 'saccade'));
    
    EEG.fix = struct([]);
    fix_events = find(strcmp({EEG.event.type}, 'fixation'));
    
    for ifix = 1:length(fix_events)
        evnt = fix_events(ifix); % index of this saccade in event structure.
        epch = EEG.event(evnt).epoch; % corresponding epoch.
        fxix = find(EEG.epoch(epch).event==evnt); % index of saccade within the epoch structure.
        
        EEG.fix(ifix).fix_avgpos_x = EEG.event(evnt).fix_avgpos_x;
        EEG.fix(ifix).fix_avgpos_y = EEG.event(evnt).fix_avgpos_y;
        EEG.fix(ifix).duration = EEG.event(evnt).duration;
        EEG.fix(ifix).latency      = EEG.epoch(epch).eventlatency{fxix};
        
    end
    
    for isac = 1:length(sacc_events)
        
        evnt = sacc_events(isac); % index of this saccade in event structure.
        epch = EEG.event(evnt).epoch; % corresponding epoch.
        scix = find(EEG.epoch(epch).event==evnt); % index of saccade within the epoch structure.
              
        EEG.saccs(isac).epoch       = EEG.event(evnt).epoch;
        EEG.saccs(isac).ur_latency  = EEG.event(evnt).latency;
        EEG.saccs(isac).ur_duration = EEG.event(evnt).duration;
        EEG.saccs(isac).latency     = EEG.epoch(epch).eventlatency{scix};
        EEG.saccs(isac).duration    = EEG.epoch(epch).eventduration{scix};
        EEG.saccs(isac).start_x     = EEG.event(evnt).sac_startpos_x;
        EEG.saccs(isac).end_x       = EEG.event(evnt).sac_endpos_x;
        EEG.saccs(isac).start_y     = EEG.event(evnt).sac_startpos_y;
        EEG.saccs(isac).end_y       = EEG.event(evnt).sac_endpos_y;
        EEG.saccs(isac).sac_amp     = EEG.event(evnt).sac_amplitude;
        EEG.saccs(isac).sac_angle   = EEG.event(evnt).sac_angle;
        
        hor_amp = (EEG.saccs(isac).end_x - EEG.saccs(isac).start_x) * cfg.eye.screen_degperpixel;
        EEG.saccs(isac).hor_amp     = hor_amp;
        EEG.saccs(isac).hor_dir     = sign(hor_amp); 
              
        t0 = find(cell2mat(EEG.epoch(epch).eventlatency)==0); % time-locking event in this epoch.
        EEG.saccs(isac).mem         = EEG.epoch(epch).eventtarget_cue_w{t0};
        EEG.saccs(isac).sac         = EEG.epoch(epch).eventsaccade_cue_w{t0};
 
    end
    