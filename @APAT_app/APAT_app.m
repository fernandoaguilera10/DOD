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
%     private/output_opts.m   — Setup Output choices (export format, images, plot defaults)
%     private/setup_style.m   — Setup selection look (subtle yellow, ON/OFF pills)
%     private/chin_sign.m     — header chinchilla's sign (messages: chin_messages.txt)
%     private/mono_font.m     — monospaced font for the pixel-style captions
%     icons/make_sprites.py   — measure icons + chinchilla sprites (icons/chin_*.png)
%     private/save_view.m     — Results "Save Image" / "Save As New"
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
    SheetPanel             matlab.ui.container.GridLayout   % Experiment buttons (grid; private/sheet_sel.m)
    SubjectsPanel          matlab.ui.container.Panel
    SelectAllBtn           matlab.ui.control.Button
    ClearSubjBtn           matlab.ui.control.Button
    RefreshSubjBtn         matlab.ui.control.Button
    ConditionsPanel        matlab.ui.container.Panel
    OptionsPanel           matlab.ui.container.Panel
    ReanalyzeCheck         matlab.ui.control.StateButton
    PlotRelativeCheck      matlab.ui.control.StateButton
    BlindCheck             matlab.ui.control.StateButton
    BlindOverlay           matlab.ui.container.Panel
    BlindOverlayMsg        matlab.ui.control.Label
    BlindRevealBtn         matlab.ui.control.Button
    MeasuresPanel          matlab.ui.container.Panel
    DescTitleLabel         matlab.ui.control.Label
    DescLabel              matlab.ui.control.Label
    % Results tab controls
    FigIndBtn              matlab.ui.control.StateButton
    FigAvgBtn              matlab.ui.control.StateButton
    FigSubjDropdown        matlab.ui.control.DropDown
    FigSubjCaption         matlab.ui.control.Label
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
    h_subj_checks         % toggle-chip array – subjects
    h_sheet_btns          % Experiment toggle buttons (one per roster sheet, sheet_sel)
    subj_ids              % cell array of subject ID strings
    h_cond_checks         % toggle-chip array – conditions
    h_cond_swatches       % colour swatch buttons – conditions (plot colour)
    h_cond_markers        % marker buttons – conditions (plot marker, app.state.cond_markers)
    h_cond_style          % condition colour / marker picker popup (chinroster_ops 'style_open')
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
    h_abr_wave_checks
    % EFR parameter controls
    h_efr_param_panel
    h_efr_harmonics_field
    h_efr_window_start_field
    h_efr_window_end_field
    % OAE / MEMR parameter panels
    h_oae_param_panel
    h_memr_param_panel
    % Setup-tab live summary (Run Summary card + project status labels)
    h_summary
    h_summary_proj
    h_row2_badges         % selection-count labels (Subjects, Conditions)
    h_output              % Setup Output card + panel handles (private/output_opts.m)
    layout_row2_in
    % Run status card (header): struct of handles, see private/run_status.m
    h_run
    % Setup: marker of the measure on screen, hint shown instead of empty parameters
    h_meas_marker
    h_param_hint
    RosterBuildBtn
    % Progress and spinner
    h_progress_label
    h_spinner_label
    h_spinner_timer
    spinner_frame
    abort_requested
    % Color palette
    clr_black; clr_gold; clr_gold_dk; clr_bg; clr_panel; clr_btn
    clr_sel; clr_sel2; clr_txt2; clr_on; clr_off   % Setup selection / ON-OFF look (setup_style)
    % Header chinchilla + sign (private/chin_sign.m)
    h_sign
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
    PeakEditSnapToggle   % snap ON/OFF state button
    PeakEditThreshBtn    % visual-threshold mode toggle
    PeakEditNelDD        % NEL confirmation (?/1/2)
    PeakEditSexDD        % sex confirmation (?/M/F)
    PeakEditWaveBtn    % 1×5 array of wave selector buttons (I–V)
    PeakEditPtToggle   % peak / trough toggle button
    PeakEditAbsentBtn  % mark selected wave absent (NaN)
    PeakEditRefDD      % Earl (1983) latency reference: Off / Earl / Earl re I
    PeakEditHelpBtn    % help window: chinchilla Waves I–V
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
    update_summary(app)
    subject_pick(app, action, src)

    % ── Startup ──────────────────────────────────────────────────────────

    function startupFcn(app)
        % mfilename returns path inside @APAT_app/ — go up one level to Code Archive/
        app.code_dir     = fileparts(fileparts(mfilename('fullpath')));
        app.profile_file = fullfile(app.code_dir,'@APAT_app','private','user_profiles.mat');
        old_profiles = fullfile(app.code_dir,'private','user_profiles.mat');   % before Oct 2026
        if ~exist(app.profile_file,'file') && exist(old_profiles,'file')
            try, copyfile(old_profiles, app.profile_file); catch, app.profile_file = old_profiles; end
        end
        % Code Archive/ (class folder parent) and Code Archive/shared/ (helpers used
        % by the app and every measure) — also when APAT_app is run directly.
        addpath(app.code_dir, fullfile(app.code_dir,'shared'));
        app.state.measure_idx = 1;
        app.state.subtype_idx = 1;
        app.state.sheet       = '';
        app.state.conds_all   = {};
        app.state.cond_labels = {};
        app.h_subj_checks = gobjects(0);
        app.subj_ids      = {};
        app.h_cond_checks = gobjects(0);
        app.h_cond_swatches = gobjects(0);
        app.h_cond_markers  = gobjects(0);
        app.state.cond_colors = zeros(0,3);
        app.state.cond_markers = {};                  % MATLAB marker codes per condition
        initMeasures(app);
        % Analyses selected for the next run: run_sel{m}(k) (one per type).
        % Several can be selected across measures; they run one after another.
        app.state.run_sel = arrayfun(@(M) false(1, max(1, numel(M.subtypes))), app.MEASURES, ...
            'UniformOutput', false);
        app.state.abr_freq = {true(1,6), true(1,6)};   % ABR frequencies: Thresholds, Peaks
        app.state.excl = struct();                     % Exclusions per analysis (private/exclusions.m)
        app.state.plot_defaults = apat_plot_defaults('defaults');   % Output: image saving + plot defaults of the last run
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
        try, chin_sign(app, 'pick'); catch, end      % header chinchilla's sign (user name known now)
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
        % MEMR: ART (original analysis, unchanged) + exploratory analyses that
        % all read one shared file per recording (MEMR/Explore/mx_analysis)
        app.MEASURES(4) = struct('name','MEMR','label','Middle Ear Muscle Reflex', ...
            'subtypes',{{'ART','Vector','Growth','Kinetics','Spectral','Absorbance','Probe','Quality'}}, ...
            'descriptions',{{ ...
              ['Measures the wideband acoustic reflex: the change in the ear-canal click ' ...
               'response (dB, re. the click with no elicitor) across frequencies while a ' ...
               'broadband elicitor plays at multiple levels. Characterizes growth functions ' ...
               '(reflex magnitude, 0.5–2 kHz) and acoustic reflex thresholds (ART).'], ...
              ['Vector change: compares the click spectra during the elicitor with the first ' ...
               'click (no elicitor) as complex numbers, so magnitude and phase changes both ' ...
               'count. A noise floor from the trial-to-trial variability gives a detection ' ...
               'threshold (SNR ≥ 3); also a vector ART and the corrected band power change.'], ...
              ['Suprathreshold growth: a sigmoid fitted to the vector growth function gives the ' ...
               'maximum response, midpoint, slope at the midpoint, 10–90 % dynamic range, area ' ...
               'above the noise floor and the slope above threshold.'], ...
              ['Click-by-click kinetics: the reflex at each of clicks 2–7 (one per elicitor ' ...
               'burst, ~167 ms apart). A build-up index shows whether the reflex grows or ' ...
               'adapts across the train; an exponential fit gives its time constant.'], ...
              ['Spectral pattern: the level change of the clicks during the elicitor across ' ...
               '0.2–8 kHz (1/6-octave), the change in octave bands at the top level and the ' ...
               'frequency of the largest change.'], ...
              ['Absorbance change: uses the session''s FPL calibration (probe source and ear-canal ' ...
               'impedance) to turn the click change into a change in wideband absorbance — the ' ...
               'standard WAI reflex measure (stiffening lowers absorbance below ~1 kHz).'], ...
              ['Elicitor as probe (exploratory): the elicitor noise is the same in the 7 sweeps of ' ...
               'a trial, so its recording in the ear canal is compared between the first burst ' ...
               'and later bursts, showing the reflex during the elicitor, with its own threshold.'], ...
              ['Recording quality: good clicks, trial-to-trial variability and drift of the ' ...
               'no-elicitor click, and the signal-to-noise ratio of the click and probe measures ' ...
               'at every elicitor level.']}});
    end

    % ── Setup-tab callbacks ───────────────────────────────────────────────

    function StopButtonPushed(app)
        app.abort_requested = true;
        run_status(app, 'stopping');
        % Peak editor waiting for a click → wake it up; it saves and exits
        setappdata(app.UIFigure, 'peak_abort', true);
        setappdata(app.UIFigure, 'peak_action', struct('type','abort','x',[]));
        uiresume(app.UIFigure);
        drawnow;
    end

    function ProfileDropdownChanged(app)
        pname = get_profile_name(app);
        if ~isempty(pname), profile_ops(app, 'load_to_gui', pname); end
        try, chin_sign(app, 'pick'); catch, end      % greet the new user
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

    function SelectAllButtonPushed(app)
        for ii = 1:numel(app.h_subj_checks)
            if isvalid(app.h_subj_checks(ii)), app.h_subj_checks(ii).Value = true; end
        end
        update_summary(app);
    end

    function ClearButtonPushed(app)
        for ii = 1:numel(app.h_subj_checks)
            if isvalid(app.h_subj_checks(ii)), app.h_subj_checks(ii).Value = false; end
        end
        update_summary(app);
    end

    function RefreshButtonPushed(app)
        chinroster_ops(app, 'load');
    end

    function MeasureButtonPushed(app, src)
        % Show this measure's types and parameters; the run selection is
        % not changed (types are added / removed with their own buttons).
        m = src.UserData;
        app.state.measure_idx = m;
        app.state.param_shown = false;              % parameters: selected type, or a type pointed at
        k = find(app.state.run_sel{m}, 1);
        if isempty(k), k = 1; end
        app.state.subtype_idx = k;
        navigate_results(app, 'measures');
    end

    function SubtypeButtonPushed(app, src)
        % Type button = add to / remove from the run. Clicking a type that is
        % not selected selects it and shows its parameters; clicking the
        % selected type on screen removes it from the run. Clicking a
        % selected type that is not on screen just shows its parameters.
        ud = src.UserData;  m = ud(1);  k = ud(2);
        on_screen = app.state.measure_idx == m && app.state.subtype_idx == k;
        if ~app.state.run_sel{m}(k)
            app.state.run_sel{m}(k) = true;
        elseif on_screen
            app.state.run_sel{m}(k) = false;
            k2 = find(app.state.run_sel{m}, 1);    % another type of this measure still selected → show it
            if ~isempty(k2), k = k2; end
        end
        app.state.measure_idx = m;
        app.state.subtype_idx = k;
        app.state.param_shown = true;               % a clicked type shows its parameters
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
        run_status(app, 'progress', n, total, msg);
        drawnow('limitrate');
        if app.abort_requested
            error('APAT:UserAbort','Analysis stopped by user.');
        end
    end

    function start_spinner_anim(app)
        % chinchilla animation step + elapsed time (run_status 'tick', 0.25 s)
        if ~isempty(app.h_spinner_timer) && isvalid(app.h_spinner_timer)
            stop(app.h_spinner_timer);  delete(app.h_spinner_timer);
        end
        app.h_spinner_timer = timer('Name','APAT_spinner','Period',0.25, ...
            'ExecutionMode','fixedRate','BusyMode','drop', ...
            'TimerFcn',@(~,~) spinner_tick(app));
        start(app.h_spinner_timer);
    end

    function spinner_tick(app)
        if ~isvalid(app), return; end
        app.spinner_frame = mod(app.spinner_frame, 2) + 1;
        run_status(app, 'tick', app.spinner_frame);
    end

    function stop_spinner_anim(app, ~)
        if ~isvalid(app), return; end
        if ~isempty(app.h_spinner_timer) && isvalid(app.h_spinner_timer)
            stop(app.h_spinner_timer);  delete(app.h_spinner_timer);
            app.h_spinner_timer = [];
        end
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
        % 'MEMR' = MEMR ART (key kept so saved exclusions still apply);
        % the exploratory MEMR analyses come after it (indices 9-15)
        labels = {'ABR Thresholds','ABR Peaks','EFR dAM','EFR RAM', ...
                  'DPOAE','SFOAE','TEOAE','MEMR', ...
                  'MEMR Vector','MEMR Growth','MEMR Kinetics','MEMR Spectral', ...
                  'MEMR Absorbance','MEMR Probe','MEMR Quality'};
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
            t = [timerfindall('Name','APAT_spinner'), timerfindall('Name','APAT_relayout'), ...
                 timerfindall('Name','APAT_runcard'), timerfindall('Name','APAT_chinhop')];
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
        if isvalid(app.UIFigure)
            try                                   % macOS: leave full screen before deleting
                if ismac && strcmp(app.UIFigure.WindowState,'fullscreen')
                    app.UIFigure.WindowState = 'normal';  drawnow;  pause(1.5);
                end
            catch
            end
            if isvalid(app.UIFigure), delete(app.UIFigure); end
        end
    end

end % public methods

end % classdef
