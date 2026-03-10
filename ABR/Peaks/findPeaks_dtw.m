function [peaks,latencies] = findPeaks_dtw(t_signal,signal,template,latencies_template,subject,condition,Conds2Run,CondIND,levels,counter,level_counter,colors,shapes,ylim_ind,freq_str,idx_abr,idx_template)
tolerance = 5;
num_waves = 3;
num_peaks = num_waves*2;
snap_to_localminmax = 1;    % apply time constraint to select peaks/throughs chronologically (t1 < t2) and amplitude constraint to differntiate peaks/throughs
y_units = 'Amplitude (\muV)';
x_units = 'Time (ms)';
frame_sig = 1:length(signal);
if ~isempty(template) && all(~isnan(template))
    norm_factor_signal = max(signal)-min(signal);
    norm_factor_template = max(template)-min(template);
    signal_norm = diff(signal/norm_factor_signal);  % derivative of normalized signal
    template_norm = diff(template/norm_factor_template);    % derivative of normalized template
    [~, xi, yi] = dtw(template_norm,signal_norm,tolerance);
    for i = 1:size(latencies_template,1)
        warp_ind_temp = find(xi==latencies_template(i,3));
        warp_ind(i) = round(mean(warp_ind_temp));
    end
    sig_inds = yi(warp_ind);

    if snap_to_localminmax
        signal = signal(:); % force column
        t_signal = t_signal(:);

        % Time windows for each latency
        time_windows = [
        0.007 0.0085   % Wave I
        0.0085 0.0095  % N1
        0.0095 0.0105  % Wave III
        0.0105 0.0115  % N3
        0.0110 0.0125  % Wave V
        0.0125 0.0140  % N5
        ];

        % Find peaks
        [~, pks_locs, ~, peaks_p] = findpeaks(signal);
        threshold = 0.25; % new treshold
        pks = pks_locs(peaks_p/max(peaks_p) > threshold);

        % Find valleys (negative peaks)
        [~, vals_locs, ~, vals_p] = findpeaks(-signal);
        vals = vals_locs(vals_p/max(vals_p) > threshold);
        
        % for debugging
        pks_threshold = pks;
        vals_threshold = vals;
      
        % Snap each latency to nearest local peak or valley
        % max_snap_dist = 5; % samples - we don't need anymore
        last_assigned = -inf; % keep track of most recent assignment

        for j = 1:length(sig_inds)
            % time window for this wave
            t_min = time_windows(j,1);
            t_max = time_windows(j,2);
            if mod(j,2)==0  % valleys (N)
                % only consider valleys after the previous peak
                prev_peak = sig_inds(j-1);
                candidate_vals = vals(vals > prev_peak & vals > last_assigned & t_signal(vals) >= t_min & t_signal(vals) <= t_max);
                if ~isempty(candidate_vals)
                    % update
                    if ~isempty(candidate_vals)
                    [~, ind] = min(signal(candidate_vals));
                    sig_inds(j) = candidate_vals(ind);
                    end
                end
            else  % peaks (P)
                % only consider peaks after the last assigned latency
                candidate_pks = pks(pks > last_assigned & t_signal(pks) >= t_min & t_signal(pks) <= t_max);
                if ~isempty(candidate_pks)
                    % update
                    if ~isempty(candidate_pks)
                    [~, ind] = max(signal(candidate_pks));
                    sig_inds(j) = candidate_pks(ind);
                    end
                end
            end

            % update last assigned latency
            last_assigned = sig_inds(j);
        end
    end


    peaks = signal(sig_inds)*10^2;
    latencies = t_signal(sig_inds)*10^3;

    %-----------------------Debug Plot-------------------------------
    figure;
    plot(t_signal*10^3, signal*10^2,'k','LineWidth',2);
    hold on; grid on;
    
    % threshold peaks
    plot(t_signal(pks_threshold)*10^3, signal(pks_threshold)*10^2,...
        'ro','MarkerFaceColor','r','DisplayName','Threshold peaks');
    
    % final selected peaks after constraint
    plot(t_signal(sig_inds)*10^3, signal(sig_inds)*10^2,...
        'gs','MarkerFaceColor','g','MarkerSize',8,...
        'DisplayName','Final selected peaks');
    
    % show time windows
    for j = 1:size(time_windows,1)
        xline(time_windows(j,1)*1000,'--g','HandleVisibility','off');
        xline(time_windows(j,2)*1000,'--g','HandleVisibility','off');
    end
    
    xlabel('Time (ms)');
    ylabel('Amplitude (\muV)');
    xlim([0 20]);
    title('Debug: Threshold vs Final Peaks');
    legend show;
    
    % Plotting

    figure(counter);
    subplot_idx = (CondIND-1)*length(levels) + level_counter;
    subplot(length(Conds2Run),length(levels),subplot_idx);
    time_plot = t_signal*10^3;
    wform_plot = 10^2*signal;
    peaks_plot = 10^2*signal(sig_inds);
    template_plot = 10^2*template;
    template_peaks = 10^2*latencies_template(:,2);
    hold on
    waves_legend = ["I","III","V"];
    for k = 1:num_waves % number of waves I-V
        idx = (2*k-1):(2*k);  % indices for pairs: peak + trough
        plot(time_plot(latencies_template(idx,3)),template_peaks(idx), shapes(k),'Color', [0.60,0.60,0.60],'MarkerFaceColor', [0.60,0.60,0.60],'MarkerSize', 12,'LineWidth', 1.5,'HandleVisibility','off'); % template
        plot(time_plot(frame_sig(sig_inds(idx))),peaks_plot(idx), shapes(k),'Color', colors(k+4,:),'MarkerFaceColor', colors(k+4,:),'MarkerSize', 12,'LineWidth', 1.5, 'DisplayName', sprintf('Wave %s', waves_legend(k))); % ABR
    end
    plot(time_plot(frame_sig),template_plot,'--','LineWidth',3,'color',[0 0 0 0.25],'HandleVisibility','off');
    plot(time_plot,wform_plot,'LineWidth',3,'Color', colors(CondIND,:),'HandleVisibility','off');
    set(gca,'FontSize',25); xlim([0,20]); grid on;
else
    peaks = nan(1,num_peaks);
    latencies = nan(1,num_peaks);
    plot(t_signal*10^3,signal*10^2,'LineWidth',3,'Color', colors(CondIND,:),'HandleVisibility','off')
end
set(gcf, 'Units', 'Normalized', 'OuterPosition', [0, 0.05, 0.95, 0.95]);
ylim(ylim_ind);
hold off
if CondIND == 1
    title_str = sprintf('%s | %s dB SPL | %s ',freq_str,num2str(levels(level_counter)),cell2mat(subject));
    title(title_str,'FontSize', 16,'FontWeight','bold');
    set(gca,'FontSize',25);
end
if subplot_idx == 1
    legend({},'Location','northeast','Orientation','vertical')
    legend box off;
    set(gca,'FontSize',25);
end
if CondIND == length(Conds2Run)
    xlabel(x_units, 'FontWeight', 'bold','FontSize',20);
end
if level_counter == 1
    ylabel(y_units, 'FontWeight', 'bold','FontSize',20);
end
if CondIND ~= length(Conds2Run)
    xticklabels([]);
end
subtitle(sprintf('%s',condition));
grid on;
end