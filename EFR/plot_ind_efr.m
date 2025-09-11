function plot_ind_efr(data,plot_type,colors,shapes,Conds2Run,Chins2Run,all_Conds2Run,ChinIND,CondIND,outpath,idx_plot_relative,subject_idx)
global legend_string
legend_string= Conds2Run;
x_units = 'Frequency (Hz)';
condition = strsplit(all_Conds2Run{CondIND}, filesep);
figure(ChinIND); hold on;
if strcmp(plot_type,'RAM')
    title_str = 'RAM 223 Hz';
    y_units = 'PLV';
    filename = cell2mat([Chins2Run(ChinIND),'_RAM223_',mat2str(data.spl),'dBSPL_',condition{2}]);
    plot(data.peaks_locs, data.peaks,'Marker',shapes(CondIND,:),'LineStyle','-', 'linew', 3, 'MarkerSize', 15, 'Color', colors(CondIND,:),'MarkerFaceColor', colors(CondIND,:), 'MarkerEdgeColor', colors(CondIND,:));
    ylim([0,1]); hold off;
    ylabel(y_units, 'FontWeight', 'bold')
    xlabel(x_units, 'FontWeight', 'bold')
elseif strcmp(plot_type,'dAM')
    title_str = 'dAM 4 kHz';
    y_units = 'Power (dB)';
    filename = cell2mat([Chins2Run(ChinIND),'_dAM4kHz_',mat2str(data.spl),'dBSPL_',condition{2}]);
    plot(data.smooth.f, data.smooth.dAM,'LineStyle','-', 'linew', 3, 'Color', colors(CondIND,:));
    plot(data.smooth.f, data.smooth.NF,'LineStyle','--', 'linew', 3, 'Color', colors(CondIND,:),'HandleVisibility','off');
    hold off; xlim([-inf,inf]);
    set(gca, 'XScale', 'log')
    ylabel(y_units, 'FontWeight', 'bold')
    xlabel(x_units, 'FontWeight', 'bold')
end
legend(legend_string,'Location','southoutside','Orientation','horizontal')
legend boxoff
title(sprintf('EFR (%s) | %s | %.0f dB SPL',title_str, cell2mat(Chins2Run(ChinIND)),data.spl));
set(gca,'FontSize',25);
set(gcf, 'Units', 'normalized', 'Position', [0.2 0.2 0.5 0.6]);
%% Export
cd(outpath);
print(figure(ChinIND),[filename,'_figure'],'-dpng','-r300');
end