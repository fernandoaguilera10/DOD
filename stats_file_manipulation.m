%clear all; clc; close all;
%% ABR Thresholds
thresholds = nan(size(average.all_y));
freq_idx = 6;   % click = 1,  0.5kHz = 2,  1kHz = 3,  2kHz = 4,  4kHz = 5,  8kHz = 6
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
data_matrix = thresholds';
%y = cell2mat(average.all_ratio(:,2:end))-cell2mat(average.all_ratio(:,1));
colors = [0,114,189; 237,177,32; 126,47,142; 119,172,48; 204,0,0; 255,51,255]/255;
%colors = [237,177,32; 126,47,142; 119,172,48; 204,0,0; 255,51,255]/255;
title_str = sprintf('ABR Thresholds | %s',freq_str(freq_idx));
y_str = 'Threshold Shift (re. Baseline)';
[num_rows, num_groups] = size(data_matrix); 
groups = reshape(repmat(1:num_groups, num_rows, 1), [], 1);
data_vector = data_matrix(:);
figure;
h1 = daviolinplot(data_vector, 'color', colors, 'violin', 'full', 'scatter', 2,'groups',groups);
%xticklabels(average.conditions(2:end))
xticklabels(average.subjects)
set(gca,'FontSize',15);
title(title_str)
ylabel(y_str,'FontWeight','bold');
ylim([-80,80]);
