classdef APAT_app < matlab.apps.AppBase
%APAT_APP  Auditory Physiology Analysis Toolkit — App Designer version.
%
%   Three-tab workflow:
%     1. Setup   – configure user, project, subjects, conditions,
%                  options, and auditory measure; then click Run Analysis
%     2. Figures – Individual sub-tab: per-subject/condition plots
%                  Average sub-tab: final averaged plots
%     3. Status  – data-availability table across subjects × conditions
%
%   Run:  APAT_app

% ── Public properties: all named UI components ────────────────────────────
properties (Access = public)
    UIFigure                matlab.ui.Figure
    % Header (fixed across tabs)
    HeaderPanel             matlab.ui.container.Panel
    TitleLabel              matlab.ui.control.Label
    SubtitleLabel           matlab.ui.control.Label
    RunButton               matlab.ui.control.Button
    StopButton              matlab.ui.control.Button
    % Tab group
    TabGroup                matlab.ui.container.TabGroup
    SetupTab                matlab.ui.container.Tab
    FiguresTab              matlab.ui.container.Tab
    StatusTab               matlab.ui.container.Tab
    % ── Setup tab ──────────────────────────────────────────────────────────
    UserPanel               matlab.ui.container.Panel
    ProfileDropdown         matlab.ui.control.DropDown
    NewUserBtn              matlab.ui.control.Button
    SaveUserBtn             matlab.ui.control.Button
    ProjectPanel            matlab.ui.container.Panel
    RootDirLabel            matlab.ui.control.Label
    RootDirField            matlab.ui.control.EditField
    BrowseBtn               matlab.ui.control.Button
    RosterLabel             matlab.ui.control.Label
    RosterDropdown          matlab.ui.control.DropDown
    ExpLabel                matlab.ui.control.Label
    SheetDropdown           matlab.ui.control.DropDown
    % ── Setup tab (continued) ──────────────────────────────────────────────
    SubjectsPanel           matlab.ui.container.Panel
    SelectAllBtn            matlab.ui.control.Button
    ClearSubjBtn            matlab.ui.control.Button
    RefreshSubjBtn          matlab.ui.control.Button
    ConditionsPanel         matlab.ui.container.Panel
    OptionsPanel            matlab.ui.container.Panel
    ReanalyzeCheck          matlab.ui.control.CheckBox
    PlotRelativeCheck       matlab.ui.control.CheckBox
    ShowAnalysisCheck       matlab.ui.control.CheckBox
    ShowIndCheck            matlab.ui.control.CheckBox
    ShowAvgCheck            matlab.ui.control.CheckBox
    MeasuresPanel           matlab.ui.container.Panel
    DescTitleLabel          matlab.ui.control.Label
    DescLabel               matlab.ui.control.Label
    % ── Figures tab ────────────────────────────────────────────────────────
    FigIndBtn               matlab.ui.control.StateButton
    FigAvgBtn               matlab.ui.control.StateButton
    FigExpDropdown          matlab.ui.control.DropDown
    FigSubjDropdown         matlab.ui.control.DropDown
    FigSubtypeDD            matlab.ui.control.DropDown
    FigFreqDD               matlab.ui.control.DropDown
    FigLevelDD              matlab.ui.control.DropDown
    % ── Status tab ─────────────────────────────────────────────────────────
    RefreshStatusBtn        matlab.ui.control.Button
    StatusInnerTG           matlab.ui.container.TabGroup
    % ── User Input tab ─────────────────────────────────────────────────────
    UserInputTab            matlab.ui.container.Tab
end

% ── Private properties: app state and dynamic handles ─────────────────────
properties (Access = private)
    MEASURES
    state
    profiles
    last_user
    code_dir
    profile_file
    % Dynamic component arrays (rebuilt when chinroster changes)
    h_subj_checks           % uicheckbox array – subjects
    subj_ids                % cell array of subject ID strings
    h_cond_checks           % uicheckbox array – conditions
    h_meas_btns             % uibutton array   – measure selector (Setup)
    h_sub_btns              % cell of uibutton arrays – subtypes
    % Figures tab panels
    fig_major_btns          % 1×4 push button handles – ABR/EFR/OAE/MEMR
    fig_cur_major           % current major index 1..4
    fig_panels              % 2×8 cell array of uipanels {mode, measure}
    fig_panel_mode          % current mode: 1=Individual, 2=Average
    fig_panel_meas          % current measure index 1..8
    fig_subj_data           % 1×8 cell of struct(names,panels,exps)
    % Purdue palette
    clr_black; clr_gold; clr_gold_dk; clr_bg; clr_panel; clr_btn
    % Measure-button layout constants
    n_meas; meas_h; meas_gap
    meas_sub_area_start  % pixel x where subtype buttons begin (used by refreshMeasureButtons)
    % Panel height constants (set in buildSetupTab, used by helpers)
    layout_row2_h       % height of Subjects/Conditions/Options row
    layout_meas_h       % height of MeasuresPanel
    % ABR Peaks parameter controls (shown only for ABR→Peaks)
    h_abr_param_panel        % uipanel container
    h_abr_freq_checks        % uicheckbox array – frequencies
    h_abr_level_checks       % uicheckbox array – levels
    h_abr_tpl_req_check      % uicheckbox – require template for each level
    h_abr_custom_freq_field  % uieditfield – custom frequencies saved in profile
    % User Input tab – template creation controls
    h_tpl_subj_dd            % subject dropdown
    h_tpl_cond_dd            % condition dropdown
    h_tpl_freq_dd            % frequency dropdown
    h_tpl_level_dd           % level editfield
    h_tpl_status_label       % label showing template scan results
    h_tpl_list_panel         % scrollable panel listing existing templates
    % Progress spinner (under Run Analysis button)
    h_progress_label         % uilabel – status text under Run button
    h_spinner_label          % uilabel – rotating char under Run button
    h_spinner_timer          % timer – drives spinner animation
    spinner_frame            % current frame index into spinner chars
    % Stop / abort
    abort_requested          % logical – set true by StopButton to cancel analysis
    % ABR wave selection / normalization (Peaks only)
    h_abr_wave_checks        % uicheckbox array W1-W5
    h_abr_ratio_field        % uieditfield – ratio combinations
    % EFR parameter controls (shown only for EFR measures)
    h_efr_param_panel        % uipanel container
    h_efr_harmonics_field    % uieditfield – max harmonics (RAM only)
    h_efr_window_start_field % uieditfield – analysis window start s (RAM only)
    h_efr_window_end_field   % uieditfield – analysis window end s (RAM only)
    % OAE parameter panel (shown only for OAE measures)
    h_oae_param_panel        % uipanel container
    % MEMR parameter panel (shown only for MEMR)
    h_memr_param_panel       % uipanel container
end

% ══════════════════════════════════════════════════════════════════════════
%  PRIVATE METHODS
% ══════════════════════════════════════════════════════════════════════════
methods (Access = private)

    % ── Component construction ─────────────────────────────────────────────

    function createComponents(app)
        app.clr_black   = [0.08 0.08 0.08];
        app.clr_gold    = [0.81 0.73 0.57];
        app.clr_gold_dk = [0.55 0.42 0.12];
        app.clr_bg      = [0.97 0.96 0.93];
        app.clr_panel   = [0.93 0.91 0.87];
        app.clr_btn     = [0.86 0.84 0.79];

        PAD   = 8;
        HDR_H = 110;

        % Use screen size for component layout; WindowState='maximized' handles display.
        % On macOS the menu bar (~25px) + title bar (~22px) eat into the top,
        % so subtract 50px from height to keep all components in the visible area.
        scr   = get(0,'ScreenSize');
        FIG_W = scr(3);
        FIG_H = scr(4) - 50;
        TAB_H = FIG_H - HDR_H;

        app.UIFigure = uifigure( ...
            'Name','Auditory Physiology Analysis Toolkit (APAT)', ...
            'WindowState','maximized', ...
            'Color',app.clr_bg, ...
            'CloseRequestFcn', @(~,~) delete(app));

        % ── Header ─────────────────────────────────────────────────────────
        app.HeaderPanel = uipanel(app.UIFigure, ...
            'BorderType','none','BackgroundColor',app.clr_black, ...
            'Position',[0 FIG_H-HDR_H FIG_W HDR_H]);

        app.TitleLabel = uilabel(app.HeaderPanel, ...
            'Text','Auditory Physiology Analysis Toolkit (APAT)', ...
            'Position',[16 54 FIG_W-250 36], ...
            'FontSize',26,'FontWeight','bold', ...
            'FontColor',app.clr_gold);

        app.SubtitleLabel = uilabel(app.HeaderPanel, ...
            'Text','Auditory Neurophysiology and Modeling Lab  —  Purdue University', ...
            'Position',[16 30 FIG_W-250 22], ...
            'FontSize',15, ...
            'FontColor',[0.88 0.84 0.74]);

        RUN_W = 190;  RUN_H = 46;
        app.RunButton = uibutton(app.HeaderPanel,'push', ...
            'Text','▶  Run Analysis', ...
            'Position',[FIG_W-RUN_W-16 round((HDR_H-RUN_H)/2) RUN_W RUN_H], ...
            'FontSize',16,'FontWeight','bold', ...
            'FontColor',app.clr_black,'BackgroundColor',app.clr_gold, ...
            'ButtonPushedFcn', @(~,~) RunButtonPushed(app));

        % ── Stop button + spinner + progress label ───────────────────────────
        RUN_X   = FIG_W - RUN_W - 16;
        RUN_Y   = round((HDR_H - RUN_H) / 2);
        STOP_W  = 120;  STOP_H = RUN_H;
        SPIN_W  = 30;   SPIN_H = 30;
        LBL_H   = 16;
        % Stop button: same height as Run, immediately left of it
        STOP_X  = RUN_X - STOP_W - 10;
        STOP_Y  = RUN_Y;
        % Spinner: vertically centered with Run button, 10 px gap left of Stop
        SPIN_X  = STOP_X - SPIN_W - 10;
        SPIN_Y  = RUN_Y + round((RUN_H - SPIN_H) / 2);
        % Progress text: centered directly under Run button
        LBL_Y   = RUN_Y - LBL_H - 3;

        app.StopButton = uibutton(app.HeaderPanel,'push', ...
            'Text','■  Stop', ...
            'Position',[STOP_X STOP_Y STOP_W STOP_H], ...
            'FontSize',16,'FontWeight','bold', ...
            'FontColor',app.clr_black,'BackgroundColor',[0.78 0.28 0.28], ...
            'Visible','off','Enable','on', ...
            'ButtonPushedFcn', @(~,~) StopButtonPushed(app));

        app.h_spinner_label = uilabel(app.HeaderPanel, ...
            'Text','', 'FontSize',18, ...
            'FontColor',app.clr_gold, ...
            'HorizontalAlignment','center', ...
            'Position',[SPIN_X SPIN_Y SPIN_W SPIN_H], ...
            'Visible','off');
        app.h_progress_label = uilabel(app.HeaderPanel, ...
            'Text','', 'FontSize',10, ...
            'FontColor',[0.78 0.74 0.64], ...
            'HorizontalAlignment','center', ...
            'Position',[RUN_X LBL_Y RUN_W LBL_H], ...
            'Visible','off');
        app.spinner_frame = 1;
        app.abort_requested = false;

        % ── Tab group ───────────────────────────────────────────────────────
        app.TabGroup = uitabgroup(app.UIFigure, 'Position',[0 0 FIG_W TAB_H]);
        app.SetupTab      = uitab(app.TabGroup,'Title','  Setup  ');
        app.FiguresTab    = uitab(app.TabGroup,'Title','  Figures  ');
        app.StatusTab     = uitab(app.TabGroup,'Title','  Data Status  ');
        app.UserInputTab  = uitab(app.TabGroup,'Title','  User Input  ');
        app.SetupTab.BackgroundColor      = app.clr_bg;
        app.FiguresTab.BackgroundColor    = app.clr_bg;
        app.StatusTab.BackgroundColor     = app.clr_bg;
        app.UserInputTab.BackgroundColor  = app.clr_bg;

        buildSetupTab(app,      PAD, FIG_W, TAB_H);
        buildFiguresTab(app,    PAD, FIG_W, TAB_H);
        buildStatusTab(app,     PAD, FIG_W, TAB_H);
        buildUserInputTab(app,  PAD, FIG_W, TAB_H);
    end

    function buildSetupTab(app, PAD, FIG_W, TAB_H)
        FS   = 15;   % base font size
        CH   = 30;   % standard control height
        LH   = 24;   % label height

        % ── Row heights and y positions (bottom → top) ──────────────────────
        ROW1_H = 4*CH + 2*PAD + 20;   % 3 controls + title gap (~172px)
        ROW2_H = 5*CH + 2*PAD + 20;   % 5 checkboxes + title gap (~192px)
        MEAS_H = max(100, TAB_H - 30 - PAD - ROW1_H - PAD - ROW2_H - PAD - PAD);

        app.layout_row2_h = ROW2_H;
        app.layout_meas_h = MEAS_H;

        meas_y  = PAD;
        row2_y  = meas_y  + MEAS_H  + PAD;
        row1_y  = row2_y  + ROW2_H  + PAD;

        USER_W = 240;
        SP_X   = PAD + USER_W + PAD;
        SP_W   = FIG_W - SP_X - PAD;

        % ── User panel ──────────────────────────────────────────────────────
        app.UserPanel = uipanel(app.SetupTab, ...
            'Title','User','FontSize',FS,'FontWeight','bold', ...
            'BackgroundColor',app.clr_panel,'BorderColor',app.clr_gold, ...
            'Position',[PAD row1_y USER_W ROW1_H]);

        inner_w = USER_W - 22;
        y3 = ROW1_H - 30 - CH;
        y2 = y3 - PAD - CH;
        y1 = y2 - PAD - CH;
        app.ProfileDropdown = uidropdown(app.UserPanel, ...
            'Items',{'(no profiles)'},'Value','(no profiles)', ...
            'Position',[8 y3 inner_w CH], ...
            'FontSize',FS,'FontWeight','bold', ...
            'ValueChangedFcn', @(~,~) ProfileDropdownChanged(app));
        app.NewUserBtn = uibutton(app.UserPanel,'push','Text','New User', ...
            'Position',[8 y2 inner_w CH],'FontSize',FS,'BackgroundColor',app.clr_btn, ...
            'ButtonPushedFcn', @(~,~) NewUserButtonPushed(app));
        app.SaveUserBtn = uibutton(app.UserPanel,'push','Text','Save User', ...
            'Position',[8 y1 inner_w CH],'FontSize',FS,'BackgroundColor',app.clr_btn, ...
            'ButtonPushedFcn', @(~,~) SaveUserButtonPushed(app));

        % ── Project settings panel ──────────────────────────────────────────
        app.ProjectPanel = uipanel(app.SetupTab, ...
            'Title','Project Settings','FontSize',FS,'FontWeight','bold', ...
            'BackgroundColor',app.clr_panel,'BorderColor',app.clr_gold, ...
            'Position',[SP_X row1_y SP_W ROW1_H]);

        LBL_W = 140;  CTRL_X = LBL_W + 8;  CTRL_W = SP_W - CTRL_X - 14;
        py3 = ROW1_H - 30 - CH;
        py2 = py3 - PAD - CH;
        py1 = py2 - PAD - CH;
        uilabel(app.ProjectPanel,'Text','Root Directory:', ...
            'Position',[8 py3 LBL_W LH],'FontSize',FS);
        app.RootDirField = uieditfield(app.ProjectPanel,'text','Value','', ...
            'Position',[CTRL_X py3 CTRL_W-100 CH],'FontSize',FS,'BackgroundColor','white');
        app.BrowseBtn = uibutton(app.ProjectPanel,'push','Text','Browse...', ...
            'Position',[CTRL_X+CTRL_W-96 py3 96 CH],'FontSize',FS,'BackgroundColor',app.clr_btn, ...
            'ButtonPushedFcn', @(~,~) BrowseButtonPushed(app));
        uilabel(app.ProjectPanel,'Text','Subject Roster:', ...
            'Position',[8 py2 LBL_W LH],'FontSize',FS);
        app.RosterDropdown = uidropdown(app.ProjectPanel, ...
            'Items',{'(set root directory first)'},'Value','(set root directory first)', ...
            'Position',[CTRL_X py2 CTRL_W CH],'FontSize',FS, ...
            'ValueChangedFcn', @(~,~) RosterDropdownChanged(app));
        uilabel(app.ProjectPanel,'Text','Experiment:', ...
            'Position',[8 py1 LBL_W LH],'FontSize',FS);
        app.SheetDropdown = uidropdown(app.ProjectPanel, ...
            'Items',{'(load chinroster first)'},'Value','(load chinroster first)', ...
            'Position',[CTRL_X py1 round(CTRL_W*0.6) CH],'FontSize',FS+1,'FontWeight','bold', ...
            'ValueChangedFcn', @(~,~) SheetDropdownChanged(app));

        % ── Subjects ────────────────────────────────────────────────────────
        subj_w  = round((FIG_W - 3*PAD) * 0.55);
        right_w = FIG_W - 3*PAD - subj_w;
        opt_w2  = max(220, round(right_w * 0.40));
        cond_w  = right_w - PAD - opt_w2;

        app.SubjectsPanel = uipanel(app.SetupTab, ...
            'Title','Subjects','FontSize',FS,'FontWeight','bold', ...
            'BackgroundColor',app.clr_panel,'BorderColor',app.clr_gold, ...
            'Position',[PAD row2_y subj_w ROW2_H]);

        BTN_W3 = round((subj_w - 4*PAD) / 3);
        app.SelectAllBtn = uibutton(app.SubjectsPanel,'push','Text','Select All', ...
            'Position',[PAD PAD BTN_W3 CH], ...
            'FontSize',FS,'BackgroundColor',app.clr_btn, ...
            'ButtonPushedFcn', @(~,~) SelectAllButtonPushed(app));
        app.ClearSubjBtn = uibutton(app.SubjectsPanel,'push','Text','Clear', ...
            'Position',[2*PAD+BTN_W3 PAD BTN_W3 CH], ...
            'FontSize',FS,'BackgroundColor',app.clr_btn, ...
            'ButtonPushedFcn', @(~,~) ClearButtonPushed(app));
        app.RefreshSubjBtn = uibutton(app.SubjectsPanel,'push','Text','Refresh', ...
            'Position',[3*PAD+2*BTN_W3 PAD BTN_W3 CH], ...
            'FontSize',FS,'BackgroundColor',app.clr_btn, ...
            'ButtonPushedFcn', @(~,~) RefreshButtonPushed(app));

        % ── Conditions ──────────────────────────────────────────────────────
        app.ConditionsPanel = uipanel(app.SetupTab, ...
            'Title','Conditions','FontSize',FS,'FontWeight','bold', ...
            'BackgroundColor',app.clr_panel,'BorderColor',app.clr_gold, ...
            'Position',[PAD+subj_w+PAD row2_y cond_w ROW2_H]);

        % ── Options ─────────────────────────────────────────────────────────
        opt_x = PAD + subj_w + PAD + cond_w + PAD;
        app.OptionsPanel = uipanel(app.SetupTab, ...
            'Title','Options','FontSize',FS,'FontWeight','bold', ...
            'BackgroundColor',app.clr_panel,'BorderColor',app.clr_gold, ...
            'Position',[opt_x row2_y opt_w2 ROW2_H]);

        ck_labels   = {'Re-analyze existing data','Plot relative to Baseline', ...
                       'Show analysis figures','Show individual plots','Show average plots'};
        ck_defaults = [true false false true true];
        ck_handles  = {'ReanalyzeCheck','PlotRelativeCheck','ShowAnalysisCheck', ...
                       'ShowIndCheck','ShowAvgCheck'};
        n_ck = numel(ck_labels);
        ck_avail = ROW2_H - 38 - 8;   % below title + above bottom edge
        ck_gap = max(2, (ck_avail - n_ck*CH) / (n_ck + 1));
        for ci = 1:n_ck
            cy = 8 + (n_ck - ci) * (CH + ck_gap) + ck_gap;
            app.(ck_handles{ci}) = uicheckbox(app.OptionsPanel, ...
                'Text',ck_labels{ci}, 'Value',ck_defaults(ci), ...
                'Position',[10 round(cy) opt_w2-20 CH], ...
                'FontSize',FS);
        end

        % ── Auditory Measures ────────────────────────────────────────────────
        app.MeasuresPanel = uipanel(app.SetupTab, ...
            'Title','Auditory Measures','FontSize',FS,'FontWeight','bold', ...
            'BackgroundColor',app.clr_panel,'BorderColor',app.clr_gold, ...
            'Position',[PAD meas_y FIG_W-2*PAD MEAS_H]);

        panel_w  = FIG_W - 2*PAD;
        % Layout: measure btns (0→14%), divider, subtype btns (16→50%),
        %         description + ABR params fill remaining right space.
        % Exact positions are updated dynamically in refreshMeasureButtons;
        % these are placeholder values for initial construction.
        DESC_X   = round(0.52 * panel_w);
        DESC_W   = max(200, round(panel_w * 0.20));
        RIGHT_X  = DESC_X + DESC_W + 12;
        RIGHT_W  = max(300, panel_w - RIGHT_X - PAD);

        app.DescTitleLabel = uilabel(app.MeasuresPanel, 'Text','', ...
            'Position',[DESC_X round(0.60*MEAS_H) DESC_W round(0.09*MEAS_H)], ...
            'FontSize',FS,'FontWeight','bold','FontColor',app.clr_black);
        app.DescLabel = uilabel(app.MeasuresPanel, 'Text','', ...
            'Position',[DESC_X round(0.05*MEAS_H) DESC_W round(0.51*MEAS_H)], ...
            'FontSize',FS,'FontColor',app.clr_gold_dk,'WordWrap','on');

        % Measure/subtype buttons built after MEASURES is initialised
        app.h_meas_btns = gobjects(0);
        app.h_sub_btns  = {};

        % ── ABR Parameters panel (right side, hidden until ABR selected) ─────
        % INNER_H: fixed coordinate space for controls (scrollable if screen is small)
        INNER_H     = 470;
        ABR_OUTER_H = min(INNER_H, max(220, MEAS_H - 10));
        ABR_PANEL_Y = round((MEAS_H - ABR_OUTER_H) / 2);

        app.h_abr_param_panel = uipanel(app.MeasuresPanel, ...
            'Title','ABR Parameters','FontSize',FS,'FontWeight','bold', ...
            'BackgroundColor',app.clr_panel,'BorderColor',app.clr_gold, ...
            'Position',[RIGHT_X ABR_PANEL_Y RIGHT_W ABR_OUTER_H], ...
            'Scrollable','on', ...
            'Visible','off');

        inner_rw  = RIGHT_W - 2*PAD;
        SECT_GAP  = 16;   % vertical gap between sections

        % Frequency checkboxes (shown for Thresholds AND Peaks)
        freq_labels = {'Click','0.5 kHz','1 kHz','2 kHz','4 kHz','8 kHz'};
        n_freq = numel(freq_labels);
        ck_w = max(60, floor(inner_rw / n_freq));
        app.h_abr_freq_checks = gobjects(1, n_freq);
        FREQ_Y  = INNER_H - 40 - CH;
        FREQ_LY = FREQ_Y + CH + 4;
        uilabel(app.h_abr_param_panel,'Text','Frequencies:', ...
            'Position',[PAD FREQ_LY inner_rw LH],'FontSize',FS,'FontWeight','bold');
        for fi = 1:n_freq
            app.h_abr_freq_checks(fi) = uicheckbox(app.h_abr_param_panel, ...
                'Text',freq_labels{fi}, 'Value',true, ...
                'Position',[PAD + (fi-1)*ck_w FREQ_Y ck_w-2 CH],'FontSize',FS-1);
        end

        % Level checkboxes (Peaks only — shown/hidden by refreshMeasureButtons)
        level_labels = {'80 dB','70 dB','60 dB','50 dB','40 dB'};
        n_lev = numel(level_labels);
        lev_w = max(60, floor(inner_rw / n_lev));
        app.h_abr_level_checks = gobjects(1, n_lev);
        LEV_Y  = FREQ_Y - SECT_GAP - LH - CH;
        LEV_LY = LEV_Y + CH + 4;
        uilabel(app.h_abr_param_panel,'Text','Levels (Peaks only):', ...
            'Tag','abr_lev_lbl', ...
            'Position',[PAD LEV_LY inner_rw LH],'FontSize',FS,'FontWeight','bold');
        for li = 1:n_lev
            app.h_abr_level_checks(li) = uicheckbox(app.h_abr_param_panel, ...
                'Text',level_labels{li}, 'Value',true, ...
                'Position',[PAD + (li-1)*lev_w LEV_Y lev_w-2 CH],'FontSize',FS-1);
        end

        % Custom frequencies — saved in user profile
        CUST_Y  = LEV_Y - SECT_GAP - LH - CH;
        CUST_LY = CUST_Y + CH + 4;
        uilabel(app.h_abr_param_panel,'Text','Custom Freqs (Hz, comma-separated):', ...
            'Position',[PAD CUST_LY inner_rw LH],'FontSize',FS-2);
        app.h_abr_custom_freq_field = uieditfield(app.h_abr_param_panel,'text', ...
            'Value','','Placeholder','e.g. 3000, 6000  (saved in profile)', ...
            'Position',[PAD CUST_Y inner_rw CH],'FontSize',FS-2, ...
            'BackgroundColor','white');

        % Template requirement option (Peaks only)
        TPL_Y = CUST_Y - SECT_GAP - CH;
        app.h_abr_tpl_req_check = uicheckbox(app.h_abr_param_panel, ...
            'Text','Require template for each level (Peaks only)', ...
            'Tag','abr_tpl_req', ...
            'Value', false, ...
            'Position',[PAD TPL_Y inner_rw CH],'FontSize',FS-2, ...
            'Tooltip','Unchecked (default): if a level has no template, use the highest-level template as a fallback. Checked: only run DTW for levels that have their own template; skip the rest.');

        % Wave selection checkboxes (Peaks only)
        wave_labels = {'W I','W II','W III','W IV','W V'};
        n_wave = numel(wave_labels);
        wave_ck_w = max(48, floor(inner_rw / n_wave));
        app.h_abr_wave_checks = gobjects(1, n_wave);
        WAVE_Y  = TPL_Y - SECT_GAP - LH - CH;
        WAVE_LY = WAVE_Y + CH + 4;
        uilabel(app.h_abr_param_panel,'Text','Waves to Show (Peaks only):', ...
            'Tag','abr_wave_lbl', ...
            'Position',[PAD WAVE_LY inner_rw LH],'FontSize',FS-2,'FontWeight','bold');
        for wi = 1:n_wave
            app.h_abr_wave_checks(wi) = uicheckbox(app.h_abr_param_panel, ...
                'Text',wave_labels{wi}, 'Value',true, ...
                'Tag','abr_wave_ck', ...
                'Position',[PAD+(wi-1)*wave_ck_w WAVE_Y wave_ck_w-2 CH],'FontSize',FS-2);
        end

        % Normalization ratios (Peaks only)
        RATIO_Y  = WAVE_Y - SECT_GAP - LH - CH;
        RATIO_LY = RATIO_Y + CH + 4;
        uilabel(app.h_abr_param_panel,'Text','Normalization Ratios (e.g. W1/W5, W1/W2):', ...
            'Tag','abr_ratio_lbl', ...
            'Position',[PAD RATIO_LY inner_rw LH],'FontSize',FS-2);
        app.h_abr_ratio_field = uieditfield(app.h_abr_param_panel,'text', ...
            'Value','W1/W5', ...
            'Tag','abr_ratio_field', ...
            'Position',[PAD RATIO_Y inner_rw CH],'FontSize',FS-2, ...
            'BackgroundColor','white', ...
            'Tooltip','Comma-separated wave ratios shown in avg plots. E.g. "W1/W5, W1/W2". Leave empty to hide ratio panel.');

        % ── EFR Parameters panel (right side, hidden until EFR selected) ────
        app.h_efr_param_panel = uipanel(app.MeasuresPanel, ...
            'Title','EFR Parameters','FontSize',FS,'FontWeight','bold', ...
            'BackgroundColor',app.clr_panel,'BorderColor',app.clr_gold, ...
            'Position',[RIGHT_X ABR_PANEL_Y RIGHT_W ABR_OUTER_H], ...
            'Scrollable','on', ...
            'Visible','off');

        % RAM section header
        uilabel(app.h_efr_param_panel,'Text','RAM — configurable:', ...
            'Tag','efr_ram_hdr', ...
            'Position',[PAD INNER_H-40 inner_rw LH],'FontSize',FS,'FontWeight','bold');
        uilabel(app.h_efr_param_panel,'Text','Mod. freq: 223 Hz  |  Filter: 60–4000 Hz', ...
            'Tag','efr_ram_info', ...
            'Position',[PAD INNER_H-65 inner_rw LH],'FontSize',FS-2,'FontColor',[0.5 0.5 0.5]);

        % Max harmonics
        HARM_Y  = INNER_H - 100 - CH;
        HARM_LY = HARM_Y + CH + 4;
        uilabel(app.h_efr_param_panel,'Text','Max harmonics (1–16):', ...
            'Tag','efr_harm_lbl', ...
            'Position',[PAD HARM_LY inner_rw LH],'FontSize',FS,'FontWeight','bold');
        app.h_efr_harmonics_field = uieditfield(app.h_efr_param_panel,'numeric', ...
            'Value',16,'Limits',[1 16],'RoundFractionalValues','on', ...
            'Tag','efr_harmonics', ...
            'Position',[PAD HARM_Y 80 CH],'FontSize',FS, ...
            'BackgroundColor','white', ...
            'Tooltip','Number of harmonics analyzed in RAM EFR (default: 16)');

        % Analysis window
        WIN_Y  = HARM_Y - SECT_GAP - LH - CH;
        WIN_LY = WIN_Y + CH + 4;
        uilabel(app.h_efr_param_panel,'Text','Analysis window (s):', ...
            'Tag','efr_win_lbl', ...
            'Position',[PAD WIN_LY inner_rw LH],'FontSize',FS,'FontWeight','bold');
        uilabel(app.h_efr_param_panel,'Text','Start:', ...
            'Tag','efr_win_s_lbl', ...
            'Position',[PAD WIN_Y 38 CH],'FontSize',FS-2);
        app.h_efr_window_start_field = uieditfield(app.h_efr_param_panel,'numeric', ...
            'Value',0.2,'Limits',[0 2], ...
            'Tag','efr_win_start', ...
            'Position',[PAD+42 WIN_Y 60 CH],'FontSize',FS-2,'BackgroundColor','white');
        uilabel(app.h_efr_param_panel,'Text','End:', ...
            'Tag','efr_win_e_lbl', ...
            'Position',[PAD+116 WIN_Y 36 CH],'FontSize',FS-2);
        app.h_efr_window_end_field = uieditfield(app.h_efr_param_panel,'numeric', ...
            'Value',0.9,'Limits',[0 2], ...
            'Tag','efr_win_end', ...
            'Position',[PAD+156 WIN_Y 60 CH],'FontSize',FS-2,'BackgroundColor','white');

        % dAM section header
        DAM_HDR_Y = WIN_Y - SECT_GAP - LH;
        uilabel(app.h_efr_param_panel,'Text','dAM — fixed parameters:', ...
            'Position',[PAD DAM_HDR_Y inner_rw LH],'FontSize',FS,'FontWeight','bold');
        uilabel(app.h_efr_param_panel,'Text','Carrier: 4 kHz  |  AM sweep: 4–10.5 Hz  |  Demod filter: 10–1500 Hz', ...
            'Position',[PAD DAM_HDR_Y-LH inner_rw LH],'FontSize',FS-2,'FontColor',[0.5 0.5 0.5]);

        % ── OAE Parameters panel (right side, hidden until OAE selected) ────
        app.h_oae_param_panel = uipanel(app.MeasuresPanel, ...
            'Title','OAE Parameters','FontSize',FS,'FontWeight','bold', ...
            'BackgroundColor',app.clr_panel,'BorderColor',app.clr_gold, ...
            'Position',[RIGHT_X ABR_PANEL_Y RIGHT_W ABR_OUTER_H], ...
            'Scrollable','on', ...
            'Visible','off');

        uilabel(app.h_oae_param_panel,'Text','All OAE: FPL (Forward Pressure Level) calibration', ...
            'Position',[PAD INNER_H-40 inner_rw LH],'FontSize',FS-1,'FontWeight','bold');
        uilabel(app.h_oae_param_panel,'Text','DPOAE:', ...
            'Position',[PAD INNER_H-80 inner_rw LH],'FontSize',FS,'FontWeight','bold');
        uilabel(app.h_oae_param_panel,'Text','Analysis window: 0.25 s  |  f2/f1 = 1.2  |  FFT: 512 pts  |  Upward sweep', ...
            'Position',[PAD INNER_H-105 inner_rw LH],'FontSize',FS-2,'FontColor',[0.5 0.5 0.5]);
        uilabel(app.h_oae_param_panel,'Text','SFOAE:', ...
            'Position',[PAD INNER_H-145 inner_rw LH],'FontSize',FS,'FontWeight','bold');
        uilabel(app.h_oae_param_panel,'Text','Downward frequency sweep  |  FPL calibration', ...
            'Position',[PAD INNER_H-170 inner_rw LH],'FontSize',FS-2,'FontColor',[0.5 0.5 0.5]);
        uilabel(app.h_oae_param_panel,'Text','TEOAE:', ...
            'Position',[PAD INNER_H-210 inner_rw LH],'FontSize',FS,'FontWeight','bold');
        uilabel(app.h_oae_param_panel,'Text','Stimulus: click  |  FPL calibration', ...
            'Position',[PAD INNER_H-235 inner_rw LH],'FontSize',FS-2,'FontColor',[0.5 0.5 0.5]);

        % ── MEMR Parameters panel (right side, hidden until MEMR selected) ──
        app.h_memr_param_panel = uipanel(app.MeasuresPanel, ...
            'Title','MEMR Parameters','FontSize',FS,'FontWeight','bold', ...
            'BackgroundColor',app.clr_panel,'BorderColor',app.clr_gold, ...
            'Position',[RIGHT_X ABR_PANEL_Y RIGHT_W ABR_OUTER_H], ...
            'Scrollable','on', ...
            'Visible','off');

        uilabel(app.h_memr_param_panel,'Text','Wideband Middle Ear Muscle Reflex', ...
            'Position',[PAD INNER_H-40 inner_rw LH],'FontSize',FS,'FontWeight','bold');
        uilabel(app.h_memr_param_panel,'Text','Frequency range: 0.2–8 kHz', ...
            'Position',[PAD INNER_H-80 inner_rw LH],'FontSize',FS-1,'FontColor',[0.5 0.5 0.5]);
        uilabel(app.h_memr_param_panel,'Text','Metric: Δ absorbed sound power (dB) vs. elicitor level', ...
            'Position',[PAD INNER_H-110 inner_rw LH],'FontSize',FS-1,'FontColor',[0.5 0.5 0.5]);
        uilabel(app.h_memr_param_panel,'Text','Elicitor: broadband noise, multiple levels', ...
            'Position',[PAD INNER_H-140 inner_rw LH],'FontSize',FS-1,'FontColor',[0.5 0.5 0.5]);
        uilabel(app.h_memr_param_panel,'Text','Output: growth functions and reflex thresholds', ...
            'Position',[PAD INNER_H-170 inner_rw LH],'FontSize',FS-1,'FontColor',[0.5 0.5 0.5]);
    end

    function buildFiguresTab(app, ~, FIG_W, TAB_H)
        PAD    = 6;
        FS     = 15;
        ROW_H  = 50;                           % single control row
        CTRL_H = ROW_H + 2*PAD;
        PLOT_H = TAB_H - 30 - CTRL_H;
        N_MEAS = numel(app.measure_tab_labels());
        y1 = PAD;

        ctrl = uipanel(app.FiguresTab, 'BorderType','none', ...
            'BackgroundColor',app.clr_panel, 'Position',[0 PLOT_H FIG_W CTRL_H]);

        x = PAD;

        % ── Individual + Subject dropdown (visually grouped) ─────────────────
        app.FigIndBtn = uibutton(ctrl, 'state', 'Text','Individual', 'Value',true, ...
            'FontSize',FS, 'FontWeight','bold', ...
            'BackgroundColor',app.clr_gold, 'FontColor',app.clr_black, ...
            'Position',[x y1 120 ROW_H], ...
            'ValueChangedFcn',@(~,~) figuresIndClicked(app));
        x = x + 120 + 2;
        app.FigSubjDropdown = uidropdown(ctrl, ...
            'Items',{'(no data)'},'Value','(no data)', ...
            'FontSize',FS,'Position',[x y1+5 200 ROW_H-10], ...
            'ValueChangedFcn',@(~,~) figuresSubjChanged(app));
        x = x + 200 + 14;

        % ── Average button ───────────────────────────────────────────────────
        app.FigAvgBtn = uibutton(ctrl, 'state', 'Text','Average', 'Value',false, ...
            'FontSize',FS, ...
            'BackgroundColor',app.clr_btn, 'FontColor',app.clr_black, ...
            'Position',[x y1 104 ROW_H], ...
            'ValueChangedFcn',@(~,~) figuresAvgClicked(app));
        x = x + 104 + PAD;

        uipanel(ctrl,'BorderType','none','BackgroundColor',app.clr_gold,'Position',[x y1+4 2 ROW_H-8]);
        x = x + 10;

        % ── Major measure buttons ─────────────────────────────────────────────
        major_names = {'ABR','EFR','OAE','MEMR'};
        MBTW = 92;
        app.fig_major_btns = gobjects(1,4);
        for mi = 1:4
            app.fig_major_btns(mi) = uibutton(ctrl,'push', ...
                'Text',major_names{mi}, 'FontSize',FS+2, 'FontWeight','bold', ...
                'BackgroundColor',ternary(mi==1,app.clr_gold,app.clr_btn), ...
                'FontColor',app.clr_black, 'Position',[x y1 MBTW ROW_H], ...
                'ButtonPushedFcn',@(~,~) figuresMajorChanged(app,mi));
            x = x + MBTW + PAD;
        end
        app.fig_cur_major = 1;

        % ── Separator + dropdowns ─────────────────────────────────────────────
        uipanel(ctrl,'BorderType','none','BackgroundColor',app.clr_gold,'Position',[x y1+4 2 ROW_H-8]);
        x = x + 10;

        uilabel(ctrl,'Text','Type:','FontSize',FS,'Position',[x y1+16 48 20]);
        x = x + 50;
        app.FigSubtypeDD = uidropdown(ctrl, ...
            'Items',{'Thresholds','Peaks'},'Value','Thresholds', ...
            'FontSize',FS,'Position',[x y1+6 158 ROW_H-12], ...
            'ValueChangedFcn',@(~,~) figuresSubtypeChanged(app));
        x = x + 162;

        uilabel(ctrl,'Text','Exp:','FontSize',FS,'Position',[x y1+16 44 20]);
        x = x + 46;
        app.FigExpDropdown = uidropdown(ctrl, ...
            'Items',{'(no data)'},'Value','(no data)', ...
            'FontSize',FS,'Position',[x y1+6 230 ROW_H-12], ...
            'ValueChangedFcn',@(~,~) figuresExpChanged(app));
        x = x + 234;

        uilabel(ctrl,'Tag','fig_freq_lbl','Text','Freq:','FontSize',FS, ...
            'Visible','off','Position',[x y1+16 48 20]);
        x = x + 50;
        app.FigFreqDD = uidropdown(ctrl, ...
            'Items',{'—'},'Value','—', ...
            'FontSize',FS,'Visible','off','Position',[x y1+6 148 ROW_H-12], ...
            'ValueChangedFcn',@(~,~) figuresFreqChanged(app));
        x = x + 152;

        uilabel(ctrl,'Tag','fig_level_lbl','Text','Level:','FontSize',FS, ...
            'Visible','off','Position',[x y1+16 52 20]);
        x = x + 54;
        app.FigLevelDD = uidropdown(ctrl, ...
            'Items',{'All Levels'},'Value','All Levels', ...
            'FontSize',FS,'Visible','off','Position',[x y1+6 148 ROW_H-12], ...
            'ValueChangedFcn',@(~,~) figuresLevelChanged(app));

        % ── Figure panels (stacked 2×8, one visible at a time) ──────────────
        app.fig_panels    = cell(2, N_MEAS);
        app.fig_subj_data = cell(1, N_MEAS);
        for mi = 1:N_MEAS
            app.fig_subj_data{mi} = struct('names',{{}},'panels',{{}},'exps',{{}});
        end
        for mode = 1:2
            for mi = 1:N_MEAS
                p = uipanel(app.FiguresTab,'BorderType','none','BackgroundColor',app.clr_bg, ...
                    'Position',[0 0 FIG_W PLOT_H],'Visible','off');
                if mode == 2
                    uilabel(p,'Tag','placeholder', ...
                        'Text','Run analysis to see average figures here.', ...
                        'Position',[0 round(PLOT_H/2-30) FIG_W 60], ...
                        'FontSize',18,'FontColor',[0.55 0.55 0.55], ...
                        'HorizontalAlignment','center','WordWrap','on');
                end
                app.fig_panels{mode,mi} = p;
            end
        end
        app.fig_panels{1,1}.Visible = 'on';
        app.fig_panel_mode = 1;
        app.fig_panel_meas = 1;
    end

    function buildStatusTab(app, PAD, FIG_W, TAB_H)
        INNER_H = TAB_H - 30;   % subtract outer tab bar
        BTN_H   = 40;
        TG_Y    = 0;
        TG_H    = INNER_H - BTN_H - 2*PAD;

        app.RefreshStatusBtn = uibutton(app.StatusTab,'push','Text','⟳  Refresh', ...
            'Position',[PAD TG_H+PAD 110 BTN_H],'FontSize',16, ...
            'BackgroundColor',app.clr_btn, ...
            'ButtonPushedFcn', @(~,~) RefreshStatusButtonPushed(app));

        app.StatusInnerTG = uitabgroup(app.StatusTab, ...
            'Position',[0 TG_Y FIG_W TG_H]);
    end

    function buildUserInputTab(app, PAD, FIG_W, TAB_H)
        FS   = 15;
        CH   = 30;
        INNER_H = TAB_H - 30;   % subtract tab bar

        % ── Left panel: Template Creation ──────────────────────────────────
        LEFT_W  = max(380, round(FIG_W * 0.35));
        LEFT_H  = INNER_H - 2*PAD;
        LEFT_X  = PAD;
        LEFT_Y  = PAD;

        left_panel = uipanel(app.UserInputTab, ...
            'Title','ABR Template Creation','FontSize',FS,'FontWeight','bold', ...
            'BackgroundColor',app.clr_panel,'BorderColor',app.clr_gold, ...
            'Position',[LEFT_X LEFT_Y LEFT_W LEFT_H]);

        % Instructions label
        instr = uilabel(left_panel, ...
            'Text',['Select subject, condition, frequency and level, then click ' ...
                    '"Create Template". You will be prompted to click on the ABR ' ...
                    'waveform to identify peaks (P1–N5). A dialog will confirm ' ...
                    'before saving.'], ...
            'WordWrap','on', ...
            'Position',[10 LEFT_H-120 LEFT_W-24 90], ...
            'FontSize',14,'FontColor',[0.3 0.3 0.3]);  %#ok<NASGU>

        CTRL_W = LEFT_W - 24;
        y_cur  = LEFT_H - 140;
        row_gap = CH + 12;

        % Subject dropdown
        uilabel(left_panel,'Text','Subject','FontSize',FS, ...
            'Position',[10 y_cur CTRL_W 20]);
        y_cur = y_cur - 26;
        app.h_tpl_subj_dd = uidropdown(left_panel, ...
            'Items',{'(load chinroster first)'},'Value','(load chinroster first)', ...
            'Position',[10 y_cur CTRL_W CH], 'FontSize',FS);
        y_cur = y_cur - row_gap;

        % Condition dropdown
        uilabel(left_panel,'Text','Condition','FontSize',FS, ...
            'Position',[10 y_cur CTRL_W 20]);
        y_cur = y_cur - 26;
        app.h_tpl_cond_dd = uidropdown(left_panel, ...
            'Items',{'(load chinroster first)'},'Value','(load chinroster first)', ...
            'Position',[10 y_cur CTRL_W CH], 'FontSize',FS);
        y_cur = y_cur - row_gap;

        % Frequency dropdown
        uilabel(left_panel,'Text','Frequency','FontSize',FS, ...
            'Position',[10 y_cur CTRL_W 20]);
        y_cur = y_cur - 26;
        app.h_tpl_freq_dd = uidropdown(left_panel, ...
            'Items',{'Click (0 Hz)','500 Hz','1000 Hz','2000 Hz','4000 Hz','8000 Hz'}, ...
            'Value','Click (0 Hz)', ...
            'Position',[10 y_cur CTRL_W CH], 'FontSize',FS);
        y_cur = y_cur - row_gap;

        % Level field
        uilabel(left_panel,'Text','Level (dB SPL)','FontSize',FS, ...
            'Position',[10 y_cur CTRL_W 20]);
        y_cur = y_cur - 26;
        app.h_tpl_level_dd = uieditfield(left_panel,'numeric', ...
            'Value',80,'Limits',[0 120],'RoundFractionalValues','on', ...
            'Position',[10 y_cur CTRL_W CH], 'FontSize',FS);
        y_cur = y_cur - row_gap - 8;

        % Create Template button
        uibutton(left_panel,'push','Text','Create Template', ...
            'Position',[10 y_cur CTRL_W CH+4], ...
            'FontSize',FS,'FontWeight','bold', ...
            'BackgroundColor',app.clr_gold,'FontColor',app.clr_black, ...
            'ButtonPushedFcn', @(~,~) CreateTemplateButtonPushed(app));
        y_cur = y_cur - row_gap - 4;

        % Scan button
        uibutton(left_panel,'push','Text','⟳  Scan Existing Templates', ...
            'Position',[10 y_cur CTRL_W CH], ...
            'FontSize',FS,'BackgroundColor',app.clr_btn, ...
            'ButtonPushedFcn', @(~,~) ScanTemplatesButtonPushed(app));

        % ── Right panel: Template Status ────────────────────────────────────
        RIGHT_X = LEFT_X + LEFT_W + PAD;
        RIGHT_W = max(300, FIG_W - RIGHT_X - PAD);
        RIGHT_H = LEFT_H;

        right_panel = uipanel(app.UserInputTab, ...
            'Title','Existing Templates','FontSize',FS,'FontWeight','bold', ...
            'BackgroundColor',app.clr_panel,'BorderColor',app.clr_gold, ...
            'Position',[RIGHT_X LEFT_Y RIGHT_W RIGHT_H]);

        app.h_tpl_status_label = uilabel(right_panel, ...
            'Text','Click "Scan Existing Templates" to list available templates.', ...
            'WordWrap','on', ...
            'Position',[10 RIGHT_H-80 RIGHT_W-24 60], ...
            'FontSize',14,'FontColor',[0.4 0.4 0.4]);

        app.h_tpl_list_panel = uipanel(right_panel, ...
            'BorderType','none','BackgroundColor',app.clr_bg, ...
            'Position',[6 10 RIGHT_W-14 RIGHT_H-90], ...
            'Scrollable','on');
    end

    % ── Figures tab callbacks ──────────────────────────────────────────────

    function figuresIndClicked(app)
        app.FigIndBtn.Value = true;
        app.FigAvgBtn.Value = false;
        app.FigIndBtn.BackgroundColor = app.clr_gold;
        app.FigAvgBtn.BackgroundColor = app.clr_btn;
        app.FigSubjDropdown.Visible = 'on';
        switchFigurePanel(app, 1, app.fig_panel_meas);
        % Refresh freq dropdown to only this subject's available frequencies
        meas_idx = current_meas_idx(app);
        subj = app.FigSubjDropdown.Value;
        if ~strcmp(subj,'(no data)')
            update_filter_dds(app, meas_idx, subj);
            apply_filter(app);
        end
    end

    function figuresAvgClicked(app)
        app.FigAvgBtn.Value = true;
        app.FigIndBtn.Value = false;
        app.FigAvgBtn.BackgroundColor = app.clr_gold;
        app.FigIndBtn.BackgroundColor = app.clr_btn;
        app.FigSubjDropdown.Visible = 'off';
        switchFigurePanel(app, 2, app.fig_panel_meas);
        meas_idx_avg = current_meas_idx(app);
        % Hide Freq/Cond dropdown for non-Peaks measures (Average shows all
        % conditions together — no per-condition filtering needed)
        update_filter_visibility(app, meas_idx_avg);
        % Restore all avg-available frequencies for the avg dropdown (Peaks only)
        sync_avg_freq_labels(app, meas_idx_avg);
        apply_avg_filter(app);
    end

    function figuresMajorChanged(app, major_idx)
        app.fig_cur_major = major_idx;
        major_subtypes = {{'Thresholds','Peaks'},{'dAM','RAM'},{'DPOAE','SFOAE','TEOAE'},{}};
        for bi = 1:4
            if isvalid(app.fig_major_btns(bi))
                app.fig_major_btns(bi).BackgroundColor = ternary(bi==major_idx, app.clr_gold, app.clr_btn);
            end
        end
        subs = major_subtypes{major_idx};
        if isempty(subs)
            app.FigSubtypeDD.Visible = 'off';
        else
            app.FigSubtypeDD.Items   = subs;
            app.FigSubtypeDD.Value   = subs{1};
            app.FigSubtypeDD.Visible = 'on';
        end
        meas_idx = current_meas_idx(app);
        update_filter_visibility(app, meas_idx);
        switchFigurePanel(app, app.fig_panel_mode, meas_idx);
        rebuild_exp_dropdown(app, meas_idx);
        refresh_subj_dropdown(app, meas_idx);
        reset_filter_dds(app, meas_idx);
    end

    function figuresSubtypeChanged(app)
        meas_idx = current_meas_idx(app);
        update_filter_visibility(app, meas_idx);
        switchFigurePanel(app, app.fig_panel_mode, meas_idx);
        rebuild_exp_dropdown(app, meas_idx);
        refresh_subj_dropdown(app, meas_idx);
        reset_filter_dds(app, meas_idx);
    end

    function figuresExpChanged(app)
        meas_idx = current_meas_idx(app);
        refresh_subj_dropdown(app, meas_idx);
        figuresSubjChanged(app);
    end

    function figuresSubjChanged(app)
        meas_idx = current_meas_idx(app);
        data     = app.fig_subj_data{meas_idx};
        if isempty(data.names), return; end
        subj = app.FigSubjDropdown.Value;
        if strcmp(subj,'(no data)'), return; end
        si = find(strcmp(data.names, subj), 1);
        if isempty(si), return; end
        for k = 1:numel(data.panels)
            if isvalid(data.panels{k}), data.panels{k}.Visible = 'off'; end
        end
        if isvalid(data.panels{si}), data.panels{si}.Visible = 'on'; end
        update_filter_dds(app, meas_idx, subj);
        apply_filter(app);
    end

    function figuresFreqChanged(app)
        apply_filter(app);
        if app.fig_panel_mode == 2   % only update avg panel when avg view is active
            apply_avg_filter(app);
        end
    end

    function figuresLevelChanged(app)
        apply_filter(app);
    end

    function switchFigurePanel(app, mode_idx, meas_idx)
        if ~isempty(app.fig_panels)
            app.fig_panels{app.fig_panel_mode, app.fig_panel_meas}.Visible = 'off';
        end
        app.fig_panel_mode = mode_idx;
        app.fig_panel_meas = meas_idx;
        app.fig_panels{mode_idx, meas_idx}.Visible = 'on';
    end

    function meas_idx = current_meas_idx(app)
        % Maps (fig_cur_major, FigSubtypeDD) → 1..8 panel index
        offsets = [0, 2, 4, 7];
        major_subtypes = {{'Thresholds','Peaks'},{'dAM','RAM'},{'DPOAE','SFOAE','TEOAE'},{}};
        mi   = app.fig_cur_major;
        subs = major_subtypes{mi};
        if isempty(subs)
            ki = 1;
        else
            ki = find(strcmp(subs, app.FigSubtypeDD.Value), 1);
            if isempty(ki), ki = 1; end
        end
        meas_idx = offsets(mi) + ki;
    end

    function update_major_from_meas(app, meas_idx)
        % Sync major buttons, subtype DD, and filter visibility from meas_idx
        offsets = [0, 2, 4, 7];
        major_subtypes = {{'Thresholds','Peaks'},{'dAM','RAM'},{'DPOAE','SFOAE','TEOAE'},{}};
        for mi = 4:-1:1
            if meas_idx > offsets(mi)
                app.fig_cur_major = mi;
                ki   = meas_idx - offsets(mi);
                subs = major_subtypes{mi};
                for bi = 1:4
                    if isvalid(app.fig_major_btns(bi))
                        app.fig_major_btns(bi).BackgroundColor = ternary(bi==mi, app.clr_gold, app.clr_btn);
                    end
                end
                if isempty(subs)
                    app.FigSubtypeDD.Visible = 'off';
                else
                    app.FigSubtypeDD.Items   = subs;
                    app.FigSubtypeDD.Value   = subs{ki};
                    app.FigSubtypeDD.Visible = 'on';
                end
                update_filter_visibility(app, meas_idx);
                break;
            end
        end
    end

    function update_filter_visibility(app, meas_idx)
        % Frequency selector shown for ABR Peaks (meas_idx==2); levels are
        % stacked within each per-frequency figure so no level filter needed.
        show_freq  = meas_idx == 2;
        show_level = false;
        fv = ternary(show_freq,  'on', 'off');
        lv = ternary(show_level, 'on', 'off');
        app.FigFreqDD.Visible  = fv;
        app.FigLevelDD.Visible = lv;
        lbl_f = findall(app.UIFigure,'Tag','fig_freq_lbl');
        lbl_l = findall(app.UIFigure,'Tag','fig_level_lbl');
        if ~isempty(lbl_f), lbl_f.Visible = fv; end
        if ~isempty(lbl_l), lbl_l.Visible = lv; end
    end

    function cond_tab_changed_ind(app, meas_idx, subject)
        % Called when the user clicks a different condition tab in individual view.
        % Refresh freq dropdown to the newly selected tab's available frequencies.
        update_filter_dds(app, meas_idx, subject);
        apply_filter(app);
    end

    function refresh_subj_dropdown(app, meas_idx)
        % Rebuild subject dropdown filtered by selected experiment
        data = app.fig_subj_data{meas_idx};
        if isempty(data.names)
            app.FigSubjDropdown.Items = {'(no data)'};
            app.FigSubjDropdown.Value = '(no data)';
            return;
        end
        exp_sel = app.FigExpDropdown.Value;
        if strcmp(exp_sel,'(no data)')
            filtered = data.names;
        else
            mask     = strcmp(data.exps, exp_sel);
            filtered = data.names(mask);
        end
        if isempty(filtered)
            app.FigSubjDropdown.Items = {'(no data)'};
            app.FigSubjDropdown.Value = '(no data)';
        else
            app.FigSubjDropdown.Items = filtered;
            if ~any(strcmp(filtered, app.FigSubjDropdown.Value))
                app.FigSubjDropdown.Value = filtered{1};
            end
        end
    end

    function rebuild_exp_dropdown(app, meas_idx)
        % Update FigExpDropdown items from unique experiments in this measure
        data = app.fig_subj_data{meas_idx};
        if isempty(data.exps)
            app.FigExpDropdown.Items = {'(no data)'};
            app.FigExpDropdown.Value = '(no data)';
            return;
        end
        exps = unique(data.exps);
        app.FigExpDropdown.Items = exps(:)';
        if ~any(strcmp(exps, app.FigExpDropdown.Value))
            app.FigExpDropdown.Value = exps{1};
        end
    end

    function update_filter_dds(app, meas_idx, subject)
        % Populate FigFreqDD from figure Names embedded for this subject.
        % Works for both stacked layout (direct children) and scroll grid.
        si = find(strcmp(app.fig_subj_data{meas_idx}.names, subject), 1);
        if isempty(si), return; end
        sp = app.fig_subj_data{meas_idx}.panels{si};

        % Collect freq labels: stacked panels store label in Tag, grid panels in Title
        titles = {};
        for chk = sp.Children(:)'
            if isa(chk,'matlab.ui.container.Panel')
                lbl = chk.Tag;
                if isempty(lbl), lbl = chk.Title; end
                if ~isempty(lbl), titles{end+1} = lbl; end %#ok<AGROW>
            end
        end
        if isempty(titles)
            for chk = sp.Children(:)'
                if isa(chk,'matlab.ui.container.Panel')
                    for chk2 = chk.Children(:)'
                        if isa(chk2,'matlab.ui.container.Panel')
                            lbl = chk2.Tag;
                            if isempty(lbl), lbl = chk2.Title; end
                            if ~isempty(lbl), titles{end+1} = lbl; end %#ok<AGROW>
                        end
                    end
                end
            end
        end
        % Handle condition tabgroup (ABR Peaks individual, multiple conditions):
        % read freq labels from the currently selected condition tab
        if isempty(titles)
            for chk = sp.Children(:)'
                if isa(chk,'matlab.ui.container.TabGroup') && ~isempty(chk.Children)
                    active_tab = chk.SelectedTab;
                    for chk2 = active_tab.Children(:)'
                        if isa(chk2,'matlab.ui.container.Panel')
                            for chk3 = chk2.Children(:)'
                                if isa(chk3,'matlab.ui.container.Panel')
                                    lbl = chk3.Tag;
                                    if isempty(lbl), lbl = chk3.Title; end
                                    if ~isempty(lbl), titles{end+1} = lbl; end %#ok<AGROW>
                                end
                            end
                        end
                    end
                end
            end
        end
        titles = unique(titles, 'stable');   % deduplicate while preserving order
        if isempty(titles), return; end

        app.FigFreqDD.Items = titles(:)';
        if ~any(strcmp(titles, app.FigFreqDD.Value))
            app.FigFreqDD.Value = titles{1};
        end
        if strcmp(app.FigLevelDD.Visible,'on')
            app.FigLevelDD.Items = titles(:)';
            app.FigLevelDD.Value = titles{1};
        end

        % Show FigFreqDD and set label contextually:
        %   freq labels contain 'Hz' or equal 'Click' → 'Freq:'
        %   condition labels (pre, D7, …) → 'Cond:'
        lbl_f = findall(app.UIFigure,'Tag','fig_freq_lbl');
        is_freq_labels = any(cellfun( ...
            @(t) ~isempty(regexp(t,'\d+\s*(k?Hz|click)', 'once', 'ignorecase')), titles));
        if ~isempty(lbl_f)
            lbl_f.Text    = ternary(is_freq_labels, 'Freq:', 'Cond:');
            lbl_f.Visible = 'on';
        end
        app.FigFreqDD.Visible = 'on';
    end

    function reset_filter_dds(app, meas_idx)
        % Reset filter DDs then re-populate from current subject
        app.FigFreqDD.Items  = {'—'};   app.FigFreqDD.Value  = '—';
        app.FigLevelDD.Items = {'—'};   app.FigLevelDD.Value = '—';
        subj = app.FigSubjDropdown.Value;
        if ~strcmp(subj,'(no data)'), update_filter_dds(app, meas_idx, subj); end
        % Also sync freq labels from the avg panel tabgroup (ABR Peaks only)
        sync_avg_freq_labels(app, meas_idx);
    end

    function sync_avg_freq_labels(app, meas_idx)
        % Scan the avg panel tabgroup and merge any freq labels missing from FigFreqDD.
        % Called after measure switches to restore freq options without re-running analysis.
        if meas_idx ~= 2 || isempty(app.fig_panels), return; end
        avg_panel = app.fig_panels{2, meas_idx};
        if ~isvalid(avg_panel), return; end
        tg = [];
        for ch = avg_panel.Children(:)'
            if isa(ch,'matlab.ui.container.TabGroup'), tg = ch; break; end
        end
        if isempty(tg), return; end
        tab_freqs = {};
        for ti = 1:numel(tg.Children)
            tab = tg.Children(ti);
            for ch = tab.Children(:)'
                if isa(ch,'matlab.ui.container.Panel')
                    for ch2 = ch.Children(:)'
                        if isa(ch2,'matlab.ui.container.Panel') && ~isempty(ch2.Tag)
                            if ~any(strcmp(tab_freqs, ch2.Tag))
                                tab_freqs{end+1} = ch2.Tag; %#ok<AGROW>
                            end
                        end
                    end
                end
            end
        end
        if ~isempty(tab_freqs)
            existing      = app.FigFreqDD.Items;
            existing_real = existing(~strcmp(existing,'—'));   % strip placeholder
            new_items     = tab_freqs(~ismember(tab_freqs, existing_real));
            merged        = [existing_real, new_items];
            if ~isempty(merged) && ~isequal(merged, existing)
                app.FigFreqDD.Items = merged;
                if ~any(strcmp(merged, app.FigFreqDD.Value))
                    app.FigFreqDD.Value = merged{1};
                end
            end
        end
    end

    function apply_filter(app)
        % Show/hide per-figure sub-panels based on current Freq selection.
        % For stacked-layout panels (ABR Peaks): exactly one panel is visible
        % at a time. '—' (placeholder) shows the first panel.
        meas_idx = current_meas_idx(app);
        data = app.fig_subj_data{meas_idx};
        if isempty(data.names), return; end
        subj = app.FigSubjDropdown.Value;
        if strcmp(subj,'(no data)'), return; end
        si = find(strcmp(data.names, subj), 1);
        if isempty(si), return; end
        sp = data.panels{si};

        freq_filter = '';
        if strcmp(app.FigFreqDD.Visible,'on') && ~strcmp(app.FigFreqDD.Value,'—')
            freq_filter = app.FigFreqDD.Value;
        end

        % Collect direct-child panels with a freq Tag (stacked) or Title (grid/scroll)
        titled_ps = {};
        for chk = sp.Children(:)'
            if isa(chk,'matlab.ui.container.Panel') && (~isempty(chk.Tag) || ~isempty(chk.Title))
                titled_ps{end+1} = chk; %#ok<AGROW>
            end
        end
        % Also look one level deeper (scroll container case)
        if isempty(titled_ps)
            for chk = sp.Children(:)'
                if isa(chk,'matlab.ui.container.Panel')
                    for chk2 = chk.Children(:)'
                        if isa(chk2,'matlab.ui.container.Panel') && (~isempty(chk2.Tag) || ~isempty(chk2.Title))
                            titled_ps{end+1} = chk2; %#ok<AGROW>
                        end
                    end
                end
            end
        end
        % Handle condition tabgroup (ABR Peaks individual, multiple conditions):
        % freq panels live inside the currently selected condition tab
        if isempty(titled_ps)
            for chk = sp.Children(:)'
                if isa(chk,'matlab.ui.container.TabGroup') && ~isempty(chk.Children)
                    active_tab = chk.SelectedTab;
                    for chk2 = active_tab.Children(:)'
                        if isa(chk2,'matlab.ui.container.Panel')
                            for chk3 = chk2.Children(:)'
                                if isa(chk3,'matlab.ui.container.Panel') && (~isempty(chk3.Tag) || ~isempty(chk3.Title))
                                    titled_ps{end+1} = chk3; %#ok<AGROW>
                                end
                            end
                        end
                    end
                end
            end
        end

        if isempty(titled_ps), return; end

        is_stacked = numel(titled_ps) > 1 && ...
            all(cellfun(@(p) p.Position(1), titled_ps) == titled_ps{1}.Position(1)) && ...
            all(cellfun(@(p) p.Position(2), titled_ps) == titled_ps{1}.Position(2));

        if is_stacked
            % Stacked mode: show only the matching panel (or first if no match).
            % Freq label is stored in Tag (Title is blank to hide the text).
            % MATLAB Children are in reverse creation order, so {end} = first created.
            matched = false;
            first_p = titled_ps{end};
            for i = 1:numel(titled_ps)
                p = titled_ps{i};
                if isempty(freq_filter)
                    p.Visible = ternary(p == first_p, 'on', 'off');
                else
                    hits = strcmpi(p.Tag, freq_filter);
                    p.Visible = ternary(hits, 'on', 'off');
                    if hits, matched = true; end
                end
            end
            % If nothing matched, fall back to showing the first
            if ~isempty(freq_filter) && ~matched
                first_p.Visible = 'on';
            end
            % Sync dropdown to what is actually visible
            if strcmp(app.FigFreqDD.Visible,'on')
                actual = ternary(matched, freq_filter, first_p.Tag);
                if ~isempty(actual) && any(strcmp(app.FigFreqDD.Items, actual)) && ...
                        ~strcmp(app.FigFreqDD.Value, actual)
                    app.FigFreqDD.Value = actual;
                end
            end
        else
            % Grid mode: show/hide by title match
            for i = 1:numel(titled_ps)
                p = titled_ps{i};
                if isempty(freq_filter)
                    p.Visible = 'on';
                else
                    p.Visible = ternary(strcmpi(p.Title, freq_filter), 'on', 'off');
                end
            end
        end
    end

    function buildMeasureButtons(app)
        COMB_H  = app.layout_meas_h;
        FIG_W   = app.UIFigure.Position(3);  PAD = 8;
        panel_w = FIG_W - 2*PAD;

        app.n_meas = length(app.MEASURES);
        app.meas_h   = 0.22;
        app.meas_gap = 0.02;

        % Delete stale buttons
        if ~isempty(app.h_meas_btns)
            valid = app.h_meas_btns(isvalid(app.h_meas_btns));
            if ~isempty(valid), delete(valid); end
        end
        for m = 1:numel(app.h_sub_btns)
            valid = app.h_sub_btns{m}(isvalid(app.h_sub_btns{m}));
            if ~isempty(valid), delete(valid); end
        end
        app.h_meas_btns = gobjects(1, app.n_meas);
        app.h_sub_btns  = cell(1, app.n_meas);

        MEAS_BTN_W = max(110, min(150, round(0.12*panel_w)));
        for m = 1:app.n_meas
            y_m = 0.99 - m*(app.meas_h + app.meas_gap) + app.meas_gap;
            app.h_meas_btns(m) = uibutton(app.MeasuresPanel,'push', ...
                'Text',app.MEASURES(m).name, ...
                'Position',[round(0.01*panel_w) round(y_m*COMB_H) MEAS_BTN_W round(app.meas_h*COMB_H)], ...
                'FontSize',20,'FontWeight','bold','BackgroundColor',app.clr_btn, ...
                'UserData',m, ...
                'ButtonPushedFcn', @(src,~) MeasureButtonPushed(app, src));
        end

        % Gold divider
        div_x = round(0.01*panel_w) + MEAS_BTN_W + 4;
        uipanel(app.MeasuresPanel,'BorderType','none','BackgroundColor',app.clr_gold, ...
            'Position',[div_x round(0.02*COMB_H) 3 round(0.94*COMB_H)]);

        % Subtype buttons: start just after divider, end at 0.50
        SUB_START_PX = div_x + 10;
        app.meas_sub_area_start = SUB_START_PX;
        SUB_END   = 0.50;
        for m = 1:app.n_meas
            y_m  = 0.99 - m*(app.meas_h + app.meas_gap) + app.meas_gap;
            subs = app.MEASURES(m).subtypes;
            app.h_sub_btns{m} = gobjects(1, max(1,numel(subs)));
            if ~isempty(subs)
                sub_area_px = round(SUB_END * panel_w) - SUB_START_PX;
                sub_btn_w   = max(120, floor(sub_area_px / numel(subs)) - 4);
                for k = 1:numel(subs)
                    app.h_sub_btns{m}(k) = uibutton(app.MeasuresPanel,'push', ...
                        'Text',subs{k}, ...
                        'Position',[SUB_START_PX + (k-1)*(sub_btn_w+4) round(y_m*COMB_H) sub_btn_w round(app.meas_h*COMB_H)], ...
                        'FontSize',18,'BackgroundColor',app.clr_btn,'Visible','off', ...
                        'UserData',[m k], ...
                        'ButtonPushedFcn', @(src,~) SubtypeButtonPushed(app, src));
                end
            end
        end
    end

    % ── Startup ────────────────────────────────────────────────────────────

    function startupFcn(app)
        app.code_dir    = fileparts(mfilename('fullpath'));
        app.profile_file = fullfile(app.code_dir,'private','user_profiles.mat');
        app.state.measure_idx = 1;
        app.state.subtype_idx = 1;
        app.state.sheet       = '';
        app.state.conds_all   = {};
        app.state.cond_labels = {};
        app.h_subj_checks = gobjects(0);
        app.subj_ids      = {};
        app.h_cond_checks = gobjects(0);

        initMeasures(app);
        buildMeasureButtons(app);
        refreshMeasureButtons(app);

        [app.profiles, app.last_user] = APAT_app.load_profiles(app.profile_file);

        all_pnames = fieldnames(app.profiles);
        if ~isempty(all_pnames)
            app.ProfileDropdown.Items = all_pnames;
            if ~isempty(app.last_user) && isfield(app.profiles, app.last_user)
                app.ProfileDropdown.Value = app.last_user;
            else
                app.ProfileDropdown.Value = all_pnames{1};
            end
            load_profile_to_gui(app, app.ProfileDropdown.Value);
        end
    end

    function initMeasures(app)
        % Pre-declare as struct array so MATLAB doesn't try to grow a double array
        app.MEASURES = struct('name',{},'label',{},'subtypes',{},'descriptions',{});
        app.MEASURES(1) = struct('name','ABR', 'label','Auditory Brainstem Response', ...
            'subtypes',{{'Thresholds','Peaks'}}, ...
            'descriptions',{{...
              ['Estimates hearing thresholds across click and pure-tone frequencies. '...
               'Uses a bootstrapped cross-correlation method and fits a sigmoid to the '...
               'normalized ABR amplitude-vs-level function to extract threshold.'], ...
              ['Detects Wave I–V peaks and troughs using Dynamic Time Warping (DTW) '...
               'against a reference template. Quantifies peak-to-peak amplitudes and '...
               'absolute latencies across stimulus levels and frequencies.']}});
        app.MEASURES(2) = struct('name','EFR', 'label','Envelope Following Response', ...
            'subtypes',{{'dAM','RAM'}}, ...
            'descriptions',{{...
              ['Measures neural responses to a modulated stimulus using dynamic amplitude '...
               'modulation (dAM) to assess temporal encoding up to 1.5 kHz.'], ...
              ['Measures neural responses using rectangular amplitude modulation (RAM). '...
               'Phase Locking Value (PLV) captures subcortical synchrony up to the 16th '...
               'harmonic of the modulation frequency.']}});
        app.MEASURES(3) = struct('name','OAE', 'label','Otoacoustic Emissions', ...
            'subtypes',{{'DPOAE','SFOAE','TEOAE'}}, ...
            'descriptions',{{...
              ['Estimates DPOAE amplitude using a two-tone UPWARD sweep paradigm. '...
               'Implements FPL calibration for accurate in-ear stimulus levels.'], ...
              ['Estimates SFOAE amplitude using a two-tone DOWNWARD sweep paradigm. '...
               'Implements FPL calibration for accurate in-ear stimulus levels.'], ...
              ['Estimates TEOAE amplitude using a click stimulus. '...
               'Implements FPL calibration for accurate in-ear stimulus levels.']}});
        app.MEASURES(4) = struct('name','MEMR', 'label','Middle Ear Muscle Reflex', ...
            'subtypes',{{}}, ...
            'descriptions',{{...
              ['Measures wideband acoustic reflex by tracking changes in absorbed sound '...
               'power (dB) across frequencies in response to a broadband elicitor at '...
               'multiple levels. Characterizes growth functions and reflex thresholds.']}});
    end

    % ── Callbacks ──────────────────────────────────────────────────────────

    function RunButtonPushed(app)
        ROOTdir = strtrim(app.RootDirField.Value);
        if isempty(ROOTdir)
            uialert(app.UIFigure,'Root directory is required.','Missing Field'); return
        end
        if isempty(app.state.sheet) || isempty(app.state.conds_all)
            uialert(app.UIFigure,'Load the chinroster and select an experiment first.','Not Ready'); return
        end
        Chins2Run = get_checked_subjects(app);
        if isempty(Chins2Run)
            uialert(app.UIFigure,'Select at least one subject.','No Subjects'); return
        end
        cond_sel = false(1, numel(app.h_cond_checks));
        for ci = 1:numel(app.h_cond_checks)
            if isvalid(app.h_cond_checks(ci))
                cond_sel(ci) = app.h_cond_checks(ci).Value;
            end
        end
        if ~any(cond_sel)
            uialert(app.UIFigure,'Select at least one condition.','No Conditions'); return
        end
        Conds2Run = app.state.conds_all(cond_sel);

        EXPname  = app.MEASURES(app.state.measure_idx).name;
        subs     = app.MEASURES(app.state.measure_idx).subtypes;
        EXPname2 = [];
        if ~isempty(subs), EXPname2 = subs{app.state.subtype_idx}; end

        chinroster_filename = app.RosterDropdown.Value;
        reanalyze           = app.ReanalyzeCheck.Value;
        plot_relative_flag  = app.PlotRelativeCheck.Value;
        sheet               = app.state.sheet;

        show_figs.analysis = app.ShowAnalysisCheck.Value;
        show_figs.ind      = app.ShowIndCheck.Value;
        show_figs.avg      = app.ShowAvgCheck.Value;

        % Save user profile + last settings before closing
        pname = get_current_profile_name(app);
        if ~isempty(pname)
            save_current_to_profile(app, pname);
            app.last_user = pname;
            save_profiles_to_file(app);
        end
        save_last_settings(app, Chins2Run, Conds2Run);

        % Derive the measure label (must match pre-created tab titles)
        switch EXPname
            case {'ABR','EFR'},  measure_lbl = [EXPname ' ' EXPname2];
            case 'OAE',          measure_lbl = EXPname2;
            case 'MEMR',         measure_lbl = 'MEMR';
            otherwise,           measure_lbl = EXPname;
        end

        % Clear only this measure's panels so other measures persist
        clearMeasureFigures(app, measure_lbl);
        meas_idx = find(strcmp(app.measure_tab_labels(), measure_lbl), 1);
        if ~isempty(meas_idx)
            switchFigurePanel(app, 1, meas_idx);
            app.FigIndBtn.Value = true;
            app.FigAvgBtn.Value = false;
            app.FigIndBtn.BackgroundColor = app.clr_gold;
            app.FigAvgBtn.BackgroundColor = app.clr_btn;
            app.FigSubjDropdown.Visible = 'on';
            update_major_from_meas(app, meas_idx);
        end
        app.TabGroup.SelectedTab = app.FiguresTab;
        app.RunButton.Enable  = 'off';
        app.abort_requested   = false;
        app.StopButton.Text   = '■  Stop';
        app.StopButton.Enable = 'on';
        app.StopButton.Visible = 'on';
        app.h_progress_label.Text    = 'Starting analysis…';
        app.h_progress_label.Visible = 'on';
        start_spinner_anim(app);
        drawnow;

        % Build embed callbacks — analysis_run will call these after each step
        embed_fns.analysis  = @(figs, meas, subj, cond) embed_in_analysis(app, figs, meas, subj, sheet);
        embed_fns.average   = @(figs, label) embed_in_average(app, figs, label);
        embed_fns.progress  = @(n, total, msg) update_progress(app, n, total, msg);

        % Collect ABR freq selection (Thresholds + Peaks); levels/waves/ratios only for Peaks
        abr_freq_sel       = [];
        abr_levels_sel     = [];
        abr_tpl_per_level  = false;
        abr_wave_sel       = [];
        abr_wave_ratios    = {};
        if strcmp(EXPname,'ABR')
            all_freqs  = [0 0.5 1 2 4 8] * 1e3;
            all_levels = [80 70 60 50 40];
            if ~isempty(app.h_abr_freq_checks) && any(isvalid(app.h_abr_freq_checks))
                sel = arrayfun(@(c) isvalid(c) && c.Value, app.h_abr_freq_checks);
                abr_freq_sel = all_freqs(sel);
                if isempty(abr_freq_sel), abr_freq_sel = all_freqs; end
            end
            if strcmp(EXPname2,'Peaks')
                if ~isempty(app.h_abr_level_checks) && any(isvalid(app.h_abr_level_checks))
                    sel = arrayfun(@(c) isvalid(c) && c.Value, app.h_abr_level_checks);
                    abr_levels_sel = all_levels(sel);
                    if isempty(abr_levels_sel), abr_levels_sel = all_levels; end
                end
                if ~isempty(app.h_abr_tpl_req_check) && isvalid(app.h_abr_tpl_req_check)
                    abr_tpl_per_level = app.h_abr_tpl_req_check.Value;
                end
                % Wave selection
                if ~isempty(app.h_abr_wave_checks) && any(isvalid(app.h_abr_wave_checks))
                    abr_wave_sel = arrayfun(@(c) isvalid(c) && c.Value, app.h_abr_wave_checks);
                    if ~any(abr_wave_sel), abr_wave_sel = true(1,5); end
                end
                % Ratio combinations
                if ~isempty(app.h_abr_ratio_field) && isvalid(app.h_abr_ratio_field)
                    ratio_str = strtrim(app.h_abr_ratio_field.Value);
                    if ~isempty(ratio_str)
                        parts = strsplit(ratio_str, ',');
                        abr_wave_ratios = strtrim(parts);
                        abr_wave_ratios = abr_wave_ratios(~cellfun(@isempty, abr_wave_ratios));
                    end
                end
            end
            % Merge custom frequencies from profile
            if ~isempty(app.h_abr_custom_freq_field) && isvalid(app.h_abr_custom_freq_field)
                cust_str = strtrim(app.h_abr_custom_freq_field.Value);
                if ~isempty(cust_str)
                    parts = strsplit(cust_str, ',');
                    cust_vals = str2double(strtrim(parts));
                    cust_vals = cust_vals(~isnan(cust_vals) & cust_vals > 0);
                    if ~isempty(cust_vals)
                        abr_freq_sel = unique([abr_freq_sel, cust_vals]);
                    end
                end
            end
        end

        % Collect EFR RAM parameters
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

        clc;
        analysis_errored = false;
        try
            analysis_run(ROOTdir, Chins2Run, Conds2Run, chinroster_filename, ...
                sheet, plot_relative_flag, reanalyze, EXPname, EXPname2, show_figs, embed_fns, ...
                abr_freq_sel, abr_levels_sel, abr_tpl_per_level, abr_wave_sel, abr_wave_ratios, ...
                efr_harmonics, efr_window);
        catch ME
            analysis_errored = true;
            if isvalid(app) && ~strcmp(ME.identifier,'APAT:UserAbort')
                uialert(app.UIFigure, ME.message, 'Analysis Error');
            end
        end

        if isvalid(app)
            app.RunButton.Enable   = 'on';
            app.StopButton.Visible = 'off';
            stop_spinner_anim(app, ~analysis_errored && ~app.abort_requested);
        end
    end

    function StopButtonPushed(app)
        app.abort_requested   = true;
        app.StopButton.Text   = 'Stopping…';
        app.StopButton.Enable = 'off';
        drawnow;
    end

    function DataStatusButtonPushed(app)
        % Switch to Status tab and populate the table
        app.TabGroup.SelectedTab = app.StatusTab;
        build_status_table(app);
    end

    function ProfileDropdownChanged(app)
        pname = get_current_profile_name(app);
        if ~isempty(pname), load_profile_to_gui(app, pname); end
    end

    function NewUserButtonPushed(app)
        answer = inputdlg({'Enter your initials (e.g. FA):','Full name (optional):'}, ...
            'New User',1,{'',''});
        if isempty(answer) || isempty(strtrim(answer{1})), return; end
        initials = upper(strtrim(answer{1}));
        if ~isvarname(initials)
            uialert(app.UIFigure,'Initials must be letters only (e.g. FA).','Invalid Initials'); return
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
        load_profile_to_gui(app, initials);
    end

    function SaveUserButtonPushed(app)
        pname = get_current_profile_name(app);
        if isempty(pname), return; end
        save_current_to_profile(app, pname);
        save_profiles_to_file(app);
        uialert(app.UIFigure, sprintf('User "%s" saved.',pname), 'Saved', 'Icon','success');
    end

    function BrowseButtonPushed(app)
        d = uigetdir(app.RootDirField.Value, 'Select Root Directory (DOD folder)');
        if isequal(d,0), return; end
        app.RootDirField.Value = d;
        scan_chinroster_files(app, '');
    end

    function RosterDropdownChanged(app)
        load_chinroster(app);
    end

    function SheetDropdownChanged(app)
        new_sheet = app.SheetDropdown.Value;
        if new_sheet(1) == '(', return; end
        app.state.sheet = new_sheet;
        ROOTdir  = strtrim(app.RootDirField.Value);
        chinfile = app.RosterDropdown.Value;
        if isempty(ROOTdir) || chinfile(1) == '(', return; end
        filepath = fullfile(ROOTdir,'Analysis',chinfile);
        if exist(filepath,'file'), refresh_from_chinroster(app, filepath); end
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
        load_chinroster(app);
    end

    function MeasureButtonPushed(app, src)
        app.state.measure_idx = src.UserData;
        app.state.subtype_idx = 1;
        refreshMeasureButtons(app);
    end

    function SubtypeButtonPushed(app, src)
        ud = src.UserData;
        app.state.measure_idx = ud(1);
        app.state.subtype_idx = ud(2);
        refreshMeasureButtons(app);
    end

    function RefreshStatusButtonPushed(app)
        build_status_table(app);
    end

    function CreateTemplateButtonPushed(app)
        ROOTdir = strtrim(app.RootDirField.Value);
        if isempty(ROOTdir)
            uialert(app.UIFigure,'Set Root Directory in the Setup tab first.','Missing Root Directory');
            return;
        end
        subject = app.h_tpl_subj_dd.Value;
        if isempty(subject) || subject(1) == '('
            uialert(app.UIFigure,'Select a subject.','Missing Subject');
            return;
        end
        cond_label = app.h_tpl_cond_dd.Value;
        if isempty(cond_label) || cond_label(1) == '('
            uialert(app.UIFigure,'Select a condition.','Missing Condition');
            return;
        end
        % Map label → full path (e.g. 'Baseline' → 'pre/Baseline')
        label_idx = find(strcmp(app.state.cond_labels, cond_label), 1);
        if isempty(label_idx) || label_idx > numel(app.state.conds_all)
            uialert(app.UIFigure,'Could not resolve condition path. Reload chinroster.','Condition Error');
            return;
        end
        condition = app.state.conds_all{label_idx};
        % Parse frequency
        freq_str_sel = app.h_tpl_freq_dd.Value;
        if strcmpi(freq_str_sel,'Click (0 Hz)')
            template_freq = 0;
        else
            template_freq = str2double(strtrim(strtok(freq_str_sel,' ')));
        end
        template_level = app.h_tpl_level_dd.Value;
        TEMPLATEdir = fullfile(ROOTdir,'Code Archive','ABR','Peaks','templates');
        % Navigate back to code dir after ginput so MATLAB path stays consistent
        cwd_before = pwd;
        done_cb = @() ScanTemplatesButtonPushed(app);
        try
            create_abr_template(ROOTdir, subject, condition, template_freq, template_level, TEMPLATEdir, done_cb);
        catch ME
            cd(cwd_before);
            uialert(app.UIFigure, ME.message, 'Template Creation Error');
        end
        cd(cwd_before);
    end

    function ScanTemplatesButtonPushed(app)
        ROOTdir = strtrim(app.RootDirField.Value);
        if isempty(ROOTdir)
            app.h_tpl_status_label.Text = 'Set Root Directory in the Setup tab first.';
            return;
        end
        TEMPLATEdir = fullfile(ROOTdir,'Code Archive','ABR','Peaks','templates');
        if ~exist(TEMPLATEdir,'dir')
            app.h_tpl_status_label.Text = 'Templates directory not found.';
            return;
        end
        files = dir(fullfile(TEMPLATEdir,'template_*.mat'));
        % Clear old list
        old = app.h_tpl_list_panel.Children;
        if ~isempty(old), delete(old); end
        if isempty(files)
            app.h_tpl_status_label.Text = 'No templates found.';
            return;
        end
        app.h_tpl_status_label.Text = sprintf('%d template(s) found:', numel(files));
        ITEM_H = 26;
        for fi = 1:numel(files)
            uilabel(app.h_tpl_list_panel, ...
                'Text', ['• ', files(fi).name], ...
                'Position',[6 (numel(files)-fi)*ITEM_H+4 max(300,app.h_tpl_list_panel.Position(3)-16) ITEM_H], ...
                'FontSize',14,'FontColor',app.clr_black);
        end
    end

    function refresh_template_controls(app)
        % Sync subject and condition dropdowns with loaded chinroster data
        if isempty(app.subj_ids)
            app.h_tpl_subj_dd.Items = {'(load chinroster first)'};
            app.h_tpl_subj_dd.Value = '(load chinroster first)';
            app.h_tpl_cond_dd.Items = {'(load chinroster first)'};
            app.h_tpl_cond_dd.Value = '(load chinroster first)';
            return;
        end
        app.h_tpl_subj_dd.Items = app.subj_ids;
        app.h_tpl_subj_dd.Value = app.subj_ids{1};
        if ~isempty(app.state.cond_labels)
            app.h_tpl_cond_dd.Items = app.state.cond_labels;
            app.h_tpl_cond_dd.Value = app.state.cond_labels{1};
        else
            app.h_tpl_cond_dd.Items = {'(no conditions)'};
            app.h_tpl_cond_dd.Value = '(no conditions)';
        end
    end

    % ── Helper functions ───────────────────────────────────────────────────

    function scan_chinroster_files(app, preferred_name)
        rootdir = strtrim(app.RootDirField.Value);
        if isempty(rootdir), return; end
        analysis_dir = fullfile(rootdir,'Analysis');
        if ~exist(analysis_dir,'dir')
            app.RosterDropdown.Items = {'(Analysis folder not found)'};
            app.RosterDropdown.Value = '(Analysis folder not found)'; return
        end
        files = [dir(fullfile(analysis_dir,'*.xlsx')); dir(fullfile(analysis_dir,'*.xls'))];
        files = files(~strncmp({files.name},'._',2));
        if isempty(files)
            app.RosterDropdown.Items = {'(no Excel files found)'};
            app.RosterDropdown.Value = '(no Excel files found)'; return
        end
        names = {files.name};
        app.RosterDropdown.Items = names;
        if ~isempty(preferred_name) && any(strcmp(names,preferred_name))
            app.RosterDropdown.Value = preferred_name;
        else
            app.RosterDropdown.Value = names{1};
        end
        load_chinroster(app);
    end

    function load_chinroster(app)
        rootdir  = strtrim(app.RootDirField.Value);
        if isempty(rootdir), return; end
        chinfile = app.RosterDropdown.Value;
        if isempty(chinfile) || chinfile(1) == '(', return; end
        filepath = fullfile(rootdir,'Analysis',chinfile);
        if ~exist(filepath,'file')
            app.SheetDropdown.Items = {'(file not found)'}; app.SheetDropdown.Value = '(file not found)';
            set_subj_checks(app, {}, []); refresh_conditions(app); return
        end
        try
            sheets = cellstr(sheetnames(filepath));
        catch
            app.SheetDropdown.Items = {'(error reading file)'}; app.SheetDropdown.Value = '(error reading file)'; return
        end
        cur_idx = find(strcmp(sheets, app.state.sheet), 1);
        if isempty(cur_idx), cur_idx = 1; end
        app.SheetDropdown.Items = sheets;
        app.SheetDropdown.Value = sheets{cur_idx};
        app.state.sheet = sheets{cur_idx};
        refresh_from_chinroster(app, filepath);
    end

    function refresh_from_chinroster(app, filepath)
        [subjects, app.state.conds_all, app.state.cond_labels] = ...
            APAT_app.read_chinroster_sheet(filepath, app.state.sheet);
        set_subj_checks(app, subjects, true(numel(subjects),1));
        refresh_conditions(app);
        load_last_settings(app);
        refresh_template_controls(app);
    end

    function refresh_conditions(app)
        valid = app.h_cond_checks(isvalid(app.h_cond_checks));
        if ~isempty(valid), delete(valid); end
        app.h_cond_checks = gobjects(0);
        labels = app.state.cond_labels;
        n = numel(labels);
        if n == 0, return; end
        app.h_cond_checks = gobjects(1, n);
        ROW2_H = app.layout_row2_h;
        TITLE_CLEAR = 38;
        avail_h = ROW2_H - TITLE_CLEAR - 10;
        item_h = max(18, min(28, floor(avail_h / n)));
        pp_cond = app.ConditionsPanel.Position;
        cond_inner_w = max(120, pp_cond(3) - 18);
        for ci = 1:n
            y_pos = ROW2_H - TITLE_CLEAR - ci * item_h;
            app.h_cond_checks(ci) = uicheckbox(app.ConditionsPanel, ...
                'Text',labels{ci},'Value',true, ...
                'Position',[10 y_pos cond_inner_w item_h], ...
                'FontSize',16);
        end
    end

    function set_subj_checks(app, subjs, checked)
        valid = app.h_subj_checks(isvalid(app.h_subj_checks));
        if ~isempty(valid), delete(valid); end
        app.h_subj_checks = gobjects(0);
        app.subj_ids = {};
        if isempty(subjs), return; end
        subjs   = subjs(:);
        checked = checked(:);
        n       = numel(subjs);
        app.subj_ids = subjs;

        pp = app.SubjectsPanel.Position;   % [x y w h] — always pixels in uifigure
        pw = pp(3) - 14;
        ph = pp(4);
        item_w  = 68;
        n_cols  = max(1, floor(pw / item_w));
        n_rows  = ceil(n / n_cols);
        TITLE_CLEAR = 38;   % clearance below panel title at top
        BTN_CLEAR   = 48;   % clearance above buttons at bottom
        grid_top = ph - TITLE_CLEAR;
        grid_bot = BTN_CLEAR;
        item_h   = min(24, (grid_top - grid_bot) / max(n_rows,1));

        app.h_subj_checks = gobjects(1, n);
        for ii = 1:n
            row = ceil(ii / n_cols) - 1;
            col = mod(ii - 1, n_cols);
            x = 4 + col * item_w;
            y = grid_top - (row + 1) * item_h;
            app.h_subj_checks(ii) = uicheckbox(app.SubjectsPanel, ...
                'Text',subjs{ii},'Value',logical(checked(ii)), ...
                'Position',[x y item_w item_h], ...
                'FontSize',15);
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

    function refreshMeasureButtons(app)
        if isempty(app.h_meas_btns) || ~any(isvalid(app.h_meas_btns)), return; end
        m = app.state.measure_idx;
        k = app.state.subtype_idx;
        COMB_H = app.layout_meas_h;

        for mi = 1:app.n_meas
            if ~isvalid(app.h_meas_btns(mi)), continue; end
            if mi == m
                app.h_meas_btns(mi).BackgroundColor = app.clr_gold;
                app.h_meas_btns(mi).FontColor = app.clr_black;
            else
                app.h_meas_btns(mi).BackgroundColor = app.clr_btn;
                app.h_meas_btns(mi).FontColor = app.clr_black;
            end
            for ki = 1:numel(app.MEASURES(mi).subtypes)
                if ~isvalid(app.h_sub_btns{mi}(ki)), continue; end
                if mi == m
                    app.h_sub_btns{mi}(ki).Visible = 'on';
                    if ki == k
                        app.h_sub_btns{mi}(ki).BackgroundColor = app.clr_gold_dk;
                        app.h_sub_btns{mi}(ki).FontColor = [1 1 1];
                    else
                        app.h_sub_btns{mi}(ki).BackgroundColor = app.clr_btn;
                        app.h_sub_btns{mi}(ki).FontColor = app.clr_black;
                    end
                else
                    app.h_sub_btns{mi}(ki).Visible = 'off';
                end
            end
        end

        subs  = app.MEASURES(m).subtypes;
        PAD = 8; FIG_W = app.UIFigure.Position(3); panel_w = FIG_W - 2*PAD;

        % Description starts just after the last visible subtype button for this measure
        sub_end_px = app.meas_sub_area_start;  % fallback: right of divider
        if ~isempty(subs) && ~isempty(app.h_sub_btns{m})
            last_valid = find(isvalid(app.h_sub_btns{m}), 1, 'last');
            if ~isempty(last_valid)
                lp = app.h_sub_btns{m}(last_valid).Position;
                sub_end_px = lp(1) + lp(3);
            end
        end
        DESC_GAP = 12;
        DESC_W   = max(200, round(panel_w * 0.20));
        DESC_X   = sub_end_px + DESC_GAP;
        ABR_X    = DESC_X + DESC_W + DESC_GAP;
        ABR_W    = max(300, panel_w - ABR_X - PAD);

        y_sel  = 0.99 - m*(app.meas_h + app.meas_gap) + app.meas_gap;
        btn_top_y = round((y_sel + app.meas_h) * COMB_H);
        btn_bot_y = round(y_sel * COMB_H);
        title_h   = 22;
        body_bot  = max(6, btn_bot_y - 4);
        body_h    = max(20, btn_top_y - title_h - body_bot - 6);
        title_y   = body_bot + body_h + 4;
        if ~isempty(subs)
            app.DescTitleLabel.Text = sprintf('%s (%s): %s', app.MEASURES(m).label, app.MEASURES(m).name, subs{k});
        else
            app.DescTitleLabel.Text = sprintf('%s (%s)', app.MEASURES(m).label, app.MEASURES(m).name);
        end
        app.DescLabel.Text = app.MEASURES(m).descriptions{k};
        app.DescTitleLabel.Position = [DESC_X title_y DESC_W title_h];
        app.DescLabel.Position      = [DESC_X body_bot DESC_W body_h];

        % Show only the parameter panel matching the selected measure; hide all others.
        % All panels live at the same position (ABR_X, ABR_W) — reflow whichever is visible.
        is_abr   = (m == 1);
        is_efr   = (m == 2);
        is_oae   = (m == 3);
        is_memr  = (m == 4);
        is_peaks = is_abr && (k == 2);

        if ~isempty(app.h_abr_param_panel) && isvalid(app.h_abr_param_panel)
            if is_abr
                old_pos = app.h_abr_param_panel.Position;
                app.h_abr_param_panel.Position = [ABR_X old_pos(2) ABR_W old_pos(4)];
            end
            app.h_abr_param_panel.Visible = ternary(is_abr, 'on', 'off');
            % Show/hide Peaks-only controls (levels, waves, ratios)
            lev_vis = ternary(is_peaks, 'on', 'off');
            for tag = {'abr_lev_lbl','abr_wave_lbl','abr_ratio_lbl','abr_ratio_field'}
                h = findall(app.h_abr_param_panel,'Tag',tag{1});
                if ~isempty(h), h.Visible = lev_vis; end
            end
            for li = 1:numel(app.h_abr_level_checks)
                if isvalid(app.h_abr_level_checks(li))
                    app.h_abr_level_checks(li).Visible = lev_vis;
                end
            end
            for wi = 1:numel(app.h_abr_wave_checks)
                if isvalid(app.h_abr_wave_checks(wi))
                    app.h_abr_wave_checks(wi).Visible = lev_vis;
                end
            end
        end

        % EFR panel: RAM-specific controls visible only for RAM subtype (k==2)
        if ~isempty(app.h_efr_param_panel) && isvalid(app.h_efr_param_panel)
            if is_efr
                old_pos = app.h_efr_param_panel.Position;
                app.h_efr_param_panel.Position = [ABR_X old_pos(2) ABR_W old_pos(4)];
            end
            app.h_efr_param_panel.Visible = ternary(is_efr, 'on', 'off');
            % Show RAM-specific controls only for RAM subtype (k==2)
            ram_vis = ternary(is_efr && (k == 2), 'on', 'off');
            for tag = {'efr_ram_hdr','efr_ram_info','efr_harm_lbl','efr_win_lbl', ...
                       'efr_win_s_lbl','efr_win_e_lbl','efr_harmonics','efr_win_start','efr_win_end'}
                h = findall(app.h_efr_param_panel,'Tag',tag{1});
                if ~isempty(h), h.Visible = ram_vis; end
            end
            if ~isempty(app.h_efr_harmonics_field) && isvalid(app.h_efr_harmonics_field)
                app.h_efr_harmonics_field.Visible = ram_vis;
            end
            if ~isempty(app.h_efr_window_start_field) && isvalid(app.h_efr_window_start_field)
                app.h_efr_window_start_field.Visible = ram_vis;
            end
            if ~isempty(app.h_efr_window_end_field) && isvalid(app.h_efr_window_end_field)
                app.h_efr_window_end_field.Visible = ram_vis;
            end
        end

        if ~isempty(app.h_oae_param_panel) && isvalid(app.h_oae_param_panel)
            if is_oae
                old_pos = app.h_oae_param_panel.Position;
                app.h_oae_param_panel.Position = [ABR_X old_pos(2) ABR_W old_pos(4)];
            end
            app.h_oae_param_panel.Visible = ternary(is_oae, 'on', 'off');
        end

        if ~isempty(app.h_memr_param_panel) && isvalid(app.h_memr_param_panel)
            if is_memr
                old_pos = app.h_memr_param_panel.Position;
                app.h_memr_param_panel.Position = [ABR_X old_pos(2) ABR_W old_pos(4)];
            end
            app.h_memr_param_panel.Visible = ternary(is_memr, 'on', 'off');
        end
    end

    % ── Profile management ─────────────────────────────────────────────────

    function pname = get_current_profile_name(app)
        pname = '';
        items = app.ProfileDropdown.Items;
        val   = app.ProfileDropdown.Value;
        if ~isempty(items) && ~strcmp(items{1},'(no profiles)')
            pname = val;
        end
    end

    function load_profile_to_gui(app, pname)
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
        if isfield(p,'last_sheet'),         app.state.sheet = p.last_sheet;                       end
        if isfield(p,'reanalyze'),          app.ReanalyzeCheck.Value    = logical(p.reanalyze);   end
        if isfield(p,'plot_relative_flag'), app.PlotRelativeCheck.Value = logical(p.plot_relative_flag); end
        if isfield(p,'abr_custom_freqs') && ~isempty(app.h_abr_custom_freq_field) && isvalid(app.h_abr_custom_freq_field)
            app.h_abr_custom_freq_field.Value = p.abr_custom_freqs;
        end
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
        if isfield(p,'abr_tpl_req') && ~isempty(app.h_abr_tpl_req_check) && isvalid(app.h_abr_tpl_req_check)
            app.h_abr_tpl_req_check.Value = logical(p.abr_tpl_req);
        end
        if isfield(p,'abr_wave_sel') && ~isempty(app.h_abr_wave_checks)
            for wi = 1:min(numel(p.abr_wave_sel), numel(app.h_abr_wave_checks))
                if isvalid(app.h_abr_wave_checks(wi))
                    app.h_abr_wave_checks(wi).Value = logical(p.abr_wave_sel(wi));
                end
            end
        end
        if isfield(p,'abr_wave_ratios') && ~isempty(app.h_abr_ratio_field) && isvalid(app.h_abr_ratio_field)
            app.h_abr_ratio_field.Value = p.abr_wave_ratios;
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
        scan_chinroster_files(app, preferred);
    end

    function save_current_to_profile(app, pname)
        if ismac
            app.profiles.(pname).ROOTdir_mac = strtrim(app.RootDirField.Value);
        else
            app.profiles.(pname).ROOTdir_win = strtrim(app.RootDirField.Value);
        end
        roster_val = app.RosterDropdown.Value;
        if ~isempty(roster_val) && roster_val(1) ~= '('
            app.profiles.(pname).chinroster_filename = roster_val;
        end
        app.profiles.(pname).last_sheet          = app.state.sheet;
        app.profiles.(pname).reanalyze           = app.ReanalyzeCheck.Value;
        app.profiles.(pname).plot_relative_flag  = app.PlotRelativeCheck.Value;
        if ~isempty(app.h_abr_custom_freq_field) && isvalid(app.h_abr_custom_freq_field)
            app.profiles.(pname).abr_custom_freqs = app.h_abr_custom_freq_field.Value;
        end
        if ~isempty(app.h_abr_freq_checks) && any(isvalid(app.h_abr_freq_checks))
            app.profiles.(pname).abr_freq_sel = arrayfun(@(c) isvalid(c) && c.Value, app.h_abr_freq_checks);
        end
        if ~isempty(app.h_abr_level_checks) && any(isvalid(app.h_abr_level_checks))
            app.profiles.(pname).abr_level_sel = arrayfun(@(c) isvalid(c) && c.Value, app.h_abr_level_checks);
        end
        if ~isempty(app.h_abr_tpl_req_check) && isvalid(app.h_abr_tpl_req_check)
            app.profiles.(pname).abr_tpl_req = app.h_abr_tpl_req_check.Value;
        end
        if ~isempty(app.h_abr_wave_checks) && any(isvalid(app.h_abr_wave_checks))
            app.profiles.(pname).abr_wave_sel = arrayfun(@(c) isvalid(c) && c.Value, app.h_abr_wave_checks);
        end
        if ~isempty(app.h_abr_ratio_field) && isvalid(app.h_abr_ratio_field)
            app.profiles.(pname).abr_wave_ratios = app.h_abr_ratio_field.Value;
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

    function save_profiles_to_file(app)
        profiles  = app.profiles; %#ok<PROP>
        last_user = app.last_user; %#ok<PROP>
        save(app.profile_file,'profiles','last_user');
    end

    % ── Last-used settings ─────────────────────────────────────────────────

    function save_last_settings(app, Chins2Run_sel, Conds2Run_sel)
        ROOTdir = strtrim(app.RootDirField.Value);
        if isempty(ROOTdir), return; end
        settings_file = fullfile(ROOTdir,'Analysis','launcher_last_settings.mat');
        s.Chins2Run     = Chins2Run_sel;
        s.Conds2Run     = Conds2Run_sel;
        s.reanalyze     = app.ReanalyzeCheck.Value;
        s.plot_relative = app.PlotRelativeCheck.Value;
        s.show_analysis = app.ShowAnalysisCheck.Value;
        s.show_ind      = app.ShowIndCheck.Value;
        s.show_avg      = app.ShowAvgCheck.Value;
        s.measure_idx   = app.state.measure_idx;
        s.subtype_idx   = app.state.subtype_idx;
        if ~isempty(app.h_abr_freq_checks) && any(isvalid(app.h_abr_freq_checks))
            s.abr_freq_sel = arrayfun(@(c) isvalid(c) && c.Value, app.h_abr_freq_checks);
        end
        if ~isempty(app.h_abr_level_checks) && any(isvalid(app.h_abr_level_checks))
            s.abr_level_sel = arrayfun(@(c) isvalid(c) && c.Value, app.h_abr_level_checks);
        end
        if ~isempty(app.h_abr_tpl_req_check) && isvalid(app.h_abr_tpl_req_check)
            s.abr_tpl_req = app.h_abr_tpl_req_check.Value;
        end
        if ~isempty(app.h_abr_wave_checks) && any(isvalid(app.h_abr_wave_checks))
            s.abr_wave_sel = arrayfun(@(c) isvalid(c) && c.Value, app.h_abr_wave_checks);
        end
        if ~isempty(app.h_abr_ratio_field) && isvalid(app.h_abr_ratio_field)
            s.abr_wave_ratios = app.h_abr_ratio_field.Value;
        end
        last_settings = s; %#ok<NASGU>
        try, save(settings_file,'last_settings'); catch, end
    end

    function load_last_settings(app)
        ROOTdir = strtrim(app.RootDirField.Value);
        if isempty(ROOTdir), return; end
        settings_file = fullfile(ROOTdir,'Analysis','launcher_last_settings.mat');
        if ~exist(settings_file,'file'), return; end
        try, tmp = load(settings_file,'last_settings'); catch, return; end
        s = tmp.last_settings;
        if isfield(s,'reanalyze'),     app.ReanalyzeCheck.Value    = logical(s.reanalyze);     end
        if isfield(s,'plot_relative'), app.PlotRelativeCheck.Value = logical(s.plot_relative); end
        if isfield(s,'show_analysis'), app.ShowAnalysisCheck.Value = logical(s.show_analysis); end
        if isfield(s,'show_ind'),      app.ShowIndCheck.Value      = logical(s.show_ind);      end
        if isfield(s,'show_avg'),      app.ShowAvgCheck.Value      = logical(s.show_avg);      end
        if isfield(s,'measure_idx') && s.measure_idx >= 1 && s.measure_idx <= numel(app.MEASURES)
            app.state.measure_idx = s.measure_idx;
        end
        if isfield(s,'subtype_idx'), app.state.subtype_idx = s.subtype_idx; end
        refreshMeasureButtons(app);
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
        if isfield(s,'abr_tpl_req') && ~isempty(app.h_abr_tpl_req_check) && isvalid(app.h_abr_tpl_req_check)
            app.h_abr_tpl_req_check.Value = logical(s.abr_tpl_req);
        end
        if isfield(s,'abr_wave_sel') && ~isempty(app.h_abr_wave_checks)
            for wi = 1:min(numel(s.abr_wave_sel), numel(app.h_abr_wave_checks))
                if isvalid(app.h_abr_wave_checks(wi))
                    app.h_abr_wave_checks(wi).Value = logical(s.abr_wave_sel(wi));
                end
            end
        end
        if isfield(s,'abr_wave_ratios') && ~isempty(app.h_abr_ratio_field) && isvalid(app.h_abr_ratio_field)
            app.h_abr_ratio_field.Value = s.abr_wave_ratios;
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

    % ── Data status table (per-modality subtabs) ──────────────────────────

    function build_status_table(app)
        ROOTdir = strtrim(app.RootDirField.Value);
        if isempty(ROOTdir)
            uialert(app.UIFigure,'Set the root directory first.','Data Status'); return
        end
        if isempty(app.subj_ids) || isempty(app.state.conds_all)
            uialert(app.UIFigure,'Load the chinroster first.','Data Status'); return
        end
        analysis_dir = fullfile(ROOTdir,'Analysis');
        subjs  = app.subj_ids;
        conds  = app.state.conds_all;
        labels = app.state.cond_labels;
        n_s = numel(subjs);  n_c = numel(conds);

        modalities = { ...
            'ABR Thresholds', fullfile('ABR','%s','%s'),         '*ABRthresholds*.mat'; ...
            'ABR Peaks',      fullfile('ABR','%s','%s'),         '*ABRpeaks_dtw*.mat'; ...
            'EFR RAM',        fullfile('EFR','%s','%s'),         '*EFR_RAM*.mat'; ...
            'EFR dAM',        fullfile('EFR','%s','%s'),         '*EFR_dAM*.mat'; ...
            'DPOAE',          fullfile('OAE','DPOAE','%s','%s'), '*DPOAE*.mat'; ...
            'SFOAE',          fullfile('OAE','SFOAE','%s','%s'), '*SFOAE*.mat'; ...
            'TEOAE',          fullfile('OAE','TEOAE','%s','%s'), '*TEOAE*.mat'; ...
            'MEMR',           fullfile('MEMR','%s','%s'),        '*MEMR*.mat'; ...
        };
        n_mod = size(modalities,1);

        % Pre-compute: does ANY modality have data for each (subject, condition)?
        has_any = false(n_s, n_c);
        mod_data = false(n_s, n_c, n_mod);
        for mi = 1:n_mod
            for si = 1:n_s
                for ci = 1:n_c
                    fdir = fullfile(analysis_dir, sprintf(modalities{mi,2}, subjs{si}, conds{ci}));
                    hits = dir(fullfile(fdir, modalities{mi,3}));
                    hits = hits(~strncmp({hits.name},'._',2));
                    mod_data(si,ci,mi) = ~isempty(hits);
                    if mod_data(si,ci,mi), has_any(si,ci) = true; end
                end
            end
        end

        % Clear existing subtabs and rebuild
        delete(app.StatusInnerTG.Children);

        clr_green = [0.18 0.72 0.42];   % analyzed
        clr_amber = [0.97 0.72 0.22];   % measured but not yet analyzed
        clr_grey  = [0.82 0.82 0.82];   % not measured at this timepoint
        col_w_subj = 90;
        col_w_cond = max(80, round((app.UIFigure.Position(3) - col_w_subj) / max(n_c,1)));
        tg_h = app.StatusInnerTG.Position(4) - 28;  % subtract inner tab bar

        col_names = [{'Subject'}, labels(:)'];
        col_widths = [col_w_subj, repmat(col_w_cond, 1, n_c)];

        for mi = 1:n_mod
            mod_tab = uitab(app.StatusInnerTG, 'Title', modalities{mi,1});
            tbl_data = cell(n_s, n_c + 1);
            for si = 1:n_s
                tbl_data{si,1} = subjs{si};
                for ci = 1:n_c
                    tbl_data{si,ci+1} = ternary(mod_data(si,ci,mi), '✓', '');
                end
            end
            tbl = uitable(mod_tab, ...
                'Data',tbl_data,'ColumnName',col_names, ...
                'ColumnWidth',num2cell(col_widths), ...
                'RowName',{}, ...
                'Position',[0 0 app.UIFigure.Position(3) tg_h]);
            for si = 1:n_s
                for ci = 1:n_c
                    if mod_data(si,ci,mi)
                        clr = clr_green;
                    elseif has_any(si,ci)
                        clr = clr_amber;
                    else
                        clr = clr_grey;
                    end
                    addStyle(tbl, uistyle('BackgroundColor',clr), 'cell', [si, ci+1]);
                end
            end
        end
    end

    % ── Figure embedding ───────────────────────────────────────────────────

    function embed_in_analysis(app, figs, measure_label, subject, exp_name)
        % Route individual figures into a per-subject sub-panel.
        if ~isvalid(app), return; end
        valid_figs = figs(arrayfun(@(f) isvalid(f) && ...
            ~isempty(findall(f,'Type','axes')), figs));
        if isempty(valid_figs), return; end

        meas_idx = find(strcmp(app.measure_tab_labels(), measure_label), 1);
        if isempty(meas_idx), return; end
        if nargin < 5 || isempty(exp_name), exp_name = 'Unknown'; end

        ind_panel = app.fig_panels{1, meas_idx};
        pos       = ind_panel.Position;

        % Find or create per-subject sub-panel
        data = app.fig_subj_data{meas_idx};
        si   = find(strcmp(data.names, subject), 1);
        if isempty(si)
            si = numel(data.names) + 1;
            sp = uipanel(ind_panel, 'BorderType','none', ...
                'BackgroundColor',app.clr_bg, ...
                'Position',[0 0 pos(3) pos(4)], 'Visible','off');
            data.names{si}  = subject;
            data.panels{si} = sp;
            data.exps{si}   = exp_name;
            app.fig_subj_data{meas_idx} = data;
        end

        sp = app.fig_subj_data{meas_idx}.panels{si};
        delete(sp.Children);
        embed_figs_full(app, valid_figs, sp);
        % If embed created condition tabs (ABR Peaks), attach a callback so the
        % freq dropdown refreshes when the user switches condition tabs.
        for ch = sp.Children(:)'
            if isa(ch,'matlab.ui.container.TabGroup')
                ch.SelectionChangedFcn = @(~,~) cond_tab_changed_ind(app, meas_idx, subject);
                break;
            end
        end

        % Show this subject, hide others
        for k = 1:numel(app.fig_subj_data{meas_idx}.panels)
            if isvalid(app.fig_subj_data{meas_idx}.panels{k})
                app.fig_subj_data{meas_idx}.panels{k}.Visible = 'off';
            end
        end
        sp.Visible = 'on';

        % Update control bar dropdowns to reflect new data
        rebuild_exp_dropdown(app, meas_idx);
        refresh_subj_dropdown(app, meas_idx);
        if any(strcmp(app.FigSubjDropdown.Items, subject))
            app.FigSubjDropdown.Value = subject;
        end

        switchFigurePanel(app, 1, meas_idx);
        % Ensure Individual mode active and subject controls visible
        app.FigIndBtn.Value = true;
        app.FigAvgBtn.Value = false;
        app.FigIndBtn.BackgroundColor = app.clr_gold;
        app.FigAvgBtn.BackgroundColor = app.clr_btn;
        app.FigSubjDropdown.Visible = 'on';
        update_major_from_meas(app, meas_idx);
        % update_filter_dds after update_major_from_meas so its visibility
        % override (Cond:/Freq: label + show) is not undone by update_filter_visibility
        update_filter_dds(app, meas_idx, subject);
        app.TabGroup.SelectedTab = app.FiguresTab;
        drawnow;
    end

    function embed_in_average(app, figs, label)
        % Route average figures into the Average panel for this measure.
        if ~isvalid(app), return; end
        valid_figs = figs(arrayfun(@(f) isvalid(f) && ...
            ~isempty(findall(f,'Type','axes')), figs));
        if isempty(valid_figs), return; end

        meas_idx = find(strcmp(app.measure_tab_labels(), label), 1);
        if isempty(meas_idx), return; end

        panel = app.fig_panels{2, meas_idx};
        delete(panel.Children);
        embed_figs_full(app, valid_figs, panel);

        % For ABR Peaks: merge freq labels from avg figure Names into FigFreqDD
        % so the dropdown is complete even when individual figures for some
        % frequencies are missing.
        if meas_idx == 2
            avg_names = arrayfun(@(f) get(f,'Name'), valid_figs, 'UniformOutput', false);
            avg_freqs = {};
            for fi = 1:numel(avg_names)
                pts = strsplit(avg_names{fi}, '|');
                if numel(pts) >= 2 && ~isempty(pts{2})
                    avg_freqs{end+1} = pts{2}; %#ok<AGROW>
                end
            end
            avg_freqs = unique(avg_freqs, 'stable');
            if ~isempty(avg_freqs)
                existing      = app.FigFreqDD.Items;
                existing_real = existing(~strcmp(existing,'—'));
                new_items     = avg_freqs(~ismember(avg_freqs, existing_real));
                merged        = [existing_real, new_items];
                if isempty(merged), merged = avg_freqs; end
                app.FigFreqDD.Items = merged;
                % Always reset to the first frequency — that is what
                % embed_categorized_tabs makes visible, so the dropdown
                % must match from the start.
                app.FigFreqDD.Value = avg_freqs{1};
            end
        end

        switchFigurePanel(app, 2, meas_idx);
        app.FigAvgBtn.Value = true;
        app.FigIndBtn.Value = false;
        app.FigAvgBtn.BackgroundColor = app.clr_gold;
        app.FigIndBtn.BackgroundColor = app.clr_btn;
        app.FigSubjDropdown.Visible = 'off';
        update_major_from_meas(app, meas_idx);
        app.TabGroup.SelectedTab = app.FiguresTab;
        drawnow;
        % Reconcile panel visibility with the (just-set) dropdown value.
        apply_avg_filter(app);
    end

    function embed_figs_full(app, figs, parent)
        % Place figs into parent panel, filling its available space.
        % Sizes are read from parent.Position so no tab-level counting needed.
        %
        % Layout strategy:
        %   • If every figure has a non-empty Name → stacked full-size panels,
        %     one visible at a time. FigFreqDD (or any filter) controls which
        %     one shows. First panel is visible by default.
        %   • Otherwise → 2-column scrollable grid (all visible).
        PAD  = 4;
        pos  = parent.Position;
        W    = pos(3);
        VH   = pos(4);
        n    = numel(figs);
        fw   = W - 2*PAD;
        fh   = VH - 2*PAD;

        names = arrayfun(@(f) get(f,'Name'), figs, 'UniformOutput', false);
        has_category = any(cellfun(@(n) ~isempty(n) && contains(n,'|'), names));
        if has_category
            embed_categorized_tabs(app, figs, names, parent);
            return;
        end
        use_stacked = n > 1 && all(~cellfun(@isempty, names));

        if use_stacked
            % Stacked panels: all same position, one visible at a time.
            % FigFreqDD selection controls visibility via apply_filter.
            % Title is blank (no text shown); freq label stored in Tag.
            for i = 1:n
                vis = ternary(i == 1, 'on', 'off');
                sub_p = uipanel(parent, 'Position',[PAD PAD fw fh], ...
                    'BackgroundColor','white', 'Visible', vis, ...
                    'Title', '', 'Tag', names{i}, 'FontSize', 14);
                axs = findall(figs(i),'Type','axes');
                new_axs = copyobj(axs, sub_p);
                arrayfun(@(a) set(a,'Units','normalized'), new_axs);
            end
        elseif n == 1
            sub_p = uipanel(parent, 'Position',[PAD PAD fw fh], ...
                'BackgroundColor','white', ...
                'Title', names{1}, 'FontSize', 14);
            axs = findall(figs(1),'Type','axes');
            new_axs = copyobj(axs, sub_p);
            arrayfun(@(a) set(a,'Units','normalized'), new_axs);
        elseif n == 2
            fw2 = floor((W - 3*PAD) / 2);
            for i = 1:2
                x = PAD + (i-1)*(fw2+PAD);
                sub_p = uipanel(parent, 'Position',[x PAD fw2 fh], ...
                    'BackgroundColor','white', ...
                    'Title', names{i}, 'FontSize', 14);
                axs = findall(figs(i),'Type','axes');
                new_axs = copyobj(axs, sub_p);
                arrayfun(@(a) set(a,'Units','normalized'), new_axs);
            end
        else
            % 2-column scrollable grid for 3+ unnamed figures
            fw2 = floor((W - 3*PAD) / 2);
            n_rows  = ceil(n/2);
            total_h = n_rows*(fh+PAD)+PAD;
            scroll = uipanel(parent, 'Scrollable','on', 'BorderType','none', ...
                'BackgroundColor',app.clr_bg, 'Position',[0 0 W VH]);
            for i = 1:n
                col = mod(i-1,2);  row = floor((i-1)/2);
                x   = PAD + col*(fw2+PAD);
                y   = total_h - (row+1)*(fh+PAD);
                sub_p = uipanel(scroll, 'Position',[x y fw2 fh], ...
                    'BackgroundColor','white', ...
                    'Title', names{i}, 'FontSize', 14);
                axs = findall(figs(i),'Type','axes');
                new_axs = copyobj(axs, sub_p);
                arrayfun(@(a) set(a,'Units','normalized'), new_axs);
            end
        end
        % Figures are closed by the caller after all embeds complete
    end

    function embed_categorized_tabs(app, figs, names, parent)
        % Categorized tab layout.
        % Named figures ('Category|Label') create one tab per category; within
        % each tab, stacked panels (one per label) are controlled by FigFreqDD.
        % Un-named or non-pipe figures go into a 'Summary' tab (direct embed,
        % no stacking) placed last — used for ABR Thresholds multi-condition overlay.
        PAD = 4;

        % Parse category and label from each name
        n = numel(figs);
        categories = cell(1, n);
        freq_labels = cell(1, n);
        for i = 1:n
            parts = strsplit(names{i}, '|');
            if numel(parts) >= 2
                categories{i}  = parts{1};
                freq_labels{i} = parts{2};
            else
                % No pipe → Summary tab (e.g. multi-condition overlay)
                categories{i}  = 'Summary';
                freq_labels{i} = '';
            end
        end

        % Tab ordering: average categories → diagnostic categories → Summary
        cat_order   = {'Waveforms','Amplitudes','Latencies', ...
                       'ABR Waveforms','Sigmoid Fits','Audiogram'};
        unique_cats = unique(categories, 'stable');
        present     = cat_order(ismember(cat_order, unique_cats));
        others      = unique_cats(~ismember(unique_cats, [cat_order, {'Summary'}]));
        has_summary = ismember('Summary', unique_cats);
        ordered_cats = [present, others, ternary(has_summary, {'Summary'}, {})];

        tg = uitabgroup(parent, 'Units','normalized','Position',[0 0 1 1]);

        for ci = 1:numel(ordered_cats)
            cat      = ordered_cats{ci};
            cat_mask = strcmp(categories, cat);
            cat_figs = figs(cat_mask);
            cat_freq = freq_labels(cat_mask);

            tab = uitab(tg, 'Title', cat);
            tab_panel = uipanel(tab, 'Units','normalized','Position',[0 0 1 1], ...
                'BorderType','none', 'BackgroundColor','white');

            if strcmp(cat, 'Summary')
                % Direct embed — no FigFreqDD stacking needed
                for k = 1:numel(cat_figs)
                    axs     = findall(cat_figs(k),'Type','axes');
                    new_axs = copyobj(axs, tab_panel);
                    arrayfun(@(a) set(a,'Units','normalized'), new_axs);
                end
                continue;
            end

            % Sort labels: conditions in timepoint order, frequencies numerically
            unique_freqs = sort_tab_labels(unique(cat_freq, 'stable'));

            for fi = 1:numel(unique_freqs)
                fq       = unique_freqs{fi};
                fq_mask  = strcmp(cat_freq, fq);
                fq_figs  = cat_figs(fq_mask);
                vis      = ternary(fi == 1, 'on', 'off');

                % Stacked panels all at same position; FigFreqDD toggles visibility
                freq_p = uipanel(tab_panel, 'Title', '', 'Tag', fq, 'FontSize', 14, ...
                    'Visible', vis, 'BackgroundColor','white', ...
                    'Units','normalized','Position',[0 0 1 1]);

                nf = numel(fq_figs);
                if nf == 1
                    axs     = findall(fq_figs(1),'Type','axes');
                    new_axs = copyobj(axs, freq_p);
                    arrayfun(@(a) set(a,'Units','normalized'), new_axs);
                else
                    % 2-column grid for multiple figures at the same label
                    nc = 2;  nr = ceil(nf / nc);
                    for k = 1:nf
                        r = floor((k-1)/nc);  c = mod(k-1, nc);
                        x = c/nc;  y = 1 - (r+1)/nr;
                        w = 1/nc;  h = 1/nr;
                        inner_p = uipanel(freq_p, 'Units','normalized', ...
                            'Position',[x y w h], ...
                            'BackgroundColor','white','BorderType','none');
                        axs     = findall(fq_figs(k),'Type','axes');
                        new_axs = copyobj(axs, inner_p);
                        arrayfun(@(a) set(a,'Units','normalized'), new_axs);
                    end
                end
            end
        end
    end

    function apply_avg_filter(app)
        % Show/hide frequency panels in the average panel for ABR Peaks
        % (categorized tab layout). Mirrors FigFreqDD selection across all tabs.
        % Always syncs FigFreqDD.Value back to what is actually shown.
        meas_idx = current_meas_idx(app);
        if isempty(app.fig_panels), return; end
        avg_panel = app.fig_panels{2, meas_idx};
        if ~isvalid(avg_panel) || isempty(avg_panel.Children), return; end

        % Restore freq labels from avg tabgroup into FigFreqDD (survives measure switches)
        sync_avg_freq_labels(app, meas_idx);

        freq_filter = '';
        if strcmp(app.FigFreqDD.Visible,'on') && ~strcmp(app.FigFreqDD.Value,'—')
            freq_filter = app.FigFreqDD.Value;
        end

        % Find uitabgroup in avg panel
        tg = [];
        for ch = avg_panel.Children(:)'
            if isa(ch,'matlab.ui.container.TabGroup')
                tg = ch; break;
            end
        end
        if isempty(tg), return; end

        actual_visible_tag = '';   % what is actually shown after all toggling

        % Walk every tab → tab_panel → freq_panels and show/hide
        for ti = 1:numel(tg.Children)
            tab = tg.Children(ti);
            tab_panel = [];
            for ch = tab.Children(:)'
                if isa(ch,'matlab.ui.container.Panel')
                    tab_panel = ch; break;
                end
            end
            if isempty(tab_panel), continue; end

            freq_panels = {};
            for ch = tab_panel.Children(:)'
                if isa(ch,'matlab.ui.container.Panel') && ~isempty(ch.Tag)
                    freq_panels{end+1} = ch; %#ok<AGROW>
                end
            end
            if isempty(freq_panels), continue; end

            % MATLAB Children are in reverse creation order; {end} = first created.
            first_p = freq_panels{end};
            matched = false;
            for i = 1:numel(freq_panels)
                p = freq_panels{i};
                if isempty(freq_filter)
                    p.Visible = ternary(p == first_p, 'on', 'off');
                else
                    hits = strcmpi(p.Tag, freq_filter);
                    p.Visible = ternary(hits, 'on', 'off');
                    if hits, matched = true; end
                end
            end
            % Fallback: if requested freq not found, show first panel
            if ~isempty(freq_filter) && ~matched
                first_p.Visible = 'on';
            end
            % Record what is actually visible (use first tab as reference)
            if isempty(actual_visible_tag)
                if matched
                    actual_visible_tag = freq_filter;
                else
                    actual_visible_tag = first_p.Tag;
                end
            end
        end

        % Always sync the dropdown to what is actually on screen
        if ~isempty(actual_visible_tag) && strcmp(app.FigFreqDD.Visible,'on') && ...
                ~strcmp(app.FigFreqDD.Value, actual_visible_tag) && ...
                any(strcmp(app.FigFreqDD.Items, actual_visible_tag))
            app.FigFreqDD.Value = actual_visible_tag;
        end
    end

    function update_progress(app, n, total, msg)
        % Update the status label under the Run button.
        % Throws if the user clicked Stop, so analysis_run unwinds cleanly.
        if ~isvalid(app) || total <= 0, return; end
        app.h_progress_label.Visible = 'on';
        if n >= total
            app.h_progress_label.Text = '✓  Complete';
        else
            app.h_progress_label.Text = msg;
        end
        drawnow('limitrate');
        if app.abort_requested
            error('APAT:UserAbort','Analysis stopped by user.');
        end
    end

    % ── Spinner helpers ───────────────────────────────────────────────────

    function start_spinner_anim(app)
        % Show spinner label and start timer cycling through frames.
        app.spinner_frame = 1;
        sc = spinner_chars(app); app.h_spinner_label.Text = sc{1};
        app.h_spinner_label.Visible = 'on';
        drawnow;
        % Stop any stale timer before creating a new one
        if ~isempty(app.h_spinner_timer) && isvalid(app.h_spinner_timer)
            stop(app.h_spinner_timer);
            delete(app.h_spinner_timer);
        end
        app.h_spinner_timer = timer( ...
            'Name',           'APAT_spinner', ...
            'Period',         0.12, ...
            'ExecutionMode',  'fixedRate', ...
            'BusyMode',       'drop', ...
            'TimerFcn',       @(~,~) spinner_tick(app));
        start(app.h_spinner_timer);
    end

    function spinner_tick(app)
        % Timer callback: advance to next spinner frame.
        if ~isvalid(app) || ~isvalid(app.h_spinner_label), return; end
        chars = spinner_chars(app);
        app.spinner_frame = mod(app.spinner_frame, numel(chars)) + 1;
        app.h_spinner_label.Text = chars{app.spinner_frame};
        drawnow('limitrate');
    end

    function stop_spinner_anim(app, completed)
        % Stop the timer and hide spinner (show checkmark briefly on success).
        if ~isvalid(app), return; end
        if ~isempty(app.h_spinner_timer) && isvalid(app.h_spinner_timer)
            stop(app.h_spinner_timer);
            delete(app.h_spinner_timer);
            app.h_spinner_timer = [];
        end
        if completed
            app.h_spinner_label.Text    = '✓';
            app.h_spinner_label.Visible = 'on';
            drawnow;
            pause(1.2);
        end
        app.h_spinner_label.Visible  = 'off';
        app.h_progress_label.Visible = 'off';
        drawnow;
    end

    function chars = spinner_chars(~)
        % Returns cell array of spinner Unicode frames (braille dots).
        chars = {char(0x280B), char(0x2819), char(0x2839), char(0x2838), ...
                 char(0x283C), char(0x2834), char(0x2826), char(0x2827), ...
                 char(0x2807), char(0x280F)};
    end

    function clearMeasureFigures(app, measure_label)
        % Clear only this measure's panels so other measures persist.
        meas_idx = find(strcmp(app.measure_tab_labels(), measure_label), 1);
        if isempty(meas_idx) || isempty(app.fig_panels), return; end

        % Individual: delete sub-panels and reset data struct
        p_ind = app.fig_panels{1, meas_idx};
        if isvalid(p_ind)
            data = app.fig_subj_data{meas_idx};
            for k = 1:numel(data.panels)
                if isvalid(data.panels{k}), delete(data.panels{k}); end
            end
            app.fig_subj_data{meas_idx} = struct('names',{{}},'panels',{{}},'exps',{{}});
        end

        % Average: clear content and restore placeholder
        p_avg = app.fig_panels{2, meas_idx};
        if isvalid(p_avg)
            delete(p_avg.Children);
            pos = p_avg.Position;
            uilabel(p_avg, 'Tag','placeholder', ...
                'Text','Run analysis to see average figures here.', ...
                'Position',[0 round(pos(4)/2-30) pos(3) 60], ...
                'FontSize',18, 'FontColor',[0.55 0.55 0.55], ...
                'HorizontalAlignment','center', 'WordWrap','on');
        end

        % Reset control bar if currently showing this measure
        if app.fig_panel_meas == meas_idx
            app.FigExpDropdown.Items  = {'(no data)'};
            app.FigExpDropdown.Value  = '(no data)';
            app.FigSubjDropdown.Items = {'(no data)'};
            app.FigSubjDropdown.Value = '(no data)';
            app.FigFreqDD.Items  = {'—'};   app.FigFreqDD.Value  = '—';
            app.FigLevelDD.Items = {'—'};   app.FigLevelDD.Value = '—';
        end
    end


end % private methods

% ══════════════════════════════════════════════════════════════════════════
%  STATIC UTILITY FUNCTIONS (file-scope equivalents)
% ══════════════════════════════════════════════════════════════════════════
methods (Static, Access = private)

    function labels = measure_tab_labels()
        labels = {'ABR Thresholds','ABR Peaks','EFR dAM','EFR RAM', ...
                  'DPOAE','SFOAE','TEOAE','MEMR'};
    end

    function tab = find_tab_by_title(tg, title)
        % Return the uitab in tg whose Title matches, or [] if not found.
        tab = [];
        for t = tg.Children'
            if strcmp(t.Title, title), tab = t; return; end
        end
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

    function [subjects, cond_paths, cond_labels] = read_chinroster_sheet(filepath, sheet)
        subjects    = {};
        cond_paths  = {};
        cond_labels = {};
        try
            data = readcell(filepath,'Sheet',sheet);
        catch
            return
        end
        miss_idx = cellfun(@(x) any(isa(x,'missing')), data);
        data(miss_idx) = {NaN};
        [nrows, ncols] = size(data);
        header_row = 0;
        baseline_cols = [];
        for i = 1:nrows
            for j = 1:ncols
                val = data{i,j};
                if ischar(val) && (strcmpi(val,'Baseline') || strcmp(val,'B'))
                    if header_row == 0, header_row = i; end
                    baseline_cols(end+1) = j; %#ok<AGROW>
                end
            end
        end
        if header_row > 0 && ~isempty(baseline_cols)
            c1 = baseline_cols(1);
            c2 = ncols;
            if numel(baseline_cols) >= 2, c2 = baseline_cols(2) - 1; end
            for j = c1:c2
                val = data{header_row,j};
                if ischar(val) && ~isempty(strtrim(val))
                    cond_labels{end+1} = val; %#ok<AGROW>
                    if strcmpi(val,'Baseline') || strcmp(val,'B')
                        cond_paths{end+1} = strcat('pre',filesep,val); %#ok<AGROW>
                    else
                        cond_paths{end+1} = strcat('post',filesep,val); %#ok<AGROW>
                    end
                end
            end
        end
        for i = 1:nrows
            if i == header_row, continue; end
            val = data{i,1};
            if ischar(val) && ~isempty(strtrim(val)) && ~isempty(regexp(strtrim(val),'\d','once'))
                subjects{end+1} = strtrim(val); %#ok<AGROW>
            end
        end
        subjects = subjects(:);
    end

end % static methods

% ══════════════════════════════════════════════════════════════════════════
%  PUBLIC CONSTRUCTOR / DESTRUCTOR
% ══════════════════════════════════════════════════════════════════════════
methods (Access = public)

    function app = APAT_app
        persistent the_app

        % If a valid instance is already running, bring it to front.
        if ~isempty(the_app) && isvalid(the_app) && isvalid(the_app.UIFigure)
            figure(the_app.UIFigure);
            if nargout > 0, app = the_app; end
            return;
        end

        % Previous instance is gone — clean up any orphaned timers.
        try
            t = timerfindall('Name', 'APAT_spinner');
            if ~isempty(t), stop(t); delete(t); end
        catch; end

        createComponents(app)
        registerApp(app, app.UIFigure)
        runStartupFcn(app, @startupFcn)

        % Keep a persistent reference so the app survives 'clear app'.
        the_app = app;

        if nargout == 0
            clear app
        end
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


% ── Inline ternary helper ─────────────────────────────────────────────────
function out = ternary(cond, a, b)
if cond, out = a; else, out = b; end
end

% ── Tab label sorter (conditions in study order, then frequencies) ─────────
function sorted = sort_tab_labels(labels)
cond_order = {'pre','Baseline','post','D3','D7','D14','D30'};
n = numel(labels);
idx = nan(1, n);
for k = 1:n
    ci = find(strcmpi(labels{k}, cond_order), 1);
    if ~isempty(ci)
        idx(k) = ci;
    else
        num = regexp(labels{k}, '[\d\.]+', 'match', 'once');
        if ~isempty(num)
            idx(k) = str2double(num) + 100;
        else
            idx(k) = 200;
        end
    end
end
[~, si] = sort(idx);
sorted = labels(si);
end
