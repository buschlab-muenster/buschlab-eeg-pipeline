function out_subjects = get_list_of_subjects(dirs, do_overwrite, suffix_in, suffix_out)
% out_subjects = get_list_of_subjects(dirs, overwrite, suffix_in, suffix_out)
%
% Check the directory given in "dirs" for .set files including the string
% "suffix_in" in the filename. "dirs" refers to the field "cfg.dir.eeg".
% These files are candidates for processing. Then check the same directory
% if output files with the string "suffix_out" in the filename. If
% "overwrite" is set to false, these existing files are not processed,
% leaving only unprocessed datasets in the list of subjects.
%
% If "suffix_in" is an empty string, assume that input data are not eeglab
% set files, but Biosemi raw data in the cfg.dir.bdf directory with .bdf
% extension.
%

%%
skip_subjects = [];
out_subjects  = [];

if isempty(suffix_in)
    
    % If no suffix_in is defined, assume that we want to import EEG raw
    % data, so look for BIOSEMI files.
    in_subjects = dir([dirs.bdf '**' filesep '*' suffix_in  '.bdf']);
else
    in_subjects = dir([dirs.eeg '**' filesep '*' suffix_in  '.set']);
end

% In the preprocessing/artifact rejection script, we save bad trials in a
% data file whose file names starts with "bad". We do not want to process
% these files further.
in_subjects(startsWith({in_subjects.name}, 'bad')) = [];

for isub = 1:length(in_subjects)
    
    [filepath, filename, fileext] = fileparts(in_subjects(isub).name);
    
    name = strsplit(filename, {suffix_in, '_'});
    in_subjects(isub).namestr = name{1};
    in_subjects(isub).outdir  = fullfile(dirs.eeg, in_subjects(isub).namestr);
    in_subjects(isub).outfile = fullfile([in_subjects(isub).namestr '_' suffix_out '.set']);
    
    if exist(fullfile(in_subjects(isub).outdir, in_subjects(isub).outfile), 'file') ...
            && do_overwrite==false
        skip_subjects(isub) = 1;
    else
        skip_subjects(isub) = 0;
    end
end

out_subjects = in_subjects(~skip_subjects);

%%
fprintf('--------------------------------------------------------\n')
fprintf('Found %d datasets with input suffix "%s".\n', length(in_subjects), suffix_in)
fprintf('Overwrite is set to %s.\n', mat2str(do_overwrite))
fprintf('Number of datasets to process: %d.\n', length(out_subjects))
fprintf('- %s\n', out_subjects.name)
fprintf('--------------------------------------------------------\n')
