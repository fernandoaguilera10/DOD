function plot_avg_efr_dAM_tabs(averages, all_levels, colors, shapes, idx, all_Conds2Run, idx_plot_relative)
%PLOT_AVG_EFR_DAM_TABS  Create combined "dAM Power|All Levels" figure for app embedding.
%
%   One figure is created with Visible='off' for embedding into the app:
%     "dAM Power|All Levels" — dAM power vs modulation frequency per level,
%     shown as side-by-side subplots so every level is visible simultaneously.

valid_li = find(~cellfun(@isempty, averages));
if isempty(valid_li), return; end
n_valid = numel(valid_li);

n_colors   = size(colors, 1);
n_shapes   = size(shapes,  1);
col_offset = double(~isempty(idx_plot_relative));   % 0=absolute, 1=relative

% Legend labels from first valid average
av0           = averages{valid_li(1)};
legend_string = build_legend_local(av0.dAMpower, col_offset, idx, all_Conds2Run);

% Axis layout
PAD_L = 0.10;  PAD_R = 0.03;
PAD_T = 0.13;  PAD_B = 0.20;
inter = 0.04;
w_ax  = (1 - PAD_L - PAD_R - (n_valid-1)*inter) / max(n_valid, 1);

fh = figure('Name','dAM Power|All Levels','NumberTitle','off', ...
    'Visible','off','Color','w','Units','normalized', ...
    'Position',[0.05 0.1 min(0.3*n_valid+0.2, 0.9) 0.75]);

for k = 1:n_valid
    li      = valid_li(k);
    average = averages{li};

    x  = PAD_L + (k-1)*(w_ax + inter);
    ax = axes(fh, 'Position',[x PAD_B w_ax 1-PAD_T-PAD_B]); %#ok<LAXES>
    hold(ax,'on'); grid(ax,'on'); box(ax,'off');

    for c = 1:numel(average.dAMpower)
        cidx   = mod(c - 1 + col_offset, n_colors) + 1;
        sh_idx = mod(c - 1 + col_offset, n_shapes) + 1;
        traj   = average.trajectory{1,c};
        pwr    = average.dAMpower{1,c};
        pwr_sd = average.dAMpower_std{1,c};
        if isempty(traj) || isempty(pwr), continue; end
        dname = '';
        if c <= numel(legend_string), dname = legend_string{c}; end
        errorbar(ax, traj, pwr, pwr_sd, ...
            'Marker',shapes(sh_idx,:),'LineStyle','-', ...
            'LineWidth',2,'MarkerSize',9,'CapSize',5, ...
            'Color',colors(cidx,:),'MarkerFaceColor',colors(cidx,:), ...
            'DisplayName',dname);
    end

    if ~isempty(idx_plot_relative)
        yline(ax, 0,'k--','LineWidth',1.5,'HandleVisibility','off');
    end

    set_ylim_local(ax);
    set(ax,'XScale','log','FontSize',13);
    title(ax, sprintf('%.0f dB SPL', all_levels(li)),'FontWeight','bold','FontSize',14);
    if k == 1
        if isempty(idx_plot_relative)
            ylabel(ax,'Power (dB)','FontWeight','bold','FontSize',14);
        else
            ylabel(ax,'Power Shift (re. Baseline)','FontWeight','bold','FontSize',14);
        end
    end
    xlabel(ax,'Modulation Frequency (Hz)','FontWeight','bold','FontSize',13);
    hold(ax,'off');
end

% Legend anchored to last subplot
if n_valid >= 1 && ~isempty(legend_string)
    ax_last = findobj(fh,'Type','axes');
    ax_last = ax_last(1);
    legend(ax_last, legend_string,'Location','northeast','FontSize',12,'Box','off');
end
annotation(fh,'textbox',[0 0.93 1 0.07], ...
    'String','EFR dAM 4 kHz — Average Power Spectrum', ...
    'FontWeight','bold','FontSize',14,'HorizontalAlignment','center', ...
    'EdgeColor','none','FitBoxToText','off');
end


% ── Local helpers ─────────────────────────────────────────────────────────

function ls = build_legend_local(avg_field, col_offset, idx, all_Conds2Run)
n_c  = size(avg_field, 2);
temp = cell(1, n_c);
for c = 1:n_c
    ci = c + col_offset;
    if ci <= numel(all_Conds2Run) && ci <= size(idx,2)
        parts = strsplit(cell2mat(all_Conds2Run(ci)), filesep);
        lbl   = parts{end};
        temp{c} = sprintf('%s (n=%d)', lbl, sum(idx(:,ci)));
    end
end
ls = temp(~cellfun(@isempty, temp));
end


function set_ylim_local(ax, pad)
if nargin < 2, pad = 0.12; end
all_y = [];
for k = 1:numel(ax.Children)
    try
        yd = double(get(ax.Children(k),'YData'));
        all_y = [all_y, yd(isfinite(yd))]; %#ok<AGROW>
        if isprop(ax.Children(k),'YNegativeDelta')
            v = yd - double(get(ax.Children(k),'YNegativeDelta'));
            all_y = [all_y, v(isfinite(v))]; %#ok<AGROW>
        end
        if isprop(ax.Children(k),'YPositiveDelta')
            v = yd + double(get(ax.Children(k),'YPositiveDelta'));
            all_y = [all_y, v(isfinite(v))]; %#ok<AGROW>
        end
    catch, end
end
if isempty(all_y), return; end
lo = min(all_y); hi = max(all_y);
rng = hi - lo;
if rng == 0, rng = max(abs(lo), 0.1); end
ylim(ax, [lo - pad*rng, hi + pad*rng]);
end
