%% TEsummary data

% Load Data
cwd = pwd;
cd(outpath)
fname = ['*',subj,'_MEMR_WB_',condition,'*.mat'];
datafile = {dir(fname).name};
if length(datafile) > 1
    fprintf('More than 1 data file. Check this is correct file!\n');
    checkDIR = {uigetfile(fname)};
    datafile = checkDIR; 
end
load(datafile{1});
cd(cwd);
%% PLOTTING - SPL
%colors = ["#0072BD"; "#EDB120"; "#7E2F8E"; "#77AC30"; "#A2142F"];
colors = [0,114,189; 237,177,32; 126,47,142; 119,172,48; 162,20,47]/255;
counter = 2*ChinIND-1;
figure(counter); hold on;
plot(res.elicitor, res.deltapow, 'o-','linew', 2, 'Color', colors(CondIND,:));
set(gca, 'XScale', 'log', 'FontSize', 14)
if CondIND > 1
    lim_temp = max(res.deltapow);
    if lim_temp > uplim
        uplim = lim_temp;
    end
else
    uplim = max(res.deltapow);
end
ylim([0, uplim + 0.05])
xlabel('Elicitor Level (dB FPL)', 'FontWeight', 'bold');
ylabel('\Delta Absorbed Power (dB)','FontWeight', 'bold');
set(gca, 'XScale', 'log', 'FontSize', 14)
legend(Conds2Run,'Location','southoutside','Orientation','horizontal','FontSize',8)
legend boxoff  
title(sprintf('WBMEMR | %s',Chins2Run{ChinIND}), 'FontSize', 16)
%% Export
outpath = strcat(OUTdir,filesep,'Analysis',filesep,EXPname,filesep,Chins2Run{ChinIND});
cd(outpath);
filename = [subj,'_WBMEMR_Summary'];
print(figure(counter),[filename,'_figure'],'-dpng','-r300');
cd(cwd);