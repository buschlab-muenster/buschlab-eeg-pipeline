function LOG = func_recode_makelogtable(T, cfg, isub)
% Interpret the behavioral logfile and store relevant information in a
% table. Then export that table to CSV format.



% Make a new empty table.
ntrials_log = length(T);
LOG = table();
LOG.trial       = [1:ntrials_log]';

% Extract relevant data from behavioral logfile.
LOG.scene_name  = {T.category_name}';
LOG.scene_cat(strcmp(LOG.scene_name, 'beaches'))   = 1;
LOG.scene_cat(strcmp(LOG.scene_name, 'buildings')) = 2;
LOG.scene_cat(strcmp(LOG.scene_name, 'highways'))  = 3;
LOG.scene_cat(strcmp(LOG.scene_name, 'forests'))   = 4;

LOG.scene_man(strcmp(LOG.scene_name, 'beaches')   | strcmp(LOG.scene_name, 'forests'))  = 1;
LOG.scene_man(strcmp(LOG.scene_name, 'buildings') | strcmp(LOG.scene_name, 'highways')) = 2;

LOG.is_old      = ([T.presentation_no]'-1) > 0;

report_old  = [T.ReportOld]';
report_old(isnan(report_old)) = 9;

LOG.recog_cat(LOG.is_old &  report_old == 1) = 1;
LOG.recog_cat(LOG.is_old &  report_old == 0) = 2;
LOG.recog_cat(~LOG.is_old & report_old == 1) = 3;
LOG.recog_cat(~LOG.is_old & report_old == 0) = 4;
LOG.recog_cat(report_old == 9) = 9;

LOG.recognition(LOG.recog_cat == 1) = {'hit'};
LOG.recognition(LOG.recog_cat == 2) = {'miss'};
LOG.recognition(LOG.recog_cat == 3) = {'falsealarm'};
LOG.recognition(LOG.recog_cat == 4) = {'correctreject'};

subs_correct = [T.subsequent_correct]';
subs_correct(isnan(subs_correct)) = 9;
LOG.subscorrect = subs_correct;

% Write relevant data to CSV file.
logname  = ['EMP', sprintf('%02d', isub), '_events-table.csv'];
fullname = fullfile(cfg.dir_export, logname);
fprintf('Writing events to file: %s.\n', fullname)
writetable(LOG, fullname, 'Delimiter', ';', 'writemode', 'overwrite') 
disp('Done.')
