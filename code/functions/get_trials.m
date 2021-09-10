function cond_trials = get_trials(cfg, logfile)

for icond = 1:size(cfg.conditions,1)
    for ilevel = 1:length(cfg.conditions(icond,:))
        
        cond_str   = cfg.conditions{icond,ilevel}{1};
        cond_value = cfg.conditions{icond,ilevel}{2};
        
        if isnumeric(cond_value)
            trials = [logfile.(cond_str)] == cond_value;
        elseif ischar(cond_value)
            trials = strcmp([logfile.(cond_str)], cond_value);
        end
        
        cond_trials{icond, ilevel} = find(trials);
    end
end