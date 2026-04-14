function settings_ops(app, action, varargin)
%SETTINGS_OPS  Last-run settings persistence for APAT_app.
%
%   settings_ops(app, 'save', Chins2Run, Conds2Run) — write to disk
%   settings_ops(app, 'load')                        — restore from disk

switch action
    case 'save', do_save(app, varargin{1}, varargin{2});
    case 'load', do_load(app);
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
s.measure_idx   = app.state.measure_idx;
s.subtype_idx   = app.state.subtype_idx;
if ~isempty(app.h_abr_freq_checks) && any(isvalid(app.h_abr_freq_checks))
    s.abr_freq_sel = arrayfun(@(c) isvalid(c) && c.Value, app.h_abr_freq_checks);
end
if ~isempty(app.h_abr_level_checks) && any(isvalid(app.h_abr_level_checks))
    s.abr_level_sel = arrayfun(@(c) isvalid(c) && c.Value, app.h_abr_level_checks);
end
if ~isempty(app.h_abr_wave_checks) && any(isvalid(app.h_abr_wave_checks))
    s.abr_wave_sel = arrayfun(@(c) isvalid(c) && c.Value, app.h_abr_wave_checks);
end
last_settings = s; %#ok<NASGU>
try, save(settings_file,'last_settings'); catch, end
end


% ── Load ──────────────────────────────────────────────────────────────

function do_load(app)
ROOTdir = strtrim(app.RootDirField.Value);
if isempty(ROOTdir), return; end
settings_file = fullfile(ROOTdir,'Analysis','launcher_last_settings.mat');
if ~exist(settings_file,'file'), return; end
try, tmp = load(settings_file,'last_settings'); catch, return; end
s = tmp.last_settings;

if isfield(s,'reanalyze'),     app.ReanalyzeCheck.Value    = logical(s.reanalyze);     end
if isfield(s,'plot_relative'), app.PlotRelativeCheck.Value = logical(s.plot_relative); end
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
if isfield(s,'abr_level_sel') && ~isempty(app.h_abr_level_checks)
    for li = 1:min(numel(s.abr_level_sel), numel(app.h_abr_level_checks))
        if isvalid(app.h_abr_level_checks(li))
            app.h_abr_level_checks(li).Value = logical(s.abr_level_sel(li));
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
end
