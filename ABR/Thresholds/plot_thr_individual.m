function figs = plot_thr_individual(pd, fs, cond_name, clr)
%PLOT_THR_INDIVIDUAL  ABR Thresholds — one figure per frequency.
%   Left : waveform stack (highest level on top). Levels at/above threshold
%          in the condition colour, below threshold in grey, threshold
%          marked between levels.
%   Right: response growth (normalised bootstrap cross-correlation vs
%          level) with the sigmoid fit and the threshold, plus a summary card.
%   Figure Name is 'FreqLabel|Condition', so the app shows one tab per
%   frequency with a Condition dropdown (same layout as ABR Peaks).
if nargin < 4 || isempty(clr), clr = [0.20 0.40 0.70]; end
clr  = clr(1:3);
GREY = [0.74 0.74 0.74];  GOLD = [0.81 0.73 0.57];  GOLD_DK = [0.55 0.45 0.25];
INK  = [0.15 0.15 0.15];  MUTE = [0.45 0.45 0.45];
figs = gobjects(0);

for f = 1:numel(pd)
    p    = pd(f);
    flbl = thr_freq_label(p.freq);
    fh   = figure('Name',sprintf('%s|%s',flbl,cond_name),'NumberTitle','off', ...
                  'Visible','off','Color','w');
    figs(end+1) = fh; %#ok<AGROW>
    if isempty(p.wforms) || isempty(p.lev)
        ax = axes(fh,'Position',[0 0 1 1]); axis(ax,'off');
        text(ax,0.5,0.5,'No waveform data for this frequency.', ...
            'HorizontalAlignment','center','FontSize',14,'Color',MUTE);
        continue;
    end

    % ── data (sorted high → low level) ───────────────────────────────
    thr = p.thresh;
    [lev, ord] = sort(p.lev(:)','descend');
    W   = p.wforms(:,ord);
    cor = p.cor(:)';  cer = p.cor_err(:)';
    if numel(cor) == numel(ord), cor = cor(ord); cer = cer(ord); end
    in_uv = false;
    if max(abs(W(:))) < 1e-2, W = W/2*1e6; in_uv = true; end   % V (sum of halves) → µV
    t   = (0:size(W,1)-1)/fs*1e3;
    nL  = numel(lev);
    vsp = 1.5*median(max(W,[],1) - min(W,[],1));
    if ~(vsp > 0), vsp = 1; end
    off = -(0:nL-1)*vsp;
    if isnan(thr), above = true(1,nL); else, above = lev >= thr - 1e-6; end

    % ── waveform stack ───────────────────────────────────────────────
    axW = axes(fh,'Position',[0.07 0.10 0.50 0.84]); hold(axW,'on');
    W(isnan(W)) = 0;
    for k = nL:-1:1
        if above(k), c = clr; lw = 2.5; else, c = GREY; lw = 2; end
        plot(axW, t, W(:,k)+off(k), 'Color',c, 'LineWidth',lw);
    end
    xl = [0 min(20, t(end))];
    xlim(axW, xl);
    yy = W + off;                                       % traces as drawn
    y_top = max(yy(:));  y_bot = min(yy(:));
    pad = 0.06*(y_top - y_bot);
    ylim(axW, [min(y_bot, min(off)-0.8*vsp) - pad, y_top + pad]);
    % Threshold marker between the bracketing levels
    if ~isnan(thr) && nL >= 2
        [lu, iu] = unique(lev);
        y_thr = interp1(lu, off(iu), thr, 'linear', 'extrap');
        y_thr = min(max(y_thr, min(off)-0.5*vsp), max(off)+0.5*vsp);
        plot(axW, xl, [y_thr y_thr], '--', 'Color',GOLD_DK, 'LineWidth',1.5);
        text(axW, xl(2) + 0.01*diff(xl), y_thr, sprintf('Threshold\n%.1f dB', thr), ...
            'Color',GOLD_DK, 'FontSize',12, 'FontWeight','bold', 'Clipping','off', ...
            'HorizontalAlignment','left', 'VerticalAlignment','middle');
    end
    % Scale bar (bottom-right, beside the lowest trace)
    sb = nice_bar(vsp*0.6);
    x_sb = xl(2) - 0.02*diff(xl);  y_sb = min(off) - 0.75*vsp;
    plot(axW, [x_sb x_sb], [y_sb y_sb+sb], 'k-', 'LineWidth',3);
    if in_uv, u = ' \muV'; else, u = ''; end
    text(axW, x_sb - 0.01*diff(xl), y_sb + sb/2, sprintf('%g%s', sb, u), ...
        'FontSize',12, 'HorizontalAlignment','right', 'VerticalAlignment','middle');
    % Level tick labels: grey below threshold
    tl = cell(1,nL);
    for k = 1:nL
        if above(k), cc = INK; else, cc = GREY; end
        tl{k} = sprintf('\\color[rgb]{%.2f,%.2f,%.2f}%g', cc, round(lev(k)));
    end
    set(axW, 'YTick',fliplr(off), 'YTickLabel',fliplr(tl), 'TickLabelInterpreter','tex', ...
        'FontSize',14, 'Box','off', 'XColor',INK, 'YColor',INK);
    grid(axW,'on');
    xlabel(axW, 'Time (ms)', 'FontWeight','bold');
    ylabel(axW, 'Level (dB SPL)', 'FontWeight','bold');

    % ── response growth (correlation vs level) ───────────────────────
    axC = axes(fh,'Position',[0.70 0.10 0.28 0.84]); hold(axC,'on');
    x_rng = [max(0, min(lev)-10), min(100, max(lev)+10)];
    y_lo  = min([0, cor - cer]) - 0.05;  y_hi = max([1, cor + cer]) + 0.22;
    has_fit = isfield(p,'cor_fit_vals') && any(p.cor_fit_vals ~= 0);
    if ~isnan(thr)
        patch(axC, [x_rng(1) thr thr x_rng(1)], [y_lo y_lo y_hi y_hi], [0.95 0.95 0.95], ...
            'EdgeColor','none', 'HandleVisibility','off');
    end
    if has_fit
        xf = 1:numel(p.cor_fit_vals);
        plot(axC, xf, p.cor_fit_vals, '-', 'Color',[0.35 0.35 0.35], 'LineWidth',2);
    end
    if any(~above)
        errorbar(axC, lev(~above), cor(~above), cer(~above), 'o', 'Color',GREY, ...
            'MarkerFaceColor',GREY, 'MarkerEdgeColor',GREY, 'MarkerSize',10, 'LineWidth',2);
    end
    if any(above)
        errorbar(axC, lev(above), cor(above), cer(above), 'o', 'Color',clr, ...
            'MarkerFaceColor',clr, 'MarkerEdgeColor',clr, 'MarkerSize',10, 'LineWidth',2);
    end
    if ~isnan(thr)
        plot(axC, [thr thr], [y_lo y_hi], '--', 'Color',GOLD_DK, 'LineWidth',1.5);
        if has_fit
            y_t = interp1(1:numel(p.cor_fit_vals), p.cor_fit_vals, min(max(thr,1),numel(p.cor_fit_vals)));
            plot(axC, thr, y_t, 'd', 'MarkerSize',13, 'MarkerFaceColor',GOLD, 'MarkerEdgeColor',GOLD_DK, 'LineWidth',1.5);
        end
    else
        text(axC, mean(x_rng), 0.5, 'Fit needs at least 5 levels', ...
            'HorizontalAlignment','center', 'Color',MUTE, 'FontSize',11);
    end
    xlim(axC, x_rng);  ylim(axC, [y_lo y_hi]);
    set(axC, 'FontSize',14, 'Box','off');
    grid(axC,'on');
    xlabel(axC, 'Level (dB SPL)', 'FontWeight','bold');
    ylabel(axC, 'Correlation (norm.)', 'FontWeight','bold');

    % ── threshold value (inside the growth plot, top-left) ────────────
    if isnan(thr), vs = 'Threshold: —'; else, vs = sprintf('Threshold: %.1f dB SPL', thr); end
    text(axC, 0.04, 0.96, vs, 'Units','normalized', 'FontSize',14, 'FontWeight','bold', ...
        'Color',INK, 'HorizontalAlignment','left', 'VerticalAlignment','top', ...
        'BackgroundColor','w', 'Margin',2);
end
end


function s = nice_bar(v)
c = [0.1 0.2 0.25 0.5 1 2 2.5 5 10 20 50];
s = c(find(c <= v, 1, 'last'));
if isempty(s), s = c(1); end
end
