%% Carrier Frequency
close all; clc;
flist = 500;%tone carrier in Hz
%% Stimuli Generation
doSaveFreq_Traj= 0;
fs=48828.125; %TDT sampling rate
tvec=1/fs:1/fs:1; %time in s
silence = 1/fs:1/fs:0.23; %time for silence after stimulus
tdat=tvec;
tvec2=1/fs:1/fs:.5; %duration of each piece
rftime=.001; %rise fall time in s
rflen=round(rftime*fs); %length of rise or fall
rise(1:rflen)=1-(cos(2*pi*(1/(1.33*pi*rftime))*tvec(1:rflen))).^2;
fall(1:rflen)=rise(rflen:-1:1);
noisecar=randn(1,length(tvec)); %noise carrier
tonecar=sin(2*pi*flist*tvec); %tone carrier
noisecar(noisecar>3.5)=3.5; %remove large outliers in noise
noisecar(noisecar<-3.5)=-3.5; %remove large outliers in noise
% AMmodfq1=linspace(3.5,10.5,length(tvec2));
AMmodfq1(1:length(tvec2))=linspace(4,6.5,length(tvec2));
AMmodfq1(length(tvec2)+1:length(tvec))=linspace(6.5,10.25,length(tvec2));
%Made AMmodfq1 a single continuous vector of tvec length

AMmoddepth1=1;
AMfreqvec=2.^AMmodfq1;
% AMmod1=.5*(1-AMmoddepth1*cos(2*pi*AMfreqvec.*tvec+.001));
AMmod1=.5*(1-AMmoddepth1*cos(AMfreqvec.*tvec+.001));
%Made AMmod1 a single continuous vector of tvec length

% amfmnoisevec(1:rflen)=amfmnoisevec(1:rflen).*rise;
% amfmnoisevec((length(tvec2)-rflen+1):length(tvec2))=amfmnoisevec((length(tvec2)-rflen+1):length(tvec2)).*fall;
amfmnoisevec(1:length(tvec))=noisecar.*AMmod1;
amfmtonevec=tonecar(1:length(tvec)).*AMmod1;
%% Made amfmtonevec a single continuous vector of tvec length
% amfmtonevec(1:rflen)=amfmtonevec(1:rflen).*rise;
% amfmtonevec(length(tvec2)+1:length(tvec))=amfmtonevec(length(tvec2):-1:1);
% AMfreqvec_est= AMfreqvec.*(1+6.25*log(2)*tvec)/5.33;
T_half= 0.5;
AMfreqvec_est_1= AMfreqvec(1:length(tvec2))/(2*pi) .* ( 1 + log(2)*(6.5-4)/T_half*tvec2);
AMfreqvec_est_2= AMfreqvec(length(tvec2)+1:length(tvec))/(2*pi) .* ( 1 + log(2)*(10.25-6.5)/T_half*tvec(length(tvec2)+1:length(tvec)));
AMfreqvec_est= [AMfreqvec_est_1, AMfreqvec_est_2];

figure(3);
clf;

% subplot(3,1,1)
% plot(tvec,amfmtonevec,'b-')
%
% subplot(3,1,2)
% plot(tvec,AMfreqvec,'b-')

am_adj_factor= .92;


hold on;
subplot(211)
helper.plot_spectrogram(amfmtonevec, fs, 40e-3, .95)
line(tvec*1e3, (flist+am_adj_factor*AMfreqvec)/1e3, 'color', 'r', 'linew', 2, 'linestyle', ':')
line(tvec*1e3, (flist+0*am_adj_factor*AMfreqvec)/1e3, 'color', 'r', 'linew', 2, 'linestyle', ':')
line(tvec*1e3, (flist-am_adj_factor*AMfreqvec)/1e3, 'color', 'r', 'linew', 2, 'linestyle', ':')
line(tvec*1e3, (flist+AMfreqvec_est)/1e3, 'color', 'c', 'linew', 2, 'linestyle', ':')
line(tvec*1e3, (flist+0*AMfreqvec_est)/1e3, 'color', 'c', 'linew', 2, 'linestyle', ':')
line(tvec*1e3, (flist-AMfreqvec_est)/1e3, 'color', 'c', 'linew', 2, 'linestyle', ':')

colorbar off;
ylim([(flist-2^10.25*1.2) (flist+2^10.25*1.2)]/1e3);
title('Desired');

subplot(212)
hold on;
env_sig= abs(hilbert(amfmtonevec));
helper.plot_spectrogram(env_sig-mean(env_sig), fs, 40e-3, .95)
line(tvec*1e3, am_adj_factor*AMfreqvec/1e3, 'color', 'r', 'linew', 2, 'linestyle', ':')
line(tvec*1e3, AMfreqvec_est/1e3, 'color', 'c', 'linew', 2, 'linestyle', ':')
colorbar off;
ylim([0 2^10.25*1.2]/1e3);


if doSaveFreq_Traj
    save('AMfreqvec_est.mat', 'AMfreqvec_est', 'fs');
end

%% for noise, need to work on it still
y = amfmnoisevec;
% noise_spl_at_1Vrms = compute_noise_maxSPL(y, calibrationFile, Fs_Hz);
% scaleFactor = max(abs(y));
% y = y / scaleFactor; % scale to +/- 1
% refSPL = noise_spl_at_1Vrms - 20*log10(scaleFactor);
%
% EPLwavwrite(y, Fs_Hz, 16, sprintf('Stimulus-freq0-token%d.wav', k), 'refSPL', refSPL);

%% for tone, hard coding value for 12 and 30k
% outputFolder = 'D:\Proteus\NSDH\Patterns stimuli+EEG\Stimuli\Stimulilongass4EEG';
% refSPL = 92.33 - 3; % Hardocding for CF right now. minus 3dB because it is RMS, not peak. This is freefield 4inch right speaker calib for 30k. on 8/20/21
%          refSPL = 74.5 - 3; % Hardocding for CF right now. minus 3dB because it is RMS, not peak. This is freefield 4inch right speaker calib for 12k. on 8/20/21
%            refSPL = 130.79 - 3; % Hardocding for CF right now. minus 3dB because it is RMS, not peak. This is 5ml syringe coupler at 1ml, right ER3C calib for 2000Hz. on 9/3/21
%            refSPL = 127.8 - 3; % Hardocding for CF right now. minus 3dB because it is RMS, not peak. This is 5ml syringe coupler at 1ml, right ER3C calib for 2000Hz. on 9/3/21
%              refSPL = 82.67 - 3; % Hardocding for CF right now. minus 3dB because it is RMS, not peak. This is freefield  right speaker calib for 3k. on 9/14/21
% refSPL = 118.45 - 3; % Hardocding for CF right now. minus 3dB because it is RMS, not peak. This is insert ER3c with 2cc coupler and tiptrode tube in FT, right for 3k. on 2/3/22
%                 refSPL = 125.07 - 3; % Hardocding for CF right now. minus 3dB because it is RMS, not peak. This is insert ER3c with 2cc coupler, right for 3k. on 9/21/21
%               refSPL = 125.23 - 3; % Hardocding for CF right now. minus 3dB because it is RMS, not peak. This is insert ER3c with 2cc coupler, right for 1k. on 9/21/21
%               refSPL = 86.158 - 3; % Hardocding for CF right now. minus 3dB because it is RMS, not peak. This is insert ER3c with 2cc coupler, right for 8k. on 9/21/21​
% Write wav files
%    EPLwavwrite(amfmtonevec, fs, 16, fullfile(outputFolder, sprintf('DoDAMPatterns_3k_gerbils_freefield.wav')),  'refSPL', refSPL);
%      EPLwavwrite(amfmtonevec, fs, 16, fullfile(outputFolder, sprintf('DoDAMPatternsNEW_3k_humans_ER3c2cctipFT.wav')),  'refSPL', refSPL);
%    save (fullfile(outputFolder, sprintf('DoDAMPatternsNEW_3k_humans_ER3c2cctipFT.mat')), 'amfmtonevec', 'fs');