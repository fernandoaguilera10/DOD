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
%                                             (APAT_spinner timer, 0.25 s)
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
%   'apat_chin_img'; each tick only swaps ImageSource / Position of those two.
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
            app.StopButton.Text = [char(9632) '  Stop'];  app.StopButton.Enable = 'on';  app.StopButton.Visible = 'on';
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
        try, chin_tick(elapsed_s()); catch, end
        R.elapsed.Text = mmss(elapsed_s());
        R.count.Text = count_txt();
    case 'stopping'
        R.title.Text = 'Stopping…';
        R.caption.Text = 'STOPPING';
        app.h_progress_label.Text = 'Finishing the current step — work that has finished is saved';
        app.StopButton.Text = 'Stopping…';  app.StopButton.Enable = 'off';
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
            det = sprintf('Done · %d error%s — see APAT_error_log.txt', ne, ternary_s(ne == 1, '', 's'));
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
        run_button(false);
        if ne > 0 && ~strcmp(state, 'stopped')
            stop_hide_timer();                         % stays until the next run (user may be away)
        else
            hide_after(ternary_s(strcmp(state,'done'), 6, 12));
        end
    case 'idle'
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
try, drawnow('limitrate'); catch, end

    % ── helpers (nested: share app / R / fig) ───────────────────────────
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
        s = 0;
        if isappdata(fig, 'apat_run_t0'), s = toc(getappdata(fig, 'apat_run_t0')); end
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
    function chin_reset(pose)
        % pose: 'front' | 'happy' — centred, props off, behaviour state reset
        if ~isfield(R, 'chin') || ~isgraphics(R.chin), return; end
        setappdata(fig, 'apat_chin_st', struct('mode','pace', 'x',0, 'dir',1, 't',0, ...
            'fr',0, 'cool',16, 'medded',false, 'y',0));
        W = lane_w();
        put(R.chin, ['chin_' pose], (W - 52) / 2, 0);
        prop_off();
    end
    function chin_tick(el)
        if ~isfield(R, 'chin') || ~isgraphics(R.chin), return; end
        st = [];
        if isappdata(fig, 'apat_chin_st'), st = getappdata(fig, 'apat_chin_st'); end
        if ~isstruct(st) || ~isfield(st, 'mode')
            st = struct('mode','pace', 'x',0, 'dir',1, 't',0, 'fr',0, 'cool',16, 'medded',false, 'y',0);
        end
        W  = lane_w();  WW = 56;                         % walk sprite width (design px)
        st.fr = st.fr + 1;
        spd = 4 + min(8, el / 60) + 3 * (el >= 300);     % px per tick, faster with time
        wf = sprintf('%d', 1 + mod(st.fr, 2));           % walk frame 1 / 2
        switch st.mode
            case 'pace'
                st.x = st.x + st.dir * spd;
                if st.x >= W - WW, st.x = W - WW; st.dir = -1; end
                if st.x <= 0,      st.x = 0;      st.dir = 1;  end
                put(R.chin, ['chin_walk' wf ternary_s(st.dir < 0, '_l', '')], st.x, 0);
                prop_off();
                st.cool = st.cool - 1;
                if st.cool <= 0
                    pd = 0.004;  if st.medded, pd = 0.0015; end
                    if rand < pd
                        st.mode = 'desp';  st.t = 8;
                    elseif el >= 600 && rand < 0.02
                        st.mode = 'to_bed';  st.dir = 1;
                    elseif el >= 300 && rand < 0.008
                        st.mode = 'phone';  st.t = 20;
                    elseif el >= 180 && rand < 0.006
                        st.mode = 'med';  st.t = 48;
                    elseif el >= 60 && rand < 0.008
                        st.mode = 'to_fridge';  st.dir = 1;
                    end
                end
            case 'to_fridge'                             % walk right to the fridge
                put(R.prop, 'chin_fridge', W - 28, 0);
                tx = W - 28 - WW + 4;
                st.x = min(tx, st.x + spd);  st.dir = 1;
                put(R.chin, ['chin_walk' wf], st.x, 0);
                if st.x >= tx, st.mode = 'fridge_open'; st.t = 6; end
            case 'fridge_open'                           % fridge open, chinchilla at it
                put(R.prop, 'chin_fridge_open', W - 36, 0);
                put(R.chin, 'chin_front', W - 36 - 50, 0);
                st.t = st.t - 1;
                if st.t <= 0, st.mode = 'snack'; st.t = 16; end
            case 'snack'                                 % eats by the closed fridge
                put(R.prop, 'chin_fridge', W - 28, 0);
                put(R.chin, sprintf('chin_snack%d', 1 + mod(floor(st.fr/2), 2)), W - 28 - WW, 0);
                st.t = st.t - 1;
                if st.t <= 0, back_to_pace(W - 28 - WW, 40); end
            case 'med'                                   % cushion + incense, centred
                mx = (W - 52) / 2;
                put(R.chin, 'chin_med', mx, 0);
                put(R.prop, ternary_s(mod(floor(st.fr/2), 2) == 0, 'chin_incense', 'chin_incense2'), max(0, mx - 16), 0);
                st.t = st.t - 1;
                if st.t <= 0, st.medded = true; back_to_pace(mx, 40); end
            case 'phone'
                px = min(st.x, W - 52);
                put(R.chin, 'chin_phone', px, 0);  prop_off();
                st.t = st.t - 1;
                if st.t <= 0, back_to_pace(px, 30); end
            case 'desp'                                  % short shake
                px = min(st.x, W - 52);
                put(R.chin, 'chin_desp', max(0, px + 4*mod(st.fr, 2) - 2), 0);  prop_off();
                st.t = st.t - 1;
                if st.t <= 0, back_to_pace(px, 30); end
            case 'to_bed'                                % pajamas, walk to the bed
                put(R.prop, 'chin_bed', W - 68, 0);
                tx = W - 68 - WW + 10;
                st.x = min(tx, st.x + spd);  st.dir = 1;
                put(R.chin, ['chin_pj' wf], st.x, 0);
                if st.x >= tx, st.mode = 'sleep'; st.t = 160; end
            case 'sleep'                                 % nap: the bed sprite holds the chinchilla
                R.chin.Visible = 'off';
                put(R.prop, 'chin_bed_sleep', W - 70, 0);
                if isfield(R, 'zz') && isgraphics(R.zz)
                    R.zz.Text = ternary_s(mod(floor(st.fr/3), 2) == 0, 'z', 'z Z');
                    R.zz.Visible = 'on';
                end
                st.t = st.t - 1;
                if st.t <= 0, back_to_pace(W - 68 - WW, 60); st.dir = -1; end
            otherwise
                st.mode = 'pace';
        end
        setappdata(fig, 'apat_chin_st', st);
        function back_to_pace(x, cool)
            st.mode = 'pace';  st.x = max(0, min(W - WW, x));  st.cool = cool;  st.dir = -1;
            prop_off();
        end
    end
    function prop_off()
        if isfield(R, 'prop') && isgraphics(R.prop), R.prop.Visible = 'off';  R.prop.UserData = ''; end
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
        % show sprite NAME at (x, y) design px above the track's left end;
        % ImageSource is only replaced when the sprite changes
        if ~isgraphics(h), return; end
        I = sprites();
        if ~isfield(I, name), return; end
        sp = I.(name);  sc = cur_scale();
        lp = R.lane.Position;
        pos = [lp(1) + x*sc(1), lp(2) + lp(4) + y*sc(2), sp.sz(1)*sc(1), sp.sz(2)*sc(2)];
        if ~isequal(h.UserData, name), h.ImageSource = sp.img;  h.UserData = name; end
        h.Position = pos;
        if isappdata(h, 'apat_p0'), rmappdata(h, 'apat_p0'); end      % moved at runtime
        h.Visible = 'on';
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
