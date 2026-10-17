function relayout_results(app, action)
%RELAYOUT_RESULTS  Work left after a window resize (Oct 16 2026: layout
%   managers). The Setup and Data Status tabs are uigridlayout trees and the
%   Results cards use normalized units, so MATLAB resizes them by itself;
%   the header / tab group follow at once (createComponents>fig_layout).
%   What is left runs here, once, 0.25 s after the last size change:
%     1. peak editor overlay: its pixel layout scaled to the panel's size
%        (scale_tree, from appdata 'apat_p0' at scale 1; 'apat_pe_size' =
%        build size, 'apat_pe_scale' = current scale);
%     2. a new layout epoch + plot margins of the Results view on screen
%        (fit_layout; other views are refitted when next shown);
%     3. Results bar column widths (bar_fit) and an open Plot Settings
%        panel kept inside the plot area (plot_settings 'clamp').
%   relayout_results(app, 'changed') — debounce (timer APAT_relayout)
%   relayout_results(app)            — the work itself
%   relayout_results(app, 'peak')    — step 1 only (after the peak editor
%                                      axes are rebuilt, RunButtonPushed)
if nargin < 2, action = 'refit'; end
try
    if ~isvalid(app) || ~isvalid(app.UIFigure), return; end
catch
    return;
end
fig = app.UIFigure;
switch action
    case 'changed'
        if ~isappdata(fig, 'apat_design_size'), return; end    % still building
        try
            t = timerfind('Name','APAT_relayout');
            if isempty(t)
                me = @relayout_results;                % handle now (callback runs from outside)
                t = timer('Name','APAT_relayout', 'StartDelay',0.25, 'ExecutionMode','singleShot', ...
                    'BusyMode','drop', 'TimerFcn',@(~,~) me(app));
            end
            t = t(1);
            stop(t);  start(t);
        catch
            relayout_results(app);                     % no timer: do it now
        end
    case 'peak'
        peak_scale(app);
    otherwise
        peak_scale(app);
        try                                            % plot margins for the new size
            e = 0;
            if isappdata(fig, 'apat_layout_epoch'), e = getappdata(fig, 'apat_layout_epoch'); end
            setappdata(fig, 'apat_layout_epoch', e + 1);
            root = [];
            m = app.res.meas_idx;
            if app.res.mode == 1
                data = app.res.subj_data{m};
                si = shown_subject(app, data);
                if ~isempty(si) && isvalid(data.panels{si}), root = data.panels{si}; end
            elseif isvalid(app.res.panels{2,m})
                root = app.res.panels{2,m};
            end
            if ~isempty(root), fit_layout(root); end
        catch
        end
        try, bar_fit(app); catch, end
        try, plot_settings(app, 'clamp'); catch, end
end
end


function peak_scale(app)
%PEAK_SCALE  Scale the peak editor's pixel layout to the panel's size.
try
    P = app.PeakEditPanel;
    if isempty(P) || ~isgraphics(P) || ~isappdata(P, 'apat_pe_size'), return; end
    D  = getappdata(P, 'apat_pe_size');
    s0 = [1 1];
    if isappdata(P, 'apat_pe_scale'), s0 = getappdata(P, 'apat_pe_scale'); end
    pp = P.Position;
    s1 = max([0.35 0.35], pp(3:4) ./ D);
    if ~any(abs(s1 - s0) > 1e-3), return; end
    scale_tree(P, s0, s1);
    setappdata(P, 'apat_pe_scale', s1);
catch
end
end


function scale_tree(h, s0, s1)
%SCALE_TREE  Scale every pixel-unit component under H (not inside axes).
S0 = [s0 s0];  S1 = [s1 s1];
kids = allchild(h);
for c = kids(:)'
    try
        typ = get(c, 'Type');
        is_ax = any(strcmp(typ, {'axes','uiaxes','polaraxes','geoaxes'}));
        movable = isprop(c, 'Position') && ...
            ~any(strcmp(typ, {'uitab','uimenu','uicontextmenu','text','figure','line', ...
            'patch','scatter','errorbar','surface','image','hggroup','uigridlayout'}));
        px = true;                                     % uibutton, uilabel … have no Units (always pixels)
        if isprop(c, 'Units'), px = strcmp(get(c, 'Units'), 'pixels'); end
        if movable && px
            if isappdata(c, 'apat_p0')
                p0 = getappdata(c, 'apat_p0');
            else
                p0 = double(get(c, 'Position')) ./ S0;  % made at the current scale
                setappdata(c, 'apat_p0', p0);
            end
            set(c, 'Position', p0 .* S1);
        end
        if ~is_ax && ~strcmp(typ, 'legend') && ~strcmp(typ, 'uigridlayout')
            scale_tree(c, s0, s1);                     % containers: their children too
        end
    catch
    end
end
end
