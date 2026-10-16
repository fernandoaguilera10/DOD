function plot_ind_abr(data,plot_type,colors,shapes,Conds2Run,Chins2Run,all_Conds2Run,ChinIND,CondIND,outpath,ylimits_threshold,ylimits_peaks,ylimits_lat,all_freq,wave_sel)
WSH = 'vsd^o';   % fixed Wave I-V markers (condition markers are user-set; keep waves stable)
global legend_string
legend_string= Conds2Run;
condition = strsplit(all_Conds2Run{CondIND}, filesep);
if strcmp(plot_type,'Thresholds')
    filename = cell2mat([Chins2Run(ChinIND),'_',condition,'_ABRthresholds',]);
    % Summary tab: threshold vs frequency + values table (conditions accumulate)
    fh_t = plot_thr_summary(cell2mat(Chins2Run(ChinIND)), data.freqs, data.thresholds, ...
        condition{end}, colors(CondIND,:), shapes(CondIND,:), ylimits_threshold);
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
    % 'Frequency|Condition': the app makes one tab per frequency and the
    % Condition dropdown picks the condition (same layout as ABR Thresholds)
    fig_name = sprintf('%s|%s', fig_freq_label, condition{end});
    fh = findobj('Type','figure','Name',fig_name);
    if isempty(fh)
        fh = figure('Visible','off','NumberTitle','off','Name',fig_name);
    else
        fh = fh(1);  set(fh,'Visible','off');  clf(fh);
    end
    set(fh, 'Units','normalized', 'Position',[0.01 0.1 0.7 0.9]);   % final size first (marker sizing)
    % Waves side by side at each level (same spacing as the averages)
    n_wave_slots = floor(width(data.peak_amplitude) / 2);
    shown_k = find(arrayfun(@(k) ~(k <= numel(wave_sel) && ~wave_sel(k)), 1:n_wave_slots));
    level_ticks = unique(round(data.levels));
    dl = 10;  if numel(level_ticks) > 1, dl = min(diff(level_ticks)); end
    w_off = zeros(1, n_wave_slots);  w_off(shown_k) = apat_dodge(numel(shown_k)) * dl;
    x_pad = dl;  if numel(level_ticks) > 1, x_pad = max((level_ticks(end)-level_ticks(1))*0.06, max(abs(w_off)) + 0.35*dl); end
    height = 0.33;
    
    % Peak-to-peak amplitude plot — only waves that are (a) selected by
    % wave_sel and (b) have at least one non-NaN data point (i.e. present
    % in the template used for this analysis).
    ax_amp = subplot('Position', [0.08, 0.56, left_width, height]);
    if numel(level_ticks) > 1, xlim(ax_amp, [level_ticks(1)-x_pad, level_ticks(end)+x_pad]); end
    ms_w = apat_ms(ax_amp, 0.7*dl);   % waves at true x: size from the level spacing
    amp_handles = gobjects(0);
    amp_names   = {};
    for k = 1:n_wave_slots
        i = 2*k - 1;  % column index of peak amplitude
        if k <= numel(wave_sel) && ~wave_sel(k), continue; end  % checkbox off
        amp_vals = data.peak_amplitude(:,i) - data.peak_amplitude(:,i+1);
        wn = wave_names{min(k, numel(wave_names))};
        h = plot(data.levels + w_off(k), amp_vals, 'Marker', WSH(k), 'LineStyle', '-', ...
            'LineWidth', 2, 'MarkerSize', ms_w, 'Color', colors(k+4,:), ...
            'MarkerFaceColor', colors(k+4,:), 'MarkerEdgeColor', colors(k+4,:), ...
            'DisplayName', wn);
        amp_handles(end+1) = h;
        amp_names{end+1}   = wn;
        hold on;
    end
    if numel(level_ticks) > 1
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
    apat_xgroups(gca, level_ticks);              % one column per level
    xticklabels({}); set(gca,'FontSize',14); box off;
    % Shared wave legend — bottom of the figure (same style as every measure)
    if ~isempty(amp_handles)
        LC = struct('clr',{},'shp',{},'label',{});
        for hh = 1:numel(amp_handles)
            LC(end+1) = struct('clr',amp_handles(hh).Color, 'shp',amp_handles(hh).Marker, 'label',amp_names{hh}); %#ok<AGROW>
        end
        apat_legend(fh, ax_amp, LC, [], 0.08, 0.88);
    end

    % Latency plot — same wave_sel and NaN filter as amplitude
    subplot('Position', [0.08, 0.17, left_width, height]);
    lat_handles = gobjects(0);
    lat_names   = {};
    for k = 1:n_wave_slots
        i = 2*k - 1;  % column index of peak latency
        if k <= numel(wave_sel) && ~wave_sel(k), continue; end
        lat_vals = data.peak_latency(:,i);
        wn = wave_names{min(k, numel(wave_names))};
        h = plot(data.levels + w_off(k), lat_vals, 'Marker', WSH(k), 'LineStyle', '-', ...
            'LineWidth', 2, 'MarkerSize', ms_w, 'Color', colors(k+4,:), ...
            'MarkerFaceColor', colors(k+4,:), 'MarkerEdgeColor', colors(k+4,:), ...
            'DisplayName', wn);
        lat_handles(end+1) = h;
        lat_names{end+1}   = wn;
        hold on;
    end
    if numel(level_ticks) > 1
        xlim([level_ticks(1)-x_pad, level_ticks(end)+x_pad]);
    end
    hold off;
    ylabel(y_units_lat, 'FontWeight', 'bold')
    xlabel(x_units, 'FontWeight', 'bold')
    xticks(level_ticks);
    xticklabels(level_ticks); grid on;
    apat_xgroups(gca, level_ticks);              % one column per level
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
    subplot('Position', [right_width+0.16, 0.17, right_width, 0.72]);
    buff = 1.25*max(max(data.waveforms'))*(1:size(data.waveforms',2));
    wform_plot = data.waveforms'-buff;
    plot(data.waveforms_time,wform_plot,'k','linewidth',3);
    for i=1:2:width(data.peak_latency)
        wave_k = (i+1)/2;
        if wave_k <= numel(wave_sel) && ~wave_sel(wave_k), continue; end
        hold on;
        peaks_plot = data.peak_amplitude(:,i)-buff';
        % Peak = filled marker
        plot(data.peak_latency(:,i),peaks_plot,'Marker',WSH(wave_k),'LineStyle','none', 'MarkerSize', 9, 'Color', colors(wave_k+4,:),'MarkerFaceColor', colors(wave_k+4,:), 'MarkerEdgeColor', colors(wave_k+4,:),'LineWidth', 1.5)
    end
    for i=2:2:width(data.peak_latency)
        wave_k = i/2;
        if wave_k <= numel(wave_sel) && ~wave_sel(wave_k), continue; end
        hold on;
        peaks_plot = data.peak_amplitude(:,i)-buff';
        % Trough = hollow marker (waveform stays visible)
        plot(data.peak_latency(:,i),peaks_plot,'Marker',WSH(wave_k),'LineStyle','none', 'MarkerSize', 10, 'Color', colors(wave_k+4,:),'MarkerFaceColor', 'none', 'MarkerEdgeColor', colors(wave_k+4,:),'LineWidth', 2)
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
end
%% Export
% Thresholds: the subject summary (all conditions so far, redrawn each
% call) → <Subj>/<Subj>_ABRthresholds_figure.png (the last
% call leaves the full overlay). Peaks: one figure per recording and
% frequency, next to its .mat (<Subj>_<Cond>_ABRpeaks_dtw_<freq>_figure.png).
drawnow;
if strcmp(plot_type,'Thresholds')
    subj = cell2mat(Chins2Run(ChinIND));
    try, apat_save_fig(fh_t, apat_out_dir('all_file', outpath, [subj '_ABRthresholds_figure']), 'abr_thr_ind'); catch, end
else
    if data.freq == 0, fstr = 'click'; else, fstr = [num2str(data.freq) 'Hz']; end
    stem = sprintf('%s_%s_ABRpeaks_dtw_%s', cell2mat(Chins2Run(ChinIND)), condition{end}, fstr);
    try, apat_save_fig(fh, fullfile(outpath, [stem '_figure']), 'abr_peaks_ind'); catch, end
end
end



