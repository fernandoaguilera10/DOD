function plot_avg_oae(averages, plot_types, EXPname, colors, idx, conds_idx, Chins2Run, Conds2Run, all_Conds2Run, outpath, filenames, counter, idx_plot_relative, shapes)
%PLOT_AVG_OAE  Combined EPL+SPL average figure routed to the Average panel.
%
%   averages   : cell array of average structs — {avg_epl, avg_spl} or {avg_spl}
%   plot_types : matching cell of scale strings — {'EPL','SPL'} or {'SPL'}
%   filenames  : cell array of .mat save names, one per scale
cwd = pwd;

if strcmp(EXPname,'DPOAE')
    x_units = 'F2 Frequency (kHz)';
else
    x_units = 'Frequency (kHz)';
end

n_scales = numel(plot_types);
is_relative = ~isempty(idx_plot_relative);

if is_relative
    ref_parts = strsplit(Conds2Run{idx_plot_relative}, filesep);
    ref_label = ref_parts{end};
    fig_name  = sprintf('%s Average (re. %s)', EXPname, ref_label);
else
    fig_name = sprintf('%s Average', EXPname);
end

%% ── Build figure ─────────────────────────────────────────────────────────────
fh = get_fig(counter, fig_name);
tl = tiledlayout(fh, 1, n_scales, 'TileSpacing','compact','Padding','compact');
title(tl, fig_name,'FontSize',14,'FontWeight','bold');

for si = 1:n_scales
    average   = averages{si};
    pt        = plot_types{si};

    if is_relative
        y_units = sprintf('Amplitude (dB re. %s)', ref_label);
    else
        y_units = sprintf('Amplitude (dB %s)', pt);
    end

    ax = nexttile(tl);
    hold(ax,'on'); grid(ax,'on'); box(ax,'off');
    set(ax,'XScale','log','FontSize',11);
    xlim(ax,[0.5,16]); xticks(ax,[0.5,1,2,4,8,16]);
    ylabel(ax, y_units,'FontWeight','bold','FontSize',11);
    xlabel(ax, x_units,'FontWeight','bold','FontSize',11);
    title(ax, pt,'FontSize',12,'FontWeight','bold');

    temp = cell(1, length(average.oae));

    if ~is_relative
        for cols = 1:length(average.oae)
            if ~isempty(average.bandOAE{1,cols})
                errorbar(ax, average.bandF, average.bandOAE{1,cols}, average.oae_band_std{1,cols}, ...
                    'Marker',shapes(cols,:),'LineStyle','-','LineWidth',2, ...
                    'Color',colors(cols,:),'MarkerSize',9, ...
                    'MarkerFaceColor',colors(cols,:),'MarkerEdgeColor',colors(cols,:), ...
                    'HandleVisibility','off');
                plot(ax, average.bandF, average.bandOAE{1,cols}, ...
                    'Marker',shapes(cols,:),'LineStyle','-','LineWidth',2,'MarkerSize',9, ...
                    'Color',colors(cols,:),'MarkerFaceColor',colors(cols,:),'MarkerEdgeColor',colors(cols,:));
                plot(ax, average.bandF, average.bandNF{1,cols}, ...
                    'LineStyle','--','LineWidth',1.5,'Color',[colors(cols,:),0.50],'HandleVisibility','off');
                temp{1,cols} = sprintf('%s (n=%s)', cell2mat(all_Conds2Run(cols)), mat2str(sum(idx(:,cols))));
            end
        end
    else
        for cols = 1:length(average.oae)
            if ~isempty(average.bandOAE{1,cols})
                errorbar(ax, average.bandF, average.bandOAE{1,cols}, average.oae_band_std{1,cols}, ...
                    'Marker',shapes(cols+1,:),'LineStyle','-','LineWidth',2, ...
                    'Color',colors(cols+1,:),'MarkerSize',9, ...
                    'MarkerFaceColor',colors(cols+1,:),'MarkerEdgeColor',colors(cols+1,:), ...
                    'HandleVisibility','off');
                plot(ax, average.bandF, average.bandOAE{1,cols}, ...
                    'Marker',shapes(cols+1,:),'LineStyle','-','LineWidth',2,'MarkerSize',9, ...
                    'Color',colors(cols+1,:),'MarkerFaceColor',colors(cols+1,:),'MarkerEdgeColor',colors(cols+1,:));
                plot(ax, average.bandF, zeros(size(average.bandF)), ...
                    'LineStyle','--','LineWidth',1.5,'Color','k','HandleVisibility','off');
                temp{1,cols} = sprintf('%s (n=%s)', cell2mat(all_Conds2Run(cols+1)), mat2str(sum(idx(:,cols+1))));
            end
        end
    end

    legend_idx = find(~cellfun(@isempty, temp));
    if ~isempty(legend_idx)
        legend(ax, temp(legend_idx), 'Location','southoutside','Orientation','horizontal', ...
            'Box','off','FontSize',10);
    end
    set_ylim_centered(ax);
end

set(fh,'Units','normalized','Position',[0.2 0.2 0.5 0.6]);

%% ── Save data and export ─────────────────────────────────────────────────────
cd(outpath);
for si = 1:n_scales
    average            = averages{si};
    average.subjects   = Chins2Run;
    average.conditions = [convertCharsToStrings(all_Conds2Run(:)'); idx];
    save(filenames{si}, 'average');
end
exportgraphics(fh, [filenames{1}, '_figure.png'], 'Resolution', 300);
cd(cwd);
end


% ── Local helpers ─────────────────────────────────────────────────────────────

function fh = get_fig(counter, name)
fh = findobj('Type','figure','Tag', sprintf('oae_avg_%d', counter));
if isempty(fh)
    fh = figure('Name',name,'NumberTitle','off','Tag',sprintf('oae_avg_%d',counter),'Visible','off');
else
    fh = fh(1); clf(fh);
end
set(fh,'Units','normalized','Position',[0.2 0.2 0.5 0.6]);
end

function set_ylim_centered(ax, pad)
if nargin < 2, pad = 0.15; end
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
