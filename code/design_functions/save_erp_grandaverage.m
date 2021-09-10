function ALLEEG = save_erp_grandaverage(DINFO, EP, EEG, subject_names, erp, ntrials, savepath)
%%
ALLEEG = struct([]);

for icondition = 1:DINFO.n_conditions
    alleeg = eeg_emptyset;
    
    alleeg.setname      = DINFO.condition_names{icondition};
    alleeg.filename     = [DINFO.condition_names{icondition} '.set'];
    alleeg.filepath     = savepath;
    alleeg.subject      = 'Grand average';
    alleeg.nbchan       = size(erp, 1);
    alleeg.trials       = size(erp, 4);
    alleeg.pnts         = size(erp, 2);
    alleeg.srate        = EEG.srate;
    alleeg.xmin         = EEG.xmin;
    alleeg.xmax         = EEG.xmax;
    alleeg.times        = EEG.times;
    alleeg.data         = squeeze(erp(:,:,icondition,:));
    alleeg.chanlocs     = EEG.chanlocs;
    alleeg.chaninfo     = EEG.chaninfo;
    alleeg.ref          = EEG.ref;
    alleeg.ntrials      = ntrials(icondition, :);
    alleeg.subjectnames = subject_names;
        
    alleeg = eeg_checkset(alleeg);
    alleeg.DINFO = DINFO;
    alleeg.EP = EP;

    ALLEEG = [ALLEEG alleeg];
end


ALLEEG = reshape(ALLEEG, DINFO.nlevels+1);

% We cannot use pop_saveset, because ALLEEG is multidimensional,
% pop_saveset does not accept this.
%ALLEEG = pop_saveset(ALLEEG, 'filename', ALLEEG.setname, 'filepath', ['./']);

savefile = fullfile(savepath, [EP.project_name, '_D', num2str(DINFO.design_idx), '.mat']);

save(savefile, 'ALLEEG', '-v7.3');
