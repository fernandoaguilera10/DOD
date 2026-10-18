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
set(fh, 'Units','normalized', 'Position',[0.15 0.2 0.6 0.6]);   % final size first (marker sizing)
ax = axes(fh,'Position',[0.08 0.20 0.55 0.70]); hold(ax,'on');
xlim(ax, [0.5 nF+0.5]);
if any(allf==0) && nF > 1
    plot(ax, [1.5 1.5], [-100 200], '-', 'Color',[0.88 0.88 0.88], 'LineWidth',1, 'HandleVisibility','off');
end
plot(ax, [0.5 nF+0.5], [80 80], ':', 'Color',[0.6 0.6 0.6], 'LineWidth',1, 'HandleVisibility','off');
offs = apat_dodge(nC);                     % same spacing / marker size as the averages
ms = apat_ms(ax, 0.7);   % points at true x: size from the x spacing
LC = struct('clr',{},'shp',{},'label',{});
for c = 1:nC
    C  = S.conds(c);
    [tf, loc] = ismember(C.freqs, allf);
    x  = loc(tf);  y = C.thr(tf);  isc = C.freqs(tf) == 0;
    dx = offs(c);
    mk = {'Marker',C.shp,'MarkerSize',ms,'MarkerFaceColor',C.clr,'MarkerEdgeColor',C.clr,'LineWidth',2,'Color',C.clr};
    if any(~isc)
        plot(ax, x(~isc)+dx, y(~isc), '-', mk{:}, 'HandleVisibility','off');
    end
    if any(isc)
        plot(ax, x(isc)+dx, y(isc), 'LineStyle','none', mk{:}, 'HandleVisibility','off');
    end
    LC(end+1) = struct('clr',C.clr, 'shp',C.shp, 'label',C.name); %#ok<AGROW>
end
if ~isempty(ylims), ylim(ax, ylims); else, ylim(ax, [-5 90]); yticks(ax, 0:10:80); end
set(ax, 'XTick',1:nF, 'XTickLabel',flab, 'FontSize',14, 'Box','off', 'XColor',INK, 'YColor',INK);
grid(ax,'on');
apat_xgroups(ax, 1:nF);                    % one column per frequency
xlabel(ax, 'Frequency (kHz)', 'FontWeight','bold');
ylabel(ax, 'Threshold (dB SPL)', 'FontWeight','bold');
title(ax, sprintf('%s ABR Thresholds', fig_name), 'FontSize',16, 'FontWeight','bold', 'Interpreter','none');
apat_legend(fh, ax, LC, [], ax.Position(1), ax.Position(3));    % conditions, bottom

% ── values table (block centred vertically) ──────────────────────────
axT = axes(fh,'Position',[0.68 0.13 0.30 0.74], 'Tag','abr_thr_table'); hold(axT,'on');
axis(axT,'off');  xlim(axT,[0 1]);  ylim(axT,[0 1]);
fs  = 14;  if nC > 3, fs = 12; end
rlab = cell(1, nF);                        % row labels ('Click', '0.5 kHz' …)
for r = 1:nF, rlab{r} = flab{r};  if allf(r) ~= 0, rlab{r} = [rlab{r} ' kHz']; end, end
x0  = apat_table_x0(axT, [rlab {'Freq'}], fs, {'00.0*'}, fs, nC, 0.02, 0.26, 8);   % labels + 8 px before values
cw = (1 - x0) / max(nC,1);
rh  = min(0.075, 0.70/(nF+3));
fsv = apat_table_fit('fs', axT, {'00.0*'}, fs, cw, 8);   % values fit their column (apat_table_fit)
any_lim = any(arrayfun(@(C) any(C.thr >= 80), S.conds));

y_title = 0.5 + (1.2 + nF + any_lim)*rh/2;     % centre the whole block
y_hdr   = y_title - rh*1.2;
text(axT, 0.5, y_title, 'Thresholds (dB SPL)', 'FontSize',16, 'FontWeight','bold', ...
    'Color',INK, 'HorizontalAlignment','center', 'VerticalAlignment','middle');
text(axT, 0.02, y_hdr, 'Freq', 'FontSize',fs, 'FontWeight','bold', 'Color',MUTE, 'VerticalAlignment','middle');
for c = 1:nC
    hh = text(axT, x0 + (c-0.5)*cw, y_hdr, S.conds(c).name, 'FontSize',fs, 'FontWeight','bold', ...
        'Color',S.conds(c).clr, 'HorizontalAlignment','center', 'VerticalAlignment','middle', 'Interpreter','none');
    apat_table_fit('text', hh, cw, 8);           % fits its column: smaller, two lines, then '…'
end
plot(axT, [0 1], [y_hdr-rh/2 y_hdr-rh/2], '-', 'Color',GOLD, 'LineWidth',1.2);
for r = 1:nF
    y = y_hdr - r*rh;
    g = 0.08*rh;                          % every row shaded like its frequency's column in the plot
    patch(axT, [0 1 1 0], [y-rh/2+g y-rh/2+g y+rh/2-g y+rh/2-g], apat_shade_eff(), ...
        'EdgeColor','none', 'Tag','apat_xgroup');
    text(axT, 0.02, y, rlab{r}, 'FontSize',fs, 'Color',INK, 'VerticalAlignment','middle');
    for c = 1:nC
        C = S.conds(c);  j = find(C.freqs == allf(r), 1);
        if isempty(j) || isnan(C.thr(j)), v = '—';
        elseif C.thr(j) >= 80, v = sprintf('%.0f*', C.thr(j));
        else, v = sprintf('%.1f', C.thr(j));
        end
        text(axT, x0 + (c-0.5)*cw, y, v, 'FontSize',fsv, 'Color',INK, ...
            'HorizontalAlignment','center', 'VerticalAlignment','middle');
    end
end
if any_lim
    text(axT, 0.5, y_hdr - (nF+1)*rh, '* At Upper Limit (Dotted Line) — Possible No Response', ...
        'FontSize',11, 'Color',MUTE, 'HorizontalAlignment','center', 'VerticalAlignment','middle');
end
end


function s = ternary_s(c, a, b)
if c, s = a; else, s = b; end
end
