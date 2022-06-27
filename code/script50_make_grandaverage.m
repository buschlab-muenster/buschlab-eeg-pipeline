%% Set preferences, configuration and load list of subjects.
clear; clc; close all

restoredefaultpath
addpath('./design_functions')
prefs = get_prefs('eeglab_all', 0);
cfg = get_cfg;

if ~exist(cfg.dir.grand, 'dir'); mkdir(cfg.dir.grand); end

%% ------------------------------------------------------------------------
% Set these variables to define what you want to do. The rest below runs
% automatically.
%  ------------------------------------------------------------------------
design_idx = 1;

% data_type = 'erp';
data_type = 'fft';
% data_type = 'filtbert';

%% Load all single subjects and compute grand average for selected design.
subjects = [];
design = get_design(design_idx);

switch data_type
    case 'erp'
        
        suffix_in  = 'final';
        subjects = get_list_of_subjects(cfg.dir, true, suffix_in, '');
        
        G = ed_grandaverage(subjects, design, data_type);
        
        grand_name = ['grand' '_d' num2str(design_idx) '_' data_type];
        save(fullfile(cfg.dir.grand, grand_name), 'G')
        
    case 'filtbert'
        
        for iband = 1:length(cfg.filtbert.fbands) 
            suffix_in = ['filtbert_' ...
                num2str(cfg.filtbert.fbands{iband}(1)) '_' ...
                num2str(cfg.filtbert.fbands{iband}(2))];

            subjects{iband} = get_list_of_subjects(cfg.dir, true, suffix_in, '');

            G = ed_grandaverage(subjects{iband}, design, data_type);

            grand_name = ['grand' '_d' num2str(design_idx) '_' data_type '_' ...
                num2str(cfg.filtbert.fbands{iband}(1)) '_' ...
                num2str(cfg.filtbert.fbands{iband}(2))];
            save(fullfile(cfg.dir.grand, grand_name), 'G')
        end
        
    case 'fft'
        
        for iwin = 1:length(cfg.fft)
            suffix_in = ['fft_' ...
                num2str(cfg.fft(iwin).twin(1)) '_' ...
                num2str(cfg.fft(iwin).twin(2))];
            
            subjects{iwin} = get_list_of_subjects(cfg.dir, true, suffix_in, '');
            
            G = ed_grandaverage(subjects{iwin}, design, data_type);
            
            grand_name = ['grand' '_d' num2str(design_idx) '_' data_type '_' ...
                num2str(cfg.fft(iwin).twin(1)) '_' ...
                num2str(cfg.fft(iwin).twin(2))];
            save(fullfile(cfg.dir.grand, grand_name), 'G')
        end
end

disp('Done.')
