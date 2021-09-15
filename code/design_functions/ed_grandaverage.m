function G = ed_grandaverage(subjects, D, data_type)

%%
G = struct();
G.data_type = data_type;
G.DINFO = get_design_matrix(D);
[G.data] = deal(cell(G.DINFO.nlevels+1)); % +1 because we add "all levels together" as another level.
G.ntrials = cell(G.DINFO.nlevels+1); % +1 because we add "all levels together" as another level.

n_conditions = length(G.DINFO.design_matrix);
n_subjects = length(subjects);
n_trials = cell(n_conditions, n_subjects);
subject_names = cell(1, n_subjects);

% Load one EEG set just for the meta data and for initializing the data
% matrix.
eeg_meta_data = pop_loadset('filename', subjects(1).name, ...
    'filepath', subjects(1).folder, 'loadmode', 'info');

cond_average = cell(n_conditions, n_subjects);
[cond_average{:,:}] = deal(nan(eeg_meta_data.nbchan, eeg_meta_data.pnts));

% Store meta data because we cannot do that within a parfor loop
switch data_type    
    case 'erp'
        G.times = eeg_meta_data.times;
        G.chanlocs = eeg_meta_data.chanlocs;    
    case 'filtbert'
        G.filtbert_fband = eeg_meta_data.filtbert_fband;
        G.times = eeg_meta_data.times;
        G.chanlocs = eeg_meta_data.chanlocs;        
    case 'fft'
        G.fft_twin = eeg_meta_data.fft_twin;
        G.fft_freqs = eeg_meta_data.fft_freqs;
        G.chanlocs = eeg_meta_data.chanlocs;
end

%%
parfor isub = 1:length(subjects)
    
    % --------------------------------------------------------
    % Load data and extract relevant meta-info, depending on data_type
    switch data_type        
        case 'erp'
            EEG = pop_loadset('filename', subjects(isub).name, ...
                'filepath', subjects(isub).folder);
            subject_data = EEG.data;
            events = EEG.event;
            
        case 'filtbert'
            EEG = pop_loadset('filename', subjects(isub).name, ...
                'filepath', subjects(isub).folder);
            subject_data = EEG.data;
            events = EEG.event;
            
        case 'fft'
            EEG = pop_loadset('filename', subjects(isub).name, ...
                'filepath', subjects(isub).folder);
            subject_data = EEG.fft_amps;
            events = EEG.event;            
    end
    
    subject_names{isub} = subjects(isub).name;
    
    % Extract relevant trials for each condition.
    fprintf('Extracting relevant trials.\n')

    design_trials = get_design_trials(events, G.DINFO);
    
    for icond = 1:n_conditions        
        n_trials{icond, isub} = length(design_trials(icond).trials);
        
        cond_data = subject_data(:,:,design_trials(icond).trials);
        cond_average{icond, isub} = mean(cond_data, 3);
    end
    
end

%% 
fprintf('Accumulating subject data.\n')
% Now that the parfor loop is finished, we can process a few more things
% that cannot be resolved in parfor.
G.subjects = subject_names;

for icond = 1:length(G.DINFO.design_matrix)
    G.data{icond}       = cat(3,cond_average{icond,:});
    G.ntrials{icond}   = n_trials(icond,:);
end

