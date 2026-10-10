function fh = plot_thr_summary(fig_name, freqs, thr, cond_name, clr, shp, ylims)
%PLOT_THR_SUMMARY  ABR Thresholds — per-subject summary (Summary tab).
%   Called once per condition; conditions accumulate in the figure's
%   UserData and the whole figure is redrawn each call.
%   Left : threshold vs frequency, one line per condition (click separate).
%   Right: table of threshold values (dB SPL).
if nargin < 6 || isempty(shp), shp = 'o'; end
if nargin < 7, ylims = []; end
shp = strtrim(char(shp));  if isempty(shp), shp = 'o'; end
INK = [0.15 0.15 0.15];  MUTE = [0.45 0.45 0.45];  GOLD = [0.81 0.73 0.57];

fh = findobj('Type','figure','Name',fig_name);
if isempty(fh)
    fh = figure('Name',fig_name,'NumberTitle','off','Visible','off','Color','w');
else
    fh = fh(1);
end
S = get(fh,'UserData');
if ~isstruct(S) || ~isfield(S,'conds')
    S = struct('conds', struct('name',{},'freqs',{},'thr',{},'clr',{},'shp',{}));
end
k = find(strcmp({S.conds.name}, cond_name), 1);
if isempty(k), k = numel(S.conds) + 1; end
S.conds(k) = struct('name',cond_name,'freqs',freqs(:)','thr',thr(:)','clr',clr(1:3),'shp',shp);
clf(fh);  set(fh,'Color','w','UserData',S);

allf = unique([S.conds.freqs]);              % ascending → click (0) first
nF   = numel(allf);  nC = numel(S.conds);
flab = arrayfun(@(f) ternary_s(f==0,'Click',sprintf('%g',f/1000)), allf, 'UniformOutput',false);

% ── threshold vs frequency ───────────────────────────────────────────
ax = axes(fh,'Position',[0.08 0.13 0.55 0.70]); hold(ax,'on');
if any(allf==0) && nF > 1
    plot(ax, [1.5 1.5], [-100 200], '-', 'Color',[0.88 0.88 0.88], 'LineWidth',1, 'HandleVisibility','off');
end
plot(ax, [0.5 nF+0.5], [80 80], ':', 'Color',[0.6 0.6 0.6], 'LineWidth',1, 'HandleVisibility','off');
for c = 1:nC
    C  = S.conds(c);
    [tf, loc] = ismember(C.freqs, allf);
    x  = loc(tf);  y = C.thr(tf);  isc = C.freqs(tf) == 0;
    dx = (c - (nC+1)/2) * 0.05;
    mk = {'Marker',C.shp,'MarkerSize',13,'MarkerFaceColor',C.clr,'MarkerEdgeColor',C.clr,'LineWidth',3,'Color',C.clr};
    hv = 'on';
    if any(~isc)
        plot(ax, x(~isc)+dx, y(~isc), '-', mk{:}, 'DisplayName',C.name);
        hv = 'off';
    end
    if any(isc)
        plot(ax, x(isc)+dx, y(isc), 'LineStyle','none', mk{:}, 'DisplayName',C.name, 'HandleVisibility',hv);
    end
end
xlim(ax, [0.5 nF+0.5]);
if ~isempty(ylims), ylim(ax, ylims); else, ylim(ax, [-5 90]); yticks(ax, 0:10:80); end
set(ax, 'XTick',1:nF, 'XTickLabel',flab, 'FontSize',14, 'Box','off', 'XColor',INK, 'YColor',INK);
grid(ax,'on');
xlabel(ax, 'Frequency (kHz)', 'FontWeight','bold');
ylabel(ax, 'Threshold (dB SPL)', 'FontWeight','bold');
title(ax, sprintf('%s ABR Thresholds', fig_name), 'FontSize',16, 'FontWeight','bold', 'Interpreter','none');
lg = legend(ax, 'Location','northoutside', 'Orientation','horizontal', 'FontSize',14);
legend(ax,'boxoff');  lg.ItemTokenSize = [18 10];

% ── values table (block centred vertically) ──────────────────────────
axT = axes(fh,'Position',[0.68 0.13 0.30 0.74]); hold(axT,'on');
axis(axT,'off');  xlim(axT,[0 1]);  ylim(axT,[0 1]);
fs  = 14;  if nC > 3, fs = 12; end
x0  = 0.26;  cw = (1 - x0) / max(nC,1);
rh  = min(0.075, 0.70/(nF+3));
any_lim = any(arrayfun(@(C) any(C.thr >= 80), S.conds));

y_title = 0.5 + (1.2 + nF + any_lim)*rh/2;     % centre the whole block
y_hdr   = y_title - rh*1.2;
text(axT, 0.5, y_title, 'Thresholds (dB SPL)', 'FontSize',16, 'FontWeight','bold', ...
    'Color',INK, 'HorizontalAlignment','center', 'VerticalAlignment','middle');
text(axT, 0.02, y_hdr, 'Freq', 'FontSize',fs, 'FontWeight','bold', 'Color',MUTE, 'VerticalAlignment','middle');
for c = 1:nC
    nm = S.conds(c).name;  if numel(nm) > 12, nm = [nm(1:11) '…']; end
    text(axT, x0 + (c-0.5)*cw, y_hdr, nm, 'FontSize',fs, 'FontWeight','bold', ...
        'Color',S.conds(c).clr, 'HorizontalAlignment','center', 'VerticalAlignment','middle', 'Interpreter','none');
end
plot(axT, [0 1], [y_hdr-rh/2 y_hdr-rh/2], '-', 'Color',GOLD, 'LineWidth',1.2);
for r = 1:nF
    y = y_hdr - r*rh;
    if mod(r,2) == 0
        patch(axT, [0 1 1 0], [y-rh/2 y-rh/2 y+rh/2 y+rh/2], [0.97 0.97 0.97], 'EdgeColor','none');
    end
    lbl = flab{r};  if allf(r) ~= 0, lbl = [lbl ' kHz']; end
    text(axT, 0.02, y, lbl, 'FontSize',fs, 'Color',INK, 'VerticalAlignment','middle');
    for c = 1:nC
        C = S.conds(c);  j = find(C.freqs == allf(r), 1);
        if isempty(j) || isnan(C.thr(j)), v = '—';
        elseif C.thr(j) >= 80, v = sprintf('%.0f*', C.thr(j));
        else, v = sprintf('%.1f', C.thr(j));
        end
        text(axT, x0 + (c-0.5)*cw, y, v, 'FontSize',fs, 'Color',INK, ...
            'HorizontalAlignment','center', 'VerticalAlignment','middle');
    end
end
if any_lim
    text(axT, 0.5, y_hdr - (nF+1)*rh, '* at upper limit (dotted line) — possible no response', ...
        'FontSize',11, 'Color',MUTE, 'HorizontalAlignment','center', 'VerticalAlignment','middle');
end
set(fh, 'Units','normalized', 'Position',[0.15 0.2 0.6 0.6]);
end


function s = ternary_s(c, a, b)
if c, s = a; else, s = b; end
end
