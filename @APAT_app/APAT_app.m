classdef APAT_app < matlab.apps.AppBase
%APAT_APP  Auditory Physiology Analysis Toolkit.
%
%   Three-tab workflow:
%     Setup   — configure user, project, subjects, conditions,
%               options, and auditory measure; then click Run Analysis
%     Results — individual per-subject plots and group-average figures,
%               grouped by measure (ABR, EFR, OAE, MEMR)
%     Status  — color-coded data-availability grid
%
%   Run:  APAT_app
%
%   File layout (@APAT_app/ class folder):
%     APAT_app.m          — classdef + properties + short inline callbacks
%     createComponents.m  — all UI panels and controls (tab builders as local functions)
%     RunButtonPushed.m   — input validation, cfg struct, analysis_run call
%     embed_results.m     — route individual and average figures into panels
%     navigate_results.m  — measure/mode/subject/freq navigation + filtering
%     build_status_table.m— Data Status tab color grid
%     chinroster_ops.m    — scan, load, and refresh roster data
%     profile_ops.m       — load/save user profiles
%     settings_ops.m      — load/save last-run settings
%     read_chinroster_sheet.m — static: parse subjects+conditions from xlsx
%     private/ternary.m       — inline conditional helper
%     private/sort_tab_labels.m — sort condition/frequency tab labels


% ── Public UI components ────────────────────────────────────────────────
properties (Access = public)
    UIFigure               matlab.ui.Figure
    % Header
    HeaderPanel            matlab.ui.container.Panel
    TitleLabel             matlab.ui.control.Label
    SubtitleLabel          matlab.ui.control.Label
    RunButton              matlab.ui.control.Button
    StopButton             matlab.ui.control.Button
    % Tab group
    TabGroup               matlab.ui.container.TabGroup
    SetupTab               matlab.ui.container.Tab
    ResultsTab             matlab.ui.container.Tab
    StatusTab              matlab.ui.container.Tab
    % Setup — user + project
    UserPanel              matlab.ui.container.Panel
    ProfileDropdown        matlab.ui.control.DropDown
    NewUserBtn             matlab.ui.control.Button
    SaveUserBtn            matlab.ui.control.Button
    ProjectPanel           matlab.ui.container.Panel
    RootDirField           matlab.ui.control.EditField
    BrowseBtn              matlab.ui.control.Button
    RosterDropdown         matlab.ui.control.DropDown
    SheetDropdown          matlab.ui.control.DropDown
    SubjectsPanel          matlab.ui.container.Panel
    SelectAllBtn           matlab.ui.control.Button
    ClearSubjBtn           matlab.ui.control.Button
    RefreshSubjBtn         matlab.ui.control.Button
    ConditionsPanel        matlab.ui.container.Panel
    OptionsPanel           matlab.ui.container.Panel
    ReanalyzeCheck         matlab.ui.control.CheckBox
    PlotRelativeCheck      matlab.ui.control.CheckBox
    MeasuresPanel          matlab.ui.container.Panel
    DescTitleLabel         matlab.ui.control.Label
    DescLabel              matlab.ui.control.Label
    % Results tab controls
    FigIndBtn              matlab.ui.control.StateButton
    FigAvgBtn              matlab.ui.control.StateButton
    FigSubjDropdown        matlab.ui.control.DropDown
    FigFreqDD              matlab.ui.control.DropDown
    % Status tab
    RefreshStatusBtn       matlab.ui.control.Button
    StatusInnerTG          matlab.ui.container.TabGroup
end

% ── Private state ────────────────────────────────────────────────────────
properties (Access = private)
    MEASURES              % struct array: name, label, subtypes, descriptions
    state                 % .measure_idx .subtype_idx .sheet .conds_all .cond_labels
    profiles              % struct: user profile data
    last_user             % string: last used profile name
    code_dir              % path to Code Archive/
    profile_file          % path to user_profiles.mat
    % Dynamic arrays (rebuilt when chinroster changes)
    h_subj_checks         % uicheckbox array – subjects
    subj_ids              % cell array of subject ID strings
    h_cond_checks         % uicheckbox array – conditions
    h_meas_btns           % uibutton array – setup-tab measure selector
    h_sub_btns            % cell of uibutton arrays – subtypes
    % Results tab state (created in createComponents, managed by navigate_results)
    res                   % .panels(2×8) .subj_data(1×8) .mode .meas_idx .btns(1×8)
    % Setup-tab layout constants
    layout_row2_h
    layout_meas_h
    meas_sub_area_start
    n_meas; meas_h; meas_gap
    % ABR parameter controls
    h_abr_param_panel
    h_abr_freq_checks
    h_abr_level_checks
    h_abr_wave_checks
    % EFR parameter controls
    h_efr_param_panel
    h_efr_harmonics_field
    h_efr_window_start_field
    h_efr_window_end_field
    % OAE / MEMR parameter panels
    h_oae_param_panel
    h_memr_param_panel
    % Progress and spinner
    h_progress_label
    h_spinner_label
    h_spinner_timer
    spinner_frame
    abort_requested
    % Color palette
    clr_black; clr_gold; clr_gold_dk; clr_bg; clr_panel; clr_btn
    % Peak editor overlay
    PeakEditPanel
    PeakEditInfoLabel
    PeakEditWfAx
    PeakEditAx
    PeakEditStatusLabel
    PeakEditAcceptBtn
    PeakEditRedoBtn
    PeakEditCancelBtn
    PeakEditDoneBtn
end


% ══════════════════════════════════════════════════════════════════════════
%  PRIVATE METHODS
% ══════════════════════════════════════════════════════════════════════════
methods (Access = private)

    % ── External method declarations (bodies in @APAT_app/*.m) ───────────
    createComponents(app)
    RunButtonPushed(app)
    embed_results(app, mode, figs, label, varargin)
    navigate_results(app, action, varargin)
    build_status_table(app)
    chinroster_ops(app, action, varargin)
    profile_ops(app, action, varargin)
    settings_ops(app, action, varargin)

    % ── Startup ──────────────────────────────────────────────────────────

    function startupFcn(app)
        % mfilename returns path inside @APAT_app/ — go up one level to Code Archive/
        app.code_dir     = fileparts(fileparts(mfilename('fullpath')));
        app.profile_file = fullfile(app.code_dir,'private','user_profiles.mat');
        % Ensure Code Archive/ is on the MATLAB path so that class methods can
        % access Code Archive/private/ (analysis_run, etc.) via private inheritance.
        addpath(app.code_dir);
        app.state.measure_idx = 1;
        app.state.subtype_idx = 1;
        app.state.sheet       = '';
        app.state.conds_all   = {};
        app.state.cond_labels = {};
        app.h_subj_checks = gobjects(0);
        app.subj_ids      = {};
        app.h_cond_checks = gobjects(0);
        initMeasures(app);
        navigate_results(app, 'measures');   % highlight first measure button
        [app.profiles, app.last_user] = APAT_app.load_profiles(app.profile_file);
        all_pnames = fieldnames(app.profiles);
        if ~isempty(all_pnames)
            app.ProfileDropdown.Items = all_pnames;
            if ~isempty(app.last_user) && isfield(app.profiles, app.last_user)
                app.ProfileDropdown.Value = app.last_user;
            else
                app.ProfileDropdown.Value = all_pnames{1};
            end
            profile_ops(app, 'load_to_gui', app.ProfileDropdown.Value);
        end
    end

    function initMeasures(app)
        app.MEASURES = struct('name',{},'label',{},'subtypes',{},'descriptions',{});
        app.MEASURES(1) = struct('name','ABR','label','Auditory Brainstem Response', ...
            'subtypes',{{'Thresholds','Peaks'}}, ...
            'descriptions',{{ ...
              ['Estimates hearing thresholds across click and pure-tone frequencies. ' ...
               'Uses a bootstrapped cross-correlation method and fits a sigmoid to the ' ...
               'normalized ABR amplitude-vs-level function to extract threshold.'], ...
              ['Detects Wave I–V peaks and troughs using Dynamic Time Warping (DTW) ' ...
               'against a reference template. Quantifies peak-to-peak amplitudes and ' ...
               'absolute latencies across stimulus levels and frequencies.']}});
        app.MEASURES(2) = struct('name','EFR','label','Envelope Following Response', ...
            'subtypes',{{'dAM','RAM'}}, ...
            'descriptions',{{ ...
              ['Measures neural responses to a modulated stimulus using dynamic amplitude ' ...
               'modulation (dAM) to assess temporal encoding up to 1.5 kHz.'], ...
              ['Measures neural responses using rectangular amplitude modulation (RAM). ' ...
               'Phase Locking Value (PLV) captures subcortical synchrony up to the 16th ' ...
               'harmonic of the modulation frequency.']}});
        app.MEASURES(3) = struct('name','OAE','label','Otoacoustic Emissions', ...
            'subtypes',{{'DPOAE','SFOAE','TEOAE'}}, ...
            'descriptions',{{ ...
              ['Estimates DPOAE amplitude using a two-tone UPWARD sweep paradigm. ' ...
               'Implements FPL calibration for accurate in-ear stimulus levels.'], ...
              ['Estimates SFOAE amplitude using a two-tone DOWNWARD sweep paradigm. ' ...
               'Implements FPL calibration for accurate in-ear stimulus levels.'], ...
              ['Estimates TEOAE amplitude using a click stimulus. ' ...
               'Implements FPL calibration for accurate in-ear stimulus levels.']}});
        app.MEASURES(4) = struct('name','MEMR','label','Middle Ear Muscle Reflex', ...
            'subtypes',{{}}, ...
            'descriptions',{{ ...
              ['Measures wideband acoustic reflex by tracking changes in absorbed sound ' ...
               'power (dB) across frequencies in response to a broadband elicitor at ' ...
               'multiple levels. Characterizes growth functions and reflex thresholds.']}});
    end

    % ── Setup-tab callbacks ───────────────────────────────────────────────

    function StopButtonPushed(app)
        app.abort_requested = true;
        app.StopButton.Text   = 'Stopping…';
        app.StopButton.Enable = 'off';
        drawnow;
    end

    function ProfileDropdownChanged(app)
        pname = get_profile_name(app);
        if ~isempty(pname), profile_ops(app, 'load_to_gui', pname); end
    end

    function NewUserButtonPushed(app)
        answer = inputdlg({'Enter your initials (e.g. FA):','Full name (optional):'}, ...
            'New User',1,{'',''});
        if isempty(answer) || isempty(strtrim(answer{1})), return; end
        initials = upper(strtrim(answer{1}));
        if ~isvarname(initials)
            uialert(app.UIFigure,'Initials must be letters only (e.g. FA).','Invalid Initials');
            return
        end
        app.profiles.(initials).name                = strtrim(answer{2});
        app.profiles.(initials).ROOTdir_mac         = '';
        app.profiles.(initials).ROOTdir_win         = '';
        app.profiles.(initials).chinroster_filename = 'DOD_ChinRoster.xlsx';
        app.profiles.(initials).last_sheet          = '';
        app.profiles.(initials).reanalyze           = 1;
        app.profiles.(initials).plot_relative_flag  = 0;
        pnames = fieldnames(app.profiles);
        app.ProfileDropdown.Items = pnames;
        app.ProfileDropdown.Value = initials;
        profile_ops(app, 'load_to_gui', initials);
    end

    function SaveUserButtonPushed(app)
        pname = get_profile_name(app);
        if isempty(pname), return; end
        profile_ops(app, 'save_current', pname);
        profile_ops(app, 'save_to_file');
        uialert(app.UIFigure, sprintf('User "%s" saved.',pname), 'Saved','Icon','success');
    end

    function BrowseButtonPushed(app)
        d = uigetdir(app.RootDirField.Value,'Select Root Directory (DOD folder)');
        if isequal(d,0), return; end
        app.RootDirField.Value = d;
        chinroster_ops(app, 'scan', '');
    end

    function RosterDropdownChanged(app)
        chinroster_ops(app, 'load');
    end

    function SheetDropdownChanged(app)
        new_sheet = app.SheetDropdown.Value;
        if new_sheet(1) == '(', return; end
        app.state.sheet = new_sheet;
        ROOTdir  = strtrim(app.RootDirField.Value);
        chinfile = app.RosterDropdown.Value;
        if isempty(ROOTdir) || chinfile(1) == '(', return; end
        filepath = fullfile(ROOTdir,'Analysis',chinfile);
        if exist(filepath,'file'), chinroster_ops(app, 'refresh_from', filepath); end
    end

    function SelectAllButtonPushed(app)
        for ii = 1:numel(app.h_subj_checks)
            if isvalid(app.h_subj_checks(ii)), app.h_subj_checks(ii).Value = true; end
        end
    end

    function ClearButtonPushed(app)
        for ii = 1:numel(app.h_subj_checks)
            if isvalid(app.h_subj_checks(ii)), app.h_subj_checks(ii).Value = false; end
        end
    end

    function RefreshButtonPushed(app)
        chinroster_ops(app, 'load');
    end

    function MeasureButtonPushed(app, src)
        app.state.measure_idx = src.UserData;
        app.state.subtype_idx = 1;
        navigate_results(app, 'measures');
    end

    function SubtypeButtonPushed(app, src)
        ud = src.UserData;
        app.state.measure_idx = ud(1);
        app.state.subtype_idx = ud(2);
        navigate_results(app, 'measures');
    end

    function RefreshStatusButtonPushed(app)
        build_status_table(app);
    end

    % ── Shared helpers ────────────────────────────────────────────────────

    function pname = get_profile_name(app)
        pname = '';
        items = app.ProfileDropdown.Items;
        val   = app.ProfileDropdown.Value;
        if ~isempty(items) && ~strcmp(items{1},'(no profiles)')
            pname = val;
        end
    end

    function subjs = get_checked_subjects(app)
        subjs = {};
        for ii = 1:numel(app.h_subj_checks)
            if isvalid(app.h_subj_checks(ii)) && app.h_subj_checks(ii).Value
                subjs{end+1} = app.subj_ids{ii}; %#ok<AGROW>
            end
        end
        subjs = subjs(:);
    end

    % ── Progress and spinner ──────────────────────────────────────────────

    function update_progress(app, n, total, msg)
        if ~isvalid(app) || total <= 0, return; end
        app.h_progress_label.Visible = 'on';
        app.h_progress_label.Text = ternary(n >= total, '✓  Complete', msg);
        drawnow('limitrate');
        if app.abort_requested
            error('APAT:UserAbort','Analysis stopped by user.');
        end
    end

    function start_spinner_anim(app)
        app.spinner_frame = 1;
        sc = spinner_chars(app);
        app.h_spinner_label.Text    = sc{1};
        app.h_spinner_label.Visible = 'on';
        drawnow;
        if ~isempty(app.h_spinner_timer) && isvalid(app.h_spinner_timer)
            stop(app.h_spinner_timer);  delete(app.h_spinner_timer);
        end
        app.h_spinner_timer = timer('Name','APAT_spinner','Period',0.12, ...
            'ExecutionMode','fixedRate','BusyMode','drop', ...
            'TimerFcn',@(~,~) spinner_tick(app));
        start(app.h_spinner_timer);
    end

    function spinner_tick(app)
        if ~isvalid(app) || ~isvalid(app.h_spinner_label), return; end
        chars = spinner_chars(app);
        app.spinner_frame = mod(app.spinner_frame, numel(chars)) + 1;
        app.h_spinner_label.Text = chars{app.spinner_frame};
        drawnow('limitrate');
    end

    function stop_spinner_anim(app, completed)
        if ~isvalid(app), return; end
        if ~isempty(app.h_spinner_timer) && isvalid(app.h_spinner_timer)
            stop(app.h_spinner_timer);  delete(app.h_spinner_timer);
            app.h_spinner_timer = [];
        end
        if completed
            app.h_spinner_label.Text    = '✓';
            app.h_spinner_label.Visible = 'on';
            drawnow;  pause(1.2);
        end
        app.h_spinner_label.Visible  = 'off';
        app.h_progress_label.Visible = 'off';
        drawnow;
    end

    function chars = spinner_chars(~)
        chars = {char(0x280B),char(0x2819),char(0x2839),char(0x2838), ...
                 char(0x283C),char(0x2834),char(0x2826),char(0x2827), ...
                 char(0x2807),char(0x280F)};
    end

end % private methods


% ══════════════════════════════════════════════════════════════════════════
%  STATIC UTILITY METHODS
% ══════════════════════════════════════════════════════════════════════════
methods (Static, Access = private)

    % Body in @APAT_app/read_chinroster_sheet.m
    [subjects, cond_paths, cond_labels] = read_chinroster_sheet(filepath, sheet)

    function labels = measure_tab_labels()
        labels = {'ABR Thresholds','ABR Peaks','EFR dAM','EFR RAM', ...
                  'DPOAE','SFOAE','TEOAE','MEMR'};
    end

    function [profiles, last_user] = load_profiles(profile_file)
        if exist(profile_file,'file')
            tmp       = load(profile_file,'profiles','last_user');
            profiles  = tmp.profiles;
            last_user = tmp.last_user;
        else
            profiles  = struct();
            last_user = '';
        end
    end

end % static methods


% ══════════════════════════════════════════════════════════════════════════
%  CONSTRUCTOR / DESTRUCTOR
% ══════════════════════════════════════════════════════════════════════════
methods (Access = public)

    function app = APAT_app
        persistent the_app

        % Bring existing instance to front if still valid
        if ~isempty(the_app) && isvalid(the_app) && isvalid(the_app.UIFigure)
            figure(the_app.UIFigure);
            if nargout > 0, app = the_app; end
            return;
        end

        % Clean up orphaned spinner timers from a previous instance
        try
            t = timerfindall('Name','APAT_spinner');
            if ~isempty(t), stop(t); delete(t); end
        catch; end

        initMeasures(app)    % must run before createComponents uses app.MEASURES
        createComponents(app)
        registerApp(app, app.UIFigure)
        runStartupFcn(app, @startupFcn)

        the_app = app;    % persist so 'clear app' doesn't kill the window
        if nargout == 0, clear app; end
    end

    function delete(app)
        if ~isempty(app.h_spinner_timer) && isvalid(app.h_spinner_timer)
            stop(app.h_spinner_timer);
            delete(app.h_spinner_timer);
        end
        if isvalid(app.UIFigure), delete(app.UIFigure); end
    end

end % public methods

end % classdef
