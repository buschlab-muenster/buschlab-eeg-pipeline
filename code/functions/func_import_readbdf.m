function EEG = func_import_readbdf(dirs, bdf_name)

% --------------------------------------------------------------
% Import Biosemi raw data.
% --------------------------------------------------------------

% We have an unusual setup in the lab because our trigger device is sending
% 16bit triggers, while virtually any other trigger hardware is working
% with 8bit triggers. Wanja Moessing hacked the functions in the fileio
% toolbox so that they import the correct triggers. The lines below find
% the folder of the fileio plugin and copies our modified versions to that
% folder.
d = dir('../../tools/eeglab*/plugins/fileio*/');
copyfile('./functions/ft_read_event.m', d(1).folder, 'f')
copyfile('./functions/pop_fileio.m',    d(1).folder, 'f')


% Which EEG file are we working with?
fullfilename = fullfile(dirs.bdf, bdf_name);
fprintf('Loading %s\n', fullfilename);


% Import the data.
EEG = pop_fileio(fullfilename);
EEG.urname = bdf_name;
