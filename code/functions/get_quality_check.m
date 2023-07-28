function get_quality_check(rec_length, events, cfg)
% the function creates plots for the number of events found for each subject and the
% recording length. It saves these plots to a separate folder coded at cfg.dir.qualitycheck

%plot and save figure for the recording length
fig_length = bar(rec_length), xlabel('Participants', 'FontSize', 14), ylabel('Length of recordings (min)', 'FontSize', 14)
saveas(fig_length, [cfg.dir.qualitycheck, 'recording length.png'])

%plot and save figure for the number of event types. Subjects are color coded
fig_events = bar(events(:,1),events(:,2:end)), xlabel('Events', 'FontSize', 12), ylabel('Number of occurances', 'FontSize', 12),...
    legend(string(1:length(subjects)), 'Location','southoutside', 'Orientation','horizontal','NumColumns',6, 'FontSize',5)
saveas(fig_events, [cfg.dir.qualitycheck,'events per participant.png'])