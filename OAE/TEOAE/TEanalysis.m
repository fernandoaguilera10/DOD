function TEanalysis(datapath,outpath,subject,condition)% TEOAE Analysis
% Author: Samantha Hauser
% Created: May 2023
% Last Updated: August 2, 2023
% Purpose:
% Helpful info:
%% Import data file
search_file = '*TEOAE*.mat';
datafile = load_files(datapath,search_file);
if isempty(datafile)
    return
end
cwd = pwd;
cd(datapath)
load(datafile);
stim = x.TEOAEData.stim;
cd(cwd);
%% Analysis Parameters
res.resp_win = stim.resp(:, (stim.StimWin+1):(stim.StimWin + stim.RespDur)); % Remove stimulus by windowing
resp = res.resp_win; 
if stim.doFilt
    % High pass at 200 Hz using IIR filter
    [b, a] = butter(4, 200 * 2 * 1e-3/stim.SamplingRate, 'high');
    resp = filtfilt(b, a, res.resp_win')';
end
vavg_odd = trimmean(resp(1:2:end, :), 20, 1);
vavg_even = trimmean(resp(2:2:end, :), 20, 1);
rampdur = 0.2e-3; %seconds
Fs = stim.SamplingRate/2 * 1e3;
res.vavg = rampsound((vavg_odd + vavg_even)/2, Fs, rampdur);
res.noisefloor = rampsound((vavg_odd - vavg_even)/2, Fs, rampdur);
Vavg = rfft(res.vavg);
Vavg_nf = rfft(res.noisefloor);
% Apply calibartions to convert voltage to pressure
% For ER-10X, this is approximate
mic_sens = stim.mic_sens; % mV/Pa. TO DO: change after calibration
mic_gain = stim.mic_gain; 
P_ref = stim.P_ref;
DR_onesided = stim.DR_onesided;
factors = DR_onesided * mic_gain * mic_sens * P_ref;
output_Pa_per_20uPa = Vavg / factors; % unit: 20 uPa / Vpeak
noise_Pa_per_20uPa = Vavg_nf / factors;
res.freq = 1000*linspace(0,stim.SamplingRate/2,length(Vavg))';
res.Resp =  output_Pa_per_20uPa;
res.NoiseFloor = noise_Pa_per_20uPa;
%% Plot TE - SPL
figure;
hold on;
plot(res.freq*1e-3, db(abs(res.Resp)), 'linew', 2, 'Color', 'green');
ylabel('Response (dB SPL)', 'FontSize', 14, 'FontWeight', 'bold');
uplim = max(db(abs(res.Resp)));
hold on;
semilogx(res.freq*1e-3, db(abs(res.NoiseFloor)),'--', 'linew', 2, 'Color', 'black');
xlabel('Frequency (kHz)', 'FontSize', 14, 'FontWeight', 'bold');
legend('TEOAE', 'NF');
xlim([0.5, 16]);
ticks = [0.5, 1, 2, 4, 8, 16];
set(gca, 'XTick', ticks, 'FontSize', 14, 'xscale', 'log');
ylim([-60, uplim + 5]);
title([subject, ' | TEOAE | ', condition, ' (n = 2056)'], 'FontSize', 14, 'FontWeight', 'bold');
%% Calculate band-average SF
fmin = 0.5;
fmax = 16;
edges = 2 .^ linspace(log2(fmin), log2(fmax), 21);
bandEdges = edges(2:2:end-1);
centerFreqs = edges(3:2:end-2);
teoae_w_spl = zeros(length(centerFreqs),1);
tenf_w_spl = zeros(length(centerFreqs),1);
teoae_full_spl = db(abs(res.Resp));
tenf_full_spl = db(abs(res.NoiseFloor));
% resample / average to 9 center frequencies
for z = 1:length(centerFreqs)
    band = find( res.freq*1e-3 >= bandEdges(z) & res.freq*1e-3 < bandEdges(z+1));
    % Do some weighting by SNR
    % TO DO: NF from which SNR was calculated included median of 7 points
    % nearest the target frequency
    %SPL
    SNR_spl = teoae_full_spl(band) - tenf_full_spl(band);
    weight_spl = (10.^(SNR_spl./10)).^2;  
    teoae_spl(z, 1) = mean(teoae_full_spl(band));
    tenf_spl(z,1) = mean(tenf_full_spl(band));
    teoae_w_spl(z,1) = sum(weight_spl.*teoae_full_spl(band))/sum(weight_spl);
    tenf_w_spl(z,1) = sum(weight_spl.*tenf_full_spl(band))/sum(weight_spl);

end
%% Plot band-average SF - SPL
plot(centerFreqs, teoae_w_spl, 'o', 'linew', 2, 'MarkerSize', 8, 'MarkerFaceColor', 'r', 'MarkerEdgeColor', 'r','HandleVisibility','off'); % band-average DP
plot(centerFreqs, tenf_w_spl, 'x', 'linew', 4, 'MarkerSize', 8, 'MarkerFaceColor', 'k', 'MarkerEdgeColor', 'k','HandleVisibility','off'); % band-average noise floor
lowlim = min(tenf_full_spl);
uplim = max(db(abs(res.Resp)));
ylim([round(lowlim - 5,1), round(uplim + 5,1)]);
%% Export:
% SPL
spl.f = res.freq*1e-3;
spl.oae = db(abs(res.Resp));
spl.nf = db(abs(res.NoiseFloor));
spl.centerFreq = centerFreqs;
spl.bandOAE = teoae_w_spl;
spl.bandNF = tenf_w_spl;
data.spl = spl;
cd(outpath);
fname = [subject,'_TEOAE_',condition,'_',datafile(1:end-4)];
print(gcf,[fname,'_figure'],'-dpng','-r300');
save(fname,'data')
cd(cwd);
end