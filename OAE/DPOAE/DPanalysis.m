% DPOAE swept Analysis
% Author: Samantha Hauser
% Created: May 2023
% Last Updated: August 27, 2023
% Purpose:
% Helpful info:
%%%%%%%%% Set these parameters %%%%%%%%%%%%%%%%%%
windowdur = .25;  %0.25;
offsetwin = 0.0; % not finding additional delay
npoints = 512;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Import data
cwd = pwd;
cd(datapath)
datafile = dir(fullfile(cd,('*sweptDPOAE*.mat')));
if length(datafile) < 1
    fprintf('No files for this subject...Quitting.\n')
    cd(cwd);
    return
elseif size(datafile,1) > 1
    fprintf('More than 1 data file. Check this is correct file!\n');
    checkDIR = {uigetfile('*sweptDPOAE.mat')};
    load(checkDIR{1});
    file = checkDIR; 
else
    load(datafile(1).name);
    file = datafile(1).name; 
end
stim = x.sweptDPOAEData.stim;
% SET CALIB FILE HERE
cd(calibpath)
calibfile = dir(fullfile(cd,('*calib_FPL_inv*.mat')));
if length(calibfile) < 1
    fprintf('No calibration file found...Quitting!\n'); 
elseif size(calibfile,1) > 1
    fprintf('Multiple calibration files found, select one.\n');
    checkDIR =uigetfile('*calib_FPL_inv*.mat');
    load(checkDIR);
    file = checkDIR; 
else
    load(calibfile(1).name);
    file = calibfile(1).name; 
end
calib = x.FPLearData;
res.calib = calib; 
cd(cwd);
stim.scale = 'log';
stim.nearfreqs = [0.9,.88, .86,.84];
trials = size(stim.resp,1);
% figure; plot(stim.resp(1,:))
delay_oops = 0; % 247; %128
%% Set variables from the stim
phi1_inst = 2 * pi * stim.phi1_inst;
phi2_inst = 2 * pi * stim.phi2_inst;
phi_dp_inst = (2.*stim.phi1_inst - stim.phi2_inst) * 2 * pi;
rdp = 2 / stim.ratio - 1;    % f_dp = f2 * rdp
t = stim.t;
if stim.speed < 0 % downsweep
    f_start = stim.fmax;
    f_end = stim.fmin;
else
    f_start = stim.fmin;
    f_end = stim.fmax;
end
% set freq we're testing and the timepoints when they happen.
if strcmp(stim.scale, 'log')        % in octave scaling
    freq_f2 = 2 .^ linspace(log2(f_start), log2(f_end), npoints);
    freq_f1 = freq_f2 ./ stim.ratio;
    freq_dp = 2.*freq_f1 - freq_f2;
    t_freq = log2(freq_f2/f_start)/stim.speed + stim.buffdur;
else                            % otherwise linear scaling
    freq_f2 = linspace(f_start, f_end, npoints);
    freq_f1 = freq_f2 ./ stim.ratio;
    freq_dp = 2.*freq_f1 - freq_f2;
    t_freq = (freq_f2-f_start)/stim.speed + stim.buffdur;
end
nfreqs = stim.nearfreqs;
%% Artifact Rejection
DPOAEtrials = zeros(size(stim.resp)); 
DPOAEtrials(:,1:end-delay_oops) = stim.resp(:,delay_oops +1:end);
% Set empty matricies for next steps
coeffs = zeros(npoints, 2);
a_temp = zeros(trials, npoints);
b_temp = zeros(trials, npoints);
% Least Squares fit of DP after artifact rejection
for x = 1:trials
    DPOAE = DPOAEtrials(x, :);
    fprintf(1, 'Checking trial %d / %d for artifact\n', x, trials);
    for k = 1:npoints
        win = find( (t > (t_freq(k) - windowdur/2)) & ...
            (t < (t_freq(k) + windowdur/2)));
        taper = hanning(numel(win))';
        model_dp = [cos(phi_dp_inst(win)) .* taper;
            -sin(phi_dp_inst(win)) .* taper];
        resp = DPOAE(win) .* taper;
        coeffs(k, 1:2) = model_dp' \ resp';
    end
    a_temp(x,:) = coeffs(:, 1);
    b_temp(x,:) = coeffs(:, 2);
end
oae = abs(complex(a_temp, b_temp));
median_oae = median(oae);
std_oae = std(oae);
resp_AR = DPOAEtrials;
for j = 1:trials
    for k = 1:npoints
        if oae(j,k) > median_oae(1,k) + 3*std_oae(1,k)
            win = find( (t > (t_freq(k) - windowdur.*.1)) & ...
                (t < (t_freq(k) + windowdur.*.1)));
            resp_AR(j,win) = NaN;
        end
    end
end
DPOAE = mean(resp_AR, 1, 'omitNaN');
%% LSF analysis
% Set empty matricies for next steps
maxoffset = ceil(stim.Fs * offsetwin);
coeffs = zeros(npoints, 2);
tau_dp = zeros(npoints, 1); % delay if offset > 0
coeffs_noise = zeros(npoints,8);
% if duration changes with frequency
%durs = -.5*(2.^(0.003*t_freq)-1)/ (0.003*log(2)) + 0.5;
% Least Squares fit of Chirp model (stimuli, DP, noise)
for k = 1:npoints
    fprintf(1, 'Running window %d / %d\n', k, npoints);
    % if using durs: windowdur = durs(k);
    win = find( (t > (t_freq(k) - windowdur/2)) & ...
        (t < (t_freq(k) + windowdur/2)));
    taper = hanning(numel(win))';
    % set the response
    resp = DPOAE(win) .* taper;
    % DP Coeffs with variable delay calculation
    model_dp = [cos(phi_dp_inst(win)) .* taper;
        -sin(phi_dp_inst(win)) .* taper];
    % zero out variables for offset calc
    coeff = zeros(maxoffset, 6);
    coeff_n = zeros(maxoffset, 6);
    resid = zeros(maxoffset, 3);
    for offset = 0:maxoffset
        resp = DPOAE(win+offset) .* taper;
        coeff(offset + 1, 1:2) = model_dp' \ resp';
        resid(offset + 1, 1) = sum( (resp  - coeff(offset + 1, 1:2) * model_dp).^2);
    end
    [~, ind] = min(resid(:,1));
    coeffs(k, 1:2) = coeff(ind, 1:2);
    % Calculate delay
    tau_dp(k) = (ind(1) - 1) * 1/stim.Fs; % delay in sec
    % F1 Coeffs
    model_f1 = [cos(phi1_inst(win)) .* taper;
        -sin(phi1_inst(win)) .* taper];
    coeffs(k, 3:4) = model_f1' \ resp';
    % F2 Coeffs
    model_f2 = [cos(phi2_inst(win)) .* taper;
        -sin(phi2_inst(win)) .* taper];
    coeffs(k, 5:6) = model_f2' \ resp';
    % Noise Coeffs
    model_noise = ...
        [cos(nfreqs(1)*phi_dp_inst(win)) .* taper;
        -sin(nfreqs(1)*phi_dp_inst(win)) .* taper;
        cos(nfreqs(2)*phi_dp_inst(win)) .* taper;
        -sin(nfreqs(2)*phi_dp_inst(win)) .* taper;
        cos(nfreqs(3)*phi_dp_inst(win)) .* taper;
        -sin(nfreqs(3)*phi_dp_inst(win)) .* taper;
        cos(nfreqs(4)*phi_dp_inst(win)) .* taper;
        -sin(nfreqs(4)*phi_dp_inst(win)) .* taper];
    coeffs_noise(k,:) = model_noise' \ resp';
end
%% Amplitude and Delay calculations
a_dp = coeffs(:, 1);
b_dp = coeffs(:, 2);
a_f1 = coeffs(:, 3);
b_f1 = coeffs(:, 4);
a_f2 = coeffs(:, 5);
b_f2 = coeffs(:, 6);
% complex DPOAE
oae_complex = complex(a_dp, b_dp);
% complex average noise
noise = zeros(npoints,4);
for i = 1:2:8
    noise(:,ceil(i/2)) = complex(coeffs_noise(:,i), coeffs_noise(:,i+1));
end
noise_complex = mean(noise,2);
% delay
phi_dp = tau_dp.*freq_dp'; % cycles (from delay/offset)
phasor_dp = exp(-1j * phi_dp * 2 * pi);
VtoSPL = stim.VoltageToPascal .* stim.PascalToLinearSPL;
res.VtoSPL = VtoSPL;
%% Plot Results Figure
figure;
plot(freq_f2/1000, db(abs(oae_complex).*VtoSPL), 'linew', 2, 'Color', 'red');
hold on;
plot(freq_f2/1000, db(abs(noise_complex).*VtoSPL), '--', 'linew', 2, 'Color', 'black');
plot(freq_f2/1000, db(abs(complex(a_f2,b_f2)).*VtoSPL), 'linew', 2, 'Color', [0.4940 0.1840 0.5560]);
plot(freq_f1/1000, db(abs(complex(a_f1, b_f1)).*VtoSPL), 'linew', 2, 'Color', [0.9290 0.6940 0.1250]);
title('DPOAE', 'FontSize', 14)
set(gca, 'XScale', 'log', 'FontSize', 14)
xlim([.5, 16])
ylim([-50, 90])
xticks([.5, 1, 2, 4, 8, 16])
ylabel('Amplitude (dB SPL)', 'FontWeight', 'bold')
xlabel('F_2 Frequency (kHz)', 'FontWeight', 'bold')
legend('DPOAE', 'NF', 'F_2', 'F_1')
drawnow;
%% Get EPL units
[DP] = calc_EPL(freq_dp, oae_complex.*VtoSPL, calib, 1);
res.complex.dp_epl = DP.P_epl;
res.f_epl = DP.f;
res.dbEPL_dp = db(abs(DP.P_epl));
[NF] = calc_EPL(freq_dp, noise_complex.*VtoSPL, calib, 1);
res.complex.nf_epl = NF.P_epl;
res.f_epl = NF.f;
res.dbEPL_nf = db(abs(NF.P_epl));

%                 [F1] = calc_FPL(res.f.f1, res.complex_f1, res.calib.Ph1);
%                 res.complex_f1_fpl = F1.P_fpl;
%                 res.f1_fpl = F1.f;
%                 if exist('res.calib.Ph2', 'var')
%                     [F2] = calc_FPL(res.f.f2, res.complex_f2, res.calib.Ph2);
%                 else
%                     [F2] = calc_FPL(res.f.f2, res.complex_f2, res.calib.Ph1);
%                 end
%                 res.complex_f2_fpl = F2.P_fpl;
%                 res.f2_fpl = F2.f;
% plot figure again
% figure;
% plot(freq_f2/1000, res.dbEPL_dp, 'linew', 3, 'Color', 'r');
% hold on;
% plot(freq_f2/1000, res.dbEPL_nf, 'k--', 'linew', 1.5);
% %plot(freq_f2/1000, db(abs(complex(a_f2,b_f2)).*stim.VoltageToPascal.*stim.PascalToLinearSPL));
% %plot(freq_f1/1000, db(abs(complex(a_f1, b_f1)).*stim.VoltageToPascal.*stim.PascalToLinearSPL));
% %title(sprintf('Subj: %s, Ear: %s', string(subj), string(ear)))
% title('DPOAE', 'FontSize', 14)
% set(gca, 'XScale', 'log', 'FontSize', 14)
% xlim([.5, 16])
% ylim([-50, 50])
% xticks([.5, 1, 2, 4, 8, 16])
% ylabel('Amplitude (dB EPL)', 'FontWeight', 'bold')
% xlabel('F2 Frequency (kHz)', 'FontWeight', 'bold')
% legend('DPOAE', 'NF')
drawnow;
res.f.f2 = freq_f2;         % frequency vectors
res.f.f1 = freq_f1;
res.f.dp = freq_dp;
dpoae_full = res.dbEPL_dp;
dpnf_full = res.dbEPL_nf;
f2 = res.f.f2/1000;
% SEt params
fmin = 0.5;
fmax = 16;
edges = 2 .^ linspace(log2(fmin), log2(fmax), 21);
bandEdges = edges(2:2:end-1);
centerFreqs = edges(3:2:end-2);
dpoae = zeros(length(centerFreqs),1);
dpnf = zeros(length(centerFreqs),1);
dpoae_w = zeros(length(centerFreqs),1);
dpnf_w = zeros(length(centerFreqs),1);
% resample / average to 9 center frequencies
for z = 1:length(centerFreqs)
    band = find( f2 >= bandEdges(z) & f2 < bandEdges(z+1));
    % Do some weighting by SNR
    % TO DO: NF from which SNR was calculated included median of 7 points
    % nearest the target frequency.
    SNR = dpoae_full(band) - dpnf_full(band);
    weight = (10.^(SNR./10)).^2;  
    dpoae(z, 1) = mean(dpoae_full(band));
    dpnf(z,1) = mean(dpnf_full(band));
    dpoae_w(z,1) = sum(weight.*dpoae_full(band))/sum(weight);
    dpnf_w(z,1) = sum(weight.*dpnf_full(band))/sum(weight);
end
% figure;
% hold on;
% semilogx(f2, dpoae_full, 'Color', [.8, .8, .8], 'linew', 2)
% semilogx(f2, dpnf_full, '--', 'linew', 1.5, 'Color', [.8, .8, .8])
% semilogx(centerFreqs, dpoae_w, 'o', 'linew', 4, 'MarkerSize', 10, 'MarkerFaceColor', 'b', 'MarkerEdgeColor', 'b')
% set(gca, 'XScale', 'log', 'FontSize', 14)
% xlim([.5, 16])
% ylim([-50, 50])
% xticks([.5, 1, 2, 4, 8, 16])
% ylabel('Amplitude (dB EPL)', 'FontWeight', 'bold')
% xlabel('F2 Frequency (kHz)', 'FontWeight', 'bold')
% title('DPOAE', 'FontSize', 16); 
result.f2 = f2; 
result.oae_full = dpoae_full; 
result.nf_full = dpnf_full; 
result.centerFreqs = centerFreqs; 
result.oae_summary = dpoae_w; 
data.result = result; 
data.res = res; 
%% Export:
cd(outpath);
fname = [subj,'_DPOAEswept_',condition,'_',file(end-11:end-4)];
print(gcf,[fname,'_figure'],'-dpng','-r300');
save(fname,'data')
cd(cwd);