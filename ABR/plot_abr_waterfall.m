function plot_abr_waterfall(waveforms, latencies, trough_latencies, colors, shapes, ...
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
wave_ci   = cell(n_levels, n_conds);   % 95% CI half-width: 1.96 * SEM
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
            n_valid = sum(~isnan(stack(:,1)));
            if n_valid > 1
                wave_ci{lev,c} = 1.96 * nanstd(stack, 0, 1) / sqrt(n_valid);
            end
        end
    end
end

% Latency field names as stored by avg_abr
wave_lat_fields = {'w1','w2','w3','w4','w5'};

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
wave_labels  = {'W I','W II','W III','W IV','W V'};

% Track which conditions already have a legend entry (one entry per condition total)
cond_in_legend = false(1, size(waveforms.y, 2) + 1);

for lev = 1:n_levels
    offset = -(lev - 1) * vert_spacing;
    y_ticks(lev)       = offset;
    y_tick_labels{lev} = sprintf('%d', levels(lev));

    % --- Waveforms (one trace per condition, coloured) with 95% CI shading ---
    for c = conds_idx(:)'
        if isempty(wave_mean{lev,c}), continue; end
        cond_parts = strsplit(all_Conds2Run{c}, filesep);
        lbl = cond_parts{end};
        % Shaded 95% CI
        if ~isempty(wave_ci{lev,c})
            y_upper = wave_mean{lev,c} + wave_ci{lev,c} + offset;
            y_lower = wave_mean{lev,c} - wave_ci{lev,c} + offset;
            fill(ax, [t_ref, fliplr(t_ref)], [y_upper, fliplr(y_lower)], ...
                colors(c,:), 'FaceAlpha', 0.2, 'EdgeColor', 'none', ...
                'HandleVisibility', 'off');
        end
        if ~cond_in_legend(c)
            plot(ax, t_ref, wave_mean{lev,c} + offset, ...
                'Color', colors(c,:), 'LineWidth', 2.5, ...
                'DisplayName', lbl);
            cond_in_legend(c) = true;
        else
            plot(ax, t_ref, wave_mean{lev,c} + offset, ...
                'Color', colors(c,:), 'LineWidth', 2.5, ...
                'HandleVisibility','off');
        end
    end

    % --- Peak markers — shape by wave, color by condition, filled ---
    % Match this level's dB value into each condition's latency vector.
    level_db = levels(lev);
    for c = conds_idx(:)'
        ref_wf  = wave_mean{lev, c};
        lat_x_c = latencies.x{1, c};   % dB levels for this condition (descending)
        if isempty(ref_wf) || isempty(lat_x_c), continue; end
        [min_diff, lev_idx] = min(abs(lat_x_c - level_db));
        if min_diff > 5, continue; end  % no matching level within 5 dB
        for w = 1:5
            fld = wave_lat_fields{w};
            if ~isfield(latencies, fld) || isempty(latencies.(fld){1,c}), continue; end
            lat_ms = latencies.(fld){1,c}(lev_idx);
            if isnan(lat_ms) || lat_ms <= 0, continue; end
            [~, t_idx] = min(abs(t_ref - lat_ms));
            if t_idx < 1 || t_idx > length(ref_wf), continue; end
            pk_amp = ref_wf(t_idx) + offset;
            plot(ax, lat_ms, pk_amp, shapes(w), ...
                'Color', colors(c,:), 'MarkerFaceColor', colors(c,:), ...
                'MarkerSize', 9, 'LineWidth', 1.5, ...
                'HandleVisibility', 'off');
        end
    end

    % --- Trough markers (N points) — same shape, hollow ---
    if ~isempty(trough_latencies)
        for c = conds_idx(:)'
            ref_wf  = wave_mean{lev, c};
            lat_x_c = trough_latencies.x{1, c};
            if isempty(ref_wf) || isempty(lat_x_c), continue; end
            [min_diff, lev_idx] = min(abs(lat_x_c - level_db));
            if min_diff > 5, continue; end
            for w = 1:5
                fld = wave_lat_fields{w};
                if ~isfield(trough_latencies,fld) || isempty(trough_latencies.(fld){1,c}), continue; end
                lat_ms = trough_latencies.(fld){1,c}(lev_idx);
                if isnan(lat_ms) || lat_ms <= 0, continue; end
                [~, t_idx] = min(abs(t_ref - lat_ms));
                if t_idx < 1 || t_idx > length(ref_wf), continue; end
                tr_amp = ref_wf(t_idx) + offset;
                plot(ax, lat_ms, tr_amp, shapes(w), ...
                    'Color', colors(c,:), 'MarkerFaceColor', 'none', ...
                    'MarkerSize', 9, 'LineWidth', 1.5, ...
                    'HandleVisibility', 'off');
            end
        end
    end
end
hold(ax,'off');

%% Formatting
xlim(ax, [0 20]);
yticks(ax, flip(y_ticks));
yticklabels(ax, flip(y_tick_labels));
xlabel(ax, 'Time (ms)',     'FontWeight','bold','FontSize',16);
ylabel(ax, 'Sound Level (dB SPL)',   'FontWeight','bold','FontSize',16);
title(ax,  sprintf('ABR Waveforms – %s', freq_label), ...
    'FontSize',18,'FontWeight','bold');
grid(ax,'on');
set(ax,'FontSize',14);
% 1 µV scale bar anchored to the center of the bottom-most waveform
x_sb   = 19.75;                  % ms, 0.25 ms before right edge
y_sb_b = min(y_ticks);           % center of bottom (highest-level) waveform
hold(ax,'on');
plot(ax, [x_sb x_sb], [y_sb_b, y_sb_b+1], 'k-', 'LineWidth', 3, 'HandleVisibility','off');
text(ax, x_sb-0.3, y_sb_b+0.5, '1 \muV', 'FontSize', 12, 'VerticalAlignment', 'middle', 'HorizontalAlignment', 'right');
hold(ax,'off');

% Legend sentinels — three groups separated by blank spacer entries:
%   Group 1: wave shapes (W I–V)
%   Group 2: peak / trough example
% (Condition color lines were added during the waveform loop above.)
hold(ax,'on');
% Spacer between conditions and waves
plot(ax, nan, nan, 'Color','none', 'LineStyle','none', 'DisplayName',' ');
% Wave markers (black, filled)
for w = 1:5
    plot(ax, nan, nan, shapes(w), ...
        'Color', 'k', 'MarkerFaceColor', 'k', ...
        'MarkerSize', 9, 'LineWidth', 1.5, 'DisplayName', wave_labels{w});
end
% Spacer between waves and peak/trough example
plot(ax, nan, nan, 'Color','none', 'LineStyle','none', 'DisplayName',' ');
% Peak / trough example using shapes(1)
plot(ax, nan, nan, shapes(1), 'Color','k', 'MarkerFaceColor','k', ...
    'MarkerSize',9, 'LineWidth',1.5, 'DisplayName','Peak');
plot(ax, nan, nan, shapes(1), 'Color','k', 'MarkerFaceColor','none', ...
    'MarkerSize',9, 'LineWidth',1.5, 'DisplayName','Trough');
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
