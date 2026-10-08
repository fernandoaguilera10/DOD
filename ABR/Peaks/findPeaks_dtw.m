function [peaks,latencies,sig_inds_out,nav] = findPeaks_dtw(t_signal,signal,template,latencies_template,subject,condition,Conds2Run,CondIND,ChinIND,levels,counter,level_counter,colors,shapes,ylim_ind,freq_str,idx_abr,idx_template,outpath,peak_ui,wave_sel,opts)
%FINDPEAKS_DTW  DTW-based ABR peak detection with manual override.
%
%  Classic mode (peak_ui=[]):  ginput-based editing in a standalone figure.
%  App mode    (peak_ui=struct): uiwait/uiresume editing embedded in the app.
%
%  wave_sel – 1×5 logical; which waves (I–V) to show/edit (default all true).
%  opts     – (app mode, optional) struct:
%               .session   true when ABR_dtw drives a multi-level session
%                          (waterfall drawn by ABR_dtw; clicks on it jump levels)
%               .init_inds previous picks (sample indices) to resume from
%               .do_log    append this level to the latency-memory log
%               .auto_only skip the editor; return the automatic picks (or
%                          init_inds if given) — used when "Done" finalises
%                          the levels of a waterfall
%  Outputs  – sig_inds_out: final picks (sample indices, NaN = none/absent)
%             nav: .type 'done' (level confirmed) or 'goto' (.level = target)

% ── Defaults ─────────────────────────────────────────────────────────────
if ~exist('peak_ui','var'), peak_ui  = []; end
if ~exist('wave_sel','var') || isempty(wave_sel), wave_sel = true(1,5); end
if ~exist('opts','var') || isempty(opts), opts = struct(); end
in_session = isfield(opts,'session') && opts.session;
init_inds  = [];
if isfield(opts,'init_inds'), init_inds = opts.init_inds; end
do_log     = ~isfield(opts,'do_log') || opts.do_log;
auto_only  = isfield(opts,'auto_only') && opts.auto_only;   % no UI: keep auto/resumed picks
nav        = struct('type','done','level',[]);

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

n_pts     = size(latencies_template, 1);
peaks     = nan(1, n_pts);
latencies = nan(1, n_pts);
sig_inds_out = nan(1, n_pts);

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
        snap_radius_samp = round(1.5 * fs);  % 1.5 ms — snap only when click is close to a critical point

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
        % ── Search windows (raw recording time, ms) ─────────────────────
        % Primary: centre each point's window on the template's own latency
        % for that point (templates are in raw time, per freq/level).
        % Points the template lacks (e.g. P4/N4 in click templates) are
        % interpolated between the neighbouring same-polarity points; if
        % that is not possible, fall back to legacy defaults + raw offset.
        tpl_half_w_ms      = 0.6;    % ± half-width around template latency
        raw_offset_ms      = 4.7;    % legacy (delay-corrected) → raw time, fallback only
        ms_windows_default = [1.4,2.4; 2.4,3.5; 3.4,4.6; 4.0,5.2; 5.1,6.5] + raw_offset_ms;
        ms_windows_default = ms_windows_default + (level_counter-1) * 0.08;
        tpl_ms = nan(10,1);
        n_tpl_rows = min(10, size(latencies_template,1));
        tpl_ms(1:n_tpl_rows) = latencies_template(1:n_tpl_rows,1) * 1e3;   % s → ms
        for j = 1:10
            if isnan(tpl_ms(j)) && j > 2 && j < 9 && ~isnan(tpl_ms(j-2)) && ~isnan(tpl_ms(j+2))
                tpl_ms(j) = (tpl_ms(j-2) + tpl_ms(j+2)) / 2;   % midpoint of neighbours
            end
        end
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
            if ~isnan(tpl_ms(j))
                pt_ms_windows(j,:) = tpl_ms(j) + [-tpl_half_w_ms, tpl_half_w_ms];
            else
                pt_ms_windows(j,:) = ms_windows_default(w,:);
            end
            obs = level_log.(pt_names{j});
            obs = obs(~isnan(obs));
            if length(obs) >= min_obs
                center = mean(obs);
                sd     = std(obs);
                % Window tightens as data accumulates (floor 0.25 ms each side)
                half_w = max(0.25, 1.5 * sd);
                pt_ms_windows(j,:)  = [center - half_w, center + half_w];
                memory_seed_idx(j)  = round(center * fs);
            end
        end
        idx_windows = round(pt_ms_windows * fs);   % 10×2, sample indices

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
        % Revisiting a level: start from the user's previous picks
        if ~isempty(init_inds) && numel(init_inds) == numel(sig_inds_manual)
            sig_inds_manual      = reshape(init_inds, size(sig_inds_manual));
            sig_inds_constrained = sig_inds_manual;
        end

        % ── CLASSIC MODE — ginput / questdlg (unchanged behaviour) ──────
        if auto_only
            % No editing: keep the automatic (or resumed) picks as they are
        elseif ~use_app
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
                            shapes(k),'Color','g','MarkerSize',9,'LineWidth',2,'MarkerFaceColor','none','HandleVisibility','off');
                    end
                end
                changed = sig_inds_manual ~= sig_inds_constrained;
                if any(changed(idx_sig_inds))
                    for k = 1:num_waves
                        pair = [(2*k-1),2*k];
                        ch   = pair(changed(pair) & idx_sig_inds(pair));
                        if ~isempty(ch)
                            plot(t_signal(sig_inds_manual(ch)), signal(sig_inds_manual(ch)), ...
                                shapes(k),'Color','r','MarkerSize',9,'LineWidth',2,'MarkerFaceColor','none','HandleVisibility','off');
                        end
                    end
                end
                for k = 1:num_waves
                    plot(nan,nan,shapes(k),'Color','g','MarkerSize',9,'LineWidth',2,'MarkerFaceColor','none','DisplayName',sprintf('Wave %s',waves_legend(k)));
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
                    shapes(wave_k),'Color','r','MarkerSize',9,'LineWidth',2,'MarkerFaceColor','none','HandleVisibility','off');
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
                    snap_thr = 0.05;  % classic mode: fixed threshold
                    if mod(sel_idx_in_sig_inds,2)==1
                        new_idx_time = snap_to_peak(new_idx_time, pks_locs, peaks_p, snap_thr);
                    else
                        new_idx_time = snap_to_peak(new_idx_time, vals_locs, vals_p,  snap_thr);
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
                                shapes(k2),'Color','g','MarkerSize',9,'LineWidth',2,'MarkerFaceColor','none','DisplayName','New selection');
                        end
                    end
                    plot(t_signal(sig_inds_constrained(sel_idx_in_sig_inds)), signal(sig_inds_constrained(sel_idx_in_sig_inds)), ...
                        shapes(wave_k),'Color','r','MarkerSize',9,'LineWidth',2,'MarkerFaceColor','none','DisplayName','Previous selection');
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
                                        shapes(k),'Color','g','MarkerSize',9,'LineWidth',2,'MarkerFaceColor','none','HandleVisibility','off');
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
                                shapes(wave_k),'Color','r','MarkerSize',9,'LineWidth',2,'MarkerFaceColor','none','HandleVisibility','off');
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
            is_blind = isfield(peak_ui,'blind') && peak_ui.blind;
            if is_blind
                peak_ui.info_lbl.Text = sprintf( ...
                    'BLIND MODE  |  Subject %s  |  Recording %s  |  %s  |  Level %d / %d  (%d dB SPL)', ...
                    peak_ui.blind_subj, peak_ui.blind_cond, freq_str, level_counter, numel(levels), levels(level_counter));
            else
                peak_ui.info_lbl.Text = sprintf( ...
                    'Subject: %s  |  Condition: %s  |  %s  |  Level %d / %d  (%d dB SPL)', ...
                    cell2mat(subject), condition, freq_str, level_counter, numel(levels), levels(level_counter));
            end
            peak_ui.info_lbl.FontSize        = 15;
            peak_ui.info_lbl.FontWeight      = 'bold';
            peak_ui.info_lbl.HorizontalAlignment = 'center';
            peak_ui_busy(peak_ui, 'Loading waveform…');
            drawnow;

            % Waterfall: recreate axes on new subject/freq only
            % (in a session ABR_dtw owns the waterfall, so skip this)
            if ~in_session
            wf_tag = sprintf('%s|%s', cell2mat(subject), freq_str);
            ud     = ax_w.UserData;
            if ~isstruct(ud) || ~isfield(ud,'subj_key') || ~strcmp(ud.subj_key, wf_tag) || ~isfield(ud,'levels_labeled')
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
                ax_w.UserData = struct('subj_key',wf_tag, 'vspacing',vsp, ...
                                       'levels_labeled',[], 'has_legend',false);
                drawnow;
            end
            % Always read fresh state — valid for both new and existing waterfall
            wf_ud = ax_w.UserData;
            vsp   = wf_ud.vspacing;
            end   % ~in_session

            % Wire app button callbacks (buttons stay constant across levels)
            peak_ui.done_btn.ButtonPushedFcn   = @(~,~) set_peak_action(fig,'done',  nan);
            peak_ui.accept_btn.ButtonPushedFcn = @(~,~) set_peak_action(fig,'accept',nan);
            peak_ui.redo_btn.ButtonPushedFcn   = @(~,~) set_peak_action(fig,'redo',  nan);
            peak_ui.cancel_btn.ButtonPushedFcn = @(~,~) set_peak_action(fig,'cancel',nan);
            has_absent_btn = isfield(peak_ui,'absent_btn') && isvalid(peak_ui.absent_btn);
            if has_absent_btn
                peak_ui.absent_btn.ButtonPushedFcn = @(~,~) set_peak_action(fig,'absent',nan);
                peak_ui.absent_btn.Visible = 'off';
            end

            % Waves the user marks absent → peak & trough exported as NaN.
            % Positions are stashed so the wave can be restored.
            absent        = false(1, num_waves);
            absent_stash  = sig_inds_manual;
            absent_stashc = sig_inds_constrained;
            clr_wave_btn  = [0.86 0.84 0.79];   % neutral (wave not selected)
            clr_present   = [0.60 0.82 0.60];   % green  — wave present
            clr_absent    = [0.90 0.45 0.45];   % red    — wave marked absent
            if ~isempty(init_inds)
                % Waves blank in the previous picks were marked absent
                for kk = 1:num_waves
                    pr = [2*kk-1, 2*kk];
                    if wave_sel(kk) && all(isnan(sig_inds_manual(pr))) && any(~isnan(sig_inds_auto(pr)))
                        absent(kk) = true;
                        absent_stash(pr)  = sig_inds_auto(pr);
                        absent_stashc(pr) = sig_inds_auto(pr);
                    end
                end
            end

            % Outer loop: pick a point to edit, or Done
            done_editing = false;
            while ~done_editing
                % Update wave-selector button callbacks with current peak positions
                if isfield(peak_ui,'wave_btns') && isfield(peak_ui,'pt_toggle')
                    for kk = 1:num_waves
                        if wave_sel(kk)
                            peak_ui.wave_btns(kk).ButtonPushedFcn = ...
                                @(~,~) wave_select_cb(fig, peak_ui.pt_toggle, kk, sig_inds_manual, t_signal);
                            has_pk = ~isnan(sig_inds_manual(2*kk-1));
                            has_tr = ~isnan(sig_inds_manual(2*kk));
                            if has_pk || has_tr || absent(kk)
                                peak_ui.wave_btns(kk).Enable = 'on';
                            else
                                peak_ui.wave_btns(kk).Enable = 'off';
                            end
                            if absent(kk)
                                peak_ui.wave_btns(kk).BackgroundColor = clr_absent;
                                peak_ui.wave_btns(kk).Tooltip = sprintf('Wave %s marked absent — click to restore', waves_legend(kk));
                            else
                                peak_ui.wave_btns(kk).BackgroundColor = clr_present;
                                peak_ui.wave_btns(kk).Tooltip = sprintf('Wave %s present — click to select', waves_legend(kk));
                            end
                        else
                            peak_ui.wave_btns(kk).Enable = 'off';
                            peak_ui.wave_btns(kk).BackgroundColor = clr_wave_btn;
                        end
                    end
                end

                ax_e = fresh_uiaxes(ax_e, fig);
                draw_edit(ax_e, t_signal, signal, sig_inds_constrained, sig_inds_manual, ...
                    idx_sig_inds, wave_sel, shapes, colors(5:end,:), num_waves, [], ...
                    sprintf('%s  @  %d dB SPL — click to edit, or Done', freq_str, levels(level_counter)), ...
                    x_units, y_units, [0 20]);
                if in_session
                    peak_ui.status_lbl.Text = '';     % no instruction text in the session view
                else
                    peak_ui.status_lbl.Text = ...
                        'Click a peak/trough  —  or use the Wave buttons to select directly  |  "Done" to advance';
                end
                set_confirm(peak_ui, false);
                peak_ui_ready(peak_ui);
                drawnow;

                setappdata(fig,'peak_action',[]);
                uiwait(fig);
                if isvalid(ax_e), ax_e.ButtonDownFcn = []; end  % block stale clicks
                peak_ui_busy(peak_ui, 'Processing…');
                drawnow;
                if ~isvalid(fig), break; end
                act = getappdata(fig,'peak_action');
                if isempty(act) || strcmp(act.type,'done'), break; end
                if strcmp(act.type,'thresh') && in_session   % visual threshold set on waterfall
                    nav = struct('type','thresh','level',act.x);
                    break;
                end
                if strcmp(act.type,'goto')       % waterfall click → another level
                    if in_session && act.x ~= level_counter
                        nav = struct('type','goto','level',act.x);
                        break;
                    end
                    continue;
                end
                if strcmp(act.type,'restore')   % Wave button on an absent wave
                    k_r = act.x;  pr = [2*k_r-1, 2*k_r];
                    sig_inds_manual(pr)      = absent_stash(pr);
                    sig_inds_constrained(pr) = absent_stashc(pr);
                    absent(k_r) = false;
                    continue;
                end
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
                    % Zoom on current position so user can place the new point accurately
                    t_sel_cur = t_signal(sig_inds_manual(sel));
                    ax_e = fresh_uiaxes(ax_e, fig);
                    draw_edit(ax_e, t_signal, signal, sig_inds_constrained, sig_inds_manual, ...
                        idx_sig_inds, wave_sel, shapes, colors(5:end,:), num_waves, sel, ...
                        sprintf('%s  @  %d dB SPL — click NEW position for Wave %s (%s)', ...
                                freq_str, levels(level_counter), waves_legend(wave_k), pt_type), ...
                        x_units, y_units, [t_sel_cur-2, t_sel_cur+2]);
                    peak_ui.status_lbl.Text = sprintf( ...
                        'Wave %s (%s) selected — click waveform to place new position, or "Mark Absent" if no wave is present', ...
                        waves_legend(wave_k), pt_type);
                    set_confirm(peak_ui, false);
                    peak_ui_ready(peak_ui);
                    if has_absent_btn
                        peak_ui.absent_btn.Text    = sprintf('∅ Wave %s Absent', waves_legend(wave_k));
                        peak_ui.absent_btn.Enable  = 'on';
                        peak_ui.absent_btn.Visible = 'on';
                    end
                    drawnow;

                    setappdata(fig,'peak_action',[]);
                    uiwait(fig);
                    if isvalid(ax_e), ax_e.ButtonDownFcn = []; end  % block stale clicks
                    peak_ui_busy(peak_ui, 'Snapping to nearest peak…');
                    drawnow;
                    if ~isvalid(fig), inner_done=true; done_editing=true; break; end
                    act2 = getappdata(fig,'peak_action');
                    if has_absent_btn, peak_ui.absent_btn.Visible = 'off'; end
                    if isempty(act2), continue; end
                    if strcmp(act2.type,'done'), inner_done=true; done_editing=true; break; end
                    if strcmp(act2.type,'thresh') && in_session
                        nav = struct('type','thresh','level',act2.x);
                        inner_done = true;  done_editing = true;  break;
                    end
                    if strcmp(act2.type,'goto')
                        if in_session && act2.x ~= level_counter
                            nav = struct('type','goto','level',act2.x);
                            inner_done = true;  done_editing = true;  break;
                        end
                        continue;
                    end
                    if strcmp(act2.type,'absent')
                        pr = [2*wave_k-1, 2*wave_k];
                        absent_stash(pr)  = sig_inds_manual(pr);
                        absent_stashc(pr) = sig_inds_constrained(pr);
                        sig_inds_manual(pr)      = NaN;
                        sig_inds_constrained(pr) = NaN;
                        absent(wave_k) = true;
                        inner_done = true;
                        continue;
                    end
                    if ~strcmp(act2.type,'click'), continue; end

                    % Snap threshold from dropdown
                    [~,new_idx] = min(abs(t_signal - act2.x));
                    snap_thr = snap_thr_from_ui(peak_ui);
                    if mod(sel,2)==1
                        new_idx = snap_to_peak(new_idx, pks_locs, peaks_p, snap_thr);
                    else
                        new_idx = snap_to_peak(new_idx, vals_locs, vals_p,  snap_thr);
                    end
                    old_idx = sig_inds_manual(sel);
                    sig_inds_manual(sel) = new_idx;

                    % Zoomed confirm view
                    t_new = t_signal(new_idx);
                    ax_e = fresh_uiaxes(ax_e, fig);
                    draw_edit(ax_e, t_signal, signal, sig_inds_constrained, sig_inds_manual, ...
                        idx_sig_inds, wave_sel, shapes, colors(5:end,:), num_waves, sel, ...
                        sprintf('%s  @  %d dB SPL — Accept, Redo, or Cancel?', freq_str, levels(level_counter)), ...
                        x_units, y_units, [t_new-2, t_new+2]);
                    peak_ui.status_lbl.Text = sprintf( ...
                        'Wave %s (%s) — Accept new position, Redo, or Cancel', waves_legend(wave_k), pt_type);
                    set_confirm(peak_ui, true);
                    peak_ui_ready(peak_ui);
                    drawnow;

                    setappdata(fig,'peak_action',[]);
                    uiwait(fig);
                    if isvalid(ax_e), ax_e.ButtonDownFcn = []; end  % block stale clicks
                    peak_ui_busy(peak_ui, 'Processing…');
                    drawnow;
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
                        case 'thresh'            % unconfirmed move is discarded
                            sig_inds_manual(sel) = old_idx;
                            if in_session
                                nav = struct('type','thresh','level',act3.x);
                                inner_done = true;  done_editing = true;
                            end
                        case 'goto'              % unconfirmed move is discarded
                            sig_inds_manual(sel) = old_idx;
                            if in_session && act3.x ~= level_counter
                                nav = struct('type','goto','level',act3.x);
                                inner_done = true;  done_editing = true;
                            end
                    end
                end  % while ~inner_done
            end  % while ~done_editing

            % Sanitise: clamp any out-of-bounds manual indices
            oob = sig_inds_manual < 1 | sig_inds_manual > length(signal);
            sig_inds_manual(oob & idx_sig_inds) = sig_inds_constrained(oob & idx_sig_inds);
            if isvalid(ax_e), ax_e.ButtonDownFcn = []; end  % no clicks during waterfall render
            if has_absent_btn
                peak_ui.absent_btn.Visible = 'off';
                peak_ui.absent_btn.Text    = '∅ Mark Absent';
            end
            if isfield(peak_ui,'wave_btns')
                for wb = peak_ui.wave_btns
                    if isvalid(wb), wb.BackgroundColor = clr_wave_btn; wb.Tooltip = ''; end
                end
            end
            peak_ui_busy(peak_ui, 'Saving peaks — updating waterfall…');
            drawnow;

        end  % if ~use_app / else

        % ── Final selection ───────────────────────────────────────────────
        sig_inds      = sig_inds_manual;
        sig_inds(repelem(~wave_sel, 2)) = NaN;  % unchecked waves → NaN, not real signal values
        idx_export    = ~isnan(sig_inds);       % template-based + any user-placed
        peaks(idx_export)     = signal(sig_inds(idx_export));
        latencies(idx_export) = t_signal(sig_inds(idx_export));
        sig_inds_out          = sig_inds;

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
        if do_log && strcmp(nav.type,'done')   % log each level once, when confirmed
            peak_memory.log = [peak_memory.log; new_row];
            save(mem_file, 'peak_memory');
        end

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
                    plot(latencies(idx(1)), peaks(idx(1))+offset, shapes(k), ...
                        'Color',colors(k+4,:),'MarkerFaceColor',colors(k+4,:), ...
                        'MarkerSize',10,'LineWidth',1.5,'HandleVisibility',show);
                    plot(latencies(idx(2)), peaks(idx(2))+offset, shapes(k), ...
                        'Color',colors(k+4,:),'MarkerFaceColor','none', ...
                        'MarkerSize',11,'LineWidth',2,'HandleVisibility','off');
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

        elseif ~in_session
            % App mode (single-level): draw on embedded ax_w.
            % (In a session ABR_dtw redraws the waterfall markers itself.)
            % Offset is purely level-based so conditions at the same level overlay.
            offset_w = -(level_counter-1) * vsp;
            sig_dc   = signal - mean(signal);
            hold(ax_w,'on');
            if isfield(peak_ui,'blind') && peak_ui.blind
                wf_clr = [0.25 0.25 0.25];      % same colour for every condition
            else
                wf_clr = colors(CondIND,:);
            end
            plot(ax_w, t_signal, sig_dc+offset_w, 'LineWidth',1.5, ...
                'Color',wf_clr,'HandleVisibility','off');
            legend_str = {};
            for k = 1:num_waves
                if ~wave_sel(k), continue; end
                pair = [2*k-1, 2*k];
                if ~any(isnan(latencies(pair))) && ~any(isnan(peaks(pair)))
                    if ~wf_ud.has_legend, show = 'on'; else, show = 'off'; end
                    plot(ax_w, latencies(pair(1)), peaks(pair(1))-mean(signal)+offset_w, ...
                        shapes(k),'Color',colors(k+4,:),'MarkerFaceColor',colors(k+4,:), ...
                        'MarkerSize',8,'LineWidth',1.5,'HandleVisibility',show);
                    plot(ax_w, latencies(pair(2)), peaks(pair(2))-mean(signal)+offset_w, ...
                        shapes(k),'Color',colors(k+4,:),'MarkerFaceColor','none', ...
                        'MarkerSize',9,'LineWidth',2,'HandleVisibility','off');
                    if ~wf_ud.has_legend, legend_str{end+1} = sprintf('Wave %s',waves_legend(k)); end %#ok<AGROW>
                end
            end
            % Level label and scale bar: draw only on the first condition to reach this level
            if ~ismember(level_counter, wf_ud.levels_labeled)
                text(ax_w, 0.5, offset_w + max(sig_dc) + 0.01*vsp, sprintf('%d dB',levels(level_counter)), ...
                    'FontSize',16,'FontWeight','bold','HorizontalAlignment','left', ...
                    'VerticalAlignment','bottom');
                sb_x = 18.8;
                plot(ax_w, [sb_x sb_x], [offset_w, offset_w+1], 'k-', ...
                    'LineWidth',2.5,'HandleVisibility','off');
                text(ax_w, sb_x - 0.15, offset_w + 0.5, '1 \muV', ...
                    'FontSize',12,'FontWeight','bold', ...
                    'HorizontalAlignment','right','VerticalAlignment','middle');
                wf_ud2 = ax_w.UserData;
                wf_ud2.levels_labeled = [wf_ud2.levels_labeled, level_counter];
                ax_w.UserData = wf_ud2;
            end
            % No legend on the waterfall — the edit axes legend covers it.
            % Expand ylim to accommodate this level
            cur_yl = ylim(ax_w);
            ylim(ax_w, [min(cur_yl(1), offset_w - 0.6*vsp), cur_yl(2)]);
            drawnow;
        end

    end  % if snap_to_localminmax
end  % if ~isempty(template)
end  % function


% ── Local helper functions ────────────────────────────────────────────────

function thr = snap_thr_from_ui(peak_ui)
%SNAP_THR_FROM_UI  Snap threshold from the Snap ON/OFF toggle.
%  ON  → snap to the nearest peak/trough with prominence ≥ 3 % of max.
%  OFF → free placement (no snapping).
thr = 0.03;  % default (classic mode / no UI)
if ~isfield(peak_ui,'snap_toggle') || ~isvalid(peak_ui.snap_toggle), return; end
if ~peak_ui.snap_toggle.Value, thr = 0; end
end


function wave_select_cb(fig, pt_toggle, k, sig_inds_manual, t_signal)
%WAVE_SELECT_CB  Wave-selector button callback.
%  Resolves peak vs trough from the toggle state, then fires a synthetic
%  click at that slot's current position so the outer editing loop
%  selects it unambiguously regardless of spatial overlap.
if strcmp(pt_toggle.Text, '▲ Peak')
    slot = 2*k - 1;   % peak
else
    slot = 2*k;        % trough
end
if slot > length(sig_inds_manual), return; end
if all(isnan(sig_inds_manual([2*k-1, 2*k])))
    % Wave was marked absent → ask the editing loop to restore it
    setappdata(fig, 'peak_action', struct('type','restore','x',k));
    uiresume(fig);
    return;
end
if isnan(sig_inds_manual(slot)), return; end
x = t_signal(sig_inds_manual(slot));
setappdata(fig, 'peak_action', struct('type','click','x',x));
uiresume(fig);
end


function idx = snap_to_peak(idx, pks_locs, proms, threshold)
%SNAP_TO_PEAK  Snap idx to nearest local extremum based on prominence threshold.
%  threshold=0  → free placement, no snapping at all.
%  threshold>0  → snap to nearest peak/trough with prominence >= threshold*max.
%                 Higher threshold = only prominent peaks qualify.
if threshold <= 0 || isempty(pks_locs) || isempty(proms), return; end
max_p = max(proms);
if max_p <= 0, return; end
cands = pks_locs(proms / max_p >= threshold);
if isempty(cands), return; end
[~, i] = min(abs(cands - idx));
idx = cands(i);
end


function new_ax = fresh_uiaxes(old_ax, fig)
%FRESH_UIAXES  Delete old edit axes and create a clean replacement.
%  delete+recreate is the only reliable way to clear UIAxes content —
%  cla, children-delete, and hold-off all fail to flush the render cache.
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


function draw_edit(ax, t, sig, inds_c, inds_m, idx_tpl, wave_sel, shapes, wave_clrs, n_waves, sel_slot, ttl, xu, yu, xlims)
%DRAW_EDIT  Render waveform + peak markers on the edit axes.
%  Markers use each wave's own colour (same as the waterfall/results).
%  Peak (P) = filled marker, trough (N) = hollow marker.
%  Blinking green dotted ring = currently selected slot for editing
% axes is always fresh (created by fresh_uiaxes) — just draw.
% HitTest='off' on all children so every click falls through to the axes
% ButtonDownFcn regardless of whether the user clicks on a marker or blank space.
hold(ax,'on');
% Compute and lock final limits before any plotting so the axes never
% auto-scales to an intermediate state.  Direct property assignment avoids
% the xlim/ylim wrapper overhead that can trip on fresh UIAxes.
vis = t >= xlims(1) & t <= xlims(2);
if any(vis), y_lo = min(sig(vis)); y_hi = max(sig(vis));
else,        y_lo = min(sig);      y_hi = max(sig); end
pad = 0.30 * max(y_hi - y_lo, eps);
ax.XLim = xlims;
ax.YLim = [y_lo - pad, y_hi + pad];
xlabel(ax, xu, 'FontWeight','bold','FontSize',15);
ylabel(ax, yu, 'FontWeight','bold','FontSize',15);
grid(ax,'on');
set(ax,'FontSize',13);
plot(ax, t, sig, 'k', 'LineWidth',1.5, 'HandleVisibility','off', 'HitTest','off');
for k = 1:n_waves
    if ~wave_sel(k), continue; end
    for j = [2*k-1, 2*k]
        if isnan(inds_m(j)), continue; end
        is_peak = mod(j,2) == 1;   % odd = peak (P), even = trough (N)
        clr = wave_clrs(k,:);
        if is_peak, ms = 10; fc = clr;     % peak: filled marker
        else,       ms = 11; fc = 'none';  % trough: hollow marker
        end
        plot(ax, t(inds_m(j)), sig(inds_m(j)), shapes(k), ...
            'Color',clr,'MarkerSize',ms,'LineWidth',2,'MarkerFaceColor',fc, ...
            'HandleVisibility','off','HitTest','off');
    end
end
% Highlight selected slot: blinking green dotted ring around the point
stop_blink(ancestor(ax,'figure'));
if ~isempty(sel_slot) && ~isnan(inds_m(sel_slot))
    x0 = t(inds_m(sel_slot));  y0 = sig(inds_m(sel_slot));
    % Ring radius fixed in screen pixels so it stays round at any zoom
    old_un = ax.Units;  ax.Units = 'pixels';  ap = ax.InnerPosition;  ax.Units = old_un;
    r_px = 20;
    rx = r_px * diff(ax.XLim) / max(ap(3),1);
    ry = r_px * diff(ax.YLim) / max(ap(4),1);
    th = linspace(0, 2*pi, 60);
    h_ring = plot(ax, x0 + rx*cos(th), y0 + ry*sin(th), ':', ...
        'Color',[0.00 0.70 0.20], 'LineWidth',3, ...
        'HandleVisibility','off','HitTest','off');
    start_blink(ancestor(ax,'figure'), h_ring);
end
% Legend: wave shapes group, then spacer, then peak/trough group
wl = ["I","II","III","IV","V"];
leg_h   = gobjects(1, n_waves + 3);
leg_lbl = {};
ki = 0;
for k = 1:n_waves
    if ~wave_sel(k), continue; end
    ki = ki + 1;
    leg_h(ki) = plot(ax, nan, nan, shapes(k), 'Color',wave_clrs(k,:), ...
        'MarkerSize',10,'LineWidth',1.5,'MarkerFaceColor',wave_clrs(k,:));
    leg_lbl{ki} = sprintf('Wave %s', wl(k));
end
% Spacer, then peak/trough example using first selected wave shape
first_k = find(wave_sel, 1);
if ~isempty(first_k)
    ki = ki + 1;
    leg_h(ki) = plot(ax, nan, nan, 'Color','none','LineStyle','none');
    leg_lbl{ki} = ' ';
    ki = ki + 1;
    leg_h(ki) = plot(ax, nan, nan, shapes(first_k), 'Color','k', ...
        'MarkerSize',10,'LineWidth',1.5,'MarkerFaceColor','k');
    leg_lbl{ki} = 'Peak';
    ki = ki + 1;
    leg_h(ki) = plot(ax, nan, nan, shapes(first_k), 'Color','k', ...
        'MarkerSize',11,'LineWidth',2,'MarkerFaceColor','none');
    leg_lbl{ki} = 'Trough';
end
if ki > 0
    lg = legend(ax, leg_h(1:ki), leg_lbl, 'Location','northeast', ...
        'Orientation','horizontal','FontSize',12);
    legend(ax,'boxoff');
    lg.HitTest       = 'off';
    lg.PickableParts = 'none';
end
set(ax,'FontSize',13);
end


function set_confirm(peak_ui, show_confirm)
%SET_CONFIRM  Toggle between "Done" button and Accept/Redo/Cancel buttons.
if show_confirm
    peak_ui.accept_btn.Visible = 'on';
    peak_ui.redo_btn.Visible   = 'on';
    peak_ui.cancel_btn.Visible = 'on';
    peak_ui.done_btn.Visible   = 'off';
    if isfield(peak_ui,'thresh_btn') && isvalid(peak_ui.thresh_btn)
        peak_ui.thresh_btn.Visible = 'off';   % shares a slot with Redo
    end
else
    peak_ui.accept_btn.Visible = 'off';
    peak_ui.redo_btn.Visible   = 'off';
    peak_ui.cancel_btn.Visible = 'off';
    peak_ui.done_btn.Visible   = 'on';
    if isfield(peak_ui,'thresh_btn') && isvalid(peak_ui.thresh_btn)
        peak_ui.thresh_btn.Visible = 'on';
    end
end
end


function start_blink(fig, h)
%START_BLINK  Toggle visibility of graphics object h every 0.4 s.
%  One blink timer per figure (stored in appdata); it deletes itself as
%  soon as h is gone (axes recreated) or stop_blink is called.
stop_blink(fig);
tmr = timer('Name','APAT_peak_blink', 'ExecutionMode','fixedSpacing', ...
    'Period',0.4, 'BusyMode','drop', ...
    'TimerFcn',@(src,~) blink_tick(src, h));
setappdata(fig, 'peak_blink_timer', tmr);
start(tmr);
end


function blink_tick(tmr, h)
if ~isvalid(h)
    stop(tmr); delete(tmr);
    return;
end
if strcmp(h.Visible,'on'), h.Visible = 'off'; else, h.Visible = 'on'; end
end


function stop_blink(fig)
%STOP_BLINK  Stop and delete the selection blink timer (if any).
if isempty(fig) || ~isvalid(fig), return; end
tmr = getappdata(fig, 'peak_blink_timer');
if ~isempty(tmr) && isvalid(tmr)
    stop(tmr); delete(tmr);
end
setappdata(fig, 'peak_blink_timer', []);
end


function peak_ui_busy(peak_ui, msg)
%PEAK_UI_BUSY  Enter loading/processing state — disables all interaction.
if isempty(peak_ui) || ~isstruct(peak_ui) || ~isvalid(peak_ui.fig), return; end
if nargin < 2 || isempty(msg), msg = 'Please wait…'; end
stop_blink(peak_ui.fig);   % no blinking selection while busy
peak_ui.status_lbl.Text      = msg;
peak_ui.status_lbl.FontColor = [0.72 0.35 0.00];   % amber
peak_ui.done_btn.Enable      = 'off';
peak_ui.accept_btn.Enable    = 'off';
peak_ui.redo_btn.Enable      = 'off';
peak_ui.cancel_btn.Enable    = 'off';
if isfield(peak_ui,'wave_btns')
    for wb = peak_ui.wave_btns
        if isvalid(wb), wb.Enable = 'off'; end
    end
end
if isfield(peak_ui,'pt_toggle') && isvalid(peak_ui.pt_toggle)
    peak_ui.pt_toggle.Enable = 'off';
end
if isfield(peak_ui,'snap_toggle') && isvalid(peak_ui.snap_toggle)
    peak_ui.snap_toggle.Enable = 'off';
end
if isfield(peak_ui,'absent_btn') && isvalid(peak_ui.absent_btn)
    peak_ui.absent_btn.Enable = 'off';
end
end


function peak_ui_ready(peak_ui)
%PEAK_UI_READY  Restore interactive state — re-enables buttons and resets
%   the status label colour to normal.
if isempty(peak_ui) || ~isstruct(peak_ui) || ~isvalid(peak_ui.fig), return; end
peak_ui.status_lbl.FontColor = [0.08 0.08 0.08];   % normal dark
peak_ui.done_btn.Enable      = 'on';
peak_ui.accept_btn.Enable    = 'on';
peak_ui.redo_btn.Enable      = 'on';
peak_ui.cancel_btn.Enable    = 'on';
if isfield(peak_ui,'wave_btns')
    for wb = peak_ui.wave_btns
        if isvalid(wb), wb.Enable = 'on'; end
    end
end
if isfield(peak_ui,'pt_toggle') && isvalid(peak_ui.pt_toggle)
    peak_ui.pt_toggle.Enable = 'on';
end
if isfield(peak_ui,'snap_toggle') && isvalid(peak_ui.snap_toggle)
    peak_ui.snap_toggle.Enable = 'on';
end
end
