%% Set preferences, configuration and load list of subjects.
clear; clc; close all

restoredefaultpath
prefs = get_prefs('eeglab_all', 0);
cfg = get_cfg;

%%
design_idx = 1;

% load(fullfile(cfg.dir.grand, ['grand_d' num2str(design_idx) '_' 'erp']))
% load(fullfile(cfg.dir.grand, ['grand_d' num2str(design_idx) '_' 'fft_1000_1998']))
load(fullfile(cfg.dir.grand, ['grand_d' num2str(design_idx) '_' 'fft_3000_3998']))
load(fullfile(cfg.dir.grand, ['grand_d' num2str(design_idx) '_' 'fft_-1000_-2']))
% load(fullfile(cfg.dir.grand, ['grand_d' num2str(design_idx) '_' 'filtbert_8_12']))

%%
% figure; topoplot([],G.chanlocs,'style','blank','electrodes','numbers');
% addpath('C:\Users\nbusch\OneDrive\Dokumente\Github\My-utilities\EEG_functions\')
% cond = [3,2,3];

conditions = {};

correctness = 1;

conditions{1} = {
    'target_cue_w', 'MemL';
    'saccade_cue_w', 'SaccL';
    'response_correct', correctness};

conditions{2} = {
    'target_cue_w', 'MemL';
    'saccade_cue_w', 'SaccR';
    'response_correct', correctness};

conditions{3} = {
    'target_cue_w', 'MemR';
    'saccade_cue_w', 'SaccL';
    'response_correct', correctness};

conditions{4} = {
    'target_cue_w', 'MemR';
    'saccade_cue_w', 'SaccR';
    'response_correct', correctness};

conditions{5} = {
    'target_cue_w', 'MemX';
    'saccade_cue_w', 'SaccL';
    'response_correct', correctness};

conditions{6} = {
    'target_cue_w', 'MemX';
    'saccade_cue_w', 'SaccR';
    'response_correct', correctness};


chans_l = [57 26 61 60 58 59];
chans_r = [19 21 17 18 22 23];

[erpall, erproi, topo, statdat] = ed_select_results(...
    G, conditions, 'channels', [chans_r], 'times', [3000 4000]);

%%
conditions = {};

correctness = 1;

conditions{1} = {
    'target_cue_w', 'MemL';
    'saccade_cue_w', '*';
    'response_correct', correctness};

conditions{2} = {
    'target_cue_w', 'MemR';
    'saccade_cue_w', '*';
    'response_correct', correctness};

[erpall, erproi, topo, statdat] = ed_select_results(...
    G, conditions, 'channels', [chans_r], 'times', [1000 2000]);


topo_opts= {'conv', 'off', 'electrodes', 'on', ...
    'numcontour', 3, ...
    'maplimits', 'absmax', 'whitebk', 'on', ...
    'emarker2', {[chans_l chans_r],'.','w',18,1}};

topo1 = topo{2} - topo{1};

figure;
% subplot(2,2,1)
topoplot(topo1, G.chanlocs, topo_opts{:}); colorbar('location', 'southoutside')

%%

clrs = {'b', 'b', 'r', 'r', 'k', 'k'};
lsty = {'-', ':', '-', ':', '-', ':'};

figure; hold all;
lat_lr = []; mean_lat_lr = []; ph = []; legstr = [];
for icond = 1:length(conditions)
    
    roi_l = mmean(erpall{icond}(chans_l,:,:), [1, 3]);
    roi_r = mmean(erpall{icond}(chans_r,:,:), [1, 3]);
    lat_lr(:, icond) = (roi_r - roi_l) ./ (roi_r + roi_l);    
    
%     [lat_lr(:, icond), ~, basemin, basemax] = my_bslcorrect(lat_lr(:, icond), 1, G.times./1000, [-0.200 0], 'sub');       
    
    legstr{icond} = sprintf('%s', [conditions{icond}{:,2}]);
% ph(icond) = plot(G.times, erproi{icond});
ph(icond) = plot(G.fft_freqs, lat_lr(:,icond), 'color', clrs{icond}, 'linestyle', lsty{icond});
end
    
legend(ph, legstr)

% xlim([-200 4000])
xlim([1 20])

%%


chans = 17;
timewin = [500 2000];
subjects = [];


chans_l = [57 26 61 60 58 59];
chans_r = [19 21 17 18 22 23];
topo_opts= {'conv', 'off', 'electrodes', 'on', ...
    'numcontour', 3, ...
    'maplimits', 'absmax', 'whitebk', 'on', ...
    'emarker2', {[chans_l chans_r],'.','w',18,1}};

lat_lr = (mmean(erpall(chans_r,:,:) - erpall(chans_l,:,:), [1])) ./ ...
    (mmean(erpall(chans_r,:,:) + erpall(chans_l,:,:), [1]));

[lat_lr, ~, basemin, basemax] = my_bslcorrect(lat_lr, 1, G.times, [-0.200 0], 'sub');

figure; hold all;
for i = 1:length(conditions)
    ph(i) = plot(G.times, lat_lr(:,i));
    legstr{i} = sprintf('%s', [conditions{i}{:,2}]);
end

legend(ph, legstr)
% figure
% topoplot(diff(topo), G.chanlocs, topo_opts{:});

xlim([-200 4000])
yline(0)
%%
[lateralization, ipsi, contra, ll, rl, lr, rr] = eeg_lateralization(chans_l, chans_r, ...
    erpall(:,:,1), erpall(:,:,2), 1);

figure; hold all
plot(G.times, ipsi)
plot(G.times, contra)
legend('ipsi', 'contra')

