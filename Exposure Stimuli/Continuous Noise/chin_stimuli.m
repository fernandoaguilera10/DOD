clear all; close all; clc;
%% Select ME Directory
dir_mac = '/Users/fernandoaguileradealba/Library/Mobile Documents/com~apple~CloudDocs/Desktop/Purdue/Heinz Lab/Grants/Blast DoD/Aircraft Spectra/';
dir_windows = 'C:\Users\aguilerl\iCloudDrive\Desktop\Purdue\Heinz Lab\Grants\Blast DoD\Aircraft Spectra\';
sel = input('Select OS - Windows (W)/Mac (M):  ','s');
if sel == 'W' || sel == 'w', dir = dir_windows; end
if sel == 'M' || sel == 'm', dir = dir_mac; end
%% Generate White Noise
load('noise_spectra.mat')
fs = floor(97656.25);  %TDT sampling rate
audio_length = 11; % audio length in secs
t_noise = linspace(0,audio_length,round(fs));
noise = randn(1,round(fs*t_noise(end)));
noise = noise/max(abs(noise)); % sets max value to 1 for wav file 
%% Bandpass Filter Parameters
% Constant parameters
order = 97000;
nfft = 2^round(log2(order)); 
x_lim = [10^0,10^5];
m = db2mag(avgSpectra); % convert dB to magnitude
m_lp = [m(1) m m(end)/100]; % LP cutoff at 500 Hz (chinchilla)
m_hp = [0 0 1 1]*max(m_lp); % HP cutoff at 250 Hz (chinchilla)
%% Filter Response
% Filter Design - Low Pass
freq_chin = freq;
f_norm_chin_lp = [0 freq'/(fs/2) 1]; % normalize relative to fs
b_chin_lp = fir2(order,f_norm_chin_lp,m_lp);
[h_chin_lp, f_chin_lp] = freqz(b_chin_lp, 1, nfft, fs);
% Filter Design - High Pass
fc_chin_hp = freq_chin(1);
f_norm_chin_hp = [0 fc_chin_hp fc_chin_hp+1 fs/2]/(fs/2); % normalize relative to fs
b_chin_hp = fir2(order,f_norm_chin_hp,m_hp);
[h_chin_hp, f_chin_hp] = freqz(b_chin_hp, 1, nfft, fs);
% Filter Design - Band Pass
b_chin_bp = conv(b_chin_lp,b_chin_hp);
[h_chin_bp,f_chin_bp] = freqz(b_chin_bp, 1, nfft, fs);
figure;
plot(f_chin_lp, mag2db(abs(h_chin_lp)),'-','color',[1 0 0 0.2],'LineWidth', 8); box off; hold on; % Plot Low Pass
plot(f_chin_hp, mag2db(abs(h_chin_hp)),'-', 'color',[0 1 0 0.2],'LineWidth', 8); box off; % Plot High Pass
plot(f_chin_bp, mag2db(abs(h_chin_bp))-max(mag2db(abs(h_chin_lp))),'-.', 'color',[0 0 0],'LineWidth', 3); hold on; box off; % Plot Band Pass
legend(sprintf('FIR - LP (f_c = %.0f Hz)',freq_chin(5)), sprintf('FIR - HP (f_c = %.1f Hz)',fc_chin_hp),'FIR - BP (LP + HP)','Location','southeast'); legend boxoff; % Plot Average Spectra
xlabel('Frequency [Hz]'); ylabel('Magnitude [dB]'); xlim(x_lim); ylim([-10,120]);
set(gca, 'xscale', 'log'); hold off; title('Frequency Response'); subtitle('Chinchilla');
print -dtiff ChinFilterSpectra
%% Average Frequency Response
fc_chin_lp = freq_chin(5);
h_chin = (mag2db(abs(h_chin_bp)) - max(mag2db(abs(h_chin_bp)))) - 10*log10(fc_chin_lp-fc_chin_hp) + 87.5 ;
figure;
plot(f_chin_bp,h_chin, '-', 'LineWidth',4);
title('Average Frequency Response (Node Room & Sponson Area)'); subtitle(sprintf('Chinchilla (f_1 = %.1f Hz; f_2 = %.0f Hz)',fc_chin_hp,fc_chin_lp));
xlabel('Frequency [Hz]'); ylabel('Sound Level [dB SPL]'); set (gca, 'xscale', 'log');
text(3000,60,sprintf('Spectral Level: 87.5 dB SPL\nDosage: 8 hours/day\nDuration: 30 days'),'FontWeight','bold');
xlim(x_lim); ylim([0,70]); box off;
print -dtiff ChinNoiseSpectra
%% Middle Ear Absorbance
cd (sprintf('%sChin ME',dir));
load('Q351.mat'); load('Q381.mat'); load('Q421.mat'); load('Q422.mat'); load('Q425.mat'); load('Q426.mat'); load('Q427.mat'); load('Q428.mat'); load('Q431.mat')
cd (dir)
me_chin_ind = [Q351.abs, Q381.abs, Q421.abs, Q422.abs, Q425.abs, Q426.abs, Q427.abs, Q428.abs, Q431.abs];
f_chin_me = Q421.freq*1000;
me_chin_ind(me_chin_ind < 0) = 1;
me_chin_ind_db = 10*log10(me_chin_ind/100);
me_chin_avg = mean(me_chin_ind,2);
me_chin_avg_db = 10*log10(me_chin_avg/100);
me_chin_avg_smooth_lowess_db = smooth(10*log10(me_chin_avg/100),0.01,'rlowess');
figure;
plot(f_chin_me, me_chin_ind_db,'-k','LineWidth', 3, 'color', [0.7 0.7 0.7 0.5],'HandleVisibility','off'); hold on;
plot(f_chin_me, me_chin_avg_db,'-k','LineWidth', 3);
plot(f_chin_me, me_chin_avg_smooth_lowess_db,':g','LineWidth', 3);
title('Middle Ear Absorbance'); subtitle('Chinchilla (n = 9)');
xlabel('Frequency [Hz]'); 
ylabel('Absorbance [dB]');
set (gca, 'xscale', 'log'); 
xlim([25,25e3]); ylim([-50, 5]); box off;
legend('Mean', 'Lowess (1%)','Location','southwest'); legend boxoff;
print -dtiff ChinAbsorbance
figure;
plot(f_chin_me, me_chin_ind,'-k','LineWidth', 3, 'color', [0.7 0.7 0.7 0.5]); hold on;
plot(f_chin_me, me_chin_avg,'-k','LineWidth', 3);
title('Middle Ear Absorbance'); subtitle('Chinchilla (n = 9)');
xlabel('Frequency [Hz]'); 
ylabel('Absorbance [%]');
set (gca, 'xscale', 'log'); 
xlim([25,25e3]); ylim([0, 105]); box off;
%% Stimuli Generation
stimuli_chin = filter(b_chin_bp,1,noise);
stimuli_chin = (stimuli_chin + fliplr(stimuli_chin))/2;
t = linspace(0,audio_length,length(stimuli_chin));
t = t(fs+1:end-fs);
stimuli_chin = stimuli_chin(fs+1:end-fs);
stimuli_chin = stimuli_chin/max(abs(stimuli_chin)); % sets max value to 1 for wav file
figure; 
subplot(2,1,1);
plot(t,stimuli_chin,'LineWidth',1.5); hold on; 
xlabel('Time [s]'); ylabel('Amplitude'); 
ylim([-1, 1]); box off;
title('Aircraft Noise'); subtitle('Chinchilla');
% Stimuli Spectra
nfft = 2*fs;
f_fft = fs*ceil(-nfft/2:nfft/2-1)/nfft;
idx = f_fft >= 0;
fft_stim_chin = fftshift(fft(stimuli_chin,nfft));
fft_stim_chin = fft_stim_chin(idx);
%me_chin_avg_db_interp = [interp1(f_chin_me,me_chin_avg_db,f_fft(fs+1:fs+1+0.5*fs)),me_chin_avg_db(end)*ones(1,0.5*fs-1)];
me_chin_avg_db_interp = [interp1(f_chin_me,me_chin_avg_smooth_lowess_db,f_fft(fs+1:fs+1+0.5*fs)),me_chin_avg_smooth_lowess_db(end)*ones(1,0.5*fs-1)];
fft_stim_chin_adj = mag2db(abs(fft_stim_chin)) + me_chin_avg_db_interp;   % adjust for ME absorbance
subplot(2,1,2);
plot(f_fft(idx),mag2db(abs(fft_stim_chin)),'LineWidth',1.5); hold on;
plot(f_fft(idx),fft_stim_chin_adj,'LineWidth',1.5);
title('Aircraft Noise Spectra');
xlabel('Frequency [Hz]'); 
ylabel('Magnitude [dB]');
set (gca, 'xscale', 'log'); 
legend('ME-Unajusted','ME-Adjusted','Location','southwest'); legend boxoff;
xlim([0,50e3]); ylim([-60, 70]); box off;
% Calibration
N = length(fft_stim_chin);
stimuli_chin_energy_t = rms(stimuli_chin)^2;
stimuli_chin_energy_f_unadjusted = rms(abs(fft_stim_chin))^2/(2*N);
stimuli_chin_energy_f_adjusted = rms(db2mag(fft_stim_chin_adj))^2/(2*N);
calib_dBA = 10*log(stimuli_chin_energy_f_unadjusted/stimuli_chin_energy_f_adjusted);
text(1,50,sprintf('Calib: %.1f dBA',calib_dBA),'FontWeight','bold');
print -dtiff ChinAircraftNoise
% Display the results
fprintf('Power in time domain: %.4f\n', stimuli_chin_energy_t);
fprintf('Power in frequency domain (unadjusted): %.4f\n', stimuli_chin_energy_f_unadjusted);
fprintf('Power in frequency domain (adjusted): %.4f\n', stimuli_chin_energy_f_adjusted);
%% Save Stimuli
filename_chin = 'DoD_Chin_stimuli.wav';
audiowrite(filename_chin,stimuli_chin,round(fs));