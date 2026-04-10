function WBMEMRanalysis(ROOTdir,datapath,outpath,subject,condition)% WBMEMR Analysis

% Author: Samantha Hauser modified code from Hari Bharadwaj
% Created: August 2023
% Last Updated: 23 September 2025 (FA)

%% Import data
cwd = pwd;
search_file = '*memr*.mat';
PRIVdir = strcat(ROOTdir,filesep,'Code Archive',filesep,'private');
cd(PRIVdir)
datafile = load_files(datapath,search_file,'data');
if isempty(datafile)
    return
end
%% Load MEMR template
% Analysis loop
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
    power = mean(abs(memr.MEM(memr.ind,:))); 
    deltapow = power - min(power); 
    subplot(1,3,3)
    %plot(memr.elicitor, mean(abs(memr.MEM(:, memr.ind)), 2)*5, 'ok-', 'linew', 2);
    plot(memr.elicitor, deltapow, '*k', 'linew', 1.5,'MarkerSize',8);
    xlabel('Elicitor Level (dB FPL)', 'FontSize', 14, 'FontWeight', 'bold');
    ylabel('\Delta Absorbed Power (dB)', 'FontSize', 14, 'FontWeight', 'bold');
    ymax = max(deltapow+.05); 
    ylim([0,ymax])
    set(gca, 'XScale', 'log', 'FontSize', 14)

    % %% Fitting:
    % if length(deltapow) > 4      % at least 4 points needed for exponential fit
    %     cor_fit = fit(memr.elicitor', deltapow','exp1');
    %     a = cor_fit.a;
    %     b = cor_fit.b;
    %     x_fit = memr.elicitor(1):memr.elicitor(end);
    %     y_fit = a*exp(b*x_fit);
    %     %Find x value on exponential that is 10% of the max
    %     % x = ln(y/a)/b
    %     tol = 0.10;
    %     y_norm = tol*max(y_fit);
    %     thresh = log(y_norm/a)/b;
    %     y_thresh = a*exp(b*thresh);
    % else
    %     thresh = nan;
    % end
    % hold on;
    % plot(x_fit,y_fit, 'k-', 'linew', 2);
    % plot(thresh,y_thresh,'ok','LineWidth',2,'MarkerSize',8,'MarkerFaceColor','r');
    % yline(y_thresh,'r--','LineWidth',2)
    % text(50,2*y_thresh,sprintf('Threshold:\n%.1f dB FPL',thresh));
    %% Fitting: SIGMOID and extended elicitor axis
    xdata = memr.elicitor(:);
    ydata = deltapow(:);

    % extended elicitor levels
    x_ext = (40:2:130)';   % wider + smoother    
    if numel(ydata) >= 4

        % 4-parameter sigmoid
        ft = fittype('y0 + L./(1+exp(-k*(x-x0)))', ...
                     'independent','x','dependent','y', ...
                     'coefficients', {'y0','L','k','x0'});

        % good start guesses
        y0_0 = min(ydata);
        L_0  = max(ydata) - min(ydata);
        k_0  = 0.15;
        x0_0 = median(xdata);

        opts = fitoptions(ft);
        opts.StartPoint = [y0_0, L_0, k_0, x0_0];
        opts.Lower      = [0,    0,   0,  min(xdata)];
        opts.Upper      = [Inf,  Inf, 2,  max(xdata)];

        sig_fit = fit(xdata, ydata, ft, opts);

        % evaluate sigmoid on extended elicitor range
        y_ext = sig_fit.y0 + sig_fit.L ./ (1 + exp(-sig_fit.k*(x_ext - sig_fit.x0)));

        % threshold at 10% dynamic range
        tol = 0.10;
        y_thresh = sig_fit.y0 + tol*sig_fit.L;

        thresh = sig_fit.x0 - (1/sig_fit.k) * ...
                 log( (sig_fit.L/(y_thresh - sig_fit.y0)) - 1 );

    else
        thresh = nan;
        y_thresh = nan;
        y_ext = nan(size(x_ext));
    end

    hold on
    plot(x_ext, y_ext, 'k-', 'LineWidth', 2)
    xlim([40 130])    
    plot(thresh, y_thresh, 'ok', 'LineWidth', 2, ...
         'MarkerSize', 8, 'MarkerFaceColor', 'r')
    yline(y_thresh,'r--','LineWidth',2)
    text(50,2*y_thresh,sprintf('Threshold:\n%.1f dB FPL',thresh))
    %% Export:
    memr.threshold = thresh;
    memr.deltapow = deltapow';
    cd(outpath);
    if stim.fc == 7000
        fname = [subject,'_MEMR_HP_',condition,'_',datafile(1:5)];
    else
        fname = [subject,'_MEMR_WB_',condition,'_',datafile(1:5)];
    end
    print(gcf,[fname,'_figure'],'-dpng','-r300');
    close(gcf);
    save(fname,'memr')
    cd(cwd);
    clear stim
    clear memr
end
end








% %% ABRpresto style resampled subaverage correlation threshold for MEMR
% function WBMEMRanalysis(ROOTdir,datapath,outpath,subject,condition)
% % WBMEMR Analysis + ABRpresto style Option A correlation threshold for MEMR
% 
% %% Import data
% cwd = pwd;
% search_file = '*memr*.mat';
% PRIVdir = strcat(ROOTdir,filesep,'Code Archive',filesep,'private');
% cd(PRIVdir)
% 
% datafile = load_files(datapath,search_file,'data');
% if isempty(datafile)
%     cd(cwd);
%     return
% end
% 
% if ischar(datafile)
%     files = cellstr(datafile);
% elseif isstring(datafile)
%     files = cellstr(datafile);
% else
%     files = datafile;
% end
% 
% %% Analysis loop
% numOfFiles = numel(files);
% 
% for i = 1:numOfFiles
% 
%     cd(datapath)
%     thisfile = files{i};
%     S = load(thisfile);
%     cd(cwd);
% 
%     if isfield(S,'x')
%         x = S.x;
%     else
%         warning('File %s does not contain variable x. Skipping.', thisfile);
%         continue
%     end
% 
%     stim = x.MemrData.stim;
%     memr = MEMRbyLevel(stim);
% 
%     %% Plot setup
%     figure_prop_name = {'PaperPositionMode', 'units', 'Position'};
%     figure_prop_val  = {'auto', 'inches', [1 1 8 5]};
%     figure;
%     set(gcf,figure_prop_name,figure_prop_val);
% 
%     if stim.fc == 7000
%         sgtitle([subject ' | MEMR - HP | ' condition], 'FontSize', 14, 'FontWeight', 'bold')
%     else
%         sgtitle([subject ' | MEMR - WB | ' condition ' (n = ' num2str(memr.trials) ')'], 'FontSize', 14)
%     end
% 
%     %% Subplot 1: MEM spectra by elicitor
%     subplot(1,3,1:2)
%     semilogx(memr.freq / 1e3, memr.MEM, 'linew', 2);
%     xlim([0.2, 8]);
%     xticks([0.25, 0.5, 1, 2, 4, 8])
%     legend(num2str(memr.elicitor'), 'FontSize', 10, 'NumColumns', 2, 'location', 'best');
%     xlabel('Frequency (kHz)', 'FontSize', 14, 'FontWeight', 'bold');
%     ylabel('Ear canal pressure (dB re: Baseline)', 'FontSize', 14, 'FontWeight', 'bold');
%     box off;
% 
%     %% Compute deltapow
%     power = mean(abs(memr.MEM(memr.ind,:)));
%     deltapow = power - min(power);
% 
%     %% Subplot 3: Option A correlation threshold if possible, otherwise your deltapow sigmoid
%     subplot(1,3,3)
% 
%     useCorr = isfield(memr,'MEM_trials') && ~isempty(memr.MEM_trials);
% 
%     if useCorr
%         R = 500;
%         levels = memr.elicitor(:);
%         nLevels = numel(levels);
% 
%         meanSim = nan(nLevels,1);
%         stdSim  = nan(nLevels,1);
%         allSims = cell(nLevels,1);
% 
%         for j = 1:nLevels
%             X = memr.MEM_trials(:,:,j);   % nFreq x nTrials
%             nT = size(X,2);
% 
%             if nT < 4
%                 allSims{j} = nan(R,1);
%                 continue
%             end
% 
%             sims = nan(R,1);
%             for r = 1:R
%                 idx = randperm(nT);
%                 A = idx(1:floor(nT/2));
%                 B = idx(floor(nT/2)+1:end);
% 
%                 avgA = mean(X(:,A),2);
%                 avgB = mean(X(:,B),2);
% 
%                 sims(r) = corr(avgA(memr.ind), avgB(memr.ind), 'Rows','complete');
%             end
% 
%             allSims{j} = sims;
%             meanSim(j) = mean(sims,'omitnan');
%             stdSim(j)  = std(sims,'omitnan');
%         end
% 
%         nLow = min(4, nLevels);
%         noiseSims = vertcat(allSims{1:nLow});
%         crit = mean(noiseSims,'omitnan') + 3*std(noiseSims,'omitnan');
% 
%         [thresh_corr, sig_fit, x_ext, y_ext] = fit_sigmoid_crossing(levels, meanSim, crit, 40, 130);
% 
%         memr.threshold_corr = thresh_corr;
%         memr.meanSim = meanSim(:)';
%         memr.stdSim  = stdSim(:)';
%         memr.crit = crit;
%         memr.sig_fit = sig_fit;
% 
%         plot(levels, meanSim, 'ok', 'LineWidth', 1.5, 'MarkerSize', 6);
%         hold on
%         plot(x_ext, y_ext, 'k-', 'LineWidth', 2);
%         yline(crit, 'r--', 'LineWidth', 2);
% 
%         xlim([40 130])
%         ylim([0 1])
%         set(gca, 'XScale', 'log', 'FontSize', 14)
% 
%         xlabel('Elicitor Level (dB FPL)', 'FontSize', 14, 'FontWeight', 'bold');
%         ylabel('Subavg corr', 'FontSize', 14, 'FontWeight', 'bold');
%         box off
% 
%         if isfinite(thresh_corr)
%             plot(thresh_corr, crit, 'ok', 'LineWidth', 2, 'MarkerSize', 8, 'MarkerFaceColor', 'r');
%             text(50, min(0.95, crit + 0.07), sprintf('Threshold:\n%.1f dB FPL', thresh_corr));
%         else
%             text(50, 0.9, 'Threshold: NaN', 'FontSize', 12, 'FontWeight', 'bold');
%         end
% 
%     else
%         warning('memr.MEM_trials not found. Plotting deltapow sigmoid threshold instead.');
% 
%         xdata = memr.elicitor(:);
%         ydata = deltapow(:);
% 
%         x_ext = (40:2:130)';
% 
%         if numel(ydata) >= 4
%             ft = fittype('y0 + L./(1+exp(-k*(x-x0)))', ...
%                 'independent','x','dependent','y', ...
%                 'coefficients', {'y0','L','k','x0'});
% 
%             y0_0 = min(ydata);
%             L_0  = max(ydata) - min(ydata);
%             k_0  = 0.15;
%             x0_0 = median(xdata);
% 
%             opts = fitoptions(ft);
%             opts.StartPoint = [y0_0, L_0, k_0, x0_0];
%             opts.Lower      = [0,    0,   0,  min(xdata)];
%             opts.Upper      = [Inf,  Inf, 2,  max(xdata)];
% 
%             sig_fit = fit(xdata, ydata, ft, opts);
% 
%             y_ext = sig_fit.y0 + sig_fit.L ./ (1 + exp(-sig_fit.k*(x_ext - sig_fit.x0)));
% 
%             tol = 0.10;
%             y_thresh = sig_fit.y0 + tol*sig_fit.L;
% 
%             thresh = sig_fit.x0 - (1/sig_fit.k) * log( (sig_fit.L/(y_thresh - sig_fit.y0)) - 1 );
%         else
%             thresh = nan;
%             y_thresh = nan;
%             y_ext = nan(size(x_ext));
%         end
% 
%         plot(memr.elicitor, deltapow, '*k', 'linew', 1.5,'MarkerSize',8);
%         hold on
%         plot(x_ext, y_ext, 'k-', 'LineWidth', 2)
%         xlim([40 130])
% 
%         if isfinite(thresh)
%             plot(thresh, y_thresh, 'ok', 'LineWidth', 2, 'MarkerSize', 8, 'MarkerFaceColor', 'r')
%             yline(y_thresh,'r--','LineWidth',2)
%             text(50,2*y_thresh,sprintf('Threshold:\n%.1f dB FPL',thresh))
%         end
% 
%         xlabel('Elicitor Level (dB FPL)', 'FontSize', 14, 'FontWeight', 'bold');
%         ylabel('\Delta Absorbed Power (dB)', 'FontSize', 14, 'FontWeight', 'bold');
%         set(gca, 'XScale', 'log', 'FontSize', 14)
%         box off;
% 
%         memr.threshold = thresh;
%         memr.deltapow = deltapow';
%     end
% 
%     %% Export
%     cd(outpath);
% 
%     base5 = thisfile;
%     if numel(base5) >= 5
%         base5 = base5(1:5);
%     end
% 
%     if stim.fc == 7000
%         fname = [subject,'_MEMR_HP_',condition,'_',base5];
%     else
%         fname = [subject,'_MEMR_WB_',condition,'_',base5];
%     end
% 
%     print(gcf,[fname,'_figure'],'-dpng','-r300');
%     save(fname,'memr')
% 
%     cd(cwd);
%     clear stim memr x S
% end
% 
% end
% 
% 
% function [thresh, sig_fit, x_ext, y_ext] = fit_sigmoid_crossing(xdata, ydata, ycrit, xmin, xmax)
% % Fit 4-parameter sigmoid and solve for x where sigmoid(x) = ycrit
% 
% xdata = xdata(:);
% ydata = ydata(:);
% 
% x_ext = (xmin:1:xmax)';
% thresh = nan;
% y_ext = nan(size(x_ext));
% sig_fit = [];
% 
% ok = isfinite(xdata) & isfinite(ydata);
% xdata = xdata(ok);
% ydata = ydata(ok);
% 
% if numel(ydata) < 4
%     return
% end
% 
% try
%     ft = fittype('y0 + L./(1+exp(-k*(x-x0)))', ...
%         'independent','x','dependent','y', ...
%         'coefficients', {'y0','L','k','x0'});
% 
%     y0_0 = min(ydata);
%     L_0  = max(ydata) - min(ydata);
%     if L_0 <= 0
%         return
%     end
%     k_0  = 0.15;
%     x0_0 = median(xdata);
% 
%     opts = fitoptions(ft);
%     opts.StartPoint = [y0_0, L_0, k_0, x0_0];
%     opts.Lower      = [-Inf, 0,   0,  min(xdata)];
%     opts.Upper      = [ Inf, Inf, 2,  max(xdata)];
% 
%     sig_fit = fit(xdata, ydata, ft, opts);
% 
%     y_ext = sig_fit.y0 + sig_fit.L ./ (1 + exp(-sig_fit.k*(x_ext - sig_fit.x0)));
% 
%     ymin = sig_fit.y0;
%     ymax = sig_fit.y0 + sig_fit.L;
% 
%     if ~(ycrit > ymin && ycrit < ymax)
%         thresh = nan;
%         return
%     end
% 
%     thresh = sig_fit.x0 - (1/sig_fit.k) * log( (sig_fit.L/(ycrit - sig_fit.y0)) - 1 );
% 
% catch
%     thresh = nan;
%     sig_fit = [];
%     y_ext = nan(size(x_ext));
% end
% end
