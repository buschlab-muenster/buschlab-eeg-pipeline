if isunix
    rosa_tboxes_path = '/data3/Niko/ROSA3/tools/tools/';
else
    rosa_tboxes_path = 'Z:/Wanja/Sciebo2/ROSA/tools/';
end

% don't use all cores, so other people can run other stuff on the server
[~] = maxNumCompThreads('automatic');
maxThreads = maxNumCompThreads('automatic');
[~] = maxNumCompThreads(maxThreads - 1);
addpath([rosa_tboxes_path, 'eeglab2019_1']);
addpath([rosa_tboxes_path, 'unfold']);
addpath(genpath([rosa_tboxes_path, 'rosa-elektro-pipe']));
addpath('/data3/Niko/ROSA3/Analysis/helper-funs/');

clear('rosa_tboxes_path', 'maxThreads');
