function [peaks,latencies] = findPeaks_dtw(t_signal,signal,template,latencies_template,nel_delay,subject,condition,Conds2Run,CondIND,ChinIND,levels,counter,level_counter,colors,shapes,ylim_ind,freq_str,idx_abr,idx_template,outpath)
global vertical_spacing
tolerance = 5;
num_waves = 5;
waves_legend = ["I","II","III-IV","V","V"];
snap_to_localminmax = 1;    % apply time constraint to select peaks/throughs chronologically (t1 < t2) and amplitude constraint to differntiate peaks/throughs
y_units = 'Amplitude (\muV)';
x_units = 'Time (ms)';
t_signal = t_signal*10^3; % convert to ms
signal = signal*10^2; % converto to microV
if ~isnan(nel_delay.delay_ms(ChinIND,CondIND))
    delay = nel_delay.delay_ms(ChinIND,CondIND); % NEL delay
else
    delay = 0;
end
t_signal = t_signal-delay; % shift to account for NEL delay

n_pts = size(latencies_template, 1);
peaks     = nan(1, n_pts);
latencies = nan(1, n_pts);

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

        % Derivative-based critical points: zero crossings of 1st derivative
        % Peak: + to - transition; Trough: - to + transition
        dsignal = diff(signal_col);
        crit_peaks   = find(dsignal(1:end-1) > 0 & dsignal(2:end) < 0) + 1;
        crit_troughs = find(dsignal(1:end-1) < 0 & dsignal(2:end) > 0) + 1;

        % 2. Define Latency Windows (Adjusted for NEL delay)
        % Load peak memory for adaptive windows
        mem_file = fullfile(fileparts(fileparts(fileparts(outpath))), ['ABR_peak_latency_memory_' freq_str '.mat']);
        min_obs = 3;
        pt_names        = {'P1','N1','P2','N2','P3','N3','P4','N4','P5','N5'};
        pt_edited_names = strcat(pt_names, '_edited');
        if exist(mem_file, 'file')
            tmp = load(mem_file, 'peak_memory');
            peak_memory = tmp.peak_memory;
        else
            peak_memory = struct('log', table('Size',[0,25], ...
                'VariableTypes', [{'string','string','string','double'}, repmat({'double'},1,10), repmat({'logical'},1,10), {'double'}], ...
                'VariableNames', [{'Subject','Condition','Date','Level_dBSPL'}, pt_names, pt_edited_names, {'Pct_edited'}]));
        end

        % Default fixed windows per wave [min_ms, max_ms]
        ms_windows_default = [ 1.4, 2.4;   % Wave I
            2.4, 3.5;   % Wave II
            3.4, 4.6;   % Wave III
            4.0, 5.2;   % Wave IV
            5.1, 6.5];  % Wave V
        ms_windows_default = ms_windows_default + (level_counter - 1) * 0.08;

        % Build per-point 10x2 windows; override with adaptive windows from memory
        pt_ms_windows = nan(10, 2);
        for j = 1:10
            w = ceil(j/2);
            pt_ms_windows(j,:) = ms_windows_default(w,:);  % default
            if height(peak_memory.log) >= min_obs
                obs = peak_memory.log.(pt_names{j});
                obs = obs(~isnan(obs));
                if length(obs) >= min_obs
                    center  = mean(obs);
                    half_w  = max(0.5, 2 * std(obs));
                    pt_ms_windows(j,:) = [center - half_w, center + half_w];
                end
            end
        end
        idx_windows = round((pt_ms_windows + delay) * fs);  % 10x2, raw sample indices

        % 3. Run DTW Snapping Logic
        max_snap_dist = 3; % samples - search radius around DTW index
        last_assigned = -inf;
        last_peak_amp = inf;
        sig_inds_raw = sig_inds;
        sig_inds_constrained = sig_inds;

        for j = 1:length(sig_inds_constrained)
            win_min = idx_windows(j, 1);
            win_max = idx_windows(j, 2);

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
        sig_inds_auto   = sig_inds_constrained; % snapshot of algorithm selection before any manual edits
        sig_inds_manual = sig_inds_constrained; % initialize manual copy
        plot_constrained = true; % assume plotting enabled for manual edit UI
        if plot_constrained
            done_editing = false;

            while ~done_editing
                figure(999); clf;
                set(gcf, 'Units', 'Normalized', 'OuterPosition', [1-0.025-0.4, 0.15, 0.4, 0.65]);
                plot(t_signal,signal,'k','LineWidth',1.5,'HandleVisibility','off'); hold on;
                % DTW constrained: filled green markers (per-wave shape)
                for k = 1:num_waves
                    pair = [(2*k-1), 2*k];
                    valid = pair(idx_sig_inds(pair));
                    if ~isempty(valid)
                        plot(t_signal(sig_inds_constrained(valid)), signal(sig_inds_constrained(valid)), shapes(k), 'Color','k', 'MarkerSize',8, 'LineWidth',1.5, 'MarkerFaceColor','g', 'HandleVisibility','off');
                    end
                end
                % Manual edits: red filled markers for entries that differ from constrained
                manual_changed = sig_inds_manual ~= sig_inds_constrained;
                if any(manual_changed(idx_sig_inds))
                    for k = 1:num_waves
                        pair = [(2*k-1), 2*k];
                        ch = pair(manual_changed(pair) & idx_sig_inds(pair));
                        if ~isempty(ch)
                            plot(t_signal(sig_inds_manual(ch)), signal(sig_inds_manual(ch)), shapes(k), 'Color','k', 'MarkerSize',8, 'LineWidth',1.5, 'MarkerFaceColor','r', 'HandleVisibility','off');
                        end
                    end
                end
                % Legend: one entry per wave shape
                for k = 1:num_waves
                    plot(nan, nan, shapes(k), 'Color','k', 'MarkerSize',8, 'LineWidth',1.5, 'MarkerFaceColor','g', 'DisplayName', sprintf('Wave %s', waves_legend(k)));
                end
                legend('Location','northeast','Orientation','horizontal','FontSize',11); legend box off;
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
                wave_k = ceil(sel_idx_in_sig_inds/2);
                figure(999);
                hsel = plot(t_signal(sig_inds_manual(sel_idx_in_sig_inds)), signal(sig_inds_manual(sel_idx_in_sig_inds)), shapes(wave_k), 'Color','k', 'MarkerSize',8, 'LineWidth',1.5,'MarkerFaceColor','r', 'HandleVisibility','off');
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

                    % Snap click to nearest critical point (1st-derivative zero crossing)
                    [~, new_idx_time] = min(abs(t_signal - x_new));
                    if mod(sel_idx_in_sig_inds, 2) == 1  % Peak slot: + to - derivative
                        if ~isempty(crit_peaks)
                            [~, snap] = min(abs(crit_peaks - new_idx_time));
                            new_idx_time = crit_peaks(snap);
                        end
                    else  % Trough slot: - to + derivative
                        if ~isempty(crit_troughs)
                            [~, snap] = min(abs(crit_troughs - new_idx_time));
                            new_idx_time = crit_troughs(snap);
                        end
                    end
                    [~, rel_editable] = min(abs(sig_inds_manual - idx_time));
                    % Map back to index within sig_inds arrays
                    if editable_positions(rel_editable) ~= 0
                        sel_idx_in_sig_inds = rel_editable;
                        chosen_idx = new_idx_time;
                    end

                    % Update manual index for that slot
                    old_idx = sig_inds_manual(sel_idx_in_sig_inds);
                    sig_inds_manual(sel_idx_in_sig_inds) = chosen_idx;

                    % Refresh plot — zoomed in around new selection to verify peak/trough placement
                    zoom_w = 2; % ms half-width
                    t_sel = t_signal(chosen_idx);
                    figure(999);
                    clf;
                    plot(t_signal,signal,'k','LineWidth',1.5,'HandleVisibility','off'); hold on;
                    set(gca,'FontSize',12);
                    xlabel(x_units, 'FontWeight', 'bold','FontSize',20);
                    ylabel(y_units, 'FontWeight', 'bold','FontSize',20);
                    xlim([t_sel - zoom_w, t_sel + zoom_w]); grid on;

                    manual_changed = sig_inds_manual ~= sig_inds_constrained & ~isnan(sig_inds_manual);
                    if any(manual_changed(idx_sig_inds))
                        changed_idx = find(manual_changed == 1);
                        for j = changed_idx(:)'
                            k = ceil(j/2);
                            plot(t_signal(sig_inds_manual(j)), signal(sig_inds_manual(j)), shapes(k), 'Color','k', 'MarkerSize',8, 'LineWidth',1.5, 'MarkerFaceColor','g', 'DisplayName','New selection');
                        end
                    end
                    % Highlight current edited point
                    plot(t_signal(sig_inds_constrained(sel_idx_in_sig_inds)), signal(sig_inds_constrained(sel_idx_in_sig_inds)), shapes(wave_k), 'Color','k', 'MarkerSize',8, 'LineWidth',1.5, 'MarkerFaceColor','r', 'DisplayName','Previous selection');
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
                            for k = 1:num_waves
                                pair = [(2*k-1), 2*k];
                                valid = pair(idx_sig_inds(pair));
                                if ~isempty(valid)
                                    plot(t_signal(sig_inds_manual(valid)), signal(sig_inds_manual(valid)), shapes(k), 'Color','k', 'MarkerSize',8, 'LineWidth',1.5, 'MarkerFaceColor','g', 'HandleVisibility','off');
                                end
                            end
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
                            hsel = plot(t_signal(sig_inds_manual(sel_idx_in_sig_inds)), signal(sig_inds_manual(sel_idx_in_sig_inds)), shapes(wave_k), 'Color','k', 'MarkerSize',8, 'LineWidth',1.5, 'MarkerFaceColor','r', 'HandleVisibility','off');
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

            % Save confirmed latencies to memory log (table row per waveform)
            new_obs = nan(1, 10);
            for j = 1:10
                if ~isnan(latencies(j))
                    new_obs(j) = latencies(j);
                end
            end
            was_edited   = sig_inds_manual ~= sig_inds_auto;           % 1x10 logical
            n_valid      = sum(idx_sig_inds);                           % number of detected points
            pct_edited   = 100 * sum(was_edited(idx_sig_inds)) / max(n_valid, 1);
            new_row = [table(string(cell2mat(subject)), string(condition), string(datestr(now,'yyyy-mm-dd HH:MM:SS')), levels(level_counter), ...
                'VariableNames', {'Subject','Condition','Date','Level_dBSPL'}), ...
                array2table(new_obs,                   'VariableNames', pt_names), ...
                array2table(was_edited,                'VariableNames', pt_edited_names), ...
                table(pct_edited,                      'VariableNames', {'Pct_edited'})];
            peak_memory.log = [peak_memory.log; new_row];
            save(mem_file, 'peak_memory');

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