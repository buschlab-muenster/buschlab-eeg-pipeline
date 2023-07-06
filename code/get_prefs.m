function [prefs] = getprefs(eeglab_level, load_fieldtrip)
% This function adds machine-specific settings, i.e. paths to relevant
% folders and other settings such as maximum number of cores for
% parfor loops.
% eeglab_level: "eeglab_top" ==> addpath only the top-level folder
% eeglab_level: "eeglab_all" ==> addpath/genpath eeglab with all subfolders.
% load_fieldtrip: whether or not to load the fieldtrip-lite plugin. Usually
% not recommended due to large number of name conflicts, but necessary for
% BDF data import.



% Add path to subfolder with sub-functions.
addpath('./files/')
addpath('./functions/')

% ------------------------------------------------------------------------
% Which machine are we running on?
% ------------------------------------------------------------------------
[~, computername] = system('hostname');

% ------------------------------------------------------------------------
% Determine machine-specific foldres and settings.
% ------------------------------------------------------------------------
% Don't use all cores, so you/other people can run other stuff on
% this machine.
[~] = maxNumCompThreads('automatic'); % Reset max threads to true default.
maxThreads = maxNumCompThreads('automatic');

switch(strip(computername))
    
    case 'LABSERVER1'
        dir_toolboxes = '/data3/Niko/buschlab-pipeline-dev/tools/';
%         dir_myutils = '~/Code/Github/My-utilities/';
        prefs.max_threads = maxThreads - 1;
%         
%     case 'busch02'
%         dir_toolboxes = 'Y:\Niko\ROSA-project\tools\';
%         dir_myutils = 'C:\Users\nbusch\Documents\Github\My-utilities\';
%         prefs.max_threads = maxThreads - 1;
%         
%     case 'X1YOGA'
%         dir_toolboxes = 'Z:\Niko\ROSA-project\tools\';
%         dir_myutils = 'C:\Users\nbusch\Documents\GitHub Repos\Tools\My-utilities\';
%         prefs.max_threads = maxThreads - 1;
%         
%     case 'busch-x1-2021'
%         dir_toolboxes = 'Z:\Niko\ROSA-project\tools\';
%         dir_myutils = 'C:\Users\nbusch\Documents\GitHub Repos\Tools\My-utilities\';
%         prefs.max_threads = maxThreads - 1;
        
end

addpath([dir_toolboxes, 'eeglab2023.0']);

% ------------------------------------------------------------------------
% Now set the number of threads for this machine.
% ------------------------------------------------------------------------
[~] = maxNumCompThreads(prefs.max_threads);

% ------------------------------------------------------------------------
% Set paths to relelvant folders.
% ------------------------------------------------------------------------


% eeglab_path = [dir_toolboxes, 'eeglab2019_1' filesep];
% 
% % The fieldtrip-lite plugin has a large number of name conflicts, so I am
% % not loading this folder by default.
% fieldtriplite_path = dir([eeglab_path '**' filesep 'Fieldtrip-lite*']);
% 
% switch eeglab_level
%     case 'eeglab_top'
%         addpath([dir_toolboxes, 'eeglab2019_1']);
%     case 'eeglab_all'
%         switch load_fieldtrip
%             case 0
%                 addpath(genpath_exclude(eeglab_path, fieldtriplite_path.name));
%             case 1
%                 addpath(genpath(eeglab_path));
%         end
%         
% end
% 
% addpath([dir_toolboxes, 'unfold']);
% addpath(genpath([dir_toolboxes, 'rosa-elektro-pipe']));
% 
% % We need this specific function for BDF import.
% addpath([dir_toolboxes, 'eeglab2019_1', '/plugins/fileio'])
% 
% % Folder with Niko's utility functions.
% addpath(genpath(dir_myutils))

