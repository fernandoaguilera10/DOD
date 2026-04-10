function analysis_launcher()
close all; clear all; clc;
%ANALYSIS_LAUNCHER  Unified GUI launcher for the DOD analysis pipeline.
%
%  Run this file in MATLAB to open the launcher. Select your profile,
%  set the root directory, load the chinroster, pick an analysis type,
%  and click Run.
%
%  ── Adding a new analysis measure ────────────────────────────────────────
%  Append one entry to the MEASURES struct below. No other changes needed.
%  ─────────────────────────────────────────────────────────────────────────

clc;

%% ── Measures config ──────────────────────────────────────────────────────
%  name         : short identifier used in analysis_run (must match existing code)
%  label        : full descriptive name shown in the GUI
%  subtypes     : cell array of sub-analysis options (empty = none)
%  descriptions : one description per subtype (or one entry for measures with no subtypes)
MEASURES(1) = struct('name','ABR',  'label','Auditory Brainstem Response', 'subtypes', {{'Thresholds','Peaks'}}, ...
    'descriptions', {{
        ['Estimates hearing thresholds across click and pure-tone frequencies. ' ...
         'Uses a bootstrapped cross-correlation method and fits a sigmoid to the ' ...
         'normalized ABR amplitude-vs-level function to extract threshold.'], ...
        ['Detects Wave I–V peaks and troughs using Dynamic Time Warping (DTW) ' ...
         'against a reference template. Quantifies peak-to-peak amplitudes and ' ...
         'absolute latencies across stimulus levels and frequencies.']
    }});
MEASURES(2) = struct('name','EFR',  'label','Envelope Following Response',  'subtypes', {{'dAM','RAM'}}, ...
    'descriptions', {{
        ['Measures neural responses to a modulated stimulus using dynamic amplitude modulation (dAM) ' ...
         'to assess temporal encoding up to 1.5 kHz.'], ...
        ['Measures neural responses to a modulated stimulus using rectangular amplitude modulation (RAM). Phase ' ...
         'Locking Value (PLV) captures subcortical synchrony up to the 16th harmonic of the modulation frequency.']
    }});
MEASURES(3) = struct('name','OAE',  'label','Otoacoustic Emissions',        'subtypes', {{'DPOAE','SFOAE','TEOAE'}}, ...
    'descriptions', {{
        ['Estimates distortion product otoacoustic emmision (DPOAE) amplitude elicited using a two-tone UPWARD sweep paradigm. '...
         'Implemented forward pressure level (FPL) calibration for accurate in-ear stimulus presentation levels.'], ...
        ['Estimates stimulus frequency otoacoustic emmision (SFOAE) amplitude elicited using a two-tone DOWNWARD sweep paradigm. '...
         'Implemented forward pressure level (FPL) calibration for accurate in-ear stimulus presentation levels.'], ...
        ['Estimates transient evoked otoacoustic emmision (TEOAE) amplitude elicited using a click stimulus. '...
         'Implemented forward pressure level (FPL) calibration for accurate in-ear stimulus presentation levels.']
    }});
MEASURES(4) = struct('name','MEMR', 'label','Middle Ear Muscle Reflex',     'subtypes', {{}}, ...
    'descriptions', {{
        ['Measures wideband acoustic reflex by tracking changes in absorbed ' ... 
         'sound power (dB) across frequencies in response to a broadband elicitor ' ...
         'at multiple levels. Characterizes growth functions and reflex thresholds.']
    }});
%% ─────────────────────────────────────────────────────────────────────────

%% ── UI text ──────────────────────────────────────────────────────────────
txt_win_title    = 'Auditory Physiology Analysis Toolkit (APAT)';
txt_header_title = 'Auditory Physiology Analysis Toolkit (APAT)';
txt_header_sub   = 'Auditory Neurophysiology and Modeling Lab  —  Purdue University';
txt_run_btn      = 'Run Analysis';
%% ─────────────────────────────────────────────────────────────────────────

%% ── Purdue palette ───────────────────────────────────────────────────────
clr_black   = [0.08 0.08 0.08];
clr_gold    = [0.81 0.73 0.57];
clr_gold_dk = [0.55 0.42 0.12];
clr_bg      = [0.97 0.96 0.93];
clr_panel   = [0.93 0.91 0.87];
clr_btn     = [0.86 0.84 0.79];

%% ── User store ────────────────────────────────────────────────────────
code_dir     = fileparts(mfilename('fullpath'));
profile_file = fullfile(code_dir, 'private', 'user_profiles.mat');
[profiles, last_user] = load_profiles(profile_file);

%% ── GUI state ────────────────────────────────────────────────────────────
state.measure_idx  = 1;
state.subtype_idx  = 1;
state.sheet        = '';
state.conds_all    = {};   % full paths  e.g. {pre/Baseline, post/D7, ...}
state.cond_labels  = {};   % display labels e.g. {'Baseline','D7', ...}

% Subject checkbox grid (created dynamically)
h_subj_checks = gobjects(0);
subj_ids      = {};

%% ── Figure ───────────────────────────────────────────────────────────────
PAD    = 8;
FIG_W  = 940;
HDR_H  = 70;
ROW1_H = 140;
ROW2_H = 215;
ROW3_H = 155;
ROW4_H = 105;
FIG_H  = HDR_H + ROW1_H + ROW2_H + ROW3_H + ROW4_H + 6*PAD;

scr = get(0,'ScreenSize');
fig = figure('Name',txt_win_title,'NumberTitle','off', ...
    'Position',[round((scr(3)-FIG_W)/2) round((scr(4)-FIG_H)/2) FIG_W FIG_H], ...
    'MenuBar','none','ToolBar','none','Resize','off','Color',clr_bg, ...
    'CloseRequestFcn',@on_close);

row4_y = PAD;
row3_y = row4_y + ROW4_H + PAD;
row2_y = row3_y + ROW3_H + PAD;
row1_y = row2_y + ROW2_H + PAD;
hdr_y  = row1_y + ROW1_H + PAD;

%% ── Header ───────────────────────────────────────────────────────────────
hp = uipanel(fig,'BorderType','none','BackgroundColor',clr_black, ...
    'Units','pixels','Position',[0 hdr_y FIG_W HDR_H]);
uicontrol(hp,'Style','text','String',txt_header_title, ...
    'Units','normalized','Position',[0.02 0.48 0.70 0.44], ...
    'HorizontalAlignment','left','FontSize',17,'FontWeight','bold', ...
    'ForegroundColor',clr_gold,'BackgroundColor',clr_black);
uicontrol(hp,'Style','text','String',txt_header_sub, ...
    'Units','normalized','Position',[0.02 0.06 0.70 0.36], ...
    'HorizontalAlignment','left','FontSize',9.5, ...
    'ForegroundColor',[0.88 0.84 0.74],'BackgroundColor',clr_black);
uicontrol(hp,'Style','pushbutton','String','Data Status', ...
    'Units','normalized','Position',[0.52 0.12 0.20 0.76], ...
    'FontSize',12,'FontWeight','bold', ...
    'ForegroundColor',clr_black,'BackgroundColor',clr_btn, ...
    'Callback',@on_status);
uicontrol(hp,'Style','pushbutton','String',txt_run_btn, ...
    'Units','normalized','Position',[0.75 0.12 0.22 0.76], ...
    'FontSize',14,'FontWeight','bold', ...
    'ForegroundColor',clr_black,'BackgroundColor',clr_gold, ...
    'Callback',@on_run);

%% ── Row 1: User | Project Settings ───────────────────────────────────
pp = uipanel(fig,'Title','User','FontSize',9,'FontWeight','bold', ...
    'BackgroundColor',clr_panel,'HighlightColor',clr_gold, ...
    'Units','pixels','Position',[PAD row1_y 200 ROW1_H]);

profile_names = fieldnames(profiles);
if isempty(profile_names), profile_names = {'(no profiles)'}; end
h_profile_popup = uicontrol(pp,'Style','popupmenu','String',profile_names, ...
    'Units','normalized','Position',[0.05 0.68 0.90 0.23], ...
    'FontSize',11,'FontWeight','bold','BackgroundColor','white', ...
    'Callback',@on_profile_select);
uicontrol(pp,'Style','pushbutton','String','New User', ...
    'Units','normalized','Position',[0.05 0.40 0.90 0.23], ...
    'FontSize',9,'BackgroundColor',clr_btn,'Callback',@on_new_profile);
uicontrol(pp,'Style','pushbutton','String','Save User', ...
    'Units','normalized','Position',[0.05 0.13 0.90 0.23], ...
    'FontSize',9,'BackgroundColor',clr_btn,'Callback',@on_save_profile);

% Project settings panel
sp_x = PAD + 200 + PAD;
sp_w = FIG_W - sp_x - PAD;
sp = uipanel(fig,'Title','Project Settings','FontSize',9,'FontWeight','bold', ...
    'BackgroundColor',clr_panel,'HighlightColor',clr_gold, ...
    'Units','pixels','Position',[sp_x row1_y sp_w ROW1_H]);

uicontrol(sp,'Style','text','String','Root Directory:', ...
    'Units','normalized','Position',[0.01 0.74 0.14 0.17], ...
    'HorizontalAlignment','left','FontSize',9,'BackgroundColor',clr_panel);
h_rootdir = uicontrol(sp,'Style','edit','String','', ...
    'Units','normalized','Position',[0.16 0.73 0.63 0.20], ...
    'HorizontalAlignment','left','FontSize',9,'BackgroundColor','white');
uicontrol(sp,'Style','pushbutton','String','Browse...', ...
    'Units','normalized','Position',[0.80 0.72 0.10 0.22], ...
    'FontSize',9,'BackgroundColor',clr_btn,'Callback',@on_browse_rootdir);

uicontrol(sp,'Style','text','String','Subject Roster:', ...
    'Units','normalized','Position',[0.01 0.48 0.14 0.17], ...
    'HorizontalAlignment','left','FontSize',9,'BackgroundColor',clr_panel);
h_chinroster = uicontrol(sp,'Style','popupmenu','String',{'(set root directory first)'}, ...
    'Units','normalized','Position',[0.16 0.46 0.60 0.22], ...
    'FontSize',9,'BackgroundColor','white', ...
    'Callback',@on_chinroster_change);

uicontrol(sp,'Style','text','String','Experiment:', ...
    'Units','normalized','Position',[0.01 0.20 0.13 0.17], ...
    'HorizontalAlignment','left','FontSize',9,'BackgroundColor',clr_panel);
h_sheet_popup = uicontrol(sp,'Style','popupmenu','String',{'(load chinroster first)'}, ...
    'Units','normalized','Position',[0.15 0.17 0.35 0.22], ...
    'FontSize',10,'FontWeight','bold','BackgroundColor','white', ...
    'Callback',@on_sheet_change);

%% ── Row 2: Subjects | Conditions | Options ───────────────────────────────
subj_w   = round((FIG_W - 3*PAD) * 0.55);
right_w  = FIG_W - 3*PAD - subj_w;          % total right-side width
opt_w2   = 185;                              % Options panel width in row 2
cond_w   = right_w - PAD - opt_w2;          % Conditions gets the rest

subj_p = uipanel(fig,'Title','Subjects','FontSize',9,'FontWeight','bold', ...
    'BackgroundColor',clr_panel,'HighlightColor',clr_gold, ...
    'Units','pixels','Position',[PAD row2_y subj_w ROW2_H]);
% Subject checkboxes are built dynamically by set_subj_checks()
uicontrol(subj_p,'Style','pushbutton','String','Select All', ...
    'Units','normalized','Position',[0.02 0.02 0.31 0.18], ...
    'FontSize',8.5,'BackgroundColor',clr_btn,'Callback',@on_select_all_subj);
uicontrol(subj_p,'Style','pushbutton','String','Clear', ...
    'Units','normalized','Position',[0.35 0.02 0.31 0.18], ...
    'FontSize',8.5,'BackgroundColor',clr_btn,'Callback',@on_clear_subj);
uicontrol(subj_p,'Style','pushbutton','String','Refresh', ...
    'Units','normalized','Position',[0.68 0.02 0.30 0.18], ...
    'FontSize',8.5,'BackgroundColor',clr_btn,'Callback',@(~,~) load_chinroster());

cond_p = uipanel(fig,'Title','Conditions','FontSize',9,'FontWeight','bold', ...
    'BackgroundColor',clr_panel,'HighlightColor',clr_gold, ...
    'Units','pixels','Position',[PAD+subj_w+PAD row2_y cond_w ROW2_H]);
h_cond_checks = [];

% Options panel — placed to the right of Conditions in Row 2
opt_x2 = PAD + subj_w + PAD + cond_w + PAD;
opt_p = uipanel(fig,'Title','Options','FontSize',9,'FontWeight','bold', ...
    'BackgroundColor',clr_panel,'HighlightColor',clr_gold, ...
    'Units','pixels','Position',[opt_x2 row2_y opt_w2 ROW2_H]);
h_reanalyze = uicontrol(opt_p,'Style','checkbox','String','Re-analyze existing data', ...
    'Units','normalized','Position',[0.05 0.82 0.90 0.13], ...
    'FontSize',9,'Value',1,'BackgroundColor',clr_panel);
h_relative = uicontrol(opt_p,'Style','checkbox','String','Plot relative to Baseline', ...
    'Units','normalized','Position',[0.05 0.66 0.90 0.13], ...
    'FontSize',9,'Value',0,'BackgroundColor',clr_panel);
h_show_analysis = uicontrol(opt_p,'Style','checkbox','String','Show analysis figures', ...
    'Units','normalized','Position',[0.05 0.50 0.90 0.13], ...
    'FontSize',9,'Value',0,'BackgroundColor',clr_panel);
h_show_ind = uicontrol(opt_p,'Style','checkbox','String','Show individual plots', ...
    'Units','normalized','Position',[0.05 0.34 0.90 0.13], ...
    'FontSize',9,'Value',1,'BackgroundColor',clr_panel);
h_show_avg = uicontrol(opt_p,'Style','checkbox','String','Show average plots', ...
    'Units','normalized','Position',[0.05 0.18 0.90 0.13], ...
    'FontSize',9,'Value',1,'BackgroundColor',clr_panel);

%% ── Row 3+4: Auditory Measures (merged panel — buttons + description) ────
COMB_H = ROW3_H + PAD + ROW4_H;   % 268 px
anal_p = uipanel(fig,'Title','Auditory Measures','FontSize',9,'FontWeight','bold', ...
    'BackgroundColor',clr_panel,'HighlightColor',clr_gold, ...
    'Units','pixels','Position',[PAD row4_y FIG_W-2*PAD COMB_H]);

% ── Left sidebar: measure selector (stacked) ─────────────────────────────
n_meas   = length(MEASURES);
meas_w   = 0.14;   % sidebar width
meas_h   = 0.22;   % each button height
meas_gap = 0.02;   % gap between buttons

h_meas_btns = gobjects(1, n_meas);
h_sub_btns  = cell(1, n_meas);
for m = 1:n_meas
    y_m = 0.99 - m*(meas_h + meas_gap) + meas_gap;
    h_meas_btns(m) = uicontrol(anal_p,'Style','pushbutton', ...
        'String',MEASURES(m).name, ...
        'Units','normalized','Position',[0.01 y_m meas_w meas_h], ...
        'FontSize',13,'FontWeight','bold','BackgroundColor',clr_btn, ...
        'UserData',m,'Callback',@on_measure_select);
end

% ── Thin gold divider ─────────────────────────────────────────────────────
uipanel(anal_p,'BorderType','none','BackgroundColor',clr_gold, ...
    'Units','normalized','Position',[0.155 0.02 0.003 0.94]);

% ── Right content: subtype buttons aligned to their measure row ───────────
for m = 1:n_meas
    y_m = 0.99 - m*(meas_h + meas_gap) + meas_gap;
    subs = MEASURES(m).subtypes;
    h_sub_btns{m} = gobjects(1, max(1,length(subs)));
    if ~isempty(subs)
        sub_w = 0.81 / length(subs);
        for k = 1:length(subs)
            h_sub_btns{m}(k) = uicontrol(anal_p,'Style','pushbutton', ...
                'String',subs{k}, ...
                'Units','normalized', ...
                'Position',[0.17+(k-1)*sub_w y_m sub_w*0.97 meas_h], ...
                'FontSize',12,'BackgroundColor',clr_btn,'Visible','off', ...
                'UserData',[m k],'Callback',@on_subtype_select);
        end
    end
end

% ── Description placeholders (positions set dynamically in refresh) ───────
h_desc_title = uicontrol(anal_p,'Style','text','String','', ...
    'Units','normalized','Position',[0.17 0.60 0.81 0.09], ...
    'HorizontalAlignment','left','FontSize',9,'FontWeight','bold', ...
    'ForegroundColor',clr_black,'BackgroundColor',clr_panel);
h_desc = uicontrol(anal_p,'Style','text','String','', ...
    'Units','normalized','Position',[0.17 0.05 0.81 0.51], ...
    'HorizontalAlignment','left','FontSize',9,'FontAngle','italic', ...
    'ForegroundColor',clr_gold_dk,'BackgroundColor',clr_panel);


%% ── Initialise ───────────────────────────────────────────────────────────
refresh_measure_buttons();

all_pnames = fieldnames(profiles);
if ~isempty(last_user) && isfield(profiles, last_user)
    idx = find(strcmp(all_pnames, last_user), 1);
    set(h_profile_popup,'Value',idx);
    load_profile_to_gui(last_user);
elseif ~isempty(all_pnames) && ~strcmp(all_pnames{1},'(no profiles)')
    load_profile_to_gui(all_pnames{1});
end

uiwait(fig);


%% ══════════════════════════════════════════════════════════════════════════
%%  CALLBACKS
%% ══════════════════════════════════════════════════════════════════════════

    function on_close(~,~)
        delete(fig);
    end

    % ── User ────────────────────────────────────────────────────────────

    function on_profile_select(~,~)
        pname = get_current_profile_name();
        if ~isempty(pname), load_profile_to_gui(pname); end
    end

    function on_new_profile(~,~)
        answer = inputdlg({'Enter your initials (e.g. FA):','Full name (optional):'}, ...
            'New User',1,{'',''});
        if isempty(answer) || isempty(strtrim(answer{1})), return; end
        initials = upper(strtrim(answer{1}));
        if ~isvarname(initials)
            errordlg('Initials must be letters only (e.g. FA).','Invalid Initials','modal');
            return
        end
        profiles.(initials).name                = strtrim(answer{2});
        profiles.(initials).ROOTdir_mac         = '';
        profiles.(initials).ROOTdir_win         = '';
        profiles.(initials).chinroster_filename = 'DOD_ChinRoster.xlsx';
        profiles.(initials).last_sheet          = '';
        profiles.(initials).reanalyze           = 1;
        profiles.(initials).plot_relative_flag  = 0;
        pnames = fieldnames(profiles);
        set(h_profile_popup,'String',pnames,'Value',find(strcmp(pnames,initials)));
        load_profile_to_gui(initials);
    end

    function on_save_profile(~,~)
        pname = get_current_profile_name();
        if isempty(pname), return; end
        save_current_to_profile(pname);
        save_profiles_to_file();
        msgbox(sprintf('User "%s" saved.',pname),'Saved','help','modal');
    end

    % ── Project settings ───────────────────────────────────────────────────

    function on_browse_rootdir(~,~)
        d = uigetdir(get(h_rootdir,'String'),'Select Root Directory (DOD folder)');
        if isequal(d,0), return; end
        set(h_rootdir,'String',d);
        scan_chinroster_files('');
    end

    function on_chinroster_change(~,~)
        load_chinroster();
    end

    function on_sheet_change(~,~)
        sheets = get(h_sheet_popup,'String');
        idx    = get(h_sheet_popup,'Value');
        new_sheet = sheets{idx};
        if strcmp(new_sheet,'(load chinroster first)') || strcmp(new_sheet,'(file not found)'), return; end
        state.sheet = new_sheet;
        % Re-read subjects and conditions for the new sheet
        rootdir  = strtrim(get(h_rootdir,'String'));
        chinfile = strtrim(get(h_chinroster,'String'));
        if isempty(rootdir) || isempty(chinfile), return; end
        filepath = fullfile(rootdir,'Analysis',chinfile);
        if exist(filepath,'file')
            refresh_from_chinroster(filepath);
        end
    end

    % ── Subjects ───────────────────────────────────────────────────────────

    function on_select_all_subj(~,~)
        for ii = 1:numel(h_subj_checks)
            if ishandle(h_subj_checks(ii)), set(h_subj_checks(ii),'Value',1); end
        end
    end

    function on_clear_subj(~,~)
        for ii = 1:numel(h_subj_checks)
            if ishandle(h_subj_checks(ii)), set(h_subj_checks(ii),'Value',0); end
        end
    end

    % ── Analysis type ──────────────────────────────────────────────────────

    function on_measure_select(src,~)
        state.measure_idx = src.UserData;
        state.subtype_idx = 1;
        refresh_measure_buttons();
    end

    function on_subtype_select(src,~)
        ud = src.UserData;
        state.measure_idx = ud(1);
        state.subtype_idx = ud(2);
        refresh_measure_buttons();
    end

    % ── Run ────────────────────────────────────────────────────────────────

    function on_run(~,~)
        ROOTdir = strtrim(get(h_rootdir,'String'));
        if isempty(ROOTdir)
            errordlg('Root directory is required.','Missing Field','modal'); return
        end
        if isempty(state.sheet) || isempty(state.conds_all)
            errordlg('Load the chinroster and select an experiment first.','Not Ready','modal'); return
        end
        Chins2Run = get_checked_subjects();
        if isempty(Chins2Run)
            errordlg('Select at least one subject.','No Subjects','modal'); return
        end
        cond_sel = false(1, numel(h_cond_checks));
        for ci = 1:numel(h_cond_checks)
            cond_sel(ci) = logical(get(h_cond_checks(ci),'Value'));
        end
        if ~any(cond_sel)
            errordlg('Select at least one condition.','No Conditions','modal'); return
        end
        Conds2Run = state.conds_all(cond_sel);

        EXPname  = MEASURES(state.measure_idx).name;
        subs     = MEASURES(state.measure_idx).subtypes;
        EXPname2 = [];
        if ~isempty(subs), EXPname2 = subs{state.subtype_idx}; end

        chin_names = get(h_chinroster,'String');
        chin_idx   = get(h_chinroster,'Value');
        chinroster_filename = chin_names{chin_idx};
        reanalyze           = get(h_reanalyze,'Value');
        plot_relative_flag  = get(h_relative,'Value');

        pname = get_current_profile_name();
        if ~isempty(pname)
            save_current_to_profile(pname);
            last_user = pname;
            save_profiles_to_file();
        end
        save_last_settings(Chins2Run, Conds2Run);

        show_figs.analysis = logical(get(h_show_analysis,'Value'));
        show_figs.ind      = logical(get(h_show_ind,'Value'));
        show_figs.avg      = logical(get(h_show_avg,'Value'));

        close(fig);
        clc;
        analysis_run(ROOTdir, Chins2Run, Conds2Run, chinroster_filename, state.sheet, plot_relative_flag, reanalyze, EXPname, EXPname2, show_figs);
    end


%% ══════════════════════════════════════════════════════════════════════════
%%  HELPER FUNCTIONS
%% ══════════════════════════════════════════════════════════════════════════

    function scan_chinroster_files(preferred_name)
        % Populate h_chinroster popup with Excel files found in Analysis/
        rootdir = strtrim(get(h_rootdir,'String'));
        if isempty(rootdir), return; end
        analysis_dir = fullfile(rootdir,'Analysis');
        if ~exist(analysis_dir,'dir')
            set(h_chinroster,'String',{'(Analysis folder not found)'},'Value',1);
            return
        end
        files = [dir(fullfile(analysis_dir,'*.xlsx')); dir(fullfile(analysis_dir,'*.xls'))];
        % Exclude macOS resource fork files (._filename)
        files = files(~strncmp({files.name},'._',2));
        if isempty(files)
            set(h_chinroster,'String',{'(no Excel files found)'},'Value',1);
            return
        end
        names = {files.name};
        % Restore preferred selection if provided, otherwise keep first
        idx = find(strcmp(names, preferred_name), 1);
        if isempty(idx), idx = 1; end
        set(h_chinroster,'String',names,'Value',idx);
        load_chinroster();
    end

    function load_chinroster()
        rootdir = strtrim(get(h_rootdir,'String'));
        if isempty(rootdir), return; end
        names = get(h_chinroster,'String');
        idx   = get(h_chinroster,'Value');
        if ~iscell(names), names = {names}; end
        chinfile = names{idx};
        % Skip placeholder entries
        if chinfile(1) == '(', return; end
        filepath = fullfile(rootdir,'Analysis',chinfile);
        if ~exist(filepath,'file')
            set(h_sheet_popup,'String',{'(file not found)'},'Value',1);
            set_subj_checks({}, []);
            refresh_conditions();
            return
        end
        % Read sheet names
        try
            sheets = cellstr(sheetnames(filepath));
        catch
            set(h_sheet_popup,'String',{'(error reading file)'},'Value',1);
            return
        end
        % Restore last-used sheet if available, otherwise use first
        cur_idx = find(strcmp(sheets, state.sheet), 1);
        if isempty(cur_idx), cur_idx = 1; end
        set(h_sheet_popup,'String',sheets,'Value',cur_idx);
        state.sheet = sheets{cur_idx};
        refresh_from_chinroster(filepath);
    end

    function refresh_from_chinroster(filepath)
        [subjects, state.conds_all, state.cond_labels] = ...
            read_chinroster_sheet(filepath, state.sheet);
        set_subj_checks(subjects, true(numel(subjects),1));
        refresh_conditions();
        load_last_settings();
    end

    function refresh_conditions()
        if ~isempty(h_cond_checks) && all(ishandle(h_cond_checks))
            delete(h_cond_checks);
            h_cond_checks = [];
        end
        labels = state.cond_labels;
        n      = numel(labels);
        if n == 0, return; end
        h_cond_checks = gobjects(1,n);
        item_h = 0.78 / n;
        for ci = 1:n
            h_cond_checks(ci) = uicontrol(cond_p,'Style','checkbox', ...
                'String',labels{ci},'Value',1, ...
                'Units','normalized', ...
                'Position',[0.08 0.93-ci*item_h 0.84 item_h*0.88], ...
                'FontSize',10,'BackgroundColor',clr_panel);
        end
    end

    function refresh_measure_buttons()
        m = state.measure_idx;
        k = state.subtype_idx;
        % y of selected measure button (same formula as layout)
        y_sel = 0.99 - m*(meas_h + meas_gap) + meas_gap;

        for mi = 1:n_meas
            if mi == m
                set(h_meas_btns(mi),'BackgroundColor',clr_gold,'ForegroundColor',clr_black);
            else
                set(h_meas_btns(mi),'BackgroundColor',clr_btn,'ForegroundColor',clr_black);
            end
            for ki = 1:numel(MEASURES(mi).subtypes)
                if mi == m
                    set(h_sub_btns{mi}(ki),'Visible','on');
                    if ki == k
                        set(h_sub_btns{mi}(ki),'BackgroundColor',clr_gold_dk,'ForegroundColor','white');
                    else
                        set(h_sub_btns{mi}(ki),'BackgroundColor',clr_btn,'ForegroundColor',clr_black);
                    end
                else
                    set(h_sub_btns{mi}(ki),'Visible','off');
                end
            end
        end

        subs = MEASURES(m).subtypes;
        if ~isempty(subs)
            % Description anchored just below the selected measure row
            title_y = y_sel - 0.10;
            body_h  = max(0.04, title_y - 0.03);
            set(h_desc_title,'String',sprintf('%s (%s): %s', MEASURES(m).label, MEASURES(m).name, subs{k}));
            set(h_desc,      'String',MEASURES(m).descriptions{k});
        else
            % No subtypes: description starts at the top of the measure row
            title_y = y_sel + meas_h - 0.09;
            body_h  = max(0.04, title_y - 0.03);
            set(h_desc_title,'String',sprintf('%s (%s)', MEASURES(m).label, MEASURES(m).name));
            set(h_desc,      'String',MEASURES(m).descriptions{1});
        end
        set(h_desc_title,'Position',[0.17 title_y  0.81 0.09]);
        set(h_desc,      'Position',[0.17 0.02      0.81 body_h]);
    end

    function pname = get_current_profile_name()
        pnames = get(h_profile_popup,'String');
        idx    = get(h_profile_popup,'Value');
        if iscell(pnames) && ~strcmp(pnames{1},'(no profiles)')
            pname = pnames{idx};
        else
            pname = '';
        end
    end

    function load_profile_to_gui(pname)
        if ~isfield(profiles,pname), return; end
        p = profiles.(pname);
        if ismac
            if isfield(p,'ROOTdir_mac'), set(h_rootdir,'String',p.ROOTdir_mac); end
        else
            if isfield(p,'ROOTdir_win'), set(h_rootdir,'String',p.ROOTdir_win); end
        end
        if isfield(p,'last_sheet'), state.sheet = p.last_sheet; end
        if isfield(p,'reanalyze'),          set(h_reanalyze,'Value',p.reanalyze);         end
        if isfield(p,'plot_relative_flag'), set(h_relative, 'Value',p.plot_relative_flag); end
        % Scan for chinroster files and restore last-used selection
        preferred = '';
        if isfield(p,'chinroster_filename'), preferred = p.chinroster_filename; end
        scan_chinroster_files(preferred);
    end

    function save_current_to_profile(pname)
        if ismac
            profiles.(pname).ROOTdir_mac = strtrim(get(h_rootdir,'String'));
        else
            profiles.(pname).ROOTdir_win = strtrim(get(h_rootdir,'String'));
        end
        names = get(h_chinroster,'String');
        idx   = get(h_chinroster,'Value');
        if iscell(names) && names{idx}(1) ~= '('
            profiles.(pname).chinroster_filename = names{idx};
        end
        profiles.(pname).last_sheet          = state.sheet;
        profiles.(pname).reanalyze           = get(h_reanalyze,'Value');
        profiles.(pname).plot_relative_flag  = get(h_relative,'Value');
    end

    function save_profiles_to_file()
        save(profile_file,'profiles','last_user');
    end

    function set_subj_checks(subjs, checked)
        % Delete old checkboxes
        valid = h_subj_checks(ishandle(h_subj_checks));
        if ~isempty(valid), delete(valid); end
        h_subj_checks = gobjects(0);
        subj_ids      = {};
        if isempty(subjs), return; end

        subjs   = subjs(:);
        checked = checked(:);
        n       = numel(subjs);
        subj_ids = subjs;

        % Grid layout (pixel-based)
        pp  = getpixelposition(subj_p);
        pw  = pp(3) - 14;          % usable panel width
        ph  = pp(4);
        item_w  = 68;              % px per checkbox cell
        n_cols  = max(1, floor(pw / item_w));
        n_rows  = ceil(n / n_cols);
        grid_top = 0.95 * ph;      % top of grid area (normalized px)
        grid_bot = 0.23 * ph;      % bottom of grid area
        item_h   = min(22, (grid_top - grid_bot) / n_rows);

        h_subj_checks = gobjects(1, n);
        for ii = 1:n
            row = ceil(ii / n_cols) - 1;
            col = mod(ii - 1, n_cols);
            x = (col * item_w) / pp(3);
            y = (grid_top - (row + 1)*item_h) / ph;
            w = item_w / pp(3);
            h = item_h / ph;
            h_subj_checks(ii) = uicontrol(subj_p,'Style','checkbox', ...
                'String',subjs{ii},'Value',checked(ii), ...
                'Units','normalized','Position',[x y w h], ...
                'FontSize',9,'BackgroundColor',clr_panel);
        end
    end

    function subjs = get_checked_subjects()
        subjs = {};
        for ii = 1:numel(h_subj_checks)
            if ishandle(h_subj_checks(ii)) && get(h_subj_checks(ii),'Value')
                subjs{end+1} = subj_ids{ii}; %#ok<AGROW>
            end
        end
        subjs = subjs(:);
    end

    % ── Last-used settings ─────────────────────────────────────────────────

    function save_last_settings(Chins2Run_sel, Conds2Run_sel)
        ROOTdir = strtrim(get(h_rootdir,'String'));
        if isempty(ROOTdir), return; end
        settings_file = fullfile(ROOTdir,'Analysis','launcher_last_settings.mat');
        last_settings.Chins2Run       = Chins2Run_sel;
        last_settings.Conds2Run       = Conds2Run_sel;
        last_settings.reanalyze       = get(h_reanalyze,'Value');
        last_settings.plot_relative   = get(h_relative,'Value');
        last_settings.show_analysis   = get(h_show_analysis,'Value');
        last_settings.show_ind        = get(h_show_ind,'Value');
        last_settings.show_avg        = get(h_show_avg,'Value');
        last_settings.measure_idx     = state.measure_idx;
        last_settings.subtype_idx     = state.subtype_idx;
        try, save(settings_file,'last_settings'); catch, end
    end

    function load_last_settings()
        ROOTdir = strtrim(get(h_rootdir,'String'));
        if isempty(ROOTdir), return; end
        settings_file = fullfile(ROOTdir,'Analysis','launcher_last_settings.mat');
        if ~exist(settings_file,'file'), return; end
        try, tmp = load(settings_file,'last_settings'); catch, return; end
        s = tmp.last_settings;
        % Restore checkboxes
        if isfield(s,'reanalyze'),     set(h_reanalyze,    'Value',s.reanalyze);     end
        if isfield(s,'plot_relative'), set(h_relative,     'Value',s.plot_relative); end
        if isfield(s,'show_analysis'), set(h_show_analysis,'Value',s.show_analysis); end
        if isfield(s,'show_ind'),      set(h_show_ind,     'Value',s.show_ind);      end
        if isfield(s,'show_avg'),      set(h_show_avg,     'Value',s.show_avg);      end
        % Restore measure/subtype selection
        if isfield(s,'measure_idx') && s.measure_idx >= 1 && s.measure_idx <= length(MEASURES)
            state.measure_idx = s.measure_idx;
        end
        if isfield(s,'subtype_idx'), state.subtype_idx = s.subtype_idx; end
        refresh_measure_buttons();
        % Restore subject selections (match by name)
        if isfield(s,'Chins2Run') && ~isempty(s.Chins2Run)
            for ii = 1:numel(h_subj_checks)
                if ishandle(h_subj_checks(ii))
                    sid = subj_ids{ii};
                    set(h_subj_checks(ii),'Value', any(strcmp(s.Chins2Run, sid)));
                end
            end
        end
        % Restore condition selections (match by name)
        if isfield(s,'Conds2Run') && ~isempty(s.Conds2Run)
            for ci = 1:numel(h_cond_checks)
                if ishandle(h_cond_checks(ci))
                    cpath = state.conds_all{ci};
                    set(h_cond_checks(ci),'Value', any(strcmp(s.Conds2Run, cpath)));
                end
            end
        end
    end

    % ── Data status table ──────────────────────────────────────────────────

    function on_status(~,~)
        ROOTdir = strtrim(get(h_rootdir,'String'));
        if isempty(ROOTdir)
            msgbox('Set the root directory first.','Data Status','warn'); return
        end
        if isempty(subj_ids) || isempty(state.conds_all)
            msgbox('Load the chinroster first.','Data Status','warn'); return
        end
        analysis_dir = fullfile(ROOTdir,'Analysis');
        subjs  = subj_ids;
        conds  = state.conds_all;
        labels = state.cond_labels;
        n_s = numel(subjs);
        n_c = numel(conds);

        % Build cell table: each cell is a string of abbreviations for present modalities
        modalities = { ...
            'ABR-T', fullfile('ABR','%s','%s'), '*ABRthresholds*.mat'; ...
            'ABR-P', fullfile('ABR','%s','%s'), '*ABRpeaks_dtw*.mat'; ...
            'RAM',   fullfile('EFR','%s','%s'), '*EFR_RAM*.mat'; ...
            'dAM',   fullfile('EFR','%s','%s'), '*EFR_dAM*.mat'; ...
            'DP',    fullfile('OAE','DPOAE','%s','%s'), '*DPOAE*.mat'; ...
            'SF',    fullfile('OAE','SFOAE','%s','%s'), '*SFOAE*.mat'; ...
            'TE',    fullfile('OAE','TEOAE','%s','%s'), '*TEOAE*.mat'; ...
            'MEMR',  fullfile('MEMR','%s','%s'), '*MEMR*.mat'; ...
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
                if isempty(parts)
                    tbl_data{si,ci} = '—';
                else
                    tbl_data{si,ci} = strjoin(parts,' ');
                    has_data(si,ci) = true;
                end
            end
        end

        % Open status figure
        sf = uifigure('Name','Data Analysis Status','Position',[100 100 min(1400,200+n_c*120) min(800,80+n_s*30)]);
        col_names = [{'Subject'}, labels(:)'];
        tbl_full  = [subjs(:), tbl_data];
        uit = uitable(sf,'Data',tbl_full,'ColumnName',col_names, ...
            'Units','normalized','Position',[0 0 1 1], ...
            'ColumnWidth',repmat({110},1,n_c+1), ...
            'RowName',{});
        % Style: gold for cells with data, grey for empty
        clr_done  = [0.85 0.76 0.50];
        clr_empty = [0.88 0.88 0.88];
        for si = 1:n_s
            for ci = 1:n_c
                s_obj = uistyle('BackgroundColor', clr_done * has_data(si,ci) + clr_empty * ~has_data(si,ci));
                addStyle(uit, s_obj, 'cell', [si, ci+1]);
            end
        end
    end

end


%% ══════════════════════════════════════════════════════════════════════════
%%  FILE-SCOPE UTILITIES
%% ══════════════════════════════════════════════════════════════════════════

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
%READ_CHINROSTER_SHEET  Extract subjects and conditions from one chinroster sheet.
subjects    = {};
cond_paths  = {};
cond_labels = {};
try
    data = readcell(filepath,'Sheet',sheet);
catch
    return
end
% Replace missing values
miss_idx = cellfun(@(x) any(isa(x,'missing')), data);
data(miss_idx) = {NaN};
[nrows, ncols] = size(data);

% Find header row: the row containing 'Baseline' or 'B'
header_row   = 0;
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

% Extract condition labels from the first modality block
if header_row > 0 && ~isempty(baseline_cols)
    c1 = baseline_cols(1);
    c2 = ncols;
    if numel(baseline_cols) >= 2
        c2 = baseline_cols(2) - 1;
    end
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

% Extract subjects: col 1 strings that contain at least one digit
% (excludes column headers like 'Subject', 'Animal', 'Sex', etc.)
for i = 1:nrows
    if i == header_row, continue; end
    val = data{i,1};
    if ischar(val) && ~isempty(strtrim(val)) && ~isempty(regexp(strtrim(val),'\d','once'))
        subjects{end+1} = strtrim(val); %#ok<AGROW>
    end
end
subjects = subjects(:);
end

