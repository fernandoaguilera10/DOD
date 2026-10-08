function plot_avg_efr(average, plot_type, level_spl, colors, shapes, idx, conds_idx, Chins2Run, Conds2Run, all_Conds2Run, outpath, filename, counter, ylimits, idx_plot_relative)
% Plot EFR average figures and export.  plot_type: 'RAM' | 'dAM'
cwd = pwd;
legend_string = [];
level_tag = sprintf('%ddB', round(level_spl));

switch plot_type
    case 'RAM'
        y_units   = 'PLV';
        title_str = 'RAM 223 Hz';
        x_units   = 'Frequency (Hz)';
    case 'dAM'
        y_units   = 'Power (dB)';
        title_str = 'dAM 4 kHz';
        x_units   = 'Modulation Frequency (Hz)';
end

%% Helper: find or create a figure (Visible off, clear on reuse)
    function fh = get_fig(base_tag, name)
        tag = [base_tag, '_', level_tag];
        fh = findobj('Type','figure','Tag',tag);
        if isempty(fh)
            fh = figure('Name',name,'NumberTitle','off','Tag',tag,'Visible','off');
        else
            fh = fh(1);
        end
        clf(fh);
        set(fh,'Units','normalized','Position',[0.2 0.2 0.5 0.6]);
    end

%% Helper: build legend string from current data
    function ls = build_legend(avg_field, col_offset)
        temp = cell(1, length(avg_field));
        for c = 1:length(avg_field)
            if ~isempty(avg_field{1,c})
                temp{1,c} = sprintf('%s (n = %s)', ...
                    cell2mat(all_Conds2Run(c+col_offset)), mat2str(sum(idx(:,c+col_offset))));
            end
        end
        valid = find(~cellfun(@isempty, temp));
        ls = temp(valid);
    end

%% Helper: color boxplots by timepoint
    function color_boxplot(ax, colors_in, col_offset, n_conds)
        boxHandles    = flipud(findobj(ax,'Tag','Box'));
        medianHandles = flipud(findobj(ax,'Tag','Median'));
        upperWhiskerH = flipud(findobj(ax,'Tag','Upper Whisker'));
        lowerWhiskerH = flipud(findobj(ax,'Tag','Lower Whisker'));
        capH          = flipud(findobj(ax,'Tag','Upper Adjacent Value'));
        capH2         = flipud(findobj(ax,'Tag','Lower Adjacent Value'));
        outlierH      = flipud(findobj(ax,'Tag','Outliers'));
        n_tp = length(boxHandles);
        if nargin < 4 || isempty(n_conds), n_conds = n_tp; end
        n_colors = size(colors_in, 1);
        for bi = 1:n_tp
            tp_idx = mod(bi-1, n_conds) + 1;
            c = colors_in(mod(tp_idx + col_offset - 1, n_colors) + 1, :);
            x = get(boxHandles(bi),'XData');
            y = get(boxHandles(bi),'YData');
            patch(ax, x([1 2 3 4 1]), y([1 2 3 4 1]), c, 'FaceAlpha',0.5,'EdgeColor','none');
            set(boxHandles(bi),    'Color',c,'LineWidth',2);
            set(medianHandles(bi), 'Color',c,'LineWidth',2);
            set(upperWhiskerH(bi), 'Color',c,'LineWidth',2);
            set(lowerWhiskerH(bi), 'Color',c,'LineWidth',2);
            set(capH(bi),          'Color',c,'LineWidth',2);
            set(capH2(bi),         'Color',c,'LineWidth',2);
            set(ax,'XTick',[]);
            set(outlierH(bi),'MarkerEdgeColor',c,'LineWidth',2);
        end
        all_lines = findobj(ax,'Type','Line');
        for li = 1:length(all_lines)
            xd = get(all_lines(li),'XData'); yd = get(all_lines(li),'YData');
            if length(xd) >= 2 && abs(xd(2)-xd(1)) < 0.01 && (yd(2)-yd(1)) > range(ylim(ax))*0.9
                set(all_lines(li),'LineWidth',2,'LineStyle','-','Color','k');
            end
        end
    end

%% Helper: draw a boxplot dataset
    function [timepoints, n_tp_unique] = draw_boxplot(ax, data_cell, freq_labels)
        [n_subj, n_tp] = size(data_cell);
        n_freq = length(freq_labels);
        vals = []; freqs = []; timepoints = [];
        for s = 1:n_subj
            for t = 1:n_tp
                d = data_cell{s,t};
                if isempty(d), d = NaN(1,n_freq); end
                vals       = [vals,       d(:)'];            %#ok<AGROW>
                freqs      = [freqs,      freq_labels(1:n_freq)]; %#ok<AGROW>
                timepoints = [timepoints, repmat(t,1,n_freq)]; %#ok<AGROW>
            end
        end
        boxplot(ax, vals(:), {freqs(:), timepoints(:)}, ...
            'factorseparator',1,'labelverbosity','minor','ColorGroup',timepoints(:),'Symbol','*');
        n_tp_unique = length(unique(timepoints));
    end

%% Helper: add colored legend squares for conditions
    function add_box_legend(ax, ls, col_offset)
        conds_counts_idx = find(any(idx,1));
        n_leg = numel(conds_counts_idx);
        leg_h = gobjects(n_leg,1);
        for li = 1:n_leg
            leg_h(li) = plot(ax, NaN,NaN,'s','MarkerFaceColor',colors(conds_counts_idx(li)+col_offset,:), ...
                'MarkerEdgeColor','k','MarkerSize',9);
        end
        valid = isgraphics(leg_h);
        legend(ax, leg_h(valid), ls, 'Location','southoutside','Orientation','horizontal');
        legend(ax,'boxoff');
    end

%% ── ABSOLUTE MODE ────────────────────────────────────────────────────────────
if isempty(idx_plot_relative)
    switch plot_type
        % ── RAM absolute ──────────────────────────────────────────────────
        case 'RAM'
            legend_string = build_legend(average.peaks, 0);

            % Figure 1: PLV spectrum (continuous envelope + harmonic peaks)
            fh1 = get_fig('APAT_efr_RAM_avg', sprintf('EFR RAM Average %s', level_tag));
            ax1 = axes(fh1); hold(ax1,'on'); grid(ax1,'on'); box(ax1,'off');
            n_colors = size(colors, 1);
            for cols = 1:length(average.plv_env)
                cidx = mod(cols-1, n_colors) + 1;
                if ~isempty(average.plv_env{1,cols}) && ~isempty(average.f{1,cols})
                    plot(ax1, average.f{1,cols}, average.plv_env{1,cols}, ...
                        'LineStyle','-','LineWidth',1,'Color',[colors(cidx,:), 0.25], ...
                        'HandleVisibility','off');
                end
            end
            for cols = 1:length(average.peaks)
                cidx = mod(cols-1, n_colors) + 1;
                if ~isempty(average.peaks_locs{1,cols})
                    errorbar(ax1, average.peaks_locs{1,cols}, average.peaks{1,cols}, average.peaks_std{1,cols}, ...
                        'Marker',shapes(mod(cols-1,size(shapes,1))+1,:),'LineStyle','-','LineWidth',1.5,'MarkerSize',9, ...
                        'Color',colors(cidx,:),'MarkerFaceColor',colors(cidx,:),'MarkerEdgeColor',colors(cidx,:), ...
                        'HandleVisibility','off');
                    avg_fit = fillmissing(average.peaks{1,cols},'linear', ...
                        'SamplePoints',average.peaks_locs{find(~cellfun(@isempty,average.peaks_locs(:,cols)),1),cols});
                    plot(ax1, average.peaks_locs{1,cols}, avg_fit, ...
                        'Marker',shapes(mod(cols-1,size(shapes,1))+1,:),'LineStyle','-','LineWidth',1.5,'MarkerSize',9, ...
                        'Color',colors(cidx,:),'MarkerFaceColor',colors(cidx,:),'MarkerEdgeColor',colors(cidx,:));
                end
            end
            ylabel(ax1, y_units,'FontWeight','bold','FontSize',14);
            xlabel(ax1, x_units,'FontWeight','bold','FontSize',14);
            title(ax1, sprintf('EFR (%s) | %.0f dB SPL',title_str,level_spl),'FontWeight','bold','FontSize',14);
            legend(ax1, legend_string,'Location','southoutside','Orientation','horizontal');
            legend(ax1,'boxoff'); hold(ax1,'off');
            set_ylim_centered(ax1);
            last_nonempty = find(~cellfun(@isempty, average.peaks_locs(1,:)), 1, 'last');
            if ~isempty(last_nonempty)
                idx_pk = ~isnan(average.peaks_locs{1,last_nonempty});
                if any(idx_pk)
                    xlim(ax1,[0, round(max(average.peaks_locs{1,last_nonempty}(idx_pk)),-3)]);
                end
                xticks(ax1, round(average.peaks_locs{1,last_nonempty}));
            end
            set(ax1,'XScale','linear','FontSize',14);

            % Figure 2: Low/High harmonics boxplot
            fh2 = get_fig('APAT_efr_RAM_harm', sprintf('EFR RAM Harmonics %s', level_tag));
            ax2 = axes(fh2); hold(ax2,'on'); grid(ax2,'on'); box(ax2,'off');
            freq_labels_harm = {'Low Harmonics (1-4)','High Harmonics (5-16)'};
            [~, n_tp] = draw_boxplot(ax2, average.all_low_high_peaks, freq_labels_harm);
            color_boxplot(ax2, colors, 0, n_tp);
            add_box_legend(ax2, legend_string, 0);
            ylabel(ax2, y_units,'FontWeight','bold','FontSize',14);
            title(ax2, sprintf('EFR Harmonic Contribution (%s) | %.0f dB SPL',title_str,level_spl),'FontWeight','bold','FontSize',14);
            set(ax2,'FontSize',14);
            group_ticks = (1:length(freq_labels_harm)) * n_tp - (n_tp-1)/2;
            set(ax2,'XTick',group_ticks,'XTickLabel',freq_labels_harm);
            legend(ax2,'boxoff'); hold(ax2,'off');

            % Figure 3: PLV sum boxplot
            fh3 = get_fig('APAT_efr_RAM_plvsum', sprintf('EFR RAM PLV Sum %s', level_tag));
            ax3 = axes(fh3); hold(ax3,'on'); grid(ax3,'on'); box(ax3,'off');
            [~, n_tp] = draw_boxplot(ax3, average.all_plv_sum, {'PLV Sum'});
            color_boxplot(ax3, colors, 0, n_tp);
            add_box_legend(ax3, legend_string, 0);
            ylabel(ax3, 'PLV Sum','FontWeight','bold','FontSize',14);
            title(ax3, sprintf('EFR Total PLV Sum (%s) | %.0f dB SPL',title_str,level_spl),'FontWeight','bold','FontSize',14);
            set(ax3,'FontSize',14);
            group_ticks = (1:1) * n_tp - (n_tp-1)/2;
            set(ax3,'XTick',group_ticks,'XTickLabel',{'PLV Sum'});
            legend(ax3,'boxoff'); hold(ax3,'off');

        % ── dAM absolute ─────────────────────────────────────────────────
        case 'dAM'
            legend_string = build_legend(average.dAMpower, 0);
            fh1 = get_fig('APAT_efr_dAM_avg', sprintf('EFR dAM Average %s', level_tag));
            ax1 = axes(fh1); hold(ax1,'on'); grid(ax1,'on'); box(ax1,'off');
            for cols = 1:length(average.dAMpower)
                if ~isempty(average.dAMpower{1,cols})
                    plot(ax1, average.trajectory{1,cols}, average.dAMpower{1,cols}, ...
                        'Marker',shapes(cols,:),'LineStyle','-','LineWidth',3,'MarkerSize',9, ...
                        'Color',colors(cols,:),'MarkerFaceColor',colors(cols,:),'MarkerEdgeColor',colors(cols,:));
                    errorbar(ax1, average.trajectory{1,cols}, average.dAMpower{1,cols}, average.dAMpower_std{1,cols}, ...
                        'Marker',shapes(cols,:),'LineStyle','-','LineWidth',3,'MarkerSize',9, ...
                        'Color',colors(cols,:),'MarkerFaceColor',colors(cols,:),'MarkerEdgeColor',colors(cols,:), ...
                        'HandleVisibility','off');
                end
            end
            ylabel(ax1, y_units,'FontWeight','bold','FontSize',14);
            xlabel(ax1, x_units,'FontWeight','bold','FontSize',14);
            title(ax1, sprintf('EFR (%s) | %.0f dB SPL',title_str,level_spl),'FontWeight','bold','FontSize',14);
            legend(ax1, legend_string,'Location','southoutside','Orientation','horizontal');
            legend(ax1,'boxoff'); hold(ax1,'off');
            set_ylim_centered(ax1);
            set(ax1,'XScale','log','FontSize',14);
    end
end

%% ── RELATIVE MODE ────────────────────────────────────────────────────────────
if ~isempty(idx_plot_relative)
    switch plot_type
        % ── RAM relative ──────────────────────────────────────────────────
        case 'RAM'
            legend_string = build_legend(average.peaks, 1);

            % Figure 1: PLV spectrum (relative — continuous envelope + harmonic peaks)
            fh1 = get_fig('APAT_efr_RAM_avg', sprintf('EFR RAM Average %s', level_tag));
            ax1 = axes(fh1); hold(ax1,'on'); grid(ax1,'on'); box(ax1,'off');
            n_colors = size(colors, 1);
            for cols = 1:length(average.plv_env)
                cidx = mod(cols, n_colors) + 1;
                if ~isempty(average.plv_env{1,cols}) && ~isempty(average.f{1,cols})
                    plot(ax1, average.f{1,cols}, average.plv_env{1,cols}, ...
                        'LineStyle','-','LineWidth',1,'Color',[colors(cidx,:), 0.25], ...
                        'HandleVisibility','off');
                end
            end
            for cols = 1:length(average.peaks)
                cidx = mod(cols, n_colors) + 1;
                sh_idx = mod(cols, size(shapes,1)) + 1;
                if ~isempty(average.peaks_locs{1,cols})
                    errorbar(ax1, average.peaks_locs{1,cols}, average.peaks{1,cols}, average.peaks_std{1,cols}, ...
                        'Marker',shapes(sh_idx,:),'LineStyle','-','LineWidth',1.5,'MarkerSize',9, ...
                        'Color',colors(cidx,:),'MarkerFaceColor',colors(cidx,:),'MarkerEdgeColor',colors(cidx,:), ...
                        'HandleVisibility','off');
                    plot(ax1, average.peaks_locs{1,cols}, average.peaks{1,cols}, ...
                        'Marker',shapes(sh_idx,:),'LineStyle','-','LineWidth',1.5,'MarkerSize',9, ...
                        'Color',colors(cidx,:),'MarkerFaceColor',colors(cidx,:),'MarkerEdgeColor',colors(cidx,:));
                    plot(ax1, average.peaks_locs{1,cols}, zeros(size(average.peaks_locs{1,cols})), ...
                        'LineStyle','--','LineWidth',1.5,'Color','k','HandleVisibility','off');
                end
            end
            ylabel(ax1, 'PLV Shift (re. Baseline)','FontWeight','bold','FontSize',14);
            xlabel(ax1, x_units,'FontWeight','bold','FontSize',14);
            title(ax1, sprintf('EFR (%s) | %.0f dB SPL',title_str,level_spl),'FontWeight','bold','FontSize',14);
            legend(ax1, legend_string,'Location','southoutside','Orientation','horizontal');
            legend(ax1,'boxoff'); hold(ax1,'off');
            set_ylim_centered(ax1);
            last_nonempty = find(~cellfun(@isempty, average.peaks_locs(1,:)), 1, 'last');
            if ~isempty(last_nonempty)
                idx_pk = ~isnan(average.peaks_locs{1,last_nonempty});
                if any(idx_pk)
                    x_max = round(max(average.peaks_locs{1,last_nonempty}(idx_pk)),-3);
                    xticks(ax1, round(average.peaks_locs{1,last_nonempty}));
                    xlim(ax1,[0, x_max+200]);
                end
            end
            xtickangle(ax1,90); set(ax1,'XScale','linear','FontSize',14);

            % Figure 2: Low/High harmonics boxplot (relative)
            fh2 = get_fig('APAT_efr_RAM_harm', sprintf('EFR RAM Harmonics %s', level_tag));
            ax2 = axes(fh2); hold(ax2,'on'); grid(ax2,'on'); box(ax2,'off');
            freq_labels_harm = {'Low Harmonics (1-4)','High Harmonics (5-16)'};
            [~, n_tp] = draw_boxplot(ax2, average.all_low_high_peaks, freq_labels_harm);
            yline(ax2, 0,'k--','LineWidth',1.5);
            color_boxplot(ax2, colors, 1, n_tp);
            idx_rel = idx(:,2:end);
            conds_counts_idx = find(any(idx_rel,1));
            n_leg = numel(conds_counts_idx);
            leg_h = gobjects(n_leg,1);
            for li = 1:n_leg
                leg_h(li) = plot(ax2, NaN,NaN,'s', ...
                    'MarkerFaceColor',colors(mod(conds_counts_idx(li), n_colors)+1,:), ...
                    'MarkerEdgeColor','k','MarkerSize',9);
            end
            valid = isgraphics(leg_h);
            legend(ax2, leg_h(valid), legend_string,'Location','southoutside','Orientation','horizontal');
            ylabel(ax2, 'PLV Shift (re. Baseline)','FontWeight','bold','FontSize',14);
            title(ax2, sprintf('EFR Harmonic Contribution (%s) | %.0f dB SPL',title_str,level_spl),'FontWeight','bold','FontSize',14);
            set(ax2,'FontSize',14);
            group_ticks = (1:length(freq_labels_harm)) * n_tp - (n_tp-1)/2;
            set(ax2,'XTick',group_ticks,'XTickLabel',freq_labels_harm);
            legend(ax2,'boxoff'); hold(ax2,'off');

            % Figure 3: PLV sum boxplot (relative)
            fh3 = get_fig('APAT_efr_RAM_plvsum', sprintf('EFR RAM PLV Sum %s', level_tag));
            ax3 = axes(fh3); hold(ax3,'on'); grid(ax3,'on'); box(ax3,'off');
            [~, n_tp] = draw_boxplot(ax3, average.all_plv_sum, {'PLV Sum'});
            yline(ax3, 0,'k--','LineWidth',1.5);
            color_boxplot(ax3, colors, 1, n_tp);
            idx_rel = idx(:,2:end);
            conds_counts_idx = find(any(idx_rel,1));
            n_leg = numel(conds_counts_idx);
            leg_h = gobjects(n_leg,1);
            for li = 1:n_leg
                leg_h(li) = plot(ax3, NaN,NaN,'s', ...
                    'MarkerFaceColor',colors(mod(conds_counts_idx(li), n_colors)+1,:), ...
                    'MarkerEdgeColor','k','MarkerSize',9);
            end
            valid = isgraphics(leg_h);
            legend(ax3, leg_h(valid), legend_string,'Location','southoutside','Orientation','horizontal');
            ylabel(ax3, 'PLV Shift (re. Baseline)','FontWeight','bold','FontSize',14);
            title(ax3, sprintf('EFR Total PLV Sum (%s) | %.0f dB SPL',title_str,level_spl),'FontWeight','bold','FontSize',14);
            set(ax3,'FontSize',14);
            group_ticks = (1:1) * n_tp - (n_tp-1)/2;
            set(ax3,'XTick',group_ticks,'XTickLabel',{'PLV Sum'});
            legend(ax3,'boxoff'); hold(ax3,'off');

        % ── dAM relative ─────────────────────────────────────────────────
        case 'dAM'
            legend_string = build_legend(average.dAMpower, 1);
            fh1 = get_fig('APAT_efr_dAM_avg', sprintf('EFR dAM Average %s', level_tag));
            ax1 = axes(fh1); hold(ax1,'on'); grid(ax1,'on'); box(ax1,'off');
            for cols = 1:length(average.dAMpower)
                if ~isempty(average.dAMpower{1,cols})
                    plot(ax1, average.trajectory{1,cols}, average.dAMpower{1,cols}, ...
                        'Marker',shapes(cols+1,:),'LineStyle','-','LineWidth',3,'MarkerSize',9, ...
                        'Color',colors(cols+1,:),'MarkerFaceColor',colors(cols+1,:),'MarkerEdgeColor',colors(cols+1,:));
                    errorbar(ax1, average.trajectory{1,cols}, average.dAMpower{1,cols}, average.dAMpower_std{1,cols}, ...
                        'Marker',shapes(cols+1,:),'LineStyle','-','LineWidth',3,'MarkerSize',9, ...
                        'Color',colors(cols+1,:),'MarkerFaceColor',colors(cols+1,:),'MarkerEdgeColor',colors(cols+1,:), ...
                        'HandleVisibility','off');
                    plot(ax1, average.trajectory{1,cols}, zeros(size(average.trajectory{1,cols})), ...
                        'LineStyle','--','LineWidth',1.5,'Color','k','HandleVisibility','off');
                end
            end
            ylabel(ax1, 'Power Shift (re. Baseline)','FontWeight','bold','FontSize',14);
            xlabel(ax1, x_units,'FontWeight','bold','FontSize',14);
            title(ax1, sprintf('EFR (%s) | %.0f dB SPL',title_str,level_spl),'FontWeight','bold','FontSize',14);
            legend(ax1, legend_string,'Location','southoutside','Orientation','horizontal');
            legend(ax1,'boxoff'); hold(ax1,'off');
            set_ylim_centered(ax1);
            set(ax1,'XScale','log','FontSize',14);
    end
end

%% ── Local helper ─────────────────────────────────────────────────────────────

function set_ylim_centered(ax, pad)
if nargin < 2, pad = 0.12; end
all_y = [];
kids  = ax.Children;
for k = 1:numel(kids)
    try
        yd = double(get(kids(k),'YData'));
        all_y = [all_y, yd(isfinite(yd))]; %#ok<AGROW>
        if isprop(kids(k),'YNegativeDelta')
            v = yd - double(get(kids(k),'YNegativeDelta'));
            all_y = [all_y, v(isfinite(v))]; %#ok<AGROW>
        end
        if isprop(kids(k),'YPositiveDelta')
            v = yd + double(get(kids(k),'YPositiveDelta'));
            all_y = [all_y, v(isfinite(v))]; %#ok<AGROW>
        end
    catch, end
end
if isempty(all_y), return; end
lo = min(all_y);  hi = max(all_y);
rng = hi - lo;
if rng == 0, rng = max(abs(lo), 0.1); end
ylim(ax, [lo - pad*rng, hi + pad*rng]);
end

%% Save data and export figures
average.subjects   = Chins2Run;
average.conditions = [convertCharsToStrings(all_Conds2Run(:)'); idx];
cd(outpath);
save(filename,'average');
set(fh1,'Visible','off');
exportgraphics(fh1,[filename,'_figure.png'],'Resolution',300);
if strcmp(plot_type,'RAM')
    set(fh2,'Visible','off');
    exportgraphics(fh2,[filename,'_PLVharmonics_figure.png'],'Resolution',300);
    close(fh2);
    set(fh3,'Visible','off');
    exportgraphics(fh3,[filename,'_PLVsum_figure.png'],'Resolution',300);
    close(fh3);
end
cd(cwd);
end
