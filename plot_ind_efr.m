function plot_ind_efr(data,plot_type,shapes,colors,Conds2Run,Chins2Run,ChinIND,CondIND,outpath,idx_plot_relative,subject_idx)
global legend_string
legend_string = [];
legend_string= Conds2Run(subject_idx(ChinIND,:) == 1);
x_units = 'Frequency (Hz)';
y_units = 'PLV';
condition = strsplit(Conds2Run{CondIND}, filesep);
if strcmp(plot_type,'RAM')
    title_str = 'RAM 223 Hz';
    filename = cell2mat([Chins2Run(ChinIND),'_RAM223_',mat2str(data.spl),'dBSPL_',condition{2}]);
elseif strcmp(plot_type,'AM/FM')
    filename = cell2mat([Chins2Run(ChinIND),'_AMFM_',mat2str(data.spl),'dBSPL_',condition{2}]);
    title_str = 'AM/FM 4 kHz';
end
figure(ChinIND); hold on;
plot(data.peaks_locs, data.peaks,'Marker',shapes(CondIND,:),'LineStyle','-', 'linew', 2, 'MarkerSize', 12, 'Color', colors(CondIND,:),'MarkerFaceColor', colors(CondIND,:), 'MarkerEdgeColor', colors(CondIND,:))
ylim([0,1]); hold off;
ylabel(y_units, 'FontWeight', 'bold')
xlabel(x_units, 'FontWeight', 'bold')
legend(legend_string,'Location','southoutside','Orientation','horizontal')
legend boxoff
title(sprintf('EFR (%s) | %s | %.0f dB SPL',title_str, cell2mat(Chins2Run(ChinIND)),data.spl));
set(gca,'FontSize',15);
%% Export
cd(outpath);
print(figure(ChinIND),[filename,'_figure'],'-dpng','-r300');
end