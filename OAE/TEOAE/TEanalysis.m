function TEanalysis(ROOTdir,datapath,outpath,subject,condition)% TEOAE Analysis
% Author: Samantha Hauser
% Created: May 2023
% Last Updated: Oct 2026 — high-pass cutoff and trimmed mean from the OAE
%   Setup panel (oae_opts); bands via oae_band_avg.
o = oae_opts();
% Purpose:
% Helpful info:
%% Import data file
cwd = pwd;
search_file = '*TEOAE*.mat';
datafile = load_files(datapath,search_file,'data');
if isempty(datafile)
    return
end
cd(datapath)
S_raw = load(datafile, 'x');  x = S_raw.x;  clear S_raw
stim = x.TEOAEData.stim;
cd(cwd);
%% Analysis Parameters
res.resp_win = stim.resp(:, (stim.StimWin+1):(stim.StimWin + stim.RespDur)); % Remove stimulus by windowing
resp = res.resp_win; 
if stim.doFilt
    % High pass (default 200 Hz) using IIR filter
    [b, a] = butter(4, o.te_hp * 2 * 1e-3/stim.SamplingRate, 'high');
    resp = filtfilt(b, a, res.resp_win')';
end
vavg_odd = trimmean(resp(1:2:end, :), o.te_trim, 1);
vavg_even = trimmean(resp(2:2:end, :), o.te_trim, 1);
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
title([subject, ' | TEOAE | ', condition, ' (n = ', num2str(size(resp,1)), ')'], 'FontSize', 14, 'FontWeight', 'bold');
%% Calculate band-average TE (bands / method / SNR criterion from oae_opts)
teoae_full_spl = db(abs(res.Resp));
tenf_full_spl = db(abs(res.NoiseFloor));
[centerFreqs, b_lo, b_hi] = oae_bands(o);
B_spl = oae_band_avg(res.freq*1e-3, teoae_full_spl, tenf_full_spl, b_lo, b_hi, o);
teoae_w_spl = B_spl.oae(:);  tenf_w_spl = B_spl.nf(:);
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
data.n_trials = size(resp,1);                        % trials used (individual legend)
data.opts = struct('hp',o.te_hp,'trim',o.te_trim);   % analysis settings used
cd(outpath);
fname = [subject,'_TEOAE_',condition,'_',datafile(1:end-4)];
try, apat_save_fig(gcf, fullfile(outpath, [fname '_figure']), 'te_rec'); catch, end   % this recording's analysis figure
close(gcf);
data.sex = apat_sex('get', subject);   % chinroster Sex column ('' if unknown)
save(fname,'data')
cd(cwd);
end
