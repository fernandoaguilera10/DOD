function chin_sign(app, action)
%CHIN_SIGN  Header chinchilla's sign (top right of the header, app.h_sign).
%   chin_sign(app, 'pick')   choose a new message and show it: about half
%                            of the time a greeting with the user's name,
%                            otherwise a time-of-day / day-of-week / lab line
%                            (sometimes greeting + lab line). Never the same
%                            message twice in a row (last one kept in UIFigure
%                            appdata 'apat_sign_last' and getpref('APAT',
%                            'chin_last'), so also across sessions).
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
