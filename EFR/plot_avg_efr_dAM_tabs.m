function plot_avg_efr_dAM_tabs(averages, all_levels, colors, shapes, idx, all_Conds2Run, idx_plot_relative, Chins2Run)
%PLOT_AVG_EFR_DAM_TABS  EFR dAM average figures for the app (ABR-style format).
%     One figure per level ('Level|<lev> dB SPL', Tag 'APAT_efr_avg'): mean ± SD
%     dAM power vs modulation frequency, noise floor dashed. Individual subjects: Tag
%     'efr_subj_pts' (hidden by default), subject ID in DisplayName.
if nargin < 8, Chins2Run = {}; end
valid_li = find(~cellfun(@isempty, averages));
if isempty(valid_li), return; end
col_offset = double(~isempty(idx_plot_relative));
rel = ~isempty(idx_plot_relative);

names = {};  cidx_list = [];
for c = 1:size(averages{valid_li(1)}.dAMpower, 2)
    ci = c + col_offset;
    if ci <= numel(all_Conds2Run) && ci <= size(idx,2) && sum(idx(:,ci)) > 0
        parts = strsplit(all_Conds2Run{ci}, filesep);
        names{end+1} = sprintf('%s (n = %d)', parts{end}, sum(idx(:,ci))); %#ok<AGROW>
        cidx_list(end+1) = mod(ci-1, size(colors,1)) + 1; %#ok<AGROW>
    end
end

% One figure per level ('Level|<lev> dB SPL', Tag 'APAT_efr_avg'); the app
% shows one level at a time via the Level dropdown in the Results bar.
n = numel(valid_li);  L = 0.07;  R = 0.82;
for k = 1:n
    li = valid_li(k);  A = averages{li};
    nm = sprintf('Level|%d dB SPL', round(all_levels(li)));
    old = findobj('Type','figure','Name',nm,'Tag','APAT_efr_avg');  if ~isempty(old), close(old); end
    fh = figure('Name',nm,'NumberTitle','off','Visible','off','Color','w','Tag','APAT_efr_avg', ...
        'Units','normalized','Position',[0.05 0.1 0.85 0.75]);
    ax = axes(fh, 'Position',[L 0.22 R-L 0.64], 'Tag','efr_tile');  hold(ax,'on');  axs = ax;
    if rel, plot(ax, [1e-3 1e6], [0 0], 'k--', 'LineWidth',1.5, 'HandleVisibility','off'); end
    for c = 1:numel(A.dAMpower)
        tr = A.trajectory{1,c};  pw = A.dAMpower{1,c};
        if isempty(tr) || isempty(pw), continue; end
        ci  = c + col_offset;
        clr = colors(mod(ci-1, size(colors,1)) + 1, 1:3);
        shp = strtrim(char(shapes(mod(ci-1, size(shapes,1)) + 1, :)));  if isempty(shp), shp = 'o'; end
        % individual subjects (hidden by default)
        for s = 1:size(A.all_dAMpower, 1)
            ys = A.all_dAMpower{s,c};  xs = A.all_trajectory{s,c};
            if isempty(ys) || isempty(xs), continue; end
            m = min(numel(xs), numel(ys));
            if numel(Chins2Run) >= s, sn = char(Chins2Run{s}); else, sn = sprintf('Subject %d', s); end
            scatter(ax, xs(1:m), ys(1:m), 40, clr, shp, 'filled', 'MarkerFaceAlpha',0.30, ...
                'MarkerEdgeColor','none', 'HandleVisibility','off', 'Tag','efr_subj_pts', ...
                'Visible','off', 'DisplayName',sn);
        end
        if isfield(A,'NFpower') && numel(A.NFpower) >= c && ~isempty(A.NFpower{1,c})
            plot(ax, tr, A.NFpower{1,c}, '--', 'Color',clr, 'LineWidth',1.5, 'HandleVisibility','off');
        end
        errorbar(ax, tr, pw, A.dAMpower_std{1,c}, 'Marker',shp, 'LineStyle','-', 'LineWidth',2, ...
            'MarkerSize',9, 'Color',clr, 'MarkerFaceColor',clr, 'MarkerEdgeColor',clr, 'HandleVisibility','off');
    end
    set(ax, 'XScale','log', 'FontSize',14, 'Box','off');  grid(ax,'on');
    xlabel(ax, 'Modulation Frequency (Hz)', 'FontWeight','bold');
    if rel, ylabel(ax, 'Power Shift (re. Baseline)', 'FontWeight','bold');
    else,   ylabel(ax, 'Power (dB)', 'FontWeight','bold'); end
    yy = [];
    for h = findall(ax, 'Type','errorbar')'
        v = [h.YData - h.YNegativeDelta, h.YData + h.YPositiveDelta];  yy = [yy, v(isfinite(v))]; %#ok<AGROW>
    end
    for h = findall(ax, 'Type','line')'
        v = h.YData;  yy = [yy, v(isfinite(v))]; %#ok<AGROW>
    end
    if ~isempty(yy)
        lo = min(yy);  hi = max(yy);  r = max(hi - lo, 0.5);
        ylim(ax, [lo - 0.12*r, hi + 0.12*r]);
    end
    title(ax, 'dAM power', 'FontSize',14, 'FontWeight','bold');
    % figure title (axes, survives embedding)
    axH = axes(fh, 'Position',[0 0.92 0.89 0.06], 'Visible','off');
    text(axH, 0.5, 0.5, sprintf('EFR dAM 4 kHz — %d dB SPL', round(all_levels(li))), 'FontSize',16, ...
        'FontWeight','bold', 'HorizontalAlignment','center', 'Color',[0.15 0.15 0.15]);
    text(ax, 1, -0.16, 'dashed = noise floor', 'Units','normalized', 'FontSize',11, ...
        'Color',[0.45 0.45 0.45], 'HorizontalAlignment','right', 'VerticalAlignment','top');
    % condition legend under the plot (squares, black edge) — as ABR Peaks
    if ~isempty(names)
        lh = gobjects(1, numel(names));
        for i = 1:numel(names)
            lh(i) = plot(ax, NaN, NaN, 's', 'MarkerFaceColor',colors(cidx_list(i),:), ...
                'MarkerEdgeColor','k', 'MarkerSize',12, 'LineWidth',1.5);
        end
        lg = legend(ax, lh, names, 'Orientation','horizontal', 'Box','off', 'FontSize',14, 'Location','none');
        lg.Units = 'normalized';
        lg.Position(1) = L + (R - L - lg.Position(3))/2;
        lg.Position(2) = 0.03;
    end
end
end
