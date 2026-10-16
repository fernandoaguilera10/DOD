function [AX, KY] = memr_resp_plot(fh, box, conds, rel_label)
%MEMR_RESP_PLOT  "Growth Response": reflex response (ear-canal pressure
%   change vs frequency) as it grows with elicitor level — one small panel
%   per condition inside BOX = [x y w h] (normalized figure units), stacked
%   (≤ 3 conditions) or in two columns, condition name in its colour.
%   Each elicitor level is one line in the viridis palette (dark purple =
%   lowest level → yellow = highest), the same level → colour in every panel.
%   Shared x (log, kHz); each panel its own y. conds.sd (optional, same size
%   as R; Average) adds a mean ± SD band per level (Tag memr_resp_sd).
%   A colour bar on the right (axes Tag 'memr_lvl_cbar', drawn as an
%   image so the app copies it with the plots) maps colour to elicitor
%   level (dB FPL), ticks at the levels. KY is returned empty (kept for
%   the callers' legend call).
%   conds  struct array .name .clr .f (Hz) .R (levels x freq) .elic
%   rel_label  reference condition name when plotted relative ('' = none)
%   Axes Tag 'memr_resp_ax'; each line carries appdata 'apat_cond_rgb'
%   (its condition colour) so the Conditions ON/OFF buttons find it.
if nargin < 4, rel_label = ''; end
INK = [0.15 0.15 0.15];
ok = arrayfun(@(c) ~isempty(c.R) && ~isempty(c.f), conds);
nC = numel(conds);
AX = gobjects(0);
KY = struct('args',{}, 'label',{});
if nC == 0, return; end
ncol = 1 + (nC > 3);  nrow = ceil(nC / ncol);
CBW = 0.075;                                   % width kept on the right for the colour bar
box_all = box;  box(3) = box(3) - CBW;
gx = 0.035;  gy = 0.035 + 0.02*(nrow > 1);
w = (box(3) - (ncol-1)*gx) / ncol;  h = (box(4) - (nrow-1)*gy) / nrow;
% y range: each condition panel fits its own data (conditions can differ a
% lot in size); the app's "Growth Response Y" rows change them one by one
yl_of = @(R) fit_range(R);
fr = [];
for c = find(ok), fr = [fr, conds(c).f]; end %#ok<AGROW>
fr = fr(fr > 0) / 1e3;
xl = [0.2 8];  if ~isempty(fr), xl = [max(0.1, min(fr)), max(fr)]; end
kt = [0.125 0.25 0.5 1 2 4 8 16];  kt = kt(kt >= xl(1)*0.999 & kt <= xl(2)*1.001);
% one heat colour per elicitor level (shared by all panels)
LV = [];
for c = find(ok), LV = [LV, double(conds(c).elic(:)')]; end %#ok<AGROW>
LV = unique(LV(isfinite(LV)));
% viridis (dark purple = lowest level → blue → teal → green → yellow =
% highest); MATLAB has no built-in viridis, so it is interpolated from its
% published anchor colours
anc = [0.267 0.005 0.329; 0.283 0.141 0.458; 0.254 0.265 0.530; 0.207 0.372 0.553; ...
       0.164 0.471 0.558; 0.128 0.567 0.551; 0.135 0.659 0.518; 0.267 0.749 0.441; ...
       0.478 0.821 0.318; 0.741 0.873 0.150; 0.993 0.906 0.144];
HM  = interp1(linspace(0, 1, size(anc,1)), anc, linspace(0, 1, 256));
lvl_clr = @(v) HM(1 + round(255 * (find(LV == v, 1) - 1) / max(numel(LV) - 1, 1)), :);
for c = 1:nC
    rr = ceil(c / ncol);  cc = c - (rr-1)*ncol;
    pos = [box(1) + (cc-1)*(w+gx), box(2) + box(4) - rr*h - (rr-1)*gy, w, h];
    ax = axes(fh, 'Position',pos, 'Tag','memr_resp_ax');  hold(ax, 'on');
    AX(end+1) = ax; %#ok<AGROW>
    set(ax, 'XScale','log', 'FontSize',12, 'Box','off', 'XColor',INK, 'YColor',INK, ...
        'XLim',xl, 'YLim',yl_of(conds(c).R), 'XTick',kt, 'XTickLabel',compose('%g', kt));
    ax.UserData = struct('memr_cond',conds(c).name, 'clr',conds(c).clr, 'k',c);   % for the app's y-limit rows
    grid(ax, 'on');  ax.XMinorGrid = 'off';  ax.XMinorTick = 'off';
    C = conds(c);
    if ok(c)
        nL = size(C.R, 1);
        % spread across subjects (Average): mean ± SD band per level, in the
        % level's colour, behind the lines (Tag memr_resp_sd; app toggle)
        hasSD = isfield(C,'sd') && isequal(size(C.sd), size(C.R));
        if hasSD
            fx = C.f(:)' / 1e3;
            for k = 1:nL
                lc = [0.5 0.5 0.5];
                if k <= numel(C.elic) && any(LV == C.elic(k)), lc = lvl_clr(C.elic(k)); end
                up = C.R(k,:) + C.sd(k,:);  dn = C.R(k,:) - C.sd(k,:);
                g = isfinite(up) & isfinite(dn);
                if nnz(g) < 2, continue; end
                hf = fill(ax, [fx(g), fliplr(fx(g))], [up(g), fliplr(dn(g))], lc, 'FaceAlpha',0.15, ...
                    'EdgeColor','none', 'HandleVisibility','off', 'Tag','memr_resp_sd', ...
                    'PickableParts','none');
                setappdata(hf, 'apat_cond_rgb', C.clr);
                hf.UserData = struct('apat_cond_rgb', C.clr);
            end
            set(ax, 'YLim', fit_range([C.R + C.sd; C.R - C.sd]));
        end
        for k = 1:nL
            lc = [0.5 0.5 0.5];
            if k <= numel(C.elic) && any(LV == C.elic(k)), lc = lvl_clr(C.elic(k)); end
            hl = plot(ax, C.f / 1e3, C.R(k,:), '-', 'Color',lc, 'LineWidth',1.6, ...
                'HandleVisibility','off', 'Tag','memr_resp');
            if k <= numel(C.elic), hl.DisplayName = sprintf('%g dB FPL', C.elic(k)); end
            setappdata(hl, 'apat_cond_rgb', C.clr);       % Conditions ON/OFF buttons
            hl.UserData = struct('apat_cond_rgb', C.clr);  % (also in UserData: kept by copyobj)
        end
        plot(ax, xl, [0 0], 'k--', 'LineWidth',1, 'HandleVisibility','off');
    else
        text(ax, 0.5, 0.5, 'No Response Data', 'Units','normalized', 'HorizontalAlignment','center', ...
            'Color',[0.5 0.5 0.5], 'FontSize',11);
    end
    text(ax, 0.02, 0.95, C.name, 'Units','normalized', 'FontWeight','bold', 'FontSize',12, ...
        'Color',C.clr, 'Interpreter','none', 'VerticalAlignment','top');
    if rr < nrow && c + ncol <= nC, ax.XTickLabel = {}; else
        xlabel(ax, 'Frequency (kHz)', 'FontWeight','bold', 'FontSize',13);
    end
end
% one y label and one title for the whole block
ylab = '\DeltaEar-Canal Level (dB re. No Elicitor)';
if ~isempty(rel_label), ylab = sprintf('\\DeltaEar-Canal Level Shift (dB re. %s)', rel_label); end
ylabel(AX(1), ylab, 'FontWeight','bold', 'FontSize',13);
if nrow > 1, AX(1).YLabel.Units = 'normalized';  AX(1).YLabel.Position(2) = 1 - (nrow + (nrow - 1) * gy/h) / 2; end
title(AX(1), 'Growth Response', 'FontSize',14, 'FontWeight','bold');
if ncol > 1, AX(1).Title.Units = 'normalized'; AX(1).Title.Position(1) = (box(3)/2) / w; end
% colour bar: elicitor level (dB FPL), same heat map as the lines
KY = struct('args',{}, 'label',{});
if numel(LV) >= 1
    lo = LV(1);  hi = LV(end);  if hi <= lo, hi = lo + 1; end
    yy = linspace(lo, hi, 256)';
    ii = 1 + round(255 * (yy - lo) / (hi - lo));
    img = reshape(HM(ii,:), [256 1 3]);
    axC = axes(fh, 'Position',[box_all(1) + box_all(3) - CBW + 0.012, box_all(2) + 0.06*box_all(4), ...
        0.014, 0.88*box_all(4)], 'Tag','memr_lvl_cbar');
    image(axC, 0.5, [lo hi], img);
    tk = LV;  if numel(tk) > 8, tk = tk(1:2:end); if tk(end) ~= LV(end), tk(end+1) = LV(end); end, end
    set(axC, 'YDir','normal', 'XLim',[0 1], 'XTick',[], 'YAxisLocation','right', 'YLim',[lo hi], 'YTick',tk, ...
        'YTickLabel',compose('%g', tk), 'FontSize',11, 'Box','on', 'TickLength',[0 0], ...
        'XColor',INK, 'YColor',INK, 'Layer','top');
    ylabel(axC, 'Elicitor Level (dB FPL)', 'FontWeight','bold', 'FontSize',12);
end
end


function yl = fit_range(R)
v = double(R(:));  v = v(isfinite(v));
if isempty(v), yl = [-1 1]; return; end
lo = min(v);  hi = max(v);  r = max(hi - lo, 0.1);
yl = [lo - 0.08*r, hi + 0.08*r];
end
