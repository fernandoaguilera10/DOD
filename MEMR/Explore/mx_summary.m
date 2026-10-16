function mx_summary(type, filepath, OUTdir, Conds2Run, Chins2Run, all_Conds2Run, ...
        ChinIND, CondIND, idx_plot_relative, colors, shapes, is_last_pair, subj_active_conds) %#ok<INUSL>
%MX_SUMMARY  Individual + group figures of one exploratory MEMR view.
%
%   type  'Vector' | 'Growth' | 'Kinetics' | 'Spectral' | 'Absorbance' |
%         'Probe' | 'Quality'
%
%   Loads <subject>_MX_<condition>_*.mat (mx_analysis) into the global
%   memrx_data{subject, condition}; redraws the subject's individual figure
%   (Tag 'memr_ind', all its conditions so far); on the last subject /
%   condition pair of the run draws the group figure (Tag 'memr_avg') and
%   saves Analysis/MEMR/Average/MEMR_<type>_Average.mat (+ _figure.png, .csv).
%   Same layout and conventions as the ART figures: conditions in their
%   colours / markers, subject points Tag 'memr_subj_pts' (subject ID in
%   DisplayName), level families in viridis with a level colour bar,
%   legends at the bottom (apat_legend), right strip left free for the
%   app's Plot Settings. Exclusions: means / SD / n without the excluded
%   pairs, subject points keep everyone (apat_excl).
global memrx_data
nS = numel(Chins2Run);  nC = numel(all_Conds2Run);
if ~iscell(memrx_data) || size(memrx_data,1) ~= nS || size(memrx_data,2) ~= nC
    memrx_data = cell(nS, nC);
end
subj = Chins2Run{ChinIND};
cond = last_part(all_Conds2Run{CondIND});

%% ── Load this subject / condition ──────────────────────────────────────
d = dir(fullfile(filepath, sprintf('%s_MX_%s_*.mat', subj, cond)));
if ~isempty(d), d = d(~strncmp({d.name}, '._', 2)); end
if isempty(d)
    fprintf('MEMR %s: no explore file for %s (%s) — run it with Re-analyze if this persists.\n', type, subj, cond);
else
    [~, j] = max([d.datenum]);
    tmp = load(fullfile(filepath, d(j).name), 'mx');
    memrx_data{ChinIND, CondIND} = tmp.mx;
end

%% ── Individual figure (all conditions of this subject so far) ───────────
C = struct('name',{}, 'clr',{}, 'shp',{}, 'idx',{}, 'Q',{});
for c = 1:nC
    if isempty(memrx_data{ChinIND, c}), continue; end
    shp = strtrim(char(shapes(mod(c-1, size(shapes,1)) + 1, :)));  if isempty(shp), shp = 'o'; end
    C(end+1) = struct('name', last_part(all_Conds2Run{c}), 'clr', colors(mod(c-1, size(colors,1)) + 1, 1:3), ...
        'shp', shp, 'idx', c, 'Q', mx_data('quant', type, memrx_data{ChinIND, c})); %#ok<AGROW>
end
old = findobj('Type','figure', 'Tag','memr_ind');
if ~isempty(old), close(old); end
if ~isempty(C)
    fh = draw_figure(type, 'ind', C, {}, sprintf('%s  MEMR %s', subj, type), '');
    if ~isempty(subj_active_conds) && CondIND == subj_active_conds(end) && exist(filepath, 'dir')
        try, apat_save_fig(fh, apat_out_dir('all_file', filepath, sprintf('%s_MEMR_%s_figure', subj, type)), ...
                ['mx_' lower(type) '_ind']); catch, end
    end
end

%% ── Rows of this recording for this view (kept for the average files) + CSV ────
if ~isempty(memrx_data{ChinIND, CondIND})
    try
        apat_csv('rec', ['mx_' type], [subj '|' cond], mx_rows(subj, cond, type, memrx_data{ChinIND, CondIND}), ...
            fullfile(filepath, sprintf('%s_MEMR%s_%s.csv', subj, type, cond)));
    catch ME, warning('APAT:csv', 'MEMR %s CSV: %s', type, ME.message);
    end
end

%% ── Group figure ────────────────────────────────────────────────────────
if is_last_pair
    F = memrx_data;                                   % everyone (subject points)
    apat_excl('apply', Chins2Run, all_Conds2Run);     % empties excluded cells of memrx_data
    M = memrx_data;                                   % without the excluded pairs
    A = mx_data('avg', type, F, M, Chins2Run, all_Conds2Run, colors, shapes, idx_plot_relative);
    old = findobj('Type','figure', 'Tag','memr_avg');
    if ~isempty(old), close(old); end
    if isempty(A.cols)
        fprintf('MEMR %s: nothing to average.\n', type);
        return
    end
    ttl = sprintf('MEMR %s Average', type);
    if A.relative, ttl = sprintf('%s (re. %s)', ttl, A.ref_name); end
    fh = draw_figure(type, 'avg', A.cols, A.subjects, ttl, A.ref_name);
    average = summarize(A);
    outdir = apat_out_dir('avg', fullfile(OUTdir, 'MEMR'));   % Analysis/MEMR/Average
    if ~exist(outdir, 'dir'), try, mkdir(outdir); catch, end, end
    fname = sprintf('MEMR_%s_Average', type);
    if apat_csv('avg_mat'), try, apat_avg_mat('save', fullfile(outdir, [fname '.mat']), 'average', average); catch, end, end   % average.<EXP>
    try, apat_save_fig(fh, fullfile(outdir, [fname '_figure']), ['mx_' lower(type) '_avg']); catch, end
    % Individual values (Excluded flag) + cell Mean / SD / N: CSV + average.individual
    try
        I = apat_csv('average', ['mx_' type], fullfile(outdir, [fname '.csv']), Chins2Run, all_Conds2Run, idx_plot_relative);
        if apat_csv('avg_mat'), apat_csv('attach', fullfile(outdir, fname), I); end
    catch
    end
end
end


% ══════════════════════════════════════════════════════════════════════════
%  View layouts
% ══════════════════════════════════════════════════════════════════════════
function V = view_spec(type)
% Panels: kind 'lev' (vs elicitor level), 'sca' (one value per condition),
% 'cur' (one curve per condition), 'fam' (one curve per level, one small
% panel per condition). key = Q field; nf = noise-floor series drawn
% dashed; zero = dashed 0 line; logy; crit = dotted reference line (y).
P = @(kind, key, pos, ttl, ylab) struct('kind',kind, 'key',key, 'pos',pos, 'title',ttl, 'ylab',ylab, ...
    'xlab','', 'nf','', 'zero',false, 'logy',false, 'crit',NaN, 'fit',false, 'xscale','linear', ...
    'xdiv',1, 'markers',false, 'nf2','');
L1 = [0.06 0.22 0.20 0.64];                          % left growth panel
S1 = [0.31 0.22 0.07 0.64];                          % first category panel
FB = [0.46 0.22 0.34 0.64];                          % level-family block (as ART Growth Response)
NFK = struct('args',{{'LineStyle','--','Color',[0.35 0.35 0.35],'LineWidth',1.5}}, 'label','Noise Floor');
keys = struct('args',{}, 'label',{});
switch type
    case 'Vector'
        p1 = P('lev','V', L1, 'Vector Growth', 'Vector Change (%)');  p1.nf = 'Vn';
        p2 = P('sca','thr_nf', S1, 'NF Threshold', 'Noise-Floor Threshold (dB FPL)');
        p3 = P('sca','vart', [0.43 0.22 0.07 0.64], 'Vector ART', 'Vector ART (dB FPL)');
        p4 = P('lev','P', [0.57 0.22 0.20 0.64], 'Power Change', 'Band Power Change (dB)');  p4.zero = true;
        panels = [p1 p2 p3 p4];  keys = NFK;
    case 'Growth'
        p1 = P('lev','V', [0.06 0.22 0.25 0.64], 'Growth Function', 'Vector Change (%)');
        p1.nf = 'Vn';  p1.fit = true;
        T = {'max','Max Response','Max Response (%)'; 'x0','Midpoint','Midpoint (dB FPL)'; ...
             'slope','Slope At Midpoint','Slope At Midpoint (%/dB)'; 'dyn','Dynamic Range','10–90 % Range (dB)'; ...
             'auc','Area Above Noise','Area Above Noise (% \times dB)'; 'supra','Suprathreshold Slope','Suprathreshold Slope (%/dB)'};
        x0 = 0.40;  w = 0.105;  gx = 0.045;  h = 0.25;  gy = 0.14;
        panels = p1;
        for i = 1:6
            r = ceil(i/3);  cc = i - (r-1)*3;
            pos = [x0 + (cc-1)*(w+gx), 0.22 + (2-r)*(h+gy), w, h];
            pp = P('sca', T{i,1}, pos, T{i,2}, T{i,3});
            panels(end+1) = pp; %#ok<AGROW>
        end
        keys = [NFK, struct('args',{{'LineStyle','-','Color',[0.35 0.35 0.35],'LineWidth',1}}, 'label','Sigmoid Fit')];
    case 'Kinetics'
        p1 = P('lev','bi', L1, 'Build-Up Index', 'Build-Up Index (Late − First) / Max');  p1.zero = true;
        p2 = P('sca','tau', S1, 'Time Constant', 'Time Constant At Top Level (ms)');
        p3 = P('fam','', FB, 'Click-By-Click Change', 'Vector Change (%)');
        p3.xlab = 'Time re. First Elicitor Onset (ms)';  p3.markers = true;
        panels = [p1 p2 p3];
    case 'Spectral'
        p1 = P('cur','band', L1, 'Band Change At Top Level', '\DeltaEar-Canal Level (dB re. Click 1)');
        p1.xlab = 'Band Centre (kHz)';  p1.xscale = 'log';  p1.xdiv = 1e3;  p1.zero = true;  p1.markers = true;
        p2 = P('sca','peak', S1, 'Peak Frequency', 'Frequency Of Largest Change (kHz)');
        p3 = P('fam','', FB, 'Spectral Change', '\DeltaEar-Canal Level (dB re. Click 1)');
        p3.xlab = 'Frequency (kHz)';  p3.xscale = 'log';  p3.xdiv = 1e3;
        panels = [p1 p2 p3];
    case 'Absorbance'
        p1 = P('lev','dA_low', [0.06 0.22 0.15 0.64], 'Absorbance Growth', '\DeltaAbsorbance 0.25–1 kHz');  p1.zero = true;
        p2 = P('cur','A0', [0.27 0.22 0.13 0.64], 'Baseline Absorbance', 'Absorbance');
        p2.xlab = 'Frequency (kHz)';  p2.xscale = 'log';  p2.xdiv = 1e3;
        p3 = P('fam','', FB, 'Absorbance Change', '\DeltaAbsorbance re. No Elicitor');
        p3.xlab = 'Frequency (kHz)';  p3.xscale = 'log';  p3.xdiv = 1e3;
        panels = [p1 p2 p3];
    case 'Probe'
        p1 = P('lev','D', L1, 'Probe Growth', 'Elicitor Probe Change (%)');  p1.nf = 'N';
        p2 = P('sca','thr', S1, 'Probe Threshold', 'Probe Threshold (dB FPL)');
        p3 = P('fam','', FB, 'Change During The Elicitor', 'Elicitor Probe Change (%)');
        p3.xlab = 'Time re. Elicitor Onset (ms)';
        panels = [p1 p2 p3];  keys = NFK;
    case 'Quality'
        w = 0.145;  g = 0.053;
        p1 = P('lev','good',  [0.06 0.22 w 0.64], 'Good Clicks', 'Good Clicks (%)');
        p2 = P('lev','var',   [0.06+(w+g) 0.22 w 0.64], 'Baseline Variability', 'Click 1 Trial-To-Trial Variability (%)');
        p3 = P('lev','drift', [0.06+2*(w+g) 0.22 w 0.64], 'Baseline Drift', 'Click 1 Change re. Lowest Level (%)');
        p4 = P('lev','snr',   [0.06+3*(w+g) 0.22 w 0.64], 'Signal-To-Noise', 'SNR (Response / Noise Floor)');
        p4.logy = true;  p4.crit = 3;  p4.nf2 = 'psnr';
        panels = [p1 p2 p3 p4];
        keys = [struct('args',{{'LineStyle','-','Color',[0.35 0.35 0.35],'LineWidth',2}}, 'label','Click SNR'), ...
                struct('args',{{'LineStyle','--','Color',[0.35 0.35 0.35],'LineWidth',1.5}}, 'label','Probe SNR'), ...
                struct('args',{{'LineStyle',':','Color',[0 0 0],'LineWidth',1.5}}, 'label','Detection Criterion (3)')];
    otherwise
        error('mx_summary: unknown view %s', type);
end
% full-width layout (×1.22 from the left edge 0.06; Oct 15): the layouts above were
% drawn for plots ending at 0.80 (room for the old control strip) and were
% stretched after embedding — now they are drawn at their final width
for i = 1:numel(panels)
    q = panels(i).pos;
    panels(i).pos = [0.06 + (q(1) - 0.06)*1.22, q(2), q(3)*1.22, q(4)];
end
V = struct('panels', panels, 'keys', keys);
end


% ══════════════════════════════════════════════════════════════════════════
%  Figure
% ══════════════════════════════════════════════════════════════════════════
function fh = draw_figure(type, mode, D, subjects, ttl, ref_name)
V = view_spec(type);
avg = strcmp(mode, 'avg');
INK = [0.15 0.15 0.15];
fh = figure('NumberTitle','off', 'Visible','off', 'Color','w', 'Tag',ternary(avg,'memr_avg','memr_ind'), ...
    'Units','normalized', 'Position',[0.05 0.1 0.85 0.75]);
axH = axes(fh, 'Position',[0 0.92 1 0.06], 'Visible','off');
text(axH, 0.5, 0.62, ttl, 'FontSize',16, 'FontWeight','bold', 'HorizontalAlignment','center', ...
    'Interpreter','none', 'Color',INK);
nt = notes(type, mode, D);
if ~isempty(nt)
    text(axH, 0.5, -0.05, nt, 'FontSize',11, 'HorizontalAlignment','center', 'Interpreter','none', ...
        'Color',[0.40 0.40 0.40]);
end
rel = avg && ~isempty(ref_name);
ax1 = [];
for i = 1:numel(V.panels)
    p = V.panels(i);
    if rel, p = rel_labels(p, ref_name); end
    switch p.kind
        case 'lev', ax = axes(fh, 'Position',p.pos, 'Tag','mx_ax');  draw_lev(ax, p, D, mode, subjects, rel);
        case 'sca', ax = axes(fh, 'Position',p.pos, 'Tag','mx_ax');  draw_sca(ax, p, D, mode, subjects, rel);
        case 'cur', ax = axes(fh, 'Position',p.pos, 'Tag','mx_ax');  draw_cur(ax, p, D, mode, subjects, rel);
        case 'fam', ax = draw_family(fh, p, D, mode);
    end
    if isempty(ax1) && ~isempty(ax), ax1 = ax(1); end
end
% legend: conditions (+ line keys)
LC = struct('clr',{}, 'shp',{}, 'label',{});
for j = 1:numel(D)
    lbl = D(j).name;
    if avg
        lbl = sprintf('%s (n = %d)', D(j).name, D(j).n);
    elseif isfield(D(j).Q, 'ntr') && isfinite(D(j).Q.ntr)       % trials of this recording
        lbl = sprintf('%s (n = %d trials)', D(j).name, round(D(j).Q.ntr));
    end
    LC(end+1) = struct('clr',D(j).clr, 'shp',D(j).shp, 'label',lbl); %#ok<AGROW>
end
keys = V.keys;
if rel && ~isempty(keys)                                 % no noise floor / fit when relative
    keys = keys(~ismember({keys.label}, {'Noise Floor','Sigmoid Fit'}));
end
if ~isempty(ax1), apat_legend(fh, ax1, LC, keys, 0.06, 0.903); end
end


function p = rel_labels(p, ref)
% relative plots: values are differences re. the reference condition
if any(strcmp(p.kind, {'lev','sca','cur'}))
    u = regexp(p.ylab, '\(([^)]*)\)\s*$', 'tokens', 'once');
    base = strtrim(regexprep(p.ylab, '\([^)]*\)\s*$', ''));
    if ~isempty(u), p.ylab = sprintf('%s Shift (%s re. %s)', base, u{1}, ref);
    else, p.ylab = sprintf('%s Shift (re. %s)', base, ref); end
    p.nf = '';  p.nf2 = '';  p.fit = false;  p.logy = false;  p.crit = NaN;  p.zero = true;
end
end


function nt = notes(type, mode, D)
nt = '';
if ~strcmp(type, 'Absorbance') || ~strcmp(mode, 'ind'), return; end
parts = {};
for j = 1:numel(D)
    q = D(j).Q;
    if ~isempty(q.note), parts{end+1} = sprintf('%s: %s', D(j).name, q.note); end %#ok<AGROW>
end
nt = strjoin(parts, '   ·   ');
end


% ── series vs elicitor level ───────────────────────────────────────────
function draw_lev(ax, p, D, mode, subjects, rel)
hold(ax, 'on');
avg = strcmp(mode, 'avg');
ev = [];
for j = 1:numel(D)
    if avg, ev = [ev, D(j).lev.(p.key).x]; %#ok<AGROW>
    elseif D(j).Q.ok, ev = [ev, D(j).Q.elic]; end %#ok<AGROW>
end
ev = unique(ev(isfinite(ev)));
if isempty(ev), no_data(ax, p); return; end
de = 5;  if numel(ev) > 1, de = median(diff(ev)); end
xlim(ax, [min(ev) - 0.6*de, max(ev) + 0.6*de]);
[ms, sa] = apat_ms(ax, 0.7*de);
for j = 1:numel(D)
    clr = D(j).clr;  shp = D(j).shp;
    if ~avg
        q = D(j).Q;  if ~q.ok, continue; end
        x = q.elic;  y = q.lev.(p.key);
        plot(ax, x, y, '-', 'Marker',shp, 'MarkerSize',ms, 'LineWidth',2, 'Color',clr, ...
            'MarkerFaceColor',clr, 'MarkerEdgeColor',clr, 'HandleVisibility','off');
        if ~isempty(p.nf)
            plot(ax, x, q.lev.(p.nf), '--', 'Color',clr, 'LineWidth',1.4, 'HandleVisibility','off');
        end
        if ~isempty(p.nf2)
            plot(ax, x, q.lev.(p.nf2), '--', 'Marker',shp, 'MarkerSize',max(6, round(ms/2)), 'Color',clr, ...
                'MarkerFaceColor','w', 'LineWidth',1.4, 'HandleVisibility','off');
        end
        if p.fit && isfield(q.cur, 'fit') && ~isempty(q.cur.fit.x)
            plot(ax, q.cur.fit.x, q.cur.fit.y, '-', 'Color',clr, 'LineWidth',1, 'HandleVisibility','off');
        end
    else
        L = D(j).lev.(p.key);  x = L.x;
        for s = 1:size(L.F, 1)
            y = L.F(s, :);  g = isfinite(y);
            if ~any(g), continue; end
            jit = ((mod(s*7, 11)/10) - 0.5) * 0.06 * de;
            scatter(ax, x(g) + jit, y(g), sa, clr, shp, 'filled', 'MarkerFaceAlpha',0.30, ...
                'MarkerEdgeColor','none', 'HandleVisibility','off', 'Tag','memr_subj_pts', ...
                'DisplayName',subj_name(subjects, s));
        end
        st = mx_data('stats', L.M);
        g = isfinite(st.mean);
        if ~any(g), continue; end
        plot(ax, x(g), st.mean(g), '-', 'LineWidth',2, 'Color',clr, 'HandleVisibility','off');
        errorbar(ax, x(g), st.mean(g), st.sd(g), 'Marker',shp, 'LineStyle','none', 'LineWidth',2, ...
            'MarkerSize',ms, 'Color',clr, 'MarkerFaceColor',clr, 'MarkerEdgeColor',clr, 'HandleVisibility','off');
        if ~isempty(p.nf) && ~rel
            sn = mx_data('stats', D(j).lev.(p.nf).M);
            plot(ax, x, sn.mean, '--', 'Color',clr, 'LineWidth',1.4, 'HandleVisibility','off');
        end
        if ~isempty(p.nf2) && ~rel
            sn = mx_data('stats', D(j).lev.(p.nf2).M);
            plot(ax, x, sn.mean, '--', 'Marker',shp, 'MarkerSize',max(6, round(ms/2)), 'Color',clr, ...
                'MarkerFaceColor','w', 'LineWidth',1.4, 'HandleVisibility','off');
        end
        if p.fit && ~rel
            [~, sg] = mx_sigfit(x(g), st.mean(g));
            if all(isfinite(sg))
                xf = linspace(min(x), max(x), 121);
                plot(ax, xf, sg(1) + sg(2) ./ (1 + exp(-sg(3) * (xf - sg(4)))), '-', 'Color',clr, ...
                    'LineWidth',1, 'HandleVisibility','off');
            end
        end
    end
end
style_axes(ax, p, 'Elicitor Level (dB FPL)');
if numel(ev) > 1
    stp = de;  if numel(ev) > 10, stp = 2*de; end
    xticks(ax, ev(1):stp:ev(end));
end
fit_y(ax, p);
ref_lines(ax, p);
try, apat_xgroups(ax, ev); catch, end
end


% ── one value per condition ────────────────────────────────────────────
function draw_sca(ax, p, D, mode, subjects, rel) %#ok<INUSD>
hold(ax, 'on');
avg = strcmp(mode, 'avg');
nK = numel(D);
xlim(ax, [0.5 max(nK,1) + 0.5]);
[ms, sa] = apat_ms(ax, 0.7);
lab = cell(1, nK);  miss = cell(1, nK);
for j = 1:nK
    clr = D(j).clr;  shp = D(j).shp;  lab{j} = D(j).name;
    if ~avg
        q = D(j).Q;  v = NaN;
        if q.ok && isfield(q.sca, p.key), v = double(q.sca.(p.key)); end
        if isfinite(v)
            plot(ax, j, v, 'LineStyle','none', 'Marker',shp, 'MarkerSize',ms, 'LineWidth',2, 'Color',clr, ...
                'MarkerFaceColor',clr, 'MarkerEdgeColor',clr, 'HandleVisibility','off');
        else
            miss{j} = 'None';
        end
    else
        S = D(j).sca.(p.key);
        for s = 1:numel(S.F)
            if ~isfinite(S.F(s)), continue; end
            scatter(ax, j + ((mod(s*7, 11)/10) - 0.5) * 0.08, S.F(s), sa, clr, shp, 'filled', ...
                'MarkerFaceAlpha',0.30, 'MarkerEdgeColor','none', 'HandleVisibility','off', ...
                'Tag','memr_subj_pts', 'DisplayName',subj_name(subjects, s));
        end
        st = mx_data('stats', S.M);
        if isfinite(st.mean)
            errorbar(ax, j, st.mean, st.sd, 'Marker',shp, 'LineStyle','none', 'LineWidth',2, ...
                'MarkerSize',ms, 'Color',clr, 'MarkerFaceColor',clr, 'MarkerEdgeColor',clr, 'HandleVisibility','off');
        end
        miss{j} = sprintf('%d / %d', st.n, D(j).n);       % subjects with a value / with data
    end
end
INK = [0.15 0.15 0.15];
set(ax, 'FontSize',12, 'Box','off', 'XColor',INK, 'YColor',INK, 'XTick',1:nK, 'XTickLabel',lab, ...
    'TickLabelInterpreter','none');
try, xtickangle(ax, 0); catch, end
grid(ax, 'on');  set(ax, 'XGrid','off');
ylabel(ax, p.ylab, 'FontWeight','bold', 'FontSize',12);
title(ax, p.title, 'FontSize',13, 'FontWeight','bold');
fit_y(ax, p);
ref_lines(ax, p);
yl = ylim(ax);
for j = 1:nK
    if isempty(miss{j}), continue; end
    text(ax, j, yl(1) + 0.04*diff(yl), miss{j}, 'HorizontalAlignment','center', 'VerticalAlignment','bottom', ...
        'FontSize',10, 'Color',D(j).clr * 0.8, 'Interpreter','none', 'Tag','mx_count');
end
end


% ── one curve per condition ───────────────────────────────────────────
function draw_cur(ax, p, D, mode, subjects, rel) %#ok<INUSD>
hold(ax, 'on');
avg = strcmp(mode, 'avg');
xx = [];
for j = 1:numel(D)
    if avg, xx = [xx, D(j).cur.(p.key).x]; %#ok<AGROW>
    elseif D(j).Q.ok && isfield(D(j).Q.cur, p.key), xx = [xx, D(j).Q.cur.(p.key).x]; end %#ok<AGROW>
end
xx = unique(xx(isfinite(xx) & xx > 0)) / p.xdiv;
if isempty(xx), no_data(ax, p); return; end
set(ax, 'XScale',p.xscale);
if strcmp(p.xscale, 'log')
    xlim(ax, [min(xx) / 2^(0.35*(numel(xx) < 10)), max(xx) * 2^(0.35*(numel(xx) < 10))]);
else
    xlim(ax, [min(xx) max(xx)]);
end
ms = 10;  sa = 60;
if numel(xx) < 10
    stp = median(diff(log10(xx)));  if ~isfinite(stp) || stp <= 0, stp = 0.3; end
    [ms, sa] = apat_ms(ax, 0.7*stp);
end
for j = 1:numel(D)
    clr = D(j).clr;  shp = D(j).shp;
    mk = 'none';  if p.markers, mk = shp; end
    if ~avg
        q = D(j).Q;
        if ~q.ok || ~isfield(q.cur, p.key) || isempty(q.cur.(p.key).x), continue; end
        plot(ax, q.cur.(p.key).x / p.xdiv, q.cur.(p.key).y, '-', 'Marker',mk, 'MarkerSize',ms, ...
            'LineWidth',2, 'Color',clr, 'MarkerFaceColor',clr, 'MarkerEdgeColor',clr, 'HandleVisibility','off');
    else
        Cv = D(j).cur.(p.key);  x = Cv.x / p.xdiv;
        st = mx_data('stats', Cv.M);
        g = isfinite(st.mean);
        if ~any(g), continue; end
        if p.markers                                  % few points: subject points + mean ± SD
            for s = 1:size(Cv.F, 1)
                y = Cv.F(s, :);  gg = isfinite(y);
                if ~any(gg), continue; end
                scatter(ax, x(gg) .* 10.^(((mod(s*7,11)/10) - 0.5) * 0.02), y(gg), sa, clr, shp, 'filled', ...
                    'MarkerFaceAlpha',0.30, 'MarkerEdgeColor','none', 'HandleVisibility','off', ...
                    'Tag','memr_subj_pts', 'DisplayName',subj_name(subjects, s));
            end
            plot(ax, x(g), st.mean(g), '-', 'LineWidth',2, 'Color',clr, 'HandleVisibility','off');
            errorbar(ax, x(g), st.mean(g), st.sd(g), 'Marker',shp, 'LineStyle','none', 'LineWidth',2, ...
                'MarkerSize',ms, 'Color',clr, 'MarkerFaceColor',clr, 'MarkerEdgeColor',clr, 'HandleVisibility','off');
        else                                          % dense curve: mean line + SD band
            up = st.mean + st.sd;  dn = st.mean - st.sd;  gb = isfinite(up) & isfinite(dn);
            if nnz(gb) > 1
                hf = fill(ax, [x(gb), fliplr(x(gb))], [up(gb), fliplr(dn(gb))], clr, 'FaceAlpha',0.15, ...
                    'EdgeColor','none', 'HandleVisibility','off', 'Tag','memr_resp_sd', 'PickableParts','none');
                set(hf, 'UserData', struct('apat_cond_rgb', clr));
            end
            plot(ax, x(g), st.mean(g), '-', 'LineWidth',2, 'Color',clr, 'HandleVisibility','off');
        end
    end
end
style_axes(ax, p, p.xlab);
if strcmp(p.xscale, 'log')
    kt = [0.125 0.25 0.5 1 2 4 8 16];
    xl = xlim(ax);  kt = kt(kt >= xl(1)*0.999 & kt <= xl(2)*1.001);
    set(ax, 'XTick',kt, 'XTickLabel',compose_g(kt));
    set(ax, 'XMinorTick','off', 'XMinorGrid','off');
end
fit_y(ax, p);
ref_lines(ax, p);
end


% ── one curve per elicitor level, one panel per condition ─────────────
function AX = draw_family(fh, p, D, mode)
% Same look as memr_resp_plot (ART Growth Response): viridis per level
% (dark purple = lowest → yellow = highest, same colour in every panel),
% one panel per condition (stacked ≤ 3, else two columns), condition name
% in its colour, own y-range per panel, level colour bar on the right.
% Tags: axes 'memr_resp_ax' (UserData memr_cond / clr / k for the app's
% y-limit rows), lines 'memr_resp', SD bands 'memr_resp_sd', colour bar
% 'memr_lvl_cbar' — so the app's MEMR controls work unchanged.
INK = [0.15 0.15 0.15];
avg = strcmp(mode, 'avg');
box = p.pos;
cond = struct('name',{}, 'clr',{}, 'x',{}, 'Y',{}, 'sd',{}, 'elic',{});
for j = 1:numel(D)
    if ~avg
        q = D(j).Q;
        if ~q.ok || isempty(q.fam.x), cond(end+1) = struct('name',D(j).name, 'clr',D(j).clr, 'x',[], 'Y',[], 'sd',[], 'elic',[]); continue; end %#ok<AGROW>
        cond(end+1) = struct('name',D(j).name, 'clr',D(j).clr, 'x',q.fam.x, 'Y',q.fam.Y, 'sd',[], 'elic',q.fam.elic); %#ok<AGROW>
    else
        fm = D(j).fam;
        if isempty(fm.x), cond(end+1) = struct('name',D(j).name, 'clr',D(j).clr, 'x',[], 'Y',[], 'sd',[], 'elic',[]); continue; end %#ok<AGROW>
        nl = numel(fm.elic);  Y = nan(nl, numel(fm.x));  SD = Y;
        for k = 1:nl
            st = mx_data('stats', reshape(fm.M(:, k, :), size(fm.M,1), []));
            Y(k, :) = st.mean;  SD(k, :) = st.sd;
        end
        keep = any(isfinite(Y), 2);
        cond(end+1) = struct('name',D(j).name, 'clr',D(j).clr, 'x',fm.x, 'Y',Y(keep,:), 'sd',SD(keep,:), ...
            'elic',fm.elic(keep)); %#ok<AGROW>
    end
end
AX = gobjects(0);
nC = numel(cond);
if nC == 0, return; end
ok = arrayfun(@(c) ~isempty(c.Y), cond);
ncol = 1 + (nC > 3);  nrow = ceil(nC / ncol);
CBW = 0.075;
box_all = box;  box(3) = box(3) - CBW;
gx = 0.035;  gy = 0.035 + 0.02*(nrow > 1);
w = (box(3) - (ncol-1)*gx) / ncol;  h = (box(4) - (nrow-1)*gy) / nrow;
xr = [];
for c = find(ok), xr = [xr, cond(c).x / p.xdiv]; end %#ok<AGROW>
if strcmp(p.xscale, 'log'), xr = xr(xr > 0); end
xl = [0 1];  if ~isempty(xr), xl = [min(xr), max(xr)]; end
if xl(2) <= xl(1), xl(2) = xl(1) + 1; end
LV = [];
for c = find(ok), LV = [LV, double(cond(c).elic(:)')]; end %#ok<AGROW>
LV = unique(LV(isfinite(LV)));
anc = [0.267 0.005 0.329; 0.283 0.141 0.458; 0.254 0.265 0.530; 0.207 0.372 0.553; ...
       0.164 0.471 0.558; 0.128 0.567 0.551; 0.135 0.659 0.518; 0.267 0.749 0.441; ...
       0.478 0.821 0.318; 0.741 0.873 0.150; 0.993 0.906 0.144];
HM = interp1(linspace(0, 1, size(anc,1)), anc, linspace(0, 1, 256));
lvl_clr = @(v) HM(1 + round(255 * (find(LV == v, 1) - 1) / max(numel(LV) - 1, 1)), :);
for c = 1:nC
    rr = ceil(c / ncol);  cc = c - (rr-1)*ncol;
    pos = [box(1) + (cc-1)*(w+gx), box(2) + box(4) - rr*h - (rr-1)*gy, w, h];
    ax = axes(fh, 'Position',pos, 'Tag','memr_resp_ax');  hold(ax, 'on');
    AX(end+1) = ax; %#ok<AGROW>
    set(ax, 'XScale',p.xscale, 'FontSize',12, 'Box','off', 'XColor',INK, 'YColor',INK, 'XLim',xl);
    set(ax, 'UserData', struct('memr_cond',cond(c).name, 'clr',cond(c).clr, 'k',c));
    grid(ax, 'on');
    Cc = cond(c);
    if ok(c)
        fx = Cc.x / p.xdiv;
        nL = size(Cc.Y, 1);
        yy = Cc.Y;
        if ~isempty(Cc.sd) && isequal(size(Cc.sd), size(Cc.Y))
            for k = 1:nL
                lc = [0.5 0.5 0.5];  if any(LV == Cc.elic(k)), lc = lvl_clr(Cc.elic(k)); end
                up = Cc.Y(k,:) + Cc.sd(k,:);  dn = Cc.Y(k,:) - Cc.sd(k,:);
                g = isfinite(up) & isfinite(dn);
                if nnz(g) < 2, continue; end
                hf = fill(ax, [fx(g), fliplr(fx(g))], [up(g), fliplr(dn(g))], lc, 'FaceAlpha',0.15, ...
                    'EdgeColor','none', 'HandleVisibility','off', 'Tag','memr_resp_sd', 'PickableParts','none');
                setappdata(hf, 'apat_cond_rgb', Cc.clr);
                set(hf, 'UserData', struct('apat_cond_rgb', Cc.clr));
            end
            yy = [Cc.Y + Cc.sd; Cc.Y - Cc.sd];
        end
        mk = 'none';  if p.markers, mk = 'o'; end
        for k = 1:nL
            lc = [0.5 0.5 0.5];  if any(LV == Cc.elic(k)), lc = lvl_clr(Cc.elic(k)); end
            hl = plot(ax, fx, Cc.Y(k,:), '-', 'Color',lc, 'LineWidth',1.6, 'Marker',mk, 'MarkerSize',4, ...
                'MarkerFaceColor',lc, 'HandleVisibility','off', 'Tag','memr_resp');
            set(hl, 'DisplayName', sprintf('%g dB FPL', Cc.elic(k)), 'UserData', struct('apat_cond_rgb', Cc.clr));
            setappdata(hl, 'apat_cond_rgb', Cc.clr);
        end
        plot(ax, xl, [0 0], 'k--', 'LineWidth',1, 'HandleVisibility','off');
        set(ax, 'YLim', fit_range(yy));
    else
        text(ax, 0.5, 0.5, 'No Data', 'Units','normalized', 'HorizontalAlignment','center', ...
            'Color',[0.5 0.5 0.5], 'FontSize',11);
    end
    text(ax, 0.02, 0.95, Cc.name, 'Units','normalized', 'FontWeight','bold', 'FontSize',12, ...
        'Color',Cc.clr, 'Interpreter','none', 'VerticalAlignment','top');
    if strcmp(p.xscale, 'log')
        kt = [0.125 0.25 0.5 1 2 4 8 16];  kt = kt(kt >= xl(1)*0.999 & kt <= xl(2)*1.001);
        set(ax, 'XTick',kt, 'XTickLabel',compose_g(kt));
        set(ax, 'XMinorGrid','off', 'XMinorTick','off');
    end
    if rr < nrow && c + ncol <= nC
        set(ax, 'XTickLabel', {});
    else
        xlabel(ax, p.xlab, 'FontWeight','bold', 'FontSize',13);
    end
end
ylabel(AX(1), p.ylab, 'FontWeight','bold', 'FontSize',13);
if nrow > 1
    yh = get(AX(1), 'YLabel');  set(yh, 'Units','normalized');
    yp = get(yh, 'Position');  yp(2) = 1 - (nrow + (nrow - 1) * gy/h) / 2;  set(yh, 'Position', yp);
end
title(AX(1), p.title, 'FontSize',14, 'FontWeight','bold');
if ncol > 1
    th = get(AX(1), 'Title');  set(th, 'Units','normalized');
    tp = get(th, 'Position');  tp(1) = (box(3)/2) / w;  set(th, 'Position', tp);
end
if ~isempty(LV)
    lo = LV(1);  hi = LV(end);  if hi <= lo, hi = lo + 1; end
    yv = linspace(lo, hi, 256)';
    ii = 1 + round(255 * (yv - lo) / (hi - lo));
    img = reshape(HM(ii,:), [256 1 3]);
    axC = axes(fh, 'Position',[box_all(1) + box_all(3) - CBW + 0.012, box_all(2) + 0.06*box_all(4), ...
        0.014, 0.88*box_all(4)], 'Tag','memr_lvl_cbar');
    image(axC, 0.5, [lo hi], img);
    tk = LV;  if numel(tk) > 8, tk = tk(1:2:end); if tk(end) ~= LV(end), tk(end+1) = LV(end); end, end
    set(axC, 'YDir','normal', 'XLim',[0 1], 'XTick',[], 'YAxisLocation','right', 'YLim',[lo hi], 'YTick',tk, ...
        'YTickLabel',compose_g(tk), 'FontSize',11, 'Box','on', 'TickLength',[0 0], ...
        'XColor',INK, 'YColor',INK, 'Layer','top');
    ylabel(axC, 'Elicitor Level (dB FPL)', 'FontWeight','bold', 'FontSize',12);
end
end


% ══════════════════════════════════════════════════════════════════════════
%  Helpers
% ══════════════════════════════════════════════════════════════════════════
function style_axes(ax, p, xlab)
INK = [0.15 0.15 0.15];
set(ax, 'FontSize',14, 'Box','off', 'XColor',INK, 'YColor',INK);
grid(ax, 'on');
if p.logy, set(ax, 'YScale','log'); end
if ~isempty(xlab), xlabel(ax, xlab, 'FontWeight','bold'); end
ylabel(ax, p.ylab, 'FontWeight','bold');
title(ax, p.title, 'FontSize',14, 'FontWeight','bold');
end


function ref_lines(ax, p)
xl = xlim(ax);
if p.zero, plot(ax, xl, [0 0], 'k--', 'LineWidth',1.2, 'HandleVisibility','off'); end
if isfinite(p.crit), plot(ax, xl, [p.crit p.crit], 'k:', 'LineWidth',1.5, 'HandleVisibility','off'); end
end


function fit_y(ax, p)
% y-limits from lines, error bars and subject points (+ 12 % padding)
yy = [];
for h = findall(ax, 'Type','errorbar')'
    yd = get(h, 'YData');  dn = get(h, 'YNegativeDelta');  up = get(h, 'YPositiveDelta');
    v = [yd(:) - dn(:); yd(:) + up(:)];
    yy = [yy; v(isfinite(v))]; %#ok<AGROW>
end
for h = [findall(ax, 'Type','line'); findall(ax, 'Type','scatter'); findall(ax, 'Type','patch')]'
    v = double(get(h, 'YData'));  v = v(:);  yy = [yy; v(isfinite(v))]; %#ok<AGROW>
end
if p.zero, yy = [yy; 0]; end
if isfinite(p.crit), yy = [yy; p.crit]; end
if isempty(yy), return; end
if p.logy
    yy = yy(yy > 0);  if isempty(yy), return; end
    lo = min(yy);  hi = max(yy);
    ylim(ax, [lo / 1.4, hi * 1.4]);
    return
end
lo = min(yy);  hi = max(yy);  r = max(hi - lo, 0.05*max(abs([lo hi 1])));
ylim(ax, [lo - 0.12*r, hi + 0.12*r]);
end


function yl = fit_range(R)
v = double(R(:));  v = v(isfinite(v));
if isempty(v), yl = [-1 1]; return; end
lo = min(v);  hi = max(v);  r = max(hi - lo, 0.02*max(abs([lo hi 1e-3])));
if r <= 0, r = 1; end
yl = [lo - 0.08*r, hi + 0.08*r];
end


function no_data(ax, p)
style_axes(ax, p, '');
text(ax, 0.5, 0.5, 'No Data', 'Units','normalized', 'HorizontalAlignment','center', ...
    'Color',[0.5 0.5 0.5], 'FontSize',12);
end


function s = subj_name(subjects, k)
s = sprintf('Subject %d', k);
if iscell(subjects) && numel(subjects) >= k, s = char(subjects{k}); end
end


function c = compose_g(v)
c = arrayfun(@(x) sprintf('%g', x), v, 'UniformOutput', false);
end


function s = last_part(p)
q = strsplit(char(p), {'/','\'});
s = q{end};
end


function out = ternary(c, a, b)
if c, out = a; else, out = b; end
end


function average = summarize(A)
% Saved group data: per condition, every series / value with its mean, SD
% and n (without the excluded pairs) and the per-subject values.
average = struct('type',A.type, 'subjects',{A.subjects}, 'relative',A.relative, ...
    'reference',A.ref_name, 'conditions',{{A.cols.name}});
for j = 1:numel(A.cols)
    C = A.cols(j);
    out = struct('name',C.name, 'n',C.n);
    for k = fieldnames(C.lev)'
        L = C.lev.(k{1});  st = mx_data('stats', L.M);
        out.(k{1}) = struct('elicitor',L.x, 'mean',st.mean, 'sd',st.sd, 'n',st.n, 'subjects',L.M);
    end
    for k = fieldnames(C.sca)'
        S = C.sca.(k{1});  st = mx_data('stats', S.M);
        out.(k{1}) = struct('mean',st.mean, 'sd',st.sd, 'n',st.n, 'subjects',S.M);
    end
    for k = fieldnames(C.cur)'
        Cv = C.cur.(k{1});  st = mx_data('stats', Cv.M);
        out.(k{1}) = struct('x',Cv.x, 'mean',st.mean, 'sd',st.sd, 'n',st.n, 'subjects',Cv.M);
    end
    if ~isempty(C.fam.x)
        out.family = struct('x',C.fam.x, 'elicitor',C.fam.elic, 'subjects',C.fam.M);
    end
    average.cols(j) = out;
end
end


function T = mx_rows(subj, cond, type, mx)
%MX_ROWS  Tidy CSV rows of one recording for one exploratory MEMR view:
%   every series vs elicitor level (Q.lev) and every scalar (Q.sca) of
%   mx_data('quant') — the values the figure plots (curves / families stay
%   in the .mat). Measure = MEMR_<view>; Metric = the PascalCase name of the
%   mx_data key (apat_data_dictionary 'mx', e.g. V → VectorChange).
T = table();
Q = mx_data('quant', type, mx);
if ~isstruct(Q) || ~Q.ok, return; end
E = [];  M = {};  V = [];
for k = fieldnames(Q.lev)'
    v = double(Q.lev.(k{1})(:));  n = min(numel(v), numel(Q.elic));
    E = [E; double(Q.elic(1:n)')];  M = [M; repmat(k, n, 1)];  V = [V; v(1:n)]; %#ok<AGROW>
end
for k = fieldnames(Q.sca)'
    v = double(Q.sca.(k{1}));  if isempty(v), v = NaN; end
    E = [E; NaN];  M = [M; k];  V = [V; v(1)]; %#ok<AGROW>
end
if isempty(V), return; end
[nm, un] = cellfun(@(k) apat_data_dictionary('mx', k), M, 'UniformOutput', false);
T = apat_csv('mk', struct('Measure',['MEMR_' type], 'Subject',subj, 'Condition',cond), ...
    struct('Elicitor_dBFPL',E, 'Metric',{nm}, 'Value',V, 'Units',{un}));
end
