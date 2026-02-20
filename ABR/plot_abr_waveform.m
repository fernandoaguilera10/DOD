%% 1. Configuration and Setup
t_start = 5; 
t_end = 15;
fSize = 14; 
num_subjects = size(waveforms.y, 1);
cond_names = waveforms.conditions(1, :);

% Target the 3 post-exposure conditions
target_labels = {'post/D7', 'post/D14', 'post/D30'};
post_indices = [];
for lbl = target_labels
    idx = find(contains(cond_names, lbl{1}), 1);
    if ~isempty(idx), post_indices(end+1) = idx; end
end

idx_base = find(contains(cond_names, "pre/Baseline"), 1);
progression_colors = [0.8 0 0; 0.9 0.5 0; 0 0.6 0]; % Red, Orange, Green

t_ref = waveforms.x{1, idx_base}(1,:);
mask = (t_ref >= t_start) & (t_ref <= t_end);
t_win = t_ref(mask);
max_len = length(t_win);

%% 2. Calculate Baseline Mean and CI
base_matrix = [];
for s = 1:num_subjects
    raw = waveforms.y{s, idx_base};
    if ~isempty(raw)
        subj_avg = nanmean(raw(:, mask(1:min(end, size(raw,2)))), 1);
        base_matrix(end+1, :) = [subj_avg, nan(1, max_len - length(subj_avg))];
    end
end

mu_base = nanmean(base_matrix, 1);
sem_base = nanstd(base_matrix, 0, 1) ./ sqrt(size(base_matrix, 1));
ci95_base = 1.96 * sem_base;

%% 3. Create 3-Panel Comparison Plot
fig = figure('Color', 'w', 'Position', [50, 50, 1600, 600]);
t = tiledlayout(1, 3, 'TileSpacing', 'Compact', 'Padding', 'Compact');

for i = 1:length(post_indices)
    c = post_indices(i);
    nexttile; hold on;
    
    % Calculate Current Condition Mean and CI
    curr_matrix = [];
    for s = 1:num_subjects
        raw = waveforms.y{s, c};
        if ~isempty(raw)
            subj_avg = nanmean(raw(:, mask(1:min(end, size(raw,2)))), 1);
            curr_matrix(end+1, :) = [subj_avg, nan(1, max_len - length(subj_avg))];
        end
    end
    mu_curr = nanmean(curr_matrix, 1);
    sem_curr = nanstd(curr_matrix, 0, 1) ./ sqrt(size(curr_matrix, 1));
    ci95_curr = 1.96 * sem_curr;

    % --- Plot 95% CI Shading ---
    % Baseline Shading (Grey)
    fill([t_win, fliplr(t_win)], [mu_base + ci95_base, fliplr(mu_base - ci95_base)], ...
        [0.8 0.8 0.8], 'EdgeColor', 'none', 'FaceAlpha', 0.4, 'HandleVisibility', 'off');
    
    % Condition Shading (Colored)
    fill([t_win, fliplr(t_win)], [mu_curr + ci95_curr, fliplr(mu_curr - ci95_curr)], ...
        progression_colors(i,:), 'EdgeColor', 'none', 'FaceAlpha', 0.25, 'HandleVisibility', 'off');

    % --- Plot Mean Waveforms ---
    % Baseline in solid Black
    h1 = plot(t_win, mu_base, 'k-', 'LineWidth', 2, 'DisplayName', 'Baseline');
    % Condition in solid Color
    h2 = plot(t_win, mu_curr, 'Color', progression_colors(i,:), 'LineWidth', 2.5, 'DisplayName', cond_names{c});
    
    % --- Publication Formatting ---
    title(cond_names{c}, 'FontSize', fSize + 2);
    set(gca, 'FontSize', fSize, 'LineWidth', 1.2, 'TickDir', 'out', 'Box', 'off');
    grid on;
    legend([h1 h2], 'Location', 'northeast', 'FontSize', fSize - 2);
    
    % Dynamic limits to encompass the CI shading
    ylim([min([mu_base-ci95_base, mu_curr-ci95_curr])-0.2, max([mu_base+ci95_base, mu_curr+ci95_curr])+0.3]);
end

% Global Axis Labels
xlabel(t, 'Time (ms)', 'FontSize', fSize + 2, 'FontWeight', 'bold');
ylabel(t, 'Amplitude (\muV)', 'FontSize', fSize + 2, 'FontWeight', 'bold');

%% ALL TOGETHER

%% 1. Configuration and Setup
t_start = 5; 
t_end = 15;
fSize = 16; % Larger for single-pane publication plot
num_subjects = size(waveforms.y, 1);
cond_names = waveforms.conditions(1, :);

% Define target conditions in chronological order
target_labels = {'pre/Baseline', 'post/D7', 'post/D14', 'post/D30'};
target_indices = [];
for lbl = target_labels
    idx = find(contains(cond_names, lbl{1}), 1);
    if ~isempty(idx), target_indices(end+1) = idx; end
end

% Colors: Black for Baseline, then a gradient for recovery
colors = [0 0 0;        % Baseline: Black
          0.8 0 0;      % D3: Deep Red
          0.9 0.5 0;    % D14: Burnt Orange
          0 0.6 0];     % D28: Forest Green

% Master Time Vector
t_ref = waveforms.x{1, target_indices(1)}(1,:);
mask = (t_ref >= t_start) & (t_ref <= t_end);
t_win = t_ref(mask);
max_len = length(t_win);

%% 2. Plotting Initialization
figure('Color', 'w', 'Position', [100, 100, 1000, 700]);
hold on;
h_plots = []; % Store handles for the legend

%% 3. Loop through all conditions and plot CI + Means
for i = 1:length(target_indices)
    c = target_indices(i);
    curr_matrix = [];
    
    % Collect data for all subjects in this condition
    for s = 1:num_subjects
        raw = waveforms.y{s, c};
        if ~isempty(raw)
            subj_avg = nanmean(raw(:, mask(1:min(end, size(raw,2)))), 1);
            curr_matrix(end+1, :) = [subj_avg, nan(1, max_len - length(subj_avg))];
        end
    end
    
    % Stats
    mu = nanmean(curr_matrix, 1);
    sem = nanstd(curr_matrix, 0, 1) ./ sqrt(size(curr_matrix, 1));
    ci95 = 1.96 * sem;
    
    % --- Plot CI Shading ---
    % Low alpha (0.15) prevents the plot from becoming a "blob" when overlaid
    fill([t_win, fliplr(t_win)], [mu + ci95, fliplr(mu - ci95)], ...
        colors(i,:), 'EdgeColor', 'none', 'FaceAlpha', 0.15, 'HandleVisibility', 'off');
    
    % --- Plot Mean Waveforms ---
    lw = 2; if i == 1, lw = 3; end % Make baseline slightly thicker
    h_plots(i) = plot(t_win, mu, 'Color', colors(i,:), 'LineWidth', lw, ...
        'DisplayName', target_labels{i});
end

%% 4. Publication Formatting
xlabel('Time (ms)', 'FontSize', fSize+2, 'FontWeight', 'bold');
ylabel('Amplitude (\muV)', 'FontSize', fSize+2, 'FontWeight', 'bold');
title('ABR Mean Waveforms \pm 95% CI', 'FontSize', fSize+4);

set(gca, 'FontSize', fSize, 'LineWidth', 1.5, 'TickDir', 'out', 'Box', 'off');
grid on;

% Create Legend
legend(h_plots, 'Location', 'northeast', 'FontSize', fSize-2);

% Final Y-limit adjustment
all_mu = nanmean(cell2mat(waveforms.y(:)), 1); % Rough estimate for scaling
ylim([min(mu(:))-0.4, max(mu(:))+0.5]);