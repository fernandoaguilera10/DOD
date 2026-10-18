function navigate_results(app, action, varargin)
%NAVIGATE_RESULTS  All Results-tab navigation and setup-tab measure highlighting.
%
%   navigate_results(app, 'ind')                    — switch to Individual mode
%   navigate_results(app, 'avg')                    — switch to Average mode
%   navigate_results(app, 'meas_btn', idx)          — Results-tab measure button #idx
%   navigate_results(app, 'subj')                   — subject dropdown changed
%   navigate_results(app, 'freq')                   — freq dropdown changed
%   navigate_results(app, 'measures')               — refresh setup-tab measure buttons
%   navigate_results(app, 'after_ind_embed', mi, s) — post-embed: show ind panel
%   navigate_results(app, 'after_avg_embed', mi)    — post-embed: show avg panel
%   navigate_results(app, 'cond_tab', mi, s)        — ABR Peaks condition tab changed
%   navigate_results(app, 'filter_ind')             — apply individual freq filter
%   navigate_results(app, 'filter_avg')             — apply average freq filter
%   navigate_results(app, 'reset_dds')              — reset and re-populate FigFreqDD
%   navigate_results(app, 'exp_overlay')            — Experiments overlaid changed (redraw)
%
% Experiment overlay (private/exp_overlay.m): removed at the start of every
% action that redraws (before the EFR level overlay is rebuilt, so the axis
% limits nest) and rebuilt just before the Conditions filter, so overlaid
% objects follow the Conditions / Subjects / tracking state of the view.

% Busy state for every switch that redraws the view (subject, Average /
% Individual, measure, frequency, EFR level, OAE scale, conditions): the window is
% dimmed with a "Loading…" box and clicks wait until it closes, so it is
% clear when the view is ready. Closed automatically, also on errors.
busy = []; %#ok<NASGU>
if any(strcmp(action, {'subj','ind','avg','meas_btn','freq','efr_level','oae_toggle','cond_toggle','exp_overlay'}))
    busy = busy_start(app); %#ok<NASGU>
end
if ~any(strcmp(action, {'measures','cond_toggle','oae_toggle'}))
    try, exp_overlay(app, 'clear'); catch, end     % previous Experiment overlay off first
end
switch action
    case 'ind',             do_ind(app);
    case 'avg',             do_avg(app);
    case 'meas_btn',        do_meas_btn(app, varargin{1});
    case 'subj',            do_subj(app);
    case 'freq',            do_freq(app);
    case 'measures',        do_measures(app);
    case 'after_ind_embed', do_after_ind_embed(app, varargin{1}, varargin{2});
    case 'after_avg_embed', do_after_avg_embed(app, varargin{1});
    case 'cond_tab',        do_cond_tab(app, varargin{1}, varargin{2});
    case 'filter_ind',      do_filter_ind(app);
    case 'filter_avg',      do_filter_avg(app);
    case 'reset_dds',       do_reset_dds(app);
    case 'oae_scale'        % EPL / SPL buttons — handled by do_scale below
    case 'oae_toggle',      oae_toggle(app, varargin{1}, varargin{2}); return;
    case 'efr_level',       efr_level_toggle(app, varargin{1});   % EFR level button — do_level below
    case 'cond_toggle',     cond_filter(app, 'toggle', varargin{1}); return;   % Conditions buttons
    case 'efr_level_sync'   % after the EFR strips are built — do_level below
    case 'exp_overlay'      % Plot Settings EXPERIMENT buttons — rebuilt below
end
% Individual views parked during the run (images up to date, embed_results
% 'park'): built now that the subject is opened
if any(strcmp(action, {'subj','ind','meas_btn'})), unpark_shown(app); end
% EFR (dAM / RAM): the dropdown picks the stimulus level, in both modes
if isfield(app.res,'meas_idx') && any(app.res.meas_idx == [3 4]) && ...
        ~any(strcmp(action, {'measures'}))
    do_level(app);
end
% OAE (DPOAE / SFOAE / TEOAE): EPL / SPL buttons in the plot pick the scale view
if isfield(app.res,'meas_idx') && any(app.res.meas_idx == [5 6 7]) && ...
        ~any(strcmp(action, {'measures'}))
    do_scale(app);
end
% Other Experiments drawn into the Average view on screen (exp_overlay)
if ~strcmp(action, 'measures'), try, exp_overlay(app, 'build'); catch, end, end
% Conditions switched off (Conditions buttons) stay hidden in every view
if ~strcmp(action, 'measures'), cond_filter(app, 'apply'); end
% Plot Settings: a new view starts with its controls hidden
if any(strcmp(action, {'subj','ind','avg','meas_btn','freq','after_ind_embed','after_avg_embed'}))
    try, plot_settings(app, 'hide'); catch, end
end
% Exclude button: count / "Excluded" for the subject on screen
if ~strcmp(action, 'measures'), try, exclusions(app, 'sync'); catch, end, end
% Results theme: selected view / measure buttons, gold underline, group
% captions, and the status strip under the plots (private/res_style.m)
if ~strcmp(action, 'measures')
    try, res_style('bar_sync', app); catch, end
    try, res_style('status', app); catch, end
end
% Margins for any view laid out for the first time (fit_layout skips done panels)
if any(strcmp(action, {'subj','ind','avg','meas_btn','freq','efr_level','oae_toggle','cond_tab'}))
    try, fit_layout(cur_root(app)); catch, end
end
end


function root = cur_root(app)
%CUR_ROOT  The Results panel on screen (current subject's panel or the
%   measure's Average panel).
root = [];
m = app.res.meas_idx;
if app.res.mode == 1
    data = app.res.subj_data{m};
    si = shown_subject(app, data);
    if ~isempty(si) && isvalid(data.panels{si}), root = data.panels{si}; end
elseif isvalid(app.res.panels{2,m})
    root = app.res.panels{2,m};
end
end

function do_scale(app)
%DO_SCALE  OAE: show the scale view chosen with the EPL / SPL buttons in the
%   plot's control strip (built by embed_results>build_oae_ctrl, Tags
%   'oae_scale_epl' / 'oae_scale_spl'). Both on → the 'EPL + SPL' panel; one
%   on → that scale's panel; at least one stays on; an unavailable scale is
%   disabled (TEOAE). The choice is kept across subjects / measures
%   (app.res.oae_on). The Results-bar dropdown is not used for OAE.
m = app.res.meas_idx;
cont = [];
if app.res.mode == 1
    data = app.res.subj_data{m};
    si = shown_subject(app, data);
    if ~isempty(si) && isvalid(data.panels{si}), cont = data.panels{si}; end
else
    if isvalid(app.res.panels{2,m}), cont = app.res.panels{2,m}; end
end
app.FigFreqDD.Visible = 'off';
lbl_f = findall(app.UIFigure,'Tag','fig_freq_lbl');
if ~isempty(lbl_f), lbl_f.Visible = 'off'; end
if isempty(cont), return; end
order = {'EPL','SPL','EPL + SPL'};
lp = findobj(cont.Children, 'flat', 'Type','uipanel');
lp = lp(arrayfun(@(p) any(strcmp(p.Tag, order)), lp));
if isempty(lp), return; end
tags = arrayfun(@(p) p.Tag, lp, 'UniformOutput', false);
avail = [any(strcmp(tags,'EPL')), any(strcmp(tags,'SPL'))];
if ~isfield(app.res,'oae_on') || numel(app.res.oae_on) ~= 2, app.res.oae_on = [true true]; end
on = app.res.oae_on & avail;
if ~any(on), on = avail; end
if all(on), want = 'EPL + SPL'; elseif on(1), want = 'EPL'; else, want = 'SPL'; end
if ~any(strcmp(tags, want)), want = tags{1}; end
for k = 1:numel(lp), lp(k).Visible = ternary(strcmp(tags{k}, want), 'on', 'off'); end
% sync the EPL / SPL buttons in every view's control strip
btag = {'oae_scale_epl','oae_scale_spl'};
for k = 1:2
    for b = findall(cont, 'Tag', btag{k})'
        b.Enable = ternary(avail(k), 'on', 'off');
        b.Value  = on(k);
        res_style('seg', b, on(k));                  % subtle yellow = shown
    end
end
end


function oae_toggle(app, k, src)
%OAE_TOGGLE  EPL (k = 1) / SPL (k = 2) button in an OAE control strip.
if ~isfield(app.res,'oae_on') || numel(app.res.oae_on) ~= 2, app.res.oae_on = [true true]; end
on = app.res.oae_on;  on(k) = logical(src.Value);
if ~any(on), on(k) = true; end                       % keep at least one scale
app.res.oae_on = on;
navigate_results(app, 'oae_scale');
end


function do_level(app)
%DO_LEVEL  EFR: show the level(s) chosen with the level buttons in each
%   plot's control strip (Tag 'efr_lev_btn', embed_results>add_level_chips).
%   Several levels can be selected: they are overlaid on the same plots
%   (efr_overlay). The choice (app.res.efr_level, cell of level tags) is kept
%   across subjects / modes; default = highest level. The Results-bar
%   dropdown is not used.
m = app.res.meas_idx;
cont = [];
if app.res.mode == 1
    data = app.res.subj_data{m};
    si = shown_subject(app, data);
    if ~isempty(si) && isvalid(data.panels{si}), cont = data.panels{si}; end
else
    if isvalid(app.res.panels{2,m}), cont = app.res.panels{2,m}; end
end
app.FigFreqDD.Visible = 'off';
lbl_f = findall(app.UIFigure,'Tag','fig_freq_lbl');
if ~isempty(lbl_f), lbl_f.Visible = 'off'; end
if isempty(cont), return; end
lp = findobj(cont.Children, 'flat', 'Type','uipanel', '-regexp', 'Tag', 'dB SPL$');
if isempty(lp), return; end
tags = arrayfun(@(p) p.Tag, lp, 'UniformOutput', false);
v = inf(1, numel(tags));
for k = 1:numel(tags), x = sscanf(tags{k}, '%f'); if ~isempty(x), v(k) = x(1); end, end
[~, o] = sort(v);  lp = lp(o);  tags = tags(o);
sel = {};
if isfield(app.res,'efr_level')
    sel = app.res.efr_level;
    if ischar(sel), sel = {sel}; end
    if ~iscell(sel), sel = {}; end
end
on = ismember(tags, sel);
if ~any(on)
    vis = find(arrayfun(@(p) strcmp(p.Visible,'on'), lp), 1, 'last');   % keep what is showing
    if isempty(vis), vis = numel(tags); end                    % default: highest level
    on(vis) = true;
end
app.res.efr_level = unique([sel(:)' tags(on)'], 'stable');   % remember what is shown
% show the highest selected level; overlay the other selected levels on it
efr_overlay(app, lp, tags, on);
for b = findall(cont, 'Tag','efr_lev_btn')'
    bon = any(strcmp(tags(on), b.UserData));
    b.Value = bon;
    res_style('seg', b, bon);
end
end


function efr_overlay(app, lp, tags, on)
%EFR_OVERLAY  Show the highest selected level's panel and draw the other
%   selected levels into its plots (same axes, matched by Tag): lower levels
%   get dashed / dotted / dash-dot lines and open markers, and are shifted a
%   little on the categorical Harmonic-sums axis. A level key goes top left
%   and the title lists the levels. Everything added is removed again
%   (Tag 'efr_ovl_grp' / 'efr_lvl_key') before each redraw. Tables are not
%   overlaid (the individual table already lists every level).
for k = 1:numel(lp)                               % undo the previous overlay
    delete(findall(lp(k), 'Tag','efr_ovl_grp'));
    delete(findall(lp(k), 'Tag','efr_lvl_key'));
    for A = findall(lp(k), 'Type','axes')'
        if isappdata(A, 'efr_ylim0'), A.YLim = getappdata(A, 'efr_ylim0'); rmappdata(A, 'efr_ylim0'); end
    end
    for t = findall(lp(k), 'Type','text')'
        if isappdata(t, 'efr_title0'), t.String = getappdata(t, 'efr_title0'); rmappdata(t, 'efr_title0'); end
    end
    for g = findall(lp(k), 'Type','legend')'          % legends back to their row
        if isappdata(g, 'efr_lg_y0'), g.Position(2) = getappdata(g, 'efr_lg_y0'); rmappdata(g, 'efr_lg_y0'); end
    end
    set(lp(k), 'Units','normalized', 'Position',[0 0 1 1]);
end
sel = find(on);                                   % ascending level order
prim = sel(end);
for k = 1:numel(lp), lp(k).Visible = ternary(k == prim, 'on', 'off'); end
others = fliplr(sel(1:end-1));                    % next-highest first
if isempty(others), return; end
P = lp(prim);
set(findall(P, 'Type','legend'), 'AutoUpdate','off');
styles = {'--', ':', '-.'};
skip_tags = {'efr_table','efr_lvl_key','legend'};
for oi = 1:numel(others)
    Q  = lp(others(oi));
    ls = styles{mod(oi-1, numel(styles)) + 1};
    for A = findall(P, 'Type','axes')'
        if isempty(A.Tag) || any(strcmp(A.Tag, skip_tags)) || strcmp(A.Visible,'off'), continue; end
        B = findall(Q, 'Type','axes', 'Tag',A.Tag);
        if isempty(B), continue; end
        kids = allchild(B(1));
        keep = false(size(kids));
        for j = 1:numel(kids)
            h = kids(j);
            if isa(h,'matlab.graphics.primitive.Text') || any(strcmp(h.Tag,{'efr_xlab','apat_xgroup'})), continue; end
            if isprop(h,'YData')
                yd = double(h.YData);  if isempty(yd) || all(~isfinite(yd(:))), continue; end
            end
            keep(j) = true;
        end
        if ~any(keep), continue; end
        hg = hggroup(A, 'Tag','efr_ovl_grp', 'HandleVisibility','off', 'UserData',tags{others(oi)});
        nh = copyobj(kids(keep), hg);
        for h = nh(:)'
            if isprop(h,'LineStyle') && ~strcmp(h.LineStyle,'none'), h.LineStyle = ls; end
            if isprop(h,'MarkerFaceColor') && ~(ischar(h.MarkerFaceColor) && strcmp(h.MarkerFaceColor,'none'))
                h.MarkerFaceColor = 'w';
            end
            if any(strcmp(A.Tag,{'efr_tile','efr_tile_total'})) && isprop(h,'XData')   % categorical groups: shift a bit
                h.XData = h.XData + 0.10*oi;
            end
        end
        % make room for the overlaid data
        yy = [];
        for h = nh(:)'
            if ~isprop(h,'YData'), continue; end
            v = double(h.YData(:)');
            if isprop(h,'YNegativeDelta') && ~isempty(h.YNegativeDelta)
                v = [v, double(h.YData(:)' - h.YNegativeDelta(:)'), double(h.YData(:)' + h.YPositiveDelta(:)')]; %#ok<AGROW>
            end
            yy = [yy, v(isfinite(v))]; %#ok<AGROW>
        end
        if ~isempty(yy)
            if ~isappdata(A, 'efr_ylim0'), setappdata(A, 'efr_ylim0', A.YLim); end
            yl = A.YLim;  lo = min(yy);  hi = max(yy);
            if lo < yl(1) || hi > yl(2)
                r = max(hi, yl(2)) - min(lo, yl(1));
                A.YLim = [min(lo - 0.05*r, yl(1)), max(hi + 0.05*r, yl(2))];
            end
        end
    end
end
% title: list the levels shown
lev_txt = cellfun(@(t) strtrim(strrep(t, 'dB SPL', '')), tags(sel), 'UniformOutput', false);
for t = findall(P, 'Type','text')'
    str = t.String;
    if ischar(str) && ~isempty(regexp(str, '\d+(\.\d+)? dB SPL', 'once'))
        setappdata(t, 'efr_title0', str);
        t.String = regexprep(str, '\d+(\.\d+)? dB SPL', [strjoin(lev_txt, ' + ') ' dB SPL']);
    end
end
% level key (line style per level): bottom row, under the condition legend
% (the legends already there move up one row while the overlay is shown)
lgs = findall(P, 'Type','legend');
cx = 0.5;
if ~isempty(lgs)
    set(lgs, 'Units','normalized');
    cx = mean(arrayfun(@(g) g.Position(1) + g.Position(3)/2, lgs));
    for g = lgs(:)'
        if ~isappdata(g, 'efr_lg_y0'), setappdata(g, 'efr_lg_y0', g.Position(2)); end
        g.Position(2) = getappdata(g, 'efr_lg_y0') + 0.046;
    end
end
axK = axes(P, 'Units','normalized', 'Position',[0.06 0.005 0.6 0.01], 'Visible','off', ...
    'Tag','efr_lvl_key', 'HitTest','off');
hold(axK, 'on');
order = [prim, others];  stl = [{'-'}, styles];
hK = gobjects(1, numel(order));  L = cell(1, numel(order));
for k = 1:numel(order)
    hK(k) = plot(axK, NaN, NaN, 'Color',[0.15 0.15 0.15], 'LineWidth',2, ...
        'LineStyle',stl{mod(k-1, numel(stl)) + 1}, 'Marker','o', ...
        'MarkerFaceColor',ternary(k == 1, [0.15 0.15 0.15], [1 1 1]));
    L{k} = strrep(tags{order(k)}, ' SPL', '');
end
lg = legend(axK, hK, L, 'Orientation','horizontal', 'Box','off', 'FontSize',12, 'Location','none');
lg.Units = 'normalized';  lg.Position(1:2) = [cx - lg.Position(3)/2, 0.012];
try, subject_pick(app, 'wire'); catch, end         % overlaid subject points clickable
end


function efr_level_toggle(app, tag)
%EFR_LEVEL_TOGGLE  Add / remove one level from the EFR selection (at least
%   one level stays selected).
sel = {};
if isfield(app.res,'efr_level')
    sel = app.res.efr_level;
    if ischar(sel), sel = {sel}; end
    if ~iscell(sel), sel = {}; end
end
% only levels that exist in the current view count towards "at least one"
cur = {};
try
    btns = findall(app.ResultsTab, 'Tag','efr_lev_btn');
    cur = unique(arrayfun(@(b) b.UserData, btns, 'UniformOutput', false));
catch
end
if any(strcmp(sel, tag))
    rest = setdiff(sel, {tag});
    if isempty(cur) || any(ismember(rest, cur)), sel = rest; end
else
    sel = [sel(:)' {tag}];
end
app.res.efr_level = sel;
end


function unpark_shown(app)
%UNPARK_SHOWN  The subject chosen in the Individual view, if its view was
%   parked (embed_results>park), is embedded now.
try
    if app.res.mode ~= 1, return; end
    m = app.res.meas_idx;
    data = app.res.subj_data{m};
    subj = app.FigSubjDropdown.Value;
    si = find(strcmp(data.names, subj), 1);
    if isempty(si) || ~isvalid(data.panels{si}) || ~isappdata(data.panels{si}, 'apat_parked'), return; end
    embed_results(app, 'unpark', m, subj);
catch err
    warning('APAT:unpark', 'Could not build the view of %s: %s', app.FigSubjDropdown.Value, err.message);
end
end


% ─────────────────────────────────────────────────────────────────────
%  MODE CALLBACKS
% ─────────────────────────────────────────────────────────────────────

function do_ind(app)
app.FigIndBtn.Value = true;   app.FigAvgBtn.Value = false;
res_style('bar', app, app.FigIndBtn, true);  res_style('bar', app, app.FigAvgBtn, false);
app.FigSubjDropdown.Visible   = 'on';
if ~isempty(app.FigSubjCaption) && isvalid(app.FigSubjCaption), app.FigSubjCaption.Visible = 'on'; end
switch_panel(app, 1, app.res.meas_idx);
set_freq_visible(app, app.res.meas_idx);
subj = app.FigSubjDropdown.Value;
if ~strcmp(subj,'-')
    do_update_dds(app, app.res.meas_idx, subj);
    do_filter_ind(app);
end
end

function do_avg(app)
app.FigAvgBtn.Value = true;   app.FigIndBtn.Value = false;
res_style('bar', app, app.FigAvgBtn, true);  res_style('bar', app, app.FigIndBtn, false);
app.FigSubjDropdown.Visible   = 'off';
if ~isempty(app.FigSubjCaption) && isvalid(app.FigSubjCaption), app.FigSubjCaption.Visible = 'off'; end
switch_panel(app, 2, app.res.meas_idx);
set_freq_visible(app, app.res.meas_idx);
sync_avg_freq(app, app.res.meas_idx);
do_filter_avg(app);
end


% ─────────────────────────────────────────────────────────────────────
%  RESULTS-TAB MEASURE BUTTON
% ─────────────────────────────────────────────────────────────────────

function do_meas_btn(app, idx)
for k = 1:numel(app.res.btns)
    if isvalid(app.res.btns(k))
        set_chip(app, app.res.btns(k), k==idx);
    end
end
memr_sync(app, idx);
switch_panel(app, app.res.mode, idx);
set_freq_visible(app, idx);
refresh_subj_dd(app, idx);
do_reset_dds(app);
if app.res.mode == 1
    subj = app.FigSubjDropdown.Value;
    if ~strcmp(subj,'-'), do_update_dds(app, idx, subj); do_filter_ind(app); end
else
    sync_avg_freq(app, idx);
    do_filter_avg(app);
end
end


% ─────────────────────────────────────────────────────────────────────
%  DROPDOWN CALLBACKS
% ─────────────────────────────────────────────────────────────────────

function do_subj(app)
data = app.res.subj_data{app.res.meas_idx};
if isempty(data.names), return; end
subj = app.FigSubjDropdown.Value;
if strcmp(subj,'-'), return; end
si = find(strcmp(data.names, subj), 1);
if isempty(si), return; end
for k = 1:numel(data.panels)
    if isvalid(data.panels{k}), data.panels{k}.Visible = 'off'; end
end
if isvalid(data.panels{si}), data.panels{si}.Visible = 'on'; end
do_update_dds(app, app.res.meas_idx, subj);
do_filter_ind(app);
end

function do_freq(app)
do_filter_ind(app);
if app.res.mode == 2, do_filter_avg(app); end
end

function do_cond_tab(app, meas_idx, subject)
% Fired when the user switches tabs (frequency tabs for ABR Peaks)
do_update_dds(app, meas_idx, subject);
do_filter_ind(app);
end


% ─────────────────────────────────────────────────────────────────────
%  SETUP-TAB MEASURE BUTTON REFRESH  (replaces refreshMeasureButtons)
% ─────────────────────────────────────────────────────────────────────

function do_measures(app)
if isempty(app.h_meas_btns) || ~any(isvalid(app.h_meas_btns)), return; end
m      = app.state.measure_idx;
k      = app.state.subtype_idx;

% Measure buttons: green (white bold text) when any of its types is selected
% for the run, otherwise greyed out. The measure on screen is marked by the
% dark-gold bar on the divider (app.h_meas_marker).
% Type buttons (of the measure on screen): selected for the run = green with
% white text; not selected = greyed out. Several can be selected.
if ~isfield(app.state,'run_sel') || numel(app.state.run_sel) ~= app.n_meas
    app.state.run_sel = arrayfun(@(M) false(1, max(1, numel(M.subtypes))), app.MEASURES, 'UniformOutput', false);
end
CLR_ON   = [0.30 0.62 0.36];
CLR_OFFT = [0.45 0.45 0.45];
for mi = 1:app.n_meas
    if ~isvalid(app.h_meas_btns(mi)), continue; end
    sel = app.state.run_sel{mi};
    if any(sel)
        app.h_meas_btns(mi).BackgroundColor = CLR_ON;
        app.h_meas_btns(mi).FontColor       = [1 1 1];
    else
        app.h_meas_btns(mi).BackgroundColor = app.clr_btn;
        app.h_meas_btns(mi).FontColor       = CLR_OFFT;
    end
    app.h_meas_btns(mi).FontWeight = 'bold';
    app.h_meas_btns(mi).Text = app.MEASURES(mi).name;
    subs = app.MEASURES(mi).subtypes;  if isempty(subs), subs = {app.MEASURES(mi).name}; end
    for ki = 1:numel(app.h_sub_btns{mi})
        h = app.h_sub_btns{mi}(ki);
        if ~isgraphics(h), continue; end
        if mi == m
            h.Visible = 'on';
            if numel(sel) >= ki && sel(ki)
                h.BackgroundColor = CLR_ON;        h.FontColor = [1 1 1];
            else
                h.BackgroundColor = app.clr_btn;   h.FontColor = CLR_OFFT;
            end
            if ki <= numel(subs), h.Text = subs{ki}; end
        else
            h.Visible = 'off';
        end
    end
end

% Type buttons live in one row grid per measure (all in the same cell of
% the Measures grid): only the grid of the measure on screen is shown
for mi = 1:app.n_meas
    try
        g = app.h_sub_btns{mi}(1).Parent;
        if isa(g, 'matlab.ui.container.GridLayout'), g.Visible = ternary(mi == m, 'on', 'off'); end
    catch
    end
end

% Description (About card) — fixed position, text only
subs = app.MEASURES(m).subtypes;
if ~isempty(subs)
    app.DescTitleLabel.Text = sprintf('%s (%s): %s', app.MEASURES(m).label, app.MEASURES(m).name, subs{k});
else
    app.DescTitleLabel.Text = sprintf('%s (%s)', app.MEASURES(m).label, app.MEASURES(m).name);
end
app.DescLabel.Text = app.MEASURES(m).descriptions{k};

% Parameters are shown for the type on screen when it is selected for the
% run, or once the pointer has rested on a type button / a type was clicked
% (app.state.param_shown, set by setup_hover / SubtypeButtonPushed; cleared
% when a measure is opened). At start nothing is shown — just the hint.
is_sel = (numel(app.state.run_sel{m}) >= k && app.state.run_sel{m}(k)) || ...
         (isfield(app.state, 'param_shown') && app.state.param_shown);
has_hint = ~isempty(app.h_param_hint) && isgraphics(app.h_param_hint) && isvalid(app.h_param_hint);
if ~is_sel
    update_param_panels(app, false, false, false, false, false);
    if has_hint
        tn = app.MEASURES(m).subtypes;
        if isempty(tn), tn = {app.MEASURES(m).name}; end
        if numel(tn) == 1
            tstr = tn{1};
        elseif numel(tn) > 4
            tstr = sprintf('a %s type (%s …)', app.MEASURES(m).name, strjoin(tn(1:3), ', '));
        else
            tstr = [strjoin(tn(1:end-1), ', ') ' or ' tn{end}];
        end
        app.h_param_hint.Text    = sprintf('Point at %s above to see its parameters — click to add it to the run.', tstr);
        app.h_param_hint.Visible = 'on';
    end
else
    if has_hint, app.h_param_hint.Visible = 'off'; end
    % Show only the parameter panel for the selected measure
    is_abr  = (m==1);  is_efr = (m==2);  is_oae = (m==3);  is_memr = (m==4);
    is_peaks = is_abr && (k==2);
    update_param_panels(app, is_abr, is_efr, is_oae, is_memr, is_peaks);
    if is_abr, abr_freq_sync(app, 'load'); end        % chips show this ABR type's frequencies
end
update_summary(app);
end


% ─────────────────────────────────────────────────────────────────────
%  POST-EMBED PANEL ROUTING
% ─────────────────────────────────────────────────────────────────────

function do_after_ind_embed(app, meas_idx, subject)
% Highlight this measure's Results button
for k = 1:numel(app.res.btns)
    if isvalid(app.res.btns(k))
        set_chip(app, app.res.btns(k), k==meas_idx);
    end
end
memr_sync(app, meas_idx);
switch_panel(app, 1, meas_idx);
app.FigIndBtn.Value = true;  app.FigAvgBtn.Value = false;
res_style('bar', app, app.FigIndBtn, true);  res_style('bar', app, app.FigAvgBtn, false);
app.FigSubjDropdown.Visible   = 'on';
if ~isempty(app.FigSubjCaption) && isvalid(app.FigSubjCaption), app.FigSubjCaption.Visible = 'on'; end
% Populate subject dropdown
data = app.res.subj_data{meas_idx};
if isempty(data.names)
    app.FigSubjDropdown.Items = {'-'};
    app.FigSubjDropdown.Value = '-';
else
    app.FigSubjDropdown.Items = data.names(:)';
    if ~isempty(subject) && any(strcmp(data.names, subject))
        app.FigSubjDropdown.Value = subject;
    elseif ~any(strcmp(data.names, app.FigSubjDropdown.Value))
        app.FigSubjDropdown.Value = data.names{1};
    end
end
set_freq_visible(app, meas_idx);
if ~isempty(subject)
    do_update_dds(app, meas_idx, subject);
    do_filter_ind(app);
end
end

function do_after_avg_embed(app, meas_idx)
for k = 1:numel(app.res.btns)
    if isvalid(app.res.btns(k))
        set_chip(app, app.res.btns(k), k==meas_idx);
    end
end
memr_sync(app, meas_idx);
switch_panel(app, 2, meas_idx);
app.FigAvgBtn.Value = true;  app.FigIndBtn.Value = false;
res_style('bar', app, app.FigAvgBtn, true);  res_style('bar', app, app.FigIndBtn, false);
app.FigSubjDropdown.Visible   = 'off';
if ~isempty(app.FigSubjCaption) && isvalid(app.FigSubjCaption), app.FigSubjCaption.Visible = 'off'; end
set_freq_visible(app, meas_idx);
end


% ─────────────────────────────────────────────────────────────────────
%  FILTERING  (replaces apply_filter + apply_avg_filter)
% ─────────────────────────────────────────────────────────────────────

function do_filter_ind(app)
meas_idx = app.res.meas_idx;
data     = app.res.subj_data{meas_idx};
if isempty(data.names), return; end
subj = app.FigSubjDropdown.Value;
if strcmp(subj,'-'), return; end
si = find(strcmp(data.names, subj), 1);
if isempty(si), return; end
sp = data.panels{si};

freq_filter = get_freq_filter(app);
titled_ps   = collect_titled_panels(sp);

% Condition tabgroup (ABR Peaks multi-condition individual)
if isempty(titled_ps)
    for chk = sp.Children(:)'
        if isa(chk,'matlab.ui.container.TabGroup') && ~isempty(chk.Children)
            active = chk.SelectedTab;
            for chk2 = active.Children(:)'
                if isa(chk2,'matlab.ui.container.Panel')
                    for chk3 = chk2.Children(:)'
                        if isa(chk3,'matlab.ui.container.Panel') && ...
                                (~isempty(chk3.Tag) || ~isempty(chk3.Title))
                            titled_ps{end+1} = chk3; %#ok<AGROW>
                        end
                    end
                end
            end
        end
    end
end
if isempty(titled_ps), return; end

apply_stacked_or_grid_filter(app, titled_ps, freq_filter);
end

function do_filter_avg(app)
meas_idx    = app.res.meas_idx;
avg_panel   = app.res.panels{2, meas_idx};
if ~isvalid(avg_panel) || isempty(avg_panel.Children), return; end
sync_avg_freq(app, meas_idx);  % Restore labels after measure switch

freq_filter = get_freq_filter(app);

tg = [];
for ch = avg_panel.Children(:)'
    if isa(ch,'matlab.ui.container.TabGroup'), tg = ch; break; end
end
if isempty(tg), return; end

actual_tag = '';
for ti = 1:numel(tg.Children)
    tab = tg.Children(ti);
    tab_panel = [];
    for ch = tab.Children(:)'
        if isa(ch,'matlab.ui.container.Panel'), tab_panel = ch; break; end
    end
    if isempty(tab_panel), continue; end

    freq_panels = {};
    for ch = tab_panel.Children(:)'
        if isa(ch,'matlab.ui.container.Panel') && ~isempty(ch.Tag)
            freq_panels{end+1} = ch; %#ok<AGROW>
        end
    end
    if isempty(freq_panels), continue; end

    first_p = freq_panels{end};  % MATLAB Children are reverse creation order
    matched = false;
    for i = 1:numel(freq_panels)
        p = freq_panels{i};
        if isempty(freq_filter)
            p.Visible = ternary(p==first_p, 'on', 'off');
        else
            hits = strcmpi(p.Tag, freq_filter);
            p.Visible = ternary(hits, 'on', 'off');
            if hits, matched = true; end
        end
    end
    if ~isempty(freq_filter) && ~matched, first_p.Visible = 'on'; end
    if isempty(actual_tag)
        actual_tag = ternary(matched, freq_filter, first_p.Tag);
    end
end

if ~isempty(actual_tag) && strcmp(app.FigFreqDD.Visible,'on') && ...
        ~strcmp(app.FigFreqDD.Value, actual_tag) && ...
        any(strcmp(app.FigFreqDD.Items, actual_tag))
    app.FigFreqDD.Value = actual_tag;
end
end


% ─────────────────────────────────────────────────────────────────────
%  DROPDOWN HELPERS
% ─────────────────────────────────────────────────────────────────────

function do_reset_dds(app)
app.FigFreqDD.Items = {'—'}; app.FigFreqDD.Value = '—';
end

function do_update_dds(app, meas_idx, subject)
%DO_UPDATE_DDS  Populate FigFreqDD from embedded figure panels for this subject.
si = find(strcmp(app.res.subj_data{meas_idx}.names, subject), 1);
if isempty(si), return; end
sp = app.res.subj_data{meas_idx}.panels{si};

lbl_f = findall(app.UIFigure,'Tag','fig_freq_lbl');

titles = {};
% Direct child panels (stacked or grid)
for chk = sp.Children(:)'
    if isa(chk,'matlab.ui.container.Panel')
        lbl = chk.Tag; if isempty(lbl), lbl = chk.Title; end
        if ~isempty(lbl), titles{end+1} = lbl; end %#ok<AGROW>
    end
end
% One level deeper (scroll container)
if isempty(titles)
    for chk = sp.Children(:)'
        if isa(chk,'matlab.ui.container.Panel')
            for chk2 = chk.Children(:)'
                if isa(chk2,'matlab.ui.container.Panel')
                    lbl = chk2.Tag; if isempty(lbl), lbl = chk2.Title; end
                    if ~isempty(lbl), titles{end+1} = lbl; end %#ok<AGROW>
                end
            end
        end
    end
end
% Tabgroup: two layouts are possible.
%   Category layout (ABR Thresholds): tabs = 'ABR Waveforms','Sigmoid Fits','Summary';
%     freq_p panels inside each tab are CONDITIONS.
%     → collect from ALL non-Summary tabs; hide dropdown when Summary is active.
%   Condition layout (ABR Peaks): tabs = condition names; freq_p = frequencies.
%     → collect from the active tab only (existing behaviour).
if isempty(titles)
    cat_tab_names = {'Waveforms','Amplitudes','Latencies','ABR Waveforms','Sigmoid Fits','Summary'};
    for chk = sp.Children(:)'
        if ~isa(chk,'matlab.ui.container.TabGroup') || isempty(chk.Children), continue; end
        tab_titles = arrayfun(@(t) t.Title, chk.Children, 'UniformOutput', false);
        is_cat_tg  = any(ismember(tab_titles, cat_tab_names));

        if is_cat_tg
            % Category tabs: hide dropdown when Summary is selected
            if strcmp(chk.SelectedTab.Title, 'Summary')
                app.FigFreqDD.Visible = 'off';
                if ~isempty(lbl_f), lbl_f.Visible = 'off'; end
                return;
            end
            % Collect condition labels from ALL non-Summary tabs
            for tab = chk.Children(:)'
                if strcmp(tab.Title, 'Summary'), continue; end
                for chk2 = tab.Children(:)'
                    if isa(chk2,'matlab.ui.container.Panel')
                        for chk3 = chk2.Children(:)'
                            if isa(chk3,'matlab.ui.container.Panel')
                                lbl = chk3.Tag; if isempty(lbl), lbl = chk3.Title; end
                                if ~isempty(lbl) && ~any(strcmp(titles, lbl))
                                    titles{end+1} = lbl; %#ok<AGROW>
                                end
                            end
                        end
                    end
                end
            end
        else
            % Condition tabs (ABR Peaks): collect frequencies from active tab only
            active = chk.SelectedTab;
            for chk2 = active.Children(:)'
                if isa(chk2,'matlab.ui.container.Panel')
                    for chk3 = chk2.Children(:)'
                        if isa(chk3,'matlab.ui.container.Panel')
                            lbl = chk3.Tag; if isempty(lbl), lbl = chk3.Title; end
                            if ~isempty(lbl), titles{end+1} = lbl; end %#ok<AGROW>
                        end
                    end
                end
            end
        end
        break;  % only one tabgroup per sp
    end
end

titles = unique(titles,'stable');
if isempty(titles), return; end

% Sort to match Setup tab condition order (last path component of conds_all)
if ~isempty(app.state) && isfield(app.state,'conds_all') && ~isempty(app.state.conds_all)
    cend = cellfun(@(c) strsplit(c,filesep), app.state.conds_all, 'UniformOutput',false);
    cend = cellfun(@(c) c{end}, cend, 'UniformOutput',false);
    ordered = cend(ismember(cend, titles));
    if numel(ordered) == numel(titles)
        titles = ordered(:)';
    end
end

app.FigFreqDD.Items = titles(:)';
if ~any(strcmp(titles, app.FigFreqDD.Value)), app.FigFreqDD.Value = titles{1}; end

is_freq = any(cellfun(@(t) ~isempty(regexp(t,'\d+\s*(k?Hz|click)','once','ignorecase')), titles));
if ~isempty(lbl_f)
    lbl_f.Text    = ternary(is_freq, 'Frequency:', 'Condition:');
    lbl_f.Visible = 'on';
end
app.FigFreqDD.Visible = 'on';
end

function sync_avg_freq(app, meas_idx)
%SYNC_AVG_FREQ  Merge freq labels from avg tabgroup into FigFreqDD.
if meas_idx ~= 2 || isempty(app.res.panels), return; end
avg_panel = app.res.panels{2, meas_idx};
if ~isvalid(avg_panel), return; end

tg = [];
for ch = avg_panel.Children(:)'
    if isa(ch,'matlab.ui.container.TabGroup'), tg = ch; break; end
end
if isempty(tg), return; end

tab_freqs = {};
for ti = 1:numel(tg.Children)
    tab = tg.Children(ti);
    for ch = tab.Children(:)'
        if isa(ch,'matlab.ui.container.Panel')
            for ch2 = ch.Children(:)'
                if isa(ch2,'matlab.ui.container.Panel') && ~isempty(ch2.Tag)
                    if ~any(strcmp(tab_freqs, ch2.Tag))
                        tab_freqs{end+1} = ch2.Tag; %#ok<AGROW>
                    end
                end
            end
        end
    end
end

% Average mode: the dropdown lists frequencies (Individual mode lists
% conditions), so replace the items rather than merging them.
if ~isempty(tab_freqs)
    if ~isequal(tab_freqs, app.FigFreqDD.Items)
        cur = app.FigFreqDD.Value;
        app.FigFreqDD.Items = tab_freqs;
        if any(strcmp(tab_freqs, cur)), app.FigFreqDD.Value = cur; else, app.FigFreqDD.Value = tab_freqs{1}; end
    end
    lbl_f = findall(app.UIFigure,'Tag','fig_freq_lbl');
    if ~isempty(lbl_f), lbl_f.Text = 'Frequency:'; end
end
end

function refresh_subj_dd(app, meas_idx)
data = app.res.subj_data{meas_idx};
if isempty(data.names)
    app.FigSubjDropdown.Items = {'-'};
    app.FigSubjDropdown.Value = '-'; return;
end
items = data.names(:)';
app.FigSubjDropdown.Items = items;
if ~any(strcmp(items, app.FigSubjDropdown.Value))
    app.FigSubjDropdown.Value = items{1};
end
end


% ─────────────────────────────────────────────────────────────────────
%  LOW-LEVEL HELPERS
% ─────────────────────────────────────────────────────────────────────

function switch_panel(app, mode, meas_idx)
if ~isempty(app.res.panels)
    % Hide the previously tracked panel (may be a different measure)
    old_p = app.res.panels{app.res.mode, app.res.meas_idx};
    if isvalid(old_p), old_p.Visible = 'off'; end
    % Belt-and-suspenders: hide both ind/avg panels for the target measure
    % so stale Visible='on' from rapid back-to-back calls can't bleed through.
    for m = 1:size(app.res.panels, 1)
        p = app.res.panels{m, meas_idx};
        if isvalid(p), p.Visible = 'off'; end
    end
end
app.res.mode     = mode;
app.res.meas_idx = meas_idx;
fit_panel(app, app.res.panels{mode, meas_idx});
app.res.panels{mode, meas_idx}.Visible = 'on';
end

function fit_panel(~, ~)
%FIT_PANEL  (Kept for callers.) The Results cards fill the plot host in
%   normalized units (createComponents>buildResultsTab), so they always
%   match the window — nothing to do here.
end

function set_freq_visible(app, meas_idx)
show = meas_idx == 2;   % only ABR Peaks uses the freq dropdown
fv   = ternary(show, 'on', 'off');
app.FigFreqDD.Visible = fv;
lbl = findall(app.UIFigure,'Tag','fig_freq_lbl');
if ~isempty(lbl), lbl.Visible = fv; end
end

function freq_filter = get_freq_filter(app)
freq_filter = '';
if strcmp(app.FigFreqDD.Visible,'on') && ~strcmp(app.FigFreqDD.Value,'—')
    freq_filter = app.FigFreqDD.Value;
end
end

function apply_stacked_or_grid_filter(app, titled_ps, freq_filter)
is_stacked = numel(titled_ps) > 1 && ...
    all(cellfun(@(p) p.Position(1), titled_ps) == titled_ps{1}.Position(1)) && ...
    all(cellfun(@(p) p.Position(2), titled_ps) == titled_ps{1}.Position(2));

if is_stacked
    first_p = titled_ps{end};  % MATLAB Children are reverse creation order
    matched = false;
    for i = 1:numel(titled_ps)
        p = titled_ps{i};
        if isempty(freq_filter)
            p.Visible = ternary(p==first_p, 'on', 'off');
        else
            hits = strcmpi(p.Tag, freq_filter);
            p.Visible = ternary(hits, 'on', 'off');
            if hits, matched = true; end
        end
    end
    if ~isempty(freq_filter) && ~matched, first_p.Visible = 'on'; end
    % Sync dropdown to what is actually visible
    if strcmp(app.FigFreqDD.Visible,'on')
        actual = ternary(matched, freq_filter, first_p.Tag);
        if ~isempty(actual) && any(strcmp(app.FigFreqDD.Items, actual)) && ...
                ~strcmp(app.FigFreqDD.Value, actual)
            app.FigFreqDD.Value = actual;
        end
    end
else
    % Grid: show all or filter by tag/title.
    % freq_p panels from embed_categorized_tabs use Tag=label, Title=''.
    % Older grid panels (2-col scrollable) use Title=label, Tag=''.
    % Always prefer Tag when non-empty so both layouts are handled.
    for i = 1:numel(titled_ps)
        p = titled_ps{i};
        if isempty(freq_filter)
            p.Visible = 'on';
        else
            lbl = p.Tag; if isempty(lbl), lbl = p.Title; end
            p.Visible = ternary(strcmpi(lbl, freq_filter), 'on', 'off');
        end
    end
end
end

function titled_ps = collect_titled_panels(sp)
titled_ps = {};
for chk = sp.Children(:)'
    if isa(chk,'matlab.ui.container.Panel') && (~isempty(chk.Tag) || ~isempty(chk.Title))
        titled_ps{end+1} = chk; %#ok<AGROW>
    end
end
if isempty(titled_ps)
    for chk = sp.Children(:)'
        if isa(chk,'matlab.ui.container.Panel')
            for chk2 = chk.Children(:)'
                if isa(chk2,'matlab.ui.container.Panel') && ...
                        (~isempty(chk2.Tag) || ~isempty(chk2.Title))
                    titled_ps{end+1} = chk2; %#ok<AGROW>
                end
            end
        end
    end
end
end

function update_param_panels(app, is_abr, is_efr, is_oae, is_memr, is_peaks)
% Panels are created at their final positions; only visibility changes here
% (so AutoResizeChildren keeps them correct after window resizes).
if ~isempty(app.h_abr_param_panel) && isvalid(app.h_abr_param_panel)
    app.h_abr_param_panel.Visible = ternary(is_abr, 'on', 'off');
    lev_vis = ternary(is_peaks, 'on', 'off');
    h = findall(app.h_abr_param_panel,'Tag','abr_wave_lbl');
    set(h, 'Visible', lev_vis);
    for wi = 1:numel(app.h_abr_wave_checks)
        if isvalid(app.h_abr_wave_checks(wi))
            app.h_abr_wave_checks(wi).Visible = lev_vis;
        end
    end
end
if ~isempty(app.h_efr_param_panel) && isvalid(app.h_efr_param_panel)
    app.h_efr_param_panel.Visible = ternary(is_efr, 'on', 'off');
    ram_vis = ternary(is_efr && (app.state.subtype_idx==2), 'on', 'off');
    dam_vis = ternary(is_efr && (app.state.subtype_idx==1), 'on', 'off');
    for tag = {'efr_ram_hdr','efr_ram_info','efr_harm_lbl','efr_win_lbl', ...
               'efr_win_s_lbl','efr_win_e_lbl','efr_harmonics','efr_win_start','efr_win_end', ...
               'efr_low_lbl','efr_low_from','efr_low_dash','efr_low_to', ...
               'efr_high_lbl','efr_high_from','efr_high_dash','efr_high_to', ...
               'efr_sum_lbl','efr_sum_dd','efr_norm_lbl','efr_norm_btn','efr_ram_note'}
        h = findall(app.h_efr_param_panel,'Tag',tag{1});
        set(h, 'Visible', ram_vis);
    end
    for tag = {'efr_dam_hdr','efr_dam_info','efr_dam_lbl','efr_dam_bands','efr_dam_note'}
        h = findall(app.h_efr_param_panel,'Tag',tag{1});
        set(h, 'Visible', dam_vis);
    end
    for fld = {'h_efr_harmonics_field','h_efr_window_start_field','h_efr_window_end_field'}
        if ~isempty(app.(fld{1})) && isvalid(app.(fld{1}))
            app.(fld{1}).Visible = ram_vis;
        end
    end
end
if ~isempty(app.h_oae_param_panel) && isvalid(app.h_oae_param_panel)
    app.h_oae_param_panel.Visible = ternary(is_oae, 'on', 'off');
    % analysis block of the selected subtype only (Tag or UserData = group)
    grp = {'oae_dp','oae_sf','oae_te'};
    for gi = 1:3
        vis = ternary(is_oae && app.state.subtype_idx == gi, 'on', 'off');
        for h = findall(app.h_oae_param_panel)'
            if h == app.h_oae_param_panel, continue; end
            ud = '';  try, ud = h.UserData; catch, end
            if strcmp(h.Tag, grp{gi}) || (ischar(ud) && strcmp(ud, grp{gi}))
                h.Visible = vis;
            end
        end
    end
end
if ~isempty(app.h_memr_param_panel) && isvalid(app.h_memr_param_panel)
    app.h_memr_param_panel.Visible = ternary(is_memr, 'on', 'off');
    is_art = is_memr && app.state.subtype_idx == 1;           % ART text / exploratory text
    set(findall(app.h_memr_param_panel, 'Tag','memr_art'), 'Visible', ternary(is_art, 'on', 'off'));
    set(findall(app.h_memr_param_panel, 'Tag','memr_mx'),  'Visible', ternary(is_memr && ~is_art, 'on', 'off'));
end
% Parameter panels are grids of rows (createComponents>buildParamPanels):
% blocks of other types share a cell, so hide every grid with nothing
% visible, and collapse rows that hold nothing visible
for P = {app.h_abr_param_panel, app.h_efr_param_panel, app.h_oae_param_panel, app.h_memr_param_panel}
    if ~isempty(P{1}) && isvalid(P{1}) && vis_on(P{1}), grid_sync(P{1}); end
end
end


function grid_sync(root)
%GRID_SYNC  Under ROOT: every uigridlayout whose children are all hidden is
%   hidden (deepest first, so blocks of other types sharing a cell never
%   paint over the visible one); in the panels' row grids (appdata
%   'apat_rows' = design row heights) rows without anything visible get
%   height 0. Silent.
try
    G = findall(root, 'Type','uigridlayout');
    if isempty(G), return; end
    d = zeros(numel(G), 1);
    for i = 1:numel(G)
        p = G(i).Parent;
        while ~isempty(p) && isgraphics(p) && ~isequal(p, root)
            d(i) = d(i) + 1;  p = p.Parent;
        end
    end
    [~, o] = sort(d, 'descend');
    for i = o(:)'
        g = G(i);
        k = g.Children;
        on = false(numel(k), 1);
        for j = 1:numel(k), on(j) = vis_on(k(j)); end
        if isappdata(g, 'apat_rows')
            rh = getappdata(g, 'apat_rows');
            used = false(1, numel(rh));
            for j = 1:numel(k)
                try
                    r = k(j).Layout.Row;
                    if on(j) && all(r <= numel(rh)), used(r) = true; end
                catch
                end
            end
            rh(~used) = {0};
            g.RowHeight = [rh, {'1x'}];
        else
            if vis_on(g) ~= any(on), g.Visible = ternary(any(on), 'on', 'off'); end
        end
    end
catch
end
end


function tf = vis_on(h)
%VIS_ON  Visible property as logical (char or OnOffSwitchState).
tf = false;
try
    v = h.Visible;
    if ischar(v) || isstring(v), tf = strcmp(v, 'on'); else, tf = logical(v); end
catch
end
end


function memr_sync(app, idx)
%MEMR_SYNC  Results bar MEMR group: one visible button + a dropdown. When a
%   MEMR analysis (label 8 = ART, 9-15 = exploratory) is on screen, the
%   button shows its name, opens it, and is highlighted; the dropdown shows
%   the same analysis. Other measures leave the last MEMR choice in place.
try
    if ~isfield(app.res, 'memr_dd') || ~isvalid(app.res.memr_dd), return; end
    b = app.res.btns(8);
    if ~isvalid(b), return; end
    if idx >= 8 && idx <= numel(app.res.btns)
        L = APAT_app.measure_tab_labels();
        nm = strrep(L{idx}, 'MEMR ', '');  if strcmp(nm, 'MEMR'), nm = 'ART'; end
        b.Text = nm;  b.UserData = idx;
        res_style('icon', b, idx);
        set_chip(app, b, true);
        if ~isequal(app.res.memr_dd.Value, idx), app.res.memr_dd.Value = idx; end
    end
catch
end
end


function set_chip(app, btn, on)
%SET_CHIP  Selected Results measure button = subtle yellow (same as the
%   Average / Individual buttons), otherwise neutral (private/res_style.m).
if ~isvalid(btn), return; end
res_style('bar', app, btn, on);                 % subtle yellow, dark bold text
end
