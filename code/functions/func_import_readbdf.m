function EEG = func_import_readbdf(dirs, bdf_name)

% --------------------------------------------------------------
% Import Biosemi raw data.
% --------------------------------------------------------------
fullfilename = fullfile(dirs.bdf, bdf_name);

fprintf('Loading %s\n', fullfilename);
EEG = pop_fileio(fullfilename);
EEG.urname = bdf_name;
