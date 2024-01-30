%% DPsummary data

% Load Data
cwd = pwd;
cd(outpath)
fname = ['*',subj,'_DPOAEswept_',condition,'*.mat'];
datafile = {dir(fname).name};
if length(datafile) > 1
    fprintf('More than 1 data file. Check this is correct file!\n');
end
load(datafile{1});
cd(cwd);
res = data.res;
spl = data.spl;
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
%% PLOTTING - EPL
colors = ["#0072BD"; "#EDB120"; "#7E2F8E"; "#77AC30"; "#A2142F"];
counter = 2*ChinIND-1;
figure(counter); hold on;
plot(f2, dpoae_full, 'Color', [.8, .8, .8], 'linew', 2, 'Color', colors(CondIND))
plot(f2, dpnf_full, '--', 'linew', 2, 'Color', colors(CondIND),'HandleVisibility','off')
%plot(centerFreqs, dpoae_w, '*', 'linew', 2, 'MarkerSize', 5, 'MarkerFaceColor', colors(CondIND), 'MarkerEdgeColor', colors(CondIND))
set(gca, 'XScale', 'log', 'FontSize', 14)
xlim([.5, 16])
if CondIND > 1
    lim_temp = max(dpoae_full);
    if lim_temp > uplim
        uplim = lim_temp;
    end
else
    uplim = max(dpoae_full);
end
ylim([-50, uplim + 5])
xticks([.5, 1, 2, 4, 8, 16])
ylabel('Amplitude (dB EPL)', 'FontWeight', 'bold')
xlabel('F2 Frequency (kHz)', 'FontWeight', 'bold')
legend(Conds2Run)
title(sprintf('DPOAE | %s',Chins2Run{ChinIND}), 'FontSize', 16)
%% PLOTTING - SPL
figure(counter+1); hold on;
plot(spl.f, db(abs(spl.oae).*spl.VtoSPL), 'linew', 2, 'Color', colors(CondIND));
plot(spl.f, db(abs(spl.noise).*spl.VtoSPL), '--', 'linew', 2, 'Color', colors(CondIND),'HandleVisibility','off');
set(gca, 'XScale', 'log', 'FontSize', 14)
xlim([.5, 16])
if CondIND > 1
    lim_temp = max(db(abs(spl.oae).*spl.VtoSPL));
    if lim_temp > uplim
        uplim = lim_temp;
    end
else
    uplim = max(db(abs(spl.oae).*spl.VtoSPL));
end
ylim([-50, uplim + 5])
xticks([.5, 1, 2, 4, 8, 16])
ylabel('Amplitude (dB SPL)', 'FontWeight', 'bold')
xlabel('F_2 Frequency (kHz)', 'FontWeight', 'bold')
legend(Conds2Run)
title(sprintf('DPOAE | %s',Chins2Run{ChinIND}), 'FontSize', 16)
%% Export
outpath = strcat(OUTdir,filesep,'Analysis',filesep,EXPname,filesep,Chins2Run{ChinIND});
cd(outpath);
filename_EPL = [subj,'_DPOAEswept_Summary_EPL'];
print(figure(counter),[filename_EPL,'_figure'],'-dpng','-r300');
filename_SPL = [subj,'_DPOAEswept_Summary_SPL'];
print(figure(counter+1),[filename_SPL,'_figure'],'-dpng','-r300');
cd(cwd);