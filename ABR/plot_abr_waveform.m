%% NEED TO LOAD AMPLITUDE, LATENCY, AND WAVEFORM FILES MANUALLY
% --- Parameters ---
fs = 18;          
lw = 2.5;         
fontName = 'Arial';
tp_names = waveforms.conditions(1, :); 
num_tp = length(tp_names);

% Colors = Conditions
tp_colors = [
    0.00, 0.45, 0.74; % Blue
    0.85, 0.33, 0.10; % Orange
    0.47, 0.67, 0.19; % Green
    0.49, 0.18, 0.56  % Purple
];

% --- Figure Setup ---
figure(107); clf;
set(gcf, 'Color', 'w', 'Position', [100, 100, 1200, 800]); 
main_ax = axes('Position', [0.12, 0.15, 0.70, 0.75]); 
hold on;

% --- Plotting Loop ---
for c = 1:num_tp
    all_y = []; 
    time_vec = [];
    
    for row = 1:size(waveforms.y, 1)
        if ~isempty(waveforms.y{row, c})
            if isempty(time_vec)
                time_vec = waveforms.x{row, c}(1, :); 
            end
            
            subj_data = waveforms.y{row, c};
            % Average across levels per subject
            if size(subj_data, 1) > 1
                all_y = [all_y; mean(subj_data, 1)]; 
            else
                all_y = [all_y; subj_data];
            end
        end
    end
    
    if ~isempty(all_y)
        % Filter data to the 0-20ms window
        mask = (time_vec >= 0) & (time_vec <= 20);
        t_win = time_vec(mask);
        y_win = all_y(:, mask);
        
        n = size(y_win, 1);
        mu = mean(y_win, 1);
        sem = std(y_win, 0, 1) ./ sqrt(n);
        ci95 = 1.96 * sem;
        
        % Plot Shaded CI Area (95% Confidence)
        fill([t_win, fliplr(t_win)], [mu + ci95, fliplr(mu - ci95)], ...
            tp_colors(c,:), 'FaceAlpha', 0.15, 'EdgeColor', 'none', 'HandleVisibility', 'off');
        
        % Plot Mean Line
        plot(t_win, mu, 'Color', tp_colors(c,:), 'LineWidth', lw, ...
            'DisplayName', char(tp_names(c)));
    end
end

% --- Final Polish ---
set(main_ax, 'FontName', fontName, 'FontSize', fs, 'LineWidth', 2, 'TickDir', 'out', 'Box', 'on');
grid on;
xlim([0 20]); % Set the requested X-axis range
xlabel('Latency (ms)', 'FontWeight', 'bold');
ylabel('Amplitude (\muV)', 'FontWeight', 'bold');
title(['Average ABR (N = ' num2str(length(waveforms.subjects)),')']);

% Legend
L = legend('show', 'Location', 'northeastoutside', 'FontSize', fs-2, 'EdgeColor', 'none');
title(L, 'Conditions');

hold off;

%% Latency Distribution
%% ABR LATENCY CLUSTERING (OPTIMIZED VERTICAL VIOLINS)
% --- Parameters ---
fs = 18;          
ms_size = 40;     
fontName = 'Arial';
wave_names = {'all_w1', 'all_w2', 'all_w3', 'all_w4', 'all_w5'};
wave_labels = {'Wave I', 'Wave II', 'Wave III', 'Wave IV', 'Wave V'};
tp_names = waveforms.conditions(1, :); 
num_tp = length(tp_names);

% Colors = Conditions
tp_colors = [
    0.00, 0.45, 0.74; % Blue
    0.85, 0.33, 0.10; % Orange
    0.47, 0.67, 0.19; % Green
    0.49, 0.18, 0.56  % Purple
];

figure(110); clf;
set(gcf, 'Color', 'w', 'Position', [100, 100, 1200, 900]);
hold on;

% Width management for vertical grouping
group_width = 0.8; 
sub_spacing = group_width / (num_tp + 1);

% Tracking for Y-axis limits
all_collected_lats = [];

% --- Plotting Loop ---
for w = 1:length(wave_names)
    current_wave = wave_names{w};
    x_center = w; 
    
    for c = 1:num_tp
        lats = [];
        if isfield(latencies, current_wave)
            for s = 1:size(latencies.(current_wave), 1)
                val = latencies.(current_wave){s, c};
                if ~isempty(val) && ~any(isnan(val))
                    lats = [lats; val(:)];
                end
            end
        end
        
        if ~isempty(lats) && length(lats) > 1
            all_collected_lats = [all_collected_lats; lats]; % Collect for Y-lims
            
            % 1. Calculate Density for Violin
            [f, xi] = ksdensity(lats, 'Bandwidth', 0.15);
            f = (f / max(f)) * (sub_spacing * 0.9); 
            
            % Offset each condition
            x_offset = x_center - (group_width/2) + (c * sub_spacing);
            
            % 2. Plot Symmetrical Vertical Violin
            fill([x_offset + f, x_offset - fliplr(f)], [xi, fliplr(xi)], ...
                tp_colors(c,:), 'FaceAlpha', 0.3, 'EdgeColor', tp_colors(c,:), 'LineWidth', 1.5);
            
            % 3. Individual Data Points
            pt_jitter = x_offset + (rand(size(lats)) - 0.5) * (sub_spacing * 0.4);
            scatter(pt_jitter, lats, ms_size, tp_colors(c,:), 'filled', ...
                'MarkerFaceAlpha', 0.6, 'MarkerEdgeColor', 'none', 'HandleVisibility', 'off');
            
            % 4. Mean Marker
            plot(x_offset, mean(lats), 'wo', 'MarkerSize', 8, 'MarkerFaceColor', 'w');
        end
    end
end

% --- Final Polish & Dynamic Y-Axis ---
if ~isempty(all_collected_lats)
    y_min = min(all_collected_lats);
    y_max = max(all_collected_lats);
    y_range = y_max - y_min;
    % Add 10% buffer to top and bottom
    ylim([y_min - 0.1*y_range, y_max + 0.1*y_range]);
end

set(gca, 'XTick', 1:length(wave_names), 'XTickLabel', wave_labels, ...
    'FontName', fontName, 'FontSize', fs, 'LineWidth', 2, 'TickDir', 'out');

grid on; ax = gca; ax.YGrid = 'on'; ax.XGrid = 'off';
ylabel('Latency (ms)', 'FontWeight', 'bold');
xlabel('Wave Category', 'FontWeight', 'bold');
title('ABR Peak Latencies');
xlim([0.5 length(wave_names)+0.5]);

% Legend
for c = 1:num_tp
    h_leg(c) = scatter(nan, nan, 100, tp_colors(c,:), 'filled', 'DisplayName', char(tp_names(c)));
end
L = legend(h_leg, 'Location', 'northeastoutside', 'FontSize', fs-2, 'EdgeColor', 'none');
title(L, 'Conditions');

hold off;