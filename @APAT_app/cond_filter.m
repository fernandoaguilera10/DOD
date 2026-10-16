function out = cond_filter(app, action, varargin)
%COND_FILTER  Show / hide conditions in every Results plot (all measures).
%
%   cond_filter(app, 'apply')                     — apply the ON/OFF state to all plots
%   cond_filter(app, 'refresh')                   — same, after another control (Subjects,
%                                                   Sweep …) changed visibility: keeps that
%                                                   new visibility for when the condition returns
%   cond_filter(app, 'set_vis', H, 'on'|'off')    — another control (Subjects, Sweep …)
%                                                   shows / hides objects H: objects hidden
%                                                   by a condition that is OFF only get their
%                                                   remembered visibility updated (shown when
%                                                   the condition is back ON), others change now
%   cond_filter(app, 'toggle', k)                 — flip condition k (at least one stays on)
%   y = cond_filter(app, 'chips', cp, host, x, y, w, rh, gap)
%                                                 — "Conditions" buttons in a control strip
%
%   Conditions are recognised by their plot colour (the colours chosen on the
%   Setup tab, as used in the last run — app.res.run_conds). Lines, error
%   bars, scatter points and patches drawn in a condition's colour are hidden
%   when it is OFF and restored to their previous visibility when it is ON.
%   Reference lines (2-point black/grey dashed lines), legend helper axes
%   and the tracked-subject highlight are left alone. Buttons: Tag
%   'cond_chip', UserData = condition index; ON = filled with the condition
%   colour (white / black text by luminance), OFF = pale (70 % to white), grey text.
out = [];
switch action
    case 'apply'
        apply_filter(app, false);
    case 'refresh'
        apply_filter(app, true);
    case 'toggle'
        k  = varargin{1};
        on = cond_state(app);
        if k >= 1 && k <= numel(on)
            on(k) = ~on(k);
            if ~any(on), on(k) = true; end           % keep at least one condition
            app.res.cond_on = on;
            app.res.cond_used = true;
        end
        apply_filter(app, false);
    case 'set_vis'
        H = varargin{1};  v = varargin{2};
        for h = H(:)'
            if ~isvalid(h), continue; end
            if isappdata(h, 'cond_hid')
                setappdata(h, 'cond_hid', v);         % stays hidden until its condition is ON
            else
                h.Visible = v;
            end
        end
        apply_filter(app, true);
    case 'chips'
        out = add_chips(app, varargin{:});
end
end


% ── state ──────────────────────────────────────────────────────────────
function [names, rgb] = cond_list(app)
names = {};  rgb = zeros(0,3);
cc = [];
if isfield(app.res, 'run_conds'), cc = app.res.run_conds; end
if isempty(cc) || ~isstruct(cc)
    try, cc = struct('paths',{app.state.conds_all}, 'rgb',app.state.cond_colors); catch, end
end
if isempty(cc) || ~isfield(cc,'paths'), return; end
p = cc.paths;  if ischar(p), p = {p}; end
n = min(numel(p), size(cc.rgb,1));
names = cell(1, n);
for k = 1:n
    parts = strsplit(p{k}, {'/','\'});  names{k} = parts{end};
end
rgb = double(cc.rgb(1:n, 1:3));
end

function on = cond_state(app)
[names, ~] = cond_list(app);
on = true(1, numel(names));
if isfield(app.res, 'cond_on') && numel(app.res.cond_on) == numel(names)
    on = logical(app.res.cond_on(:)');
end
app.res.cond_on = on;
end


% ── colour → condition ─────────────────────────────────────────────────
function k = match_cond(h, rgb)
k = 0;
if isempty(rgb), return; end
try
    if any(strcmp(h.Tag, {'subj_pick_hl','abr_wf_sb','abr_wf_sbT'})), return; end
    ax = ancestor(h, 'axes');
    if isempty(ax) || strcmp(ax.Visible, 'off'), return; end   % legend helper axes
    c = [];
    if isappdata(h, 'apat_cond_rgb'), c = double(getappdata(h, 'apat_cond_rgb')); c = c(1:3);
    elseif isprop(h, 'UserData') && isstruct(h.UserData) && isfield(h.UserData, 'apat_cond_rgb')
        c = double(h.UserData.apat_cond_rgb);  c = c(1:3);
    elseif isprop(h, 'LineStyle') && strcmp(h.LineStyle, 'none') && isprop(h, 'Marker') && ~strcmp(h.Marker, 'none')
        % marker-only line (band means, hollow below-criterion points): its
        % Color is the default colour order, the condition is in the marker
        if isnumeric(h.MarkerEdgeColor) && numel(h.MarkerEdgeColor) == 3
            c = double(h.MarkerEdgeColor);
        elseif isnumeric(h.MarkerFaceColor) && numel(h.MarkerFaceColor) == 3
            c = double(h.MarkerFaceColor);
        else
            c = double(h.Color(1:3));
        end
    elseif isprop(h, 'CData') && isnumeric(h.CData) && numel(h.CData) == 3
        c = double(h.CData(:)');
    elseif isprop(h, 'Color') && isnumeric(h.Color) && numel(h.Color) >= 3
        c = double(h.Color(1:3));
    elseif isprop(h, 'FaceColor') && isnumeric(h.FaceColor) && numel(h.FaceColor) == 3
        c = double(h.FaceColor);
    end
    if isempty(c), return; end
    % reference lines: black / grey, dashed, two points (zero lines, dividers)
    if isprop(h, 'LineStyle') && isprop(h, 'XData') && numel(h.XData) <= 2 && ...
            ~strcmp(h.LineStyle, '-') && max(c) - min(c) < 0.02
        return;
    end
    d = max(abs(rgb - c), [], 2);
    [dm, k] = min(d);
    if dm > 0.02, k = 0; end
catch
    k = 0;
end
end

function H = candidates(root)
H = [findall(root, 'Type','line'); findall(root, 'Type','errorbar'); ...
     findall(root, 'Type','scatter'); findall(root, 'Type','patch'); findall(root, 'Type','area')];
end


% ── apply ──────────────────────────────────────────────────────────────
function apply_filter(app, recapture)
if ~isvalid(app) || ~isprop(app, 'ResultsTab') || ~isvalid(app.ResultsTab), return; end
[~, rgb] = cond_list(app);
on = cond_state(app);
if all(on) && ~any_hidden(app), return; end   % nothing switched off yet: nothing to do
root = view_root(app);                          % only the view on screen (fast);
for h = candidates(root)'                       % other views are done when shown
    k = match_cond(h, rgb);
    if k == 0, continue; end
    hidden = isappdata(h, 'cond_hid');
    if ~on(k) && hidden && recapture && strcmp(h.Visible, 'on')
        % another control just showed it (without set_vis): remember 'on',
        % hide it again. A hidden object is never re-read as 'off' here —
        % that 'off' is the condition's own hiding, and storing it lost the
        % means / legend markers when the condition came back ON.
        setappdata(h, 'cond_hid', 'on');
        h.Visible = 'off';
    elseif ~on(k) && ~hidden
        setappdata(h, 'cond_hid', h.Visible);
        h.Visible = 'off';
    elseif on(k) && hidden
        h.Visible = getappdata(h, 'cond_hid');
        rmappdata(h, 'cond_hid');
    end
end
sync_chips(root, rgb, on);
end

function sync_chips(root, rgb, on)
for b = findall(root, 'Tag','cond_chip')'
    k = b.UserData;
    if ~isnumeric(k) || k < 1 || k > numel(on), continue; end
    b.Value = on(k);
    style_chip(b, rgb(k,:), on(k));
end
end

function style_chip(b, c, on)
%STYLE_CHIP  Results theme (Oct 16, 2nd pass): the button itself takes the
%   condition colour (BackgroundColor), text = marker symbol + name in white
%   or black (whichever contrasts more); OFF = the colour 70 % towards white
%   with grey text. No frame panel (an old one from appdata chip_frame is
%   deleted).
try
    if isappdata(b, 'chip_frame')
        fr = getappdata(b, 'chip_frame');
        try, if ~isempty(fr) && isvalid(fr), delete(fr); end, catch, end
        rmappdata(b, 'chip_frame');
    end
    mk = char(9679);  if isappdata(b, 'chip_marker'), mk = getappdata(b, 'chip_marker'); end
    nm = b.Tooltip;
    if isappdata(b, 'chip_name'), nm = getappdata(b, 'chip_name'); end
    c = double(c(1:3));
    if on
        b.BackgroundColor = c;  b.FontColor = ink_on(c);
    else
        b.BackgroundColor = 0.30*c + 0.70*[1 1 1];  b.FontColor = [0.45 0.45 0.45];
    end
    try, if isprop(b, 'Interpreter'), b.Interpreter = 'none'; end, catch, end
    b.Text = [mk ' ' nm];
    b.FontWeight = 'bold';
catch
    try
        if on, b.BackgroundColor = c; else, b.BackgroundColor = 0.30*c + 0.70*[1 1 1]; end
    catch
    end
end
end

function k = ink_on(c)
%INK_ON  White or black text on colour C: the one with the higher WCAG
%   contrast ratio (relative luminance of sRGB C).
lin = c;  lo = c <= 0.04045;
lin(lo) = c(lo) / 12.92;  lin(~lo) = ((c(~lo) + 0.055) / 1.055) .^ 2.4;
L = 0.2126*lin(1) + 0.7152*lin(2) + 0.0722*lin(3);
if (1.05 / (L + 0.05)) >= ((L + 0.05) / 0.05), k = [1 1 1]; else, k = [0.08 0.08 0.08]; end
end

function mk = cond_marker(app, k)
%COND_MARKER  Symbol of condition k's plot marker: app.state.cond_markers
%   (marker codes per condition) if present, else the shapes analysis_run
%   uses (v, square, diamond, ^, o, >, pentagram, *, x — by condition order).
code = '';
try
    M = [];
    if isfield(app.res, 'run_conds') && isstruct(app.res.run_conds)
        for f = {'markers','shapes'}
            if isfield(app.res.run_conds, f{1}), M = app.res.run_conds.(f{1}); break; end
        end
    end
    if isempty(M) && isfield(app.state, 'cond_markers'), M = app.state.cond_markers; end
    if isstring(M), M = cellstr(M); end
    if iscell(M) && numel(M) >= k
        code = char(M{k});
    elseif ischar(M) && size(M,1) >= k
        code = strtrim(M(k,:));
    end
catch
end
if isempty(code)
    shp = {'v','square','diamond','^','o','>','pentagram','*','x'};
    code = shp{mod(k-1, numel(shp)) + 1};
end
mk = res_style('marker', code);
if isempty(mk), mk = char(9679); end
end


% ── buttons in a control strip ─────────────────────────────────────────
function y = add_chips(app, cp, host, x, y, w, rh, gap)
% "Conditions" label, then one button per condition drawn in HOST
% (2 per row across the strip width). Returns the y for the next row.
[names, rgb] = cond_list(app);
if isempty(names), return; end
present = false(1, numel(names));
for h = candidates(host)'
    k = match_cond(h, rgb);
    if k > 0, present(k) = true; end
end
idx = find(present);
if numel(idx) < 2, return; end                    % nothing to choose between
on = cond_state(app);
uilabel(cp, 'Text','Conditions', 'FontSize',13, 'FontWeight','bold', ...
    'FontColor',[0.15 0.15 0.15], 'Position',[x y w rh]);
cg = 6;  per = 2;  cw = floor((w - (per-1)*cg) / per);  bh = rh - 2;
for j = 1:numel(idx)
    k = idx(j);  col = mod(j-1, per);
    if col == 0, y = y - bh - 4; end
    bx = x + col*(cw+cg);
    b = uibutton(cp, 'state', 'Text',names{k}, 'Value',on(k), 'FontSize',12, 'FontWeight','bold', ...
        'Tag','cond_chip', 'UserData',k, 'Position',[bx, y, cw, bh], ...
        'Tooltip',sprintf('Show / hide %s in every plot', names{k}), ...
        'ValueChangedFcn',@(~,~) navigate_results(app, 'cond_toggle', k));
    setappdata(b, 'chip_name', names{k});
    setappdata(b, 'chip_marker', cond_marker(app, k));
    style_chip(b, rgb(k,:), on(k));
end
y = y - rh - gap;
end


function root = view_root(app)
%VIEW_ROOT  The Results panel on screen: the current subject's panel
%   (Individual) or the measure's Average panel; whole tab as fallback.
root = app.ResultsTab;
try
    m = app.res.meas_idx;
    if app.res.mode == 1
        data = app.res.subj_data{m};
        si = shown_subject(app, data);
        if ~isempty(si) && isvalid(data.panels{si}), root = data.panels{si}; end
    else
        p = app.res.panels{2, m};
        if isvalid(p), root = p; end
    end
catch
end
end

function tf = any_hidden(app)
%ANY_HIDDEN  True once any condition has been switched off this session
%   (so objects may still carry the 'cond_hid' mark and need restoring).
tf = isfield(app.res, 'cond_used') && app.res.cond_used;
end

