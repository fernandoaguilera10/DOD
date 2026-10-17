function chin_sign(app, action)
%CHIN_SIGN  Header chinchilla's sign (top right of the header, app.h_sign).
%   chin_sign(app, 'pick')   choose a new message and show it: about half
%                            of the time a greeting with the user's name,
%                            otherwise a time-of-day / day-of-week / lab line
%                            (sometimes greeting + lab line). Never the same
%                            message twice in a row (last one kept in UIFigure
%                            appdata 'apat_sign_last' and getpref('APAT',
%                            'chin_last'), so also across sessions).
%   chin_sign(app, 'fit')    size the sign to its text (wider first, then a
%                            smaller font, width ≤ 380 px) inside the
%                            header's right block, left of the chinchilla
%   chin_sign(app, 'show' | 'hide')   sign + chinchilla visible / hidden
%                            (hidden while the run status card is shown)
%   Messages: @APAT_app/chin_messages.txt ("section: text", {name} = profile
%   name). Called when the Setup tab is built / shown and when a user profile
%   is loaded. Never throws.
try
    if ~isvalid(app) || ~isstruct(app.h_sign) || ~isfield(app.h_sign, 'label'), return; end
    S = app.h_sign;
    switch action
        case 'pick'
            S.label.Text = pick_message(app);
            fit_sign(app);
        case 'fit'
            fit_sign(app);
        case {'show','hide'}
            v = 'off';  if strcmp(action, 'show'), v = 'on'; end
            for f = {'chin','shadow','panel','post'}
                if isfield(S, f{1}) && isgraphics(S.(f{1})), S.(f{1}).Visible = v; end
            end
    end
catch
end
end


function msg = pick_message(app)
M = read_messages();
name = user_name(app);
nowv = datetime('now');
hr = hour(nowv);  wd = weekday(nowv);               % 1 = Sunday
if hr >= 5 && hr < 12,      tsec = 'morning';
elseif hr >= 12 && hr < 17, tsec = 'afternoon';
elseif hr >= 17 && hr < 22, tsec = 'evening';
else,                       tsec = 'late';
end
dsec = '';
if wd == 2, dsec = 'monday'; elseif wd == 6, dsec = 'friday'; elseif wd == 1 || wd == 7, dsec = 'weekend'; end
greet = get_sec(M, 'greet');  lab = get_sec(M, 'lab');
other = [get_sec(M, tsec), get_sec(M, dsec), lab];
if isempty(greet), greet = {'Hello, {name}!'}; end
if isempty(other), other = greet; end
last = '';
try
    fig = app.UIFigure;
    if isappdata(fig, 'apat_sign_last'), last = getappdata(fig, 'apat_sign_last');
    elseif ispref('APAT', 'chin_last'), last = getpref('APAT', 'chin_last'); end
catch
end
msg = last;
for tries = 1:12
    if rand < 0.5
        msg = greet{randi(numel(greet))};
        if ~isempty(lab) && rand < 0.4                 % "Hello, Fernando! Wave I says hi."
            l2 = lab{randi(numel(lab))};
            if numel(msg) + numel(l2) < 64 && any(msg(end) == '!.'), msg = [msg ' ' l2]; end
        end
    else
        msg = other{randi(numel(other))};
    end
    msg = strrep(msg, '{name}', name);
    if ~strcmp(msg, last), break; end
end
try
    setappdata(app.UIFigure, 'apat_sign_last', msg);
    setpref('APAT', 'chin_last', msg);
catch
end
end


function M = read_messages()
% struct of cellstr per section (file read each time: it is tiny)
M = struct();
f = fullfile(fileparts(fileparts(mfilename('fullpath'))), 'chin_messages.txt');
try
    L = readlines(f, 'EmptyLineRule','skip');
catch
    try, L = string(splitlines(fileread(f))); catch, L = strings(0,1); end
end
for k = 1:numel(L)
    s = strtrim(char(L(k)));
    if isempty(s) || s(1) == '#', continue; end
    tok = regexp(s, '^([A-Za-z]+)\s*:\s*(.+)$', 'tokens', 'once');
    if isempty(tok), continue; end
    sec = lower(tok{1});
    if ~isfield(M, sec), M.(sec) = {}; end
    M.(sec){end+1} = strtrim(tok{2});
end
end


function c = get_sec(M, sec)
c = {};
if ~isempty(sec) && isfield(M, sec), c = M.(sec); end
end


function n = user_name(app)
% profile full name (first word), else the initials, else 'Friend'
n = 'Friend';
try
    items = app.ProfileDropdown.Items;  p = app.ProfileDropdown.Value;
    if isempty(items) || strcmp(items{1}, '(no profiles)') || isempty(p), return; end
    n = p;
    if isfield(app.profiles, p) && isfield(app.profiles.(p), 'name')
        full = strtrim(char(app.profiles.(p).name));
        if ~isempty(full), w = strsplit(full); n = w{1}; end
    end
catch
end
end


function fit_sign(app)
% Sign box sized to the message: widths 250…380 px (never into the title),
% mono font 12 → 9 pt (× the window font factor), first combination whose
% wrapped text fits under the header's top edge.
try
    G = app.h_sign;
    hh = 110;
    try, hp = G.chin.Parent.Position;  hh = hp(4); catch, end   % header right block
    cp = G.chin.Position;
    fp = app.UIFigure.Position;
    f  = max(0.85, min(1, min(fp(3)/1500, fp(4)/860)));
    msg = strtrim(char(G.label.Text));
    sg_y = round(cp(2) + 22);
    Hmax = max(30, hh - sg_y - 6);
    % the sign stays inside the header's right block (fixed width, right of
    % the title column; createComponents>fig_layout keeps it at the edge)
    Wmax = max(200, cp(1) + 6 - 8);
    Ws  = [250 290 330 380];  Ws = Ws(Ws <= Wmax);
    if isempty(Ws), Ws = Wmax; end
    fss = [12 11 10 9];  fss = fss(fss <= max(9, round(12*f)));
    pick = [];
    for fs = fss
        for W = Ws
            cpl = max(8, floor((W - 26) / (fs * 0.62)));
            H = max(40, wrap_lines(msg, cpl) * ceil(fs * 1.3) + 12);
            if H <= Hmax, pick = [W fs H]; break; end
        end
        if ~isempty(pick), break; end
    end
    if isempty(pick), pick = [Ws(end) fss(end) Hmax]; end
    W = pick(1);  fs = pick(2);  H = pick(3);
    sg_x = cp(1) + 6 - W;
    G.panel.Position  = [sg_x sg_y W H];
    G.shadow.Position = [sg_x+3 sg_y-3 W H];
    G.post.Position   = [sg_x+W-22 sg_y-14 4 14];
    G.label.Position  = [8 2 W-22 H-10];
    G.label.FontSize  = fs;
catch
end
end


function n = wrap_lines(msg, cpl)
% lines of msg word-wrapped at cpl characters
w = strsplit(msg);  n = 1;  L = 0;
for k = 1:numel(w)
    lw = numel(w{k});
    if lw == 0, continue; end
    if L == 0, L = lw;
    elseif L + 1 + lw <= cpl, L = L + 1 + lw;
    else, n = n + 1;  L = lw;
    end
    while L > cpl, n = n + 1;  L = L - cpl; end
end
end
