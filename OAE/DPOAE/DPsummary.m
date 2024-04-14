%% DPsummary
% Load Data
cwd = pwd;
if exist(outpath,"dir")
    cd(outpath)
    fname = ['*',subj,'_DPOAEswept_',condition,'*.mat'];
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
    res = data.res;
    spl = data.spl;
    dpoae_full = res.dbEPL_dp;
    dpnf_full = res.dbEPL_nf;
    f2 = res.f.f2/1000;
    %% PLOTTING - EPL
    dp_f2{ChinIND,CondIND} = f2;
    dp_amp_epl{ChinIND,CondIND} = dpoae_full';
    dp_nf_epl{ChinIND,CondIND} = dpnf_full';
    %colors = ["#0072BD"; "#EDB120"; "#7E2F8E"; "#77AC30"; "#A2142F"; "#FF33FF"];
    colors = [0,114,189; 237,177,32; 126,47,142; 119,172,48; 162,20,47; 255,51,255]/255;
    shapes = ["x";"^";"v";"diamond";"o";"*"];
    counter = 2*ChinIND-1;
    figure(counter); hold on;
    plot(f2, dpoae_full,'-', 'linew', 2, 'Color', colors(CondIND,:))
    plot(f2, dpnf_full, '--', 'linew', 2, 'Color', [colors(CondIND,:),0.5],'HandleVisibility','off')
    %plot(centerFreqs, dpoae_w, '*', 'linew', 2, 'MarkerSize', 5, 'MarkerFaceColor', colors(CondIND), 'MarkerEdgeColor', colors(CondIND))
    set(gca, 'XScale', 'log', 'FontSize', 14)
    xlim([.5, 16])
    if CondIND > 1
        upperlim_temp = max(dpoae_full);
        lowerlim_temp = min(dpnf_full);
        if upperlim_temp > uplim
            uplim = upperlim_temp;
        end
        if lowerlim_temp < lowlim
            lowlim = lowerlim_temp;
        end
    else
        lowlim = min(dpnf_full);
        uplim = max(dpoae_full);
    end
    ylim([lowlim - 5, uplim + 5])
    xticks([.5, 1, 2, 4, 8, 16])
    ylabel('Amplitude (dB EPL)', 'FontWeight', 'bold')
    xlabel('F2 Frequency (kHz)', 'FontWeight', 'bold')
    legend(Conds2Run,'Location','southoutside','Orientation','horizontal','FontSize',8)
    legend boxoff
    title(sprintf('DPOAE | %s',Chins2Run{ChinIND}), 'FontSize', 16)
    %% PLOTTING - SPL
    dp_f_spl{ChinIND,CondIND} = spl.f;
    dp_amp_spl{ChinIND,CondIND} = abs(spl.oae)';
    dp_nf_spl{ChinIND,CondIND} = abs(spl.noise)';
    figure(counter+1); hold on;
    plot(spl.f, db(abs(spl.oae).*spl.VtoSPL), '-', 'linew', 2, 'Color', colors(CondIND,:));
    plot(spl.f, db(abs(spl.noise).*spl.VtoSPL), '--', 'linew', 2, 'Color', [colors(CondIND,:),0.5],'HandleVisibility','off');
    set(gca, 'XScale', 'log', 'FontSize', 14)
    xlim([.5, 16])
    if CondIND > 1
        upperlim_temp = max(db(abs(spl.oae).*spl.VtoSPL));
        lowerlim_temp = min(db(abs(spl.noise).*spl.VtoSPL));
        if upperlim_temp > uplim
            uplim = upperlim_temp;
        end
        if lowerlim_temp < lowlim
            lowlim = lowerlim_temp;
        end
    else
        lowlim = min(db(abs(spl.noise).*spl.VtoSPL));
        uplim = max(db(abs(spl.oae).*spl.VtoSPL));
    end
    ylim([lowlim - 5, uplim + 5])
    xticks([.5, 1, 2, 4, 8, 16])
    ylabel('Amplitude (dB SPL)', 'FontWeight', 'bold')
    xlabel('F_2 Frequency (kHz)', 'FontWeight', 'bold')
    legend(Conds2Run,'Location','southoutside','Orientation','horizontal','FontSize',8)
    legend boxoff
    title(sprintf('DPOAE | %s',Chins2Run{ChinIND}), 'FontSize', 16)
    % Export
    outpath = strcat(OUTdir,filesep,'Analysis',filesep,EXPname,filesep,Chins2Run{ChinIND});
    cd(outpath);
    filename_EPL = [subj,'_DPOAEswept_Summary_EPL'];
    print(figure(counter),[filename_EPL,'_figure'],'-dpng','-r300');
    filename_SPL = [subj,'_DPOAEswept_Summary_SPL'];
    print(figure(counter+1),[filename_SPL,'_figure'],'-dpng','-r300');
    cd(cwd);
    %% PLOTTING - AVERAGE EPL
    counter_avg = 2*length(Chins2Run);
    figure(counter_avg+1); hold on;
    %plot(f2, dpoae_full, '-', 'linew', 2, 'Color', [colors(CondIND,:),0.25],'HandleVisibility','off');
    %plot(f2, dpnf_full, '--', 'linew', 2, 'Color', [colors(CondIND,:),0.25],'HandleVisibility','off');
    set(gca, 'XScale', 'log', 'FontSize', 14)
    xlim([.5, 16]); xticks([.5, 1, 2, 4, 8, 16])
    ylabel('Amplitude (dB EPL)', 'FontWeight', 'bold')
    xlabel('F_2 Frequency (kHz)', 'FontWeight', 'bold')
    title(sprintf('DPOAE | Average (n = %.0f)',length(Chins2Run)), 'FontSize', 16); hold off;
    legend_string = {};
    if ChinIND == length(Chins2Run) && CondIND == length(Conds2Run)
        for j = 1:length(Conds2Run)
            idx = cellfun(@isempty,dp_amp_epl);
            idx2 = find(sum(~idx) == 1);
            if j == idx2
                avg_f_epl{1,j} = dp_f2{:, j};
                avg_dp_epl{1,j} = dp_amp_epl{:, j};
                avg_nf_epl{1,j} = dp_nf_epl{:, j};
            else
                avg_f_epl{1,j} = mean(cat(1, dp_f2{:, j}));
                avg_dp_epl{1,j} = mean(cat(1, dp_amp_epl{:, j}));
                avg_nf_epl{1,j} = mean(cat(1, dp_nf_epl{:, j}));
            end
            figure(2*length(Chins2Run)+1); hold on;
            plot(avg_f_epl{j}, avg_dp_epl{j},'-', 'linew', 2, 'Color', colors(j,:))
            plot(avg_f_epl{j}, avg_nf_epl{j},'--', 'linew', 2, 'Color', colors(j,:),'HandleVisibility','off')
            uplim = max(cellfun(@max, avg_dp_epl), [], 'all');
            lowlim = max(cellfun(@min, avg_nf_epl), [], 'all');
            ylim([lowlim - 5, uplim + 5])
            legend_string = [legend_string; sprintf('%s (n = %d)',cell2mat(Conds2Run(j)),length(Chins2Run)-sum(idx(:,j)))];
            legend(legend_string,'Location','southoutside','Orientation','horizontal','FontSize',8)
            legend boxoff
            hold off;
        end
        %% Export
        outpath = strcat(OUTdir,filesep,'Analysis',filesep,EXPname);
        cd(outpath);
        filename = 'DPOAEswept_Average_EPL';
        print(counter_avg+1,[filename,'_figure'],'-dpng','-r300');
        cd(cwd);
    end
    %% PLOTTING - AVERAGE SPL
    counter_avg = 2*length(Chins2Run);
    figure(counter_avg+2); hold on;
    %plot(spl.f, db(abs(spl.oae).*spl.VtoSPL), '-', 'linew', 2, 'Color', [colors(CondIND,:),0.25],'HandleVisibility','off');
    %plot(spl.f, db(abs(spl.noise).*spl.VtoSPL), '--', 'linew', 2, 'Color', [colors(CondIND,:),0.25],'HandleVisibility','off');
    set(gca, 'XScale', 'log', 'FontSize', 14)
    xlim([.5, 16]); xticks([.5, 1, 2, 4, 8, 16])
    ylabel('Amplitude (dB SPL)', 'FontWeight', 'bold')
    xlabel('F_2 Frequency (kHz)', 'FontWeight', 'bold')
    title(sprintf('DPOAE | Average (n = %.0f)',length(Chins2Run)), 'FontSize', 16); hold off;
    legend_string = {};
     if ChinIND == length(Chins2Run) && CondIND == length(Conds2Run)
        for j = 1:length(Conds2Run)
            idx = cellfun(@isempty,dp_amp_spl);
            idx2 = find(sum(~idx) == 1);
            if j == idx2
                avg_f_spl{1,j} = dp_f_spl{:, j};
                avg_dp_spl{1,j} = dp_amp_spl{:, j};
                avg_nf_spl{1,j} = dp_nf_spl{:, j};
            else
                avg_f_spl{1,j} = mean(cat(1, dp_f_spl{:, j}));
                avg_dp_spl{1,j} = mean(cat(1, dp_amp_spl{:, j}));
                avg_nf_spl{1,j} = mean(cat(1, dp_nf_spl{:, j}));
            end
            figure(counter_avg+2); hold on;
            plot(avg_f_spl{j}, db(avg_dp_spl{j}.*spl.VtoSPL),'-', 'linew', 2, 'Color', colors(j,:))
            plot(avg_f_spl{j}, db(avg_nf_spl{j}.*spl.VtoSPL),'--', 'linew', 2, 'Color', colors(j,:),'HandleVisibility','off')
            uplim = db(max(cellfun(@max, avg_dp_spl), [], 'all').*spl.VtoSPL);
            lowlim = db(max(cellfun(@min, avg_nf_spl), [], 'all').*spl.VtoSPL);
            ylim([lowlim - 5, uplim + 5])
            legend_string = [legend_string; sprintf('%s (n = %d)',cell2mat(Conds2Run(j)),length(Chins2Run)-sum(idx(:,j)))];
            legend(legend_string,'Location','southoutside','Orientation','horizontal','FontSize',8)
            legend boxoff
            hold off;
        end
        %% Export
        outpath = strcat(OUTdir,filesep,'Analysis',filesep,EXPname);
        cd(outpath);
        filename = 'DPOAEswept_Average_SPL';
        print(counter_avg+2,[filename,'_figure'],'-dpng','-r300');
        cd(cwd);
    end
else
    fprintf('No directory found.\n');
    count = count + 1;
    %% PLOTTING - AVERAGE EPL
    counter_avg = 2*length(Chins2Run);
    figure(counter_avg+1); hold on;
    %plot(f2, dpoae_full, '-', 'linew', 2, 'Color', [colors(CondIND,:),0.25],'HandleVisibility','off');
    %plot(f2, dpnf_full, '--', 'linew', 2, 'Color', [colors(CondIND,:),0.25],'HandleVisibility','off');
    set(gca, 'XScale', 'log', 'FontSize', 14)
    xlim([.5, 16]); xticks([.5, 1, 2, 4, 8, 16])
    ylabel('Amplitude (dB EPL)', 'FontWeight', 'bold')
    xlabel('F_2 Frequency (kHz)', 'FontWeight', 'bold')
    title(sprintf('DPOAE | Average (n = %.0f)',length(Chins2Run)), 'FontSize', 16); hold off;
    legend_string = {};
    if ChinIND == length(Chins2Run) && CondIND == length(Conds2Run)
        for j = 1:length(Conds2Run)
            idx = cellfun(@isempty,dp_amp_epl);
            idx2 = find(sum(~idx) == 1);
            if j == idx2
                avg_f_epl{1,j} = dp_f2{:, j};
                avg_dp_epl{1,j} = dp_amp_epl{:, j};
                avg_nf_epl{1,j} = dp_nf_epl{:, j};
            else
                avg_f_epl{1,j} = mean(cat(1, dp_f2{:, j}));
                avg_dp_epl{1,j} = mean(cat(1, dp_amp_epl{:, j}));
                avg_nf_epl{1,j} = mean(cat(1, dp_nf_epl{:, j}));
            end
            figure(2*length(Chins2Run)+1); hold on;
            plot(avg_f_epl{j}, avg_dp_epl{j},'-', 'linew', 2, 'Color', colors(j,:))
            plot(avg_f_epl{j}, avg_nf_epl{j},'--', 'linew', 2, 'Color', colors(j,:),'HandleVisibility','off')
            uplim = max(cellfun(@max, avg_dp_epl), [], 'all');
            lowlim = max(cellfun(@min, avg_nf_epl), [], 'all');
            ylim([lowlim - 5, uplim + 5])
            legend_string = [legend_string; sprintf('%s (n = %d)',cell2mat(Conds2Run(j)),length(Chins2Run)-sum(idx(:,j)))];
            legend(legend_string,'Location','southoutside','Orientation','horizontal','FontSize',8)
            legend boxoff
            hold off;
        end
        %% Export
        outpath = strcat(OUTdir,filesep,'Analysis',filesep,EXPname);
        cd(outpath);
        filename = 'DPOAEswept_Average_EPL';
        print(counter_avg+1,[filename,'_figure'],'-dpng','-r300');
        cd(cwd);
    end
    %% PLOTTING - AVERAGE SPL
    counter_avg = 2*length(Chins2Run);
    figure(counter_avg+2); hold on;
    %plot(spl.f, db(abs(spl.oae).*spl.VtoSPL), '-', 'linew', 2, 'Color', [colors(CondIND,:),0.25],'HandleVisibility','off');
    %plot(spl.f, db(abs(spl.noise).*spl.VtoSPL), '--', 'linew', 2, 'Color', [colors(CondIND,:),0.25],'HandleVisibility','off');
    set(gca, 'XScale', 'log', 'FontSize', 14)
    xlim([.5, 16]); xticks([.5, 1, 2, 4, 8, 16])
    ylabel('Amplitude (dB SPL)', 'FontWeight', 'bold')
    xlabel('F_2 Frequency (kHz)', 'FontWeight', 'bold')
    title(sprintf('DPOAE | Average (n = %.0f)',length(Chins2Run)), 'FontSize', 16); hold off;
    legend_string = {};
    if ChinIND == length(Chins2Run) && CondIND == length(Conds2Run)
        for j = 1:length(Conds2Run)
            idx = cellfun(@isempty,dp_amp_spl);
            idx2 = find(sum(~idx) == 1);
            if j == idx2
                avg_f_spl{1,j} = dp_f_spl{:, j};
                avg_dp_spl{1,j} = dp_amp_spl{:, j};
                avg_nf_spl{1,j} = dp_nf_spl{:, j};
            else
                avg_f_spl{1,j} = mean(cat(1, dp_f_spl{:, j}));
                avg_dp_spl{1,j} = mean(cat(1, dp_amp_spl{:, j}));
                avg_nf_spl{1,j} = mean(cat(1, dp_nf_spl{:, j}));
            end
            figure(counter_avg+2); hold on;
            plot(avg_f_spl{j}, db(avg_dp_spl{j}.*spl.VtoSPL),'-', 'linew', 2, 'Color', colors(j,:))
            plot(avg_f_spl{j}, db(avg_nf_spl{j}.*spl.VtoSPL),'--', 'linew', 2, 'Color', colors(j,:),'HandleVisibility','off')
            uplim = db(max(cellfun(@max, avg_dp_spl), [], 'all').*spl.VtoSPL);
            lowlim = db(max(cellfun(@min, avg_nf_spl), [], 'all').*spl.VtoSPL);
            ylim([lowlim - 5, uplim + 5])
            legend_string = [legend_string; sprintf('%s (n = %d)',cell2mat(Conds2Run(j)),length(Chins2Run)-sum(idx(:,j)))];
            legend(legend_string,'Location','southoutside','Orientation','horizontal','FontSize',8)
            legend boxoff
            hold off;
        end
        %% Export
        outpath = strcat(OUTdir,filesep,'Analysis',filesep,EXPname);
        cd(outpath);
        filename = 'DPOAEswept_Average_SPL';
        print(counter_avg+2,[filename,'_figure'],'-dpng','-r300');
        cd(cwd);
    end
end
%% PLOTTING - BAND AVERAGING
% Set params
% fmin = 0.5;
% fmax = 16;
% edges = 2 .^ linspace(log2(fmin), log2(fmax), 21);
% bandEdges = edges(2:2:end-1);
% centerFreqs = edges(3:2:end-2);
% dpoae = zeros(length(centerFreqs),1);
% dpnf = zeros(length(centerFreqs),1);
% dpoae_w = zeros(length(centerFreqs),1);
% dpnf_w = zeros(length(centerFreqs),1);
% % resample / average to 9 center frequencies
% for z = 1:length(centerFreqs)
%     band = find( f2 >= bandEdges(z) & f2 < bandEdges(z+1));
%     % Do some weighting by SNR
%     % TO DO: NF from which SNR was calculated included median of 7 points
%     % nearest the target frequency.
%     SNR = dpoae_full(band) - dpnf_full(band);
%     weight = (10.^(SNR./10)).^2;
%     dpoae(z, 1) = mean(dpoae_full(band));
%     dpnf(z,1) = mean(dpnf_full(band));
%     dpoae_w(z,1) = sum(weight.*dpoae_full(band))/sum(weight);
%     dpnf_w(z,1) = sum(weight.*dpnf_full(band))/sum(weight);
% end