function plot_avg_abr(average,plot_type,colors,shapes,idx,conds_idx,Chins2Run,Conds2Run,all_Conds2Run,outpath,filename,counter,ylimits_threshold,idx_plot_relative,peak_analysis,freq,wave_sel)
str_plot_relative = strsplit(Conds2Run{idx_plot_relative}, filesep);
legend_string = [];
cwd = pwd;
%% Plot ALL
if isempty(idx_plot_relative)
    %% Thresholds
    if strcmp(plot_type,'Thresholds')
        y_units = 'Threshold (dB SPL)';
        fh_thr_avg = findobj('Type','figure','Tag','APAT_thr_avg');
        if isempty(fh_thr_avg)
            fh_thr_avg = figure('Name','ABR Thresholds Average', ...
                'NumberTitle','off','Tag','APAT_thr_avg','Visible','off');
        else
            fh_thr_avg = fh_thr_avg(1); set(0,'CurrentFigure', fh_thr_avg);
        end
        clf; hold on;
        % Box Plot — derive freq labels dynamically from data
        ref_col = find(~cellfun(@isempty, average.x), 1);
        if ~isempty(ref_col)
            ref_freqs = average.x{1, ref_col};
        else
            ref_freqs = [0 500 1000 2000 4000 8000];
        end
        num_freqs = length(ref_freqs);
        freq_labels = cell(1, num_freqs);
        for fi = 1:num_freqs
            if ref_freqs(fi) == 0
                freq_labels{fi} = 'Click';
            else
                freq_labels{fi} = [num2str(ref_freqs(fi)/1000), ' kHz'];
            end
        end
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
            set(boxHandles(i), 'Color', thisColor, 'LineWidth', 3);
            set(medianHandles(i), 'Color', thisColor, 'LineWidth', 3);
            set(upperWhiskerHandles(i), 'Color', thisColor, 'LineWidth', 3);
            set(lowerWhiskerHandles(i), 'Color', thisColor, 'LineWidth', 3);
            set(capHandles(i), 'Color', thisColor, 'LineWidth', 3);
            set(capHandles2(i), 'Color', thisColor, 'LineWidth', 3);
            set(gca, 'XTick', []);
            set(allOutliers(i), 'MarkerEdgeColor', thisColor, 'LineWidth', 3);
        end
        idx_temp = idx;
        hold on;
        if size(idx,1) > 1
            for z = 1:size(idx,1)
                conds_counts(z) = sum(idx(z,:));
            end
        else
            conds_counts = sum(idx(1,:));
        end
        legend_handles = gobjects(conds_counts(find(max(conds_counts))), 1);
        conds_counts_idx =  find(any(idx, 1));
        for i = 1:length(conds_counts_idx)
            legend_handles(i) = plot(NaN, NaN, 's', 'MarkerFaceColor', colors(conds_counts_idx(i), :), 'MarkerEdgeColor', 'k', 'MarkerSize', 15);
        end
        for cols = 1:length(average.y)
            if ~isempty(average.y{1,cols})
                temp{1,cols} = sprintf('%s (n = %s)',cell2mat(all_Conds2Run(cols)),mat2str(sum(idx(:,cols))));
                legend_idx = find(~cellfun(@isempty,temp));
                legend_string = temp(legend_idx);
            end
        end
        valid_idx = isgraphics(legend_handles);
        legend_handles = legend_handles(valid_idx);
        legend(legend_handles,legend_string,'Location','southoutside','Orientation','horizontal');
        ylabel(y_units, 'FontWeight', 'bold');
        title(sprintf('ABR Thresholds'),'FontWeight','bold');
        set(gca,'FontSize',25);
        legend boxoff; hold off; box off;
        group_ticks = (1:num_freqs) * num_timepoints - (num_timepoints-1)/2;
        set(gca, 'XTick', group_ticks);
        set(gca, 'XTickLabel', freq_labels);
        set(fh_thr_avg, 'Units', 'normalized', 'Position', [0.2 0.2 0.5 0.6]);
        if ~isempty(ylimits_threshold)
            ylim(ylimits_threshold);
        else
            valid_thr = thresholds(isfinite(thresholds));
            if ~isempty(valid_thr)
                lo = min(valid_thr); hi = max(valid_thr);
                pad = max(0.15 * (hi - lo), 5);
                ylim([lo - pad, hi + pad]);
            end
        end
        average.subjects = Chins2Run;
        average.conditions = Conds2Run;
        average.analysis_log = idx;
        % Export
        cd(outpath);
        save(filename,'average');
        drawnow;
        exportgraphics(fh_thr_avg,[filename,'_figure.png'],'Resolution',300);
        idx = idx_temp;
%% Peaks
    elseif strcmp(plot_type,'Peaks')
        if freq == 0
            freq_str   = 'Click';
            freq_label = 'Click';
        else
            freq_str = [mat2str(freq),' Hz'];
            if freq >= 1000
                freq_label = sprintf('%.4g kHz', freq/1000);
            else
                freq_label = sprintf('%.4g Hz', freq);
            end
        end
        x_units = 'Sound Level (dB SPL)';
        if strcmp(peak_analysis,'Amplitude')
            y_units = 'Peak-to-Peak Amplitude (\muV)';
            title_str = sprintf('ABR Peak-to-Peak Amplitude (%s)',freq_str);
        elseif strcmp(peak_analysis,'Latency')
            y_units = 'Latency (ms)';
            title_str = sprintf('ABR Absolute Peak Latency (%s)',freq_str);
        end
        % Wave selection defaults
        if ~exist('wave_sel','var') || isempty(wave_sel), wave_sel = true(1,5); end
        valid_cols = cellfun(@(c) ~(isempty(c) || (isnumeric(c) && isequal(size(c),[0 0]))), average.w1);
        cols_idx = find(any(valid_cols, 1));
        if strcmp(peak_analysis,'Latency'), cat_label = 'Latencies'; else, cat_label = [peak_analysis 's']; end
        fig_name_str = [cat_label '|' freq_label];
        all_wave_names  = {'Wave I','Wave II','Wave III','Wave IV','Wave V'};
        all_wave_fields = {'w1','w2','w3','w4','w5'};
        all_wave_std    = {'w1_std','w2_std','w3_std','w4_std','w5_std'};
        shown_wi = find(wave_sel);
        n_tiles  = numel(shown_wi);
        if n_tiles == 0, n_tiles = 1; end
        t_cols = min(n_tiles, 3);
        t_rows = ceil(n_tiles / t_cols);
        % Build single tiledlayout figure
        fh = figure(counter); clf;
        set(fh,'Visible','off');
        set(fh, 'Name', fig_name_str);
        tl = tiledlayout(fh, t_rows, t_cols, 'TileSpacing','compact', 'Padding','compact');
        title(tl, title_str, 'FontSize',16, 'FontWeight','bold');
        ax1 = [];
        wave_axes = gobjects(numel(shown_wi), 1);
        % --- Wave tiles ---
        for wi_idx = 1:numel(shown_wi)
            wnum = shown_wi(wi_idx);
            wf   = all_wave_fields{wnum};
            wsf  = all_wave_std{wnum};
            wn   = all_wave_names{wnum};
            ax = nexttile(tl);
            wave_axes(wi_idx) = ax;
            if isempty(ax1), ax1 = ax; end
            hold(ax,'on');
            for cols = cols_idx
                errorbar(ax, round(average.x{1,cols}), average.(wf){1,cols}, average.(wsf){1,cols}, ...
                    'Marker',shapes(wnum,:),'LineStyle','-','LineWidth',2,'Color',colors(cols,:),...
                    'MarkerSize',12,'MarkerFaceColor',colors(cols,:),'MarkerEdgeColor',colors(cols,:),...
                    'HandleVisibility','off');
                fit_y = fillmissing(flip(average.(wf){1,cols}),'linear','SamplePoints',flip(round(average.x{1,cols}))); fit_y = flip(fit_y);
                plot(ax, round(average.x{1,cols}), fit_y, 'Marker',shapes(wnum,:),'LineStyle','-','LineWidth',2,...
                    'Color',colors(cols,:),'MarkerSize',12,'MarkerFaceColor',colors(cols,:),'MarkerEdgeColor',colors(cols,:),...
                    'HandleVisibility','off');
            end
            if ~isempty(cols_idx)
                x_tks = round(unique(average.x{1,cols_idx(1)}));
            else
                x_tks = [];
            end
            xticks(ax, x_tks);
            if numel(x_tks) > 1, x_pad = (x_tks(end)-x_tks(1))*0.06; xlim(ax,[x_tks(1)-x_pad, x_tks(end)+x_pad]); end
            title(ax, wn, 'FontSize',14); grid(ax,'on'); set(ax,'FontSize',14);
            % Per-tile axis labels: ylabel on left column, xlabel on every tile
            if mod(wi_idx-1, t_cols) == 0, ylabel(ax, y_units, 'FontSize',14, 'FontWeight','bold'); end
            xlabel(ax, x_units, 'FontSize',14, 'FontWeight','bold');
            hold(ax,'off');
        end
        % Link wave y-axes so amplitudes/latencies are directly comparable
        if numel(shown_wi) > 1
            linkaxes(wave_axes, 'y');
        end
        % Latency: tight ylim fitted to data+errorbars, ticks every 0.5 ms
        if strcmp(peak_analysis,'Latency') && numel(shown_wi) > 0
            lat_lo = Inf; lat_hi = -Inf;
            for wai = 1:numel(shown_wi)
                wf_tmp  = all_wave_fields{shown_wi(wai)};
                wsf_tmp = all_wave_std{shown_wi(wai)};
                for c_tmp = cols_idx
                    v_tmp = average.(wf_tmp){1,c_tmp};
                    s_tmp = average.(wsf_tmp){1,c_tmp};
                    if ~isempty(v_tmp) && any(isfinite(v_tmp(:)))
                        fin = isfinite(v_tmp(:));
                        err = zeros(size(v_tmp(:)));
                        if ~isempty(s_tmp) && any(isfinite(s_tmp(:))), err = s_tmp(:); err(~isfinite(err)) = 0; end
                        lat_lo = min(lat_lo, min(v_tmp(fin) - err(fin)));
                        lat_hi = max(lat_hi, max(v_tmp(fin) + err(fin)));
                    end
                end
            end
            if isfinite(lat_lo) && isfinite(lat_hi)
                step = 0.5;
                t0 = floor(lat_lo/step)*step;
                t1 = ceil(lat_hi/step)*step;
                set(wave_axes, 'YTick', t0:1:t1, 'YLim', [t0-step/2, t1+step/2]);
            end
        end
        % --- Condition legend (south of entire layout) ---
        if ~isempty(ax1) && ~isempty(cols_idx)
            hold(ax1,'on');
            lh = gobjects(numel(cols_idx),1);
            leg_str = {};
            for li = 1:numel(cols_idx)
                c = cols_idx(li);
                lh(li) = plot(ax1, NaN, NaN, 's', 'MarkerFaceColor',colors(c,:), ...
                    'MarkerEdgeColor','k','MarkerSize',12,'LineWidth',1.5);
                leg_str{li} = sprintf('%s (n = %s)', cell2mat(all_Conds2Run(c)), mat2str(sum(idx(:,c))));
            end
            hold(ax1,'off');
            lg = legend(ax1, lh, leg_str, 'Orientation','horizontal', 'Box','off');
            lg.Layout.Tile = 'south';
        end
        average.subjects   = Chins2Run;
        average.conditions = [convertCharsToStrings(all_Conds2Run(:)');idx];
        % Export
        cd(outpath);
        save(filename,'average');
        print(counter, [filename,'_figure'], '-dpng', '-r300');
    end
end
%% Plot relative to Baseline
if ~isempty(idx_plot_relative)  
    %% Thresholds
    if strcmp(plot_type,'Thresholds')
        y_units = sprintf('Threshold Shift (re. %s)',str_plot_relative{2});
        fh_thr_avg = findobj('Type','figure','Tag','APAT_thr_avg');
        if isempty(fh_thr_avg)
            fh_thr_avg = figure('Name','ABR Thresholds Average', ...
                'NumberTitle','off','Tag','APAT_thr_avg','Visible','off');
        else
            fh_thr_avg = fh_thr_avg(1); set(0,'CurrentFigure', fh_thr_avg);
        end
        hold on;
        % Box Plot — derive freq labels dynamically from data
        ref_col = find(~cellfun(@isempty, average.x), 1);
        if ~isempty(ref_col)
            ref_freqs = average.x{1, ref_col};
        else
            ref_freqs = [0 500 1000 2000 4000 8000];
        end
        num_freqs = length(ref_freqs);
        freq_labels = cell(1, num_freqs);
        for fi = 1:num_freqs
            if ref_freqs(fi) == 0
                freq_labels{fi} = 'Click';
            else
                freq_labels{fi} = [num2str(ref_freqs(fi)/1000), ' kHz'];
            end
        end
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
        yline(0, 'k--', 'LineWidth', 3);
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
            set(boxHandles(i), 'Color', thisColor, 'LineWidth', 3);
            set(medianHandles(i), 'Color', thisColor, 'LineWidth', 3);
            set(upperWhiskerHandles(i), 'Color', thisColor, 'LineWidth', 3);
            set(lowerWhiskerHandles(i), 'Color', thisColor, 'LineWidth', 3);
            set(capHandles(i), 'Color', thisColor, 'LineWidth', 3);
            set(capHandles2(i), 'Color', thisColor, 'LineWidth', 3);
            set(gca, 'XTick', []);
            set(allOutliers(i), 'MarkerEdgeColor', thisColor, 'LineWidth', 3);
        end
        idx_temp = idx;
        idx = idx(:,2:end);
        hold on;
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
        for cols = 1:length(average.y)
            if ~isempty(average.y{1,cols})
                temp{1,cols} = sprintf('%s (n = %s)',cell2mat(all_Conds2Run(cols+1)),mat2str(sum(idx(:,cols))));
                legend_idx = find(~cellfun(@isempty,temp));
                legend_string = temp(legend_idx);
            end
        end
        valid_idx = isgraphics(legend_handles);
        legend_handles = legend_handles(valid_idx);
        legend(legend_handles,legend_string,'Location','southoutside','Orientation','horizontal');
        ylabel(y_units, 'FontWeight', 'bold');
        title(sprintf('ABR Thresholds'),'FontWeight','bold');
        set(gca,'FontSize',25);
        legend boxoff; hold off; box off;
        group_ticks = (1:num_freqs) * num_timepoints - (num_timepoints-1)/2;
        set(gca, 'XTick', group_ticks);
        set(gca, 'XTickLabel', freq_labels);
        set(fh_thr_avg, 'Units', 'normalized', 'Position', [0.2 0.2 0.5 0.6]);
        if ~isempty(ylimits_threshold)
            ylim(ylimits_threshold);
        else
            valid_thr = thresholds(isfinite(thresholds));
            if ~isempty(valid_thr)
                lo = min(valid_thr); hi = max(valid_thr);
                pad = max(0.15 * (hi - lo), 5);
                ylim([lo - pad, hi + pad]);
            end
        end
        average.subjects = Chins2Run;
        average.conditions = Conds2Run;
        average.analysis_log = idx;
        % Export
        cd(outpath);
        save(filename,'average');
        drawnow;
        exportgraphics(fh_thr_avg,[filename,'_figure.png'],'Resolution',300);
        idx = idx_temp;
    elseif strcmp(plot_type,'Peaks')
        x_units = 'Sound Level (dB SPL)';
        if strcmp(peak_analysis,'Amplitude')
            y_units = sprintf('Peak-to-Peak Amplitude Shift (re. %s)',str_plot_relative{2});
            title_str = sprintf('ABR Peak-to-Peak Amplitude');
        elseif strcmp(peak_analysis,'Latency')
            y_units = sprintf('Latency Shift (re. %s)',str_plot_relative{2});
            title_str = sprintf('ABR Absolute Peak Latency');
        end
        % Wave selection defaults
        if ~exist('wave_sel','var') || isempty(wave_sel), wave_sel = true(1,5); end
        all_wave_names  = {'Wave I','Wave II','Wave III','Wave IV','Wave V'};
        all_wave_fields = {'w1','w2','w3','w4','w5'};
        all_wave_std    = {'w1_std','w2_std','w3_std','w4_std','w5_std'};
        shown_wi = find(wave_sel);
        n_tiles  = numel(shown_wi);
        if n_tiles == 0, n_tiles = 1; end
        t_cols = min(n_tiles, 3);
        t_rows = ceil(n_tiles / t_cols);
        % Build single tiledlayout figure
        fh = figure(counter); clf;
        set(fh,'Visible','off');
        tl = tiledlayout(fh, t_rows, t_cols, 'TileSpacing','compact', 'Padding','compact');
        title(tl, title_str, 'FontSize',16, 'FontWeight','bold');
        n_rel_cols = size(average.w1, 1);  % number of post conditions (rows in average struct)
        ax1 = [];
        wave_axes = gobjects(numel(shown_wi), 1);
        % --- Wave tiles ---
        for wi_idx = 1:numel(shown_wi)
            wnum = shown_wi(wi_idx);
            wf   = all_wave_fields{wnum};
            wsf  = all_wave_std{wnum};
            wn   = all_wave_names{wnum};
            ax = nexttile(tl);
            if isempty(ax1), ax1 = ax; end
            hold(ax,'on');
            for cols = 1:n_rel_cols
                if isempty(average.(wf){1,cols}), continue; end
                c_idx = cols + 1;  % colors shifted by 1 for relative plots
                errorbar(ax, round(average.x{1,cols}), average.(wf){1,cols}, average.(wsf){1,cols}, ...
                    'Marker',shapes(wnum,:),'LineStyle','-','LineWidth',2,'Color',colors(c_idx,:),...
                    'MarkerSize',12,'MarkerFaceColor',colors(c_idx,:),'MarkerEdgeColor',colors(c_idx,:),...
                    'HandleVisibility','off');
                fit_y = fillmissing(flip(average.(wf){1,cols}),'linear','SamplePoints',flip(round(average.x{1,cols}))); fit_y = flip(fit_y);
                plot(ax, round(average.x{1,cols}), fit_y,'Marker',shapes(wnum,:),'LineStyle','-','LineWidth',2,...
                    'Color',colors(c_idx,:),'MarkerSize',12,'MarkerFaceColor',colors(c_idx,:),'MarkerEdgeColor',colors(c_idx,:),...
                    'HandleVisibility','off');
                plot(ax, round(average.x{1,cols}), zeros(size(average.x{1,cols})),'LineStyle','--','LineWidth',2,'Color','k','HandleVisibility','off');
            end
            x_tks = round(unique(average.x{1,1}));
            xticks(ax, x_tks);
            if numel(x_tks) > 1, x_pad = (x_tks(end)-x_tks(1))*0.06; xlim(ax,[x_tks(1)-x_pad, x_tks(end)+x_pad]); end
            title(ax, wn, 'FontSize',14); grid(ax,'on'); set(ax,'FontSize',14);
            % Per-tile axis labels: ylabel on left column, xlabel on every tile
            if mod(wi_idx-1, t_cols) == 0, ylabel(ax, y_units, 'FontSize',14, 'FontWeight','bold'); end
            xlabel(ax, x_units, 'FontSize',14, 'FontWeight','bold');
            hold(ax,'off');
            wave_axes(wi_idx) = ax;
        end
        % Link wave y-axes for comparable view across waves
        valid_wave_ax = wave_axes(arrayfun(@(a) ~isequal(a, gobjects(1)), wave_axes) & isvalid(wave_axes));
        if numel(valid_wave_ax) > 1
            linkaxes(valid_wave_ax, 'y');
        end
        % Latency: tight ylim fitted to data+errorbars, ticks every 0.5 ms
        if strcmp(peak_analysis,'Latency') && numel(valid_wave_ax) > 0
            lat_lo = Inf; lat_hi = -Inf;
            for wai = 1:numel(shown_wi)
                wf_tmp  = all_wave_fields{shown_wi(wai)};
                wsf_tmp = all_wave_std{shown_wi(wai)};
                for c_tmp = 1:n_rel_cols
                    v_tmp = average.(wf_tmp){1,c_tmp};
                    s_tmp = average.(wsf_tmp){1,c_tmp};
                    if ~isempty(v_tmp) && any(isfinite(v_tmp(:)))
                        fin = isfinite(v_tmp(:));
                        err = zeros(size(v_tmp(:)));
                        if ~isempty(s_tmp) && any(isfinite(s_tmp(:))), err = s_tmp(:); err(~isfinite(err)) = 0; end
                        lat_lo = min(lat_lo, min(v_tmp(fin) - err(fin)));
                        lat_hi = max(lat_hi, max(v_tmp(fin) + err(fin)));
                    end
                end
            end
            if isfinite(lat_lo) && isfinite(lat_hi)
                step = 0.5;
                t0 = floor(lat_lo/step)*step;
                t1 = ceil(lat_hi/step)*step;
                set(valid_wave_ax, 'YTick', t0:step:t1, 'YLim', [t0-step/2, t1+step/2]);
            end
        end
        % --- Condition legend (south of entire layout) ---
        if ~isempty(ax1)
            hold(ax1,'on');
            lh = gobjects(n_rel_cols,1);
            leg_str = {};
            for cols = 1:n_rel_cols
                c_idx = cols + 1;
                lh(cols) = plot(ax1, NaN, NaN, 's', 'MarkerFaceColor',colors(c_idx,:), ...
                    'MarkerEdgeColor','k','MarkerSize',12,'LineWidth',1.5);
                leg_str{cols} = sprintf('%s (n = %s)', cell2mat(Conds2Run(cols+1)), mat2str(sum(idx(:,conds_idx(cols+1)))));
            end
            hold(ax1,'off');
            lg = legend(ax1, lh, leg_str, 'Orientation','horizontal', 'Box','off');
            lg.Layout.Tile = 'south';
        end
        average.subjects   = Chins2Run;
        average.conditions = [convertCharsToStrings(all_Conds2Run(:)');idx];
        % Export
        cd(outpath);
        save(filename,'average');
        print(counter, [filename,'_figure'], '-dpng', '-r300');
    end
end
cd(cwd)
end

