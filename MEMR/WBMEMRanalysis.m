function WBMEMRanalysis(ROOTdir,datapath,outpath,subject,condition)% WBMEMR Analysis

% Author: Samantha Hauser modified code from Hari Bharadwaj
% Created: August 2023
% Last Updated: 23 September 2025 (FA)

%% Import data
cwd = pwd;
search_file = '*memr*.mat';
PRIVdir = strcat(ROOTdir,filesep,'Code Archive',filesep,'private');
cd(PRIVdir)
datafile = load_files(datapath,search_file);
if isempty(datafile)
    return
end
%% Load MEMR template

%% Analysis loop
numOfFiles = size(datafile,1);
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
    legend(num2str(memr.elicitor'), 'FontSize', 10, 'NumColumns', 2, 'location', 'best');
    xlabel('Frequency (kHz)', 'FontSize', 14, 'FontWeight', 'bold');
    ylabel('Ear canal pressure (dB re: Baseline)', 'FontSize', 14, 'FontWeight', 'bold');
    box off;
    power = mean(abs(memr.MEM(:, memr.ind)), 2); 
    deltapow = power - min(power); 
    subplot(1,3,3)
    %plot(memr.elicitor, mean(abs(memr.MEM(:, memr.ind)), 2)*5, 'ok-', 'linew', 2);
    plot(memr.elicitor, deltapow, '*k', 'linew', 1.5,'MarkerSize',8);
    xlabel('Elicitor Level (dB FPL)', 'FontSize', 14, 'FontWeight', 'bold');
    ylabel('\Delta Absorbed Power (dB)', 'FontSize', 14, 'FontWeight', 'bold');
    ymax = max(deltapow+.05); 
    ylim([0,ymax])
    set(gca, 'XScale', 'log', 'FontSize', 14)

    %% Fitting:
    if length(deltapow) > 4      % at least 4 points needed for exponential fit
        cor_fit = fit(memr.elicitor', deltapow,'exp1');
        a = cor_fit.a;
        b = cor_fit.b;
        x_fit = memr.elicitor(1):memr.elicitor(end);
        y_fit = a*exp(b*x_fit);
        %Find x value on exponential that is 10% of the max
        % x = ln(y/a)/b
        tol = 0.10;
        y_norm = tol*max(y_fit);
        thresh = log(y_norm/a)/b;
        y_thresh = a*exp(b*thresh);
    else
        thresh = nan;
    end
    hold on;
    plot(x_fit,y_fit, 'k-', 'linew', 2);
    plot(thresh,y_thresh,'ok','LineWidth',2,'MarkerSize',8,'MarkerFaceColor','r');
    yline(y_thresh,'r--','LineWidth',2)
    text(50,2*y_thresh,sprintf('Threshold:\n%.1f dB FPL',thresh));
    %% Export:
    memr.threshold = thresh;
    memr.deltapow = deltapow;
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


