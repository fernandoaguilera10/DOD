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
            y_units_ratio = 'High/Low Ratio';
            row_idx{cols} = find(~cellfun('isempty', average.peaks_locs(:, cols)));
            %% Average PLV Spectrum
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
    %% Average PLV at Low and High Freqs
    figure(counter+1); hold on;
    freq_labels = {'Low Harmonics (1-3)','High Harmonics (4+)'};
    num_freqs = length(freq_labels);
    [num_subjects, num_timepoints] = size(average.all_low_high_peaks);
    peaks = [];
    frequencies = [];
    timepoints = [];
    for subj = 1:num_subjects
        for tpt = 1:num_timepoints
            data = average.all_low_high_peaks{subj, tpt};
            if isempty(data)
                data = NaN(1, num_freqs);     % handle empty entries
            end
            peaks = [peaks, data];                  % concat thresholds
            frequencies = [frequencies, freq_labels(1:num_freqs)];         % frequency indices
            timepoints = [timepoints, repmat(tpt, 1, num_freqs)];  % group/timepoint indices
        end
    end
    peaks = peaks(:);
    frequencies = frequencies(:);
    timepoints = timepoints(:);
    boxplot(peaks, {frequencies, timepoints},'factorseparator',1,'labelverbosity', 'minor','ColorGroup',timepoints,'Symbol','*');
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
    ylabel(y_units_amp, 'FontWeight', 'bold');
    title(sprintf('EFR Harmonics (%s) | %.0f dB SPL',title_str,level_spl),'FontWeight','bold');
    set(gca,'FontSize',15);
    legend boxoff; hold off; box off;
    group_ticks = (1:num_freqs) * num_timepoints - (num_timepoints-1)/2;
    set(gca, 'XTick', group_ticks);
    set(gca, 'XTickLabel', freq_labels);
    %% Average PLV Ratio
    figure(counter+2); hold on;
    num_freqs = 1;
    [num_subjects, num_timepoints] = size(average.all_ratio);
    peaks = [];
    frequencies = [];
    timepoints = [];
    for subj = 1:num_subjects
        for tpt = 1:num_timepoints
            data = average.all_ratio{subj, tpt};
            if isempty(data)
                data = NaN(1, num_freqs);     % handle empty entries
            end
            peaks = [peaks, data];                  % concat thresholds
            frequencies = [frequencies, freq_labels(1:num_freqs)];         % frequency indices
            timepoints = [timepoints, repmat(tpt, 1, num_freqs)];  % group/timepoint indices
        end
    end
    peaks = peaks(:);
    frequencies = frequencies(:);
    timepoints = timepoints(:);
    boxplot(peaks, {frequencies, timepoints},'factorseparator',1,'labelverbosity', 'minor','ColorGroup',timepoints,'Symbol','*');
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
    ylabel(y_units_amp, 'FontWeight', 'bold');
    title(sprintf('EFR Ratio (%s) | %.0f dB SPL',title_str,level_spl),'FontWeight','bold');
    set(gca,'FontSize',15);
    legend boxoff; hold off; box off;
    ylabel(y_units_ratio, 'FontWeight', 'bold');
end
%% Plot relative to Baseline
if ~isempty(idx_plot_relative)
    y_units_amp = sprintf('PLV (re. %s)',str_plot_relative{2});
    y_units_ratio = sprintf('High/Low Ratio (re. %s)',str_plot_relative{2});
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
    %% Average PLV at Low and High Freqs
    figure(counter+1); hold on;
    freq_labels = {'Low Harmonics (1-3)','High Harmonics (4+)'};
    num_freqs = length(freq_labels);
    [num_subjects, num_timepoints] = size(average.all_low_high_peaks);
    peaks = [];
    frequencies = [];
    timepoints = [];
    for subj = 1:num_subjects
        for tpt = 1:num_timepoints
            data = average.all_low_high_peaks{subj, tpt};
            if isempty(data)
                data = NaN(1, num_freqs);     % handle empty entries
            end
            peaks = [peaks, data];                  % concat thresholds
            frequencies = [frequencies, freq_labels(1:num_freqs)];         % frequency indices
            timepoints = [timepoints, repmat(tpt, 1, num_freqs)];  % group/timepoint indices
        end
    end
    peaks = peaks(:);
    frequencies = frequencies(:);
    timepoints = timepoints(:);
    boxplot(peaks, {frequencies, timepoints},'factorseparator',1,'labelverbosity', 'minor','ColorGroup',timepoints,'Symbol','*');
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
    ylabel(y_units_amp, 'FontWeight', 'bold');
    title(sprintf('EFR Harmonics (%s) | %.0f dB SPL',title_str,level_spl),'FontWeight','bold');
    set(gca,'FontSize',15);
    legend boxoff; hold off; box off;
    group_ticks = (1:num_freqs) * num_timepoints - (num_timepoints-1)/2;
    set(gca, 'XTick', group_ticks);
    set(gca, 'XTickLabel', freq_labels);
    %% Average PLV Ratio
    figure(counter+2); hold on;
    num_freqs = 1;
    [num_subjects, num_timepoints] = size(average.all_ratio);
    peaks = [];
    frequencies = [];
    timepoints = [];
    for subj = 1:num_subjects
        for tpt = 1:num_timepoints
            data = average.all_ratio{subj, tpt};
            if isempty(data)
                data = NaN(1, num_freqs);     % handle empty entries
            end
            peaks = [peaks, data];                  % concat thresholds
            frequencies = [frequencies, freq_labels(1:num_freqs)];         % frequency indices
            timepoints = [timepoints, repmat(tpt, 1, num_freqs)];  % group/timepoint indices
        end
    end
    peaks = peaks(:);
    frequencies = frequencies(:);
    timepoints = timepoints(:);
    boxplot(peaks, {frequencies, timepoints},'factorseparator',1,'labelverbosity', 'minor','ColorGroup',timepoints,'Symbol','*');
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
    ylabel(y_units_amp, 'FontWeight', 'bold');
    title(sprintf('EFR Ratio (%s) | %.0f dB SPL',title_str,level_spl),'FontWeight','bold');
    set(gca,'FontSize',15);
    legend boxoff; hold off; box off;
    ylabel(y_units_ratio, 'FontWeight', 'bold');
end
average.subjects = Chins2Run;
average.conditions = Conds2Run;
average.analysis_log = idx;
%% Export
cd(outpath);
save(filename,'average');
print(figure(counter),[filename,'_figure'],'-dpng','-r300');
print(figure(counter+1),[filename,'_PLVharmonics_figure'],'-dpng','-r300');
print(figure(counter+2),[filename,'_PLVratio_figure'],'-dpng','-r300');
end