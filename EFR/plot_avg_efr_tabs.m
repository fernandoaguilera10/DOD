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
    axP = axes(fh, 'Position',[0.07 0.24 0.471 0.62], 'Tag','efr_spec_tile');  hold(axP,'on');   % full width (Oct 15)
    axS = axes(fh, 'Position',[0.628 0.24 0.322 0.62], 'Tag','efr_tile'); hold(axS,'on');
    draw_spec(axP, A, colors, shapes, col_offset, rel, Chins2Run);
    draw_sums(axS, A, colors, shapes, col_offset, rel, Chins2Run);
    oF = efr_opts();
    add_title(fh, sprintf('EFR RAM %g Hz — %d dB SPL', oF.ram_f0, round(all_levels(li))));
    add_legend(fh, axP, colors, shapes, cidx_list, cnames);
end
end


function draw_spec(ax, A, colors, shapes, col_offset, rel, Chins2Run)
    % True harmonic axis: means at k × F0 (F0 = RAM modulation frequency),
    % fixed ticks k × F0 — identical in every session, whatever FFT bin the
    % peak fell in. Conditions side by side (apat_dodge) at each harmonic.
    oF = efr_opts();  F0 = oF.ram_f0;
    if rel, plot(ax, [0 1e5], [0 0], 'k--', 'LineWidth',1.5, 'HandleVisibility','off'); end
    has = find(arrayfun(@(c) ~isempty(A.peaks_locs{1,c}) && ~isempty(A.peaks{1,c}), 1:numel(A.peaks)));
    nH  = max([1, cellfun(@numel, A.peaks(1,has))]);
    xlim(ax, [0.4*F0, (nH + 0.6)*F0]);
    offs = apat_dodge(numel(has)) * F0;
    [ms, sa] = apat_ms(ax, 0.7*F0);   % points at true x: size from the x spacing
    for j = 1:numel(has)
        c = has(j);
        [clr, shp] = cs(colors, shapes, c + col_offset);
        if ~isempty(A.plv_env{1,c}) && ~isempty(A.f{1,c})
            % A.f stacks one frequency row per subject (avg_efr); plotting
            % that matrix against the mean PLV drew one line per frequency
            % bin (~22,000 objects, made the app slow) — one row is the axis
            fx = A.f{1,c};  yv = A.plv_env{1,c};
            if ~isvector(fx), fx = fx(1,:); end
            nn = min(numel(fx), numel(yv));
            plot(ax, fx(1:nn), yv(1:nn), '-', 'LineWidth',1.5, 'Color',[clr 0.30], 'HandleVisibility','off');
        end
        xh = (1:numel(A.peaks{1,c})) * F0 + offs(j);
        subj_pts(ax, A.all_peaks(:,c), xh, clr, shp, Chins2Run, 'off', 0.06*F0, sa);
        errorbar(ax, xh, A.peaks{1,c}, A.peaks_std{1,c}, 'Marker',shp, 'LineStyle','-', ...
            'LineWidth',2, 'MarkerSize',ms, 'Color',clr, 'MarkerFaceColor',clr, 'MarkerEdgeColor',clr, ...
            'HandleVisibility','off');
    end
    hk = (1:nH) * F0;                                 % one tick per harmonic
    set(ax, 'XTick',hk, 'XTickLabel',arrayfun(@(v) sprintf('%d', round(v)), hk, 'UniformOutput',false));
    xtickangle(ax, 45);
    ax.XAxis.FontSize = 11;
    finish_tile(ax, 1, 0, 'Frequency (Hz)', ternary_s(rel,'PLV Shift (re. Baseline)','PLV'));
    apat_xgroups(ax, hk, harm_tint(nH));              % one band per harmonic, Low / High range tinted
    title(ax, 'PLV Spectrum', 'FontSize',14, 'FontWeight','bold');
end


function draw_sums(ax, A, colors, shapes, col_offset, rel, Chins2Run)
o  = efr_opts();  LB = efr_ram_labels(o);
% one y-axis when Low / High / All share units: PLV sums, or normalised
% fractions (All = 1); otherwise "All" (PLV) gets its own right axis
same_units = strcmp(o.measure,'amplitude') || o.normalize;
    nH = max(cellfun(@numel, A.peaks_locs(1,:)));
    axR = [];
    if ~same_units
        % "All" has other units: a second, transparent axes on top with its
        % own y-axis on the right (not yyaxis — the app cannot copy yyaxis axes)
        fh  = ancestor(ax, 'figure');
        axR = axes(fh, 'Units',ax.Units, 'Position',ax.Position, 'Color','none', ...
            'YAxisLocation','right', 'XLim',[0.5 3.5], 'XTick',[], 'Box','off', ...
            'Tag','efr_tile_total', 'PickableParts','none', 'FontSize',14);
        hold(axR, 'on');
    end
    [nS, nCc] = size(A.all_low_high_peaks);
    Ms = cell(1, nCc);  has = false(1, nCc);
    for c = 1:nCc
        M = nan(nS, 3);
        for s = 1:nS
            lh = A.all_low_high_peaks{s,c};  ps = A.all_plv_sum{s,c};
            if numel(lh) >= 2, M(s,1:2) = lh(1:2); end
            if isscalar(ps), M(s,3) = ps; end
        end
        Ms{c} = M;  has(c) = ~all(isnan(M(:)));
    end
    % subject points incl. data excluded from the mean (Exclusions)
    Mp = Ms;
    if isfield(A,'all_low_high_peaks_pts') && isequal(size(A.all_low_high_peaks_pts), [nS nCc])
        for c = 1:nCc
            M = nan(nS, 3);
            for s = 1:nS
                lh = A.all_low_high_peaks_pts{s,c};  ps = A.all_plv_sum_pts{s,c};
                if numel(lh) >= 2, M(s,1:2) = lh(1:2); end
                if isscalar(ps), M(s,3) = ps; end
            end
            Mp{c} = M;
        end
    end
    has = find(has);
    xlim(ax, [0.5 3.5]);
    offs = apat_dodge(numel(has));                 % same spacing as ABR Thresholds
    [ms, sa] = apat_ms(ax, 0.7);   % points at true x: size from the x spacing
    for j = 1:numel(has)
        c = has(j);  M = Ms{c};  P = Mp{c};
        [clr, shp] = cs(colors, shapes, c + col_offset);
        if same_units
            group_pts(ax, M, (1:3) + offs(j), clr, shp, Chins2Run, ms, sa, P);
        else
            group_pts(ax,  M(:,1:2), (1:2) + offs(j), clr, shp, Chins2Run, ms, sa, P(:,1:2));
            group_pts(axR, M(:,3),   3 + offs(j),     clr, shp, Chins2Run, ms, sa, P(:,3));
        end
    end
    if ~same_units
        ylabel(axR, ternary_s(rel,'Sum Shift (PLV)','Sum (PLV, All Harmonics)'), 'FontWeight','bold');
        axR.YColor = [0.15 0.15 0.15];  axR.XColor = 'none';
    end
    % two-line group labels, each line centred on its tick (tick-label
    % \newline would left-align the lines), drawn as text below the axis
    set(ax, 'XTick',1:3, 'XTickLabel',{'','',''});
    xlim(ax, [0.5 3.5]);
    xlabel(ax, {' ',' '}, 'FontSize',14);           % reserves room for the two-line group labels
    glab = {LB.low, LB.high, sprintf('All (H1–H%d)', nH)};
    for gk = 1:3
        t2 = regexp(glab{gk}, '^(.*?)\s*(\(.*\))$', 'tokens', 'once');
        if isempty(t2), t2 = {glab{gk}}; end
        text(ax, (gk-0.5)/3, -0.02, t2, 'Units','normalized', 'HorizontalAlignment','center', ...
            'VerticalAlignment','top', 'FontSize',14, 'Color',[0.15 0.15 0.15], ...
            'Clipping','off', 'HandleVisibility','off', 'Tag','efr_xlab');
    end
    if same_units && ~o.normalize, ylab = 'PLV Sum'; else, ylab = LB.measure; end
    if rel, ylab = [ylab ' Shift']; end
    if same_units
        finish_tile(ax, 1, 0, '', ylab);
    else
        set(ax, 'FontSize',14, 'Box','off');  grid(ax,'on');
        side_lim(axR, @(x) x > 2.5);
        side_lim(ax,  @(x) x < 2.5);
        ylabel(ax, ylab, 'FontWeight','bold');
    end
    % group divider (Sum) and zero line, drawn after the limits are set
    yl = ylim(ax);
    plot(ax, [2.5 2.5], yl, '-', 'Color',[0.85 0.85 0.85], 'LineWidth',1, 'HandleVisibility','off');
    if rel, plot(ax, [0.5 3.5], [0 0], 'k--', 'LineWidth',1.5, 'HandleVisibility','off'); end
    ylim(ax, yl);
    if rel && ~isempty(axR)
        plot(axR, [2.5 3.5], [0 0], 'k--', 'LineWidth',1.5, 'HandleVisibility','off');
    end
    title(ax, 'Harmonic Sums', 'FontSize',14, 'FontWeight','bold');
    T = apat_region_tints();                          % Low / High sums: same tints as their harmonics
    apat_xgroups(ax, 1:3, [T(1,:); T(3,:); NaN NaN NaN]);   % "All" unshaded: it is not one range
    if ~isempty(axR), uistack(axR, 'top'); end
end


function C = harm_tint(nH)
% Tint per harmonic: Low range (efr_opts .low) blue-grey, High range rose,
% others grey — the same tints as the Low / High harmonic-sum columns.
o = efr_opts();  T = apat_region_tints();
C = repmat([0.88 0.88 0.88], nH, 1);
for h = 1:nH
    if h >= o.low(1)  && h <= o.low(end),  C(h,:) = T(1,:); end
    if h >= o.high(1) && h <= o.high(end), C(h,:) = T(3,:); end
end
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


function group_pts(ax, M, xs, clr, shp, names, ms, sa, P)
% Individual subjects (transparent, Tag efr_subj_pts) + mean ± SD per column
%   P (optional) — subject values for the points incl. excluded ones (M: mean)
if nargin < 7, ms = 20; end
if nargin < 8, sa = 90; end
if nargin < 9 || isempty(P) || size(P,2) ~= size(M,2), P = M; end
for s = 1:size(P,1)
    if all(isnan(P(s,:))), continue; end
    jit = ((mod(s*7,11)/10) - 0.5) * 0.08;
    scatter(ax, xs + jit, P(s,:), sa, clr, shp, 'filled', 'MarkerFaceAlpha',0.30, ...
        'MarkerEdgeColor','none', 'HandleVisibility','off', 'Tag','efr_subj_pts', ...
        'DisplayName',subj_name(names, s));
end
mu = mean(M, 1, 'omitnan');  sd = std(M, 0, 1, 'omitnan');
errorbar(ax, xs, mu, sd, 'Marker',shp, 'LineStyle','none', 'LineWidth',2, ...
    'MarkerSize',ms, 'Color',clr, 'MarkerFaceColor',clr, 'MarkerEdgeColor',clr, 'HandleVisibility','off');
end


% ═════════════════════════════════════════════════════════════════════════
function fh = new_fig(nm)
old = findobj('Type','figure','Name',nm,'Tag','APAT_efr_avg');
if ~isempty(old), close(old); end
fh = figure('Name',nm,'NumberTitle','off','Visible','off','Color','w','Tag','APAT_efr_avg', ...
    'Units','normalized','Position',[0.05 0.1 0.85 0.75]);
end

function axs = tile_axes(fh, n)
L = 0.07;  R = 0.95;  gap = 0.035;  w = (R - L - (n-1)*gap) / n;
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
axH = axes(fh, 'Position',[0 0.92 1 0.06], 'Visible','off');
text(axH, 0.5, 0.5, txt, 'FontSize',16, 'FontWeight','bold', 'HorizontalAlignment','center', ...
    'Color',[0.15 0.15 0.15]);
end

function add_legend(fh, ax1, colors, shapes, cidx_list, cnames)
% Condition legend (line + condition marker, same as every measure),
% centred under both plots at the bottom of the figure
if isempty(cnames), return; end
LC = struct('clr',{},'shp',{},'label',{});
for i = 1:numel(cnames)
    [clr, shp] = cs(colors, shapes, cidx_list(i));
    LC(end+1) = struct('clr',clr, 'shp',shp, 'label',cnames{i}); %#ok<AGROW>
end
apat_legend(fh, ax1, LC, [], 0.07, 0.88);
end

function subj_pts(ax, col_cells, locs, clr, shp, names, vis, jit_w, sa)
if nargin < 9, sa = 45; end
for s = 1:numel(col_cells)
    y = col_cells{s};  if isempty(y), continue; end
    m = min(numel(y), numel(locs));  x = locs(1:m);  y = y(1:m);
    jit = ((mod(s*7,11)/10) - 0.5) * jit_w;
    scatter(ax, x + jit, y, sa, clr, shp, 'filled', 'MarkerFaceAlpha',0.30, 'MarkerEdgeColor','none', ...
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
