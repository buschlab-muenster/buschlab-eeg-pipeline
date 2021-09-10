%% "Master file" that runs the grand average for all ERPs from all subjects.

% Load the configuration file. The cfg structure contains information on
% subject names, directories, etc.
cfg = getcfg;

% Load th edesign file. The "d" structure contains information on the
% factors and factor levels of the design.
d = getdesign;

%% Run grandaverage for all designs and subejcts.
eeg_grandaverage(cfg, 1:9, '_united_icaclean', d, 2)
TF = eeg_runtf(cfg, 1:9, '_united_icaclean', d, 1);
TF = eeg_runtf(cfg, 1:9, '_united_icaclean');

%% Load and display the grand averaged ERPs.
% [ALLEEG, condition_names] = load_design(cfg, d, 1);
% pop_comperp( ALLEEG, 1, [1 2], [4 5],'addavg','off','addstd','off','addall','on','suball','on','diffavg','off','diffstd','off','tplotopt',{'ydir' -1});
