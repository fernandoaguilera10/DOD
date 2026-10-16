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
% Selection look (Oct 16 2026 redesign; buttons have no alpha, so the blends
% are precomputed): gold [218 170 0]/255 at 24 % / 40 % over clr_panel
app.clr_sel     = [0.912 0.852 0.661];   % selected chip / type / measure with selections
app.clr_sel2    = [0.900 0.813 0.522];   % measure on screen
app.clr_txt2    = [0.29 0.275 0.247];    % text of unselected buttons
app.clr_on      = [0.18 0.49 0.31];      % ON pill, Run Analysis
app.clr_off     = [0.69 0.23 0.18];      % OFF pill

PAD   = 8;
HDR_H = 110;

app.UIFigure = uifigure( ...
    'Name','Auditory Physiology Analysis Toolkit (APAT)', ...
    'Color',app.clr_bg, ...
    'AutoResizeChildren','off', ...
    'CloseRequestFcn',@(src,~) close_apat(app, src));

% Size the window to the screen's usable area (excludes the menu bar and
% Dock/taskbar, wherever they are) and lay out against its real drawable
% area. WindowState='maximized' was unreliable on macOS (it could settle
% late, and the fallback ignored a side Dock).
% Window resizes are handled by relayout_results (SizeChangedFcn, set at
% the end): every component is scaled proportionally from this layout, in
% both directions. (MATLAB's AutoResizeChildren is off: it never shrinks
% components below their starting size, so a smaller window was clipped.)
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

% Run Analysis lives in the Setup tab's Run Summary card. The header holds
% the run status card (status, current step, progress bar, elapsed / time
% left, Stop) so it stays visible from every tab while an analysis runs.
% Hidden when idle; driven by private/run_status.m.
CARD_W = 700;  CARD_H = 84;
CARD_X = FIG_W - CARD_W - 16;  CARD_Y = round((HDR_H - CARD_H) / 2);
CREAM  = [0.88 0.84 0.74];                        % header subtitle colour
MONO   = mono_font();                             % pixel-style captions (no pixel font in MATLAB)
icon_dir = fullfile(fileparts(mfilename('fullpath')), 'icons');
R = struct();
% Same look as the rest of APAT: header black, gold border (as the Setup
% cards), gold title (as the APAT title), cream text (as the subtitle),
% small caps caption (as the Run Summary tiles), beige Stop button.
% Left: the chinchilla on a small track (private/run_status.m animates it).
R.card = uipanel(app.HeaderPanel, 'BorderType','line', 'BackgroundColor',app.clr_black, ...
    'Position',[CARD_X CARD_Y CARD_W CARD_H], 'Visible','off');
if isprop(R.card,'BorderColor'), R.card.BorderColor = app.clr_gold; end
LANE_X = 12;  LANE_W = 190;  LANE_Y = 10;
R.lane = uipanel(R.card, 'BorderType','none', 'BackgroundColor',[0.35 0.33 0.27], ...
    'Position',[LANE_X LANE_Y LANE_W 2]);
R.prop = uiimage(R.card, 'Position',[LANE_X+LANE_W-28 LANE_Y+2 28 36], 'Visible','off', 'UserData','');
R.chin = uiimage(R.card, 'Position',[LANE_X+round((LANE_W-52)/2) LANE_Y+2 52 44], 'UserData','');
try, R.chin.ImageSource = fullfile(icon_dir, 'chin_front.png'); catch, end
R.zz = uilabel(R.card, 'Text','z Z', 'FontName',MONO, 'FontSize',13, 'FontWeight','bold', ...
    'FontColor',[0.92 0.85 0.62], 'Position',[LANE_X+LANE_W-66 LANE_Y+30 44 18], 'Visible','off');
STOP_W = 104;  STOP_H = 34;
IN_X = LANE_X + LANE_W + 16;  TXT_W = CARD_W - IN_X - STOP_W - 24;
% caption row (small caps, as the Run Summary tiles)
R.caption = uilabel(R.card, 'Text','ANALYSIS', 'FontSize',10, 'FontWeight','bold', 'FontName',MONO, ...
    'FontColor',[0.80 0.76 0.66], 'Position',[IN_X CARD_H-20 TXT_W-70 14]);
R.elapsed = uilabel(R.card, 'Text','', 'FontSize',11, 'FontColor',CREAM, 'FontName',MONO, ...
    'HorizontalAlignment','right', 'Position',[IN_X+TXT_W-70 CARD_H-21 70 16], ...
    'Tooltip','Elapsed time');
% row 1: status title (gold, as the APAT title). (h_spinner_label: the old
% activity dot, kept hidden so older code that touches it still works.)
app.h_spinner_label = uilabel(R.card, 'Text','', 'FontSize',12, 'Visible','off', ...
    'FontColor',app.clr_gold, 'Position',[IN_X CARD_H-42 14 20]);
R.title = uilabel(R.card, 'Text','Running', 'FontSize',15, 'FontWeight','bold', ...
    'FontColor',app.clr_gold, 'Position',[IN_X CARD_H-42 TXT_W 20]);
% row 2: current step (cream, as the subtitle)
app.h_progress_label = uilabel(R.card, 'Text','', 'FontSize',11, ...
    'FontColor',CREAM, 'Position',[IN_X 20 TXT_W 16]);
% row 3: progress bar (gold on dark) + count
BAR_W = TXT_W - 150;
R.track = uipanel(R.card, 'BorderType','none', 'BackgroundColor',[0.24 0.22 0.18], ...
    'Position',[IN_X 9 BAR_W 5]);
R.fill  = uipanel(R.card, 'BorderType','none', 'BackgroundColor',app.clr_gold, ...
    'Position',[IN_X 9 1 5]);
R.count = uilabel(R.card, 'Text','', 'FontSize',10, 'FontColor',CREAM, ...
    'HorizontalAlignment','left', 'Position',[IN_X+BAR_W+10 3 140 16]);   % right next to the bar
% Stop: APAT button style (beige, black bold text), vertically centred
app.StopButton = uibutton(R.card,'push', ...
    'Text',[char(9632) '  Stop'], 'FontSize',14, 'FontWeight','bold', ...
    'FontColor',app.clr_black, 'BackgroundColor',app.clr_btn, ...
    'Position',[CARD_W-STOP_W-14 round((CARD_H-STOP_H)/2) STOP_W STOP_H], ...
    'Tooltip','Stop after the current step (work that has finished is saved)', ...
    'Visible','off', 'Enable','on', ...
    'ButtonPushedFcn',@(~,~) StopButtonPushed(app));
app.h_run = R;

% Header chinchilla holding a sign (top right; hidden while the run card is
% shown). Message: private/chin_sign.m from chin_messages.txt, picked when
% the Setup tab is built / shown and when a user profile is loaded.
G = struct();
CH_W = 78;  CH_H = 66;  SG_W = 250;  SG_H = 48;
ch_x = FIG_W - 22 - CH_W;  sg_x = ch_x + 6 - SG_W;  sg_y = 4 + 22;
GOLD_SH = [0.557 0.435 0.243];                    % #8E6F3E: sign shadow + post
G.post   = uipanel(app.HeaderPanel, 'BorderType','none', 'BackgroundColor',GOLD_SH, ...
    'Position',[sg_x+SG_W-22 sg_y-14 4 14]);
G.shadow = uipanel(app.HeaderPanel, 'BorderType','none', 'BackgroundColor',GOLD_SH, ...
    'Position',[sg_x+3 sg_y-3 SG_W SG_H]);
G.panel  = uipanel(app.HeaderPanel, 'BorderType','line', 'BackgroundColor',[0.965 0.933 0.827], ...
    'Position',[sg_x sg_y SG_W SG_H]);
if isprop(G.panel,'BorderColor'), G.panel.BorderColor = app.clr_black; end
try, G.panel.BorderWidth = 3; catch, end
G.label  = uilabel(G.panel, 'Text','', 'WordWrap','on', 'FontName',MONO, 'FontSize',12, ...
    'FontWeight','bold', 'FontColor',app.clr_black, 'VerticalAlignment','center', ...
    'Position',[8 2 SG_W-22 SG_H-10]);
G.chin   = uiimage(app.HeaderPanel, 'Position',[ch_x 4 CH_W CH_H], ...
    'Tooltip','APAT chinchilla');
try, G.chin.ImageSource = fullfile(icon_dir, 'chin_front_lg.png'); catch, end
app.h_sign = G;

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
% Back on Setup → the header chinchilla shows a new message (local wrapper)
app.TabGroup.SelectionChangedFcn = @(~,evt) tab_cb(app, evt);

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
    app.UIFigure.Position = [p_now(1), p_now(2) + p_now(4) - FIG_H, FIG_W, FIG_H];
    drawnow;
end
% Layout size the components were built for; resizes scale from it
setappdata(app.UIFigure, 'apat_design_size', [FIG_W FIG_H]);
setappdata(app.UIFigure, 'apat_cur_scale', [1 1]);
% Figure callbacks name LOCAL functions of this file: an anonymous callback
% that names a private function (or a handle to one) can fail when it fires
% ("Unable to find function … within createComponents.m"), e.g. after the
% class files change while APAT is open.
app.UIFigure.SizeChangedFcn = @(~,~) relayout_cb(app);     % local wrapper (same reason as hover_cb)
% Setup: resting the pointer on a measure / type button shows its types /
% parameters (private/setup_hover.m). The callback names a LOCAL function
% of this file (always found), which calls the private one and swallows any
% error: this callback fires on every mouse move, so an error here would
% flood the Command Window and stall the window (Oct 15 freeze).
app.UIFigure.WindowButtonMotionFcn = @(~,evt) hover_cb(app, evt);
% Esc: close an open Plot Settings panel, else stop tracking a subject
app.UIFigure.WindowKeyPressFcn = @(~,evt) key_cb(app, evt);
% Results bar: Tracking group / Save / Plot Settings right-anchored, left
% groups compressed when the bar is narrower than its content (the design
% layout needs ~2000 px; also re-run after every resize by relayout_results)
try, bar_fit(app); catch, end
end


function key_cb(app, evt)
%KEY_CB  WindowKeyPressFcn: Esc closes Plot Settings (if open) or clears the
%   tracked subject. Silent wrapper (never throws).
try
    if ~isvalid(app) || ~strcmp(evt.Key, 'escape'), return; end
    if isfield(app.res,'ps_on') && app.res.ps_on
        plot_settings(app, 'hide');
    elseif isfield(app.res,'sel_subj') && ~isempty(app.res.sel_subj)
        subject_pick(app, 'clear');
    end
catch
end
end


function tab_cb(app, evt)
%TAB_CB  TabGroup SelectionChangedFcn: Setup shown → new sign message
%   (private/chin_sign.m). Silent wrapper (never throws).
try
    if isvalid(app) && isequal(evt.NewValue, app.SetupTab), chin_sign(app, 'pick'); end
catch
end
end


function relayout_cb(app)
%RELAYOUT_CB  SizeChangedFcn: silent wrapper around relayout_results.
try
    if isvalid(app), relayout_results(app, 'changed'); end
catch
end
end


function hover_cb(app, evt)
%HOVER_CB  WindowButtonMotionFcn: wrapper around setup_hover that never
%   throws. The first error of a session is printed once (orange), so a
%   broken hover is visible without flooding the Command Window.
persistent told
try
    if isvalid(app), setup_hover(app, evt); end
catch err
    if isempty(told)
        told = true;
        fprintf(2, 'APAT hover (shown once): %s\n', err.message);
        if ~isempty(err.stack)
            fprintf(2, '   at %s (line %d)\n', err.stack(1).name, err.stack(1).line);
        end
    end
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
%BUILDSETUPTAB  Setup tab (Oct 16 2026 layout, approved design "Combined"):
%   row 1 User | Project Settings; row 2 Subjects | Conditions | Run Options |
%   Output; row 3 Auditory Measures. Every section is a panel with a black
%   header strip (cream bold title, gold tag number 01–07; setup_section).
%   Labels sit right next to their controls (label column = widest label).
FS    = 15;                 % parameter panels (buildParamPanels)
FT    = 14;                 % rows 1–2 text
CH    = 28;
LH    = 24;
STRIP = 30;                 % section header strip
MONO  = mono_font();
GREY  = app.clr_txt2;
tw    = @(s, fs) ceil(numel(s) * fs * 0.56) + 8;   % text width estimate (px)

ROW1_H = STRIP + 3*CH + 2*8 + 22;                   % 3 rows of controls
ROW2_H = min(236, max(206, round(0.27 * (TAB_H - 30))));
MEAS_H = max(100, TAB_H - 30 - PAD - ROW1_H - PAD - ROW2_H - PAD - PAD);

app.layout_row2_h = ROW2_H;
app.layout_meas_h = MEAS_H;

meas_y = PAD;
row2_y = meas_y + MEAS_H + PAD;
row1_y = row2_y + ROW2_H + PAD;

USER_W = 230;
SP_X   = PAD + USER_W + PAD;
SP_W   = FIG_W - SP_X - PAD;

% ── 01 User ─────────────────────────────────────────────────────────────
app.UserPanel = setup_section(app, app.SetupTab, [PAD row1_y USER_W ROW1_H], '01', 'User');
in_w = USER_W - 2 - 24;
uy = ROW1_H - 2 - STRIP - 12 - 32;
app.ProfileDropdown = uidropdown(app.UserPanel, ...
    'Items',{'(no profiles)'},'Value','(no profiles)', ...
    'Position',[12 uy in_w 32], 'BackgroundColor','white', ...
    'FontSize',FT,'FontWeight','bold', ...
    'ValueChangedFcn',@(~,~) ProfileDropdownChanged(app));
ubw = floor((in_w - 8) / 2);
app.NewUserBtn = uibutton(app.UserPanel,'push','Text','New User', ...
    'Position',[12 uy-10-32 ubw 32],'FontSize',FT-1,'BackgroundColor',app.clr_btn, ...
    'ButtonPushedFcn',@(~,~) NewUserButtonPushed(app));
app.SaveUserBtn = uibutton(app.UserPanel,'push','Text','Save User', ...
    'Position',[12+ubw+8 uy-10-32 ubw 32],'FontSize',FT-1,'BackgroundColor',app.clr_btn, ...
    'ButtonPushedFcn',@(~,~) SaveUserButtonPushed(app));

% ── 02 Project Settings ─────────────────────────────────────────────────
% label | control (≤ 480 px) | button, then a gold divider and the live
% project status (subjects / conditions in the roster, folders found)
app.ProjectPanel = setup_section(app, app.SetupTab, [SP_X row1_y SP_W ROW1_H], '02', 'Project Settings');
LBL_W  = tw('Subject Roster', FT);
CTRL_X = 12 + LBL_W + 8;
STAT_W = 200;
BTN_W  = 130;
DIR_W  = max(160, min(480, SP_W - 2 - CTRL_X - 8 - BTN_W - 16 - 2 - 16 - STAT_W - 12));
py3 = ROW1_H - 2 - STRIP - 10 - CH;
py2 = py3 - 8 - CH;
py1 = py2 - 8 - CH;
uilabel(app.ProjectPanel,'Text','Root Directory','FontColor',GREY, ...
    'Position',[12 py3 LBL_W CH],'FontSize',FT);
app.RootDirField = uieditfield(app.ProjectPanel,'text','Value','', ...
    'Position',[CTRL_X py3 DIR_W CH],'FontSize',FT-1,'BackgroundColor','white', ...
    'ValueChangedFcn',@(~,~) chinroster_ops(app,'scan',''));
app.BrowseBtn = uibutton(app.ProjectPanel,'push','Text','Browse…', ...
    'Position',[CTRL_X+DIR_W+8 py3 BTN_W CH],'FontSize',FT-1,'BackgroundColor',app.clr_btn, ...
    'ButtonPushedFcn',@(~,~) BrowseButtonPushed(app));
uilabel(app.ProjectPanel,'Text','Subject Roster','FontColor',GREY, ...
    'Position',[12 py2 LBL_W CH],'FontSize',FT);
app.RosterDropdown = uidropdown(app.ProjectPanel, ...
    'Items',{'(set root directory first)'},'Value','(set root directory first)', ...
    'Position',[CTRL_X py2 DIR_W CH],'FontSize',FT-1,'BackgroundColor','white', ...
    'ValueChangedFcn',@(~,~) RosterDropdownChanged(app));
% Create / edit the subject roster inside APAT (no Excel needed)
rb_fn = @roster_builder;            % private function: take the handle here (see SizeChangedFcn note)
app.RosterBuildBtn = uibutton(app.ProjectPanel,'push','Text','Create / Edit…', ...
    'Position',[CTRL_X+DIR_W+8 py2 BTN_W CH],'FontSize',FT-1,'BackgroundColor',app.clr_btn, ...
    'Tooltip','Create a new subject roster, or edit the one selected, without opening Excel', ...
    'ButtonPushedFcn',@(~,~) rb_fn(app));
uilabel(app.ProjectPanel,'Text','Experiment','FontColor',GREY, ...
    'Position',[12 py1 LBL_W CH],'FontSize',FT);
% Experiments: one toggle button per roster sheet (several can be run in
% one go), built by private/sheet_sel.m ('list') inside this host panel
app.SheetPanel = uipanel(app.ProjectPanel,'BorderType','none', ...
    'BackgroundColor',app.ProjectPanel.BackgroundColor, ...
    'Position',[CTRL_X py1 DIR_W+8+BTN_W CH]);
app.h_sheet_btns = gobjects(0);
uilabel(app.SheetPanel,'Text','(load chinroster first)','Tag','sheet_msg', ...
    'FontSize',FT-1,'FontColor',GREY,'Position',[0 0 DIR_W CH]);

% Project status column (filled by update_summary): right after the controls
app.h_summary_proj = gobjects(0);
stat_x = CTRL_X + DIR_W + 8 + BTN_W + 16;
if stat_x + 2 + 14 + 120 <= SP_W - 2
    uipanel(app.ProjectPanel,'BorderType','none','BackgroundColor',app.clr_gold, ...
        'Position',[stat_x py1 2 py3+CH-py1]);
    sw = min(STAT_W, SP_W - 2 - stat_x - 16 - 8);
    app.h_summary_proj = gobjects(1,3);
    for si = 1:3
        yy = [py3 py2 py1];
        app.h_summary_proj(si) = uilabel(app.ProjectPanel,'Text','', ...
            'FontSize',FT-1,'Interpreter','html', ...
            'Position',[stat_x+16 yy(si) sw CH]);
    end
end

% ── Row 2 widths: Subjects (rest) | Conditions | Run Options | Output ─────
cond_w = 220;  run_w = 270;  out_w = 430;
if FIG_W < 1400, run_w = 250;  out_w = 390; end
subj_w = FIG_W - 5*PAD - cond_w - run_w - out_w;
IN2 = ROW2_H - 2 - STRIP;       % drawable height below the header strips
app.layout_row2_in = IN2;
SMALL_H = 26;
STRIP_TXT = [0.92 0.85 0.62];   % #EBD99F: counts / links in the header strips

% ── 03 Subjects ─────────────────────────────────────────────────────────
[sec_p, sstrip] = setup_section(app, app.SetupTab, [PAD row2_y subj_w ROW2_H], '03', 'Subjects');
app.SubjectsPanel = sec_p;
% Bottom strip: compact action buttons; "n of N" count in the header strip
sb = {'Select All','SelectAllBtn',@(~,~) SelectAllButtonPushed(app); ...
      'Clear',     'ClearSubjBtn',@(~,~) ClearButtonPushed(app); ...
      '⟳ Refresh', 'RefreshSubjBtn',@(~,~) RefreshButtonPushed(app)};
for bi = 1:3
    app.(sb{bi,2}) = uibutton(app.SubjectsPanel,'push','Text',sb{bi,1}, ...
        'Position',[12+(bi-1)*(96+8) 6 96 SMALL_H],'FontSize',FT-1,'FontWeight','bold', ...
        'BackgroundColor',app.clr_btn,'ButtonPushedFcn',sb{bi,3});
end
app.h_row2_badges = gobjects(1,2);
app.h_row2_badges(1) = uilabel(sstrip,'Text','','FontSize',12, ...
    'FontColor',STRIP_TXT,'HorizontalAlignment','right', ...
    'Position',[subj_w-2-12-140 5 140 20]);
% thin rule above the strip
uipanel(app.SubjectsPanel,'BorderType','none','BackgroundColor',app.clr_gold, ...
    'Position',[12 6+SMALL_H+6 subj_w-2-24 1]);

% ── 04 Conditions: include chip + colour swatch + marker per condition ───
% (rows built by chinroster_ops 'refresh_conds'; colour / marker picker:
% chinroster_ops 'style_open')
[sec_p, cstrip] = setup_section(app, app.SetupTab, ...
    [PAD+subj_w+PAD row2_y cond_w ROW2_H], '04', 'Conditions');
app.ConditionsPanel = sec_p;
lk = {'Clear', @(~,~) cond_all(app, false); 'All', @(~,~) cond_all(app, true)};
% All / Clear sit in the bottom row (right), so the header can show "Conditions · <EXPERIMENT>"
CL_TXT = app.clr_gold_dk;
lx = cond_w - 2 - 12;
for li = 1:2
    w = tw(lk{li,1}, 12);  lx = lx - w;
    try
        uihyperlink(app.ConditionsPanel, 'Text',lk{li,1}, 'FontSize',12, 'FontWeight','bold', 'FontColor',CL_TXT, ...
            'VisitedColor',CL_TXT, 'Position',[lx 3 w 20], 'HyperlinkClickedFcn',lk{li,2}, ...
            'Tooltip','Colour and marker of each condition: click its swatch or its symbol');
    catch                                               % (no uihyperlink: small button)
        uibutton(app.ConditionsPanel,'push','Text',lk{li,1},'FontSize',11,'FontWeight','bold', ...
            'BackgroundColor',app.clr_btn,'Position',[lx 3 w+6 20],'ButtonPushedFcn',lk{li,2});
    end
    lx = lx - 10;
end
app.h_row2_badges(2) = uilabel(app.ConditionsPanel,'Text','','FontSize',11, ...
    'FontWeight','bold','FontColor',app.clr_gold_dk, ...
    'Position',[12 4 60 18]);
% (hint 'Click swatch / symbol' now a tooltip on All / Clear and the swatches)

% ── 05 Run Options: title + description, ON/OFF pill ──────────────────────
opt_x = PAD + subj_w + PAD + cond_w + PAD;
app.OptionsPanel = setup_section(app, app.SetupTab, [opt_x row2_y run_w ROW2_H], '05', 'Run Options');
opt_def = {'ReanalyzeCheck',    'Re-Analyze Data',      'Even if results exist',       true; ...
           'PlotRelativeCheck', 'Relative to Baseline', 'Changes vs. first condition', false; ...
           'BlindCheck',        'Blind Mode',           'Hide names while analysing',  false};
opt_tip = {'Recompute every analysis even if its results already exist', ...
           'Plot the changes of every condition relative to the first condition (Baseline)', ...
           'Hide subject & condition names while the analysis runs (random order)'};
PILL_W = 58;  PILL_H = 24;
row_h  = floor((IN2 - 12) / 3);
for oi = 1:3
    cy  = IN2 - 6 - oi*row_h;                       % row bottom
    mid = cy + round(row_h/2);
    txt_w = run_w - 2 - 12 - PILL_W - 20;
    uilabel(app.OptionsPanel,'Text',opt_def{oi,2},'FontSize',FT-1,'FontWeight','bold', ...
        'FontColor',app.clr_black,'Position',[12 mid txt_w 18],'Tooltip',opt_tip{oi});
    uilabel(app.OptionsPanel,'Text',opt_def{oi,3},'FontSize',11, ...
        'FontColor',[0.36 0.34 0.31],'Position',[12 mid-16 txt_w 15],'Tooltip',opt_tip{oi});
    app.(opt_def{oi,1}) = uibutton(app.OptionsPanel,'state','Text','ON','Value',opt_def{oi,4}, ...
        'FontSize',11,'FontWeight','bold','FontName',MONO,'Tooltip',opt_tip{oi}, ...
        'Position',[run_w-2-12-PILL_W mid-PILL_H/2 PILL_W PILL_H], ...
        'ValueChangedFcn',@(~,~) update_summary(app));
    setup_style(app, 'onoff', app.(opt_def{oi,1}));
end

% ── 06 Output (values: private/output_opts.m; handles app.h_output) ───────
% Data Export .mat / .csv (one or both) | Images ON/OFF + 300 / 150
% dpi | Plot Defaults (Subject Points, Shading). Measure-specific plot
% defaults sit in the measure parameter panels (buildParamPanels).
out_x = opt_x + run_w + PAD;
app.h_output = struct();
OP = setup_section(app, app.SetupTab, [out_x row2_y out_w ROW2_H], '06', 'Output');
O = struct();  O.panel = OP;  O.chk = struct();
OLW = tw('Plot Defaults', FT-1);  OX = 12 + OLW + 10;  RH = 26;
oy = IN2 - 10 - RH;
tipE = ['Format of the data files written for the analysed results: MATLAB .mat files ' ...
    '(APAT''s own format), CSV tables for other software, or both (at least one stays on). ' ...
    'Per-recording .mat files are always kept (APAT needs them to build averages).'];
uilabel(OP,'Text','Data Export','FontSize',FT-1,'FontColor',GREY,'Position',[12 oy OLW RH],'Tooltip',tipE);
O.mat_btn = uibutton(OP,'state','Text','.mat','Value',true,'FontSize',12,'FontWeight','bold', ...
    'UserData','.mat','Position',[OX oy 76 RH],'Tooltip',tipE, ...
    'ValueChangedFcn',@(src,~) output_cb(app, 'fmt', src));
O.csv_btn = uibutton(OP,'state','Text','.csv','Value',false,'FontSize',12,'FontWeight','bold', ...
    'UserData','.csv','Position',[OX+82 oy 76 RH],'Tooltip',tipE, ...
    'ValueChangedFcn',@(src,~) output_cb(app, 'fmt', src));
oy = oy - RH - 9;                 % (Group row removed Oct 16: Experiment is a data column)
tipI = ['Save every figure as a PNG while the analysis runs (300 dpi for reports; 150 dpi ' ...
    'saves faster). Results → Save Image updates a saved image with the view on screen.'];
uilabel(OP,'Text','Images','FontSize',FT-1,'FontColor',GREY,'Position',[12 oy OLW RH],'Tooltip',tipI);
O.img_btn = uibutton(OP,'state','Text','ON','Value',true,'FontSize',11,'FontWeight','bold', ...
    'FontName',MONO,'Position',[OX oy+1 PILL_W PILL_H],'Tooltip',tipI, ...
    'ValueChangedFcn',@(~,~) output_cb(app, 'changed'));
O.dpi300_btn = uibutton(OP,'state','Text','300 dpi','Value',true,'FontSize',12, ...
    'Position',[OX+PILL_W+10 oy 84 RH],'Tooltip',tipI, ...
    'ValueChangedFcn',@(~,~) output_cb(app, 'dpi', 300));
O.dpi150_btn = uibutton(OP,'state','Text','150 dpi','Value',false,'FontSize',12, ...
    'Position',[OX+PILL_W+10+84 oy 84 RH],'Tooltip',tipI, ...
    'ValueChangedFcn',@(~,~) output_cb(app, 'dpi', 150));
oy = oy - RH - 9;
uilabel(OP,'Text','Plot Defaults','FontSize',FT-1,'FontColor',GREY,'Position',[12 oy OLW RH], ...
    'Tooltip','Saved images and the Results views start with these; change them live with Plot Settings');
O.chk.subj_pts = pdef_btn(app, OP, 'Subject Points', [OX oy 136 RH-2], ...
    'Each subject''s points on the average plots');
O.chk.shading  = pdef_btn(app, OP, 'Shading', [OX+142 oy 100 RH-2], ...
    'Grey bands that group the points of one x value');
oy = oy - 22;
uilabel(OP,'Text','Measure-specific plot defaults are with each measure''s parameters below.', ...
    'FontSize',11,'FontColor',[0.36 0.34 0.31],'Position',[12 max(4, oy) out_w-2-24 16]);
app.h_output = O;

% ── Auditory Measures panel ──────────────────────────────────────────────
% Layout (left → right):
%   [measure buttons] | [subtype buttons (top row) + parameter panel below] | [About card + Run Summary card]
app.MeasuresPanel = setup_section(app, app.SetupTab, [PAD meas_y FIG_W-2*PAD MEAS_H], '07', 'Auditory Measures');

panel_w = FIG_W - 2*PAD;
MEAS_IN = MEAS_H - 2 - STRIP - 2; % drawable height below the header strip
app.layout_meas_h = MEAS_IN;
% Right edge of the subtype/parameter column: 60 % of the panel, widened on
% narrower screens so the parameter panels get ~760 px (the OAE panel's
% design width), while the About / Run Summary column keeps >= 420 px.
SUB_X0  = round(0.01*panel_w) + max(110, min(150, round(0.12*panel_w))) + 18;   % as buildMeasureButtons
MID_END = round(max(0.60*panel_w, min(SUB_X0 + 760, panel_w - 12 - 420)));
RIGHT_X = MID_END + 12;
RIGHT_W = panel_w - RIGHT_X - 12;

app.h_meas_btns = gobjects(0);
app.h_sub_btns  = {};
[SUB_X, TOP_Y] = buildMeasureButtons(app, panel_w, MEAS_IN, MID_END);

% Parameter panels fill the column under the subtype buttons
PARAM_POS = [SUB_X 6 MID_END-SUB_X max(120, TOP_Y-14)];
buildParamPanels(app, PARAM_POS, FS, LH);

% ── About card (description of the selected analysis) ────────────────────
ABOUT_H = max(96, round(0.30 * MEAS_IN));
about = uipanel(app.MeasuresPanel,'BorderType','line','BackgroundColor',app.clr_bg, ...
    'Position',[RIGHT_X MEAS_IN-ABOUT_H-4 RIGHT_W ABOUT_H]);
if isprop(about,'BorderColor'), about.BorderColor = app.clr_gold; end
ab_in = ABOUT_H - 2;
uilabel(about,'Text','Analysis Insight','FontSize',FT-1,'FontWeight','bold', ...
    'FontColor',app.clr_black,'Position',[12 ab_in-8-18 RIGHT_W-26 18]);
app.DescTitleLabel = uilabel(about,'Text','', 'WordWrap','on', ...
    'Position',[12 ab_in-8-18-22 RIGHT_W-26 20], ...
    'FontSize',FT-1,'FontWeight','bold','FontColor',app.clr_gold_dk);
app.DescLabel = uilabel(about,'Text','', 'WordWrap','on', ...
    'VerticalAlignment','top', ...
    'Position',[12 6 RIGHT_W-26 max(20, ab_in-8-18-22-10)], ...
    'FontSize',12,'FontColor',GREY);

% ── Run Summary card (live overview of what Run Analysis will do) ────────
% Cream card: "RUN SUMMARY" + "n ANALYSES", three count tiles (subtle
% yellow), the analyses / options rows, green Run Analysis button.
SUM_H = MEAS_IN - ABOUT_H - 14;
sp = uipanel(app.MeasuresPanel,'BorderType','line','BackgroundColor',[0.965 0.933 0.827], ...
    'Position',[RIGHT_X 4 RIGHT_W SUM_H]);
if isprop(sp,'BorderColor'), sp.BorderColor = app.clr_gold; end
try, sp.BorderWidth = 2; catch, end
s_iw = RIGHT_W - 4;  s_ih = SUM_H - 4;
CAP_C = [0.353 0.290 0.118];                              % #5A4A1E tile captions
S = struct();
uilabel(sp,'Text','RUN SUMMARY','FontName',MONO,'FontSize',11,'FontWeight','bold', ...
    'FontColor',CAP_C,'Position',[12 s_ih-8-16 160 16]);
S.head_n = uilabel(sp,'Text','','FontName',MONO,'FontSize',10,'FontWeight','bold', ...
    'FontColor',[0.557 0.435 0.243],'HorizontalAlignment','right', ...
    'Position',[s_iw-12-160 s_ih-8-16 160 16]);
RUN_H  = max(36, min(44, round(0.20*s_ih)));
TILE_H = max(36, min(48, round(0.22*s_ih)));
ty = s_ih - 8 - 16 - 8 - TILE_H;
tile_w = floor((s_iw - 24 - 2*6) / 3);
tile_caps = {'Subjects','Conditions','Datasets'};
S.tiles = gobjects(1,3);
for ti = 1:3
    tp = uipanel(sp,'BorderType','line','BackgroundColor',[0.941 0.874 0.645], ...
        'Position',[12+(ti-1)*(tile_w+6) ty tile_w TILE_H]);
    if isprop(tp,'BorderColor'), tp.BorderColor = [0.855 0.667 0]; end
    S.tiles(ti) = uilabel(tp,'Text','0','FontName',MONO,'FontSize',20,'FontWeight','bold', ...
        'FontColor',app.clr_black,'Position',[8 TILE_H-2-4-24 tile_w-14 24]);
    uilabel(tp,'Text',upper(tile_caps{ti}),'FontName',MONO,'FontSize',9,'FontWeight','bold', ...
        'FontColor',CAP_C,'Position',[8 3 tile_w-14 13]);
end
app.RunButton = uibutton(sp,'push', ...
    'Text',[char(9654) ' RUN ANALYSIS'], ...
    'Position',[12 8 s_iw-24 RUN_H], ...
    'FontSize',15,'FontWeight','bold','FontName',MONO, ...
    'FontColor',[1 1 1],'BackgroundColor',app.clr_on, ...
    'ButtonPushedFcn',@(~,~) RunButtonPushed(app));
% Summary rows between the tiles and the button: one row per selected
% analysis, then the options rows (update_summary fills them; as many as fit)
line_h = 18;
top_l  = ty - 6;  bot_l = 8 + RUN_H + 6;
n_lines = max(3, floor((top_l - bot_l) / line_h));
ly = top_l - line_h;
S.lines = gobjects(1, n_lines);
for li = 1:n_lines
    S.lines(li) = uilabel(sp,'Text','','FontSize',12, ...
        'FontColor',[0.227 0.212 0.184],'Interpreter','html', ...
        'Position',[12 ly s_iw-24 line_h]);
    ly = ly - line_h;
end
S.proj = app.h_summary_proj;   % project-status labels built in the Project panel
app.h_summary = S;

output_cb(app, 'refresh');
end


function [p, strip] = setup_section(app, parent, pos, num, title)
%SETUP_SECTION  Setup section: panel (gold border) with a black header strip
%   carrying a small gold tag number (num, e.g. '03') and the cream bold
%   title. Content goes below the strip (inner height pos(4)-2-30).
p = uipanel(parent,'BorderType','line','BackgroundColor',app.clr_panel,'Position',pos);
if isprop(p,'BorderColor'), p.BorderColor = app.clr_gold; end
iw = pos(3) - 2;  ih = pos(4) - 2;
strip = uipanel(p,'BorderType','none','BackgroundColor',app.clr_black,'Position',[0 ih-30 iw 30]);
uilabel(strip,'Text',num,'FontName',mono_font(),'FontSize',10,'FontWeight','bold', ...
    'FontColor',app.clr_black,'BackgroundColor',app.clr_gold,'HorizontalAlignment','center', ...
    'Position',[10 8 24 15]);
uilabel(strip,'Text',title,'FontSize',13,'FontWeight','bold','FontColor',[0.97 0.96 0.93], ...
    'Position',[42 5 ceil(numel(title)*13*0.62)+10 20], 'Tag',['apat_sec_title_' num], 'UserData',title);
end


function b = pdef_btn(app, parent, name, pos, tip)
%PDEF_BTN  Plot-default toggle ('■ Name' on / '□ Name' off; setup_style
%   'pdef'). Values read by private/output_opts.m through app.h_output.chk.
b = uibutton(parent,'state','Text',name,'Value',true,'FontSize',12,'UserData',name, ...
    'BackgroundColor',[1 1 1],'Position',pos,'Tooltip',tip, ...
    'ValueChangedFcn',@(~,~) output_cb(app, 'changed'));
setup_style(app, 'pdef', b);
end


function cond_all(app, on)
%COND_ALL  Conditions header "All" / "Clear".
try
    for c = app.h_cond_checks(:)'
        if isgraphics(c), c.Value = on; end
    end
    update_summary(app);
catch
end
end


function save_view_cb(app, mode)
%SAVE_VIEW_CB  Results "Save Image" / "Save As New": local wrapper around
%   private/save_view.m (see the callback note in createComponents).
try
    if isvalid(app), save_view(app, mode); end
catch err
    try
        app.UIFigure.Pointer = 'arrow';
        app.res.save_msg.Text = ['Could not save the image: ' err.message];
        app.res.save_msg.Visible = 'on';
    catch
    end
end
end


function output_cb(app, action, arg)
%OUTPUT_CB  Callbacks of the Output section (and of the plot-default toggles
%   in the parameter panels): local wrapper (never throws) around
%   private/output_opts.m (see the callback note above).
%   'fmt', src   .mat / .csv toggles (at least one stays on)
%   'dpi', v     300 / 150 dpi segments (exactly one on)
try
    if ~isvalid(app), return; end
    O = app.h_output;
    switch action
        case 'fmt'
            if ~O.mat_btn.Value && ~O.csv_btn.Value, arg.Value = true; end
            output_opts(app, 'refresh');
            update_summary(app);
        case 'dpi'
            O.dpi300_btn.Value = (arg == 300);
            O.dpi150_btn.Value = (arg == 150);
            output_opts(app, 'refresh');
            update_summary(app);
        case 'changed'
            output_opts(app, 'refresh');
            update_summary(app);
        case 'refresh'
            output_opts(app, 'refresh');
    end
catch
end
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
% Pixel-art icons (icons/make_icons.py) shown above each button's text
icon_dir = fullfile(fileparts(mfilename('fullpath')), 'icons');
for m = 1:app.n_meas
    y_m = 0.99 - m*(app.meas_h + app.meas_gap) + app.meas_gap;
    app.h_meas_btns(m) = uibutton(app.MeasuresPanel,'push', ...
        'Text',app.MEASURES(m).name, ...
        'Position',[round(0.01*panel_w) round(y_m*MEAS_IN) MEAS_BTN_W row_h], ...
        'FontSize',15,'FontWeight','bold','BackgroundColor',app.clr_btn,'FontColor',app.clr_txt2, ...
        'UserData',m, ...
        'ButtonPushedFcn',@(src,~) MeasureButtonPushed(app, src));
    set_btn_icon(app.h_meas_btns(m), fullfile(icon_dir, ...
        ['icon_' lower(app.MEASURES(m).name) '.png']));
end

% Gold vertical divider
div_x = round(0.01*panel_w) + MEAS_BTN_W + 6;
uipanel(app.MeasuresPanel,'BorderType','none','BackgroundColor',app.clr_gold, ...
    'Position',[div_x 6 3 MEAS_IN-8]);
% Marker of the measure on screen: thicker gold bar on the divider, level
% with that button (moved by navigate_results>do_measures)
app.h_meas_marker = uipanel(app.MeasuresPanel,'BorderType','none','BackgroundColor',app.clr_gold_dk, ...
    'Position',[div_x-2 round((0.99-app.meas_h)*MEAS_IN) 7 row_h]);

% Subtype buttons — always on the top row of the middle column
SUB_X = div_x + 12;
app.meas_sub_area_start = SUB_X;
TOP_Y = round((0.99 - app.meas_h) * MEAS_IN);
% Type buttons add / remove an analysis from the run (several can be
% selected, across measures). MEMR: ART + the exploratory analyses.
sub_tip = ['Click to add to / remove from the run. Several analyses can be ' ...
    'selected (also from other measures); they run one after another.'];
for m = 1:app.n_meas
    subs = app.MEASURES(m).subtypes;
    no_types = isempty(subs);
    if no_types, subs = {app.MEASURES(m).name}; end
    app.h_sub_btns{m} = gobjects(1, numel(subs));
    sub_area_px = MID_END - SUB_X;
    sub_btn_w   = min(240, floor(sub_area_px / max(numel(subs),3)) - 6);
    sub_fs      = 14;  if numel(subs) > 5, sub_fs = 13; end   % MEMR: 8 types on one row
    for k = 1:numel(subs)
        btxt = subs{k};
        if no_types && strcmp(app.MEASURES(m).name, 'MEMR'), btxt = 'ART'; end   % acoustic reflex threshold
        app.h_sub_btns{m}(k) = uibutton(app.MeasuresPanel,'push', ...
            'Text',btxt, ...
            'Position',[SUB_X + (k-1)*(sub_btn_w+6) TOP_Y sub_btn_w row_h], ...
            'FontSize',sub_fs,'FontWeight','bold','BackgroundColor',app.clr_btn,'Visible','off', ...
            'UserData',[m k], 'Tooltip',sub_tip, ...
            'ButtonPushedFcn',@(src,~) SubtypeButtonPushed(app, src));
        if no_types
            icon_f = ['icon_' lower(app.MEASURES(m).name) '_type.png'];
        else
            icon_f = ['icon_' lower(app.MEASURES(m).name) '_' lower(subs{k}) '.png'];
            if ~exist(fullfile(icon_dir, icon_f), 'file') && strcmp(app.MEASURES(m).name, 'MEMR') && k == 1
                icon_f = 'icon_memr_type.png';        % ART: the reflex-spectra icon
            end
        end
        set_btn_icon(app.h_sub_btns{m}(k), fullfile(icon_dir, icon_f));
    end
end
end


function set_btn_icon(btn, f)
%SET_BTN_ICON  Put icon file f above the button text (silently skipped if
%   the file is missing or the icon cannot be set).
try
    if exist(f, 'file')
        set(btn, 'Icon', f, 'IconAlignment', 'top');
    end
catch
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
% Thresholds and Peaks keep their own frequency selection (abr_freq_sync):
% the chips show the one of the ABR type on screen; All / Clear set them all.
FL_W = 260;
uilabel(app.h_abr_param_panel,'Text','Frequencies — Thresholds','FontSize',FS,'FontWeight','bold', ...
    'Tag','abr_freq_lbl', 'Position',[PAD y-LH FL_W LH]);
ab_w = 64;
uibutton(app.h_abr_param_panel,'push','Text','All','FontSize',FS-3,'FontWeight','bold', ...
    'BackgroundColor',[1 1 1], 'Position',[PAD+FL_W+6 y-LH+1 ab_w LH-2], ...
    'Tooltip','Select every frequency (for the ABR type on screen)', ...
    'ButtonPushedFcn',@(~,~) abr_freq_chip(app, 'all'));
uibutton(app.h_abr_param_panel,'push','Text','Clear','FontSize',FS-3,'FontWeight','bold', ...
    'BackgroundColor',[1 1 1], 'Position',[PAD+FL_W+12+ab_w y-LH+1 ab_w LH-2], ...
    'Tooltip','Clear every frequency (for the ABR type on screen)', ...
    'ButtonPushedFcn',@(~,~) abr_freq_chip(app, 'none'));
y = y - LH - 4 - chip_h;
app.h_abr_freq_checks = gobjects(1, numel(freq_labels));
for fi = 1:numel(freq_labels)
    app.h_abr_freq_checks(fi) = uibutton(app.h_abr_param_panel,'state', ...
        'Text',freq_labels{fi},'Value',true,'FontSize',FS-1,'FontWeight','bold', ...
        'Position',[PAD+(fi-1)*(chip_w+gap) y chip_w chip_h], ...
        'ValueChangedFcn',@(~,~) abr_freq_chip(app, 'store'));
end
y = y - 14;
uilabel(app.h_abr_param_panel,'Text','Waves','Tag','abr_wave_lbl', ...
    'FontSize',FS,'FontWeight','bold','Position',[PAD y-LH FL_W LH]);
uibutton(app.h_abr_param_panel,'push','Text','All','FontSize',FS-3,'FontWeight','bold', ...
    'Tag','abr_wave_lbl', 'BackgroundColor',[1 1 1], 'Position',[PAD+FL_W+6 y-LH+1 ab_w LH-2], ...
    'Tooltip','Select every wave', 'ButtonPushedFcn',@(~,~) abr_wave_all(app, true));
uibutton(app.h_abr_param_panel,'push','Text','Clear','FontSize',FS-3,'FontWeight','bold', ...
    'Tag','abr_wave_lbl', 'BackgroundColor',[1 1 1], 'Position',[PAD+FL_W+12+ab_w y-LH+1 ab_w LH-2], ...
    'Tooltip','Clear every wave', 'ButtonPushedFcn',@(~,~) abr_wave_all(app, false));
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
% Repeated Levels (Thresholds and Peaks): a level recorded more than once →
% every recording ('all') or their average ('average'); cfg.abr_dup_levels
y = y - LH - 2 - 10 - 28;
tipR = ['A stimulus level recorded more than once (e.g. repeated at the end of a series): ' ...
    'Show All = every recording is used and shown; Average = the repeated recordings ' ...
    'of a level are averaged into one.'];
rl_w = ceil(numel('Repeated Levels:')*(FS-1)*0.56) + 8;
uilabel(app.h_abr_param_panel,'Text','Repeated Levels:','FontSize',FS-1,'HorizontalAlignment','right', ...
    'Position',[PAD y rl_w 28],'Tooltip',tipR);
uidropdown(app.h_abr_param_panel,'Items',{'Show All','Average'},'ItemsData',{'all','average'}, ...
    'Value','all','Tag','abr_dup_dd','FontSize',FS-1,'BackgroundColor','white','Tooltip',tipR, ...
    'Position',[PAD+rl_w+6 y 130 28],'ValueChangedFcn',@(~,~) update_summary(app));
pd_x = PAD + rl_w + 6 + 130 + 24;
pd_w = ceil(numel('Plot Defaults')*(FS-1)*0.56) + 8;
uilabel(app.h_abr_param_panel,'Text','Plot Defaults','FontSize',FS-1,'HorizontalAlignment','right', ...
    'Position',[pd_x y pd_w 28], ...
    'Tooltip','Saved images and the Results views start with these; change them live with Plot Settings');
O = app.h_output;
O.chk.abr_n = pdef_btn(app, app.h_abr_param_panel, 'Sample Size (n)', [pd_x+pd_w+6 y+1 150 26], ...
    'n labels on the ABR Peaks average plots');
app.h_output = O;

% ── EFR ──────────────────────────────────────────────────────────────────
app.h_efr_param_panel = mkpanel('EFR Parameters');
p = app.h_efr_param_panel;
% RAM block (visible for RAM) and dAM block (visible for dAM) share the top.
y0 = IH - 6;
y = textline(p, y0, 'RAM — configurable', true, 'efr_ram_hdr');
y = textline(p, y, 'Mod. freq: 223 Hz  |  Filter: 60–4000 Hz  |  H1 = 223 Hz (fundamental)', false, 'efr_ram_info');
% Row 1: max harmonics + analysis window
y = y - 30 - 4;
uilabel(p,'Text','Max harmonics:','Tag','efr_harm_lbl','FontSize',FS-1, ...
    'Position',[PAD y+3 120 LH]);
app.h_efr_harmonics_field = uieditfield(p,'numeric', ...
    'Value',16,'Limits',[1 16],'RoundFractionalValues','on','Tag','efr_harmonics', ...
    'Position',[PAD+122 y 60 30],'FontSize',FS-1,'BackgroundColor','white', ...
    'ValueChangedFcn',@(src,~) efr_sync_high(src));
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
% Row 2: low / high harmonic ranges
y = y - 30 - 8;
hnum = @(v,tag,x) uieditfield(p,'numeric','Value',v,'Limits',[1 16],'RoundFractionalValues','on', ...
    'Tag',tag,'Position',[x y 46 30],'FontSize',FS-1,'BackgroundColor','white');
uilabel(p,'Text','Low harmonics:','Tag','efr_low_lbl','FontSize',FS-1,'Position',[PAD y+3 120 LH]);
hnum(1,'efr_low_from',PAD+122);
uilabel(p,'Text','–','Tag','efr_low_dash','FontSize',FS-1,'HorizontalAlignment','center', ...
    'Position',[PAD+168 y+3 14 LH]);
hnum(4,'efr_low_to',PAD+182);
hx = PAD + 182 + 46 + 24;
uilabel(p,'Text','High harmonics:','Tag','efr_high_lbl','FontSize',FS-1,'Position',[hx y+3 120 LH]);
hnum(5,'efr_high_from',hx+122);
uilabel(p,'Text','–','Tag','efr_high_dash','FontSize',FS-1,'HorizontalAlignment','center', ...
    'Position',[hx+168 y+3 14 LH]);
hnum(16,'efr_high_to',hx+182);
% Row 3: what to sum + normalisation
y = y - 30 - 8;
uilabel(p,'Text','Sum of:','Tag','efr_sum_lbl','FontSize',FS-1,'Position',[PAD y+3 120 LH]);
uidropdown(p,'Items',{'Amplitude (PLV)','SNR (dB)','Magnitude (µV)'},'ItemsData',{'amplitude','snr','magnitude'}, ...
    'Value','amplitude','Tag','efr_sum_dd','FontSize',FS-1,'BackgroundColor','white', ...
    'Position',[PAD+122 y 150 30]);
nx = PAD + 122 + 150 + 24;
uilabel(p,'Text','Normalize by all harmonics:','Tag','efr_norm_lbl','FontSize',FS-1, ...
    'Position',[nx y+3 196 LH]);
nb = uibutton(p,'state','Text','OFF','Value',false,'Tag','efr_norm_btn','FontSize',FS-1, ...
    'FontWeight','bold','Position',[nx+198 y 64 30],'BackgroundColor','white', ...
    'FontColor',[0.6 0.6 0.6]);
nb.ValueChangedFcn = @(src,~) efr_style_toggle(src);
efr_style_toggle(nb);
y = y - 6;
textline(p, y, 'Total PLV over all harmonics is always reported.', false, 'efr_ram_note');

% dAM block (same top position; shown only for dAM)
y = textline(p, y0, 'dAM', true, 'efr_dam_hdr');
y = textline(p, y, 'Carrier: 4 kHz  |  AM sweep: 4–10.5 Hz  |  Demod filter: 10–1500 Hz', false, 'efr_dam_info');
y = y - 30 - 4;
uilabel(p,'Text','dAM bands:','Tag','efr_dam_lbl','FontSize',FS-1,'Position',[PAD y+3 120 LH]);
uieditfield(p,'numeric','Value',16,'Limits',[2 64],'RoundFractionalValues','on', ...
    'Tag','efr_dam_bands','Position',[PAD+122 y 60 30],'FontSize',FS-1,'BackgroundColor','white');
uilabel(p,'Text','log-spaced smoothing bands (16 = number of RAM harmonics)', ...
    'Tag','efr_dam_note','FontSize',FS-3,'FontColor',GRY,'Position',[PAD+192 y+3 IW-200 LH]);

% ── OAE ──────────────────────────────────────────────────────────────────
% Left: band averaging / display (applied when results are summarized — no
% re-analysis). Right: analysis settings of the selected subtype (used when
% the analysis runs: new data or Reanalyze). Controls are found by Tag in
% RunButtonPushed (oae_*), saved in profiles as oae_ctl.
app.h_oae_param_panel = mkpanel('OAE Parameters');
p = app.h_oae_param_panel;
% Layout is sized from the panel actually available (IW × IH, set by the
% screen): the design widths below (left 430 px + gap 24 + right 280 px) are
% scaled down with sx() — and the font with them — when the panel is
% narrower; below 75 % the right column moves under the left one. Row
% height follows the available height.
LEFT_W = 430;  GAP_W = 24;  RIGHT_W0 = 280;
sc = min(1, IW / (LEFT_W + GAP_W + RIGHT_W0));
two_col = sc >= 0.75;
if ~two_col, sc = min(1, IW / max(LEFT_W, RIGHT_W0)); end
sx  = @(v) round(v * sc);
OFS = FS - 2;  if sc < 0.92, OFS = max(9, floor((FS - 2) * sc)); end
nrows = 7 + ~two_col * 6;                          % rows stacked in one column (+ Plot defaults)
RS = max(26, min(36, floor((IH - (1 + ~two_col)*(LH + 8)) / nrows)));
RH = RS - 8 + 2*(RS <= 30);  FW = sx(50);
LX = PAD;  RX = PAD + sx(LEFT_W + GAP_W);
if ~two_col, RX = PAD; end
y0 = IH - 6;
uilabel(p,'Text','Band Average','FontSize',OFS+1,'FontWeight','bold', ...
    'Position',[LX y0-LH sx(LEFT_W) LH], ...
    'Tooltip','Applied when results are summarized (no re-analysis needed)');
y = y0 - LH - 4 - RH;
lbl(p, 'Band width', LX, y, sx(92));
uidropdown(p,'Items',{'1 octave','1/2 octave','1/3 octave','1/4 octave'},'ItemsData',{1,2,3,4}, ...
    'Value',2,'Tag','oae_bpo','FontSize',OFS,'BackgroundColor','white','Position',[LX+sx(94) y sx(124) RH]);
lbl(p, 'Range', LX+sx(230), y, sx(48));
num(p, 0.5, 'oae_fmin', LX+sx(278), y, [0.05 50]);
dash(p, LX+sx(328), y);
num(p, 16, 'oae_fmax', LX+sx(342), y, [0.1 100]);
lbl(p, 'kHz', LX+sx(396), y, sx(34), true);
y = y - RS;
lbl(p, 'Method', LX, y, sx(92));
uidropdown(p,'Items',{'SNR-weighted','Power average','Mean of dB','Median'}, ...
    'ItemsData',{'snrw','power','meandb','median'},'Value','snrw','Tag','oae_method', ...
    'FontSize',OFS,'BackgroundColor','white','Position',[LX+sx(94) y sx(150) RH], ...
    'Tooltip',['SNR-weighted: weighted mean of dB, weight = SNR²  |  Power average: mean of pressure², ' ...
               'then dB  |  Mean of dB  |  Median of dB']);
lbl(p, 'Y-axis', LX+sx(256), y, sx(52));
uidropdown(p,'Items',{'Amplitude','SNR'},'ItemsData',{'amp','snr'},'Value','amp','Tag','oae_ymeas', ...
    'FontSize',OFS,'BackgroundColor','white','Position',[LX+sx(308) y sx(118) RH]);
y = y - RS;
lbl(p, 'SNR ≥', LX, y, sx(92));
num(p, 6, 'oae_snr_min', LX+sx(94), y, [-20 60]);
lbl(p, 'dB', LX+sx(146), y, sx(24), true);
sb = uibutton(p,'state','Text','ON','Value',true,'Tag','oae_snr_btn','FontSize',OFS, ...
    'FontWeight','bold','Position',[LX+sx(172) y sx(58) RH],'BackgroundColor',app.clr_gold, ...
    'FontColor',app.clr_black,'Tooltip','SNR criterion: points below it are left out of the band average');
sb.ValueChangedFcn = @(src,~) efr_style_toggle(src);
efr_style_toggle(sb);
lbl(p, 'Min. passing', LX+sx(242), y, sx(92));
num(p, 50, 'oae_min_frac', LX+sx(334), y, [0 100]);
lbl(p, '%', LX+sx(386), y, sx(22), true);
y = y - RS;
lbl(p, 'Regions', LX, y, sx(92));
rtip = {'Low band starts','Low | Mid edge','Mid | High edge','High band ends'};
rv = [0.5 2 8 16];
for ri = 1:4
    h = num(p, rv(ri), sprintf('oae_reg%d', ri), LX+sx(94+(ri-1)*64), y, [0.05 100]);
    h.Tooltip = ['Frequency bands (kHz): ' rtip{ri}];
    if ri < 4, sep(p, LX+sx(144+(ri-1)*64), y); end
end
lbl(p, 'kHz', LX+sx(350), y, sx(34), true);
y = y - RS;
lbl(p, 'Flagged bands', LX, y, sx(92));
uidropdown(p,'Items',{'Include in average','Exclude from average'},'ItemsData',{'include','exclude'}, ...
    'Value','include','Tag','oae_gate_avg','FontSize',OFS,'BackgroundColor','white', ...
    'Position',[LX+sx(94) y sx(190) RH], ...
    'Tooltip',['Bands where fewer than the minimum % of points pass the SNR criterion. ' ...
               'Excluding them can hide a loss of emissions after exposure.']);
y = y - RS;
lbl(p, 'Save files', LX, y, sx(92));
for ui = 1:2
    un = {'EPL','SPL'};
    ub = uibutton(p,'state','Text',un{ui},'Value',true,'Tag',['oae_save_' lower(un{ui})], ...
        'FontSize',OFS,'FontWeight','bold','Position',[LX+sx(94+(ui-1)*66) y sx(60) RH], ...
        'BackgroundColor',app.clr_gold,'FontColor',app.clr_black, ...
        'Tooltip',sprintf(['Save %s figures and average files (one or both; both = also the ' ...
                           'EPL + SPL figure). TEOAE is SPL only.'], un{ui}));
    ub.ValueChangedFcn = @(src,~) oae_unit_toggle(src);
    setup_style(app, 'chip', ub);
end
% Plot defaults of the OAE figures (saved images + Results views start with
% these; values in app.h_output.chk, private/output_opts.m)
y = y - RS;
lbl(p, 'Plot defaults', LX, y, sx(92));
O = app.h_output;
O.chk.oae_sweep = pdef_btn(app, p, 'Sweeps', [LX+sx(94) y sx(96) RH], ...
    'DPOAE / SFOAE / TEOAE sweep (raw) traces');
O.chk.oae_nf    = pdef_btn(app, p, 'Noise Floor', [LX+sx(196) y sx(124) RH], ...
    'Noise floor of the OAE plots');
app.h_output = O;
yL = y;

% Right column: analysis settings, one block per subtype (same position)
if two_col, yr0 = y0; else, yr0 = yL - 8; end
aw = sx(130);  ax = RX + aw + 2;  hw = sx(RIGHT_W0);
hdr = {'oae_dp','DPOAE'; 'oae_sf','SFOAE'; 'oae_te','TEOAE'};
for hi = 1:3
    uilabel(p,'Text',[hdr{hi,2} ' Extraction'],'Tag',hdr{hi,1},'FontSize',OFS+1, ...
        'FontWeight','bold','Position',[RX yr0-LH hw LH], ...
        'Tooltip',[hdr{hi,2} ' settings, used when the analysis runs: new data, or with Re-analyze data ON']);
end
% DPOAE
y = yr0 - LH - 4 - RH;
lbl(p, 'Window (s)', RX, y, aw, false, 'oae_dp');   num(p, 0.25, 'oae_dp_win',  ax, y, [0.01 2], 'oae_dp');  y = y - RS;
lbl(p, 'Freq. points', RX, y, aw, false, 'oae_dp'); num(p, 512,  'oae_dp_npts', ax, y, [16 4096], 'oae_dp', sx(64)); y = y - RS;
lbl(p, 'Artifact (SD)', RX, y, aw, false, 'oae_dp'); num(p, 3,   'oae_dp_ar',   ax, y, [1 20], 'oae_dp');
% SFOAE
y = yr0 - LH - 4 - RH;
lbl(p, 'Window base (s)', RX, y, aw, false, 'oae_sf'); num(p, 0.038, 'oae_sf_win', ax, y, [0.002 1], 'oae_sf', sx(64));  y = y - RS;
lbl(p, 'Freq. points', RX, y, aw, false, 'oae_sf');    num(p, 512, 'oae_sf_npts', ax, y, [16 4096], 'oae_sf', sx(64)); y = y - RS;
lbl(p, 'Artifact (SD)', RX, y, aw, false, 'oae_sf');   num(p, 4,   'oae_sf_ar',   ax, y, [1 20], 'oae_sf');   y = y - RS;
lbl(p, 'High-pass (Hz)', RX, y, aw, false, 'oae_sf');  num(p, 300, 'oae_sf_hp',   ax, y, [0 5000], 'oae_sf', sx(64)); y = y - RS;
lbl(p, 'Noise floor', RX, y, aw, false, 'oae_sf');
uidropdown(p,'Items',{'Nearby freqs','Subtraction'},'ItemsData',{'adjacent','subtraction'}, ...
    'Value','adjacent','Tag','oae_sf_nf','UserData','oae_sf','FontSize',OFS,'BackgroundColor','white', ...
    'Position',[ax y sx(140) RH], ...
    'Tooltip','Nearby freqs: fit at 1.10–1.16 × probe phase  |  Subtraction: alternate-trial difference');
% TEOAE
y = yr0 - LH - 4 - RH;
lbl(p, 'High-pass (Hz)', RX, y, aw, false, 'oae_te');   num(p, 200, 'oae_te_hp',   ax, y, [0 5000], 'oae_te', sx(64)); y = y - RS;
lbl(p, 'Trimmed mean (%)', RX, y, aw, false, 'oae_te'); num(p, 20,  'oae_te_trim', ax, y, [0 50], 'oae_te');    y = y - RS;
lbl(p, 'No FPL calibration: SPL only', RX, y, hw, true, 'oae_te');
% Files (every OAE type): which raw recording when a data
% folder holds several — below the longest block (SFOAE, 5 rows)
y = yr0 - LH - 4 - RH - 5*RS - 6;
rec_file_menus(p, RX, ax, y, aw, sx(170), RS, RH, OFS);

% ── MEMR ─────────────────────────────────────────────────────────────────
app.h_memr_param_panel = mkpanel('MEMR Parameters');
p = app.h_memr_param_panel;
y0m = IH - 6;
% ART (Tag memr_art) — shown for the ART type only (navigate_results>update_param_panels)
y = textline(p, y0m, 'Wideband Middle Ear Muscle Reflex', true, 'memr_art');
y = y - 4;
y = textline(p, y, 'Frequency range: 0.2–8 kHz', false, 'memr_art');
y = textline(p, y, 'Metric: reflex magnitude (dB) vs. elicitor level (mean |change|, 0.5–2 kHz)', false, 'memr_art');
y = textline(p, y, 'Response: Δ ear-canal click level (dB) re. no elicitor', false, 'memr_art');
y = textline(p, y, 'Elicitor: broadband noise, multiple levels', false, 'memr_art');
textline(p, y, 'Output: growth functions and acoustic reflex thresholds (ART)', false, 'memr_art');
% Exploratory types (Tag memr_mx) — the type itself is described in Analysis Insight
y = textline(p, y0m, 'Wideband MEMR — Exploratory Analysis', true, 'memr_mx');
y = y - 4;
y = textline(p, y, 'One file per recording, shared by every exploratory type (_MX_)', false, 'memr_mx');
y = textline(p, y, 'Click spectra: complex mean over trials (magnitude + phase), 0.2–8 kHz', false, 'memr_mx');
y = textline(p, y, 'Baseline: click 1 (no elicitor); response: clicks 2–7', false, 'memr_mx');
y = textline(p, y, 'Noise floor: trial-to-trial variability; detected when SNR ≥ 3', false, 'memr_mx');
y = textline(p, y, 'Absorbance: FPL calibration of the same session (if recorded)', false, 'memr_mx');
textline(p, y, 'ART files are not read or changed', false, 'memr_mx');
% Files (ART and exploratory): same setting as in OAE Parameters
y = y0m - 8*(LH + 2) - 12 - RH;
rec_file_menus(p, PAD, PAD + sx(150), y, sx(146), sx(170), RS, RH, OFS);
% Plot default of the MEMR Growth Response average (app.h_output.chk)
y = y - RS;
uilabel(p,'Text','Plot Defaults:','FontSize',OFS,'FontColor',app.clr_black,'HorizontalAlignment','right', ...
    'Position',[PAD y sx(146) RH], ...
    'Tooltip','Saved images and the Results views start with these; change them live with Plot Settings');
O = app.h_output;
O.chk.resp_sd = pdef_btn(app, p, 'Response SD', [PAD+sx(150) y sx(130) RH], ...
    'Mean ± SD bands of the MEMR Growth Response average');
app.h_output = O;
% Labels right next to their controls (right-aligned in their column)
for hl = findall(app.MeasuresPanel, 'Type','uilabel')'
    if any(strcmp(hl.Tag, {'efr_harm_lbl','efr_win_lbl','efr_low_lbl','efr_high_lbl', ...
            'efr_sum_lbl','efr_norm_lbl','efr_dam_lbl'})) || strcmp(hl.Text, 'Data File:')
        hl.HorizontalAlignment = 'right';
    end
end

% Shown instead of the parameters when the type on screen is not selected
% for the run (navigate_results>do_measures)
app.h_param_hint = uilabel(app.MeasuresPanel, 'Text','', 'FontSize',FS-1, ...
    'FontColor',[0.45 0.45 0.45], 'HorizontalAlignment','center', 'WordWrap','on', ...
    'Position',[POS(1)+20 POS(2)+POS(4)/2-30 POS(3)-40 60], 'Visible','off');

    function efr_style_toggle(b)
        % ON / OFF pill: ON green, OFF red (setup_style 'onoff')
        setup_style(app, 'onoff', b);
    end

    function efr_sync_high(src)
        % keep "High harmonics" end within the max harmonics
        hto = findall(app.h_efr_param_panel,'Tag','efr_high_to');
        if ~isempty(hto), hto(1).Value = src.Value; end
    end

    function oae_unit_toggle(b)
        % EPL / SPL save toggles: subtle yellow = on; keep at least one on
        other = findall(app.h_oae_param_panel,'-regexp','Tag','^oae_save_');
        if ~any([other.Value]), b.Value = true; end
        for ob = other(:)'
            setup_style(app, 'chip', ob);
        end
    end

    function h = lbl(p, txt, x, y, w, grey, grp)
        % label for an OAE parameter row (grp → UserData, used to show per
        % subtype); row labels are right-aligned so they sit next to their
        % control, grey unit / note labels stay left-aligned
        if nargin < 6 || isempty(grey), grey = false; end
        fc = app.clr_black;  fs = OFS;  ha = 'right';
        if grey, fc = GRY; fs = OFS-1; ha = 'left'; end
        h = uilabel(p,'Text',txt,'FontSize',fs,'FontColor',fc,'HorizontalAlignment',ha,'Position',[x y w RH]);
        if nargin > 6, h.UserData = grp; end
    end

    function h = num(p, v, tag, x, y, lim, grp, w)
        if nargin < 8, w = FW; end
        h = uieditfield(p,'numeric','Value',v,'Limits',lim,'Tag',tag,'FontSize',OFS, ...
            'BackgroundColor','white','Position',[x y w RH]);
        if nargin > 6 && ~isempty(grp), h.UserData = grp; end
    end

    function dash(p, x, y)
        uilabel(p,'Text','–','FontSize',OFS,'HorizontalAlignment','center','Position',[x y+2 sx(14) LH]);
    end

    function sep(p, x, y)
        uilabel(p,'Text','|','FontSize',OFS,'FontColor',GRY,'HorizontalAlignment','center', ...
            'Position',[x y+2 sx(14) LH]);
    end

    function p = mkpanel(title)
        p = uipanel(app.MeasuresPanel,'Title',title,'FontSize',FS-1,'FontWeight','bold', ...
            'BackgroundColor',app.clr_bg,'Position',POS,'Scrollable','on','Visible','off');
        if isprop(p,'BorderColor'), p.BorderColor = app.clr_gold; end
    end

    function rec_file_menus(p, xl, xd, y, lw, dw, rs, rh, fs)
        % "Data File": which raw recording to use when a data folder holds
        % several (choose_recording). One setting, shown in the OAE and MEMR
        % panels (dropdowns with the same Tag stay in sync). The FPL
        % calibration always follows the data file: the calibration recorded
        % closest before it (no setting).
        items = {'Auto (Most Trials)','Auto (Most Recent)','Auto (Least Recent)', ...
                 'Manual (Ask Once)','Manual (Always)'};
        vals  = {'complete','latest','earliest','ask_once','ask_every'};
        tipD = ['Several raw recordings in a data folder (e.g. p0004 and p0014 sweptDPOAE): ' ...
            'Auto picks one without asking — Most Trials: all trials completed, then most ' ...
            'trials, then the most recent; Most Recent / Least Recent: by recording number. ' ...
            'Manual (Ask Once) asks and remembers the answer; Manual (Always) asks every time. ' ...
            'Manual shows the files with a quick preview of each (click = preview, ' ...
            'double-click = use it). The FPL calibration always follows the data file: the ' ...
            'one recorded closest before it. Choices are logged in Analysis/APAT_recording_choices_log.txt.'];
        uilabel(p,'Text','Data File:','FontSize',fs,'FontColor',app.clr_black, ...
            'Position',[xl y lw rh],'Tooltip',tipD);
        uidropdown(p,'Items',items,'ItemsData',vals,'Value','complete','Tag','rec_data_dd', ...
            'FontSize',fs,'BackgroundColor','white','Position',[xd y dw rh],'Tooltip',tipD, ...
            'ValueChangedFcn',@(src,~) rec_sync(src));
    end

    function rec_sync(src)
        % same value in the OAE and MEMR panels
        for h = findall(app.MeasuresPanel, 'Tag', src.Tag)'
            if h ~= src, h.Value = src.Value; end
        end
        update_summary(app);
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
RT     = res_style('theme', app);    % Results theme (private/res_style.m)

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
    'BackgroundColor',RT.sel,'FontColor',RT.ink, ...
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
    'FontName',RT.mono,'FontColor',RT.cap,'Position',[x cap_y 90 CAP_H],'Visible','off');
app.FigSubjDropdown = uidropdown(ctrl, ...
    'Items',{'-'},'Value','-', ...
    'FontSize',FS,'Position',[x y1+5 90 ROW_H-10],'Visible','off', ...
    'ValueChangedFcn',@(~,~) navigate_results(app,'subj'));

% Exclude button: leave subjects / conditions out of the group average
% (private/exclusions.m). Shown in the Individual view only (with the
% Subject dropdown); red "Excluded" when the subject on screen is excluded.
ex_fn = @exclusions;
app.res.excl_btn = uibutton(ctrl,'push','Text','Exclude', ...
    'FontSize',FS-2,'FontWeight','bold','BackgroundColor',app.clr_btn,'FontColor',app.clr_black, ...
    'Tooltip','Leave subjects or conditions out of the group average', ...
    'Position',[x+90+PAD y1+5 100 ROW_H-10], 'Visible','off', ...
    'ButtonPushedFcn',@(~,~) ex_fn(app,'dialog'));
x = x + 90 + PAD + 100 + PAD;
% Divider
uipanel(ctrl,'BorderType','none','BackgroundColor',app.clr_gold,'Position',[x y1+4 2 ROW_H-8]);
x = x + 2*PAD;

% ── 8 measure buttons (grouped with thin separators between groups) ─────
labels = APAT_app.measure_tab_labels();
% groups = {1:2, 3:4, 5:7, 8}  — ABR | EFR | OAE | MEMR
% MEMR: one button (the MEMR analysis on screen; ART by default) + a
% dropdown that picks it (ART, Vector, Growth …). The exploratory analyses
% (labels 9-15) also get a button each, kept hidden, so the measure-button
% highlighting works the same for every index (navigate_results>memr_sync).
groups   = {[1 2],[3 4],[5 6 7],[8]};
BTN_W    = 112;
SHORT_W  = 80;
app.res.btns = gobjects(1, numel(labels));
memr_idx = find(strncmp(labels, 'MEMR', 4));
app.res.grp_caps = gobjects(1, numel(groups));   % group captions (dark gold = measure on screen)

for gi = 1:numel(groups)
    grp = groups{gi};
    grp_names = {'ABR','EFR','OAE','MEMR'};
    app.res.grp_caps(gi) = caption(x, 200, grp_names{gi});
    if gi == 1, app.res.grp_caps(gi).FontColor = RT.gold_dk; end
    for k = 1:numel(grp)
        idx  = grp(k);
        lbl  = labels{idx};
        if strcmp(lbl, 'MEMR'), lbl = 'ART'; end      % display only (labels{} stay the internal keys)
        if idx == 8
            % MEMR button: width for the longest MEMR analysis name; its
            % UserData = the MEMR label index it opens
            btn = uibutton(ctrl,'push','Text',lbl, ...
                'FontSize',FS-1,'FontWeight','bold','BackgroundColor',app.clr_btn, ...
                'FontColor',app.clr_black,'Position',[x y1 BTN_W ROW_H],'UserData',idx, ...
                'ButtonPushedFcn',@(src,~) navigate_results(app,'meas_btn',src.UserData));
            app.res.btns(idx) = btn;
            res_style('icon', btn, idx);
            for mi = memr_idx(memr_idx > 8)           % hidden twins (highlight bookkeeping only)
                app.res.btns(mi) = uibutton(ctrl,'push','Text',strrep(labels{mi},'MEMR ',''), ...
                    'Visible','off','Position',[x y1 BTN_W ROW_H],'UserData',mi, ...
                    'ButtonPushedFcn',@(src,~) navigate_results(app,'meas_btn',src.UserData));
            end
            x = x + BTN_W + 4;
            mnames = cellfun(@(s) strrep(s,'MEMR ',''), labels(memr_idx), 'UniformOutput', false);
            mnames{1} = 'ART';
            app.res.memr_dd = uidropdown(ctrl, 'Items',mnames, 'ItemsData',memr_idx, ...
                'Value',8, 'FontSize',FS-2, 'Position',[x y1+6 120 ROW_H-12], ...
                'Tooltip','MEMR analysis to show (ART or one of the exploratory analyses)', ...
                'ValueChangedFcn',@(src,~) navigate_results(app,'meas_btn',src.Value));
            x = x + 120 + PAD;
            continue
        end
        bw   = ternary(numel(lbl) <= 5, SHORT_W, BTN_W);
        is_first = (gi==1 && k==1);
        btn = uibutton(ctrl,'push','Text',lbl, ...
            'FontSize',FS-1,'FontWeight','bold', ...
            'BackgroundColor',ternary(is_first,RT.sel,RT.btn), ...
            'FontColor',RT.ink, ...
            'Position',[x y1 bw ROW_H], ...
            'UserData',idx, ...
            'ButtonPushedFcn',@(~,~) navigate_results(app,'meas_btn',idx));
        app.res.btns(idx) = btn;
        res_style('icon', btn, idx);
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
    'FontSize',10,'FontWeight','bold','FontName',RT.mono,'FontColor',RT.cap, ...
    'Visible','off','Position',[x cap_y 148 CAP_H]);
app.FigFreqDD = uidropdown(ctrl, ...
    'Items',{'—'},'Value','—', ...
    'FontSize',FS,'Visible','off','Position',[x y1+6 148 ROW_H-12], ...
    'ValueChangedFcn',@(~,~) navigate_results(app,'freq'));

% ── Subject tracking chip (shown after clicking a subject point) ──────────
% Subtle-yellow chip (gold border) with the subject in dark bold text and a
% small dark ✕ (= stop tracking, also Esc), then "Individual". All direct
% children of the bar so bar_fit right-anchors them as one group.
TW = 270;  PW = 150;  CH = ROW_H - 12;
xt = max(x + 148 + 2*PAD, FIG_W - TW - 2*PAD);
pk_cap  = uilabel(ctrl,'Text','TRACKING','FontSize',10,'FontWeight','bold', ...
    'FontName',RT.mono,'FontColor',RT.cap,'Position',[xt cap_y 200 CAP_H],'Visible','off');
pk_pill = uipanel(ctrl,'BorderType','line','BackgroundColor',RT.sel, ...
    'Position',[xt y1+6 PW CH],'Visible','off');
try, pk_pill.BorderColor = RT.gold; catch, try, pk_pill.HighlightColor = RT.gold; catch, end, end
try, pk_pill.BorderWidth = 2; catch, end
pk_name = uilabel(ctrl,'Text','','FontSize',FS,'FontWeight','bold', ...
    'FontColor',RT.ink,'Tooltip','Subject tracked in every plot', ...
    'Position',[xt+12 y1+6 PW-46 CH],'Visible','off');
pk_clr  = uibutton(ctrl,'push','Text',char(10005),'FontSize',12,'FontWeight','bold', ...
    'BackgroundColor',RT.ink,'FontColor',RT.cream, ...
    'Tooltip','Stop tracking this subject (Esc)', ...
    'Position',[xt+PW-30 y1+6+round((CH-24)/2) 24 24],'Visible','off', ...
    'ButtonPushedFcn',@(~,~) subject_pick(app,'clear'));
pk_open = uibutton(ctrl,'push','Text','Individual','FontSize',FS-2,'FontWeight','bold', ...
    'BackgroundColor',RT.btn,'FontColor',RT.ink, ...
    'Tooltip','Open this subject''s individual results', ...
    'Position',[xt+PW+8 y1+6 100 CH],'Visible','off', ...
    'ButtonPushedFcn',@(~,~) subject_pick(app,'open'));
% [caption, name label, open button, ✕ (clear) button, chip backdrop]
pk_ui = gobjects(1,5);  pk_ui(1) = pk_cap;  pk_ui(2) = pk_name;  pk_ui(3) = pk_open;  pk_ui(4) = pk_clr;  pk_ui(5) = pk_pill;
app.res.pick_ui  = pk_ui;
app.res.sel_subj = '';

% ── Figure panels: 2 modes × 8 measures (stacked, one visible at a time) ──
N_MEAS = numel(labels);
app.res.panels   = cell(2, N_MEAS);
app.res.subj_data = cell(1, N_MEAS);
for mi = 1:N_MEAS
    app.res.subj_data{mi} = struct('names',{{}},'panels',{{}});
end
% Plot host = white card with a thin gold border (CM px from the window
% sides), above the one-line status strip (SG px gaps, STAT_H high).
% navigate_results>fit_panel keeps the same geometry after resizes.
CM = 8;  SG = 6;  STAT_H = 26;
CARD_Y = SG + STAT_H + SG;
CARD_H = PLOT_H - SG - CARD_Y;
for mode = 1:2
    for mi = 1:N_MEAS
        p = uipanel(app.ResultsTab,'BorderType','line','BackgroundColor',[1 1 1], ...
            'Position',[CM CARD_Y FIG_W-2*CM CARD_H],'Visible','off');
        try, p.BorderColor = RT.gold_line; catch, try, p.HighlightColor = RT.gold_line; catch, end, end
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
% "Plot Settings" (top-right of the plot area, above the figure panels):
% shows / hides the view controls of the plot on screen (private/plot_settings.m)
ps_fn = @plot_settings;
app.res.ps_on  = false;
app.res.ps_btn = uibutton(app.ResultsTab,'push','Text','Plot Settings', ...
    'FontSize',FS-2,'FontWeight','bold','BackgroundColor',RT.gold,'FontColor',RT.ink, ...
    'Tooltip','Show / hide the controls of this plot (conditions, subjects, shading, axis limits …)', ...
    'Position',[FIG_W-190 PLOT_H-46 170 32],'Enable','off', ...
    'ButtonPushedFcn',@(~,~) ps_fn(app,'toggle'));
% "Save Image" / "Save As New" (left of Plot Settings): write the view on
% screen — with its current Plot Settings and axes — over its auto-saved PNG,
% or as a new numbered copy (<name>_2.png …) (private/save_view.m)
app.res.save_btn = uibutton(app.ResultsTab,'push','Text','Save Image', ...
    'FontSize',FS-2,'FontWeight','normal','BackgroundColor',RT.btn,'FontColor',RT.ink, ...
    'Tooltip','Save the view on screen (as shown now) over its saved image', ...
    'Position',[FIG_W-190-8-128 PLOT_H-46 128 32],'Enable','off', ...
    'ButtonPushedFcn',@(~,~) save_view_cb(app,'save'));
app.res.savenew_btn = uibutton(app.ResultsTab,'push','Text','Save As New', ...
    'FontSize',FS-2,'FontWeight','normal','BackgroundColor',RT.btn,'FontColor',RT.ink, ...
    'Tooltip','Save the view on screen as a new image next to the saved one (name_2.png, name_3.png …)', ...
    'Position',[FIG_W-190-2*(8+128) PLOT_H-46 128 32],'Enable','off', ...
    'ButtonPushedFcn',@(~,~) save_view_cb(app,'new'));
% short confirmation under the buttons (hidden after a few seconds)
app.res.save_msg = uilabel(app.ResultsTab,'Text','','FontSize',FS-3,'FontWeight','bold', ...
    'FontColor',RT.gold_dk,'BackgroundColor',[1 1 1],'HorizontalAlignment','right', ...
    'Position',[FIG_W-20-560 PLOT_H-46-24 560 20],'Visible','off');
% Status strip under the plot card: one line "OAE › DPOAE › AVERAGE  GROUP …
% n SUBJECTS · n CONDITIONS  EXCLUDED: …" + "SAVED hh:mm" right
% (res_style 'status'; refreshed on view changes and after saves)
sb = uipanel(app.ResultsTab,'BorderType','line','BackgroundColor',RT.status_bg, ...
    'Position',[CM SG FIG_W-2*CM STAT_H]);
try, sb.BorderColor = RT.gold_line; catch, try, sb.HighlightColor = RT.gold_line; catch, end, end
SW = FIG_W - 2*CM;
app.res.status_lbl = uilabel(sb,'Text','','FontSize',11,'FontWeight','bold','FontName',RT.mono, ...
    'FontColor',RT.status_fg,'Position',[12 1 SW-170 STAT_H-3]);
app.res.status_save = uilabel(sb,'Text','','FontSize',11,'FontWeight','bold','FontName',RT.mono, ...
    'FontColor',RT.status_fg,'HorizontalAlignment','right','Position',[SW-152 1 140 STAT_H-3]);
app.res.status_bar = sb;
app.res.last_save  = [];
% Gold underline under the measure button on screen (res_style 'underline';
% made last in the bar so it sits on top of the buttons)
app.res.meas_line = uipanel(ctrl,'BorderType','none','BackgroundColor',RT.gold, ...
    'Tag','res_meas_line','Position',[0 0 4 3],'Visible','off');
% Start in Average mode, measure 1 (ABR Thresholds)
app.res.mode     = 2;
app.res.meas_idx = 1;
app.res.panels{2,1}.Visible = 'on';
res_style('bar_sync', app);
res_style('status', app);

% ── Blind-mode cover: hides the whole Results tab (subject names, condition
%    tabs, figure titles) during a blinded run until the user unblinds.
%    Created last so it sits above every other Results-tab component.
app.BlindOverlay = uipanel(app.ResultsTab,'BorderType','none', ...
    'BackgroundColor',app.clr_black,'Position',[0 0 FIG_W TAB_H-30],'Visible','off');
CW = 560;  CHh = 190;
bc = uipanel(app.BlindOverlay,'BorderType','line','BackgroundColor',app.clr_panel, ...
    'Position',[round((FIG_W-CW)/2) round((TAB_H-30-CHh)/2) CW CHh]);
if isprop(bc,'BorderColor'), bc.BorderColor = app.clr_gold; end
uipanel(bc,'BorderType','none','BackgroundColor',app.clr_gold,'Position',[0 CHh-6 CW 6]);
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


    function h = caption(x, w, txt)
        % small bold monospaced caps, muted grey (FontSize 10 = caption for bar_fit)
        h = uilabel(ctrl,'Text',upper(txt),'FontSize',10,'FontWeight','bold', ...
            'FontName',RT.mono,'FontColor',RT.cap,'Position',[x cap_y w CAP_H]);
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
REF_W = 250;                              % Ref dropdown + help button (top right)
app.PeakEditInfoLabel = uilabel(app.PeakEditPanel, ...
    'Text','', 'FontSize',FS, 'FontWeight','bold', 'WordWrap','on', ...
    'FontColor',app.clr_black, 'HorizontalAlignment','center', ...
    'Position',[EDIT_X TAB_H-INFO_H-PAD EDIT_W-REF_W INFO_H]);

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
% Remember the original layout so each run can rebuild these axes exactly
% (ABR_dtw/findPeaks_dtw delete + recreate them while editing).
setappdata(app.PeakEditPanel, 'wf_ax_pos',   app.PeakEditWfAx.Position);
setappdata(app.PeakEditPanel, 'edit_ax_pos', app.PeakEditAx.Position);

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
    'FontColor',[1 1 1], 'BackgroundColor',app.clr_on, ...
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
% Earl (1983) latency reference + help — top-right corner, beside the
% info line, so they never collide with the NEL / Sex boxes.
rx = EDIT_X + EDIT_W - REF_W + 6;  ry = TAB_H - INFO_H - PAD + (INFO_H - WAVE_H)/2;
uilabel(app.PeakEditPanel, 'Text','Ref:', 'FontSize',FS-3, 'FontWeight','bold', ...
    'Position',[rx ry+4 34 18]);
app.PeakEditRefDD = uidropdown(app.PeakEditPanel, 'Items',{'Off','Absolute','Relative to Wave I'}, 'Value','Off', ...
    'FontSize',FS-3, 'FontWeight','bold', ...
    'Tooltip',['Earl (1983) chinchilla latency ranges for Waves I–V at this level. ' ...
               'Absolute: latency after click onset. Relative to Wave I: interpeak ranges placed ' ...
               'from your Wave I pick (use this when the NEL / system delay differs).'], ...
    'Position',[rx+36 ry 168 WAVE_H], ...
    'ValueChangedFcn',@(dd,~) peak_ref_changed(app, dd));
app.PeakEditHelpBtn = uibutton(app.PeakEditPanel, 'push', 'Text','?', ...
    'FontSize',FS-1, 'FontWeight','bold', 'BackgroundColor',app.clr_btn, ...
    'Tooltip','Help: chinchilla ABR Waves I–V (Earl, 1983)', ...
    'Position',[rx+36+168+6 ry WAVE_H+4 WAVE_H], ...
    'ButtonPushedFcn',@(~,~) peak_wave_help(app));
% Visual threshold: sets the level currently being edited as the threshold.
% Bottom row, in the slot left of Done (hidden with Done during Accept/Redo/Cancel).
app.PeakEditThreshBtn = uibutton(app.PeakEditPanel, 'push', ...
    'Text','⊥ Set as Threshold', 'FontSize',FS-3, 'FontWeight','bold', ...
    'BackgroundColor',app.clr_btn, 'Visible','off', ...
    'Tooltip','Make the level shown in the editor the visual threshold (lower levels get no peaks)', ...
    'Position',[btn_x+(BTN_W+PAD) PAD BTN_W BTN_H]);

% NEL / Sex confirmation — right end of the tool row. Prefilled by ABR_dtw
% (existing file → acquisition metadata); amber = '?' (not confirmed).
DD_W = 62;
sx = FIG_W - 2*PAD - DD_W;
app.PeakEditSexDD = uidropdown(app.PeakEditPanel, 'Items',{'?','M','F'}, 'Value','?', ...
    'FontSize',FS-3, 'FontWeight','bold', 'Visible','off', ...
    'Tooltip','Confirm the subject''s sex (saved in the peaks file)', ...
    'Position',[sx WAVE_Y DD_W WAVE_H]);
uilabel(app.PeakEditPanel, 'Text','Sex:', 'Tag','peak_meta_lbl', 'FontSize',FS-3, ...
    'FontWeight','bold', 'Visible','off', 'HorizontalAlignment','right', ...
    'Position',[sx-40 WAVE_Y+4 36 18]);
nx = sx - 40 - 14 - DD_W;
app.PeakEditNelDD = uidropdown(app.PeakEditPanel, 'Items',{'?','1','2'}, 'Value','?', ...
    'FontSize',FS-3, 'FontWeight','bold', 'Visible','off', ...
    'Tooltip','Confirm which NEL recorded this session (saved in the peaks file)', ...
    'Position',[nx WAVE_Y DD_W WAVE_H]);
uilabel(app.PeakEditPanel, 'Text','NEL:', 'Tag','peak_meta_lbl', 'FontSize',FS-3, ...
    'FontWeight','bold', 'Visible','off', 'HorizontalAlignment','right', ...
    'Position',[nx-40 WAVE_Y+4 36 18]);
end


function abr_wave_all(app, on)
%ABR_WAVE_ALL  Waves All / Clear (ABR Peaks).
for c = app.h_abr_wave_checks(:)'
    if isgraphics(c), c.Value = on; end
end
update_summary(app);
end


function abr_freq_chip(app, action)
%ABR_FREQ_CHIP  Frequency chip / All / Clear → selection of the ABR type on
%   screen (Thresholds and Peaks are independent), then refresh the summary.
abr_freq_sync(app, action);
update_summary(app);
end


function style_snap(b)
%STYLE_SNAP  Snap toggle look: green ON / red OFF (as every ON/OFF pill).
if b.Value
    b.Text = 'ON';  b.BackgroundColor = [0.18 0.49 0.31]; b.FontColor = [1 1 1];
else
    b.Text = 'OFF'; b.BackgroundColor = [0.69 0.23 0.18]; b.FontColor = [1 1 1];
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


function peak_ref_changed(app, dd)
%PEAK_REF_CHANGED  Ref dropdown: store the mode and redraw the bands now.
setappdata(app.UIFigure, 'peak_ref_mode', dd.Value);
ensure_peaks_path(app);
try
    earl_ref_draw('refresh', app.UIFigure);
catch
end
end


function peak_wave_help(app)
%PEAK_WAVE_HELP  Open the Waves I–V help window (works at any time).
ensure_peaks_path(app);
try
    abr_wave_help(app.UIFigure);
catch err
    uialert(app.UIFigure, sprintf('Could not open the help window: %s', err.message), 'Help');
end
end


function ensure_peaks_path(app)
if exist('earl_ref_data','file') ~= 2
    addpath(fullfile(app.code_dir, 'ABR', 'Peaks'));
end
end


function close_apat(app, fig)
%CLOSE_APAT  CloseRequestFcn. Any error while asking closes the window
%   anyway (and is printed), so the × can never be dead.
try
    close_apat_ask(app, fig);
catch err
    fprintf(2, 'APAT close: %s - closing without asking.\n', err.message);
    do_close(app, fig, false);
end
end


function close_apat_ask(app, fig)
%CLOSE_APAT_ASK  Window close (red ×). Asks first, without blocking: closing
%   stops a running analysis and clears everything shown in the Results tab
%   (files already saved on disk are kept). The question is a non-blocking
%   uiconfirm (a blocking dialog inside CloseRequestFcn can stall the
%   window); its answer calls do_close. Pressing × again while the question
%   is up closes at once, so the window can never get stuck open. If the
%   question cannot be shown, APAT closes without asking.
try
    if isappdata(fig, 'apat_closing')           % second × while asking → close now
        do_close(app, fig, false);
        return;
    end
    setappdata(fig, 'apat_closing', true);
catch
end
running = false;
try, running = isappdata(fig, 'apat_running') && isequal(getappdata(fig, 'apat_running'), true); catch, end
if running
    msg = sprintf(['An analysis is still running.\n\nClosing APAT will stop it now. Work that ' ...
        'has finished is saved, but the figures in the Results tab and any unsaved ' ...
        'settings will be lost.\n\nClose APAT?']);
else
    msg = sprintf(['APAT will close.\n\nThe figures in the Results tab and any unsaved ' ...
        'settings will be lost (files already saved on disk are kept).\n\nClose APAT?']);
end
try
    uiconfirm(fig, msg, 'Close APAT', 'Options',{'Close APAT','Cancel'}, ...
        'DefaultOption',2, 'CancelOption',2, 'Icon','warning', ...
        'CloseFcn',@(~,evt) on_answer(app, fig, evt, running));
catch err
    fprintf(2, 'APAT: close question could not be shown (%s) - closing.\n', err.message);
    do_close(app, fig, running);
end
end


function on_answer(app, fig, evt, running)
%ON_ANSWER  Answer to the close question.
try
    if strcmp(evt.SelectedOption, 'Close APAT')
        do_close(app, fig, running);
    else
        try, rmappdata(fig, 'apat_closing'); catch, end
    end
catch
    do_close(app, fig, running);
end
end


function do_close(app, fig, running)
%DO_CLOSE  Shut down: "Closing APAT…" box, stop a running analysis, timers,
%   peak editor, hidden figures, then the window. Always completes, even when
%   the app object is already deleted; each step is guarded so one failure
%   cannot leave the window stuck open.
try                                                       % no mouse-move / resize callbacks while closing
    if isvalid(fig), fig.WindowButtonMotionFcn = '';  fig.SizeChangedFcn = '';  fig.WindowKeyPressFcn = ''; end
catch
end
try
    if isvalid(fig)
        uiprogressdlg(fig, 'Title','Closing APAT', 'Indeterminate','on', ...
            'Message',ternary_c(running, 'Stopping the analysis and closing APAT — please wait…', ...
            'Closing APAT — please wait…'));
        drawnow;
    end
catch
end
try
    if isvalid(app)
        try, app.abort_requested = true; catch, end      % stop a running analysis
    end
catch
end
try                                                       % spinner / relayout timers
    t = [timerfind('Name','APAT_spinner'), timerfind('Name','APAT_relayout'), timerfind('Name','APAT_runcard'), ...
         timerfind('Name','APAT_savemsg'), timerfind('Name','APAT_chinhop')];
    if ~isempty(t), stop(t); delete(t); end
catch
end
try, uiresume(fig); catch, end                            % release a waiting peak editor
try                                                       % hidden analysis figures left open
    hid = findall(0, 'Type','figure', 'Visible','off');
    hid = hid(hid ~= fig);
    if ~isempty(hid), delete(hid); end
catch
end
try
    if isvalid(app), delete(app); end
catch err
    fprintf(2, 'APAT close: app shutdown step failed (%s) - closing the window anyway.\n', err.message);
end
try
    if isvalid(fig), delete(fig); end
catch err
    fprintf(2, 'APAT close: window delete failed (%s).\n', err.message);
end
try                                                       % last resort: plain close, no callbacks
    if isvalid(fig)
        fprintf(2, 'APAT close: window still open - forcing it closed.\n');
        fig.CloseRequestFcn = 'closereq';
        fig.SizeChangedFcn  = '';
        delete(fig);
    end
catch err
    fprintf(2, ['APAT close: could not close the window (%s). Run in the Command Window:\n' ...
        '   delete(timerfindall); delete(findall(0,''Type'',''figure''))\n'], err.message);
end
end


function s = ternary_c(c, a, b)
if c, s = a; else, s = b; end
end
