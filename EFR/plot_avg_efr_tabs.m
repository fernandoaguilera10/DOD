function plot_avg_efr_tabs(averages, all_levels, colors, shapes, idx, conds_idx, ...
    Chins2Run, Conds2Run, all_Conds2Run, outpath, ylimits, idx_plot_relative)
%PLOT_AVG_EFR_TABS  Create combined tab figures for EFR RAM app embedding.
%
%   Two figures are created with Visible='off' for embedding into the app:
%     "PLV Average|All Levels" — PLV spectrum (envelope + peaks) per level
%     "PLV Sum|All Levels"     — Low / High / Total PLV sum per level
%
%   Each figure shows all available levels as side-by-side subplots so every
%   level is visible simultaneously within its tab.

valid_li = find(~cellfun(@isempty, averages));
if isempty(valid_li), return; end
n_valid = numel(valid_li);

n_colors = size(colors, 1);
n_shapes = size(shapes,  1);
col_offset = double(~isempty(idx_plot_relative));   % 0=absolute, 1=relative

% Legend labels from first valid average
av0           = averages{valid_li(1)};
legend_string = build_legend_local(av0.peaks, col_offset, idx, all_Conds2Run);
n_conds       = numel(legend_string);

% Shared axis width layout
PAD_L = 0.10;  PAD_R = 0.03;
PAD_T = 0.13;  PAD_B = 0.20;
inter = 0.04;
w_ax  = (1 - PAD_L - PAD_R - (n_valid-1)*inter) / max(n_valid, 1);

% ── Figure 1: PLV Average ────────────────────────────────────────────────
fh1 = figure('Name','PLV Average|All Levels','NumberTitle','off', ...
    'Visible','off','Color','w','Units','normalized', ...
    'Position',[0.05 0.1 min(0.3*n_valid+0.2, 0.9) 0.75]);

for k = 1:n_valid
    li      = valid_li(k);
    average = averages{li};

    x  = PAD_L + (k-1)*(w_ax + inter);
    ax = axes(fh1, 'Position',[x PAD_B w_ax 1-PAD_T-PAD_B]); %#ok<LAXES>
    hold(ax,'on'); grid(ax,'on'); box(ax,'off');

    % Continuous PLV envelope — light background lines
    for c = 1:numel(average.plv_env)
        cidx = mod(c - 1 + col_offset, n_colors) + 1;
        if ~isempty(average.plv_env{1,c}) && ~isempty(average.f{1,c})
            plot(ax, average.f{1,c}, average.plv_env{1,c}, ...
                'LineStyle','-','LineWidth',1, ...
                'Color',[colors(cidx,:) 0.18], ...
                'HandleVisibility','off');
        end
    end

    % Harmonic peaks with error bars
    for c = 1:numel(average.peaks)
        cidx   = mod(c - 1 + col_offset, n_colors) + 1;
        sh_idx = mod(c - 1 + col_offset, n_shapes) + 1;
        locs   = average.peaks_locs{1,c};
        pks    = average.peaks{1,c};
        pks_sd = average.peaks_std{1,c};
        if isempty(locs) || isempty(pks), continue; end
        dname = '';
        if c <= numel(legend_string), dname = legend_string{c}; end
        errorbar(ax, locs, pks, pks_sd, ...
            'Marker',shapes(sh_idx,:),'LineStyle','none', ...
            'LineWidth',1.5,'MarkerSize',8,'CapSize',3, ...
            'Color',colors(cidx,:),'MarkerFaceColor',colors(cidx,:), ...
            'HandleVisibility','off');
        plot(ax, locs, pks, ...
            'Marker',shapes(sh_idx,:),'LineStyle','-', ...
            'LineWidth',1.5,'MarkerSize',8, ...
            'Color',colors(cidx,:),'MarkerFaceColor',colors(cidx,:), ...
            'DisplayName',dname);
    end

    if ~isempty(idx_plot_relative)
        yline(ax, 0,'k--','LineWidth',1.5,'HandleVisibility','off');
    end

    % X limits and ticks at harmonic frequencies
    last_ne = find(~cellfun(@isempty, average.peaks_locs(1,:)), 1,'last');
    if ~isempty(last_ne)
        locs_ref = average.peaks_locs{1,last_ne};
        valid_locs = locs_ref(~isnan(locs_ref));
        if ~isempty(valid_locs)
            xlim(ax,[0, round(max(valid_locs),-3)+200]);
            xticks(ax, round(locs_ref));
        end
    end
    xtickangle(ax, 45);
    set_ylim_local(ax);

    title(ax, sprintf('%.0f dB SPL', all_levels(li)), 'FontWeight','bold','FontSize',13);
    if k == 1
        if isempty(idx_plot_relative)
            ylabel(ax,'PLV','FontWeight','bold','FontSize',12);
        else
            ylabel(ax,'PLV Shift (re. Baseline)','FontWeight','bold','FontSize',12);
        end
    end
    xlabel(ax,'Frequency (Hz)','FontWeight','bold','FontSize',12);
    set(ax,'FontSize',11);
    hold(ax,'off');
end

% Legend anchored to last subplot
if n_valid >= 1 && ~isempty(legend_string)
    ax_last = findobj(fh1,'Type','axes');
    ax_last = ax_last(1);   % most recently created = last subplot
    legend(ax_last, legend_string, 'Location','northeast','FontSize',10,'Box','off');
end
annotation(fh1,'textbox',[0 0.93 1 0.07], ...
    'String','EFR RAM 223 Hz — Average PLV Spectrum', ...
    'FontWeight','bold','FontSize',14,'HorizontalAlignment','center', ...
    'EdgeColor','none','FitBoxToText','off');


% ── Figure 2: PLV Sum ────────────────────────────────────────────────────
fh2 = figure('Name','PLV Sum|All Levels','NumberTitle','off', ...
    'Visible','off','Color','w','Units','normalized', ...
    'Position',[0.05 0.1 min(0.3*n_valid+0.2, 0.9) 0.75]);

freq_labels_3 = {'Low (1-4)','High (5-16)','Total'};

for k = 1:n_valid
    li      = valid_li(k);
    average = averages{li};
    [n_subj, n_c] = size(average.all_low_high_peaks);

    x  = PAD_L + (k-1)*(w_ax + inter);
    ax = axes(fh2, 'Position',[x PAD_B w_ax 1-PAD_T-PAD_B]); %#ok<LAXES>
    hold(ax,'on'); grid(ax,'on'); box(ax,'off');

    % Build 3-group combined data matrix for boxplot
    vals = []; grps = []; tps = [];
    for s = 1:n_subj
        for t = 1:n_c
            lh = average.all_low_high_peaks{s,t};
            ps = average.all_plv_sum{s,t};
            if isempty(lh) || numel(lh) < 2, lh = [NaN NaN]; end
            if isempty(ps)  || ~isscalar(ps), ps = NaN; end
            d = [lh(1), lh(2), ps];
            for g = 1:3
                vals(end+1) = d(g); %#ok<AGROW>
                grps(end+1) = g;    %#ok<AGROW>
                tps(end+1)  = t;    %#ok<AGROW>
            end
        end
    end

    if ~isempty(vals) && any(~isnan(vals))
        boxplot(ax, vals(:), {grps(:), tps(:)}, ...
            'factorseparator',1,'labelverbosity','minor', ...
            'ColorGroup',tps(:),'Symbol','*');
        color_boxplot_local(ax, colors, col_offset, n_c);
        group_ticks = (1:3)*n_c - (n_c-1)/2;
        set(ax,'XTick',group_ticks,'XTickLabel',freq_labels_3,'FontSize',11);
    end

    if ~isempty(idx_plot_relative)
        yline(ax, 0,'k--','LineWidth',1.5);
    end

    title(ax, sprintf('%.0f dB SPL', all_levels(li)),'FontWeight','bold','FontSize',13);
    if k == 1
        if isempty(idx_plot_relative)
            ylabel(ax,'PLV Sum','FontWeight','bold','FontSize',12);
        else
            ylabel(ax,'PLV Shift (re. Baseline)','FontWeight','bold','FontSize',12);
        end
    end
    set(ax,'FontSize',11);
    hold(ax,'off');
end

% Condition legend in first subplot
if n_valid >= 1 && ~isempty(legend_string) && n_conds > 0
    ax_first = findobj(fh2,'Type','axes');
    ax_first = ax_first(end);   % oldest = first subplot
    leg_h = gobjects(n_conds, 1);
    for ci = 1:n_conds
        cidx      = mod(ci - 1 + col_offset, n_colors) + 1;
        leg_h(ci) = plot(ax_first, NaN, NaN, 's', ...
            'MarkerFaceColor',colors(cidx,:),'MarkerEdgeColor','k','MarkerSize',9);
    end
    valid_leg = isgraphics(leg_h);
    legend(ax_first, leg_h(valid_leg), legend_string(1:sum(valid_leg)), ...
        'Location','northeast','FontSize',10,'Box','off');
end
annotation(fh2,'textbox',[0 0.93 1 0.07], ...
    'String','EFR RAM 223 Hz — PLV Sum (Low / High / Total)', ...
    'FontWeight','bold','FontSize',14,'HorizontalAlignment','center', ...
    'EdgeColor','none','FitBoxToText','off');

end


% ── Local helpers ─────────────────────────────────────────────────────────

function ls = build_legend_local(avg_field, col_offset, idx, all_Conds2Run)
n_c  = size(avg_field, 2);
temp = cell(1, n_c);
for c = 1:n_c
    ci = c + col_offset;
    if ci <= numel(all_Conds2Run) && ci <= size(idx,2)
        parts = strsplit(cell2mat(all_Conds2Run(ci)), filesep);
        lbl   = parts{end};
        temp{c} = sprintf('%s (n=%d)', lbl, sum(idx(:,ci)));
    end
end
ls = temp(~cellfun(@isempty, temp));
end


function color_boxplot_local(ax, colors_in, col_offset, n_conds)
bH  = flipud(findobj(ax,'Tag','Box'));
mH  = flipud(findobj(ax,'Tag','Median'));
uwH = flipud(findobj(ax,'Tag','Upper Whisker'));
lwH = flipud(findobj(ax,'Tag','Lower Whisker'));
c1H = flipud(findobj(ax,'Tag','Upper Adjacent Value'));
c2H = flipud(findobj(ax,'Tag','Lower Adjacent Value'));
oH  = flipud(findobj(ax,'Tag','Outliers'));
n_boxes  = numel(bH);
n_colors = size(colors_in, 1);
for bi = 1:n_boxes
    tp_idx = mod(bi-1, n_conds) + 1;
    cidx   = mod(tp_idx + col_offset - 1, n_colors) + 1;
    c      = colors_in(cidx, :);
    xd = get(bH(bi),'XData'); yd = get(bH(bi),'YData');
    patch(ax, xd([1 2 3 4 1]), yd([1 2 3 4 1]), c, 'FaceAlpha',0.5,'EdgeColor','none');
    set(bH(bi),'Color',c,'LineWidth',2);
    set(mH(bi),'Color',c,'LineWidth',2);
    if ~isempty(uwH), set(uwH(bi),'Color',c,'LineWidth',2); end
    if ~isempty(lwH), set(lwH(bi),'Color',c,'LineWidth',2); end
    if ~isempty(c1H), set(c1H(bi),'Color',c,'LineWidth',2); end
    if ~isempty(c2H), set(c2H(bi),'Color',c,'LineWidth',2); end
    if ~isempty(oH),  set(oH(bi),'MarkerEdgeColor',c,'LineWidth',2); end
end
end


function set_ylim_local(ax, pad)
if nargin < 2, pad = 0.12; end
all_y = [];
for k = 1:numel(ax.Children)
    try
        yd = double(get(ax.Children(k),'YData'));
        all_y = [all_y, yd(isfinite(yd))]; %#ok<AGROW>
        if isprop(ax.Children(k),'YNegativeDelta')
            v = yd - double(get(ax.Children(k),'YNegativeDelta'));
            all_y = [all_y, v(isfinite(v))]; %#ok<AGROW>
        end
        if isprop(ax.Children(k),'YPositiveDelta')
            v = yd + double(get(ax.Children(k),'YPositiveDelta'));
            all_y = [all_y, v(isfinite(v))]; %#ok<AGROW>
        end
    catch, end
end
if isempty(all_y), return; end
lo = min(all_y); hi = max(all_y);
rng = hi - lo;
if rng == 0, rng = max(abs(lo), 0.1); end
ylim(ax, [lo - pad*rng, hi + pad*rng]);
end
