%% TEsummary data

% Load Data
cwd = pwd;
cd(outpath)
fname = ['*',subj,'_TEOAE_',condition,'_','*.mat'];
datafile = {dir(fname).name};
if length(datafile) > 1
    fprintf('More than 1 data file. Check this is correct file!\n');
    datafile = {uigetfile(fname)};
end
if isempty(datafile)
    fprintf('No file found. Please analyze raw data first.\n');
end
load(datafile{1});
cd(cwd);
spl = data.spl;
teoae_full = spl.Resp;
tenf_full = spl.NoiseFloor;
spl.freq = spl.freq/1000;
%% PLOTTING - SPL
te_f_spl{ChinIND,CondIND} = spl.freq';
te_amp_spl{ChinIND,CondIND} = abs(spl.oae);
te_nf_spl{ChinIND,CondIND} = abs(spl.noise);
%colors = ["#0072BD"; "#EDB120"; "#7E2F8E"; "#77AC30"; "#A2142F"];
colors = [0,114,189; 237,177,32; 126,47,142; 119,172,48; 162,20,47]/255;
counter = 2*ChinIND-1;
figure(counter); hold on;
plot(spl.freq, db(abs(spl.oae)), 'linew', 2, 'Color', colors(CondIND,:));
plot(spl.freq, db(abs(spl.noise)), '--', 'linew', 2, 'Color', [colors(CondIND,:),0.5],'HandleVisibility','off');
set(gca, 'XScale', 'log', 'FontSize', 14)
xlim([.5, 16])
if CondIND > 1
    upperlim_temp = max(db(abs(spl.oae)));
    lowerlim_temp = min(db(abs(spl.noise)));
    if upperlim_temp > uplim
        uplim = upperlim_temp;
    end
    if lowerlim_temp < lowlim
        lowlim = lowerlim_temp;
    end
else
    lowlim = min(db(abs(spl.noise)));
    uplim = max(db(abs(spl.oae)));
end
ylim([lowlim - 5, uplim + 5])
xticks([.5, 1, 2, 4, 8, 16])
ylabel('Amplitude (dB SPL)', 'FontWeight', 'bold')
xlabel('Frequency (kHz)', 'FontWeight', 'bold')
legend(Conds2Run,'Location','southoutside','Orientation','horizontal','FontSize',8)
legend boxoff  
title(sprintf('TEOAE | %s',Chins2Run{ChinIND}), 'FontSize', 16)
% Export
outpath = strcat(OUTdir,filesep,'Analysis',filesep,EXPname,filesep,Chins2Run{ChinIND});
cd(outpath);
filename_SPL = [subj,'_TEOAE_Summary_SPL'];
print(figure(counter),[filename_SPL,'_figure'],'-dpng','-r300');
cd(cwd);
%% PLOTTING - AVERAGE SPL
counter_avg = 2*length(Chins2Run);
figure(counter_avg+2); hold on;
%plot(spl.f, db(abs(spl.oae)), '-', 'linew', 2, 'Color', [colors(CondIND,:),0.25],'HandleVisibility','off');
%plot(spl.f, db(abs(spl.noise)), '--', 'linew', 2, 'Color', [colors(CondIND,:),0.25],'HandleVisibility','off');
set(gca, 'XScale', 'log', 'FontSize', 14)
xlim([.5, 16]); xticks([.5, 1, 2, 4, 8, 16])
ylabel('Amplitude (dB SPL)', 'FontWeight', 'bold')
xlabel('Frequency (kHz)', 'FontWeight', 'bold')
title(sprintf('TEOAE | Average (n = %.0f)',length(Chins2Run)), 'FontSize', 16); hold off;
if ChinIND == length(Chins2Run) && CondIND == length(Conds2Run)
    for j = 1:length(Conds2Run)
        avg_f_spl{1,j} = mean(cat(1, te_f_spl{:, j}));
        avg_te_spl{1,j} = mean(cat(1, te_amp_spl{:, j}));
        avg_nf_spl{1,j} = mean(cat(1, te_nf_spl{:, j}));
        figure(2*length(Chins2Run)+2); hold on;
        plot(avg_f_spl{j}, db(avg_te_spl{j}),'-', 'linew', 2, 'Color', colors(j,:))
        plot(avg_f_spl{j}, db(avg_nf_spl{j}),'--', 'linew', 2, 'Color', colors(j,:),'HandleVisibility','off')
        uplim = db(max(cellfun(@max, avg_te_spl), [], 'all'));
        lowlim = db(max(cellfun(@min, avg_nf_spl), [], 'all'));
        ylim([lowlim - 5, uplim + 5])
        legend(Conds2Run,'Location','southoutside','Orientation','horizontal','FontSize',8)
        legend boxoff
        hold off;
    end
    %% Export
    outpath = strcat(OUTdir,filesep,'Analysis',filesep,EXPname);
    cd(outpath);
    filename = 'TEOAE_Average_SPL';
    print(counter_avg+2,[filename,'_figure'],'-dpng','-r300');
    cd(cwd);
end