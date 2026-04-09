classdef APAT_app < matlab.apps.AppBase
%APAT_APP  Auditory Physiology Analysis Toolkit — App Designer version.
%
%   Three-tab workflow:
%     1. Setup    – configure user, project, subjects, conditions,
%                   options, and auditory measure; then click Run Analysis
%     2. Analysis – figures appear here as each subject is processed
%     3. Status   – data-availability table across subjects × conditions
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
    DataStatusButton        matlab.ui.control.Button
    % Tab group
    TabGroup                matlab.ui.container.TabGroup
    SetupTab                matlab.ui.container.Tab
    AnalysisTab             matlab.ui.container.Tab
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
    % ── Analysis tab ───────────────────────────────────────────────────────
    AnalysisPlaceholderPanel matlab.ui.container.Panel
    AnalysisLogArea         matlab.ui.control.TextArea
    % ── Status tab ─────────────────────────────────────────────────────────
    RefreshStatusBtn        matlab.ui.control.Button
    StatusTable             matlab.ui.control.Table
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
    h_meas_btns             % uibutton array   – measure selector
    h_sub_btns              % cell of uibutton arrays – subtypes
    % Purdue palette
    clr_black; clr_gold; clr_gold_dk; clr_bg; clr_panel; clr_btn
    % Measure-button layout constants
    n_meas; meas_h; meas_gap
    % Panel height constants (set in buildSetupTab, used by helpers)
    layout_row2_h       % height of Subjects/Conditions/Options row
    layout_meas_h       % height of MeasuresPanel
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
        FIG_W = 940;
        HDR_H = 70;
        FIG_H = 720;
        TAB_H = FIG_H - HDR_H;

        scr = get(0,'ScreenSize');
        app.UIFigure = uifigure( ...
            'Name','Auditory Physiology Analysis Toolkit (APAT)', ...
            'Position',[round((scr(3)-FIG_W)/2) round((scr(4)-FIG_H)/2) FIG_W FIG_H], ...
            'Color',app.clr_bg, ...
            'CloseRequestFcn', @(~,~) delete(app));

        % ── Header ─────────────────────────────────────────────────────────
        app.HeaderPanel = uipanel(app.UIFigure, ...
            'BorderType','none','BackgroundColor',app.clr_black, ...
            'Position',[0 FIG_H-HDR_H FIG_W HDR_H]);

        app.TitleLabel = uilabel(app.HeaderPanel, ...
            'Text','Auditory Physiology Analysis Toolkit (APAT)', ...
            'Position',[14 33 660 30], ...
            'FontSize',17,'FontWeight','bold', ...
            'FontColor',app.clr_gold);

        app.SubtitleLabel = uilabel(app.HeaderPanel, ...
            'Text','Auditory Neurophysiology and Modeling Lab  —  Purdue University', ...
            'Position',[14 8 660 22], ...
            'FontSize',9.5, ...
            'FontColor',[0.88 0.84 0.74]);

        app.DataStatusButton = uibutton(app.HeaderPanel,'push', ...
            'Text','Data Status', ...
            'Position',[round(FIG_W*0.52) 8 round(FIG_W*0.20) 54], ...
            'FontSize',12,'FontWeight','bold', ...
            'FontColor',app.clr_black,'BackgroundColor',app.clr_btn, ...
            'ButtonPushedFcn', @(~,~) DataStatusButtonPushed(app));

        app.RunButton = uibutton(app.HeaderPanel,'push', ...
            'Text','Run Analysis', ...
            'Position',[round(FIG_W*0.75) 8 round(FIG_W*0.22) 54], ...
            'FontSize',14,'FontWeight','bold', ...
            'FontColor',app.clr_black,'BackgroundColor',app.clr_gold, ...
            'ButtonPushedFcn', @(~,~) RunButtonPushed(app));

        % ── Tab group ───────────────────────────────────────────────────────
        app.TabGroup = uitabgroup(app.UIFigure, 'Position',[0 0 FIG_W TAB_H]);
        app.SetupTab    = uitab(app.TabGroup,'Title','  Setup  ');
        app.AnalysisTab = uitab(app.TabGroup,'Title','  Analysis  ');
        app.StatusTab   = uitab(app.TabGroup,'Title','  Data Status  ');
        app.SetupTab.BackgroundColor    = app.clr_bg;
        app.AnalysisTab.BackgroundColor = app.clr_bg;
        app.StatusTab.BackgroundColor   = app.clr_bg;

        buildSetupTab(app,    PAD, FIG_W, TAB_H);
        buildAnalysisTab(app, PAD, FIG_W, TAB_H);
        buildStatusTab(app,   PAD, FIG_W, TAB_H);
    end

    function buildSetupTab(app, PAD, FIG_W, TAB_H)
        % ── Row heights and y positions (bottom → top) ──────────────────────
        ROW1_H = 130;   % User + Project Settings
        ROW2_H = 200;   % Subjects + Conditions + Options
        % MeasuresPanel fills the remaining space at the bottom
        MEAS_H = TAB_H - 30 - PAD - ROW1_H - PAD - ROW2_H - PAD - PAD;

        app.layout_row2_h = ROW2_H;
        app.layout_meas_h = MEAS_H;

        meas_y  = PAD;
        row2_y  = meas_y  + MEAS_H  + PAD;
        row1_y  = row2_y  + ROW2_H  + PAD;

        USER_W = 200;
        SP_X   = PAD + USER_W + PAD;
        SP_W   = FIG_W - SP_X - PAD;

        % ── User panel ──────────────────────────────────────────────────────
        app.UserPanel = uipanel(app.SetupTab, ...
            'Title','User','FontSize',9,'FontWeight','bold', ...
            'BackgroundColor',app.clr_panel,'BorderColor',app.clr_gold, ...
            'Position',[PAD row1_y USER_W ROW1_H]);

        app.ProfileDropdown = uidropdown(app.UserPanel, ...
            'Items',{'(no profiles)'},'Value','(no profiles)', ...
            'Position',[8 80 USER_W-22 26], ...
            'FontSize',11,'FontWeight','bold', ...
            'ValueChangedFcn', @(~,~) ProfileDropdownChanged(app));

        app.NewUserBtn = uibutton(app.UserPanel,'push','Text','New User', ...
            'Position',[8 48 USER_W-22 26],'FontSize',9,'BackgroundColor',app.clr_btn, ...
            'ButtonPushedFcn', @(~,~) NewUserButtonPushed(app));

        app.SaveUserBtn = uibutton(app.UserPanel,'push','Text','Save User', ...
            'Position',[8 16 USER_W-22 26],'FontSize',9,'BackgroundColor',app.clr_btn, ...
            'ButtonPushedFcn', @(~,~) SaveUserButtonPushed(app));

        % ── Project settings panel ──────────────────────────────────────────
        app.ProjectPanel = uipanel(app.SetupTab, ...
            'Title','Project Settings','FontSize',9,'FontWeight','bold', ...
            'BackgroundColor',app.clr_panel,'BorderColor',app.clr_gold, ...
            'Position',[SP_X row1_y SP_W ROW1_H]);

        uilabel(app.ProjectPanel,'Text','Root Directory:', ...
            'Position',[8 90 110 20],'FontSize',9);
        app.RootDirField = uieditfield(app.ProjectPanel,'text','Value','', ...
            'Position',[122 88 SP_W-240 24],'FontSize',9,'BackgroundColor','white');
        app.BrowseBtn = uibutton(app.ProjectPanel,'push','Text','Browse...', ...
            'Position',[SP_W-110 86 92 28],'FontSize',9,'BackgroundColor',app.clr_btn, ...
            'ButtonPushedFcn', @(~,~) BrowseButtonPushed(app));

        uilabel(app.ProjectPanel,'Text','Subject Roster:', ...
            'Position',[8 56 110 20],'FontSize',9);
        app.RosterDropdown = uidropdown(app.ProjectPanel, ...
            'Items',{'(set root directory first)'},'Value','(set root directory first)', ...
            'Position',[122 54 SP_W-140 24],'FontSize',9, ...
            'ValueChangedFcn', @(~,~) RosterDropdownChanged(app));

        uilabel(app.ProjectPanel,'Text','Experiment:', ...
            'Position',[8 22 90 20],'FontSize',9);
        app.SheetDropdown = uidropdown(app.ProjectPanel, ...
            'Items',{'(load chinroster first)'},'Value','(load chinroster first)', ...
            'Position',[122 20 round(SP_W*0.45) 24],'FontSize',10,'FontWeight','bold', ...
            'ValueChangedFcn', @(~,~) SheetDropdownChanged(app));

        % ── Subjects ────────────────────────────────────────────────────────
        subj_w  = round((FIG_W - 3*PAD) * 0.55);
        right_w = FIG_W - 3*PAD - subj_w;
        opt_w2  = 190;
        cond_w  = right_w - PAD - opt_w2;

        app.SubjectsPanel = uipanel(app.SetupTab, ...
            'Title','Subjects','FontSize',9,'FontWeight','bold', ...
            'BackgroundColor',app.clr_panel,'BorderColor',app.clr_gold, ...
            'Position',[PAD row2_y subj_w ROW2_H]);

        app.SelectAllBtn = uibutton(app.SubjectsPanel,'push','Text','Select All', ...
            'Position',[round(0.02*subj_w) 6 round(0.31*subj_w) 26], ...
            'FontSize',8.5,'BackgroundColor',app.clr_btn, ...
            'ButtonPushedFcn', @(~,~) SelectAllButtonPushed(app));
        app.ClearSubjBtn = uibutton(app.SubjectsPanel,'push','Text','Clear', ...
            'Position',[round(0.35*subj_w) 6 round(0.31*subj_w) 26], ...
            'FontSize',8.5,'BackgroundColor',app.clr_btn, ...
            'ButtonPushedFcn', @(~,~) ClearButtonPushed(app));
        app.RefreshSubjBtn = uibutton(app.SubjectsPanel,'push','Text','Refresh', ...
            'Position',[round(0.68*subj_w) 6 round(0.29*subj_w) 26], ...
            'FontSize',8.5,'BackgroundColor',app.clr_btn, ...
            'ButtonPushedFcn', @(~,~) RefreshButtonPushed(app));

        % ── Conditions ──────────────────────────────────────────────────────
        app.ConditionsPanel = uipanel(app.SetupTab, ...
            'Title','Conditions','FontSize',9,'FontWeight','bold', ...
            'BackgroundColor',app.clr_panel,'BorderColor',app.clr_gold, ...
            'Position',[PAD+subj_w+PAD row2_y cond_w ROW2_H]);

        % ── Options ─────────────────────────────────────────────────────────
        opt_x = PAD + subj_w + PAD + cond_w + PAD;
        app.OptionsPanel = uipanel(app.SetupTab, ...
            'Title','Options','FontSize',9,'FontWeight','bold', ...
            'BackgroundColor',app.clr_panel,'BorderColor',app.clr_gold, ...
            'Position',[opt_x row2_y opt_w2 ROW2_H]);

        ck_positions = [0.82 0.66 0.50 0.34 0.18];
        ck_labels    = {'Re-analyze existing data','Plot relative to Baseline', ...
                        'Show analysis figures','Show individual plots','Show average plots'};
        ck_defaults  = [true false false true true];

        app.ReanalyzeCheck    = uicheckbox(app.OptionsPanel,'Text',ck_labels{1}, ...
            'Position',[8 round(ck_positions(1)*ROW2_H) opt_w2-18 22], ...
            'FontSize',9,'Value',ck_defaults(1));
        app.PlotRelativeCheck = uicheckbox(app.OptionsPanel,'Text',ck_labels{2}, ...
            'Position',[8 round(ck_positions(2)*ROW2_H) opt_w2-18 22], ...
            'FontSize',9,'Value',ck_defaults(2));
        app.ShowAnalysisCheck = uicheckbox(app.OptionsPanel,'Text',ck_labels{3}, ...
            'Position',[8 round(ck_positions(3)*ROW2_H) opt_w2-18 22], ...
            'FontSize',9,'Value',ck_defaults(3));
        app.ShowIndCheck      = uicheckbox(app.OptionsPanel,'Text',ck_labels{4}, ...
            'Position',[8 round(ck_positions(4)*ROW2_H) opt_w2-18 22], ...
            'FontSize',9,'Value',ck_defaults(4));
        app.ShowAvgCheck      = uicheckbox(app.OptionsPanel,'Text',ck_labels{5}, ...
            'Position',[8 round(ck_positions(5)*ROW2_H) opt_w2-18 22], ...
            'FontSize',9,'Value',ck_defaults(5));

        % ── Auditory Measures ────────────────────────────────────────────────
        app.MeasuresPanel = uipanel(app.SetupTab, ...
            'Title','Auditory Measures','FontSize',9,'FontWeight','bold', ...
            'BackgroundColor',app.clr_panel,'BorderColor',app.clr_gold, ...
            'Position',[PAD meas_y FIG_W-2*PAD MEAS_H]);

        panel_w = FIG_W - 2*PAD;
        app.DescTitleLabel = uilabel(app.MeasuresPanel, 'Text','', ...
            'Position',[round(0.17*panel_w) round(0.60*MEAS_H) round(0.81*panel_w) round(0.09*MEAS_H)], ...
            'FontSize',9,'FontWeight','bold','FontColor',app.clr_black);
        app.DescLabel = uilabel(app.MeasuresPanel, 'Text','', ...
            'Position',[round(0.17*panel_w) round(0.05*MEAS_H) round(0.81*panel_w) round(0.51*MEAS_H)], ...
            'FontSize',9,'FontColor',app.clr_gold_dk,'WordWrap','on');

        % Measure/subtype buttons built after MEASURES is initialised
        app.h_meas_btns = gobjects(0);
        app.h_sub_btns  = {};
    end

    function buildAnalysisTab(app, PAD, FIG_W, TAB_H)
        % ── Placeholder panel (figures will be embedded here in a future release) ──
        LOG_H = round((TAB_H - 30 - 3*PAD) * 0.35);   % lower 35%: log
        FIG_H_PNL = TAB_H - 30 - 3*PAD - LOG_H;       % upper 65%: figures

        app.AnalysisPlaceholderPanel = uipanel(app.AnalysisTab, ...
            'Title','Figures','FontSize',9,'FontWeight','bold', ...
            'BackgroundColor',app.clr_panel,'BorderColor',app.clr_gold, ...
            'Position',[PAD PAD+LOG_H+PAD FIG_W-2*PAD FIG_H_PNL]);

        lbl = uilabel(app.AnalysisPlaceholderPanel, ...
            'Text', ['Configure your analysis in the Setup tab, then click ' ...
                     '"Run Analysis". ' newline newline ...
                     'Figures will be embedded here in a future release. ' ...
                     'During this release they appear as floating windows.'], ...
            'Position',[20 round(0.3*FIG_H_PNL) FIG_W-2*PAD-40 round(0.35*FIG_H_PNL)], ...
            'FontSize',11,'FontColor',[0.45 0.45 0.45],'WordWrap','on', ...
            'HorizontalAlignment','center');
        %#ok<NASGU> lbl not stored — static informational label

        % ── Console log (diary output redirected here when analysis runs) ────
        uilabel(app.AnalysisTab, 'Text','Console output:', ...
            'Position',[PAD PAD+LOG_H-2 120 18],'FontSize',9, ...
            'FontColor',[0.45 0.45 0.45]);

        app.AnalysisLogArea = uitextarea(app.AnalysisTab, ...
            'Value',{''},'Editable',false, ...
            'Position',[PAD PAD FIG_W-2*PAD LOG_H], ...
            'FontSize',9,'FontColor',app.clr_black);
    end

    function buildStatusTab(app, PAD, FIG_W, TAB_H)
        app.RefreshStatusBtn = uibutton(app.StatusTab,'push','Text','⟳  Refresh', ...
            'Position',[PAD TAB_H-56 110 32],'FontSize',10, ...
            'BackgroundColor',app.clr_btn, ...
            'ButtonPushedFcn', @(~,~) RefreshStatusButtonPushed(app));

        app.StatusTable = uitable(app.StatusTab, ...
            'Position',[PAD PAD FIG_W-2*PAD TAB_H-70], ...
            'RowName',{},'ColumnEditable',false);
    end

    function buildMeasureButtons(app)
        COMB_H  = app.layout_meas_h;
        FIG_W   = 940;  PAD = 8;
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

        for m = 1:app.n_meas
            y_m = 0.99 - m*(app.meas_h + app.meas_gap) + app.meas_gap;
            app.h_meas_btns(m) = uibutton(app.MeasuresPanel,'push', ...
                'Text',app.MEASURES(m).name, ...
                'Position',[round(0.01*panel_w) round(y_m*COMB_H) round(0.14*panel_w) round(app.meas_h*COMB_H)], ...
                'FontSize',13,'FontWeight','bold','BackgroundColor',app.clr_btn, ...
                'UserData',m, ...
                'ButtonPushedFcn', @(src,~) MeasureButtonPushed(app, src));
        end

        % Gold divider
        uipanel(app.MeasuresPanel,'BorderType','none','BackgroundColor',app.clr_gold, ...
            'Position',[round(0.155*panel_w) round(0.02*COMB_H) round(0.003*panel_w) round(0.94*COMB_H)]);

        for m = 1:app.n_meas
            y_m  = 0.99 - m*(app.meas_h + app.meas_gap) + app.meas_gap;
            subs = app.MEASURES(m).subtypes;
            app.h_sub_btns{m} = gobjects(1, max(1,numel(subs)));
            if ~isempty(subs)
                sub_w = 0.81 / numel(subs);
                for k = 1:numel(subs)
                    app.h_sub_btns{m}(k) = uibutton(app.MeasuresPanel,'push', ...
                        'Text',subs{k}, ...
                        'Position',[round((0.17+(k-1)*sub_w)*panel_w) round(y_m*COMB_H) round(sub_w*0.97*panel_w) round(app.meas_h*COMB_H)], ...
                        'FontSize',12,'BackgroundColor',app.clr_btn,'Visible','off', ...
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

        % Switch to Analysis tab so the user sees output as it runs
        app.TabGroup.SelectedTab = app.AnalysisTab;
        app.AnalysisLogArea.Value = {''};
        drawnow;

        delete(app);
        clc;
        analysis_run(ROOTdir, Chins2Run, Conds2Run, chinroster_filename, ...
            sheet, plot_relative_flag, reanalyze, EXPname, EXPname2, show_figs);
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
        item_h = max(18, min(28, floor((0.78 * ROW2_H - 8) / n)));
        for ci = 1:n
            y_pos = ROW2_H - 24 - ci * (item_h + 2);
            app.h_cond_checks(ci) = uicheckbox(app.ConditionsPanel, ...
                'Text',labels{ci},'Value',true, ...
                'Position',[10 y_pos 160 item_h], ...
                'FontSize',10);
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
        grid_top = 0.95 * ph;
        grid_bot = 0.23 * ph;
        item_h   = min(22, (grid_top - grid_bot) / max(n_rows,1));

        app.h_subj_checks = gobjects(1, n);
        for ii = 1:n
            row = ceil(ii / n_cols) - 1;
            col = mod(ii - 1, n_cols);
            x = 4 + col * item_w;
            y = grid_top - (row + 1) * item_h;
            app.h_subj_checks(ii) = uicheckbox(app.SubjectsPanel, ...
                'Text',subjs{ii},'Value',logical(checked(ii)), ...
                'Position',[x y item_w item_h], ...
                'FontSize',9);
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
        meas_w_norm = 0.14;  FIG_W = 940; PAD = 8; panel_w = FIG_W - 2*PAD;
        y_sel = 0.99 - m*(app.meas_h + app.meas_gap) + app.meas_gap;
        if ~isempty(subs)
            title_y = max(round((y_sel - 0.10)*COMB_H), round(0.55*COMB_H));
            body_h  = max(round(0.04*COMB_H), title_y - round(0.05*COMB_H));
            app.DescTitleLabel.Text = sprintf('%s (%s): %s', app.MEASURES(m).label, app.MEASURES(m).name, subs{k});
        else
            title_y = round((y_sel + app.meas_h - 0.09)*COMB_H);
            body_h  = max(round(0.04*COMB_H), title_y - round(0.03*COMB_H));
            app.DescTitleLabel.Text = sprintf('%s (%s)', app.MEASURES(m).label, app.MEASURES(m).name);
        end
        app.DescLabel.Text = app.MEASURES(m).descriptions{k};
        app.DescTitleLabel.Position(2) = title_y;
        app.DescLabel.Position(4)      = body_h;
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

    % ── Data status table ──────────────────────────────────────────────────

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
            'ABR-T', fullfile('ABR','%s','%s'),            '*ABRthresholds*.mat'; ...
            'ABR-P', fullfile('ABR','%s','%s'),            '*ABRpeaks_dtw*.mat'; ...
            'RAM',   fullfile('EFR','%s','%s'),            '*EFR_RAM*.mat'; ...
            'dAM',   fullfile('EFR','%s','%s'),            '*EFR_dAM*.mat'; ...
            'DP',    fullfile('OAE','DPOAE','%s','%s'),    '*DPOAE*.mat'; ...
            'SF',    fullfile('OAE','SFOAE','%s','%s'),    '*SFOAE*.mat'; ...
            'TE',    fullfile('OAE','TEOAE','%s','%s'),    '*TEOAE*.mat'; ...
            'MEMR',  fullfile('MEMR','%s','%s'),           '*MEMR*.mat'; ...
        };
        tbl_data = cell(n_s, n_c);
        has_data = false(n_s, n_c);
        for si = 1:n_s
            for ci = 1:n_c
                parts = {};
                for mi = 1:size(modalities,1)
                    fdir = fullfile(analysis_dir, sprintf(modalities{mi,2}, subjs{si}, conds{ci}));
                    hits = dir(fullfile(fdir, modalities{mi,3}));
                    hits = hits(~strncmp({hits.name},'._',2));
                    if ~isempty(hits), parts{end+1} = modalities{mi,1}; end %#ok<AGROW>
                end
                tbl_data{si,ci} = ternary(isempty(parts), '—', strjoin(parts,' '));
                has_data(si,ci) = ~isempty(parts);
            end
        end

        col_names = [{'Subject'}, labels(:)'];
        tbl_full  = [subjs(:), tbl_data];
        app.StatusTable.Data        = tbl_full;
        app.StatusTable.ColumnName  = col_names;
        app.StatusTable.ColumnWidth = repmat({110}, 1, n_c+1);

        clr_done  = [0.85 0.76 0.50];
        clr_empty = [0.88 0.88 0.88];
        for si = 1:n_s
            for ci = 1:n_c
                s_obj = uistyle('BackgroundColor', ...
                    clr_done * has_data(si,ci) + clr_empty * ~has_data(si,ci));
                addStyle(app.StatusTable, s_obj, 'cell', [si, ci+1]);
            end
        end
    end

end % private methods

% ══════════════════════════════════════════════════════════════════════════
%  STATIC UTILITY FUNCTIONS (file-scope equivalents)
% ══════════════════════════════════════════════════════════════════════════
methods (Static, Access = private)

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
        createComponents(app)
        registerApp(app, app.UIFigure)
        runStartupFcn(app, @startupFcn)
        if nargout == 0
            clear app
        end
    end

    function delete(app)
        if isvalid(app.UIFigure), delete(app.UIFigure); end
    end

end % public methods

end % classdef


% ── Inline ternary helper ─────────────────────────────────────────────────
function out = ternary(cond, a, b)
if cond, out = a; else, out = b; end
end
