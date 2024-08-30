%% ABR threshold plotting
clc; close all; clear all;
Chins2Run={'Q438','Q445','Q446','Q447'};
abr = {};
stimuli = [0.25, 0.5, 1, 2, 4, 8];
stimuli_labels = {'click', '0.5', '1', '2', '4', '8'};
%colors = ["#0072BD"; "#EDB120"; "#7E2F8E"; "#77AC30"; "#A2142F"; "#FF33FF"];
colors = [0,114,189; 237,177,32; 126,47,142; 119,172,48; 162,20,47; 255,51,255]/255;
shapes = ["x";"^";"v";"diamond";"o";"*"];
%% Q438
abr.Q438.conds = {'Baseline_2', 'D7', 'D14', 'D21'};
abr.Q438.thresholds = {[19.1, 18.1, 21.7, 9.7, 8.8, 13.3], [32.4, 30.7, 23.9, 25.4, 28.0, 35.7], [30.1, 25.1, 22.1, 24.5, 30.6, 33.9], [42.2, 30.5, 30.6, 28.1, 36.3, 45.3]};
figure;
for CondIND = 1:length(abr.Q438.conds)
    scatter(stimuli, cell2mat(abr.Q438.thresholds(CondIND)),100, 'o', 'filled', 'Color', [colors(CondIND,:),1]);
    hold on;
end
title(sprintf('Q438 | ABR Thresholds'), 'FontSize', 14, 'FontWeight', 'bold');
xlabel('Frequency (kHz)', 'FontWeight', 'bold'); ylabel('Threshold (dB SPL)','FontWeight', 'bold');
set(gca, 'XScale','log', 'FontSize', 14); xticks(stimuli); xticklabels(stimuli_labels); box off; ylim([0,50]);
legend(abr.Q438.conds,'Location','southoutside','Orientation','horizontal','FontSize',8); legend boxoff;
%% Q445
abr.Q445.conds = {'Baseline_2', 'D7', 'D14'};
abr.Q445.thresholds = {[18.5, 29.7, 22.5, 16.4, 12.6, 20.5], [22.3, 41.0, 20.4, 18.1, 20.1, 29.3], [21.7, 32.4, 21.3, 22.5, 19.3, 19.1]};
figure;
for CondIND = 1:length(abr.Q445.conds)
    scatter(stimuli, cell2mat(abr.Q445.thresholds(CondIND)),100, 'o', 'filled', 'Color', [colors(CondIND,:),1]);
    hold on;
end
title(sprintf('Q445 | ABR Thresholds'), 'FontSize', 14, 'FontWeight', 'bold');
xlabel('Frequency (kHz)', 'FontWeight', 'bold'); ylabel('Threshold (dB SPL)','FontWeight', 'bold');
set(gca, 'XScale','log', 'FontSize', 14); xticks(stimuli); xticklabels(stimuli_labels); box off; ylim([0,50]);
legend(abr.Q445.conds,'Location','southoutside','Orientation','horizontal','FontSize',8); legend boxoff;
%% Q446
abr.Q446.conds = {'Baseline_2', 'D7', 'D14'};
abr.Q446.thresholds = {[25.8, 39.6, 45.7, 49.3, 23.9, 21.0], [29.8, 33.8, 34.2, 34.1, 22.3, 21.9], [32.8, 33.5, 40.1, 39.6, 23.8, 30.1]};
figure;
for CondIND = 1:length(abr.Q446.conds)
    scatter(stimuli, cell2mat(abr.Q446.thresholds(CondIND)),100, 'o', 'filled', 'Color', [colors(CondIND,:),1]);
    hold on;
end
title(sprintf('Q446 | ABR Thresholds'), 'FontSize', 14, 'FontWeight', 'bold');
xlabel('Frequency (kHz)', 'FontWeight', 'bold'); ylabel('Threshold (dB SPL)','FontWeight', 'bold');
set(gca, 'XScale','log', 'FontSize', 14); xticks(stimuli); xticklabels(stimuli_labels); box off; ylim([0,50]);
legend(abr.Q446.conds,'Location','southoutside','Orientation','horizontal','FontSize',8); legend boxoff;
%% Q447
abr.Q447.conds = {'Baseline_2', 'D7', 'D14', 'D30'};
abr.Q447.thresholds = {[23.2, 43.4, 29.6, 27.0, 17.5, 23.8], [26.2, 43.8, 31.2, 31.6, 23.5, 21.7], [41.7, NaN, 50.3, 50.6, 32.8, 41.5], [43.6, 39.4, 40.2, 41.3, 34.3, 43.3]};
figure;
for CondIND = 1:length(abr.Q447.conds)
    scatter(stimuli, cell2mat(abr.Q447.thresholds(CondIND)),100, 'o', 'filled', 'Color', [colors(CondIND,:),1]);
    hold on;
end
title(sprintf('Q447 | ABR Thresholds'), 'FontSize', 14, 'FontWeight', 'bold');
xlabel('Frequency (kHz)', 'FontWeight', 'bold'); ylabel('Threshold (dB SPL)','FontWeight', 'bold');
set(gca, 'XScale','log', 'FontSize', 14); xticks(stimuli); xticklabels(stimuli_labels); box off; ylim([0,50]);
legend(abr.Q447.conds,'Location','southoutside','Orientation','horizontal','FontSize',8); legend boxoff;