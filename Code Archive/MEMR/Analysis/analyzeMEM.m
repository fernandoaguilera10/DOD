clear;
close all;
clc;

[FileName,PathName,FilterIndex] = uigetfile(strcat('MEMR_*.mat'),...
    'Please pick MEM data file to analyze');
MEMfile = fullfile(PathName, FileName);
load(MEMfile);

endsamps = ceil(stim.clickwin*stim.Fs*1e-3);

freq = linspace(200, 8000, 1024);
MEMband = [500, 2000];
ind = (freq >= MEMband(1)) & (freq <= MEMband(2));

for k = 1:stim.nLevels
    fprintf(1, 'Analyzing level # %d / %d ...\n', k, stim.nLevels);
    temp = reshape(squeeze(stim.resp(k, :, 2:end, 1:endsamps)),...
        (stim.nreps-1)*stim.Averages, endsamps);
    tempf = pmtm(temp', 4, freq, stim.Fs)';
    resp_freq(k, :) = median(tempf, 1); %#ok<*SAGROW>
    

    blevs = k; % Which levels to use as baseline (consider 1:k)
    temp2 = squeeze(stim.resp(blevs, :, 1, 1:endsamps));
    
    if(numel(blevs) > 1)
        temp2 = reshape(temp2, size(temp2, 2)*numel(blevs), endsamps);
    end
    
    temp2f = pmtm(temp2', 4, freq, stim.Fs)';
    bline_freq(k, :) = median(temp2f, 1);
end



if(min(stim.noiseatt) == 6)
    elicitor = 94 - (stim.noiseatt - 6);
else
    elicitor = 94 - stim.noiseatt;
end

MEM = pow2db(resp_freq ./ bline_freq);

% Colorblind friendly continuous hue/sat changes
cols = [103,0,31;
178,24,43;
214,96,77;
244,165,130;
253,219,199;
247, 247, 247;
209,229,240;
146,197,222;
67,147,195;
33,102,172;
5,48,97];
cols = cols(end:-1:1, :)/255;

% cols = jet(size(MEM, 1));
axes('NextPlot','replacechildren', 'ColorOrder',cols);
semilogx(freq / 1e3, MEM, 'linew', 2);
xlim([0.2, 8]);
ticks = [0.25, 0.5, 1, 2, 4, 8];
set(gca, 'XTick', ticks, 'XTickLabel', num2str(ticks'), 'FontSize', 16);
legend(num2str(elicitor'));
xlabel('Frequency (kHz)', 'FontSize', 16);
ylabel('Ear canal pressure (dB re: Baseline)', 'FontSize', 16);



figure;
plot(elicitor, mean(abs(MEM(:, ind)), 2)*5 , 'ok-', 'linew', 2);
hold on;
xlabel('Elicitor Level (dB SPL)', 'FontSize', 16);
ylabel('\Delta Absorbed Power (dB)', 'FontSize', 16);
set(gca,'FontSize', 16);


