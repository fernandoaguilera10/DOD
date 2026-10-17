function RunButtonPushed(app)
%RUNBUTTONPUSHED  Validate inputs, build cfg struct, and launch analysis_run.
%   Only one run at a time: the button is locked from the first line (a
%   click queued while a run is starting or running would otherwise start
%   the analysis again inside the running one). A second press tells the
%   user the analysis is already running. Progress, elapsed time and Stop
%   are in the header status card (private/run_status.m).

% "Save & Update Average" (Exclusions window): only the given analyses,
% from the saved results (no re-analysis)
ov = [];
if isappdata(app.UIFigure, 'apat_run_override')
    ov = getappdata(app.UIFigure, 'apat_run_override');
    rmappdata(app.UIFigure, 'apat_run_override');
end

% ── One run at a time ─────────────────────────────────────────────────
if isappdata(app.UIFigure, 'apat_running') && isequal(getappdata(app.UIFigure, 'apat_running'), true)
    uialert(app.UIFigure, ['An analysis is already running. Its progress is shown at the ' ...
        'top right of the window; press Stop there to end it, or wait for it to finish ' ...
        'before starting another run.'], 'Analysis Running', 'Icon','info');
    return
end
setappdata(app.UIFigure, 'apat_running', true);
app.RunButton.Enable = 'off';                     % lock at once (busy look set by run_status)
unlock = onCleanup(@() unlock_if_idle(app)); %#ok<NASGU> validation errors / crashes unlock

% ── Validate inputs ───────────────────────────────────────────────────
ROOTdir = strtrim(app.RootDirField.Value);
if isempty(ROOTdir)
    uialert(app.UIFigure,'Root directory is required.','Missing Field'); return
end
if isempty(sheet_sel(app, 'on_screen')) || isempty(app.state.conds_all)
    uialert(app.UIFigure,'Load the chinroster and select an experiment first.','Not Ready'); return
end
% Experiments (roster sheets) to run: every selected one, roster order;
% each with its own subjects / conditions (private/sheet_sel.m 'run_set').
% "Save & Update Average" re-runs only the sheet of the Results on screen.
sheet_sel(app, 'store');
sheets = sheet_sel(app, 'selected');
if isstruct(ov) && isfield(app.res, 'run_sheet') && any(strcmp(sheets, app.res.run_sheet))
    sheets = {app.res.run_sheet};
end
if isempty(sheets), sheets = {sheet_sel(app, 'on_screen')}; end
multi = numel(sheets) > 1;
sets = struct([]);
for si = 1:numel(sheets)
    S = sheet_sel(app, 'run_set', sheets{si});
    pre = '';  if multi, pre = sprintf('Experiment %s: ', sheets{si}); end
    if isempty(S.conds_all)
        uialert(app.UIFigure, sprintf('%sthe roster sheet could not be read.', pre), 'Not Ready'); return
    end
    if isempty(S.Chins2Run)
        uialert(app.UIFigure, sprintf('%sSelect at least one subject.', pre), 'No Subjects'); return
    end
    if isempty(S.Conds2Run)
        uialert(app.UIFigure, sprintf('%sSelect at least one condition.', pre), 'No Conditions'); return
    end
    if isempty(sets), sets = S; else, sets(end+1) = S; end %#ok<AGROW>
end
S0 = sheet_sel(app, 'run_set', sheet_sel(app, 'on_screen'));   % saved as last run's lists
Chins2Run = S0.Chins2Run;  Conds2Run = S0.Conds2Run;

% ── Analyses to run (Setup: every selected measure / subtype, in order) ──
runs = run_list(app);
if isstruct(ov) && isfield(ov, 'runs') && ~isempty(ov.runs), runs = ov.runs; end
no_rean = isstruct(ov) && isfield(ov, 'no_reanalyze') && ov.no_reanalyze;
setappdata(app.UIFigure, 'apat_no_reanalyze', no_rean);
clr_nr = onCleanup(@() clear_no_reanalyze(app)); %#ok<NASGU>
if isempty(runs)
    uialert(app.UIFigure, 'Select at least one analysis (a measure button, then its type).', ...
        'No Analysis Selected'); return
end
for ri = 1:size(runs,1)                           % ABR: each type needs a frequency
    if runs(ri,1) == 1 && isfield(app.state,'abr_freq') && ~any(app.state.abr_freq{runs(ri,2)})
        uialert(app.UIFigure, sprintf(['ABR %s has no frequencies selected. Select at least one ' ...
            'frequency (or All) for it, or remove it from the run.'], app.MEASURES(1).subtypes{runs(ri,2)}), ...
            'No Frequencies'); return
    end
end

% Save profile + last settings before running
pname = get_profile_name(app);
if ~isempty(pname)
    profile_ops(app, 'save_current', pname);
    app.last_user = pname;
    profile_ops(app, 'save_to_file');
end
settings_ops(app, 'save', Chins2Run, Conds2Run);

% ── Run them one after another: Experiments (outer) × analyses ────────
% Results keep the views of EVERY Experiment of the run (private/res_exp.m:
% one set of host panels per Experiment, the others hidden; Plot Settings
% "Experiment" buttons switch). A new run starts from empty Results; "Save &
% Update Average" re-runs only the Experiment on screen and keeps the
% others. Each run_one clears its measure in its Experiment's set. Averages of
% every sheet share one file per average in Analysis/<Measure>/Average/
% (Experiment = a column / a field of `average`): the CSV row store is
% emptied only by the first run_one of the whole run (cfg.csv_keep).
nA = size(runs, 1);  nE = numel(sets);  nR = nA * nE;
if ~isstruct(ov), res_exp(app, 'reset'); end      % new run: Results of earlier runs cleared
app.abort_requested = false;
setappdata(app.UIFigure, 'peak_abort', false);
% Errors during the run: logged in Analysis/APAT_error_log.txt + a notice
% that closes itself after 15 s (no modal dialog) — the run goes on
try, apat_run_error('start', fullfile(ROOTdir, 'Analysis'), app.UIFigure); catch, end
run_status(app, 'start', run_label(app, runs(1,1), runs(1,2)), 1, nR, sets(1).sheet);
start_spinner_anim(app);
drawnow;
errs = false(1, nR);  n_done = 0;  ii = 0;
try                                               % Results Shading starts as Setup → Output says
    po = output_opts(app, 'get');  app.res.xgroup_on = logical(po.plot.shading);
catch
end
for si = 1:nE
    for ri = 1:nA
        if ~isvalid(app) || app.abort_requested, break; end
        ii = ii + 1;
        run_status(app, 'phase', run_label(app, runs(ri,1), runs(ri,2)), ii, nR, sets(si).sheet);
        errs(ii) = run_one(app, ROOTdir, sets(si), runs(ri,1), runs(ri,2), ii == 1);
        if isvalid(app) && ~app.abort_requested, n_done = n_done + 1; end
    end
    if ~isvalid(app) || app.abort_requested, break; end
end

if isvalid(app)
    if ~isempty(app.PeakEditPanel) && isvalid(app.PeakEditPanel)
        app.PeakEditPanel.Visible = 'off';
    end
    stop_spinner_anim(app);
    n_err = 0;  try, n_err = apat_run_error('count'); catch, end
    if app.abort_requested
        run_status(app, 'stopped', n_done, nR);    % shows what has been analysed so far
        app.TabGroup.SelectedTab = app.ResultsTab;
    elseif any(errs)
        run_status(app, 'error', nnz(errs), nR, n_err);
    else
        run_status(app, 'done', nR, nR, n_err);    % "Done · 2 errors — see APAT_error_log.txt"
    end
    setappdata(app.UIFigure, 'peak_abort', false);
end
end


function runs = run_list(app)
%RUN_LIST  Selected analyses as rows [measure subtype], in Setup order
%   (ABR Thresholds, ABR Peaks, EFR dAM, EFR RAM, DPOAE, SFOAE, TEOAE, MEMR).
%   Falls back to the measure / type on screen when nothing is stored.
runs = zeros(0, 2);
sel = {};
if isfield(app.state, 'run_sel'), sel = app.state.run_sel; end
for m = 1:numel(app.MEASURES)
    nk = max(1, numel(app.MEASURES(m).subtypes));
    for k = 1:nk
        if numel(sel) >= m && numel(sel{m}) >= k && sel{m}(k), runs(end+1,:) = [m k]; end %#ok<AGROW>
    end
end
if isempty(runs) && ~isfield(app.state, 'run_sel')
    runs = [app.state.measure_idx, app.state.subtype_idx];
end
end


function s = run_label(app, m, k)
%RUN_LABEL  'ABR Thresholds', 'EFR RAM', 'DPOAE', 'MEMR' …
M = app.MEASURES(m);
if strcmp(M.name,'MEMR'), s = ['MEMR ' M.subtypes{k}];      % MEMR ART, MEMR Vector …
elseif isempty(M.subtypes), s = M.name;
elseif any(strcmp(M.name, {'ABR','EFR'})), s = [M.name ' ' M.subtypes{k}];
else, s = M.subtypes{k};
end
end


function analysis_errored = run_one(app, ROOTdir, S, m_sel, k_sel, first_run)
%RUN_ONE  One analysis (measure m_sel, subtype k_sel) of one Experiment S
%   (sheet_sel 'run_set': sheet, Chins2Run, Conds2Run, conds_all,
%   cond_colors, cond_markers): clears that measure's Results panels (in
%   the Experiment's own set, res_exp 'activate'), builds
%   cfg from the Setup parameters and calls analysis_run. Returns true if it
%   stopped with an error (or was stopped by the user).
Chins2Run = S.Chins2Run;  Conds2Run = S.Conds2Run;
EXPname  = app.MEASURES(m_sel).name;
subs     = app.MEASURES(m_sel).subtypes;
EXPname2 = [];
if ~isempty(subs), EXPname2 = subs{k_sel}; end
% MEMR ART runs exactly as before (no subtype); the exploratory MEMR
% analyses pass their name ('Vector', 'Growth', …)
if strcmp(EXPname,'MEMR') && k_sel == 1, EXPname2 = []; end
chinroster_filename = app.RosterDropdown.Value;
reanalyze           = app.ReanalyzeCheck.Value;
if isappdata(app.UIFigure, 'apat_no_reanalyze') && isequal(getappdata(app.UIFigure, 'apat_no_reanalyze'), true)
    reanalyze = false;                            % Update Average: use the saved results
end
plot_relative_flag  = app.PlotRelativeCheck.Value;
sheet               = S.sheet;
res_exp(app, 'activate', S.sheet);              % this Experiment's Results views become current
app.res.run_sheet   = S.sheet;                  % Experiment of the Results on screen

% ── Derive measure label and index ───────────────────────────────────
switch EXPname
    case {'ABR','EFR'},  measure_lbl = [EXPname ' ' EXPname2];
    case 'OAE',          measure_lbl = EXPname2;
    case 'MEMR'                                   % 'MEMR' = ART; 'MEMR Vector' …
        measure_lbl = 'MEMR';
        if ~isempty(EXPname2), measure_lbl = ['MEMR ' EXPname2]; end
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
    if isfield(app.state,'abr_freq') && numel(app.state.abr_freq) >= k_sel
        sel = logical(app.state.abr_freq{k_sel});   % Thresholds / Peaks have their own selection
        sel(end+1:numel(all_freqs)) = false;  sel = sel(1:numel(all_freqs));
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

% OAE band averaging / display / analysis options — read from the Setup panel by Tag
oae_opts_cfg = struct();
if ~isempty(app.h_oae_param_panel) && isvalid(app.h_oae_param_panel)
    gv = @(tag, def) efr_val(app.h_oae_param_panel, tag, def);
    oae_opts_cfg.bands_per_oct = gv('oae_bpo', 2);
    oae_opts_cfg.frange        = sort([gv('oae_fmin',0.5), gv('oae_fmax',16)]);
    oae_opts_cfg.method        = gv('oae_method', 'snrw');
    oae_opts_cfg.y_measure     = gv('oae_ymeas', 'amp');
    oae_opts_cfg.snr_on        = logical(gv('oae_snr_btn', true));
    oae_opts_cfg.snr_min       = gv('oae_snr_min', 6);
    oae_opts_cfg.min_frac      = gv('oae_min_frac', 50);
    oae_opts_cfg.regions       = sort([gv('oae_reg1',0.5), gv('oae_reg2',2), gv('oae_reg3',8), gv('oae_reg4',16)]);
    oae_opts_cfg.gate_avg      = gv('oae_gate_avg', 'include');
    oae_opts_cfg.save_epl      = logical(gv('oae_save_epl', true));
    oae_opts_cfg.save_spl      = logical(gv('oae_save_spl', true));
    oae_opts_cfg.dp_win        = gv('oae_dp_win', 0.25);
    oae_opts_cfg.dp_npts       = gv('oae_dp_npts', 512);
    oae_opts_cfg.dp_ar         = gv('oae_dp_ar', 3);
    oae_opts_cfg.sf_win        = gv('oae_sf_win', 0.038);
    oae_opts_cfg.sf_npts       = gv('oae_sf_npts', 512);
    oae_opts_cfg.sf_ar         = gv('oae_sf_ar', 4);
    oae_opts_cfg.sf_hp         = gv('oae_sf_hp', 300);
    oae_opts_cfg.sf_nf         = gv('oae_sf_nf', 'adjacent');
    oae_opts_cfg.te_hp         = gv('oae_te_hp', 200);
    oae_opts_cfg.te_trim       = gv('oae_te_trim', 20);
end

% ── Rebuild the peak-editor axes at their original layout ───────────────
% ABR_dtw/findPeaks_dtw delete + recreate the waterfall and edit uiaxes
% while editing, so after a run the app properties point to deleted objects
% and replacement axes may be left behind. Start every run from a clean
% editor: remove every axes in the panel and recreate both exactly where
% createComponents placed them (same layout in blind and normal mode).
if ~isempty(app.PeakEditPanel) && isvalid(app.PeakEditPanel)
    old_ax = findall(app.PeakEditPanel, 'Type', 'axes');
    if ~isempty(old_ax), delete(old_ax); end
    wf_pos = getappdata(app.PeakEditPanel, 'wf_ax_pos');
    ed_pos = getappdata(app.PeakEditPanel, 'edit_ax_pos');
    if isempty(wf_pos) || isempty(ed_pos)
        % Panel built by an older createComponents: same formulas as there
        PAD = 12;  INFO_H = 32;  CTRL_H = 40 + 26 + 3*PAD;
        pp  = app.PeakEditPanel.Position;  FIG_W = pp(3);  TAB_H = pp(4);
        WF_W = round(0.36*FIG_W);  EDIT_X = PAD + WF_W + 3*PAD;
        wf_pos = [PAD PAD WF_W TAB_H-2*PAD];
        ed_pos = [EDIT_X CTRL_H+PAD FIG_W-EDIT_X-2*PAD TAB_H-INFO_H-3*PAD-CTRL_H];
    end
    app.PeakEditWfAx = uiaxes(app.PeakEditPanel, 'Position', wf_pos, ...
        'BackgroundColor','white', 'Box','on');
    disableDefaultInteractivity(app.PeakEditWfAx);
    title(app.PeakEditWfAx, 'Waveform Stack', 'FontSize',13, 'FontWeight','bold');
    app.PeakEditAx = uiaxes(app.PeakEditPanel, 'Position', ed_pos, ...
        'BackgroundColor','white', 'Box','on');
    disableDefaultInteractivity(app.PeakEditAx);
    % positions above are at build size: record them and scale the axes to
    % the window as it is now (private/relayout_results 'peak')
    try
        sc = [1 1];
        if isappdata(app.PeakEditPanel, 'apat_pe_scale'), sc = getappdata(app.PeakEditPanel, 'apat_pe_scale'); end
        setappdata(app.PeakEditWfAx, 'apat_p0', wf_pos);
        setappdata(app.PeakEditAx,   'apat_p0', ed_pos);
        app.PeakEditWfAx.Position = wf_pos .* [sc sc];
        app.PeakEditAx.Position   = ed_pos .* [sc sc];
        relayout_results(app, 'peak');
    catch
    end
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
cfg.oae_opts          = oae_opts_cfg;
cfg.blind             = logical(app.BlindCheck.Value);
% left out of the averages: only the stored pairs of THIS run (this
% Experiment's subjects / conditions; subject IDs belong to a roster sheet —
% stored pairs of other subjects stay stored but are not passed on)
cfg.exclude           = exclusions(app, 'for_run', measure_lbl, Chins2Run, Conds2Run);
cfg.cond_colors       = struct('paths',{S.conds_all}, 'rgb',S.cond_colors);
% Condition markers chosen in Setup (chinroster_ops style popup): MATLAB
% marker codes per condition path; analysis_run puts them into `shapes`
cmk = S.cond_markers;
cfg.cond_markers      = struct('paths',{S.conds_all}, 'mk',{cmk});
% ABR Parameters → Repeated Levels: 'all' (every recording) | 'average'
cfg.abr_dup_levels    = dd_value(app, 'abr_dup_dd', 'all');
out_o = struct('export_fmt','mat', 'plot',apat_plot_defaults('defaults'));   % Setup → Output
try, out_o = output_opts(app, 'get'); catch, end
cfg.export_fmt        = out_o.export_fmt;   % 'mat' | 'csv' | 'both' (also root appdata APAT_export_fmt)
cfg.plot_defaults     = out_o.plot;         % images + plot defaults (also root appdata APAT_plot_defaults)
cfg.csv_keep          = ~first_run;         % keep the CSV rows of the earlier Experiments of this run
app.state.plot_defaults = out_o.plot;       % Results strips start like the saved images
app.res.run_conds     = cfg.cond_colors;    % colours of this run (Results Conditions buttons)
app.res.run_conds.markers = cmk;            % + markers (cond_filter; sheet may not be on screen)
app.res.run_conds.sel = S.Conds2Run;        % conditions run (exclusions: relative reference)
app.res.run_conds.subj = Chins2Run;         % subjects run (exclusions shown / counted only for these)
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
    % Earl reference mode from the Ref dropdown (kept between runs)
    if ~isempty(app.PeakEditRefDD) && isvalid(app.PeakEditRefDD)
        setappdata(fig_, 'peak_ref_mode', app.PeakEditRefDD.Value);
    end
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
% Several raw recordings in a folder: rule read by choose_recording (via load_files)
% (OAE / MEMR Parameters → Data File; calibration = closest before the data file)
setappdata(0, 'APAT_rec_policy', dd_value(app, 'rec_data_dd', 'complete'));
setappdata(0, 'APAT_cal_policy', 'latest');      % calibration: closest before the data file (no setting)
% Output (Setup → Output card): data export format, image saving and the
% plot defaults applied by apat_save_fig / apat_plot_defaults
setappdata(0, 'APAT_export_fmt', cfg.export_fmt);
setappdata(0, 'APAT_plot_defaults', cfg.plot_defaults);
rec_clean = onCleanup(@() rm_rec_policy()); %#ok<NASGU>
try, apat_run_error('context', 'analysis',measure_lbl, 'subject','', 'condition','', 'blind',blind); catch, end
t_run = tic;
clr_t = onCleanup(@() log_total(t_run)); %#ok<NASGU>   % APAT_timing.csv: whole analysis
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
        % no modal alert (unattended runs): logged + self-closing notice,
        % the next analysis starts (apat_run_error)
        try, apat_run_error('error', ME, 'analysis stopped'); catch, end
        if blind
            run_log = sprintf('%s\n\nERROR: %s\n%s', run_log, ME.message, ...
                strjoin(arrayfun(@(s) sprintf('  %s (line %d)', s.name, s.line), ME.stack, 'UniformOutput', false), '\n'));
        end
    end
end
if blind
    % Keep the hidden console output so nothing is lost
    try
        fid = fopen(fullfile(ROOTdir,'Analysis','APAT_blind_run_log.txt'), ternary(first_run, 'w', 'a'));
        if fid > 0, fprintf(fid, '%s', run_log); fclose(fid); end
    catch
    end
    if isvalid(app)
        app.BlindOverlayMsg.Text = ['Analysis finished. Results are still hidden — ' ...
            'unblind when you are ready to see subject and condition labels.'];
        app.BlindRevealBtn.Enable = 'on';
    end
end
end

function unlock_if_idle(app)
%UNLOCK_IF_IDLE  Run button back to normal when RunButtonPushed returns
%   without having finished a run (input checks failed, or it errored).
try
    if ~isvalid(app), return; end
    if isappdata(app.UIFigure, 'apat_running') && isequal(getappdata(app.UIFigure, 'apat_running'), true)
        try                                         % activity timer (by name: no method call here)
            t = timerfind('Name','APAT_spinner');
            if ~isempty(t), stop(t); delete(t); end
        catch
        end
        if strcmp(app.h_run.card.Visible, 'on')
            run_status(app, 'error');               % crashed after the run had started
        else
            run_status(app, 'idle');
        end
    end
catch
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


function rm_rec_policy()
if isappdata(0, 'APAT_rec_policy'), rmappdata(0, 'APAT_rec_policy'); end
if isappdata(0, 'APAT_cal_policy'), rmappdata(0, 'APAT_cal_policy'); end
if isappdata(0, 'APAT_export_fmt'), rmappdata(0, 'APAT_export_fmt'); end
if isappdata(0, 'APAT_plot_defaults'), rmappdata(0, 'APAT_plot_defaults'); end
if isappdata(0, 'APAT_experiment'), rmappdata(0, 'APAT_experiment'); end
if isappdata(0, 'APAT_subject_sex'), rmappdata(0, 'APAT_subject_sex'); end
end


function v = dd_value(app, tag, def)
%DD_VALUE  Value of a Setup dropdown found by Tag (default if missing).
v = def;
try
    h = findall(app.MeasuresPanel, 'Tag', tag);
    if ~isempty(h), v = h(1).Value; end
catch
end
end


function log_total(t_run)
%LOG_TOTAL  TOTAL row in APAT_timing.csv for one analysis (all pairs)
try
    apat_run_error('context', 'subject','', 'condition','');
    apat_timing('TOTAL', toc(t_run));
catch
end
end

function clear_no_reanalyze(app)
try
    if isvalid(app) && isappdata(app.UIFigure, 'apat_no_reanalyze')
        rmappdata(app.UIFigure, 'apat_no_reanalyze');
    end
catch
end
end
