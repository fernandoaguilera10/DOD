function plot_settings(app, action, varargin)
%PLOT_SETTINGS  "Plot Settings" button: the view controls of every Results
%   plot (Conditions ON/OFF, Subjects, Shading, axis limits, levels, EPL/SPL,
%   Growth Response y …) are hidden by default so the figures use the full
%   width; the button shows them as a floating panel over the right of the
%   plots (gold border) and hides them again.
%
%   plot_settings(app, 'toggle')        button pressed: show / hide for the view on screen
%   plot_settings(app, 'stash', root)   after embedding: hide the strips under root
%   plot_settings(app, 'hide')          view changed: hide all, button back to "Plot Settings"
%   plot_settings(app, 'sync')          button enabled only when the view has settings
%   plot_settings(app, 'clamp')         window relayout: re-place the open panel(s)
%
%   Placement (place_panel): the open strip floats at the right of its host,
%   sized to its controls and clamped to the host's current inner size (it was
%   left at its embed position past the axes, so on narrower windows only a
%   sliver showed at the right edge). Taller / wider than the host → the
%   panel scrolls (Scrollable 'on'). Done when shown and after each relayout.
%
%   The strips are the uipanels built by embed_results (Tag 'apat_ctrl' /
%   'apat_ctrl_slot'); they stay where they are in the hierarchy, so every
%   control keeps working, and fit_layout no longer reserves space for them.
%
%   Experiment row (several Experiments in the run, private/res_exp.m): the
%   floating panel starts with "EXPERIMENT" and one button per Experiment
%   (on screen = subtle yellow); a click shows that Experiment's views and
%   keeps the panel open. Rebuilt on every show (exp_row, Tag apat_ps_exp),
%   placed by place_panel between the header and the controls. A view
%   without controls gets an empty strip (appdata apat_exp_only) so the row
%   is reachable everywhere.
%   Average views: the buttons toggle (several on = overlaid on the same
%   plots, private/exp_overlay.m; the first selected = the base view whose
%   panels are shown; at least one stays on). Individual views: one
%   Experiment at a time (subjects differ per Experiment).
switch action
    case 'toggle'
        root = cur_root(app);
        S = strips(root);
        if isempty(S) && multi_exp(app) && ~isempty(root)
            S = exp_only_strip(root);
        end
        if isempty(S), sync_btn(app); return; end
        on = ~(isfield(app.res,'ps_on') && app.res.ps_on);
        show(app, S, on);
        app.res.ps_on = on;
        sync_btn(app);
    case 'stash'
        S = strips(varargin{1});
        if ~isempty(S), set(S, 'Visible','off'); end
        if isfield(app.res,'ps_on') && app.res.ps_on, show(app, S, true); end   % panel open: keep it open
    case 'hide'
        S = strips(app.ResultsTab);
        if ~isempty(S), set(S, 'Visible','off'); end
        app.res.ps_on = false;
        sync_btn(app);
    case 'sync'
        sync_btn(app);
    case 'clamp'
        try
            if ~(isfield(app.res,'ps_on') && app.res.ps_on), return; end
            S = strips(cur_root(app));
            for k = 1:numel(S)
                if strcmp(S(k).Visible, 'on'), place_panel(S(k)); end
            end
        catch
        end
end
end


function S = strips(root)
S = gobjects(0);
if isempty(root) || ~isvalid(root), return; end
S = [findall(root, 'Type','uipanel', 'Tag','apat_ctrl'); findall(root, 'Type','uipanel', 'Tag','apat_ctrl_slot')];
end

function show(app, S, on)
if isempty(S), return; end
if on
    for s = S(:)'
        try
            T = res_style('theme', app);
            set(s, 'Visible','on', 'BorderType','line', 'BorderWidth',2);
            try, s.BorderColor = T.ink; catch, s.HighlightColor = T.ink; end
            try, s.BackgroundColor = T.ps_body; catch, end
            if strcmp(s.Tag, 'apat_ctrl'), make_head(app, s, T); end
            exp_row(app, s, T);
            uistack(s, 'top');
            place_panel(s);
        catch
        end
    end
else
    set(S, 'Visible','off');
end
end

function place_panel(s)
%PLACE_PANEL  Float strip S fully inside its parent (see header). Silent.
try
    host = s.Parent;
    hp = getpixelposition(host);  hw = hp(3);  hh = hp(4);
    if hw < 40 || hh < 40, return; end
    old_u = s.Units;
    s.Units = 'normalized';
    p = s.Position;
    if ~isappdata(s, 'apat_ps_top0'), setappdata(s, 'apat_ps_top0', min(1, p(2) + p(4))); end
    % content extent (children are pixel-positioned inside the strip)
    K = allchild(s);  B = zeros(0, 4);
    hd = findobj(K, 'flat', 'Tag','apat_ps_head');      % cartridge header: placed on top below
    er = findobj(K, 'flat', 'Tag','apat_ps_exp');       % Experiment row: under the header
    K = K(~ismember(K, [hd; er]));
    for k = K(:)'
        try
            if isprop(k,'Units') && ~strcmp(k.Units,'pixels'), continue; end
            if strcmp(k.Visible,'off'), continue; end
            B(end+1,:) = double(k.Position); %#ok<AGROW>
        catch
        end
    end
    if isempty(B) && isempty(er), s.Units = old_u; return; end
    if isempty(B), B = [8 0 202 0]; end        % strip holding only the Experiment row
    % trim empty margins left / below the controls (shift them once)
    lx = min(B(:,1));  by = min(B(:,2));
    dx = max(0, lx - 8);  dy = max(0, by - 6);
    if dx > 0 || dy > 0
        for k = K(:)'
            try
                if isprop(k,'Units') && ~strcmp(k.Units,'pixels'), continue; end
                k.Position(1:2) = k.Position(1:2) - [dx dy];
                if isappdata(k, 'apat_p0'), rmappdata(k, 'apat_p0'); end   % re-read at the next resize
            catch
            end
        end
        B(:,1) = B(:,1) - dx;  B(:,2) = B(:,2) - dy;
    end
    cw = max(B(:,1) + B(:,3)) + 10;            % content size (px)
    ch = max(B(:,2) + B(:,4)) + 6;
    HD = 0;  if ~isempty(hd), HD = 30; end     % header strip height
    c_top = ch;                                % header (and Experiment row) sit above the controls
    if ~isempty(hd) || ~isempty(er), cw = max(cw, 210); end
    ER = 0;
    if strcmp(s.Tag, 'apat_ctrl')
        w = min(cw + 4, hw - 8);
        if ~isempty(er), ER = exp_layout(er(1), w - 4); end
        ch = ch + ER + HD + 4;  cw = cw + 4;   % + Experiment row, header, the 2 px border
        h = min(ch, hh - 8);
        top = min(hh - 4, getappdata(s, 'apat_ps_top0') * hh);
        y = max(4, top - h);
        x = max(4, hw - w - 6);                % right of the plot area
    else                                       % 'apat_ctrl_slot' (ABR Peaks empty tile): keep the slot, clamp it
        if ~isappdata(s, 'apat_ps_slot0'), setappdata(s, 'apat_ps_slot0', p); end
        p0 = getappdata(s, 'apat_ps_slot0');   % slot as built (the row is added on top of it)
        x = p0(1)*hw;  y = p0(2)*hh;  w = p0(3)*hw;  h = p0(4)*hh;
        w = min(w, hw - 8);
        if ~isempty(er), ER = exp_layout(er(1), w - 4);  h = h + ER;  y = y - ER; end
        h = min(h, hh - 8);
        x = min(max(4, x), hw - w - 4);  y = min(max(4, y), hh - h - 4);
        c_top = h - ER - 4;                    % row at the top of the slot
        ch = ch + ER + 4;  cw = cw + 4;
    end
    s.Position = [x/hw y/hh w/hw h/hh];
    if ~isempty(er), er(1).Position = [0 c_top max(60, w - 4) ER]; end
    if ~isempty(hd), place_head(hd(1), c_top + ER, w - 4, HD); end
    big = cw > w + 1 || ch > h + 1;
    try
        if big, s.Scrollable = 'on'; else, s.Scrollable = 'off'; end
        if big, scroll(s, 'top'); end
    catch
    end
catch
end
end

function sync_btn(app)
try, save_view(app, 'sync'); catch, end          % Save Image / Save As New: enabled when the view has plots
if ~isfield(app.res,'ps_btn') || isempty(app.res.ps_btn) || ~isvalid(app.res.ps_btn), return; end
b = app.res.ps_btn;
has = ~isempty(strips(cur_root(app))) || multi_exp(app);   % Experiment row always reachable
on  = has && isfield(app.res,'ps_on') && app.res.ps_on;
b.Enable = onoff(has);
T = res_style('theme', app);                    % gold button, dark bold text (both states)
if on, b.Text = 'Hide Plot Settings'; else, b.Text = 'Plot Settings'; end
b.BackgroundColor = T.gold;  b.FontColor = T.ink;  b.FontWeight = 'bold';
try, res_style('status', app); catch, end        % status strip follows the view on screen
end


function make_head(app, s, T)
%MAKE_HEAD  Cartridge header of a floating strip (once): black strip with a
%   small gold "P" tag, "Plot Settings" in cream bold and a close ✕.
%   Tag 'apat_ps_head'; positioned by place_head (place_panel).
try
    if ~isempty(findobj(allchild(s), 'flat', 'Tag','apat_ps_head')), return; end
    hd = uipanel(s, 'BorderType','none', 'BackgroundColor',T.ink, 'Tag','apat_ps_head', ...
        'Units','pixels', 'Position',[0 0 210 30]);
    uilabel(hd, 'Text','P', 'FontSize',10, 'FontWeight','bold', 'FontName',T.mono, ...
        'FontColor',T.ink, 'BackgroundColor',T.gold, 'HorizontalAlignment','center', ...
        'Tag','apat_ps_tag', 'Position',[10 8 16 15]);
    uilabel(hd, 'Text','Plot Settings', 'FontSize',13, 'FontWeight','bold', ...
        'FontColor',T.cream, 'Tag','apat_ps_title', 'Position',[34 5 150 20]);
    uibutton(hd, 'push', 'Text',char(10005), 'FontSize',11, 'FontWeight','bold', ...
        'BackgroundColor',[0.23 0.23 0.23], 'FontColor',T.cream, 'Tag','apat_ps_close', ...
        'Tooltip','Close Plot Settings (Esc)', 'Position',[180 4 22 22], ...
        'ButtonPushedFcn',@(~,~) ps_close(app));
catch
end
end

function place_head(hd, y, w, H)
%PLACE_HEAD  Header across the strip's inner width, above the controls.
try
    hd.Position = [0 y max(60, w) H];
    c = findobj(allchild(hd), 'flat', 'Tag','apat_ps_close');
    if ~isempty(c), c(1).Position = [max(40, w - 30) 4 22 22]; end
    t = findobj(allchild(hd), 'flat', 'Tag','apat_ps_title');
    if ~isempty(t), t(1).Position = [34 5 max(40, w - 74) 20]; end
    for h = [hd; allchild(hd)]'
        if isappdata(h, 'apat_p0'), rmappdata(h, 'apat_p0'); end   % placed here, not scaled by relayout
    end
catch
end
end

function ps_close(app)
%PS_CLOSE  Header ✕: same as "Hide Plot Settings". Silent.
try, plot_settings(app, 'hide'); catch, end
end

function root = cur_root(app)
% Results panel on screen (current subject's panel or the Average panel)
root = [];
try
    m = app.res.meas_idx;
    if app.res.mode == 1
        data = app.res.subj_data{m};
        si = shown_subject(app, data);
        if ~isempty(si) && isvalid(data.panels{si}), root = data.panels{si}; end
    elseif isvalid(app.res.panels{2,m})
        root = app.res.panels{2,m};
    end
    if isempty(root) && isvalid(app.res.panels{app.res.mode, m})   % no subject yet: the host
        root = app.res.panels{app.res.mode, m};
    end
catch
end
end


% ── Experiment row ───────────────────────────────────────────────────────
function tf = multi_exp(app)
tf = false;
try, tf = numel(res_exp(app, 'list')) > 1; catch, end
end

function S = exp_only_strip(root)
%EXP_ONLY_STRIP  Empty strip (Experiment row only) for a view without controls.
S = findobj(allchild(root), 'flat', 'Type','uipanel', 'Tag','apat_ctrl');
if ~isempty(S), return; end
try
    S = uipanel(root, 'Units','normalized', 'Position',[0.80 0.70 0.18 0.27], ...
        'BorderType','none', 'BackgroundColor','white', 'Tag','apat_ctrl', 'Visible','off');
    setappdata(S, 'apat_exp_only', true);
catch
    S = gobjects(0);
end
end

function exp_row(app, s, T)
%EXP_ROW  (Re)build the "EXPERIMENT" row of strip S (several Experiments only).
try
    delete(findobj(allchild(s), 'flat', 'Tag','apat_ps_exp'));
    names = res_exp(app, 'list');
    if numel(names) < 2, return; end
    on_scr = '';  try, on_scr = char(app.res.run_sheet); catch, end
    ind = isfield(app.res, 'mode') && app.res.mode == 1;
    shown = {on_scr};
    if ~ind, try, shown = exp_overlay(app, 'names'); catch, end, end
    busy = isappdata(app.UIFigure, 'apat_running') && isequal(getappdata(app.UIFigure, 'apat_running'), true);
    er = uipanel(s, 'BorderType','none', 'BackgroundColor',T.ps_body, 'Tag','apat_ps_exp', ...
        'Units','pixels', 'Position',[0 0 210 60]);
    uilabel(er, 'Text','EXPERIMENT', 'FontSize',10, 'FontWeight','bold', 'FontName',T.mono, ...
        'FontColor',T.cap, 'Tag','apat_ps_exp_cap', 'Position',[10 0 180 16]);
    uipanel(er, 'BorderType','none', 'BackgroundColor',T.gold_line, 'Tag','apat_ps_exp_rule', ...
        'Position',[8 0 190 1]);
    for i = 1:numel(names)
        sel = any(strcmp(shown, names{i}));
        if sel, bg = T.seg_on; else, bg = T.seg_off; end
        if ind
            tip = sprintf(['Individual view: subjects differ per Experiment, so one Experiment ' ...
                'at a time — click to list the subjects of %s'], names{i});
        elseif strcmp(names{i}, on_scr)
            tip = sprintf(['%s is the base view (first selected); click to remove it — the next ' ...
                'selected Experiment becomes the base. At least one stays on.'], names{i});
        elseif sel
            tip = sprintf('%s is overlaid (dashed lines, open markers) — click to remove it', names{i});
        else
            tip = sprintf('Overlay %s on these plots (dashed lines, open markers)', names{i});
        end
        if busy, tip = 'Available when the analysis has finished'; end
        uibutton(er, 'push', 'Text',names{i}, 'FontSize',12, 'FontWeight','bold', ...
            'BackgroundColor',bg, 'FontColor',T.ink, 'UserData',names{i}, ...
            'Tag','apat_ps_exp_btn', 'Tooltip',tip, 'Enable',onoff(~busy), ...
            'Position',[10 0 80 26], 'ButtonPushedFcn',@(o,~) exp_pick(app, o.UserData));
    end
catch
end
end

function H = exp_layout(er, w)
%EXP_LAYOUT  Caption on top, buttons in rows across width W (wrapping), a
%   thin rule under them. Returns the row's height (px).
H = 0;
try
    B = findobj(allchild(er), 'flat', 'Tag','apat_ps_exp_btn');
    B = flipud(B(:));                              % creation order
    BH = 26;  G = 6;  X0 = 10;  CAP = 18;
    wb = arrayfun(@(b) max(64, 9*numel(char(b.Text)) + 28), B);
    xr = max(X0 + 64, w - 8);
    row = 1;  x = X0;  rx = zeros(size(B));  rr = zeros(size(B));
    for i = 1:numel(B)
        wb(i) = min(wb(i), xr - X0);
        if x > X0 && x + wb(i) > xr, row = row + 1;  x = X0; end
        rx(i) = x;  rr(i) = row;  x = x + wb(i) + G;
    end
    nR = max(1, row);
    H = CAP + nR*(BH + 4) + 8;
    for i = 1:numel(B)
        B(i).Position = [rx(i), H - CAP - rr(i)*(BH + 4), wb(i), BH];
    end
    c = findobj(allchild(er), 'flat', 'Tag','apat_ps_exp_cap');
    if ~isempty(c), c(1).Position = [X0 H - CAP + 1 max(60, w - 20) 16]; end
    r = findobj(allchild(er), 'flat', 'Tag','apat_ps_exp_rule');
    if ~isempty(r), r(1).Position = [8 3 max(20, w - 16) 1]; end
    for h = [er; allchild(er)]'
        if isappdata(h, 'apat_p0'), rmappdata(h, 'apat_p0'); end   % placed here, not scaled by relayout
    end
catch
end
end

function exp_pick(app, name)
%EXP_PICK  Experiment button: show that Experiment's views, panel stays open. Silent.
try
    was = isfield(app.res,'ps_on') && app.res.ps_on;
    exp_overlay(app, 'pick', name);                % Average: toggle overlay; Individual: switch
    if was                                         % re-open: the row shows the new selection
        plot_settings(app, 'hide');  plot_settings(app, 'toggle');
    end
catch
end
end

function s = onoff(tf)
if tf, s = 'on'; else, s = 'off'; end
end
