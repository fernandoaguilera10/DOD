function ax = plot_thr_average(fh, all_y, ref_freqs, cond_names, cond_colors, cond_shapes, y_units, ylims, is_shift, subj_names, all_y_pts)
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
set(fh, 'Units','normalized', 'Position',[0.15 0.2 0.6 0.6]);   % final size first (marker sizing)
ax = axes(fh,'Position',[0.08 0.20 0.87 0.70],'Tag','abr_thr_avg');  hold(ax,'on');   % full width (Oct 15)
xlim(ax, [0.5 nF+0.5]);
if any(ref_freqs==0) && nF > 1
    plot(ax, [1.5 1.5], [-200 200], '-', 'Color',[0.88 0.88 0.88], 'LineWidth',1, 'HandleVisibility','off');
end
if is_shift
    plot(ax, [0.5 nF+0.5], [0 0], '-', 'Color',[0.55 0.55 0.55], 'LineWidth',1, 'HandleVisibility','off');
else
    plot(ax, [0.5 nF+0.5], [80 80], ':', 'Color',[0.6 0.6 0.6], 'LineWidth',1, 'HandleVisibility','off');
end

if nargin < 11 || isempty(all_y_pts) || ~isequal(size(all_y_pts), size(all_y)), all_y_pts = all_y; end
nC   = size(all_y,2);
has  = false(1,nC);
for c = 1:nC, has(c) = any(~cellfun(@isempty, all_y_pts(:,c))); end
cols = find(has);  nK = numel(cols);
all_vals = [];
offs = apat_dodge(nK);                     % shared spacing (all measures)
[ms, sa] = apat_ms(ax, 0.7);   % points at true x: size from the x spacing
LC = struct('clr',{},'shp',{},'label',{});
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
    x  = (1:nF) + offs(kk);
    % individual subjects (incl. those excluded from the mean — marked by the app)
    rowsP = find(~cellfun(@isempty, all_y_pts(:,c)));
    MP = nan(numel(rowsP), nF);
    for r = 1:numel(rowsP)
        v = all_y_pts{rowsP(r),c}(:)';  m = min(numel(v), nF);  MP(r,1:m) = v(1:m);
    end
    all_vals = [all_vals; MP(:)]; %#ok<AGROW>
    for r = 1:size(MP,1)
        jit = ((mod(rowsP(r)*7,11)/10) - 0.5) * 0.08;
        if numel(subj_names) >= rowsP(r), sn = char(subj_names{rowsP(r)}); else, sn = sprintf('Subject %d', rowsP(r)); end
        scatter(ax, x + jit, MP(r,:), sa, clr, shp, 'filled', 'MarkerFaceAlpha',0.30, ...
            'MarkerEdgeColor','none', 'HandleVisibility','off', 'Tag','thr_subj_pts', 'DisplayName',sn);
    end
    % mean ± SD (click not joined to tones)
    isc = ref_freqs(:)' == 0;
    % same style as ABR Peaks averages: errorbar + markers, edge = face colour
    if any(~isc)
        plot(ax, x(~isc), mu(~isc), '-', 'Color',clr, 'LineWidth',2, 'HandleVisibility','off');
    end
    errorbar(ax, x, mu, sd, 'Marker',shp, 'LineStyle','none', 'LineWidth',2, 'Color',clr, ...
        'MarkerSize',ms, 'MarkerFaceColor',clr, 'MarkerEdgeColor',clr, 'HandleVisibility','off');
    LC(end+1) = struct('clr',clr, 'shp',shp, 'label',sprintf('%s (n = %d)', cond_names{c}, numel(rows))); %#ok<AGROW>
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
apat_xgroups(ax, 1:nF);                    % one column per frequency (dodged points stay inside)
xlabel(ax, 'Frequency (kHz)', 'FontWeight','bold');
ylabel(ax, y_units, 'FontWeight','bold');
if is_shift, ttl = 'ABR Threshold Shift'; else, ttl = 'ABR Thresholds'; end
title(ax, ttl, 'FontSize',16, 'FontWeight','bold');
set(fh, 'Units','normalized', 'Position',[0.15 0.2 0.6 0.6]);
% Condition legend centred under the plot (same style for every measure)
apat_legend(fh, ax, LC, [], ax.Position(1), ax.Position(3));
end
