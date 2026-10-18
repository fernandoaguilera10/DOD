function run_status(app, state, varargin)
%RUN_STATUS  Header run status card (top right) and the Run Analysis button.
%   run_status(app, 'start', label, i, n)    card shown, Stop on, Run button
%                                             locked (busy look); i / n = which
%                                             of the selected analyses
%   run_status(app, 'phase', label, i, n [, sheet])  next analysis of the run:
%                                             title, caption "ANALYSIS i OF n"
%                                             ("NOISE · ANALYSIS 2 OF 6" with the
%                                             Experiment; also for 'start'), bar reset
%   run_status(app, 'progress', n, total, msg)  bar n/total, "n of total",
%                                             current step
%   run_status(app, 'tick', frame)           chinchilla animation step + elapsed time
%                                             (APAT_spinner timer, 0.1 s)
%   run_status(app, 'hop')                   'done' hop step (timer APAT_chinhop)
%   run_status(app, 'stopping')              Stop pressed: "Stopping…"
%   run_status(app, 'done' | 'stopped' | 'error', k, n [, n_err])  final state (k = analyses
%                                             finished / with errors of n), Stop hidden, Run button
%                                             unlocked; the card hides itself
%                                             after a few seconds — unless n_err > 0
%                                             (errors logged by apat_run_error:
%                                             "Done · 2 errors — see APAT_error_log.txt",
%                                             kept until the next run)
%   run_status(app, 'idle')                  Run button unlocked, card hidden
%   The card's handles are app.h_run (built in createComponents).
%
%   Chinchilla (Oct 16 2026, replaces the activity dot): R.chin / R.prop are
%   uiimage objects on a small track (R.lane) at the left of the card; images
%   are read once from @APAT_app/icons/chin_*.png (make_sprites.py),
%   composited on the card colour and kept in UIFigure appdata
%   'apat_chin_img'; each sprite is its own preloaded uiimage (appdata
%   'apat_chin_pool') that a tick only moves / shows / hides; R.chin / R.prop
%   are the two slots (they keep the name of the sprite shown). Motion is
%   in px per second of elapsed time (smooth however often it is drawn).
%   'start' = front view; running = pacing left / right (walk frames
%   alternate, speed grows with the elapsed time) with occasional behaviours
%   by elapsed time: >= 1 min fridge snack, >= 3 min meditation (incense),
%   >= 5 min phone (and faster pacing), >= 10 min pajamas + nap in bed
%   ("z Z"), any time a rare desperate moment (rarer after meditating);
%   'done' = happy hop, 'stopped' / 'error' = front view. The header sign
%   (chin_sign) is hidden while the card is shown.
try
    if ~isvalid(app), return; end
    R = app.h_run;
    if ~isstruct(R) || ~isfield(R,'card') || ~isvalid(R.card), return; end
catch
    return;
end
fig  = app.UIFigure;
% APAT palette only: gold (title / bar), cream (subtitle text); errors in a
% muted red so they still stand out
GOLD = app.clr_gold;  TXT = GOLD;  CREAM = [0.88 0.84 0.74];
GREEN = GOLD;  AMBER = CREAM;  RED = [0.86 0.47 0.42];
% Card drawn by icons/run_card.html (R.html): it animates the clock, bar,
% dot and chinchilla itself — the timer ticks have nothing to do
use_html = isfield(R, 'html') && isgraphics(R.html);
STALL_MIN = 15;                                  % hang alert: no progress for this long
if any(strcmp(state, {'start','phase','progress'}))   % progress: hang-alert clock restarts
    setappdata(fig, 'apat_last_prog', now); %#ok<TNOW1>
    try, setappdata(fig, 'apat_last_prog_ms', posixtime(datetime('now', 'TimeZone','local')) * 1000); catch, end
    setappdata(fig, 'apat_stall_logged', false);
    if ~use_html, try, app.h_progress_label.FontColor = CREAM; catch, end, end   % (hang alert off)
end
if use_html && strcmp(state, 'hop'), return; end
if use_html && strcmp(state, 'tick'), try, watchdog(); catch, end, return; end
if strcmp(state, 'start')                        % run start for the page clock (ms, UTC)
    try, setappdata(fig, 'apat_run_t0_ms', posixtime(datetime('now', 'TimeZone','local')) * 1000); catch, end
end
switch state
    case {'start','phase'}
        meas = '';  if ~isempty(varargin), meas = char(varargin{1}); end
        ii = 1;  nn = 1;
        if numel(varargin) >= 3, ii = varargin{2};  nn = varargin{3}; end
        if strcmp(state, 'start')
            stop_hide_timer();
            setappdata(fig, 'apat_run_t0', tic);
            stop_hop();
            chin_reset('front');
        end
        setappdata(fig, 'apat_phase_t0', tic);
        setappdata(fig, 'apat_run_prog', [0 0]);
        setappdata(fig, 'apat_run_n', nn);
        R.title.Text = ternary_s(isempty(meas), 'Running', ['Running  ·  ' meas]);
        R.title.FontColor = TXT;
        cap = ternary_s(nn > 1, sprintf('ANALYSIS %d OF %d', ii, nn), 'ANALYSIS IN PROGRESS');
        if numel(varargin) >= 4 && ~isempty(varargin{4})          % Experiment (roster sheet)
            cap = sprintf('%s  ·  %s', upper(char(varargin{4})), cap);
        end
        R.caption.Text = cap;
        app.h_progress_label.Text = 'Preparing…';
        R.elapsed.Text = mmss(elapsed_s());
        R.count.Text = '';
        R.fill.BackgroundColor = GOLD;
        set_bar(0);
        if strcmp(state, 'start')
            offer_off();                               % Resume / Restart → Stop again
            setappdata(fig, 'apat_paused', false);  setappdata(fig, 'apat_pause_active', false);
            setappdata(fig, 'apat_pause_total', 0);
            app.StopButton.Text = [char(9632) '  Stop'];  app.StopButton.Enable = 'on';  app.StopButton.Visible = 'on';
            if isfield(R, 'pause') && isgraphics(R.pause)
                R.pause.Text = [char(10074) char(10074) '  Pause'];  R.pause.Enable = 'on';
                R.pause.Tooltip = 'Pause after the current step (Resume continues; Stop is still available)';
                row({R.pause, app.StopButton});
            end
            R.card.Visible = 'on';
            try, chin_sign(app, 'hide'); catch, end
            run_button(true);
        end
    case 'progress'
        n = varargin{1};  total = varargin{2};  msg = '';
        if numel(varargin) >= 3, msg = char(varargin{3}); end
        setappdata(fig, 'apat_run_prog', [n total]);
        % the count is shown next to the bar: drop a trailing "(n / N)"
        msg = strtrim(regexprep(msg, '\s*\(\s*\d+\s*/\s*\d+\s*\)\s*$', ''));
        if ~isempty(msg), app.h_progress_label.Text = msg; end
        set_bar(min(1, max(0, n / max(total,1))));
        R.count.Text = count_txt();
        R.elapsed.Text = mmss(elapsed_s());
    case 'tick'
        if strcmp(R.card.Visible,'off'), return; end
        try, watchdog(); catch, end
        try, chin_tick(elapsed_s()); catch, end
        et = mmss(elapsed_s());  ct = count_txt();   % (only changed text is sent)
        if ~strcmp(R.elapsed.Text, et), R.elapsed.Text = et; end
        if ~strcmp(R.count.Text, ct), R.count.Text = ct; end
        % NO drawnow here: this runs from the spinner TIMER, which can fire
        % while the main thread is half-way through building a graphics
        % object (e.g. xregion in apat_xgroups). Flushing then corrupts the
        % scene ("Error in state of SceneNode") and can hang the run. The
        % main thread's own drawnow('limitrate') calls render these updates.
        return
    case 'stopping'
        R.title.Text = 'Stopping…';
        R.caption.Text = 'STOPPING';
        app.h_progress_label.Text = 'Finishing the current step — work that has finished is saved';
        app.StopButton.Text = 'Stopping…';  app.StopButton.Enable = 'off';
        if isfield(R, 'pause') && isgraphics(R.pause), R.pause.Visible = 'off'; end
        row({app.StopButton});
    case 'pausing'                                 % Pause pressed: waits for the next step
        setappdata(fig, 'apat_pause_texts', {R.title.Text, R.caption.Text, app.h_progress_label.Text});
        R.caption.Text = 'PAUSING';
        app.h_progress_label.Text = 'Pausing after the current step…';
        if isfield(R, 'pause') && isgraphics(R.pause)
            R.pause.Text = [char(9654) '  Resume'];  R.pause.Tooltip = 'Cancel the pause';
            row({R.pause, app.StopButton});
        end
    case 'paused'                                  % the run waits (APAT_app>wait_if_paused)
        setappdata(fig, 'apat_pause_active', true);
        setappdata(fig, 'apat_pause_t', tic);
        try, setappdata(fig, 'apat_pause_ms', posixtime(datetime('now', 'TimeZone','local')) * 1000); catch, end
        T = getappdata_or(fig, 'apat_pause_texts', {});
        if numel(T) == 3, T{1} = R.title.Text;  T{3} = app.h_progress_label.Text;   % caption from before 'pausing'
        else, T = {R.title.Text, R.caption.Text, app.h_progress_label.Text}; end
        setappdata(fig, 'apat_pause_texts', T);
        R.title.Text = regexprep(char(R.title.Text), '^Running', 'Paused');
        R.caption.Text = 'PAUSED';
        app.h_progress_label.Text = 'Paused — press Resume to continue, or Stop';
        if isfield(R, 'pause') && isgraphics(R.pause)
            R.pause.Text = [char(9654) '  Resume'];  R.pause.Tooltip = 'Continue the run';
            row({R.pause, app.StopButton});
        end
    case 'unpaused'
        if isappdata(fig, 'apat_pause_active') && isequal(getappdata(fig, 'apat_pause_active'), true)
            dur = toc(getappdata(fig, 'apat_pause_t'));     % the pause does not count as run time
            setappdata(fig, 'apat_pause_total', getappdata_or(fig, 'apat_pause_total', 0) + dur);
            if isappdata(fig, 'apat_run_t0_ms')
                setappdata(fig, 'apat_run_t0_ms', getappdata(fig, 'apat_run_t0_ms') + dur * 1000);
            end
            setappdata(fig, 'apat_last_prog', now); %#ok<TNOW1> hang-alert clock restarts
            try, setappdata(fig, 'apat_last_prog_ms', posixtime(datetime('now', 'TimeZone','local')) * 1000); catch, end
            T = getappdata_or(fig, 'apat_pause_texts', {});
            if numel(T) == 3, R.title.Text = T{1};  R.caption.Text = T{2};  app.h_progress_label.Text = T{3}; end
        else
            T = getappdata_or(fig, 'apat_pause_texts', {});   % pause cancelled before it began
            if numel(T) == 3, R.caption.Text = T{2};  app.h_progress_label.Text = T{3}; end
        end
        setappdata(fig, 'apat_pause_active', false);
        if isfield(R, 'pause') && isgraphics(R.pause)
            R.pause.Text = [char(10074) char(10074) '  Pause'];
            R.pause.Tooltip = 'Pause after the current step (Resume continues; Stop is still available)';
            row({R.pause, app.StopButton});
        end
    case {'done','stopped','error'}
        el = elapsed_s();
        kk = 1;  nn = 1;  ne = 0;
        if numel(varargin) >= 2, kk = varargin{1};  nn = varargin{2}; end
        if numel(varargin) >= 3 && ~isempty(varargin{3}), ne = varargin{3}; end
        switch state
            case 'done'
                clr = GREEN;  ttl = 'Complete';  cap = 'ANALYSIS COMPLETE';
                det = sprintf('Finished in %s', mmss(el));
                if nn > 1, det = sprintf('%d analyses finished in %s', nn, mmss(el)); end
                set_bar(1);
            case 'stopped'
                clr = AMBER;  ttl = 'Stopped';   cap = 'ANALYSIS STOPPED';
                det = sprintf('Stopped after %s — work that has finished is saved', mmss(el));
                if nn > 1, det = sprintf('Stopped after %s (%d of %d analyses done) — finished work is saved', mmss(el), kk, nn); end
            otherwise
                clr = RED;    ttl = 'Stopped with an error';  cap = 'ANALYSIS ERROR';
                det = 'See the error message for details — work that has finished is saved';
                if nn > 1
                    ttl = ternary_s(kk == 1, '1 analysis had an error', sprintf('%d analyses had an error', kk));
                    det = sprintf('The other %d of %d finished — see the error message for details', nn - kk, nn);
                end
        end
        if ne > 0 && ~strcmp(state, 'stopped')         % errors were logged, the run went on
            det = sprintf('Done · %d error%s — see Analysis/Logs/APAT_error_log.txt', ne, ternary_s(ne == 1, '', 's'));
            if strcmp(state, 'done'), cap = 'COMPLETE WITH ERRORS'; end
        end
        if strcmp(state, 'done'), chin_reset('happy'); start_hop(); else, chin_reset('front'); end
        R.title.Text = ttl;  R.title.FontColor = clr;  R.caption.Text = cap;
        app.h_progress_label.Text = det;
        R.fill.BackgroundColor = clr;
        R.elapsed.Text = '';
        pr = [0 0];  if isappdata(fig, 'apat_run_prog'), pr = getappdata(fig, 'apat_run_prog'); end
        R.count.Text = '';
        if nn > 1, R.count.Text = sprintf('%d of %d analyses', ternary_s(strcmp(state,'error'), nn - kk, kk), nn);
        elseif pr(2) > 0, R.count.Text = sprintf('%d of %d datasets', min(pr(1),pr(2)), pr(2)); end
        app.StopButton.Visible = 'off';
        if isfield(R, 'pause') && isgraphics(R.pause), R.pause.Visible = 'off'; end
        setappdata(fig, 'apat_paused', false);  setappdata(fig, 'apat_pause_active', false);
        run_button(false);
        if ne > 0 && ~strcmp(state, 'stopped')
            stop_hide_timer();                         % stays until the next run (user may be away)
        else
            hide_after(ternary_s(strcmp(state,'done'), 6, 12));
        end
    case 'offer'
        % stopped / error with analyses left (run checkpoint): Stop becomes
        % "Resume" (only when some analyses are done) and "Restart" appears;
        % the card stays until one is pressed or a new run starts
        can_resume = ~isempty(varargin) && logical(varargin{1});
        stop_hide_timer();
        setappdata(fig, 'apat_resume_offer', can_resume);
        b = app.StopButton;
        if isfield(R, 'pause') && isgraphics(R.pause), R.pause.Visible = 'off'; end
        if isfield(R, 'restart') && isgraphics(R.restart), R.restart.Enable = 'on'; end
        if can_resume
            b.Text = [char(9654) '  Resume'];  b.Enable = 'on';
            b.Tooltip = 'Continue with the analyses that did not finish (finished ones are loaded)';
            row({b, R.restart});
        else
            b.Visible = 'off';
            row({R.restart});
        end
        run_button(false);
    case 'idle'
        offer_off();
        run_button(false);
        R.card.Visible = 'off';
        try, chin_sign(app, 'show'); catch, end
    case 'hide'
        R.card.Visible = 'off';
        stop_hop();
        try, chin_sign(app, 'show'); catch, end
    case 'hop'
        try, hop_step(); catch, end
end
if use_html, try, html_push(state); catch, end, end
% Button presses (Pause / Resume, Stop) run as callbacks at the analysis'
% next refresh point — possibly while a plot is half-built — so they do not
% force a redraw here (same reason as the timer ticks); the run's own next
% refresh shows them.
if ~any(strcmp(state, {'pausing','unpaused','stopping'}))
    try, drawnow('limitrate'); catch, end
end

    % ── helpers (nested: share app / R / fig) ───────────────────────────
    function watchdog()
        % Hang alert (timer tick): no progress for STALL_MIN minutes while a
        % run is going → logged once (Analysis/Logs/APAT_error_log.txt,
        % "STALL") and shown on the card (the page shows it by itself too,
        % so it appears even if MATLAB cannot redraw). Waiting in the ABR
        % peak editor is not a hang.
        if ~(isappdata(fig, 'apat_running') && isequal(getappdata(fig, 'apat_running'), true)), return; end
        if ~isappdata(fig, 'apat_last_prog'), return; end
        if isappdata(fig, 'apat_pause_active') && isequal(getappdata(fig, 'apat_pause_active'), true), return; end
        editing = false;
        try, editing = ~isempty(app.PeakEditPanel) && isvalid(app.PeakEditPanel) && strcmp(app.PeakEditPanel.Visible, 'on'); catch, end
        was = isappdata(fig, 'apat_wait_flag') && isequal(getappdata(fig, 'apat_wait_flag'), true);
        if editing ~= was
            setappdata(fig, 'apat_wait_flag', editing);
            if editing, setappdata(fig, 'apat_last_prog', now); end   %#ok<TNOW1> clock restarts after editing
            if use_html, try, html_push('keep'); catch, end, end
        end
        if editing, return; end
        mins = (now - getappdata(fig, 'apat_last_prog')) * 1440; %#ok<TNOW1>
        if mins < STALL_MIN, return; end
        if isappdata(fig, 'apat_stall_logged') && isequal(getappdata(fig, 'apat_stall_logged'), true), return; end
        setappdata(fig, 'apat_stall_logged', true);
        stepn = '';  try, stepn = char(app.h_progress_label.Text); catch, end
        msg = sprintf(['No progress for %d min (%s · %s) — MATLAB may be stuck. If nothing moves: ' ...
            'press Stop, or quit MATLAB; finished analyses are saved (Resume / Load Saved Results).'], ...
            round(mins), char(R.title.Text), stepn);
        try, apat_run_error('stall', msg); catch, end
        if ~use_html                                  % MATLAB-drawn card
            try, app.h_progress_label.Text = sprintf('No progress for %d min — MATLAB may be stuck (Stop, or quit and Resume)', round(mins)); catch, end
            try, app.h_progress_label.FontColor = RED; catch, end
        end
    end
    function html_push(st)
        % the card's state → icons/run_card.html (texts as set above)
        switch st
            case 'keep'
                hs = 'run';  if isappdata(fig, 'apat_run_hstate'), hs = getappdata(fig, 'apat_run_hstate'); end
            case {'start','phase','progress','pausing','unpaused'}, hs = 'run';
            case 'paused',                     hs = 'paused';
            case {'idle','hide'},              hs = 'hidden';
            case 'offer'
                hs = 'stopped';  if isappdata(fig, 'apat_run_hstate'), hs = getappdata(fig, 'apat_run_hstate'); end
            otherwise,                          hs = st;      % stopping / done / stopped / error
        end
        setappdata(fig, 'apat_run_hstate', hs);
        ttl = char(R.title.Text);  head = ttl;  meas = '';
        k = strfind(ttl, '  ·  ');
        if ~isempty(k), head = ttl(1:k(1)-1);  meas = ttl(k(1)+5:end); end
        pr = [0 0];  if isappdata(fig, 'apat_run_prog'), pr = getappdata(fig, 'apat_run_prog'); end
        t0 = 0;  if isappdata(fig, 'apat_run_t0_ms'), t0 = getappdata(fig, 'apat_run_t0_ms'); end
        fr = 0;
        try, fr = min(1, max(0, R.fill.Position(3) / max(1, R.track.Position(3)))); catch, end
        if strcmp(hs, 'done'), fr = 1; end
        D = struct('state',hs, 't0',t0, 'head',head, 'meas',meas, ...
            'caption',char(R.caption.Text), 'step',char(app.h_progress_label.Text), ...
            'count',char(R.count.Text), 'n',pr(1), 'total',pr(2), 'frac',fr, ...
            'tclr',hex(R.title.FontColor), 'fclr',hex(R.fill.BackgroundColor), ...
            'bg',hex(R.card.BackgroundColor), 'gold',hex(GOLD), 'cream',hex(CREAM), ...
            'capc',hex([0.80 0.76 0.66]), 'track',hex([0.24 0.22 0.18]), ...
            'font',sprintf('%s, Menlo, Consolas, monospace', mono_font()), ...
            'pt',getappdata_or(fig, 'apat_last_prog_ms', 0), 'stall_min',STALL_MIN, ...
            'tp',getappdata_or(fig, 'apat_pause_ms', 0), ...
            'wait',isappdata(fig, 'apat_wait_flag') && isequal(getappdata(fig, 'apat_wait_flag'), true));
        R.html.Data = D;
    end
    function v = getappdata_or(h, k, d)
        v = d;  if isappdata(h, k), v = getappdata(h, k); end
    end
    function s = hex(c)
        c = round(255 * min(1, max(0, double(c(1:3)))));
        s = sprintf('#%02x%02x%02x', c(1), c(2), c(3));
    end
    function offer_off()
        % Resume / Restart gone, the Stop button back in the middle
        setappdata(fig, 'apat_resume_offer', false);
        try
            if isfield(R, 'restart') && isgraphics(R.restart), R.restart.Visible = 'off'; end
            app.StopButton.Tooltip = 'Stop after the current step (work that has finished is saved)';
        catch
        end
    end
    function row(btns)
        % buttons in a row at the right of the card, each as wide as its
        % text, vertically centred; the others of the card hidden by callers
        try
            W = R.card.Position(3);  H = R.card.Position(4);  bh = 30;
            x = W - 12;
            btns = btns(cellfun(@(b) ~isempty(b) && isgraphics(b), btns));
            for i = numel(btns):-1:1
                b = btns{i};
                b.FontSize = 13;
                w = round(24 + 8.2 * numel(char(b.Text)));
                x = x - w;
                p = [x round((H - bh) / 2) w bh];
                b.Position = p;  setappdata(b, 'apat_p0', p);  b.Visible = 'on';
                x = x - 6;
            end
        catch
        end
    end
    function place(h, key)
        % button at its design position KEY (createComponents appdata)
        if ~isappdata(h, key), return; end
        p = getappdata(h, key);  sc = cur_scale();
        h.Position = p .* [sc(1) sc(end) sc(1) sc(end)];
        setappdata(h, 'apat_p0', p);
    end
    function set_bar(frac)
        tp = R.track.Position;
        w  = max(1, round(frac * tp(3)));
        R.fill.Position = [tp(1) tp(2) w tp(4)];
        if isappdata(R.fill, 'apat_p0'), rmappdata(R.fill, 'apat_p0'); end   % re-read at next window resize
    end
    function run_button(busy)
        try
            b = app.RunButton;
            if busy
                b.Text = [char(9679) ' RUNNING…'];
                b.Enable = 'off';
                b.BackgroundColor = app.clr_btn;  b.FontColor = app.clr_black;
                b.Tooltip = 'An analysis is running — progress is shown at the top right (Stop is there too).';
            else
                b.Text = [char(9654) ' RUN ANALYSIS'];
                b.Enable = 'on';
                b.BackgroundColor = app.clr_on;  b.FontColor = [1 1 1];
                b.Tooltip = '';
            end
        catch
        end
        setappdata(fig, 'apat_running', busy);
    end
    function s = elapsed_s()
        % run time without pauses
        s = 0;
        if isappdata(fig, 'apat_run_t0'), s = toc(getappdata(fig, 'apat_run_t0')); end
        s = s - getappdata_or(fig, 'apat_pause_total', 0);
        if isappdata(fig, 'apat_pause_active') && isequal(getappdata(fig, 'apat_pause_active'), true) ...
                && isappdata(fig, 'apat_pause_t')
            s = s - toc(getappdata(fig, 'apat_pause_t'));
        end
        s = max(0, s);
    end
    function s = count_txt()
        % "n of total" (no time-left estimate: only the running timer and
        % the total time at the end are shown)
        s = '';
        pr = [0 0];  if isappdata(fig, 'apat_run_prog'), pr = getappdata(fig, 'apat_run_prog'); end
        if pr(2) <= 0, return; end
        s = sprintf('%d of %d', min(pr(1),pr(2)), pr(2));
    end
    function stop_hide_timer()
        try
            t = timerfind('Name','APAT_runcard');
            if ~isempty(t), stop(t); delete(t); end
        catch
        end
    end
    % ── chinchilla (nested: share app / R / fig) ────────────────────────
    % Smooth motion (Oct 17 2026): positions follow the real elapsed time
    % (px per second, not per tick), so the chinchilla moves at the same
    % speed however often the window is redrawn; the walk frame changes
    % with the distance walked; every behaviour is reached by walking there
    % (no jumps); each sprite is its own preloaded image that is only shown
    % / hidden / moved (no picture re-sent on every step — that flickered).
    function chin_reset(pose)
        if use_html, return; end                     % drawn by icons/run_card.html
        % pose: 'front' | 'happy' — centred, props off, behaviour state reset
        if ~isfield(R, 'chin') || ~isgraphics(R.chin), return; end
        preload();
        st = new_st();  st.x = (lane_w() - 56) / 2;
        setappdata(fig, 'apat_chin_st', st);
        put(R.chin, ['chin_' pose], (lane_w() - 52) / 2, 0);
        prop_off();
    end
    function st = new_st()
        st = struct('mode','pace', 'x',0, 'dir',1, 't',0, 'tl',NaN, 'cool',4, ...
            'medded',false, 'dist',0, 'tx',0, 'next','', 'pj',false);
    end
    function chin_tick(el)
        if use_html, return; end                     % drawn by icons/run_card.html
        if ~isfield(R, 'chin') || ~isgraphics(R.chin), return; end
        st = [];
        if isappdata(fig, 'apat_chin_st'), st = getappdata(fig, 'apat_chin_st'); end
        if ~isstruct(st) || ~isfield(st, 'tl'), st = new_st(); end
        dt = 0.1;  if isfinite(st.tl), dt = min(1, max(0, el - st.tl)); end   % real time since the last step
        st.tl = el;
        W  = lane_w();  WW = 56;                         % walk sprite width (design px)
        v  = 16 + min(32, el / 15) + 12 * (el >= 300);   % px per second, faster with time
        xf = W - 36 - 54;                                % at the fridge (clear of its open door)
        xb = W - 68 - WW + 10;                           % at the bed
        mx = (W - 52) / 2;                               % centre (meditation)
        switch st.mode
            case 'pace'
                step(st.dir * v * dt);
                if st.x >= W - WW, st.x = W - WW; st.dir = -1; end
                if st.x <= 0,      st.x = 0;      st.dir = 1;  end
                put(R.chin, walk_sprite(false), st.x, 0);
                prop_off();
                st.cool = st.cool - dt;
                if st.cool <= 0
                    pd = 0.004;  if st.medded, pd = 0.0015; end
                    if chance(pd)
                        st.mode = 'desp';  st.t = 2;
                    elseif el >= 600 && chance(0.02)
                        go_to(xb, 'sleep', true);
                    elseif el >= 300 && chance(0.008)
                        st.mode = 'phone';  st.t = 5;
                    elseif el >= 180 && chance(0.006)
                        go_to(mx - 2, 'med', false);
                    elseif el >= 60 && chance(0.008)
                        go_to(xf, 'fridge_open', false);
                    end
                end
            case 'walk'                                  % walking to st.tx, then st.next
                if strcmp(st.next, 'fridge_open'), put(R.prop, 'chin_fridge', W - 28, 0);
                elseif strcmp(st.next, 'sleep'),   put(R.prop, 'chin_bed', W - 68, 0);
                else, prop_off();
                end
                d = st.tx - st.x;
                if d ~= 0, st.dir = sign(d); end
                step(sign(d) * min(abs(d), v * dt));
                put(R.chin, walk_sprite(st.pj), st.x, 0);
                if abs(st.tx - st.x) < 0.5
                    st.mode = st.next;
                    switch st.next
                        case 'fridge_open', st.t = 1.5;
                        case 'med',         st.t = 12;
                        case 'sleep',       st.t = 40;
                    end
                end
            case 'fridge_open'                           % fridge open, chinchilla at it
                put(R.prop, 'chin_fridge_open', W - 36, 0);
                put(R.chin, 'chin_front', st.x + 2, 0);
                st.t = st.t - dt;
                if st.t <= 0, st.mode = 'snack'; st.t = 4; end
            case 'snack'                                 % eats by the closed fridge
                put(R.prop, 'chin_fridge', W - 28, 0);
                put(R.chin, sprintf('chin_snack%d', 1 + mod(floor(el / 0.5), 2)), st.x, 0);
                st.t = st.t - dt;
                if st.t <= 0, back_to_pace(10); end
            case 'med'                                   % cushion + incense, centred
                put(R.chin, 'chin_med', mx, 0);
                put(R.prop, ternary_s(mod(floor(el / 0.5), 2) == 0, 'chin_incense', 'chin_incense2'), max(0, mx - 16), 0);
                st.t = st.t - dt;
                if st.t <= 0, st.medded = true; back_to_pace(10); end
            case 'phone'
                st.x = min(st.x, W - 52);
                put(R.chin, 'chin_phone', st.x, 0);  prop_off();
                st.t = st.t - dt;
                if st.t <= 0, back_to_pace(7.5); end
            case 'desp'                                  % short shake
                st.x = min(st.x, W - 52);
                put(R.chin, 'chin_desp', max(0, st.x + 4*mod(floor(el / 0.12), 2) - 2), 0);  prop_off();
                st.t = st.t - dt;
                if st.t <= 0, back_to_pace(7.5); end
            case 'sleep'                                 % nap: the bed sprite holds the chinchilla
                slot_off(R.chin);
                put(R.prop, 'chin_bed_sleep', W - 70, 0);
                if isfield(R, 'zz') && isgraphics(R.zz)
                    R.zz.Text = ternary_s(mod(floor(el / 0.75), 2) == 0, 'z', 'z Z');
                    R.zz.Visible = 'on';
                end
                st.t = st.t - dt;
                if st.t <= 0, st.x = W - 68 - WW;  st.pj = false;  back_to_pace(15); end
            otherwise
                st.mode = 'pace';
        end
        setappdata(fig, 'apat_chin_st', st);
        function step(dx)
            st.x = st.x + dx;  st.dist = st.dist + abs(dx);
        end
        function nm = walk_sprite(pj)
            f = 1 + mod(floor(st.dist / 10), 2);       % a step every 10 px walked
            nm = sprintf('chin_%s%d%s', ternary_s(pj, 'pj', 'walk'), f, ternary_s(st.dir < 0, '_l', ''));
        end
        function go_to(tx, next, pj)
            st.mode = 'walk';  st.tx = max(0, min(W - WW, tx));  st.next = next;  st.pj = pj;
        end
        function tf = chance(p)
            % p = old chance per 0.25 s tick → same rate per second
            tf = rand < 1 - (1 - p)^(dt / 0.25);
        end
        function back_to_pace(cool)
            st.mode = 'pace';  st.x = max(0, min(W - WW, st.x));  st.cool = cool;  st.dir = -1;
            prop_off();
        end
    end
    function prop_off()
        slot_off(R.prop);
        if isfield(R, 'zz') && isgraphics(R.zz), R.zz.Visible = 'off'; end
    end
    function W = lane_w()
        % track width in design pixels (the card may have been rescaled)
        W = 190;
        try
            sc = cur_scale();
            W = R.lane.Position(3) / sc(1);
        catch
        end
    end
    function sc = cur_scale()
        sc = [1 1];
        if isappdata(fig, 'apat_cur_scale'), sc = getappdata(fig, 'apat_cur_scale'); end
    end
    function put(h, name, x, y)
        % show sprite NAME for slot H (R.chin / R.prop) at (x, y) design px
        % above the track's left end: its preloaded image is moved / shown,
        % the slot's previous sprite hidden (no ImageSource change)
        if ~isgraphics(h), return; end
        I = sprites();
        if ~isfield(I, name), return; end
        sp = I.(name);  sc = cur_scale();
        lp = R.lane.Position;
        pos = [lp(1) + x*sc(1), lp(2) + lp(4) + y*sc(2), sp.sz(1)*sc(1), sp.sz(2)*sc(2)];
        q = pool_img(name, h == R.chin);
        if isempty(q), return; end
        if ~isequal(q.Position, pos), q.Position = pos; end
        if isappdata(q, 'apat_p0'), rmappdata(q, 'apat_p0'); end      % moved at runtime
        prev = '';  if ischar(h.UserData), prev = h.UserData; end
        if ~strcmp(q.Visible, 'on'), q.Visible = 'on'; end
        if ~strcmp(prev, name)
            p = pool_img(prev, []);  if ~isempty(p), p.Visible = 'off'; end
            h.UserData = name;
        end
        if strcmp(h.Visible, 'on'), h.Visible = 'off'; end   % the slot itself only keeps the name
    end
    function slot_off(h)
        if ~isgraphics(h), return; end
        if ischar(h.UserData) && ~isempty(h.UserData)
            p = pool_img(h.UserData, []);  if ~isempty(p), p.Visible = 'off'; end
        end
        h.UserData = '';  h.Visible = 'off';
    end
    function q = pool_img(name, is_chin)
        % the uiimage that holds sprite NAME (created once, hidden; is_chin
        % [] = only look it up)
        q = [];
        if isempty(name), return; end
        P = struct();
        if isappdata(fig, 'apat_chin_pool'), P = getappdata(fig, 'apat_chin_pool'); end
        if isfield(P, name) && isgraphics(P.(name)), q = P.(name); return; end
        if isempty(is_chin), return; end
        I = sprites();
        if ~isfield(I, name), return; end
        q = uiimage(R.card, 'ImageSource',I.(name).img, 'Visible','off', 'UserData',name, ...
            'Tag', ternary_s(is_chin, 'apat_chin_c', 'apat_chin_p'), 'Position',[1 1 1 1]);
        P.(name) = q;
        setappdata(fig, 'apat_chin_pool', P);
        layer();
    end
    function preload()
        % every sprite's image made once (first run): no image is created
        % or sent while the chinchilla is moving
        if isappdata(fig, 'apat_chin_pool'), return; end
        props = {'chin_fridge','chin_fridge_open','chin_bed','chin_bed_sleep','chin_incense','chin_incense2'};
        I = sprites();
        for f = fieldnames(I)'
            pool_img(f{1}, ~any(strcmp(props, f{1})));
        end
    end
    function layer()
        % stacking on the card: "z Z" on top, then the chinchilla, then props
        try
            ch = R.card.Children;
            tg = arrayfun(@(c) string(c.Tag), ch);
            isz = false(size(ch));  if isfield(R, 'zz') && isgraphics(R.zz), isz = ch == R.zz; end
            isc = tg == "apat_chin_c";  isp = tg == "apat_chin_p";
            R.card.Children = [ch(isz); ch(isc); ch(isp); ch(~(isz | isc | isp))];
        catch
        end
    end
    function I = sprites()
        % chin_*.png read once, composited on the card colour, 2x pixels
        % (shown at half size: crisp on high-DPI screens)
        if isappdata(fig, 'apat_chin_img'), I = getappdata(fig, 'apat_chin_img'); return; end
        I = struct();
        d = fullfile(fileparts(fileparts(mfilename('fullpath'))), 'icons');
        bg = R.card.BackgroundColor;
        names = {'chin_front','chin_happy','chin_desp','chin_phone','chin_med','chin_snack1','chin_snack2', ...
                 'chin_fridge','chin_fridge_open','chin_bed','chin_bed_sleep','chin_incense','chin_incense2', ...
                 'chin_walk1','chin_walk2','chin_walk1_l','chin_walk2_l','chin_pj1','chin_pj2','chin_pj1_l','chin_pj2_l'};
        for k = 1:numel(names)
            try
                [im, ~, a] = imread(fullfile(d, [names{k} '.png']));
                im = double(im) / 255;
                if isempty(a), a = ones(size(im,1), size(im,2)); else, a = double(a) / 255; end
                for c = 1:3, im(:,:,c) = im(:,:,c) .* a + bg(c) .* (1 - a); end
                I.(names{k}) = struct('img', repelem(uint8(round(255*im)), 2, 2, 1), ...
                    'sz', [size(im,2) size(im,1)]);
            catch
            end
        end
        setappdata(fig, 'apat_chin_img', I);
    end
    function start_hop()
        if use_html, return; end                     % drawn by icons/run_card.html
        stop_hop();
        setappdata(fig, 'apat_chin_hop', 0);
        try
            me = @run_status;                          % handle now (callback runs from outside)
            t = timer('Name','APAT_chinhop', 'Period',0.1, 'ExecutionMode','fixedRate', ...
                'TasksToExecute',24, 'BusyMode','drop', 'TimerFcn',@(~,~) me(app, 'hop'), ...
                'StopFcn',@(tt,~) delete(tt));
            start(t);
        catch
        end
    end
    function stop_hop()
        try
            t = timerfind('Name','APAT_chinhop');
            if ~isempty(t), stop(t); delete(t); end
        catch
        end
    end
    function hop_step()
        if use_html, return; end                     % drawn by icons/run_card.html
        % popcorn hop: y offsets (design px), twice
        k = 0;  if isappdata(fig, 'apat_chin_hop'), k = getappdata(fig, 'apat_chin_hop'); end
        k = k + 1;  setappdata(fig, 'apat_chin_hop', k);
        yy = [0 4 8 10 8 4 0 0 0 3 5 3 0 0 0 0 4 8 10 8 4 0 0 0];
        if ~isfield(R, 'chin') || ~isgraphics(R.chin) || strcmp(R.card.Visible, 'off'), return; end
        put(R.chin, 'chin_happy', (lane_w() - 52) / 2, yy(min(k, numel(yy))));
    end
    function hide_after(sec)
        stop_hide_timer();
        try
            me = @run_status;                          % handle now (callback runs from outside)
            t = timer('Name','APAT_runcard', 'StartDelay',sec, 'ExecutionMode','singleShot', ...
                'TimerFcn',@(~,~) me(app, 'hide'));
            start(t);
        catch
        end
    end
end


function s = mmss(sec)
sec = max(0, round(sec));
if sec >= 3600
    s = sprintf('%d:%02d:%02d', floor(sec/3600), floor(mod(sec,3600)/60), mod(sec,60));
else
    s = sprintf('%02d:%02d', floor(sec/60), mod(sec,60));
end
end


function v = ternary_s(c, a, b)
if c, v = a; else, v = b; end
end
