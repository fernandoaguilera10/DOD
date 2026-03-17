function [peaks,latencies] = findPeaks_dtw(t_signal,signal,template,latencies_template,subject,condition,Conds2Run,CondIND,levels,counter,level_counter,colors,shapes,ylim_ind,freq_str,idx_abr,idx_template)
global vertical_spacing
tolerance = 5;
num_waves = 5;
num_peaks = num_waves*2;
waves_legend = ["I","II","III-IV","V","V"];
snap_to_localminmax = 1;    % apply time constraint to select peaks/throughs chronologically (t1 < t2) and amplitude constraint to differntiate peaks/throughs
y_units = 'Amplitude (\muV)';
x_units = 'Time (ms)';
frame_sig = 1:length(signal);
if ~isempty(template) && all(~isnan(template))
    norm_factor_signal = max(signal)-min(signal);
    norm_factor_template = max(template)-min(template);
    signal_norm = signal/norm_factor_signal;  % derivative of normalized signal
    template_norm = template/norm_factor_template;    % derivative of normalized template
    [~, xi, yi] = dtw(template_norm,signal_norm,tolerance);
    for i = 1:size(latencies_template,1)
        warp_ind_temp = find(xi==latencies_template(i,3));
        warp_ind(i) = round(mean(warp_ind_temp));
    end
    sig_inds = nan(1,length(latencies_template));
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
<<<<<<< HEAD

=======
>>>>>>> d372f747d13519d7cfec4fd31e2a9ef1572b4812
        [~, vals_locs, ~, vals_p] = findpeaks(-signal_col);
        vals = vals_locs(vals_p/max(vals_p) > threshold);

        % 2. Define Latency Windows (Adjusted for NEL delay)
        % Expected latency windows in ms: [min_ms, max_ms]
        ms_windows = [ 1.4, 2.4;   % Wave I
            2.4, 3.5;   % Wave II
            3.4, 4.6;   % Wave III
            4.0, 5.2;   % Wave IV
            5.1, 6.5];  % Wave V
        ms_windows = ms_windows + 5 + (level_counter - 1) * 0.08; % 5ms delay for NEL and 0.075 ms delay per le
        idx_windows = round(ms_windows * 1e-3 * fs);
        
        % 3. Run DTW Snapping Logic
        max_snap_dist = 3; % samples - search radius around DTW index
        last_assigned = -inf;
        last_peak_amp = inf;
        sig_inds_raw = sig_inds;
        sig_inds_constrained = sig_inds;
<<<<<<< HEAD

=======
>>>>>>> d372f747d13519d7cfec4fd31e2a9ef1572b4812
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
<<<<<<< HEAD

=======
>>>>>>> d372f747d13519d7cfec4fd31e2a9ef1572b4812
                if ~isempty(candidate_pks) && ~isnan(sig_inds_constrained(j))
                    % Priority 1: highest amplitude within snap radius of DTW index
                    near_mask = abs(candidate_pks - sig_inds_constrained(j)) <= max_snap_dist;
                    near_candidates = candidate_pks(near_mask);
<<<<<<< HEAD

=======
>>>>>>> d372f747d13519d7cfec4fd31e2a9ef1572b4812
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
        
<<<<<<< HEAD

=======
>>>>>>> d372f747d13519d7cfec4fd31e2a9ef1572b4812
        % Prepare manual editing variables and plotting flags
        sig_inds_manual = sig_inds_constrained; % initialize manual copy
        plot_constrained = true; % assume plotting enabled for manual edit UI
        if plot_constrained
            done_editing = false;
<<<<<<< HEAD
            fprintf('Interactive edit: left-click to select a peak/trough to edit. Right-click or Enter to finish.\n');
=======
>>>>>>> d372f747d13519d7cfec4fd31e2a9ef1572b4812
            % Precompute indices displayed (idx_sig_inds expected to exist in context)
            if ~exist('idx_sig_inds','var') || isempty(idx_sig_inds)
                % fallback: display all indices
                idx_sig_inds = 1:length(sig_inds_constrained);
            end
<<<<<<< HEAD

            while ~done_editing
                figure(999); clf;
                plot(t_signal,signal,'k','LineWidth',1.5,'HandleVisibility','off'); hold on;
                % DTW raw: open marker (use sig_inds_raw)
                plot(t_signal(sig_inds_raw(idx_sig_inds)), signal(sig_inds_raw(idx_sig_inds)), '^k', 'MarkerSize',8, 'LineWidth',1,'HandleVisibility','off');
                % DTW constrained: filled green markers
                plot(t_signal(sig_inds_constrained(idx_sig_inds)), signal(sig_inds_constrained(idx_sig_inds)), '^k', 'MarkerSize',8, 'LineWidth',1.5, 'MarkerFaceColor','g');
=======
            while ~done_editing
                figure(999); clf;
                set(gcf, 'Units', 'Normalized', 'OuterPosition', [0.55, 0.03, 0.4, 0.9]);
                plot(10^3*t_signal,10^2*signal,'k','LineWidth',1.5,'HandleVisibility','off'); hold on;
                % DTW raw: open marker (use sig_inds_raw)
                plot(10^3*t_signal(sig_inds_raw(idx_sig_inds)), 10^2*signal(sig_inds_raw(idx_sig_inds)), '^k', 'MarkerSize',8, 'LineWidth',1,'HandleVisibility','off');
                % DTW constrained: filled green markers
                plot(10^3*t_signal(sig_inds_constrained(idx_sig_inds)), 10^2*signal(sig_inds_constrained(idx_sig_inds)), '^k', 'MarkerSize',8, 'LineWidth',1.5, 'MarkerFaceColor','g');
>>>>>>> d372f747d13519d7cfec4fd31e2a9ef1572b4812
                % Manual edits: red filled squares for entries that differ from constrained
                manual_changed = sig_inds_manual ~= sig_inds_constrained;
                if any(manual_changed(idx_sig_inds))
                    changed_idx = idx_sig_inds(manual_changed(idx_sig_inds));
<<<<<<< HEAD
                    plot(t_signal(sig_inds_manual(changed_idx)), signal(sig_inds_manual(changed_idx)), '^k', 'MarkerSize',8, 'LineWidth',1.5, 'MarkerFaceColor','r');
                end
                xlim([0,0.02]);
                title(sprintf('%s @ %d dB SPL - Manual Edit Mode',freq_str,levels(level_counter)));
                set(gca,'FontSize',12);
=======
                    plot(10^3*t_signal(sig_inds_manual(changed_idx)), 10^2*signal(sig_inds_manual(changed_idx)), '^k', 'MarkerSize',8, 'LineWidth',1.5, 'MarkerFaceColor','r');
                end
                title(sprintf('%s @ %d dB SPL - Manual Edit Mode',freq_str,levels(level_counter)));
                set(gca,'FontSize',12);
                xlabel(x_units, 'FontWeight', 'bold','FontSize',20);
                ylabel(y_units, 'FontWeight', 'bold','FontSize',20);
                xlim([0,20]); grid on;
>>>>>>> d372f747d13519d7cfec4fd31e2a9ef1572b4812
                legend({'DTW Peak','Manual Peak'}, 'Location','northeast'); legend box off;
                set(gcf, 'Units', 'Normalized', 'OuterPosition', [1-0.025-0.4, 0.25, 0.4, 0.65]);
                drawnow;

                % Ask user to click a point or finish
<<<<<<< HEAD
                uiwait(msgbox({'Left-click peak to edit. Right-click or press Enter to skip.'}, 'Select to Edit','modal'));
                figure(999);
=======
                % Prompt the user once at the beginning of the interactive loop
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
>>>>>>> d372f747d13519d7cfec4fd31e2a9ef1572b4812
                [x_old, ~, button] = ginput(1);
                if isempty(button) || button==3
                    break; % finish editing
                end

                % Map click time to nearest sample index on t_signal
                [~, idx_time] = min(abs(t_signal - x_old));

                % Build list of editable slots: those in idx_sig_inds that are not NaN in sig_inds_manual
                editable_positions = ~isnan(sig_inds_manual);
                if isempty(editable_positions)
                    uiwait(msgbox('No editable peaks/valleys available (all NaN).','No Edit','modal'));
                    continue;
                end

                % For selection convenience, compute time distance from click to each editable slot's current assigned sample
                [~, rel_editable] = min(abs(sig_inds_manual - idx_time));
                % Map back to index within sig_inds arrays
                if editable_positions(rel_editable) ~= 0
                    sel_idx_in_sig_inds = rel_editable;
                end

                % Highlight selected slot
                figure(999);
<<<<<<< HEAD
                hsel = plot(t_signal(sig_inds_manual(sel_idx_in_sig_inds)), signal(sig_inds_manual(sel_idx_in_sig_inds)), '^k', 'MarkerSize',8, 'LineWidth',1.5,'MarkerFaceColor','r');
=======
                hsel = plot(10^3*t_signal(sig_inds_manual(sel_idx_in_sig_inds)), 10^2*signal(sig_inds_manual(sel_idx_in_sig_inds)), '^k', 'MarkerSize',8, 'LineWidth',1.5,'MarkerFaceColor','r');
>>>>>>> d372f747d13519d7cfec4fd31e2a9ef1572b4812
                drawnow;
                if mod(sel_idx_in_sig_inds,2)==1
                    pt_type = 'Peak';
                else
                    pt_type = 'Trough';

                end
                title(sprintf('%s @ %d dB SPL - Editing Wave %d (%s)',freq_str, levels(level_counter), ceil(sel_idx_in_sig_inds/2), pt_type));
                legend({'DTW Peak','Manual Peak'}, 'Location','northeast'); legend box off;
                set(gcf, 'Units', 'Normalized', 'OuterPosition', [1-0.025-0.4, 0.25, 0.4, 0.65]);
                % Now allow user to pick a new point: loop until they accept or cancel
                editing_slot_done = false;
                while ~editing_slot_done
                    figure(999);
                    [x_new, ~, btn2] = ginput(1);
                    if isempty(btn2) || btn2==3
                        % cancel this edit, revert highlight and exit inner loop
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

                    % Re-plot to show tentative change (red square)
                    figure(999);
                    % refresh plots
                    clf;
<<<<<<< HEAD
                    plot(t_signal,signal,'k','LineWidth',1.5,'HandleVisibility','off'); hold on;
                    manual_changed = sig_inds_manual ~= sig_inds_constrained & ~isnan(sig_inds_manual);
                    if any(manual_changed(idx_sig_inds))
                        changed_idx = find(manual_changed == 1);
                        plot(t_signal(sig_inds_manual(changed_idx)), signal(sig_inds_manual(changed_idx)), '^k', 'MarkerSize',8, 'LineWidth',1.5, 'MarkerFaceColor','g');
                    end
                    % Highlight current edited point
                    plot(t_signal(sig_inds_constrained(sel_idx_in_sig_inds)), signal(sig_inds_constrained(sel_idx_in_sig_inds)), '^k', 'MarkerSize',8, 'LineWidth',1.5, 'MarkerFaceColor','r');
                    xlim([0,0.02]);
=======
                    plot(10^3*t_signal,10^2*signal,'k','LineWidth',1.5,'HandleVisibility','off'); hold on;
                    manual_changed = sig_inds_manual ~= sig_inds_constrained & ~isnan(sig_inds_manual);
                    if any(manual_changed(idx_sig_inds))
                        changed_idx = find(manual_changed == 1);
                        plot(10^3*t_signal(sig_inds_manual(changed_idx)), 10^2*signal(sig_inds_manual(changed_idx)), '^k', 'MarkerSize',8, 'LineWidth',1.5, 'MarkerFaceColor','g');
                    end
                    % Highlight current edited point
                    plot(10^3*t_signal(sig_inds_constrained(sel_idx_in_sig_inds)), 10^2*signal(sig_inds_constrained(sel_idx_in_sig_inds)), '^k', 'MarkerSize',8, 'LineWidth',1.5, 'MarkerFaceColor','r');
                    xlim([0,20]);
>>>>>>> d372f747d13519d7cfec4fd31e2a9ef1572b4812
                    if mod(sel_idx_in_sig_inds,2)==1
                        pt_type = 'Peak';
                    else
                        pt_type = 'Trough';

                    end
                    title(sprintf('%s @ %d dB SPL - Editing Wave %d (%s)',freq_str, levels(level_counter), ceil(sel_idx_in_sig_inds/2), pt_type));
                    drawnow;
                    legend({'DTW Peak','Manual Peak'}, 'Location','northeast'); legend box off;
                    set(gcf, 'Units', 'Normalized', 'OuterPosition', [1-0.025-0.4, 0.25, 0.4, 0.65]);
                    % Ask user to accept or redo
                    choice = questdlg('Accept this selection for the chosen slot?', 'Confirm Selection', 'Accept','Redo','Cancel','Accept');
                    switch choice
                        case 'Accept'
                            editing_slot_done = true;
                            if isvalid(hsel), delete(hsel); end
                            clf;
<<<<<<< HEAD
                            plot(t_signal,signal,'k','LineWidth',1.5,'HandleVisibility','off'); hold on;
                            plot(t_signal(sig_inds_raw(idx_sig_inds)), signal(sig_inds_raw(idx_sig_inds)), '^k', 'MarkerSize',8, 'LineWidth',1,'HandleVisibility','off');
                            plot(t_signal(sig_inds_manual(idx_sig_inds)), signal(sig_inds_manual(idx_sig_inds)), '^k', 'MarkerSize',8, 'LineWidth',1.5, 'MarkerFaceColor','g');
                            xlim([0,0.02]);
=======
                            plot(10^3*t_signal,10^2*signal,'k','LineWidth',1.5,'HandleVisibility','off'); hold on;
                            plot(10^3*t_signal(sig_inds_raw(idx_sig_inds)), 10^2*signal(sig_inds_raw(idx_sig_inds)), '^k', 'MarkerSize',8, 'LineWidth',1,'HandleVisibility','off');
                            plot(10^3*t_signal(sig_inds_manual(idx_sig_inds)), 10^2*signal(sig_inds_manual(idx_sig_inds)), '^k', 'MarkerSize',8, 'LineWidth',1.5, 'MarkerFaceColor','g');
                            xlim([0,20]);
>>>>>>> d372f747d13519d7cfec4fd31e2a9ef1572b4812
                            if mod(sel_idx_in_sig_inds,2)==1
                                pt_type = 'Peak';
                            else
                                pt_type = 'Trough';
               
                            end
                            title(sprintf('%s @ %d dB SPL - Editing Wave %d (%s)',freq_str, levels(level_counter), ceil(sel_idx_in_sig_inds/2), pt_type));
                            drawnow;
                            legend({'DTW Peak','Manual Peak'}, 'Location','northeast'); legend box off;
                            set(gcf, 'Units', 'Normalized', 'OuterPosition', [1-0.025-0.4, 0.25, 0.4, 0.65]);
                            sig_inds_constrained = sig_inds_manual;
                        case 'Redo'
                            % revert to old and continue editing (or keep old until user picks new)
                            sig_inds_manual(sel_idx_in_sig_inds) = old_idx;
                            % re-highlight original
                            if isvalid(hsel), delete(hsel); end
<<<<<<< HEAD
                            hsel = plot(t_signal(sig_inds_manual(sel_idx_in_sig_inds)), signal(sig_inds_manual(sel_idx_in_sig_inds)), '^k', 'MarkerSize',8, 'LineWidth',1.5, 'MarkerFaceColor','r');
=======
                            hsel = plot(10^3*t_signal(sig_inds_manual(sel_idx_in_sig_inds)), 10^2*signal(sig_inds_manual(sel_idx_in_sig_inds)), '^k', 'MarkerSize',12, 'LineWidth',2, 'MarkerFaceColor','y');
>>>>>>> d372f747d13519d7cfec4fd31e2a9ef1572b4812
                            drawnow;
                            % continue loop to pick another point
                        case 'Cancel'
                            % revert change and exit editing for this slot
                            sig_inds_manual(sel_idx_in_sig_inds) = old_idx;
                            if isvalid(hsel), delete(hsel); end
                            editing_slot_done = true;
                    end                    
                end % while ~editing_slot_done
<<<<<<< HEAD

                % After finishing editing one slot, ask whether to continue editing others
                cont = questdlg('Continue editing other peaks/valleys?', 'Continue?', 'Yes','No','Yes');
                if strcmp(cont,'No')
                    done_editing = true;
                end
=======
>>>>>>> d372f747d13519d7cfec4fd31e2a9ef1572b4812
            end % while ~done_editing

            % After editing, ensure sig_inds_manual maintains monotonic ordering and validity
            % Replace any NaNs or invalid indices with constrained values
            invalid_mask = isnan(sig_inds_manual) | sig_inds_manual < 1 | sig_inds_manual > length(signal);
            sig_inds_manual(invalid_mask) = sig_inds_constrained(invalid_mask);
        end

        sig_inds = sig_inds_manual;
        peaks = nan(length(idx_sig_inds),1);
        latencies = nan(length(idx_sig_inds),1);
        peaks_temp = signal(sig_inds(idx_sig_inds))*10^2;
        latencies_temp= t_signal(sig_inds(idx_sig_inds))*10^3;
        peaks(idx_sig_inds) = peaks_temp;
        latencies(idx_sig_inds) = latencies_temp;

        % Plotting
        time_plot = t_signal*10^3;
        wform_plot = 10^2*signal;
        peaks_plot = 10^2*signal(sig_inds(idx_sig_inds));
        template_plot = 10^2*template;
        template_peaks = 10^2*latencies_template(:,2);
        full_peaks_plot = nan(size(template_peaks));
        full_peaks_plot(idx_sig_inds) = peaks_plot;
        subplot_idx = (CondIND-1)*length(levels) + level_counter;
        figure(counter);
        if level_counter == 1
            vertical_spacing = 1.2*range(wform_plot);
        end
        offset = -(level_counter - 1) * vertical_spacing;
        hold on
        for k = 1:num_waves % number of waves I-V
            idx = (2*k-1):(2*k);  % indices for pairs: peak + trough
            if level_counter == 1
                show_in_legend = 'on';
            else
                show_in_legend = 'off';
            end
            if ~any(isnan(latencies_template(idx,3)))
                %plot(time_plot(latencies_template(idx,3)),template_peaks(idx)+offset, shapes(k),'Color', [0.60,0.60,0.60],'MarkerFaceColor', [0.60,0.60,0.60],'MarkerSize', 12,'LineWidth', 1.5,'HandleVisibility','off'); % template
            end
            if ~any(isnan(sig_inds(idx))) && ~any(isnan(full_peaks_plot(idx)))
                %plot(time_plot(frame_sig(sig_inds_raw(idx))),10^2*signal(sig_inds_raw(idx))+offset, shapes(k),'Color', colors(k+4,:),'MarkerSize', 12,'LineWidth', 1.5,'HandleVisibility', 'off'); % ABR
                plot(time_plot(frame_sig(sig_inds(idx))),full_peaks_plot(idx)+offset, shapes(k),'Color', colors(k+4,:),'MarkerFaceColor', colors(k+4,:),'MarkerSize', 12,'LineWidth', 1.5,'HandleVisibility', show_in_legend); % ABR
            end
            legend_string{k} = sprintf('Wave %s', waves_legend(k));
        end
<<<<<<< HEAD
        plot(time_plot(frame_sig),template_plot+offset,'--','LineWidth',3,'color',[0 0 0 0.25],'HandleVisibility','off');
=======
        %plot(time_plot(frame_sig),template_plot+offset,'--','LineWidth',3,'color',[0 0 0 0.25],'HandleVisibility','off');
>>>>>>> d372f747d13519d7cfec4fd31e2a9ef1572b4812
        plot(time_plot,wform_plot+offset,'LineWidth',3,'Color', [colors(CondIND,:),0.50],'HandleVisibility','off');
        bar_height = 1; % Set this to a standard amplitude for your experiment
        scale_x = 1;   % Position
        if level_counter == 1
            text(scale_x - 0.5, offset + 1.2*bar_height, sprintf('%g \\muV', bar_height), ...
                'Rotation', 0, 'HorizontalAlignment', 'center', 'FontSize', 12, 'FontWeight', 'bold');
        end
        plot([scale_x, scale_x], [offset, offset + bar_height], 'k', 'LineWidth', 2.5, 'HandleVisibility', 'off');
        text(-0.05*max(time_plot),offset, sprintf('%d dB', levels(level_counter)), 'FontSize', 18, 'HorizontalAlignment', 'left','FontWeight','bold');
    else
        peaks = nan(1,num_peaks);
        latencies = nan(1,num_peaks);
        plot(t_signal*10^3,signal*10^2,'LineWidth',3,'Color', colors(CondIND,:),'HandleVisibility','off')
    end
<<<<<<< HEAD
    set(gcf, 'Units', 'Normalized', 'OuterPosition', [0.025, 0.25, 0.5, 0.65]);
=======
    set(gcf, 'Units', 'Normalized', 'OuterPosition', [0.01, 0.03, 0.5, 0.9]);
>>>>>>> d372f747d13519d7cfec4fd31e2a9ef1572b4812
    ticks = 0:1:round(max(t_signal*10^3), -1);
    xticks(ticks);
    labels = string(ticks);         % Convert all numbers to strings
    labels(mod(ticks, 2) ~= 0) = ""; % Replace odd numbers with an empty string
    xticklabels(labels); xtickangle(0);
    set(gca,'YColor','none');
    ylim(vertical_spacing*[-1*length(levels),1.2]);
    hold off
    title_str = sprintf('%s | %s ',cell2mat(subject), condition);
    title(title_str,'FontSize', 16,'FontWeight','bold');
    subtitle(sprintf('%s',freq_str));
    if level_counter == 1
        legend(legend_string,'Location','northeast','Orientation','horizontal','FontSize',15)
        legend box off;
    end
<<<<<<< HEAD
    set(gca,'FontSize',25); grid on;
=======
    set(gca,'FontSize',15); grid on;
>>>>>>> d372f747d13519d7cfec4fd31e2a9ef1572b4812
    xlabel(x_units, 'FontWeight', 'bold','FontSize',20);
    ylabel(y_units, 'FontWeight', 'bold','FontSize',20);
    xlim([0,20])
end