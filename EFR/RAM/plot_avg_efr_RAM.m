function plot_avg_efr_RAM(average,plot_type,level_spl,colors,shapes,idx,conds_idx,Chins2Run,Conds2Run,all_Conds2Run,outpath,filename,counter,ylimits,idx_plot_relative,flag)
str_plot_relative = strsplit(all_Conds2Run{idx_plot_relative}, filesep);
legend_string = [];
x_units = 'Frequency (Hz)';
title_str = 'RAM 223 Hz';
if isempty(idx_plot_relative)
    for cols = 1:length(average.peaks)
        if ~isempty(average.peaks_locs{1,cols})
            row_idx{cols} = find(~cellfun('isempty', average.peaks_locs(:, cols)));
            %% Average PLV Spectrum
            figure(counter); hold on;
            errorbar(average.peaks_locs{1,cols},average.peaks{1,cols},average.peaks_std{1,cols},'Marker',shapes(cols,:),'LineStyle','-','linew', 3, 'MarkerSize', 15, 'Color', colors(cols,:), 'MarkerFaceColor', colors(cols,:), 'MarkerEdgeColor', colors(cols,:),'HandleVisibility','off');
            average.efr_fit = fillmissing(average.peaks{1,cols},'linear','SamplePoints',average.peaks_locs{row_idx{1,cols}(1),cols});
            plot(average.peaks_locs{1,cols},average.efr_fit,'Marker',shapes(cols,:),'LineStyle','-', 'linew', 3,'Color', colors(cols,:), 'MarkerSize', 15, 'MarkerFaceColor', colors(cols,:), 'MarkerEdgeColor', colors(cols,:));
            ylabel('PLV', 'FontWeight', 'bold');
            xlabel(x_units, 'FontWeight', 'bold');
            title(sprintf('EFR (%s) | %.0f dB SPL',title_str,level_spl));
            temp{1,cols} = sprintf('%s (n = %s)',cell2mat(all_Conds2Run(cols)),mat2str(sum(idx(:,cols))));
            legend_idx = find(~cellfun(@isempty,temp));
            legend_string = temp(legend_idx);
            legend(legend_string,'Location','southoutside','Orientation','horizontal');
            legend boxoff; hold off;
            ylim(ylimits); grid on;
            idx_peaks = ~isnan(average.peaks{1,cols});
            x_max = round(max(average.peaks_locs{1,cols}(idx_peaks)),-3);
            xlim([0,x_max]); set(gca,'xscale','linear');
            set(gca,'FontSize',25); xticks(round(average.peaks_locs{1,cols}));
        end
    end
    set(gcf, 'Units', 'normalized', 'Position', [0.2 0.2 0.5 0.6]);
    %% Average PLV at Low and High Freqs
    figure(counter+1); hold on;
    freq_labels = {'Low Harmonics (1-4)','High Harmonics (5-16)'};
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
                set(all_lines(i), 'LineWidth', 3, 'LineStyle','-','Color','k');  % Thicken factor separator line
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
        set(boxHandles(i), 'Color', thisColor, 'LineWidth', 3);
        set(medianHandles(i), 'Color', thisColor, 'LineWidth', 3);
        set(upperWhiskerHandles(i), 'Color', thisColor, 'LineWidth', 3);
        set(lowerWhiskerHandles(i), 'Color', thisColor, 'LineWidth', 3);
        set(capHandles(i), 'Color', thisColor, 'LineWidth', 3);
        set(capHandles2(i), 'Color', thisColor, 'LineWidth', 3);
        set(gca, 'XTick', []);
        set(allOutliers(i), 'MarkerEdgeColor', thisColor, 'LineWidth', 3);
    end
    hold on;
    for z = 1:size(idx,1)
        conds_counts(z) = sum(idx(z,:));
    end
    legend_handles = gobjects(conds_counts(find(max(conds_counts))), 1);
    conds_counts_idx =  find(sum(idx)~= 0);
    for i = 1:length(conds_counts_idx)
        legend_handles(i) = plot(NaN, NaN, 's', 'MarkerFaceColor', colors(conds_counts_idx(i), :), 'MarkerEdgeColor', 'k', 'MarkerSize', 15);
    end
    legend(legend_handles,legend_string,'Location','southoutside','Orientation','horizontal');
    ylabel('PLV', 'FontWeight', 'bold');
    title(sprintf('EFR Harmonic Contribution (%s) | %.0f dB SPL',title_str,level_spl),'FontWeight','bold');
    set(gca,'FontSize',15);
    legend boxoff; hold off; box off;
    group_ticks = (1:num_freqs) * num_timepoints - (num_timepoints-1)/2;
    set(gca, 'XTick', group_ticks);
    set(gca, 'XTickLabel', freq_labels);
    set(gcf, 'Units', 'normalized', 'Position', [0.2 0.2 0.5 0.6]);
    %% Average PLV Sum
    figure(counter+2); hold on;
    num_freqs = 1;
    [num_subjects, num_timepoints] = size(average.all_plv_sum);
    peaks = [];
    frequencies = [];
    timepoints = [];
    for subj = 1:num_subjects
        for tpt = 1:num_timepoints
            data = average.all_plv_sum{subj, tpt};
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
        set(boxHandles(i), 'Color', thisColor, 'LineWidth', 3);
        set(medianHandles(i), 'Color', thisColor, 'LineWidth', 3);
        set(upperWhiskerHandles(i), 'Color', thisColor, 'LineWidth', 3);
        set(lowerWhiskerHandles(i), 'Color', thisColor, 'LineWidth', 3);
        set(capHandles(i), 'Color', thisColor, 'LineWidth', 3);
        set(capHandles2(i), 'Color', thisColor, 'LineWidth', 3);
        set(gca, 'XTick', []);
        set(allOutliers(i), 'MarkerEdgeColor', thisColor, 'LineWidth', 3);
    end
    hold on;
    legend_handles = gobjects(conds_counts(find(max(conds_counts))), 1);
    for i = 1:length(conds_counts_idx)
        legend_handles(i) = plot(NaN, NaN, 's', 'MarkerFaceColor', colors(conds_counts_idx(i), :), 'MarkerEdgeColor', 'k', 'MarkerSize', 15);
    end
    legend(legend_handles,legend_string,'Location','southoutside','Orientation','horizontal');
    ylabel('PLV Sum', 'FontWeight', 'bold');
    title(sprintf('EFR Total PLV Sum (%s) | %.0f dB SPL',title_str,level_spl),'FontWeight','bold');
    set(gca,'FontSize',15);
    legend boxoff; hold off; box off;
    set(gcf, 'Units', 'normalized', 'Position', [0.2 0.2 0.5 0.6]);
end
%% Plot relative to Baseline
if ~isempty(idx_plot_relative)
    for cols = 1:length(average.peaks)
        if ~isempty(average.peaks_locs{1,cols})
            figure(counter); hold on;
            errorbar(average.peaks_locs{1,cols},average.peaks{1,cols},average.peaks_std{1,cols},'Marker',shapes(cols+1,:),'LineStyle','-','linew', 3, 'MarkerSize', 15, 'Color', colors(cols+1,:), 'MarkerFaceColor', colors(cols+1,:), 'MarkerEdgeColor', colors(cols+1,:),'HandleVisibility','off');
            %average.efr_fit = fillmissing(average.peaks{1,cols},'linear','SamplePoints',average.peaks_locs{1,cols});
            %plot(average.peaks_locs{1,cols},average.efr_fit,'Marker',shapes(cols+1,:),'LineStyle','-', 'linew', 2,'Color', colors(cols+1,:), 'MarkerSize', 12, 'MarkerFaceColor', colors(cols+1,:), 'MarkerEdgeColor', colors(cols+1,:));
            %plot(average.peaks_locs{1,cols},average.peaks{1,cols},'*k','linewidth',2)
            plot(average.peaks_locs{1,cols},average.peaks{1,cols},'Marker',shapes(cols+1,:),'LineStyle','-','linew', 3, 'MarkerSize', 15, 'Color', colors(cols+1,:), 'MarkerFaceColor', colors(cols+1,:), 'MarkerEdgeColor', colors(cols+1,:));
            plot(average.peaks_locs{1,cols}, zeros(size(average.peaks_locs{1,cols})),'LineStyle','--', 'linew', 3, 'Color', 'k','HandleVisibility','off');
            ylabel('PLV Shift (re. Baseline)', 'FontWeight', 'bold');
            xlabel(x_units, 'FontWeight', 'bold');
            title(sprintf('EFR (%s) | %.0f dB SPL',title_str,level_spl));
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
            xtickangle(90);
            set(gca,'xscale','linear');
            set(gca,'FontSize',25);
        end        
    end
    set(gcf, 'Units', 'normalized', 'Position', [0.2 0.2 0.5 0.6]);
    %% Average PLV at Low and High Freqs
    figure(counter+1); hold on;
    freq_labels = {'Low Harmonics (1-4)','High Harmonics (5-16)'};
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
    yline(0, 'k--', 'LineWidth', 3);
    % Thickens vertical separator line
    all_lines = findobj(gca, 'Type', 'Line');
    for i = 1:length(all_lines)
        xdata = get(all_lines(i), 'XData');
        ydata = get(all_lines(i), 'YData');
        if length(xdata) >= 2 && length(ydata) >= 2
            if abs(xdata(2) - xdata(1)) < 0.01 && (ydata(2) - ydata(1)) > range(ylim)*0.9
                set(all_lines(i), 'LineWidth', 3, 'LineStyle','-','Color','k');  % Thicken factor separator line
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
        set(boxHandles(i), 'Color', thisColor, 'LineWidth', 3);
        set(medianHandles(i), 'Color', thisColor, 'LineWidth', 3);
        set(upperWhiskerHandles(i), 'Color', thisColor, 'LineWidth', 3);
        set(lowerWhiskerHandles(i), 'Color', thisColor, 'LineWidth', 3);
        set(capHandles(i), 'Color', thisColor, 'LineWidth', 3);
        set(capHandles2(i), 'Color', thisColor, 'LineWidth', 3);
        set(gca, 'XTick', []);
        set(allOutliers(i), 'MarkerEdgeColor', thisColor, 'LineWidth', 3);
    end
    hold on;
    idx_temp = idx;
    idx = idx(:,2:end);
    if size(idx,1) > 1
        for z = 1:size(idx,1)-1
            conds_counts(z) = sum(idx(z+1,:));
        end
    else
        conds_counts = sum(idx(1,:));
    end
    legend_handles = gobjects(conds_counts(find(max(conds_counts))), 1);
    conds_counts_idx =  find(any(idx, 1));
    for i = 1:length(conds_counts_idx)
        legend_handles(i) = plot(NaN, NaN, 's', 'MarkerFaceColor', colors(conds_counts_idx(i)+1, :), 'MarkerEdgeColor', 'k', 'MarkerSize', 15);
    end
    valid_idx = isgraphics(legend_handles);
    legend_handles = legend_handles(valid_idx);
    legend(legend_handles,legend_string,'Location','southoutside','Orientation','horizontal');
    ylabel('PLV Shift (re. Baseline)', 'FontWeight', 'bold');
    title(sprintf('EFR Harmonic Contribution (%s) | %.0f dB SPL',title_str,level_spl),'FontWeight','bold');
    set(gca,'FontSize',25);
    legend boxoff; hold off; box off;
    group_ticks = (1:num_freqs) * num_timepoints - (num_timepoints-1)/2;
    set(gca, 'XTick', group_ticks);
    set(gca, 'XTickLabel', freq_labels);
    set(gcf, 'Units', 'normalized', 'Position', [0.2 0.2 0.5 0.6]);
    %% Average PLV Sum
    figure(counter+2); hold on;
    num_freqs = 1;
    [num_subjects, num_timepoints] = size(average.all_plv_sum);
    peaks = [];
    frequencies = [];
    timepoints = [];
    for subj = 1:num_subjects
        for tpt = 1:num_timepoints
            data = average.all_plv_sum{subj, tpt};
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
    yline(0, 'k--', 'LineWidth', 3);
    % Thickens vertical separator line
    all_lines = findobj(gca, 'Type', 'Line');
    for i = 1:length(all_lines)
        xdata = get(all_lines(i), 'XData');
        ydata = get(all_lines(i), 'YData');
        if length(xdata) >= 2 && length(ydata) >= 2
            if abs(xdata(2) - xdata(1)) < 0.01 && (ydata(2) - ydata(1)) > range(ylim)*0.9
                set(all_lines(i), 'LineWidth', 3, 'LineStyle','-','Color','k');  % Thicken factor separator line
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
        set(boxHandles(i), 'Color', thisColor, 'LineWidth', 3);
        set(medianHandles(i), 'Color', thisColor, 'LineWidth', 3);
        set(upperWhiskerHandles(i), 'Color', thisColor, 'LineWidth', 3);
        set(lowerWhiskerHandles(i), 'Color', thisColor, 'LineWidth', 3);
        set(capHandles(i), 'Color', thisColor, 'LineWidth', 3);
        set(capHandles2(i), 'Color', thisColor, 'LineWidth', 3);
        set(gca, 'XTick', []);
        set(allOutliers(i), 'MarkerEdgeColor', thisColor, 'LineWidth', 3);
    end
    hold on;
    legend_handles = gobjects(conds_counts(find(max(conds_counts))), 1);
    for i = 1:length(conds_counts_idx)
        legend_handles(i) = plot(NaN, NaN, 's', 'MarkerFaceColor', colors(conds_counts_idx(i)+1, :), 'MarkerEdgeColor', 'k', 'MarkerSize', 15);
    end
    legend(legend_handles,legend_string,'Location','southoutside','Orientation','horizontal');
    ylabel('PLV Shift (re. Baseline)', 'FontWeight', 'bold');
    title(sprintf('EFR Total PLV Sum (%s) | %.0f dB SPL',title_str,level_spl),'FontWeight','bold');
    set(gca,'FontSize',25);
    legend boxoff; hold off; box off;
    set(gcf, 'Units', 'normalized', 'Position', [0.2 0.2 0.5 0.6]);
    idx = idx_temp;
end
average.subjects = Chins2Run;
average.conditions = [convertCharsToStrings(all_Conds2Run);idx];
%% Export
cd(outpath);
save(filename,'average');
print(figure(counter),[filename,'_figure'],'-dpng','-r300');
print(figure(counter+1),[filename,'_PLVharmonics_figure'],'-dpng','-r300');
print(figure(counter+2),[filename,'_PLVsum_figure'],'-dpng','-r300');
end