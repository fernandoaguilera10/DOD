function plot_avg_efr(average, plot_type, level_spl, colors, shapes, idx, conds_idx, Chins2Run, Conds2Run, all_Conds2Run, outpath, filename, counter, ylimits, idx_plot_relative)
% Plot EFR average figures and export.  plot_type: 'RAM' | 'dAM'
cwd = pwd;
legend_string = [];

switch plot_type
    case 'RAM'
        y_units  = 'PLV';
        title_str = 'RAM 223 Hz';
    case 'dAM'
        y_units  = 'Power (dB)';
        title_str = 'dAM 4 kHz';
end
x_units = 'Frequency (Hz)';

%% Helper: find or create a figure (Visible off, clear on first create)
    function fh = get_fig(tag, name)
        fh = findobj('Type','figure','Tag',tag);
        if isempty(fh)
            fh = figure('Name',name,'NumberTitle','off','Tag',tag,'Visible','off');
            clf(fh);
        else
            fh = fh(1); set(0,'CurrentFigure',fh); clf;
        end
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
    function color_boxplot(colors_in, col_offset)
        boxHandles         = flipud(findobj(gca,'Tag','Box'));
        medianHandles      = flipud(findobj(gca,'Tag','Median'));
        upperWhiskerH      = flipud(findobj(gca,'Tag','Upper Whisker'));
        lowerWhiskerH      = flipud(findobj(gca,'Tag','Lower Whisker'));
        capH               = flipud(findobj(gca,'Tag','Upper Adjacent Value'));
        capH2              = flipud(findobj(gca,'Tag','Lower Adjacent Value'));
        outlierH           = flipud(findobj(gca,'Tag','Outliers'));
        n_tp = length(boxHandles);
        for bi = 1:n_tp
            tp_idx = mod(bi-1, n_tp) + 1;
            c = colors_in(tp_idx + col_offset, :);
            x = get(boxHandles(bi),'XData');
            y = get(boxHandles(bi),'YData');
            patch(x([1 2 3 4 1]), y([1 2 3 4 1]), c, 'FaceAlpha',0.5,'EdgeColor','none');
            set(boxHandles(bi),    'Color',c,'LineWidth',3);
            set(medianHandles(bi), 'Color',c,'LineWidth',3);
            set(upperWhiskerH(bi), 'Color',c,'LineWidth',3);
            set(lowerWhiskerH(bi), 'Color',c,'LineWidth',3);
            set(capH(bi),          'Color',c,'LineWidth',3);
            set(capH2(bi),         'Color',c,'LineWidth',3);
            set(gca,'XTick',[]);
            set(outlierH(bi),'MarkerEdgeColor',c,'LineWidth',3);
        end
        % Thicken factor separator lines
        all_lines = findobj(gca,'Type','Line');
        for li = 1:length(all_lines)
            xd = get(all_lines(li),'XData'); yd = get(all_lines(li),'YData');
            if length(xd) >= 2 && abs(xd(2)-xd(1)) < 0.01 && (yd(2)-yd(1)) > range(ylim)*0.9
                set(all_lines(li),'LineWidth',3,'LineStyle','-','Color','k');
            end
        end
    end

%% Helper: draw a boxplot dataset
    function [timepoints, n_tp_unique] = draw_boxplot(data_cell, freq_labels)
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
        boxplot(vals(:), {freqs(:), timepoints(:)}, ...
            'factorseparator',1,'labelverbosity','minor','ColorGroup',timepoints(:),'Symbol','*');
        n_tp_unique = length(unique(timepoints));
    end

%% Helper: add colored legend squares for conditions
    function add_box_legend(ls, conds_idx_in, col_offset)
        conds_counts_idx = find(any(idx,1));
        n_leg = numel(conds_counts_idx);
        leg_h = gobjects(n_leg,1);
        for li = 1:n_leg
            leg_h(li) = plot(NaN,NaN,'s','MarkerFaceColor',colors(conds_counts_idx(li)+col_offset,:), ...
                'MarkerEdgeColor','k','MarkerSize',15);
        end
        valid = isgraphics(leg_h);
        legend(leg_h(valid), ls, 'Location','southoutside','Orientation','horizontal');
        legend boxoff;
    end

%% ── ABSOLUTE MODE ────────────────────────────────────────────────────────────
if isempty(idx_plot_relative)
    switch plot_type
        % ── RAM absolute ──────────────────────────────────────────────────
        case 'RAM'
            legend_string = build_legend(average.peaks, 0);

            % Figure 1: PLV spectrum
            fh1 = get_fig('APAT_efr_RAM_avg', 'EFR RAM Average');
            hold on;
            for cols = 1:length(average.peaks)
                if ~isempty(average.peaks_locs{1,cols})
                    errorbar(average.peaks_locs{1,cols}, average.peaks{1,cols}, average.peaks_std{1,cols}, ...
                        'Marker',shapes(cols,:),'LineStyle','-','LineWidth',3,'MarkerSize',15, ...
                        'Color',colors(cols,:),'MarkerFaceColor',colors(cols,:),'MarkerEdgeColor',colors(cols,:), ...
                        'HandleVisibility','off');
                    avg_fit = fillmissing(average.peaks{1,cols},'linear', ...
                        'SamplePoints',average.peaks_locs{find(~cellfun(@isempty,average.peaks_locs(:,cols)),1),cols});
                    plot(average.peaks_locs{1,cols}, avg_fit, ...
                        'Marker',shapes(cols,:),'LineStyle','-','LineWidth',3,'MarkerSize',15, ...
                        'Color',colors(cols,:),'MarkerFaceColor',colors(cols,:),'MarkerEdgeColor',colors(cols,:));
                end
            end
            ylabel(y_units,'FontWeight','bold');
            xlabel(x_units,'FontWeight','bold');
            title(sprintf('EFR (%s) | %.0f dB SPL',title_str,level_spl),'FontWeight','bold');
            legend(legend_string,'Location','southoutside','Orientation','horizontal');
            legend boxoff; hold off; grid on;
            if ~isempty(ylimits), ylim(ylimits); end
            idx_pk = ~isnan(average.peaks{1,end});
            if any(idx_pk)
                xlim([0, round(max(average.peaks_locs{1,end}(idx_pk)),-3)]);
            end
            set(gca,'XScale','linear','FontSize',25); xticks(round(average.peaks_locs{1,end}));
            box off;

            % Figure 2: Low/High harmonics boxplot
            fh2 = get_fig('APAT_efr_RAM_harm', 'EFR RAM Harmonics');
            hold on;
            freq_labels_harm = {'Low Harmonics (1-4)','High Harmonics (5-16)'};
            [timepoints, n_tp] = draw_boxplot(average.all_low_high_peaks, freq_labels_harm);
            color_boxplot(colors, 0);
            add_box_legend(legend_string, conds_idx, 0);
            ylabel(y_units,'FontWeight','bold');
            title(sprintf('EFR Harmonic Contribution (%s) | %.0f dB SPL',title_str,level_spl),'FontWeight','bold');
            set(gca,'FontSize',25);
            group_ticks = (1:length(freq_labels_harm)) * n_tp - (n_tp-1)/2;
            set(gca,'XTick',group_ticks,'XTickLabel',freq_labels_harm);
            legend boxoff; hold off; box off;

            % Figure 3: PLV sum boxplot
            fh3 = get_fig('APAT_efr_RAM_plvsum', 'EFR RAM PLV Sum');
            hold on;
            [timepoints, n_tp] = draw_boxplot(average.all_plv_sum, {'PLV Sum'});
            color_boxplot(colors, 0);
            add_box_legend(legend_string, conds_idx, 0);
            ylabel('PLV Sum','FontWeight','bold');
            title(sprintf('EFR Total PLV Sum (%s) | %.0f dB SPL',title_str,level_spl),'FontWeight','bold');
            set(gca,'FontSize',25);
            group_ticks = (1:1) * n_tp - (n_tp-1)/2;
            set(gca,'XTick',group_ticks,'XTickLabel',{'PLV Sum'});
            legend boxoff; hold off; box off;

        % ── dAM absolute ─────────────────────────────────────────────────
        case 'dAM'
            legend_string = build_legend(average.dAMpower, 0);
            fh1 = get_fig('APAT_efr_dAM_avg', 'EFR dAM Average');
            hold on;
            for cols = 1:length(average.dAMpower)
                if ~isempty(average.dAMpower{1,cols})
                    plot(average.trajectory{1,cols}, average.dAMpower{1,cols}, ...
                        'Marker',shapes(cols,:),'LineStyle','-','LineWidth',3,'MarkerSize',15, ...
                        'Color',colors(cols,:),'MarkerFaceColor',colors(cols,:),'MarkerEdgeColor',colors(cols,:));
                    errorbar(average.trajectory{1,cols}, average.dAMpower{1,cols}, average.dAMpower_std{1,cols}, ...
                        'Marker',shapes(cols,:),'LineStyle','-','LineWidth',3,'MarkerSize',15, ...
                        'Color',colors(cols,:),'MarkerFaceColor',colors(cols,:),'MarkerEdgeColor',colors(cols,:), ...
                        'HandleVisibility','off');
                end
            end
            ylabel(y_units,'FontWeight','bold');
            xlabel(x_units,'FontWeight','bold');
            title(sprintf('EFR (%s) | %.0f dB SPL',title_str,level_spl),'FontWeight','bold');
            legend(legend_string,'Location','southoutside','Orientation','horizontal');
            legend boxoff; hold off; grid on;
            if ~isempty(ylimits), ylim(ylimits); end
            set(gca,'XScale','log','FontSize',25); box off;
    end
end

%% ── RELATIVE MODE ────────────────────────────────────────────────────────────
if ~isempty(idx_plot_relative)
    switch plot_type
        % ── RAM relative ──────────────────────────────────────────────────
        case 'RAM'
            legend_string = build_legend(average.peaks, 1);

            % Figure 1: PLV spectrum (relative)
            fh1 = get_fig('APAT_efr_RAM_avg', 'EFR RAM Average');
            hold on;
            for cols = 1:length(average.peaks)
                if ~isempty(average.peaks_locs{1,cols})
                    errorbar(average.peaks_locs{1,cols}, average.peaks{1,cols}, average.peaks_std{1,cols}, ...
                        'Marker',shapes(cols+1,:),'LineStyle','-','LineWidth',3,'MarkerSize',15, ...
                        'Color',colors(cols+1,:),'MarkerFaceColor',colors(cols+1,:),'MarkerEdgeColor',colors(cols+1,:), ...
                        'HandleVisibility','off');
                    plot(average.peaks_locs{1,cols}, average.peaks{1,cols}, ...
                        'Marker',shapes(cols+1,:),'LineStyle','-','LineWidth',3,'MarkerSize',15, ...
                        'Color',colors(cols+1,:),'MarkerFaceColor',colors(cols+1,:),'MarkerEdgeColor',colors(cols+1,:));
                    plot(average.peaks_locs{1,cols}, zeros(size(average.peaks_locs{1,cols})), ...
                        'LineStyle','--','LineWidth',3,'Color','k','HandleVisibility','off');
                end
            end
            ylabel('PLV Shift (re. Baseline)','FontWeight','bold');
            xlabel(x_units,'FontWeight','bold');
            title(sprintf('EFR (%s) | %.0f dB SPL',title_str,level_spl),'FontWeight','bold');
            legend(legend_string,'Location','southoutside','Orientation','horizontal');
            legend boxoff; hold off; grid on;
            if ~isempty(ylimits), ylim(ylimits); end
            idx_pk = ~isnan(average.peaks{1,end});
            if any(idx_pk)
                x_max = round(max(average.peaks_locs{1,end}(idx_pk)),-3);
                xticks(round(average.peaks_locs{1,end}));
                xlim([0, x_max+200]);
            end
            xtickangle(90); set(gca,'XScale','linear','FontSize',25); box off;

            % Figure 2: Low/High harmonics boxplot (relative)
            fh2 = get_fig('APAT_efr_RAM_harm', 'EFR RAM Harmonics');
            hold on;
            freq_labels_harm = {'Low Harmonics (1-4)','High Harmonics (5-16)'};
            [timepoints, n_tp] = draw_boxplot(average.all_low_high_peaks, freq_labels_harm);
            yline(0,'k--','LineWidth',3);
            color_boxplot(colors, 1);
            idx_rel = idx(:,2:end);
            conds_counts_idx = find(any(idx_rel,1));
            n_leg = numel(conds_counts_idx);
            leg_h = gobjects(n_leg,1);
            for li = 1:n_leg
                leg_h(li) = plot(NaN,NaN,'s','MarkerFaceColor',colors(conds_counts_idx(li)+1,:), ...
                    'MarkerEdgeColor','k','MarkerSize',15);
            end
            valid = isgraphics(leg_h);
            legend(leg_h(valid), legend_string,'Location','southoutside','Orientation','horizontal');
            ylabel('PLV Shift (re. Baseline)','FontWeight','bold');
            title(sprintf('EFR Harmonic Contribution (%s) | %.0f dB SPL',title_str,level_spl),'FontWeight','bold');
            set(gca,'FontSize',25);
            group_ticks = (1:length(freq_labels_harm)) * n_tp - (n_tp-1)/2;
            set(gca,'XTick',group_ticks,'XTickLabel',freq_labels_harm);
            legend boxoff; hold off; box off;

            % Figure 3: PLV sum boxplot (relative)
            fh3 = get_fig('APAT_efr_RAM_plvsum', 'EFR RAM PLV Sum');
            hold on;
            [timepoints, n_tp] = draw_boxplot(average.all_plv_sum, {'PLV Sum'});
            yline(0,'k--','LineWidth',3);
            color_boxplot(colors, 1);
            idx_rel = idx(:,2:end);
            conds_counts_idx = find(any(idx_rel,1));
            n_leg = numel(conds_counts_idx);
            leg_h = gobjects(n_leg,1);
            for li = 1:n_leg
                leg_h(li) = plot(NaN,NaN,'s','MarkerFaceColor',colors(conds_counts_idx(li)+1,:), ...
                    'MarkerEdgeColor','k','MarkerSize',15);
            end
            valid = isgraphics(leg_h);
            legend(leg_h(valid), legend_string,'Location','southoutside','Orientation','horizontal');
            ylabel('PLV Shift (re. Baseline)','FontWeight','bold');
            title(sprintf('EFR Total PLV Sum (%s) | %.0f dB SPL',title_str,level_spl),'FontWeight','bold');
            set(gca,'FontSize',25);
            group_ticks = (1:1) * n_tp - (n_tp-1)/2;
            set(gca,'XTick',group_ticks,'XTickLabel',{'PLV Sum'});
            legend boxoff; hold off; box off;

        % ── dAM relative ─────────────────────────────────────────────────
        case 'dAM'
            legend_string = build_legend(average.dAMpower, 1);
            fh1 = get_fig('APAT_efr_dAM_avg', 'EFR dAM Average');
            hold on;
            for cols = 1:length(average.dAMpower)
                if ~isempty(average.dAMpower{1,cols})
                    plot(average.trajectory{1,cols}, average.dAMpower{1,cols}, ...
                        'Marker',shapes(cols+1,:),'LineStyle','-','LineWidth',3,'MarkerSize',15, ...
                        'Color',colors(cols+1,:),'MarkerFaceColor',colors(cols+1,:),'MarkerEdgeColor',colors(cols+1,:));
                    errorbar(average.trajectory{1,cols}, average.dAMpower{1,cols}, average.dAMpower_std{1,cols}, ...
                        'Marker',shapes(cols+1,:),'LineStyle','-','LineWidth',3,'MarkerSize',15, ...
                        'Color',colors(cols+1,:),'MarkerFaceColor',colors(cols+1,:),'MarkerEdgeColor',colors(cols+1,:), ...
                        'HandleVisibility','off');
                    plot(average.trajectory{1,cols}, zeros(size(average.trajectory{1,cols})), ...
                        'LineStyle','--','LineWidth',3,'Color','k','HandleVisibility','off');
                end
            end
            ylabel('Power Shift (re. Baseline)','FontWeight','bold');
            xlabel(x_units,'FontWeight','bold');
            title(sprintf('EFR (%s) | %.0f dB SPL',title_str,level_spl),'FontWeight','bold');
            legend(legend_string,'Location','southoutside','Orientation','horizontal');
            legend boxoff; hold off; grid on;
            if ~isempty(ylimits), ylim(ylimits); end
            set(gca,'XScale','log','FontSize',25); box off;
    end
end

%% Save data and export figures
average.subjects   = Chins2Run;
average.conditions = [convertCharsToStrings(all_Conds2Run(:)'); idx];
cd(outpath);
save(filename,'average');
drawnow;
exportgraphics(fh1,[filename,'_figure.png'],'Resolution',300);
if strcmp(plot_type,'RAM')
    exportgraphics(fh2,[filename,'_PLVharmonics_figure.png'],'Resolution',300);
    exportgraphics(fh3,[filename,'_PLVsum_figure.png'],'Resolution',300);
end
cd(cwd);
end
