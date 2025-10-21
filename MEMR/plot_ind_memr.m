function plot_ind_memr(data,EXPname,colors,Conds2Run,Chins2Run,all_Conds2Run,ChinIND,CondIND,outpath,xlimits,shapes)
global legend_string
legend_string= Conds2Run;
condition = strsplit(all_Conds2Run{CondIND}, filesep);
figure(ChinIND);
subplot(1,4,[1,3]); hold on;
plot(data.elicitor, data.deltapow,'Marker',shapes(CondIND,:),'LineStyle','-','linew', 2, 'MarkerSize', 12, 'Color', colors(CondIND,:), 'MarkerFaceColor', colors(CondIND,:));
xlim(xlimits); xticks(xlimits(1):5:xlimits(2)); xtickangle(90);
xlabel('Elicitor Level (dB FPL)', 'FontWeight', 'bold');
ylabel('\Delta Absorbed Power (dB)','FontWeight', 'bold');
title(sprintf('%s | %s',EXPname,Chins2Run{ChinIND}));
set(gca,'FontSize',25);
set(gcf, 'Units', 'normalized', 'Position', [0.2 0.2 0.5 0.6]);
legend(legend_string,'Location','northwest','Orientation','vertical')
legend boxoff
subplot(1,4,4); hold on;
plot(data.threshold,'Marker',shapes(CondIND,:),'LineStyle','-','linew', 2, 'MarkerSize', 20, 'Color', colors(CondIND,:), 'MarkerFaceColor', colors(CondIND,:));
ylabel('Threshold (dB FPL)', 'FontWeight', 'bold'); xticklabels([]); xticks([]);
set(gca,'FontSize',25);
set(gcf, 'Units', 'normalized', 'Position', [0.2 0.2 0.5 0.6]);
%% Export
cd(outpath);
filename = cell2mat([Chins2Run(ChinIND),'_MEMR_WB_',condition{2}]);
print(figure(ChinIND),[filename,'_figure'],'-dpng','-r300');
end