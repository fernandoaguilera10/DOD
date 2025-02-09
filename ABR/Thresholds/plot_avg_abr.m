function plot_avg_abr(average,plot_type,colors,shapes,idx,Conds2Run,outpath,filename,counter,ylimits_threshold,ylimits_peaks,ylimits_lat,idx_plot_relative)
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
            legend boxoff; hold off; grid on;
            if ~isempty(ylimits_threshold)
                ylim(ylimits_threshold);
            end
        end
    elseif strcmp(plot_type,'Peaks')
        x_units = 'Sound Level (dB SPL)';
        y_units_amp = 'Peak-to-Peak Amplitude (\muV)';
        y_units_lat = 'Time (ms)';
        for cols = 1:length(average.w1)
            %% Peaks
            figure(counter); hold on;
            subplot(5,1,1); % wave 1
            errorbar(average.x{1,cols}, average.w1{1,cols},average.w1_std{1,cols},'Marker',shapes(1,:),'LineStyle','-', 'linew', 2, 'Color', colors(cols,:), 'MarkerSize', 8, 'MarkerFaceColor', colors(cols,:), 'MarkerEdgeColor', colors(cols,:));
            plot(average.x{1,cols}, average.w1{1,cols},'LineStyle','-', 'linew', 2, 'Color', colors(cols,:),'HandleVisibility','off');
            title(sprintf('ABR Peak Amplitude | Average (n = %.0f)',sum(idx(:,1))), 'FontSize', 16); grid on;
            legend_string{1,cols} = sprintf('%s (n = %s)',cell2mat(Conds2Run(cols)),mat2str(sum(idx(:,cols))));
            legend(legend_string,'Location','north','Orientation','horizontal','FontSize',8);
            legend boxoff;
            xticks(round(unique(average.x{1,1})));
            subplot(5,1,2); % wave 2
            errorbar(average.x{1,cols}, average.w2{1,cols},average.w2_std{1,cols},'Marker',shapes(2,:),'LineStyle','-', 'linew', 2, 'Color', colors(cols,:), 'MarkerSize', 8, 'MarkerFaceColor', colors(cols,:), 'MarkerEdgeColor', colors(cols,:));
            plot(average.x{1,cols}, average.w2{1,cols},'LineStyle','-', 'linew', 2, 'Color', colors(cols,:),'HandleVisibility','off'); grid on;
            xticks(round(unique(average.x{1,1})));
            subplot(5,1,3); % wave 3
            errorbar(average.x{1,cols}, average.w3{1,cols},average.w3_std{1,cols},'Marker',shapes(3,:),'LineStyle','-', 'linew', 2, 'Color', colors(cols,:), 'MarkerSize', 8, 'MarkerFaceColor', colors(cols,:), 'MarkerEdgeColor', colors(cols,:));
            plot(average.x{1,cols}, average.w3{1,cols},'LineStyle','-', 'linew', 2, 'Color', colors(cols,:),'HandleVisibility','off');
            ylabel(y_units_amp, 'FontWeight', 'bold'); grid on;
            xticks(round(unique(average.x{1,1})));
            subplot(5,1,4); % wave 4
            errorbar(average.x{1,cols}, average.w4{1,cols},average.w4_std{1,cols},'Marker',shapes(4,:),'LineStyle','-', 'linew', 2, 'Color', colors(cols,:), 'MarkerSize', 8, 'MarkerFaceColor', colors(cols,:), 'MarkerEdgeColor', colors(cols,:));
            plot(average.x{1,cols}, average.w4{1,cols},'LineStyle','-', 'linew', 2, 'Color', colors(cols,:),'HandleVisibility','off'); grid on;
            xticks(round(unique(average.x{1,1})));
            subplot(5,1,5); % wave 5
            errorbar(average.x{1,cols}, average.w5{1,cols},average.w5_std{1,cols},'Marker',shapes(5,:),'LineStyle','-', 'linew', 2, 'Color', colors(cols,:), 'MarkerSize', 8, 'MarkerFaceColor', colors(cols,:), 'MarkerEdgeColor', colors(cols,:));
            plot(average.x{1,cols}, average.w5{1,cols},'LineStyle','-', 'linew', 2, 'Color', colors(cols,:),'HandleVisibility','off');
            xticks(round(unique(average.x{1,1})));
            xlabel(x_units, 'FontWeight', 'bold'); hold off; grid on;
            set(gcf, 'Units', 'Normalized', 'OuterPosition', [0.25, 0.20, 0.25, 0.8]);
            %% Latencies
            set(gcf, 'Units', 'Normalized', 'OuterPosition', [0.50, 0.20, 0.25, 0.8]);
        end

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
            legend boxoff; hold off; grid on;
            if ~isempty(ylimits_threshold)
                ylim(ylimits_threshold);
            end
        end
    elseif strcmp(plot_type,'Peaks')
        x_units = 'Sound Level (dB SPL)';
        y_units_amp = 'Peak-to-Peak Amplitude (\muV)';
        y_units_lat = 'Time (ms)';
        %% ADD RELATIVE TO FOR PEAKS AND LATENCIES
    end
end
%% Export
cd(outpath);
print(figure(counter),[filename,'_figure'],'-dpng','-r300');
end