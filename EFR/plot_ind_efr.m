function plot_ind_efr(data_by_level, all_levels, plot_type, colors, shapes, ...
    Conds2Run, Chins2Run, all_Conds2Run, ChinIND, CondIND, outpath, idx_plot_relative, conds_idx)
%PLOT_IND_EFR  Per-condition EFR individual plots routed into the Results tab.
%
%   Figure naming follows the "Category|Label" convention for embed_results:
%     Time Domain|<cond>       — one figure per condition (FigFreqDD switches)
%     Frequency Domain|<cond>  — one figure per condition (FigFreqDD switches)
%     Summary|EFR <type>       — one figure accumulated across all conditions
%
%   Summary carries a shared horizontal legend at the bottom centre.
%   Time Domain and Frequency Domain show one condition each — no legend needed.

n_levels = numel(all_levels);
cond_parts = strsplit(all_Conds2Run{CondIND}, filesep);
cond_label = cond_parts{end};

switch plot_type
    case 'RAM', type_str = 'EFR RAM';  sup_td = sprintf('EFR RAM 223 Hz  |  %s  |  %s', Chins2Run{ChinIND}, cond_label);
    case 'dAM', type_str = 'EFR dAM';  sup_td = sprintf('EFR dAM 4 kHz  |  %s  |  %s', Chins2Run{ChinIND}, cond_label);
end
sup_sum = sprintf('%s  |  %s', type_str, Chins2Run{ChinIND});

%% ── Time Domain figure (one per condition; RAM only) ──────────────────
if strcmp(plot_type,'RAM')
    nm_time = sprintf('Time Domain|%s', cond_label);
    fh_time = find_or_clear(nm_time);
    tl_time = tiledlayout(fh_time, 1, n_levels,'TileSpacing','compact','Padding','compact');
    title(tl_time, sup_td,'FontSize',16,'FontWeight','bold');
    for li = 1:n_levels
        ax = nexttile(tl_time);
        ax.Tag = sprintf('lvl_%d', all_levels(li));
        hold(ax,'on'); box(ax,'off'); grid(ax,'on'); set(ax,'FontSize',14);
        title(ax, sprintf('%d dB SPL', all_levels(li)),'FontSize',14,'FontWeight','bold');
        ylabel(ax,'Amplitude (\muV)','FontWeight','bold','FontSize',14);
        xlabel(ax,'Time (s)','FontWeight','bold','FontSize',14);
    end
end

%% ── Frequency Domain figure (one per condition) ───────────────────────
nm_freq = sprintf('Frequency Domain|%s', cond_label);
fh_freq = find_or_clear(nm_freq);
tl_freq = tiledlayout(fh_freq, 1, n_levels,'TileSpacing','compact','Padding','compact');
title(tl_freq, sup_td,'FontSize',16,'FontWeight','bold');
for li = 1:n_levels
    ax = nexttile(tl_freq);
    ax.Tag = sprintf('lvl_%d', all_levels(li));
    hold(ax,'on'); box(ax,'off'); grid(ax,'on'); set(ax,'FontSize',14);
    title(ax, sprintf('%d dB SPL', all_levels(li)),'FontSize',14,'FontWeight','bold');
    [ylbl,xlbl] = freq_labels(plot_type);
    ylabel(ax,ylbl,'FontWeight','bold','FontSize',14);
    xlabel(ax,xlbl,'FontWeight','bold','FontSize',14);
    if strcmp(plot_type,'dAM'), set(ax,'XScale','log'); end
end
% dAM: add a small fixed legend (dAM / NF) on first subplot only
if strcmp(plot_type,'dAM')
    ax1 = findobj(fh_freq,'Type','axes','Tag',sprintf('lvl_%d',all_levels(1)));
    if ~isempty(ax1)
        lh_dam = legend(ax1(1),{'dAM','NF'},'Location','none','Box','off','FontSize',11,'Orientation','horizontal');
        lh_dam.Units = 'normalized';
        lh_dam.Position(1) = (1 - lh_dam.Position(3)) / 2;
        lh_dam.Position(2) = 0.01;
    end
end

%% ── Summary figure (accumulated across conditions) ────────────────────
nm_sum  = sprintf('Summary|%s', type_str);
fh_sum  = findobj('Type','figure','Name',nm_sum);
is_first_cond = (CondIND == conds_idx(1));
if isempty(fh_sum)
    fh_sum = figure('Name',nm_sum,'NumberTitle','off','Visible','off');
    set(fh_sum,'Units','normalized','OuterPosition',[0.05 0.05 0.9 0.85]);
    build_summary(fh_sum, plot_type, n_levels, all_levels, sup_sum);
elseif is_first_cond
    fh_sum = fh_sum(1);  clf(fh_sum);
    build_summary(fh_sum, plot_type, n_levels, all_levels, sup_sum);
else
    fh_sum = fh_sum(1);
end

%% ── Plot data onto each figure ────────────────────────────────────────
for li = 1:n_levels
    if isempty(data_by_level{li}), continue; end
    d   = data_by_level{li};
    clr = colors(CondIND,:);
    mk  = shapes(CondIND,:);
    tag = sprintf('lvl_%d', all_levels(li));

    % Time Domain
    if strcmp(plot_type,'RAM')
        ax = findobj(fh_time,'Type','axes','Tag',tag);
        if ~isempty(ax) && isfield(d,'t') && isfield(d,'t_env')
            plot(ax(1), d.t, d.t_env,'Color',clr,'LineWidth',3);
        end
    end

    % Frequency Domain
    ax = findobj(fh_freq,'Type','axes','Tag',tag);
    if ~isempty(ax)
        ax = ax(1);
        switch plot_type
            case 'RAM'
                plot(ax, d.f, d.plv_env,'LineStyle','-','LineWidth',3,'Color',clr,'HandleVisibility','off');
                plot(ax, d.peaks_locs, d.peaks,'Marker',mk,'LineStyle','none','LineWidth',3,'Color',clr, ...
                    'MarkerSize',9,'MarkerFaceColor',clr,'MarkerEdgeColor',clr);
            case 'dAM'
                plot(ax, d.trajectory, d.dAMpower,'LineStyle','-','LineWidth',3,'Color',clr,'DisplayName','dAM');
                plot(ax, d.trajectory, d.NFpower, 'LineStyle','--','LineWidth',1.5,'Color',clr,'DisplayName','NF');
        end
    end

    % Summary
    ax = findobj(fh_sum,'Type','axes','Tag',tag);
    if ~isempty(ax)
        ax = ax(1);
        switch plot_type
            case 'RAM'
                plot(ax, d.peaks_locs, d.peaks,'Marker',mk,'LineStyle','-','LineWidth',3,'Color',clr, ...
                    'MarkerSize',9,'MarkerFaceColor',clr,'MarkerEdgeColor',clr);
            case 'dAM'
                plot(ax, d.smooth.f, d.smooth.dAM,'Marker',mk,'LineStyle','-','LineWidth',3,'Color',clr, ...
                    'MarkerSize',9,'MarkerFaceColor',clr,'MarkerEdgeColor',clr);
                plot(ax, d.smooth.f, d.smooth.NF,'LineStyle','--','LineWidth',1.5,'Color',clr,'HandleVisibility','off');
        end
    end
end

%% ── Update shared bottom-centre legend on Summary ─────────────────────
plotted_idxs = conds_idx(conds_idx <= CondIND);
cond_labels  = arrayfun(@(ci) strsplit(all_Conds2Run{ci},filesep), plotted_idxs,'UniformOutput',false);
cond_labels  = cellfun(@(c) c{end}, cond_labels,'UniformOutput',false);
update_summary_legend(fh_sum, colors, plotted_idxs, cond_labels);

%% ── Auto y-limits centred on data ────────────────────────────────────────
for li = 1:n_levels
    tag = sprintf('lvl_%d', all_levels(li));
    if strcmp(plot_type,'RAM')
        ax = findobj(fh_time,'Type','axes','Tag',tag);
        if ~isempty(ax), set_ylim_centered(ax(1)); end
    end
    ax = findobj(fh_freq,'Type','axes','Tag',tag);
    if ~isempty(ax), set_ylim_centered(ax(1)); end
    ax = findobj(fh_sum,'Type','axes','Tag',tag);
    if ~isempty(ax), set_ylim_centered(ax(1)); end
end
end


% ── Local helpers ────────────────────────────────────────────────────────

function fh = find_or_clear(fig_name)
fh = findobj('Type','figure','Name',fig_name);
if isempty(fh)
    fh = figure('Name',fig_name,'NumberTitle','off','Visible','off');
    set(fh,'Units','normalized','OuterPosition',[0.05 0.05 0.9 0.85]);
else
    fh = fh(1);  clf(fh);
end
end

function build_summary(fh, plot_type, n_levels, all_levels, sup_title)
% Leave bottom 10% for the shared legend axes.
tl = tiledlayout(fh, 1, n_levels,'TileSpacing','compact','Padding','compact');
tl.OuterPosition = [0 0.10 1 0.90];
title(tl, sup_title,'FontSize',16,'FontWeight','bold');
for li = 1:n_levels
    ax = nexttile(tl);
    ax.Tag = sprintf('lvl_%d', all_levels(li));
    hold(ax,'on'); box(ax,'off'); grid(ax,'on'); set(ax,'FontSize',14);
    title(ax, sprintf('%d dB SPL', all_levels(li)),'FontSize',14,'FontWeight','bold');
    [ylbl,xlbl] = freq_labels(plot_type);
    ylabel(ax,ylbl,'FontWeight','bold','FontSize',14);
    xlabel(ax,xlbl,'FontWeight','bold','FontSize',14);
    if strcmp(plot_type,'dAM'), set(ax,'XScale','log'); end
end
% Create the shared legend axes (invisible, used only to hold the legend)
ax_leg = axes(fh,'Position',[0.05 0 0.90 0.09],'Visible','off','Tag','legend_ax');
hold(ax_leg,'on');
end

function update_summary_legend(fh, colors, plotted_idxs, cond_labels)
ax_leg = findobj(fh,'Type','axes','Tag','legend_ax');
if isempty(ax_leg), return; end
ax_leg = ax_leg(1);
delete(findobj(ax_leg,'Type','line'));
for ci = 1:numel(plotted_idxs)
    plot(ax_leg, nan, nan,'Color',colors(plotted_idxs(ci),:),'LineWidth',3,'DisplayName',cond_labels{ci});
end
lh = legend(ax_leg,'Orientation','horizontal','Box','off','FontSize',13,'Location','none');
lh.Units = 'normalized';
lh.Position(1) = max(0, (1 - lh.Position(3)) / 2);
lh.Position(2) = 0.01;
end

function [ylbl, xlbl] = freq_labels(plot_type)
if strcmp(plot_type,'RAM')
    ylbl = 'PLV';          xlbl = 'Frequency (Hz)';
else
    ylbl = 'Power (dB)';   xlbl = 'Modulation Frequency (Hz)';
end
end

function set_ylim_centered(ax, pad)
if nargin < 2, pad = 0.12; end
all_y = [];
kids  = ax.Children;
for k = 1:numel(kids)
    try
        yd = double(get(kids(k),'YData'));
        all_y = [all_y, yd(isfinite(yd))]; %#ok<AGROW>
        if isprop(kids(k),'YNegativeDelta')
            v = yd - double(get(kids(k),'YNegativeDelta'));
            all_y = [all_y, v(isfinite(v))]; %#ok<AGROW>
        end
        if isprop(kids(k),'YPositiveDelta')
            v = yd + double(get(kids(k),'YPositiveDelta'));
            all_y = [all_y, v(isfinite(v))]; %#ok<AGROW>
        end
    catch, end
end
if isempty(all_y), return; end
lo = min(all_y);  hi = max(all_y);
rng = hi - lo;
if rng == 0, rng = max(abs(lo), 0.1); end
ylim(ax, [lo - pad*rng, hi + pad*rng]);
end
