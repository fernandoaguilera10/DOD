function plot_ind_abr(data,plot_type,colors,shapes,Conds2Run,Chins2Run,all_Conds2Run,ChinIND,CondIND,outpath,ylimits_threshold,ylimits_peaks,ylimits_lat,all_freq,wave_sel)
global legend_string
legend_string= Conds2Run;
condition = strsplit(all_Conds2Run{CondIND}, filesep);
if strcmp(plot_type,'Thresholds')
    freq = 1:length(data.freqs);
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
    % Find by Name to accumulate conditions via hold on, never by integer
    % (integer lookup collides with Branch 1 diagnostic figures).
    subj_name = cell2mat(Chins2Run(ChinIND));
    fh_t = findobj('Type','figure','Name', subj_name);
    if isempty(fh_t)
        fh_t = figure('Name', subj_name, 'NumberTitle','off', 'Visible','off');
    else
        fh_t = fh_t(1);  set(0,'CurrentFigure', fh_t);
    end
    hold on;
    % Only draw the click series when click was actually selected
    if any(click_mask)
        plot(freq,click_threshold,'Marker',shapes(CondIND,:),'LineStyle','-', 'linew', 3, 'MarkerSize', 9, 'Color', colors(CondIND,:),'MarkerFaceColor', colors(CondIND,:), 'MarkerEdgeColor', colors(CondIND,:))
    end
    % Only draw the pure-tone series when at least one pure tone was selected
    if any(tone_mask)
        % Suppress legend entry when the click line already represents this condition
        hv = 'off'; if ~any(click_mask), hv = 'on'; end
        plot(freq,freq_threshold,'Marker',shapes(CondIND,:),'LineStyle','-', 'linew',3, 'MarkerSize', 9, 'Color', colors(CondIND,:),'MarkerFaceColor', colors(CondIND,:), 'MarkerEdgeColor', colors(CondIND,:),'HandleVisibility',hv)
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
    % Build legend from plotted lines with HandleVisibility='on' so the
    % entry count always matches the plotted count (avoids "Ignoring extra
    % legend entries" on intermediate calls) and copyobj preserves it.
    h_vis = findobj(gca, 'Type', 'line', 'HandleVisibility', 'on');
    h_vis = flipud(h_vis);  % restore draw order (findobj returns newest first)
    n_vis = numel(h_vis);
    leg_labels = legend_string(1:min(n_vis, numel(legend_string)));
    lh = legend(h_vis, leg_labels, 'Location','southoutside','Orientation','horizontal');
    legend boxoff; grid on;
    set(gca,'FontSize',25); set(gca,'xscale','linear'); set(lh,'visible','on');
    set(gcf, 'Units', 'normalized', 'Position', [0.2 0.2 0.5 0.6]);
elseif strcmp(plot_type,'Peaks')
    if ~exist('wave_sel','var') || isempty(wave_sel), wave_sel = true(1,5); end
    wave_names = {'Wave I','Wave II','Wave III','Wave IV','Wave V'};
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
    % Use Name-based figure creation to avoid collisions with pre-existing
    % figures (which would land in pre_subj_figs and never be closed).
    fig_name = sprintf('%s|%s', condition{end}, fig_freq_label);
    fh = findobj('Type','figure','Name',fig_name);
    if isempty(fh)
        fh = figure('Visible','off','NumberTitle','off','Name',fig_name);
    else
        fh = fh(1);  set(fh,'Visible','off');  clf(fh);
    end
    
    % Peak-to-peak amplitude plot — only waves that are (a) selected by
    % wave_sel and (b) have at least one non-NaN data point (i.e. present
    % in the template used for this analysis).
    ax_amp = subplot('Position', [0.08,height+0.15, left_width, height]);
    n_wave_slots = floor(width(data.peak_amplitude) / 2);
    amp_handles = gobjects(0);
    amp_names   = {};
    for k = 1:n_wave_slots
        i = 2*k - 1;  % column index of peak amplitude
        if k <= numel(wave_sel) && ~wave_sel(k), continue; end  % checkbox off
        amp_vals = data.peak_amplitude(:,i) - data.peak_amplitude(:,i+1);
        wn = wave_names{min(k, numel(wave_names))};
        h = plot(data.levels, amp_vals, 'Marker', shapes(k,:), 'LineStyle', '-', ...
            'LineWidth', 3, 'MarkerSize', 9, 'Color', colors(k+4,:), ...
            'MarkerFaceColor', colors(k+4,:), 'MarkerEdgeColor', colors(k+4,:), ...
            'DisplayName', wn);
        amp_handles(end+1) = h;
        amp_names{end+1}   = wn;
        hold on;
    end
    level_ticks = unique(round(data.levels));
    if numel(level_ticks) > 1
        x_pad = (level_ticks(end) - level_ticks(1)) * 0.06;
        xlim([level_ticks(1)-x_pad, level_ticks(end)+x_pad]);
    end
    hold off;
    ylabel(y_units_amp, 'FontWeight', 'bold')
    xticks(level_ticks);
    % Y-limits: use global limits if provided, else data-driven with 20% padding
    if ~isempty(ylimits_peaks)
        ylim(ylimits_peaks);
    else
        yl = ylim;
        rng_amp = yl(2) - yl(1); if rng_amp == 0, rng_amp = 1; end
        ylim([max(0, yl(1) - 0.2*rng_amp), yl(2) + 0.2*rng_amp]);
    end
    sgtitle(sprintf('ABR Peaks  |  %s  |  %s  |  %s', cell2mat(Chins2Run(ChinIND)), condition{end}, fig_freq_label), 'FontSize', 16, 'FontWeight', 'bold'); grid on;
    xticklabels({}); set(gca,'FontSize',14); box off;
    % Shared wave legend — pinned at a fixed figure-normalised position above
    % the amplitude subplot so neither subplot is resized.
    if ~isempty(amp_handles)
        lg = legend(ax_amp, amp_handles, amp_names, ...
            'Orientation','horizontal', 'Box','off', 'FontSize',14, 'Location','none');
        lg.Units = 'normalized';
        % Place legend in the band between the amplitude subplot top and sgtitle
        lg.Position = [0.08, height+0.15+height+0.01, left_width, 0.04];
    end

    % Latency plot — same wave_sel and NaN filter as amplitude
    subplot('Position', [0.08, 0.12, left_width, height]);
    lat_handles = gobjects(0);
    lat_names   = {};
    for k = 1:n_wave_slots
        i = 2*k - 1;  % column index of peak latency
        if k <= numel(wave_sel) && ~wave_sel(k), continue; end
        lat_vals = data.peak_latency(:,i);
        wn = wave_names{min(k, numel(wave_names))};
        h = plot(data.levels, lat_vals, 'Marker', shapes(k,:), 'LineStyle', '-', ...
            'LineWidth', 3, 'MarkerSize', 9, 'Color', colors(k+4,:), ...
            'MarkerFaceColor', colors(k+4,:), 'MarkerEdgeColor', colors(k+4,:), ...
            'DisplayName', wn);
        lat_handles(end+1) = h;
        lat_names{end+1}   = wn;
        hold on;
    end
    if numel(level_ticks) > 1
        x_pad = (level_ticks(end) - level_ticks(1)) * 0.06;
        xlim([level_ticks(1)-x_pad, level_ticks(end)+x_pad]);
    end
    hold off;
    ylabel(y_units_lat, 'FontWeight', 'bold')
    xlabel(x_units, 'FontWeight', 'bold')
    xticks(level_ticks);
    xticklabels(level_ticks); grid on;
    % Y-limits: use global limits if provided, else data-driven with 20% padding
    if ~isempty(ylimits_lat)
        ylim(ylimits_lat);
    else
        yl = ylim;
        rng_lat = yl(2) - yl(1); if rng_lat == 0, rng_lat = 1; end
        ylim([max(0, yl(1) - 0.2*rng_lat), yl(2) + 0.2*rng_lat]);
    end
    set(gca,'FontSize',14); box off;

    % Waveform plots
    subplot('Position', [right_width+0.16, 0.12, right_width, 0.80]);
    buff = 1.25*max(max(data.waveforms'))*(1:size(data.waveforms',2));
    wform_plot = data.waveforms'-buff;
    plot(data.waveforms_time,wform_plot,'k','linewidth',3);
    for i=1:2:width(data.peak_latency)
        wave_k = (i+1)/2;
        if wave_k <= numel(wave_sel) && ~wave_sel(wave_k), continue; end
        hold on;
        peaks_plot = data.peak_amplitude(:,i)-buff';
        plot(data.peak_latency(:,i),peaks_plot,'Marker',shapes(wave_k,:),'LineStyle','none', 'MarkerSize', 9, 'Color', colors(wave_k+4,:),'MarkerFaceColor', colors(wave_k+4,:), 'MarkerEdgeColor', colors(wave_k+4,:),'LineWidth', 2)
    end
    for i=2:2:width(data.peak_latency)
        wave_k = i/2;
        if wave_k <= numel(wave_sel) && ~wave_sel(wave_k), continue; end
        hold on;
        peaks_plot = data.peak_amplitude(:,i)-buff';
        plot(data.peak_latency(:,i),peaks_plot,'Marker',shapes(wave_k,:),'LineStyle','none', 'MarkerSize', 9, 'Color', colors(wave_k+4,:),'MarkerFaceColor', colors(wave_k+4,:), 'MarkerEdgeColor', colors(wave_k+4,:),'LineWidth', 2)
    end
    ylabel(x_units, 'FontWeight', 'bold')
    xlabel(y_units_lat, 'FontWeight', 'bold')
    xlim([0,20]);
    yticks(flip(mean(wform_plot)));
    yticklabels(flip(round(data.levels)));
    ylim([1.05*min(min(wform_plot)),0])
    set(gca,'FontSize',14); box off;
    % 1 µV scale bar anchored to the center of the bottom-most waveform.
    % Waveforms are stored in units where 1 unit ≈ 1 µV (abr_data * 1e2).
    x_sb   = 19.75;                           % ms, 0.25 ms before right edge
    y_sb_b = min(mean(wform_plot));           % center of bottom (highest-level) waveform
    hold on;
    plot([x_sb x_sb], [y_sb_b, y_sb_b+1], 'k-', 'LineWidth', 3);
    text(x_sb-0.3, y_sb_b+0.5, '1 \muV', 'FontSize', 12, 'VerticalAlignment', 'middle', 'HorizontalAlignment', 'right');
    hold off;
    set(gcf, 'Units', 'normalized', 'Position', [0.01 0.1 0.7 0.9]);
end
%% Export
cd(outpath);
if strcmp(plot_type,'Thresholds')
    drawnow;
    exportgraphics(fh_t,[filename,'_figure.png'],'Resolution',300);
else
    drawnow;
    exportgraphics(fh,[filename,'_figure.png'],'Resolution',300);
end
end



