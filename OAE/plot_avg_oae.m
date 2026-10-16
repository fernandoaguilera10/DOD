function plot_avg_oae(A, EXPname, colors, shapes, Chins2Run, all_Conds2Run, idx_plot_relative, outpath, o)
%PLOT_AVG_OAE  OAE group figures for the app's Average panel.
%   One figure per scale view ('Scale|EPL', 'Scale|SPL', 'Scale|EPL + SPL';
%   Tag 'oae_avg_<view>'), shown one at a time with the Scale dropdown.
%     left  — band mean ± SD (conditions dodged), subject points (Tag
%             'oae_subj_pts', subject ID in DisplayName), mean full-resolution
%             curve (faint, Tag 'oae_raw'), mean noise floor (dashed, 'oae_nf').
%             Axes Tag 'oae_avg_ax'.
%     right — 'Frequency Band Average' Low / Mid / High: mean ± SD + subject points
%             (Axes Tag 'oae_reg_ax').
%   In the combined view SPL is drawn dotted with open markers.
%   Saves <EXP>_Average_<EPL|SPL>.mat (struct 'average'; not in CSV-only mode)
%   and ONE image <EXP>_Average_figure.png (outpath = Analysis/OAE/Average).
if nargin < 9, o = oae_opts(); end
scales = fieldnames(A)';                       % {'epl','spl'} or {'spl'}
if isempty(scales), return; end
views = cellfun(@(s) {upper(s)}, scales, 'UniformOutput', false);
if numel(scales) == 2, views{end+1} = {'EPL','SPL'}; end
rel = ~isempty(idx_plot_relative);
snr = strcmp(o.y_measure, 'snr');
prefix = EXPname;  if any(strcmp(EXPname, {'DPOAE','SFOAE'})), prefix = [EXPname 'swept']; end
ref_label = '';
if rel
    p = strsplit(all_Conds2Run{idx_plot_relative}, filesep);  ref_label = p{end};
end

figs = gobjects(1, numel(views));
for vi = 1:numel(views)
    v  = views{vi};  nm = strjoin(v, ' + ');
    fh = new_fig(['Scale|' nm], ['oae_avg_' strjoin(v, '_')]);
    ttl = sprintf('%s Average', EXPname);
    if rel, ttl = sprintf('%s (re. %s)', ttl, ref_label); end
    add_title(fh, ttl);
    axB = axes(fh, 'Position',[0.06 0.22 0.553 0.64], 'Tag','oae_avg_ax');  hold(axB,'on');   % full width (Oct 15)
    axR = axes(fh, 'Position',[0.685 0.22 0.265 0.64], 'Tag','oae_reg_ax');  hold(axR,'on');
    G = A.(lower(v{1}));
    nk = numel(G.cols);  nsc = numel(v);
    w  = 1 / o.bands_per_oct;
    % conditions (× scales) side by side — same spacing / marker size rule
    % as ABR Thresholds; only the slots that hold data are used
    nslot = 0;
    for k = 1:nk, for si = 1:nsc, nslot = nslot + (A.(lower(v{si})).n(k) > 0); end, end
    offs  = apat_dodge(max(nslot,1)) * w;             % octaves
    roffs = apat_dodge(max(nslot,1));                 % region categories
    set(axB, 'XScale','log');  xlim(axB, o.frange);  xlim(axR, [0.5 3.5]);
    [ms,  sa ] = apat_ms(axB, 0.7 * w * log10(2));   % points at true x: size from the x spacing
    [msR, saR] = apat_ms(axR, 0.7);
    j = 0;
    for k = 1:nk
        for si = 1:nsc
            G = A.(lower(v{si}));
            if G.n(k) == 0, continue; end
            j = j + 1;
            [clr, shp] = cs(colors, shapes, G.cols(k));
            spl2 = nsc == 2 && si == 2;
            ls = '-';  mfc = clr;
            if spl2, ls = ':';  mfc = 'w'; end
            % mean full-resolution curve + noise floor
            mf = mean(G.full{k}, 1, 'omitnan');
            plot(axB, G.fg, mf, ls, 'LineWidth',1, 'Color',[clr 0.30], 'HandleVisibility','off', 'Tag','oae_raw');
            if ~isempty(G.band_nf{k})
                plot(axB, G.cf, mean(G.band_nf{k}, 1, 'omitnan'), '--', 'LineWidth',1.3, ...
                    'Color',[clr 0.55], 'HandleVisibility','off', 'Tag','oae_nf');
            end
            % bands: subject points + mean ± SD
            xb = G.cf .* 2 .^ offs(j);
            M  = G.band{k};
            Mp = M;  if isfield(G,'band_pts') && numel(G.band_pts) >= k, Mp = G.band_pts{k}; end   % incl. excluded
            subj_pts(axB, Mp, xb, clr, shp, Chins2Run, @(s) xb .* 2 .^ (jit(s) * 0.05 * w), sa);
            mu = mean(M, 1, 'omitnan');  sd = std(M, 0, 1, 'omitnan');
            plot(axB, xb, mu, ls, 'LineWidth',2, 'Color',clr, 'HandleVisibility','off');
            errorbar(axB, xb, mu, sd, 'Marker',shp, 'LineStyle','none', 'LineWidth',1.8, ...
                'MarkerSize',ms, 'Color',clr, 'MarkerFaceColor',mfc, 'MarkerEdgeColor',clr, ...
                'HandleVisibility','off');
            % regions
            xr = (1:3) + roffs(j);
            Rm = G.reg{k};
            Rp = Rm;  if isfield(G,'reg_pts') && numel(G.reg_pts) >= k, Rp = G.reg_pts{k}; end      % incl. excluded
            subj_pts(axR, Rp, xr, clr, shp, Chins2Run, @(s) xr + jit(s) * 0.05, saR);
            errorbar(axR, xr, mean(Rm, 1, 'omitnan'), std(Rm, 0, 1, 'omitnan'), 'Marker',shp, ...
                'LineStyle','none', 'LineWidth',2, 'MarkerSize',msR, 'Color',clr, ...
                'MarkerFaceColor',mfc, 'MarkerEdgeColor',clr, 'HandleVisibility','off');
        end
    end
    if rel || snr
        plot(axB, [1e-3 1e3], [0 0], 'k--', 'LineWidth',1.3, 'HandleVisibility','off');
        plot(axR, [0.5 3.5], [0 0], 'k--', 'LineWidth',1.3, 'HandleVisibility','off');
    end
    % ── axes cosmetics ─────────────────────────────────────────────────
    style_freq_ax(axB, EXPname, o);
    ylab = y_label(v, snr, rel, ref_label);
    ylabel(axB, ylab, 'FontWeight','bold');
    title(axB, sprintf('%s (%s)', EXPname, band_txt(o)), 'FontSize',14, 'FontWeight','bold');
    fit_ylim(axB);
    cfs = [];  for si = 1:nsc, cfs = [cfs, double(A.(lower(v{si})).cf(:)')]; end %#ok<AGROW>
    apat_xgroups(axB, cfs, region_tint(cfs, o.regions));   % one band per frequency, tinted by region
    r = o.regions;
    set(axR, 'FontSize',14, 'Box','off', 'XTick',1:3, 'XTickLabel', { ...
        sprintf('Low (%g–%g)', r(1), r(2)), sprintf('Mid (%g–%g)', r(2), r(3)), ...
        sprintf('High (%g–%g)', r(3), r(4))});
    grid(axR,'on');  xlim(axR, [0.5 3.5]);
    xlabel(axR, 'Frequency Band (kHz)', 'FontWeight','bold');
    ylabel(axR, ylab, 'FontWeight','bold');
    title(axR, 'Frequency Band Average', 'FontSize',14, 'FontWeight','bold');
    fit_ylim(axR);
    apat_xgroups(axR, 1:3, apat_region_tints());     % Low / Mid / High: same tints as the bands they average
    add_legend(axB, A.(lower(v{1})), colors, shapes, all_Conds2Run, nsc == 2, snr || rel);
    figs(vi) = fh;
end

%% ── Save data and export ────────────────────────────────────────────────
if ~exist(outpath, 'dir'), try, mkdir(outpath); catch, end, end
if exist(outpath, 'dir')
    keep = oae_save_views(views, o);            % Setup: Save files EPL / SPL
    for s = scales
        if ~any(keep & cellfun(@(v) isequal(v, {upper(s{1})}), views)), continue; end
        if ~apat_csv('avg_mat'), continue; end      % CSV only: no group .mat
        average = A.(s{1});
        average.subjects   = Chins2Run;
        average.conditions = all_Conds2Run(average.cols);
        try, apat_avg_mat('save', fullfile(outpath, sprintf('%s_Average_%s.mat', prefix, upper(s{1}))), 'average', average); catch, end   % average.<EXP>
    end
    % ONE image: the view with every chosen unit (EPL + SPL when both)
    vi = oae_save_views(views, o, 'one');
    try, apat_save_fig(figs(vi), fullfile(outpath, sprintf('%s_Average_figure', prefix)), oae_key(EXPname, 'avg')); catch, end
end
end


% ═════════════════════════════════════════════════════════════════════════
function C = region_tint(cf, r)
% Tint of each band centre by the region it belongs to (Low / Mid / High,
% edges r = o.regions in kHz); bands outside every region get grey.
T = apat_region_tints();  C = repmat([0.88 0.88 0.88], numel(cf), 1);
for k = 1:numel(cf)
    for ri = 1:3
        if cf(k) >= r(ri) && cf(k) < r(ri+1) || (ri == 3 && cf(k) == r(4)), C(k,:) = T(ri,:); end
    end
end
end


function subj_pts(ax, M, x, clr, shp, names, xfun, sa) %#ok<INUSL>
% Individual subjects (transparent; Tag oae_subj_pts; DisplayName = subject)
if nargin < 8, sa = 40; end
for s = 1:size(M,1)
    if all(isnan(M(s,:))), continue; end
    scatter(ax, xfun(s), M(s,:), sa, clr, shp, 'filled', 'MarkerFaceAlpha',0.30, ...
        'MarkerEdgeColor','none', 'HandleVisibility','off', 'Tag','oae_subj_pts', ...
        'DisplayName',subj_name(names, s));
end
end

function j = jit(s)
j = (mod(s*7, 11)/10) - 0.5;
end

function fh = new_fig(nm, tag)
old = findobj('Type','figure','Tag',tag);
if ~isempty(old), close(old); end
fh = figure('Name',nm,'NumberTitle','off','Visible','off','Color','w','Tag',tag, ...
    'Units','normalized','Position',[0.05 0.1 0.85 0.75]);
end

function add_title(fh, txt)
axH = axes(fh, 'Position',[0 0.92 1 0.06], 'Visible','off');
text(axH, 0.5, 0.5, txt, 'FontSize',16, 'FontWeight','bold', 'HorizontalAlignment','center', ...
    'Color',[0.15 0.15 0.15], 'Interpreter','none');
end

function add_legend(ax, G, colors, shapes, all_Conds2Run, both, zero_line)
% conditions (upper) and line keys (lower), centred under both plots
fh = ancestor(ax, 'figure');
hC = gobjects(0);  LC = {};
for k = 1:numel(G.cols)
    if G.n(k) == 0, continue; end
    [clr, shp] = cs(colors, shapes, G.cols(k));
    p = strsplit(all_Conds2Run{G.cols(k)}, filesep);
    hC(end+1) = plot(ax, NaN, NaN, 'LineStyle','-', 'Marker',shp, 'MarkerSize',10, 'LineWidth',2, ...
        'Color',clr, 'MarkerFaceColor',clr); %#ok<AGROW>
    LC{end+1} = sprintf('%s (n = %d)', p{end}, G.n(k)); %#ok<AGROW>
end
keys = struct('args',{},'label',{});
if both
    keys(end+1) = struct('args',{{'k-o','LineWidth',2,'MarkerFaceColor','k'}}, 'label','EPL');
    keys(end+1) = struct('args',{{'k:o','LineWidth',2,'MarkerFaceColor','w'}}, 'label','SPL');
end
if ~zero_line
    keys(end+1) = struct('args',{{'--','Color',[0.5 0.5 0.5],'LineWidth',1.3}}, 'label','Noise Floor');
end
oae_legends(fh, ax, hC, LC, keys, 0.06, 0.89);
end

function style_freq_ax(ax, EXPname, o)
set(ax, 'XScale','log', 'FontSize',14, 'Box','off');  grid(ax,'on');
xlim(ax, o.frange);
t = [0.25 0.5 1 2 4 8 16 32];  t = t(t >= o.frange(1) & t <= o.frange(2));
if numel(t) >= 2, set(ax, 'XTick',t, 'XTickLabel',arrayfun(@(v) sprintf('%g',v), t, 'UniformOutput',false)); end
if strcmp(EXPname,'DPOAE'), xl = 'F_2 Frequency (kHz)'; else, xl = 'Frequency (kHz)'; end
xlabel(ax, xl, 'FontWeight','bold');
end

function s = y_label(view, snr, rel, ref_label)
if snr, s = 'SNR (dB)';
elseif numel(view) == 2, s = 'Amplitude (dB)';
else, s = sprintf('Amplitude (dB %s)', view{1}); end
if rel
    if snr, s = sprintf('SNR Change re. %s (dB)', ref_label);
    else,   s = sprintf('Change re. %s (dB)', ref_label); end
end
end

function s = band_txt(o)
switch o.bands_per_oct
    case 1, s = '1 Octave';
    otherwise, s = sprintf('1/%d Octave', o.bands_per_oct);
end
switch o.method
    case 'snrw',   s = [s ', SNR-Weighted'];
    case 'power',  s = [s ', Power Avg.'];
    case 'median', s = [s ', Median'];
    otherwise,     s = [s ', Mean dB'];
end
end

function fit_ylim(ax)
% y-limits from the errorbars and subject points (not the faint sweep)
yy = [];
for h = findall(ax, 'Type','errorbar')'
    yd = get(h,'YData');  ln = get(h,'YNegativeDelta');  lp = get(h,'YPositiveDelta');
    v = [yd(:) - ln(:); yd(:) + lp(:)];  v = v(:)';  yy = [yy, v(isfinite(v))]; %#ok<AGROW>
end
for h = findall(ax, 'Type','scatter')'
    v = get(h,'YData');  v = v(:)';  yy = [yy, v(isfinite(v))]; %#ok<AGROW>
end
for h = findall(ax, 'Type','line', 'Tag','oae_nf')'
    v = get(h,'YData');  v = v(:)';  yy = [yy, v(isfinite(v))]; %#ok<AGROW>
end
if isempty(yy), return; end
lo = min(yy);  hi = max(yy);  r = max(hi - lo, 1);
ylim(ax, [lo - 0.08*r, hi + 0.08*r]);
end

function [clr, shp] = cs(colors, shapes, ci)
clr = colors(mod(ci-1, size(colors,1)) + 1, 1:3);
if iscell(shapes), shp = shapes{mod(ci-1, numel(shapes)) + 1};
else, shp = shapes(mod(ci-1, size(shapes,1)) + 1, :); end
shp = strtrim(char(shp));  if isempty(shp), shp = 'o'; end
end

function s = subj_name(names, r)
if numel(names) >= r, s = char(names{r}); else, s = sprintf('Subject %d', r); end
end
