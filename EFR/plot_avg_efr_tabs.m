function plot_avg_efr_tabs(averages, all_levels, colors, shapes, idx, conds_idx, ...
    Chins2Run, Conds2Run, all_Conds2Run, outpath, ylimits, idx_plot_relative) %#ok<INUSL>
%PLOT_AVG_EFR_TABS  EFR RAM average figures for the app (ABR-style format).
%   One figure per level ('Level|<lev> dB SPL', Tag 'APAT_efr_avg'):
%     left  — mean PLV spectrum + harmonic peaks (mean ± SD)
%     right — harmonic sums: Low / High / Sum (all harmonics), conditions
%             side by side within each group
%   Individual subjects: Tag 'efr_subj_pts', subject ID in DisplayName
%   (spectrum: hidden by default; sums: shown). Condition legend centred
%   under the plots; right strip left free for the app's controls.
valid_li = find(~cellfun(@isempty, averages));
if isempty(valid_li), return; end
col_offset = double(~isempty(idx_plot_relative));
rel = ~isempty(idx_plot_relative);
[cnames, cidx_list] = cond_info(averages{valid_li(1)}.peaks, col_offset, idx, all_Conds2Run, size(colors,1));

% ── One figure per level: PLV spectrum (left) + harmonic sums (right) ───
% Name 'Level|<lev> dB SPL', Tag 'APAT_efr_avg' → the app shows one level at
% a time, chosen with the Level dropdown in the Results bar.
for k = 1:numel(valid_li)
    li = valid_li(k);  A = averages{li};
    fh = new_fig(sprintf('Level|%d dB SPL', round(all_levels(li))));
    axP = axes(fh, 'Position',[0.06 0.22 0.42 0.64], 'Tag','efr_spec_tile');  hold(axP,'on');
    axS = axes(fh, 'Position',[0.56 0.22 0.26 0.64], 'Tag','efr_tile');       hold(axS,'on');
    draw_spec(axP, A, colors, shapes, col_offset, rel, Chins2Run);
    draw_sums(axS, A, colors, shapes, col_offset, rel, Chins2Run);
    add_title(fh, sprintf('EFR RAM 223 Hz — %d dB SPL', round(all_levels(li))));
    add_legend(axP, colors, cidx_list, cnames);
end
end


function draw_spec(ax, A, colors, shapes, col_offset, rel, Chins2Run)
    if rel, plot(ax, [0 1e5], [0 0], 'k--', 'LineWidth',1.5, 'HandleVisibility','off'); end
    for c = 1:numel(A.peaks)
        if isempty(A.peaks_locs{1,c}) || isempty(A.peaks{1,c}), continue; end
        [clr, shp] = cs(colors, shapes, c + col_offset);
        if ~isempty(A.plv_env{1,c}) && ~isempty(A.f{1,c})
            plot(ax, A.f{1,c}, A.plv_env{1,c}, '-', 'LineWidth',1.5, 'Color',[clr 0.30], 'HandleVisibility','off');
        end
        locs = A.peaks_locs{1,c};
        subj_pts(ax, A.all_peaks(:,c), locs, clr, shp, Chins2Run, 'off', 0.012*max(locs));
        errorbar(ax, locs, A.peaks{1,c}, A.peaks_std{1,c}, 'Marker',shp, 'LineStyle','-', ...
            'LineWidth',2, 'MarkerSize',10, 'Color',clr, 'MarkerFaceColor',clr, 'MarkerEdgeColor',clr, ...
            'HandleVisibility','off');
    end
    last_ne = find(~cellfun(@isempty, A.peaks_locs(1,:)), 1, 'last');
    if ~isempty(last_ne)
        lr = A.peaks_locs{1,last_ne};  vl = lr(isfinite(lr));
        if ~isempty(vl), xlim(ax, [0, round(max(vl),-3) + 200]); xticks(ax, round(vl(1:2:end))); end
    end
    xtickangle(ax, 45);
    finish_tile(ax, 1, 0, 'Frequency (Hz)', ternary_s(rel,'PLV Shift (re. Baseline)','PLV'));
    title(ax, 'PLV spectrum', 'FontSize',14, 'FontWeight','bold');
end


function draw_sums(ax, A, colors, shapes, col_offset, rel, Chins2Run)
o  = efr_opts();  LB = efr_ram_labels(o);
same_units = strcmp(o.measure,'amplitude') && ~o.normalize;
    nH = max(cellfun(@numel, A.peaks_locs(1,:)));
    [nS, nCc] = size(A.all_low_high_peaks);
    offs = 0;  if nCc > 1, offs = linspace(-0.25, 0.25, nCc); end
    for c = 1:nCc
        [clr, shp] = cs(colors, shapes, c + col_offset);
        M = nan(nS, 3);
        for s = 1:nS
            lh = A.all_low_high_peaks{s,c};  ps = A.all_plv_sum{s,c};
            if numel(lh) >= 2, M(s,1:2) = lh(1:2); end
            if isscalar(ps), M(s,3) = ps; end
        end
        if all(isnan(M(:))), continue; end
        if same_units
            group_pts(ax, M, (1:3) + offs(c), clr, shp, Chins2Run);
        else
            yyaxis(ax,'left');   group_pts(ax, M(:,1:2), (1:2) + offs(c), clr, shp, Chins2Run);
            yyaxis(ax,'right');  group_pts(ax, M(:,3),   3 + offs(c),     clr, shp, Chins2Run);
        end
    end
    if ~same_units
        yyaxis(ax,'right');
        ylabel(ax, ternary_s(rel,'Sum shift (PLV)','Sum (PLV, all harmonics)'), 'FontWeight','bold');
        ax.YAxis(2).Color = [0.15 0.15 0.15];
        yyaxis(ax,'left');  ax.YAxis(1).Color = [0.15 0.15 0.15];
    end
    set(ax, 'XTick',1:3, 'XTickLabel',{LB.low, LB.high, sprintf('Sum (H1–H%d)', nH)});
    xlim(ax, [0.5 3.5]);
    if same_units, ylab = 'PLV sum'; else, ylab = LB.measure; end
    if rel, ylab = [ylab ' shift']; end
    if same_units
        finish_tile(ax, 1, 0, '', ylab);
    else
        set(ax, 'FontSize',14, 'Box','off');  grid(ax,'on');

        yyaxis(ax,'right');  side_lim(ax, @(x) x > 2.5);
        yyaxis(ax,'left');   side_lim(ax, @(x) x < 2.5);
        ylabel(ax, ylab, 'FontWeight','bold');
    end
    % group divider (Sum) and zero line, drawn after the limits are set
    yl = ylim(ax);
    plot(ax, [2.5 2.5], yl, '-', 'Color',[0.85 0.85 0.85], 'LineWidth',1, 'HandleVisibility','off');
    if rel, plot(ax, [0.5 3.5], [0 0], 'k--', 'LineWidth',1.5, 'HandleVisibility','off'); end
    ylim(ax, yl);
    title(ax, 'Harmonic sums', 'FontSize',14, 'FontWeight','bold');
end


function side_lim(ax, sel)
% y-limits for one yyaxis side from the mean ± SD errorbars in that x-range
yy = [];
for h = findall(ax, 'Type','errorbar')'
    keep = sel(h.XData);
    v = [h.YData(keep) - h.YNegativeDelta(keep), h.YData(keep) + h.YPositiveDelta(keep)];
    yy = [yy, v(isfinite(v))]; %#ok<AGROW>
end
for h = findall(ax, 'Type','scatter')'
    keep = sel(h.XData);  v = h.YData(keep);  yy = [yy, v(isfinite(v))]; %#ok<AGROW>
end
if ~isempty(yy)
    lo = min(yy);  hi = max(yy);  r = max(hi - lo, 0.05);
    ylim(ax, [lo - 0.12*r, hi + 0.12*r]);
end
end


function group_pts(ax, M, xs, clr, shp, names)
% Individual subjects (transparent, Tag efr_subj_pts) + mean ± SD per column
for s = 1:size(M,1)
    if all(isnan(M(s,:))), continue; end
    jit = ((mod(s*7,11)/10) - 0.5) * 0.06;
    scatter(ax, xs + jit, M(s,:), 60, clr, shp, 'filled', 'MarkerFaceAlpha',0.30, ...
        'MarkerEdgeColor','none', 'HandleVisibility','off', 'Tag','efr_subj_pts', ...
        'DisplayName',subj_name(names, s));
end
mu = mean(M, 1, 'omitnan');  sd = std(M, 0, 1, 'omitnan');
errorbar(ax, xs, mu, sd, 'Marker',shp, 'LineStyle','none', 'LineWidth',2, ...
    'MarkerSize',14, 'Color',clr, 'MarkerFaceColor',clr, 'MarkerEdgeColor',clr, 'HandleVisibility','off');
end


% ═════════════════════════════════════════════════════════════════════════
function fh = new_fig(nm)
old = findobj('Type','figure','Name',nm,'Tag','APAT_efr_avg');
if ~isempty(old), close(old); end
fh = figure('Name',nm,'NumberTitle','off','Visible','off','Color','w','Tag','APAT_efr_avg', ...
    'Units','normalized','Position',[0.05 0.1 0.85 0.75]);
end

function axs = tile_axes(fh, n)
L = 0.07;  R = 0.82;  gap = 0.035;  w = (R - L - (n-1)*gap) / n;
axs = gobjects(1, n);
for k = 1:n
    axs(k) = axes(fh, 'Position',[L+(k-1)*(w+gap) 0.22 w 0.64], 'Tag','efr_tile');
end
end

function finish_tile(ax, k, lev, xl, yl)
set(ax, 'FontSize',14, 'Box','off');  grid(ax,'on');
title(ax, sprintf('%.0f dB SPL', lev), 'FontSize',14, 'FontWeight','bold');
if ~isempty(xl), xlabel(ax, xl, 'FontWeight','bold'); end
if k == 1, ylabel(ax, yl, 'FontWeight','bold'); end
yy = [];
for h = findall(ax, 'Type','errorbar')'
    v = [h.YData - h.YNegativeDelta, h.YData + h.YPositiveDelta];  yy = [yy, v(isfinite(v))]; %#ok<AGROW>
end
for h = findall(ax, 'Type','line')'
    v = h.YData;  yy = [yy, v(isfinite(v))]; %#ok<AGROW>
end
if ~isempty(yy)
    lo = min(yy);  hi = max(yy);  r = max(hi - lo, 0.05);
    ylim(ax, [lo - 0.12*r, hi + 0.12*r]);
end
end

function add_title(fh, txt)
axH = axes(fh, 'Position',[0 0.92 0.89 0.06], 'Visible','off');
text(axH, 0.5, 0.5, txt, 'FontSize',16, 'FontWeight','bold', 'HorizontalAlignment','center', ...
    'Color',[0.15 0.15 0.15]);
end

function add_legend(ax1, colors, cidx_list, cnames)
% Condition legend (squares, black edge) centred under the tiles — as ABR Peaks
if isempty(cnames), return; end
hold(ax1,'on');
lh = gobjects(1, numel(cnames));
for i = 1:numel(cnames)
    lh(i) = plot(ax1, NaN, NaN, 's', 'MarkerFaceColor',colors(cidx_list(i),:), ...
        'MarkerEdgeColor','k', 'MarkerSize',12, 'LineWidth',1.5);
end
lg = legend(ax1, lh, cnames, 'Orientation','horizontal', 'Box','off', 'FontSize',14, 'Location','none');
lg.Units = 'normalized';
lg.Position(1) = 0.07 + (0.75 - lg.Position(3))/2;
lg.Position(2) = 0.03;
end

function subj_pts(ax, col_cells, locs, clr, shp, names, vis, jit_w)
for s = 1:numel(col_cells)
    y = col_cells{s};  if isempty(y), continue; end
    m = min(numel(y), numel(locs));  x = locs(1:m);  y = y(1:m);
    jit = ((mod(s*7,11)/10) - 0.5) * jit_w;
    scatter(ax, x + jit, y, 45, clr, shp, 'filled', 'MarkerFaceAlpha',0.30, 'MarkerEdgeColor','none', ...
        'HandleVisibility','off', 'Tag','efr_subj_pts', 'Visible',vis, 'DisplayName',subj_name(names, s));
end
end

function [names, cidx] = cond_info(avg_field, col_offset, idx, all_Conds2Run, n_colors)
names = {};  cidx = [];
for c = 1:size(avg_field, 2)
    ci = c + col_offset;
    if ci <= numel(all_Conds2Run) && ci <= size(idx,2) && sum(idx(:,ci)) > 0
        parts = strsplit(all_Conds2Run{ci}, filesep);
        names{end+1} = sprintf('%s (n = %d)', parts{end}, sum(idx(:,ci))); %#ok<AGROW>
        cidx(end+1)  = mod(ci-1, n_colors) + 1; %#ok<AGROW>
    end
end
end

function [clr, shp] = cs(colors, shapes, ci)
clr = colors(mod(ci-1, size(colors,1)) + 1, 1:3);
shp = strtrim(char(shapes(mod(ci-1, size(shapes,1)) + 1, :)));  if isempty(shp), shp = 'o'; end
end

function s = subj_name(names, r)
if numel(names) >= r, s = char(names{r}); else, s = sprintf('Subject %d', r); end
end

function s = ternary_s(c, a, b)
if c, s = a; else, s = b; end
end
