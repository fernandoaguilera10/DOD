function [peaks,latencies] = findPeaks_dtw(t_signal,signal,template,latencies_template,nel_delay,subject,condition,Conds2Run,CondIND,ChinIND,levels,counter,level_counter,colors,shapes,ylim_ind,freq_str,idx_abr,idx_template,outpath,peak_ui,wave_sel)
%FINDPEAKS_DTW  DTW-based ABR peak detection with manual override.
%
%  Classic mode (peak_ui=[]):  ginput-based editing in a standalone figure.
%  App mode    (peak_ui=struct): uiwait/uiresume editing embedded in the app.
%
%  wave_sel – 1×5 logical; which waves (I–V) to show/edit (default all true).

% ── Defaults ─────────────────────────────────────────────────────────────
if ~exist('peak_ui','var'), peak_ui  = []; end
if ~exist('wave_sel','var') || isempty(wave_sel), wave_sel = true(1,5); end

% global is used by the classic waterfall only (cross-call level spacing)
global vertical_spacing

tolerance          = 5;
num_waves          = 5;
waves_legend       = ["I","II","III","IV","V"];
snap_to_localminmax = 1;
y_units = 'Amplitude (\muV)';
x_units = 'Time (ms)';
t_signal = t_signal * 1e3;   % s → ms
signal   = signal   * 1e2;   % V → µV

% NEL delay
if ~isempty(nel_delay) && ~isnan(nel_delay.delay_ms(ChinIND,CondIND))
    delay = nel_delay.delay_ms(ChinIND,CondIND);
else
    delay = 0;
end
t_signal = t_signal - delay;

n_pts     = size(latencies_template, 1);
peaks     = nan(1, n_pts);
latencies = nan(1, n_pts);

if ~isempty(template) && all(~isnan(template))

    % ── DTW warping ───────────────────────────────────────────────────────
    signal_norm   = signal   / range(signal);
    template_norm = template / range(template);
    [~, xi, yi]   = dtw(template_norm, signal_norm, tolerance);
    warp_ind = nan(1, size(latencies_template,1));
    for i = 1:size(latencies_template,1)
        idx_t = find(xi == latencies_template(i,3));
        if ~isempty(idx_t)
            warp_ind(i) = round(mean(idx_t));
        end
    end
    sig_inds             = nan(1, length(latencies_template));
    idx_sig_inds         = ~isnan(warp_ind);
    sig_inds(idx_sig_inds) = yi(warp_ind(idx_sig_inds));

    % ── DTW constraints (snap to local peaks/troughs) ────────────────────
    if snap_to_localminmax
        signal_col = signal(:);
        fs         = 1 / (t_signal(2) - t_signal(1));

        [~, pks_locs,  ~, peaks_p] = findpeaks( signal_col);
        threshold = 0.15;
        pks  = pks_locs( peaks_p /max(peaks_p)  > threshold);
        [~, vals_locs, ~, vals_p]  = findpeaks(-signal_col);
        vals = vals_locs(vals_p /max(vals_p)  > threshold);

        dsignal      = diff(signal_col);
        crit_peaks   = find(dsignal(1:end-1) > 0 & dsignal(2:end) < 0) + 1;
        crit_troughs = find(dsignal(1:end-1) < 0 & dsignal(2:end) > 0) + 1;

        % Adaptive latency windows from memory
        mem_file  = fullfile(fileparts(fileparts(fileparts(outpath))), ['ABR_peak_latency_memory_' freq_str '.mat']);
        min_obs   = 1;
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
        ms_windows_default = [1.4,2.4; 2.4,3.5; 3.4,4.6; 4.0,5.2; 5.1,6.5];
        ms_windows_default = ms_windows_default + (level_counter-1) * 0.08;
        pt_ms_windows    = nan(10,2);
        memory_seed_idx  = nan(1,10);   % sample-index seed from memory (NaN = no data)

        % Filter log to this intensity level so latency stats are level-specific
        if height(peak_memory.log) >= 1
            level_log = peak_memory.log(peak_memory.log.Level_dBSPL == levels(level_counter), :);
        else
            level_log = peak_memory.log([],:);
        end

        for j = 1:10
            w = ceil(j/2);
            pt_ms_windows(j,:) = ms_windows_default(w,:);
            obs = level_log.(pt_names{j});
            obs = obs(~isnan(obs));
            if length(obs) >= min_obs
                center = mean(obs);
                sd     = std(obs);
                % Window tightens as data accumulates (floor 0.25 ms each side)
                half_w = max(0.25, 1.5 * sd);
                pt_ms_windows(j,:)  = [center - half_w, center + half_w];
                memory_seed_idx(j)  = round((center + delay) * fs);
            end
        end
        idx_windows = round((pt_ms_windows + delay) * fs);   % 10×2, sample indices

        % Constrained snapping
        % When memory_seed_idx exists: pick candidate closest to predicted time.
        % When it does not (sparse data): fall back to DTW + amplitude criterion.
        max_snap_dist    = 3;
        last_assigned    = -inf;
        last_peak_amp    = inf;
        sig_inds_constrained = sig_inds;

        for j = 1:length(sig_inds_constrained)
            win_min  = idx_windows(j,1);
            win_max  = idx_windows(j,2);
            has_seed = ~isnan(memory_seed_idx(j));
            ref_idx  = memory_seed_idx(j);
            if ~has_seed, ref_idx = sig_inds_constrained(j); end

            if mod(j,2) == 0  % trough
                cands = vals(vals > last_assigned & vals >= win_min & vals <= win_max);
                cands = cands(signal_col(cands) < last_peak_amp);
                if ~isempty(cands) && ~isnan(ref_idx)
                    if has_seed
                        [~,ind] = min(abs(cands - ref_idx));
                        sig_inds_constrained(j) = cands(ind);
                    else
                        near = cands(abs(cands - ref_idx) <= max_snap_dist);
                        if ~isempty(near)
                            [~,ind] = min(signal_col(near));  sig_inds_constrained(j) = near(ind);
                        else
                            [~,ind] = min(signal_col(cands)); sig_inds_constrained(j) = cands(ind);
                        end
                    end
                end
            else  % peak
                cands = pks(pks > last_assigned & pks >= win_min & pks <= win_max);
                if ~isempty(cands) && ~isnan(ref_idx)
                    if has_seed
                        [~,ind] = min(abs(cands - ref_idx));
                        sig_inds_constrained(j) = cands(ind);
                    else
                        near = cands(abs(cands - ref_idx) <= max_snap_dist);
                        if ~isempty(near)
                            [~,ind] = max(signal_col(near));  sig_inds_constrained(j) = near(ind);
                        else
                            [~,ind] = max(signal_col(cands)); sig_inds_constrained(j) = cands(ind);
                        end
                    end
                    last_peak_amp = signal_col(sig_inds_constrained(j));
                end
            end
            if ~isnan(sig_inds_constrained(j))
                last_assigned = sig_inds_constrained(j);
            end
        end

        % ── Prepare manual editing variables ────────────────────────────
        sig_inds_auto   = sig_inds_constrained;   % snapshot of algo selection
        sig_inds_manual = sig_inds_constrained;   % user-editable copy

        % In app mode, seed no-template slots with window midpoints so the
        % user has a drag handle for every wave slot regardless of template.
        % (Classic mode leaves these NaN — only template-matched slots shown.)
        use_app = ~isempty(peak_ui) && isstruct(peak_ui) && ...
                  isfield(peak_ui,'fig') && isvalid(peak_ui.fig);
        idx_no_tpl = ~idx_sig_inds;
        if use_app
            for j = find(idx_no_tpl(:)')
                mid = max(1, min(length(signal), round(mean(idx_windows(j,:)))));
                sig_inds_manual(j) = mid;
                sig_inds_auto(j)   = mid;   % same baseline so "unedited" shows as unchanged
            end
        end

        % ── CLASSIC MODE — ginput / questdlg (unchanged behaviour) ──────
        if ~use_app
            done_editing = false;
            edit_fig = findobj('Type','figure','Name','ABR Peak Selection');
            if isempty(edit_fig)
                edit_fig = figure('Visible','on','Name','ABR Peak Selection','NumberTitle','off');
            else
                edit_fig = edit_fig(1);
            end
            while ~done_editing
                figure(edit_fig); clf;
                set(edit_fig,'Visible','on');
                set(edit_fig,'Units','Normalized','OuterPosition',[1-0.025-0.4, 0.15, 0.4, 0.65]);
                plot(t_signal,signal,'k','LineWidth',1.5,'HandleVisibility','off'); hold on;
                for k = 1:num_waves
                    pair  = [(2*k-1), 2*k];
                    valid = pair(idx_sig_inds(pair));
                    if ~isempty(valid)
                        plot(t_signal(sig_inds_constrained(valid)), signal(sig_inds_constrained(valid)), ...
                            shapes(k),'Color','k','MarkerSize',8,'LineWidth',1.5,'MarkerFaceColor','g','HandleVisibility','off');
                    end
                end
                changed = sig_inds_manual ~= sig_inds_constrained;
                if any(changed(idx_sig_inds))
                    for k = 1:num_waves
                        pair = [(2*k-1),2*k];
                        ch   = pair(changed(pair) & idx_sig_inds(pair));
                        if ~isempty(ch)
                            plot(t_signal(sig_inds_manual(ch)), signal(sig_inds_manual(ch)), ...
                                shapes(k),'Color','k','MarkerSize',8,'LineWidth',1.5,'MarkerFaceColor','r','HandleVisibility','off');
                        end
                    end
                end
                for k = 1:num_waves
                    plot(nan,nan,shapes(k),'Color','k','MarkerSize',8,'LineWidth',1.5,'MarkerFaceColor','g','DisplayName',sprintf('Wave %s',waves_legend(k)));
                end
                legend('Location','northeast','Orientation','horizontal','FontSize',11); legend box off;
                set(gca,'FontSize',12);
                xlabel(x_units,'FontWeight','bold','FontSize',20);
                ylabel(y_units,'FontWeight','bold','FontSize',20);
                xlim([0,20]); grid on;
                if level_counter==1 && CondIND==1
                    uiwait(msgbox({...
                        'For each level, use the window on the RIGHT to manually overwrite automatically selected peaks and troughs for waves I, II, III–IV, and V.'; ...
                        ''; ...
                        'Instructions:'; ...
                        '1. Left-click a peak/trough to edit its position (RED)'; ...
                        '2. Left-click a NEW peak/trough to change its position (GREEN)'; ...
                        '3. Right-click or press Enter to finish editing'; ...
                        ''; ...
                        'Note: A window on the LEFT will show ABR waveforms and peaks/throughs across all levels.'}, ...
                        'Manual Edit: Select Peaks/Troughs','modal'));
                end
                figure(edit_fig);
                title(sprintf('%s @ %d dB SPL - Select Peak/Trough to Edit',freq_str,levels(level_counter)));
                drawnow;
                figure(edit_fig); [x_old,~,button_old] = ginput(1);
                if isempty(button_old) || button_old==3, break; end

                [~,idx_time] = min(abs(t_signal - x_old));
                editable_positions = ~isnan(sig_inds_manual);
                if ~any(editable_positions)
                    uiwait(msgbox('No editable peaks/troughs available.','No Edit','modal'));
                    continue;
                end
                [~,rel_editable]       = min(abs(sig_inds_manual - idx_time));
                if editable_positions(rel_editable)
                    sel_idx_in_sig_inds = rel_editable;
                end

                wave_k = ceil(sel_idx_in_sig_inds/2);
                figure(edit_fig);
                hsel = plot(t_signal(sig_inds_manual(sel_idx_in_sig_inds)), signal(sig_inds_manual(sel_idx_in_sig_inds)), ...
                    shapes(wave_k),'Color','k','MarkerSize',8,'LineWidth',1.5,'MarkerFaceColor','r','HandleVisibility','off');
                if mod(sel_idx_in_sig_inds,2)==1; pt_type='Peak'; else; pt_type='Trough'; end

                editing_slot_done = false;
                while ~editing_slot_done
                    figure(edit_fig);
                    title(sprintf('%s @ %d dB SPL - Select NEW Wave %d (%s)',freq_str,levels(level_counter),ceil(sel_idx_in_sig_inds/2),pt_type));
                    drawnow;
                    figure(edit_fig); [x_new,~,button_new] = ginput(1);
                    if isempty(button_new) || button_new==3
                        if isvalid(hsel), delete(hsel); end
                        editing_slot_done = true; break;
                    end
                    [~,new_idx_time] = min(abs(t_signal - x_new));
                    if mod(sel_idx_in_sig_inds,2)==1
                        if ~isempty(crit_peaks);   [~,snap]=min(abs(crit_peaks-new_idx_time));   new_idx_time=crit_peaks(snap);   end
                    else
                        if ~isempty(crit_troughs); [~,snap]=min(abs(crit_troughs-new_idx_time)); new_idx_time=crit_troughs(snap); end
                    end
                    [~,rel_editable] = min(abs(sig_inds_manual - idx_time));
                    if editable_positions(rel_editable)
                        sel_idx_in_sig_inds = rel_editable;
                        chosen_idx = new_idx_time;
                    end
                    old_idx = sig_inds_manual(sel_idx_in_sig_inds);
                    sig_inds_manual(sel_idx_in_sig_inds) = chosen_idx;

                    zoom_w  = 2;
                    t_sel   = t_signal(chosen_idx);
                    figure(edit_fig); clf;
                    plot(t_signal,signal,'k','LineWidth',1.5,'HandleVisibility','off'); hold on;
                    set(gca,'FontSize',12);
                    xlabel(x_units,'FontWeight','bold','FontSize',20);
                    ylabel(y_units,'FontWeight','bold','FontSize',20);
                    xlim([t_sel-zoom_w, t_sel+zoom_w]); grid on;
                    changed2 = sig_inds_manual ~= sig_inds_constrained & ~isnan(sig_inds_manual);
                    if any(changed2(idx_sig_inds))
                        for j2 = find(changed2(:)')
                            k2 = ceil(j2/2);
                            plot(t_signal(sig_inds_manual(j2)), signal(sig_inds_manual(j2)), ...
                                shapes(k2),'Color','k','MarkerSize',8,'LineWidth',1.5,'MarkerFaceColor','g','DisplayName','New selection');
                        end
                    end
                    plot(t_signal(sig_inds_constrained(sel_idx_in_sig_inds)), signal(sig_inds_constrained(sel_idx_in_sig_inds)), ...
                        shapes(wave_k),'Color','k','MarkerSize',8,'LineWidth',1.5,'MarkerFaceColor','r','DisplayName','Previous selection');
                    if mod(sel_idx_in_sig_inds,2)==1; pt_type='Peak'; else; pt_type='Trough'; end
                    title(sprintf('%s @ %d dB SPL - Editing Wave %d (%s)',freq_str,levels(level_counter),ceil(sel_idx_in_sig_inds/2),pt_type));
                    legend('Location','northeast'); legend box off;

                    choice = questdlg(sprintf('Accept new selection for Wave %d (%s)?',ceil(sel_idx_in_sig_inds/2),pt_type),...
                        'Confirm Selection','Accept','Redo','Cancel','Accept');
                    switch choice
                        case 'Accept'
                            editing_slot_done = true;
                            if isvalid(hsel), delete(hsel); end
                            clf; plot(t_signal,signal,'k','LineWidth',1.5,'HandleVisibility','off'); hold on;
                            for k = 1:num_waves
                                pair  = [(2*k-1),2*k];
                                valid = pair(idx_sig_inds(pair));
                                if ~isempty(valid)
                                    plot(t_signal(sig_inds_manual(valid)), signal(sig_inds_manual(valid)), ...
                                        shapes(k),'Color','k','MarkerSize',8,'LineWidth',1.5,'MarkerFaceColor','g','HandleVisibility','off');
                                end
                            end
                            title(sprintf('%s @ %d dB SPL - Current Peaks',freq_str,levels(level_counter)));
                            set(gca,'FontSize',12);
                            xlabel(x_units,'FontWeight','bold','FontSize',20);
                            ylabel(y_units,'FontWeight','bold','FontSize',20);
                            xlim([0,20]); grid on;
                            sig_inds_constrained = sig_inds_manual;
                        case 'Redo'
                            sig_inds_manual(sel_idx_in_sig_inds) = old_idx;
                            if isvalid(hsel), delete(hsel); end
                            hsel = plot(t_signal(sig_inds_manual(sel_idx_in_sig_inds)), signal(sig_inds_manual(sel_idx_in_sig_inds)), ...
                                shapes(wave_k),'Color','k','MarkerSize',8,'LineWidth',1.5,'MarkerFaceColor','r','HandleVisibility','off');
                            editing_slot_done = false;
                        case 'Cancel'
                            sig_inds_manual(sel_idx_in_sig_inds) = old_idx;
                            if isvalid(hsel), delete(hsel); end
                            editing_slot_done = true;
                    end
                end  % while ~editing_slot_done

                invalid_mask = isnan(sig_inds_manual) | sig_inds_manual<1 | sig_inds_manual>length(signal);
                sig_inds_manual(invalid_mask) = sig_inds_constrained(invalid_mask);
            end  % while ~done_editing

        else
            % ── APP MODE — embedded panel, uiwait/uiresume ───────────────
            % peak_ui.ax may be stale if fresh_uiaxes replaced it on a prior level;
            % use appdata to track the live handle across calls.
            fig  = peak_ui.fig;

            % Recover live axes handles (fresh_uiaxes replaces them each draw)
            if isvalid(peak_ui.ax)
                ax_e = peak_ui.ax;
            else
                ax_e = getappdata(fig, 'peak_edit_ax');
            end
            if isvalid(peak_ui.wf_ax)
                ax_w = peak_ui.wf_ax;
            else
                ax_w = getappdata(fig, 'peak_wf_ax');
            end

            peak_ui.panel.Visible = 'on';
            peak_ui.info_lbl.Text = sprintf( ...
                'Subject: %s  |  Condition: %s  |  %s  |  Level %d / %d  (%d dB SPL)', ...
                cell2mat(subject), condition, freq_str, level_counter, numel(levels), levels(level_counter));
            peak_ui.info_lbl.FontSize        = 15;
            peak_ui.info_lbl.FontWeight      = 'bold';
            peak_ui.info_lbl.HorizontalAlignment = 'center';

            % Waterfall: recreate axes on new subject/freq only
            wf_tag = sprintf('%s|%s', cell2mat(subject), freq_str);
            ud     = ax_w.UserData;
            if ~isstruct(ud) || ~isfield(ud,'subj_key') || ~strcmp(ud.subj_key, wf_tag)
                sig_dc0 = signal - mean(signal);
                vsp     = 1.2 * range(sig_dc0);
                parent_w = ax_w.Parent;
                pos_w    = ax_w.Position;
                un_w     = ax_w.Units;
                delete(ax_w);
                ax_w = uiaxes(parent_w, 'Units', un_w, 'Position', pos_w);
                setappdata(fig, 'peak_wf_ax', ax_w);
                hold(ax_w,'on'); grid(ax_w,'on');
                xlabel(ax_w, x_units, 'FontWeight','bold','FontSize',15);
                set(ax_w,'YColor','none','FontSize',13);
                ylim(ax_w, vsp * [-numel(levels), 1.2]);
                xlim(ax_w, [0, 20]);
                % cond_base tracks cumulative offset across conditions;
                % has_legend ensures legend only drawn once per waterfall
                ax_w.UserData = struct('subj_key',wf_tag, 'vspacing',vsp, ...
                                       'cond_base',0, 'has_legend',false);
                drawnow;
            end
            % Always read fresh state — valid for both new and existing waterfall
            wf_ud = ax_w.UserData;
            vsp   = wf_ud.vspacing;

            % Wire app button callbacks (buttons stay constant across levels)
            peak_ui.done_btn.ButtonPushedFcn   = @(~,~) set_peak_action(fig,'done',  nan);
            peak_ui.accept_btn.ButtonPushedFcn = @(~,~) set_peak_action(fig,'accept',nan);
            peak_ui.redo_btn.ButtonPushedFcn   = @(~,~) set_peak_action(fig,'redo',  nan);
            peak_ui.cancel_btn.ButtonPushedFcn = @(~,~) set_peak_action(fig,'cancel',nan);

            % Outer loop: pick a point to edit, or Done
            done_editing = false;
            while ~done_editing
                % fresh_uiaxes = equivalent of clf: delete old axes, create clean one
                ax_e = fresh_uiaxes(ax_e, fig);
                draw_edit(ax_e, t_signal, signal, sig_inds_constrained, sig_inds_manual, ...
                    idx_sig_inds, wave_sel, shapes, num_waves, [], ...
                    sprintf('%s  @  %d dB SPL — click to edit, or Done', freq_str, levels(level_counter)), ...
                    x_units, y_units, [0 20]);
                peak_ui.status_lbl.Text = ...
                    'Click a peak/trough to edit  |  "Done" to accept current peaks and advance';
                set_confirm(peak_ui, false);
                drawnow;

                setappdata(fig,'peak_action',[]);
                uiwait(fig);
                if ~isvalid(fig), break; end
                act = getappdata(fig,'peak_action');
                if isempty(act) || strcmp(act.type,'done'), break; end
                if ~strcmp(act.type,'click'), continue; end

                % Find nearest selectable slot to click
                [~,idx_c] = min(abs(t_signal - act.x));
                slots = [];
                for kk = 1:num_waves
                    if wave_sel(kk), slots = [slots, 2*kk-1, 2*kk]; end %#ok<AGROW>
                end
                slots = slots(~isnan(sig_inds_manual(slots)));
                if isempty(slots), continue; end
                [~,ei]  = min(abs(sig_inds_manual(slots) - idx_c));
                sel     = slots(ei);
                wave_k  = ceil(sel/2);
                if mod(sel,2)==1; pt_type='Peak'; else; pt_type='Trough'; end

                % Inner loop: pick new position for selected slot
                inner_done = false;
                while ~inner_done
                    ax_e = fresh_uiaxes(ax_e, fig);
                    draw_edit(ax_e, t_signal, signal, sig_inds_constrained, sig_inds_manual, ...
                        idx_sig_inds, wave_sel, shapes, num_waves, sel, ...
                        sprintf('%s  @  %d dB SPL — click NEW position for Wave %s (%s)', ...
                                freq_str, levels(level_counter), waves_legend(wave_k), pt_type), ...
                        x_units, y_units, [0 20]);
                    peak_ui.status_lbl.Text = sprintf( ...
                        'Wave %s (%s) selected — click waveform to place new position', ...
                        waves_legend(wave_k), pt_type);
                    set_confirm(peak_ui, false);
                    drawnow;

                    setappdata(fig,'peak_action',[]);
                    uiwait(fig);
                    if ~isvalid(fig), inner_done=true; done_editing=true; break; end
                    act2 = getappdata(fig,'peak_action');
                    if isempty(act2), continue; end
                    if strcmp(act2.type,'done'), inner_done=true; done_editing=true; break; end
                    if ~strcmp(act2.type,'click'), continue; end

                    % Snap click to nearest critical point
                    [~,new_idx] = min(abs(t_signal - act2.x));
                    if mod(sel,2)==1
                        if ~isempty(crit_peaks);   [~,s_]=min(abs(crit_peaks-new_idx));   new_idx=crit_peaks(s_);   end
                    else
                        if ~isempty(crit_troughs); [~,s_]=min(abs(crit_troughs-new_idx)); new_idx=crit_troughs(s_); end
                    end
                    old_idx = sig_inds_manual(sel);
                    sig_inds_manual(sel) = new_idx;

                    % Zoomed confirm view
                    t_new = t_signal(new_idx);
                    ax_e = fresh_uiaxes(ax_e, fig);
                    draw_edit(ax_e, t_signal, signal, sig_inds_constrained, sig_inds_manual, ...
                        idx_sig_inds, wave_sel, shapes, num_waves, sel, ...
                        sprintf('%s  @  %d dB SPL — Accept, Redo, or Cancel?', freq_str, levels(level_counter)), ...
                        x_units, y_units, [t_new-2, t_new+2]);
                    peak_ui.status_lbl.Text = sprintf( ...
                        'Wave %s (%s) — Accept new position, Redo, or Cancel', waves_legend(wave_k), pt_type);
                    set_confirm(peak_ui, true);
                    drawnow;

                    setappdata(fig,'peak_action',[]);
                    uiwait(fig);
                    if ~isvalid(fig), inner_done=true; done_editing=true; break; end
                    act3 = getappdata(fig,'peak_action');
                    if isempty(act3), continue; end
                    switch act3.type
                        case 'accept'
                            sig_inds_constrained(sel) = sig_inds_manual(sel);
                            inner_done = true;
                        case 'redo'
                            sig_inds_manual(sel) = old_idx;
                        case {'cancel','done'}
                            sig_inds_manual(sel) = old_idx;
                            inner_done = true;
                            if strcmp(act3.type,'done'), done_editing = true; end
                    end
                end  % while ~inner_done
            end  % while ~done_editing

            % Leave axes blank when done with this level
            ax_e = fresh_uiaxes(ax_e, fig);
            drawnow;

            % Sanitise: clamp any out-of-bounds manual indices
            oob = sig_inds_manual < 1 | sig_inds_manual > length(signal);
            sig_inds_manual(oob & idx_sig_inds) = sig_inds_constrained(oob & idx_sig_inds);

        end  % if ~use_app / else

        % ── Final selection ───────────────────────────────────────────────
        sig_inds      = sig_inds_manual;
        idx_export    = ~isnan(sig_inds);       % template-based + any user-placed
        peaks(idx_export)     = signal(sig_inds(idx_export));
        latencies(idx_export) = t_signal(sig_inds(idx_export));

        % Save confirmed latencies to memory log
        new_obs    = nan(1,10);
        was_edited = sig_inds_manual ~= sig_inds_auto;
        for j = 1:10
            if ~isnan(latencies(j)), new_obs(j) = latencies(j); end
        end
        n_valid    = sum(idx_sig_inds);
        pct_edited = 100 * sum(was_edited(idx_sig_inds)) / max(n_valid,1);
        new_row = [table(string(cell2mat(subject)), string(condition), ...
                         string(datestr(now,'yyyy-mm-dd HH:MM:SS')), levels(level_counter), ...
                   'VariableNames', {'Subject','Condition','Date','Level_dBSPL'}), ...
                   array2table(new_obs,    'VariableNames', pt_names), ...
                   array2table(was_edited, 'VariableNames', pt_edited_names), ...
                   table(pct_edited,       'VariableNames', {'Pct_edited'})];
        peak_memory.log = [peak_memory.log; new_row];
        save(mem_file, 'peak_memory');

        % ── Waterfall ─────────────────────────────────────────────────────
        if ~use_app
            % Classic mode: invisible standalone figure, persistent via global
            wf_name = sprintf('Peaks Waterfall|%s|%s', condition, freq_str);
            if level_counter == 1
                vertical_spacing = 1.2 * range(signal);
                wf_fig = figure('Visible','off','Name',wf_name,'NumberTitle','off');
                set(wf_fig,'Units','Normalized','OuterPosition',[0.01,0.03,0.5,0.9]);
                figure(wf_fig); hold on;
                ticks  = 0:1:round(max(t_signal),-1);
                xticks(ticks);
                lbl    = string(ticks); lbl(mod(ticks,2)~=0) = "";
                xticklabels(lbl); xtickangle(0);
                ylim(vertical_spacing*[-length(levels),1.2]);
                hold off;
                title(sprintf('%s | %s', cell2mat(subject), condition),'FontSize',16,'FontWeight','bold');
                subtitle(sprintf('%s',freq_str));
                set(gca,'FontSize',15); grid on;
                xlabel(x_units,'FontWeight','bold','FontSize',20);
                ylabel(y_units,'FontWeight','bold','FontSize',20); set(gca,'YColor','none');
                xlim([0,20]);
            end
            offset  = -(level_counter-1) * vertical_spacing;
            wf_fig  = findobj('Type','figure','Name',wf_name);
            if isempty(wf_fig)
                wf_fig = figure('Visible','off','Name',wf_name,'NumberTitle','off');
                set(wf_fig,'Units','Normalized','OuterPosition',[0.01,0.03,0.5,0.9]);
            else
                wf_fig = wf_fig(1);
            end
            set(0,'CurrentFigure',wf_fig); hold on;
            legend_string = cell(1,num_waves);
            for k = 1:num_waves
                idx = (2*k-1):(2*k);
                show = 'off'; if level_counter==1, show='on'; end
                if ~any(isnan(peaks(idx)))
                    plot(latencies(idx), peaks(idx)+offset, shapes(k), ...
                        'Color',colors(k+4,:),'MarkerFaceColor',colors(k+4,:), ...
                        'MarkerSize',12,'LineWidth',1.5,'HandleVisibility',show);
                end
                legend_string{k} = sprintf('Wave %s', waves_legend(k));
            end
            plot(t_signal, signal+offset, 'LineWidth',3, 'Color',[colors(CondIND,:),0.50], 'HandleVisibility','off');
            bar_h   = 1;
            scale_x = 1;
            text(scale_x-0.65, offset+1.2*bar_h, sprintf('%g \\muV',bar_h), ...
                'Rotation',0,'HorizontalAlignment','center','FontSize',12,'FontWeight','bold');
            plot([scale_x,scale_x],[offset,offset+bar_h],'k','LineWidth',2.5,'HandleVisibility','off');
            text(-0.06*max(t_signal), offset, sprintf('%d dB',levels(level_counter)), ...
                'FontSize',18,'HorizontalAlignment','left','FontWeight','bold');
            legend(legend_string,'Location','northeast','Orientation','horizontal','FontSize',15);
            legend box off;

        else
            % App mode: draw on embedded ax_w
            % offset_w accumulates across conditions via cond_base
            offset_w = wf_ud.cond_base - (level_counter-1) * vsp;
            sig_dc   = signal - mean(signal);
            hold(ax_w,'on');
            plot(ax_w, t_signal, sig_dc+offset_w, 'LineWidth',1.5, ...
                'Color',colors(CondIND,:),'HandleVisibility','off');
            legend_str = {};
            for k = 1:num_waves
                if ~wave_sel(k), continue; end
                pair = [2*k-1, 2*k];
                if ~any(isnan(latencies(pair))) && ~any(isnan(peaks(pair)))
                    if ~wf_ud.has_legend, show = 'on'; else, show = 'off'; end
                    plot(ax_w, latencies(pair), peaks(pair)-mean(signal)+offset_w, ...
                        shapes(k),'Color',colors(k+4,:),'MarkerFaceColor',colors(k+4,:), ...
                        'MarkerSize',10,'LineWidth',1.5,'HandleVisibility',show);
                    if ~wf_ud.has_legend, legend_str{end+1} = sprintf('Wave %s',waves_legend(k)); end %#ok<AGROW>
                end
            end
            % Level label just above the waveform crest
            text(ax_w, 0.5, offset_w + max(sig_dc) + 0.01*vsp, sprintf('%d dB',levels(level_counter)), ...
                'FontSize',16,'FontWeight','bold','HorizontalAlignment','left', ...
                'VerticalAlignment','bottom');
            % Scale bar: 1 µV vertical reference on the right edge
            sb_x = 18.8;
            plot(ax_w, [sb_x sb_x], [offset_w, offset_w+1], 'k-', ...
                'LineWidth',2.5,'HandleVisibility','off');
            text(ax_w, sb_x - 0.15, offset_w + 0.5, '1 \muV', ...
                'FontSize',12,'FontWeight','bold', ...
                'HorizontalAlignment','right','VerticalAlignment','middle');
            % Show legend once per waterfall (first level of first condition)
            if ~wf_ud.has_legend && ~isempty(legend_str)
                legend(ax_w, legend_str{:},'Location','northeast','Orientation','horizontal','FontSize',13);
                legend(ax_w,'boxoff');
                wf_ud.has_legend = true;
                ax_w.UserData = wf_ud;
            end
            % Expand ylim to accommodate this level
            cur_yl = ylim(ax_w);
            ylim(ax_w, [min(cur_yl(1), offset_w - 0.6*vsp), cur_yl(2)]);
            % After last level of this condition, advance cond_base for next condition
            if level_counter == numel(levels)
                wf_ud2 = ax_w.UserData;
                wf_ud2.cond_base = wf_ud2.cond_base - numel(levels) * vsp;
                ax_w.UserData = wf_ud2;
            end
            drawnow;
        end

    end  % if snap_to_localminmax
end  % if ~isempty(template)
end  % function


% ── Local helper functions ────────────────────────────────────────────────

function new_ax = fresh_uiaxes(old_ax, fig)
%FRESH_UIAXES  Delete old uiaxes and return a clean one in the same slot.
%  Equivalent to clf for classic figures — guarantees completely clean state.
%  Stores the new handle in fig appdata so the next findPeaks_dtw call can
%  recover it even after peak_ui.ax has become invalid.
parent = old_ax.Parent;
pos    = old_ax.Position;
un     = old_ax.Units;
delete(old_ax);
new_ax = uiaxes(parent, 'Units', un, 'Position', pos);
disableDefaultInteractivity(new_ax);
set(new_ax, 'HitTest','on', 'PickableParts','all');
new_ax.ButtonDownFcn = @(src,~) set_peak_action(fig,'click', src.CurrentPoint(1,1));
setappdata(fig, 'peak_edit_ax', new_ax);
end


function set_peak_action(fig, type, x)
%SET_PEAK_ACTION  Store action and unblock uiwait.
if ~isvalid(fig), return; end
setappdata(fig, 'peak_action', struct('type', type, 'x', x));
uiresume(fig);
end


function draw_edit(ax, t, sig, inds_c, inds_m, idx_tpl, wave_sel, shapes, n_waves, sel_slot, ttl, xu, yu, xlims)
%DRAW_EDIT  Render waveform + peak markers on the edit axes.
%  Green  = DTW-selected (template-based, unedited)
%  Red    = manually moved from DTW position
%  Grey   = no template reference (user-placed or seeded midpoint)
%  Yellow = currently selected slot for editing
% axes is always fresh (created by fresh_uiaxes) — just draw.
% HitTest='off' on all children so every click falls through to the axes
% ButtonDownFcn regardless of whether the user clicks on a marker or blank space.
hold(ax,'on');
plot(ax, t, sig, 'k', 'LineWidth',1.5, 'HandleVisibility','off', 'HitTest','off');
for k = 1:n_waves
    if ~wave_sel(k), continue; end
    for j = [2*k-1, 2*k]
        if isnan(inds_m(j)), continue; end
        if idx_tpl(j)
            if inds_m(j) ~= inds_c(j)
                clr = 'r';           % manually moved
            else
                clr = 'g';           % DTW auto
            end
        else
            clr = [0.55 0.55 0.55];  % no template reference
        end
        plot(ax, t(inds_m(j)), sig(inds_m(j)), shapes(k), ...
            'Color','k','MarkerSize',10,'LineWidth',1.5,'MarkerFaceColor',clr, ...
            'HandleVisibility','off','HitTest','off');
    end
end
% Highlight selected slot in yellow
if ~isempty(sel_slot) && ~isnan(inds_m(sel_slot))
    k = ceil(sel_slot/2);
    plot(ax, t(inds_m(sel_slot)), sig(inds_m(sel_slot)), shapes(k), ...
        'Color','k','MarkerSize',14,'LineWidth',2,'MarkerFaceColor','y', ...
        'HandleVisibility','off','HitTest','off');
end
% Legend: one entry per selected wave showing its shape
wl = ["I","II","III","IV","V"];
leg_h   = gobjects(1, n_waves);
leg_lbl = {};
ki = 0;
for k = 1:n_waves
    if ~wave_sel(k), continue; end
    ki = ki + 1;
    leg_h(ki) = plot(ax, nan, nan, shapes(k), 'Color','k', ...
        'MarkerSize',9,'LineWidth',1.5,'MarkerFaceColor','g');
    leg_lbl{ki} = sprintf('Wave %s', wl(k)); %#ok<AGROW>
end
if ki > 0
    lg = legend(ax, leg_h(1:ki), leg_lbl, 'Location','northeast', ...
        'Orientation','horizontal','FontSize',12);
    legend(ax,'boxoff');
    lg.HitTest       = 'off';
    lg.PickableParts = 'none';
end
grid(ax,'on');
xlabel(ax, xu, 'FontWeight','bold','FontSize',15);
ylabel(ax, yu, 'FontWeight','bold','FontSize',15);
xlim(ax, xlims);
vis = t >= xlims(1) & t <= xlims(2);
if any(vis), y_lo = min(sig(vis)); y_hi = max(sig(vis));
else,        y_lo = min(sig);      y_hi = max(sig); end
pad = 0.30 * max(y_hi - y_lo, eps);
ylim(ax, [y_lo - pad, y_hi + pad]);
set(ax,'FontSize',13);
end


function set_confirm(peak_ui, show_confirm)
%SET_CONFIRM  Toggle between "Done" button and Accept/Redo/Cancel buttons.
if show_confirm
    peak_ui.accept_btn.Visible = 'on';
    peak_ui.redo_btn.Visible   = 'on';
    peak_ui.cancel_btn.Visible = 'on';
    peak_ui.done_btn.Visible   = 'off';
else
    peak_ui.accept_btn.Visible = 'off';
    peak_ui.redo_btn.Visible   = 'off';
    peak_ui.cancel_btn.Visible = 'off';
    peak_ui.done_btn.Visible   = 'on';
end
end
