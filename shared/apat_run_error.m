function out = apat_run_error(action, varargin)
%APAT_RUN_ERROR  Run-time errors that must not stop an unattended run.
%   Errors during a run are written to Analysis/Logs/APAT_error_log.txt and shown
%   in a small notice over the APAT window that closes itself after 15 s
%   (no modal dialog); the run goes on with the next item.
%
%   apat_run_error('start', analysis_dir, fig)  new run: count = 0, log in
%                              <analysis_dir>/Logs/APAT_error_log.txt, notices on
%                              FIG (the APAT UIFigure; [] = Command Window)
%   tf = apat_run_error('ensure', analysis_dir) start only if no run state
%                              exists (headless analysis_run); true if started
%   apat_run_error('end')      forget the run state
%   apat_run_error('context', 'analysis',lbl, 'subject',s, 'condition',c, 'blind',tf)
%                              what is being processed (used by 'error')
%   apat_run_error('error', ME_or_msg [, stage])  log one error (+1), notice
%   apat_run_error('auto', msg) log an automatic choice taken because a
%                              prompt got no answer (not counted), notice
%   apat_run_error('stall', msg) log "no progress" (hang alert, run_status):
%                              not counted as an error, no notice (the run
%                              card shows it)
%   n = apat_run_error('count')  errors logged since 'start'
%   f = apat_run_error('file')   the log file
%   Never throws.
out = [];
try
    switch action
        case 'start'
            d = '';  fig = [];
            if numel(varargin) >= 1, d = char(varargin{1}); end
            if numel(varargin) >= 2, fig = varargin{2}; end
            S = new_state(d, fig);
            setappdata(0, 'APAT_err', S);
            out = true;
        case 'ensure'
            out = false;
            if ~isappdata(0, 'APAT_err') || isempty(getappdata(0, 'APAT_err'))
                d = '';  if numel(varargin) >= 1, d = char(varargin{1}); end
                setappdata(0, 'APAT_err', new_state(d, []));
                out = true;
            end
        case 'end'
            if isappdata(0, 'APAT_err'), rmappdata(0, 'APAT_err'); end
        case 'context'
            S = state();
            for k = 1:2:numel(varargin) - 1
                S.ctx.(varargin{k}) = varargin{k+1};
            end
            setappdata(0, 'APAT_err', S);
        case 'count'
            S = state();  out = S.n;
        case 'file'
            S = state();  out = S.file;
        case 'stall'
            S = state();
            write_log(S, 'STALL', 'no progress', char(varargin{1}), '');
            fprintf(2, 'APAT: %s\n', char(varargin{1}));
        case 'error'
            ME = varargin{1};
            stage = '';  if numel(varargin) >= 2, stage = char(varargin{2}); end
            S = state();
            S.n = S.n + 1;
            setappdata(0, 'APAT_err', S);
            [msg, frame] = describe(ME);
            write_log(S, 'ERROR', stage, msg, frame);
            ttl = 'Analysis Error';
            if ~isempty(S.ctx.analysis), ttl = [ttl '  ·  ' S.ctx.analysis]; end
            show_notice(S, ttl, msg, true);
            fprintf(2, 'APAT error (%s): %s\n', ternary(isempty(stage), 'run', stage), shown(S, msg));
        case 'auto'
            msg = char(varargin{1});
            S = state();
            write_log(S, 'AUTO', 'no answer', msg, '');
            show_notice(S, 'No Answer — Automatic Choice', msg, false);
            fprintf('APAT: %s\n', shown(S, msg));
    end
catch
end
end


% ── state ───────────────────────────────────────────────────────────────

function S = new_state(d, fig)
f = '';
if ~isempty(d), f = apat_paths(d, 'logs', 'APAT_error_log.txt'); end   % Analysis/Logs (apat_timing writes next to it)
S = struct('file', f, 'fig', fig, 'n', 0, 'header', false, 't0', now, ... %#ok<TNOW1>
    'ctx', struct('analysis','', 'subject','', 'condition','', 'blind',false));
end

function S = state()
S = [];
if isappdata(0, 'APAT_err'), S = getappdata(0, 'APAT_err'); end
if isempty(S)                                     % called outside a run
    S = new_state('', []);
    setappdata(0, 'APAT_err', S);
end
end


% ── log file ────────────────────────────────────────────────────────────

function [msg, frame] = describe(ME)
frame = '';
if isa(ME, 'MException')
    msg = ME.message;
    if ~isempty(ME.identifier), msg = sprintf('%s  [%s]', msg, ME.identifier); end
    if ~isempty(ME.stack)
        s = ME.stack(1);
        [~, fn] = fileparts(s.file);
        if isempty(fn), fn = s.name; end
        frame = sprintf('%s > %s (line %d)', fn, s.name, s.line);
    end
else
    msg = char(ME);
end
end

function write_log(S, kind, stage, msg, frame)
if isempty(S.file), return; end
try
    d = fileparts(S.file);
    if ~isempty(d) && ~exist(d, 'dir'), mkdir(d); end
    fid = fopen(S.file, 'a');
    if fid < 0, return; end
    c = onCleanup(@() fclose(fid));
    if ~S.header                                  % one header per run, only when needed
        fprintf(fid, '\n==== APAT run started %s ====\n', datestr(S.t0, 'yyyy-mm-dd HH:MM:SS')); %#ok<DATST>
        S.header = true;  setappdata(0, 'APAT_err', S);
    end
    subj = S.ctx.subject;  cond = S.ctx.condition;
    if S.ctx.blind
        msg = redact(S, msg);  frame = redact(S, frame);
        if ~isempty(subj), subj = '(hidden)'; end
        if ~isempty(cond), cond = '(hidden)'; end
    end
    fprintf(fid, '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n', datestr(now, 'yyyy-mm-dd HH:MM:SS'), kind, ... %#ok<TNOW1,DATST>
        dash(S.ctx.analysis), dash(subj), dash(cond), dash(stage), oneline(msg), dash(frame));
catch
end
end

function s = dash(s)
s = oneline(s);
if isempty(s), s = '-'; end
end

function s = oneline(s)
s = regexprep(char(s), '[\r\n\t]+', ' ');
end

function s = redact(S, s)
s = char(s);
for v = {S.ctx.subject, S.ctx.condition}
    if ~isempty(v{1}), s = strrep(s, char(v{1}), '***'); end
end
end

function s = shown(S, msg)
s = msg;
if S.ctx.blind, s = redact(S, msg); end
end


% ── notice (non-blocking, closes itself) ────────────────────────────────

function show_notice(S, ttl, msg, is_err)
fig = S.fig;
if isempty(fig) || ~isgraphics(fig), return; end
SEC = 15;
try
    old = timerfind('Name', 'APAT_notice');
    if ~isempty(old), stop(old); delete(old); end
catch
end
try
    P = getappdata(fig, 'apat_notice');
    if ~isempty(P) && isgraphics(P), delete(P); end
catch
end
if S.ctx.blind
    msg = 'Details are hidden in blind mode.';
end
GOLD = [218 170 0]/255;  CREAM = [0.88 0.84 0.74];  RED = [0.86 0.47 0.42];
try
    fp = fig.Position;
    W = min(480, max(300, fp(3) - 40));  H = 132;
    P = uipanel(fig, 'Units','pixels', 'Position',[fp(3) - W - 16, 46, W, H], ...
        'BackgroundColor',[0.10 0.10 0.10], 'BorderType','line', 'Tag','apat_notice');
    try, P.HighlightColor = GOLD; catch, end
    try, P.BorderColor = GOLD;  P.BorderWidth = 2; catch, end
    uilabel(P, 'Text',ttl, 'FontWeight','bold', 'FontSize',13, 'Interpreter','none', ...
        'FontColor',ternary(is_err, RED, GOLD), 'Position',[12 H-32 W-24 22]);
    uilabel(P, 'Text',msg, 'FontSize',12, 'FontColor',CREAM, 'WordWrap','on', ...
        'Interpreter','none', 'VerticalAlignment','top', 'Position',[12 40 W-24 H-76]);
    foot = uilabel(P, 'Text','', 'FontSize',11, 'FontColor',[0.70 0.67 0.60], ...
        'Interpreter','none', 'Position',[12 10 W-112 22]);
    uibutton(P, 'Text','Close', 'FontSize',12, 'FontWeight','bold', ...
        'BackgroundColor',[0.93 0.90 0.84], 'FontColor',[0 0 0], ...
        'Position',[W-92 9 80 26], 'ButtonPushedFcn',@(~,~) close_notice(P));
    setappdata(fig, 'apat_notice', P);
    who = {};
    if ~S.ctx.blind
        if ~isempty(S.ctx.subject), who{end+1} = char(S.ctx.subject); end
        if ~isempty(S.ctx.condition), who{end+1} = char(S.ctx.condition); end
    end
    tail = '';
    if S.n > 0
        [~, fn, fe] = fileparts(S.file);
        tail = sprintf('  ·  %d error%s — see %s%s', S.n, ternary(S.n == 1, '', 's'), fn, fe);
    end
    pre = '';  if ~isempty(who), pre = [strjoin(who, ' · ') '  ·  ']; end
    set_foot(foot, pre, SEC, tail);
    t = timer('Name','APAT_notice', 'Period',1, 'ExecutionMode','fixedSpacing', ...
        'TasksToExecute',SEC, 'BusyMode','drop', ...
        'TimerFcn',@(tm,~) tick(tm, foot, pre, SEC, tail), ...
        'StopFcn',@(tm,~) finish(tm, P));
    start(t);
    drawnow limitrate
catch
end
end

function set_foot(foot, pre, left, tail)
try
    if isgraphics(foot)
        foot.Text = sprintf('%sContinuing in %d s%s', pre, max(0, left), tail);
    end
catch
end
end

function tick(tm, foot, pre, SEC, tail)
try, set_foot(foot, pre, SEC - tm.TasksExecuted, tail); catch, end
end

function finish(tm, P)
try, if isgraphics(P), delete(P); end, catch, end
try, delete(tm); catch, end
end

function close_notice(P)
try
    t = timerfind('Name','APAT_notice');
    if ~isempty(t), stop(t); delete(t); end
catch
end
try, if isgraphics(P), delete(P); end, catch, end
end

function v = ternary(c, a, b)
if c, v = a; else, v = b; end
end
