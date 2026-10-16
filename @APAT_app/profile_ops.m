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
if isfield(p,'last_sheet'),         sheet_sel(app, 'set_on_screen', p.last_sheet, false);        end   % shown after the roster loads
if isfield(p,'reanalyze'),          app.ReanalyzeCheck.Value    = logical(p.reanalyze);          end
if isfield(p,'plot_relative_flag'), app.PlotRelativeCheck.Value = logical(p.plot_relative_flag); end
if isfield(p,'blind_mode'),         app.BlindCheck.Value        = logical(p.blind_mode);         end

if ~isempty(app.h_abr_freq_checks), abr_freq_sync(app, 'from_saved', p); end
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
if isfield(p,'efr_ctl') && isstruct(p.efr_ctl) && ~isempty(app.h_efr_param_panel) && isvalid(app.h_efr_param_panel)
    for f = fieldnames(p.efr_ctl)'
        h = findall(app.h_efr_param_panel,'Tag',f{1});
        if ~isempty(h)
            try, h(1).Value = p.efr_ctl.(f{1}); catch, end
            if strcmp(f{1},'efr_norm_btn'), setup_style(app, 'onoff', h(1)); end   % ON green / OFF red
        end
    end
end
if isfield(p,'oae_ctl') && isstruct(p.oae_ctl) && ~isempty(app.h_oae_param_panel) && isvalid(app.h_oae_param_panel)
    for f = fieldnames(p.oae_ctl)'
        h = findall(app.h_oae_param_panel,'Tag',f{1});
        if ~isempty(h)
            try, h(1).Value = p.oae_ctl.(f{1}); catch, end
            if strncmp(f{1},'oae_save_',9)          % EPL / SPL save toggles keep their text
                setup_style(app, 'chip', h(1));
            end
            if strcmp(f{1},'oae_snr_btn'), setup_style(app, 'onoff', h(1)); end
        end
    end
end
preferred = '';
if isfield(p,'chinroster_filename'), preferred = p.chinroster_filename; end
chinroster_ops(app, 'scan', preferred);
update_summary(app);
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
app.profiles.(pname).last_sheet         = sheet_sel(app, 'on_screen');   % Experiment on screen
app.profiles.(pname).reanalyze          = app.ReanalyzeCheck.Value;
app.profiles.(pname).plot_relative_flag = app.PlotRelativeCheck.Value;
app.profiles.(pname).blind_mode         = app.BlindCheck.Value;
if ~isempty(app.h_abr_freq_checks) && any(isvalid(app.h_abr_freq_checks))
    abr_freq_sync(app, 'store');
    app.profiles.(pname).abr_freq     = app.state.abr_freq;      % {Thresholds, Peaks}
    app.profiles.(pname).abr_freq_sel = app.state.abr_freq{1};   % older APAT versions
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
if ~isempty(app.h_efr_param_panel) && isvalid(app.h_efr_param_panel)
    ec = struct();
    for t = {'efr_low_from','efr_low_to','efr_high_from','efr_high_to','efr_sum_dd','efr_norm_btn','efr_dam_bands'}
        h = findall(app.h_efr_param_panel,'Tag',t{1});
        if ~isempty(h), ec.(t{1}) = h(1).Value; end
    end
    app.profiles.(pname).efr_ctl = ec;
end
if ~isempty(app.h_oae_param_panel) && isvalid(app.h_oae_param_panel)
    oc = struct();
    for h = findall(app.h_oae_param_panel)'
        t = h.Tag;
        if strncmp(t,'oae_',4) && isprop(h,'Value') && ~any(strcmp(t,{'oae_dp','oae_sf','oae_te'}))
            oc.(t) = h.Value;
        end
    end
    app.profiles.(pname).oae_ctl = oc;
end
end


% ── Flush to disk ─────────────────────────────────────────────────────

function do_save_to_file(app)
profiles  = app.profiles; %#ok<PROP>
last_user = app.last_user; %#ok<PROP>
save(app.profile_file,'profiles','last_user');
end
