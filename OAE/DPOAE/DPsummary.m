%% DPsummary
% Load Data
uplim = 0;
lowlim = 0;
cwd = pwd;
%colors = ["#0072BD"; "#EDB120"; "#7E2F8E"; "#77AC30"; "#A2142F"; "#FF33FF"];
colors = [0,114,189; 237,177,32; 126,47,142; 119,172,48; 162,20,47; 255,51,255]/255;
shapes = ["x";"^";"v";"diamond";"o";"*"];
%% INDIVIDUAL PLOTS
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

    % PLOTTING EPL
    dp_f_epl{ChinIND,CondIND} = f2;
    dp_amp_epl{ChinIND,CondIND} = dpoae_full';
    dp_nf_epl{ChinIND,CondIND} = dpnf_full';
    dp_amp_summ_epl{ChinIND,CondIND} = data.epl.bandOAE';
    dp_nf_summ_epl{ChinIND,CondIND} = data.epl.bandNF';
    counter = 2*ChinIND-1;
    figure(counter); hold on;
    plot(f2, dpoae_full,'-', 'linew', 2, 'Color', colors(CondIND,:))
    plot(f2, dpnf_full, '--', 'linew', 2, 'Color', [colors(CondIND,:),0.25],'HandleVisibility','off')
    plot(data.epl.centerFreq, data.epl.bandOAE, 'o', 'linew', 2, 'MarkerSize', 8, 'MarkerFaceColor', colors(CondIND,:), 'MarkerEdgeColor', colors(CondIND,:),'HandleVisibility','off')
    plot(data.epl.centerFreq, data.epl.bandNF, 'x', 'linew', 4, 'MarkerSize', 8, 'MarkerFaceColor', colors(CondIND,:), 'MarkerEdgeColor', colors(CondIND,:),'HandleVisibility','off')
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
    ylim([round(lowlim - 5,1), round(uplim + 5,1)])
    xticks([.5, 1, 2, 4, 8, 16])
    ylabel('Amplitude (dB EPL)', 'FontWeight', 'bold')
    xlabel('F2 Frequency (kHz)', 'FontWeight', 'bold')
    legend(Conds2Run{CondIND},'Location','southoutside','Orientation','horizontal','FontSize',8)
    legend boxoff
    title(sprintf('DPOAE | %s',Chins2Run{ChinIND}), 'FontSize', 16)

    % PLOTTING SPL
    dp_f_spl{ChinIND,CondIND} = spl.f;
    dp_amp_spl{ChinIND,CondIND} = abs(spl.oae)';
    dp_nf_spl{ChinIND,CondIND} = abs(spl.noise)';
    dp_amp_summ_spl{ChinIND,CondIND} = data.spl.bandOAE';
    dp_nf_summ_spl{ChinIND,CondIND} = data.spl.bandNF';
    figure(counter+1); hold on;
    plot(spl.f, db(abs(spl.oae).*spl.VtoSPL), '-', 'linew', 2, 'Color', colors(CondIND,:));
    plot(spl.f, db(abs(spl.noise).*spl.VtoSPL), '--', 'linew', 2, 'Color', [colors(CondIND,:),0.25],'HandleVisibility','off');
    plot(data.spl.centerFreq, data.spl.bandOAE, 'o', 'linew', 2, 'MarkerSize', 8, 'MarkerFaceColor', colors(CondIND,:), 'MarkerEdgeColor', colors(CondIND,:),'HandleVisibility','off')
    plot(data.spl.centerFreq, data.spl.bandNF, 'x', 'linew', 4, 'MarkerSize', 8, 'MarkerFaceColor', colors(CondIND,:), 'MarkerEdgeColor', colors(CondIND,:),'HandleVisibility','off')
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
    ylim([round(lowlim - 5,1), round(uplim + 5,1)])
    xticks([.5, 1, 2, 4, 8, 16])
    ylabel('Amplitude (dB SPL)', 'FontWeight', 'bold')
    xlabel('F_2 Frequency (kHz)', 'FontWeight', 'bold')
    legend(Conds2Run{CondIND},'Location','southoutside','Orientation','horizontal','FontSize',8)
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

    %
else
    fprintf('No directory found.\n');
    count = count + 1;
end
%% AVERAGE PLOTS - individual + average
if ChinIND == length(Chins2Run) && CondIND == length(Conds2Run)
    counter_avg = 2*length(Chins2Run);
    avg_f_epl{1,length(Conds2Run)} = [];
    avg_dp_epl{1,length(Conds2Run)} = [];
    avg_nf_epl{1,length(Conds2Run)} = [];
    avg_dp_summ_epl{1,length(Conds2Run)} = [];
    avg_nf_summ_epl{1,length(Conds2Run)} = [];
    avg_f_spl{1,length(Conds2Run)} = [];
    avg_dp_spl{1,length(Conds2Run)} = [];
    avg_nf_spl{1,length(Conds2Run)} = [];
    avg_dp_summ_spl{1,length(Conds2Run)} = [];
    avg_nf_summ_spl{1,length(Conds2Run)} = [];
    legend_string = [];
    idx = ~cellfun(@isempty,dp_amp_spl);    % find if data file is present: rows = Chins2Run, cols = Conds2Run
    % Plot individual lines
    for cols = 1:length(Conds2Run)
        for rows = 1:length(Chins2Run)
            % if data is present for a given timepoint, then it will be included for averaging
            if idx(rows,cols) == 1
                % EPL
                avg_f_epl{1,cols} = mean([avg_f_epl{1,cols}; dp_f_epl{rows, cols}],1);
                avg_dp_epl{1,cols} = mean([avg_dp_epl{1,cols}; dp_amp_epl{rows, cols}],1);
                avg_nf_epl{1,cols} = mean([avg_nf_epl{1,cols}; dp_nf_epl{rows, cols}],1);
                avg_dp_summ_epl{1,cols} = mean([avg_dp_summ_epl{1,cols}; dp_amp_summ_epl{rows, cols}],1);
                avg_nf_summ_epl{1,cols} = mean([avg_nf_summ_epl{1,cols}; dp_nf_summ_epl{rows, cols}],1);
                % PLOT EPL
                % % Individual DP + NF
                figure(counter_avg+1); hold on;
                plot(dp_f_epl{rows, cols}, dp_amp_epl{rows, cols}, '-', 'linew', 2, 'Color', [colors(cols,:),0.25],'HandleVisibility','off');
                %plot(dp_f_epl{rows, cols}, dp_nf_epl{rows, cols}, '--', 'linew', 2, 'Color', [colors(cols,:),0.25],'HandleVisibility','off');
                
                % SPL
                avg_f_spl{1,cols} = mean([avg_f_spl{1,cols}; dp_f_spl{rows, cols}],1);
                avg_dp_spl{1,cols} = mean([avg_dp_spl{1,cols}; dp_amp_spl{rows, cols}],1);
                avg_nf_spl{1,cols} = mean([avg_nf_spl{1,cols}; dp_nf_spl{rows, cols}],1);
                avg_dp_summ_spl{1,cols} = mean([avg_dp_summ_spl{1,cols}; dp_amp_summ_spl{rows, cols}],1);
                avg_nf_summ_spl{1,cols} = mean([avg_nf_summ_spl{1,cols}; dp_nf_summ_spl{rows, cols}],1);
                % PLOT SPL
                % Individual DP + NF
                figure(counter_avg+2); hold on;
                plot(dp_f_spl{rows, cols}, db(abs(dp_amp_spl{rows, cols}).*spl.VtoSPL), '-', 'linew', 2, 'Color', [colors(cols,:),0.25],'HandleVisibility','off');
                %plot(dp_f_spl{rows, cols}, db(abs(dp_nf_spl{rows, cols}).*spl.VtoSPL), '--', 'linew', 2, 'Color', [colors(cols,:),0.25],'HandleVisibility','off');
            end
        end
    end
    N = 0;
    for cols = 1:length(Conds2Run)
        % EPL Average DP + NF
        N = N + sum(idx(:,cols));
        figure(counter_avg+1); hold on;
        plot(avg_f_epl{1,cols}, avg_dp_epl{1,cols},'-', 'linew', 2, 'Color', colors(cols,:))
        plot(avg_f_epl{1,cols}, avg_nf_epl{1,cols},'--', 'linew', 2, 'Color', [colors(cols,:),0.50],'HandleVisibility','off')
        plot(data.epl.centerFreq, avg_dp_summ_epl{1,cols}, 'o', 'linew', 2, 'MarkerSize', 8, 'MarkerFaceColor', colors(cols,:), 'MarkerEdgeColor', colors(cols,:),'HandleVisibility','off')
        plot(data.epl.centerFreq, avg_nf_summ_epl{1,cols}, 'x', 'linew', 4, 'MarkerSize', 8, 'MarkerFaceColor', colors(cols,:), 'MarkerEdgeColor', colors(cols,:),'HandleVisibility','off')
        uplim = max(avg_dp_epl{1,cols});
        lowlim = min(avg_nf_epl{1,cols});
        set(gca, 'XScale', 'log', 'FontSize', 14)
        ylim([round(lowlim - 5,1), round(uplim + 10,1)])
        xlim([.5, 16]); xticks([.5, 1, 2, 4, 8, 16])
        ylabel('Amplitude (dB EPL)', 'FontWeight', 'bold')
        xlabel('F_2 Frequency (kHz)', 'FontWeight', 'bold')
        title(sprintf('DPOAE | Average (n = %.0f)',N), 'FontSize', 16); hold off;
        legend_string = [legend_string; sprintf('%s (n = %d)',cell2mat(Conds2Run(cols)),sum(idx(:,cols)))];
        legend(legend_string,'Location','southoutside','Orientation','horizontal','FontSize',8)
        legend boxoff; hold off;
        % SPL Average DP + NF
        figure(counter_avg+2); hold on;
        plot(avg_f_spl{1,cols}, db(avg_dp_spl{1,cols}.*spl.VtoSPL),'-', 'linew', 2, 'Color', colors(cols,:))
        plot(avg_f_spl{1,cols}, db(avg_nf_spl{1,cols}.*spl.VtoSPL),'--', 'linew', 2, 'Color', [colors(cols,:),0.50],'HandleVisibility','off')
        plot(data.spl.centerFreq, avg_dp_summ_spl{1,cols}, 'o', 'linew', 2, 'MarkerSize', 8, 'MarkerFaceColor', colors(cols,:), 'MarkerEdgeColor', colors(cols,:),'HandleVisibility','off')
        plot(data.spl.centerFreq, avg_nf_summ_spl{1,cols}, 'x', 'linew', 4, 'MarkerSize', 8, 'MarkerFaceColor', colors(cols,:), 'MarkerEdgeColor', colors(cols,:),'HandleVisibility','off')
        uplim = db(max(avg_dp_spl{1,cols}).*spl.VtoSPL);
        lowlim = db(min(avg_nf_spl{1,cols}).*spl.VtoSPL);
        set(gca, 'XScale', 'log', 'FontSize', 14)
        ylim([round(lowlim - 5,1), round(uplim + 10,1)])
        xlim([.5, 16]); xticks([.5, 1, 2, 4, 8, 16])
        ylabel('Amplitude (dB SPL)', 'FontWeight', 'bold')
        xlabel('F_2 Frequency (kHz)', 'FontWeight', 'bold')
        title(sprintf('DPOAE | Average (n = %.0f)',N) , 'FontSize', 16); hold off;
        legend(legend_string,'Location','southoutside','Orientation','horizontal','FontSize',8)
        legend boxoff; hold off;
    end
    % NOTE: PLOT AVERAGE USING A SEPARATE LOOP
    %% Export EPL
    outpath = strcat(OUTdir,filesep,'Analysis',filesep,EXPname);
    cd(outpath);
    filename = 'DPOAEswept_Average_EPL';
    print(counter_avg+1,[filename,'_figure'],'-dpng','-r300');
    cd(cwd);
    %% Export SPL
    outpath = strcat(OUTdir,filesep,'Analysis',filesep,EXPname);
    cd(outpath);
    filename = 'DPOAEswept_Average_SPL';
    print(counter_avg+2,[filename,'_figure'],'-dpng','-r300');
    cd(cwd);
end