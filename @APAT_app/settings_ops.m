function settings_ops(app, action, varargin)
%SETTINGS_OPS  Last-run settings persistence for APAT_app.
%
%   settings_ops(app, 'save', Chins2Run, Conds2Run) — write to disk
%   settings_ops(app, 'load')                        — restore from disk

switch action
    case 'save', do_save(app, varargin{1}, varargin{2});
    case 'load', do_load(app);
    case 'save_colors', do_save_colors(app);
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
s.measure_idx   = app.state.measure_idx;
s.subtype_idx   = app.state.subtype_idx;
if ~isempty(app.h_abr_freq_checks) && any(isvalid(app.h_abr_freq_checks))
    s.abr_freq_sel = arrayfun(@(c) isvalid(c) && c.Value, app.h_abr_freq_checks);
end
if ~isempty(app.h_abr_wave_checks) && any(isvalid(app.h_abr_wave_checks))
    s.abr_wave_sel = arrayfun(@(c) isvalid(c) && c.Value, app.h_abr_wave_checks);
end
s.cond_colors   = merge_colors(app, settings_file);
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
s.cond_colors = merge_colors(app, settings_file);
last_settings = s; %#ok<NASGU>
try, save(settings_file,'last_settings'); catch, end
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
    chinroster_ops(app, 'paint_swatches');
end
if isfield(s,'reanalyze'),     app.ReanalyzeCheck.Value    = logical(s.reanalyze);     end
if isfield(s,'plot_relative'), app.PlotRelativeCheck.Value = logical(s.plot_relative); end
if isfield(s,'blind_mode'),    app.BlindCheck.Value        = logical(s.blind_mode);    end
if isfield(s,'measure_idx') && s.measure_idx >= 1 && s.measure_idx <= numel(app.MEASURES)
    app.state.measure_idx = s.measure_idx;
end
if isfield(s,'subtype_idx'), app.state.subtype_idx = s.subtype_idx; end
navigate_results(app, 'measures');

if isfield(s,'abr_freq_sel') && ~isempty(app.h_abr_freq_checks)
    for fi = 1:min(numel(s.abr_freq_sel), numel(app.h_abr_freq_checks))
        if isvalid(app.h_abr_freq_checks(fi))
            app.h_abr_freq_checks(fi).Value = logical(s.abr_freq_sel(fi));
        end
    end
end
if isfield(s,'abr_wave_sel') && ~isempty(app.h_abr_wave_checks)
    for wi = 1:min(numel(s.abr_wave_sel), numel(app.h_abr_wave_checks))
        if isvalid(app.h_abr_wave_checks(wi))
            app.h_abr_wave_checks(wi).Value = logical(s.abr_wave_sel(wi));
        end
    end
end
if isfield(s,'Chins2Run') && ~isempty(s.Chins2Run)
    for ii = 1:numel(app.h_subj_checks)
        if isvalid(app.h_subj_checks(ii))
            app.h_subj_checks(ii).Value = any(strcmp(s.Chins2Run, app.subj_ids{ii}));
        end
    end
end
if isfield(s,'Conds2Run') && ~isempty(s.Conds2Run)
    for ci = 1:numel(app.h_cond_checks)
        if isvalid(app.h_cond_checks(ci))
            app.h_cond_checks(ci).Value = any(strcmp(s.Conds2Run, app.state.conds_all{ci}));
        end
    end
end
update_summary(app);
end
