function fit_layout(root)
%FIT_LAYOUT  Keep every embedded plot clear of the window edges, the control
%   strip (buttons / limits) and the bottom legends.
%   For each panel under ROOT that holds plot axes, the plots of that panel
%   (as one group, so side-by-side plots keep their proportions) are shrunk
%   and/or shifted only as much as needed so that their outer box — tick
%   labels, axis labels and titles included (TightInset) — stays
%     · ≥ EDGE px from all four panel edges,
%     · ≥ GAP_CTRL px left of a value table on the right (axes tagged
%       '*_table'); control strips (Tag 'apat_ctrl') are not obstacles —
%       they are hidden in the "Plot Settings" panel (plot_settings.m),
%     · plots that leave more than 3 % of the width free on the right are
%       widened (as one group, ≤ 1.6×) to use it,
%     · ≥ GAP_LEG px above the legends at the bottom,
%     · below the figure title (invisible title axes at the top).
%   Bottom legends are then re-centred under the plots. Display only; saved
%   figures are unchanged.
%   Window resizes: the first fit stores each plot's designed position
%   (appdata 'apat_pos0'); every later fit starts again from it, so plots
%   grow back when the window gets bigger. A panel is fitted once per
%   layout epoch (UIFigure appdata 'apat_layout_epoch', bumped by
%   relayout_results after the window size changes).
EDGE = 14;  GAP_CTRL = 18;  GAP_LEG = 8;  GAP_TTL = 4;  GAP_UNDER = 6;
if nargin < 1 || isempty(root) || ~isvalid(root), return; end
try
    drawnow;
    allax = findall(root, 'Type','axes');
    if isempty(allax), return; end
    hosts = unique(arrayfun(@(a) a.Parent, allax));
    ctrls = findall(root, 'Type','uipanel', 'Tag','apat_ctrl');
    fig = ancestor(root, 'figure');
    epoch = 0;
    if ~isempty(fig) && isappdata(fig, 'apat_layout_epoch'), epoch = getappdata(fig, 'apat_layout_epoch'); end
    for host = hosts(:)'
      try
        if isappdata(host, 'apat_fit') && isequal(getappdata(host, 'apat_fit'), epoch), continue; end
        kids = host.Children;
        main = findobj(kids, 'flat', 'Type','axes', 'Visible','on');
        main = main(~cellfun(@(t) ~isempty(regexp(t, '_table$', 'once')), {main.Tag}));
        if isempty(main), continue; end
        hp = getpixelposition(host, true);
        if hp(3) < 50 || hp(4) < 50, continue; end
        % start from the designed layout (restores what an earlier fit changed)
        for a = main(:)'
            set(a, 'Units','normalized');
            if isappdata(a, 'apat_pos0'), a.Position = getappdata(a, 'apat_pos0');
            else, setappdata(a, 'apat_pos0', a.Position); end
        end
        for g = findobj(kids, 'flat', 'Type','legend')'
            set(g, 'Units','normalized');
            if isappdata(g, 'apat_lx0'), g.Position(1) = getappdata(g, 'apat_lx0');
            else, setappdata(g, 'apat_lx0', g.Position(1)); end
        end
        drawnow limitrate;
        % ── plot boxes (absolute pixels) ──────────────────────────────
        n = numel(main);  P = zeros(n,4);  O = zeros(n,4);
        under = findobj(kids, 'flat', 'Type','uipanel', 'Tag','apat_under_ax');   % bars under an axes (EFR Listen)
        for k = 1:n
            P(k,:) = getpixelposition(main(k), true);
            ti = tight_px(main(k));
            O(k,:) = [P(k,1)-ti(1), P(k,2)-ti(2), P(k,1)+P(k,3)+ti(3), P(k,2)+P(k,4)+ti(4)];   % L B R T
            for u = under(:)'
                if isequal(u.UserData, main(k))           % keep room for it under the x-label
                    q = getpixelposition(u, true);  O(k,2) = O(k,2) - q(4) - GAP_UNDER;
                end
            end
        end
        PL = min(P(:,1));  PR = max(P(:,1)+P(:,3));  PB = min(P(:,2));  PT = max(P(:,2)+P(:,4));
        OL = min(O(:,1));  OB = min(O(:,2));  OR = max(O(:,3));  OT = max(O(:,4));
        cy = (PB + PT)/2;
        % ── limits ────────────────────────────────────────────────────
        xl = hp(1) + EDGE;  xr = hp(1) + hp(3) - EDGE;
        yb = hp(2) + EDGE;  yt = hp(2) + hp(4) - EDGE;
        % control strips are no obstacle any more: they live in the "Plot
        % Settings" panel (hidden; shown floating over the plots on request)
        obst = gobjects(1,0);
        tb = findobj(kids, 'flat', 'Type','axes');
        tb = tb(~cellfun(@isempty, regexp({tb.Tag}, '_table$', 'once')));
        obst = [obst, tb(:)']; %#ok<AGROW>
        for h = obst
            if ~isvalid(h), continue; end
            q = getpixelposition(h, true);
            overlap_y = q(2) < PT && q(2) + q(4) > PB;
            if overlap_y && q(1) >= PR - 2 && q(1) < xr       % a strip to the right of the plots
                xr = min(xr, q(1) - GAP_CTRL);
            end
        end
        lgs = findobj(kids, 'flat', 'Type','legend');
        lgs = lgs(arrayfun(@(g) strcmp(g.Visible,'on'), lgs));
        below = false(size(lgs));
        for k = 1:numel(lgs)
            q = getpixelposition(lgs(k), true);
            if q(2) + q(4)/2 < cy
                below(k) = true;  yb = max(yb, q(2) + q(4) + GAP_LEG);
            end
        end
        ttl = findobj(kids, 'flat', 'Type','axes', 'Visible','off');
        for a = ttl(:)'
            if isempty(findobj(a, 'Type','text')), continue; end
            q = getpixelposition(a, true);
            if q(2) > cy, yt = min(yt, q(2) - GAP_TTL); end
        end
        % ── horizontal: scale (if too wide) then shift inside [xl xr] ──
        inL = PL - OL;  inR = OR - PR;
        sx = 1;  wP = PR - PL;
        if OR - OL > xr - xl && wP > 0, sx = max(0.3, (xr - xl - inL - inR) / wP); end
        % room left on the right (the space once kept for the controls):
        % widen the plots, as one group, up to the right limit
        if sx == 1 && wP > 0 && (xr - OR) > 0.03 * hp(3)
            sx = min(1.6, (xr - inR - PL) / wP);
        end
        nPL = PL;  nW = wP * sx;
        if nPL - inL < xl, nPL = xl + inL; end
        if nPL + nW + inR > xr, nPL = xr - inR - nW; end
        % ── vertical ──────────────────────────────────────────────────
        inB = PB - OB;  inT = OT - PT;
        sy = 1;  hP = PT - PB;
        if OT - OB > yt - yb && hP > 0, sy = max(0.3, (yt - yb - inB - inT) / hP); end
        nPB = PB;  nH = hP * sy;
        if nPB - inB < yb, nPB = yb + inB; end
        if nPB + nH + inT > yt, nPB = yt - inT - nH; end
        changed = abs(sx-1) > 1e-3 || abs(sy-1) > 1e-3 || abs(nPL-PL) > 0.5 || abs(nPB-PB) > 0.5;
        if changed
            for k = 1:n
                np = [nPL + (P(k,1)-PL)*sx, nPB + (P(k,2)-PB)*sy, P(k,3)*sx, P(k,4)*sy];
                set(main(k), 'Units','normalized', 'Position', ...
                    [(np(1)-hp(1))/hp(3), (np(2)-hp(2))/hp(4), np(3)/hp(3), np(4)/hp(4)]);
            end
            % bottom legends re-centred under the plots
            cx = nPL + nW/2;
            for g = lgs(below)'
                if strcmp(g.Tag, 'apat_legend') || isempty(g.Tag)
                    set(g, 'Units','normalized');  q = g.Position;
                    q(1) = (cx - hp(1))/hp(3) - q(3)/2;
                    g.Position = q;
                end
            end
        end
        place_under(under, hp, GAP_UNDER);                % bars follow their axes
        setappdata(host, 'apat_fit', epoch);
      catch
      end
    end
catch
    % layout is cosmetic — never break the Results view
end
end


function ti = tight_px(ax)
%TIGHT_PX  TightInset of an axes in pixels (fallback: typical label sizes).
ti = [60 50 10 30];
try
    u = ax.Units;  ax.Units = 'pixels';  t = ax.TightInset;  ax.Units = u;
    if all(isfinite(t)), ti = t; end
catch
end
end


function place_under(under, hp, gap)
%PLACE_UNDER  Panels tagged 'apat_under_ax' (UserData = an axes) sit right
%   under that axes' x-label, with its left edge and width.
for u = under(:)'
    try
        a = u.UserData;
        if ~isgraphics(a), continue; end
        q  = getpixelposition(a, true);  ti = tight_px(a);
        up = getpixelposition(u, true);
        y  = q(2) - ti(2) - gap - up(4);
        set(u, 'Units','normalized', 'Position', ...
            [(q(1) - hp(1))/hp(3), (y - hp(2))/hp(4), q(3)/hp(3), up(4)/hp(4)]);
    catch
    end
end
end
