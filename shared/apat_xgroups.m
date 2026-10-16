function apat_xgroups(ax, xc, clr)
%APAT_XGROUPS  Show that side-by-side (dodged) points belong to ONE x value.
%   Each x group (tick / harmonic / level / band / category) gets one light
%   band that wraps its cluster of points — every group shaded the same way,
%   white gaps between groups — so a cluster reads as a single unit sitting
%   on its tick, not as separate x values. The band width is measured from
%   the points actually plotted (widest cluster + a margin; at least ~1/3 of
%   the group spacing), so it fits every measure without tuning.
%   clr (optional, n×3; a NaN row = leave that group unshaded): grey shade per band (apat_region_tints) to link a
%   plot with its summary plot / table rows. Greys only (drawn at 50 %
%   opacity; apat_shade_eff gives the matching opaque colour for tables) so
%   the shading never competes with the condition colours.
%   Vertical grid lines are turned off (horizontal ones stay), and the x
%   ticks are set to the group centres (labelled with their values) unless
%   the axes already has exactly those ticks. Drawn with
%   xregion (any y range, no effect on the y-limits), behind the data, not
%   clickable, Tag 'apat_xgroup'.
if nargin < 3, clr = []; end
xc = double(xc(:)');  keep = isfinite(xc);  xc = xc(keep);
if ~isempty(clr), clr = clr(keep(1:min(end,size(clr,1))), :); end
[xc, o] = unique(xc);  if ~isempty(clr) && size(clr,1) >= max(o), clr = clr(o,:); end
if isempty(xc) || ~isvalid(ax), return; end
lg = strcmp(ax.XScale, 'log');
if lg, ok = xc > 0; xc = xc(ok); if ~isempty(clr), clr = clr(ok(1:min(end,size(clr,1))),:); end, end
if isempty(xc), return; end
tf = @(x) x;  itf = @(u) u;
if lg, tf = @log10;  itf = @(u) 10.^u; end
u = tf(xc);
sp = 1;  if numel(u) > 1, sp = min(diff(u)); end
if ~(sp > 0), sp = 1; end
hw = 0.30*sp;                                  % band covers the tick's area (points sit at its centre)
ax.XGrid = 'off';  ax.XMinorGrid = 'off';
% One tick per group, at its centre, labelled with that group's value, so
% every cluster sits on a labelled tick (e.g. OAE bands at 1/2-octave
% centres, dAM modulation bands, every MEMR elicitor level). Axes whose
% ticks already are the group centres keep their own labels (ABR 'Click',
% EFR k×F0, category names …).
try
    xt = double(ax.XTick(:)');
    same = numel(xt) == numel(xc) && all(abs(tf(xt) - u) < 1e-6*max(1, max(abs(u))));
    if ~same
        ax.XTick = xc;
        ax.XTickLabel = arrayfun(@tick_txt, xc, 'UniformOutput', false);
        if numel(xc) > 9, xtickangle(ax, 45); end
    end
    ax.XMinorTick = 'off';
catch
end
yl = ax.YLim;  ym = ax.YLimMode;
base = [0.88 0.88 0.88];                      % plain band: ≈ 0.94 grey on white
for k = 1:numel(u)
    fc = base;  fa = 0.5;
    if ~isempty(clr) && size(clr,1) >= k
        fc = clr(k,1:3);                              % region grey (apat_region_tints)
        if any(isnan(fc)), continue; end              % NaN row = no band for this group
    end
    e1 = itf(u(k) - hw);  e2 = itf(u(k) + hw);
    try
        r = xregion(ax, e1, e2, 'FaceColor',fc, 'FaceAlpha',fa, 'EdgeColor','none', ...
            'HandleVisibility','off', 'Tag','apat_xgroup');
        try, set(r, 'HitTest','off', 'PickableParts','none'); catch, end
        try, uistack(r, 'bottom'); catch, end
    catch
        % xregion unavailable (MATLAB < R2023a): fall back to a patch
        hp = patch(ax, [e1 e2 e2 e1], [-1e9 -1e9 1e9 1e9], fc, 'FaceAlpha',fa, ...
            'EdgeColor','none', 'HandleVisibility','off', 'Tag','apat_xgroup', ...
            'HitTest','off', 'PickableParts','none');
        try, uistack(hp, 'bottom'); catch, end
    end
end
if strcmp(ym, 'manual'), ax.YLim = yl; end
end


function t = tick_txt(v)
% compact label: 3 significant digits at most (1.41, 22.4, 708, 4000 …)
a = abs(v);
if a >= 100,     t = sprintf('%d', round(v));
elseif a >= 10,  t = sprintf('%.3g', v);
elseif a >= 1,   t = sprintf('%.3g', v);
else,            t = sprintf('%.2g', v);
end
end
