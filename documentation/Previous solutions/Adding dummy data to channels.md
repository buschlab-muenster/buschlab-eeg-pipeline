Addin
Hack for AlphaICon: the first subjects were recorded with incomplete triggers in the eyetracking files. As a result, the import_eyelink function is not able to sync EEG and eyetracking data. To make the data structure compatible with complete data in the future, I am inserting 3 empty channels with the appropriate channel labels.
   
	 lastchan = EEG.nbchan;
    dummydat = zeros(size(EEG.data(lastchan,:)));
    EEG.data(lastchan+1,:) = dummydat;
    EEG.data(lastchan+2,:) = dummydat;
    EEG.data(lastchan+3,:) = dummydat;
    EEG.nbchan = size(EEG.data,1);

    EEG.chanlocs(lastchan+1).labels = 'Eyegaze-X';
    EEG.chanlocs(lastchan+2).labels = 'Eyegaze-Y';
    EEG.chanlocs(lastchan+3).labels = 'Pupil-Dilation';

    EEG = eeg_checkset(EEG, 'chanlocsize', 'chanlocs_homogeneous');