function out = sheet_sel(app, action, varargin)
%SHEET_SEL  Setup "Experiment" toggle buttons (one per chinroster sheet).
%   Several experiments (sheets) can be selected and run in one go
%   (RunButtonPushed loops over them). The sheet ON SCREEN (last clicked,
%   stronger yellow app.clr_sel2; app.state.sheet) is the one the Subjects /
%   Conditions sections and Data Status show. Each sheet keeps its own chip
%   selection while switching (app.state.sheet_store).
%
%   L   = sheet_sel(app, 'list')                sheets of the loaded roster
%   cur = sheet_sel(app, 'list', sheets, file)  roster (re)loaded: rebuild the
%                                               buttons, keep / seed the
%                                               selection; returns the sheet
%                                               to put on screen
%   sheet_sel(app, 'message', txt)              no sheets: grey hint instead
%   S   = sheet_sel(app, 'selected')            selected sheets (roster order)
%   s   = sheet_sel(app, 'on_screen')           sheet on screen ('' = none)
%   sheet_sel(app, 'set_on_screen', name [, refresh])  show that sheet
%                                               (refresh = false: name only,
%                                               before a roster load)
%   sheet_sel(app, 'toggle', name)              button click: not selected →
%                                               select + show; selected → show;
%                                               the one on screen → deselect
%                                               (one always stays selected)
%   sheet_sel(app, 'store')                     chips on screen → store
%   sheet_sel(app, 'restore')                   store → chips (chinroster_ops
%                                               'refresh_from' calls it)
%   R   = sheet_sel(app, 'run_set', name)       one sheet's run inputs: .sheet
%                                               .subjects .Chins2Run .conds_all
%                                               .cond_labels .Conds2Run
%                                               .cond_colors .cond_markers
%   n   = sheet_sel(app, 'counts', name)        [selected subjects, conditions]
%   s   = sheet_sel(app, 'saved')               struct for launcher_last_settings
%                                               (.file .sheets .on_screen .per)
%   sheet_sel(app, 'style')                     restyle the buttons
%
%   State: app.state.sheet (on screen), .sheet_list, .sheets_sel (cellstr),
%   .sheet_file (roster path), .sheet_chips (sheet the chips belong to),
%   .sheet_store.(makeValidName(sheet)) = struct name / subj_off / cond_off
%   (DEselected subject IDs / condition paths: new ones default to on),
%   .sheet_roster.(key) = cached roster (subjects / conds_all / cond_labels).
%   Buttons: app.h_sheet_btns in app.SheetPanel (createComponents).
out = [];
ensure(app);
switch action
    case 'list'
        if isempty(varargin), out = app.state.sheet_list; return; end
        out = do_list(app, varargin{1}, varargin{2});
    case 'message',   do_message(app, varargin{1});
    case 'selected',  out = selected(app);
    case 'on_screen', out = app.state.sheet;
    case 'set_on_screen'
        rf = true;  if numel(varargin) > 1, rf = logical(varargin{2}); end
        set_on_screen(app, char(varargin{1}), rf);
    case 'toggle',    do_toggle(app, char(varargin{1}));
    case 'store',     do_store(app);
    case 'restore',   do_restore(app);
    case 'run_set',   out = run_set(app, char(varargin{1}), true);
    case 'counts'
        R = run_set(app, char(varargin{1}), false);
        out = [numel(R.Chins2Run) numel(R.Conds2Run)];
    case 'saved'
        do_store(app);
        [~, fn, ex] = fileparts(app.state.sheet_file);
        out = struct('file',[fn ex], 'sheets',{selected(app)}, ...
            'on_screen',app.state.sheet, 'per',app.state.sheet_store);
    case 'style',     style(app);
end
end


% ── state ────────────────────────────────────────────────────────────────
function ensure(app)
d = struct('sheet','', 'sheet_list',{{}}, 'sheets_sel',{{}}, 'sheet_file','', ...
    'sheet_chips','', 'sheet_store',struct(), 'sheet_roster',struct());
f = fieldnames(d);
for i = 1:numel(f)
    if ~isfield(app.state, f{i}), app.state.(f{i}) = d.(f{i}); end
end
end


function k = key(name)
k = matlab.lang.makeValidName(char(name));
end


function S = selected(app)
L = app.state.sheet_list;
S = L(ismember(L, app.state.sheets_sel));
S = S(:)';
end


% ── roster loaded ────────────────────────────────────────────────────────
function cur = do_list(app, sheets, filepath)
sheets = cellstr(sheets);  sheets = sheets(:)';
do_store(app);                                   % chips on screen belong to sheet_chips
app.state.sheet_roster = struct();               % file may have been edited
if ~strcmp(app.state.sheet_file, filepath)       % another roster file: start over
    app.state.sheet_store = struct();
    app.state.sheets_sel  = {};
    sv = saved_settings(app, filepath);
    if ~isempty(sv)
        if isfield(sv,'per') && isstruct(sv.per), app.state.sheet_store = sv.per; end
        if isfield(sv,'sheets'), app.state.sheets_sel = cellstr(sv.sheets); end
        if ~any(strcmp(sheets, app.state.sheet)) && isfield(sv,'on_screen')
            app.state.sheet = char(sv.on_screen);
        end
    end
    app.state.sheet_file  = filepath;
    app.state.sheet_chips = '';
end
app.state.sheet_list = sheets;
cur = app.state.sheet;
if ~any(strcmp(sheets, cur))
    s0 = selected(app);
    if ~isempty(s0), cur = s0{1}; else, cur = sheets{1}; end
end
app.state.sheets_sel = union(intersect(app.state.sheets_sel, sheets), {cur});   % (old settings: just the one)
app.state.sheet = cur;
build(app);
end


function sv = saved_settings(app, filepath)
% sheet selection saved with the last run (same roster file only)
sv = [];
try
    root = strtrim(app.RootDirField.Value);
    f = fullfile(root, 'Analysis', 'launcher_last_settings.mat');
    if ~exist(f, 'file'), return; end
    t = load(f, 'last_settings');
    if ~isfield(t.last_settings, 'sheet_sel'), return; end
    s = t.last_settings.sheet_sel;
    [~, fn, ex] = fileparts(filepath);
    if isfield(s, 'file') && ~isempty(s.file) && ~strcmp(s.file, [fn ex]), return; end
    sv = s;
catch
    sv = [];
end
end


% ── buttons ──────────────────────────────────────────────────────────────
function clear_btns(app)
try
    h = app.h_sheet_btns;
    h = h(isgraphics(h));
    if ~isempty(h), delete(h); end
catch
end
try, delete(findall(app.SheetPanel, 'Tag', 'sheet_msg')); catch, end
app.h_sheet_btns = gobjects(0);
end


function do_message(app, txt)
clear_btns(app);
app.state.sheet_list = {};  app.state.sheets_sel = {};
try
    P = app.SheetPanel.Position;
    uilabel(app.SheetPanel, 'Text', txt, 'Tag', 'sheet_msg', 'FontSize', 13, ...
        'FontColor', app.clr_txt2, 'Position', [0 0 P(3) P(4)]);
catch
end
end


function build(app)
clear_btns(app);
L = app.state.sheet_list;  n = numel(L);
if n == 0, return; end
P = app.SheetPanel.Position;  W = P(3);  H = P(4);
gap = 6;  FS = 14;
tw = @(fs) cellfun(@(s) ceil(0.62*fs*numel(s)) + 26, L);   % bold text width estimate
w = max(56, tw(FS));
rows = 1;
if sum(w) + gap*(n-1) > W                        % shrink: smaller font, then narrower
    FS = 11;  w = max(44, tw(FS));
    avail = W - gap*(n-1);
    if sum(w) > avail
        if avail / n >= 44
            w = floor(w * avail / sum(w));
        else
            rows = 2;  FS = 9;                   % many sheets: two rows
        end
    end
end
if rows == 1
    x = [0 cumsum(w(1:end-1) + gap)];  y = zeros(1, n);  h = H * ones(1, n);
else
    per = ceil(n / 2);  hh = floor((H - 2) / 2);
    ww = floor((W - gap*(per-1)) / per);
    w = ww * ones(1, n);
    c = mod((1:n) - 1, per);  r = floor(((1:n) - 1) / per);
    x = c * (ww + gap);  y = (1 - r) * (hh + 2);  h = hh * ones(1, n);
end
me = @sheet_sel;                                 % handle now (callback runs from outside)
app.h_sheet_btns = gobjects(1, n);
for i = 1:n
    app.h_sheet_btns(i) = uibutton(app.SheetPanel, 'state', 'Text', L{i}, ...
        'Position', [x(i) y(i) w(i) h(i)], 'FontSize', FS, 'FontWeight', 'bold', ...
        'UserData', L{i}, ...
        'Tooltip', sprintf(['%s — click to add it to the run and show its subjects / ' ...
            'conditions; click the one on screen again to remove it from the run'], L{i}), ...
        'ValueChangedFcn', @(src,~) me(app, 'toggle', src.UserData));
end
style(app);
end


function style(app)
sel = selected(app);
% Subjects / Conditions headers name the experiment on screen ("Conditions · NOISE")
try
    for t = {'03','04'}
        h = findobj(app.UIFigure, 'Tag', ['apat_sec_title_' t{1}]);
        for k = 1:numel(h)
            txt = h(k).UserData;
            if ~isempty(app.state.sheet), txt = sprintf('%s %s %s', txt, char(183), app.state.sheet); end
            h(k).Text = txt;
            p = h(k).Position;  p(3) = ceil(numel(txt)*13*0.62) + 10;  h(k).Position = p;
            try, rmappdata(h(k), 'apat_p0'); catch, end
        end
    end
catch
end
for b = app.h_sheet_btns(:)'
    if ~isgraphics(b), continue; end
    on = any(strcmp(sel, b.UserData));
    b.Value = on;
    setup_style(app, 'chip', b, on);
    if on && strcmp(b.UserData, app.state.sheet)
        b.BackgroundColor = app.clr_sel2;
    end
end
end


% ── clicks / switching ───────────────────────────────────────────────────
function do_toggle(app, name)
sel = selected(app);
if ~any(strcmp(sel, name))
    app.state.sheets_sel = [sel {name}];
    set_on_screen(app, name, true);
elseif ~strcmp(name, app.state.sheet)
    set_on_screen(app, name, true);
elseif numel(sel) > 1                            % the one on screen: remove it
    i = find(strcmp(sel, name), 1);
    rest = sel;  rest(i) = [];
    app.state.sheets_sel = rest;
    set_on_screen(app, rest{min(i, numel(rest))}, true);
end
style(app);
update_summary(app);
end


function set_on_screen(app, name, refresh)
if ~refresh, app.state.sheet = name; return; end
do_store(app);
if ~any(strcmp(app.state.sheets_sel, name)), app.state.sheets_sel{end+1} = name; end
app.state.sheet = name;
style(app);
if strcmp(app.state.sheet_chips, name), return; end
if ~isempty(app.state.sheet_file) && exist(app.state.sheet_file, 'file')
    % the chips are rebuilt for the new sheet: until 'restore' they belong
    % to no sheet (else 'counts' / 'run_set' / 'store' of the previous sheet
    % would read — or save — the new sheet's chips under its name)
    app.state.sheet_chips = '';
    chinroster_ops(app, 'refresh_from', app.state.sheet_file);
end
end


% ── per-sheet chip selections ────────────────────────────────────────────
function do_store(app)
nm = app.state.sheet_chips;
if isempty(nm), return; end
on_s = arrayfun(@(c) isgraphics(c) && c.Value, app.h_subj_checks);
on_c = arrayfun(@(c) isgraphics(c) && c.Value, app.h_cond_checks);
ids = app.subj_ids(:)';  cp = app.state.conds_all(:)';
if numel(on_s) ~= numel(ids) || numel(on_c) ~= numel(cp), return; end
app.state.sheet_store.(key(nm)) = struct('name',nm, ...
    'subj_off',{ids(~on_s)}, 'cond_off',{cp(~on_c)});
end


function do_restore(app)
nm = app.state.sheet;
app.state.sheet_chips = nm;
if isempty(nm), return; end
k = key(nm);
app.state.sheet_roster.(k) = struct('subjects',{app.subj_ids(:)'}, ...
    'conds_all',{app.state.conds_all(:)'}, 'cond_labels',{app.state.cond_labels(:)'});
if isfield(app.state.sheet_store, k)
    st = app.state.sheet_store.(k);
    for i = 1:numel(app.h_subj_checks)
        if isgraphics(app.h_subj_checks(i))
            app.h_subj_checks(i).Value = ~any(strcmp(st.subj_off, app.subj_ids{i}));
        end
    end
    for i = 1:numel(app.h_cond_checks)
        if isgraphics(app.h_cond_checks(i))
            app.h_cond_checks(i).Value = ~any(strcmp(st.cond_off, app.state.conds_all{i}));
        end
    end
end
style(app);
update_summary(app);
end


% ── run inputs of one sheet ──────────────────────────────────────────────
function R = run_set(app, name, with_style)
R = struct('sheet',name, 'subjects',{{}}, 'Chins2Run',{{}}, 'conds_all',{{}}, ...
    'cond_labels',{{}}, 'Conds2Run',{{}}, 'cond_colors',zeros(0,3), 'cond_markers',{{}});
k = key(name);
if strcmp(name, app.state.sheet_chips)          % on screen: the chips themselves
    on_s = arrayfun(@(c) isgraphics(c) && c.Value, app.h_subj_checks);
    on_c = arrayfun(@(c) isgraphics(c) && c.Value, app.h_cond_checks);
    R.subjects    = app.subj_ids(:)';
    R.conds_all   = app.state.conds_all(:)';
    R.cond_labels = app.state.cond_labels(:)';
    R.Chins2Run   = app.subj_ids(on_s);  R.Chins2Run = R.Chins2Run(:);
    R.Conds2Run   = R.conds_all(on_c);
    R.cond_colors = app.state.cond_colors;
    R.cond_markers = app.state.cond_markers;
    return
end
if ~isfield(app.state.sheet_roster, k)          % read once per roster load
    try
        [s, c, l] = APAT_app.read_chinroster_sheet(app.state.sheet_file, name);
        app.state.sheet_roster.(k) = struct('subjects',{s(:)'}, 'conds_all',{c(:)'}, 'cond_labels',{l(:)'});
    catch
        return
    end
end
ro = app.state.sheet_roster.(k);
R.subjects = ro.subjects;  R.conds_all = ro.conds_all;  R.cond_labels = ro.cond_labels;
off_s = {};  off_c = {};
if isfield(app.state.sheet_store, k)
    off_s = app.state.sheet_store.(k).subj_off;  off_c = app.state.sheet_store.(k).cond_off;
end
R.Chins2Run = R.subjects(~ismember(R.subjects, off_s));  R.Chins2Run = R.Chins2Run(:);
R.Conds2Run = R.conds_all(~ismember(R.conds_all, off_c));
if ~with_style, return; end
% plot colours / markers: defaults in roster order, then the saved ones (by path)
n = numel(R.conds_all);
pal = default_plot_colors();
R.cond_colors = pal(mod((1:n)-1, size(pal,1)) + 1, :);
d = {'v','s','d','^','o','>','p','*','x'};      % = chinroster_ops>default_markers
R.cond_markers = d(mod((1:n)-1, numel(d)) + 1);
try
    f = fullfile(strtrim(app.RootDirField.Value), 'Analysis', 'launcher_last_settings.mat');
    if exist(f, 'file')
        t = load(f, 'last_settings');  s = t.last_settings;
        for i = 1:n
            if isfield(s,'cond_colors') && isfield(s.cond_colors,'paths')
                j = find(strcmp(s.cond_colors.paths, R.conds_all{i}), 1);
                if ~isempty(j), R.cond_colors(i,:) = s.cond_colors.rgb(j,:); end
            end
            if isfield(s,'cond_markers') && isfield(s.cond_markers,'paths')
                j = find(strcmp(s.cond_markers.paths, R.conds_all{i}), 1);
                if ~isempty(j) && j <= numel(s.cond_markers.mk), R.cond_markers{i} = char(s.cond_markers.mk{j}); end
            end
        end
    end
catch
end
end
