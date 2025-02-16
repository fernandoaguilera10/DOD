function plot_avg_abr(average,plot_type,colors,shapes,idx,Conds2Run,outpath,filename,counter,ylimits_threshold,idx_plot_relative,peak_analysis)
str_plot_relative = strsplit(Conds2Run{idx_plot_relative}, filesep);
legend_string = [];
rows = 1:4; % plot highest 4 levels [90 80 70 60] dB SPL
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
        if strcmp(peak_analysis,'Amplitude')
            y_units = 'Peak-to-Peak Amplitude (\muV)';
            title_str = sprintf('ABR Peak-to-Peak Amplitude | Average (n = %.0f)',sum(idx(:,1)));
            plot_loc = [0.25, 0.20, 0.30, 0.8];
        elseif strcmp(peak_analysis,'Latency')
            y_units = 'Time (ms)';
            title_str = sprintf('ABR Absolute Peak Latency | Average (n = %.0f)',sum(idx(:,1)));
            plot_loc = [0.50, 0.20, 0.30, 0.8];
        end
        for cols = 1:length(average.w1)
            figure(counter);
            set(gcf, 'Units', 'Normalized', 'OuterPosition', plot_loc);
            subplot(6,1,1); hold on; % wave 1
            w1 = errorbar(round(average.x{1,cols}(rows)), average.w1{1,cols}(rows),average.w1_std{1,cols}(rows),'Marker',shapes(1,:),'LineStyle','-', 'linew', 2, 'Color', colors(cols,:), 'MarkerSize', 8, 'MarkerFaceColor', colors(cols,:), 'MarkerEdgeColor', colors(cols,:));
            w1_fit = fillmissing(flip(average.w1{1,cols}(rows)),'linear','SamplePoints',flip(round(average.x{1,cols}(rows)))); w1_fit = flip(w1_fit);
            plot(round(average.x{1,cols}(rows)),w1_fit,'LineStyle','-', 'linew', 2, 'Color', colors(cols,:),'HandleVisibility','off');
            title(title_str, 'FontSize', 16); grid on;
            subtitle('Wave I'); xlim([-inf,inf]);
            xticks(round(unique(average.x{1,1}(rows))));
            subplot(6,1,2); hold on; % wave 2
            w2 = errorbar(round(average.x{1,cols}(rows)), average.w2{1,cols}(rows),average.w2_std{1,cols}(rows),'Marker',shapes(2,:),'LineStyle','-', 'linew', 2, 'Color', colors(cols,:), 'MarkerSize', 8, 'MarkerFaceColor', colors(cols,:), 'MarkerEdgeColor', colors(cols,:));
            w2_fit = fillmissing(flip(average.w2{1,cols}(rows)),'linear','SamplePoints',flip(round(average.x{1,cols}(rows)))); w2_fit = flip(w2_fit);
            plot(round(average.x{1,cols}(rows)), w2_fit,'LineStyle','-', 'linew', 2, 'Color', colors(cols,:),'HandleVisibility','off'); grid on;
            xticks(round(unique(average.x{1,1}(rows))));
            subtitle('Wave II'); xlim([-inf,inf]);
            subplot(6,1,3); hold on; % wave 3
            w3 = errorbar(round(average.x{1,cols}(rows)), average.w3{1,cols}(rows),average.w3_std{1,cols}(rows),'Marker',shapes(3,:),'LineStyle','-', 'linew', 2, 'Color', colors(cols,:), 'MarkerSize', 8, 'MarkerFaceColor', colors(cols,:), 'MarkerEdgeColor', colors(cols,:));
            w3_fit = fillmissing(flip(average.w3{1,cols}(rows)),'linear','SamplePoints',flip(round(average.x{1,cols}(rows)))); w3_fit = flip(w3_fit);
            plot(round(average.x{1,cols}(rows)), w3_fit,'LineStyle','-', 'linew', 2, 'Color', colors(cols,:),'HandleVisibility','off');
            ylabel(y_units, 'FontWeight', 'bold'); grid on;
            xticks(round(unique(average.x{1,1}(rows))));
            subtitle('Wave III'); xlim([-inf,inf]);
            subplot(6,1,4); hold on; % wave 4
            w4 = errorbar(round(average.x{1,cols}(rows)), average.w4{1,cols}(rows),average.w4_std{1,cols}(rows),'Marker',shapes(4,:),'LineStyle','-', 'linew', 2, 'Color', colors(cols,:), 'MarkerSize', 8, 'MarkerFaceColor', colors(cols,:), 'MarkerEdgeColor', colors(cols,:));
            w4_fit = fillmissing(flip(average.w4{1,cols}(rows)),'linear','SamplePoints',flip(round(average.x{1,cols}(rows)))); w4_fit = flip(w4_fit);
            plot(round(average.x{1,cols}(rows)), w4_fit,'LineStyle','-', 'linew', 2, 'Color', colors(cols,:),'HandleVisibility','off'); grid on;
            xticks(round(unique(average.x{1,1}(rows))));
            subtitle('Wave IV'); xlim([-inf,inf]);
            subplot(6,1,5); hold on;% wave 5
            w5 = errorbar(round(average.x{1,cols}(rows)), average.w5{1,cols}(rows),average.w5_std{1,cols}(rows),'Marker',shapes(5,:),'LineStyle','-', 'linew', 2, 'Color', colors(cols,:), 'MarkerSize', 8, 'MarkerFaceColor', colors(cols,:), 'MarkerEdgeColor', colors(cols,:));
            w5_fit = fillmissing(flip(average.w5{1,cols}(rows)),'linear','SamplePoints',flip(round(average.x{1,cols}(rows)))); w5_fit = flip(w5_fit);
            plot(round(average.x{1,cols}(rows)), w5_fit,'LineStyle','-', 'linew', 2, 'Color', colors(cols,:),'HandleVisibility','off');
            xticks(round(unique(average.x{1,1}(rows)))); hold off; grid on;
            subtitle('Wave V'); xlim([-inf,inf]);
            subplot(6,1,6); hold on;% wave 1/5 ratio
            w1and5 = errorbar(round(average.x{1,cols}(rows)), average.w1and5{1,cols}(rows),average.w1and5_std{1,cols}(rows),'Marker',shapes(6,:),'LineStyle','-', 'linew', 2, 'Color', colors(cols,:), 'MarkerSize', 8, 'MarkerFaceColor', colors(cols,:), 'MarkerEdgeColor', colors(cols,:));
            w1and5_fit = fillmissing(flip(average.w1and5{1,cols}(rows)),'linear','SamplePoints',flip(round(average.x{1,cols}(rows)))); w1and5_fit = flip(w1and5_fit);
            plot(round(average.x{1,cols}(rows)), w1and5_fit,'LineStyle','-', 'linew', 2, 'Color', colors(cols,:),'HandleVisibility','off');
            xticks(round(unique(average.x{1,1}(rows))));
            xlabel(x_units, 'FontWeight', 'bold'); hold off; grid on;
            subtitle('Wave I/V'); xlim([-inf,inf]);
            legend_string{1,cols} = sprintf('%s (n = %s)',cell2mat(Conds2Run(cols)),mat2str(sum(idx(:,cols))));
            if cols == length(average.w1)
                lgd = legend(legend_string,'Location','north','Orientation','horizontal','FontSize',8);
                lgd.Box = 'off';
                lgd.Position = [0.5,0.04,0,0];
            end
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
        if strcmp(peak_analysis,'Amplitude')
            y_units = sprintf('Peak-to-Peak Amplitude Shift (re. %s)',str_plot_relative{2});
            title_str = sprintf('ABR Peak-to-Peak Amplitude | Average (n = %.0f)',sum(idx(:,1)));
            plot_loc = [0.23, 0.20, 0.30, 0.8];
        elseif strcmp(peak_analysis,'Latency')
            y_units = sprintf('Latency Shift (re. %s)',str_plot_relative{2});
            title_str = sprintf('ABR Absolute Peak Latency | Average (n = %.0f)',sum(idx(:,1)));
            plot_loc = [0.52, 0.20, 0.30, 0.8];
        end
        for cols = 1:length(average.w1)
            figure(counter);
            set(gcf, 'Units', 'Normalized', 'OuterPosition', plot_loc);
            subplot(6,1,1); hold on; % wave 1
            w1 = errorbar(round(average.x{1,cols}(rows)), average.w1{1,cols}(rows),average.w1_std{1,cols}(rows),'Marker',shapes(1,:),'LineStyle','-', 'linew', 2, 'Color', colors(cols+1,:), 'MarkerSize', 8, 'MarkerFaceColor', colors(cols+1,:), 'MarkerEdgeColor', colors(cols+1,:));
            w1_fit = fillmissing(flip(average.w1{1,cols}(rows)),'linear','SamplePoints',flip(round(average.x{1,cols}(rows)))); w1_fit = flip(w1_fit);
            plot(round(average.x{1,cols}(rows)), w1_fit,'LineStyle','-', 'linew', 2, 'Color', colors(cols+1,:),'HandleVisibility','off');
            plot(round(average.x{1,cols}(rows)), zeros(size(average.x{1,cols}(rows))),'LineStyle','--', 'linew', 2, 'Color', 'k','HandleVisibility','off');
            title(title_str, 'FontSize', 16); grid on;
            subtitle('Wave I'); xlim([-inf,inf]);
            xticks(round(unique(average.x{1,1}(rows))));
            subplot(6,1,2); hold on; % wave 2
            w2 = errorbar(round(average.x{1,cols}(rows)), average.w2{1,cols}(rows),average.w2_std{1,cols}(rows),'Marker',shapes(2,:),'LineStyle','-', 'linew', 2, 'Color', colors(cols+1,:), 'MarkerSize', 8, 'MarkerFaceColor', colors(cols+1,:), 'MarkerEdgeColor', colors(cols+1,:));
            w2_fit = fillmissing(flip(average.w2{1,cols}(rows)),'linear','SamplePoints',flip(round(average.x{1,cols}(rows)))); w2_fit = flip(w2_fit);
            plot(round(average.x{1,cols}(rows)), w2_fit,'LineStyle','-', 'linew', 2, 'Color', colors(cols+1,:),'HandleVisibility','off'); grid on;
            plot(round(average.x{1,cols}(rows)), zeros(size(average.x{1,cols}(rows))),'LineStyle','--', 'linew', 2, 'Color', 'k','HandleVisibility','off');
            xticks(round(unique(average.x{1,1}(rows))));
            subtitle('Wave II'); xlim([-inf,inf]);
            subplot(6,1,3); hold on; % wave 3
            w3 = errorbar(round(average.x{1,cols}(rows)), average.w3{1,cols}(rows),average.w3_std{1,cols}(rows),'Marker',shapes(3,:),'LineStyle','-', 'linew', 2, 'Color', colors(cols+1,:), 'MarkerSize', 8, 'MarkerFaceColor', colors(cols+1,:), 'MarkerEdgeColor', colors(cols+1,:));
            w3_fit = fillmissing(flip(average.w3{1,cols}(rows)),'linear','SamplePoints',flip(round(average.x{1,cols}(rows)))); w3_fit = flip(w3_fit);
            plot(round(average.x{1,cols}(rows)), w3_fit,'LineStyle','-', 'linew', 2, 'Color', colors(cols+1,:),'HandleVisibility','off');
            plot(round(average.x{1,cols}(rows)), zeros(size(average.x{1,cols}(rows))),'LineStyle','--', 'linew', 2, 'Color', 'k','HandleVisibility','off');
            ylabel(y_units, 'FontWeight', 'bold'); grid on;
            xticks(round(unique(average.x{1,1}(rows))));
            subtitle('Wave III'); xlim([-inf,inf]);
            subplot(6,1,4); hold on; % wave 4
            w4 = errorbar(round(average.x{1,cols}(rows)), average.w4{1,cols}(rows),average.w4_std{1,cols}(rows),'Marker',shapes(4,:),'LineStyle','-', 'linew', 2, 'Color', colors(cols+1,:), 'MarkerSize', 8, 'MarkerFaceColor', colors(cols+1,:), 'MarkerEdgeColor', colors(cols+1,:));
            w4_fit = fillmissing(flip(average.w4{1,cols}(rows)),'linear','SamplePoints',flip(round(average.x{1,cols}(rows)))); w4_fit = flip(w4_fit);
            plot(round(average.x{1,cols}(rows)), w4_fit,'LineStyle','-', 'linew', 2, 'Color', colors(cols+1,:),'HandleVisibility','off'); grid on;
            plot(round(average.x{1,cols}(rows)), zeros(size(average.x{1,cols}(rows))),'LineStyle','--', 'linew', 2, 'Color', 'k','HandleVisibility','off');
            xticks(round(unique(average.x{1,1}(rows))));
            subtitle('Wave IV'); xlim([-inf,inf]);
            subplot(6,1,5); hold on;% wave 5
            w5 = errorbar(round(average.x{1,cols}(rows)), average.w5{1,cols}(rows),average.w5_std{1,cols}(rows),'Marker',shapes(5,:),'LineStyle','-', 'linew', 2, 'Color', colors(cols+1,:), 'MarkerSize', 8, 'MarkerFaceColor', colors(cols+1,:), 'MarkerEdgeColor', colors(cols+1,:));
            w5_fit = fillmissing(flip(average.w5{1,cols}(rows)),'linear','SamplePoints',flip(round(average.x{1,cols}(rows)))); w5_fit = flip(w5_fit);
            plot(round(average.x{1,cols}(rows)), w5_fit,'LineStyle','-', 'linew', 2, 'Color', colors(cols+1,:),'HandleVisibility','off');
            plot(round(average.x{1,cols}(rows)), zeros(size(average.x{1,cols}(rows))),'LineStyle','--', 'linew', 2, 'Color', 'k','HandleVisibility','off');
            xticks(round(unique(average.x{1,1}(rows)))); grid on;
            subtitle('Wave I/V'); xlim([-inf,inf]);
            subplot(6,1,6); hold on;% wave 1/5 ratio
            w1and5 = errorbar(round(average.x{1,cols}(rows)), average.w1and5{1,cols}(rows),average.w1and5_std{1,cols}(rows),'Marker',shapes(1,:),'LineStyle','-', 'linew', 2, 'Color', colors(cols+1,:), 'MarkerSize', 8, 'MarkerFaceColor', colors(cols+1,:), 'MarkerEdgeColor', colors(cols+1,:));
            w1and5_fit = fillmissing(flip(average.w1and5{1,cols}(rows)),'linear','SamplePoints',flip(round(average.x{1,cols}(rows)))); w1and5_fit = flip(w1and5_fit);
            plot(round(average.x{1,cols}(rows)), w1and5_fit,'LineStyle','-', 'linew', 2, 'Color', colors(cols+1,:),'HandleVisibility','off');
            plot(round(average.x{1,cols}(rows)), zeros(size(average.x{1,cols}(rows))),'LineStyle','--', 'linew', 2, 'Color', 'k','HandleVisibility','off');
            xticks(round(unique(average.x{1,1}(rows))));
            xlabel(x_units, 'FontWeight', 'bold'); hold off; grid on;
            subtitle('Wave I/V'); xlim([-inf,inf]);
            legend_string{1,cols} = sprintf('%s (n = %s)',cell2mat(Conds2Run(cols+1)),mat2str(sum(idx(:,cols+1))));
            if cols == length(average.w1)
                lgd = legend(legend_string,'Location','north','Orientation','horizontal','FontSize',8);
                lgd.Box = 'off';
                lgd.Position = [0.5,0.04,0,0];
            end
        end
    end
end
%% Export
cd(outpath);
print(figure(counter),[filename,'_figure'],'-dpng','-r300');
end