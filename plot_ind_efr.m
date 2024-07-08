function plot_ind_efr(data,plot_type,colors,shapes,Conds2Run,Chins2Run,ChinIND,CondIND,outpath)
global legend_string
x_units = 'Frequency (Hz)';
y_units = 'PLV';
condition = strsplit(Conds2Run{CondIND}, filesep);
if strcmp(plot_type,'RAM')
    title_str = 'RAM 223 Hz';
    filename = cell2mat([Chins2Run(ChinIND),'_RAM223_',condition{2}]);
elseif strcmp(plot_type,'AM/FM')
    filename = cell2mat([Chins2Run(ChinIND),'_AMFM_',condition{2}]);
    title_str = 'AM/FM 4 kHz';
end
figure(ChinIND); hold on;
plot(data.peaks_locs, data.peaks, shapes(CondIND,:), 'linew', 4, 'MarkerSize', 8, 'MarkerFaceColor', colors(CondIND,:), 'MarkerEdgeColor', colors(CondIND,:))
ylim([0,1]); hold off;
ylabel(y_units, 'FontWeight', 'bold')
xlabel(x_units, 'FontWeight', 'bold')
legend_string{1,CondIND} = sprintf('%s',Conds2Run{CondIND});
legend(legend_string,'Location','southoutside','Orientation','horizontal','FontSize',8)
legend boxoff
title(sprintf('EFR (%s) | %s | %.0f dB SPL',title_str, cell2mat(Chins2Run(ChinIND)),data.spl), 'FontSize', 16);
%% Export
cd(outpath);
print(figure(ChinIND),[filename,'_figure'],'-dpng','-r300');
end