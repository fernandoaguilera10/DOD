%% WBMEMRsummary
% Load Data
cwd = pwd;
cd(outpath)
fname = ['*',subj,'_MEMR_WB_',condition,'*.mat'];
datafile = {dir(fname).name};
if length(datafile) > 1
    fprintf('More than 1 data file. Check this is correct file!\n');
    datafile = {uigetfile(fname)};
end
load(datafile{1});
cd(cwd);
elicitor{ChinIND,CondIND} = res.elicitor;
deltapow{ChinIND,CondIND} = res.deltapow';
%% Plot individual subjects
%colors = ["#0072BD"; "#EDB120"; "#7E2F8E"; "#77AC30"; "#A2142F"];
colors = [0,114,189; 237,177,32; 126,47,142; 119,172,48; 162,20,47]/255;
shapes = ["*";"^";"v";"diamond"];
figure(ChinIND); hold on;
plot(res.elicitor, res.deltapow,'Marker',shapes(CondIND,:),'LineStyle','-','linew', 2, 'Color', [colors(CondIND,:),1], 'MarkerFaceColor', colors(CondIND,:));
if CondIND > 1
    lim_temp = max(res.deltapow);
    if lim_temp > uplim
        uplim = lim_temp;
    end
else
    uplim = max(res.deltapow);
end
ylim([0, uplim + 0.05]);
xlim([50, 105]);
xlabel('Elicitor Level (dB FPL)', 'FontWeight', 'bold');
ylabel('\Delta Absorbed Power (dB)','FontWeight', 'bold');
set(gca, 'XScale', 'log', 'FontSize', 14)
legend(Conds2Run,'Location','southoutside','Orientation','horizontal','FontSize',8)
legend boxoff
title(sprintf('WBMEMR | %s',Chins2Run{ChinIND}), 'FontSize', 16); hold off;
outpath = strcat(OUTdir,filesep,'Analysis',filesep,EXPname,filesep,Chins2Run{ChinIND});
cd(outpath);
filename = [subj,'_WBMEMR_Summary'];
print(figure(ChinIND),[filename,'_figure'],'-dpng','-r300');
cd(cwd);

% Plot average
figure(length(Chins2Run)+1); hold on;
%plot(res.elicitor, res.deltapow,'Marker',shapes(CondIND,:),'LineStyle','-','linew', 2, 'Color', [colors(CondIND,:),0.25], 'MarkerFaceColor', colors(CondIND,:),'MarkerFaceAlpha',0.25,'MarkerEdgeAlpha',0.25);
%plot(res.elicitor, res.deltapow,'LineStyle','-','linew', 2, 'Color', [colors(CondIND,:),0.25],'HandleVisibility','off');
set(gca, 'XScale', 'log', 'FontSize', 14)
xlabel('Elicitor Level (dB FPL)', 'FontWeight', 'bold');
ylabel('\Delta Absorbed Power (dB)','FontWeight', 'bold');
title(sprintf('WBMEMR | Average (n = %.0f)',length(Chins2Run)), 'FontSize', 16); hold off;
if ChinIND == length(Chins2Run) && CondIND == length(Conds2Run)
    for j = 1:length(Conds2Run)
        avg_elicitor{1,j} = mean(cat(1, elicitor{:, j}));
        avg_deltapow{1,j} = mean(cat(1, deltapow{:, j}));
        figure(length(Chins2Run)+1); hold on;
        plot(avg_elicitor{j}, avg_deltapow{j},'Marker',shapes(j,:),'LineStyle','-','linew', 2, 'Color', [colors(j,:),1],'MarkerFaceColor', colors(j,:))
        uplim = max(cellfun(@max, avg_deltapow), [], 'all');
        ylim([0, uplim + 0.05]);
        xlim([50, 105]); 
        legend(Conds2Run,'Location','southoutside','Orientation','horizontal','FontSize',8)
        legend boxoff
        hold off;
    end
    %% Export
    outpath = strcat(OUTdir,filesep,'Analysis',filesep,EXPname);
    cd(outpath);
    filename = 'WBMEMR_Average';
    print(figure(length(Chins2Run)+1),[filename,'_figure'],'-dpng','-r300');
    cd(cwd);
end