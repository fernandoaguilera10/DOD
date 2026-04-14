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
%                                'DPOAE'|'SFOAE'|'TEOAE'
%   .plot_relative      logical – plot relative to first condition    [false]
%   .reanalyze          logical – redo analysis even if output exists [false]
%   .show_figs          struct  – .analysis / .ind / .avg logicals
%   .embed_fns          struct  – .analysis / .average / .progress callbacks
%   .abr_freq           numeric – frequencies to include (Hz)
%   .abr_levels         numeric – levels to include (dB)
%   .abr_tpl_per_level  logical – require per-level template          [false]
%   .abr_wave_sel       logical 1×5 – ABR waves to show
%   .efr_harmonics      integer – max harmonics for RAM EFR           [16]
%   .efr_window         1×2     – RAM analysis window [start end] s

cwd = pwd;
if nargin < 6 || isempty(cfg), cfg = struct(); end

%% ── Plotting constants ───────────────────────────────────────────────────
shapes = ["v";"square";"diamond";"^";"o";">";"pentagram";"*";"x"];
colors = [0 0 0; 255 190 25; 77 192 181; 101 116 205; 149 97 226; ...
          52 144 220; 246 109 155; 246 153 63; 227 52 47] / 255;

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
    case 'MEMR',         measure_lbl = 'MEMR';
    otherwise,           measure_lbl = EXPname;
end

[DATAdir, OUTdir, CODEdir, PRIVATEdir] = get_directory(ROOTdir, EXPname, EXPname2);
addpath(genpath(CODEdir));

%% ── File search patterns ─────────────────────────────────────────────────
[filepath_searchfile, datapath_searchfile] = get_file_patterns(EXPname, EXPname2);

%% ── Parse chinroster ─────────────────────────────────────────────────────
if ~isempty(search_files(OUTdir, chinroster_filename).files)
    cd(OUTdir)
    chinroster_temp = readcell(chinroster_filename, 'Sheet', chinroster_sheet);
    temp_idx = cellfun(@(x) any(isa(x,'missing')), chinroster_temp);
    chinroster_temp(temp_idx) = {NaN};
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
filepath_idx      = zeros(length(Chins2Run), length(all_Conds2Run));
datapath_idx      = zeros(length(Chins2Run), length(all_Conds2Run));
subject_idx       = zeros(length(Chins2Run), length(all_Conds2Run));
addpath(strcat(ROOTdir, filesep, 'Code Archive'))

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

%% ── NEL delay (ABR Peaks only) ───────────────────────────────────────────
nel_delay = [];
if strcmp(EXPname,'ABR') && strcmp(EXPname2,'Peaks')
    nel_delay_file = fullfile(OUTdir, 'ABR', ['ABR_NEL_delay_' chinroster_sheet '.mat']);
    nel_delay.delay_ms      = nan(length(Chins2Run), length(all_Conds2Run));
    nel_delay.nel           = nan(length(Chins2Run), length(all_Conds2Run));
    nel_delay.is_estimated  = false(length(Chins2Run), length(all_Conds2Run));
    nel_delay.nel_confirmed = false(length(Chins2Run), length(all_Conds2Run));
    nel_delay.subjects      = Chins2Run(:);
    nel_delay.timepoints    = all_Conds2Run;
    if exist(nel_delay_file, 'file')
        tmp   = load(nel_delay_file, 'nel_delay');
        saved = tmp.nel_delay;
        for s = 1:length(Chins2Run)
            saved_s = find(strcmp(saved.subjects, Chins2Run{s}), 1);
            if isempty(saved_s), continue; end
            for t = 1:length(all_Conds2Run)
                saved_t = find(strcmp(saved.timepoints, all_Conds2Run{t}), 1);
                if isempty(saved_t), continue; end
                nel_delay.delay_ms(s,t)     = saved.delay_ms(saved_s, saved_t);
                nel_delay.nel(s,t)          = saved.nel(saved_s, saved_t);
                nel_delay.is_estimated(s,t) = saved.is_estimated(saved_s, saved_t);
                if isfield(saved, 'nel_confirmed')
                    nel_delay.nel_confirmed(s,t) = saved.nel_confirmed(saved_s, saved_t);
                end
                % Guard: clear stale delay if NEL number is unknown
                if isnan(nel_delay.nel(s,t)) && ~nel_delay.nel_confirmed(s,t)
                    nel_delay.delay_ms(s,t)     = NaN;
                    nel_delay.is_estimated(s,t) = false;
                end
            end
        end
        fprintf('  [NEL] Loaded existing ABR_NEL_delay.mat (%d subjects, %d timepoints mapped)\n', ...
            length(Chins2Run), length(all_Conds2Run));
    end
    for ChinIND = 1:length(Chins2Run)
        for CondIND = 1:length(all_Conds2Run)
            if datapath_idx(ChinIND,CondIND) && isnan(nel_delay.delay_ms(ChinIND,CondIND))
                nel_delay = get_nel_delay(ROOTdir, datapath_dir{ChinIND,CondIND}, Chins2Run, ChinIND, ...
                    all_Conds2Run, CondIND, nel_delay, nel_delay_file);
            end
        end
    end
    nel_expected = false(length(Chins2Run), length(all_Conds2Run));
    for s = 1:length(Chins2Run)
        for t = 1:length(all_Conds2Run)
            if strcmp(chinroster.signal(s,t),'X') || strcmp(chinroster.signal(s,t),'x')
                nel_expected(s,t) = true;
            end
        end
    end
    nel_delay = prompt_missing_nel(nel_delay, Chins2Run, all_Conds2Run, nel_delay_file, nel_expected);
end

%% ── Main processing loop ─────────────────────────────────────────────────
n_total = sum(sum(subject_idx));

for ChinIND = 1:length(Chins2Run)
    % Conditions that are active (have data + are in subject roster) for this subject
    subj_active_conds = find(subject_idx(ChinIND,:) == 1);
    Conds2Run         = all_Conds2Run(subj_active_conds);

    if use_embed, pre_subj_figs = findall(0,'Type','figure'); end

    for i = 1:length(subj_active_conds)
        CondIND       = subj_active_conds(i);
        file_check    = filepath_idx(ChinIND, CondIND);
        data_check    = datapath_idx(ChinIND, CondIND);
        subject_check = subject_idx(ChinIND, CondIND);
        condition     = strsplit(all_Conds2Run{CondIND}, filesep);
        drawnow limitrate;
        cd(CODEdir);

        % ── Branch 2: move RAW files into subject/condition folder ─────────
        if data_check == 0 && subject_check == 1
            datapath = strcat(DATAdir, filesep, Chins2Run{ChinIND}, filesep, EXPname, filesep, all_Conds2Run{CondIND});
            if ~exist(datapath, 'dir')
                fprintf('\nCreating data directory for %s (%s)...\n', Chins2Run{ChinIND}, all_Conds2Run{CondIND});
                mkdir(datapath);
            end
            sourcepath = strcat(DATAdir, filesep, 'RAW');
            cd(CODEdir)
            move_files(Chins2Run, all_Conds2Run, ChinIND, CondIND, sourcepath, EXPname, DATAdir, CODEdir);
            new_dp = search_files(datapath, datapath_searchfile);
            if ~isempty(new_dp.files)
                datapath_idx(ChinIND,CondIND) = 1;
                datapath_dir{ChinIND,CondIND} = new_dp.dir;
                data_check = 1;
            end
        end

        % ── ABR Thresholds: check if existing output is compatible ──────────
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
                    if needs_rerun
                        file_check = 0;
                    end
                catch
                end
            end
        end

        % ── Branch 1: analyse RAW → output ────────────────────────────────
        if (file_check == 0 && data_check == 1 && subject_check == 1) || reanalyze
            fprintf('\nSubject: %s (%s)\n', Chins2Run{ChinIND}, all_Conds2Run{CondIND});
            if use_embed && isfield(embed_fns,'progress')
                cond_lbl = condition{end};
                embed_fns.progress(max(0,counter), n_total, ...
                    sprintf('Analyzing  %s \x2014 %s  (%d / %d)', Chins2Run{ChinIND}, cond_lbl, max(0,counter), n_total));
            end
            filepath = strcat(OUTdir, filesep, EXPname, filesep, Chins2Run{ChinIND}, filesep, all_Conds2Run{CondIND});
            datapath = datapath_dir{ChinIND, CondIND};
            if ~exist(filepath, 'dir')
                fprintf('\nCreating analysis directory for %s (%s)...\n', Chins2Run{ChinIND}, all_Conds2Run{CondIND});
                mkdir(filepath);
            end
            pre_figs_b1 = findall(0,'Type','figure');
            set(0, 'DefaultFigureVisible', onoff(~use_embed && show_figs.analysis));

            run_analysis_step(EXPname, EXPname2, datapath, filepath, ...
                Chins2Run, ChinIND, all_Conds2Run, Conds2Run, CondIND, ...
                nel_delay, colors, shapes, limits, mparams, ROOTdir, CODEdir);

            if ~use_embed, set(0,'DefaultFigureVisible','on'); end
            new_figs_b1 = setdiff(findall(0,'Type','figure'), pre_figs_b1);
            new_figs_b1 = new_figs_b1(isvalid(new_figs_b1));
            if strcmp(EXPname,'ABR') && use_embed
                % ABR Branch-3 (ABRsummary) reconstructs all figures from saved
                % plot_data — Branch-1 figures are redundant and use a different
                % naming convention ('Name | subject | cond' vs 'Name|cond') that
                % creates duplicate tabs. Close them so Branch-3 starts clean.
                if ~isempty(new_figs_b1), close(new_figs_b1); end
            else
                % Non-ABR: Branch-1 analysis figures carry useful content;
                % keep invisible so they accumulate with Branch-3 for embedding.
                if ~isempty(new_figs_b1), set(new_figs_b1, 'Visible', 'off'); end
            end
            filepath_idx(ChinIND,CondIND) = 1;
            filepath_dir{ChinIND,CondIND} = filepath;
            file_check = 1;
        end

        % ── Branch 3: load output → summary / averages ────────────────────
        % Runs whenever output MAT exists and subject is in the roster.
        % Raw data (data_check) is not required — all summary functions
        % load from saved output files, not from raw data.
        if file_check == 1 && subject_check == 1
            counter      = counter + 1;
            is_last_pair = (counter == n_total);

            fprintf('\nLoading Data for Averaging...\nSubject: %s (%s)\n', Chins2Run{ChinIND}, all_Conds2Run{CondIND});
            if use_embed && isfield(embed_fns,'progress')
                cond_lbl = condition{end};
                embed_fns.progress(counter, n_total, ...
                    sprintf('Summarizing  %s \x2014 %s  (%d / %d)', Chins2Run{ChinIND}, cond_lbl, counter, n_total));
            end
            filepath = filepath_dir{ChinIND, CondIND};
            datapath = datapath_dir{ChinIND, CondIND};
            if use_embed, pre_figs_b3 = findall(0,'Type','figure'); end
            set(0, 'DefaultFigureVisible', onoff(~use_embed && (show_figs.ind || show_figs.avg)));

            run_summary_step(EXPname, EXPname2, filepath, datapath, OUTdir, PRIVATEdir, ...
                Conds2Run, Chins2Run, all_Conds2Run, ChinIND, CondIND, ...
                idx_plot_relative, limits, colors, shapes, is_last_pair, subj_active_conds, ...
                mparams, CODEdir, ROOTdir, subject_idx);

            if ~use_embed, set(0,'DefaultFigureVisible','on'); end

            % ── Embed figures into app tabs (in-app mode only) ─────────────
            if use_embed && i == length(subj_active_conds)
                drawnow;
                after_figs    = findall(0,'Type','figure');
                from_subj     = setdiff(after_figs, pre_subj_figs);
                from_subj     = from_subj(isvalid(from_subj));
                if ~isempty(from_subj), set(from_subj, 'Visible', 'off'); end
                new_this_call = setdiff(after_figs, pre_figs_b3);
                new_this_call = new_this_call(isvalid(new_this_call));

                [ind_figs, avg_figs] = split_ind_avg_figs(EXPname, from_subj, new_this_call, is_last_pair);

                if ~isempty(ind_figs)
                    embed_fns.analysis(ind_figs, measure_lbl, Chins2Run{ChinIND}, condition{end});
                end
                if is_last_pair && ~isempty(avg_figs)
                    embed_fns.average(avg_figs, measure_lbl);
                end
                to_close = from_subj(isvalid(from_subj));
                if ~isempty(to_close), close(to_close); end
            end

            branch3_ran = true;
        end
    end
end

cd(cwd);
if use_embed, set(0,'DefaultFigureVisible','on'); end

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
        filepath_pat = '*MEMR*.mat';
        datapath_pat = filepath_pat;
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
        mparams.abr_levels        = cfg_get(cfg, 'abr_levels',        [80 70 60 50 40]);
        mparams.abr_tpl_per_level = cfg_get(cfg, 'abr_tpl_per_level', false);
        mparams.abr_wave_sel      = cfg_get(cfg, 'abr_wave_sel',      true(1,5));
        mparams.peak_ui           = cfg_get(cfg, 'peak_ui',           []);
    case 'EFR'
        mparams.efr_harmonics     = cfg_get(cfg, 'efr_harmonics', 16);
        mparams.efr_window        = cfg_get(cfg, 'efr_window',    [0.2, 0.9]);
    case 'OAE'
        % No extra parameters currently
    case 'MEMR'
        % No extra parameters currently
end
end


function run_analysis_step(EXPname, EXPname2, datapath, filepath, ...
        Chins2Run, ChinIND, all_Conds2Run, Conds2Run, CondIND, ...
        nel_delay, colors, shapes, limits, mparams, ROOTdir, CODEdir)
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
                    all_Conds2Run, Conds2Run, CondIND, nel_delay, colors, shapes, ...
                    limits.ind.peaks, mparams.abr_freq, mparams.abr_levels, mparams.abr_tpl_per_level, ...
                    mparams.peak_ui, mparams.abr_wave_sel);
        end
    case 'EFR'
        switch EXPname2
            case 'dAM'
                dAManalysis(datapath, filepath, Chins2Run{ChinIND}, condition{2});
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
        WBMEMRanalysis(ROOTdir, datapath, filepath, Chins2Run{ChinIND}, condition{2});
end
end


function run_summary_step(EXPname, EXPname2, filepath, datapath, OUTdir, PRIVATEdir, ...
        Conds2Run, Chins2Run, all_Conds2Run, ChinIND, CondIND, ...
        idx_plot_relative, limits, colors, shapes, is_last_pair, subj_active_conds, ...
        mparams, CODEdir, ROOTdir, subject_idx)
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
                    colors, shapes, EXPname2, is_last_pair, subj_active_conds, mparams.abr_freq);
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
        lvl_files = dir(fullfile(filepath, lvl_pattern));
        lvl_files = lvl_files(~strncmp({lvl_files.name},'._',2));
        efr_level = 80;   % fallback level
        if ~isempty(lvl_files)
            tok = regexp(lvl_files(1).name, '_(\d+)dBSPL', 'tokens');
            if ~isempty(tok), efr_level = str2double(tok{1}{1}); end
        end
        switch EXPname2
            case 'dAM'
                dAMsummary(filepath, OUTdir, PRIVATEdir, Conds2Run, Chins2Run, all_Conds2Run, ...
                    ChinIND, CondIND, limits.avg, idx_plot_relative, efr_level, shapes, colors, ...
                    is_last_pair, subject_idx, subj_active_conds);
            case 'RAM'
                RAMsummary(filepath, OUTdir, PRIVATEdir, Conds2Run, Chins2Run, all_Conds2Run, ...
                    ChinIND, CondIND, limits.avg, idx_plot_relative, efr_level, shapes, colors, ...
                    is_last_pair, subject_idx, subj_active_conds);
        end
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
        WBMEMRsummary(filepath, OUTdir, PRIVATEdir, Conds2Run, Chins2Run, all_Conds2Run, ...
            ChinIND, CondIND, idx_plot_relative, limits.avg, limits.threshold, shapes, colors, ...
            is_last_pair, subj_active_conds);
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
