  
This is a patch for ROSA3: for some subjects, the time lag between
recording start and first trial onset is too short for the long
baseline we require for epoching, so the first trials is dropped.

This creates a huge headache because then the numbers of trials in
 EEG and logfile do not match. To fix this, I append a little bit of
 data at the beginning of each file.

    %     nsecs = 5;
    %     EEG = func_import_patchdata(EEG, nsecs);
    