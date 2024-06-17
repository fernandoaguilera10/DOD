function plot_ind_memr(data,EXPname,colors,Conds2Run,Chins2Run,ChinIND,CondIND,outpath,xlimits,shapes)
global legend_string
condition = strsplit(Conds2Run{CondIND}, filesep);
figure(ChinIND); hold on;
plot(data.elicitor, data.deltapow,'Marker',shapes(CondIND,:),'LineStyle','-','linew', 2, 'Color', [colors(CondIND,:),1], 'MarkerFaceColor', colors(CondIND,:));
xlim(xlimits);
xlabel('Elicitor Level (dB FPL)', 'FontWeight', 'bold');
ylabel('\Delta Absorbed Power (dB)','FontWeight', 'bold');
set(gca, 'XScale', 'log', 'FontSize', 14);
legend_string{1,CondIND} = sprintf('%s',Conds2Run{CondIND});
legend(legend_string,'Location','southoutside','Orientation','horizontal','FontSize',8)
legend boxoff
title(sprintf('%s | %s',EXPname,Chins2Run{ChinIND}), 'FontSize', 16)
%% Export
cd(outpath);
filename = cell2mat([Chins2Run(ChinIND),'_MEMR_WB_',condition{2}]);
print(figure(ChinIND),[filename,'_figure'],'-dpng','-r300');
end