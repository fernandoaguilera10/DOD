function out = exp_overlay(app, action, varargin)
%EXP_OVERLAY  Several Experiments on the same Average plots.
%
%   exp_overlay(app, 'clear')        remove the overlay (groups, keys) and put
%                                    back the axis limits it changed
%   exp_overlay(app, 'build')        Average view, several Experiments selected
%                                    (app.res.exp_show): draw the other
%                                    Experiments' data into the view on screen
%   names = exp_overlay(app, 'names')  selection, base (= Experiment on screen) first
%   names = exp_overlay(app, 'shown')  Experiments drawn right now ({} = no overlay)
%   exp_overlay(app, 'pick', name)   Plot Settings EXPERIMENT button
%   f = exp_overlay(app, 'file', f)  Save Image path: '_<BASE>' → '_<BASE>_<OTHER>'
%
%   The base view is the Experiment on screen (app.res.exp_cur, private/res_exp.m);
%   its panels are shown as usual. For every other selected Experiment the
%   Average container of the same measure is looked up in app.res.exp_sets and
%   every plotted axes of the base view (visible, all tabs) is matched with the
%   source axes at the same place: the path of containers from the Average
%   host down to the axes (panel / tab Tag or Title, then rank among equal
%   siblings; axes Tag (+ UserData.memr_cond) and rank). Its data objects
%   (lines, error bars, scatter, patches, areas, bars — no text, shading
%   bands (apat_xgroup), tracking lines, reference lines, legends, tables,
%   other overlays) are copied ONCE per navigation into an hggroup
%   (Tag 'exp_ovl_grp', UserData = Experiment) inside the base axes.
%   Style: condition colours kept; 2nd Experiment dashed, 3rd dotted, 4th
%   dash-dot; open markers. EFR with several levels shown (efr_overlay):
%   each shown level of the other Experiment is copied with that level's
%   line style and drawn thinner (experiment = line weight, level = style).
%   Categorical x axes (integer ticks with text labels): positions are
%   matched by label (labels the base lacks are appended, x range widened)
%   and shifted slightly so the points do not sit on top of each other.
%   Y limits widen to include the overlay (originals in appdata exp_ylim0;
%   restored only if nobody changed them since). Key: hidden axes Tag
%   'exp_key' + horizontal legend top-left of each container holding
%   overlaid plots ("NOISE" solid / filled, "BLAST" dashed / open).
%   Copies keep their Tags / DisplayName (Subjects ON/OFF, tracking, ✕
%   excluded marks) and carry appdata apat_cond_rgb (Conditions buttons);
%   visibility follows the base view's objects with the same Tag.
%   Handles are recorded in app.res.exp_ovl so 'clear' is cheap. Silent.
out = [];
try
    switch action
        case 'clear', do_clear(app);
        case 'build', do_build(app);
        case 'names', out = sel_names(app);
        case 'shown'
            out = {};
            if isfield(app.res, 'exp_ovl') && isstruct(app.res.exp_ovl) && isfield(app.res.exp_ovl, 'names')
                g = app.res.exp_ovl.grp;
                if ~isempty(g) && any(isvalid(g)), out = app.res.exp_ovl.names; end
            end
        case 'pick', do_pick(app, varargin{1});
        case 'file'
            out = varargin{1};
            out = file_name(app, out);
    end
catch
    if any(strcmp(action, {'names','shown'})), out = {}; end
    if strcmp(action, 'file'), out = varargin{1}; end
end
end


% ── selection ──────────────────────────────────────────────────────────
function s = sel_names(app)
L = res_exp(app, 'list');
cur = '';  try, cur = char(app.res.exp_cur); catch, end
s = {};
if isfield(app.res, 'exp_show') && iscell(app.res.exp_show), s = app.res.exp_show(:)'; end
s = s(ismember(s, L));
if ~isempty(cur), s = [{cur}, s(~strcmp(s, cur))]; end
s = unique(s, 'stable');
end

function do_pick(app, name)
if is_running(app), return; end
L = res_exp(app, 'list');
if ~any(strcmp(L, name)), return; end
cur = '';  try, cur = char(app.res.exp_cur); catch, end
if app.res.mode == 1                      % Individual: one Experiment at a time
    if ~strcmp(name, cur), res_exp(app, 'show', name); end
    return
end
sh = sel_names(app);
if strcmp(name, cur)
    if numel(sh) < 2, return; end         % at least one stays on
    app.res.exp_show = sh(2:end);         % next one becomes the base view
    res_exp(app, 'show', sh{2});
elseif any(strcmp(sh, name))
    app.res.exp_show = sh(~strcmp(sh, name));
    navigate_results(app, 'exp_overlay');
else
    app.res.exp_show = [sh, {name}];
    navigate_results(app, 'exp_overlay');
end
end

function tf = is_running(app)
tf = isappdata(app.UIFigure, 'apat_running') && isequal(getappdata(app.UIFigure, 'apat_running'), true);
end

function f = file_name(app, f)
sh = exp_overlay(app, 'shown');
if numel(sh) < 2, return; end
cl = cellfun(@(n) regexprep(char(n), '[^\w-]', '_'), sh, 'UniformOutput', false);
tok = ['_' cl{1}];
k = strfind(f, tok);
if ~isempty(k)
    k = k(end);
    f = [f(1:k-1) '_' strjoin(cl, '_') f(k+numel(tok):end)];
else
    f = [f '_' strjoin(cl, '_')];
end
end


% ── clear ──────────────────────────────────────────────────────────────
function do_clear(app)
if ~isfield(app.res, 'exp_ovl') || ~isstruct(app.res.exp_ovl), app.res.exp_ovl = empty_rec(); return; end
O = app.res.exp_ovl;
del(O.key);  del(O.grp);
for A = O.ax(:)'
    try
        if ~isvalid(A), continue; end
        if isappdata(A, 'exp_ylim0')
            if isequal(A.YLim, getappdata(A, 'exp_ylim1')), A.YLim = getappdata(A, 'exp_ylim0'); end
            rmappdata(A, 'exp_ylim0');  rmappdata(A, 'exp_ylim1');
        end
        if isappdata(A, 'exp_x0')
            x0 = getappdata(A, 'exp_x0');
            if isequal(A.XLim, x0.xl1), A.XLim = x0.XLim; end
            A.XTick = x0.XTick;  A.XTickLabel = x0.XTickLabel;
            rmappdata(A, 'exp_x0');
        end
    catch
    end
end
app.res.exp_ovl = empty_rec();
end

function R = empty_rec()
R = struct('grp',gobjects(0), 'key',gobjects(0), 'ax',gobjects(0), 'names',{{}});
end

function del(H)
for h = H(:)'
    try, if isvalid(h), delete(h); end, catch, end
end
end


% ── build ──────────────────────────────────────────────────────────────
function do_build(app)
if ~isfield(app.res, 'exp_ovl') || ~isstruct(app.res.exp_ovl), app.res.exp_ovl = empty_rec(); end
if app.res.mode ~= 2 || is_running(app), return; end
sh = sel_names(app);
if numel(sh) < 2, return; end
m = app.res.meas_idx;
root = app.res.panels{2, m};
if ~isvalid(root) || strcmp(root.Visible, 'off'), return; end
delete(findall(root, 'Tag','exp_ovl_grp'));      % strays (never recorded)
delete(findall(root, 'Tag','exp_key'));
% source Average containers of the other Experiments
src = {};  nm = {};
for i = 2:numel(sh)
    j = find(strcmp({app.res.exp_sets.name}, sh{i}), 1);
    if isempty(j), continue; end
    P = app.res.exp_sets(j).panels;
    if size(P, 2) < m || ~isvalid(P{2, m}), continue; end
    src{end+1} = P{2, m};  nm{end+1} = sh{i}; %#ok<AGROW>
end
if isempty(src), return; end
% EFR: levels shown on the base view (navigate_results>efr_overlay)
[lvl_prim, lvl_tags, lvl_ls] = efr_levels(app, root, m);
multi_lvl = numel(lvl_tags) > 1;
% plotted axes of the base view
A_all = findall(root, 'Type','axes');
base = gobjects(0);
for A = A_all(:)'
    if plot_axes(A) && shown_in(A, root), base(end+1) = A; end %#ok<AGROW>
end
if isempty(base), return; end
set(findall(root, 'Type','legend'), 'AutoUpdate','off');
estyle = {'--', ':', '-.'};
R = app.res.exp_ovl;
used = false(1, numel(src));
conts = gobjects(0);
for e = 1:numel(src)
    smap = key_map(src{e});
    if smap.Count == 0, continue; end
    for A = base(:)'
        key = key_of(A, root);
        if isempty(key), continue; end
        % (key variant, line style, level rank) per shown level
        V = {key, '', 0};
        if multi_lvl && contains(key, ['uipanel:' lvl_prim '#'])
            V = cell(numel(lvl_tags), 3);
            for t = 1:numel(lvl_tags)
                V(t, :) = {strrep(key, ['uipanel:' lvl_prim '#'], ['uipanel:' lvl_tags{t} '#']), lvl_ls{t}, t - 1};
            end
        end
        vmap = base_vis(A);
        for v = 1:size(V, 1)
            if ~isKey(smap, V{v,1}), continue; end
            B = smap(V{v,1});
            kids = allchild(B);
            keep = arrayfun(@copy_ok, kids);
            if ~any(keep), continue; end
            ls = V{v,2};  if isempty(ls), ls = estyle{mod(e-1, numel(estyle)) + 1}; end
            % categorical x: match by label, shift sideways
            [isc, fx] = cat_map(A, B);
            dx = 0;
            if isc
                if multi_lvl, dx = 0.10*V{v,3} + 0.06*e; else, dx = 0.12*e; end
            end
            hg = hggroup(A, 'Tag','exp_ovl_grp', 'HandleVisibility','off', 'UserData',nm{e});
            S = kids(keep);
            nh = copyobj(S, hg);
            for q = 1:numel(nh)
                restyle(nh(q), S(q), ls, multi_lvl, vmap, fx, dx);
            end
            R.grp(end+1) = hg;
            widen_y(A, nh);
            if ~any(R.ax == A), R.ax(end+1) = A; end
            used(e) = true;
            c = holder(A);
            if ~isempty(c) && ~any(conts == c), conts(end+1) = c; end %#ok<AGROW>
        end
    end
end
if ~any(used), app.res.exp_ovl = R; return; end
R.names = [sh(1), nm(used)];
for c = conts(:)'
    k = add_key(c, root, R.names, multi_lvl, estyle);
    if ~isempty(k), R.key(end+1) = k; end
end
app.res.exp_ovl = R;
try, subject_pick(app, 'wire'); catch, end        % overlaid subject points clickable / tracked
end


function [prim, tags, ls] = efr_levels(app, root, m)
% EFR: shown level tags (prim = highest first), line style per level as in
% navigate_results>efr_overlay (prim '-', next-highest '--', ':', '-.').
prim = '';  tags = {};  ls = {};
if ~any(m == [3 4]), return; end
lp = findobj(root.Children, 'flat', 'Type','uipanel', '-regexp', 'Tag', 'dB SPL$');
if isempty(lp), return; end
t = arrayfun(@(p) p.Tag, lp, 'UniformOutput', false);
v = inf(1, numel(t));
for k = 1:numel(t), x = sscanf(t{k}, '%f'); if ~isempty(x), v(k) = x(1); end, end
[~, o] = sort(v);  t = t(o);  lp = lp(o);
sel = {};  try, sel = app.res.efr_level; catch, end
if ischar(sel), sel = {sel}; end
on = ismember(t, sel);
vis = arrayfun(@(p) strcmp(p.Visible, 'on'), lp);
if ~any(on), on = vis; end
if ~any(on), return; end
s = find(on);
prim = t{s(end)};
others = fliplr(s(1:end-1));
st = {'--', ':', '-.'};
tags = [{prim}, t(others)];
ls = [{'-'}, arrayfun(@(i) st{mod(i-1, 3) + 1}, 1:numel(others), 'UniformOutput', false)];
end


% ── matching ───────────────────────────────────────────────────────────
function tf = plot_axes(A)
tf = false;
try
    if strcmp(A.Visible, 'off'), return; end
    tg = char(A.Tag);
    if any(strcmp(tg, {'efr_lvl_key','exp_key','memr_lvl_cbar','legend'})), return; end
    if ~isempty(regexp(tg, '_table$', 'once')), return; end
    tf = true;
catch
end
end

function tf = shown_in(A, root)
% every container between A and root visible (tabs: any tab counts)
tf = true;
x = A.Parent;
while ~isempty(x) && x ~= root
    if isa(x, 'matlab.ui.Figure'), tf = false; return; end
    if ~isa(x, 'matlab.ui.container.Tab') && isprop(x, 'Visible') && strcmp(x.Visible, 'off')
        tf = false; return;
    end
    x = x.Parent;
end
if isempty(x), tf = false; end
end

function M = key_map(root)
M = containers.Map('KeyType','char', 'ValueType','any');
for A = findall(root, 'Type','axes')'
    try
        if any(strcmp(char(A.Tag), {'efr_lvl_key','exp_key'})), continue; end
        k = key_of(A, root);
        if ~isempty(k) && ~isKey(M, k), M(k) = A; end
    catch
    end
end
end

function k = key_of(h, root)
parts = {};
x = h;
while ~isempty(x) && x ~= root
    if isa(x, 'matlab.ui.Figure'), k = ''; return; end
    parts{end+1} = node_key(x); %#ok<AGROW>
    x = x.Parent;
end
if isempty(x), k = ''; return; end
k = strjoin(fliplr(parts), '/');
end

function id = node_key(x)
id0 = node_id(x);
r = 1;
try
    sib = allchild(x.Parent);
    for s = sib(:)'
        if s == x, break; end
        if strcmp(node_id(s), id0), r = r + 1; end
    end
catch
end
id = sprintf('%s#%d', id0, r);
end

function id = node_id(x)
id = '';
try
    ty = char(x.Type);
    tg = '';  if isprop(x, 'Tag'), tg = char(x.Tag); end
    tt = '';
    if ~strcmp(ty, 'axes') && isprop(x, 'Title') && (ischar(x.Title) || isstring(x.Title))
        tt = char(x.Title);
    end
    if ~isempty(tg),     id = [ty ':' tg];
    elseif ~isempty(tt), id = [ty '|' tt];
    else,                id = ty;
    end
    if strcmp(ty, 'axes') && isstruct(x.UserData) && isfield(x.UserData, 'memr_cond')
        id = [id '@' char(x.UserData.memr_cond)];      % MEMR panels: one per condition
    end
catch
end
end

function c = holder(A)
% container (panel / tab) the key goes into
c = [];
x = A.Parent;
while ~isempty(x)
    if isa(x, 'matlab.ui.container.Panel') || isa(x, 'matlab.ui.container.Tab'), c = x; return; end
    if isa(x, 'matlab.ui.Figure'), return; end
    x = x.Parent;
end
end


% ── what to copy, how it looks ─────────────────────────────────────────
function tf = copy_ok(h)
tf = false;
try
    if ~any(strcmp(h.Type, {'line','errorbar','scatter','patch','area','stair','bar'})), return; end
    tg = char(h.Tag);
    if any(strcmp(tg, {'apat_xgroup','subj_pick_hl','efr_xlab','apat_leg_item','abr_n_lbl'})), return; end
    if isprop(h, 'YData')
        y = double(h.YData);  if isempty(y) || all(~isfinite(y(:))), return; end
    end
    % reference lines (2-point black / grey: zero lines, dividers)
    if isprop(h, 'XData') && numel(h.XData) <= 2 && isprop(h, 'Color') && isnumeric(h.Color)
        c = double(h.Color(1:3));
        if max(c) - min(c) < 0.02, return; end
    end
    tf = true;
catch
end
end

function M = base_vis(A)
% intended visibility of the base objects per Tag (Subjects, Sweeps, SD …)
M = containers.Map('KeyType','char', 'ValueType','char');
for c = allchild(A)'
    try
        tg = char(c.Tag);
        if isempty(tg) || isKey(M, tg) || strcmp(c.Type, 'hggroup'), continue; end
        v = c.Visible;
        if isappdata(c, 'cond_hid'), v = getappdata(c, 'cond_hid'); end
        M(tg) = char(v);
    catch
    end
end
end

function restyle(n, h, ls, thin, vmap, fx, dx)
try
    c = cond_rgb(h);
    for f = {'apat_excluded','pick_orig','pick_dim0'}
        if isappdata(h, f{1}), setappdata(n, f{1}, getappdata(h, f{1})); end
    end
    if ~isempty(c), setappdata(n, 'apat_cond_rgb', c); end
    v = h.Visible;
    if isappdata(h, 'cond_hid'), v = getappdata(h, 'cond_hid'); end
    if isappdata(n, 'cond_hid'), rmappdata(n, 'cond_hid'); end
    tg = char(n.Tag);
    if ~isempty(tg) && isKey(vmap, tg), v = vmap(tg); end
    n.Visible = v;
    if isprop(n, 'LineStyle') && ~strcmp(n.LineStyle, 'none') && ~any(strcmp(n.Type, {'patch','area','bar'}))
        n.LineStyle = ls;
    end
    if thin && isprop(n, 'LineWidth'), n.LineWidth = max(0.5, 0.55*n.LineWidth); end
    if thin && isprop(n, 'MarkerSize'), n.MarkerSize = max(3, 0.8*n.MarkerSize); end
    % open markers, condition colour on the edge
    if strcmp(n.Type, 'scatter')
        if ~(ischar(n.MarkerFaceColor) && strcmp(n.MarkerFaceColor, 'none'))
            if ischar(n.MarkerEdgeColor) && strcmp(n.MarkerEdgeColor, 'none')
                if isnumeric(n.MarkerFaceColor), n.MarkerEdgeColor = n.MarkerFaceColor;
                else, n.MarkerEdgeColor = 'flat'; end
            end
            n.MarkerFaceColor = 'none';
            if isnumeric(n.MarkerEdgeAlpha) && isnumeric(n.MarkerFaceAlpha)
                n.MarkerEdgeAlpha = max(n.MarkerEdgeAlpha, n.MarkerFaceAlpha);
            end
        end
        if isappdata(n, 'pick_orig')                     % tracking restores the open look
            o = getappdata(n, 'pick_orig');
            o.MarkerEdgeColor = n.MarkerEdgeColor;
            if isnumeric(o.MarkerEdgeAlpha) && isnumeric(n.MarkerEdgeAlpha)
                o.MarkerEdgeAlpha = max(o.MarkerEdgeAlpha, n.MarkerEdgeAlpha);
            end
            setappdata(n, 'pick_orig', o);
        end
    elseif isprop(n, 'MarkerFaceColor') && isnumeric(n.MarkerFaceColor) && ~any(strcmp(n.Type, {'patch','area','bar'}))
        if ~isnumeric(n.MarkerEdgeColor) && strcmp(n.MarkerEdgeColor, 'none')
            n.MarkerEdgeColor = n.MarkerFaceColor;
        end
        n.MarkerFaceColor = [1 1 1];
        if isappdata(n, 'pick_dim0')
            o = getappdata(n, 'pick_dim0');  o.MFC = [1 1 1];  o.MEC = n.MarkerEdgeColor;
            setappdata(n, 'pick_dim0', o);
        end
    end
    if any(strcmp(n.Type, {'patch','area'})) && isprop(n, 'FaceAlpha') && isnumeric(n.FaceAlpha)
        n.FaceAlpha = 0.6*n.FaceAlpha;                   % bands: lighter, the base stays readable
    end
    % categorical x positions
    if ~isempty(fx) && isprop(n, 'XData')
        n.XData = fx(double(n.XData)) + dx;
    end
catch
end
end

function c = cond_rgb(h)
% condition colour as cond_filter>match_cond reads it (before restyling)
c = [];
try
    if isappdata(h, 'apat_cond_rgb'), c = double(getappdata(h, 'apat_cond_rgb')); c = c(1:3); return; end
    if isprop(h, 'UserData') && isstruct(h.UserData) && isfield(h.UserData, 'apat_cond_rgb')
        c = double(h.UserData.apat_cond_rgb);  c = c(1:3);  return
    end
    if isprop(h, 'LineStyle') && strcmp(h.LineStyle, 'none') && isprop(h, 'Marker') && ~strcmp(h.Marker, 'none')
        if isnumeric(h.MarkerEdgeColor) && numel(h.MarkerEdgeColor) == 3, c = double(h.MarkerEdgeColor);
        elseif isnumeric(h.MarkerFaceColor) && numel(h.MarkerFaceColor) == 3, c = double(h.MarkerFaceColor);
        elseif isprop(h, 'Color'), c = double(h.Color(1:3));
        end
    elseif isprop(h, 'CData') && isnumeric(h.CData) && numel(h.CData) == 3
        c = double(h.CData(:)');
    elseif isprop(h, 'Color') && isnumeric(h.Color) && numel(h.Color) >= 3
        c = double(h.Color(1:3));
    elseif isprop(h, 'FaceColor') && isnumeric(h.FaceColor) && numel(h.FaceColor) == 3
        c = double(h.FaceColor);
    end
catch
    c = [];
end
end


% ── categorical x axes ─────────────────────────────────────────────────
function [isc, fx] = cat_map(A, B)
% A (base), B (source): integer ticks with text labels on both → map source
% positions to the base position of the same label (new labels appended).
isc = false;  fx = [];
try
    if ~(is_cat(A) || any(strcmp(A.Tag, {'efr_tile','efr_tile_total'}))), return; end
    if ~(is_cat(B) || any(strcmp(B.Tag, {'efr_tile','efr_tile_total'}))), return; end
    ta = double(A.XTick(:)');  la = strtrim(cellstr(A.XTickLabel))';
    tb = double(B.XTick(:)');  lb = strtrim(cellstr(B.XTickLabel))';
    if numel(la) ~= numel(ta) || numel(lb) ~= numel(tb) || isempty(tb), return; end
    pos = zeros(1, numel(tb));  add_t = [];  add_l = {};
    for j = 1:numel(tb)
        i = find(strcmp(la, lb{j}), 1);
        if isempty(i), i = find(strcmp(add_l, lb{j}), 1); if ~isempty(i), pos(j) = add_t(i); continue; end, end
        if isempty(i)
            nt = max([ta, add_t]) + 1;
            add_t(end+1) = nt;  add_l{end+1} = lb{j}; %#ok<AGROW>
            pos(j) = nt;
        else
            pos(j) = ta(i);
        end
    end
    if ~isempty(add_t)                               % labels the base view lacks
        if ~isappdata(A, 'exp_x0')
            setappdata(A, 'exp_x0', struct('XTick',A.XTick, 'XTickLabel',{A.XTickLabel}, ...
                'XLim',A.XLim, 'xl1',[]));
        end
        A.XTick = [ta, add_t];  A.XTickLabel = [la, add_l];
        xl = A.XLim;  A.XLim = [xl(1), max(xl(2), max(add_t) + 0.5)];
        x0 = getappdata(A, 'exp_x0');  x0.xl1 = A.XLim;  setappdata(A, 'exp_x0', x0);
    end
    isc = true;
    fx = @(x) map_x(x, tb, pos);
catch
    isc = false;  fx = [];
end
end

function y = map_x(x, tb, pos)
y = nan(size(x));
for k = 1:numel(x)
    if ~isfinite(x(k)), continue; end
    [d, j] = min(abs(tb - x(k)));
    if d <= 0.45, y(k) = pos(j) + (x(k) - tb(j)); end
end
end

function tf = is_cat(A)
tf = false;
try
    if ~strcmp(A.XScale, 'linear'), return; end
    t = double(A.XTick);  L = cellstr(A.XTickLabel);
    if isempty(t) || numel(L) ~= numel(t) || any(abs(t - round(t)) > 1e-9), return; end
    L = strtrim(L);
    txt = ~cellfun(@isempty, L) & isnan(str2double(L));
    tf = any(txt);
catch
end
end


% ── limits, key ────────────────────────────────────────────────────────
function widen_y(A, nh)
yy = [];
for h = nh(:)'
    try
        if ~isprop(h, 'YData') || strcmp(h.Visible, 'off'), continue; end
        v = double(h.YData(:)');
        if isprop(h, 'YNegativeDelta') && ~isempty(h.YNegativeDelta)
            v = [v, double(h.YData(:)' - h.YNegativeDelta(:)'), double(h.YData(:)' + h.YPositiveDelta(:)')]; %#ok<AGROW>
        end
        yy = [yy, v(isfinite(v))]; %#ok<AGROW>
    catch
    end
end
if isempty(yy), return; end
if ~isappdata(A, 'exp_ylim0'), setappdata(A, 'exp_ylim0', A.YLim); end
yl = A.YLim;  lo = min(yy);  hi = max(yy);
if lo < yl(1) || hi > yl(2)
    r = max(hi, yl(2)) - min(lo, yl(1));
    if strcmp(A.YScale, 'log')
        A.YLim = [min(lo, yl(1)), max(hi, yl(2))];
    else
        A.YLim = [min(lo - 0.05*r, yl(1)), max(hi + 0.05*r, yl(2))];
    end
end
setappdata(A, 'exp_ylim1', A.YLim);
end

function axK = add_key(c, root, names, multi_lvl, estyle)
% "NOISE ━●  BLAST ╌○" top-left of container c (below the exclusion note)
axK = [];
try
    axK = axes(c, 'Units','normalized', 'Position',[0.01 0.97 0.2 0.01], 'Visible','off', ...
        'Tag','exp_key', 'HitTest','off');
    hold(axK, 'on');
    ink = [0.15 0.15 0.15];
    hK = gobjects(1, numel(names));
    for k = 1:numel(names)
        if multi_lvl                                 % levels use the styles: weight = Experiment
            ls = '-';  lw = 2.2;  if k > 1, lw = 1; end
        else
            ls = '-';  if k > 1, ls = estyle{mod(k-2, numel(estyle)) + 1}; end
            lw = 2;
        end
        mfc = ink;  if k > 1, mfc = [1 1 1]; end
        hK(k) = plot(axK, NaN, NaN, 'Color',ink, 'LineWidth',lw, 'LineStyle',ls, ...
            'Marker','o', 'MarkerSize',7, 'MarkerFaceColor',mfc, 'MarkerEdgeColor',ink);
    end
    lg = legend(axK, hK, names, 'Orientation','horizontal', 'Box','off', 'FontSize',12, ...
        'Location','none', 'Interpreter','none', 'AutoUpdate','off');
    lg.Tag = 'exp_key_lg';
    lg.Units = 'normalized';
    ph = 600;  try, pp = getpixelposition(c);  ph = max(100, pp(4)); catch, end
    off = 6;
    if ~isempty(findall(root, 'Tag','apat_excl_note')), off = 34; end   % under "✕ Excluded From Average"
    lg.Position(1:2) = [0.012, 1 - lg.Position(4) - off/ph];
catch
    try, if ~isempty(axK) && isvalid(axK), delete(axK); end, catch, end
    axK = [];
end
end
