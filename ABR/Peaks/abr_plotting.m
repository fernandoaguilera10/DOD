%% abr_plotting
% This function is used to plot ABR waveforms, thresholds, and peaks (amplitude + latency)
% after they have been analyzed
%close all;
clear; clc;
%% Animal ID
freq = 0; % use 0 for click
ChinID = 'Q456';
ChinCondition = 'post';
ChinFile = 'D14';
if (ismac == 1) %MAC computer
    %Synology:
    %PROJdir = strcat(filesep,'Volumes',filesep,'Heinz-Lab',filesep,'Projects',filesep,'DOD',filesep,'Pilot Study');
    %abr_data_dir = strcat(PROJdir,filesep,'Data',filesep,ChinID,filesep,'ABR',filesep,ChinCondition);
    PROJdir = strcat(filesep,'Users',filesep,'fernandoaguileradealba',filesep,'Desktop',filesep,'DOD-Analysis');
    abr_data_dir = strcat(filesep,'Users',filesep,'fernandoaguileradealba',filesep,'Desktop',filesep,'DOD-Analysis',filesep,'Data',filesep,ChinID,filesep,'ABR',filesep,ChinCondition);
else %if using WINDOWS computer..
    %Synology:
    %PROJdir = strcat('Y:',filesep,'Projects',filesep,'DOD',filesep,'Pilot Study');
    %abr_data_dir = strcat(PROJdir,filesep,'Data',filesep,ChinID,filesep,'ABR',filesep,ChinCondition);
    PROJdir = strcat('C:',filesep,'Users',filesep,'aguilerl',filesep,'OneDrive - purdue.edu',filesep,'Desktop',filesep,'DOD-Analysis');
    abr_data_dir = strcat('C:',filesep,'Users',filesep,'aguilerl',filesep,'OneDrive - purdue.edu',filesep,'Desktop',filesep,'DOD-Analysis',filesep,'Data',filesep,ChinID,filesep,'ABR',filesep,ChinCondition);
end
out_dir = [PROJdir strcat(filesep,'Analysis',filesep,'ABR',filesep,ChinID,filesep,ChinCondition,filesep,ChinFile)];
%% Analysis
% load data file
cwd = pwd;
cd(out_dir);
if freq == 0, freq = 'click'; end
datafile = dir(sprintf('*%s*.mat',num2str(freq)));
if length(datafile) < 1
    fprintf('No ABR peak files found for %s under current directory:\n%s',ChinID,abr_data_dir)
    cd(cwd);
    return
elseif size(datafile,1) > 1
    fprintf('More than 1 data file found. Select one file to use\n');
    checkDIR = {uigetfile(sprintf('*%s*',num2str(freq)))};
    load(checkDIR{1});
    file = cell2mat(checkDIR);
else
    load(datafile(1).name);
    file = datafile(1).name;
end
fprintf('Data file: %s\n',file);

% plotting waveforms and peaks
numLevels = length(abrs.plot.levels);
figure;
set(gcf, 'Position', get(0, 'Screensize'));
shift = 0;
colors = [0,114,189; 0,114,189; 237,177,32; 237,177,32; 126,47,142; 126,47,142; 119,172,48; 119,172,48; 162,20,47; 162,20,47]/255;
for i = 1:numLevels
    if i > 1
        delta = abs(max(abrs.plot.waveforms(i,:))) + abs(min(abrs.plot.waveforms(i-1,:)));
        if delta < 1, delta = 1; end
        shift = shift + delta;
    end
    plot(abrs.plot.waveforms_time, abrs.plot.waveforms(i,:)-shift, 'linew', 2, 'Color', 'black');
    text(0.5, -shift+0.35,sprintf('%.0f dB SPL',abrs.plot.levels(i)), 'FontWeight', 'bold', 'FontSize', 14);
    hold on;
    for j = 1:length(abrs.plot.peaks)
        plot(abrs.plot.peak_latency(i,j), abrs.plot.peak_amplitude(i,j)-shift, '*', 'Color', colors(j,:), 'LineWidth', 2);
        text(abrs.plot.peak_latency(i,j)+0.15, abrs.plot.peak_amplitude(i,j)-shift+0.05,sprintf('%s',abrs.plot.peaks(j)), 'FontWeight', 'bold', 'FontSize', 8);
    end
    
end
if freq ~= 'click', freq = [num2str(freq), ' Hz']; end
text(round(abrs.plot.waveforms_time(end))-6, round(max(abrs.plot.waveforms(1,:)))-0.5,sprintf('Threshold: %.1f dB SPL',abrs.plot.threshold), 'FontWeight', 'bold', 'Color', 'red','FontSize', 14)
title(sprintf('%s | %s | ABR - %s',ChinID,ChinFile,freq), 'FontSize', 14, 'FontWeight', 'bold');
set(gca, 'XScale', 'linear', 'FontSize', 14)
ylabel('Response ({\mu}V)', 'FontWeight', 'bold');
xlabel('Time (ms)', 'FontWeight', 'bold');
xlim([0,30]); ylim([-round(shift)-0.5,round(max(abrs.plot.waveforms(1,:)))+0.5]); yticks([]); box off;
% save file
print(1,[file(1:end-4),'_figure'],'-dpng','-r300');
cd(cwd);