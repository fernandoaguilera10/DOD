function plot_avg_abr(average,plot_type,colors,shapes,idx,conds_idx,Chins2Run,Conds2Run,all_Conds2Run,outpath,filename,counter,ylimits_threshold,idx_plot_relative,peak_analysis)
str_plot_relative = strsplit(Conds2Run{idx_plot_relative}, filesep);
legend_string = [];
rows = 1:4; % plot highest 4 levels [90 80 70 60] dB SPL for ABR peaks
%% Plot ALL
if isempty(idx_plot_relative)
    %% Thresholds
    if strcmp(plot_type,'Thresholds')
        y_units = 'Threshold (dB SPL)';
        figure(counter); hold on;
        % Box Plot
        freq_labels = {'Click', '0.5 kHz', '1 kHz', '2 kHz', '4 kHz', '8 kHz'};
        num_freqs = length(freq_labels);
        [num_subjects, num_timepoints] = size(average.all_y);
        thresholds = [];
        frequencies = [];
        timepoints = [];
        for subj = 1:num_subjects
            for tpt = 1:num_timepoints
                data = average.all_y{subj, tpt};
                if isempty(data)
                    data = NaN(1, num_freqs);     % handle empty entries
                end
                thresholds = [thresholds, data];                  % concat thresholds
                frequencies = [frequencies, freq_labels(1:num_freqs)];         % frequency indices
                timepoints = [timepoints, repmat(tpt, 1, num_freqs)];  % group/timepoint indices
            end
        end
        thresholds = thresholds(:);
        frequencies = frequencies(:);
        timepoints = timepoints(:);
        %daviolinplot(thresholds, 'color', colors, 'violin', 'full', 'scatter', 2,'groups',timepoints);
        boxplot(thresholds, {frequencies, timepoints},'factorseparator',1,'labelverbosity', 'minor','ColorGroup',timepoints,'Symbol','*');
        % Thickens vertical separator line
        all_lines = findobj(gca, 'Type', 'Line');
        for i = 1:length(all_lines)
            xdata = get(all_lines(i), 'XData');
            ydata = get(all_lines(i), 'YData');
            if length(xdata) >= 2 && length(ydata) >= 2
                if abs(xdata(2) - xdata(1)) < 0.01 && (ydata(2) - ydata(1)) > range(ylim)*0.9
                    set(all_lines(i), 'LineWidth', 2, 'LineStyle','-','Color','k');  % Thicken factor separator line
                end
            end
        end
        % Flip handles to match left-to-right plotting order
        boxHandles = flipud(findobj(gca, 'Tag', 'Box'));
        medianHandles = flipud(findobj(gca, 'Tag', 'Median'));
        upperWhiskerHandles = flipud(findobj(gca, 'Tag', 'Upper Whisker'));
        lowerWhiskerHandles = flipud(findobj(gca, 'Tag', 'Lower Whisker'));
        capHandles = flipud(findobj(gca, 'Tag', 'Upper Adjacent Value')); % for caps
        capHandles2 = flipud(findobj(gca, 'Tag', 'Lower Adjacent Value')); % for lower caps
        allOutliers = flipud(findobj(gca, 'Tag', 'Outliers'));
        unique_timepoints = unique(timepoints);
        num_timepoints = length(unique_timepoints);
        % Color everything by timepoint
        for i = 1:length(boxHandles)
            timepoint_idx = mod(i-1, num_timepoints) + 1;
            thisColor = colors(timepoint_idx, :);
            x = get(boxHandles(i), 'XData');
            y = get(boxHandles(i), 'YData');
            patch(x([1 2 3 4 1]), y([1 2 3 4 1]), thisColor, ...
                'FaceAlpha', 0.5, 'EdgeColor', 'none');
            set(boxHandles(i), 'Color', thisColor, 'LineWidth', 1.5);
            set(medianHandles(i), 'Color', thisColor, 'LineWidth', 1.5);
            set(upperWhiskerHandles(i), 'Color', thisColor, 'LineWidth', 1.5);
            set(lowerWhiskerHandles(i), 'Color', thisColor, 'LineWidth', 1.5);
            set(capHandles(i), 'Color', thisColor, 'LineWidth', 1.5);
            set(capHandles2(i), 'Color', thisColor, 'LineWidth', 1.5);
            set(gca, 'XTick', []);
            set(allOutliers(i), 'MarkerEdgeColor', thisColor, 'LineWidth', 1.5);
        end
        hold on;
        for i = 1:num_timepoints
            plot(NaN, NaN, 's', 'MarkerFaceColor', colors(i,:), ...
                'MarkerEdgeColor', 'k', 'MarkerSize', 8);
        end
        legend(all_Conds2Run,'Location','southoutside','Orientation','horizontal');
        ylabel(y_units, 'FontWeight', 'bold');
        title(sprintf('ABR Thresholds'),'FontWeight','bold');
        set(gca,'FontSize',15);
        legend boxoff; hold off; box off;
        group_ticks = (1:num_freqs) * num_timepoints - (num_timepoints-1)/2;
        set(gca, 'XTick', group_ticks);
        set(gca, 'XTickLabel', freq_labels);
        if ~isempty(ylimits_threshold)
            ylim(ylimits_threshold);
        end
        average.subjects = Chins2Run;
        average.conditions = Conds2Run;
        average.analysis_log = idx;
        % Export
        cd(outpath);
        save(filename,'average');
        print(figure(counter),[filename,'_figure'],'-dpng','-r300');
%% Peaks
    elseif strcmp(plot_type,'Peaks')
        x_units = 'Sound Level (dB SPL)';
        if strcmp(peak_analysis,'Amplitude')
            y_units = 'Peak-to-Peak Amplitude (\muV)';
            title_str = sprintf('ABR Peak-to-Peak Amplitude');
        elseif strcmp(peak_analysis,'Latency')
            y_units = 'Time (ms)';
            title_str = sprintf('ABR Absolute Peak Latency');
        end
        for cols = 1:length(average.w1)
            figure(counter); hold on; % wave 1
            w1 = errorbar(round(average.x{1,cols}(rows)), average.w1{1,cols}(rows),average.w1_std{1,cols}(rows),'Marker',shapes(1,:),'LineStyle','-', 'linew', 2, 'Color', colors(cols,:), 'MarkerSize', 12, 'MarkerFaceColor', colors(cols,:), 'MarkerEdgeColor', colors(cols,:),'HandleVisibility','off');
            w1_fit = fillmissing(flip(average.w1{1,cols}(rows)),'linear','SamplePoints',flip(round(average.x{1,cols}(rows)))); w1_fit = flip(w1_fit);
            plot(round(average.x{1,cols}(rows)),w1_fit,'Marker',shapes(1,:),'LineStyle','-', 'linew', 2, 'Color', colors(cols,:), 'MarkerSize', 12, 'MarkerFaceColor', colors(cols,:), 'MarkerEdgeColor', colors(cols,:));
            subtitle('Wave I'); xlim([-inf,inf]); grid on;
            ylabel(y_units, 'FontWeight', 'bold');
            xticks(round(unique(average.x{1,1}(rows))));
            xlabel(x_units, 'FontWeight', 'bold'); hold off;
            legend_string{1,cols} = sprintf('%s (n = %s)',cell2mat(Conds2Run(cols)),mat2str(sum(idx(:,conds_idx(cols)))));
            legend(legend_string,'Location','southoutside','Orientation','horizontal');
            legend boxoff; set(gca,'FontSize',15); title(title_str, 'FontSize', 16);

            figure(counter+1); hold on; % wave 2
            w2 = errorbar(round(average.x{1,cols}(rows)), average.w2{1,cols}(rows),average.w2_std{1,cols}(rows),'Marker',shapes(2,:),'LineStyle','-', 'linew', 2, 'Color', colors(cols,:), 'MarkerSize', 12, 'MarkerFaceColor', colors(cols,:), 'MarkerEdgeColor', colors(cols,:),'HandleVisibility','off');
            w2_fit = fillmissing(flip(average.w2{1,cols}(rows)),'linear','SamplePoints',flip(round(average.x{1,cols}(rows)))); w2_fit = flip(w2_fit);
            plot(round(average.x{1,cols}(rows)), w2_fit,'Marker',shapes(2,:),'LineStyle','-', 'linew', 2, 'Color', colors(cols,:), 'MarkerSize', 12, 'MarkerFaceColor', colors(cols,:), 'MarkerEdgeColor', colors(cols,:)); grid on;
            xticks(round(unique(average.x{1,1}(rows))));
            subtitle('Wave II'); xlim([-inf,inf]);
            ylabel(y_units, 'FontWeight', 'bold'); grid on;
            xlabel(x_units, 'FontWeight', 'bold'); hold off;
            legend(legend_string,'Location','southoutside','Orientation','horizontal');
            legend boxoff; set(gca,'FontSize',15); title(title_str, 'FontSize', 16);

            figure(counter+2); hold on; % wave 3
            w3 = errorbar(round(average.x{1,cols}(rows)), average.w3{1,cols}(rows),average.w3_std{1,cols}(rows),'Marker',shapes(3,:),'LineStyle','-', 'linew', 2, 'Color', colors(cols,:), 'MarkerSize', 12, 'MarkerFaceColor', colors(cols,:), 'MarkerEdgeColor', colors(cols,:),'HandleVisibility','off');
            w3_fit = fillmissing(flip(average.w3{1,cols}(rows)),'linear','SamplePoints',flip(round(average.x{1,cols}(rows)))); w3_fit = flip(w3_fit);
            plot(round(average.x{1,cols}(rows)), w3_fit,'Marker',shapes(3,:),'LineStyle','-', 'linew', 2, 'Color', colors(cols,:), 'MarkerSize', 12, 'MarkerFaceColor', colors(cols,:), 'MarkerEdgeColor', colors(cols,:));
            ylabel(y_units, 'FontWeight', 'bold'); grid on;
            xticks(round(unique(average.x{1,1}(rows))));
            subtitle('Wave III'); xlim([-inf,inf]);
            ylabel(y_units, 'FontWeight', 'bold'); grid on;
            xlabel(x_units, 'FontWeight', 'bold'); hold off;
            legend(legend_string,'Location','southoutside','Orientation','horizontal');
            legend boxoff; set(gca,'FontSize',15); title(title_str, 'FontSize', 16);

            figure(counter+3); hold on; % wave 4
            w4 = errorbar(round(average.x{1,cols}(rows)), average.w4{1,cols}(rows),average.w4_std{1,cols}(rows),'Marker',shapes(4,:),'LineStyle','-', 'linew', 2, 'Color', colors(cols,:), 'MarkerSize', 12, 'MarkerFaceColor', colors(cols,:), 'MarkerEdgeColor', colors(cols,:),'HandleVisibility','off');
            w4_fit = fillmissing(flip(average.w4{1,cols}(rows)),'linear','SamplePoints',flip(round(average.x{1,cols}(rows)))); w4_fit = flip(w4_fit);
            plot(round(average.x{1,cols}(rows)), w4_fit,'Marker',shapes(4,:),'LineStyle','-', 'linew', 2, 'Color', colors(cols,:), 'MarkerSize', 12, 'MarkerFaceColor', colors(cols,:), 'MarkerEdgeColor', colors(cols,:)); grid on;
            xticks(round(unique(average.x{1,1}(rows))));
            subtitle('Wave IV'); xlim([-inf,inf]);
            ylabel(y_units, 'FontWeight', 'bold'); grid on;
            xticks(round(unique(average.x{1,1}(rows))));
            ylabel(y_units, 'FontWeight', 'bold'); grid on;
            xlabel(x_units, 'FontWeight', 'bold'); hold off;
            legend(legend_string,'Location','southoutside','Orientation','horizontal');
            legend boxoff; set(gca,'FontSize',15); title(title_str, 'FontSize', 16);

            figure(counter+4); hold on;% wave 5
            w5 = errorbar(round(average.x{1,cols}(rows)), average.w5{1,cols}(rows),average.w5_std{1,cols}(rows),'Marker',shapes(5,:),'LineStyle','-', 'linew', 2, 'Color', colors(cols,:), 'MarkerSize', 12, 'MarkerFaceColor', colors(cols,:), 'MarkerEdgeColor', colors(cols,:),'HandleVisibility','off');
            w5_fit = fillmissing(flip(average.w5{1,cols}(rows)),'linear','SamplePoints',flip(round(average.x{1,cols}(rows)))); w5_fit = flip(w5_fit);
            plot(round(average.x{1,cols}(rows)), w5_fit,'Marker',shapes(5,:),'LineStyle','-', 'linew', 2, 'Color', colors(cols,:), 'MarkerSize', 12, 'MarkerFaceColor', colors(cols,:), 'MarkerEdgeColor', colors(cols,:));
            xticks(round(unique(average.x{1,1}(rows)))); hold off; grid on;
            subtitle('Wave V'); xlim([-inf,inf]);
            ylabel(y_units, 'FontWeight', 'bold'); grid on;
            xticks(round(unique(average.x{1,1}(rows))));
            xlabel(x_units, 'FontWeight', 'bold'); hold off;
            ylabel(y_units, 'FontWeight', 'bold'); grid on;
            legend(legend_string,'Location','southoutside','Orientation','horizontal');
            legend boxoff; set(gca,'FontSize',15); title(title_str, 'FontSize', 16);

            figure(counter+5); hold on;% wave 1/5 ratio
            w1and5 = errorbar(round(average.x{1,cols}(rows)), average.w1and5{1,cols}(rows),average.w1and5_std{1,cols}(rows),'Marker',shapes(6,:),'LineStyle','-', 'linew', 2, 'Color', colors(cols,:), 'MarkerSize', 12, 'MarkerFaceColor', colors(cols,:), 'MarkerEdgeColor', colors(cols,:),'HandleVisibility','off');
            w1and5_fit = fillmissing(flip(average.w1and5{1,cols}(rows)),'linear','SamplePoints',flip(round(average.x{1,cols}(rows)))); w1and5_fit = flip(w1and5_fit);
            plot(round(average.x{1,cols}(rows)), w1and5_fit,'Marker',shapes(6,:),'LineStyle','-', 'linew', 2, 'Color', colors(cols,:), 'MarkerSize', 12, 'MarkerFaceColor', colors(cols,:), 'MarkerEdgeColor', colors(cols,:));
            xticks(round(unique(average.x{1,1}(rows))));
            xlabel(x_units, 'FontWeight', 'bold'); hold off; grid on;
            ylabel('Wave I/V Ratio', 'FontWeight', 'bold');
            subtitle('Wave I/V'); xlim([-inf,inf]);
            legend(legend_string,'Location','southoutside','Orientation','horizontal');
            legend boxoff; set(gca,'FontSize',15); title(title_str, 'FontSize', 16);
        end
        average.subjects = Chins2Run;
        average.conditions = Conds2Run;
        average.analysis_log = idx;
        % Export
        cd(outpath);
        save(filename,'average');
        print(figure(counter),[filename,'_w1_figure'],'-dpng','-r300');
        print(figure(counter+1),[filename,'_w2_figure'],'-dpng','-r300');
        print(figure(counter+2),[filename,'_w3_figure'],'-dpng','-r300');
        print(figure(counter+3),[filename,'_w4_figure'],'-dpng','-r300');
        print(figure(counter+4),[filename,'_w5_figure'],'-dpng','-r300');
        print(figure(counter+5),[filename,'_w1and5_figure'],'-dpng','-r300');
    end
end
%% Plot relative to Baseline
if ~isempty(idx_plot_relative)  
    %% Thresholds
    if strcmp(plot_type,'Thresholds')
        y_units = sprintf('Threshold Shift (re. %s)',str_plot_relative{2});
        figure(counter); hold on;
        % Box Plot
        freq_labels = {'Click', '0.5 kHz', '1 kHz', '2 kHz', '4 kHz', '8 kHz'};
        num_freqs = length(freq_labels);
        [num_subjects, num_timepoints] = size(average.all_y);
        thresholds = [];
        frequencies = [];
        timepoints = [];
        for subj = 1:num_subjects
            for tpt = 1:num_timepoints
                data = average.all_y{subj, tpt};
                if isempty(data)
                    data = NaN(1, num_freqs);     % handle empty entries
                end
                thresholds = [thresholds, data];                  % concat thresholds
                frequencies = [frequencies, freq_labels(1:num_freqs)];         % frequency indices
                timepoints = [timepoints, repmat(tpt, 1, num_freqs)];  % group/timepoint indices
            end
        end
        thresholds = thresholds(:);
        frequencies = frequencies(:);
        timepoints = timepoints(:);
        %daviolinplot(thresholds, 'color', colors, 'violin', 'full', 'scatter', 2,'groups',timepoints);
        boxplot(thresholds, {frequencies, timepoints},'factorseparator',1,'labelverbosity', 'minor','ColorGroup',timepoints,'Symbol','*');
        % Thickens vertical separator line
        all_lines = findobj(gca, 'Type', 'Line');
        for i = 1:length(all_lines)
            xdata = get(all_lines(i), 'XData');
            ydata = get(all_lines(i), 'YData');
            if length(xdata) >= 2 && length(ydata) >= 2
                if abs(xdata(2) - xdata(1)) < 0.01 && (ydata(2) - ydata(1)) > range(ylim)*0.9
                    set(all_lines(i), 'LineWidth', 2, 'LineStyle','-','Color','k');  % Thicken factor separator line
                end
            end
        end
        % Flip handles to match left-to-right plotting order
        boxHandles = flipud(findobj(gca, 'Tag', 'Box'));
        medianHandles = flipud(findobj(gca, 'Tag', 'Median'));
        upperWhiskerHandles = flipud(findobj(gca, 'Tag', 'Upper Whisker'));
        lowerWhiskerHandles = flipud(findobj(gca, 'Tag', 'Lower Whisker'));
        capHandles = flipud(findobj(gca, 'Tag', 'Upper Adjacent Value')); % for caps
        capHandles2 = flipud(findobj(gca, 'Tag', 'Lower Adjacent Value')); % for lower caps
        allOutliers = flipud(findobj(gca, 'Tag', 'Outliers'));
        unique_timepoints = unique(timepoints);
        num_timepoints = length(unique_timepoints);
        % Color everything by timepoint
        for i = 1:length(boxHandles)
            timepoint_idx = mod(i-1, num_timepoints) + 1;
            thisColor = colors(timepoint_idx+1, :);
            x = get(boxHandles(i), 'XData');
            y = get(boxHandles(i), 'YData');
            patch(x([1 2 3 4 1]), y([1 2 3 4 1]), thisColor, ...
                'FaceAlpha', 0.5, 'EdgeColor', 'none');
            set(boxHandles(i), 'Color', thisColor, 'LineWidth', 1.5);
            set(medianHandles(i), 'Color', thisColor, 'LineWidth', 1.5);
            set(upperWhiskerHandles(i), 'Color', thisColor, 'LineWidth', 1.5);
            set(lowerWhiskerHandles(i), 'Color', thisColor, 'LineWidth', 1.5);
            set(capHandles(i), 'Color', thisColor, 'LineWidth', 1.5);
            set(capHandles2(i), 'Color', thisColor, 'LineWidth', 1.5);
            set(gca, 'XTick', []);
            set(allOutliers(i), 'MarkerEdgeColor', thisColor, 'LineWidth', 1.5);
        end
        hold on;
        for i = 1:num_timepoints
            plot(NaN, NaN, 's', 'MarkerFaceColor', colors(i,:), ...
                'MarkerEdgeColor', 'k', 'MarkerSize', 8);
        end
        legend(all_Conds2Run(2:end),'Location','southoutside','Orientation','horizontal');
        ylabel(y_units, 'FontWeight', 'bold');
        title(sprintf('ABR Thresholds'),'FontWeight','bold');
        set(gca,'FontSize',15);
        legend boxoff; hold off; box off;
        group_ticks = (1:num_freqs) * num_timepoints - (num_timepoints-1)/2;
        set(gca, 'XTick', group_ticks);
        set(gca, 'XTickLabel', freq_labels);
        if ~isempty(ylimits_threshold)
            ylim(ylimits_threshold);
        end
        average.subjects = Chins2Run;
        average.conditions = Conds2Run;
        average.analysis_log = idx;
        % Export
        cd(outpath);
        save(filename,'average');
        print(figure(counter),[filename,'_figure'],'-dpng','-r300');
    elseif strcmp(plot_type,'Peaks')
        x_units = 'Sound Level (dB SPL)';
        if strcmp(peak_analysis,'Amplitude')
            y_units = sprintf('Peak-to-Peak Amplitude Shift (re. %s)',str_plot_relative{2});
            title_str = sprintf('ABR Peak-to-Peak Amplitude');
        elseif strcmp(peak_analysis,'Latency')
            y_units = sprintf('Latency Shift (re. %s)',str_plot_relative{2});
            title_str = sprintf('ABR Absolute Peak Latency');
        end
        for cols = 1:length(average.w1)
            figure(counter); hold on; % wave 1
            w1 = errorbar(round(average.x{1,cols}(rows)), average.w1{1,cols}(rows),average.w1_std{1,cols}(rows),'Marker',shapes(1,:),'LineStyle','-', 'linew', 2, 'Color', colors(cols+1,:), 'MarkerSize', 12, 'MarkerFaceColor', colors(cols+1,:), 'MarkerEdgeColor', colors(cols+1,:),'HandleVisibility','off');
            w1_fit = fillmissing(flip(average.w1{1,cols}(rows)),'linear','SamplePoints',flip(round(average.x{1,cols}(rows)))); w1_fit = flip(w1_fit);
            plot(round(average.x{1,cols}(rows)), w1_fit,'Marker',shapes(1,:),'LineStyle','-', 'linew', 2, 'Color', colors(cols+1,:), 'MarkerSize', 12, 'MarkerFaceColor', colors(cols+1,:), 'MarkerEdgeColor', colors(cols+1,:));
            plot(round(average.x{1,cols}(rows)), zeros(size(average.x{1,cols}(rows))),'LineStyle','--', 'linew', 2, 'Color', 'k','HandleVisibility','off');
            subtitle('Wave I'); xlim([-inf,inf]); grid on;
            ylabel(y_units, 'FontWeight', 'bold');
            xticks(round(unique(average.x{1,1}(rows))));
            xlabel(x_units, 'FontWeight', 'bold'); hold off;
            legend_string{1,cols} = sprintf('%s (n = %s)',cell2mat(Conds2Run(cols+1)),mat2str(sum(idx(:,conds_idx(cols+1)))));
            legend(legend_string,'Location','southoutside','Orientation','horizontal');
            legend boxoff; set(gca,'FontSize',15); title(title_str, 'FontSize', 16);


            figure(counter+1); hold on; % wave 2
            w2 = errorbar(round(average.x{1,cols}(rows)), average.w2{1,cols}(rows),average.w2_std{1,cols}(rows),'Marker',shapes(2,:),'LineStyle','-', 'linew', 2, 'Color', colors(cols+1,:), 'MarkerSize', 12, 'MarkerFaceColor', colors(cols+1,:), 'MarkerEdgeColor', colors(cols+1,:),'HandleVisibility','off');
            w2_fit = fillmissing(flip(average.w2{1,cols}(rows)),'linear','SamplePoints',flip(round(average.x{1,cols}(rows)))); w2_fit = flip(w2_fit);
            plot(round(average.x{1,cols}(rows)), w2_fit,'Marker',shapes(2,:),'LineStyle','-', 'linew', 2, 'Color', colors(cols+1,:), 'MarkerSize', 12, 'MarkerFaceColor', colors(cols+1,:), 'MarkerEdgeColor', colors(cols+1,:)); grid on;
            plot(round(average.x{1,cols}(rows)), zeros(size(average.x{1,cols}(rows))),'LineStyle','--', 'linew', 2, 'Color', 'k','HandleVisibility','off');
            xticks(round(unique(average.x{1,1}(rows))));
            subtitle('Wave II'); xlim([-inf,inf]);
            ylabel(y_units, 'FontWeight', 'bold'); grid on;
            xlabel(x_units, 'FontWeight', 'bold'); hold off;
            legend(legend_string,'Location','southoutside','Orientation','horizontal');
            legend boxoff; set(gca,'FontSize',15); title(title_str, 'FontSize', 16);


            figure(counter+2); hold on; % wave 3
            w3 = errorbar(round(average.x{1,cols}(rows)), average.w3{1,cols}(rows),average.w3_std{1,cols}(rows),'Marker',shapes(3,:),'LineStyle','-', 'linew', 2, 'Color', colors(cols+1,:), 'MarkerSize', 12, 'MarkerFaceColor', colors(cols+1,:), 'MarkerEdgeColor', colors(cols+1,:),'HandleVisibility','off');
            w3_fit = fillmissing(flip(average.w3{1,cols}(rows)),'linear','SamplePoints',flip(round(average.x{1,cols}(rows)))); w3_fit = flip(w3_fit);
            plot(round(average.x{1,cols}(rows)), w3_fit,'Marker',shapes(3,:),'LineStyle','-', 'linew', 2, 'Color', colors(cols+1,:), 'MarkerSize', 12, 'MarkerFaceColor', colors(cols+1,:), 'MarkerEdgeColor', colors(cols+1,:));
            plot(round(average.x{1,cols}(rows)), zeros(size(average.x{1,cols}(rows))),'LineStyle','--', 'linew', 2, 'Color', 'k','HandleVisibility','off');
            ylabel(y_units, 'FontWeight', 'bold'); grid on;
            xticks(round(unique(average.x{1,1}(rows))));
            subtitle('Wave III'); xlim([-inf,inf]);
            ylabel(y_units, 'FontWeight', 'bold'); grid on;
            xlabel(x_units, 'FontWeight', 'bold'); hold off;
            legend(legend_string,'Location','southoutside','Orientation','horizontal');
            legend boxoff; set(gca,'FontSize',15); title(title_str, 'FontSize', 16);


            figure(counter+3); hold on; % wave 4
            w4 = errorbar(round(average.x{1,cols}(rows)), average.w4{1,cols}(rows),average.w4_std{1,cols}(rows),'Marker',shapes(4,:),'LineStyle','-', 'linew', 2, 'Color', colors(cols+1,:), 'MarkerSize', 12, 'MarkerFaceColor', colors(cols+1,:), 'MarkerEdgeColor', colors(cols+1,:),'HandleVisibility','off');
            w4_fit = fillmissing(flip(average.w4{1,cols}(rows)),'linear','SamplePoints',flip(round(average.x{1,cols}(rows)))); w4_fit = flip(w4_fit);
            plot(round(average.x{1,cols}(rows)), w4_fit,'Marker',shapes(4,:),'LineStyle','-', 'linew', 2, 'Color', colors(cols+1,:), 'MarkerSize', 12, 'MarkerFaceColor', colors(cols+1,:), 'MarkerEdgeColor', colors(cols+1,:)); grid on;
            plot(round(average.x{1,cols}(rows)), zeros(size(average.x{1,cols}(rows))),'LineStyle','--', 'linew', 2, 'Color', 'k','HandleVisibility','off');
            xticks(round(unique(average.x{1,1}(rows))));
            subtitle('Wave IV'); xlim([-inf,inf]);
            ylabel(y_units, 'FontWeight', 'bold'); grid on;
            xticks(round(unique(average.x{1,1}(rows))));
            ylabel(y_units, 'FontWeight', 'bold'); grid on;
            xlabel(x_units, 'FontWeight', 'bold'); hold off;
            legend(legend_string,'Location','southoutside','Orientation','horizontal');
            legend boxoff; set(gca,'FontSize',15); title(title_str, 'FontSize', 16);


            figure(counter+4); hold on;% wave 5
            w5 = errorbar(round(average.x{1,cols}(rows)), average.w5{1,cols}(rows),average.w5_std{1,cols}(rows),'Marker',shapes(5,:),'LineStyle','-', 'linew', 2, 'Color', colors(cols+1,:), 'MarkerSize', 12, 'MarkerFaceColor', colors(cols+1,:), 'MarkerEdgeColor', colors(cols+1,:),'HandleVisibility','off');
            w5_fit = fillmissing(flip(average.w5{1,cols}(rows)),'linear','SamplePoints',flip(round(average.x{1,cols}(rows)))); w5_fit = flip(w5_fit);
            plot(round(average.x{1,cols}(rows)), w5_fit,'Marker',shapes(5,:),'LineStyle','-', 'linew', 2, 'Color', colors(cols+1,:), 'MarkerSize', 12, 'MarkerFaceColor', colors(cols+1,:), 'MarkerEdgeColor', colors(cols+1,:));
            plot(round(average.x{1,cols}(rows)), zeros(size(average.x{1,cols}(rows))),'LineStyle','--', 'linew', 2, 'Color', 'k','HandleVisibility','off');
            xticks(round(unique(average.x{1,1}(rows)))); hold off; grid on;
            subtitle('Wave V'); xlim([-inf,inf]);
            ylabel(y_units, 'FontWeight', 'bold'); grid on;
            xticks(round(unique(average.x{1,1}(rows))));
            xlabel(x_units, 'FontWeight', 'bold'); hold off;
            ylabel(y_units, 'FontWeight', 'bold'); grid on;
            legend(legend_string,'Location','southoutside','Orientation','horizontal');
            legend boxoff; set(gca,'FontSize',15); title(title_str, 'FontSize', 16);


            figure(counter+5); hold on;% wave 1/5 ratio
            w1and5 = errorbar(round(average.x{1,cols}(rows)), average.w1and5{1,cols}(rows),average.w1and5_std{1,cols}(rows),'Marker',shapes(1,:),'LineStyle','-', 'linew', 2, 'Color', colors(cols+1,:), 'MarkerSize', 12, 'MarkerFaceColor', colors(cols+1,:), 'MarkerEdgeColor', colors(cols+1,:),'HandleVisibility','off');
            w1and5_fit = fillmissing(flip(average.w1and5{1,cols}(rows)),'linear','SamplePoints',flip(round(average.x{1,cols}(rows)))); w1and5_fit = flip(w1and5_fit);
            plot(round(average.x{1,cols}(rows)), w1and5_fit,'Marker',shapes(1,:),'LineStyle','-', 'linew', 2, 'Color', colors(cols+1,:), 'MarkerSize', 12, 'MarkerFaceColor', colors(cols+1,:), 'MarkerEdgeColor', colors(cols+1,:));
            plot(round(average.x{1,cols}(rows)), zeros(size(average.x{1,cols}(rows))),'LineStyle','--', 'linew', 2, 'Color', 'k','HandleVisibility','off');
            xticks(round(unique(average.x{1,1}(rows))));
            xlabel(x_units, 'FontWeight', 'bold'); hold off; grid on;
            ylabel('Wave I/V Ratio', 'FontWeight', 'bold');
            subtitle('Wave I/V'); xlim([-inf,inf]);
            legend(legend_string,'Location','southoutside','Orientation','horizontal');
            legend boxoff; set(gca,'FontSize',15); title(title_str, 'FontSize', 16);
        end
        average.subjects = Chins2Run;
        average.conditions = Conds2Run;
        average.analysis_log = idx;
        % Export
        cd(outpath);
        save(filename,'average');
        print(figure(counter),[filename,'_w1_figure'],'-dpng','-r300');
        print(figure(counter+1),[filename,'_w2_figure'],'-dpng','-r300');
        print(figure(counter+2),[filename,'_w3_figure'],'-dpng','-r300');
        print(figure(counter+3),[filename,'_w4_figure'],'-dpng','-r300');
        print(figure(counter+4),[filename,'_w5_figure'],'-dpng','-r300');
        print(figure(counter+5),[filename,'_w1and5_figure'],'-dpng','-r300');
    end
end
end