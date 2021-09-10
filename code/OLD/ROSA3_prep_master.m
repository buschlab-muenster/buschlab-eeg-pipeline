%-----------------------------------
% Make sure dependencies are available
%-----------------------------------
% you should have recent eeglab and Elektro-Pipe in your matlab-path
% we launch eeglab once, to make sure it loads all the plugins
addpath('../../../');
ROSA_startup;
eeglab;
close(findobj('tag', 'EEGLAB')); % 'nogui' doesn't load fieldtrip...
addpath('../../../helper-funs/');

% make sure we're in the proper directory, so all paths are relative to the
% location of this file (and hence system-independent)
% fname    = which('ROSA3_prep_master.m');
% rootpath = fname(1:regexp(fname,'[\\|/]Analysis[\\|/]'));
% cd(rootpath);
% addpath(genpath(rootpath));

%-----------------------------------
% specify location of getcfg.m & SubjectsTable.xlsx
%-----------------------------------
EP.cfg_file = fullfile('./ROSA3_get_cfg.m');
EP.st_file  = fullfile('./ROSA3_SubjectsTable.xlsx');

%-----------------------------------
% which subjects should be preprocessed?
%-----------------------------------
EP.who = {'Index', [10:16]}; % Single numerical index.

%-----------------------------------
% Should subjects be processed in parallel (faster, but hard to debug)?
%-----------------------------------
EP.prep_parallel = Inf; % 0 = serial, N = use N cores, Inf = use max cores
    
%% PREP-1: Import and automatic preprocessing.
% addpath('/data3/Niko/ROSA3/tools/tools/eeglab2019_1/plugins/fileio')
% try
% prep01_preproc_test_HEOG(EP);
%     elektro_notify('nbusch@wwu.de', 'Import and preprocessing done!')
% catch ME
%     elektro_notify('nbusch@wwu.de', ME);
% end

%%
% PREP-2: Semi-automatic preparation for ICA.
% prep02_cleanbeforeICA;
% elektro_notify('moessing@wwu.de', 'Done with artifact rejection!')


%% PREP-3: Run ICA.
% try
% prep03_runICA(EP);
    %Send a notification via email when done or throwing error
%     elektro_notify('moessing@wwu.de', 'All ICA computations done!')
% catch ME
%     elektro_notify('moessing@wwu.de', ME);
% end

%% PREP-4: Reject ICA components.
% try
prep04_rejectICs(EP);
    %Send a notification via email when done or throwing error
%     elektro_notify('moessing@wwu.de', 'All IC rejections done!')
% catch ME
%     elektro_notify('moessing@wwu.de', ME);
% end
%% run tf
% ROSA3_design_master

