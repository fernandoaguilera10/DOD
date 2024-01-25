%% SF summary data -- CHIN
% Load Data
cwd = pwd;
cd(datapath)
load(datafile{1});
cd(cwd);
dpoae_full = res.dbEPL_sf;
dpnf_full = res.dbEPL_nf;
f2 = res.f/1000;
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
figure;
hold on;
semilogx(f2, dpoae_full, 'Color', [.8, .8, .8], 'linew', 2)
semilogx(f2, dpnf_full, '--', 'linew', 1.5, 'Color', [.8, .8, .8])
semilogx(centerFreqs, dpoae_w, 'o', 'linew', 4, 'MarkerSize', 10, 'MarkerFaceColor', '#4575b4', 'MarkerEdgeColor', '#4575b4')
set(gca, 'XScale', 'log', 'FontSize', 14)
xlim([.5, 16])
ylim([-50, 50])
xticks([.5, 1, 2, 4, 8, 16])
ylabel('Amplitude (dB EPL)', 'FontWeight', 'bold')
xlabel('Frequency (kHz)', 'FontWeight', 'bold')
title('SFOAE', 'FontSize', 16)