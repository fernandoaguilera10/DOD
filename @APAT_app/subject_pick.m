function subject_pick(app, action, src)
%SUBJECT_PICK  Click an individual-subject point in any Results plot to see
%   which subject it is and highlight that subject everywhere in APAT
%   (ABR Thresholds average, ABR Peaks Amplitudes / Latencies / Waveforms,
%   EFR dAM / RAM averages, OAE averages, every tab). The selection stays active while you switch
%   measures and is re-applied to figures embedded later.
%
%   subject_pick(app, 'wire')        — make all subject points clickable
%   subject_pick(app, 'click', h)    — point clicked (toggle that subject)
%   subject_pick(app, 'clear')       — clear the selection
%   subject_pick(app, 'open')        — open the subject's Individual results
%   subject_pick(app, 'color')       — choose the highlight colour (name chip);
%                                      kept with setpref('APAT','pick_color')
%
%   The selected subject's points are shown in their condition colour at
%   full strength and joined per condition by a solid line in that colour
%   (Tag 'subj_pick_hl'); other subjects fade and the condition averages are
%   dimmed (still visible for reference). The tracking colour is used for the
%   name chip in the Results bar.
%   Subject points carry Tag 'thr_subj_pts' / 'abr_subj_pts' and the
%   subject ID in DisplayName (set by the plotting functions).
if nargin < 3, src = []; end
if ~isfield(app.res, 'sel_subj'), app.res.sel_subj = ''; end
busy = []; %#ok<NASGU>
switch action                                    % "Loading…" popup while it redraws
    case 'click', busy = busy_start(app, 'Highlighting subject — please wait…'); %#ok<NASGU>
    case 'clear', busy = busy_start(app, 'Clearing selection — please wait…'); %#ok<NASGU>
    case 'open',  busy = busy_start(app, 'Opening subject — please wait…'); %#ok<NASGU>
end
switch action
    case 'wire'
        for h = all_pts(app)'
            h.ButtonDownFcn = @(o,~) subject_pick(app, 'click', o);
            h.PickableParts = 'visible';
            h.HitTest = 'on';
            try                                  % hover tooltip: Subject row
                n = numel(h.XData);
                rows = h.DataTipTemplate.DataTipRows;
                if any(arrayfun(@(r) strcmp(r.Label,'Subject'), rows)), continue; end
                h.DataTipTemplate.DataTipRows(end+1) = ...
                    dataTipTextRow('Subject', repmat({h.DisplayName}, 1, n));
            catch
            end
        end
        apply_sel(app, []);
    case 'click'
        if isempty(src) || ~isvalid(src), return; end
        nm = src.DisplayName;
        if isempty(nm), return; end
        if strcmp(nm, app.res.sel_subj)
            app.res.sel_subj = '';               % second click on same subject = clear
        else
            app.res.sel_subj = nm;
        end
        apply_sel(app, src);
    case 'clear'
        app.res.sel_subj = '';
        apply_sel(app, []);
    case 'color'
        c0 = pick_color(app);
        try
            c = uisetcolor(c0, 'Tracked subject colour');
        catch
            c = 0;
        end
        try, figure(app.UIFigure); catch, end          % bring APAT back to the front
        if isnumeric(c) && numel(c) == 3
            app.res.pick_color = c;
            try, setpref('APAT', 'pick_color', c); catch, end
            recolor(app, c);
        end
    case 'open'
        nm = app.res.sel_subj;
        if isempty(nm), return; end
        mi = app.res.meas_idx;
        data = app.res.subj_data{mi};
        if ~any(strcmp(data.names, nm))
            % fall back to any measure that has this subject analysed
            mi = find(cellfun(@(d) any(strcmp(d.names, nm)), app.res.subj_data), 1);
            if isempty(mi)
                uialert(app.UIFigure, sprintf('No individual results for %s yet.', nm), 'Subject');
                return;
            end
            navigate_results(app, 'meas_btn', mi);
        end
        navigate_results(app, 'ind');
        app.FigSubjDropdown.Items = app.res.subj_data{mi}.names(:)';
        app.FigSubjDropdown.Value = nm;
        navigate_results(app, 'subj');
end
end


% ── helpers ────────────────────────────────────────────────────────────

function H = all_pts(app)
H = [findall(app.ResultsTab, 'Tag','thr_subj_pts'); findall(app.ResultsTab, 'Tag','abr_subj_pts'); ...
     findall(app.ResultsTab, 'Tag','efr_subj_pts'); findall(app.ResultsTab, 'Tag','oae_subj_pts'); ...
     findall(app.ResultsTab, 'Tag','memr_subj_pts')];
H = H(arrayfun(@(h) isprop(h,'SizeData'), H));
end

function apply_sel(app, clicked) %#ok<INUSD>
% Selected subject: its own points in their CONDITION colour at full
% strength, joined per condition by a solid line in that colour (no ring);
% everyone else fades, and the condition averages (mean ± SD markers / lines)
% are dimmed so they stay visible as a reference.
HL = pick_color(app);                                % tracking colour (name chip only)
nm = app.res.sel_subj;
delete(findall(app.ResultsTab, 'Tag','subj_pick_lbl'));
delete(findall(app.ResultsTab, 'Tag','subj_pick_hl'));
P = all_pts(app);
for h = P'
    o = getappdata(h, 'pick_orig');
    if isempty(o)
        o = struct('SizeData',h.SizeData, 'MarkerFaceAlpha',h.MarkerFaceAlpha, ...
            'MarkerEdgeAlpha',h.MarkerEdgeAlpha, 'MarkerEdgeColor',h.MarkerEdgeColor, ...
            'LineWidth',h.LineWidth);
        setappdata(h, 'pick_orig', o);
    end
    if isempty(nm)                                   % restore
        set(h, 'SizeData',o.SizeData, 'MarkerFaceAlpha',o.MarkerFaceAlpha, ...
            'MarkerEdgeAlpha',o.MarkerEdgeAlpha, 'MarkerEdgeColor',o.MarkerEdgeColor, ...
            'LineWidth',o.LineWidth);
    elseif strcmp(h.DisplayName, nm)                 % selected subject: full colour
        set(h, 'SizeData',o.SizeData*1.3, 'MarkerFaceAlpha',1, 'MarkerEdgeAlpha',1, ...
            'MarkerEdgeColor',[1 1 1], 'LineWidth',0.75);
        if isappdata(h, 'apat_excluded')             % excluded (✕): keep its colour
            set(h, 'MarkerEdgeColor',o.MarkerEdgeColor, 'LineWidth',2.2);
        end
        add_highlight(h);
        try, uistack(h, 'top'); catch, end
    else                                             % everyone else fades
        set(h, 'SizeData',o.SizeData, 'MarkerFaceAlpha',0.06, 'MarkerEdgeAlpha',0.06, ...
            'MarkerEdgeColor',o.MarkerEdgeColor, 'LineWidth',o.LineWidth);
    end
end
% dim / restore the averages in every axes that holds subject points
axs = unique(arrayfun(@(h) ancestor(h,'axes'), P));
for a = axs(:)'
    dim_averages(a, ~isempty(nm));
end
% Control-bar chip
if isfield(app.res, 'pick_ui') && all(isvalid(app.res.pick_ui))
    u = app.res.pick_ui;     % [caption, name label, open button, ✕ clear button, chip backdrop]
    if isempty(nm)
        set(u, 'Visible','off');
    else
        u(2).Text = nm;      % subtle-yellow chip, dark bold text (Results theme; not the tracking colour)
        if numel(u) < 5, style_chip(u(2), HL); end
        set(u, 'Visible','on');
    end
    try, bar_fit(app); catch, end                % Tracking columns of the Results bar (0 when hidden)
end
end


function dim_averages(ax, on)
%DIM_AVERAGES  Condition means (errorbars, mean lines) faded towards white
%   while a subject is tracked (on), restored otherwise. Reference lines
%   (black / grey), x-group bands, legend items and subject points are left
%   alone. Original colours kept in appdata 'pick_dim0'.
if isempty(ax) || ~isvalid(ax), return; end
skip = {'subj_pick_hl','apat_xgroup','apat_leg_item','thr_subj_pts','abr_subj_pts', ...
        'efr_subj_pts','oae_subj_pts','memr_subj_pts','oae_raw','oae_nf','abr_wf_sb','abr_wf_sbT'};
W = 0.72;                                            % how far towards white
for h = [findall(ax,'Type','errorbar'); findall(ax,'Type','line')]'
    try
        if any(strcmp(h.Tag, skip)), continue; end
        if numel(h.XData) > 400, continue; end      % spectra / sweeps: already faint (translucent)
        c = double(h.Color(1:3));
        if max(c) - min(c) < 0.02 && ~strcmp(h.Type,'errorbar') && numel(h.XData) <= 2
            continue;                                % black / grey reference line
        end
        o = getappdata(h, 'pick_dim0');
        if on
            if isempty(o)
                o = struct('Color',h.Color, 'MFC',h.MarkerFaceColor, 'MEC',h.MarkerEdgeColor);
                setappdata(h, 'pick_dim0', o);
            end
            h.Color = lighten(o.Color(1:3), W);
            if isnumeric(o.MFC), h.MarkerFaceColor = lighten(o.MFC, W); end
            if isnumeric(o.MEC), h.MarkerEdgeColor = lighten(o.MEC, W); end
        elseif ~isempty(o)
            h.Color = o.Color;  h.MarkerFaceColor = o.MFC;  h.MarkerEdgeColor = o.MEC;
            rmappdata(h, 'pick_dim0');
        end
    catch
    end
end
end


function c = lighten(c, w)
c = double(c(1:3));  c = c + (1 - c) * w;
end


function add_highlight(h)
%ADD_HIGHLIGHT  Solid line in the subject point's own (condition) colour
%   joining that subject's points of one condition in this plot (Tag
%   'subj_pick_hl'; not clickable; follows the points' visibility and their
%   waterfall level via UserData).
ax = ancestor(h, 'axes');
if isempty(ax), return; end
x = double(h.XData(:)');  y = double(h.YData(:)');
ok = isfinite(x) & isfinite(y);  x = x(ok);  y = y(ok);
if numel(x) < 2, return; end
c = h.CData;
if ~(isnumeric(c) && numel(c) == 3), c = [0.3 0.3 0.3]; end
hold(ax, 'on');
[xs, o] = sort(x);
ln = plot(ax, xs, y(o), '-', 'Color',c(:)', 'LineWidth',2.2, 'HandleVisibility','off', ...
    'HitTest','off', 'PickableParts','none', 'Tag','subj_pick_hl', 'Visible',h.Visible);
if isnumeric(h.UserData) && isscalar(h.UserData), ln.UserData = h.UserData; end
try, uistack(ln, 'top'); uistack(h, 'top'); catch, end
try
    addlistener(h, 'Visible', 'PostSet', @(~,~) sync_vis(h, ln));
catch
end
end


function sync_vis(h, hl)
if ~isvalid(h), return; end
hl = hl(isvalid(hl));
if ~isempty(hl), set(hl, 'Visible', h.Visible); end
end


function c = pick_color(app)
%PICK_COLOR  Highlight colour: this session's choice, else the saved one,
%   else magenta.
c = [0.86 0.10 0.62];
if isfield(app.res, 'pick_color') && isnumeric(app.res.pick_color) && numel(app.res.pick_color) == 3
    c = app.res.pick_color;  return;
end
try
    if ispref('APAT', 'pick_color')
        v = getpref('APAT', 'pick_color');
        if isnumeric(v) && numel(v) == 3, c = v(:)'; end
    end
catch
end
app.res.pick_color = c;
end


function style_chip(b, c)
%STYLE_CHIP  Name chip in the highlight colour, readable text.
if ~isvalid(b), return; end
b.BackgroundColor = c;
if 0.299*c(1) + 0.587*c(2) + 0.114*c(3) > 0.6, b.FontColor = [0 0 0]; else, b.FontColor = [1 1 1]; end
end


function recolor(app, c)
%RECOLOR  Apply a new highlight colour to everything already drawn.
% (tracked points / lines keep their condition colours; only the chip changes)
set(findall(app.ResultsTab, 'Tag','subj_pick_lbl'), 'Color', c);
if isfield(app.res, 'pick_ui') && numel(app.res.pick_ui) >= 2 && numel(app.res.pick_ui) < 5 && isvalid(app.res.pick_ui(2))
    style_chip(app.res.pick_ui(2), c);           % old chip only (the themed chip stays subtle yellow)
end
end

