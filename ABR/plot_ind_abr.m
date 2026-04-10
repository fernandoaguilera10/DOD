function plot_ind_abr(data,plot_type,colors,shapes,Conds2Run,Chins2Run,all_Conds2Run,ChinIND,CondIND,outpath,ylimits_threshold,ylimits_peaks,ylimits_lat,all_freq)
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
    % Build click vs. pure-tone vectors based on actual frequency content,
    % not by position — works for any subset of selected frequencies.
    click_mask = (data.freqs(:)' == 0);
    tone_mask  = (data.freqs(:)' ~= 0);
    click_threshold = nan(1, length(data.freqs));
    click_threshold(click_mask) = data.thresholds(click_mask);
    freq_threshold  = nan(1, length(data.freqs));
    freq_threshold(tone_mask)   = data.thresholds(tone_mask);
    fh_t = figure(fig_num);
    set(fh_t, 'Visible', 'off');
    hold on;
    % Name identifies this as an individual figure (used by analysis_run embed logic)
    set(fh_t, 'Name', cell2mat(Chins2Run(ChinIND)));
    % Only draw the click series when click was actually selected
    if any(click_mask)
        plot(freq,click_threshold,'Marker',shapes(CondIND,:),'LineStyle','-', 'linew', 3, 'MarkerSize', 15, 'Color', colors(CondIND,:),'MarkerFaceColor', colors(CondIND,:), 'MarkerEdgeColor', colors(CondIND,:))
    end
    % Only draw the pure-tone series when at least one pure tone was selected
    if any(tone_mask)
        % Suppress legend entry when the click line already represents this condition
        hv = 'off'; if ~any(click_mask), hv = 'on'; end
        plot(freq,freq_threshold,'Marker',shapes(CondIND,:),'LineStyle','-', 'linew',3, 'MarkerSize', 15, 'Color', colors(CondIND,:),'MarkerFaceColor', colors(CondIND,:), 'MarkerEdgeColor', colors(CondIND,:),'HandleVisibility',hv)
    end
    if ~isempty(ylimits_threshold)
        ylim(ylimits_threshold);
    end 
    ylabel(y_units, 'FontWeight', 'bold')
    xlabel(x_units, 'FontWeight', 'bold')
    freq_tick_labels = cell(1, length(data.freqs));
    for fi = 1:length(data.freqs)
        if data.freqs(fi) == 0
            freq_tick_labels{fi} = 'Click';
        else
            freq_tick_labels{fi} = num2str(data.freqs(fi)/1000);
        end
    end
    xticks(freq); xlim([0.5, length(freq)+0.5]);
    xticklabels(freq_tick_labels);
    legend(legend_string,'Location','southoutside','Orientation','horizontal')
    legend boxoff; grid on;
    set(gca,'FontSize',25); set(gca,'xscale','linear'); set(legend,'visible','on');
    set(gcf, 'Units', 'normalized', 'Position', [0.2 0.2 0.5 0.6]);
elseif strcmp(plot_type,'Peaks')
    x_units = 'Sound Level (dB SPL)';
    y_units_amp = 'Amplitude (\muV)';
    y_units_lat = 'Latency (ms)';
    if data.freq == 0
        freq = 'click';
        fig_freq_label = 'Click';
    else
        freq = [num2str(data.freq), ' Hz'];
        f_val = data.freq;
        if f_val >= 1000
            fig_freq_label = sprintf('%.4g kHz', f_val/1000);
        else
            fig_freq_label = sprintf('%.4g Hz', f_val);
        end
    end
    filename = cell2mat([Chins2Run(ChinIND),'_',condition,'_ABRpeaks_',freq]);

    % Define positions for subplots
    left_width = 0.40;  % Left side takes half the figure
    right_width = 0.40; % Right side takes half the figure
    height = 0.375;     % Height for each of the stacked plots
    FreqIND = find(all_freq == data.freq);
    fig_num = (ChinIND - 1) * (length(all_freq) * length(all_Conds2Run)) + (FreqIND - 1) * length(all_Conds2Run) + CondIND;
    fh = figure(fig_num);
    set(fh, 'Visible', 'off');
    set(fh, 'Name', sprintf('%s|%s', condition{end}, fig_freq_label));
    
    % Peak plots
    subplot('Position', [0.08,height+0.15, left_width, height]);
    for i=1:2:width(data.peak_amplitude)-1
        % peak-to-peak amplitude
        plot(data.levels, data.peak_amplitude(:,i)-data.peak_amplitude(:,i+1),'Marker',shapes((i+1)/2,:),'LineStyle','-', 'linew', 3, 'MarkerSize', 15, 'Color', colors((i+1)/2+4,:),'MarkerFaceColor', colors((i+1)/2+4,:), 'MarkerEdgeColor', colors((i+1)/2+4,:));
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
    yl = ylim; yl(1) = max(0, yl(1));
    if all(isfinite(yl)) && yl(2) > yl(1)
        ylim(yl); yticks(floor(yl(1)):1:ceil(yl(2)));
    end
    sgtitle(sprintf('ABR Peaks | %s | %s | %s', cell2mat(Chins2Run(ChinIND)),condition{2},freq),'FontSize', 25,'FontWeight', 'bold'); grid on;
    xticklabels({}); set(gca,'FontSize',25);
    
    % Latency plots
    subplot('Position', [0.08, 0.12, left_width, height]);
    for i=1:2:width(data.peak_latency)
        plot(data.levels, data.peak_latency(:,i),'Marker',shapes((i+1)/2,:),'LineStyle','-', 'linew', 3, 'MarkerSize', 15, 'Color', colors((i+1)/2+4,:),'MarkerFaceColor', colors((i+1)/2+4,:), 'MarkerEdgeColor', colors((i+1)/2+4,:))
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
    yl = ylim; yl(1) = max(0, yl(1));
    if all(isfinite(yl)) && yl(2) > yl(1)
        ylim(yl); yticks(floor(yl(1)):1:ceil(yl(2)));
    end
    legend_string = {'w1','w2','w3','w4','w5'};
    legend(legend_string,'Location','northoutside','Orientation','horizontal')
    legend boxoff;
    set(gca,'FontSize',25);

    % Waveform plots
    subplot('Position', [right_width+0.16, 0.12, right_width, 0.80]);
    buff = 1.25*max(max(data.waveforms'))*(1:size(data.waveforms',2));
    wform_plot = data.waveforms'-buff;
    plot(data.waveforms_time,wform_plot,'k','linewidth',3);
    for i=1:2:width(data.peak_latency)
        hold on;
        peaks_plot = data.peak_amplitude(:,i)-buff';
        plot(data.peak_latency(:,i),peaks_plot,'Marker',shapes((i+1)/2,:),'LineStyle','none', 'MarkerSize', 10, 'Color', colors((i+1)/2+4,:),'MarkerFaceColor', 'none', 'MarkerEdgeColor', colors((i+1)/2+4,:),'LineWidth', 2)
    end
    for i=2:2:width(data.peak_latency)
        hold on;
        peaks_plot = data.peak_amplitude(:,i)-buff';
        plot(data.peak_latency(:,i),peaks_plot,'Marker',shapes(i/2,:),'LineStyle','none', 'MarkerSize', 10, 'Color', colors(i/2+4,:),'MarkerFaceColor', 'none', 'MarkerEdgeColor', colors(i/2+4,:),'LineWidth', 2)
    end
    ylabel(x_units, 'FontWeight', 'bold')
    xlabel(y_units_lat, 'FontWeight', 'bold')
    xlim([0,inf]);
    yticks(flip(mean(wform_plot)));
    yticklabels(flip(round(data.levels)));
    ylim([1.05*min(min(wform_plot)),0])
    set(gca,'FontSize',25);
    set(gcf, 'Units', 'normalized', 'Position', [0.01 0.1 0.7 0.9]);
end
%% Export
cd(outpath);
print(fig_num,[filename,'_figure'],'-dpng','-r300');
end



