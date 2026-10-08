function plot_ind_oae(data, EXPname, colors, Conds2Run, Chins2Run, all_Conds2Run, ChinIND, CondIND, outpath, shapes, conds_idx)
%PLOT_IND_OAE  Per-condition OAE individual plots routed into the Results tab.
%
%   Figure naming follows the "Category|Label" convention for embed_results:
%     Amplitudes|<cond>  — one figure per condition (FigFreqDD toggles)
%     Summary|<EXPname>  — one figure accumulated across all conditions
cwd = pwd;
cond_parts = strsplit(all_Conds2Run{CondIND}, filesep);
cond_label = cond_parts{end};

has_epl = isfield(data,'epl') && ~isempty(data.epl) && isfield(data.epl,'f');
has_spl = isfield(data,'spl') && ~isempty(data.spl) && isfield(data.spl,'f');

plot_types = {};
if has_epl, plot_types{end+1} = 'EPL'; end
if has_spl, plot_types{end+1} = 'SPL'; end
if isempty(plot_types), return; end
n_plots = numel(plot_types);

if strcmp(EXPname,'DPOAE')
    x_units = 'F2 Frequency (kHz)';
else
    x_units = 'Frequency (kHz)';
end

% Axes positions for explicit layout (reliable in headless mode)
if n_plots == 1
    ax_positions = {[0.13 0.15 0.76 0.72]};
else
    ax_positions = {[0.09 0.15 0.36 0.72], [0.57 0.15 0.36 0.72]};
end

% Summary axes positions: leave bottom 10% for legend
if n_plots == 1
    sum_ax_positions = {[0.13 0.18 0.76 0.68]};
else
    sum_ax_positions = {[0.09 0.18 0.36 0.68], [0.57 0.18 0.36 0.68]};
end

%% ── Per-condition Amplitudes figure (one per condition, toggled by dropdown) ──
nm_amp = sprintf('Amplitudes|%s', cond_label);
fh_amp = find_or_clear(nm_amp);

fig_title = sprintf('%s  |  %s  |  %s', EXPname, Chins2Run{ChinIND}, cond_label);
add_fig_title(fh_amp, fig_title);

amp_axes = cell(1, n_plots);
for ti = 1:n_plots
    pt = plot_types{ti};
    ax = axes(fh_amp, 'Position', ax_positions{ti}); %#ok<LAXES>
    setup_ax(ax, sprintf('Amplitude (dB %s)', pt), x_units, pt);
    draw_oae_full(ax, data.(lower(pt)), colors(CondIND,:), shapes(CondIND,:), true);
    set_ylim_centered(ax);
    amp_axes{ti} = ax;
end

% OAE / NF legend centred below axes
lh = legend(amp_axes{1}, {'OAE','NF'}, 'Location','none','Box','off', ...
    'FontSize',10,'Orientation','horizontal');
lh.Units = 'normalized';
lh.Position(1) = max(0, (1 - lh.Position(3)) / 2);
lh.Position(2) = 0.01;

%% ── Summary figure (accumulated across all conditions for this subject) ─────
nm_sum        = sprintf('Summary|%s', EXPname);
fh_sum        = findobj('Type','figure','Name',nm_sum);
is_first_cond = (CondIND == conds_idx(1));
if isempty(fh_sum)
    fh_sum = figure('Name',nm_sum,'NumberTitle','off','Visible','off');
    set(fh_sum,'Units','normalized','OuterPosition',[0.05 0.05 0.9 0.85]);
    build_summary(fh_sum, plot_types, x_units, EXPname, sum_ax_positions);
elseif is_first_cond
    fh_sum = fh_sum(1); clf(fh_sum);
    build_summary(fh_sum, plot_types, x_units, EXPname, sum_ax_positions);
else
    fh_sum = fh_sum(1);
end

% Summary shows band-average only (no full-resolution sweep)
for ti = 1:n_plots
    pt = plot_types{ti};
    ax = findobj(fh_sum,'Type','axes','Tag',pt);
    if isempty(ax), continue; end
    draw_oae_band(ax(1), data.(lower(pt)), colors(CondIND,:), shapes(CondIND,:));
    set_ylim_centered(ax(1));
end

plotted_idxs = conds_idx(conds_idx <= CondIND);
cond_labels  = arrayfun(@(ci) strsplit(all_Conds2Run{ci},filesep), plotted_idxs,'UniformOutput',false);
cond_labels  = cellfun(@(c) c{end}, cond_labels,'UniformOutput',false);
update_legend(fh_sum, colors, shapes, plotted_idxs, cond_labels);

%% ── Export when last condition for this subject is done ─────────────────────
if CondIND == conds_idx(end)
    cd(outpath); drawnow;
    subj = Chins2Run{ChinIND};
    exportgraphics(fh_sum, sprintf('%s_%s_Summary_figure.png', subj, EXPname), 'Resolution',300);
    for ci = 1:numel(conds_idx)
        cp = strsplit(all_Conds2Run{conds_idx(ci)}, filesep);
        fh = findobj('Type','figure','Name', sprintf('Amplitudes|%s', cp{end}));
        if ~isempty(fh)
            exportgraphics(fh(1), sprintf('%s_%s_%s_Amplitudes_figure.png', subj, EXPname, cp{end}), 'Resolution',300);
        end
    end
    cd(cwd);
end
end


% ── Local helpers ─────────────────────────────────────────────────────────────

function fh = find_or_clear(fig_name)
fh = findobj('Type','figure','Name',fig_name);
if isempty(fh)
    fh = figure('Name',fig_name,'NumberTitle','off','Visible','off');
    set(fh,'Units','normalized','OuterPosition',[0.05 0.05 0.9 0.85]);
else
    fh = fh(1); clf(fh);
end
end

function add_fig_title(fh, title_str)
annotation(fh, 'textbox', [0 0.92 1 0.07], 'String', title_str, ...
    'HorizontalAlignment','center','VerticalAlignment','middle', ...
    'EdgeColor','none','FontSize',14,'FontWeight','bold','FitBoxToText','off');
end

function setup_ax(ax, y_label, x_label, tag)
ax.Tag = tag;
hold(ax,'on'); box(ax,'off'); grid(ax,'on'); set(ax,'FontSize',11);
ylabel(ax, y_label, 'FontWeight','bold','FontSize',11);
xlabel(ax, x_label, 'FontWeight','bold','FontSize',11);
title(ax, tag, 'FontSize',12,'FontWeight','bold');
set(ax,'XScale','log');
xlim(ax,[0.5,16]); xticks(ax,[0.5,1,2,4,8,16]);
end

function draw_oae_full(ax, d, clr, mk, show_in_legend)
% Normalise to row vectors to handle column-vector data (e.g. TEOAE)
f   = d.f(:)';     oae = d.oae(:)';   nf = d.nf(:)';
cf  = d.centerFreq(:)';
bOAE = d.bandOAE(:)';  bNF = d.bandNF(:)';

if show_in_legend, hv = 'on'; else, hv = 'off'; end
plot(ax, f,   oae,  '-',  'LineWidth',1.5,'Color',[clr,0.25],'HandleVisibility','off');
plot(ax, f,   nf,   '--', 'LineWidth',1,  'Color',[clr,0.15],'HandleVisibility','off');
plot(ax, cf, bOAE, 'Marker',mk, 'LineStyle','-',    'LineWidth',2,'MarkerSize',9, ...
    'Color',clr,'MarkerFaceColor',clr,'MarkerEdgeColor',clr, ...
    'DisplayName','OAE','HandleVisibility',hv);
plot(ax, cf, bNF,  'x',          'LineStyle','none', 'LineWidth',3,'MarkerSize',9, ...
    'Color',clr,'HandleVisibility','off');
plot(ax, cf, bNF,                 'LineStyle','--',   'LineWidth',1.5, ...
    'Color',[clr,0.50],'DisplayName','NF','HandleVisibility',hv);
end

function draw_oae_band(ax, d, clr, mk)
% Band-averaged only: solid OAE line + dashed NF line (no full-resolution sweep)
cf  = d.centerFreq(:)';
bOAE = d.bandOAE(:)';  bNF = d.bandNF(:)';
plot(ax, cf, bOAE, 'Marker',mk, 'LineStyle','-', 'LineWidth',2,'MarkerSize',9, ...
    'Color',clr,'MarkerFaceColor',clr,'MarkerEdgeColor',clr,'HandleVisibility','off');
plot(ax, cf, bNF,                'LineStyle','--','LineWidth',1.5, ...
    'Color',[clr,0.50],'HandleVisibility','off');
end

function build_summary(fh, plot_types, x_units, EXPname, ax_positions)
n = numel(plot_types);
add_fig_title(fh, sprintf('%s  |  Summary', EXPname));
for ti = 1:n
    ax = axes(fh, 'Position', ax_positions{ti}); %#ok<LAXES>
    setup_ax(ax, sprintf('Amplitude (dB %s)', plot_types{ti}), x_units, plot_types{ti});
end
% Invisible axes to anchor the shared bottom legend
ax_leg = axes(fh,'Position',[0.05 0 0.90 0.09],'Visible','off','Tag','legend_ax');
hold(ax_leg,'on');
end

function update_legend(fh, colors, shapes, plotted_idxs, cond_labels)
ax_leg = findobj(fh,'Type','axes','Tag','legend_ax');
if isempty(ax_leg), return; end
ax_leg = ax_leg(1);
delete(findobj(ax_leg,'Type','line'));
for ci = 1:numel(plotted_idxs)
    idx = plotted_idxs(ci);
    plot(ax_leg, nan, nan, 'Marker',shapes(idx,:),'LineStyle','-','LineWidth',2, ...
        'MarkerSize',9,'Color',colors(idx,:),'MarkerFaceColor',colors(idx,:), ...
        'DisplayName',cond_labels{ci});
end
lh = legend(ax_leg,'Orientation','horizontal','Box','off','FontSize',11,'Location','none');
lh.Units = 'normalized';
lh.Position(1) = max(0, (1 - lh.Position(3)) / 2);
lh.Position(2) = 0.01;
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
