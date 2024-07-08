function plot_avg_efr(average,plot_type,level_spl,colors,shapes,idx,Conds2Run,outpath,filename,counter,ylimits,idx_plot_relative)
str_plot_relative = strsplit(Conds2Run{idx_plot_relative}, filesep);
legend_string = [];
x_units = 'Frequency (Hz)';
y_units = 'PLV';
if strcmp(plot_type,'RAM')
    title_str = 'RAM 223 Hz';
elseif strcmp(plot_type,'AM/FM')
    title_str = 'AM/FM 4 kHz';
end
if isempty(idx_plot_relative)
    for cols = 1:length(average.efr)
        % Average DP + NF
        figure(counter); hold on;
        plot(average.peaks_locs{1,cols},average.peaks{1,cols},shapes(cols,:),'linew', 4, 'MarkerSize', 8, 'MarkerFaceColor', colors(cols,:), 'MarkerEdgeColor', colors(cols,:));
        ylabel(y_units, 'FontWeight', 'bold');
        xlabel(x_units, 'FontWeight', 'bold');
        title(sprintf('EFR (%s) | Average (n = %.0f) | %.0f dB SPL',title_str,sum(idx(:,1)),level_spl), 'FontSize', 16);
        legend_string{1,cols} = sprintf('%s',cell2mat(Conds2Run(cols)));
        legend(legend_string,'Location','southoutside','Orientation','horizontal','FontSize',8);
        legend boxoff; hold off;
        ylim(ylimits);
    end
end

if ~isempty(idx_plot_relative)  %plot relative to
    y_units = sprintf('PLV (re. %s)',str_plot_relative{2});
    for cols = 1:length(average.peaks_locs)
        % Average DP + NF
        figure(counter); hold on;
        plot(average.peaks_locs{1,cols},average.peaks{1,cols},shapes(cols+1,:),'linew', 4, 'MarkerSize', 8, 'MarkerFaceColor', colors(cols+1,:), 'MarkerEdgeColor', colors(cols+1,:));
        ylabel(y_units, 'FontWeight', 'bold');
        xlabel(x_units, 'FontWeight', 'bold');
        title(sprintf('EFR (%s) | Average (n = %.0f) | %.0f dB SPL',title_str,sum(idx(:,1)),level_spl), 'FontSize', 16);
        legend_string{1,cols} = sprintf('%s',cell2mat(Conds2Run(cols+1)));
        legend(legend_string,'Location','southoutside','Orientation','horizontal','FontSize',8);
        legend boxoff; hold off;
        ylim(ylimits);
    end
end
%% Export
cd(outpath);
print(figure(counter),[filename,'_figure'],'-dpng','-r300');
end