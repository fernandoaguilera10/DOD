function plot_avg_efr(average,plot_type,level_spl,colors,shapes,idx,conds_idx,Chins2Run,Conds2Run,all_Conds2Run,outpath,filename,counter,ylimits,idx_plot_relative,flag)
str_plot_relative = strsplit(all_Conds2Run{idx_plot_relative}, filesep);
legend_string = [];
x_units = 'Frequency (Hz)';
if strcmp(plot_type,'RAM')
    title_str = 'RAM 223 Hz';
elseif strcmp(plot_type,'AM/FM')
    title_str = 'AM/FM 4 kHz';
end
if isempty(idx_plot_relative)
    for cols = 1:length(average.peaks)
        if ~isempty(average.peaks_locs{1,cols})
            y_units_amp = 'PLV';
            y_units_ratio = 'PLV Ratio';
            row_idx{cols} = find(~cellfun('isempty', average.peaks_locs(:, cols)));
            % Average PLV amplitude
            figure(counter); hold on;
            errorbar(average.peaks_locs{1,cols},average.peaks{1,cols},average.peaks_std{1,cols},'Marker',shapes(cols,:),'LineStyle','-','linew', 2, 'MarkerSize', 12, 'Color', colors(cols,:), 'MarkerFaceColor', colors(cols,:), 'MarkerEdgeColor', colors(cols,:),'HandleVisibility','off');
            average.efr_fit = fillmissing(average.peaks{1,cols},'linear','SamplePoints',average.peaks_locs{row_idx{1,cols}(1),cols});
            plot(average.peaks_locs{1,cols},average.efr_fit,'Marker',shapes(cols,:),'LineStyle','-', 'linew', 2,'Color', colors(cols,:), 'MarkerSize', 12, 'MarkerFaceColor', colors(cols,:), 'MarkerEdgeColor', colors(cols,:));
            ylabel(y_units_amp, 'FontWeight', 'bold');
            xlabel(x_units, 'FontWeight', 'bold');
            title(sprintf('EFR (%s) | %.0f dB SPL',title_str,level_spl), 'FontSize', 16);
            temp{1,cols} = sprintf('%s (n = %s)',cell2mat(all_Conds2Run(cols)),mat2str(sum(idx(:,cols))));
            legend_idx = find(~cellfun(@isempty,temp));
            legend_string = temp(legend_idx);
            legend(legend_string,'Location','southoutside','Orientation','horizontal');
            legend boxoff; hold off;
            ylim(ylimits); grid on;
            idx_peaks = ~isnan(average.peaks{1,cols});
            x_max = round(max(average.peaks_locs{1,cols}(idx_peaks)),-3);
            xlim([0,x_max]); set(gca,'xscale','linear');
            set(gca,'FontSize',15); xticks(round(average.peaks_locs{1,cols}));
        end
    end
    % Average PLV ratio
    figure(counter+1); hold on;
    ratio_plot = boxplot(cell2mat(average.all_ratio(:,legend_idx)),'Labels',legend_string,'Colors',colors(legend_idx,:));
    h = findobj(gca,'Tag','Box');
    for j=1:length(h)
        patch(get(h(j),'XData'),get(h(j),'YData'),'y', ...
            'FaceAlpha',0.5,'FaceColor', get(h(j), 'Color'), ...
            'EdgeColor', get(h(j), 'Color'));
    end
    set(ratio_plot(1:6,:), 'LineWidth', 2);
    ylabel(y_units_ratio, 'FontWeight', 'bold','FontSize',13);
    title(sprintf('EFR Ratio (%s) |  (n = %.0f) | %.0f dB SPL',title_str,sum(idx(:,1)),level_spl), 'FontSize', 16);
    set(gca,'FontSize',15); xlim([0.50,width(average.all_ratio(:,legend_idx))+0.50]);
end

if ~isempty(idx_plot_relative)   %plot relative to
    y_units_amp = sprintf('PLV (re. %s)',str_plot_relative{2});
    y_units_ratio = sprintf('PLV Ratio (re. %s)',str_plot_relative{2});
    for cols = 1:length(average.peaks)
        if ~isempty(average.peaks_locs{1,cols})
            % Average PLV amplitude
            figure(counter); hold on;
            errorbar(average.peaks_locs{1,cols},average.peaks{1,cols},average.peaks_std{1,cols},'Marker',shapes(cols+1,:),'LineStyle','-','linew', 2, 'MarkerSize', 12, 'Color', colors(cols+1,:), 'MarkerFaceColor', colors(cols+1,:), 'MarkerEdgeColor', colors(cols+1,:),'HandleVisibility','off');
            average.efr_fit = fillmissing(average.peaks{1,cols},'linear','SamplePoints',average.peaks_locs{1,cols});
            plot(average.peaks_locs{1,cols},average.efr_fit,'Marker',shapes(cols+1,:),'LineStyle','-', 'linew', 2,'Color', colors(cols+1,:), 'MarkerSize', 12, 'MarkerFaceColor', colors(cols+1,:), 'MarkerEdgeColor', colors(cols+1,:));
            %plot(average.peaks_locs{1,cols},average.peaks{1,cols},'*k','linewidth',2)
            plot(average.peaks_locs{1,cols}, zeros(size(average.peaks_locs{1,cols})),'LineStyle','--', 'linew', 2, 'Color', 'k','HandleVisibility','off');
            ylabel(y_units_amp, 'FontWeight', 'bold');
            xlabel(x_units, 'FontWeight', 'bold');
            title(sprintf('EFR (%s) | %.0f dB SPL',title_str,level_spl), 'FontSize', 16);
            temp{1,cols} = sprintf('%s (n = %s)',cell2mat(all_Conds2Run(cols+1)),mat2str(sum(idx(:,cols+1))));
            legend_idx = find(~cellfun(@isempty,temp));
            legend_string = temp(legend_idx);
            legend(legend_string,'Location','southoutside','Orientation','horizontal');
            legend boxoff; hold off;
            ylim(ylimits); grid on;
            idx_peaks = ~isnan(average.peaks{1,cols});
            if ~isnan(average.peaks_locs{1,cols}(idx_peaks))
                x_max = round(max(average.peaks_locs{1,cols}(idx_peaks)),-3);
                xticks(round(average.peaks_locs{1,cols}));
                xlim([0,x_max+200]);
            end
            set(gca,'xscale','linear');
            set(gca,'FontSize',15); 
        end
    end
    % Average PLV ratio
    figure(counter+1); hold on;
    ratio_plot = boxplot(cell2mat(average.all_ratio(:,legend_idx)),'Labels',legend_string,'Colors',colors(legend_idx+1,:));
    h = findobj(gca,'Tag','Box');
    for j=1:length(h)
        patch(get(h(j),'XData'),get(h(j),'YData'),'y', ...
            'FaceAlpha',0.5,'FaceColor', get(h(j), 'Color'), ...
            'EdgeColor', get(h(j), 'Color'));
    end
    set(ratio_plot(1:6,:), 'LineWidth', 2);
    ylabel(y_units_ratio, 'FontWeight', 'bold','FontSize',13);
    title(sprintf('EFR Ratio (%s) | %.0f dB SPL',title_str,level_spl), 'FontSize', 16);
    set(gca,'FontSize',15); xlim([0.75,width(average.all_ratio(:,legend_idx))+0.25]);
end
average.subjects = Chins2Run;
average.conditions = Conds2Run;
%% Export
cd(outpath);
save(filename,'average');
print(figure(counter),[filename,'_figure'],'-dpng','-r300');
print(figure(counter+1),[filename,'_PLVratio_figure'],'-dpng','-r300');
end