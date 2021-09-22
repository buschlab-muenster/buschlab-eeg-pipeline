%% Set preferences, configuration and load list of subjects.
clear; clc; %close all

restoredefaultpath
prefs = get_prefs('eeglab_all', 0);
cfg = get_cfg;
addpath('./design_functions/')

%%
design_idx = 1;
tic
load(fullfile(cfg.dir.grand, ['grand_d' num2str(design_idx) '_' 'erp']))
toc

% for icond = 1:numel(G.data)
% 
%     ref = mean(G.data{icond}, 1);
%     G.data{icond}(1:65,:,:) = bsxfun(@minus, G.data{icond}(1:65,:,:), ref);
%     
% end

%%
% figure; topoplot([],G.chanlocs,'style','blank','electrodes','numbers');
% addpath('C:\Users\nbusch\OneDrive\Dokumente\Github\My-utilities\EEG_functions\')


conditions = {};
% correctness = 1;
correctness = '*';
goodsubs = [1:18 20:27];
goodsubs = [2 7 9 10 11 13 14 16 17 20 22 23 25 26]; % Simply the best.

ntrials_total = cell2mat(G.ntrials{4,3,3});
goodsubs = find(ntrials_total > 100);

conditions{1} = {
    'target_cue_w', 'MemL'; 'saccade_cue_w', 'SaccL'; 'response_correct', correctness};

conditions{2} = {
    'target_cue_w', 'MemL'; 'saccade_cue_w', 'SaccR'; 'response_correct', correctness};

conditions{3} = {
    'target_cue_w', 'MemR'; 'saccade_cue_w', 'SaccL'; 'response_correct', correctness};

conditions{4} = {
    'target_cue_w', 'MemR'; 'saccade_cue_w', 'SaccR'; 'response_correct', correctness};

conditions{5} = {
    'target_cue_w', 'MemX'; 'saccade_cue_w', 'SaccL'; 'response_correct', correctness};

conditions{6} = {
    'target_cue_w', 'MemX'; 'saccade_cue_w', 'SaccR'; 'response_correct', correctness};

conditions{7} = {
    'target_cue_w', 'MemL'; 'saccade_cue_w', '*'; 'response_correct', correctness};

conditions{8} = {
    'target_cue_w', 'MemR'; 'saccade_cue_w', '*'; 'response_correct', correctness};

conditions{9} = {
    'target_cue_w', 'MemX'; 'saccade_cue_w', '*'; 'response_correct', correctness};

conditions{10} = {
    'target_cue_w', '*'; 'saccade_cue_w', 'SaccL'; 'response_correct', correctness};

conditions{11} = {
    'target_cue_w', '*'; 'saccade_cue_w', 'SaccR'; 'response_correct', correctness};


chans_l = [57 61 58 ];
chans_r = [19 18 22 ];
% chans_r = [14:19];
% chans_l = [57 60];
% chans_r = [19 17];

timewin = [1000 2000];
timewin = [3000 4000];
bsl_win = [-500 0];
% bsl_win = [2800 3000];


% Data for left CHANNELS.
[erpall_l, erproi_l, topo_l, statdat_l] = ed_select_results(...
    G, conditions, 'subjects', goodsubs, 'channels', [chans_l], 'times', timewin, 'bsl_win', bsl_win, 'bsl_method', 'sub');

% Data for right CHANNELS.
[erpall_r, erproi_r, topo_r, statdat_r] = ed_select_results(...
    G, conditions, 'subjects', goodsubs, 'channels', [chans_r], 'times', timewin, 'bsl_win', bsl_win, 'bsl_method', 'sub');

for icond = 1:length(conditions)
    erproi_lat{icond} = erproi_r{icond} - erproi_l{icond};
    erproi_lat{icond} = eegfilt(erproi_lat{icond}, 256, 0, 8, 0, [], [], 'firls');
    
    statdat_lat{icond} = statdat_r{icond} - statdat_l{icond};
end

%

xvals = G.times;
xl = [-0500 4000];
yl = [-4 4];
xlbl = 'Time';

fh = figure;
movegui(fh, 'center')

subplot(1,4,1); hold all

ph(1) = plot(xvals, erproi_lat{1}, 'color', 'b');
ph(2) = plot(xvals, erproi_lat{3}, 'color', 'r');
ph(3) = plot(xvals, erproi_lat{5}, 'color', 'k');
title('Saccade left')
legend('Left mem', 'Right mem', 'No mem')
xlim(xl); ylim(yl); xlabel(xlbl)
xlines = xline([0 1000 2000 3000 4000], ':', {'Encoding', 'Pre-saccade', 'Saccade', 'Post-saccade', ' '});
legend(ph, 'Left mem', 'Right mem', 'No mem')

subplot(1,4,2); hold all

ph(1) = plot(xvals, erproi_lat{2}, 'color', 'b');
ph(2) = plot(xvals, erproi_lat{4}, 'color', 'r');
ph(3) = plot(xvals, erproi_lat{6}, 'color', 'k', 'DisplayName', 'This is the legend for this line');
title('Saccade right')
xlim(xl); ylim(yl); xlabel(xlbl)
xlines = xline([0 1000 2000 3000 4000], ':', {'Encoding', 'Pre-saccade', 'Saccade', 'Post-saccade', ' '});
legend(ph, 'Left mem', 'Right mem', 'No mem', 'location', 'southeast')
set(fh, 'color', 'w')

subplot(1,4,3); hold all

ph(1) = plot(xvals, erproi_lat{7}, 'color', 'b');
ph(2) = plot(xvals, erproi_lat{8}, 'color', 'r');
ph(3) = plot(xvals, erproi_lat{9}, 'color', 'k', 'DisplayName', 'This is the legend for this line');
title('All saccades')
xlim(xl); ylim(yl); xlabel(xlbl)
xlines = xline([0 1000 2000 3000 4000], ':', {'Encoding', 'Pre-saccade', 'Saccade', 'Post-saccade', ' '});
legend(ph, 'Left mem', 'Right mem', 'No mem', 'location', 'southeast')
set(fh, 'color', 'w')

subplot(1,4,4); hold all

ph(1) = plot(xvals, erproi_lat{10}, 'color', 'b');
ph(2) = plot(xvals, erproi_lat{11}, 'color', 'r');
title('All Memory conditions')
xlim(xl); ylim(yl); xlabel(xlbl)
xlines = xline([0 1000 2000 3000 4000], ':', {'Encoding', 'Pre-saccade', 'Saccade', 'Post-saccade', ' '});
legend(ph, 'Left saccade', 'Right saccade', 'location', 'southeast')
set(fh, 'color', 'w')


% -------------------
% Plot topo
% -------------------
topo_opts= {'conv', 'off', 'electrodes', 'on', ...
    'numcontour', 3, ...
    'maplimits', 'absmax', 'whitebk', 'on', ...
    'emarker2', {[chans_l chans_r],'.','w',18,1}};

topo_all_lat = topo_l{7} - topo_l{8};

fh2 = figure;
topoplot(topo_all_lat, G.chanlocs, topo_opts{:}); colorbar('location', 'southoutside')

movegui(fh2, 'center')
%%
% bxh = figure; hold all
% boxplot([statdat_lat{1} statdat_lat{2} statdat_lat{3} statdat_lat{4} statdat_lat{5} statdat_lat{6}])
% % boxplot([statdat_lat{3} statdat_lat{4}])
% % boxplot([statdat_lat{5} statdat_lat{6}])
% movegui(bxh, 'center')
