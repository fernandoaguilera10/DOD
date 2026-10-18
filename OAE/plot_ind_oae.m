function plot_ind_oae(data, EXPname, colors, shapes, Chins2Run, all_Conds2Run, ...
    ChinIND, CondIND, outpath, conds_idx, o)
%PLOT_IND_OAE  OAE individual results, all conditions overlaid.
%   One figure per scale view, 'Scale|EPL', 'Scale|SPL', 'Scale|EPL + SPL'
%   (TEOAE: SPL only); the app shows one view at a time, chosen with the
%   EPL / SPL buttons in the Results bar (both on = 'EPL + SPL').
%     left   — full-resolution sweep (faint, Tag 'oae_raw'), band values
%              (bold; hollow = below the SNR criterion), band noise floor
%              (dashed, Tag 'oae_nf'). Axes Tag 'oae_ind_ax'.
%     right  — 'Frequency Band Average' table (rows Low / Mid / High; columns
%              conditions, EPL | SPL sub-columns when both; Tag 'oae_table'); the app puts
%              the view controls under it.
%   Conditions accumulate in root appdata 'APAT_oae_ind_<EXPname>'; reset on
%   a new subject or on the first condition of a run.
if nargin < 11, o = oae_opts(); end
cond_parts = strsplit(all_Conds2Run{CondIND}, filesep);
cond_label = cond_parts{end};
subj = Chins2Run{ChinIND};
[clr, mk] = cs(colors, shapes, CondIND);

%% ── Accumulate this condition for the subject ──────────────────────────
key = ['APAT_oae_ind_' EXPname];
S = [];  if isappdata(0, key), S = getappdata(0, key); end
if ~isstruct(S) || ~isfield(S,'subj') || ~strcmp(S.subj, subj) || ...
        (~isempty(conds_idx) && CondIND == conds_idx(1))
    S = struct('subj',subj, 'conds',struct('name',{},'clr',{},'shp',{},'idx',{},'data',{}));
end
k = find(strcmp({S.conds.name}, cond_label), 1);
if isempty(k), k = numel(S.conds) + 1; end
S.conds(k) = struct('name',cond_label, 'clr',clr, 'shp',mk, 'idx',CondIND, 'data',data);
[~, ord] = sort([S.conds.idx]);  S.conds = S.conds(ord);
setappdata(0, key, S);

%% ── Views ──────────────────────────────────────────────────────────────
scales = {};
for sc = {'epl','spl'}
    if any(arrayfun(@(C) isfield(C.data, sc{1}) && ~isempty(C.data.(sc{1})), S.conds))
        scales{end+1} = sc{1}; %#ok<AGROW>
    end
end
if isempty(scales), return; end
views = cellfun(@upper, scales, 'UniformOutput', false);
views = cellfun(@(v) {v}, views, 'UniformOutput', false);   % {{'EPL'},{'SPL'}}
if numel(scales) == 2, views{end+1} = {'EPL','SPL'}; end

figs = gobjects(1, numel(views));
for vi = 1:numel(views)
    v  = views{vi};
    nm = strjoin(v, ' + ');
    fh = get_fig(['Scale|' nm]);
    draw_view(fh, S, v, EXPname, o);
    figs(vi) = fh;
end

%% ── Export after the subject's last condition ──────────────────────────
% ONE image, <Subj>/<Subj>_<EXP>_figure.png: the view with
% every unit chosen in Setup 'Save files' (EPL + SPL when both; the other
% looks come from the Results "Save Image" button)
if ~isempty(conds_idx) && CondIND == conds_idx(end) && exist(outpath,'dir')
    vi = oae_save_views(views, o, 'one');
    fn = sprintf('%s_%s_figure', subj, EXPname);
    try, apat_save_fig(figs(vi), apat_out_dir('all_file', outpath, fn), oae_key(EXPname, 'ind')); catch, end
end
end


% ═════════════════════════════════════════════════════════════════════════
function draw_view(fh, S, view, EXPname, o)
INK = [0.15 0.15 0.15];  MUTE = [0.45 0.45 0.45];  GOLD = [0.81 0.73 0.57];
both = numel(view) == 2;
snr  = strcmp(o.y_measure, 'snr');

axH = axes(fh, 'Position',[0 0.93 1 0.06], 'Visible','off');
text(axH, 0.5, 0.5, sprintf('%s  %s', S.subj, EXPname), ...
    'FontSize',16, 'FontWeight','bold', 'HorizontalAlignment','center', ...
    'Interpreter','none', 'Color',INK);

ax = axes(fh, 'Position',[0.06 0.22 0.58 0.64], 'Tag','oae_ind_ax');  hold(ax,'on');
any_flag = false;
% conditions (× scales) side by side at each band — same spacing / marker
% size rule as ABR Thresholds (the sweep itself stays at its true frequency)
w = 1 / o.bands_per_oct;
DD = cell(numel(S.conds), numel(view));
for c = 1:numel(S.conds), for si = 1:numel(view), DD{c,si} = oae_derive(S.conds(c).data, view{si}, o); end, end
nslot = nnz(~cellfun(@isempty, DD));
offs = apat_dodge(max(nslot,1)) * w;                  % octaves
set(ax, 'XScale','log');  xlim(ax, o.frange);
msB = apat_ms(ax, 0.7 * w * log10(2));   % points at true x: size from the x spacing
j = 0;
for c = 1:numel(S.conds)
    C = S.conds(c);
    for si = 1:numel(view)
        D = DD{c,si};
        if isempty(D), continue; end
        j = j + 1;  xb = D.cf .* 2 .^ offs(j);
        spl2 = both && si == 2;                       % SPL in the combined view
        ls = '-';  ms = msB;  lw = 2;
        if spl2, ls = ':';  lw = 1.8; end
        if snr
            raw = D.oae - D.nf;  bv = D.band.snr;
        else
            raw = D.oae;         bv = D.band.oae;
        end
        plot(ax, D.f, raw, ls, 'LineWidth',1, 'Color',[C.clr 0.25], ...
            'HandleVisibility','off', 'Tag','oae_raw');
        if ~snr
            plot(ax, D.f, D.nf, ':', 'LineWidth',0.8, 'Color',[C.clr 0.18], ...
                'HandleVisibility','off', 'Tag','oae_raw');
            plot(ax, D.cf, D.band.nf, '--', 'LineWidth',1.3, 'Color',[C.clr 0.55], ...
                'HandleVisibility','off', 'Tag','oae_nf');
        end
        plot(ax, xb, bv, ls, 'LineWidth',lw, 'Color',C.clr, 'HandleVisibility','off');
        ok = D.band.ok;
        plot(ax, xb(ok), bv(ok), 'LineStyle','none', 'Marker',C.shp, 'MarkerSize',ms, 'Color',C.clr, ...
            'MarkerFaceColor',C.clr, 'MarkerEdgeColor',C.clr, 'LineWidth',1.5, 'HandleVisibility','off');
        if any(~ok)
            any_flag = true;
            plot(ax, xb(~ok), bv(~ok), 'LineStyle','none', 'Marker',C.shp, 'MarkerSize',ms, 'Color',C.clr, ...
                'MarkerFaceColor','w', 'MarkerEdgeColor',C.clr, 'LineWidth',1.5, 'HandleVisibility','off');
        end
    end
end
if snr, plot(ax, [1e-3 1e3], [0 0], 'k-', 'LineWidth',1, 'HandleVisibility','off'); end
style_freq_ax(ax, EXPname, o);
ylabel(ax, y_label(view, snr), 'FontWeight','bold');
pad_ylim(ax);
cfs = [];  for kk = 1:numel(DD), if ~isempty(DD{kk}), cfs = [cfs, double(DD{kk}.cf(:)')]; end, end %#ok<AGROW>
apat_xgroups(ax, cfs, region_tint(cfs, o.regions));   % one band per frequency, tinted by region (as the table rows)

% ── legends: conditions (upper) and line keys (lower), bottom of the figure
hC = gobjects(0);  LC = {};
for c = 1:numel(S.conds)
    C = S.conds(c);
    hC(end+1) = plot(ax, NaN, NaN, 'LineStyle','-', 'Marker',C.shp, 'MarkerSize',9, 'LineWidth',2, ...
        'Color',C.clr, 'MarkerFaceColor',C.clr); %#ok<AGROW>
    lbl = C.name;                                % trials of this recording (not the
    if isfield(C.data, 'n_trials') && isfinite(C.data.n_trials)   % number of subjects of the averages)
        lbl = sprintf('%s (n = %d trials)', C.name, round(C.data.n_trials));
    end
    LC{end+1} = lbl; %#ok<AGROW>
end
keys = struct('args',{},'label',{});
if both
    keys(end+1) = struct('args',{{'k-','LineWidth',2}}, 'label','EPL');
    keys(end+1) = struct('args',{{'k:','LineWidth',2}}, 'label','SPL');
end
if ~snr
    keys(end+1) = struct('args',{{'--','Color',[0.5 0.5 0.5],'LineWidth',1.3}}, 'label','Noise Floor');
end
if any_flag
    keys(end+1) = struct('args',{{'o','MarkerFaceColor','w','MarkerEdgeColor',INK,'LineWidth',1.5}}, ...
        'label',sprintf('SNR < %g dB', o.snr_min));
end
oae_legends(fh, ax, hC, LC, keys, 0.06, 0.58);

% ── frequency band average table (top right) ───────────────────────────
% Rows: Low / Mid / High. Columns: conditions (name only — the unit is
% shown once, in the title); in the EPL + SPL view each condition has EPL
% and SPL sub-columns. Headers / values are fitted to their column
% (apat_table_fit), so many conditions never overlap.
axS = axes(fh, 'Position',[0.68 0.50 0.31 0.38], 'Tag','oae_table');  hold(axS,'on');
axis(axS,'off');  xlim(axS,[0 1]);  ylim(axS,[0 1]);
nC = numel(S.conds);  nV = numel(view);
fs = 13;  if nC*nV > 4, fs = 11; end
if nC*nV > 6, fs = 10; end
r = o.regions;
rlab = {sprintf('Low  %g–%g kHz', r(1), r(2)), sprintf('Mid  %g–%g kHz', r(2), r(3)), ...
        sprintf('High  %g–%g kHz', r(3), r(4))};
% value columns start where the widest row label ends + 8 px (measured)
x0 = apat_table_x0(axS, rlab, fs-1, {'-00.0*'}, fs, nC*nV, 0.01, 0.25, 8);
cw = (1 - x0) / max(nC,1);  sw = cw / nV;
rh = 0.12;
fsv = apat_table_fit('fs', axS, {'-00.0*'}, fs, sw, 8);   % values fit their sub-column
ht = text(axS, 0.5, 0.99, sprintf('Frequency Band Average (%s)', unit_txt(view, snr)), ...
    'FontSize',15, 'FontWeight','bold', 'Color',INK, ...
    'HorizontalAlignment','center', 'VerticalAlignment','top');
apat_table_fit('text', ht, 1, 11, 1);
text(axS, 0.5, 0.86, method_txt(o), 'FontSize',fs-2, 'Color',MUTE, ...
    'HorizontalAlignment','center', 'VerticalAlignment','middle', 'Interpreter','none');
% condition headers (unit in the title)
y = 0.73;
for c = 1:nC
    hh = text(axS, x0 + (c-0.5)*cw, y, S.conds(c).name, 'FontSize',fs, ...
        'FontWeight','bold', 'Color',S.conds(c).clr, 'HorizontalAlignment','center', ...
        'VerticalAlignment','middle', 'Interpreter','none');
    apat_table_fit('text', hh, cw, 8);
end
if nV == 2                                    % EPL / SPL sub-column headers
    y = y - 0.75*rh;
    for c = 1:nC
        for si = 1:nV
            text(axS, x0 + (c-1)*cw + (si-0.5)*sw, y, view{si}, 'FontSize',min(fs-2, fsv), 'Color',MUTE, ...
                'FontWeight','bold', 'HorizontalAlignment','center', 'VerticalAlignment','middle');
        end
    end
end
plot(axS, [0 1], [y-rh/2 y-rh/2], '-', 'Color',GOLD, 'LineWidth',1.2);
for c = 2:nC                                  % light dividers between conditions
    xd = x0 + (c-1)*cw;
    plot(axS, [xd xd], [y-rh/2-3*rh y+rh/2], '-', 'Color',[0.88 0.88 0.88], 'LineWidth',0.8);
end
% values: D{c,si}
D = cell(nC, nV);
for c = 1:nC, for si = 1:nV, D{c,si} = oae_derive(S.conds(c).data, view{si}, o); end, end
flagged = false;
for k = 1:3
    y = y - rh;
    % row shaded like its frequency region in the plot (Low / Mid / High
    % grey, apat_region_tints); white gaps between rows as between bands
    T = apat_region_tints();  g = 0.08*rh;
    patch(axS, [0 1 1 0], [y-rh/2+g y-rh/2+g y+rh/2-g y+rh/2-g], apat_shade_eff(T(k,:)), ...
        'EdgeColor','none', 'Tag','apat_xgroup');
    text(axS, 0.01, y, rlab{k}, 'FontSize',fs-1, 'Color',INK, 'VerticalAlignment','middle');
    for c = 1:nC
        for si = 1:nV
            d = D{c,si};  vtxt = '—';  tc = INK;
            if ~isempty(d)
                if snr, val = d.reg.snr(k); else, val = d.reg.oae(k); end
                if isfinite(val)
                    vtxt = sprintf('%.1f', val);
                    if ~d.reg.ok(k), vtxt = [vtxt '*']; tc = MUTE; flagged = true; end %#ok<AGROW>
                end
            end
            text(axS, x0 + (c-1)*cw + (si-0.5)*sw, y, vtxt, 'FontSize',fsv, 'Color',tc, ...
                'HorizontalAlignment','center', 'VerticalAlignment','middle');
        end
    end
end
if flagged
    text(axS, 0.01, y - rh, sprintf('* Below SNR Criterion (%g dB)', o.snr_min), ...
        'FontSize',fs-3, 'Color',MUTE, 'VerticalAlignment','middle');
end
end


% ── helpers ────────────────────────────────────────────────────────────
function fh = get_fig(nm)
% Always a fresh figure (an old one with the same name would not be picked
% up for embedding); everything is redrawn from appdata.
old = findobj('Type','figure','Name',nm);
old = old(~arrayfun(@(f) strncmp(get(f,'Tag'),'oae_avg',7), old));
if ~isempty(old), close(old); end
fh = figure('Name',nm,'NumberTitle','off','Visible','off','Color','w');
set(fh,'Units','normalized','OuterPosition',[0.05 0.05 0.9 0.85]);
end

function style_freq_ax(ax, EXPname, o)
set(ax, 'XScale','log', 'FontSize',14, 'Box','off');  grid(ax,'on');
xlim(ax, o.frange);
t = [0.25 0.5 1 2 4 8 16 32];  t = t(t >= o.frange(1) & t <= o.frange(2));
if numel(t) >= 2, set(ax, 'XTick',t, 'XTickLabel',arrayfun(@(v) sprintf('%g',v), t, 'UniformOutput',false)); end
if strcmp(EXPname,'DPOAE'), xl = 'F_2 Frequency (kHz)'; else, xl = 'Frequency (kHz)'; end
xlabel(ax, xl, 'FontWeight','bold');
end

function s = y_label(view, snr)
if snr, s = 'SNR (dB)'; return; end
if numel(view) == 2, s = 'Amplitude (dB)'; else, s = sprintf('Amplitude (dB %s)', view{1}); end
end

function s = unit_txt(view, snr)
if snr, s = 'dB SNR'; elseif numel(view) == 2, s = 'dB EPL | dB SPL'; else, s = ['dB ' view{1}]; end
end

function s = method_txt(o)
switch o.method
    case 'snrw',   s = 'SNR-Weighted';
    case 'power',  s = 'Power Average';
    case 'median', s = 'Median';
    otherwise,     s = 'Mean Of dB';
end
if o.snr_on, s = sprintf('%s, SNR ≥ %g dB', s, o.snr_min); end
end

function C = region_tint(cf, r)
% Tint of each band centre by its region (Low / Mid / High); grey outside.
T = apat_region_tints();  C = repmat([0.88 0.88 0.88], numel(cf), 1);
for k = 1:numel(cf)
    for ri = 1:3
        if cf(k) >= r(ri) && cf(k) < r(ri+1) || (ri == 3 && cf(k) == r(4)), C(k,:) = T(ri,:); end
    end
end
end


function pad_ylim(ax, pad)
if nargin < 2, pad = 0.10; end
yy = [];
for h = findall(ax, 'Type','line')'
    if strcmp(get(h,'Tag'),'oae_raw'), continue; end   % fit the band values, not the sweep
    v = double(get(h,'YData'));  v = v(:)';  yy = [yy, v(isfinite(v))]; %#ok<AGROW>
end
if isempty(yy), return; end
lo = min(yy);  hi = max(yy);  r = hi - lo;
if r == 0, r = max(abs(lo), 1); end
ylim(ax, [lo - pad*r, hi + pad*r]);
end

function [clr, shp] = cs(colors, shapes, ci)
clr = colors(mod(ci-1, size(colors,1)) + 1, 1:3);
if iscell(shapes), shp = shapes{mod(ci-1, numel(shapes)) + 1};
else, shp = shapes(mod(ci-1, size(shapes,1)) + 1, :); end
shp = strtrim(char(shp));  if isempty(shp), shp = 'o'; end
end
