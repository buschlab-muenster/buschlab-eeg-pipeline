function EEG = func_saveset(EEG, subjects)

EEG = pop_editset(EEG, 'setname', subjects.outfile);
pop_saveset(EEG, 'filename', subjects.outfile, 'filepath', subjects.outdir);
