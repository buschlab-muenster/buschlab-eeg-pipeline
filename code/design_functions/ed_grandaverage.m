function G = ed_grandaverage(subjects, D, data_type)

%%
G = struct();
G.data_type = data_type;
G.DINFO = get_design_matrix(D);
[G.data] = deal(cell(G.DINFO.nlevels+1)); % +1 because we add "all levels together" as another level.
G.ntrials = cell(G.DINFO.nlevels+1); % +1 because we add "all levels together" as another level.
cond_average = [];

for isub = 1:length(subjects)
    
    % --------------------------------------------------------
    % Load data and extract relevant meta-info, depending on data_type
    switch data_type
            
        case 'erp'
            EEG = pop_loadset('filename', subjects(isub).name, ...
                'filepath', subjects(isub).folder);
            subject_data = EEG.data;
            events = EEG.event; 
            G.times = EEG.times;
            G.chanlocs = EEG.chanlocs;
            
        case 'filtbert'
            EEG = pop_loadset('filename', subjects(isub).name, ...
                'filepath', subjects(isub).folder);
            subject_data = EEG.data;     
            events = EEG.event;        
            G.filtbert_fband = EEG.filtbert_fband;
            G.times = EEG.times;
            G.chanlocs = EEG.chanlocs;
            events = EEG.event;
            
        case 'fft'
            EEG = pop_loadset('filename', subjects(isub).name, ...
                'filepath', subjects(isub).folder);
            subject_data = EEG.fft_amps;
            events = EEG.event; 
            G.fft_twin = EEG.fft_twin;
            G.fft_freqs = EEG.fft_freqs;    
            G.chanlocs = EEG.chanlocs;  
            
    end
    
    G.subjects{isub} = subjects(isub).name;
    
    % Extract relevant trials for each condition.
    design_trials = get_design_trials(events, G.DINFO);
    
    for icond = 1:length(G.DINFO.design_matrix)    
        
        ntrials{icond, isub} = length(design_trials(icond).trials);  
        
        cond_data = subject_data(:,:,design_trials(icond).trials);
        cond_average{icond}{isub} = mean(cond_data, 3);              
    end
    
end

%%
for icond = 1:length(G.DINFO.design_matrix)    
    G.data{icond}       = cat(3,cond_average{icond}{:});
%     G.fft_amps{icond}  = cat(3,fft_amps{icond}{:});
%     G.fft_freqs{icond} = cat(3,fft_freqs{icond}{:});
    G.ntrials{icond}   = ntrials(icond,:);
end

