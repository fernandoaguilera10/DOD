%% TEsummary data

% Load Data
cwd = pwd;
cd(outpath)
fname = ['*',subj,'_TEOAE_',condition,'*.mat'];
datafile = {dir(fname).name};
if length(datafile) > 1
    fprintf('More than 1 data file. Check this is correct file!\n');
end
load(datafile{1});
cd(cwd);
spl = data.spl;
teoae_full = spl.Resp;
tenf_full = spl.NoiseFloor;
spl.freq = spl.freq/1000;
%% PLOTTING - SPL
colors = ["#0072BD"; "#EDB120"; "#7E2F8E"; "#77AC30"; "#A2142F"];
figure(1); hold on;
plot(spl.freq, db(abs(spl.oae)), 'linew', 2, 'Color', colors(CondIND));
plot(spl.freq, db(abs(spl.noise)), '--', 'linew', 2, 'Color', colors(CondIND),'HandleVisibility','off');
set(gca, 'XScale', 'log', 'FontSize', 14)
xlim([.5, 16])
if CondIND > 1
    lim_temp = max(db(abs(spl.oae)));
    if lim_temp > uplim
        uplim = lim_temp;
    end
else
    uplim = max(db(abs(spl.oae)));
end
ylim([-50, uplim + 5])
xticks([.5, 1, 2, 4, 8, 16])
ylabel('Amplitude (dB SPL)', 'FontWeight', 'bold')
xlabel('Frequency (kHz)', 'FontWeight', 'bold')
legend(Conds2Run)
title('TEOAE', 'FontSize', 16)
%% Export
outpath = strcat(OUTdir,filesep,'Analysis',filesep,EXPname,filesep,Chins2Run{ChinIND});
cd(outpath);
filename_SPL = [subj,'_TEOAE_Summary_SPL'];
print(figure(1),[filename_SPL,'_figure'],'-dpng','-r300');
cd(cwd);