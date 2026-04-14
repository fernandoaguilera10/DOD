function profile_ops(app, action, varargin)
%PROFILE_OPS  User-profile persistence for APAT_app.
%
%   profile_ops(app, 'load_to_gui', pname)  — restore GUI state from profile
%   profile_ops(app, 'save_current', pname) — write GUI state into profile struct
%   profile_ops(app, 'save_to_file')        — flush profiles struct to disk

switch action
    case 'load_to_gui',   do_load_to_gui(app, varargin{1});
    case 'save_current',  do_save_current(app, varargin{1});
    case 'save_to_file',  do_save_to_file(app);
end
end


% ── Load profile → GUI ────────────────────────────────────────────────

function do_load_to_gui(app, pname)
if ~isfield(app.profiles, pname), return; end
p = app.profiles.(pname);
if ismac
    if isfield(p,'ROOTdir_mac') && ~isempty(p.ROOTdir_mac)
        app.RootDirField.Value = p.ROOTdir_mac;
    end
else
    if isfield(p,'ROOTdir_win') && ~isempty(p.ROOTdir_win)
        app.RootDirField.Value = p.ROOTdir_win;
    end
end
if isfield(p,'last_sheet'),         app.state.sheet = p.last_sheet;                              end
if isfield(p,'reanalyze'),          app.ReanalyzeCheck.Value    = logical(p.reanalyze);          end
if isfield(p,'plot_relative_flag'), app.PlotRelativeCheck.Value = logical(p.plot_relative_flag); end

if isfield(p,'abr_freq_sel') && ~isempty(app.h_abr_freq_checks)
    for fi = 1:min(numel(p.abr_freq_sel), numel(app.h_abr_freq_checks))
        if isvalid(app.h_abr_freq_checks(fi))
            app.h_abr_freq_checks(fi).Value = logical(p.abr_freq_sel(fi));
        end
    end
end
if isfield(p,'abr_level_sel') && ~isempty(app.h_abr_level_checks)
    for li = 1:min(numel(p.abr_level_sel), numel(app.h_abr_level_checks))
        if isvalid(app.h_abr_level_checks(li))
            app.h_abr_level_checks(li).Value = logical(p.abr_level_sel(li));
        end
    end
end
if isfield(p,'abr_wave_sel') && ~isempty(app.h_abr_wave_checks)
    for wi = 1:min(numel(p.abr_wave_sel), numel(app.h_abr_wave_checks))
        if isvalid(app.h_abr_wave_checks(wi))
            app.h_abr_wave_checks(wi).Value = logical(p.abr_wave_sel(wi));
        end
    end
end
if isfield(p,'efr_harmonics') && ~isempty(app.h_efr_harmonics_field) && isvalid(app.h_efr_harmonics_field)
    app.h_efr_harmonics_field.Value = p.efr_harmonics;
end
if isfield(p,'efr_window') && numel(p.efr_window) == 2
    if ~isempty(app.h_efr_window_start_field) && isvalid(app.h_efr_window_start_field)
        app.h_efr_window_start_field.Value = p.efr_window(1);
    end
    if ~isempty(app.h_efr_window_end_field) && isvalid(app.h_efr_window_end_field)
        app.h_efr_window_end_field.Value = p.efr_window(2);
    end
end
preferred = '';
if isfield(p,'chinroster_filename'), preferred = p.chinroster_filename; end
chinroster_ops(app, 'scan', preferred);
end


% ── Save GUI → profile ─────────────────────────────────────────────────

function do_save_current(app, pname)
if ismac
    app.profiles.(pname).ROOTdir_mac = strtrim(app.RootDirField.Value);
else
    app.profiles.(pname).ROOTdir_win = strtrim(app.RootDirField.Value);
end
roster_val = app.RosterDropdown.Value;
if ~isempty(roster_val) && roster_val(1) ~= '('
    app.profiles.(pname).chinroster_filename = roster_val;
end
app.profiles.(pname).last_sheet         = app.state.sheet;
app.profiles.(pname).reanalyze          = app.ReanalyzeCheck.Value;
app.profiles.(pname).plot_relative_flag = app.PlotRelativeCheck.Value;
if ~isempty(app.h_abr_freq_checks) && any(isvalid(app.h_abr_freq_checks))
    app.profiles.(pname).abr_freq_sel = arrayfun(@(c) isvalid(c) && c.Value, app.h_abr_freq_checks);
end
if ~isempty(app.h_abr_level_checks) && any(isvalid(app.h_abr_level_checks))
    app.profiles.(pname).abr_level_sel = arrayfun(@(c) isvalid(c) && c.Value, app.h_abr_level_checks);
end
if ~isempty(app.h_abr_wave_checks) && any(isvalid(app.h_abr_wave_checks))
    app.profiles.(pname).abr_wave_sel = arrayfun(@(c) isvalid(c) && c.Value, app.h_abr_wave_checks);
end
if ~isempty(app.h_efr_harmonics_field) && isvalid(app.h_efr_harmonics_field)
    app.profiles.(pname).efr_harmonics = app.h_efr_harmonics_field.Value;
end
if ~isempty(app.h_efr_window_start_field) && isvalid(app.h_efr_window_start_field) && ...
   ~isempty(app.h_efr_window_end_field)   && isvalid(app.h_efr_window_end_field)
    app.profiles.(pname).efr_window = [app.h_efr_window_start_field.Value, ...
                                        app.h_efr_window_end_field.Value];
end
end


% ── Flush to disk ─────────────────────────────────────────────────────

function do_save_to_file(app)
profiles  = app.profiles; %#ok<PROP>
last_user = app.last_user; %#ok<PROP>
save(app.profile_file,'profiles','last_user');
end
