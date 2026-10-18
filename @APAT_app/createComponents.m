function createComponents(app)
%CREATECOMPONENTS  Build all UI components for APAT_app.
%   Creates the figure window, black header bar, and three tabs:
%   Setup, Results, Status. Each tab is built by a local function.
%
%   Layout (Oct 16 2026, layout managers): the Setup and Data Status tabs
%   are uigridlayout trees inside a full-tab panel (Units normalized), so
%   MATLAB sizes, pads and scrolls them at any window size — no MATLAB code
%   runs for them on resize. The few pixel-placed parts are positioned by
%   cheap size callbacks: header + tab group (UIFigure SizeChangedFcn →
%   fig_layout), the Results bar / plot host / status strip (results root
%   panel → res_layout) and the buttons over the plots (plot host →
%   host_layout). Floating panels (condition style popup, Plot Settings,
%   notices, blind cover, peak editor) are children of plain containers,
%   never of a grid.

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

HDR_H = 110;

app.UIFigure = uifigure( ...
    'Name','Auditory Physiology Analysis Toolkit (APAT)', ...
    'Color',app.clr_bg, ...
    'AutoResizeChildren','off', ...
    'CloseRequestFcn',@(src,~) close_apat(app, src));

% Size the window to the screen's usable area (excludes the menu bar and
% Dock/taskbar, wherever they are). WindowState='maximized' was unreliable
% on macOS. Resizes: fig_layout (header + tab group, immediate) and
% relayout_results (debounced: plot margins, Results bar widths, peak editor).
[FIG_W, FIG_H] = usable_figure_size(app.UIFigure);
TAB_H = FIG_H - HDR_H;

% ── Header ─────────────────────────────────────────────────────────────
% Title / subtitle on the left; the right block (run status card, or the
% chinchilla with its sign) is a fixed-size panel kept at the right edge.
app.HeaderPanel = uipanel(app.UIFigure, ...
    'BorderType','none','BackgroundColor',app.clr_black, ...
    'Position',[0 FIG_H-HDR_H FIG_W HDR_H]);
HR_W = 732;                                       % run card 700 + margins
HR = uipanel(app.HeaderPanel, 'BorderType','none', 'BackgroundColor',app.clr_black, ...
    'Position',[max(0, FIG_W-HR_W) 0 HR_W HDR_H]);
setappdata(app.HeaderPanel, 'apat_hdr_right', HR);
TT_W = max(160, FIG_W - HR_W - 24);

app.TitleLabel = uilabel(app.HeaderPanel, ...
    'Text','Auditory Physiology Analysis Toolkit (APAT)', ...
    'Position',[16 54 TT_W 36], ...
    'FontSize',26,'FontWeight','bold','FontColor',app.clr_gold);

app.SubtitleLabel = uilabel(app.HeaderPanel, ...
    'Text','Auditory Neurophysiology and Modeling Lab  —  Purdue University', ...
    'Position',[16 30 TT_W 22], ...
    'FontSize',15,'FontColor',[0.88 0.84 0.74]);

% Run Analysis lives in the Setup tab's Run Summary card. The header holds
% the run status card (status, current step, progress bar, elapsed / time
% left, Stop) so it stays visible from every tab while an analysis runs.
% Hidden when idle; driven by private/run_status.m.
CARD_W = 700;  CARD_H = 84;
CARD_X = HR_W - CARD_W - 16;  CARD_Y = round((HDR_H - CARD_H) / 2);
CREAM  = [0.88 0.84 0.74];                        % header subtitle colour
MONO   = mono_font();                             % pixel-style captions (no pixel font in MATLAB)
icon_dir = fullfile(fileparts(mfilename('fullpath')), 'icons');
R = struct();
% Same look as the rest of APAT: header black, gold border (as the Setup
% cards), gold title (as the APAT title), cream text (as the subtitle),
% small caps caption (as the Run Summary tiles), beige Stop button.
% Left: the chinchilla on a small track (private/run_status.m animates it).
R.card = uipanel(HR, 'BorderType','line', 'BackgroundColor',app.clr_black, ...
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
% Pause (left of Stop): the run waits at the next step until Resume
% (APAT_app>PauseButtonPushed / wait_if_paused). Buttons are laid out in a
% row, each as wide as its text (private/run_status>row).
R.pause = uibutton(R.card,'push', ...
    'Text',[char(10074) char(10074) '  Pause'], 'FontSize',13, 'FontWeight','bold', ...
    'FontColor',app.clr_black, 'BackgroundColor',app.clr_btn, ...
    'Position',[CARD_W-STOP_W-14-96 round((CARD_H-30)/2) 90 30], ...
    'Tooltip','Pause after the current step (Resume continues; Stop is still available)', ...
    'Visible','off', ...
    'ButtonPushedFcn',@(~,~) PauseButtonPushed(app));
% After a Stop / error with analyses left (run checkpoint): Stop becomes
% "Resume" (top) and "Restart" appears under it (private/run_status 'offer')
B_X = CARD_W-STOP_W-14;  B2_H = 30;
setappdata(app.StopButton, 'apat_pos_one', [B_X round((CARD_H-STOP_H)/2) STOP_W STOP_H]);
setappdata(app.StopButton, 'apat_pos_top', [B_X CARD_H-B2_H-9 STOP_W B2_H]);
R.restart = uibutton(R.card,'push', ...
    'Text',[char(8635) '  Restart'], 'FontSize',13, 'FontWeight','bold', ...
    'FontColor',app.clr_black, 'BackgroundColor',app.clr_btn, ...
    'Position',[B_X 9 STOP_W B2_H], ...
    'Tooltip','Run the same analyses again from the start, with the current settings', ...
    'Visible','off', ...
    'ButtonPushedFcn',@(~,~) ResumeOfferPushed(app, 'Start over'));
setappdata(R.restart, 'apat_pos_one', [B_X round((CARD_H-STOP_H)/2) STOP_W STOP_H]);
setappdata(R.restart, 'apat_pos_bot', [B_X 9 STOP_W B2_H]);
% Live part of the card as a small web page (icons/run_card.html): clock,
% progress bar, pulsing "recording" dot and the chinchilla are animated by
% the page itself, so they keep time while MATLAB is busy with an analysis
% (MATLAB's own controls only redraw when the analysis lets them).
% run_status sends it the state (R.html.Data). Without uihtml (older
% MATLAB) the MATLAB-drawn pieces above are used as before.
try
    R.html = uihtml(R.card, 'HTMLSource', fullfile(icon_dir, 'run_card.html'), ...
        'Position',[1 1 CARD_W-232 CARD_H-2]);       % right part: the buttons (two in a row)
    old = {R.lane, R.prop, R.chin, R.zz, R.caption, R.elapsed, R.title, ...
           app.h_progress_label, R.track, R.fill, R.count};
    for k = 1:numel(old), old{k}.Visible = 'off'; end
catch
    if isfield(R, 'html'), R = rmfield(R, 'html'); end
end
app.h_run = R;

% Header chinchilla holding a sign (right block; hidden while the run card
% is shown). Message: private/chin_sign.m from chin_messages.txt, picked
% when the Setup tab is built / shown and when a user profile is loaded.
G = struct();
CH_W = 78;  CH_H = 66;  SG_W = 250;  SG_H = 48;
ch_x = HR_W - 22 - CH_W;  sg_x = ch_x + 6 - SG_W;  sg_y = 4 + 22;
GOLD_SH = [0.557 0.435 0.243];                    % #8E6F3E: sign shadow + post
G.post   = uipanel(HR, 'BorderType','none', 'BackgroundColor',GOLD_SH, ...
    'Position',[sg_x+SG_W-22 sg_y-14 4 14]);
G.shadow = uipanel(HR, 'BorderType','none', 'BackgroundColor',GOLD_SH, ...
    'Position',[sg_x+3 sg_y-3 SG_W SG_H]);
G.panel  = uipanel(HR, 'BorderType','line', 'BackgroundColor',[0.965 0.933 0.827], ...
    'Position',[sg_x sg_y SG_W SG_H]);
if isprop(G.panel,'BorderColor'), G.panel.BorderColor = app.clr_black; end
try, G.panel.BorderWidth = 3; catch, end
G.label  = uilabel(G.panel, 'Text','', 'WordWrap','on', 'FontName',MONO, 'FontSize',12, ...
    'FontWeight','bold', 'FontColor',app.clr_black, 'VerticalAlignment','center', ...
    'Position',[8 2 SG_W-22 SG_H-10]);
G.chin   = uiimage(HR, 'Position',[ch_x 4 CH_W CH_H], ...
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

buildSetupTab(app);
buildResultsTab(app, FIG_W, TAB_H);
buildStatusTab(app);
buildPeakEditPanel(app, FIG_W, TAB_H);

% If the window manager applied the window size after we measured it, the
% layout no longer matches the window (e.g. an empty band at the top).
% Snap the window back to the measured size, keeping its top edge fixed.
drawnow;
p_now = app.UIFigure.Position;
if abs(p_now(3)-FIG_W) > 2 || abs(p_now(4)-FIG_H) > 2
    app.UIFigure.Position = [p_now(1), p_now(2) + p_now(4) - FIG_H, FIG_W, FIG_H];
    drawnow;
end
% Build size (also marks "built" for relayout_results); the pixel-placed
% parts follow the real window size from here on
setappdata(app.UIFigure, 'apat_design_size', [FIG_W FIG_H]);
fig_layout(app);
res_layout(app);
host_layout(app);
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
% Results bar column widths (Tracking right-anchored, measure buttons
% shared out when the bar is narrower than their design widths)
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
%RELAYOUT_CB  UIFigure SizeChangedFcn (silent): header + tab group follow
%   the window at once (fig_layout, a few Position sets); plot margins,
%   Results bar widths, peak editor and Plot Settings follow 0.25 s after
%   the last size change (relayout_results, debounced).
try
    if ~isvalid(app), return; end
    fig_layout(app);
    relayout_results(app, 'changed');
catch
end
end


function fig_layout(app)
%FIG_LAYOUT  Header (title width, right block at the right edge), tab group
%   and peak editor overlay for the current window size. Silent.
try
    fp = app.UIFigure.Position;  W = fp(3);  H = fp(4);
    HDR_H = 110;
    app.HeaderPanel.Position = [0 max(0, H-HDR_H) W HDR_H];
    HR = getappdata(app.HeaderPanel, 'apat_hdr_right');
    hw = 732;
    if ~isempty(HR) && isgraphics(HR)
        hw = HR.Position(3);
        HR.Position = [max(0, W-hw) 0 hw HDR_H];
    end
    tw = max(120, W - hw - 24);
    app.TitleLabel.Position    = [16 54 tw 36];
    app.SubtitleLabel.Position = [16 30 tw 22];
    app.TabGroup.Position = [0 0 W max(60, H-HDR_H)];
    if ~isempty(app.PeakEditPanel) && isgraphics(app.PeakEditPanel)
        app.PeakEditPanel.Position = [0 0 W max(60, H-HDR_H)];
    end
catch
end
end


function res_cb(app)
%RES_CB  SizeChangedFcn of the Results root panel (silent wrapper).
try
    if isvalid(app), res_layout(app); end
catch
end
end


function res_layout(app)
%RES_LAYOUT  Results tab: control bar (top, its own grid inside), gold rule,
%   plot host (white cards + buttons) and status strip (bottom) for the
%   size of the Results root panel. Four Position sets.
try
    P = getappdata(app.res.root, 'apat_parts');
    rp = getpixelposition(app.res.root);  W = rp(3);  H = rp(4);
    if W < 50 || H < 50, return; end
    BAR_H = P.bar.Position(4);  ST_H = 26;  M = 8;  G = 6;
    P.bar.Position    = [0 H-BAR_H W BAR_H];
    P.rule.Position   = [0 H-BAR_H-2 W 2];
    P.status.Position = [M G max(20, W-2*M) ST_H];
    y0 = G + ST_H + G;
    P.host.Position   = [M y0 max(20, W-2*M) max(20, H-BAR_H-2-G-y0)];
catch
end
end


function host_cb(app)
%HOST_CB  SizeChangedFcn of the Results plot host (silent wrapper).
try
    if isvalid(app), host_layout(app); end
catch
end
end


function host_layout(app)
%HOST_LAYOUT  Plot Settings / Save Image / Save As New (top right of the
%   plot area, over the cards) and the save message under them.
try
    h  = app.res.plot_host;
    pp = h.Position;  hw = pp(3);  hh = pp(4);
    x = hw - 12;
    for f = {'ps_btn','save_btn','savenew_btn'}
        b = app.res.(f{1});
        if isempty(b) || ~isvalid(b), continue; end
        w = b.Position(3);
        b.Position = [x-w, hh-8-32, w, 32];
        x = x - w - 8;
    end
    m = app.res.save_msg;
    if ~isempty(m) && isvalid(m)
        w = max(100, min(560, hw-24));
        m.Position = [hw-12-w, hh-8-32-24, w, 20];
    end
catch
end
end


function chips_cb(app)
%CHIPS_CB  SizeChangedFcn of the Subjects section (silent): number of chip
%   columns for the new width (private/setup_chips.m; nothing to do when it
%   did not change).
try
    if isvalid(app), setup_chips(app, 'subj'); end
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


function buildSetupTab(app)
%BUILDSETUPTAB  Setup tab (Oct 16 2026 layout, approved design "Combined"):
%   row 1 User | Project Settings; row 2 Subjects | Conditions | Run Options |
%   Output; row 3 Auditory Measures. Every section is a panel with a black
%   header strip (cream bold title, gold tag number 01–07; setup_section).
%   Built with uigridlayout only: rows / columns are fixed or weighted, so
%   MATLAB does the sizing, padding and scrolling at any window size.
FS    = 15;                 % parameter panels (buildParamPanels)
FT    = 14;                 % rows 1–2 text
LH    = 24;
MONO  = mono_font();
GREY  = app.clr_txt2;
BG    = app.clr_bg;
PN    = app.clr_panel;
STRIP_TXT = [0.92 0.85 0.62];   % #EBD99F: counts / links in the header strips

% Full-tab panel (follows the tab by itself: normalized units) holding the
% root grid; floating parts (condition style popup) are children of the tab.
root = uipanel(app.SetupTab, 'BorderType','none', 'BackgroundColor',BG, ...
    'Units','normalized', 'Position',[0 0 1 1]);
G0 = grd(root, {152, '1x', '1.7x'}, {'1x'}, BG, [8 8 8 8], 8, 8);
R1 = grd(G0, {'1x'}, {230, '1x'}, BG, [0 0 0 0], 0, 8);              lay(R1, 1, 1);
R2 = grd(G0, {'1x'}, {'1x', 230, 262, 400}, BG, [0 0 0 0], 0, 8);    lay(R2, 2, 1);

% ── 01 User ─────────────────────────────────────────────────────────────
[sec_p, C] = setup_section(app, R1, [1 1], '01', 'User', {32, 32, '1x'}, {'1x', '1x'});
app.UserPanel = sec_p;
C.Padding = [12 10 12 10];  C.RowSpacing = 10;
app.ProfileDropdown = uidropdown(C, ...
    'Items',{'(no profiles)'},'Value','(no profiles)', ...
    'BackgroundColor','white', 'FontSize',FT,'FontWeight','bold', ...
    'ValueChangedFcn',@(~,~) ProfileDropdownChanged(app));
lay(app.ProfileDropdown, 1, [1 2]);
app.NewUserBtn = uibutton(C,'push','Text','New User', ...
    'FontSize',FT-1,'BackgroundColor',app.clr_btn, ...
    'ButtonPushedFcn',@(~,~) NewUserButtonPushed(app));
lay(app.NewUserBtn, 2, 1);
app.SaveUserBtn = uibutton(C,'push','Text','Save User', ...
    'FontSize',FT-1,'BackgroundColor',app.clr_btn, ...
    'ButtonPushedFcn',@(~,~) SaveUserButtonPushed(app));
lay(app.SaveUserBtn, 2, 2);

% ── 02 Project Settings ─────────────────────────────────────────────────
% label | control | button, then a gold divider and the live project
% status (subjects / conditions in the roster, folders found)
[sec_p, C] = setup_section(app, R1, [1 2], '02', 'Project Settings', ...
    {28, 28, 28}, {'fit', '1x', 130, 2, 210});
app.ProjectPanel = sec_p;
C.Padding = [12 10 12 10];  C.ColumnSpacing = 10;
L = uilabel(C,'Text','Root Directory','FontColor',GREY,'FontSize',FT);  lay(L, 1, 1);
app.RootDirField = uieditfield(C,'text','Value','', ...
    'FontSize',FT-1,'BackgroundColor','white', ...
    'ValueChangedFcn',@(~,~) chinroster_ops(app,'scan',''));
lay(app.RootDirField, 1, 2);
app.BrowseBtn = uibutton(C,'push','Text','Browse…', ...
    'FontSize',FT-1,'BackgroundColor',app.clr_btn, ...
    'ButtonPushedFcn',@(~,~) BrowseButtonPushed(app));
lay(app.BrowseBtn, 1, 3);
L = uilabel(C,'Text','Subject Roster','FontColor',GREY,'FontSize',FT);  lay(L, 2, 1);
app.RosterDropdown = uidropdown(C, ...
    'Items',{'(set root directory first)'},'Value','(set root directory first)', ...
    'FontSize',FT-1,'BackgroundColor','white', ...
    'ValueChangedFcn',@(~,~) RosterDropdownChanged(app));
lay(app.RosterDropdown, 2, 2);
% Create / edit the subject roster inside APAT (no Excel needed)
rb_fn = @roster_builder;            % private function: take the handle here (see SizeChangedFcn note)
app.RosterBuildBtn = uibutton(C,'push','Text','Create / Edit…', ...
    'FontSize',FT-1,'BackgroundColor',app.clr_btn, ...
    'Tooltip','Create a new subject roster, or edit the one selected, without opening Excel', ...
    'ButtonPushedFcn',@(~,~) rb_fn(app));
lay(app.RosterBuildBtn, 2, 3);
L = uilabel(C,'Text','Experiment','FontColor',GREY,'FontSize',FT);  lay(L, 3, 1);
% Experiments: one toggle button per roster sheet (several can be run in
% one go), built by private/sheet_sel.m ('list') in this grid ('fit'
% columns; scrolls sideways when there are many)
app.SheetPanel = grd(C, {'1x'}, {'1x'}, PN, [1 1 1 1], 0, 6);
app.SheetPanel.Scrollable = 'on';
lay(app.SheetPanel, 3, [2 3]);
app.h_sheet_btns = gobjects(0);
L = uilabel(app.SheetPanel,'Text','(load chinroster first)','Tag','sheet_msg', ...
    'FontSize',FT-1,'FontColor',GREY);
lay(L, 1, 1);
% Project status column (filled by update_summary): right after the controls
dv = uipanel(C,'BorderType','none','BackgroundColor',app.clr_gold);  lay(dv, [1 3], 4);
app.h_summary_proj = gobjects(1,3);
for si = 1:3
    app.h_summary_proj(si) = uilabel(C,'Text','','FontSize',FT-1,'Interpreter','html');
    lay(app.h_summary_proj(si), si, 5);
end

% ── 03 Subjects ─────────────────────────────────────────────────────────
% chips in a scrollable grid (columns from the width: private/setup_chips.m,
% re-counted when the section is resized), gold rule, action buttons; the
% "n of N" count sits in the header strip
[sec_p, C, sstrip] = setup_section(app, R2, [1 1], '03', 'Subjects', {'1x', 1, 26}, {'1x'});
app.SubjectsPanel = sec_p;
CG = uigridlayout(C, 'RowHeight',{28}, 'ColumnWidth',{'1x'}, 'Padding',[4 4 4 4], ...
    'RowSpacing',6, 'ColumnSpacing',6, 'Scrollable','on', 'BackgroundColor',PN, 'Tag','apat_subj_grid');
lay(CG, 1, 1);
setappdata(app.SubjectsPanel, 'apat_chip_grid', CG);
rl = uipanel(C,'BorderType','none','BackgroundColor',app.clr_gold);  lay(rl, 2, 1);
B = grd(C, {'1x'}, {96, 96, 104, '1x'}, PN, [0 0 0 0], 0, 8);  lay(B, 3, 1);
sb = {'Select All','SelectAllBtn',@(~,~) SelectAllButtonPushed(app); ...
      'Clear',     'ClearSubjBtn',@(~,~) ClearButtonPushed(app); ...
      '⟳ Refresh', 'RefreshSubjBtn',@(~,~) RefreshButtonPushed(app)};
for bi = 1:3
    app.(sb{bi,2}) = uibutton(B,'push','Text',sb{bi,1}, ...
        'FontSize',FT-1,'FontWeight','bold', ...
        'BackgroundColor',app.clr_btn,'ButtonPushedFcn',sb{bi,3});
    lay(app.(sb{bi,2}), 1, bi);
end
app.h_row2_badges = gobjects(1,2);
app.h_row2_badges(1) = uilabel(sstrip,'Text','','FontSize',12, ...
    'FontColor',STRIP_TXT,'HorizontalAlignment','right');
lay(app.h_row2_badges(1), 1, 3);
app.SubjectsPanel.SizeChangedFcn = @(~,~) chips_cb(app);     % local wrapper (silent)

% ── 04 Conditions: include chip + colour swatch + marker per condition ───
% (rows built by chinroster_ops 'refresh_conds' into the scrollable grid;
% colour / marker picker: chinroster_ops 'style_open')
[sec_p, C] = setup_section(app, R2, [1 2], '04', 'Conditions', {'1x', 20}, {'1x'});
app.ConditionsPanel = sec_p;
CG = uigridlayout(C, 'RowHeight',{26}, 'ColumnWidth',{'1x', 26, 26}, 'Padding',[4 4 4 4], ...
    'RowSpacing',4, 'ColumnSpacing',5, 'Scrollable','on', 'BackgroundColor',PN, 'Tag','apat_cond_grid');
lay(CG, 1, 1);
setappdata(app.ConditionsPanel, 'apat_chip_grid', CG);
F = grd(C, {'1x'}, {'1x', 'fit', 'fit'}, PN, [0 0 0 0], 0, 10);  lay(F, 2, 1);
app.h_row2_badges(2) = uilabel(F,'Text','','FontSize',11, ...
    'FontWeight','bold','FontColor',app.clr_gold_dk);
lay(app.h_row2_badges(2), 1, 1);
lk = {'All', @(~,~) cond_all(app, true); 'Clear', @(~,~) cond_all(app, false)};
CL_TXT = app.clr_gold_dk;
for li = 1:2
    try
        h = uihyperlink(F, 'Text',lk{li,1}, 'FontSize',12, 'FontWeight','bold', 'FontColor',CL_TXT, ...
            'VisitedColor',CL_TXT, 'HyperlinkClickedFcn',lk{li,2}, ...
            'Tooltip','Colour and marker of each condition: click its swatch or its symbol');
    catch                                               % (no uihyperlink: small button)
        h = uibutton(F,'push','Text',lk{li,1},'FontSize',11,'FontWeight','bold', ...
            'BackgroundColor',app.clr_btn,'ButtonPushedFcn',lk{li,2});
    end
    lay(h, 1, 1 + li);
end

% ── 05 Run Options: title + description, ON/OFF pill ──────────────────────
[sec_p, C] = setup_section(app, R2, [1 3], '05', 'Run Options', {'1x', '1x', '1x'}, {'1x'});
app.OptionsPanel = sec_p;
C.RowSpacing = 2;
opt_def = {'ReanalyzeCheck',    'Re-Analyze Data',      'Even if results exist',       true; ...
           'PlotRelativeCheck', 'Relative to Baseline', 'Changes vs. first condition', false; ...
           'BlindCheck',        'Blind Mode',           'Hide names while analysing',  false};
opt_tip = {'Recompute every analysis even if its results already exist', ...
           'Plot the changes of every condition relative to the first condition (Baseline)', ...
           'Hide subject & condition names while the analysis runs (random order)'};
PILL_W = 58;  PILL_H = 24;
for oi = 1:3
    Rg = grd(C, {'1x', 18, 15, '1x'}, {'1x', PILL_W}, PN, [0 0 0 0], 0, 8);  lay(Rg, oi, 1);
    h = uilabel(Rg,'Text',opt_def{oi,2},'FontSize',FT-1,'FontWeight','bold', ...
        'FontColor',app.clr_black,'Tooltip',opt_tip{oi});
    lay(h, 2, 1);
    h = uilabel(Rg,'Text',opt_def{oi,3},'FontSize',11, ...
        'FontColor',[0.36 0.34 0.31],'Tooltip',opt_tip{oi});
    lay(h, 3, 1);
    V = grd(Rg, {'1x', PILL_H, '1x'}, {'1x'}, PN, [0 0 0 0], 0, 0);  lay(V, [1 4], 2);
    app.(opt_def{oi,1}) = uibutton(V,'state','Text','ON','Value',opt_def{oi,4}, ...
        'FontSize',11,'FontWeight','bold','FontName',MONO,'Tooltip',opt_tip{oi}, ...
        'ValueChangedFcn',@(~,~) update_summary(app));
    lay(app.(opt_def{oi,1}), 2, 1);
    setup_style(app, 'onoff', app.(opt_def{oi,1}));
end

% ── 06 Output (values: private/output_opts.m; handles app.h_output) ───────
% Data Export .mat / .csv (one or both) | Images ON/OFF + 300 / 150
% dpi | Plot Defaults (Subject Points, Shading). Measure-specific plot
% defaults sit in the measure parameter panels (buildParamPanels).
app.h_output = struct();
[OP, C] = setup_section(app, R2, [1 4], '06', 'Output', {26, 26, 26, '1x'}, {'fit', '1x'});
C.RowSpacing = 9;  C.ColumnSpacing = 10;
O = struct();  O.panel = OP;  O.chk = struct();
tipE = ['Format of the data files written for the analysed results: MATLAB .mat files ' ...
    '(APAT''s own format), CSV tables for other software, or both (at least one stays on). ' ...
    'Per-recording .mat files are always kept (APAT needs them to build averages).'];
h = uilabel(C,'Text','Data Export','FontSize',FT-1,'FontColor',GREY,'Tooltip',tipE);  lay(h, 1, 1);
E = grd(C, {'1x'}, {76, 76, '1x'}, PN, [0 0 0 0], 0, 6);  lay(E, 1, 2);
O.mat_btn = uibutton(E,'state','Text','.mat','Value',true,'FontSize',12,'FontWeight','bold', ...
    'UserData','.mat','Tooltip',tipE, ...
    'ValueChangedFcn',@(src,~) output_cb(app, 'fmt', src));
lay(O.mat_btn, 1, 1);
O.csv_btn = uibutton(E,'state','Text','.csv','Value',false,'FontSize',12,'FontWeight','bold', ...
    'UserData','.csv','Tooltip',tipE, ...
    'ValueChangedFcn',@(src,~) output_cb(app, 'fmt', src));
lay(O.csv_btn, 1, 2);
tipI = ['Save every figure as a PNG while the analysis runs (300 dpi for reports; 150 dpi ' ...
    'saves faster). Results → Save Image updates a saved image with the view on screen.'];
h = uilabel(C,'Text','Images','FontSize',FT-1,'FontColor',GREY,'Tooltip',tipI);  lay(h, 2, 1);
I = grd(C, {'1x'}, {PILL_W, 84, 84, '1x'}, PN, [0 0 0 0], 0, 4);  lay(I, 2, 2);
I.ColumnSpacing = 4;
O.img_btn = uibutton(I,'state','Text','ON','Value',true,'FontSize',11,'FontWeight','bold', ...
    'FontName',MONO,'Tooltip',tipI, ...
    'ValueChangedFcn',@(~,~) output_cb(app, 'changed'));
lay(O.img_btn, 1, 1);
O.dpi300_btn = uibutton(I,'state','Text','300 dpi','Value',true,'FontSize',12, ...
    'Tooltip',tipI, 'ValueChangedFcn',@(~,~) output_cb(app, 'dpi', 300));
lay(O.dpi300_btn, 1, 2);
O.dpi150_btn = uibutton(I,'state','Text','150 dpi','Value',false,'FontSize',12, ...
    'Tooltip',tipI, 'ValueChangedFcn',@(~,~) output_cb(app, 'dpi', 150));
lay(O.dpi150_btn, 1, 3);
h = uilabel(C,'Text','Plot Defaults','FontSize',FT-1,'FontColor',GREY, ...
    'Tooltip','Saved images and the Results views start with these; change them live with Plot Settings');
lay(h, 3, 1);
D = grd(C, {'1x'}, {136, 100, '1x'}, PN, [0 0 0 0], 0, 6);  lay(D, 3, 2);
O.chk.subj_pts = pdef_btn(app, D, 'Subject Points', 'Each subject''s points on the average plots', 1);
O.chk.shading  = pdef_btn(app, D, 'Shading', 'Grey bands that group the points of one x value', 2);
h = uilabel(C,'Text','Measure-specific plot defaults: in each measure''s parameters below.', ...
    'FontSize',11,'FontColor',[0.36 0.34 0.31],'WordWrap','on','VerticalAlignment','top');
lay(h, 4, [1 2]);
app.h_output = O;

% ── 07 Auditory Measures ─────────────────────────────────────────────────
% [measure buttons] | divider | [type buttons (top row) + parameter panel
% below] | [Analysis Insight card + Run Summary card]
[sec_p, C] = setup_section(app, G0, [3 1], '07', 'Auditory Measures', ...
    {'1x', 0, 0}, {150, 3, '1x', '0.55x'});      % (spare rows while children share cells; reset below)
app.MeasuresPanel = sec_p;
C.Padding = [10 8 10 8];  C.ColumnSpacing = 10;

app.h_meas_btns = gobjects(0);
app.h_sub_btns  = {};
mid = grd(C, [{76, '1x'}, repmat({0}, 1, 8)], {'1x'}, PN, [0 0 0 0], 8, 0);  lay(mid, 1, 3);   % (spare rows: reset below)
buildMeasureButtons(app, C, mid);

% Parameter panels fill the column under the type buttons (all in one cell;
% only the measure on screen is visible)
buildParamPanels(app, mid, FS, LH);
mid.RowHeight = {76, '1x'};  mid.ColumnWidth = {'1x'};      % (overlapping children placed)

RC = grd(C, {'1x', '2.3x'}, {'1x'}, PN, [0 0 0 0], 8, 0);  lay(RC, 1, 4);
C.RowHeight = {'1x'};  C.ColumnWidth = {150, 3, '1x', '0.55x'};

% ── Analysis Insight card (description of the selected analysis) ─────────
about = uipanel(RC,'BorderType','line','BackgroundColor',BG);  lay(about, 1, 1);
if isprop(about,'BorderColor'), about.BorderColor = app.clr_gold; end
AG = grd(about, {18, 'fit', '1x'}, {'1x'}, BG, [12 6 12 8], 4, 0);
AG.Scrollable = 'on';
h = uilabel(AG,'Text','Analysis Insight','FontSize',FT-1,'FontWeight','bold', ...
    'FontColor',app.clr_black);
lay(h, 1, 1);
app.DescTitleLabel = uilabel(AG,'Text','', 'WordWrap','on', ...
    'FontSize',FT-1,'FontWeight','bold','FontColor',app.clr_gold_dk);
lay(app.DescTitleLabel, 2, 1);
app.DescLabel = uilabel(AG,'Text','', 'WordWrap','on', 'VerticalAlignment','top', ...
    'FontSize',12,'FontColor',GREY);
lay(app.DescLabel, 3, 1);

% ── Run Summary card (live overview of what Run Analysis will do) ────────
% Cream card: "RUN SUMMARY" + "n ANALYSES", three count tiles (subtle
% yellow), the analyses / options rows (scroll when there are many), green
% Run Analysis button.
CREAM_C = [0.965 0.933 0.827];
sp = uipanel(RC,'BorderType','line','BackgroundColor',CREAM_C);  lay(sp, 2, 1);
if isprop(sp,'BorderColor'), sp.BorderColor = app.clr_gold; end
try, sp.BorderWidth = 2; catch, end
SG = grd(sp, {16, 48, '1x', 42}, {'1x'}, CREAM_C, [12 8 12 8], 6, 0);
CAP_C = [0.353 0.290 0.118];                              % #5A4A1E tile captions
S = struct();
Hd = grd(SG, {'1x'}, {'1x', 'fit'}, CREAM_C, [0 0 0 0], 0, 8);  lay(Hd, 1, 1);
h = uilabel(Hd,'Text','RUN SUMMARY','FontName',MONO,'FontSize',11,'FontWeight','bold', ...
    'FontColor',CAP_C);
lay(h, 1, 1);
S.head_n = uilabel(Hd,'Text','','FontName',MONO,'FontSize',10,'FontWeight','bold', ...
    'FontColor',[0.557 0.435 0.243],'HorizontalAlignment','right');
lay(S.head_n, 1, 2);
T3 = grd(SG, {'1x'}, {'1x', '1x', '1x'}, CREAM_C, [0 0 0 0], 0, 6);  lay(T3, 2, 1);
tile_caps = {'Subjects','Conditions','Datasets'};
S.tiles = gobjects(1,3);
for ti = 1:3
    tp = uipanel(T3,'BorderType','line','BackgroundColor',[0.941 0.874 0.645]);  lay(tp, 1, ti);
    if isprop(tp,'BorderColor'), tp.BorderColor = [0.855 0.667 0]; end
    TG = grd(tp, {'1x', 13}, {'1x'}, [0.941 0.874 0.645], [8 3 6 2], 0, 0);
    S.tiles(ti) = uilabel(TG,'Text','0','FontName',MONO,'FontSize',20,'FontWeight','bold', ...
        'FontColor',app.clr_black);
    lay(S.tiles(ti), 1, 1);
    h = uilabel(TG,'Text',upper(tile_caps{ti}),'FontName',MONO,'FontSize',9,'FontWeight','bold', ...
        'FontColor',CAP_C);
    lay(h, 2, 1);
end
% Summary rows between the tiles and the button: one row per selected
% analysis, then the options rows (update_summary fills them)
NL = 10;  line_h = 18;
LG = uigridlayout(SG, 'RowHeight',repmat({line_h}, 1, NL), 'ColumnWidth',{'1x'}, ...
    'Padding',[0 0 0 0], 'RowSpacing',0, 'Scrollable','on', 'BackgroundColor',CREAM_C);
lay(LG, 3, 1);
S.lines = gobjects(1, NL);
for li = 1:NL
    S.lines(li) = uilabel(LG,'Text','','FontSize',12, ...
        'FontColor',[0.227 0.212 0.184],'Interpreter','html');
    lay(S.lines(li), li, 1);
end
app.RunButton = uibutton(SG,'push', ...
    'Text',[char(9654) ' RUN ANALYSIS'], ...
    'FontSize',15,'FontWeight','bold','FontName',MONO, ...
    'FontColor',[1 1 1],'BackgroundColor',app.clr_on, ...
    'ButtonPushedFcn',@(~,~) RunButtonPushed(app));
lay(app.RunButton, 4, 1);
S.proj = app.h_summary_proj;   % project-status labels built in the Project panel
app.h_summary = S;

output_cb(app, 'refresh');
end


function [p, C, strip] = setup_section(app, parent, rc, num, title, rows, cols)
%SETUP_SECTION  Setup section in cell rc = [row col] of grid PARENT: panel
%   (gold border) with a 30 px black header strip — gold tag number (num,
%   e.g. '03'), cream bold title (Tag apat_sec_title_<num>, UserData =
%   title; sheet_sel adds the Experiment), an optional right-hand item in
%   column 3 ('fit') — and the content grid C (rows / cols, padding 12/8)
%   below it. AutoResizeChildren is off, so a section can take a
%   SizeChangedFcn (Subjects: chip columns).
p = uipanel(parent,'BorderType','line','BackgroundColor',app.clr_panel, 'AutoResizeChildren','off');
lay(p, rc(1), rc(2));
if isprop(p,'BorderColor'), p.BorderColor = app.clr_gold; end
g = grd(p, {30, '1x'}, {'1x'}, app.clr_panel, [0 0 0 0], 0, 0);
strip = grd(g, {'1x'}, {26, '1x', 'fit'}, app.clr_black, [10 6 12 6], 0, 8);
lay(strip, 1, 1);
h = uilabel(strip,'Text',num,'FontName',mono_font(),'FontSize',10,'FontWeight','bold', ...
    'FontColor',app.clr_black,'BackgroundColor',app.clr_gold,'HorizontalAlignment','center');
lay(h, 1, 1);
h = uilabel(strip,'Text',title,'FontSize',13,'FontWeight','bold','FontColor',[0.97 0.96 0.93], ...
    'Tag',['apat_sec_title_' num], 'UserData',title);
lay(h, 1, 2);
C = grd(g, rows, cols, app.clr_panel, [12 8 12 8], 6, 8);
lay(C, 2, 1);
end


function g = grd(parent, rows, cols, bg, pad, rs, cs)
%GRD  uigridlayout with the given rows / columns, background, padding
%   [left bottom right top] and row / column spacing.
g = uigridlayout(parent, 'RowHeight',rows, 'ColumnWidth',cols, 'Padding',pad, ...
    'RowSpacing',rs, 'ColumnSpacing',cs, 'BackgroundColor',bg);
end


function lay(h, r, c)
%LAY  Grid cell of a component: row r, column c (scalars or [first last]).
h.Layout.Row    = r;
h.Layout.Column = c;
end


function v = vbox(parent, h, r, c, bg)
%VBOX  Grid in cell (r, c) of PARENT that centres one fixed-height (h)
%   child vertically: put the child in row 2 (lay(child, 2, 1)).
v = grd(parent, {'1x', h, '1x'}, {'1x'}, bg, [0 0 0 0], 0, 0);
lay(v, r, c);
end


function b = pdef_btn(app, parent, name, tip, col)
%PDEF_BTN  Plot-default toggle ('■ Name' on / '□ Name' off; setup_style
%   'pdef') in column COL of row grid PARENT. Values read by
%   private/output_opts.m through app.h_output.chk.
b = uibutton(parent,'state','Text',name,'Value',true,'FontSize',12,'UserData',name, ...
    'BackgroundColor',[1 1 1],'Tooltip',tip, ...
    'ValueChangedFcn',@(~,~) output_cb(app, 'changed'));
lay(b, 1, col);
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


function buildMeasureButtons(app, C, mid)
%BUILDMEASUREBUTTONS  Measure buttons (column 1 of the Measures grid C, one
%   '1x' row each), the gold divider (column 2) and the type buttons (row 1
%   of the middle grid MID: one row grid per measure, all in the same cell;
%   navigate_results>do_measures shows the one of the measure on screen).
PN = app.clr_panel;
app.n_meas   = length(app.MEASURES);
app.meas_h   = 0.22;
app.meas_gap = 0.02;
app.h_meas_btns = gobjects(1, app.n_meas);
app.h_sub_btns  = cell(1, app.n_meas);
% Pixel-art icons (icons/make_icons.py) shown above each button's text
icon_dir = fullfile(fileparts(mfilename('fullpath')), 'icons');
MG = grd(C, repmat({'1x'}, 1, app.n_meas), {'1x'}, PN, [0 0 0 0], 8, 0);
lay(MG, 1, 1);
for m = 1:app.n_meas
    app.h_meas_btns(m) = uibutton(MG,'push', ...
        'Text',app.MEASURES(m).name, ...
        'FontSize',15,'FontWeight','bold','BackgroundColor',app.clr_btn,'FontColor',app.clr_txt2, ...
        'UserData',m, ...
        'ButtonPushedFcn',@(src,~) MeasureButtonPushed(app, src));
    lay(app.h_meas_btns(m), m, 1);
    set_btn_icon(app.h_meas_btns(m), fullfile(icon_dir, ...
        ['icon_' lower(app.MEASURES(m).name) '.png']));
end

% Gold vertical divider; the old "measure on screen" marker bar stays a
% hidden panel in the same cell (setup_style keeps it hidden)
dv = uipanel(C,'BorderType','none','BackgroundColor',app.clr_gold);
lay(dv, 1, 2);
app.h_meas_marker = uipanel(C,'BorderType','none','BackgroundColor',app.clr_gold_dk, 'Visible','off');
lay(app.h_meas_marker, 1, 2);
app.meas_sub_area_start = 0;

% Type buttons add / remove an analysis from the run (several can be
% selected, across measures). MEMR: ART + the exploratory analyses.
sub_tip = ['Click to add to / remove from the run. Several analyses can be ' ...
    'selected (also from other measures); they run one after another.'];
for m = 1:app.n_meas
    subs = app.MEASURES(m).subtypes;
    no_types = isempty(subs);
    if no_types, subs = {app.MEASURES(m).name}; end
    n = numel(subs);
    TG = grd(mid, {'1x'}, repmat({'1x'}, 1, max(n, 3)), PN, [0 0 0 0], 0, 6);
    lay(TG, 1, 1);
    TG.Visible = 'off';                           % do_measures: measure on screen only
    app.h_sub_btns{m} = gobjects(1, n);
    sub_fs = 14;  if n > 5, sub_fs = 13; end      % MEMR: 8 types on one row
    for k = 1:n
        btxt = subs{k};
        if no_types && strcmp(app.MEASURES(m).name, 'MEMR'), btxt = 'ART'; end   % acoustic reflex threshold
        app.h_sub_btns{m}(k) = uibutton(TG,'push', ...
            'Text',btxt, ...
            'FontSize',sub_fs,'FontWeight','bold','BackgroundColor',app.clr_btn,'Visible','off', ...
            'UserData',[m k], 'Tooltip',sub_tip, ...
            'ButtonPushedFcn',@(src,~) SubtypeButtonPushed(app, src));
        lay(app.h_sub_btns{m}(k), 1, k);
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


function buildParamPanels(app, host, FS, LH)
%BUILDPARAMPANELS  ABR/EFR/OAE/MEMR parameter panels, all in row 2 of the
%   middle grid HOST (only the selected measure's panel is visible). Each
%   panel holds a scrollable grid of fixed-height rows (anchored to the top,
%   scrolls when the panel is short); each row is a grid of fixed / 'fit'
%   columns. Blocks shown per type (EFR RAM / dAM, OAE DPOAE / SFOAE /
%   TEOAE, MEMR ART / exploratory) overlap in the same row cell;
%   navigate_results>update_param_panels shows / hides them (and hides
%   rows that hold nothing visible).
GRY = [0.45 0.45 0.45];
BG  = app.clr_bg;
RH  = 28;                   % control row height

% ── ABR: frequency + wave toggle chips ───────────────────────────────────
app.h_abr_param_panel = mkpanel('ABR Parameters');
G = body(app.h_abr_param_panel);
freq_labels = {'Click','0.5 kHz','1 kHz','2 kHz','4 kHz','8 kHz'};
% Thresholds and Peaks keep their own frequency selection (abr_freq_sync):
% the chips show the one of the ABR type on screen; All / Clear set them all.
FL_W = 260;  ab_w = 64;
r = row(G, LH, {FL_W, ab_w, ab_w, '1x'});
put(uilabel(r,'Text','Frequencies — Thresholds','FontSize',FS,'FontWeight','bold', ...
    'Tag','abr_freq_lbl'), 1);
put(uibutton(r,'push','Text','All','FontSize',FS-3,'FontWeight','bold', ...
    'BackgroundColor',[1 1 1], 'Tooltip','Select every frequency (for the ABR type on screen)', ...
    'ButtonPushedFcn',@(~,~) abr_freq_chip(app, 'all')), 2);
put(uibutton(r,'push','Text','Clear','FontSize',FS-3,'FontWeight','bold', ...
    'BackgroundColor',[1 1 1], 'Tooltip','Clear every frequency (for the ABR type on screen)', ...
    'ButtonPushedFcn',@(~,~) abr_freq_chip(app, 'none')), 3);
r = row(G, 32, repmat({'1x'}, 1, 6));
app.h_abr_freq_checks = gobjects(1, numel(freq_labels));
for fi = 1:numel(freq_labels)
    app.h_abr_freq_checks(fi) = put(uibutton(r,'state', ...
        'Text',freq_labels{fi},'Value',true,'FontSize',FS-1,'FontWeight','bold', ...
        'ValueChangedFcn',@(~,~) abr_freq_chip(app, 'store')), fi);
end
r = row(G, LH, {FL_W, ab_w, ab_w, '1x'});
put(uilabel(r,'Text','Waves','Tag','abr_wave_lbl','FontSize',FS,'FontWeight','bold'), 1);
put(uibutton(r,'push','Text','All','FontSize',FS-3,'FontWeight','bold', ...
    'Tag','abr_wave_lbl', 'BackgroundColor',[1 1 1], ...
    'Tooltip','Select every wave', 'ButtonPushedFcn',@(~,~) abr_wave_all(app, true)), 2);
put(uibutton(r,'push','Text','Clear','FontSize',FS-3,'FontWeight','bold', ...
    'Tag','abr_wave_lbl', 'BackgroundColor',[1 1 1], ...
    'Tooltip','Clear every wave', 'ButtonPushedFcn',@(~,~) abr_wave_all(app, false)), 3);
r = row(G, 32, repmat({'1x'}, 1, 6));
wave_labels = {'Wave I','Wave II','Wave III','Wave IV','Wave V'};
app.h_abr_wave_checks = gobjects(1, numel(wave_labels));
for wi = 1:numel(wave_labels)
    app.h_abr_wave_checks(wi) = put(uibutton(r,'state', ...
        'Text',wave_labels{wi},'Value',true,'Tag','abr_wave_ck', ...
        'FontSize',FS-1,'FontWeight','bold', ...
        'ValueChangedFcn',@(~,~) update_summary(app)), wi);
end
r = row(G, LH, {'1x'});
put(uilabel(r,'Tag','abr_wave_lbl', ...
    'Text','All recorded stimulus levels are analysed automatically.', ...
    'FontSize',FS-3,'FontColor',GRY), 1);
% Repeated Levels (Thresholds and Peaks): a level recorded more than once →
% every recording ('all') or their average ('average'); cfg.abr_dup_levels
tipR = ['A stimulus level recorded more than once (e.g. repeated at the end of a series): ' ...
    'Show All = every recording is used and shown; Average = the repeated recordings ' ...
    'of a level are averaged into one.'];
r = row(G, RH, {'fit', 130, 18, 'fit', 150, '1x'});
put(uilabel(r,'Text','Repeated Levels:','FontSize',FS-1,'HorizontalAlignment','right', ...
    'Tooltip',tipR), 1);
put(uidropdown(r,'Items',{'Show All','Average'},'ItemsData',{'all','average'}, ...
    'Value','all','Tag','abr_dup_dd','FontSize',FS-1,'BackgroundColor','white','Tooltip',tipR, ...
    'ValueChangedFcn',@(~,~) update_summary(app)), 2);
put(uilabel(r,'Text','Plot Defaults','FontSize',FS-1,'HorizontalAlignment','right', ...
    'Tooltip','Saved images and the Results views start with these; change them live with Plot Settings'), 4);
O = app.h_output;
O.chk.abr_n = pdef_btn(app, r, 'Sample Size (n)', 'n labels on the ABR Peaks average plots', 5);
app.h_output = O;

% ── EFR ──────────────────────────────────────────────────────────────────
app.h_efr_param_panel = mkpanel('EFR Parameters');
p = app.h_efr_param_panel;
G = body(p);
% RAM block (visible for RAM) and dAM block (visible for dAM) share the top
% row of the panel (two grids in one cell).
ram_rows = {LH, LH, 30, 30, 30, LH};
cell1 = row(G, sum([ram_rows{:}]) + 5*6, {'1x'}, 0);
cell1.RowHeight = {'1x', 0};                    % (spare cell while both blocks are made)
RAM = blk(cell1, ram_rows);
DAM = blk(cell1, {LH, LH, 30, '1x'});
cell1.RowHeight = {'1x'};  cell1.ColumnWidth = {'1x'};
textline(RAM, 1, 'RAM — configurable', true, 'efr_ram_hdr');
textline(RAM, 2, 'Mod. freq: 223 Hz  |  Filter: 60–4000 Hz  |  H1 = 223 Hz (fundamental)', false, 'efr_ram_info');
% Row 1: max harmonics + analysis window
r = sub(RAM, 3, {120, 60, 18, 92, 34, 56, 6, 28, 56, '1x'});
put(uilabel(r,'Text','Max harmonics:','Tag','efr_harm_lbl','FontSize',FS-1), 1);
app.h_efr_harmonics_field = put(uieditfield(r,'numeric', ...
    'Value',16,'Limits',[1 16],'RoundFractionalValues','on','Tag','efr_harmonics', ...
    'FontSize',FS-1,'BackgroundColor','white', ...
    'ValueChangedFcn',@(src,~) efr_sync_high(src)), 2);
put(uilabel(r,'Text','Window (s):','Tag','efr_win_lbl','FontSize',FS-1), 4);
put(uilabel(r,'Text','start','Tag','efr_win_s_lbl','FontSize',FS-3,'FontColor',GRY), 5);
app.h_efr_window_start_field = put(uieditfield(r,'numeric', ...
    'Value',0.2,'Limits',[0 2],'Tag','efr_win_start', ...
    'FontSize',FS-1,'BackgroundColor','white'), 6);
put(uilabel(r,'Text','end','Tag','efr_win_e_lbl','FontSize',FS-3,'FontColor',GRY), 8);
app.h_efr_window_end_field = put(uieditfield(r,'numeric', ...
    'Value',0.9,'Limits',[0 2],'Tag','efr_win_end', ...
    'FontSize',FS-1,'BackgroundColor','white'), 9);
% Row 2: low / high harmonic ranges
r = sub(RAM, 4, {120, 46, 14, 46, 18, 120, 46, 14, 46, '1x'});
put(uilabel(r,'Text','Low harmonics:','Tag','efr_low_lbl','FontSize',FS-1), 1);
hnum(r, 1, 'efr_low_from', 2);
put(uilabel(r,'Text','–','Tag','efr_low_dash','FontSize',FS-1,'HorizontalAlignment','center'), 3);
hnum(r, 4, 'efr_low_to', 4);
put(uilabel(r,'Text','High harmonics:','Tag','efr_high_lbl','FontSize',FS-1), 6);
hnum(r, 5, 'efr_high_from', 7);
put(uilabel(r,'Text','–','Tag','efr_high_dash','FontSize',FS-1,'HorizontalAlignment','center'), 8);
hnum(r, 16, 'efr_high_to', 9);
% Row 3: what to sum + normalisation
r = sub(RAM, 5, {120, 150, 18, 196, 64, '1x'});
put(uilabel(r,'Text','Sum of:','Tag','efr_sum_lbl','FontSize',FS-1), 1);
put(uidropdown(r,'Items',{'Amplitude (PLV)','SNR (dB)','Magnitude (µV)'},'ItemsData',{'amplitude','snr','magnitude'}, ...
    'Value','amplitude','Tag','efr_sum_dd','FontSize',FS-1,'BackgroundColor','white'), 2);
put(uilabel(r,'Text','Normalize by all harmonics:','Tag','efr_norm_lbl','FontSize',FS-1), 4);
nb = put(uibutton(r,'state','Text','OFF','Value',false,'Tag','efr_norm_btn','FontSize',FS-1, ...
    'FontWeight','bold','BackgroundColor','white','FontColor',[0.6 0.6 0.6]), 5);
nb.ValueChangedFcn = @(src,~) efr_style_toggle(src);
efr_style_toggle(nb);
textline(RAM, 6, 'Total PLV over all harmonics is always reported.', false, 'efr_ram_note');

% dAM block (same cell; shown only for dAM)
textline(DAM, 1, 'dAM', true, 'efr_dam_hdr');
textline(DAM, 2, 'Carrier: 4 kHz  |  AM sweep: 4–10.5 Hz  |  Demod filter: 10–1500 Hz', false, 'efr_dam_info');
r = sub(DAM, 3, {120, 60, 10, '1x'});
put(uilabel(r,'Text','dAM bands:','Tag','efr_dam_lbl','FontSize',FS-1), 1);
put(uieditfield(r,'numeric','Value',16,'Limits',[2 64],'RoundFractionalValues','on', ...
    'Tag','efr_dam_bands','FontSize',FS-1,'BackgroundColor','white'), 2);
put(uilabel(r,'Text','log-spaced smoothing bands (16 = number of RAM harmonics)', ...
    'Tag','efr_dam_note','FontSize',FS-3,'FontColor',GRY), 4);

% ── OAE ──────────────────────────────────────────────────────────────────
% Left: band averaging / display (applied when results are summarized — no
% re-analysis). Right: analysis settings of the selected subtype (used when
% the analysis runs: new data or Reanalyze). Controls are found by Tag in
% RunButtonPushed (oae_*), saved in profiles as oae_ctl. The two columns
% have fixed widths; the panel scrolls sideways when it is narrower.
app.h_oae_param_panel = mkpanel('OAE Parameters');
p = app.h_oae_param_panel;
G = body(p);
OFS = FS - 2;
RS  = 30;                     % row step (row + spacing)
oae_rows = [{LH}, repmat({RH}, 1, 7)];
cols2 = row(G, LH + 7*RH + 7*(RS-RH), {440, 290}, 24);
LC = blk(cols2, oae_rows, RS-RH);  lay(LC, 1, 1);
RC = blk(cols2, oae_rows, RS-RH);  lay(RC, 1, 2);
cols2.RowHeight = {'1x'};  cols2.ColumnWidth = {440, 290};
RC.RowHeight = [oae_rows, repmat({0}, 1, 8)];  % (spare cells while the type rows are made; reset below)
h = uilabel(LC,'Text','Band Average','FontSize',OFS+1,'FontWeight','bold', ...
    'Tooltip','Applied when results are summarized (no re-analysis needed)');
lay(h, 1, 1);
FW = 50;
r = sub(LC, 2, {92, 124, 6, 48, FW, 14, FW, 34, '1x'}, 2);
lbl(r, 'Band width', 1);
put(uidropdown(r,'Items',{'1 octave','1/2 octave','1/3 octave','1/4 octave'},'ItemsData',{1,2,3,4}, ...
    'Value',2,'Tag','oae_bpo','FontSize',OFS,'BackgroundColor','white'), 2);
lbl(r, 'Range', 4);
num(r, 0.5, 'oae_fmin', 5, [0.05 50]);
dash(r, 6);
num(r, 16, 'oae_fmax', 7, [0.1 100]);
lbl(r, 'kHz', 8, true);
r = sub(LC, 3, {92, 150, 6, 52, 118, '1x'}, 2);
lbl(r, 'Method', 1);
put(uidropdown(r,'Items',{'SNR-weighted','Power average','Mean of dB','Median'}, ...
    'ItemsData',{'snrw','power','meandb','median'},'Value','snrw','Tag','oae_method', ...
    'FontSize',OFS,'BackgroundColor','white', ...
    'Tooltip',['SNR-weighted: weighted mean of dB, weight = SNR²  |  Power average: mean of pressure², ' ...
               'then dB  |  Mean of dB  |  Median of dB']), 2);
lbl(r, 'Y-axis', 4);
put(uidropdown(r,'Items',{'Amplitude','SNR'},'ItemsData',{'amp','snr'},'Value','amp','Tag','oae_ymeas', ...
    'FontSize',OFS,'BackgroundColor','white'), 5);
r = sub(LC, 4, {92, FW, 24, 58, 8, 92, FW, 22, '1x'}, 2);
lbl(r, 'SNR ≥', 1);
num(r, 6, 'oae_snr_min', 2, [-20 60]);
lbl(r, 'dB', 3, true);
sb = put(uibutton(r,'state','Text','ON','Value',true,'Tag','oae_snr_btn','FontSize',OFS, ...
    'FontWeight','bold','BackgroundColor',app.clr_gold, ...
    'FontColor',app.clr_black,'Tooltip','SNR criterion: points below it are left out of the band average'), 4);
sb.ValueChangedFcn = @(src,~) efr_style_toggle(src);
efr_style_toggle(sb);
lbl(r, 'Min. passing', 6);
num(r, 50, 'oae_min_frac', 7, [0 100]);
lbl(r, '%', 8, true);
r = sub(LC, 5, {92, FW, 14, FW, 14, FW, 14, FW, 34, '1x'}, 0);
lbl(r, 'Regions', 1);
rtip = {'Low band starts','Low | Mid edge','Mid | High edge','High band ends'};
rv = [0.5 2 8 16];
for ri = 1:4
    hn = num(r, rv(ri), sprintf('oae_reg%d', ri), 2*ri, [0.05 100]);
    hn.Tooltip = ['Frequency bands (kHz): ' rtip{ri}];
    if ri < 4, sep(r, 2*ri + 1); end
end
lbl(r, 'kHz', 9, true);
r = sub(LC, 6, {92, 190, '1x'}, 2);
lbl(r, 'Flagged bands', 1);
put(uidropdown(r,'Items',{'Include in average','Exclude from average'},'ItemsData',{'include','exclude'}, ...
    'Value','include','Tag','oae_gate_avg','FontSize',OFS,'BackgroundColor','white', ...
    'Tooltip',['Bands where fewer than the minimum % of points pass the SNR criterion. ' ...
               'Excluding them can hide a loss of emissions after exposure.']), 2);
r = sub(LC, 7, {92, 60, 60, '1x'}, 6);
lbl(r, 'Save files', 1);
for ui = 1:2
    un = {'EPL','SPL'};
    ub = put(uibutton(r,'state','Text',un{ui},'Value',true,'Tag',['oae_save_' lower(un{ui})], ...
        'FontSize',OFS,'FontWeight','bold', ...
        'BackgroundColor',app.clr_gold,'FontColor',app.clr_black, ...
        'Tooltip',sprintf(['Save %s figures and average files (one or both; both = also the ' ...
                           'EPL + SPL figure). TEOAE is SPL only.'], un{ui})), 1 + ui);
    ub.ValueChangedFcn = @(src,~) oae_unit_toggle(src);
    setup_style(app, 'chip', ub);
end
% Plot defaults of the OAE figures (saved images + Results views start with
% these; values in app.h_output.chk, private/output_opts.m)
r = sub(LC, 8, {92, 96, 124, '1x'}, 6);
lbl(r, 'Plot defaults', 1);
O = app.h_output;
O.chk.oae_sweep = pdef_btn(app, r, 'Sweeps', 'DPOAE / SFOAE / TEOAE sweep (raw) traces', 2);
O.chk.oae_nf    = pdef_btn(app, r, 'Noise Floor', 'Noise floor of the OAE plots', 3);
app.h_output = O;

% Right column: analysis settings, one block per subtype (rows of the
% blocks overlap; UserData / Tag = oae_dp | oae_sf | oae_te), then the
% Data File rule (every OAE type) in the last row
aw = 130;
hdr = {'oae_dp','DPOAE'; 'oae_sf','SFOAE'; 'oae_te','TEOAE'};
for hi = 1:3
    h = uilabel(RC,'Text',[hdr{hi,2} ' Extraction'],'Tag',hdr{hi,1},'FontSize',OFS+1, ...
        'FontWeight','bold', ...
        'Tooltip',[hdr{hi,2} ' settings, used when the analysis runs: new data, or with Re-analyze data ON']);
    lay(h, 1, 1);
end
% DPOAE
r = sub(RC, 2, {aw, FW, '1x'}, 2);  lbl(r, 'Window (s)', 1, false, 'oae_dp');     num(r, 0.25, 'oae_dp_win', 2, [0.01 2], 'oae_dp');
r = sub(RC, 3, {aw, 64, '1x'}, 2);  lbl(r, 'Freq. points', 1, false, 'oae_dp');   num(r, 512, 'oae_dp_npts', 2, [16 4096], 'oae_dp');
r = sub(RC, 4, {aw, FW, '1x'}, 2);  lbl(r, 'Artifact (SD)', 1, false, 'oae_dp');  num(r, 3, 'oae_dp_ar', 2, [1 20], 'oae_dp');
% SFOAE
r = sub(RC, 2, {aw, 64, '1x'}, 2);  lbl(r, 'Window base (s)', 1, false, 'oae_sf'); num(r, 0.038, 'oae_sf_win', 2, [0.002 1], 'oae_sf');
r = sub(RC, 3, {aw, 64, '1x'}, 2);  lbl(r, 'Freq. points', 1, false, 'oae_sf');    num(r, 512, 'oae_sf_npts', 2, [16 4096], 'oae_sf');
r = sub(RC, 4, {aw, FW, '1x'}, 2);  lbl(r, 'Artifact (SD)', 1, false, 'oae_sf');   num(r, 4, 'oae_sf_ar', 2, [1 20], 'oae_sf');
r = sub(RC, 5, {aw, 64, '1x'}, 2);  lbl(r, 'High-pass (Hz)', 1, false, 'oae_sf');  num(r, 300, 'oae_sf_hp', 2, [0 5000], 'oae_sf');
r = sub(RC, 6, {aw, 140, '1x'}, 2); lbl(r, 'Noise floor', 1, false, 'oae_sf');
put(uidropdown(r,'Items',{'Nearby freqs','Subtraction'},'ItemsData',{'adjacent','subtraction'}, ...
    'Value','adjacent','Tag','oae_sf_nf','UserData','oae_sf','FontSize',OFS,'BackgroundColor','white', ...
    'Tooltip','Nearby freqs: fit at 1.10–1.16 × probe phase  |  Subtraction: alternate-trial difference'), 2);
% TEOAE
r = sub(RC, 2, {aw, 64, '1x'}, 2);  lbl(r, 'High-pass (Hz)', 1, false, 'oae_te');   num(r, 200, 'oae_te_hp', 2, [0 5000], 'oae_te');
r = sub(RC, 3, {aw, FW, '1x'}, 2);  lbl(r, 'Trimmed mean (%)', 1, false, 'oae_te'); num(r, 20, 'oae_te_trim', 2, [0 50], 'oae_te');
r = sub(RC, 4, {'1x'}, 0);          lbl(r, 'No FPL calibration: SPL only', 1, true, 'oae_te');
% Files (every OAE type): which raw recording when a data folder holds
% several — under the longest block (SFOAE, 5 rows)
r = sub(RC, 8, {aw, 150, '1x'}, 2);
rec_file_menus(r, OFS);
RC.RowHeight = oae_rows;  RC.ColumnWidth = {'1x'};

% ── MEMR ─────────────────────────────────────────────────────────────────
app.h_memr_param_panel = mkpanel('MEMR Parameters');
p = app.h_memr_param_panel;
G = body(p);
% ART (Tag memr_art) and exploratory (Tag memr_mx) text blocks share the
% top row (navigate_results>update_param_panels shows the one on screen)
mrows = repmat({LH}, 1, 7);
cellm = row(G, 7*LH + 6*2 + 4, {'1x'}, 0);
cellm.RowHeight = {'1x', 0};                    % (spare cell while both blocks are made)
ART = blk(cellm, mrows, 2);
MX  = blk(cellm, mrows, 2);
cellm.RowHeight = {'1x'};  cellm.ColumnWidth = {'1x'};
textline(ART, 1, 'Wideband Middle Ear Muscle Reflex', true, 'memr_art');
textline(ART, 2, 'Frequency range: 0.2–8 kHz', false, 'memr_art');
textline(ART, 3, 'Metric: reflex magnitude (dB) vs. elicitor level (mean |change|, 0.5–2 kHz)', false, 'memr_art');
textline(ART, 4, 'Response: Δ ear-canal click level (dB) re. no elicitor', false, 'memr_art');
textline(ART, 5, 'Elicitor: broadband noise, multiple levels', false, 'memr_art');
textline(ART, 6, 'Output: growth functions and acoustic reflex thresholds (ART)', false, 'memr_art');
textline(MX, 1, 'Wideband MEMR — Exploratory Analysis', true, 'memr_mx');
textline(MX, 2, 'One file per recording, shared by every exploratory type (_MX_)', false, 'memr_mx');
textline(MX, 3, 'Click spectra: complex mean over trials (magnitude + phase), 0.2–8 kHz', false, 'memr_mx');
textline(MX, 4, 'Baseline: click 1 (no elicitor); response: clicks 2–7', false, 'memr_mx');
textline(MX, 5, 'Noise floor: trial-to-trial variability; detected when SNR ≥ 3', false, 'memr_mx');
textline(MX, 6, 'Absorbance: FPL calibration of the same session (if recorded)', false, 'memr_mx');
textline(MX, 7, 'ART files are not read or changed', false, 'memr_mx');
% Files (ART and exploratory): same setting as in OAE Parameters
r = row(G, RH, {146, 150, '1x'}, 4);
rec_file_menus(r, OFS);
% Plot default of the MEMR Growth Response average (app.h_output.chk)
r = row(G, RH, {146, 130, '1x'}, 4);
put(uilabel(r,'Text','Plot Defaults:','FontSize',OFS,'FontColor',app.clr_black,'HorizontalAlignment','right', ...
    'Tooltip','Saved images and the Results views start with these; change them live with Plot Settings'), 1);
O = app.h_output;
O.chk.resp_sd = pdef_btn(app, r, 'Response SD', 'Mean ± SD bands of the MEMR Growth Response average', 2);
app.h_output = O;
% Labels right next to their controls (right-aligned in their column)
for hl = findall(app.MeasuresPanel, 'Type','uilabel')'
    if any(strcmp(hl.Tag, {'efr_harm_lbl','efr_win_lbl','efr_low_lbl','efr_high_lbl', ...
            'efr_sum_lbl','efr_norm_lbl','efr_dam_lbl'})) || strcmp(hl.Text, 'Data File:')
        hl.HorizontalAlignment = 'right';
    end
end

% Shown instead of the parameters when the type on screen is not selected
% for the run (navigate_results>do_measures); same cell as the panels
app.h_param_hint = uilabel(host, 'Text','', 'FontSize',FS-1, ...
    'FontColor',[0.45 0.45 0.45], 'HorizontalAlignment','center', 'WordWrap','on', ...
    'Visible','off');
lay(app.h_param_hint, 2, 1);

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

    function p = mkpanel(title)
        % titled panel in the parameter cell (hidden until its measure is shown)
        p = uipanel(host,'Title',title,'FontSize',FS-1,'FontWeight','bold', ...
            'BackgroundColor',BG,'Visible','off');
        lay(p, 2, 1);
        if isprop(p,'BorderColor'), p.BorderColor = app.clr_gold; end
    end

    function g = body(p)
        % scrollable grid of fixed rows (+ a '1x' filler row at the end);
        % row heights kept in appdata 'apat_rows' (update_param_panels
        % collapses rows with nothing visible)
        g = uigridlayout(p, 'RowHeight',{'1x'}, 'ColumnWidth',{'1x'}, 'Padding',[12 8 12 8], ...
            'RowSpacing',6, 'ColumnSpacing',0, 'Scrollable','on', 'BackgroundColor',BG);
        setappdata(g, 'apat_rows', {});
    end

    function r = row(g, h, cols, cs)
        % next row (height h) of body grid g: a grid with columns cols
        if nargin < 4, cs = 6; end
        rh = getappdata(g, 'apat_rows');  rh{end+1} = h;
        setappdata(g, 'apat_rows', rh);
        g.RowHeight = [rh, {'1x'}];
        r = grd(g, {'1x'}, cols, BG, [0 0 0 0], 0, cs);
        lay(r, numel(rh), 1);
    end

    function b = blk(parent, rows, rs)
        % block grid (one column of fixed rows) in cell (1,1) of PARENT;
        % several blocks can share that cell (shown one at a time)
        if nargin < 3, rs = 6; end
        b = grd(parent, rows, {'1x'}, BG, [0 0 0 0], rs, 0);
        lay(b, 1, 1);
    end

    function r = sub(B, k, cols, cs)
        % row grid in row k of block B (blocks' rows may hold several
        % overlapping row grids: one per OAE type)
        if nargin < 4, cs = 6; end
        r = grd(B, {'1x'}, cols, BG, [0 0 0 0], 0, cs);
        lay(r, k, 1);
    end

    function h = put(h, c)
        % component → column c of its row grid
        lay(h, 1, c);
    end

    function h = lbl(r, txt, c, grey, grp)
        % label of an OAE parameter row (grp → UserData, used to show per
        % subtype); row labels are right-aligned so they sit next to their
        % control, grey unit / note labels stay left-aligned
        if nargin < 4 || isempty(grey), grey = false; end
        fc = app.clr_black;  fs = OFS;  ha = 'right';
        if grey, fc = GRY; fs = OFS-1; ha = 'left'; end
        h = put(uilabel(r,'Text',txt,'FontSize',fs,'FontColor',fc,'HorizontalAlignment',ha), c);
        if nargin > 4, h.UserData = grp; end
    end

    function h = num(r, v, tag, c, lim, grp)
        h = put(uieditfield(r,'numeric','Value',v,'Limits',lim,'Tag',tag,'FontSize',OFS, ...
            'BackgroundColor','white'), c);
        if nargin > 5 && ~isempty(grp), h.UserData = grp; end
    end

    function hnum(r, v, tag, c)
        % harmonic number field (EFR RAM ranges)
        put(uieditfield(r,'numeric','Value',v,'Limits',[1 16],'RoundFractionalValues','on', ...
            'Tag',tag,'FontSize',FS-1,'BackgroundColor','white'), c);
    end

    function dash(r, c)
        put(uilabel(r,'Text','–','FontSize',OFS,'HorizontalAlignment','center'), c);
    end

    function sep(r, c)
        put(uilabel(r,'Text','|','FontSize',OFS,'FontColor',GRY,'HorizontalAlignment','center'), c);
    end

    function rec_file_menus(r, fs)
        % "Data File": which raw recording to use when a data folder holds
        % several (choose_recording). One setting, shown in the OAE and MEMR
        % panels (dropdowns with the same Tag stay in sync). The FPL
        % calibration always follows the data file: the calibration recorded
        % closest before it (no setting). Columns 1 (label) and 2 of row r.
        items = {'Auto (Most Trials)','Auto (Most Recent)','Auto (Least Recent)', ...
                 'Manual (Ask Once)','Manual (Always)'};
        vals  = {'complete','latest','earliest','ask_once','ask_every'};
        tipD = ['Several raw recordings in a data folder (e.g. p0004 and p0014 sweptDPOAE): ' ...
            'Auto picks one without asking — Most Trials: all trials completed, then most ' ...
            'trials, then the most recent; Most Recent / Least Recent: by recording number. ' ...
            'Manual (Ask Once) asks and remembers the answer; Manual (Always) asks every time. ' ...
            'Manual shows the files with a quick preview of each (click = preview, ' ...
            'double-click = use it). The FPL calibration always follows the data file: the ' ...
            'one recorded closest before it. Choices are logged in Analysis/Logs/APAT_recording_choices_log.txt.'];
        put(uilabel(r,'Text','Data File:','FontSize',fs,'FontColor',app.clr_black,'Tooltip',tipD), 1);
        put(uidropdown(r,'Items',items,'ItemsData',vals,'Value','complete','Tag','rec_data_dd', ...
            'FontSize',fs,'BackgroundColor','white','Tooltip',tipD, ...
            'ValueChangedFcn',@(src,~) rec_sync(src)), 2);
    end

    function rec_sync(src)
        % same value in the OAE and MEMR panels
        for hh = findall(app.MeasuresPanel, 'Tag', src.Tag)'
            if hh ~= src, hh.Value = src.Value; end
        end
        update_summary(app);
    end

    function textline(B, k, txt, bold, tag)
        % one line of text in row k of block B
        if bold, fw = 'bold'; fc = app.clr_black; fs = FS; else, fw = 'normal'; fc = GRY; fs = FS-2; end
        hh = uilabel(B,'Text',txt,'FontSize',fs,'FontWeight',fw,'FontColor',fc);
        lay(hh, k, 1);
        if nargin > 4 && ~isempty(tag), hh.Tag = tag; end
    end

end


function buildResultsTab(app, FIG_W, TAB_H)
%BUILDRESULTSTAB  Results tab: control bar (View | Subject | Exclude | 8
%   measure buttons in 4 groups | Frequency | … | Tracking), plot host with
%   the figure cards (2 modes × measures, stacked) and the buttons over
%   them, status strip.
%   Containers: a full-tab root panel (normalized) with four pixel parts
%   placed by res_layout (its SizeChangedFcn): bar (a uigridlayout inside:
%   'fit' / fixed columns, a '1x' spacer before Tracking so Tracking is
%   always right-anchored; bar_fit shares the measure buttons out when the
%   bar is too narrow and gives hidden items zero width), gold rule, plot
%   host (plain panel: cards fill it in normalized units, so the embedded
%   plots, fit_layout and Plot Settings work as before) and status strip.
FS     = 15;
ROW_H  = 46;
CAP_H  = 16;
BAR_H  = 2 + 8 + CAP_H + 2 + ROW_H + 2 + 3 + 6;   % padding, caption, buttons, underline
RT     = res_style('theme', app);    % Results theme (private/res_style.m)
PN     = app.clr_panel;
IN_H   = TAB_H - 30;                 % first guess of the tab's content height (res_layout fixes it)

root = uipanel(app.ResultsTab, 'BorderType','none', 'BackgroundColor',app.clr_bg, ...
    'Units','normalized', 'Position',[0 0 1 1], 'AutoResizeChildren','off');
app.res.root = root;
barp = uipanel(root,'BorderType','none','BackgroundColor',PN, ...
    'Position',[0 IN_H-BAR_H FIG_W BAR_H]);
rule = uipanel(root,'BorderType','none','BackgroundColor',app.clr_gold, ...
    'Position',[0 IN_H-BAR_H-2 FIG_W 2]);

% ── Bar grid ─────────────────────────────────────────────────────────────
labels = APAT_app.measure_tab_labels();
groups = {[1 2],[3 4],[5 6 7],[8]};             % ABR | EFR | OAE | MEMR
grp_names = {'ABR','EFR','OAE','MEMR'};
BTN_W = 112;  SHORT_W = 80;
% columns: 1 Average | 2 Individual | 3 Subject | 4 Exclude | 5 divider |
% measure groups (divider between) | MEMR dropdown | Frequency | spacer |
% Tracking chip | Individual (tracking)
cw = {100, 112, 90, 96, 2};
col_of = zeros(1, 8);  meas_w = zeros(1, 8);
for gi = 1:numel(groups)
    for idx = groups{gi}
        lbl = labels{idx};
        w = BTN_W;
        if idx ~= 8 && numel(lbl) <= 5, w = SHORT_W; end
        cw{end+1} = w;  col_of(idx) = numel(cw);  meas_w(idx) = w; %#ok<AGROW>
    end
    if gi < numel(groups), cw{end+1} = 2; end %#ok<AGROW>
end
c_mdd = numel(cw) + 1;  cw{end+1} = 110;
c_frq = numel(cw) + 1;  cw{end+1} = 148;
c_spc = numel(cw) + 1;  cw{end+1} = '1x';
c_trk = numel(cw) + 1;  cw{end+1} = 150;  cw{end+1} = 100;
B = uigridlayout(barp, 'RowHeight',{CAP_H, ROW_H, 3}, 'ColumnWidth',cw, ...
    'Padding',[16 6 16 8], 'RowSpacing',2, 'ColumnSpacing',8, 'BackgroundColor',PN);
app.res.bar = struct('grid',B, 'cols',{cw}, 'subj',[3 4], 'freq',c_frq, 'spacer',c_spc, ...
    'track',[c_trk c_trk+1], 'meas',col_of, 'meas_w',meas_w, 'pad',32, 'gap',8);

% ── View: Average / Individual, Subject, Exclude ────────────────────────
caption(1, [1 2], 'View');
app.FigAvgBtn = uibutton(B,'state','Text','Average','Value',true, ...
    'FontSize',FS,'FontWeight','bold', ...
    'BackgroundColor',RT.sel,'FontColor',RT.ink, ...
    'ValueChangedFcn',@(~,~) navigate_results(app,'avg'));
lay(app.FigAvgBtn, 2, 1);
app.FigIndBtn = uibutton(B,'state','Text','Individual','Value',false, ...
    'FontSize',FS,'FontWeight','bold', ...
    'BackgroundColor',app.clr_btn,'FontColor',app.clr_black, ...
    'ValueChangedFcn',@(~,~) navigate_results(app,'ind'));
lay(app.FigIndBtn, 2, 2);
app.FigSubjCaption = uilabel(B,'Text','SUBJECT','FontSize',10,'FontWeight','bold', ...
    'FontName',RT.mono,'FontColor',RT.cap,'Visible','off');
lay(app.FigSubjCaption, 1, 3);
v = vbox(B, ROW_H-10, 2, 3, PN);
app.FigSubjDropdown = uidropdown(v, ...
    'Items',{'-'},'Value','-', ...
    'FontSize',FS,'Visible','off', ...
    'ValueChangedFcn',@(~,~) navigate_results(app,'subj'));
lay(app.FigSubjDropdown, 2, 1);
% Exclude button: leave subjects / conditions out of the group average
% (private/exclusions.m). Shown in the Individual view only (with the
% Subject dropdown); red "Excluded" when the subject on screen is excluded.
ex_fn = @exclusions;
v = vbox(B, ROW_H-10, 2, 4, PN);
app.res.excl_btn = uibutton(v,'push','Text','Exclude', ...
    'FontSize',FS-2,'FontWeight','bold','BackgroundColor',app.clr_btn,'FontColor',app.clr_black, ...
    'Tooltip','Leave subjects or conditions out of the group average', ...
    'Visible','off', 'ButtonPushedFcn',@(~,~) ex_fn(app,'dialog'));
lay(app.res.excl_btn, 2, 1);
divider(5);

% ── 8 measure buttons (grouped, thin dividers between groups) ───────────
% MEMR: one button (the MEMR analysis on screen; ART by default) + a
% dropdown that picks it (ART, Vector, Growth …). The exploratory analyses
% (labels 9-15) also get a button each, kept hidden in the MEMR button's
% cell, so the measure-button highlighting works the same for every index
% (navigate_results>memr_sync).
app.res.btns = gobjects(1, numel(labels));
memr_idx = find(strncmp(labels, 'MEMR', 4));
app.res.grp_caps = gobjects(1, numel(groups));   % group captions (dark gold = measure on screen)
for gi = 1:numel(groups)
    grp = groups{gi};
    cols = col_of(grp);
    if gi == 4, cols = [cols c_mdd]; end %#ok<AGROW>
    app.res.grp_caps(gi) = caption(1, [min(cols) max(cols)], grp_names{gi});
    if gi == 1, app.res.grp_caps(gi).FontColor = RT.gold_dk; end
    for k = 1:numel(grp)
        idx = grp(k);
        lbl = labels{idx};
        if strcmp(lbl, 'MEMR'), lbl = 'ART'; end      % display only (labels{} stay the internal keys)
        if idx == 8
            btn = uibutton(B,'push','Text',lbl, ...
                'FontSize',FS-1,'FontWeight','bold','BackgroundColor',app.clr_btn, ...
                'FontColor',app.clr_black,'UserData',idx, ...
                'ButtonPushedFcn',@(src,~) navigate_results(app,'meas_btn',src.UserData));
            lay(btn, 2, col_of(8));
            app.res.btns(idx) = btn;
            res_style('icon', btn, idx);
            for mi = memr_idx(memr_idx > 8)           % hidden twins (highlight bookkeeping only)
                app.res.btns(mi) = uibutton(B,'push','Text',strrep(labels{mi},'MEMR ',''), ...
                    'Visible','off','UserData',mi, ...
                    'ButtonPushedFcn',@(src,~) navigate_results(app,'meas_btn',src.UserData));
                lay(app.res.btns(mi), 2, col_of(8));
            end
            mnames = cellfun(@(s) strrep(s,'MEMR ',''), labels(memr_idx), 'UniformOutput', false);
            mnames{1} = 'ART';
            v = vbox(B, ROW_H-12, 2, c_mdd, PN);
            app.res.memr_dd = uidropdown(v, 'Items',mnames, 'ItemsData',memr_idx, ...
                'Value',8, 'FontSize',FS-2, ...
                'Tooltip','MEMR analysis to show (ART or one of the exploratory analyses)', ...
                'ValueChangedFcn',@(src,~) navigate_results(app,'meas_btn',src.Value));
            lay(app.res.memr_dd, 2, 1);
            continue
        end
        is_first = (gi==1 && k==1);
        btn = uibutton(B,'push','Text',lbl, ...
            'FontSize',FS-1,'FontWeight','bold', ...
            'BackgroundColor',ternary(is_first,RT.sel,RT.btn), ...
            'FontColor',RT.ink, 'UserData',idx, ...
            'ButtonPushedFcn',@(~,~) navigate_results(app,'meas_btn',idx));
        lay(btn, 2, col_of(idx));
        app.res.btns(idx) = btn;
        res_style('icon', btn, idx);
    end
    if gi < numel(groups), divider(max(col_of(grp)) + 1); end
end

% ── Freq/Cond dropdown ────────────────────────────────────────────────────
h = uilabel(B,'Tag','fig_freq_lbl','Text','FREQUENCY', ...
    'FontSize',10,'FontWeight','bold','FontName',RT.mono,'FontColor',RT.cap, 'Visible','off');
lay(h, 1, c_frq);
v = vbox(B, ROW_H-12, 2, c_frq, PN);
app.FigFreqDD = uidropdown(v, ...
    'Items',{'—'},'Value','—', ...
    'FontSize',FS,'Visible','off', ...
    'ValueChangedFcn',@(~,~) navigate_results(app,'freq'));
lay(app.FigFreqDD, 2, 1);

% ── Subject tracking chip (shown after clicking a subject point) ──────────
% Subtle-yellow chip (gold border) with the subject in dark bold text and a
% small dark ✕ (= stop tracking, also Esc), then "Individual". The last
% columns of the bar, after the '1x' spacer: always right-anchored.
CH = ROW_H - 12;
pk_cap = caption(1, [c_trk c_trk+1], 'Tracking');
pk_cap.Visible = 'off';
v = vbox(B, CH, 2, c_trk, PN);
pk_pill = uipanel(v,'BorderType','line','BackgroundColor',RT.sel,'Visible','off');
lay(pk_pill, 2, 1);
try, pk_pill.BorderColor = RT.gold; catch, try, pk_pill.HighlightColor = RT.gold; catch, end, end
try, pk_pill.BorderWidth = 2; catch, end
pg = grd(pk_pill, {'1x', 24, '1x'}, {'1x', 24}, RT.sel, [10 0 4 0], 0, 4);
pk_name = uilabel(pg,'Text','','FontSize',FS,'FontWeight','bold', ...
    'FontColor',RT.ink,'Tooltip','Subject tracked in every plot','Visible','off');
lay(pk_name, [1 3], 1);
pk_clr  = uibutton(pg,'push','Text',char(10005),'FontSize',12,'FontWeight','bold', ...
    'BackgroundColor',RT.ink,'FontColor',RT.cream, ...
    'Tooltip','Stop tracking this subject (Esc)','Visible','off', ...
    'ButtonPushedFcn',@(~,~) subject_pick(app,'clear'));
lay(pk_clr, 2, 2);
v = vbox(B, CH, 2, c_trk+1, PN);
pk_open = uibutton(v,'push','Text','Individual','FontSize',FS-2,'FontWeight','bold', ...
    'BackgroundColor',RT.btn,'FontColor',RT.ink, ...
    'Tooltip','Open this subject''s individual results','Visible','off', ...
    'ButtonPushedFcn',@(~,~) subject_pick(app,'open'));
lay(pk_open, 2, 1);
% [caption, name label, open button, ✕ (clear) button, chip backdrop]
pk_ui = gobjects(1,5);  pk_ui(1) = pk_cap;  pk_ui(2) = pk_name;  pk_ui(3) = pk_open;  pk_ui(4) = pk_clr;  pk_ui(5) = pk_pill;
app.res.pick_ui  = pk_ui;
app.res.sel_subj = '';

% Gold underline under the measure button on screen (res_style 'underline'
% moves it to that button's column)
app.res.meas_line = uipanel(B,'BorderType','none','BackgroundColor',RT.gold, ...
    'Tag','res_meas_line','Visible','off');
lay(app.res.meas_line, 3, col_of(1));
B.RowHeight = {CAP_H, ROW_H, 3};  B.ColumnWidth = cw;   % (overlapping children placed)

% ── Plot host: figure cards (2 modes × measures, stacked, one visible) ───
N_MEAS = numel(labels);
app.res.panels   = cell(2, N_MEAS);
app.res.subj_data = cell(1, N_MEAS);
for mi = 1:N_MEAS
    app.res.subj_data{mi} = struct('names',{{}},'panels',{{}});
end
ST_H = 26;  M = 8;  G = 6;
host_y = G + ST_H + G;
host = uipanel(root,'BorderType','none','BackgroundColor',app.clr_bg,'AutoResizeChildren','off', ...
    'Position',[M host_y FIG_W-2*M max(50, IN_H-BAR_H-2-G-host_y)]);
app.res.plot_host = host;
% white cards with a thin gold border, filling the host (normalized units:
% they follow the host without any MATLAB code)
for mode = 1:2
    for mi = 1:N_MEAS
        p = uipanel(host,'BorderType','line','BackgroundColor',[1 1 1], ...
            'Units','normalized','Position',[0 0 1 1],'Visible','off');
        try, p.BorderColor = RT.gold_line; catch, try, p.HighlightColor = RT.gold_line; catch, end, end
        if mode == 2
            make_placeholder(p, 'No average figures yet', ...
                ['Pick subjects and a measure on the Setup tab, then press Run Analysis ' ...
                '(analyses that did not change since their last run load in seconds).']);
        else
            make_placeholder(p, 'No individual figures yet', ...
                'Figures for each subject appear here as the analysis runs.');
        end
        app.res.panels{mode,mi} = p;
    end
end
% "Plot Settings" (top-right of the plot area, over the cards): shows /
% hides the view controls of the plot on screen (private/plot_settings.m).
% Placed by host_layout (the host's SizeChangedFcn).
ps_fn = @plot_settings;
app.res.ps_on  = false;
app.res.ps_btn = uibutton(host,'push','Text','Plot Settings', ...
    'FontSize',FS-2,'FontWeight','bold','BackgroundColor',RT.gold,'FontColor',RT.ink, ...
    'Tooltip','Show / hide the controls of this plot (conditions, subjects, shading, axis limits …)', ...
    'Position',[10 10 170 32],'Enable','off', ...
    'ButtonPushedFcn',@(~,~) ps_fn(app,'toggle'));
% "Save Image" / "Save As New" (left of Plot Settings): write the view on
% screen — with its current Plot Settings and axes — over its auto-saved PNG,
% or as a new numbered copy (<name>_2.png …) (private/save_view.m)
app.res.save_btn = uibutton(host,'push','Text','Save Image', ...
    'FontSize',FS-2,'FontWeight','normal','BackgroundColor',RT.btn,'FontColor',RT.ink, ...
    'Tooltip','Save the view on screen (as shown now) over its saved image', ...
    'Position',[10 10 128 32],'Enable','off', ...
    'ButtonPushedFcn',@(~,~) save_view_cb(app,'save'));
app.res.savenew_btn = uibutton(host,'push','Text','Save As New', ...
    'FontSize',FS-2,'FontWeight','normal','BackgroundColor',RT.btn,'FontColor',RT.ink, ...
    'Tooltip','Save the view on screen as a new image next to the saved one (name_2.png, name_3.png …)', ...
    'Position',[10 10 128 32],'Enable','off', ...
    'ButtonPushedFcn',@(~,~) save_view_cb(app,'new'));
% short confirmation under the buttons (hidden after a few seconds)
app.res.save_msg = uilabel(host,'Text','','FontSize',FS-3,'FontWeight','bold', ...
    'FontColor',RT.gold_dk,'BackgroundColor',[1 1 1],'HorizontalAlignment','right', ...
    'Position',[10 10 560 20],'Visible','off');
host.SizeChangedFcn = @(~,~) host_cb(app);          % local wrapper (silent)

% Status strip under the plot card: one line "OAE › DPOAE › AVERAGE  GROUP …
% n SUBJECTS · n CONDITIONS  EXCLUDED: …" + "SAVED hh:mm" right
% (res_style 'status'; refreshed on view changes and after saves)
sb = uipanel(root,'BorderType','line','BackgroundColor',RT.status_bg, ...
    'Position',[M G FIG_W-2*M ST_H]);
try, sb.BorderColor = RT.gold_line; catch, try, sb.HighlightColor = RT.gold_line; catch, end, end
sg = grd(sb, {'1x'}, {'1x', 140}, RT.status_bg, [12 0 12 0], 0, 12);
app.res.status_lbl = uilabel(sg,'Text','','FontSize',11,'FontWeight','bold','FontName',RT.mono, ...
    'FontColor',RT.status_fg);
lay(app.res.status_lbl, 1, 1);
app.res.status_save = uilabel(sg,'Text','','FontSize',11,'FontWeight','bold','FontName',RT.mono, ...
    'FontColor',RT.status_fg,'HorizontalAlignment','right');
lay(app.res.status_save, 1, 2);
app.res.status_bar = sb;
app.res.last_save  = [];
setappdata(root, 'apat_parts', struct('bar',barp, 'rule',rule, 'host',host, 'status',sb));
root.SizeChangedFcn = @(~,~) res_cb(app);           % local wrapper (silent)
% Start in Average mode, measure 1 (ABR Thresholds)
app.res.mode     = 2;
app.res.meas_idx = 1;
app.res.panels{2,1}.Visible = 'on';
res_style('bar_sync', app);
res_style('status', app);

% ── Blind-mode cover: hides the whole Results tab (subject names, condition
%    tabs, figure titles) during a blinded run until the user unblinds.
%    Created last (child of the tab, full size) so it sits above everything.
app.BlindOverlay = uipanel(app.ResultsTab,'BorderType','none', ...
    'BackgroundColor',app.clr_black,'Units','normalized','Position',[0 0 1 1],'Visible','off');
CW = 560;  CHh = 190;
bg = grd(app.BlindOverlay, {'1x', CHh, '1x'}, {'1x', CW, '1x'}, app.clr_black, [10 10 10 10], 0, 0);
bc = uipanel(bg,'BorderType','line','BackgroundColor',app.clr_panel);
lay(bc, 2, 2);
if isprop(bc,'BorderColor'), bc.BorderColor = app.clr_gold; end
bcg = grd(bc, {6, 40, '1x', 40}, {'1x', 240, '1x'}, app.clr_panel, [0 18 0 0], 8, 0);
h = uipanel(bcg,'BorderType','none','BackgroundColor',app.clr_gold);
lay(h, 1, [1 3]);
h = uilabel(bcg,'Text','Blind mode','FontSize',22,'FontWeight','bold', ...
    'FontColor',app.clr_black,'HorizontalAlignment','center');
lay(h, 2, [1 3]);
app.BlindOverlayMsg = uilabel(bcg,'Text','', 'FontSize',14,'WordWrap','on', ...
    'FontColor',[0.40 0.40 0.40],'HorizontalAlignment','center');
lay(app.BlindOverlayMsg, 3, [1 3]);
app.BlindRevealBtn = uibutton(bcg,'push','Text','Unblind & show results', ...
    'FontSize',15,'FontWeight','bold','BackgroundColor',app.clr_gold, ...
    'FontColor',app.clr_black,'Enable','off', ...
    'ButtonPushedFcn',@(~,~) set(app.BlindOverlay,'Visible','off'));
lay(app.BlindRevealBtn, 4, 2);


    function hc = caption(rr, cc, txt)
        % small bold monospaced caps, muted grey, above a bar group
        hc = uilabel(B,'Text',upper(txt),'FontSize',10,'FontWeight','bold', ...
            'FontName',RT.mono,'FontColor',RT.cap);
        lay(hc, rr, cc);
    end

    function divider(c)
        % thin gold divider between bar groups (column c, 4 px short of
        % the button row at both ends)
        dv = vbox(B, ROW_H-8, 2, c, PN);
        dv.RowHeight = {4, '1x', 4};
        d = uipanel(dv,'BorderType','none','BackgroundColor',app.clr_gold);
        lay(d, 2, 1);
    end

end


function buildStatusTab(app)
%BUILDSTATUSTAB  Data Status tab: control bar (title, legend, Refresh) over
%   the per-measure table tabs (build_status_table). Grid layout.
PADS  = 8;
BTN_H = 40;
BAR_H = BTN_H + 2*PADS + 6;
root = uipanel(app.StatusTab, 'BorderType','none', 'BackgroundColor',app.clr_bg, ...
    'Units','normalized', 'Position',[0 0 1 1]);
G = grd(root, {BAR_H, '1x'}, {'1x'}, app.clr_bg, [0 0 0 0], 0, 0);
bar = uipanel(G,'BorderType','none','BackgroundColor',app.clr_panel);
lay(bar, 1, 1);
BG2 = grd(bar, {'1x', 2}, {'1x'}, app.clr_panel, [0 0 0 0], 0, 0);
rl = uipanel(BG2,'BorderType','none','BackgroundColor',app.clr_gold);
lay(rl, 2, 1);
leg = {[0.18 0.72 0.42],'Analysed'; [0.97 0.72 0.22],'Other measures only'; [0.82 0.82 0.82],'No data'};
cols = [{'fit', 'fit', 12}, repmat({'fit'}, 1, size(leg,1)), {'1x', 150}];
C = grd(BG2, {'1x'}, cols, app.clr_panel, [16 PADS 16 PADS], 0, 16);
lay(C, 1, 1);
h = uilabel(C,'Text','Data Availability','FontSize',18,'FontWeight','bold', ...
    'FontColor',app.clr_black);
lay(h, 1, 1);
h = uilabel(C,'Text','Analysis outputs found per subject and condition', ...
    'FontSize',13,'FontColor',[0.45 0.45 0.45]);
lay(h, 1, 2);
for li = 1:size(leg,1)
    g = grd(C, {'1x', 16, '1x'}, {16, 'fit'}, app.clr_panel, [0 0 0 0], 0, 6);
    lay(g, 1, 3 + li);
    sw = uipanel(g,'BorderType','none','BackgroundColor',leg{li,1});
    lay(sw, 2, 1);
    t = uilabel(g,'Text',leg{li,2},'FontSize',13);
    lay(t, [1 3], 2);
end
app.RefreshStatusBtn = uibutton(C,'push','Text','⟳  Refresh', ...
    'FontSize',16,'FontWeight','bold', ...
    'BackgroundColor',app.clr_gold,'FontColor',app.clr_black, ...
    'ButtonPushedFcn',@(~,~) RefreshStatusButtonPushed(app));
lay(app.RefreshStatusBtn, 1, numel(cols));

app.StatusInnerTG = uitabgroup(G);
lay(app.StatusInnerTG, 2, 1);
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
% Built for this size; relayout_results scales its contents to the panel's
% current size after window resizes (appdata apat_pe_scale)
setappdata(app.PeakEditPanel, 'apat_pe_size', [FIG_W TAB_H]);
setappdata(app.PeakEditPanel, 'apat_pe_scale', [1 1]);

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
