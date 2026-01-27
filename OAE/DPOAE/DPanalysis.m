function DPanalysis(ROOTdir,datapath,outpath,subject,condition)% DPOAE swept analysis
% Author: Samantha Hauser
% Created: May 2023
% Last Updated: 11 May 2024 by Fernando Aguilera de Alba
%%%%%%%%% Set these parameters %%%%%%%%%%%%%%%%%%
windowdur = .25;  %0.25;
offsetwin = 0.0; % not finding additional delay
npoints = 512;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Import data file
cwd = pwd;
search_file = '*sweptDPOAE*.mat';
PRIVdir = strcat(ROOTdir,filesep,'Code Archive',filesep,'private');
cd(PRIVdir)
datafile = load_files(datapath,search_file,'data');
if isempty(datafile)
    return
end
cd(datapath)
load(datafile);
stim = x.sweptDPOAEData.stim;
%% Import calibration file
search_calib = '*calib_FPL_raw*.mat';
cd(PRIVdir)
calibfile = load_files(datapath,search_calib,'calib',datafile);
cd(datapath)
load(calibfile);
calib = x.FPLearData; clear x;
cd(cwd);
%% Analysis Parameters
stim.scale = 'log';
stim.nearfreqs = [0.9,.88, .86,.84];
trials = size(stim.resp,1);
delay_oops = 0; % 247; %128
phi1_inst = 2 * pi * stim.phi1_inst;
phi2_inst = 2 * pi * stim.phi2_inst;
phi_dp_inst = (2.*stim.phi1_inst - stim.phi2_inst) * 2 * pi;
rdp = 2 / stim.ratio - 1;    % f_dp = f2 * rdp
t = stim.t;
if stim.speed < 0   % downsweep
    f_start = stim.fmax;
    f_end = stim.fmin;
else                % upsweep
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
%% LSF Analysis
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
%% Amplitude and Delay Calculations
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
%% Plot DP - SPL
numOfTrials = floor(trials/2)*2; % need even number of trials
figure;
plot(freq_f2/1000, db(abs(oae_complex).*VtoSPL), 'linew', 2, 'Color', 'red');   % DP
hold on;
plot(freq_f2/1000, db(abs(noise_complex).*VtoSPL), '--', 'linew', 2, 'Color', [0 0 0 0.25]);    % Noise floor
plot(freq_f2/1000, db(abs(complex(a_f2,b_f2)).*VtoSPL), 'linew', 2, 'Color', [0.4940 0.1840 0.5560]);   % stimulus f2
plot(freq_f1/1000, db(abs(complex(a_f1, b_f1)).*VtoSPL), 'linew', 2, 'Color', [0.9290 0.6940 0.1250]);  % stimulus f1
title([subject, ' | DPOAE | ', condition, ' (n = ', num2str(numOfTrials), ')'], 'FontSize', 14, 'FontWeight', 'bold')
set(gca, 'XScale', 'log', 'FontSize', 14)
xlim([.5, 16]); xticks([.5, 1, 2, 4, 8, 16])
ylabel('Amplitude (dB SPL)', 'FontWeight', 'bold')
xlabel('F_2 Frequency (kHz)', 'FontWeight', 'bold')
legend('DP', 'NF', 'F_2', 'F_1','Location','southoutside','Orientation','horizontal')
box off;
%% Convert SPL to EPL
[DP] = calc_EPL(freq_dp, oae_complex.*VtoSPL, calib, 1);
res.complex.dp_epl = DP.P_epl;
res.f_epl = DP.f;
res.dbEPL_dp = db(abs(DP.P_epl));
[NF] = calc_EPL(freq_dp, noise_complex.*VtoSPL, calib, 1);
res.complex.nf_epl = NF.P_epl;
res.f_epl = NF.f;
res.dbEPL_nf = db(abs(NF.P_epl));
res.f.f2 = freq_f2;         % frequency vectors
res.f.f1 = freq_f1;
res.f.dp = freq_dp;
dpoae_full_epl = res.dbEPL_dp;
dpnf_full_epl = res.dbEPL_nf;
f2 = res.f.f2/1000;
%% Calculate band-average DP
fmin = 0.5;
fmax = 16;
edges = 2 .^ linspace(log2(fmin), log2(fmax), 21);
bandEdges = edges(2:2:end-1);
centerFreqs = edges(3:2:end-2);
dpoae_w_spl = zeros(length(centerFreqs),1);
dpnf_w_spl = zeros(length(centerFreqs),1);
dpoae_full_spl = db(abs(oae_complex).*VtoSPL);
dpnf_full_spl = db(abs(noise_complex).*VtoSPL);
% resample / average to 9 center frequencies
for z = 1:length(centerFreqs)
    band = find( f2 >= bandEdges(z) & f2 < bandEdges(z+1));
    % Do some weighting by SNR
    % TO DO: NF from which SNR was calculated included median of 7 points
    % nearest the target frequency
    %EPL
    SNR_epl = dpoae_full_epl(band) - dpnf_full_epl(band);
    weight_epl = (10.^(SNR_epl./10)).^2;  
    dpoae_epl(z, 1) = mean(dpoae_full_epl(band));
    dpnf_epl(z,1) = mean(dpnf_full_epl(band));
    dpoae_w_epl(z,1) = sum(weight_epl.*dpoae_full_epl(band))/sum(weight_epl);
    dpnf_w_epl(z,1) = sum(weight_epl.*dpnf_full_epl(band))/sum(weight_epl);
    %SPL
    SNR_spl = dpoae_full_spl(band) - dpnf_full_spl(band);
    weight_spl = (10.^(SNR_spl./10)).^2;  
    dpoae_spl(z, 1) = mean(dpoae_full_spl(band));
    dpnf_spl(z,1) = mean(dpnf_full_spl(band));
    dpoae_w_spl(z,1) = sum(weight_spl.*dpoae_full_spl(band))/sum(weight_spl);
    dpnf_w_spl(z,1) = sum(weight_spl.*dpnf_full_spl(band))/sum(weight_spl);

end
%% Plot band-average DP - SPL
plot(centerFreqs, dpoae_w_spl, 'o', 'linew', 2, 'MarkerSize', 8, 'MarkerFaceColor', 'r', 'MarkerEdgeColor', 'r','HandleVisibility','off'); % band-average DP
plot(centerFreqs, dpnf_w_spl, 'x', 'linew', 4, 'MarkerSize', 8, 'MarkerFaceColor', 'k', 'MarkerEdgeColor', 'k','HandleVisibility','off'); % band-average noise floor
lowlim = min(dpnf_full_spl);
uplim = max(db(abs(oae_complex).*VtoSPL));
ylim([round(lowlim - 5,1), round(uplim + 5,1)])
%% Export:
% EPL
epl.f = f2; 
epl.oae = dpoae_full_epl; 
epl.nf = dpnf_full_epl; 
epl.centerFreq = centerFreqs;
epl.bandOAE = dpoae_w_epl;
epl.bandNF = dpnf_w_epl;
data.epl = epl; 
% SPL
spl.oae = db(abs(oae_complex).*VtoSPL);
spl.nf = db(abs(noise_complex).*VtoSPL);
spl.f = freq_f2/1000;
spl.VtoSPL = VtoSPL;
spl.centerFreq = centerFreqs;
spl.bandOAE = dpoae_w_spl;
spl.bandNF = dpnf_w_spl;
data.spl = spl;
cd(outpath);
fname = [subject,'_DPOAEswept_',condition,'_',datafile(1:end-4),'_',calibfile(1:end-4)];
print(gcf,[fname,'_figure'],'-dpng','-r300');
save(fname,'data')
cd(cwd);
end