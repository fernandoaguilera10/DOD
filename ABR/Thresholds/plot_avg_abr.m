function plot_avg_abr(average,plot_type,shapes,colors,idx,Conds2Run,outpath,filename,counter,ylimits,idx_plot_relative)
str_plot_relative = strsplit(Conds2Run{idx_plot_relative}, filesep);
legend_string = [];
if isempty(idx_plot_relative)
    if strcmp(plot_type,'Thresholds')
        x_units = 'Frequency (kHz)';
        y_units = 'Threshold (dB SPL)';
        for cols = 1:length(average.y)
            % Average DP + NF
            figure(counter); hold on;
            errorbar(average.x{1,cols}, average.y{1,cols},average.y_std{1,cols},'Marker',shapes(cols,:),'LineStyle','-', 'linew', 2, 'Color', colors(cols,:), 'MarkerSize', 8, 'MarkerFaceColor', colors(cols,:), 'MarkerEdgeColor', colors(cols,:));
            plot(average.x{1,cols}, average.y{1,cols},'LineStyle','-', 'linew', 2, 'Color', colors(cols,:),'HandleVisibility','off');
            xticks(average.x{1,1});
            xticklabels({'Click', '0.5', '1', '2', '4', '8'});
            ylabel(y_units, 'FontWeight', 'bold');
            xlabel(x_units, 'FontWeight', 'bold');
            title(sprintf('ABR Thresholds | Average (n = %.0f)',sum(idx(:,1))), 'FontSize', 16);
            legend_string{1,cols} = sprintf('%s (n = %s)',cell2mat(Conds2Run(cols)),mat2str(sum(idx(:,cols))));
            legend(legend_string,'Location','southoutside','Orientation','horizontal','FontSize',8);
            legend boxoff; hold off;
            ylim(ylimits); grid on;
        end
    elseif strcmp(plot_type,'Peaks')
        x_units = 'Time (ms)';
        y_units = 'Amplitude (TBD)';
    end
end

if ~isempty(idx_plot_relative)  %plot relative to
    if strcmp(plot_type,'Thresholds')
        x_units = 'Frequency (kHz)';
        y_units = sprintf('Threshold Shift (re. %s)',str_plot_relative{2});
        for cols = 1:length(average.y)
            % Average DP + NF
            figure(counter); hold on;
            errorbar(average.x{1,cols}, average.y{1,cols},average.y_std{1,cols},'Marker',shapes(cols+1,:),'LineStyle','-', 'linew', 2, 'Color', colors(cols+1,:), 'MarkerSize', 8, 'MarkerFaceColor', colors(cols+1,:), 'MarkerEdgeColor', colors(cols+1,:));
            plot(average.x{1,cols}, average.y{1,cols},'LineStyle','-', 'linew', 2, 'Color', colors(cols+1,:),'HandleVisibility','off');
            plot(average.x{1,cols}, zeros(size(average.x{1,cols})),'LineStyle','--', 'linew', 2, 'Color', 'k','HandleVisibility','off');
            xticks(average.x{1,1});
            xticklabels({'Click', '0.5', '1', '2', '4', '8'});
            ylabel(y_units, 'FontWeight', 'bold');
            xlabel(x_units, 'FontWeight', 'bold');
            title(sprintf('ABR Thresholds | Average (n = %.0f)',sum(idx(:,1))), 'FontSize', 16);
            legend_string{1,cols} = sprintf('%s (n = %s)',cell2mat(Conds2Run(cols+1)),mat2str(sum(idx(:,cols+1))));
            legend(legend_string,'Location','southoutside','Orientation','horizontal','FontSize',8);
            legend boxoff; hold off;
            ylim(ylimits); grid on;
        end
    elseif strcmp(plot_type,'Peaks')
        x_units = 'Time (ms)';
        y_units = 'Amplitude (TBD)';
    end
end
%% Export
cd(outpath);
print(figure(counter),[filename,'_figure'],'-dpng','-r300');
end