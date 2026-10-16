function memr_style(ax, axT, ev, de, cnames, xlab, ylab, tlab, rel, cclr)
%MEMR_STYLE  Shared axes cosmetics for the MEMR individual / average figures.
INK = [0.15 0.15 0.15];
set([ax axT], 'FontSize',14, 'Box','off', 'XColor',INK, 'YColor',INK);
grid(ax,'on');  grid(axT,'on');
if numel(ev) > 1
    st = de;  if numel(ev) > 10, st = 2*de; end
    xticks(ax, ev(1):st:ev(end));
end
xlabel(ax, xlab, 'FontWeight','bold');
ylabel(ax, ylab, 'FontWeight','bold');
title(ax, 'Growth Function', 'FontSize',14, 'FontWeight','bold');
% (y values: mean |level change re. no elicitor| over 0.5–2 kHz, minus the
%  smallest value across levels — MEMRbyLevel / WBMEMRanalysis)
set(axT, 'XTick',1:numel(cnames), 'XTickLabel',cnames, 'TickLabelInterpreter','none');
xtickangle(axT, 0);
ylabel(axT, tlab, 'FontWeight','bold');
title(axT, 'Threshold', 'FontSize',14, 'FontWeight','bold');
fit_y(ax);  fit_y(axT);
apat_xgroups(ax, ev);                              % one column per elicitor level
if nargin < 10, cclr = []; end
axT.XGrid = 'off';                                 % ART: x is the condition itself, no shading
if rel
    plot(ax,  xlim(ax),  [0 0], 'k--', 'LineWidth',1.3, 'HandleVisibility','off');
    plot(axT, xlim(axT), [0 0], 'k--', 'LineWidth',1.3, 'HandleVisibility','off');
end
end

function fit_y(ax)
% y-limits from lines, error bars and subject points (+ 10 % padding)
yy = [];
for h = findall(ax, 'Type','errorbar')'
    v = [h.YData(:) - h.YNegativeDelta(:); h.YData(:) + h.YPositiveDelta(:)];
    yy = [yy; v(isfinite(v))]; %#ok<AGROW>
end
for h = [findall(ax, 'Type','line'); findall(ax, 'Type','scatter')]'
    v = double(h.YData(:));  yy = [yy; v(isfinite(v))]; %#ok<AGROW>
end
if isempty(yy), return; end
lo = min(yy);  hi = max(yy);  r = max(hi - lo, 0.05*max(abs([lo hi 1])));
ylim(ax, [lo - 0.12*r, hi + 0.12*r]);
end
