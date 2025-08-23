%% Set up ROOTdir
ROOTdir = '/Volumes/FefeSSD/DOD';
%% Analysis
% Resample ABR p-file
fs = 8e3;
if iscell(x.AD_Data.AD_All_V{1})
    abr_raw = mean(x.AD_Data.AD_All_V{1}{1}) - mean(mean(x.AD_Data.AD_All_V{1}{1})); % waveform with DC offset removed
else
    abr_raw = mean(cell2mat(x.AD_Data.AD_All_V)) - mean(mean(cell2mat(x.AD_Data.AD_All_V))); % waveform with DC offset removed
end
abr = resample(abr_raw,fs,round(x.Stimuli.RPsamprate_Hz));
t = x.Stimuli.CAP_Gating.XstartPlot_ms/1000:1/fs:x.Stimuli.CAP_Gating.XendPlot_ms/1000-1/fs;

% Define frequency and level
if x.Stimuli.clickYes
    freq = 0;
    freq_str = 'click';
else
    freq = x.Stimuli.freq_hz;
    freq_str = mat2str(freq);
end
level_spl = round(x.Stimuli.MaxdBSPLCalib - x.Stimuli.atten_dB);

% Define template filename
template_name = ['template_',freq_str,'_',mat2str(level_spl),'dBSPL'];
%% Pick Template Peaks Manually
figure;
plot(t, abr, 'k-', 'LineWidth', 2);
set(gcf, 'Position', get(0, 'Screensize'));
hold on;

% Prompt the user to select 10 points
points = zeros(10, 3);
point_names = {'P1', 'N1', 'P2', 'N2', 'P3', 'N3', 'P4', 'N4', 'P5', 'N5'};
for i = 1:10
    title(['Choose ', point_names{i}]);
    [x_i, y_i] = ginput(1); % Get the coordinates from user input
    [~, index] = min(abs(t - x_i) + abs(abr - y_i));
    x_i = t(index);
    y_i = abr(index);
    plot(x_i, y_i, 'ro', 'MarkerSize', 8); % Plot the selected point
    points(i, :) = [x_i, y_i, index]; % Store the point in the matrix
    text(x_i, y_i, point_names{i}, 'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'right'); % Label the point
end
hold off;

% Save template
outpath = strcat(ROOTdir,filesep,'Code Archive',filesep,'ABR',filesep,'Peaks',filesep,'templates');
cd(outpath);
save(template_name, 'points','t','abr','point_names');


