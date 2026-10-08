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
                'LineStyle','-','LineWidth',1.5, ...
                'Color',[colors(cidx,:) 0.25], ...
                'HandleVisibility','off');
        end
    end

    % Harmonic peaks with error bars (mean ± SD)
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
            'Marker',shapes(sh_idx,:),'LineStyle','-', ...
            'LineWidth',2,'MarkerSize',9,'CapSize',5, ...
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

    title(ax, sprintf('%.0f dB SPL', all_levels(li)), 'FontWeight','bold','FontSize',14);
    if k == 1
        if isempty(idx_plot_relative)
            ylabel(ax,'PLV','FontWeight','bold','FontSize',14);
        else
            ylabel(ax,'PLV Shift (re. Baseline)','FontWeight','bold','FontSize',14);
        end
    end
    xlabel(ax,'Frequency (Hz)','FontWeight','bold','FontSize',13);
    set(ax,'FontSize',13);
    hold(ax,'off');
end

% Legend anchored to last subplot
if n_valid >= 1 && ~isempty(legend_string)
    ax_last = findobj(fh1,'Type','axes');
    ax_last = ax_last(1);   % most recently created = last subplot
    legend(ax_last, legend_string, 'Location','northeast','FontSize',12,'Box','off');
end
annotation(fh1,'textbox',[0 0.93 1 0.07], ...
    'String','EFR RAM 223 Hz — Average PLV Spectrum', ...
    'FontWeight','bold','FontSize',14,'HorizontalAlignment','center', ...
    'EdgeColor','none','FitBoxToText','off');


% ── Figure 2: PLV Sum ────────────────────────────────────────────────────
fh2 = figure('Name','PLV Sum|All Levels','NumberTitle','off', ...
    'Visible','off','Color','w','Units','normalized', ...
    'Position',[0.05 0.1 min(0.3*n_valid+0.2, 0.9) 0.75]);

for k = 1:n_valid
    li      = valid_li(k);
    average = averages{li};
    [n_subj, n_c] = size(average.all_low_high_peaks);

    x  = PAD_L + (k-1)*(w_ax + inter);
    ax = axes(fh2, 'Position',[x PAD_B w_ax 1-PAD_T-PAD_B]); %#ok<LAXES>
    hold(ax,'on'); grid(ax,'on'); box(ax,'off');

    if n_c > 1
        offsets = linspace(-0.25, 0.25, n_c);
    else
        offsets = 0;
    end

    for g = 1:3
        for c = 1:n_c
            data_vals = nan(n_subj, 1);
            for s = 1:n_subj
                lh = average.all_low_high_peaks{s,c};
                ps = average.all_plv_sum{s,c};
                if isempty(lh) || numel(lh) < 2, lh = [NaN NaN]; end
                if isempty(ps) || ~isscalar(ps), ps = NaN; end
                switch g
                    case 1, data_vals(s) = lh(1);
                    case 2, data_vals(s) = lh(2);
                    case 3, data_vals(s) = ps;
                end
            end
            valid = data_vals(~isnan(data_vals));
            if isempty(valid), continue; end
            cidx = mod(c - 1 + col_offset, n_colors) + 1;
            xc   = g + offsets(c);
            % Individual subject dots
            hs = scatter(ax, xc*ones(numel(valid),1), valid, 20, colors(cidx,:), 'filled', ...
                'HandleVisibility','off');
            hs.MarkerFaceAlpha = 0.35;
            % Mean ± SD errorbar (legend entry only for first group)
            m  = nanmean(valid);
            sd = nanstd(valid);
            if g == 1 && c <= numel(legend_string)
                hv = 'on'; dname = legend_string{c};
            else
                hv = 'off'; dname = '';
            end
            errorbar(ax, xc, m, sd, ...
                'Color',colors(cidx,:),'LineWidth',2,'CapSize',6, ...
                'Marker','o','MarkerFaceColor',colors(cidx,:),'MarkerSize',8, ...
                'DisplayName',dname,'HandleVisibility',hv);
        end
    end

    if ~isempty(idx_plot_relative)
        yline(ax, 0,'k--','LineWidth',1.5,'HandleVisibility','off');
    end

    set(ax,'XTick',1:3,'XTickLabel',{'Low (1-4)','High (5-16)','Total'},'FontSize',13);
    xlim(ax,[0.5, 3.5]);
    title(ax, sprintf('%.0f dB SPL', all_levels(li)),'FontWeight','bold','FontSize',14);
    if k == 1
        if isempty(idx_plot_relative)
            ylabel(ax,'PLV Sum','FontWeight','bold','FontSize',14);
        else
            ylabel(ax,'PLV Shift (re. Baseline)','FontWeight','bold','FontSize',14);
        end
    end
    set(ax,'FontSize',13);
    hold(ax,'off');
end

% Legend anchored to first subplot
if n_valid >= 1 && ~isempty(legend_string) && n_conds > 0
    ax_first = findobj(fh2,'Type','axes');
    ax_first = ax_first(end);   % oldest = first subplot
    legend(ax_first,'Location','northeast','FontSize',12,'Box','off');
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
