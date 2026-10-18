function chinroster_ops(app, action, varargin)
%CHINROSTER_OPS  Chinroster file scanning, loading, and subject/condition UI.
%
%   chinroster_ops(app, 'scan', preferred_name) — scan Analysis/ for .xlsx files
%   chinroster_ops(app, 'load')                  — load selected roster, refresh the
%                                                  Experiment buttons (sheet_sel 'list')
%   chinroster_ops(app, 'refresh_from', filepath)— re-parse the sheet on screen
%                                                  (app.state.sheet), then sheet_sel 'restore'
%   chinroster_ops(app, 'set_subj', subjs, checked) — rebuild subject checkbox grid
%   chinroster_ops(app, 'refresh_conds')         — rebuild condition rows (chip, colour, marker)
%   chinroster_ops(app, 'style_open', ci)        — colour / marker popup of condition ci
%   chinroster_ops(app, 'style_pick', what, val) — popup choice ('color' | 'custom' |
%                                                  'marker' | 'reset' | 'close')
%   app.state.cond_colors (n×3) / app.state.cond_markers (1×n cellstr of MATLAB
%   marker codes) follow the roster condition order; saved per condition path
%   in launcher_last_settings.mat (settings_ops 'save_colors'), sent to the
%   analysis as cfg.cond_colors / cfg.cond_markers (RunButtonPushed>run_one).

switch action
    case 'scan',          do_scan(app, varargin{1});
    case 'load',          do_load(app);
    case 'refresh_from',  do_refresh_from(app, varargin{1});
    case 'set_subj',      do_set_subj(app, varargin{1}, varargin{2});
    case 'refresh_conds', do_refresh_conds(app);
    case 'pick_color',    do_pick_color(app, varargin{1});
    case 'paint_swatches', do_paint_swatches(app);
    case 'style_open',    do_style_open(app, varargin{1});
    case 'style_pick',    do_style_pick(app, varargin{1}, varargin{2});
end
end


% ── Scan Analysis/ for roster files ──────────────────────────────────

function do_scan(app, preferred_name)
rootdir = strtrim(app.RootDirField.Value);
if isempty(rootdir), return; end
analysis_dir = fullfile(rootdir,'Analysis');
if ~exist(analysis_dir,'dir')
    app.RosterDropdown.Items = {'(Analysis folder not found)'};
    app.RosterDropdown.Value = '(Analysis folder not found)'; return
end
names = apat_paths(analysis_dir, 'rosters');    % Analysis/Roster (loose Excel files moved in)
if isempty(names)
    app.RosterDropdown.Items = {'(no Excel files found)'};
    app.RosterDropdown.Value = '(no Excel files found)'; return
end
app.RosterDropdown.Items = names;
if ~isempty(preferred_name) && any(strcmp(names, preferred_name))
    app.RosterDropdown.Value = preferred_name;
else
    app.RosterDropdown.Value = names{1};
end
do_load(app);
end


% ── Load selected roster → populate sheets ────────────────────────────

function do_load(app)
rootdir  = strtrim(app.RootDirField.Value);
if isempty(rootdir), return; end
chinfile = app.RosterDropdown.Value;
if isempty(chinfile) || chinfile(1) == '(', return; end
filepath = apat_paths(fullfile(rootdir,'Analysis'), 'roster', chinfile);
if ~exist(filepath,'file')
    sheet_sel(app, 'message', '(file not found)');
    do_set_subj(app, {}, []);
    do_refresh_conds(app);
    return
end
try
    sheets = cellstr(sheetnames(filepath));
catch
    sheet_sel(app, 'message', '(error reading file)'); return
end
% Experiment buttons (several sheets can be selected); the sheet on screen
% drives Subjects / Conditions (private/sheet_sel.m)
app.state.sheet = sheet_sel(app, 'list', sheets, filepath);
app.state.sheet_chips = '';                      % chips are rebuilt below
do_refresh_from(app, filepath);
end


% ── Parse chinroster and refresh subjects + conditions ─────────────────

function do_refresh_from(app, filepath)
analysis_status(app, 'invalidate');             % chip colours read the results again
[subjects, app.state.conds_all, app.state.cond_labels] = ...
    APAT_app.read_chinroster_sheet(filepath, app.state.sheet);
do_set_subj(app, subjects, true(numel(subjects),1));
do_refresh_conds(app);
settings_ops(app, 'load');
sheet_sel(app, 'restore');                       % this sheet's own chip selection
end


% ── Rebuild subject chip grid ─────────────────────────────────────────

function do_set_subj(app, subjs, checked)
valid = app.h_subj_checks(isvalid(app.h_subj_checks));
if ~isempty(valid), delete(valid); end
app.h_subj_checks = gobjects(0);
app.subj_ids      = {};
if isempty(subjs), update_summary(app); return; end
subjs   = subjs(:);
checked = checked(:);
n       = numel(subjs);
app.subj_ids = subjs;

% Toggle chips in the Subjects section's scrollable grid (uigridlayout,
% createComponents); cells set by private/setup_chips.m (columns from the
% section width, rows 28 px). Styling: update_summary.
G = getappdata(app.SubjectsPanel, 'apat_chip_grid');
G.ColumnWidth = {'1x'};  G.RowHeight = repmat({28}, 1, n);   % one cell per chip while they are made
app.h_subj_checks = gobjects(1, n);
for ii = 1:n
    app.h_subj_checks(ii) = uibutton(G,'state', ...
        'Text',subjs{ii},'Value',logical(checked(ii)), ...
        'FontSize',14,'FontWeight','bold', ...
        'ValueChangedFcn',@(~,~) update_summary(app));
end
setup_chips(app, 'subj', true);
update_summary(app);
end


% ── Rebuild condition rows ────────────────────────────────────────────

function do_refresh_conds(app)
% One row per condition: include chip | colour swatch | marker button
% (Oct 16 2026 design). Swatch / marker open the condition's style popup
% (colour palette + Custom… colour picker, marker), see do_style_open.
valid = app.h_cond_checks(isvalid(app.h_cond_checks));
if ~isempty(valid), delete(valid); end
app.h_cond_checks = gobjects(0);
vs = app.h_cond_swatches(isgraphics(app.h_cond_swatches));
if ~isempty(vs), delete(vs); end
app.h_cond_swatches = gobjects(0);
vm = app.h_cond_markers(isgraphics(app.h_cond_markers));
if ~isempty(vm), delete(vm); end
app.h_cond_markers = gobjects(0);
style_hide(app);
labels = app.state.cond_labels;
% Plot colour / marker per condition: defaults (roster order); saved
% choices are restored afterwards by settings_ops('load')
pal = default_plot_colors();
n = numel(labels);
app.state.cond_colors  = pal(mod((1:n)-1, size(pal,1)) + 1, :);
app.state.cond_markers = default_markers(n);
if n == 0, update_summary(app); return; end

% rows in the Conditions section's scrollable grid (createComponents):
% chip '1x' | swatch 26 | marker 26, cells set by private/setup_chips.m
G = getappdata(app.ConditionsPanel, 'apat_chip_grid');
G.RowHeight = repmat({26}, 1, n);  G.ColumnWidth = {'1x', 26, 26};
app.h_cond_checks   = gobjects(1, n);
app.h_cond_swatches = gobjects(1, n);
app.h_cond_markers  = gobjects(1, n);
for ci = 1:n
    txt = labels{ci};
    app.h_cond_checks(ci) = uibutton(G,'state', ...
        'Text',txt,'Value',true,'HorizontalAlignment','left', ...
        'FontSize',13,'FontWeight','bold', ...
        'Tooltip',sprintf('Include / exclude %s', txt), ...
        'ValueChangedFcn',@(~,~) update_summary(app));
    app.h_cond_checks(ci).Layout.Row = ci;  app.h_cond_checks(ci).Layout.Column = 1;
    app.h_cond_swatches(ci) = uibutton(G,'push','Text','', ...
        'BackgroundColor',app.state.cond_colors(ci,:), ...
        'Tooltip',sprintf('Plot colour of %s — click to change', txt), ...
        'ButtonPushedFcn',@(~,~) chinroster_ops(app,'style_open',ci));
    app.h_cond_swatches(ci).Layout.Row = ci;  app.h_cond_swatches(ci).Layout.Column = 2;
    app.h_cond_markers(ci) = uibutton(G,'push', ...
        'Text',marker_glyph(app.state.cond_markers{ci}), 'FontSize',13, ...
        'BackgroundColor',[1 1 1], 'FontColor',app.state.cond_colors(ci,:), ...
        'Tooltip',sprintf('Plot marker of %s — click to change', txt), ...
        'ButtonPushedFcn',@(~,~) chinroster_ops(app,'style_open',ci));
    app.h_cond_markers(ci).Layout.Row = ci;  app.h_cond_markers(ci).Layout.Column = 3;
end
setup_chips(app, 'conds');
update_summary(app);
end


% ── Condition plot colours / markers ───────────────────────────────────

function do_pick_color(app, ci)
%DO_PICK_COLOR  Colour picker (uisetcolor) for condition ci; saved to the
%   project settings (launcher_last_settings.mat).
if ci > size(app.state.cond_colors,1), return; end
lbl = app.state.cond_labels{ci};
c = uisetcolor(app.state.cond_colors(ci,:), sprintf('Plot colour — %s', lbl));
figure(app.UIFigure);                            % bring the app back to the front
if numel(c) ~= 3, return; end                    % cancelled
app.state.cond_colors(ci,:) = c;
do_paint_swatches(app);
settings_ops(app, 'save_colors');
end


function do_paint_swatches(app)
% swatches, marker buttons (glyph in the condition colour) and the popup
for ci = 1:min(numel(app.h_cond_swatches), size(app.state.cond_colors,1))
    if isgraphics(app.h_cond_swatches(ci))
        app.h_cond_swatches(ci).BackgroundColor = app.state.cond_colors(ci,:);
    end
end
if ~isfield(app.state,'cond_markers'), app.state.cond_markers = {}; end
nm = numel(app.state.cond_markers);
if nm < size(app.state.cond_colors,1)
    d = default_markers(size(app.state.cond_colors,1));
    app.state.cond_markers(nm+1:numel(d)) = d(nm+1:end);
end
for ci = 1:min(numel(app.h_cond_markers), size(app.state.cond_colors,1))
    if isgraphics(app.h_cond_markers(ci))
        app.h_cond_markers(ci).Text      = marker_glyph(app.state.cond_markers{ci});
        app.h_cond_markers(ci).FontColor = app.state.cond_colors(ci,:);
    end
end
style_refresh(app);
update_summary(app);                             % (fades the rows of excluded conditions)
end


function do_style_open(app, ci)
%DO_STYLE_OPEN  Small "<COND> STYLE" popup next to condition ci's row:
%   colour palette (+ Custom… = uisetcolor), marker (o s ^ v d x +), Reset.
if ci > numel(app.state.cond_labels), return; end
P = style_build(app);
if isempty(P), return; end
P.panel.UserData = ci;
P.title.Text = sprintf('%s STYLE', upper(app.state.cond_labels{ci}));
% place it right of the row, kept inside the tab. The popup is a child of
% the Setup tab (not of a grid); the row's place in tab coordinates = its
% Position + the content origins of its containers up to the tab.
try
    pw = P.panel.Position(3);  ph = P.panel.Position(4);
    tp = app.SetupTab.Position;  tw = tp(3);  th = tp(4);
    mk = app.h_cond_markers(ci);
    o  = origin_in(mk.Parent, app.SetupTab);
    rb = mk.Position;
    try                                          % scrolled grid: viewport offset
        vl = mk.Parent.ScrollableViewportLocation;
        rb(2) = rb(2) - (vl(2) - 1);
    catch
    end
    x = o(1) + rb(1) + rb(3) + 10;
    y = o(2) + rb(2) + rb(4) - ph + 30;
    if ~all(isfinite([x y])), error('apat:pos', 'no position'); end
    x = max(6, min(x, tw - pw - 6));
    y = max(4, min(y, th - ph - 6));
    P.panel.Position = [x y pw ph];
catch
    try                                          % fallback: centre of the tab
        tp = app.SetupTab.Position;
        P.panel.Position = [max(6, (tp(3)-P.panel.Position(3))/2), ...
            max(4, (tp(4)-P.panel.Position(4))/2), P.panel.Position(3:4)];
    catch
    end
end
style_refresh(app);
P.panel.Visible = 'on';
uistack(P.panel, 'top');
end


function do_style_pick(app, what, val)
%DO_STYLE_PICK  Popup choice: 'color' rgb | 'custom' | 'marker' code |
%   'reset' | 'close'. Saved right away (settings_ops 'save_colors').
P = app.h_cond_style;
if ~isstruct(P) || ~isfield(P,'panel') || ~isgraphics(P.panel), return; end
ci = P.panel.UserData;
if strcmp(what, 'close'), style_hide(app); return; end
if isempty(ci) || ci > size(app.state.cond_colors,1), return; end
switch what
    case 'color',  app.state.cond_colors(ci,:) = val;
    case 'custom', do_pick_color(app, ci);  return;
    case 'marker', app.state.cond_markers{ci} = val;
    case 'reset'
        pal = default_plot_colors();  d = default_markers(ci);
        app.state.cond_colors(ci,:) = pal(mod(ci-1, size(pal,1)) + 1, :);
        app.state.cond_markers{ci} = d{ci};
end
do_paint_swatches(app);
settings_ops(app, 'save_colors');
end


function P = style_build(app)
% build the popup once (parent: Setup tab); handles in app.h_cond_style
P = app.h_cond_style;
if isstruct(P) && isfield(P,'panel') && isgraphics(P.panel), return; end
P = struct();
W = 250;  H = 214;
mono = 'monospaced';  try, mono = mono_font(); catch, end
P.panel = uipanel(app.SetupTab,'BorderType','line','BackgroundColor',app.clr_bg, ...
    'Position',[100 100 W H],'Visible','off');
if isprop(P.panel,'BorderColor'), P.panel.BorderColor = app.clr_black; end
try, P.panel.BorderWidth = 2; catch, end
iw = W - 4;  ih = H - 4;
strip = uipanel(P.panel,'BorderType','none','BackgroundColor',app.clr_black,'Position',[0 ih-26 iw 26]);
P.title = uilabel(strip,'Text','STYLE','FontName',mono,'FontSize',10,'FontWeight','bold', ...
    'FontColor',[0.855 0.667 0],'Position',[10 4 iw-50 18]);
uibutton(strip,'push','Text',char(10005),'FontSize',12,'FontColor',[0.97 0.96 0.93], ...
    'BackgroundColor',app.clr_black,'Position',[iw-30 2 26 22],'Tooltip','Close', ...
    'ButtonPushedFcn',@(~,~) chinroster_ops(app,'style_pick','close',[]));
y = ih - 26 - 8 - 16;
uilabel(P.panel,'Text','Colour','FontSize',12,'FontColor',app.clr_txt2,'Position',[10 y 80 16]);
pal = [20 20 20; 232 163 61; 47 165 143; 106 111 209; 192 80 77; ...
       142 111 62; 91 141 184; 176 95 168; 122 154 58; 140 140 140] / 255;
P.sw = gobjects(1, size(pal,1));
for k = 1:size(pal,1)
    r = floor((k-1)/5);  c = mod(k-1, 5);
    P.sw(k) = uibutton(P.panel,'push','Text','','BackgroundColor',pal(k,:), ...
        'UserData',pal(k,:),'Position',[10+c*30 y-4-24-r*30 24 24], ...
        'ButtonPushedFcn',@(src,~) chinroster_ops(app,'style_pick','color',src.UserData));
end
uibutton(P.panel,'push','Text','Custom…','FontSize',11,'BackgroundColor',app.clr_btn, ...
    'Position',[164 y-4-24 72 24],'Tooltip','Any colour (colour picker)', ...
    'ButtonPushedFcn',@(~,~) chinroster_ops(app,'style_pick','custom',[]));
y = y - 4 - 24 - 30 - 10 - 16;
uilabel(P.panel,'Text','Marker','FontSize',12,'FontColor',app.clr_txt2,'Position',[10 y 80 16]);
mk = {'o','s','^','v','d','x','+'};
P.mk = gobjects(1, numel(mk));
for k = 1:numel(mk)
    P.mk(k) = uibutton(P.panel,'push','Text',marker_glyph(mk{k}),'FontSize',14, ...
        'BackgroundColor',[1 1 1],'UserData',mk{k},'Position',[10+(k-1)*32 y-4-28 28 28], ...
        'ButtonPushedFcn',@(src,~) chinroster_ops(app,'style_pick','marker',src.UserData));
end
uipanel(P.panel,'BorderType','none','BackgroundColor',app.clr_gold,'Position',[10 40 iw-20 1]);
uibutton(P.panel,'push','Text','Reset','FontSize',11,'BackgroundColor',app.clr_btn, ...
    'Position',[iw-10-70 8 70 24],'Tooltip','Default colour and marker of this condition', ...
    'ButtonPushedFcn',@(~,~) chinroster_ops(app,'style_pick','reset',[]));
P.preview = uilabel(P.panel,'Text','','FontSize',13,'Position',[10 8 iw-100 24]);
app.h_cond_style = P;
end


function style_refresh(app)
% popup look for its condition: chosen colour ticked, chosen marker yellow
P = app.h_cond_style;
if ~isstruct(P) || ~isfield(P,'panel') || ~isgraphics(P.panel), return; end
ci = P.panel.UserData;
if isempty(ci) || ci > size(app.state.cond_colors,1) || ci > numel(app.state.cond_markers), return; end
rgb = app.state.cond_colors(ci,:);  mk = app.state.cond_markers{ci};
for k = 1:numel(P.sw)
    on = max(abs(P.sw(k).UserData - rgb)) < 0.01;
    P.sw(k).Text = '';
    if on, P.sw(k).Text = char(10003); P.sw(k).FontColor = ternary(mean(rgb) < 0.5, [1 1 1], [0 0 0]); end
end
for k = 1:numel(P.mk)
    on = strcmp(P.mk(k).UserData, mk);
    P.mk(k).FontColor = rgb;
    if on, P.mk(k).BackgroundColor = app.clr_sel; else, P.mk(k).BackgroundColor = [1 1 1]; end
end
P.preview.Text = sprintf('%s%s%s  Preview', char(9472), marker_glyph(mk), char(9472));
P.preview.FontColor = rgb;
end


function style_hide(app)
try
    P = app.h_cond_style;
    if isstruct(P) && isfield(P,'panel') && isgraphics(P.panel), P.panel.Visible = 'off'; end
catch
end
end


function o = origin_in(p, top)
%ORIGIN_IN  Content origin of container P in the coordinates of container
%   TOP (an ancestor): sum of the containers' inner offsets between them.
o = [0 0];
while ~isempty(p) && isgraphics(p) && ~isequal(p, top)
    if isprop(p, 'InnerPosition'), ip = p.InnerPosition; else, ip = p.Position; end
    o = o + ip(1:2) - 1;
    p = p.Parent;
end
end


function m = default_markers(n)
%DEFAULT_MARKERS  Marker per condition in roster order — the same order as
%   analysis_run's default shapes (v, square, diamond, ^, o, >, pentagram, *, x),
%   so plots look as before until a marker is changed.
d = {'v','s','d','^','o','>','p','*','x'};
m = d(mod((1:n)-1, numel(d)) + 1);
end


function g = marker_glyph(mk)
%MARKER_GLYPH  Symbol shown for a MATLAB marker code.
switch char(mk)
    case {'o','circle'},          g = char(9679);     % ●
    case {'s','square'},          g = char(9632);     % ■
    case {'^'},                   g = char(9650);     % ▲
    case {'v'},                   g = char(9660);     % ▼
    case {'d','diamond'},         g = char(9670);     % ◆
    case {'x'},                   g = char(10005);    % ✕
    case {'+'},                   g = '+';
    case {'>'},                   g = char(9654);     % ▶
    case {'<'},                   g = char(9664);     % ◀
    case {'p','pentagram'},       g = char(9733);     % ★
    case {'*'},                   g = '*';
    otherwise,                    g = char(mk);
end
end
