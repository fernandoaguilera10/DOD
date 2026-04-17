function plot_ind_efr(data_by_level, all_levels, plot_type, colors, shapes, ...
    Conds2Run, Chins2Run, all_Conds2Run, ChinIND, CondIND, outpath, idx_plot_relative, conds_idx)
%PLOT_IND_EFR  Accumulate per-condition lines on a per-subject multi-level figure.
%   Called once per subject/condition. The figure is found-or-created by name
%   so it persists across condition calls for hold-on accumulation.
%
%   data_by_level : cell{1,n_levels} of efr structs (empty = level not found)
%   all_levels    : sorted numeric array of dB SPL levels
%   plot_type     : 'RAM' or 'dAM'

subj_name = Chins2Run{ChinIND};
n_levels  = numel(all_levels);

switch plot_type
    case 'RAM'
        fig_name    = [subj_name ' | EFR RAM'];
        sgtitle_str = sprintf('EFR RAM 223 Hz  |  %s', subj_name);
        y_units     = 'PLV';
        x_units     = 'Frequency (Hz)';
    case 'dAM'
        fig_name    = [subj_name ' | EFR dAM'];
        sgtitle_str = sprintf('EFR dAM 4 kHz  |  %s', subj_name);
        y_units     = 'Power (dB)';
        x_units     = 'Modulation Frequency (Hz)';
end

%% Find or create named figure with one subplot per level
fh = findobj('Type','figure','Name',fig_name);
if isempty(fh)
    fh = figure('Name',fig_name,'NumberTitle','off','Visible','off');
    set(fh,'Units','normalized','OuterPosition',[0.05 0.1 min(0.35*n_levels,0.95) 0.75]);
    for li = 1:n_levels
        ax = subplot(1, n_levels, li);
        ax.Tag = sprintf('lvl_%d', all_levels(li));
        hold(ax,'on'); box(ax,'off');
        title(ax, sprintf('%d dB SPL', all_levels(li)), 'FontSize',14,'FontWeight','bold');
        ylabel(ax, y_units, 'FontWeight','bold','FontSize',14);
        xlabel(ax, x_units, 'FontWeight','bold','FontSize',14);
        set(ax,'FontSize',14); grid(ax,'on'); box(ax,'off');
        if strcmp(plot_type,'RAM'),  ylim(ax,[0,1]); end
        if strcmp(plot_type,'dAM'),  set(ax,'XScale','log'); end
    end
    sgtitle(fh, sgtitle_str, 'FontSize',16,'FontWeight','bold');
else
    fh = fh(1);
    set(0,'CurrentFigure',fh);
end

%% Plot current condition onto each level subplot
for li = 1:n_levels
    if isempty(data_by_level{li}), continue; end
    ax = findobj(fh,'Type','axes','Tag',sprintf('lvl_%d',all_levels(li)));
    if isempty(ax), continue; end
    ax = ax(1);  d = data_by_level{li};
    switch plot_type
        case 'RAM'
            plot(ax, d.peaks_locs, d.peaks, ...
                'Marker',shapes(CondIND,:),'LineStyle','-','LineWidth',3, ...
                'Color',colors(CondIND,:),'MarkerSize',9, ...
                'MarkerFaceColor',colors(CondIND,:),'MarkerEdgeColor',colors(CondIND,:));
        case 'dAM'
            plot(ax, d.smooth.f, d.smooth.dAM, ...
                'Marker',shapes(CondIND,:),'LineStyle','-','LineWidth',3, ...
                'Color',colors(CondIND,:),'MarkerSize',9, ...
                'MarkerFaceColor',colors(CondIND,:),'MarkerEdgeColor',colors(CondIND,:));
            plot(ax, d.smooth.f, d.smooth.NF, ...
                'LineStyle','--','LineWidth',2,'Color',colors(CondIND,:), ...
                'HandleVisibility','off');
    end
end

%% Refresh legend on first subplot that has data — shows conditions plotted so far
first_li = find(~cellfun(@isempty, data_by_level), 1);
if ~isempty(first_li)
    ax_leg = findobj(fh,'Type','axes','Tag',sprintf('lvl_%d',all_levels(first_li)));
    if ~isempty(ax_leg)
        plotted_cond_idxs = conds_idx(conds_idx <= CondIND);
        cond_labels = arrayfun(@(ci) strsplit(all_Conds2Run{ci},filesep), ...
            plotted_cond_idxs, 'UniformOutput',false);
        cond_labels = cellfun(@(c) c{end}, cond_labels, 'UniformOutput',false);
        legend(ax_leg(1), cond_labels, 'Location','southoutside', ...
            'Orientation','horizontal','Box','off','FontSize',12);
    end
end
end
