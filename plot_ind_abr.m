function plot_ind_abr(data,plot_type,colors,shapes,Conds2Run,Chins2Run,all_Conds2Run,ChinIND,CondIND,outpath,ylimits_threshold,ylimits_peaks,ylimits_lat)
global legend_string
legend_string= Conds2Run;
condition = strsplit(all_Conds2Run{CondIND}, filesep);
if strcmp(plot_type,'Thresholds')
    freq = 1:length(data.freqs);
    fig_num = ChinIND;
    x_units = 'Frequency (kHz)';
    y_units = 'Threshold (dB SPL)';
    filename = cell2mat([Chins2Run(ChinIND),'_',condition,'_ABRthresholds',]);
    left_width = 0.60;
    right_width = 0.10; 
    height = 0.80;
    click_threshold = [data.thresholds(1),nan(1,length(data.thresholds)-1)];
    freq_threshold = [nan,data.thresholds(2:end)];
    figure(fig_num);hold on;
    plot(freq,click_threshold,'Marker',shapes(CondIND,:),'LineStyle','-', 'linew', 2, 'MarkerSize', 12, 'Color', colors(CondIND,:),'MarkerFaceColor', colors(CondIND,:), 'MarkerEdgeColor', colors(CondIND,:))
    plot(freq,freq_threshold,'Marker',shapes(CondIND,:),'LineStyle','-', 'linew', 2, 'MarkerSize', 12, 'Color', colors(CondIND,:),'MarkerFaceColor', colors(CondIND,:), 'MarkerEdgeColor', colors(CondIND,:),'HandleVisibility','off')
    if ~isempty(ylimits_threshold)
        ylim(ylimits_threshold);
    end 
    ylabel(y_units, 'FontWeight', 'bold')
    xlabel(x_units, 'FontWeight', 'bold')
    xticks(freq); xlim([0.5,6.5]);
    xticklabels({'Click', '0.5', '1', '2', '4', '8'});
    legend(legend_string,'Location','southoutside','Orientation','horizontal')
    legend boxoff; grid on;
    sgtitle(sprintf('ABR Thresholds | %s ', cell2mat(Chins2Run(ChinIND))),'FontSize', 16,'FontWeight','bold');
    set(gca,'FontSize',15); set(gca,'xscale','linear'); set(legend,'visible','on');
    set(gcf, 'Units', 'normalized', 'Position', [0.2 0.2 0.5 0.6]);
elseif strcmp(plot_type,'Peaks')
    x_units = 'Sound Level (dB SPL)';
    y_units_amp = 'Peak-to-Peak Amplitude (\muV)';
    y_units_lat = 'Time (ms)';
    if data.freq == 0, freq = 'click'; end
    if data.freq ~= 0, freq = [num2str(data.freq), ' Hz']; end
    filename = cell2mat([Chins2Run(ChinIND),'_',condition,'_ABRpeaks_',freq]);
    
    % Define positions for subplots
    left_width = 0.40;  % Left side takes half the figure
    right_width = 0.40; % Right side takes half the figure
    height = 0.375;     % Height for each of the stacked plots
    fig_num = (ChinIND - 1) * length(all_Conds2Run) + CondIND;
    figure(fig_num);
    % Peak plots
    subplot('Position', [0.08,height+0.15, left_width, height]);
    for i=1:2:width(data.peak_amplitude)-1
        % peak-to-peak amplitude
        plot(data.levels, data.peak_amplitude(:,i)-data.peak_amplitude(:,i+1),'Marker',shapes((i+1)/2,:),'LineStyle','-', 'linew', 2, 'MarkerSize', 12, 'Color', colors((i+1)/2,:),'MarkerFaceColor', colors((i+1)/2,:), 'MarkerEdgeColor', colors((i+1)/2,:));
        % absolute amplitude
        %plot(data.levels, data.peak_amplitude(:,i),'Marker',shapes((i+1)/2,:),'LineStyle','-', 'linew', 2, 'MarkerSize', 8, 'Color', colors((i+1)/2,:),'MarkerFaceColor', colors((i+1)/2,:), 'MarkerEdgeColor', colors((i+1)/2,:));
        hold on;
    end
    if ~isempty(ylimits_peaks)
        ylim(ylimits_peaks);
    end
    xlim([-inf,inf]);
    hold off;
    ylabel(y_units_amp, 'FontWeight', 'bold')
    level_ticks = unique(round(data.levels));
    xticks(level_ticks);
    sgtitle(sprintf('ABR Peak Amplitude and Latency | %s | %s | %s', cell2mat(Chins2Run(ChinIND)),all_Conds2Run{CondIND},freq),'FontSize', 16,'FontWeight', 'bold'); grid on;
    set(gca,'FontSize',15);
    % Latency plots
    subplot('Position', [0.08, 0.10, left_width, height]);
    for i=1:2:width(data.peak_latency)
        plot(data.levels, data.peak_latency(:,i),'Marker',shapes((i+1)/2,:),'LineStyle','-', 'linew', 2, 'MarkerSize', 12, 'Color', colors((i+1)/2,:),'MarkerFaceColor', colors((i+1)/2,:), 'MarkerEdgeColor', colors((i+1)/2,:))
        hold on;
    end
    if ~isempty(ylimits_lat)
        ylim(ylimits_lat);
    end
    xlim([-inf,inf]);
    hold off;
    ylabel(y_units_lat, 'FontWeight', 'bold')
    xlabel(x_units, 'FontWeight', 'bold')
    xticks(level_ticks);
    xticklabels(level_ticks); grid on;
    legend_string = {'w1','w2','w3','w4','w5'};
    legend(legend_string,'Location','northoutside','Orientation','horizontal')
    legend boxoff;
    set(gca,'FontSize',15);

    % Waveform plots
    subplot('Position', [right_width+0.16, 0.10, right_width, 0.80]);
    buff = 1.25*max(max(data.waveforms'))*(1:size(data.waveforms',2));
    wform_plot = data.waveforms'-buff;
    plot(data.waveforms_time,wform_plot,'k','linewidth',2);
    for i=1:2:width(data.peak_latency)
        hold on;
        peaks_plot = data.peak_amplitude(:,i)-buff';
        plot(data.peak_latency(:,i),peaks_plot,'Marker',shapes((i+1)/2,:),'LineStyle','none', 'MarkerSize', 7, 'Color', colors((i+1)/2,:),'MarkerFaceColor', colors((i+1)/2,:), 'MarkerEdgeColor', colors((i+1)/2,:))
    end
    for i=2:2:width(data.peak_latency)
        hold on;
        peaks_plot = data.peak_amplitude(:,i)-buff';
        plot(data.peak_latency(:,i),peaks_plot,'Marker',shapes(i/2,:),'LineStyle','none', 'MarkerSize', 7, 'Color', colors(i/2,:),'MarkerFaceColor', colors(i/2,:), 'MarkerEdgeColor', colors(i/2,:))
    end
    ylabel(x_units, 'FontWeight', 'bold')
    xlabel(y_units_lat, 'FontWeight', 'bold')
    xlim([0,30]);
    yticks(flip(mean(wform_plot)));
    yticklabels(flip(round(data.levels)));
    ylim([1.05*min(min(wform_plot)),0])
    %set(gcf, 'Units', 'Normalized', 'OuterPosition', [0.25, 0.20, 0.50, 0.50]);
    set(gca,'FontSize',15);
    set(gcf, 'Units', 'normalized', 'Position', [0.2 0.2 0.5 0.6]);
end
%% Export
cd(outpath);
print(figure(fig_num),[filename,'_figure'],'-dpng','-r300');
end



