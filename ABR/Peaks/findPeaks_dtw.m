function [peaks,latencies] = findPeaks_dtw(t_signal,signal,template,latencies_template,delay,subject,condition,Conds2Run,CondIND,levels,counter,level_counter,colors,shapes,ylim_ind,freq_str,idx_abr,idx_template)
global vertical_spacing
tolerance = 5;
num_waves = 5;
waves_legend = ["I","II","III-IV","V","V"];
snap_to_localminmax = 1;    % apply time constraint to select peaks/throughs chronologically (t1 < t2) and amplitude constraint to differntiate peaks/throughs
y_units = 'Amplitude (\muV)';
x_units = 'Time (ms)';
t_signal = t_signal*10^3; % convert to ms
signal = signal*10^2; % converto to microV
delay = delay*10^3; % convert to ms
%t_signal = t_signal-delay; % shift to account for NEL delay

if ~isempty(template) && all(~isnan(template))
    signal_norm = signal/range(signal);  % normalized signal
    template_norm = template/range(template);    % normalized template
    [~, xi, yi] = dtw(template_norm,signal_norm,tolerance);
    for i = 1:size(latencies_template,1)
        warp_ind_temp = find(xi==latencies_template(i,3));
        warp_ind(i) = round(mean(warp_ind_temp));
    end
    sig_inds = nan(1,length(latencies_template));
    peaks = nan(size(sig_inds));
    latencies = nan(size(sig_inds));
    idx_sig_inds = ~isnan(warp_ind);
    sig_inds(idx_sig_inds) = yi(warp_ind(idx_sig_inds));

    % DTW Constraints
    plot_constrained = 1;
    if snap_to_localminmax

        % 1. Setup Signal and Basic Findpeaks
        signal_col = signal(:); % Force to column for findpeaks
        fs = 1 / (t_signal(2) - t_signal(1)); % Sampling frequency

        % Find all potential peaks (P) and valleys (N)
        [~, pks_locs, ~, peaks_p] = findpeaks(signal_col);
        threshold = 0.15;
        pks = pks_locs(peaks_p/max(peaks_p) > threshold);
        [~, vals_locs, ~, vals_p] = findpeaks(-signal_col);
        vals = vals_locs(vals_p/max(vals_p) > threshold);

        % 2. Define Latency Windows (Adjusted for NEL delay)
        % Expected latency windows in ms: [min_ms, max_ms]
        ms_windows = [ 1.4, 2.4;   % Wave I
            2.4, 3.5;   % Wave II
            3.4, 4.6;   % Wave III
            4.0, 5.2;   % Wave IV
            5.1, 6.5];  % Wave V
        %ms_windows = ms_windows + delay + (level_counter - 1) * 0.08; % account for NEL delay and 0.08 ms delay as level decreases
        ms_windows = ms_windows + (level_counter - 1) * 0.08; % account for NEL delay and 0.08 ms delay as level decreases
        idx_windows = round(ms_windows * 1e-3 * fs);

        % 3. Run DTW Snapping Logic
        max_snap_dist = 3; % samples - search radius around DTW index
        last_assigned = -inf;
        last_peak_amp = inf;
        sig_inds_raw = sig_inds;
        sig_inds_constrained = sig_inds;

        for j = 1:length(sig_inds_constrained)
            wave_num = ceil(j/2);
            win_min = idx_windows(wave_num, 1);
            win_max = idx_windows(wave_num, 2);

            if mod(j,2) == 0  % Valleys (Even indices)
                candidate_vals = vals(vals > last_assigned & vals >= win_min & vals <= win_max);
                candidate_vals = candidate_vals(signal_col(candidate_vals) < last_peak_amp);

                if ~isempty(candidate_vals) && ~isnan(sig_inds_constrained(j))
                    % Priority 1: highest amplitude within snap radius of DTW index
                    near_mask = abs(candidate_vals - sig_inds_constrained(j)) <= max_snap_dist;
                    near_candidates = candidate_vals(near_mask);

                    if ~isempty(near_candidates)
                        % Pick lowest amplitude valley among nearby candidates
                        [~, ind] = min(signal_col(near_candidates));
                        sig_inds_constrained(j) = near_candidates(ind);
                    else
                        % Fallback: pick lowest amplitude valley in full window
                        [~, ind] = min(signal_col(candidate_vals));
                        sig_inds_constrained(j) = candidate_vals(ind);
                    end
                end

            else  % Peaks (Odd indices)
                candidate_pks = pks(pks > last_assigned & pks >= win_min & pks <= win_max);

                if ~isempty(candidate_pks) && ~isnan(sig_inds_constrained(j))
                    % Priority 1: highest amplitude within snap radius of DTW index
                    near_mask = abs(candidate_pks - sig_inds_constrained(j)) <= max_snap_dist;
                    near_candidates = candidate_pks(near_mask);

                    if ~isempty(near_candidates)
                        % Pick highest amplitude peak among nearby candidates
                        [~, ind] = max(signal_col(near_candidates));
                        sig_inds_constrained(j) = near_candidates(ind);
                    else
                        % Fallback: pick highest amplitude peak in full window
                        [~, ind] = max(signal_col(candidate_pks));
                        sig_inds_constrained(j) = candidate_pks(ind);
                    end
                    last_peak_amp = signal_col(sig_inds_constrained(j));
                end
            end

            if ~isnan(sig_inds_constrained(j))
                last_assigned = sig_inds_constrained(j);
            end
        end

        % Prepare manual editing variables and plotting flags
        sig_inds_manual = sig_inds_constrained; % initialize manual copy
        plot_constrained = true; % assume plotting enabled for manual edit UI
        if plot_constrained
            done_editing = false;

            % Precompute indices displayed (idx_sig_inds expected to exist in context)
            if ~exist('idx_sig_inds','var') || isempty(idx_sig_inds)
                % fallback: display all indices
                idx_sig_inds = 1:length(sig_inds_constrained);
            end

            while ~done_editing
                figure(999); clf;
                set(gcf, 'Units', 'Normalized', 'OuterPosition', [1-0.025-0.4, 0.15, 0.4, 0.65]);
                plot(t_signal,signal,'k','LineWidth',1.5,'HandleVisibility','off'); hold on;
                % DTW constrained: filled green markers
                plot(t_signal(sig_inds_constrained(idx_sig_inds)), signal(sig_inds_constrained(idx_sig_inds)), '^k', 'MarkerSize',8, 'LineWidth',1.5, 'MarkerFaceColor','g');
                % Manual edits: red filled squares for entries that differ from constrained
                manual_changed = sig_inds_manual ~= sig_inds_constrained;
                if any(manual_changed(idx_sig_inds))
                    changed_idx = idx_sig_inds(manual_changed(idx_sig_inds));
                    plot(t_signal(sig_inds_manual(changed_idx)), signal(sig_inds_manual(changed_idx)), '^k', 'MarkerSize',8, 'LineWidth',1.5, 'MarkerFaceColor','r');
                end
                set(gca,'FontSize',12);
                xlabel(x_units, 'FontWeight', 'bold','FontSize',20);
                ylabel(y_units, 'FontWeight', 'bold','FontSize',20);
                xlim([0,20]); grid on;
                % Ask user to click a point or finish
                if  level_counter == 1 && CondIND == 1
                    uiwait(msgbox({...
                        'For each level, use the window on the RIGHT to manually overwrite automatically selected peaks and troughs for waves I, II, III–IV, and V.'; ...
                        ''; ...
                        'Instructions:'; ...
                        '1. Left-click a peak/trough to edit its position (RED)'; ...
                        '2. Left-click a NEW peak/trough to change its position (GREEN)'; ...
                        '3. Right-click or press Enter to finish editing'; ...
                        ''; ...
                        'Note: A window on the LEFT will show ABR waveforms and peaks/throughs across all levels.'}, ...
                        'Manual Edit: Select Peaks/Troughs', 'modal'));
                end
                figure(999);
                title(sprintf('%s @ %d dB SPL - Select Peak/Trough to Edit',freq_str,levels(level_counter)));
                drawnow;
                figure(999); [x_old, ~, button_old] = ginput(1);
                if isempty(button_old) || button_old==3
                    break; % finish editing
                end

                % Map click time to nearest sample index on t_signal
                [~, idx_time] = min(abs(t_signal - x_old));

                % Build list of editable slots: those in idx_sig_inds that are not NaN in sig_inds_manual
                editable_positions = ~isnan(sig_inds_manual);
                if isempty(editable_positions)
                    uiwait(msgbox('No editable peaks/troughs available.','No Edit','modal'));
                    continue;
                end

                % Find closest data point from selection
                [~, rel_editable] = min(abs(sig_inds_manual - idx_time));
                if editable_positions(rel_editable) ~= 0
                    sel_idx_in_sig_inds = rel_editable;
                end

                % Highlight selected slot
                figure(999);
                hsel = plot(t_signal(sig_inds_manual(sel_idx_in_sig_inds)), signal(sig_inds_manual(sel_idx_in_sig_inds)), '^k', 'MarkerSize',8, 'LineWidth',1.5,'MarkerFaceColor','r');
                if mod(sel_idx_in_sig_inds,2)==1
                    pt_type = 'Peak';
                else
                    pt_type = 'Trough';

                end
                % Editing loop: allow user to manually select peak/trough
                editing_slot_done = false;
                while ~editing_slot_done
                    figure(999);
                    title(sprintf('%s @ %d dB SPL - Select NEW Wave %d (%s)',freq_str, levels(level_counter), ceil(sel_idx_in_sig_inds/2), pt_type));
                    drawnow;
                    figure(999); [x_new, ~, button_new] = ginput(1);
                    if isempty(button_new) || button_new==3
                        if isvalid(hsel), delete(hsel); end
                        editing_slot_done = true;
                        break;
                    end

                    % Map new click to nearest sample index
                    [~, new_idx_time] = min(abs(t_signal - x_new));
                    [~, rel_editable] = min(abs(sig_inds_manual - idx_time));
                    % Map back to index within sig_inds arrays
                    if editable_positions(rel_editable) ~= 0
                        sel_idx_in_sig_inds = rel_editable;
                        chosen_idx = new_idx_time;
                    end

                    % Update manual index for that slot
                    old_idx = sig_inds_manual(sel_idx_in_sig_inds);
                    sig_inds_manual(sel_idx_in_sig_inds) = chosen_idx;

                    % Refresh plot
                    figure(999);
                    clf;
                    plot(t_signal,signal,'k','LineWidth',1.5,'HandleVisibility','off'); hold on;
                    set(gca,'FontSize',12);
                    xlabel(x_units, 'FontWeight', 'bold','FontSize',20);
                    ylabel(y_units, 'FontWeight', 'bold','FontSize',20);
                    xlim([0,20]); grid on;

                    manual_changed = sig_inds_manual ~= sig_inds_constrained & ~isnan(sig_inds_manual);
                    if any(manual_changed(idx_sig_inds))
                        changed_idx = find(manual_changed == 1);
                        plot(t_signal(sig_inds_manual(changed_idx)), signal(sig_inds_manual(changed_idx)), '^k', 'MarkerSize',8, 'LineWidth',1.5, 'MarkerFaceColor','g','DisplayName',sprintf('New %s',pt_type));
                    end
                    % Highlight current edited point
                    plot(t_signal(sig_inds_constrained(sel_idx_in_sig_inds)), signal(sig_inds_constrained(sel_idx_in_sig_inds)), '^k', 'MarkerSize',8, 'LineWidth',1.5, 'MarkerFaceColor','r','DisplayName',sprintf('Previous %s',pt_type));
                    if mod(sel_idx_in_sig_inds,2)==1
                        pt_type = 'Peak';
                    else
                        pt_type = 'Trough';

                    end
                    title(sprintf('%s @ %d dB SPL - Editing Wave %d (%s)',freq_str, levels(level_counter), ceil(sel_idx_in_sig_inds/2), pt_type));
                    legend('Location','northeast'); legend box off;

                    % Ask user to accept or redo
                    choice = questdlg(sprintf('Do you accept new selection for Wave %d (%s)?',ceil(sel_idx_in_sig_inds/2),pt_type), 'Confirm Selection', 'Accept','Redo','Cancel','Accept');
                    switch choice
                        case 'Accept'
                            editing_slot_done = true;
                            if isvalid(hsel), delete(hsel); end
                            clf;
                            plot(t_signal,signal,'k','LineWidth',1.5,'HandleVisibility','off'); hold on;
                            plot(t_signal(sig_inds_manual(idx_sig_inds)), signal(sig_inds_manual(idx_sig_inds)), '^k', 'MarkerSize',8, 'LineWidth',1.5, 'MarkerFaceColor','g');
                            title(sprintf('%s @ %d dB SPL - Current Peaks',freq_str, levels(level_counter)));
                            set(gca,'FontSize',12);
                            xlabel(x_units, 'FontWeight', 'bold','FontSize',20);
                            ylabel(y_units, 'FontWeight', 'bold','FontSize',20);
                            xlim([0,20]); grid on;
                            sig_inds_constrained = sig_inds_manual;
                        case 'Redo'
                            % revert to old and continue editing (or keep old until user picks new)
                            sig_inds_manual(sel_idx_in_sig_inds) = old_idx;
                            % re-highlight original
                            if isvalid(hsel), delete(hsel); end
                            hsel = plot(t_signal(sig_inds_manual(sel_idx_in_sig_inds)), signal(sig_inds_manual(sel_idx_in_sig_inds)), '^k', 'MarkerSize',8, 'LineWidth',1.5, 'MarkerFaceColor','r');
                            editing_slot_done = false;
                        case 'Cancel'
                            % revert change and exit editing for this slot
                            sig_inds_manual(sel_idx_in_sig_inds) = old_idx;
                            if isvalid(hsel), delete(hsel); end
                            editing_slot_done = true;
                    end
                end % while ~editing_slot_done
                % After editing, ensure sig_inds_manual maintains monotonic ordering and validity
                % Replace any NaNs or invalid indices with constrained values
                invalid_mask = isnan(sig_inds_manual) | sig_inds_manual < 1 | sig_inds_manual > length(signal);
                sig_inds_manual(invalid_mask) = sig_inds_constrained(invalid_mask);
            end % while ~done_editing

            % Final Selection
            sig_inds = sig_inds_manual;
            peaks(idx_sig_inds) = signal(sig_inds(idx_sig_inds));
            latencies(idx_sig_inds) = t_signal(sig_inds(idx_sig_inds));

            % Plotting selected peaks/troughs
            
            if level_counter == 1
                vertical_spacing = 1.2*range(signal);
                offset = -(level_counter-1) * vertical_spacing;
                figure(counter); hold on
                set(gcf, 'Units', 'Normalized', 'OuterPosition', [0.01, 0.03, 0.5, 0.9]);
                ticks = 0:1:round(max(t_signal), -1);
                xticks(ticks);
                labels = string(ticks);         % Convert all numbers to strings
                labels(mod(ticks, 2) ~= 0) = ""; % Replace odd numbers with an empty string
                xticklabels(labels); xtickangle(0);
                ylim(vertical_spacing*[-1*length(levels),1.2]);
                hold off
                title_str = sprintf('%s | %s ',cell2mat(subject), condition);
                title(title_str,'FontSize', 16,'FontWeight','bold');
                subtitle(sprintf('%s',freq_str));
                set(gca,'FontSize',15); grid on;
                xlabel(x_units, 'FontWeight', 'bold','FontSize',20);
                ylabel(y_units, 'FontWeight', 'bold','FontSize',20); set(gca,'YColor','none');
                xlim([0,20])
            end
            
            offset = -(level_counter-1) * vertical_spacing;
            figure(counter); hold on;
            for k = 1:num_waves % number of waves I-V
                idx = (2*k-1):(2*k);  % indices for pairs: peak + trough
                if level_counter == 1
                    show_in_legend = 'on';
                else
                    show_in_legend = 'off';
                end
                if ~any(isnan(latencies_template(idx,3)))
                    %plot(t_signal(latencies_template(idx,3)),template_peaks(idx)+offset, shapes(k),'Color', [0.60,0.60,0.60],'MarkerFaceColor', [0.60,0.60,0.60],'MarkerSize', 12,'LineWidth', 1.5,'HandleVisibility','off'); % template
                end
                if ~any(isnan(peaks(idx)))
                    %plot(t_signal(sig_inds_raw(idx)),signal(sig_inds_raw(idx))+offset, shapes(k),'Color', colors(k+4,:),'MarkerSize', 12,'LineWidth', 1.5,'HandleVisibility', 'off'); % ABR
                    plot(latencies(idx),peaks(idx)+offset, shapes(k),'Color', colors(k+4,:),'MarkerFaceColor', colors(k+4,:),'MarkerSize', 12,'LineWidth', 1.5,'HandleVisibility', show_in_legend); % ABR
                end
                legend_string{k} = sprintf('Wave %s', waves_legend(k));
            end
            plot(t_signal,signal+offset,'LineWidth',3,'Color', [colors(CondIND,:),0.50],'HandleVisibility','off');
            bar_height = 1; % Set this to a standard amplitude for your experiment
            scale_x = 1;   % Position
            text(scale_x - 0.65, offset + 1.2*bar_height, sprintf('%g \\muV', bar_height),'Rotation', 0, 'HorizontalAlignment', 'center', 'FontSize', 12, 'FontWeight', 'bold');
            plot([scale_x, scale_x], [offset, offset + bar_height], 'k', 'LineWidth', 2.5, 'HandleVisibility', 'off');
            text(-0.06*max(t_signal),offset, sprintf('%d dB', levels(level_counter)), 'FontSize', 18, 'HorizontalAlignment', 'left','FontWeight','bold');
            legend(legend_string,'Location','northeast','Orientation','horizontal','FontSize',15)
            legend box off;
        end
    end
end