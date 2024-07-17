function WBMEMRanalysis(datapath,outpath,subject,condition)% WBMEMR Analysis

% DPOAE swept Analysis
% Author: Samantha Hauser modified code from Hari Bharadwaj
% Created: August 2023
% Last Updated: August 23, 2023
% Purpose:
% Helpful info:

%% Import data
search_file = '*memr*.mat';
datafile = load_files(datapath,search_file);
if isempty(datafile)
    return
end
cwd = pwd;
numOfFiles = size(datafile,1);
%% setting colors
% Colorblind friendly continuous hue/sat changes
cols = [103,0,31;
    178,24,43;
    214,96,77;
    244,165,130;
    253,219,199;
    247, 247, 247;
    209,229,240;
    146,197,222;
    67,147,195;
    33,102,172;
    5,48,97];
cols = cols(end:-1:1, :)/255;
%% Analysis loop
for i = 1:numOfFiles
    cd(datapath)
    load(datafile);
    cd(cwd);
    stim = x.MemrData.stim; 
    memr = MEMRbyLevel(stim);
    figure_prop_name = {'PaperPositionMode', 'units', 'Position'};
    figure_prop_val = {'auto', 'inches', [1 1 8 5]}; % xcor, ycor, xwid, yheight
    figure;
    set(gcf,figure_prop_name,figure_prop_val);
    if stim.fc == 7000
        sgtitle([subject ' | MEMR - HP | ' condition], 'FontSize', 14, 'FontWeight', 'bold')
    else
        sgtitle([subject ' | MEMR - WB | ' condition ' (n = ' num2str(memr.trials) ')'], 'FontSize', 14)
    end
    subplot(1,3,1:2)
    semilogx(memr.freq / 1e3, memr.MEM, 'linew', 2);
    xlim([0.2, 8]);
    xticks([0.25, 0.5, 1, 2, 4, 8])
    %axes('ColorOrder',cols);
    %set(gca, 'XTick', ticks, 'XTickLabel', num2str(ticks'), 'FontSize', 14);
    legend(num2str(memr.elicitor'), 'FontSize', 10, 'NumColumns', 2, 'location', 'best');
    xlabel('Frequency (kHz)', 'FontSize', 14, 'FontWeight', 'bold');
    ylabel('Ear canal pressure (dB re: Baseline)', 'FontSize', 14, 'FontWeight', 'bold');
    box off;
    power = mean(abs(memr.MEM(:, memr.ind)), 2); 
    deltapow = power - min(power); 
    subplot(1,3,3)
    %plot(memr.elicitor, mean(abs(memr.MEM(:, memr.ind)), 2)*5, 'ok-', 'linew', 2);
    plot(memr.elicitor, deltapow, 'ok-', 'linew', 2);
    xlabel('Elicitor Level (dB FPL)', 'FontSize', 14, 'FontWeight', 'bold');
    ylabel('\Delta Absorbed Power (dB)', 'FontSize', 14, 'FontWeight', 'bold');
    ymax = max(deltapow+.05); 
    ylim([0,ymax])
    set(gca, 'XScale', 'log', 'FontSize', 14)
    memr.threshold = interp1(deltapow, memr.elicitor, 0.1);
    memr.deltapow = deltapow;
    %% Export:
    cd(outpath);
    if stim.fc == 7000
        fname = [subject,'_MEMR_HP_',condition,'_',datafile(1:5)];
    else
        fname = [subject,'_MEMR_WB_',condition,'_',datafile(1:5)];
    end
    print(gcf,[fname,'_figure'],'-dpng','-r300');
    save(fname,'memr')
    cd(cwd);
    clear stim
    clear memr
end
end


