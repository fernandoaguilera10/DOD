function setup_hover(app, evt)
%SETUP_HOVER  UIFigure WindowButtonMotionFcn (via createComponents>hover_cb).
%   On the Setup tab, resting the pointer on a measure button (ABR, EFR,
%   OAE, MEMR) shows its types, and on a type button (Thresholds, DPOAE,
%   ART …) shows that type's parameters and Analysis Insight — no click
%   needed. What is shown stays until the pointer reaches another measure /
%   type button. The run selection is not changed: one click on a type adds
%   it to the run (green), another click removes it.
%   The button under the pointer is found from the event's HitObject when
%   MATLAB provides it, else from the pointer position and the button
%   rectangles (cached; re-read after a window resize, which bumps appdata
%   'apat_layout_epoch'; buttons in grids: Position + the content origins
%   of the containers above, uigridlayout included). Errors are left to
%   hover_cb (reported once).
persistent busy
if ~isempty(busy) && busy, return; end
if ~isvalid(app) || app.TabGroup.SelectedTab ~= app.SetupTab, return; end
busy = true;
try
    do_hover(app, evt);
catch ME
    busy = false;  rethrow(ME);
end
busy = false;
% (no onCleanup + nested function here: its destructor could run after the
%  workspace was gone and warn "already-destroyed variable 'busy'")
end


function do_hover(app, evt)
[m, k] = from_hit(app, evt);
if isempty(m)
    pt = app.UIFigure.CurrentPoint;
    R = rects(app);                                % [x y w h m k], k = 0: measure button
    if isempty(R), return; end
    on = R(:,6) == 0 | R(:,5) == app.state.measure_idx;   % type buttons: measure on screen only
    hit = find(on & pt(1) >= R(:,1) & pt(1) <= R(:,1) + R(:,3) & ...
                    pt(2) >= R(:,2) & pt(2) <= R(:,2) + R(:,4), 1);
    if isempty(hit), return; end
    m = R(hit,5);  k = R(hit,6);
end
shown = isfield(app.state, 'param_shown') && app.state.param_shown;
if k == 0                                          % measure button: show its types
    if app.state.measure_idx == m, return; end
    k = find(app.state.run_sel{m}, 1);  if isempty(k), k = 1; end
    app.state.param_shown = false;                 % parameters only for a selected type
else                                               % type button: show its parameters
    if app.state.measure_idx == m && app.state.subtype_idx == k && shown, return; end
    app.state.param_shown = true;
end
app.state.measure_idx = m;
app.state.subtype_idx = k;
navigate_results(app, 'measures');
end


function [m, k] = from_hit(app, evt)
% measure / type button under the pointer from the event (or its parent chain)
m = [];  k = [];
if nargin < 2 || isempty(evt) || ~isprop(evt, 'HitObject'), return; end
h = evt.HitObject;
for depth = 1:4
    if isempty(h) || ~isgraphics(h), return; end
    mi = find(app.h_meas_btns == h, 1);
    if ~isempty(mi), m = mi;  k = 0;  return; end
    for mm = 1:numel(app.h_sub_btns)
        ki = find(app.h_sub_btns{mm} == h, 1);
        if ~isempty(ki)
            if mm == app.state.measure_idx, m = mm;  k = ki; end
            return
        end
    end
    h = h.Parent;
end
end


function R = rects(app)
fig = app.UIFigure;
ep = 0;  if isappdata(fig, 'apat_layout_epoch'), ep = getappdata(fig, 'apat_layout_epoch'); end
key = [ep, fig.Position];
if isappdata(fig, 'apat_hover_rects')
    c = getappdata(fig, 'apat_hover_rects');
    if isequal(c.key, key), R = c.R; return; end
end
% buttons sit in grids (uigridlayout): each one's Position is relative to
% its grid, so add up the content origins of every container above it
R = zeros(0, 6);
for m = 1:numel(app.h_meas_btns)
    b = app.h_meas_btns(m);
    if isgraphics(b), R(end+1, :) = [inner_origin(b.Parent) + b.Position(1:2) - 1, b.Position(3:4), m, 0]; end %#ok<AGROW>
    if numel(app.h_sub_btns) >= m
        for k = 1:numel(app.h_sub_btns{m})
            b = app.h_sub_btns{m}(k);
            if isgraphics(b), R(end+1, :) = [inner_origin(b.Parent) + b.Position(1:2) - 1, b.Position(3:4), m, k]; end %#ok<AGROW>
        end
    end
end
setappdata(fig, 'apat_hover_rects', struct('key',key, 'R',R));
end


function o = inner_origin(p)
% lower-left corner (figure pixels) of the content area of a container:
% add up the content offsets of every container up to the figure
o = [0 0];
while ~isempty(p) && isgraphics(p) && ~isa(p, 'matlab.ui.Figure')
    if isprop(p, 'InnerPosition')
        ip = p.InnerPosition;                      % content area, in its parent's coordinates
    else
        ip = p.Position;                           % e.g. uitab: Position = its content area
    end
    if isa(p, 'matlab.ui.container.Tab')
        ip = p.Position;
    end
    o = o + ip(1:2) - 1;
    p = p.Parent;
end
o = o + 1;
end
