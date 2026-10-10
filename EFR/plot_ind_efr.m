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
            draw_ram_level(fh, S, all_levels(li), li);
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
axH = axes(fh,'Position',[0 0.93 0.86 0.06],'Visible','off');
text(axH, 0.5, 0.5, sprintf('%s EFR dAM — %d dB SPL', S.subj, round(lev)), 'FontSize',16, ...
    'FontWeight','bold', 'HorizontalAlignment','center', 'Interpreter','none', 'Color',INK);
% Time series (left)
axT = axes(fh,'Position',[0.06 0.13 0.40 0.70],'Tag','efr_time_tile');  hold(axT,'on');
% Frequency (right)
axF = axes(fh,'Position',[0.53 0.13 0.30 0.70],'Tag','efr_freq_tile');  hold(axF,'on');
missing = false;  tmax = 0;
for c = 1:numel(S.conds)
    C = S.conds(c);  d = C.data{li};
    if isempty(d), continue; end
    if isfield(d,'t') && isfield(d,'t_env') && ~isempty(d.t_env)
        plot(axT, d.t, d.t_env, '-', 'Color',C.clr, 'LineWidth',1, 'DisplayName',C.name, ...
            'Tag','efr_wave', 'UserData',round(lev));
        tmax = max(tmax, max(d.t));
    else
        missing = true;
    end
    plot(axF, d.trajectory, d.dAMpower, '-', 'Color',[C.clr 0.30], 'LineWidth',1, 'HandleVisibility','off');
    if isfield(d,'smooth') && isfield(d.smooth,'f')
        plot(axF, d.smooth.f, d.smooth.dAM, '-', 'Marker',C.shp, 'MarkerSize',9, 'MarkerFaceColor',C.clr, ...
            'MarkerEdgeColor',C.clr, 'LineWidth',2, 'Color',C.clr, 'DisplayName',C.name);
        plot(axF, d.smooth.f, d.smooth.NF, '--', 'Color',C.clr, 'LineWidth',1.5, 'HandleVisibility','off');
    end
end
style_ax(axT, 'Time (s)', 'Amplitude (\muV)');
title(axT, 'Time', 'FontSize',14, 'FontWeight','bold');
if tmax > 0, xlim(axT, [0 tmax]); end
pad_ylim(axT);
if missing
    text(axT, 0.02, 0.04, 'No saved time waveform for some conditions — re-run the dAM analysis.', ...
        'Units','normalized', 'FontSize',11, 'Color',MUTE, 'VerticalAlignment','bottom');
end
style_ax(axF, 'Modulation Frequency (Hz)', 'Power (dB)');
title(axF, 'Frequency', 'FontSize',14, 'FontWeight','bold');
set(axF, 'XScale','log');
pad_ylim(axF);
text(axF, 1, -0.17, 'dashed = noise floor', 'Units','normalized', 'FontSize',11, ...
    'Color',MUTE, 'HorizontalAlignment','right', 'VerticalAlignment','top');
if ~isempty(findall(axF,'Type','line','HandleVisibility','on'))
    lg = legend(axF, 'Orientation','horizontal', 'Box','off', 'FontSize',14, 'Location','none');
    lg.Units = 'normalized';
    lg.Position(1) = 0.06 + (0.77 - lg.Position(3))/2;
    lg.Position(2) = 0.865;
end
end


% ═════════════════════════════════════════════════════════════════════════
function draw_ram_level(fh, S, lev, li)
INK = [0.15 0.15 0.15];  MUTE = [0.45 0.45 0.45];  GOLD = [0.81 0.73 0.57];
axH = axes(fh,'Position',[0 0.93 1 0.06],'Visible','off');
text(axH, 0.5, 0.5, sprintf('%s EFR RAM — %d dB SPL', S.subj, round(lev)), 'FontSize',16, ...
    'FontWeight','bold', 'HorizontalAlignment','center', 'Interpreter','none', 'Color',INK);
axT = axes(fh,'Position',[0.05 0.13 0.30 0.70],'Tag','efr_time_tile');  hold(axT,'on');
axF = axes(fh,'Position',[0.40 0.13 0.26 0.70],'Tag','efr_freq_tile');  hold(axF,'on');
nC = numel(S.conds);  missing = false;  tmax = 0;  fmax = 0;  pmax = 0.1;
for c = 1:nC
    C = S.conds(c);  d = C.data{li};
    if isempty(d), continue; end
    if isfield(d,'t') && isfield(d,'t_env') && ~isempty(d.t_env)
        plot(axT, d.t, d.t_env, '-', 'Color',C.clr, 'LineWidth',1.5, 'DisplayName',C.name, ...
            'Tag','efr_wave', 'UserData',round(lev));
        tmax = max(tmax, max(d.t));
    else
        missing = true;
    end
    plot(axF, d.f, d.plv_env, '-', 'Color',[C.clr 0.45], 'LineWidth',1, 'HandleVisibility','off');
    plot(axF, d.peaks_locs, d.peaks, 'LineStyle','none', 'Marker',C.shp, 'MarkerSize',9, ...
        'MarkerFaceColor',C.clr, 'MarkerEdgeColor',C.clr, 'LineWidth',2, 'DisplayName',C.name);
    pl = d.peaks_locs(isfinite(d.peaks_locs));  if ~isempty(pl), fmax = max(fmax, max(pl)); end
    pmax = max([pmax; d.peaks(:)]);
end
style_ax(axT, 'Time (s)', 'Amplitude (\muV)');
title(axT, 'Time', 'FontSize',14, 'FontWeight','bold');
if tmax >= 0.40, xlim(axT, [0.30 0.40]); elseif tmax > 0, xlim(axT, [0 tmax]); end
pad_ylim(axT);
if missing
    text(axT, 0.02, 0.04, 'No saved time waveform for some conditions.', ...
        'Units','normalized', 'FontSize',11, 'Color',MUTE, 'VerticalAlignment','bottom');
end
style_ax(axF, 'Frequency (Hz)', 'PLV');
title(axF, 'Frequency', 'FontSize',14, 'FontWeight','bold');
if fmax > 0, xlim(axF, [0 fmax + 200]); end
ylim(axF, [0 1.15*pmax]);
if ~isempty(findall(axF,'Type','line','HandleVisibility','on'))
    lg = legend(axF, 'Orientation','horizontal', 'Box','off', 'FontSize',14, 'Location','none');
    lg.Units = 'normalized';
    lg.Position(1) = 0.05 + (0.61 - lg.Position(3))/2;
    lg.Position(2) = 0.865;
end
% ── harmonic-sum table for this level (top right) ───────────────────────
o  = efr_opts();  LB = efr_ram_labels(o);
axS = axes(fh,'Position',[0.70 0.56 0.29 0.30],'Tag','efr_table');  hold(axS,'on');
axis(axS,'off');  xlim(axS,[0 1]);  ylim(axS,[0 1]);
fs = 13;  if nC > 3, fs = 11; end
x0 = 0.46;  cw = (1 - x0) / max(nC,1);  rh = 0.15;
text(axS, 0.5, 0.97, 'Harmonic sums', 'FontSize',15, 'FontWeight','bold', 'Color',INK, ...
    'HorizontalAlignment','center', 'VerticalAlignment','top');
text(axS, 0.5, 0.80, sprintf('Low / High: %s', LB.measure), 'FontSize',fs-2, 'Color',MUTE, ...
    'HorizontalAlignment','center', 'VerticalAlignment','middle');
y = 0.64;
for c = 1:nC
    nm = S.conds(c).name;  if numel(nm) > 12, nm = [nm(1:11) '…']; end
    text(axS, x0 + (c-0.5)*cw, y, nm, 'FontSize',fs, 'FontWeight','bold', 'Color',S.conds(c).clr, ...
        'HorizontalAlignment','center', 'VerticalAlignment','middle', 'Interpreter','none');
end
plot(axS, [0 1], [y-rh/2 y-rh/2], '-', 'Color',GOLD, 'LineWidth',1.2);
rowlab = {LB.low, LB.high, LB.total};
for k = 1:3
    y = y - rh;
    if k == 3
        patch(axS, [0 1 1 0], [y-rh/2 y-rh/2 y+rh/2 y+rh/2], [0.97 0.97 0.97], 'EdgeColor','none');
    end
    text(axS, 0.01, y, rowlab{k}, 'FontSize',fs-1, 'Color',INK, 'VerticalAlignment','middle');
    for c = 1:nC
        d = S.conds(c).data{li};  v = '—';
        if ~isempty(d)
            mt  = efr_ram_metrics(d.peaks, d.peaks_locs, d.f, d.plv_env, o);
            val = [mt.low, mt.high, mt.total];
            if ~isnan(val(k)), v = sprintf('%.2f', val(k)); end
        end
        text(axS, x0 + (c-0.5)*cw, y, v, 'FontSize',fs, 'Color',INK, ...
            'FontWeight',ternary_s(k==3,'bold','normal'), ...
            'HorizontalAlignment','center', 'VerticalAlignment','middle');
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
