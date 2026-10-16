function out = res_style(action, varargin)
%RES_STYLE  Results-tab theme (Oct 16 restyle): one place for the colours
%   and the small styling helpers of the Results bar, the Plot Settings
%   strips and the status strip. Silent: never throws.
%
%   T = res_style('theme', app)        colour struct (see below)
%   res_style('bar', app, btn, on)     Results-bar button: on = subtle yellow,
%                                      dark bold text; off = light grey (clr_btn)
%   res_style('bar_sync', app)         View + measure buttons, gold underline
%                                      under the measure on screen, group captions
%   res_style('underline', app)        re-place the gold underline only (bar_fit)
%   res_style('onoff', b)              strip ON / OFF toggle: ON green, OFF red
%   res_style('seg', b, on)            segmented / level choice: on = subtle yellow
%   res_style('icon', btn, idx)        small measure icon on a bar button (if a
%                                      small PNG exists in @APAT_app/icons)
%   s = res_style('marker', code)      MATLAB marker code -> symbol (● ■ ▲ ▼ ◆ ✕ + …)
%   res_style('status', app)           refresh the status strip under the plots
%
%   Subtle yellow = [218 170 0]/255 blended over the background it sits on
%   (24 % over the bar, 30 % over the Plot Settings body), precomputed.
out = [];
try
    switch action
        case 'theme',     out = theme(varargin{:});
        case 'bar',       style_bar(varargin{:});
        case 'bar_sync',  bar_sync(varargin{:});
        case 'underline', underline(varargin{:});
        case 'onoff',     style_onoff(varargin{:});
        case 'seg',       style_seg(varargin{:});
        case 'icon',      set_icon(varargin{:});
        case 'marker',    out = marker_char(varargin{:});
        case 'status',    status(varargin{:});
    end
catch
end
end


% ── colours ──────────────────────────────────────────────────────────────
function T = theme(app)
bar = [0.93 0.91 0.87];  btn = [0.86 0.84 0.79];  ink = [0.08 0.08 0.08];
try, bar = app.clr_panel; catch, end
try, btn = app.clr_btn;   catch, end
Y = [218 170 0] / 255;
T.ink       = ink;
T.bar       = bar;
T.btn       = btn;
T.sel       = 0.24*Y + 0.76*bar;              % selected bar button / tracking chip
T.gold      = [0.85 0.67 0];                  % strong gold (Plot Settings button, underline)
T.gold_line = [0.81 0.73 0.57];               % thin gold borders / dividers
T.gold_dk   = [0.56 0.44 0.24];               % caption of the group on screen, status accents
T.cap       = [0.44 0.42 0.38];               % muted captions
T.ps_body   = [0.94 0.92 0.89];               % Plot Settings body
T.seg_on    = 0.30*Y + 0.70*T.ps_body;        % segmented choice selected
T.seg_off   = [0.97 0.96 0.93];
T.on        = [0.18 0.49 0.31];               % ON toggle
T.off       = [0.69 0.23 0.18];               % OFF toggle
T.cream     = [0.97 0.96 0.93];
T.status_bg = [0.965 0.933 0.827];
T.status_fg = [0.23 0.21 0.18];
T.mono      = 'Courier New';                  % monospaced captions / status (a real font
try                                           % name: uifigures are web-rendered, so the
    if ispc,      T.mono = 'Consolas';        % logical 'Monospaced' is not used)
    elseif ismac, T.mono = 'Menlo';
    else,         T.mono = 'DejaVu Sans Mono';
    end
catch
end
end


% ── Results bar ──────────────────────────────────────────────────────────
function style_bar(app, b, on)
if isempty(b) || ~isvalid(b), return; end
T = theme(app);
if on
    b.BackgroundColor = T.sel;  b.FontColor = T.ink;  b.FontWeight = 'bold';
else
    b.BackgroundColor = T.btn;  b.FontColor = T.ink;  b.FontWeight = 'bold';
end
end

function bar_sync(app)
if ~isfield(app.res, 'mode'), return; end
try
    style_bar(app, app.FigAvgBtn, app.res.mode == 2);
    style_bar(app, app.FigIndBtn, app.res.mode == 1);
catch
end
m = app.res.meas_idx;
B = app.res.btns;
for k = 1:numel(B)
    try
        if ~isvalid(B(k)), continue; end
        on = (k == m) || (k == 8 && m >= 8);
        style_bar(app, B(k), on);
    catch
    end
end
% caption of the group on screen in dark gold, the others muted
T = theme(app);
if isfield(app.res, 'grp_caps')
    g = 1 + (m >= 3) + (m >= 5) + (m >= 8);      % ABR | EFR | OAE | MEMR
    C = app.res.grp_caps;
    for i = 1:numel(C)
        try
            if isvalid(C(i)), C(i).FontColor = ternary_c(i == g, T.gold_dk, T.cap); end
        catch
        end
    end
end
underline(app);
end

function underline(app)
%UNDERLINE  Gold bar along the bottom edge of the measure button on screen.
if ~isfield(app.res, 'meas_line') || isempty(app.res.meas_line) || ~isvalid(app.res.meas_line), return; end
L = app.res.meas_line;
m = app.res.meas_idx;  if m >= 8, m = 8; end
if m < 1 || m > numel(app.res.btns) || ~isvalid(app.res.btns(m)), L.Visible = 'off'; return; end
b = app.res.btns(m);
p = double(b.Position);
h = 3;
L.Position = [p(1)+3, p(2)+2, max(4, p(3)-6), h];
for f = {'apat_p0','apat_bar0'}
    if isappdata(L, f{1}), rmappdata(L, f{1}); end      % owned here, not by relayout / bar_fit
end
L.Visible = 'on';
try, uistack(L, 'top'); catch, end
end


% ── strip toggles ────────────────────────────────────────────────────────
function style_onoff(b)
if isempty(b) || ~isvalid(b), return; end
T = theme([]);
if b.Value
    b.Text = 'ON';   b.BackgroundColor = T.on;
else
    b.Text = 'OFF';  b.BackgroundColor = T.off;
end
b.FontColor = [1 1 1];  b.FontWeight = 'bold';
end

function style_seg(b, on)
if isempty(b) || ~isvalid(b), return; end
T = theme([]);
if on
    b.BackgroundColor = T.seg_on;   b.FontColor = T.ink;  b.FontWeight = 'bold';
else
    b.BackgroundColor = T.seg_off;  b.FontColor = [0.40 0.38 0.35];  b.FontWeight = 'normal';
end
end


% ── icons ────────────────────────────────────────────────────────────────
function set_icon(btn, idx)
%SET_ICON  Small icon left of the text: icons/icon_<name>_sm.png, else
%   icons/icon_<name>.png when it is small enough (≤ 34 px high) for the bar.
if isempty(btn) || ~isvalid(btn) || ~isprop(btn, 'Icon'), return; end
names = {'abr_thresholds','abr_peaks','efr_dam','efr_ram','oae_dpoae','oae_sfoae','oae_teoae', ...
         'memr_art','memr_vector','memr_growth','memr_kinetics','memr_spectral', ...
         'memr_absorbance','memr_probe','memr_quality'};
f = '';
if idx >= 1 && idx <= numel(names)
    d = fullfile(fileparts(fileparts(mfilename('fullpath'))), 'icons');
    c1 = fullfile(d, ['icon_' names{idx} '_sm.png']);
    c2 = fullfile(d, ['icon_' names{idx} '.png']);
    if exist(c1, 'file')
        f = c1;
    elseif exist(c2, 'file')
        try
            I = imfinfo(c2);
            if I(1).Height <= 34 && I(1).Width <= 60, f = c2; end
        catch
        end
    end
end
try
    if isempty(f)
        btn.Icon = '';
    else
        btn.Icon = f;  btn.IconAlignment = 'left';
    end
catch
end
end


% ── condition markers ────────────────────────────────────────────────────
function s = marker_char(code)
s = char(9679);                                  % ● (default)
try
    code = lower(strtrim(char(code)));
    switch code
        case {'o','circle'},              s = char(9679);   % ●
        case {'s','square'},              s = char(9632);   % ■
        case {'^','triangle'},            s = char(9650);   % ▲
        case {'v'},                       s = char(9660);   % ▼
        case {'>'},                       s = char(9654);   % ▶
        case {'<'},                       s = char(9664);   % ◀
        case {'d','diamond'},             s = char(9670);   % ◆
        case {'p','pentagram'},           s = char(9733);   % ★
        case {'h','hexagram'},            s = char(10038);  % ✶
        case {'x'},                       s = char(10005);  % ✕
        case {'+'},                       s = '+';
        case {'*'},                       s = char(10033);  % ✱
        case {'.'},                       s = char(8226);   % •
        case {'|'},                       s = '|';
        case {'_'},                       s = '_';
    end
catch
end
end


% ── status strip ─────────────────────────────────────────────────────────
function status(app)
%STATUS  "OAE › DPOAE › AVERAGE   GROUP NOISE   12 SUBJECTS · 4 CONDITIONS
%   EXCLUDED: Q438 (D7)   SAVED 01:42" for the view on screen.
if ~isfield(app.res, 'status_lbl') || isempty(app.res.status_lbl) || ~isvalid(app.res.status_lbl), return; end
T = theme(app);
L = APAT_app.measure_tab_labels();
m = app.res.meas_idx;  lbl = L{m};
switch lbl
    case {'DPOAE','SFOAE','TEOAE'}, path = {'OAE', lbl};
    case 'MEMR',                    path = {'MEMR', 'ART'};
    otherwise
        [a, r] = strtok(lbl);  path = {a, strtrim(r)};
end
if app.res.mode == 2
    path{end+1} = 'Average';
else
    path{end+1} = 'Individual';
    try
        s = app.FigSubjDropdown.Value;
        if ~isempty(s) && ~strcmp(s, '-'), path{end+1} = s; end
    catch
    end
end
segs = {};  gold = false(0);
segs{end+1} = strjoin(path, [' ' char(8250) ' ']);  gold(end+1) = false;
% Experiments of the run: "EXPERIMENT: NOISE + BLAST", the one on screen
% first and in gold (others plain) — private/res_exp.m
g = '';
try, if isfield(app.res, 'run_sheet'), g = char(app.res.run_sheet); end, catch, end
ex = {};  try, ex = res_exp(app, 'list'); catch, end
if ischar(g) && ~isempty(g), ex = [{g}, ex(~strcmp(ex, g))]; end
% several Experiments drawn on the same plots (exp_overlay): list those
ovl = {};  try, ovl = exp_overlay(app, 'shown'); catch, end
is_ovl = numel(ovl) > 1;
if is_ovl, ex = ovl; end
exp_seg = 0;
if ~isempty(ex)
    segs{end+1} = ['Experiment: ' strjoin(ex, ' + ')];  gold(end+1) = false;
    if is_ovl, segs{end} = [segs{end} ' (overlay)']; end
    exp_seg = numel(segs);
end
% subjects · conditions
n_s = 0;  n_c = 0;
try, n_s = numel(app.res.subj_data{m}.names); catch, end
try
    p = app.res.run_conds.paths;  if ischar(p), p = {p}; end
    n_c = numel(p);
catch
end
cnt = {};
if n_s > 0, cnt{end+1} = sprintf('%d %s', n_s, plural(n_s, 'subject')); end
if n_c > 0, cnt{end+1} = sprintf('%d %s', n_c, plural(n_c, 'condition')); end
if ~isempty(cnt), segs{end+1} = strjoin(cnt, [' ' char(183) ' ']);  gold(end+1) = false; end
% exclusions of this analysis
try
    P = exclusions(app, 'relevant', lbl, m);      % only pairs of the run on screen
    if ~isempty(P)
        e = cell(1, size(P,1));
        for i = 1:size(P,1)
            c = char(P{i,2});  if strcmp(c, '*'), c = 'All'; end
            c = regexprep(c, '^.*[/\\]', '');
            e{i} = sprintf('%s (%s)', char(P{i,1}), c);
        end
        if numel(e) > 3, e = [e(1:3) {sprintf('+%d', numel(e) - 3)}]; end
        segs{end+1} = ['Excluded: ' strjoin(e, ', ')];  gold(end+1) = true;
    end
catch
end
if ~has_plots(app), segs{end+1} = 'No results yet';  gold(end+1) = false; end
segs = cellfun(@upper, segs, 'UniformOutput', false);
% last save (Save Image / Save As New), right-aligned
sv = '';
try
    if isfield(app.res, 'last_save') && ~isempty(app.res.last_save)
        sv = ['SAVED ' datestr(app.res.last_save, 'HH:MM')]; %#ok<DATST>
    end
catch
end
H = app.res.status_lbl;
txt = strjoin(segs, ['   ' char(9474) '   ']);
if isprop(H, 'Interpreter')
    hex = @(c) sprintf('#%02X%02X%02X', round(255*c));
    gsp = @(t) sprintf('<span style="color:%s">%s</span>', hex(T.gold_dk), t);
    parts = cell(size(segs));
    for i = 1:numel(segs)
        t = esc(segs{i});
        if i == exp_seg                            % Experiment on screen in gold, the others plain
            u = cellfun(@(e) esc(upper(e)), ex, 'UniformOutput', false);
            u{1} = gsp(u{1});
            t = ['EXPERIMENT: ' strjoin(u, ' + ')];
            if is_ovl, t = [t ' (OVERLAY)']; end
        elseif gold(i)
            t = gsp(t);
        end
        parts{i} = t;
    end
    % items apart: "   │   " (≈ 45 px at 11 px mono), separator in the muted caption grey
    sep = sprintf('&nbsp;&nbsp;&nbsp;<span style="color:%s;font-weight:normal">%s</span>&nbsp;&nbsp;&nbsp;', ...
        hex(T.cap), char(9474));
    html = sprintf(['<span style="font-family:''%s'',monospace;font-weight:bold;' ...
        'font-size:11px;color:%s;white-space:nowrap">%s</span>'], T.mono, hex(T.status_fg), ...
        strjoin(parts, sep));
    try
        H.Interpreter = 'html';  H.Text = html;
    catch
        H.Text = txt;
    end
else
    H.Text = txt;
end
try, H.Tooltip = txt; catch, end
if isfield(app.res, 'status_save') && isvalid(app.res.status_save)
    app.res.status_save.Text = sv;
end
end

function tf = has_plots(app)
tf = false;
try
    m = app.res.meas_idx;
    if app.res.mode == 1
        tf = ~isempty(app.res.subj_data{m}.names);
    else
        tf = ~isempty(findall(app.res.panels{2,m}, 'Type','axes'));
    end
catch
end
end

function s = plural(n, w)
if n == 1, s = w; else, s = [w 's']; end
end

function s = esc(s)
s = strrep(s, '&', '&amp;');  s = strrep(s, '<', '&lt;');  s = strrep(s, '>', '&gt;');
end

function c = ternary_c(t, a, b)
if t, c = a; else, c = b; end
end
