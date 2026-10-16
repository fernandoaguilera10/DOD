function relayout_results(app, action)
%RELAYOUT_RESULTS  Proportional layout when the APAT window is resized.
%   relayout_results(app, 'changed') — UIFigure SizeChangedFcn. Debounced:
%       the relayout runs once, 0.25 s after the last size change (not on
%       every step of a drag).
%   relayout_results(app)            — the relayout itself:
%       1. every UI component with pixel units (panels, buttons, labels,
%          fields, tab groups, uiaxes …, also those added later by the
%          Results tab) is scaled from its layout position by the window's
%          size relative to the size the app was built for — smaller AND
%          larger (MATLAB's own AutoResizeChildren never shrinks below the
%          starting size, which clipped the window). Font sizes are kept.
%       2. bar_fit re-anchors the Results bar (right groups to the right
%          edge, left groups compressed so nothing is clipped);
%       3. a new layout epoch starts and the Results view on screen gets
%          its plot margins refitted (fit_layout); other views are refitted
%          when they are next shown; an open Plot Settings panel is
%          re-clamped into the plot area (plot_settings 'clamp').
%   Layout positions: appdata 'apat_p0' on each component, stored at scale
%   1 the first time it is seen (components made after a resize were made
%   at the current scale, appdata 'apat_cur_scale' on the UIFigure).
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
        try, fig.Pointer = 'watch'; catch, end             % busy pointer while dragging
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
    otherwise
        try
            D  = getappdata(fig, 'apat_design_size');
            s0 = [1 1];
            if isappdata(fig, 'apat_cur_scale'), s0 = getappdata(fig, 'apat_cur_scale'); end
            p  = fig.Position;
            s1 = max([0.35 0.35], p(3:4) ./ D);        % keep things usable on tiny windows
            if ~any(abs(s1 - s0) > 1e-3), try, fig.Pointer = 'arrow'; catch, end, end
            if any(abs(s1 - s0) > 1e-3)
                % "Resizing…" box while the layout is rebuilt (closes itself
                % when this function returns; shared with other busy boxes)
                busy = busy_start(app, 'Resizing the window — please wait…'); %#ok<NASGU>
                scale_tree(fig, s0, s1);
                setappdata(fig, 'apat_cur_scale', s1);
            end
        catch
        end
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
        % Results bar: Tracking group + Save / Plot Settings buttons right-
        % anchored, left content compressed if needed (overrides the
        % proportional positions); open Plot Settings panel kept inside
        try, bar_fit(app); catch, end
        try, plot_settings(app, 'clamp'); catch, end
end
end


function scale_tree(h, s0, s1)
%SCALE_TREE  Scale every pixel-unit component under H (not inside axes).
S0 = [s0 s0];  S1 = [s1 s1];
kids = allchild(h);
for c = kids(:)'
    try
        if isprop(c, 'AutoResizeChildren') && strcmp(c.AutoResizeChildren, 'on')
            c.AutoResizeChildren = 'off';              % one scaling rule: ours
        end
        typ = get(c, 'Type');
        is_ax = any(strcmp(typ, {'axes','uiaxes','polaraxes','geoaxes'}));
        movable = isprop(c, 'Position') && ...
            ~any(strcmp(typ, {'uitab','uimenu','uicontextmenu','text','figure','line', ...
            'patch','scatter','errorbar','surface','image','hggroup'}));
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
        if ~is_ax && ~strcmp(typ, 'legend')
            scale_tree(c, s0, s1);                     % containers: their children too
        end
    catch
    end
end
end
