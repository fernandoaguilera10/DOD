%% TEOAE Analysis
% Author: Samantha Hauser
% Created: May 2023
% Last Updated: August 2, 2023
% Purpose:
% Helpful info:
%% Import data
cwd = pwd;
cd(datapath)
datafile = {dir(fullfile(cd,'*TEOAE.mat')).name};
numOfFiles = length(datafile);
if numOfFiles > 1
    fprintf('More than 1 data file. Check this is correct file!\n');
    datafile = {uigetfile('*TEOAE.mat')}; 
elseif numOfFiles < 1
    fprintf('No files for this subject...Quitting.\n')
    cd(cwd);
    return
else
    datafile = datafile;
end
load(datafile{1});
cd(cwd);
click = x.TEOAEData.stim; 
%% Analysis loop
spl.resp_win = click.resp(:, (click.StimWin+1):(click.StimWin + click.RespDur)); % Remove stimulus by windowing
resp = spl.resp_win; 
if click.doFilt
    % High pass at 200 Hz using IIR filter
    [b, a] = butter(4, 200 * 2 * 1e-3/click.SamplingRate, 'high');
    resp = filtfilt(b, a, spl.resp_win')';
end
vavg_odd = trimmean(resp(1:2:end, :), 20, 1);
vavg_even = trimmean(resp(2:2:end, :), 20, 1);
rampdur = 0.2e-3; %seconds
Fs = click.SamplingRate/2 * 1e3;
spl.vavg = rampsound((vavg_odd + vavg_even)/2, Fs, rampdur);
spl.noisefloor = rampsound((vavg_odd - vavg_even)/2, Fs, rampdur);
Vavg = rfft(spl.vavg);
Vavg_nf = rfft(spl.noisefloor);
% Apply calibartions to convert voltage to pressure
% For ER-10X, this is approximate
mic_sens = click.mic_sens; % mV/Pa. TO DO: change after calibration
mic_gain = click.mic_gain; 
P_ref = click.P_ref;
DR_onesided = click.DR_onesided;
factors = DR_onesided * mic_gain * mic_sens * P_ref;
output_Pa_per_20uPa = Vavg / factors; % unit: 20 uPa / Vpeak
noise_Pa_per_20uPa = Vavg_nf / factors;
spl.freq = 1000*linspace(0,click.SamplingRate/2,length(Vavg))';
spl.Resp =  output_Pa_per_20uPa;
spl.NoiseFloor = noise_Pa_per_20uPa;
%% Plot
figure;
hold on;
plot(spl.freq*1e-3, db(abs(spl.Resp)), 'linew', 2, 'Color', 'green');
ylabel('Response (dB SPL)', 'FontSize', 14, 'FontWeight', 'bold');
uplim = max(db(abs(spl.Resp)));
hold on;
semilogx(spl.freq*1e-3, db(abs(spl.NoiseFloor)),'--', 'linew', 2, 'Color', 'black');
xlabel('Frequency (kHz)', 'FontSize', 14, 'FontWeight', 'bold');
legend('TEOAE', 'NF');
xlim([0.5, 16]);
ticks = [0.5, 1, 2, 4, 8, 16];
set(gca, 'XTick', ticks, 'FontSize', 14, 'xscale', 'log');
ylim([-60, uplim + 5]);
title([subj, ' | TEOAE | ', condition], 'FontSize', 14 )
drawnow; 
spl.oae = spl.Resp; 
spl.noise = spl.NoiseFloor;
data.spl = spl;
%% Save Variables and figure
cd(outpath);
fname = [subj,'_TEOAE_',condition,'_',datafile{1}(1:end-4)];
print(gcf,[fname,'_figure'],'-dpng','-r300');
save(fname,'data')
cd(cwd);