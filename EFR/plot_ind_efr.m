function plot_ind_efr(data_by_level, all_levels, plot_type, colors, shapes, ...
    Conds2Run, Chins2Run, all_Conds2Run, ChinIND, CondIND, outpath, idx_plot_relative, conds_idx) %#ok<INUSL>
%PLOT_IND_EFR  EFR individual results, all conditions overlaid (no dropdown).
%   One figure per level, 'Level|<lev> dB SPL' (RAM and dAM); the app shows
%   one level at a time, chosen with the Level dropdown in the Results bar:
%     RAM: time series (left, 0.30–0.40 s), PLV spectrum + harmonic peaks
%          (middle), harmonic-sum table (top right: Low / High in the Setup
%          measure, Total PLV); the app puts time/Listen controls under it.
%     dAM: time series (left) and dAM power / noise floor vs modulation
%          frequency (right).
%   Waveform lines carry Tag 'efr_wave', DisplayName = condition and
%   UserData = level (dB SPL) so the app can play them as sound.
%   Conditions accumulate in root appdata ('APAT_efr_ind_<type>'); reset on
%   a new subject or on the first condition of a run.

cond_parts = strsplit(all_Conds2Run{CondIND}, filesep);
cond_label = cond_parts{end};
subj  = Chins2Run{ChinIND};
clr   = colors(CondIND,1:3);
mk    = strtrim(char(shapes(CondIND,:)));  if isempty(mk), mk = 'o'; end

%% ── Accumulate this condition for the subject ──────────────────────────
key = ['APAT_efr_ind_' plot_type];
S = [];  if isappdata(0, key), S = getappdata(0, key); end
if ~isstruct(S) || ~isfield(S,'subj') || ~strcmp(S.subj, subj) || ...
        (~isempty(conds_idx) && CondIND == conds_idx(1))      % new subject / new run
    S = struct('subj',subj, 'conds',struct('name',{},'clr',{},'shp',{},'data',{}));
end
k = find(strcmp({S.conds.name}, cond_label), 1);
if isempty(k), k = numel(S.conds) + 1; end
S.conds(k) = struct('name',cond_label, 'clr',clr, 'shp',mk, 'data',{data_by_level});
setappdata(0, key, S);

switch plot_type
    case 'RAM'      % one tab per level: time + frequency + harmonic-sum table
        for li = 1:numel(all_levels)
            if ~any(arrayfun(@(C) ~isempty(C.data{li}), S.conds)), continue; end
            fh = get_fig(sprintf('Level|%d dB SPL', round(all_levels(li))));
            clf(fh);  set(fh,'Color','w');
            draw_ram_level(fh, S, all_levels(li), li, all_levels);
        end
    case 'dAM'      % one tab per level: time + frequency
        for li = 1:numel(all_levels)
            if ~any(arrayfun(@(C) ~isempty(C.data{li}), S.conds)), continue; end
            fh = get_fig(sprintf('Level|%d dB SPL', round(all_levels(li))));
            clf(fh);  set(fh,'Color','w');
            draw_dam_level(fh, S, all_levels(li), li);
        end
end
end


% ═════════════════════════════════════════════════════════════════════════
function draw_dam_level(fh, S, lev, li)
INK = [0.15 0.15 0.15];  MUTE = [0.45 0.45 0.45];
axH = axes(fh,'Position',[0 0.93 1 0.06],'Visible','off');
text(axH, 0.5, 0.5, sprintf('%s EFR dAM — %d dB SPL', S.subj, round(lev)), 'FontSize',16, ...
    'FontWeight','bold', 'HorizontalAlignment','center', 'Interpreter','none', 'Color',INK);
% Time series (left)
% Same layout as EFR RAM individual: narrow time plot, wide frequency plot
axT = axes(fh,'Position',[0.05 0.30 0.313 0.56],'Tag','efr_time_tile');  hold(axT,'on');   % room below: app's Listen bar
% Frequency (right)
axF = axes(fh,'Position',[0.428 0.30 0.522 0.56],'Tag','efr_freq_tile');  hold(axF,'on');   % dAM: full width (no table, Oct 15)
missing = false;  tmax = 0;
% conditions side by side on the (log) modulation-frequency axis
has = find(arrayfun(@(C) ~isempty(C.data{li}), S.conds));
ff = [];
for c = has
    d = S.conds(c).data{li};
    if isfield(d,'smooth') && isfield(d.smooth,'f'), ff = [ff, double(d.smooth.f(:)')]; end %#ok<AGROW>
end
ff = unique(ff(isfinite(ff) & ff > 0));
set(axF, 'XScale','log');
sp = 0.1;  if numel(ff) > 1, sp = median(diff(log10(ff))); end
offs = apat_dodge(numel(has)) * sp;
if numel(ff) > 1, xlim(axF, [ff(1)*10^(-0.6*sp - max([0 offs])), ff(end)*10^(0.6*sp + max([0 offs]))]); end
ms = apat_ms(axF, 0.7*sp);   % points at true x: size from the x spacing
LC = struct('clr',{},'shp',{},'label',{});
for j = 1:numel(has)
    c = has(j);  C = S.conds(c);  d = C.data{li};
    LC(end+1) = struct('clr',C.clr, 'shp',C.shp, 'label',C.name); %#ok<AGROW>
    if isfield(d,'t') && isfield(d,'t_env') && ~isempty(d.t_env)
        plot(axT, d.t, d.t_env, '-', 'Color',C.clr, 'LineWidth',1, 'DisplayName',C.name, ...
            'Tag','efr_wave', 'UserData',round(lev));
        tmax = max(tmax, max(d.t));
    else
        missing = true;
    end
    plot(axF, d.trajectory, d.dAMpower, '-', 'Color',[C.clr 0.30], 'LineWidth',1, 'HandleVisibility','off');
    if isfield(d,'smooth') && isfield(d.smooth,'f')
        plot(axF, d.smooth.f * 10^offs(j), d.smooth.dAM, '-', 'Marker',C.shp, 'MarkerSize',ms, 'MarkerFaceColor',C.clr, ...
            'MarkerEdgeColor',C.clr, 'LineWidth',2, 'Color',C.clr, 'HandleVisibility','off');
        plot(axF, d.smooth.f, d.smooth.NF, '--', 'Color',C.clr, 'LineWidth',1.5, 'HandleVisibility','off');
    end
end
style_ax(axT, 'Time (s)', 'Amplitude (\muV)');
title(axT, 'Time', 'FontSize',14, 'FontWeight','bold');
if tmax > 0, xlim(axT, [0 tmax]); end
pad_ylim(axT);
if missing
    text(axT, 0.02, 0.04, 'No Saved Time Waveform For Some Conditions — Re-Run The dAM Analysis', ...
        'Units','normalized', 'FontSize',11, 'Color',MUTE, 'VerticalAlignment','bottom');
end
style_ax(axF, 'Modulation Frequency (Hz)', 'Power (dB)');
title(axF, 'Frequency', 'FontSize',14, 'FontWeight','bold');
pad_ylim(axF);
apat_xgroups(axF, ff);                            % one column per modulation band
% legends at the bottom (conditions + noise-floor key), under both plots
keys = struct('args',{{'--','Color',[0.5 0.5 0.5],'LineWidth',1.5}}, 'label','Noise Floor');
apat_legend(fh, axF, LC, keys, 0.05, 0.90);
end


% ═════════════════════════════════════════════════════════════════════════
function draw_ram_level(fh, S, lev, li, all_levels)
INK = [0.15 0.15 0.15];  MUTE = [0.45 0.45 0.45];  GOLD = [0.81 0.73 0.57];
axH = axes(fh,'Position',[0 0.93 1 0.06],'Visible','off');
text(axH, 0.5, 0.5, sprintf('%s EFR RAM — %d dB SPL', S.subj, round(lev)), 'FontSize',16, ...
    'FontWeight','bold', 'HorizontalAlignment','center', 'Interpreter','none', 'Color',INK);
% Frequency plot wider (16 harmonics need room), time plot and table narrower
axT = axes(fh,'Position',[0.05 0.30 0.24 0.56],'Tag','efr_time_tile');  hold(axT,'on');   % room below: app's Listen bar
axF = axes(fh,'Position',[0.34 0.30 0.40 0.56],'Tag','efr_freq_tile');  hold(axF,'on');
nC = numel(S.conds);  missing = false;  tmax = 0;  pmax = 0.1;
% True harmonic axis: markers at k × F0 (F0 = RAM modulation frequency),
% fixed ticks k × F0 — the same in every session; conditions side by side.
oF  = efr_opts();  F0 = oF.ram_f0;
has = find(arrayfun(@(C) ~isempty(C.data{li}), S.conds));
nH  = 1;
for c = has, nH = max(nH, numel(S.conds(c).data{li}.peaks)); end
xlim(axF, [0.4*F0, (nH + 0.6)*F0]);
offs = apat_dodge(numel(has)) * F0;
ms = apat_ms(axF, 0.7*F0);   % points at true x: size from the x spacing
LC = struct('clr',{},'shp',{},'label',{});
for j = 1:numel(has)
    c = has(j);  C = S.conds(c);  d = C.data{li};
    LC(end+1) = struct('clr',C.clr, 'shp',C.shp, 'label',C.name); %#ok<AGROW>
    if isfield(d,'t') && isfield(d,'t_env') && ~isempty(d.t_env)
        plot(axT, d.t, d.t_env, '-', 'Color',C.clr, 'LineWidth',1.5, 'DisplayName',C.name, ...
            'Tag','efr_wave', 'UserData',round(lev));
        tmax = max(tmax, max(d.t));
    else
        missing = true;
    end
    plot(axF, d.f, d.plv_env, '-', 'Color',[C.clr 0.45], 'LineWidth',1, 'HandleVisibility','off');
    xh = (1:numel(d.peaks)) * F0 + offs(j);
    plot(axF, xh, d.peaks, 'LineStyle','none', 'Marker',C.shp, 'MarkerSize',ms, ...
        'MarkerFaceColor',C.clr, 'MarkerEdgeColor',C.clr, 'LineWidth',2, 'HandleVisibility','off');
    pmax = max([pmax; d.peaks(:)]);
end
style_ax(axT, 'Time (s)', 'Amplitude (\muV)');
title(axT, 'Time', 'FontSize',14, 'FontWeight','bold');
if tmax >= 0.40, xlim(axT, [0.30 0.40]); elseif tmax > 0, xlim(axT, [0 tmax]); end
pad_ylim(axT);
if missing
    text(axT, 0.02, 0.04, 'No Saved Time Waveform For Some Conditions', ...
        'Units','normalized', 'FontSize',11, 'Color',MUTE, 'VerticalAlignment','bottom');
end
style_ax(axF, 'Frequency (Hz)', 'PLV');
title(axF, 'Frequency', 'FontSize',14, 'FontWeight','bold');
hk = (1:nH) * F0;                                 % one tick per harmonic (k × F0)
set(axF, 'XTick',hk, 'XTickLabel',arrayfun(@(v) sprintf('%d', round(v)), hk, 'UniformOutput',false));
xtickangle(axF, 45);  axF.XAxis.FontSize = 11;
ylim(axF, [0 1.15*pmax]);
apat_xgroups(axF, hk, harm_tint(nH));             % one band per harmonic, Low / High range tinted (as the table rows)
apat_legend(fh, axF, LC, [], 0.05, 0.69);          % conditions, bottom, under both plots
% ── harmonic-sum table (top right): every level, as sub-columns under
%    each condition (same table in every level's figure) ───────────────────
o  = efr_opts();  LB = efr_ram_labels(o, nH);     % nH = harmonics analysed (Setup range)
lv = find(arrayfun(@(j) any(arrayfun(@(C) numel(C.data) >= j && ~isempty(C.data{j}), S.conds)), ...
    1:numel(all_levels)));
if isempty(lv), lv = li; end
nL = numel(lv);
axS = axes(fh,'Position',[0.775 0.52 0.22 0.36],'Tag','efr_table');  hold(axS,'on');
axis(axS,'off');  xlim(axS,[0 1]);  ylim(axS,[0 1]);
fs = 12;  if nC*nL > 4, fs = 10; end
if nC*nL > 8, fs = 9; end
% row labels short ("All (H1–H16)"); value columns start where the widest
% label ends + 8 px (apat_table_x0: measured, so labels never run into values)
rowlab = {LB.low, LB.high, regexprep(LB.total, '^All Harmonics', 'All')};
x0 = apat_table_x0(axS, rowlab, fs-1, {'00.00'}, fs, nC*nL, 0.01, 0.30, 8);
cw = (1 - x0) / max(nC,1);  sw = cw / nL;  rh = 0.13;
fsv = apat_table_fit('fs', axS, {'00.000'}, fs, sw, 7);   % values fit their sub-column (apat_table_fit)
text(axS, 0.5, 0.99, 'Harmonic Sums', 'FontSize',15, 'FontWeight','bold', 'Color',INK, ...
    'HorizontalAlignment','center', 'VerticalAlignment','top');
text(axS, 0.5, 0.85, sprintf('Low / High: %s', LB.measure), 'FontSize',fs-2, 'Color',MUTE, ...
    'HorizontalAlignment','center', 'VerticalAlignment','middle');
y = 0.71;
for c = 1:nC                                       % condition headers
    hh = text(axS, x0 + (c-0.5)*cw, y, S.conds(c).name, 'FontSize',fs, 'FontWeight','bold', 'Color',S.conds(c).clr, ...
        'HorizontalAlignment','center', 'VerticalAlignment','middle', 'Interpreter','none');
    apat_table_fit('text', hh, cw, 7);           % fits its column: smaller, two lines, then '…'
end
if nL > 1                                          % level sub-column headers
    y = y - 0.75*rh;
    for c = 1:nC
        for j = 1:nL
            hh = text(axS, x0 + (c-1)*cw + (j-0.5)*sw, y, sprintf('%g dB', all_levels(lv(j))), ...
                'FontSize',fs-2, 'FontWeight','bold', 'Color',MUTE, ...
                'HorizontalAlignment','center', 'VerticalAlignment','middle');
            apat_table_fit('text', hh, sw, 7, 1);
        end
    end
end
plot(axS, [0 1], [y-rh/2 y-rh/2], '-', 'Color',GOLD, 'LineWidth',1.2);
for c = 2:nC                                       % light dividers between conditions
    xd = x0 + (c-1)*cw;
    plot(axS, [xd xd], [y-rh/2-3*rh y+rh/2], '-', 'Color',[0.88 0.88 0.88], 'LineWidth',0.8);
end
for k = 1:3
    y = y - rh;
    % rows shaded like their harmonics in the plot: Low range (light grey),
    % High range (dark grey), All (plain) — apat_region_tints
    T = apat_region_tints();  g = 0.08*rh;
    rc = {apat_shade_eff(T(1,:)), apat_shade_eff(T(3,:))};
    if k <= 2                                     % "All" row unshaded (not one range)
        patch(axS, [0 1 1 0], [y-rh/2+g y-rh/2+g y+rh/2-g y+rh/2-g], rc{k}, ...
            'EdgeColor','none', 'Tag','apat_xgroup');
    end
    text(axS, 0.01, y, rowlab{k}, 'FontSize',fs-1, 'Color',INK, 'VerticalAlignment','middle');
    for c = 1:nC
        for j = 1:nL
            d = [];  v = '—';
            if numel(S.conds(c).data) >= lv(j), d = S.conds(c).data{lv(j)}; end
            if ~isempty(d)
                te  = [];  if isfield(d,'t_env'), te = d.t_env; end
                mt  = efr_ram_metrics(d.peaks, d.peaks_locs, d.f, d.plv_env, o, te);
                val = [mt.low, mt.high, mt.total];
                if ~isnan(val(k))
                    if k <= 2 && strcmp(o.measure,'magnitude') && ~o.normalize, v = sprintf('%.3f', val(k));
                    else, v = sprintf('%.2f', val(k)); end
                end
            end
            text(axS, x0 + (c-1)*cw + (j-0.5)*sw, y, v, 'FontSize',fsv, 'Color',INK, ...
                'FontWeight',ternary_s(k==3,'bold','normal'), ...
                'HorizontalAlignment','center', 'VerticalAlignment','middle');
        end
    end
end
end


% ── helpers ────────────────────────────────────────────────────────────
function fh = get_fig(nm)
% Always a fresh figure: an old one with the same name (left open by an
% earlier, interrupted run) existed before this subject started, so the app
% would not pick it up for embedding. Everything is redrawn from appdata.
old = findobj('Type','figure','Name',nm,'-not','Tag','APAT_efr_avg');
if ~isempty(old), close(old); end
fh = figure('Name',nm,'NumberTitle','off','Visible','off','Color','w');
set(fh,'Units','normalized','OuterPosition',[0.05 0.05 0.9 0.85]);
end

function C = harm_tint(nH)
% Tint per harmonic: Low range blue-grey, High range rose, others grey.
o = efr_opts();  T = apat_region_tints();
C = repmat([0.88 0.88 0.88], nH, 1);
for h = 1:nH
    if h >= o.low(1)  && h <= o.low(end),  C(h,:) = T(1,:); end
    if h >= o.high(1) && h <= o.high(end), C(h,:) = T(3,:); end
end
end


function style_ax(ax, xl, yl)
set(ax, 'FontSize',14, 'Box','off');  grid(ax,'on');
xlabel(ax, xl, 'FontWeight','bold');
if ~isempty(yl), ylabel(ax, yl, 'FontWeight','bold'); end
end

function s = plv_sum(p)
p = p(:);  s = sum(p(1:min(16,numel(p))), 'omitnan');
end

function pad_ylim(ax, pad)
if nargin < 2, pad = 0.12; end
yy = [];
for h = findall(ax, 'Type','line')'
    v = double(h.YData);  yy = [yy, v(isfinite(v))]; %#ok<AGROW>
end
if isempty(yy), return; end
lo = min(yy);  hi = max(yy);  r = hi - lo;
if r == 0, r = max(abs(lo), 0.1); end
ylim(ax, [lo - pad*r, hi + pad*r]);
end

function s = ternary_s(c, a, b)
if c, s = a; else, s = b; end
end
