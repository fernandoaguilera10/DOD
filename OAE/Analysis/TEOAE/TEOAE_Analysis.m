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
res.resp_win = click.resp(:, (click.StimWin+1):(click.StimWin + click.RespDur)); % Remove stimulus by windowing
resp = res.resp_win; 
if click.doFilt
    % High pass at 200 Hz using IIR filter
    [b, a] = butter(4, 200 * 2 * 1e-3/click.SamplingRate, 'high');
    resp = filtfilt(b, a, res.resp_win')';
end
vavg_odd = trimmean(resp(1:2:end, :), 20, 1);
vavg_even = trimmean(resp(2:2:end, :), 20, 1);
rampdur = 0.2e-3; %seconds
Fs = click.SamplingRate/2 * 1e3;
res.vavg = rampsound((vavg_odd + vavg_even)/2, Fs, rampdur);
res.noisefloor = rampsound((vavg_odd - vavg_even)/2, Fs, rampdur);
Vavg = rfft(res.vavg);
Vavg_nf = rfft(res.noisefloor);
% Apply calibartions to convert voltage to pressure
% For ER-10X, this is approximate
mic_sens = click.mic_sens; % mV/Pa. TO DO: change after calibration
mic_gain = click.mic_gain; 
P_ref = click.P_ref;
DR_onesided = click.DR_onesided;
factors = DR_onesided * mic_gain * mic_sens * P_ref;
output_Pa_per_20uPa = Vavg / factors; % unit: 20 uPa / Vpeak
noise_Pa_per_20uPa = Vavg_nf / factors;
res.freq = 1000*linspace(0,click.SamplingRate/2,length(Vavg))';
res.Resp =  output_Pa_per_20uPa;
res.NoiseFloor = noise_Pa_per_20uPa;
%% Plot
figure;
hold on;
plot(res.freq*1e-3, db(abs(res.Resp)), 'linew', 3);
ylabel('Response (dB SPL)', 'FontSize', 14, 'FontWeight', 'bold');
uplim = max(db(abs(res.Resp)));
hold on;
semilogx(res.freq*1e-3, db(abs(res.NoiseFloor)),'k--' ,'linew', 2);
xlabel('Frequency (kHz)', 'FontSize', 14, 'FontWeight', 'bold');
legend('TEOAE', 'NoiseFloor');
xlim([0.4, 16]);
ticks = [0.5, 1, 2, 4, 8, 16];
set(gca, 'XTick', ticks, 'FontSize', 14, 'xscale', 'log');
ylim([-60, uplim + 5]);
title([subj ' | TEOAE | ' condition], 'FontSize', 14)
drawnow; 
res.freq = res.freq; 
res.resp = db(abs(res.Resp)); 
res.nf = db(abs(res.NoiseFloor)); 
%% Save Variables and figure
cd(outpath);
fname = [subj,'_TEOAE_',condition];
print(gcf,[fname,'_figure'],'-dpng','-r300');
save(fname,'res')
cd(cwd);