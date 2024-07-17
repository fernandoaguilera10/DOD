function SFanalysis(datapath,outpath,subject,condition)% SFOAE swept analysis
% Author: Samantha Hauser
% Created: May 2023
% Last Updated: 11 May 2024 by Fernando Aguilera de Alba
%%% Set these parameters %%%%%%%%%%%%%
windowdur = 0.040; % 40ms in paper
offsetwin = 0.0; % 20ms in paper
npoints = 512;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Import data file
search_file = '*sweptSFOAE*.mat';
datafile = load_files(datapath,search_file);
if isempty(datafile)
    return
end
cwd = pwd;
cd(datapath)
load(datafile);
stim = x.sweptSFOAEData.stim;
%% Import calibration file
search_calib = '*calib_FPL_raw*.mat';
calibfile = load_files(datapath,search_calib);
load(calibfile);
calib = x.FPLearData; clear x;
cd(cwd);
%% Analysis Parameters
phiProbe_inst = 2*pi*stim.phiProbe_inst;
t = stim.t;
if stim.speed < 0   % downsweep
    f1 = stim.fmax;
    f2 = stim.fmin;
else                % upsweep
    f1 = stim.fmin;
    f2 = stim.fmax;
end
% set freq we're testing and the timepoints when they happen.
if abs(stim.speed) < 20 %linear sweep
    testfreq = 2 .^ linspace(log2(f1), log2(f2), npoints);
    t_freq = log2(testfreq/f1)/stim.speed + stim.buffdur;
else % log sweep
    testfreq = linspace(f1, f2, npoints);
    t_freq = (testfreq-f1)/stim.speed + stim.buffdur;
end
%duration changes w/ frequency
durs = .038*(2.^(-0.3*t_freq)-1)/ (-0.3*log(2)) + 0.038;
%% Artifact Rejection
% Cancel out stimulus
SFOAEtrials = stim.ProbeBuffs + stim.SuppBuffs - stim.BothBuffs;
trials = size(SFOAEtrials,1);
% high pass filter the response (can also be done on ER10X hardware)
filtcutoff = 300;
b = fir1(1000, filtcutoff*2/stim.Fs, 'high');
SFOAEtrials= filtfilt(b, 1, SFOAEtrials')';
% Set empty matricies for next steps
coeffs = zeros(npoints, 6);
a_temp = zeros(trials, npoints);
b_temp = zeros(trials, npoints);
% Least Squares fit of SF Only for AR
for x = 1:trials
    SFOAE = SFOAEtrials(x, :);
    fprintf(1, 'Checking trial %d / %d for artifact\n', x, trials);
    
    for k = 1:npoints
        windowdur = durs(k);
        win = find( (t > (t_freq(k) - windowdur/2)) & ...
            (t < (t_freq(k) + windowdur/2)));
        taper = hanning(numel(win))';
        model_sf = [cos(phiProbe_inst(win)) .* taper;
            -sin(phiProbe_inst(win)) .* taper];
        resp = SFOAE(win) .* taper;
        coeffs(k, 1:2) = model_sf' \ resp';
    end
    a_temp(x,:) = coeffs(:, 1);
    b_temp(x,:) = coeffs(:, 2);
end
oae = abs(complex(a_temp, b_temp));
median_oae = median(oae);
std_oae = std(oae);
resp_AR = SFOAEtrials;
for j = 1:trials
    for k = 1:npoints
        if oae(j,k) > median_oae(1,k) + 4*std_oae(1,k)
            win = find( (t > (t_freq(k) - durs(k).*.1)) & ...
                (t < (t_freq(k) + durs(k).*.1)));
            resp_AR(j,win) = NaN;
        end
    end
end
%% Calculate Noise Floor (two ways)
numOfTrials = floor(trials/2)*2; % need even number of trials
% first method, subtraction
for y = 1:2:numOfTrials
    pos_SF(ceil(y/2),:) = resp_AR(y,:);
    neg_SF(ceil(y/2),:) = resp_AR(y+1,:);
end
numTrials2 = floor(numOfTrials/4).*2;
pos_noise = zeros(numTrials2/2, size(pos_SF,2));
neg_noise = zeros(numTrials2/2, size(pos_SF,2));
for x = 1:2:numTrials2
    pos_noise(ceil(x/2),:) = (pos_SF(x, :) - pos_SF(x+1, :)) / 2;
    neg_noise(ceil(x/2),:) = (neg_SF(x, :) - neg_SF(x+1, :)) / 2;
end
noise = [pos_noise; neg_noise];
SFOAE = mean(resp_AR, "omitNaN"); % mean SFOAE after artifact rejection
NOISE = mean(noise, "omitNaN"); % mean noise after artifact rejection
%% LSF Analysis
% Set empty matricies for next steps
maxoffset = ceil(stim.Fs * offsetwin);
coeffs = zeros(npoints, 2);
coeffs_n = zeros(npoints, 2);
tau = zeros(npoints, 1);
coeffs_noise = zeros(npoints,8);
durs = .038*(2.^(-0.3*t_freq)-1)/ (-0.3*log(2)) + 0.038;
% Generate model of chirp and test against response
for k = 1:npoints
    fprintf(1, 'Running window %d / %d\n', k, (npoints));
    windowdur = durs(k);
    win = find( (t > (t_freq(k)-windowdur/2)) & ...
        (t < (t_freq(k)+windowdur/2)));
    taper = hanning(numel(win))';
    % set the models 
    % SF probe frequency
    model = [cos(phiProbe_inst(win)) .* taper;
        -sin(phiProbe_inst(win)) .* taper];   
    % nearby frequencies for nf calculation 
    model_noise = [cos(1.1*phiProbe_inst(win)) .* taper;
        -sin(1.1*phiProbe_inst(win)) .* taper;
        cos(1.12*phiProbe_inst(win)) .* taper;
        -sin(1.12*phiProbe_inst(win)) .* taper;
        cos(1.14*phiProbe_inst(win)) .* taper;
        -sin(1.14*phiProbe_inst(win)) .* taper;
        cos(1.16*phiProbe_inst(win)) .* taper;
        -sin(1.16*phiProbe_inst(win)) .* taper];
    % zero out variables for offset calc
    coeff = zeros(maxoffset, 2);
    coeff_n = zeros(maxoffset, 2);
    resid = zeros(maxoffset, 1);
    coeff_noise = zeros(maxoffset, 8);
    for offset = 0:maxoffset
        resp = SFOAE(win+offset) .* taper;
        resp_n = NOISE(win+offset) .* taper;     
        coeff(offset + 1, :) = model' \ resp';
        coeff_n(offset + 1, :) = model' \ resp_n';
        coeff_noise(offset +1, :) = model_noise' \ resp';      
        resid(offset +1) = sum( (resp - coeff(offset+1, :) * model).^2);
    end 
    [~, ind] = min(resid);  
    coeffs(k, :) = coeff(ind, :);
    coeffs_n(k, :) = coeff_n(ind, :);
    coeffs_noise(k,:) = coeff_noise(ind,:);
    tau(k) = (ind - 1) * (1/stim.Fs); % delay in sec
end
%% Amplitude and Delay Calculations
a = coeffs(:, 1);
b = coeffs(:, 2);
a_n = coeffs_n(:, 1); % subtraction nf
b_n = coeffs_n(:, 2);
phi = tau.*testfreq'; % cycles (from delay/offset)
phasor = exp(-1j * phi* 2 * pi);
% for noise
noise2 = zeros(npoints,4);
for i = 1:2:8
    noise2(:,ceil(i/2)) = complex(coeffs_noise(:,i), coeffs_noise(:,i+1));
end
oae_complex = complex(a, b).*phasor;
noise_complex2 = complex(a_n, b_n);
noise_complex = mean(noise2,2);
res.multiplier = stim.VoltageToPascal.* stim.PascalToLinearSPL;
%% Plot SF - SPL
figure;
plot(testfreq/1000, db(abs(oae_complex).*res.multiplier), 'linew', 2, 'Color', 'blue'); hold on;
plot(testfreq/1000, db(abs(noise_complex).*res.multiplier), '--', 'linew', 2, 'Color', 'black');
title([subject, ' | SFOAE | ', condition, ' (n = ', num2str(numOfTrials), ')'], 'FontSize', 14, 'FontWeight', 'bold')
set(gca, 'XScale', 'log', 'FontSize', 14)
xlim([.5, 16])
xticks([.5, 1, 2, 4, 8, 16])
xlabel('Frequency (kHz)','FontWeight','bold')
ylabel('Amplitude (dB SPL)','FontWeight','bold')
legend('SFOAE', 'NF')
box off;
%% Convert SPL to EPL
[SF] = calc_EPL(testfreq, oae_complex.*res.multiplier, calib, 1);
res.complex.dp_epl = SF.P_epl;
res.f_epl = SF.f;
res.dbEPL_sf = db(abs(SF.P_epl));
[NF] = calc_EPL(testfreq, noise_complex.*res.multiplier, calib, 1);
res.complex.nf_epl = NF.P_epl;
res.f_epl = NF.f;
res.dbEPL_nf = db(abs(NF.P_epl));
sfoae_full_epl = res.dbEPL_sf;
sfnf_full_epl = res.dbEPL_nf;
%% Plot SF - EPL
% figure;
% plot(testfreq/1000, res.dbEPL_sf, 'linew', 3, 'Color', '#4575b4'); hold on;
% plot(testfreq/1000, res.dbEPL_nf, 'k--', 'linew', 1.5);
% title([subject, ' | SFOAE | ', condition, ' (n = ', num2str(numOfTrials), ')'], 'FontSize', 14, 'FontWeight', 'bold')
% set(gca, 'XScale', 'log', 'FontSize', 14)
% xlim([.5, 16])
% xticks([.5, 1, 2, 4, 8, 16])
% xlabel('Frequency (kHz)','FontWeight','bold')
% ylabel('Amplitude (dB EPL)','FontWeight','bold')
% legend('SFOAE', 'NF')
% box off;
%% Calculate band-average SF
fmin = 0.5;
fmax = 16;
edges = 2 .^ linspace(log2(fmin), log2(fmax), 21);
bandEdges = edges(2:2:end-1);
centerFreqs = edges(3:2:end-2);
sfoae_w_spl = zeros(length(centerFreqs),1);
sfnf_w_spl = zeros(length(centerFreqs),1);
sfoae_full_spl = db(abs(oae_complex).*res.multiplier);
sfnf_full_spl = db(abs(noise_complex).*res.multiplier);
% resample / average to 9 center frequencies
for z = 1:length(centerFreqs)
    band = find( testfreq/1000 >= bandEdges(z) & testfreq/1000 < bandEdges(z+1));
    % Do some weighting by SNR
    % TO DO: NF from which SNR was calculated included median of 7 points
    % nearest the target frequency
    %EPL
    SNR_epl = sfoae_full_epl(band) - sfnf_full_epl(band);
    weight_epl = (10.^(SNR_epl./10)).^2;  
    sfoae_epl(z, 1) = mean(sfoae_full_epl(band));
    sfnf_epl(z,1) = mean(sfnf_full_epl(band));
    sfoae_w_epl(z,1) = sum(weight_epl.*sfoae_full_epl(band))/sum(weight_epl);
    sfnf_w_epl(z,1) = sum(weight_epl.*sfnf_full_epl(band))/sum(weight_epl);
    %SPL
    SNR_spl = sfoae_full_spl(band) - sfnf_full_spl(band);
    weight_spl = (10.^(SNR_spl./10)).^2;  
    sfoae_spl(z, 1) = mean(sfoae_full_spl(band));
    sfnf_spl(z,1) = mean(sfnf_full_spl(band));
    sfoae_w_spl(z,1) = sum(weight_spl.*sfoae_full_spl(band))/sum(weight_spl);
    sfnf_w_spl(z,1) = sum(weight_spl.*sfnf_full_spl(band))/sum(weight_spl);

end
%% Plot band-average SF - SPL
plot(centerFreqs, sfoae_w_spl, 'o', 'linew', 2, 'MarkerSize', 8, 'MarkerFaceColor', 'r', 'MarkerEdgeColor', 'r','HandleVisibility','off'); % band-average DP
plot(centerFreqs, sfnf_w_spl, 'x', 'linew', 4, 'MarkerSize', 8, 'MarkerFaceColor', 'k', 'MarkerEdgeColor', 'k','HandleVisibility','off'); % band-average noise floor
lowlim = min(sfnf_full_spl);
uplim = max(db(abs(oae_complex).*res.multiplier));
ylim([round(lowlim - 5,1), round(uplim + 5,1)])
%% Export:
% EPL
epl.f = testfreq/1000;
epl.oae = sfoae_full_epl; 
epl.nf = sfnf_full_epl; 
epl.centerFreq = centerFreqs;
epl.bandOAE = sfoae_w_epl;
epl.bandNF = sfnf_w_epl;
data.epl = epl; 
% SPL
spl.f = testfreq/1000;
spl.oae = db(abs(oae_complex).*res.multiplier);
spl.nf = db(abs(noise_complex).*res.multiplier);
spl.VtoSPL = res.multiplier;
spl.centerFreq = centerFreqs;
spl.bandOAE = sfoae_w_spl;
spl.bandNF = sfnf_w_spl;
data.spl = spl;
cd(outpath);
fname = [subject,'_SFOAEswept_',condition,'_',datafile(1:end-4),'_',calibfile(1:end-4)];
print(gcf,[fname,'_figure'],'-dpng','-r300');
save(fname,'data')
cd(cwd);
end