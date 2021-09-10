function [subject_name, infile, outfile, outdir] = get_filesnfolders(thesubject, outstring)

% This function resolves the names of files and folders for loading and
% saving data.
% subjects: a struct resulting from a "dir" command, e.g.:
% subjects = dir([cfg.dir.eeg '**/', 'ROSA*prep1.set']);
% thesubject = subjects(1);
%
% outstr: suffix to be appended to subject name.

% Assume that the subject name is the first part of the file name,
% separated from the rest by underscored or dot. This would work for
% Participant01.bdf, or
% Participant01_import.set
subject_name = strtok(thesubject.name, {'_', '.'});

infile = thesubject.name;
outfile = [subject_name outstring];
outdir = thesubject.folder;