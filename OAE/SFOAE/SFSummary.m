%% SF summary data -- CHIN
% Load Data
cwd = pwd;
cd(outpath)
fname = ['*',subj,'_SFOAEswept_',condition,'*.mat'];
datafile = {dir(fname).name};
if length(datafile) > 1
    fprintf('More than 1 data file. Check this is correct file!\n');
end
load(datafile{1});
cd(cwd);
res = data.res;
spl = data.spl;
sfoae_full = res.dbEPL_sf;
sfnf_full = res.dbEPL_nf;
f2 = res.f/1000;
% SEt params
fmin = 0.5;
fmax = 16;
edges = 2 .^ linspace(log2(fmin), log2(fmax), 21);
bandEdges = edges(2:2:end-1);
centerFreqs = edges(3:2:end-2);
sfoae = zeros(length(centerFreqs),1);
sfnf = zeros(length(centerFreqs),1);
sfoae_w = zeros(length(centerFreqs),1);
sfnf_w = zeros(length(centerFreqs),1);
% resample / average to 9 center frequencies
for z = 1:length(centerFreqs)
    band = find( f2 >= bandEdges(z) & f2 < bandEdges(z+1));
    % Do some weighting by SNR
    % TO DO: NF from which SNR was calculated included median of 7 points
    % nearest the target frequency.
    SNR = sfoae_full(band) - sfnf_full(band);
    weight = (10.^(SNR./10)).^2;
    sfoae(z, 1) = mean(sfoae_full(band));
    sfnf(z,1) = mean(sfnf_full(band));
    sfoae_w(z,1) = sum(weight.*sfoae_full(band))/sum(weight);
    sfnf_w(z,1) = sum(weight.*sfnf_full(band))/sum(weight); 
end
%% PLOTTING - EPL
colors = ["#0072BD"; "#EDB120"; "#7E2F8E"; "#77AC30"; "#A2142F"];
figure(1); hold on;
plot(f2, sfoae_full, 'Color', [.8, .8, .8], 'linew', 2, 'Color', colors(CondIND))
plot(f2, sfnf_full, '--', 'linew', 2, 'Color', colors(CondIND),'HandleVisibility','off')
%plot(centerFreqs, sfoae_w, '*', 'linew', 2, 'MarkerSize', 5, 'MarkerFaceColor', colors(CondIND), 'MarkerEdgeColor', colors(CondIND))
set(gca, 'XScale', 'log', 'FontSize', 14)
xlim([.5, 16])
if CondIND > 1
    lim_temp = max(sfoae_full);
    if lim_temp > uplim
        uplim = lim_temp;
    end
else
    uplim = max(sfoae_full);
end
ylim([-50, uplim + 5])
xticks([.5, 1, 2, 4, 8, 16])
ylabel('Amplitude (dB EPL)', 'FontWeight', 'bold')
xlabel('Frequency (kHz)', 'FontWeight', 'bold')
legend(Conds2Run)
title('SFOAE', 'FontSize', 16);
%% PLOTTING - SPL
figure(2); hold on;
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
xlabel('Frequency (kHz)', 'FontWeight', 'bold')
legend(Conds2Run)
title('SFOAE', 'FontSize', 16)
%% Export
outpath = strcat(OUTdir,filesep,'Analysis',filesep,EXPname,filesep,Chins2Run{ChinIND});
cd(outpath);
filename_EPL = [subj,'_SFOAEswept_Summary_EPL'];
print(figure(1),[filename_EPL,'_figure'],'-dpng','-r300');
filename_SPL = [subj,'_SFOAEswept_Summary_SPL'];
print(figure(2),[filename_SPL,'_figure'],'-dpng','-r300');
cd(cwd);