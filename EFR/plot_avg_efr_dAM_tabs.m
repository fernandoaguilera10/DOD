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
n = numel(valid_li);  L = 0.07;  R = 0.95;   % full width (Oct 15)
for k = 1:n
    li = valid_li(k);  A = averages{li};
    nm = sprintf('Level|%d dB SPL', round(all_levels(li)));
    old = findobj('Type','figure','Name',nm,'Tag','APAT_efr_avg');  if ~isempty(old), close(old); end
    fh = figure('Name',nm,'NumberTitle','off','Visible','off','Color','w','Tag','APAT_efr_avg', ...
        'Units','normalized','Position',[0.05 0.1 0.85 0.75]);
    ax = axes(fh, 'Position',[L 0.24 R-L 0.62], 'Tag','efr_tile');  hold(ax,'on');
    if rel, plot(ax, [1e-3 1e6], [0 0], 'k--', 'LineWidth',1.5, 'HandleVisibility','off'); end
    % conditions with data; log x-axis and dodge (fraction of the band spacing)
    has = find(arrayfun(@(c) ~isempty(A.trajectory{1,c}) && ~isempty(A.dAMpower{1,c}), 1:numel(A.dAMpower)));
    trs = [];  for c = has, trs = [trs, double(A.trajectory{1,c}(:)')]; end %#ok<AGROW>
    trs = trs(isfinite(trs) & trs > 0);
    set(ax, 'XScale','log');
    sp = 0.1;                                      % band spacing (log10 units)
    if numel(unique(trs)) > 1, u = unique(trs); sp = median(diff(log10(u))); xlim(ax, [u(1)*10^(-0.6*sp), u(end)*10^(0.6*sp)]); end
    offs = apat_dodge(numel(has)) * sp;
    [ms, sa] = apat_ms(ax, 0.7*sp);   % points at true x: size from the x spacing
    for j = 1:numel(has)
        c  = has(j);
        tr = A.trajectory{1,c};  pw = A.dAMpower{1,c};
        xf = 10^offs(j);                           % multiplicative offset on the log axis
        ci  = c + col_offset;
        clr = colors(mod(ci-1, size(colors,1)) + 1, 1:3);
        shp = strtrim(char(shapes(mod(ci-1, size(shapes,1)) + 1, :)));  if isempty(shp), shp = 'o'; end
        % individual subjects (hidden by default)
        for s = 1:size(A.all_dAMpower, 1)
            ys = A.all_dAMpower{s,c};  xs = A.all_trajectory{s,c};
            if isempty(ys) || isempty(xs), continue; end
            m = min(numel(xs), numel(ys));
            if numel(Chins2Run) >= s, sn = char(Chins2Run{s}); else, sn = sprintf('Subject %d', s); end
            jit = 10^(((mod(s*7,11)/10) - 0.5) * 0.06 * sp);
            scatter(ax, xs(1:m)*xf*jit, ys(1:m), sa, clr, shp, 'filled', 'MarkerFaceAlpha',0.30, ...
                'MarkerEdgeColor','none', 'HandleVisibility','off', 'Tag','efr_subj_pts', ...
                'Visible','off', 'DisplayName',sn);
        end
        if isfield(A,'NFpower') && numel(A.NFpower) >= c && ~isempty(A.NFpower{1,c})
            plot(ax, tr, A.NFpower{1,c}, '--', 'Color',clr, 'LineWidth',1.5, 'HandleVisibility','off');
        end
        errorbar(ax, tr*xf, pw, A.dAMpower_std{1,c}, 'Marker',shp, 'LineStyle','-', 'LineWidth',2, ...
            'MarkerSize',ms, 'Color',clr, 'MarkerFaceColor',clr, 'MarkerEdgeColor',clr, 'HandleVisibility','off');
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
    title(ax, 'dAM Power', 'FontSize',14, 'FontWeight','bold');
    apat_xgroups(ax, trs);                         % one column per modulation band
    % figure title (axes, survives embedding)
    axH = axes(fh, 'Position',[0 0.92 1 0.06], 'Visible','off');
    text(axH, 0.5, 0.5, sprintf('EFR dAM 4 kHz — %d dB SPL', round(all_levels(li))), 'FontSize',16, ...
        'FontWeight','bold', 'HorizontalAlignment','center', 'Color',[0.15 0.15 0.15]);
    % legends at the bottom: conditions (line + marker) and the noise-floor key
    if ~isempty(names)
        LC = struct('clr',{},'shp',{},'label',{});
        for i = 1:numel(names)
            ci  = cidx_list(i);
            shp = strtrim(char(shapes(mod(ci-1, size(shapes,1)) + 1, :)));  if isempty(shp), shp = 'o'; end
            LC(end+1) = struct('clr',colors(ci,1:3), 'shp',shp, 'label',names{i}); %#ok<AGROW>
        end
        keys = struct('args',{{'--','Color',[0.5 0.5 0.5],'LineWidth',1.5}}, 'label','Noise Floor');
        apat_legend(fh, ax, LC, keys, L, R - L);
    end
end
end
