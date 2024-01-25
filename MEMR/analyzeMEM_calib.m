clear;
close all;
clc;

load('Thevenin_ER10X.mat');
fcalib = f;

[FileName,PathName,FilterIndex] = uigetfile(strcat('MEMR_*.mat'),...
    'Please pick MEM data file to analyze');
MEMfile = fullfile(PathName, FileName);
load(MEMfile);

endsamps = ceil(stim.clickwin*stim.Fs*1e-3) + 1;
% It is assumed that the calib file has this length for all recordings

freq = linspace(200, 8000, 1024);
MEMband = [500, 2000];
ind = (freq >= MEMband(1)) & (freq <= MEMband(2));
n = stim.nLevels;

%---------
% Additional info to match calibEar.m
delay = (round(endsamps / 3) + 97) / stim.Fs;
mat2volts = 5.0;
Vo = rfft(vo)*mat2volts*db2mag(-1 * att);
factor = stim.mat2Pa / sqrt(2);
%---------

for k = 1:n
    fprintf(1, 'Analyzing level # %d / %d ...\n', k, n);
    temp = reshape(squeeze(stim.resp(k, :, 2:end, 1:endsamps)),...
        (stim.nreps-1)*stim.Averages, endsamps);
    
    %----------------
    % Additional computation to get the Conductances
    energy = sum(temp.^2, 2);
    good = energy < (median(energy) + 2*mad(energy, 1));
    avg = mean(temp(good, :), 1) * -1 * factor;
    EarRespH =  rfft(avg').*exp(1j*2*pi*fcalib*delay) ./ Vo;
    Zec_mem = ldimp(Zs, Ps, EarRespH);
    Gmem(k, :) = interp1(fcalib, real(1./Zec_mem), freq);
    %----------------

    tempf = pmtm(temp', 4, freq, stim.Fs)';
    resp_freq(k, :) = median(tempf, 1); %#ok<*SAGROW>
    
    
    blevs = k; % Which levels to use as baseline (consider 1:k)
    temp2 = squeeze(stim.resp(blevs, :, 1, 1:endsamps));
    
    if(numel(blevs) > 1)
        temp2 = reshape(temp2, size(temp2, 2)*numel(blevs), endsamps);
    end
    
    %----------------
    % Additional computation to get the Conductances
    energy = sum(temp2.^2, 2);
    good = energy < (median(energy) + 2*mad(energy, 1));
    avg = mean(temp2(good, :), 1) * -1 * factor;
    EarRespH =  rfft(avg').*exp(1j*2*pi*fcalib*delay) ./ Vo;
    Zec_bline = ldimp(Zs, Ps, EarRespH);
    Gbline(k, :) = interp1(fcalib, real(1./Zec_bline), freq);
    %---------------
    temp2f = pmtm(temp2', 4, freq, stim.Fs)';
    bline_freq(k, :) = median(temp2f, 1);
end

Gmem = abs(Gmem);
Gbline = abs(Gbline);

if(min(stim.noiseatt) == 6)
    elicitor = 94 - (stim.noiseatt - 6);
else
    elicitor = 94 - stim.noiseatt;
end

% Adjust measured ear-canal dB change with conductance change
MEM = pow2db(resp_freq ./ bline_freq) + pow2db(Gmem ./ Gbline);

cols = getDivergentColors(n);

axes('NextPlot','replacechildren', 'ColorOrder',cols);

smoothmem = true;
plotorig = false;
if smoothmem
    for k = 1:n
        MEMs(k, :) = sgolayfilt(MEM(k, :), 2, 65);
    end
end

semilogx(freq / 1e3, MEMs, 'linew', 2);
xlim([0.2, 4]);
ticks = [0.25, 0.5, 1, 2, 4];
set(gca, 'XTick', ticks, 'XTickLabel', num2str(ticks'), 'FontSize', 16);
legend(num2str(elicitor'), 'location', 'best');

if plotorig
    hold on; %#ok<UNRCH>
    semilogx(freq / 1e3, MEM, '--', 'linew', 2);
end
xlabel('Frequency (kHz)', 'FontSize', 16);
ylabel('\Delta Absorbed Power (dB)', 'FontSize', 16);


figure;
plot(elicitor, mean(abs(MEM(:, ind)), 2)*5 , 'ok-', 'linew', 2);
hold on;
xlabel('Elicitor Level (dB SPL)', 'FontSize', 16);
ylabel('\Delta Absorbed Power (dB)', 'FontSize', 16);
set(gca,'FontSize', 16);


