function plot_avg_efr(average,locs_all,plot_type,level_spl,shapes,colors,idx,Chins2Run,Conds2Run,outpath,filename,counter,ylimits,idx_plot_relative)
str_plot_relative = strsplit(Conds2Run{idx_plot_relative}, filesep);
legend_string = [];
x_units = 'Frequency (Hz)';
y_units_amp = 'PLV';
y_units_ratio = 'PLV Ratio';
if strcmp(plot_type,'RAM')
    title_str = 'RAM 223 Hz';
elseif strcmp(plot_type,'AM/FM')
    title_str = 'AM/FM 4 kHz';
end
if isempty(idx_plot_relative)
    for cols = 1:length(average.peaks_locs)
        % Average PLV amplitude
        figure(counter); hold on;
        errorbar(average.peaks_locs{1,cols},average.peaks{1,cols},average.peaks_std{1,cols},'Marker',shapes(cols,:),'LineStyle','-','linew', 2, 'MarkerSize', 8, 'Color', colors(cols,:), 'MarkerFaceColor', colors(cols,:), 'MarkerEdgeColor', colors(cols,:));
        average.efr_fit = fillmissing(average.peaks{1,cols},'linear','SamplePoints',locs_all{1,cols});
        plot(average.peaks_locs{1,cols},average.efr_fit,'LineStyle','-', 'linew', 2, 'Color', colors(cols,:),'HandleVisibility','off');
        ylabel(y_units_amp, 'FontWeight', 'bold');
        xlabel(x_units, 'FontWeight', 'bold');
        title(sprintf('EFR (%s) | Average (n = %.0f) | %.0f dB SPL',title_str,sum(idx(:,1)),level_spl), 'FontSize', 16);
        legend_string{1,cols} = sprintf('%s (n = %s)',cell2mat(Conds2Run(cols)),mat2str(sum(idx(:,cols))));
        legend(legend_string,'Location','southoutside','Orientation','horizontal','FontSize',8);
        legend boxoff; hold off;
        ylim(ylimits); grid on;
        idx_peaks = ~isnan(average.peaks{1,cols});
        x_max = round(max(average.peaks_locs{1,cols}(idx_peaks)),-3);
        xlim([0,x_max]); set(gca,'xscale','linear');
        xticks(round(average.peaks_locs{1,cols}));
    end
    % Average PLV ratio
    figure(counter+1); hold on;
    ratio_plot = boxplot(cell2mat(average.all_ratio),'Labels',legend_string,'Colors',colors);
    h = findobj(gca,'Tag','Box');
    for j=1:length(h)
        patch(get(h(j),'XData'),get(h(j),'YData'),'y', ...
            'FaceAlpha',0.5,'FaceColor', get(h(j), 'Color'), ...
            'EdgeColor', get(h(j), 'Color'));
    end
    set(ratio_plot(1:6,:), 'LineWidth', 2);
    ylabel(y_units_ratio, 'FontWeight', 'bold','FontSize',13);
    title(sprintf('EFR Ratio (%s) | Average (n = %.0f) | %.0f dB SPL',title_str,sum(idx(:,1)),level_spl), 'FontSize', 16);
    set(gca,'FontSize',15); xlim([0.75,width(average.all_ratio)+0.25]);
end

if ~isempty(idx_plot_relative)  %plot relative to
    y_units_amp = sprintf('PLV (re. %s)',str_plot_relative{2});
    for cols = 1:length(average.peaks_locs)
        % Average PLV amplitude
        figure(counter); hold on;
        errorbar(average.peaks_locs{1,cols},average.peaks{1,cols},average.peaks_std{1,cols},'Marker',shapes(cols+1,:),'LineStyle','-','linew', 2, 'MarkerSize', 8, 'Color', colors(cols+1,:), 'MarkerFaceColor', colors(cols+1,:), 'MarkerEdgeColor', colors(cols+1,:));
        average.efr_fit = fillmissing(average.peaks{1,cols},'linear','SamplePoints',locs_all{1,cols});
        plot(average.peaks_locs{1,cols},average.efr_fit,'LineStyle','-', 'linew', 2, 'Color', colors(cols+1,:),'HandleVisibility','off');
        plot(average.peaks_locs{1,cols}, zeros(size(average.peaks_locs{1,cols})),'LineStyle','--', 'linew', 2, 'Color', 'k','HandleVisibility','off');
        ylabel(y_units_amp, 'FontWeight', 'bold');
        xlabel(x_units, 'FontWeight', 'bold');
        title(sprintf('EFR (%s) | Average (n = %.0f) | %.0f dB SPL',title_str,sum(idx(:,1)),level_spl), 'FontSize', 16);
        legend_string{1,cols} = sprintf('%s (n = %s)',cell2mat(Conds2Run(cols+1)),mat2str(sum(idx(:,cols+1))));
        legend(legend_string,'Location','southoutside','Orientation','horizontal','FontSize',8);
        legend boxoff; hold off;
        ylim(ylimits); grid on;
        idx_peaks = ~isnan(average.peaks{1,cols});
        x_max = round(max(average.peaks_locs{1,cols}(idx_peaks)),-3);
        xlim([0,x_max]); set(gca,'xscale','linear');
        xticks(round(average.peaks_locs{1,cols}));
    end
    % Average PLV ratio
    figure(counter+1); hold on;
    ratio_plot = boxplot(cell2mat(average.all_ratio),'Labels',legend_string,'Colors',colors(2:end,:));
    h = findobj(gca,'Tag','Box');
    for j=1:length(h)
        patch(get(h(j),'XData'),get(h(j),'YData'),'y', ...
            'FaceAlpha',0.5,'FaceColor', get(h(j), 'Color'), ...
            'EdgeColor', get(h(j), 'Color'));
    end
    set(ratio_plot(1:6,:), 'LineWidth', 2);
    ylabel(y_units_ratio, 'FontWeight', 'bold','FontSize',13);
    title(sprintf('EFR Ratio (%s) | Average (n = %.0f) | %.0f dB SPL',title_str,sum(idx(:,1)),level_spl), 'FontSize', 16);
    set(gca,'FontSize',15); xlim([0.75,width(average.all_ratio)+0.25]);
end
average.subjects = Chins2Run;
average.conditions = Conds2Run;
%% Export
cd(outpath);
save(filename,'average');
print(figure(counter),[filename,'_figure'],'-dpng','-r300');
end