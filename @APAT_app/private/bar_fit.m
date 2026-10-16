function bar_fit(app)
%BAR_FIT  Keep the Results top bar and the buttons over the plot area inside
%   the window at any width.
%   Runs once after the Results tab is built (scale 1) and after every
%   window relayout (relayout_results, after the proportional scaling).
%     - TRACKING group (caption, chip backdrop + name, ✕, Individual) right-anchored
%       to the bar's right edge; its widths never go below 80 % of design.
%     - Everything left of it (View, Subject, Exclude, measure buttons,
%       Frequency) is compressed horizontally when it would reach the
%       Tracking group (the design layout is wider than ~2000 px, so on a
%       1920 px screen the Tracking group was past the window edge).
%     - Plot Settings / Save Image / Save As New / save message right-
%       anchored to the plot area's right edge (widths ≥ 85 % of design).
%   Design positions (scale 1, before any compression) are kept in appdata
%   'apat_bar0' on each component; this function owns their x / width (the
%   proportional scaling in relayout_results is overridden here). Silent:
%   never throws.
try
    if ~isvalid(app) || ~isfield(app.res, 'pick_ui'), return; end
    fig  = app.UIFigure;
    ctrl = app.FigAvgBtn.Parent;
    if ~isvalid(ctrl), return; end
    s = [1 1];
    if isappdata(fig, 'apat_cur_scale'), s = getappdata(fig, 'apat_cur_scale'); end
    sx = s(1);  sy = s(2);
    W  = ctrl.Position(3);
    if W < 50, return; end

    kids = allchild(ctrl);
    pk   = app.res.pick_ui;
    pk   = pk(isvalid(pk));
    is_pk = false(size(kids));
    for i = 1:numel(kids)
        try
            if ~isappdata(kids(i), 'apat_bar0')
                setappdata(kids(i), 'apat_bar0', double(kids(i).Position) ./ [sx sy sx sy]);
            end
        catch
        end
        is_pk(i) = any(kids(i) == pk);
    end

    % ── Tracking group, right-anchored ─────────────────────────────────
    m  = max(sx, 0.8);
    R  = W - max(6, 20*sx);                     % right edge of the group
    xt = R;
    if ~isempty(pk)
        B = cell2mat(arrayfun(@(h) getappdata(h,'apat_bar0'), pk(:), 'UniformOutput', false));
        bx0 = min(B(:,1));
        ext = max(B(:,1) + B(:,3) .* ~is_caption(pk(:))) - bx0;   % caption width does not count
        xt  = R - ext*m;
        for i = 1:numel(pk)
            b = B(i,:);
            x = xt + (b(1) - bx0)*m;
            w = b(3)*m;
            if is_caption(pk(i)), w = max(20, min(w, R - x)); end
            try, pk(i).Position = [x b(2)*sy w b(4)*sy]; catch, end
        end
    end

    % ── Left content, compressed if it would reach the Tracking group ──
    L = kids(~is_pk);
    P = zeros(numel(L), 4);  keep = true(numel(L), 1);
    for i = 1:numel(L)
        try
            b = getappdata(L(i), 'apat_bar0');
            if b(3) >= 0.9 * W / sx                % gold rule under the bar: full width
                L(i).Position = [0 b(2)*sy W max(1, b(4)*sy)];
                keep(i) = false;  continue
            end
            P(i,:) = b .* [sx sy sx sy];
        catch
            keep(i) = false;
        end
    end
    L = L(keep);  P = P(keep,:);
    if ~isempty(L)
        right = P(:,1) + P(:,3);
        right(is_caption(L(:))) = P(is_caption(L(:)),1) + 30;   % captions: text only
        avail = xt - max(8, 16*sx);
        f = 1;
        if max(right) > avail, f = max(0.45, avail / max(right)); end
        for i = 1:numel(L)
            try, L(i).Position = [P(i,1)*f P(i,2) P(i,3)*f P(i,4)]; catch, end
        end
    end

    % ── Buttons over the plot area, right-anchored ─────────────────────
    mb = max(sx, 0.85);
    xr = W - max(6, 20*sx);
    for f2 = {'ps_btn','save_btn','savenew_btn'}
        if ~isfield(app.res, f2{1}), continue; end
        h = app.res.(f2{1});
        if isempty(h) || ~isvalid(h), continue; end
        if ~isappdata(h, 'apat_bar0'), setappdata(h, 'apat_bar0', double(h.Position) ./ [sx sy sx sy]); end
        b = getappdata(h, 'apat_bar0');
        w = b(3)*mb;
        h.Position = [xr - w, b(2)*sy, w, b(4)*sy];
        xr = xr - w - max(4, 8*sx);
    end
    if isfield(app.res, 'save_msg') && isvalid(app.res.save_msg)
        h = app.res.save_msg;
        if ~isappdata(h, 'apat_bar0'), setappdata(h, 'apat_bar0', double(h.Position) ./ [sx sy sx sy]); end
        b = getappdata(h, 'apat_bar0');
        w = min(b(3), W - 40);
        h.Position = [W - max(6, 20*sx) - w, b(2)*sy, w, b(4)*sy];
    end
    % gold underline follows the measure button on screen (res_style)
    res_style('underline', app);
catch
end
end


function tf = is_caption(H)
%IS_CAPTION  Small-caps caption labels above the bar groups (FontSize 10).
tf = false(size(H));
for i = 1:numel(H)
    try
        tf(i) = strcmp(get(H(i), 'Type'), 'uilabel') && H(i).FontSize <= 10;
    catch
    end
end
end
