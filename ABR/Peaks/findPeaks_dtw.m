function [peaks,latencies] = findPeaks_dtw(t_signal,signal,template,latencies_template,subject,condition,Conds2Run,CondIND,levels,counter,level_counter,colors,shapes,ylim_ind,freq_str,idx_abr,idx_template)
tolerance = 10;
snap_to_localminmax = 1;
y_units = 'Amplitude (\muV)';
x_units = 'Time (ms)';
frame_sig = 1:length(signal);
if ~isempty(template) && all(~isnan(template))
    [~, xi, yi] = dtw(template/max(template),signal/max(signal),tolerance);
    for i = 1:size(latencies_template,1)
        warp_ind_temp = find(xi==latencies_template(i,3));
        warp_ind(i) = round(mean(warp_ind_temp));
    end
    sig_inds = yi(warp_ind);

    if snap_to_localminmax
        signal = signal(:); % force column

        % Find peaks
        [~, pks_locs, ~, peaks_p] = findpeaks(signal);
        threshold = 0.15;
        pks = pks_locs(peaks_p/max(peaks_p) > threshold);

        % Find valleys (negative peaks)
        [~, vals_locs, ~, vals_p] = findpeaks(-signal);
        vals = vals_locs(vals_p/max(vals_p) > threshold);

        % Snap each latency to nearest local peak or valley
        max_snap_dist = 5; % samples
        last_assigned = -inf; % keep track of most recent assignment

        for j = 1:length(sig_inds)
            if mod(j,2)==0  % valleys (N)
                % only consider valleys after the previous peak
                prev_peak = sig_inds(j-1);
                candidate_vals = vals(vals > prev_peak & vals > last_assigned);
                if ~isempty(candidate_vals)
                    [d, ind] = min(abs(sig_inds(j) - candidate_vals));
                    if d <= max_snap_dist
                        sig_inds(j) = candidate_vals(ind);
                    end
                end
            else  % peaks (P)
                % only consider peaks after the last assigned latency
                candidate_pks = pks(pks > last_assigned);
                if ~isempty(candidate_pks)
                    [d, ind] = min(abs(sig_inds(j) - candidate_pks));
                    if d <= max_snap_dist
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

    % Plotting
    figure(counter);
    subplot(length(Conds2Run),1,CondIND);
    time_plot = t_signal*10^3;
    wform_plot = 10^2*signal;
    peaks_plot = 10^2*signal(sig_inds);
    template_plot = 10^2*template;
    hold on
    plot(time_plot,wform_plot,'LineWidth',3,'Color', colors(CondIND,:),'HandleVisibility','off')
    for k = 1:5 % number of waves I-V
        idx = (2*k-1):(2*k);  % indices for pairs: peak + trough
        plot(time_plot(frame_sig(sig_inds(idx))),peaks_plot(idx), 'o','Color', colors(k+4,:),'MarkerFaceColor', colors(k+4,:),'MarkerSize', 8,'LineWidth', 1.5, 'DisplayName', sprintf('Wave %d', k));
    end
    set(gca,'FontSize',25); xlim([0,20]); grid on;
    plot(time_plot(frame_sig),template_plot,'--','LineWidth',3,'color',[0 0 0 0.25],'HandleVisibility','off');
else
    peaks = nan(1,10);
    latencies = nan(1,10);
    % Plotting
    figure(counter);
    subplot(length(Conds2Run),1,CondIND);
    hold on
    plot(t_signal*10^3,signal*10^2,'LineWidth',3,'Color', colors(CondIND,:),'HandleVisibility','off')
end
ylim(ylim_ind);
hold off
if CondIND == 1
    title_str = sprintf('ABR Peaks (DTW) | %s | %s dB SPL | %s ',freq_str,num2str(levels(level_counter)),cell2mat(subject));
    title(title_str,'FontSize', 16,'FontWeight','bold');
    set(gca,'FontSize',25); xlim([0,20]); grid on;
    legend({},'Location','northeast','Orientation','vertical','FontSize',10)
    legend boxon;
end
if CondIND == length(Conds2Run)
    xlabel(x_units, 'FontWeight', 'bold');
end
if CondIND == round(length(Conds2Run)/2)
    ylabel(y_units, 'FontWeight', 'bold');
end
if CondIND ~= length(Conds2Run)
    xticklabels([]);
end
subtitle(sprintf('%s',condition));
grid on;
set(gcf, 'Units', 'Normalized', 'OuterPosition', [0.25, 0.04, 0.5, 0.94]);
end