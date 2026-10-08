function createComponents(app)
%CREATECOMPONENTS  Build all UI components for APAT_app.
%   Creates the figure window, black header bar, and three tabs:
%   Setup, Results, Status. Each tab is built by a local function.

app.clr_black   = [0.08 0.08 0.08];
app.clr_gold    = [0.81 0.73 0.57];
app.clr_gold_dk = [0.55 0.42 0.12];
app.clr_bg      = [0.97 0.96 0.93];
app.clr_panel   = [0.93 0.91 0.87];
app.clr_btn     = [0.86 0.84 0.79];

PAD   = 8;
HDR_H = 110;

app.UIFigure = uifigure( ...
    'Name','Auditory Physiology Analysis Toolkit (APAT)', ...
    'Color',app.clr_bg, ...
    'AutoResizeChildren','on', ...
    'CloseRequestFcn',@(~,~) delete(app));

% Size the window to the screen's usable area (excludes the menu bar and
% Dock/taskbar, wherever they are) and lay out against its real drawable
% area. WindowState='maximized' was unreliable on macOS (it could settle
% late, and the fallback ignored a side Dock).
% After the initial layout, AutoResizeChildren rescales every component
% proportionally if the window is resized or moved to another monitor.
[FIG_W, FIG_H] = usable_figure_size(app.UIFigure);
TAB_H = FIG_H - HDR_H;

% ── Header ─────────────────────────────────────────────────────────────
app.HeaderPanel = uipanel(app.UIFigure, ...
    'BorderType','none','BackgroundColor',app.clr_black, ...
    'Position',[0 FIG_H-HDR_H FIG_W HDR_H]);

app.TitleLabel = uilabel(app.HeaderPanel, ...
    'Text','Auditory Physiology Analysis Toolkit (APAT)', ...
    'Position',[16 54 FIG_W-250 36], ...
    'FontSize',26,'FontWeight','bold','FontColor',app.clr_gold);

app.SubtitleLabel = uilabel(app.HeaderPanel, ...
    'Text','Auditory Neurophysiology and Modeling Lab  —  Purdue University', ...
    'Position',[16 30 FIG_W-250 22], ...
    'FontSize',15,'FontColor',[0.88 0.84 0.74]);

% Run Analysis lives in the Setup tab's Run Summary card. The header keeps
% the run-time controls (Stop, spinner, progress) so they stay reachable
% from every tab while an analysis is running.
RUN_W = 260;  RUN_H = 46;
RUN_X  = FIG_W - RUN_W - 16;
RUN_Y  = round((HDR_H - RUN_H) / 2);
STOP_W = 120;  STOP_H = RUN_H;
SPIN_W = 30;   SPIN_H = 30;
LBL_H  = 16;
STOP_X = FIG_W - STOP_W - 16;
SPIN_X = STOP_X - SPIN_W - 10;
SPIN_Y = RUN_Y + round((RUN_H - SPIN_H) / 2);
LBL_Y  = RUN_Y - LBL_H - 3;

app.StopButton = uibutton(app.HeaderPanel,'push', ...
    'Text','■  Stop', ...
    'Position',[STOP_X RUN_Y STOP_W STOP_H], ...
    'FontSize',16,'FontWeight','bold', ...
    'FontColor',app.clr_black,'BackgroundColor',[0.78 0.28 0.28], ...
    'Visible','off','Enable','on', ...
    'ButtonPushedFcn',@(~,~) StopButtonPushed(app));

app.h_spinner_label = uilabel(app.HeaderPanel, ...
    'Text','','FontSize',18,'FontColor',app.clr_gold, ...
    'HorizontalAlignment','center', ...
    'Position',[SPIN_X SPIN_Y SPIN_W SPIN_H],'Visible','off');

app.h_progress_label = uilabel(app.HeaderPanel, ...
    'Text','','FontSize',10,'FontColor',[0.78 0.74 0.64], ...
    'HorizontalAlignment','center', ...
    'Position',[RUN_X LBL_Y RUN_W LBL_H],'Visible','off');

app.spinner_frame   = 1;
app.abort_requested = false;

% ── Tab group ────────────────────────────────────────────────────────────
app.TabGroup = uitabgroup(app.UIFigure,'Position',[0 0 FIG_W TAB_H]);
app.SetupTab   = uitab(app.TabGroup,'Title','  Setup  ');
app.ResultsTab = uitab(app.TabGroup,'Title','  Results  ');
app.StatusTab  = uitab(app.TabGroup,'Title','  Data Status  ');
app.SetupTab.BackgroundColor   = app.clr_bg;
app.ResultsTab.BackgroundColor = app.clr_bg;
app.StatusTab.BackgroundColor  = app.clr_bg;

buildSetupTab(app,   PAD, FIG_W, TAB_H);
buildResultsTab(app, PAD, FIG_W, TAB_H);
buildStatusTab(app,  PAD, FIG_W, TAB_H);
buildPeakEditPanel(app, FIG_W, TAB_H);

% If the window manager applied the window size after we measured it, the
% layout no longer matches the window (e.g. an empty band at the top).
% Snap the window back to the laid-out size, keeping its top edge fixed.
drawnow;
p_now = app.UIFigure.Position;
if abs(p_now(3)-FIG_W) > 2 || abs(p_now(4)-FIG_H) > 2
    % AutoResize off for this one change: the children already have the
    % laid-out positions and must not be rescaled.
    app.UIFigure.AutoResizeChildren = 'off';
    app.UIFigure.Position = [p_now(1), p_now(2) + p_now(4) - FIG_H, FIG_W, FIG_H];
    drawnow;
    app.UIFigure.AutoResizeChildren = 'on';
end
end


function [w, h] = usable_figure_size(fig)
%USABLE_FIGURE_SIZE  Fit the window to the screen's usable area and return
%   its drawable width/height in pixels.
%   The usable area comes from Java's getMaximumWindowBounds, which excludes
%   the macOS menu bar and Dock (bottom, left or right) and the Windows
%   taskbar. If Java is unavailable, a conservative margin is used instead.
scr = get(0,'ScreenSize');            % [1 1 W H], origin bottom-left
wa  = [];
try
    ge = java.awt.GraphicsEnvironment.getLocalGraphicsEnvironment();
    b  = ge.getMaximumWindowBounds(); % origin top-left, same units as ScreenSize
    wa = [b.getX()+1, scr(4)-(b.getY()+b.getHeight())+1, ...
          b.getWidth(), b.getHeight()];
catch
end
if isempty(wa) || wa(3) < 600 || wa(4) < 400
    % Fallback: leave room for a menu bar (top) and a Dock on any side
    m  = 80;
    wa = [1+m, 1+m, scr(3)-2*m, scr(4)-m-40];
end
fig.WindowState   = 'normal';
fig.OuterPosition = wa;               % OuterPosition includes the title bar

% Wait for the window manager to apply the size, then read the drawable area
prev = [0 0];
for k = 1:20                          % ≤ ~2 s
    drawnow; pause(0.1);
    p = fig.Position(3:4);
    if k > 2 && isequal(p, prev), break; end
    prev = p;
end
w = p(1);  h = p(2);
end


% ══════════════════════════════════════════════════════════════════════════
%  TAB BUILDERS
% ══════════════════════════════════════════════════════════════════════════

function buildSetupTab(app, PAD, FIG_W, TAB_H)
FS  = 15;
CH  = 30;
LH  = 24;

ROW1_H = 4*CH + 2*PAD + 20;
ROW2_H = 5*CH + 2*PAD + 20;
MEAS_H = max(100, TAB_H - 30 - PAD - ROW1_H - PAD - ROW2_H - PAD - PAD);

app.layout_row2_h = ROW2_H;
app.layout_meas_h = MEAS_H;

meas_y = PAD;
row2_y = meas_y + MEAS_H + PAD;
row1_y = row2_y + ROW2_H + PAD;

USER_W = 240;
SP_X   = PAD + USER_W + PAD;
SP_W   = FIG_W - SP_X - PAD;

% ── User panel ──────────────────────────────────────────────────────────
% 1. Create the panel with universal properties
app.UserPanel = uipanel(app.SetupTab, ... 
    'Title','User','FontSize',FS,'FontWeight','bold', ... 
    'BackgroundColor',app.clr_panel, ... 
    'Position', [PAD row1_y USER_W ROW1_H]);

% 2. Safely apply BorderColor ONLY if supported (R2023a+)
% This prevents the "Functionality not supported" error
if isprop(app.UserPanel, 'BorderColor')
    app.UserPanel.BorderColor = app.clr_gold;
end

inner_w = USER_W - 22;
y3 = ROW1_H - 30 - CH;
y2 = y3 - PAD - CH;
y1 = y2 - PAD - CH;
app.ProfileDropdown = uidropdown(app.UserPanel, ...
    'Items',{'(no profiles)'},'Value','(no profiles)', ...
    'Position',[8 y3 inner_w CH], ...
    'FontSize',FS,'FontWeight','bold', ...
    'ValueChangedFcn',@(~,~) ProfileDropdownChanged(app));
app.NewUserBtn = uibutton(app.UserPanel,'push','Text','New User', ...
    'Position',[8 y2 inner_w CH],'FontSize',FS,'BackgroundColor',app.clr_btn, ...
    'ButtonPushedFcn',@(~,~) NewUserButtonPushed(app));
app.SaveUserBtn = uibutton(app.UserPanel,'push','Text','Save User', ...
    'Position',[8 y1 inner_w CH],'FontSize',FS,'BackgroundColor',app.clr_btn, ...
    'ButtonPushedFcn',@(~,~) SaveUserButtonPushed(app));

% ── Project settings panel ──────────────────────────────────────────────
% 1. Create the panel without the BorderColor property
app.ProjectPanel = uipanel(app.SetupTab, ...
    'Title','Project Settings','FontSize',FS,'FontWeight','bold', ...
    'BackgroundColor',app.clr_panel, ...
    'Position',[SP_X row1_y SP_W ROW1_H]);

% 2. Apply the color only if the current MATLAB version supports it
if isprop(app.ProjectPanel, 'BorderColor')
    app.ProjectPanel.BorderColor = app.clr_gold;
end

LBL_W  = 140;  CTRL_X = LBL_W + 8;
% Controls sized to their content; the space on the right shows live
% project status (folders found, roster contents).
STAT_W = max(0, min(420, SP_W - CTRL_X - 14 - 560));
CTRL_W = SP_W - CTRL_X - 14 - STAT_W - (STAT_W>0)*16;
DIR_W  = min(CTRL_W - 104, 640);
py3 = ROW1_H - 30 - CH;
py2 = py3 - PAD - CH;
py1 = py2 - PAD - CH;
uilabel(app.ProjectPanel,'Text','Root Directory:', ...
    'Position',[8 py3 LBL_W LH],'FontSize',FS);
app.RootDirField = uieditfield(app.ProjectPanel,'text','Value','', ...
    'Position',[CTRL_X py3 DIR_W CH],'FontSize',FS,'BackgroundColor','white', ...
    'ValueChangedFcn',@(~,~) chinroster_ops(app,'scan',''));
app.BrowseBtn = uibutton(app.ProjectPanel,'push','Text','Browse...', ...
    'Position',[CTRL_X+DIR_W+6 py3 96 CH],'FontSize',FS,'BackgroundColor',app.clr_btn, ...
    'ButtonPushedFcn',@(~,~) BrowseButtonPushed(app));
uilabel(app.ProjectPanel,'Text','Subject Roster:', ...
    'Position',[8 py2 LBL_W LH],'FontSize',FS);
app.RosterDropdown = uidropdown(app.ProjectPanel, ...
    'Items',{'(set root directory first)'},'Value','(set root directory first)', ...
    'Position',[CTRL_X py2 min(CTRL_W, 380) CH],'FontSize',FS, ...
    'ValueChangedFcn',@(~,~) RosterDropdownChanged(app));
uilabel(app.ProjectPanel,'Text','Experiment:', ...
    'Position',[8 py1 LBL_W LH],'FontSize',FS);
app.SheetDropdown = uidropdown(app.ProjectPanel, ...
    'Items',{'(load chinroster first)'},'Value','(load chinroster first)', ...
    'Position',[CTRL_X py1 min(CTRL_W, 240) CH], ...
    'FontSize',FS+1,'FontWeight','bold', ...
    'ValueChangedFcn',@(~,~) SheetDropdownChanged(app));

% Project status column (filled by update_summary)
app.h_summary_proj = gobjects(0);
if STAT_W > 0
    stat_x = SP_W - 14 - STAT_W;
    uipanel(app.ProjectPanel,'BorderType','none','BackgroundColor',app.clr_gold, ...
        'Position',[stat_x-10 py1 2 py3+CH-py1]);
    app.h_summary_proj = gobjects(1,3);
    for si = 1:3
        yy = [py3 py2 py1];
        app.h_summary_proj(si) = uilabel(app.ProjectPanel,'Text','', ...
            'FontSize',FS-1,'Interpreter','html', ...
            'Position',[stat_x yy(si) STAT_W CH]);
    end
end

% ── Subjects panel ──────────────────────────────────────────────────────
subj_w  = round((FIG_W - 3*PAD) * 0.55);
right_w = FIG_W - 3*PAD - subj_w;
opt_w2  = max(300, round(right_w * 0.46));   % wide enough for option titles
cond_w  = right_w - PAD - opt_w2;

app.SubjectsPanel = uipanel(app.SetupTab, ...
    'Title','Subjects','FontSize',FS,'FontWeight','bold', ...
    'BackgroundColor',app.clr_panel, ...
    'Position',[PAD row2_y subj_w ROW2_H]);
if isprop(app.SubjectsPanel, 'BorderColor')
    app.SubjectsPanel.BorderColor = app.clr_gold;
end

IN2 = ROW2_H - 28;              % drawable height below the panel titles
SMALL_H = 28;
app.layout_row2_in = IN2;

% Bottom strip: compact action buttons (left) + selection badge (right)
sb = {'Select All','SelectAllBtn',@(~,~) SelectAllButtonPushed(app); ...
      'Clear',     'ClearSubjBtn',@(~,~) ClearButtonPushed(app); ...
      '⟳ Refresh', 'RefreshSubjBtn',@(~,~) RefreshButtonPushed(app)};
for bi = 1:3
    app.(sb{bi,2}) = uibutton(app.SubjectsPanel,'push','Text',sb{bi,1}, ...
        'Position',[PAD+(bi-1)*(104+6) 6 104 SMALL_H],'FontSize',FS-2,'FontWeight','bold', ...
        'BackgroundColor',app.clr_btn,'ButtonPushedFcn',sb{bi,3});
end
app.h_row2_badges = gobjects(1,2);
app.h_row2_badges(1) = uilabel(app.SubjectsPanel,'Text','','FontSize',FS-2, ...
    'FontWeight','bold','FontColor',app.clr_gold_dk,'HorizontalAlignment','right', ...
    'Position',[subj_w-16-220 6 220 SMALL_H]);
% thin rule above the strip
uipanel(app.SubjectsPanel,'BorderType','none','BackgroundColor',app.clr_gold, ...
    'Position',[PAD 6+SMALL_H+5 subj_w-2*PAD-4 1]);

% ── Conditions panel ────────────────────────────────────────────────────
app.ConditionsPanel = uipanel(app.SetupTab, ...
    'Title','Conditions','FontSize',FS,'FontWeight','bold', ...
    'BackgroundColor',app.clr_panel, ...
    'Position',[PAD+subj_w+PAD row2_y cond_w ROW2_H]);
if isprop(app.ConditionsPanel, 'BorderColor')
    app.ConditionsPanel.BorderColor = app.clr_gold;
end
app.h_row2_badges(2) = uilabel(app.ConditionsPanel,'Text','','FontSize',FS-2, ...
    'FontWeight','bold','FontColor',app.clr_gold_dk,'HorizontalAlignment','right', ...
    'Position',[cond_w-16-200 6 200 SMALL_H]);
uilabel(app.ConditionsPanel,'Text','Click to include / exclude','FontSize',FS-4, ...
    'FontColor',[0.5 0.5 0.5],'Position',[PAD 6 200 SMALL_H]);
uipanel(app.ConditionsPanel,'BorderType','none','BackgroundColor',app.clr_gold, ...
    'Position',[PAD 6+SMALL_H+5 cond_w-2*PAD-4 1]);

% ── Options panel: two option cards with ON/OFF pills ────────────────────
opt_x = PAD + subj_w + PAD + cond_w + PAD;
app.OptionsPanel = uipanel(app.SetupTab, ...
    'Title','Options','FontSize',FS,'FontWeight','bold', ...
    'BackgroundColor',app.clr_panel, ...
    'Position',[opt_x row2_y opt_w2 ROW2_H]);
if isprop(app.OptionsPanel, 'BorderColor')
    app.OptionsPanel.BorderColor = app.clr_gold;
end

opt_def = {'ReanalyzeCheck',    'Re-analyze data',      'Recompute even if results exist',  true; ...
           'PlotRelativeCheck', 'Relative to Baseline', 'Plot changes vs. Baseline',         false; ...
           'BlindCheck',        'Blind mode',           'Hide subject & condition while analysing', false};
n_opt    = size(opt_def,1);
card_gap = 6;
card_h   = floor((IN2 - (n_opt+1)*card_gap) / n_opt);
card_w   = opt_w2 - 2*PAD - 4;
PILL_W = 58;  PILL_H = 28;
for oi = 1:n_opt
    cy = IN2 - oi*(card_h + card_gap);
    card = uipanel(app.OptionsPanel,'BorderType','none','BackgroundColor',app.clr_bg, ...
        'Position',[PAD cy card_w card_h]);
    uipanel(card,'BorderType','none','BackgroundColor',app.clr_gold, ...
        'Position',[0 0 4 card_h]);                         % gold accent bar
    txt_w = card_w - PILL_W - 26;
    mid = round(card_h/2);
    uilabel(card,'Text',opt_def{oi,2},'FontSize',FS-1,'FontWeight','bold', ...
        'FontColor',app.clr_black,'Position',[14 mid-1 txt_w 20], ...
        'Tooltip',opt_def{oi,3});
    uilabel(card,'Text',opt_def{oi,3},'FontSize',FS-4, ...
        'FontColor',[0.45 0.45 0.45],'Position',[14 mid-17 txt_w 16], ...
        'Tooltip',opt_def{oi,3});
    app.(opt_def{oi,1}) = uibutton(card,'state','Text','ON','Value',opt_def{oi,4}, ...
        'FontSize',FS-2,'FontWeight','bold', ...
        'Position',[card_w-PILL_W-10 round((card_h-PILL_H)/2) PILL_W PILL_H], ...
        'ValueChangedFcn',@(~,~) update_summary(app));
end

% ── Auditory Measures panel ──────────────────────────────────────────────
% Layout (left → right):
%   [measure buttons] | [subtype buttons (top row) + parameter panel below] | [About card + Run Summary card]
app.MeasuresPanel = uipanel(app.SetupTab, ...
    'Title','Auditory Measures','FontSize',FS,'FontWeight','bold', ...
    'BackgroundColor',app.clr_panel, ...
    'Position',[PAD meas_y FIG_W-2*PAD MEAS_H]);
if isprop(app.MeasuresPanel, 'BorderColor')
    app.MeasuresPanel.BorderColor = app.clr_gold;
end

panel_w = FIG_W - 2*PAD;
MEAS_IN = MEAS_H - 30;            % drawable height below the panel title
app.layout_meas_h = MEAS_IN;
MID_END = round(0.60 * panel_w);  % right edge of the subtype/parameter column
RIGHT_X = MID_END + 12;
RIGHT_W = panel_w - RIGHT_X - 12;

app.h_meas_btns = gobjects(0);
app.h_sub_btns  = {};
[SUB_X, TOP_Y] = buildMeasureButtons(app, panel_w, MEAS_IN, MID_END);

% Parameter panels fill the column under the subtype buttons
PARAM_POS = [SUB_X 6 MID_END-SUB_X max(120, TOP_Y-14)];
buildParamPanels(app, PARAM_POS, FS, LH);

% ── About card (description of the selected analysis) ────────────────────
ABOUT_H = round(0.40 * MEAS_IN);
about = uipanel(app.MeasuresPanel,'Title','About this analysis', ...
    'FontSize',FS-1,'FontWeight','bold','BackgroundColor',app.clr_bg, ...
    'Position',[RIGHT_X MEAS_IN-ABOUT_H-2 RIGHT_W ABOUT_H]);
if isprop(about,'BorderColor'), about.BorderColor = app.clr_gold; end
ab_in = ABOUT_H - 28;
app.DescTitleLabel = uilabel(about,'Text','', 'WordWrap','on', ...
    'Position',[10 ab_in-26 RIGHT_W-20 24], ...
    'FontSize',FS,'FontWeight','bold','FontColor',app.clr_black);
app.DescLabel = uilabel(about,'Text','', 'WordWrap','on', ...
    'VerticalAlignment','top', ...
    'Position',[10 4 RIGHT_W-20 max(20, ab_in-34)], ...
    'FontSize',FS-2,'FontColor',app.clr_gold_dk);

% ── Run Summary card (live overview of what Run Analysis will do) ────────
SUM_H = MEAS_IN - ABOUT_H - 12;
sp = uipanel(app.MeasuresPanel,'Title','Run Summary', ...
    'FontSize',FS-1,'FontWeight','bold','BackgroundColor',app.clr_bg, ...
    'Position',[RIGHT_X 6 RIGHT_W SUM_H]);
if isprop(sp,'BorderColor'), sp.BorderColor = app.clr_gold; end
sum_in  = SUM_H - 28;
TILE_H  = min(62, max(44, round(0.42*sum_in)));
RUNB_W  = max(150, round(0.30*(RIGHT_W - 20)));
tile_w  = floor((RIGHT_W - 20 - RUNB_W - 3*8) / 3);
tile_y  = sum_in - TILE_H - 4;
app.RunButton = uibutton(sp,'push', ...
    'Text','▶  Run Analysis', ...
    'Position',[RIGHT_W-10-RUNB_W tile_y RUNB_W TILE_H], ...
    'FontSize',17,'FontWeight','bold', ...
    'FontColor',app.clr_black,'BackgroundColor',app.clr_gold, ...
    'ButtonPushedFcn',@(~,~) RunButtonPushed(app));
tile_caps = {'Subjects','Conditions','Datasets'};
S = struct();
S.tiles = gobjects(1,3);
for ti = 1:3
    tp = uipanel(sp,'BorderType','none','BackgroundColor',app.clr_black, ...
        'Position',[10+(ti-1)*(tile_w+8) tile_y tile_w TILE_H]);
    S.tiles(ti) = uilabel(tp,'Text','0','FontSize',24,'FontWeight','bold', ...
        'FontColor',app.clr_gold,'HorizontalAlignment','center', ...
        'Position',[0 18 tile_w TILE_H-20]);
    uilabel(tp,'Text',upper(tile_caps{ti}),'FontSize',10,'FontWeight','bold', ...
        'FontColor',[0.80 0.76 0.66],'HorizontalAlignment','center', ...
        'Position',[0 2 tile_w 16]);
end
line_h = 20;
ly = tile_y - 6 - line_h;
S.lines = gobjects(1,3);
for li = 1:3
    S.lines(li) = uilabel(sp,'Text','','FontSize',FS-3, ...
        'FontColor',app.clr_black,'Interpreter','html', ...
        'Position',[10 ly RIGHT_W-20 line_h]);
    ly = ly - line_h;
end
S.proj = app.h_summary_proj;   % project-status labels built in the Project panel
app.h_summary = S;
end


function [SUB_X, TOP_Y] = buildMeasureButtons(app, panel_w, MEAS_IN, MID_END)
%BUILDMEASUREBUTTONS  Measure buttons (left column) + subtype buttons (top row
%   of the middle column). Rows are laid out inside the panel's drawable area
%   (below its title) so the title is never covered.
app.n_meas   = length(app.MEASURES);
app.meas_h   = 0.22;
app.meas_gap = 0.02;

MEAS_BTN_W = max(110, min(150, round(0.12*panel_w)));
app.h_meas_btns = gobjects(1, app.n_meas);
app.h_sub_btns  = cell(1, app.n_meas);
row_h = round(app.meas_h*MEAS_IN);
for m = 1:app.n_meas
    y_m = 0.99 - m*(app.meas_h + app.meas_gap) + app.meas_gap;
    app.h_meas_btns(m) = uibutton(app.MeasuresPanel,'push', ...
        'Text',app.MEASURES(m).name, ...
        'Position',[round(0.01*panel_w) round(y_m*MEAS_IN) MEAS_BTN_W row_h], ...
        'FontSize',20,'FontWeight','bold','BackgroundColor',app.clr_btn, ...
        'UserData',m, ...
        'ButtonPushedFcn',@(src,~) MeasureButtonPushed(app, src));
end

% Gold vertical divider
div_x = round(0.01*panel_w) + MEAS_BTN_W + 6;
uipanel(app.MeasuresPanel,'BorderType','none','BackgroundColor',app.clr_gold, ...
    'Position',[div_x 6 3 MEAS_IN-8]);

% Subtype buttons — always on the top row of the middle column
SUB_X = div_x + 12;
app.meas_sub_area_start = SUB_X;
TOP_Y = round((0.99 - app.meas_h) * MEAS_IN);
for m = 1:app.n_meas
    subs = app.MEASURES(m).subtypes;
    app.h_sub_btns{m} = gobjects(1, max(1,numel(subs)));
    if ~isempty(subs)
        sub_area_px = MID_END - SUB_X;
        sub_btn_w   = min(240, floor(sub_area_px / numel(subs)) - 6);
        for k = 1:numel(subs)
            app.h_sub_btns{m}(k) = uibutton(app.MeasuresPanel,'push', ...
                'Text',subs{k}, ...
                'Position',[SUB_X + (k-1)*(sub_btn_w+6) TOP_Y sub_btn_w row_h], ...
                'FontSize',18,'FontWeight','bold','BackgroundColor',app.clr_btn,'Visible','off', ...
                'UserData',[m k], ...
                'ButtonPushedFcn',@(src,~) SubtypeButtonPushed(app, src));
        end
    end
end
end


function buildParamPanels(app, POS, FS, LH)
%BUILDPARAMPANELS  ABR/EFR/OAE/MEMR parameter panels, all at POS (only the
%   selected measure's panel is visible). Content is anchored to the top.
PAD = 12;
IH  = POS(4) - 30;          % inner height (below panel title)
IW  = POS(3) - 2*PAD;
GRY = [0.45 0.45 0.45];

% ── ABR: frequency + wave toggle chips ───────────────────────────────────
app.h_abr_param_panel = mkpanel('ABR Parameters');
chip_h = 32;  gap = 6;
freq_labels = {'Click','0.5 kHz','1 kHz','2 kHz','4 kHz','8 kHz'};
chip_w = min(110, floor((IW - 5*gap) / 6));
y = IH - 6;
uilabel(app.h_abr_param_panel,'Text','Frequencies','FontSize',FS,'FontWeight','bold', ...
    'Position',[PAD y-LH IW LH]);
y = y - LH - 4 - chip_h;
app.h_abr_freq_checks = gobjects(1, numel(freq_labels));
for fi = 1:numel(freq_labels)
    app.h_abr_freq_checks(fi) = uibutton(app.h_abr_param_panel,'state', ...
        'Text',freq_labels{fi},'Value',true,'FontSize',FS-1,'FontWeight','bold', ...
        'Position',[PAD+(fi-1)*(chip_w+gap) y chip_w chip_h], ...
        'ValueChangedFcn',@(~,~) update_summary(app));
end
y = y - 14;
uilabel(app.h_abr_param_panel,'Text','Waves','Tag','abr_wave_lbl', ...
    'FontSize',FS,'FontWeight','bold','Position',[PAD y-LH IW LH]);
y = y - LH - 4 - chip_h;
wave_labels = {'Wave I','Wave II','Wave III','Wave IV','Wave V'};
app.h_abr_wave_checks = gobjects(1, numel(wave_labels));
for wi = 1:numel(wave_labels)
    app.h_abr_wave_checks(wi) = uibutton(app.h_abr_param_panel,'state', ...
        'Text',wave_labels{wi},'Value',true,'Tag','abr_wave_ck', ...
        'FontSize',FS-1,'FontWeight','bold', ...
        'Position',[PAD+(wi-1)*(chip_w+gap) y chip_w chip_h], ...
        'ValueChangedFcn',@(~,~) update_summary(app));
end
uilabel(app.h_abr_param_panel,'Tag','abr_wave_lbl', ...
    'Text','All recorded stimulus levels are analysed automatically.', ...
    'FontSize',FS-3,'FontColor',GRY,'Position',[PAD y-LH-2 IW LH]);

% ── EFR ──────────────────────────────────────────────────────────────────
app.h_efr_param_panel = mkpanel('EFR Parameters');
p = app.h_efr_param_panel;
y = IH - 6;
y = textline(p, y, 'RAM — configurable', true, 'efr_ram_hdr');
y = textline(p, y, 'Mod. freq: 223 Hz  |  Filter: 60–4000 Hz', false, 'efr_ram_info');
y = y - 30 - 4;
uilabel(p,'Text','Max harmonics:','Tag','efr_harm_lbl','FontSize',FS-1, ...
    'Position',[PAD y+3 120 LH]);
app.h_efr_harmonics_field = uieditfield(p,'numeric', ...
    'Value',16,'Limits',[1 16],'RoundFractionalValues','on','Tag','efr_harmonics', ...
    'Position',[PAD+122 y 60 30],'FontSize',FS-1,'BackgroundColor','white');
wx = PAD + 122 + 60 + 24;
uilabel(p,'Text','Window (s):','Tag','efr_win_lbl','FontSize',FS-1, ...
    'Position',[wx y+3 92 LH]);
uilabel(p,'Text','start','Tag','efr_win_s_lbl','FontSize',FS-3,'FontColor',GRY, ...
    'Position',[wx+94 y+3 34 LH]);
app.h_efr_window_start_field = uieditfield(p,'numeric', ...
    'Value',0.2,'Limits',[0 2],'Tag','efr_win_start', ...
    'Position',[wx+128 y 56 30],'FontSize',FS-1,'BackgroundColor','white');
uilabel(p,'Text','end','Tag','efr_win_e_lbl','FontSize',FS-3,'FontColor',GRY, ...
    'Position',[wx+190 y+3 28 LH]);
app.h_efr_window_end_field = uieditfield(p,'numeric', ...
    'Value',0.9,'Limits',[0 2],'Tag','efr_win_end', ...
    'Position',[wx+218 y 56 30],'FontSize',FS-1,'BackgroundColor','white');
y = y - 12;
y = textline(p, y, 'dAM — fixed parameters', true, '');
textline(p, y, 'Carrier: 4 kHz  |  AM sweep: 4–10.5 Hz  |  Demod filter: 10–1500 Hz', false, '');

% ── OAE ──────────────────────────────────────────────────────────────────
app.h_oae_param_panel = mkpanel('OAE Parameters');
p = app.h_oae_param_panel;
y = IH - 6;
y = textline(p, y, 'All OAEs use FPL (forward pressure level) calibration', true, '');
y = y - 4;
y = textline(p, y, 'DPOAE — window 0.25 s  |  f2/f1 = 1.2  |  FFT 512 pts  |  upward sweep', false, '');
y = textline(p, y, 'SFOAE — downward frequency sweep', false, '');
textline(p, y, 'TEOAE — click stimulus', false, '');

% ── MEMR ─────────────────────────────────────────────────────────────────
app.h_memr_param_panel = mkpanel('MEMR Parameters');
p = app.h_memr_param_panel;
y = IH - 6;
y = textline(p, y, 'Wideband Middle Ear Muscle Reflex', true, '');
y = y - 4;
y = textline(p, y, 'Frequency range: 0.2–8 kHz', false, '');
y = textline(p, y, 'Metric: Δ absorbed sound power (dB) vs. elicitor level', false, '');
y = textline(p, y, 'Elicitor: broadband noise, multiple levels', false, '');
textline(p, y, 'Output: growth functions and reflex thresholds', false, '');

    function p = mkpanel(title)
        p = uipanel(app.MeasuresPanel,'Title',title,'FontSize',FS,'FontWeight','bold', ...
            'BackgroundColor',app.clr_panel,'Position',POS,'Scrollable','on','Visible','off');
        if isprop(p,'BorderColor'), p.BorderColor = app.clr_gold; end
    end

    function y = textline(p, y, txt, bold, tag)
        if bold, fw = 'bold'; fc = app.clr_black; fs = FS; else, fw = 'normal'; fc = GRY; fs = FS-2; end
        h = uilabel(p,'Text',txt,'FontSize',fs,'FontWeight',fw,'FontColor',fc, ...
            'Position',[PAD y-LH IW LH]);
        if nargin > 4 && ~isempty(tag), h.Tag = tag; end
        y = y - LH - 2;
    end

end


function buildResultsTab(app, ~, FIG_W, TAB_H)
%BUILDRESULTSTAB  Results tab: 8 measure buttons + mode toggle + figure panels.
PAD    = 10;
FS     = 15;
ROW_H  = 46;
CAP_H  = 16;                       % small caption row above each control group
CTRL_H = ROW_H + 2*PAD + CAP_H;
PLOT_H = TAB_H - 30 - CTRL_H;
y1     = PAD;
cap_y  = y1 + ROW_H + 2;

ctrl = uipanel(app.ResultsTab,'BorderType','none', ...
    'BackgroundColor',app.clr_panel,'Position',[0 PLOT_H FIG_W CTRL_H]);
% Gold rule under the control bar (same accent as the Setup cards)
uipanel(ctrl,'BorderType','none','BackgroundColor',app.clr_gold, ...
    'Position',[0 0 FIG_W 2]);

% ── Mode buttons ─────────────────────────────────────────────────────────
x = 2*PAD;
caption(x, 240, 'View');
app.FigAvgBtn = uibutton(ctrl,'state','Text','Average','Value',true, ...
    'FontSize',FS,'FontWeight','bold', ...
    'BackgroundColor',app.clr_gold,'FontColor',app.clr_black, ...
    'Position',[x y1 104 ROW_H], ...
    'ValueChangedFcn',@(~,~) navigate_results(app,'avg'));

x = x + 104 + PAD;
app.FigIndBtn = uibutton(ctrl,'state','Text','Individual','Value',false, ...
    'FontSize',FS,'FontWeight','bold', ...
    'BackgroundColor',app.clr_btn,'FontColor',app.clr_black, ...
    'Position',[x y1 120 ROW_H], ...
    'ValueChangedFcn',@(~,~) navigate_results(app,'ind'));

x = x + 120 + PAD;
app.FigSubjCaption = uilabel(ctrl,'Text','SUBJECT','FontSize',10,'FontWeight','bold', ...
    'FontColor',app.clr_gold_dk,'Position',[x cap_y 90 CAP_H],'Visible','off');
app.FigSubjDropdown = uidropdown(ctrl, ...
    'Items',{'-'},'Value','-', ...
    'FontSize',FS,'Position',[x y1+5 90 ROW_H-10],'Visible','off', ...
    'ValueChangedFcn',@(~,~) navigate_results(app,'subj'));

x = x + 90 + PAD;
% Divider
uipanel(ctrl,'BorderType','none','BackgroundColor',app.clr_gold,'Position',[x y1+4 2 ROW_H-8]);
x = x + 2*PAD;

% ── 8 measure buttons (grouped with thin separators between groups) ─────
labels = APAT_app.measure_tab_labels();
% groups = {1:2, 3:4, 5:7, 8}  — ABR | EFR | OAE | MEMR
groups   = {[1 2],[3 4],[5 6 7],[8]};
BTN_W    = 120;
SHORT_W  = 80;
app.res.btns = gobjects(1, numel(labels));

for gi = 1:numel(groups)
    grp = groups{gi};
    grp_names = {'ABR','EFR','OAE','MEMR'};
    caption(x, 200, grp_names{gi});
    for k = 1:numel(grp)
        idx  = grp(k);
        lbl  = labels{idx};
        bw   = ternary(numel(lbl) <= 5, SHORT_W, BTN_W);
        is_first = (gi==1 && k==1);
        btn = uibutton(ctrl,'push','Text',lbl, ...
            'FontSize',FS-1,'FontWeight','bold', ...
            'BackgroundColor',ternary(is_first,app.clr_gold_dk,app.clr_btn), ...
            'FontColor',ternary(is_first,[1 1 1],app.clr_black), ...
            'Position',[x y1 bw ROW_H], ...
            'UserData',idx, ...
            'ButtonPushedFcn',@(~,~) navigate_results(app,'meas_btn',idx));
        app.res.btns(idx) = btn;
        x = x + bw + PAD;
    end
    % Thin gold divider between groups (not after last)
    if gi < numel(groups)
        uipanel(ctrl,'BorderType','none','BackgroundColor',app.clr_gold, ...
            'Position',[x y1+4 2 ROW_H-8]);
        x = x + PAD + 2;
    end
end

% ── Freq/Cond dropdown ────────────────────────────────────────────────────
x = x + PAD;
uilabel(ctrl,'Tag','fig_freq_lbl','Text','FREQUENCY', ...
    'FontSize',10,'FontWeight','bold','FontColor',app.clr_gold_dk, ...
    'Visible','off','Position',[x cap_y 148 CAP_H]);
app.FigFreqDD = uidropdown(ctrl, ...
    'Items',{'—'},'Value','—', ...
    'FontSize',FS,'Visible','off','Position',[x y1+6 148 ROW_H-12], ...
    'ValueChangedFcn',@(~,~) navigate_results(app,'freq'));

% ── Figure panels: 2 modes × 8 measures (stacked, one visible at a time) ──
N_MEAS = numel(labels);
app.res.panels   = cell(2, N_MEAS);
app.res.subj_data = cell(1, N_MEAS);
for mi = 1:N_MEAS
    app.res.subj_data{mi} = struct('names',{{}},'panels',{{}});
end
for mode = 1:2
    for mi = 1:N_MEAS
        p = uipanel(app.ResultsTab,'BorderType','none','BackgroundColor',app.clr_bg, ...
            'Position',[0 0 FIG_W PLOT_H],'Visible','off');
        if mode == 2
            make_placeholder(p, 'No average figures yet', ...
                'Pick subjects and a measure on the Setup tab, then press Run Analysis.');
        else
            make_placeholder(p, 'No individual figures yet', ...
                'Figures for each subject appear here as the analysis runs.');
        end
        app.res.panels{mode,mi} = p;
    end
end
% Start in Average mode, measure 1 (ABR Thresholds)
app.res.mode     = 2;
app.res.meas_idx = 1;
app.res.panels{2,1}.Visible = 'on';

% ── Blind-mode cover: hides the whole Results tab (subject names, condition
%    tabs, figure titles) during a blinded run until the user unblinds.
%    Created last so it sits above every other Results-tab component.
app.BlindOverlay = uipanel(app.ResultsTab,'BorderType','none', ...
    'BackgroundColor',app.clr_black,'Position',[0 0 FIG_W TAB_H-30],'Visible','off');
CW = 560;  CHh = 190;
bc = uipanel(app.BlindOverlay,'BorderType','line','BackgroundColor',app.clr_panel, ...
    'Position',[round((FIG_W-CW)/2) round((TAB_H-30-CHh)/2) CW CHh]);
if isprop(bc,'BorderColor'), bc.BorderColor = app.clr_gold; end
uipanel(bc,'BorderType','none','BackgroundColor',app.clr_gold_dk,'Position',[0 CHh-6 CW 6]);
uilabel(bc,'Text','Blind mode','FontSize',22,'FontWeight','bold', ...
    'FontColor',app.clr_black,'HorizontalAlignment','center','Position',[10 CHh-52 CW-20 32]);
app.BlindOverlayMsg = uilabel(bc,'Text','', 'FontSize',14,'WordWrap','on', ...
    'FontColor',[0.40 0.40 0.40],'HorizontalAlignment','center', ...
    'Position',[20 70 CW-40 54]);
app.BlindRevealBtn = uibutton(bc,'push','Text','Unblind & show results', ...
    'FontSize',15,'FontWeight','bold','BackgroundColor',app.clr_gold, ...
    'FontColor',app.clr_black,'Enable','off', ...
    'Position',[round((CW-240)/2) 18 240 40], ...
    'ButtonPushedFcn',@(~,~) set(app.BlindOverlay,'Visible','off'));

    function caption(x, w, txt)
        uilabel(ctrl,'Text',upper(txt),'FontSize',10,'FontWeight','bold', ...
            'FontColor',app.clr_gold_dk,'Position',[x cap_y w CAP_H]);
    end

end


function buildStatusTab(app, PAD, FIG_W, TAB_H)
INNER_H = TAB_H - 30;
BTN_H   = 40;
BAR_H   = BTN_H + 2*PAD + 6;
TG_H    = INNER_H - BAR_H;

% Control bar: title + legend + Refresh (same card style as Setup)
bar = uipanel(app.StatusTab,'BorderType','none','BackgroundColor',app.clr_panel, ...
    'Position',[0 TG_H FIG_W BAR_H]);
uipanel(bar,'BorderType','none','BackgroundColor',app.clr_gold,'Position',[0 0 FIG_W 2]);
uilabel(bar,'Text','Data Availability','FontSize',18,'FontWeight','bold', ...
    'FontColor',app.clr_black,'Position',[16 PAD+8 220 26]);
uilabel(bar,'Text','Analysis outputs found per subject and condition', ...
    'FontSize',13,'FontColor',[0.45 0.45 0.45],'Position',[240 PAD+10 340 22]);
leg = {[0.18 0.72 0.42],'Analysed'; [0.97 0.72 0.22],'Other measures only'; [0.82 0.82 0.82],'No data'};
lx = 600;
for li = 1:size(leg,1)
    uipanel(bar,'BorderType','none','BackgroundColor',leg{li,1}, ...
        'Position',[lx PAD+13 16 16]);
    uilabel(bar,'Text',leg{li,2},'FontSize',13,'Position',[lx+22 PAD+10 150 22]);
    lx = lx + 22 + 8 + 9*numel(leg{li,2});
end
app.RefreshStatusBtn = uibutton(bar,'push','Text','⟳  Refresh', ...
    'Position',[FIG_W-16-150 PAD+2 150 BTN_H],'FontSize',16,'FontWeight','bold', ...
    'BackgroundColor',app.clr_gold,'FontColor',app.clr_black, ...
    'ButtonPushedFcn',@(~,~) RefreshStatusButtonPushed(app));

app.StatusInnerTG = uitabgroup(app.StatusTab,'Position',[0 0 FIG_W TG_H]);
end


function buildPeakEditPanel(app, FIG_W, TAB_H)
%BUILDPEAKEDITPANEL  Full-area overlay shown during interactive ABR peak editing.
%   Covers the entire tab region, sits above the TabGroup in z-order.
%   Controlled by findPeaks_dtw via peak_ui struct.
FS    = 15;
PAD   = 12;
BTN_H = 40;
BTN_W = 160;
INFO_H = 32;
WAVE_H = 26;
CTRL_H = BTN_H + WAVE_H + 3*PAD;

% ── Overlay panel ────────────────────────────────────────────────────────
app.PeakEditPanel = uipanel(app.UIFigure, ...
    'BorderType','line', ...
    'BackgroundColor',app.clr_bg, ...
    'Position',[0 0 FIG_W TAB_H], 'Visible','off');
if isprop(app.PeakEditPanel, 'BorderColor')
    app.PeakEditPanel.BorderColor = app.clr_gold;
end

% Layout: the waterfall (left) uses the full panel height; the info line,
% editor axes, tool row, status text and action buttons all live in the
% right-hand column.
WF_W   = round(0.36 * FIG_W);
EDIT_X = PAD + WF_W + 3*PAD;              % generous gap after the waterfall
EDIT_W = FIG_W - EDIT_X - 2*PAD;

% ── Info line (top of the right column) ──────────────────────────────────
app.PeakEditInfoLabel = uilabel(app.PeakEditPanel, ...
    'Text','', 'FontSize',FS, 'FontWeight','bold', 'WordWrap','on', ...
    'FontColor',app.clr_black, 'HorizontalAlignment','center', ...
    'Position',[EDIT_X TAB_H-INFO_H-PAD EDIT_W INFO_H]);

% ── Two axes ─────────────────────────────────────────────────────────────
AX_Y  = CTRL_H + PAD;
AX_H  = TAB_H - INFO_H - 3*PAD - CTRL_H;

app.PeakEditWfAx = uiaxes(app.PeakEditPanel, ...
    'Position',[PAD PAD WF_W TAB_H-2*PAD], 'BackgroundColor','white', 'Box','on');
disableDefaultInteractivity(app.PeakEditWfAx);
title(app.PeakEditWfAx, 'Waveform Stack', 'FontSize',13, 'FontWeight','bold');

app.PeakEditAx = uiaxes(app.PeakEditPanel, ...
    'Position',[EDIT_X AX_Y EDIT_W AX_H], 'BackgroundColor','white', 'Box','on');
disableDefaultInteractivity(app.PeakEditAx);

% ── Control bar (bottom) ─────────────────────────────────────────────────
% Row 1 (y=PAD):       status label (below waterfall) | action buttons (far right)
% Row 2 (y=WAVE_Y):    snap dropdown + wave selector  — starts at EDIT_X,
%                      strictly below the edit axes; never overlaps action buttons
WAVE_Y     = BTN_H + 2*PAD;   % y of top row
WAVE_BTN_W = 32;
BTN_W      = 140;
% Accept / Redo / Cancel take three slots at the right edge; Done (shown
% when they are hidden) sits in the rightmost slot.
btn_x      = FIG_W - 2*PAD - 3*BTN_W - 2*PAD;

% Status label — bottom row of the right column, left of the buttons
app.PeakEditStatusLabel = uilabel(app.PeakEditPanel, ...
    'Text','', 'FontSize',FS-2, 'WordWrap','on', ...
    'Position',[EDIT_X PAD-4 btn_x-EDIT_X-PAD BTN_H+8]);

% Action buttons — bottom row, far right
btn_colors = {[0.60 0.82 0.60], app.clr_btn, app.clr_btn, app.clr_gold};
btn_texts  = {'✓  Accept', '↩  Redo', '✕  Cancel', 'Done  ▶'};
btn_vis    = {'off','off','off','on'};
btn_props  = {'PeakEditAcceptBtn','PeakEditRedoBtn','PeakEditCancelBtn','PeakEditDoneBtn'};
btn_slot   = [1 2 3 3];
for bi = 1:4
    app.(btn_props{bi}) = uibutton(app.PeakEditPanel,'push', ...
        'Text',btn_texts{bi}, 'FontSize',FS-1, 'FontWeight','bold', ...
        'BackgroundColor',btn_colors{bi}, 'Visible',btn_vis{bi}, ...
        'Position',[btn_x+(btn_slot(bi)-1)*(BTN_W+PAD) PAD BTN_W BTN_H]);
end

% Snap ON/OFF toggle — top row, starts at EDIT_X
cx = EDIT_X;   % running x cursor
uilabel(app.PeakEditPanel, 'Text','Snap:', 'FontSize',FS-3, 'FontWeight','bold', ...
    'Position',[cx WAVE_Y+4 44 18]);
cx = cx + 44 + 2;
app.PeakEditSnapToggle = uibutton(app.PeakEditPanel,'state', ...
    'Text','ON','Value',true, 'FontSize',FS-3, 'FontWeight','bold', ...
    'FontColor',[1 1 1], 'BackgroundColor',[0.30 0.62 0.36], ...
    'Tooltip','ON: clicks snap to the nearest peak/trough.  OFF: place points freely.', ...
    'Position',[cx WAVE_Y 64 WAVE_H], ...
    'ValueChangedFcn',@(b,~) style_snap(b));
cx = cx + 64 + PAD + 4;

% Wave selector — top row, right of dropdown
uilabel(app.PeakEditPanel, 'Text','Wave:', 'FontSize',FS-3, 'FontWeight','bold', ...
    'Position',[cx WAVE_Y+4 46 18]);
cx = cx + 46 + 2;
app.PeakEditWaveBtn = gobjects(1,5);
wave_names = {'I','II','III','IV','V'};
for k = 1:5
    app.PeakEditWaveBtn(k) = uibutton(app.PeakEditPanel, 'push', ...
        'Text', wave_names{k}, 'FontSize',FS-3, 'FontWeight','bold', ...
        'BackgroundColor', app.clr_btn, 'Enable','off', ...
        'Position',[cx+(k-1)*(WAVE_BTN_W+3) WAVE_Y WAVE_BTN_W WAVE_H]);
end
cx = cx + 5*(WAVE_BTN_W+3) + 6;
app.PeakEditPtToggle = uibutton(app.PeakEditPanel, 'push', ...
    'Text','▲ Peak', 'FontSize',FS-3, 'FontWeight','bold', ...
    'BackgroundColor',[1.0 0.88 0.80], ...
    'Position',[cx WAVE_Y 84 WAVE_H], ...
    'ButtonPushedFcn', @(btn,~) update_pt_toggle(btn));
cx = cx + 84 + 12;
% Mark the currently selected wave as absent (peak + trough → NaN).
% Shown by findPeaks_dtw only while a wave is selected for editing.
app.PeakEditAbsentBtn = uibutton(app.PeakEditPanel, 'push', ...
    'Text','∅ Mark Absent', 'FontSize',FS-3, 'FontWeight','bold', ...
    'BackgroundColor',[0.90 0.45 0.45], 'Enable','off', 'Visible','off', ...
    'Tooltip','Mark the selected wave as absent (saved as NaN). Click its Wave button again to restore it.', ...
    'Position',[cx WAVE_Y 150 WAVE_H]);
% Visual threshold: sets the level currently being edited as the threshold.
% Bottom row, in the slot left of Done (hidden with Done during Accept/Redo/Cancel).
app.PeakEditThreshBtn = uibutton(app.PeakEditPanel, 'push', ...
    'Text','⊥ Set as Threshold', 'FontSize',FS-3, 'FontWeight','bold', ...
    'BackgroundColor',app.clr_btn, 'Visible','off', ...
    'Tooltip','Make the level shown in the editor the visual threshold (lower levels get no peaks)', ...
    'Position',[btn_x+(BTN_W+PAD) PAD BTN_W BTN_H]);
end


function style_snap(b)
%STYLE_SNAP  Snap toggle look: green ON / grey OFF.
if b.Value
    b.Text = 'ON';  b.BackgroundColor = [0.30 0.62 0.36]; b.FontColor = [1 1 1];
else
    b.Text = 'OFF'; b.BackgroundColor = [0.86 0.84 0.79]; b.FontColor = [0.40 0.40 0.40];
end
end


function update_pt_toggle(btn)
if strcmp(btn.Text, '▲ Peak')
    btn.Text = '▼ Trough';
    btn.BackgroundColor = [0.78 0.88 1.0];
else
    btn.Text = '▲ Peak';
    btn.BackgroundColor = [1.0 0.88 0.80];
end
end
