function analysis_run(ROOTdir, Chins2Run, Conds2Run, chinroster_filename, chinroster_sheet, cfg)
% ANALYSIS_RUN  Run the full analysis + summary pipeline.
%
%   analysis_run(ROOTdir, Chins2Run, Conds2Run, chinroster_filename, chinroster_sheet, cfg)
%
%   ── Required ─────────────────────────────────────────────────────────────
%   ROOTdir             Root project directory
%   Chins2Run           Cell array of subject IDs to process
%   Conds2Run           Cell array of selected condition paths
%   chinroster_filename Roster Excel filename  (inside ROOTdir/Analysis/)
%   chinroster_sheet    Worksheet name in that file
%
%   ── cfg struct  (all fields optional) ─────────────────────────────────────
%   .EXPname            'ABR'|'EFR'|'OAE'|'MEMR'     (prompts if empty)
%   .EXPname2           Subtype: 'Thresholds'|'Peaks'|'dAM'|'RAM'|
%                                'DPOAE'|'SFOAE'|'TEOAE'|
%                                MEMR: '' (ART) or 'Vector'|'Growth'|'Kinetics'|
%                                'Spectral'|'Absorbance'|'Probe'|'Quality'
%   .plot_relative      logical – plot relative to first condition    [false]
%   .reanalyze          logical – redo analysis even if output exists [false]
%   .show_figs          struct  – .analysis / .ind / .avg logicals
%   .embed_fns          struct  – .analysis / .average / .progress callbacks
%   .abr_freq           numeric – frequencies to include (Hz)
%   .abr_levels         numeric – levels to include (dB); empty = all levels in the data
%   .abr_tpl_per_level  logical – require per-level template          [false]
%   .abr_wave_sel       logical 1×5 – ABR waves to show
%   .efr_harmonics      integer – max harmonics for RAM EFR           [16]
%   .efr_window         1×2     – RAM analysis window [start end] s
%   .export_fmt         'mat'|'csv'|'both' – data files written (apat_export_fmt)
%   .csv_keep           logical – keep the CSV row store of earlier analysis_run
%                       calls (the app: every Experiment after the first of
%                       one run) so the average files hold every Experiment
%                       of the run  [false]
%   Experiment = chinroster_sheet (root appdata 'APAT_experiment'): a column
%   of every CSV row / average.individual and the field of `average` in the
%   group .mat files (apat_avg_mat); averages of all Experiments share one
%   file in Analysis/<Measure>/Average/ (figures: <name>_<Experiment>_figure).

cwd = pwd;
if nargin < 6 || isempty(cfg), cfg = struct(); end
% Run-time errors never stop the run: each failing step is logged in
% Analysis/APAT_error_log.txt with a self-closing notice (apat_run_error),
% and prompts answer themselves after 30 s (APAT_prompt_timeout).
own_err = false;
try, own_err = apat_run_error('ensure', fullfile(ROOTdir, 'Analysis')); catch, end
n_err0 = 0;  try, n_err0 = apat_run_error('count'); catch, end
setappdata(0, 'APAT_prompt_timeout', 30);
err_clean = onCleanup(@() run_state_clean(own_err)); %#ok<NASGU>
% Data export format ('mat' | 'csv' | 'both', read by apat_export_fmt) and
% the CSV row store of this run (apat_csv)
if isfield(cfg, 'export_fmt') && ~isempty(cfg.export_fmt)
    setappdata(0, 'APAT_export_fmt', char(cfg.export_fmt));
end
if ~logical(cfg_get(cfg, 'csv_keep', false))     % (several Experiments of one app run: kept)
    try, apat_csv('reset'); catch, end
end
% Experiment of this run = the roster sheet (CSV column, `average` field,
% average figure names) — see apat_csv / apat_avg_mat / apat_save_fig
setappdata(0, 'APAT_experiment', char(chinroster_sheet));
if isappdata(0, 'APAT_group'), rmappdata(0, 'APAT_group'); end   % (old group layout: no longer used)
try, apat_sex('set', []); catch, end           % read again from this run's roster below
if isappdata(0, 'APAT_abr_peak_scan'), rmappdata(0, 'APAT_abr_peak_scan'); end   % ABR Peaks y-limit cache (ABRsummary)

%% ── Plotting constants ───────────────────────────────────────────────────
shapes = ["v";"square";"diamond";"^";"o";">";"pentagram";"*";"x"];
colors = default_plot_colors();

%% ── Unpack cfg ───────────────────────────────────────────────────────────
EXPname  = cfg_get(cfg, 'EXPname',  '');
EXPname2 = cfg_get(cfg, 'EXPname2', '');
if isempty(EXPname)
    [EXPname, EXPname2] = analysis_menu;
end

plot_relative_flag = logical(cfg_get(cfg, 'plot_relative', false));
reanalyze          = logical(cfg_get(cfg, 'reanalyze',     false));
show_figs_cfg      = cfg_get(cfg, 'show_figs', struct('analysis',true,'ind',true,'avg',true));
embed_fns_in       = cfg_get(cfg, 'embed_fns', []);

% In-app mode: all figures suppressed; embed callbacks route them into tabs
use_embed = isstruct(embed_fns_in);
% In the app the Results views are saved after embedding (embed_results >
% save_view 'auto'); apat_save_fig then only records the path for them
setappdata(0, 'APAT_embed_save', use_embed);
if use_embed
    % Close hidden figures left open by an earlier, interrupted run. Plot
    % functions that look figures up by name would otherwise reuse them, and
    % a reused figure is not picked up for embedding (it existed before the
    % subject started). The app window itself is visible and is kept.
    stale = findall(0, 'Type','figure', 'Visible','off');
    stale = stale(arrayfun(@(f) ~strcmp(f.Name, 'Auditory Physiology Analysis Toolkit (APAT)'), stale));
    if ~isempty(stale), delete(stale); end
end
% If the run errors or is stopped (APAT:UserAbort), drop the hidden figures
% it made (they would never be embedded), restore the figure default and
% the folder the run started in. Nothing is done after a normal finish.
setappdata(0, 'APAT_run_finished', false);
run_figs0 = findall(0, 'Type','figure');
run_clean = onCleanup(@() cleanup_after_abort(use_embed, run_figs0, cwd)); %#ok<NASGU>
blind     = logical(cfg_get(cfg, 'blind', false));   % blind mode: hide subject/condition
if use_embed
    embed_fns          = embed_fns_in;
    show_figs.analysis = false;
    show_figs.ind      = false;
    show_figs.avg      = false;
    set(0, 'DefaultFigureVisible', 'off');
else
    show_figs = show_figs_cfg;
end

% Measure-specific parameters, extracted once and carried as a struct
mparams = get_measure_params(EXPname, EXPname2, cfg);

%% ── Relative-to-baseline setup ──────────────────────────────────────────
if plot_relative_flag
    plot_relative = Conds2Run(1);
else
    plot_relative = {};
end
if ~isempty(plot_relative)
    idx_plot_relative = ismember(plot_relative, Conds2Run);
else
    idx_plot_relative = [];
end

%% ── Directories and paths ────────────────────────────────────────────────
limits = plot_limits(EXPname, EXPname2, idx_plot_relative);

switch EXPname
    case {'ABR','EFR'},  measure_lbl = [EXPname ' ' EXPname2];
    case 'OAE',          measure_lbl = EXPname2;
    case 'MEMR'                                   % 'MEMR' = ART; exploratory: 'MEMR Vector' …
        measure_lbl = 'MEMR';
        if ~isempty(EXPname2), measure_lbl = ['MEMR ' EXPname2]; end
    otherwise,           measure_lbl = EXPname;
end
try, apat_run_error('context', 'analysis',measure_lbl, 'subject','', 'condition','', 'blind',blind); catch, end

code_sub = EXPname2;
if strcmp(EXPname, 'MEMR'), code_sub = ''; end   % all MEMR code lives under MEMR/ (Explore/ inside)
[DATAdir, OUTdir, CODEdir, PRIVATEdir] = get_directory(ROOTdir, EXPname, code_sub);
add_path_once(CODEdir, true);         % measure code (+ subfolders); only what is not on the path yet
if any(strcmp(EXPname, {'EFR','OAE'}))
    add_path_once(fileparts(CODEdir), false);  % EFR/ and OAE/ parents hold shared helpers (plot_ind_efr, oae_summary …)
end

%% ── File search patterns ─────────────────────────────────────────────────
[filepath_searchfile, datapath_searchfile] = get_file_patterns(EXPname, EXPname2);

%% ── Parse chinroster ─────────────────────────────────────────────────────
if ~isempty(search_files(OUTdir, chinroster_filename).files)
    cd(OUTdir)
    chinroster_temp = readcell(chinroster_filename, 'Sheet', chinroster_sheet);
    temp_idx = cellfun(@(x) any(isa(x,'missing')), chinroster_temp);
    chinroster_temp(temp_idx) = {NaN};
    % Subject sex (roster "Sex" column, right after Subject) for the data
    % files of this run: root appdata 'APAT_subject_sex' (apat_sex)
    try, apat_sex('set', apat_sex('read', chinroster_temp)); catch, end
    [temp_rows, temp_cols] = size(chinroster_temp);
    temp = zeros(1, temp_rows);

    for i = 1:temp_rows
        for j = 1:length(Chins2Run)
            if strcmp(chinroster_temp(i,1), Chins2Run{j})
                temp(i) = 1;
            end
        end
    end

    col_idx = zeros(1, temp_cols);
    for i = 1:temp_rows
        for j = 1:temp_cols
            if strcmp(chinroster_temp(i,j),'Baseline') || strcmp(chinroster_temp(i,j),'B')
                col_idx(j) = 1;
                row_idx = i;
            end
        end
    end
    col_idx      = find(col_idx == 1);
    conds_length = col_idx(2) - col_idx(1) - 1;
    all_temp     = chinroster_temp(row_idx, col_idx(1):col_idx(1)+conds_length);
    for i = 1:length(all_temp)
        if strcmp(all_temp{i},'Baseline') || strcmp(all_temp{i},'B')
            all_Conds2Run{i} = strcat('pre', filesep, all_temp{i});
        else
            all_Conds2Run{i} = strcat('post', filesep, all_temp{i});
        end
    end
    % Condition colours chosen in the Setup tab (matched by condition path)
    cc = cfg_get(cfg, 'cond_colors', []);
    if isstruct(cc) && isfield(cc,'paths') && isfield(cc,'rgb')
        for i = 1:length(all_Conds2Run)
            k = find(strcmp(cc.paths, all_Conds2Run{i}), 1);
            if ~isempty(k) && k <= size(cc.rgb,1), colors(i,:) = cc.rgb(k,:); end
        end
    end
    % Condition markers chosen in the Setup tab (same matching): replace the
    % default `shapes` entry of each condition (default markers = the old
    % shapes order, so nothing changes until a marker is picked)
    cm = cfg_get(cfg, 'cond_markers', []);
    if isstruct(cm) && isfield(cm,'paths') && isfield(cm,'mk') && iscell(cm.mk)
        for i = 1:min(length(all_Conds2Run), numel(shapes))
            k = find(strcmp(cm.paths, all_Conds2Run{i}), 1);
            if ~isempty(k) && k <= numel(cm.mk) && ~isempty(cm.mk{k})
                shapes(i) = string(cm.mk{k});
            end
        end
    end
    chins_idx = find(temp == 1);
    roster_conds_idx = zeros(size(all_Conds2Run));   % which all_Conds2Run entries are selected
    for i = 1:length(Conds2Run)
        for j = 1:length(all_Conds2Run)
            if strcmp(Conds2Run(i), all_Conds2Run(j))
                roster_conds_idx(j) = j;
            end
        end
    end
    Chins2Run              = chinroster_temp(chins_idx, 1);
    chinroster.ChinSex     = chinroster_temp(chins_idx, 2);
    switch EXPname
        case 'ABR',  range = col_idx(1):col_idx(1)+conds_length;
        case 'EFR',  range = col_idx(2):col_idx(2)+conds_length;
        case 'OAE'
            switch EXPname2
                case 'DPOAE', range = col_idx(3):col_idx(3)+conds_length;
                case 'SFOAE', range = col_idx(4):col_idx(4)+conds_length;
                case 'TEOAE', range = col_idx(5):col_idx(5)+conds_length;
            end
        case 'MEMR', range = col_idx(6):col_idx(6)+conds_length;
    end
    temp = chinroster_temp(:, range);
    chinroster.signal = temp(chins_idx, :);
end

%% ── Check data availability ──────────────────────────────────────────────
counter      = 0;
branch3_ran  = false;
avg_done     = false;                % the last pair's summary (group average) ran
filepath_idx      = zeros(length(Chins2Run), length(all_Conds2Run));
datapath_idx      = zeros(length(Chins2Run), length(all_Conds2Run));
subject_idx       = zeros(length(Chins2Run), length(all_Conds2Run));
add_path_once(strcat(ROOTdir, filesep, 'Code Archive'), false);
add_path_once(PRIVATEdir, false);     % Code Archive/shared (load_files, apat_* helpers) — headless callers

for ChinIND = 1:length(Chins2Run)
    for CondIND = 1:length(all_Conds2Run)
        filepath = strcat(OUTdir,  filesep, EXPname, filesep, Chins2Run{ChinIND}, filesep, all_Conds2Run{CondIND});
        datapath = strcat(DATAdir, filesep, Chins2Run{ChinIND}, filesep, EXPname, filesep, all_Conds2Run{CondIND});
        filepath_files{ChinIND,CondIND}    = search_files(filepath, filepath_searchfile).files;
        datapath_files{ChinIND,CondIND}    = search_files(datapath, datapath_searchfile).files;
        filepath_dir_temp{ChinIND,CondIND} = search_files(filepath, filepath_searchfile).dir;
        datapath_dir_temp{ChinIND,CondIND} = search_files(datapath, datapath_searchfile).dir;
        if ~isempty(filepath_files{ChinIND,CondIND}), filepath_idx(ChinIND,CondIND) = 1; end
        if ~isempty(datapath_files{ChinIND,CondIND}), datapath_idx(ChinIND,CondIND) = 1; end
        if strcmp(chinroster.signal(ChinIND,CondIND),'X') || strcmp(chinroster.signal(ChinIND,CondIND),'x')
            if ~isempty(find(roster_conds_idx == CondIND))  %#ok<EFIND>
                subject_idx(ChinIND,CondIND) = 1;
            end
        end
    end
end

%% ── Drop subjects missing their baseline (relative-to mode) ─────────────
if idx_plot_relative == 1
    missing_baseline = find(subject_idx(:, idx_plot_relative) == 0);
    Chins2Run(missing_baseline)             = [];
    chinroster.ChinSex(missing_baseline,:)  = [];
    chinroster.signal(missing_baseline,:)   = [];
    subject_idx(missing_baseline,:)         = [];
    datapath_idx(missing_baseline,:)        = [];
    filepath_idx(missing_baseline,:)        = [];
    filepath_dir_temp(missing_baseline,:)   = [];
    datapath_dir_temp(missing_baseline,:)   = [];
end

filepath_dir = cell(size(filepath_dir_temp));
datapath_dir = cell(size(datapath_dir_temp));
filepath_dir(filepath_idx == 1) = filepath_dir_temp(filepath_idx == 1);
datapath_dir(datapath_idx == 1) = datapath_dir_temp(datapath_idx == 1);
define_global_vars(Chins2Run, all_Conds2Run, EXPname, EXPname2);

%% ── Exclusions: subject / condition pairs left out of the group averages ─
% (cfg.exclude, n×2 {subject, condition|'*'}; applied by each summary
% function just before its average — apat_excl — and recorded in the
% saved average files at the end of the run)
run_t0   = now; %#ok<TNOW1>
excl_ref = '';
if ~isempty(idx_plot_relative)
    p_ref = strsplit(all_Conds2Run{1}, filesep);  excl_ref = p_ref{end};
end
apat_excl('set', cfg_get(cfg, 'exclude', {}), excl_ref);
excl_clean = onCleanup(@() apat_excl('set', {})); %#ok<NASGU>
if isappdata(0,'APAT_efr_levels'), rmappdata(0,'APAT_efr_levels'); end   % EFR level list: new per run

%% ── Main processing loop ─────────────────────────────────────────────────
n_total = sum(sum(subject_idx));

% Blind mode: random subject order and anonymous progress labels.
% (Averages don't depend on order — they trigger on the dataset counter.)
subj_order = 1:length(Chins2Run);
if blind, subj_order = subj_order(randperm(numel(subj_order))); end
blind_k = 0;

for ChinIND = subj_order
    blind_k = blind_k + 1;
    if blind
        who_lbl = sprintf('blinded subject %d / %d', blind_k, numel(subj_order));
    else
        who_lbl = Chins2Run{ChinIND};
    end
    % Conditions that are active (have data + are in subject roster) for this subject
    subj_active_conds = find(subject_idx(ChinIND,:) == 1);
    Conds2Run         = all_Conds2Run(subj_active_conds);

    if use_embed, pre_subj_figs = findall(0,'Type','figure'); end
    abr_peaks_mode = strcmp(EXPname,'ABR') && strcmp(EXPname2,'Peaks');

    if ~abr_peaks_mode
        % ── Standard single-pass loop: B2 → B1 → B3 ──────────────────────
        for i = 1:length(subj_active_conds)
            CondIND       = subj_active_conds(i);
            file_check    = filepath_idx(ChinIND, CondIND);
            data_check    = datapath_idx(ChinIND, CondIND);
            subject_check = subject_idx(ChinIND, CondIND);
            condition     = strsplit(all_Conds2Run{CondIND}, filesep);
            try, apat_run_error('context', 'subject',Chins2Run{ChinIND}, 'condition',condition{end}); catch, end
            drawnow limitrate;
            cd(CODEdir);

            % ── Branch 2: retrieve missing RAW files (data and/or calib) ───
            %    move_files returns immediately when nothing is missing, so
            %    this runs every time, not only on the first analysis.
            if subject_check == 1
                datapath = strcat(DATAdir, filesep, Chins2Run{ChinIND}, filesep, EXPname, filesep, all_Conds2Run{CondIND});
                if ~exist(datapath, 'dir')
                    fprintf('\nCreating data directory for %s (%s)...\n', Chins2Run{ChinIND}, all_Conds2Run{CondIND});
                    mkdir(datapath);
                end
                sourcepath = strcat(DATAdir, filesep, 'RAW');
                cd(CODEdir)
                try
                    t_ = tic;  move_files(Chins2Run, all_Conds2Run, ChinIND, CondIND, sourcepath, EXPname, DATAdir, CODEdir);  apat_timing('retrieve RAW', toc(t_));
                catch ME
                    step_failed(ME, 'moving RAW files');  cd(CODEdir);
                end
                new_dp = search_files(datapath, datapath_searchfile);
                if ~isempty(new_dp.files)
                    datapath_idx(ChinIND,CondIND) = 1;
                    datapath_dir{ChinIND,CondIND} = new_dp.dir;
                    data_check = 1;
                end
            end

            % ── ABR Thresholds: check if existing output is compatible ──────
            % Only force re-analysis when raw data is available (data_check==1);
            % if raw data is gone, fall through to Branch 3 with whatever exists so
            % counter stays in sync and average figures are generated correctly.
            if strcmp(EXPname,'ABR') && strcmp(EXPname2,'Thresholds') && ...
                    file_check == 1 && data_check == 1
                outdir = filepath_dir{ChinIND, CondIND};
                d = dir(fullfile(outdir, '*ABRthresholds*.mat'));
                d = d(~strncmp({d.name},'._',2));
                if ~isempty(d)
                    try
                        tmp = load(fullfile(d(1).folder, d(1).name), 'abr_out');
                        needs_rerun = false;
                        % Missing requested frequencies
                        if ~isempty(mparams.abr_freq) && ~all(ismember(mparams.abr_freq, tmp.abr_out.freqs))
                            fprintf('\nABR Thresholds: new frequencies requested for %s (%s) — re-analysing.\n', ...
                                Chins2Run{ChinIND}, all_Conds2Run{CondIND});
                            needs_rerun = true;
                        end
                        % Missing plot_data (old-format file) — needed for waveform/sigmoid tabs
                        if ~needs_rerun && (~isfield(tmp.abr_out,'plot_data') || isempty(tmp.abr_out.plot_data))
                            fprintf('\nABR Thresholds: plot_data missing for %s (%s) — re-analysing.\n', ...
                                Chins2Run{ChinIND}, all_Conds2Run{CondIND});
                            needs_rerun = true;
                        end
                        % Unrounded stimulus levels (saved before Oct 16 2026, e.g. 89.7
                        % instead of 90 dB SPL) — re-analyse so the fit uses whole dB
                        if ~needs_rerun && isfield(tmp.abr_out,'plot_data') && ~isempty(tmp.abr_out.plot_data)
                            try
                                lv = [tmp.abr_out.plot_data.lev];
                                if any(abs(lv - round(lv)) > 1e-6)
                                    fprintf('\nABR Thresholds: levels not in whole dB for %s (%s) — re-analysing.\n', ...
                                        Chins2Run{ChinIND}, all_Conds2Run{CondIND});
                                    needs_rerun = true;
                                end
                            catch
                            end
                        end
                        if needs_rerun
                            file_check = 0;
                        end
                    catch
                    end
                end
            end

            % ── Branch 1: analyse RAW → output ──────────────────────────────
            if (file_check == 0 && data_check == 1 && subject_check == 1) || reanalyze
                fprintf('\nSubject: %s (%s)\n', Chins2Run{ChinIND}, all_Conds2Run{CondIND});
                if use_embed && isfield(embed_fns,'progress')
                    cond_lbl = condition{end};
                    if blind, cond_lbl = 'hidden condition'; end
                    embed_fns.progress(max(0,counter), n_total, ...
                        sprintf('Analyzing  %s \x2014 %s  (%d / %d)', who_lbl, cond_lbl, max(0,counter), n_total));
                end
                filepath = strcat(OUTdir, filesep, EXPname, filesep, Chins2Run{ChinIND}, filesep, all_Conds2Run{CondIND});
                datapath = datapath_dir{ChinIND, CondIND};
                if ~exist(filepath, 'dir')
                    fprintf('\nCreating analysis directory for %s (%s)...\n', Chins2Run{ChinIND}, all_Conds2Run{CondIND});
                    mkdir(filepath);
                end
                pre_figs_b1 = findall(0,'Type','figure');
                set(0, 'DefaultFigureVisible', onoff(~use_embed && show_figs.analysis));

                b1_ok = true;  t_ = tic;
                try
                    run_analysis_step(EXPname, EXPname2, datapath, filepath, ...
                        Chins2Run, ChinIND, all_Conds2Run, Conds2Run, CondIND, ...
                        colors, shapes, limits, mparams, ROOTdir, CODEdir);
                catch ME
                    step_failed(ME, 'analysis');  b1_ok = false;
                end
                apat_timing('analysis', toc(t_));

                if ~use_embed, set(0,'DefaultFigureVisible','on'); end
                new_figs_b1 = setdiff(findall(0,'Type','figure'), pre_figs_b1);
                new_figs_b1 = new_figs_b1(isvalid(new_figs_b1));
                if strcmp(EXPname,'ABR') || ~use_embed
                    % ABR in the app: not embedded. Outside the app nothing
                    % embeds them (they used to be hidden and kept open).
                    if ~isempty(new_figs_b1), close(new_figs_b1); end
                else
                    if ~isempty(new_figs_b1), set(new_figs_b1, 'Visible', 'off'); end
                end
                if b1_ok
                    filepath_idx(ChinIND,CondIND) = 1;
                    filepath_dir{ChinIND,CondIND} = filepath;
                    file_check = 1;
                elseif file_check == 0
                    % no result for this pair: the average comes with the
                    % last pair that does have one
                    n_total = max(0, n_total - 1);
                end                                   % (reanalyze: the older result is used)
            end

            % ── Branch 3: load output → summary / averages ────────────────
            if file_check == 1 && subject_check == 1
                counter      = counter + 1;
                is_last_pair = (counter == n_total);

                fprintf('\nLoading Data for Averaging...\nSubject: %s (%s)\n', Chins2Run{ChinIND}, all_Conds2Run{CondIND});
                if use_embed && isfield(embed_fns,'progress')
                    cond_lbl = condition{end};
                    if blind, cond_lbl = 'hidden condition'; end
                    embed_fns.progress(counter, n_total, ...
                        sprintf('Summarizing  %s \x2014 %s  (%d / %d)', who_lbl, cond_lbl, counter, n_total));
                end
                filepath = filepath_dir{ChinIND, CondIND};
                datapath = datapath_dir{ChinIND, CondIND};
                if use_embed, pre_figs_b3 = findall(0,'Type','figure'); end
                set(0, 'DefaultFigureVisible', onoff(~use_embed && (show_figs.ind || show_figs.avg)));

                t_ = tic;
                try
                    run_summary_step(EXPname, EXPname2, filepath, datapath, OUTdir, PRIVATEdir, ...
                        Conds2Run, Chins2Run, all_Conds2Run, ChinIND, CondIND, ...
                        idx_plot_relative, limits, colors, shapes, is_last_pair, subj_active_conds, ...
                        mparams, CODEdir, ROOTdir, subject_idx, chinroster_sheet);
                    if is_last_pair, avg_done = true; end
                catch ME
                    step_failed(ME, ternary_s(is_last_pair, 'summary + group average', 'summary'));
                    cd(CODEdir);
                end
                apat_timing(ternary_s(is_last_pair, 'summary + average', 'summary'), toc(t_));

                if ~use_embed, set(0,'DefaultFigureVisible','on'); end

                if use_embed && i == length(subj_active_conds)
                    drawnow;
                    after_figs    = findall(0,'Type','figure');
                    from_subj     = setdiff(after_figs, pre_subj_figs);
                    from_subj     = from_subj(isvalid(from_subj));
                    if ~isempty(from_subj), set(from_subj, 'Visible', 'off'); end
                    new_this_call = setdiff(after_figs, pre_figs_b3);
                    new_this_call = new_this_call(isvalid(new_this_call));

                    [ind_figs, avg_figs] = split_ind_avg_figs(EXPname, from_subj, new_this_call, is_last_pair);

                    try
                        if ~isempty(ind_figs)
                            t_ = tic;  embed_fns.analysis(ind_figs, measure_lbl, Chins2Run{ChinIND}, condition{end});  apat_timing('show individual', toc(t_));
                        end
                        if is_last_pair && ~isempty(avg_figs)
                            t_ = tic;  embed_fns.average(avg_figs, measure_lbl);  apat_timing('show average', toc(t_));
                        end
                    catch ME
                        step_failed(ME, 'showing results');
                    end
                    to_close = from_subj(isvalid(from_subj));
                    if ~isempty(to_close), close(to_close); end
                end

                branch3_ran = true;
            end
        end

    else
        % ── ABR Peaks: freq-outer, cond-inner order ───────────────────────
        try, apat_run_error('context', 'subject',Chins2Run{ChinIND}, 'condition',''); catch, end
        % Pass 1: Branch 2 only (move raw files per condition)
        for i = 1:length(subj_active_conds)
            CondIND       = subj_active_conds(i);
            data_check    = datapath_idx(ChinIND, CondIND);
            subject_check = subject_idx(ChinIND, CondIND);
            drawnow limitrate;
            cd(CODEdir);
            if subject_check == 1   % move_files retrieves only what is missing
                datapath = strcat(DATAdir, filesep, Chins2Run{ChinIND}, filesep, EXPname, filesep, all_Conds2Run{CondIND});
                if ~exist(datapath, 'dir')
                    fprintf('\nCreating data directory for %s (%s)...\n', Chins2Run{ChinIND}, all_Conds2Run{CondIND});
                    mkdir(datapath);
                end
                sourcepath = strcat(DATAdir, filesep, 'RAW');
                cd(CODEdir)
                try
                    t_ = tic;  move_files(Chins2Run, all_Conds2Run, ChinIND, CondIND, sourcepath, EXPname, DATAdir, CODEdir);  apat_timing('retrieve RAW', toc(t_));
                catch ME
                    step_failed(ME, 'moving RAW files');  cd(CODEdir);
                end
                new_dp = search_files(datapath, datapath_searchfile);
                if ~isempty(new_dp.files)
                    datapath_idx(ChinIND,CondIND) = 1;
                    datapath_dir{ChinIND,CondIND} = new_dp.dir;
                end
            end
        end

        % Branch 1: collect all conditions needing analysis, call ABR_dtw
        % once with all of them so the loop order becomes freq→cond→level.
        peaks_cond_INDs = [];
        peaks_datapaths = {};
        peaks_outpaths  = {};
        for i = 1:length(subj_active_conds)
            CondIND       = subj_active_conds(i);
            file_check    = filepath_idx(ChinIND, CondIND);
            data_check    = datapath_idx(ChinIND, CondIND);
            subject_check = subject_idx(ChinIND, CondIND);
            if data_check == 1 && subject_check == 1 && (file_check == 0 || reanalyze)
                filepath = strcat(OUTdir, filesep, EXPname, filesep, Chins2Run{ChinIND}, filesep, all_Conds2Run{CondIND});
                if ~exist(filepath, 'dir')
                    fprintf('\nCreating analysis directory for %s (%s)...\n', Chins2Run{ChinIND}, all_Conds2Run{CondIND});
                    mkdir(filepath);
                end
                peaks_cond_INDs(end+1) = CondIND;          %#ok<AGROW>
                peaks_datapaths{end+1} = datapath_dir{ChinIND, CondIND}; %#ok<AGROW>
                peaks_outpaths{end+1}  = filepath;          %#ok<AGROW>
            end
        end
        if ~isempty(peaks_cond_INDs)
            fprintf('\nSubject: %s\n', Chins2Run{ChinIND});
            if use_embed && isfield(embed_fns,'progress')
                embed_fns.progress(max(0,counter), n_total, ...
                    sprintf('Analyzing  %s  (%d / %d)', who_lbl, max(0,counter), n_total));
            end
            pk_ui = mparams.peak_ui;
            if blind && isstruct(pk_ui)
                % Random condition order + anonymous labels in the peak editor
                perm = randperm(numel(peaks_cond_INDs));
                peaks_cond_INDs = peaks_cond_INDs(perm);
                peaks_datapaths = peaks_datapaths(perm);
                peaks_outpaths  = peaks_outpaths(perm);
                pk_ui.blind      = true;
                pk_ui.blind_subj = sprintf('%d / %d', blind_k, numel(subj_order));
            end
            pre_figs_b1 = findall(0,'Type','figure');
            set(0, 'DefaultFigureVisible', onoff(~use_embed && show_figs.analysis));
            b1_ok = true;  t_ = tic;
            try
                ABR_dtw(ROOTdir, CODEdir, peaks_datapaths, peaks_outpaths, Chins2Run, ChinIND, ...
                    all_Conds2Run, Conds2Run, peaks_cond_INDs, colors, shapes, ...
                    limits.ind.peaks, mparams.abr_freq, mparams.abr_levels, mparams.abr_tpl_per_level, ...
                    pk_ui, mparams.abr_wave_sel);
            catch ME
                step_failed(ME, 'analysis (ABR peaks)');  b1_ok = false;  cd(CODEdir);
            end
            apat_timing('analysis (all conditions)', toc(t_));
            if ~use_embed, set(0,'DefaultFigureVisible','on'); end
            new_figs_b1 = setdiff(findall(0,'Type','figure'), pre_figs_b1);
            new_figs_b1 = new_figs_b1(isvalid(new_figs_b1));
            if use_embed && ~isempty(new_figs_b1), close(new_figs_b1); end
            for k = 1:length(peaks_cond_INDs)
                ok_k = b1_ok;                         % after an error: only conditions with a result file
                if ~ok_k
                    try, ok_k = ~isempty(search_files(peaks_outpaths{k}, filepath_searchfile).files); catch, end
                end
                if ok_k
                    filepath_idx(ChinIND, peaks_cond_INDs(k)) = 1;
                    filepath_dir{ChinIND, peaks_cond_INDs(k)} = peaks_outpaths{k};
                elseif filepath_idx(ChinIND, peaks_cond_INDs(k)) == 0
                    n_total = max(0, n_total - 1);
                end
            end
        end

        % Pass 2: Branch 3 — run summaries for all conditions, then embed once.
        % pre_figs_b3 is captured before ANY condition's summary so that
        % new_this_call spans all conditions (for non-ABR timing-based split).
        if use_embed, pre_figs_b3 = findall(0,'Type','figure'); end
        last_condition   = '';
        last_is_last_pair = false;
        for i = 1:length(subj_active_conds)
            CondIND       = subj_active_conds(i);
            file_check    = filepath_idx(ChinIND, CondIND);
            subject_check = subject_idx(ChinIND, CondIND);
            condition     = strsplit(all_Conds2Run{CondIND}, filesep);

            if file_check == 1 && subject_check == 1
                counter      = counter + 1;
                is_last_pair = (counter == n_total);

                fprintf('\nLoading Data for Averaging...\nSubject: %s (%s)\n', Chins2Run{ChinIND}, all_Conds2Run{CondIND});
                if use_embed && isfield(embed_fns,'progress')
                    cond_lbl = condition{end};
                    if blind, cond_lbl = 'hidden condition'; end
                    embed_fns.progress(counter, n_total, ...
                        sprintf('Summarizing  %s \x2014 %s  (%d / %d)', who_lbl, cond_lbl, counter, n_total));
                end
                filepath = filepath_dir{ChinIND, CondIND};
                datapath = datapath_dir{ChinIND, CondIND};
                set(0, 'DefaultFigureVisible', onoff(~use_embed && (show_figs.ind || show_figs.avg)));

                t_ = tic;
                try
                    run_summary_step(EXPname, EXPname2, filepath, datapath, OUTdir, PRIVATEdir, ...
                        Conds2Run, Chins2Run, all_Conds2Run, ChinIND, CondIND, ...
                        idx_plot_relative, limits, colors, shapes, is_last_pair, subj_active_conds, ...
                        mparams, CODEdir, ROOTdir, subject_idx, chinroster_sheet);
                    if is_last_pair, avg_done = true; end
                catch ME
                    step_failed(ME, ternary_s(is_last_pair, 'summary + group average', 'summary'));
                    cd(CODEdir);
                end
                apat_timing(ternary_s(is_last_pair, 'summary + average', 'summary'), toc(t_));

                if ~use_embed, set(0,'DefaultFigureVisible','on'); end

                last_condition    = condition{end};
                last_is_last_pair = is_last_pair;
                branch3_ran = true;
            end
        end

        % Embed once after all conditions' summaries — captures figures from
        % every condition in from_subj regardless of which condition was last.
        if use_embed && branch3_ran
            drawnow;
            after_figs    = findall(0,'Type','figure');
            from_subj     = setdiff(after_figs, pre_subj_figs);
            from_subj     = from_subj(isvalid(from_subj));
            if ~isempty(from_subj), set(from_subj, 'Visible', 'off'); end
            new_this_call = setdiff(after_figs, pre_figs_b3);
            new_this_call = new_this_call(isvalid(new_this_call));

            [ind_figs, avg_figs] = split_ind_avg_figs(EXPname, from_subj, new_this_call, last_is_last_pair);

            try
                if ~isempty(ind_figs)
                    t_ = tic;  embed_fns.analysis(ind_figs, measure_lbl, Chins2Run{ChinIND}, last_condition);  apat_timing('show individual', toc(t_));
                end
                if last_is_last_pair && ~isempty(avg_figs)
                    t_ = tic;  embed_fns.average(avg_figs, measure_lbl);  apat_timing('show average', toc(t_));
                end
            catch ME
                step_failed(ME, 'showing results');
            end
            to_close = from_subj(isvalid(from_subj));
            if ~isempty(to_close), close(to_close); end
        end
    end
end

cd(cwd);
if use_embed, set(0,'DefaultFigureVisible','on'); end
setappdata(0, 'APAT_run_finished', true);   % normal finish: cleanup_after_abort does nothing

% A failing dataset can leave the group average undrawn (it is made with
% the last dataset's summary): say so once
try
    if branch3_ran && ~avg_done && apat_run_error('count') > n_err0
        apat_run_error('error', 'Group average not drawn: the last dataset of this analysis failed.', 'group average');
    end
catch
end

% Record the exclusions in the average files written by this run
if branch3_ran
    try, apat_excl('stamp', fullfile(OUTdir, EXPname), run_t0, Chins2Run, all_Conds2Run); catch, end
end

%% ── Analysis summary ─────────────────────────────────────────────────────
Conds2Run = all_Conds2Run;
if branch3_ran
    summary_idx = zeros(length(Chins2Run), length(Conds2Run));
    for i = 1:size(summary_idx,1)
        for j = 1:size(summary_idx,2)
            if filepath_idx(i,j) == 1 && subject_idx(i,j) == 1
                summary_idx(i,j) = 1;
            end
        end
    end
    summary = cell(length(Chins2Run), length(Conds2Run)+1);
    for i = 1:size(summary,1)
        for j = 2:size(summary,2)
            if summary_idx(i,j-1) == 1
                summary(i,j) = Conds2Run(j-1);
            end
            if j == 2
                summary(i,j-1) = Chins2Run(i);
            end
        end
    end
    fprintf('\n\nANALYSIS SUMMARY - %s (%s):\n\n', EXPname, EXPname2);
    fprintf('%-10s', 'Subject');
    for j = 1:length(Conds2Run)
        if strcmpi(all_temp{j}, 'Baseline')
            fprintf('%-10s', 'B');
        else
            fprintf('%-10s', all_temp{j});
        end
    end
    fprintf('\n');
    for i = 1:size(summary,1)
        fprintf('%-10s', summary{i,1});
        for j = 2:size(summary,2)
            if ~isempty(summary{i,j})
                fprintf('%-10s', 'YES');
            else
                fprintf('%-10s', 'NO');
            end
        end
        fprintf('\n');
    end
end
end % analysis_run


%% ════════════════════════════════════════════════════════════════════════
%  EXTENSION POINTS
%  ── To add a new measure or subtype, edit the three functions below.
%  ── Everything else (looping, file checks, embedding) is automatic.
%% ════════════════════════════════════════════════════════════════════════

function [filepath_pat, datapath_pat] = get_file_patterns(EXPname, EXPname2)
% GET_FILE_PATTERNS  Return glob patterns used to detect output and raw data files.
%
%   filepath_pat  – pattern for already-analysed output files
%   datapath_pat  – pattern for raw acquisition files
%
%   Add a new case here when adding a new measure or subtype.
switch EXPname
    case 'ABR'
        datapath_pat = '*ABR*.mat';
        switch EXPname2
            case 'Thresholds', filepath_pat = '*ABRthresholds*.mat';
            case 'Peaks',      filepath_pat = '*ABRpeaks_dtw*.mat';
            otherwise,         filepath_pat = ['*' EXPname EXPname2 '*.mat'];
        end
    case 'EFR'
        switch EXPname2
            case 'dAM'
                filepath_pat = '*EFR_dAM*.mat';
                datapath_pat = '*FFR_*AMFM*.mat';
            case 'RAM'
                filepath_pat = '*EFR_RAM*.mat';
                datapath_pat = '*FFR_RAM*.mat';
            otherwise
                filepath_pat = ['*EFR_' EXPname2 '*.mat'];
                datapath_pat = ['*FFR_' EXPname2 '*.mat'];
        end
    case 'OAE'
        filepath_pat = ['*' EXPname2 '*.mat'];
        datapath_pat = filepath_pat;
    case 'MEMR'
        datapath_pat = '*MEMR*.mat';
        if isempty(EXPname2)
            filepath_pat = '*MEMR*.mat';              % ART: <subject>_MEMR_WB_<cond>_pNNNN.mat
        else
            filepath_pat = '*_MX_*.mat';              % exploratory: <subject>_MX_<cond>_pNNNN.mat (shared)
        end
    otherwise
        filepath_pat = ['*' EXPname '*.mat'];
        datapath_pat = filepath_pat;
end
end


function mparams = get_measure_params(EXPname, EXPname2, cfg) %#ok<INUSD>
% GET_MEASURE_PARAMS  Extract measure-specific parameters from cfg with defaults.
%
%   Returns a struct whose fields are passed through to run_analysis_step
%   and run_summary_step. Defaults are defined here, not scattered across
%   the main function body.
%
%   Add a new case here when adding a new measure or subtype.
mparams = struct();
switch EXPname
    case 'ABR'
        mparams.abr_freq          = cfg_get(cfg, 'abr_freq',          [0 0.5 1 2 4 8]*1e3);
        mparams.abr_levels        = cfg_get(cfg, 'abr_levels',        []);   % [] = all available
        mparams.abr_tpl_per_level = cfg_get(cfg, 'abr_tpl_per_level', false);
        mparams.abr_wave_sel      = cfg_get(cfg, 'abr_wave_sel',      true(1,5));
        mparams.peak_ui           = cfg_get(cfg, 'peak_ui',           []);
        % Repeated Levels (Setup): 'all' = every file its own level entry,
        % 'average' = files with the same rounded level pooled (sweeps).
        % Read by ABR_thresholds / ABR_dtw / ABRsummary (re-analysis check)
        % from root appdata, so their call signatures stay unchanged.
        dl = lower(char(string(cfg_get(cfg, 'abr_dup_levels', 'all'))));
        if ~strcmp(dl, 'average'), dl = 'all'; end
        mparams.abr_dup_levels    = dl;
        setappdata(0, 'APAT_abr_dup_levels', dl);
    case 'EFR'
        mparams.efr_harmonics     = cfg_get(cfg, 'efr_harmonics', 16);
        mparams.efr_window        = cfg_get(cfg, 'efr_window',    [0.2, 0.9]);
        mparams.efr_ram_opts      = cfg_get(cfg, 'efr_ram_opts',  struct());
        mparams.efr_dam_bands     = cfg_get(cfg, 'efr_dam_bands', 16);
        % Read by efr_opts() in the EFR summary / plotting code
        eo = mparams.efr_ram_opts;  eo.dam_bands = mparams.efr_dam_bands;
        setappdata(0, 'APAT_efr_opts', eo);
    case 'OAE'
        % Band averaging / display / analysis options (Setup → OAE Parameters).
        % Read by oae_opts() in the OAE analysis, summary and plotting code.
        mparams.oae_opts = cfg_get(cfg, 'oae_opts', struct());
        setappdata(0, 'APAT_oae_opts', mparams.oae_opts);
    case 'MEMR'
        % No extra parameters currently
end
end


function run_analysis_step(EXPname, EXPname2, datapath, filepath, ...
        Chins2Run, ChinIND, all_Conds2Run, Conds2Run, CondIND, ...
        colors, shapes, limits, mparams, ROOTdir, CODEdir)
% RUN_ANALYSIS_STEP  Dispatch the Branch-1 analysis call for one subject/condition.
%
%   This is called when raw data exists but output does not (or reanalyze=true).
%   Add a new case here when adding a new measure or subtype.
condition = strsplit(all_Conds2Run{CondIND}, filesep);
switch EXPname
    case 'ABR'
        switch EXPname2
            case 'Thresholds'
                ABR_thresholds(datapath, filepath, Chins2Run{ChinIND}, all_Conds2Run, CondIND, ...
                    mparams.abr_freq);
            case 'Peaks'
                ABR_dtw(ROOTdir, CODEdir, datapath, filepath, Chins2Run, ChinIND, ...
                    all_Conds2Run, Conds2Run, CondIND, colors, shapes, ...
                    limits.ind.peaks, mparams.abr_freq, mparams.abr_levels, mparams.abr_tpl_per_level, ...
                    mparams.peak_ui, mparams.abr_wave_sel);
        end
    case 'EFR'
        switch EXPname2
            case 'dAM'
                dAManalysis(datapath, filepath, Chins2Run{ChinIND}, condition{2}, mparams.efr_dam_bands);
                cd(CODEdir);
            case 'RAM'
                RAManalysis(datapath, filepath, Chins2Run{ChinIND}, condition{2}, ...
                    mparams.efr_harmonics, mparams.efr_window);
                cd(CODEdir);
        end
    case 'OAE'
        switch EXPname2
            case 'DPOAE', DPanalysis(ROOTdir, datapath, filepath, Chins2Run{ChinIND}, condition{2});
            case 'SFOAE', SFanalysis(ROOTdir, datapath, filepath, Chins2Run{ChinIND}, condition{2});
            case 'TEOAE', TEanalysis(ROOTdir, datapath, filepath, Chins2Run{ChinIND}, condition{2});
        end
    case 'MEMR'
        if isempty(EXPname2)
            WBMEMRanalysis(ROOTdir, datapath, filepath, Chins2Run{ChinIND}, condition{2});
        else                                      % one file for every exploratory MEMR view
            mx_analysis(ROOTdir, datapath, filepath, Chins2Run{ChinIND}, condition{2});
        end
end
end


function run_summary_step(EXPname, EXPname2, filepath, datapath, OUTdir, PRIVATEdir, ...
        Conds2Run, Chins2Run, all_Conds2Run, ChinIND, CondIND, ...
        idx_plot_relative, limits, colors, shapes, is_last_pair, subj_active_conds, ...
        mparams, CODEdir, ROOTdir, subject_idx, exp_name)
% RUN_SUMMARY_STEP  Dispatch the Branch-3 summary call for one subject/condition.
%
%   Called once per subject/condition to accumulate data for individual and
%   average plots. is_last_pair=true triggers final average plot generation.
%   Add a new case here when adding a new measure or subtype.
switch EXPname
    case 'ABR'
        cd(fullfile(ROOTdir, 'Code Archive', 'ABR'));
        switch EXPname2
            case 'Thresholds'
                ABRsummary(filepath, OUTdir, PRIVATEdir, Conds2Run, Chins2Run, all_Conds2Run, ...
                    ChinIND, CondIND, idx_plot_relative, limits.ind, [], [], limits.avg, [], [], ...
                    colors, shapes, EXPname2, is_last_pair, subj_active_conds, mparams.abr_freq, [], [], exp_name);
            case 'Peaks'
                ABRsummary(filepath, OUTdir, PRIVATEdir, Conds2Run, Chins2Run, all_Conds2Run, ...
                    ChinIND, CondIND, idx_plot_relative, [], limits.ind.peaks, limits.ind.latency, ...
                    [], limits.avg.peaks, limits.avg.latency, colors, shapes, EXPname2, is_last_pair, ...
                    subj_active_conds, mparams.abr_freq, mparams.abr_levels, ...
                    mparams.abr_wave_sel);
        end
    case 'EFR'
        cd(CODEdir);
        switch EXPname2
            case 'dAM', lvl_pattern = '*EFR_dAM*.mat';
            case 'RAM', lvl_pattern = '*EFR_RAM*.mat';
        end
        % One level list for the whole run, so a level keeps the same index
        % (3rd dim of the EFR globals) for every subject / condition, whatever
        % levels each one has (e.g. 65/80 for one subject, 70 for another).
        % Built once from all subjects × conditions of the run (ascending);
        % a level that appears later (analysed during this run) is appended.
        all_efr_levels = [];
        if isappdata(0,'APAT_efr_levels'), all_efr_levels = getappdata(0,'APAT_efr_levels'); end
        if isempty(all_efr_levels)
            for ci = 1:numel(Chins2Run)
                for ki = 1:numel(all_Conds2Run)
                    all_efr_levels = [all_efr_levels, efr_levels_in( ...
                        fullfile(OUTdir, EXPname, Chins2Run{ci}, all_Conds2Run{ki}), lvl_pattern)]; %#ok<AGROW>
                end
            end
            all_efr_levels = sort(unique(all_efr_levels));
        end
        new_lev = setdiff(efr_levels_in(filepath, lvl_pattern), all_efr_levels);
        all_efr_levels = [all_efr_levels, sort(new_lev)];
        if isempty(all_efr_levels), all_efr_levels = 80; end
        setappdata(0, 'APAT_efr_levels', all_efr_levels);
        EFRsummary(filepath, OUTdir, PRIVATEdir, Conds2Run, Chins2Run, all_Conds2Run, ...
            ChinIND, CondIND, limits.avg, idx_plot_relative, all_efr_levels, shapes, colors, ...
            is_last_pair, subject_idx, subj_active_conds, EXPname2);
    case 'OAE'
        cd(CODEdir);
        switch EXPname2
            case 'DPOAE'
                DPsummary(filepath, OUTdir, PRIVATEdir, Conds2Run, Chins2Run, all_Conds2Run, ...
                    ChinIND, CondIND, idx_plot_relative, limits.ind, limits.avg, shapes, colors, ...
                    is_last_pair, subj_active_conds);
            case 'SFOAE'
                SFSummary(filepath, OUTdir, PRIVATEdir, Conds2Run, Chins2Run, all_Conds2Run, ...
                    ChinIND, CondIND, idx_plot_relative, limits.ind, limits.avg, shapes, colors, ...
                    is_last_pair, subj_active_conds);
            case 'TEOAE'
                TEsummary(filepath, OUTdir, PRIVATEdir, Conds2Run, Chins2Run, all_Conds2Run, ...
                    ChinIND, CondIND, idx_plot_relative, limits.ind, limits.avg, shapes, colors, ...
                    is_last_pair, subj_active_conds);
        end
    case 'MEMR'
        cd(CODEdir);
        if isempty(EXPname2)
            WBMEMRsummary(filepath, OUTdir, PRIVATEdir, Conds2Run, Chins2Run, all_Conds2Run, ...
                ChinIND, CondIND, idx_plot_relative, limits.avg, limits.threshold, shapes, colors, ...
                is_last_pair, subj_active_conds);
        else
            mx_summary(EXPname2, filepath, OUTdir, Conds2Run, Chins2Run, all_Conds2Run, ...
                ChinIND, CondIND, idx_plot_relative, colors, shapes, is_last_pair, subj_active_conds);
        end
end
end


%% ════════════════════════════════════════════════════════════════════════
%  INTERNAL HELPERS  (not measure-specific — do not edit for new measures)
%% ════════════════════════════════════════════════════════════════════════

function [ind_figs, avg_figs] = split_ind_avg_figs(EXPname, from_subj, new_this_call, is_last_pair)
% SPLIT_IND_AVG_FIGS  Classify figures as individual or average for embedding.
%
%   ABR uses figure Name/Tag conventions to split reliably because ABRsummary
%   creates both individual and average figures in a single call.
%   All other modalities use a timing-based split (new_this_call = avg).
if strcmp(EXPname, 'ABR')
    fig_names = arrayfun(@(f) get(f,'Name'), from_subj, 'UniformOutput', false);
    fig_tags  = arrayfun(@(f) get(f,'Tag'),  from_subj, 'UniformOutput', false);
    has_name  = ~cellfun(@isempty, fig_names);
    % avg_cats: figure name prefixes that route to avg panel.
    % 'Waveforms' = plot_abr_waterfall (group-average waveforms).
    % 'ABR Waveforms' is per-subject individual waterfall → NOT here → ind panel.
    avg_cats  = {'Waveforms','Amplitudes','Latencies'};
    is_avg_named = false(size(fig_names));
    for kk = 1:numel(fig_names)
        if has_name(kk) && contains(fig_names{kk}, '|')
            pts = strsplit(fig_names{kk}, '|');
            is_avg_named(kk) = ismember(pts{1}, avg_cats);
        end
        if strcmp(fig_tags{kk}, 'APAT_thr_avg') || strcmp(fig_names{kk}, 'ABR Thresholds Average')
            is_avg_named(kk) = true;
        end
    end
    ind_figs = from_subj(has_name & ~is_avg_named);
    avg_figs = from_subj(is_avg_named | ~has_name);
    % Sort individual figures by creation order so condition tabs appear in order
    if ~isempty(ind_figs)
        [~, si] = sort(arrayfun(@(f) f.Number, ind_figs));
        ind_figs = ind_figs(si);
    end
elseif strcmp(EXPname, 'EFR')
    % EFR individual figures have '|' in their name (Category|Label).
    % Average figures from plot_avg_efr never have '|'.
    % Tab figures from plot_avg_efr_tabs also have '|' but route to avg panel.
    fig_names  = arrayfun(@(f) get(f,'Name'), from_subj, 'UniformOutput', false);
    has_pipe   = cellfun(@(nm) contains(nm,'|'), fig_names);
    fig_tags   = arrayfun(@(f) get(f,'Tag'),  from_subj, 'UniformOutput', false);
    is_avg_tab = cellfun(@(nm) strncmp(nm,'PLV Average|',12) || strncmp(nm,'PLV Sum|',8) || strncmp(nm,'dAM Power|',10), fig_names) | ...
                 strcmp(fig_tags, 'APAT_efr_avg');            % per-level average figures ('Level|...')
    ind_figs   = from_subj(has_pipe & ~is_avg_tab);
    avg_figs   = from_subj(is_avg_tab);
    if isempty(avg_figs)
        avg_figs = from_subj(~has_pipe);   % dAM: average figures have no '|'
    end
    % Sort individual figures so tabs appear in creation order
    if ~isempty(ind_figs)
        [~, si] = sort(arrayfun(@(f) f.Number, ind_figs));
        ind_figs = ind_figs(si);
    end
elseif strcmp(EXPname, 'OAE')
    % OAE figures are named 'Scale|<EPL | SPL | EPL + SPL>' (one per scale
    % view); the group figures also carry Tag 'oae_avg_<view>'.
    fig_names = arrayfun(@(f) get(f,'Name'), from_subj,'UniformOutput',false);
    fig_tags  = arrayfun(@(f) get(f,'Tag'),  from_subj,'UniformOutput',false);
    has_pipe  = cellfun(@(nm) contains(nm,'|'), fig_names);
    is_avg    = cellfun(@(t)  strncmp(t,'oae_avg_',8), fig_tags);
    ind_figs  = from_subj(has_pipe & ~is_avg);
    avg_figs  = from_subj(is_avg);
    if ~isempty(ind_figs)
        [~, si] = sort(arrayfun(@(f) f.Number, ind_figs));
        ind_figs = ind_figs(si);
    end
elseif strcmp(EXPname, 'MEMR')
    % MEMR figures carry Tag 'memr_ind' (one per subject, all conditions)
    % or 'memr_avg' (group figure); anything else (e.g. analysis plots) is
    % shown with the individual results.
    fig_tags = arrayfun(@(f) get(f,'Tag'), from_subj, 'UniformOutput', false);
    is_avg   = strcmp(fig_tags, 'memr_avg');
    ind_figs = from_subj(strcmp(fig_tags, 'memr_ind'));
    if isempty(ind_figs), ind_figs = from_subj(~is_avg); end
    avg_figs = from_subj(is_avg);
else
    % Timing-based split: figures created before this summary call = individual
    ind_figs = setdiff(from_subj, new_this_call);
    if isempty(ind_figs), ind_figs = from_subj; end   % single-condition fallback
    avg_figs = new_this_call;
    if isempty(avg_figs) && is_last_pair
        avg_figs = from_subj;   % all-in-one-call fallback
    end
end
end


function v = cfg_get(s, field, default)
% CFG_GET  Return s.field when it exists and is non-empty, otherwise default.
if isfield(s, field) && ~isempty(s.(field))
    v = s.(field);
else
    v = default;
end
end


function s = onoff(tf)
% ONOFF  Convert logical to 'on'/'off' string.
if tf, s = 'on'; else, s = 'off'; end
end


function lev = efr_levels_in(folder, pattern)
%EFR_LEVELS_IN  Stimulus levels (dB SPL) of the EFR analysis files in FOLDER,
%   read from '..._<lev>dBSPL...' in the file names (any level, any number).
lev = [];
if ~exist(folder, 'dir'), return; end
d = dir(fullfile(folder, pattern));
d = d(~strncmp({d.name}, '._', 2));
for k = 1:numel(d)
    tok = regexp(d(k).name, '_(\d+(?:\.\d+)?)dBSPL', 'tokens', 'once');
    if ~isempty(tok), lev(end+1) = str2double(tok{1}); end %#ok<AGROW>
end
lev = unique(lev);
end


function add_path_once(d, recursive)
%ADD_PATH_ONCE  addpath only the folders not on the MATLAB path yet (a
%   repeated addpath re-scans the path every run). APAT folders have no
%   duplicate function names, so their order on the path does not matter.
if recursive, p = genpath(d); else, p = d; end
want = strsplit(p, pathsep);
want = regexprep(want(~cellfun(@isempty, want)), '[\\/]+$', '');
if isempty(want), return; end
have = strsplit(path, pathsep);
if ispc, miss = ~ismember(lower(want), lower(have)); else, miss = ~ismember(want, have); end
if any(miss), addpath(want{miss}); end
end


function step_failed(ME, stage)
%STEP_FAILED  A step of one subject / condition failed: log it (notice,
%   Analysis/APAT_error_log.txt) and go on. Stop (APAT:UserAbort) still ends the run.
if strcmp(ME.identifier, 'APAT:UserAbort'), rethrow(ME); end
try, apat_run_error('error', ME, stage); catch, end
end


function v = ternary_s(c, a, b)
if c, v = a; else, v = b; end
end


function run_state_clean(own_err)
%RUN_STATE_CLEAN  onCleanup: prompt timeout / embed-save flags off; the
%   error state is dropped only when this call started it (headless).
try
    if isappdata(0, 'APAT_prompt_timeout'), rmappdata(0, 'APAT_prompt_timeout'); end
    if isappdata(0, 'APAT_embed_save'), rmappdata(0, 'APAT_embed_save'); end
    if own_err, apat_run_error('end'); end
catch
end
end


function cleanup_after_abort(use_embed, figs0, cwd)
%CLEANUP_AFTER_ABORT  onCleanup of analysis_run: only acts when the run did
%   not reach its end (error or Stop).
try
    if isappdata(0, 'APAT_run_finished') && isequal(getappdata(0, 'APAT_run_finished'), true), return; end
    if use_embed
        f = setdiff(findall(0, 'Type','figure', 'Visible','off'), figs0);
        f = f(isvalid(f));
        f = f(arrayfun(@(h) ~strcmp(h.Name, 'Auditory Physiology Analysis Toolkit (APAT)'), f));
        if ~isempty(f), delete(f); end
        set(0, 'DefaultFigureVisible', 'on');
    end
    if exist(cwd, 'dir'), cd(cwd); end
catch
end
end
