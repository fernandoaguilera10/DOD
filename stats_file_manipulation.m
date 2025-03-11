%clear all; clc; close all;
%% MEMR Thresholds
criteria = 0.3;
level = average.elicitor{1,1};
memr_thresholds = nan(size(average.all_deltapow));
for rows = 1:length(average.all_deltapow)
    for cols = 1:width(average.all_deltapow)
        if ~isempty(average.all_deltapow{rows,cols})
            memr_avg = mean(average.all_deltapow{rows,cols});
            memr_std = std(average.all_deltapow{rows,cols});
            memr = average.all_deltapow{rows,cols};
            memr = memr/max(memr);
            memr_crit = level(find(memr >= criteria));
            if ~isempty(memr_crit)
                memr_thresholds(rows,cols) = memr_crit(1);
            end
        end
    end
end
%% OAE Band Averaging
oae_avg = nan(size(average.all_oae_band));
for rows = 1:length(average.all_oae_band)
    for cols = 1:width(average.all_oae_band)
        if ~isempty(average.all_oae_band{rows,cols})
            oae_avg(rows,cols) = nanmean(average.all_oae_band{rows,cols});
        end
    end
end
%% ABR Thresholds
thresholds = nan(size(average.all_y));
freq_idx = 5;   % click = 1,  0.5kHz = 2,  1kHz = 3,  2kHz = 4,  4kHz = 5,  8kHz = 6
freq_str = ["Click","0.5 kHz","1 kHz","2 kHz","4 kHz","8 kHz"];
freq = average.x{1,1}(freq_idx);
for rows = 1:length(average.all_y)
    for cols = 1:width(average.all_y)
        if ~isempty(average.all_y{rows,cols})
            thresholds(rows,cols) = average.all_y{rows,cols}(freq_idx);
        end
    end
end
%% Violin plot
data_matrix = cell2mat(average.all_ratio);
%y = cell2mat(average.all_ratio(:,2:end))-cell2mat(average.all_ratio(:,1));
colors = [0,114,189; 237,177,32; 126,47,142; 119,172,48; 204,0,0; 255,51,255]/255;
colors = colors(1:end,:);
%title_str = sprintf('EFR Ratio | %s',freq_str(freq_idx));
title_str = sprintf('EFR Ratio | %s dB SPL','65');
y_str = 'PLV Ratio (re. Baseline)';
[num_rows, num_groups] = size(data_matrix); 
groups = reshape(repmat(1:num_groups, num_rows, 1), [], 1);
data_vector = data_matrix(:);
figure;
h1 = daviolinplot(data_vector, 'color', colors, 'violin', 'full', 'scatter', 2,'groups',groups);
xticklabels(average.conditions(1:end))
%xticklabels(average.subjects)
set(gca,'FontSize',15);
title(title_str)
ylabel(y_str,'FontWeight','bold');
ylim([-1.5,4]);
