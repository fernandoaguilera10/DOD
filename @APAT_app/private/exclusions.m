function out = exclusions(app, action, varargin)
%EXCLUSIONS  Subjects / conditions left out of the group averages.
%
%   pairs = exclusions(app, 'pairs', label)   n×2 {subject, condition|'*'}
%           for one analysis (label = Results label, e.g. 'ABR Thresholds',
%           'DPOAE', 'MEMR' (= ART), 'MEMR Vector' …); passed to analysis_run as cfg.exclude.
%   exclusions(app, 'dialog')                 open the Exclusions window for
%           the analysis on screen (current subject preselected in
%           Individual view).
%   exclusions(app, 'mark', panel, meas_idx)  after an Average is embedded:
%           subject points of excluded data are drawn as ✕ (condition
%           colour, full strength) instead of the filled translucent marker,
%           and a note above the plots lists what is excluded.
%   exclusions(app, 'sync')                   update the "Exclude" button in
%           the Results bar (count; red "Excluded" when the subject on
%           screen is excluded).
%   pairs = exclusions(app, 'relevant', label, meas_idx)
%           the stored pairs that concern the run on screen: subject one of
%           the Experiment's run subjects (app.res.run_conds.subj, else the
%           subjects with results) and condition '*' or one of the run's
%           conditions. Used for the ✕ points, the note, the button count,
%           the dialog and the status strip.
%   pairs = exclusions(app, 'for_run', label, Chins2Run, Conds2Run)
%           the stored pairs of one analysis restricted to one run
%           (RunButtonPushed>run_one → cfg.exclude, per Experiment).
%
%   Stored pairs that are not in the run (other subjects / conditions —
%   subject IDs belong to a roster sheet) are KEPT in storage but never
%   applied, listed or counted; the dialog only edits the run's pairs and
%   saves the others back unchanged.
%
%   Stored per analysis in app.state.excl.(key) (key = valid field name of
%   the label) and saved with the project settings (launcher_last_settings.mat,
%   field 'excl'). Individual results are never removed; only the averages
%   (and their subject points / n) leave the excluded data out. The saved
%   average files carry a record of what was excluded (variable 'excluded').
out = [];
switch action
    case 'pairs',  out = get_pairs(app, varargin{1});
    case 'relevant'
        m = [];  if numel(varargin) >= 2, m = varargin{2}; end
        if isempty(m), try, m = app.res.meas_idx; catch, end, end
        [S, cn] = run_scope(app, m);
        out = filter_pairs(get_pairs(app, varargin{1}), S, cn);
    case 'for_run'
        cn = cellfun(@(c) last_part(c), cellstr(varargin{3}), 'UniformOutput', false);
        out = filter_pairs(get_pairs(app, varargin{1}), cellstr(varargin{2}), cn);
    case 'dialog', open_dialog(app);
    case 'sync',   sync_btn(app);
    case 'mark',   mark_points(app, varargin{1}, varargin{2});
end
end


% ── storage ────────────────────────────────────────────────────────────
function k = key_of(label)
k = matlab.lang.makeValidName(char(label));
end

function p = get_pairs(app, label)
p = cell(0, 2);
if ~isfield(app.state, 'excl') || ~isstruct(app.state.excl), return; end
k = key_of(label);
if isfield(app.state.excl, k) && iscell(app.state.excl.(k)) && size(app.state.excl.(k),2) == 2
    p = app.state.excl.(k);
end
end

function set_pairs(app, label, p)
if ~isfield(app.state, 'excl') || ~isstruct(app.state.excl), app.state.excl = struct(); end
app.state.excl.(key_of(label)) = p;
end

function [S, cn] = run_scope(app, m)
%RUN_SCOPE  Subjects and condition names of the run on screen (the
%   Experiment whose views are current). Empty when nothing was run.
S = {};  cn = {};
try
    rc = app.res.run_conds;
    if isstruct(rc) && isfield(rc, 'subj') && ~isempty(rc.subj), S = cellstr(rc.subj); end
    if isstruct(rc) && isfield(rc, 'sel') && ~isempty(rc.sel)
        cs = cellstr(rc.sel);
    elseif isstruct(rc) && isfield(rc, 'paths')
        cs = cellstr(rc.paths);
    else
        cs = {};
    end
    cn = cellfun(@(c) last_part(c), cs, 'UniformOutput', false);
catch
end
if isempty(S) && ~isempty(m)
    try, S = cellstr(app.res.subj_data{m}.names); catch, end
end
S = S(:)';  cn = cn(:)';
end

function q = filter_pairs(p, S, cn)
%FILTER_PAIRS  Rows of P whose subject is in S and condition is '*' or in CN.
q = cell(0, 2);
if isempty(p) || isempty(S), return; end
keep = false(size(p,1), 1);
for r = 1:size(p,1)
    c = char(p{r,2});
    keep(r) = any(strcmp(S, char(p{r,1}))) && (strcmp(c, '*') || any(strcmp(cn, c)));
end
q = p(keep, :);
end

function lbl = cur_label(app)
lbl = '';
try
    L = APAT_app.measure_tab_labels();
    lbl = L{app.res.meas_idx};
catch
end
end

function s = disp_label(lbl)
s = lbl;  if strcmp(lbl, 'MEMR'), s = 'MEMR ART'; end
end


% ── Results-bar button ────────────────────────────────────────────────
function sync_btn(app)
if ~isfield(app.res, 'excl_btn') || isempty(app.res.excl_btn) || ~isvalid(app.res.excl_btn), return; end
b = app.res.excl_btn;
b.Visible = ternary_s(isfield(app.res,'mode') && app.res.mode == 1, 'on', 'off');   % Individual view only
lbl = cur_label(app);
p = exclusions(app, 'relevant', lbl, app.res.meas_idx);   % only pairs of the run on screen
subj = '';
if app.res.mode == 1 && ~isempty(app.FigSubjDropdown.Value) && ~strcmp(app.FigSubjDropdown.Value, '-')
    subj = app.FigSubjDropdown.Value;
end
here = ~isempty(subj) && any(strcmp(p(:,1), subj));
ns = numel(unique(p(:,1)));
if here
    b.Text = 'Excluded';
    b.BackgroundColor = [0.80 0.36 0.33];  b.FontColor = [1 1 1];
    b.Tooltip = sprintf('%s is (partly) left out of the %s average — click to change', subj, disp_label(lbl));
elseif ns > 0
    b.Text = sprintf('Exclude (%d)', ns);
    b.BackgroundColor = app.clr_btn;  b.FontColor = app.clr_black;
    b.Tooltip = sprintf('%d subject(s) left out of the %s average — click to review', ns, disp_label(lbl));
else
    b.Text = 'Exclude';
    b.BackgroundColor = app.clr_btn;  b.FontColor = app.clr_black;
    b.Tooltip = 'Leave subjects or conditions out of the group average';
end
end


% ── marking excluded subject points (Average view) ─────────────────────
function mark_points(app, panel, meas_idx)
if isempty(panel) || ~isvalid(panel), return; end
L = APAT_app.measure_tab_labels();
if meas_idx < 1 || meas_idx > numel(L), return; end
p = exclusions(app, 'relevant', L{meas_idx}, meas_idx);   % stored pairs not in this run: ignored
delete(findall(panel, 'Tag','apat_excl_note'));
if isempty(p), return; end
% condition names + colours of the last run
paths = {};  rgb = zeros(0,3);
try, paths = app.res.run_conds.paths;  rgb = double(app.res.run_conds.rgb); catch, end
if ischar(paths), paths = {paths}; end
cn = cellfun(@(s) last_part(s), paths, 'UniformOutput', false);
% relative to the reference (first selected condition): excluding it = whole subject
ref = '';
try
    if app.PlotRelativeCheck.Value
        % conditions of the run on screen (its Experiment may not be the
        % sheet on screen in Setup); older runs: the Setup chips
        if isfield(app.res.run_conds, 'sel') && ~isempty(app.res.run_conds.sel)
            cs = cellstr(app.res.run_conds.sel);
        else
            sel = arrayfun(@(c) isvalid(c) && c.Value, app.h_cond_checks);
            cs = app.state.conds_all(sel);
        end
        if ~isempty(cs), ref = last_part(cs{1}); end
    end
catch
end
H = findall(panel, '-regexp', 'Tag', '_subj_pts$');
nm = 0;
for h = H(:)'
    try
        rows = strcmp(p(:,1), h.DisplayName);
        if ~any(rows), continue; end
        conds = p(rows, 2);
        whole = any(strcmp(conds, '*')) || (~isempty(ref) && any(strcmp(conds, ref)));
        c = point_rgb(h);
        if isempty(c), continue; end
        hit = whole;
        if ~hit && ~isempty(rgb)
            d = max(abs(rgb(:,1:3) - c), [], 2);  [dm, k] = min(d);
            hit = dm <= 0.02 && k <= numel(cn) && any(strcmp(conds, cn{k}));
        end
        if ~hit, continue; end
        if isprop(h, 'SizeData')                     % scatter
            set(h, 'Marker','x', 'MarkerEdgeColor',c, 'MarkerEdgeAlpha',0.95, 'LineWidth',1.8);
        else                                         % line with markers
            set(h, 'Marker','x', 'MarkerFaceColor','none', 'MarkerEdgeColor',c, 'LineWidth',1.8);
        end
        setappdata(h, 'apat_excluded', true);
        nm = nm + 1;
    catch
    end
end
% note above the plots: what is left out
items = cell(1, size(p,1));
for r = 1:size(p,1)
    cnd = p{r,2};  if strcmp(cnd, '*'), cnd = 'All'; end
    items{r} = sprintf('%s (%s)', p{r,1}, cnd);
end
u = unique(p(:,1), 'stable');
txt = cell(1, numel(u));
for k = 1:numel(u)
    rr = strcmp(p(:,1), u{k});  cc = p(rr, 2);
    if any(strcmp(cc, '*')), cc = {'All'}; end
    txt{k} = sprintf('%s (%s)', u{k}, strjoin(cc, ', '));
end
try
    pp = getpixelposition(panel);
    uilabel(panel, 'Text',['✕  Excluded From Average:  ' strjoin(txt, ' · ')], ...
        'FontSize',12, 'FontWeight','bold', 'FontColor',[0.62 0.18 0.16], ...
        'Position',[16 pp(4) - 28 min(900, pp(3) - 32) 20], 'Tag','apat_excl_note', ...
        'Tooltip',sprintf('Shown as ✕ in the plots (%d point groups); means, SD and n leave them out', nm));
catch
end
end

function c = point_rgb(h)
c = [];
try
    if isprop(h, 'CData') && isnumeric(h.CData) && numel(h.CData) == 3
        c = double(h.CData(:)');
    elseif isprop(h, 'MarkerFaceColor') && isnumeric(h.MarkerFaceColor) && numel(h.MarkerFaceColor) == 3
        c = double(h.MarkerFaceColor);
    elseif isprop(h, 'MarkerEdgeColor') && isnumeric(h.MarkerEdgeColor) && numel(h.MarkerEdgeColor) == 3
        c = double(h.MarkerEdgeColor);
    elseif isprop(h, 'Color')
        c = double(h.Color(1:3));
    end
catch
end
end


% ── dialog ────────────────────────────────────────────────────────────
function open_dialog(app)
lbl = cur_label(app);
if isempty(lbl), return; end
m = app.res.meas_idx;
% subjects: those with results for this analysis + those selected on Setup
% (of the Experiment on screen; Setup chips only before a run). Stored
% pairs of other subjects / conditions are not shown and are kept as they are.
names = {};
try, names = app.res.subj_data{m}.names(:)'; catch, end
[S_run, ~] = run_scope(app, m);
names = [names, S_run];
if isempty(names), try, names = reshape(get_checked_subjects(app), 1, []); catch, end, end
p_all = get_pairs(app, lbl);
names = unique(cellfun(@char, names, 'UniformOutput', false), 'stable');
if isempty(names)
    uialert(app.UIFigure, 'Run this analysis first: there are no subjects to exclude yet.', ...
        'Exclude From Average', 'Icon','info');
    return
end
% conditions: those of the last run (else all conditions of the roster)
paths = {};
try, paths = app.res.run_conds.paths; catch, end
if isempty(paths), paths = app.state.conds_all; end
if ischar(paths), paths = {paths}; end
cn = cellfun(@(s) last_part(s), paths, 'UniformOutput', false);
p = filter_pairs(p_all, names, cn);                 % the pairs this table edits
nS = numel(names);  nC = numel(cn);
D = cell(nS, nC + 2);
for s = 1:nS
    rows = strcmp(p(:,1), names{s});
    D{s,1} = names{s};
    allc = any(strcmp(p(rows,2), '*'));
    for c = 1:nC
        D{s,c+2} = allc || any(strcmp(p(rows,2), cn{c}));
    end
    D{s,2} = allc || (nC > 0 && all([D{s,3:end}]));
end

% window
W = min(760, max(520, 260 + 110*nC));  H = min(640, 250 + 28*nS);
fp = app.UIFigure.Position;
d = uifigure('Name', sprintf('Exclude From Average — %s', disp_label(lbl)), 'WindowStyle','modal', ...
    'Resize','off', 'Color',app.clr_bg, ...
    'Position',[fp(1)+(fp(3)-W)/2, fp(2)+(fp(4)-H)/2, W, H]);
uilabel(d, 'Text',sprintf('Exclude From Average — %s', disp_label(lbl)), 'FontSize',17, 'FontWeight','bold', ...
    'FontColor',app.clr_black, 'Position',[20 H-44 W-40 28]);
uilabel(d, 'WordWrap','on', 'FontSize',12, 'FontColor',[0.35 0.35 0.35], 'Position',[20 H-92 W-40 44], ...
    'Text',['Ticked subjects / conditions are left out of the group average (their individual ' ...
            'results are kept). Tick "All Conditions" to leave a whole subject out. Select several ' ...
            'rows (Shift / Ctrl-click) and use Exclude / Include Selected to change them together.']);
cols = [{'Subject','All Conditions'}, cn(:)'];
t = uitable(d, 'Data',D, 'ColumnName',cols, 'RowName',{}, ...
    'ColumnEditable',[false true(1, nC+1)], 'FontSize',13, ...
    'ColumnWidth',[{110, 120}, repmat({'auto'}, 1, nC)], ...
    'Position',[20 112 W-40 H-212]);
try, t.SelectionType = 'row'; t.Multiselect = 'on'; catch, end
t.CellEditCallback = @(src, ev) cell_edit(src, ev, nC);
% preselect the subject on screen (Individual view)
if app.res.mode == 1
    r = find(strcmp(names, app.FigSubjDropdown.Value), 1);
    if ~isempty(r), try, t.Selection = r; catch, end, end
end
BH = 32;  y = 66;
uibutton(d, 'push', 'Text','Exclude Selected', 'FontSize',13, 'FontWeight','bold', ...
    'BackgroundColor',app.clr_btn, 'Position',[20 y 150 BH], ...
    'ButtonPushedFcn',@(~,~) set_rows(t, true, nC));
uibutton(d, 'push', 'Text','Include Selected', 'FontSize',13, 'FontWeight','bold', ...
    'BackgroundColor',app.clr_btn, 'Position',[178 y 150 BH], ...
    'ButtonPushedFcn',@(~,~) set_rows(t, false, nC));
uibutton(d, 'push', 'Text','Clear All', 'FontSize',13, ...
    'BackgroundColor',[1 1 1], 'Position',[336 y 100 BH], ...
    'ButtonPushedFcn',@(~,~) clear_all(t, nC));
cb_all = uicheckbox(d, 'Text','Apply To All Measures', 'FontSize',13, 'Value',false, ...
    'Tooltip','Use the same exclusions for every analysis (ABR, EFR, OAE, MEMR)', ...
    'Position',[W-210 y+5 190 22]);
y = 18;
uibutton(d, 'push', 'Text','Cancel', 'FontSize',13, 'BackgroundColor',[1 1 1], ...
    'Position',[W-470 y 100 BH], 'ButtonPushedFcn',@(~,~) delete(d));
uibutton(d, 'push', 'Text','Save', 'FontSize',13, 'FontWeight','bold', 'BackgroundColor',app.clr_btn, ...
    'Tooltip','Keep these exclusions; the averages change at the next run', ...
    'Position',[W-362 y 100 BH], 'ButtonPushedFcn',@(~,~) do_save(false));
uibutton(d, 'push', 'Text','Save & Update Average', 'FontSize',13, 'FontWeight','bold', ...
    'BackgroundColor',app.clr_gold, 'FontColor',app.clr_black, ...
    'Tooltip','Recompute the average now from the saved results (no re-analysis)', ...
    'Position',[W-254 y 234 BH], 'ButtonPushedFcn',@(~,~) do_save(true));

    function do_save(update)
        Dn = t.Data;
        P = cell(0, 2);
        for i = 1:size(Dn, 1)
            if Dn{i,2}
                P(end+1, :) = {Dn{i,1}, '*'}; %#ok<AGROW>
            else
                for j = 1:nC
                    if Dn{i,j+2}, P(end+1, :) = {Dn{i,1}, cn{j}}; end %#ok<AGROW>
                end
            end
        end
        labels = {lbl};
        if cb_all.Value, labels = APAT_app.measure_tab_labels(); end
        for i = 1:numel(labels)                      % pairs outside this table are kept
            old = get_pairs(app, labels{i});
            keepo = true(size(old,1), 1);
            for r = 1:size(old,1)
                c = char(old{r,2});
                keepo(r) = ~any(strcmp(names, char(old{r,1}))) || ...
                    (~strcmp(c, '*') && ~any(strcmp(cn, c)));
            end
            set_pairs(app, labels{i}, [old(keepo, :); P]);
        end
        try, settings_ops(app, 'save_excl'); catch, end
        delete(d);
        sync_btn(app);
        if update
            runs = zeros(0, 2);
            for i = 1:numel(labels)
                [mm, kk, has] = label_run(app, labels{i});
                if has, runs(end+1, :) = [mm kk]; end %#ok<AGROW>
            end
            if isempty(runs)
                uialert(app.UIFigure, 'Saved. Run this analysis to see the updated average.', ...
                    'Exclude From Average', 'Icon','info');
                return
            end
            setappdata(app.UIFigure, 'apat_run_override', struct('runs',runs, 'no_reanalyze',true));
            RunButtonPushed(app);
        end
    end
end


function cell_edit(t, ev, nC)
D = t.Data;
r = ev.Indices(1);  c = ev.Indices(2);
if c == 2
    D(r, 3:nC+2) = {logical(ev.NewData)};
else
    D{r,2} = nC > 0 && all([D{r,3:nC+2}]);
end
t.Data = D;
end

function set_rows(t, val, nC)
rows = [];
try
    sel = t.Selection;
    if ~isempty(sel), rows = unique(sel(:,1)); end
    if size(sel,2) == 1, rows = unique(sel(:)); end
catch
end
if isempty(rows), return; end
D = t.Data;
D(rows, 2:nC+2) = {logical(val)};
t.Data = D;
end

function clear_all(t, nC)
D = t.Data;
D(:, 2:nC+2) = {false};
t.Data = D;
end

function [m, k, has] = label_run(app, lbl)
% Results label -> [measure, type]; has = this analysis has results to average
m = 0;  k = 0;  has = false;
for mi = 1:numel(app.MEASURES)
    M = app.MEASURES(mi);
    subs = M.subtypes;  if isempty(subs), subs = {M.name}; end
    for ki = 1:numel(subs)
        if any(strcmp(M.name, {'ABR','EFR'})), L = [M.name ' ' subs{ki}];
        elseif strcmp(M.name, 'MEMR')                       % 'MEMR' = ART, 'MEMR Vector' …
            L = 'MEMR';  if ki > 1, L = ['MEMR ' subs{ki}]; end
        elseif isempty(M.subtypes),            L = M.name;
        else,                                  L = subs{ki};
        end
        if strcmp(L, lbl), m = mi;  k = ki; end
    end
end
if m == 0, return; end
try
    li = find(strcmp(APAT_app.measure_tab_labels(), lbl), 1);
    has = ~isempty(app.res.subj_data{li}.names);
catch
end
end

function s = last_part(p)
q = strsplit(char(p), {'/','\'});
s = q{end};
end


function s = ternary_s(c, a, b)
if c, s = a; else, s = b; end
end
