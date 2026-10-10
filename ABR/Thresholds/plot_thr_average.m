function ax = plot_thr_average(fh, all_y, ref_freqs, cond_names, cond_colors, cond_shapes, y_units, ylims, is_shift, subj_names)
%PLOT_THR_AVERAGE  ABR Thresholds — group view.
%   Mean ± SD per condition across frequency (click shown on its own),
%   individual subjects as faint points, n per point printed inside the
%   subject points tagged 'thr_subj_pts' (same marker as the condition).
%   all_y{subj,cond} = 1×nF thresholds (or shifts).
if nargin < 9, is_shift = false; end
if nargin < 10, subj_names = {}; end
INK = [0.15 0.15 0.15];  MUTE = [0.45 0.45 0.45];
nF  = numel(ref_freqs);
flab = cell(1,nF);
for i = 1:nF
    if ref_freqs(i) == 0, flab{i} = 'Click'; else, flab{i} = sprintf('%g', ref_freqs(i)/1000); end
end

set(0,'CurrentFigure',fh);  clf(fh);  set(fh,'Color','w');
ax = axes(fh,'Position',[0.08 0.20 0.68 0.70],'Tag','abr_thr_avg');  hold(ax,'on');
if any(ref_freqs==0) && nF > 1
    plot(ax, [1.5 1.5], [-200 200], '-', 'Color',[0.88 0.88 0.88], 'LineWidth',1, 'HandleVisibility','off');
end
if is_shift
    plot(ax, [0.5 nF+0.5], [0 0], '-', 'Color',[0.55 0.55 0.55], 'LineWidth',1, 'HandleVisibility','off');
else
    plot(ax, [0.5 nF+0.5], [80 80], ':', 'Color',[0.6 0.6 0.6], 'LineWidth',1, 'HandleVisibility','off');
end

nC   = size(all_y,2);
has  = false(1,nC);
for c = 1:nC, has(c) = any(~cellfun(@isempty, all_y(:,c))); end
cols = find(has);  nK = numel(cols);
all_vals = [];
for kk = 1:nK
    c   = cols(kk);
    clr = cond_colors(min(c,size(cond_colors,1)),1:3);
    shp = 'o';
    if ~isempty(cond_shapes), shp = strtrim(char(cond_shapes(min(c,size(cond_shapes,1)),:))); end
    if isempty(shp), shp = 'o'; end
    rows = find(~cellfun(@isempty, all_y(:,c)));
    M = nan(numel(rows), nF);
    for r = 1:numel(rows)
        v = all_y{rows(r),c}(:)';  m = min(numel(v), nF);  M(r,1:m) = v(1:m);
    end
    all_vals = [all_vals; M(:)]; %#ok<AGROW>
    mu = mean(M,1,'omitnan');  sd = std(M,0,1,'omitnan');  n = sum(~isnan(M),1);
    sd(n < 2) = NaN;
    dx = (kk - (nK+1)/2) * 0.16;
    x  = (1:nF) + dx;
    % individual subjects
    for r = 1:size(M,1)
        jit = ((mod(r*7,11)/10) - 0.5) * 0.08;
        if numel(subj_names) >= rows(r), sn = char(subj_names{rows(r)}); else, sn = sprintf('Subject %d', rows(r)); end
        scatter(ax, x + jit, M(r,:), 90, clr, shp, 'filled', 'MarkerFaceAlpha',0.30, ...
            'MarkerEdgeColor','none', 'HandleVisibility','off', 'Tag','thr_subj_pts', 'DisplayName',sn);
    end
    % mean ± SD (click not joined to tones)
    isc = ref_freqs(:)' == 0;
    % same style as ABR Peaks averages: errorbar + markers, edge = face colour
    if any(~isc)
        plot(ax, x(~isc), mu(~isc), '-', 'Color',clr, 'LineWidth',2, 'HandleVisibility','off');
    end
    errorbar(ax, x, mu, sd, 'Marker',shp, 'LineStyle','none', 'LineWidth',2, 'Color',clr, ...
        'MarkerSize',20, 'MarkerFaceColor',clr, 'MarkerEdgeColor',clr, 'HandleVisibility','off');
    % legend entry (square swatch, as in ABR Peaks)
    plot(ax, nan, nan, 's', 'MarkerFaceColor',clr, 'MarkerEdgeColor','k', 'MarkerSize',12, ...
        'LineWidth',1.5, 'DisplayName',sprintf('%s (n = %d)', cond_names{c}, numel(rows)));
end

xlim(ax, [0.5 nF+0.5]);
if ~isempty(ylims)
    ylim(ax, ylims);
elseif ~is_shift
    v = all_vals(isfinite(all_vals));  hi = 90;
    if ~isempty(v), hi = max(90, ceil(max(v)) + 5); end
    ylim(ax, [-5 hi]);  yticks(ax, 0:10:hi);
else
    v = all_vals(isfinite(all_vals));
    if ~isempty(v)
        lo = min([v; 0]);  hi = max([v; 0]);  pad = max(0.12*(hi-lo), 5);
        ylim(ax, [lo-pad hi+pad]);
    end
end
set(ax, 'XTick',1:nF, 'XTickLabel',flab, 'FontSize',14, 'Box','off', 'XColor',INK, 'YColor',INK);
grid(ax,'on');
xlabel(ax, 'Frequency (kHz)', 'FontWeight','bold');
ylabel(ax, y_units, 'FontWeight','bold');
if is_shift, ttl = 'ABR Threshold Shift'; else, ttl = 'ABR Thresholds'; end
title(ax, ttl, 'FontSize',16, 'FontWeight','bold');
% Condition legend centred under the plot (as in ABR Peaks averages)
lg = legend(ax, 'Orientation','horizontal', 'Box','off', 'FontSize',14, 'Location','southoutside');
ax.Position = [0.08 0.20 0.68 0.70];          % keep plot size fixed
lg.Units = 'normalized';
lg.Position(1) = ax.Position(1) + (ax.Position(3) - lg.Position(3))/2;
lg.Position(2) = 0.02;
set(fh, 'Units','normalized', 'Position',[0.15 0.2 0.6 0.6]);
end
