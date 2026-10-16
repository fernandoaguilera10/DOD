function settings_ops(app, action, varargin)
%SETTINGS_OPS  Last-run settings persistence for APAT_app.
%
%   settings_ops(app, 'save', Chins2Run, Conds2Run) — write to disk
%   settings_ops(app, 'load')                        — restore from disk
%   last_settings.sheet_sel = sheet_sel(app,'saved'): selected Experiments,
%   the one on screen and each sheet's deselected subjects / conditions
%   (read by sheet_sel 'list'); Chins2Run / Conds2Run = the sheet on screen.

switch action
    case 'save', do_save(app, varargin{1}, varargin{2});
    case 'load', do_load(app);
    case 'save_colors', do_save_colors(app);      % condition colours + markers
    case 'save_excl',   do_save_excl(app);
end
end


% ── Save ──────────────────────────────────────────────────────────────

function do_save(app, Chins2Run_sel, Conds2Run_sel)
ROOTdir = strtrim(app.RootDirField.Value);
if isempty(ROOTdir), return; end
settings_file = fullfile(ROOTdir,'Analysis','launcher_last_settings.mat');

s.Chins2Run     = Chins2Run_sel;
s.Conds2Run     = Conds2Run_sel;
s.reanalyze     = app.ReanalyzeCheck.Value;
s.plot_relative = app.PlotRelativeCheck.Value;
s.blind_mode    = app.BlindCheck.Value;
try                                                    % Data File rule
    h = findall(app.MeasuresPanel, 'Tag','rec_data_dd');  if ~isempty(h), s.rec_policy = h(1).Value; end
catch
end
try                                                    % ABR Repeated Levels ('all' | 'average')
    h = findall(app.MeasuresPanel, 'Tag','abr_dup_dd');  if ~isempty(h), s.abr_dup_levels = h(1).Value; end
catch
end
try                                                    % Output: export format, images, plot defaults
    o = output_opts(app, 'get');
    s.export_fmt    = o.export_fmt;
    s.plot_defaults = o.plot;                          % (no 'group' any more: Experiment is a data column)
catch
end
s.measure_idx   = app.state.measure_idx;
s.subtype_idx   = app.state.subtype_idx;
if isfield(app.state,'run_sel'), s.run_sel = app.state.run_sel; end   % analyses selected for the run
if ~isempty(app.h_abr_freq_checks) && any(isvalid(app.h_abr_freq_checks))
    abr_freq_sync(app, 'store');
    s.abr_freq     = app.state.abr_freq;              % {Thresholds, Peaks}
    s.abr_freq_sel = app.state.abr_freq{1};           % older APAT versions
end
if ~isempty(app.h_abr_wave_checks) && any(isvalid(app.h_abr_wave_checks))
    s.abr_wave_sel = arrayfun(@(c) isvalid(c) && c.Value, app.h_abr_wave_checks);
end
s.cond_colors   = merge_colors(app, settings_file);
s.cond_markers  = merge_markers(app, settings_file);
if isfield(app.state,'excl'), s.excl = app.state.excl; end      % Exclusions (per analysis)
try, s.sheet_sel = sheet_sel(app, 'saved'); catch, end         % Experiments + per-sheet chips
last_settings = s; %#ok<NASGU>
try, save(settings_file,'last_settings'); catch, end
end


function do_save_excl(app)
%DO_SAVE_EXCL  Store the Exclusions right away (keeps other settings).
ROOTdir = strtrim(app.RootDirField.Value);
if isempty(ROOTdir), return; end
settings_file = fullfile(ROOTdir,'Analysis','launcher_last_settings.mat');
s = struct();
if exist(settings_file,'file')
    try, tmp = load(settings_file,'last_settings'); s = tmp.last_settings; catch, end
end
if isfield(app.state,'excl'), s.excl = app.state.excl; end
last_settings = s; %#ok<NASGU>
try, save(settings_file,'last_settings'); catch, end
end


function do_save_colors(app)
%DO_SAVE_COLORS  Store condition colours right away (keeps other settings).
ROOTdir = strtrim(app.RootDirField.Value);
if isempty(ROOTdir), return; end
settings_file = fullfile(ROOTdir,'Analysis','launcher_last_settings.mat');
s = struct();
if exist(settings_file,'file')
    try, tmp = load(settings_file,'last_settings'); s = tmp.last_settings; catch, end
end
s.cond_colors  = merge_colors(app, settings_file);
s.cond_markers = merge_markers(app, settings_file);
last_settings = s; %#ok<NASGU>
try, save(settings_file,'last_settings'); catch, end
end


function cm = merge_markers(app, settings_file)
%MERGE_MARKERS  Markers of the current conditions merged into the saved list
%   (struct paths / mk, like merge_colors).
cm = struct('paths',{{}}, 'mk',{{}});
if exist(settings_file,'file')
    try
        tmp = load(settings_file,'last_settings');
        if isfield(tmp.last_settings,'cond_markers'), cm = tmp.last_settings.cond_markers; end
    catch
    end
end
if ~isfield(app.state,'cond_markers'), return; end
paths = app.state.conds_all;
for i = 1:min(numel(paths), numel(app.state.cond_markers))
    k = find(strcmp(cm.paths, paths{i}), 1);
    if isempty(k), cm.paths{end+1} = paths{i}; k = numel(cm.paths); end
    cm.mk{k} = app.state.cond_markers{i};
end
end


function cc = merge_colors(app, settings_file)
%MERGE_COLORS  Colours of the current conditions merged into the saved list,
%   so colours of conditions from other experiments/sheets are kept.
cc = struct('paths',{{}}, 'rgb',zeros(0,3));
if exist(settings_file,'file')
    try
        tmp = load(settings_file,'last_settings');
        if isfield(tmp.last_settings,'cond_colors'), cc = tmp.last_settings.cond_colors; end
    catch
    end
end
if ~isfield(app.state,'cond_colors'), return; end
paths = app.state.conds_all;
for i = 1:min(numel(paths), size(app.state.cond_colors,1))
    k = find(strcmp(cc.paths, paths{i}), 1);
    if isempty(k), cc.paths{end+1} = paths{i}; k = numel(cc.paths); end
    cc.rgb(k,:) = app.state.cond_colors(i,:);
end
end


% ── Load ──────────────────────────────────────────────────────────────

function do_load(app)
ROOTdir = strtrim(app.RootDirField.Value);
if isempty(ROOTdir), return; end
settings_file = fullfile(ROOTdir,'Analysis','launcher_last_settings.mat');
if ~exist(settings_file,'file'), return; end
try, tmp = load(settings_file,'last_settings'); catch, return; end
s = tmp.last_settings;

if isfield(s,'cond_colors') && isfield(s.cond_colors,'paths')     % saved condition colours
    for i = 1:min(numel(app.state.conds_all), size(app.state.cond_colors,1))
        k = find(strcmp(s.cond_colors.paths, app.state.conds_all{i}), 1);
        if ~isempty(k), app.state.cond_colors(i,:) = s.cond_colors.rgb(k,:); end
    end
end
if isfield(s,'cond_markers') && isfield(s.cond_markers,'paths') && isfield(app.state,'cond_markers')
    for i = 1:min(numel(app.state.conds_all), numel(app.state.cond_markers))
        k = find(strcmp(s.cond_markers.paths, app.state.conds_all{i}), 1);
        if ~isempty(k) && k <= numel(s.cond_markers.mk), app.state.cond_markers{i} = char(s.cond_markers.mk{k}); end
    end
end
chinroster_ops(app, 'paint_swatches');
if isfield(s,'reanalyze'),     app.ReanalyzeCheck.Value    = logical(s.reanalyze);     end
if isfield(s,'plot_relative'), app.PlotRelativeCheck.Value = logical(s.plot_relative); end
if isfield(s,'blind_mode'),    app.BlindCheck.Value        = logical(s.blind_mode);    end
fl = {'rec_policy','rec_data_dd'; 'abr_dup_levels','abr_dup_dd'};
for fi = 1:size(fl,1)
    if ~isfield(s, fl{fi,1}), continue; end
    try
        for h = findall(app.MeasuresPanel, 'Tag', fl{fi,2})'
            if any(strcmp(h.ItemsData, s.(fl{fi,1}))), h.Value = s.(fl{fi,1}); end
        end
    catch
    end
end
if isfield(s,'export_fmt') || isfield(s,'plot_defaults')   % Output card (an old 'group' field is ignored)
    o = struct();
    if isfield(s,'export_fmt'),    o.export_fmt = s.export_fmt;  end
    if isfield(s,'plot_defaults'), o.plot = s.plot_defaults;     end
    try, output_opts(app, 'set', o); catch, end
end
if isfield(s,'measure_idx') && s.measure_idx >= 1 && s.measure_idx <= numel(app.MEASURES)
    app.state.measure_idx = s.measure_idx;
end
if isfield(s,'subtype_idx'), app.state.subtype_idx = s.subtype_idx; end
if isfield(s,'excl') && isstruct(s.excl), app.state.excl = s.excl; else, app.state.excl = struct(); end
% (run_sel is saved but not restored: every APAT session starts with no analysis selected)
navigate_results(app, 'measures');

if ~isempty(app.h_abr_freq_checks), abr_freq_sync(app, 'from_saved', s); end
if isfield(s,'abr_wave_sel') && ~isempty(app.h_abr_wave_checks)
    for wi = 1:min(numel(s.abr_wave_sel), numel(app.h_abr_wave_checks))
        if isvalid(app.h_abr_wave_checks(wi))
            app.h_abr_wave_checks(wi).Value = logical(s.abr_wave_sel(wi));
        end
    end
end
% Subjects / conditions: newer files keep them per Experiment (sheet_sel
% 'restore' applies them after this); older files: the last run's lists,
% only when they match this sheet (else everything stays selected)
old_lists = ~isfield(s,'sheet_sel');
% (all of the saved IDs / paths must be on this sheet: a list saved for
% another Experiment is never applied here)
if old_lists && isfield(s,'Chins2Run') && ~isempty(s.Chins2Run) && all(ismember(cellstr(s.Chins2Run), app.subj_ids))
    for ii = 1:numel(app.h_subj_checks)
        if isvalid(app.h_subj_checks(ii))
            app.h_subj_checks(ii).Value = any(strcmp(s.Chins2Run, app.subj_ids{ii}));
        end
    end
end
if old_lists && isfield(s,'Conds2Run') && ~isempty(s.Conds2Run) && all(ismember(cellstr(s.Conds2Run), app.state.conds_all))
    for ci = 1:numel(app.h_cond_checks)
        if isvalid(app.h_cond_checks(ci))
            app.h_cond_checks(ci).Value = any(strcmp(s.Conds2Run, app.state.conds_all{ci}));
        end
    end
end
update_summary(app);
end
