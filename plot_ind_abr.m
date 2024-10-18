function plot_ind_abr(data,plot_type,shapes,colors,Conds2Run,Chins2Run,ChinIND,CondIND,outpath,ylimits)
global legend_string
condition = strsplit(Conds2Run{CondIND}, filesep);
if strcmp(plot_type,'Thresholds')
    x_units = 'Frequency (kHz)';
    y_units = 'Threshold (dB SPL)';
    filename = cell2mat([Chins2Run(ChinIND),'_ABRthresholds_',condition{2}]);
    figure(ChinIND); hold on;
    plot(data.freqs, data.thresholds,'Marker',shapes(CondIND,:),'LineStyle','-', 'linew', 2, 'MarkerSize', 8, 'Color', colors(CondIND,:),'MarkerFaceColor', colors(CondIND,:), 'MarkerEdgeColor', colors(CondIND,:))
    ylim(ylimits); hold off;
    ylabel(y_units, 'FontWeight', 'bold')
    xlabel(x_units, 'FontWeight', 'bold')
    xticks(data.freqs);
    xticklabels({'Click', '0.5', '1', '2', '4', '8'});
    legend_string{1,CondIND} = sprintf('%s',Conds2Run{CondIND});
    legend(legend_string,'Location','southoutside','Orientation','horizontal','FontSize',8)
    legend boxoff
    title(sprintf('ABR Thresholds | %s ', cell2mat(Chins2Run(ChinIND))), 'FontSize', 16);
elseif strcmp(plot_type,'Peaks')
    x_units = 'Time (ms)';
    y_units = 'Amplitude (TBD)';
    filename = cell2mat([Chins2Run(ChinIND),'_ABRpeaks_',condition{2}]);
end
%% Export
cd(outpath);
print(figure(ChinIND),[filename,'_figure'],'-dpng','-r300');
end