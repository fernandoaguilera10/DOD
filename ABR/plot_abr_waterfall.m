function plot_abr_waterfall(waveforms, latencies, colors, shapes, ...
        Chins2Run, Conds2Run, all_Conds2Run, conds_idx, freq, outpath, fig_num)
%PLOT_ABR_WATERFALL  Waterfall plot of ABR waveforms across sound levels.
%
%   One figure per frequency.  Waveforms are averaged across subjects for
%   each (level, condition).  Levels are stacked from highest (top) to
%   lowest (bottom).  Wave I–V peak positions are marked using the average
%   latencies from avg_abr output.
%
%   Figure.Name is set to 'Waveforms|<freq_label>' so the app can route it
%   into the correct tab (Waveforms) and frequency slot.
%
%Author: Fernando Aguilera de Alba / Andrew Sivaprakasam
%Last Updated: Apr 2026

%% Frequency label
if freq == 0
    freq_label = 'Click';
    freq_str   = 'click';
elseif freq >= 1000
    freq_label = sprintf('%.4g kHz', freq/1000);
    freq_str   = [mat2str(freq), 'Hz'];
else
    freq_label = sprintf('%.4g Hz', freq);
    freq_str   = [mat2str(freq), 'Hz'];
end

%% Find reference time vector and level vector from first valid cell
n_subj  = size(waveforms.y, 1);
n_conds = size(waveforms.y, 2);
t_ref = []; levels = [];
for r = 1:n_subj
    for c = 1:n_conds
        if ~isempty(waveforms.y{r,c}) && ~isempty(waveforms.x{r,c})
            t_ref  = waveforms.x{r,c};            % time vector in ms
            levels = waveforms.levels{r,c};       % levels, descending (e.g. 80→40)
            break;
        end
    end
    if ~isempty(t_ref), break; end
end
if isempty(t_ref), return; end
n_levels = length(levels);
n_t      = length(t_ref);

%% Average waveforms across subjects per (level, condition)
wave_mean = cell(n_levels, n_conds);   % each: [1 × n_t]
for lev = 1:n_levels
    for c = 1:n_conds
        stack = [];
        for r = 1:n_subj
            y = waveforms.y{r,c};
            x = waveforms.x{r,c};
            if isempty(y) || isempty(x), continue; end
            if size(y,1) < lev, continue; end
            % Resample to reference time vector if needed
            if length(x) ~= n_t || any(abs(x - t_ref) > 1e-6)
                y_row = interp1(x, y(lev,:), t_ref, 'linear', nan);
            else
                y_row = y(lev,:);
            end
            stack = [stack; y_row]; %#ok<AGROW>
        end
        if ~isempty(stack)
            wave_mean{lev,c} = nanmean(stack, 1);
        end
    end
end

%% Average latencies per (level, wave) across all used conditions
wave_fields = {'avg_w1','avg_w2','avg_w3','avg_w4','avg_w5'};
lat_mean = nan(n_levels, 5);   % rows = levels, cols = waves I–V
for w = 1:5
    fld = wave_fields{w};
    if ~isfield(latencies, fld), continue; end
    for lev = 1:n_levels
        vals = [];
        for c = conds_idx(:)'
            col_data = latencies.(fld){1,c};
            if isempty(col_data) || size(col_data,1) < lev, continue; end
            vals(end+1) = col_data(lev); %#ok<AGROW>
        end
        lat_mean(lev, w) = nanmean(vals);
    end
end

%% Compute vertical spacing
all_ranges = [];
for lev = 1:n_levels
    for c = conds_idx(:)'
        if ~isempty(wave_mean{lev,c})
            r = max(wave_mean{lev,c}) - min(wave_mean{lev,c});
            if r > 0, all_ranges(end+1) = r; end %#ok<AGROW>
        end
    end
end
if isempty(all_ranges), return; end
vert_spacing = 1.4 * median(all_ranges);

%% Create figure
fh = figure(fig_num); clf;
set(fh, 'Name', ['Waveforms|' freq_label], ...
    'Units','Normalized','OuterPosition',[0.05 0.05 0.50 0.90]);
ax = axes(fh); hold(ax, 'on');

y_ticks      = zeros(1, n_levels);
y_tick_labels = cell(1, n_levels);
wave_labels  = {'W I','W II','W III-IV','W IV','W V'};

for lev = 1:n_levels
    offset = -(lev - 1) * vert_spacing;
    y_ticks(lev)       = offset;
    y_tick_labels{lev} = sprintf('%d dB', levels(lev));

    % --- Waveforms (one trace per condition, coloured) ---
    first_plotted = false;
    for c = conds_idx(:)'
        if isempty(wave_mean{lev,c}), continue; end
        cond_parts = strsplit(all_Conds2Run{c}, filesep);
        lbl = cond_parts{end};
        if ~first_plotted
            plot(ax, t_ref, wave_mean{lev,c} + offset, ...
                'Color', colors(c,:), 'LineWidth', 2.5, ...
                'DisplayName', lbl);
            first_plotted = true;
        else
            plot(ax, t_ref, wave_mean{lev,c} + offset, ...
                'Color', colors(c,:), 'LineWidth', 2.5, ...
                'HandleVisibility','off');
        end
    end

    % --- Peak markers ---
    % Use the first condition's average waveform for amplitude reference
    ref_wf = [];
    for c = conds_idx(:)'
        if ~isempty(wave_mean{lev,c}), ref_wf = wave_mean{lev,c}; break; end
    end
    if isempty(ref_wf), continue; end

    for w = 1:5
        lat_ms = lat_mean(lev, w);
        if isnan(lat_ms), continue; end
        [~, t_idx] = min(abs(t_ref - lat_ms));
        if t_idx < 1 || t_idx > length(ref_wf), continue; end
        pk_amp = ref_wf(t_idx) + offset;
        plot(ax, lat_ms, pk_amp, shapes(w), ...
            'Color', colors(w+4,:), 'MarkerFaceColor', colors(w+4,:), ...
            'MarkerSize', 9, 'LineWidth', 1.5, ...
            'HandleVisibility','off');
    end
end
hold(ax,'off');

%% Formatting
xlim(ax, [0 20]);
yticks(ax, flip(y_ticks));
yticklabels(ax, flip(y_tick_labels));
xlabel(ax, 'Time (ms)',     'FontWeight','bold','FontSize',16);
ylabel(ax, 'Sound Level',   'FontWeight','bold','FontSize',16);
title(ax,  sprintf('ABR Waveforms – %s', freq_label), ...
    'FontSize',18,'FontWeight','bold');
grid(ax,'on');
set(ax,'FontSize',14);

% Build wave legend handles manually (invisible sentinel points)
hold(ax,'on');
for w = 1:5
    plot(ax, nan, nan, shapes(w), ...
        'Color', colors(w+4,:), 'MarkerFaceColor', colors(w+4,:), ...
        'MarkerSize', 9, 'LineWidth', 1.5, 'DisplayName', wave_labels{w});
end
hold(ax,'off');
legend(ax,'Location','northeastoutside','FontSize',13,'Box','off');

set(fh,'Units','Normalized','OuterPosition',[0.05 0.05 0.50 0.90]);

%% Export PNG
cwd = pwd;
cd(outpath);
fn_out = ['ABR_WaterfallWaveforms_' freq_str];
print(fh, fn_out, '-dpng', '-r300');
cd(cwd);
end
