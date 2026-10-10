function RunButtonPushed(app)
%RUNBUTTONPUSHED  Validate inputs, build cfg struct, and launch analysis_run.

% ── Validate inputs ───────────────────────────────────────────────────
ROOTdir = strtrim(app.RootDirField.Value);
if isempty(ROOTdir)
    uialert(app.UIFigure,'Root directory is required.','Missing Field'); return
end
if isempty(app.state.sheet) || isempty(app.state.conds_all)
    uialert(app.UIFigure,'Load the chinroster and select an experiment first.','Not Ready'); return
end
Chins2Run = get_checked_subjects(app);
if isempty(Chins2Run)
    uialert(app.UIFigure,'Select at least one subject.','No Subjects'); return
end
cond_sel = false(1, numel(app.h_cond_checks));
for ci = 1:numel(app.h_cond_checks)
    if isvalid(app.h_cond_checks(ci)), cond_sel(ci) = app.h_cond_checks(ci).Value; end
end
if ~any(cond_sel)
    uialert(app.UIFigure,'Select at least one condition.','No Conditions'); return
end
Conds2Run = app.state.conds_all(cond_sel);

% ── Identify measure ──────────────────────────────────────────────────
EXPname  = app.MEASURES(app.state.measure_idx).name;
subs     = app.MEASURES(app.state.measure_idx).subtypes;
EXPname2 = [];
if ~isempty(subs), EXPname2 = subs{app.state.subtype_idx}; end

chinroster_filename = app.RosterDropdown.Value;
reanalyze           = app.ReanalyzeCheck.Value;
plot_relative_flag  = app.PlotRelativeCheck.Value;
sheet               = app.state.sheet;

% Save profile + last settings before running
pname = get_profile_name(app);
if ~isempty(pname)
    profile_ops(app, 'save_current', pname);
    app.last_user = pname;
    profile_ops(app, 'save_to_file');
end
settings_ops(app, 'save', Chins2Run, Conds2Run);

% ── Derive measure label and index ───────────────────────────────────
switch EXPname
    case {'ABR','EFR'},  measure_lbl = [EXPname ' ' EXPname2];
    case 'OAE',          measure_lbl = EXPname2;
    case 'MEMR',         measure_lbl = 'MEMR';
    otherwise,           measure_lbl = EXPname;
end
meas_idx = find(strcmp(APAT_app.measure_tab_labels(), measure_lbl), 1);

% ── Clear this measure's panels (others persist) ──────────────────────
if ~isempty(meas_idx) && ~isempty(app.res.panels)
    p_ind = app.res.panels{1, meas_idx};
    if isvalid(p_ind)
        data = app.res.subj_data{meas_idx};
        for k = 1:numel(data.panels)
            if isvalid(data.panels{k}), delete(data.panels{k}); end
        end
        app.res.subj_data{meas_idx} = struct('names',{{}},'panels',{{}});
    end
    p_avg = app.res.panels{2, meas_idx};
    if isvalid(p_avg)
        delete(p_avg.Children);
        pos = p_avg.Position;
        make_placeholder(p_avg, 'Analysis running…', ...
            'Average figures appear here once the last subject is processed.');
    end
    if ~isempty(meas_idx) && app.res.meas_idx == meas_idx
        app.FigSubjDropdown.Items = {'-'};  app.FigSubjDropdown.Value = '-';
        app.FigFreqDD.Items = {'—'};        app.FigFreqDD.Value = '—';
    end
end

% ── Switch Results tab to this measure, Individual mode ───────────────
if ~isempty(meas_idx)
    navigate_results(app, 'after_ind_embed', meas_idx, '');  % switch panel + highlight btn
end
app.TabGroup.SelectedTab = app.ResultsTab;
app.RunButton.Enable   = 'off';
app.RunButton.Text     = 'Running…';
app.abort_requested    = false;
app.StopButton.Text    = '■  Stop';
app.StopButton.Enable  = 'on';
app.StopButton.Visible = 'on';
app.h_progress_label.Text    = 'Starting analysis…';
app.h_progress_label.Visible = 'on';
start_spinner_anim(app);
drawnow;

% ── Embed callbacks ───────────────────────────────────────────────────
embed_fns.analysis = @(figs, meas, subj, ~) embed_results(app, 'ind', figs, meas, subj);
embed_fns.average  = @(figs, lbl) embed_results(app, 'avg', figs, lbl);
embed_fns.progress = @(n, total, msg) update_progress(app, n, total, msg);

% ── Collect ABR parameters ────────────────────────────────────────────
abr_freq_sel      = [];
abr_levels_sel    = [];   % empty = use every level available in the data
abr_wave_sel      = [];
if strcmp(EXPname,'ABR')
    all_freqs  = [0 0.5 1 2 4 8] * 1e3;
    if ~isempty(app.h_abr_freq_checks) && any(isvalid(app.h_abr_freq_checks))
        sel = arrayfun(@(c) isvalid(c) && c.Value, app.h_abr_freq_checks);
        abr_freq_sel = all_freqs(sel);
        if isempty(abr_freq_sel), abr_freq_sel = all_freqs; end
    end
    if strcmp(EXPname2,'Peaks')
        if ~isempty(app.h_abr_wave_checks) && any(isvalid(app.h_abr_wave_checks))
            abr_wave_sel = arrayfun(@(c) isvalid(c) && c.Value, app.h_abr_wave_checks);
            if ~any(abr_wave_sel), abr_wave_sel = true(1,5); end
        end
    end
end

% ── Collect EFR parameters ────────────────────────────────────────────
efr_harmonics = [];
efr_window    = [];
if strcmp(EXPname,'EFR') && strcmp(EXPname2,'RAM')
    if ~isempty(app.h_efr_harmonics_field) && isvalid(app.h_efr_harmonics_field)
        efr_harmonics = round(app.h_efr_harmonics_field.Value);
    end
    if ~isempty(app.h_efr_window_start_field) && isvalid(app.h_efr_window_start_field) && ...
       ~isempty(app.h_efr_window_end_field)   && isvalid(app.h_efr_window_end_field)
        efr_window = [app.h_efr_window_start_field.Value, ...
                      app.h_efr_window_end_field.Value];
    end
end

% EFR harmonic sums (RAM) and dAM bands — read from the Setup panel by Tag
efr_ram_opts = struct('low',[1 4],'high',[5 16],'measure','amplitude','normalize',false);
efr_dam_bands = 16;
if ~isempty(app.h_efr_param_panel) && isvalid(app.h_efr_param_panel)
    gv = @(tag, def) efr_val(app.h_efr_param_panel, tag, def);
    efr_ram_opts.low       = sort([gv('efr_low_from',1),  gv('efr_low_to',4)]);
    efr_ram_opts.high      = sort([gv('efr_high_from',5), gv('efr_high_to',16)]);
    efr_ram_opts.measure   = gv('efr_sum_dd','amplitude');
    efr_ram_opts.normalize = logical(gv('efr_norm_btn',false));
    efr_dam_bands          = gv('efr_dam_bands',16);
end

% ── Build cfg and run ─────────────────────────────────────────────────
clc;
cfg                   = struct();
cfg.EXPname           = EXPname;
cfg.EXPname2          = EXPname2;
cfg.plot_relative     = plot_relative_flag;
cfg.reanalyze         = reanalyze;
cfg.embed_fns         = embed_fns;
cfg.abr_freq          = abr_freq_sel;
cfg.abr_levels        = abr_levels_sel;
cfg.abr_wave_sel      = abr_wave_sel;
cfg.efr_harmonics     = efr_harmonics;
cfg.efr_window        = efr_window;
cfg.efr_ram_opts      = efr_ram_opts;
cfg.efr_dam_bands     = efr_dam_bands;
cfg.blind             = logical(app.BlindCheck.Value);
cfg.cond_colors       = struct('paths',{app.state.conds_all}, 'rgb',app.state.cond_colors);
if strcmp(EXPname,'ABR') && strcmp(EXPname2,'Peaks') && ...
        ~isempty(app.PeakEditPanel) && isvalid(app.PeakEditPanel)
    cfg.peak_ui = struct( ...
        'panel',      app.PeakEditPanel, ...
        'info_lbl',   app.PeakEditInfoLabel, ...
        'wf_ax',      app.PeakEditWfAx, ...
        'ax',         app.PeakEditAx, ...
        'status_lbl', app.PeakEditStatusLabel, ...
        'accept_btn', app.PeakEditAcceptBtn, ...
        'redo_btn',   app.PeakEditRedoBtn, ...
        'cancel_btn', app.PeakEditCancelBtn, ...
        'done_btn',   app.PeakEditDoneBtn, ...
        'snap_toggle',  app.PeakEditSnapToggle, ...
        'wave_btns',  app.PeakEditWaveBtn, ...
        'pt_toggle',  app.PeakEditPtToggle, ...
        'absent_btn', app.PeakEditAbsentBtn, ...
        'thresh_btn', app.PeakEditThreshBtn, ...
        'nel_dd',     app.PeakEditNelDD, ...
        'sex_dd',     app.PeakEditSexDD, ...
        'fig',        app.UIFigure);
    % Subject sex from the chinroster's "Sex" column (prefills the editor)
    [cfg.peak_ui.sex_ids, cfg.peak_ui.sex_vals] = roster_sex( ...
        fullfile(ROOTdir,'Analysis',chinroster_filename), sheet);
else
    cfg.peak_ui = [];
end

% Reset per-run state so waterfall and auto-skip start fresh even when
% re-running the same subjects.
if ~isempty(cfg.peak_ui)
    fig_ = cfg.peak_ui.fig;
    setappdata(fig_, 'peak_last_sck', '');
    setappdata(fig_, 'peak_last_subj','');
    setappdata(fig_, 'peak_subj_sex', []);   % sex carried across conditions within a run
    % Clear waterfall UserData so the first subject always triggers a fresh clear.
    if ~isempty(app.PeakEditWfAx) && isvalid(app.PeakEditWfAx)
        app.PeakEditWfAx.UserData = [];
    end
    % Reset live-axes appdata so the first level uses the original app axes.
    setappdata(fig_, 'peak_edit_ax', []);
    setappdata(fig_, 'peak_wf_ax',   []);
end

% Close any stale MATLAB figures left over from a previous interrupted run.
% These can cause findobj/exportgraphics/copyobj to pick up bad handles.
stale_figs = findall(0, 'Type', 'figure');
stale_figs = stale_figs(~arrayfun(@(f) isa(f, 'matlab.ui.Figure'), stale_figs));
if ~isempty(stale_figs), close(stale_figs); end

% ── Blind mode: cover the Results tab and silence the Command Window ──
blind = cfg.blind;
if blind
    app.BlindOverlayMsg.Text = ['Subject and condition information is hidden while the ' ...
        'analysis runs. Subjects and conditions are processed in random order.'];
    app.BlindRevealBtn.Enable = 'off';
    app.BlindOverlay.Visible  = 'on';
    uistack(app.BlindOverlay, 'top');
else
    app.BlindOverlay.Visible  = 'off';
end

analysis_errored = false;
run_log = '';
try
    if blind
        % evalc captures all console output (subject IDs, file names) so
        % nothing identifying is printed while the user is analysing.
        run_log = evalc('analysis_run(ROOTdir, Chins2Run, Conds2Run, chinroster_filename, sheet, cfg);');
    else
        analysis_run(ROOTdir, Chins2Run, Conds2Run, chinroster_filename, sheet, cfg);
    end
catch ME
    analysis_errored = true;
    if isvalid(app) && ~strcmp(ME.identifier,'APAT:UserAbort')
        if blind
            uialert(app.UIFigure, ['The analysis stopped with an error. Details are hidden ' ...
                'in blind mode and were saved to Analysis/APAT_blind_run_log.txt.'], 'Analysis Error');
            run_log = sprintf('%s\n\nERROR: %s\n%s', run_log, ME.message, ...
                strjoin(arrayfun(@(s) sprintf('  %s (line %d)', s.name, s.line), ME.stack, 'UniformOutput', false), '\n'));
        else
            uialert(app.UIFigure, ME.message, 'Analysis Error');
        end
    end
end
if blind
    % Keep the hidden console output so nothing is lost
    try
        fid = fopen(fullfile(ROOTdir,'Analysis','APAT_blind_run_log.txt'), 'w');
        if fid > 0, fprintf(fid, '%s', run_log); fclose(fid); end
    catch
    end
    if isvalid(app)
        app.BlindOverlayMsg.Text = ['Analysis finished. Results are still hidden — ' ...
            'unblind when you are ready to see subject and condition labels.'];
        app.BlindRevealBtn.Enable = 'on';
    end
end

if isvalid(app)
    if ~isempty(app.PeakEditPanel) && isvalid(app.PeakEditPanel)
        app.PeakEditPanel.Visible = 'off';
    end
    app.RunButton.Enable   = 'on';
    app.RunButton.Text     = '▶  Run Analysis';
    app.StopButton.Visible = 'off';
    stop_spinner_anim(app, ~analysis_errored && ~app.abort_requested);
end
end


function [ids, sexes] = roster_sex(filepath, sheet)
%ROSTER_SEX  Subject IDs and sex ('M'/'F') from the chinroster sheet's
%   "Sex" column (header row found by the cell text "Sex").
ids = {};  sexes = {};
try
    rc = readcell(filepath, 'Sheet', sheet);
catch
    return
end
rc(cellfun(@(v) any(isa(v,'missing')), rc)) = {NaN};
[r, c] = find(cellfun(@(v) ischar(v) && strcmpi(strtrim(v),'Sex'), rc), 1);
if isempty(r), return; end
for i = r+1:size(rc,1)
    id = rc{i,1};  sx = rc{i,c};
    if ischar(id) && ~isempty(strtrim(id)) && ischar(sx) && ~isempty(strtrim(sx))
        ids{end+1}   = strtrim(id);                  %#ok<AGROW>
        sexes{end+1} = upper(strtrim(sx(1)));        %#ok<AGROW>
    end
end
end


function v = efr_val(panel, tag, def)
%EFR_VAL  Value of a Setup EFR control found by Tag (default if missing).
h = findall(panel, 'Tag', tag);
v = def;
if ~isempty(h) && isprop(h(1),'Value'), v = h(1).Value; end
end
