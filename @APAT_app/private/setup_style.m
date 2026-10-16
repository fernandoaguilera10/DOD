function setup_style(app, what, varargin)
%SETUP_STYLE  Setup-tab look of selectable controls (Oct 16 2026 redesign).
%   Selected = subtle yellow (app.clr_sel: gold [218 170 0]/255 at 24 % over
%   the panel colour, precomputed — buttons have no alpha), dark bold text;
%   the measure on screen = stronger yellow (app.clr_sel2, 40 %); not
%   selected = beige app.clr_btn with brown-grey text (app.clr_txt2).
%   ON/OFF pills: ON green app.clr_on, OFF red app.clr_off, white text.
%
%   setup_style(app, 'chip', b [, on])    toggle chip (subject, condition,
%                                         ABR frequency / wave, .mat / .csv,
%                                         dpi segment); on = b.Value by default
%   setup_style(app, 'onoff', b)          ON/OFF pill from b.Value (sets Text)
%   setup_style(app, 'pdef', b)           plot-default toggle: '■ Name' on /
%                                         '□ Name' off (b.UserData = name)
%   setup_style(app, 'measures')          measure + type buttons (called by
%                                         update_summary, i.e. after every
%                                         navigate_results>do_measures)
%   Never throws.
try
    switch what
        case 'chip'
            b = varargin{1};
            if ~isgraphics(b), return; end
            on = logical(b.Value);  if numel(varargin) > 1, on = logical(varargin{2}); end
            chip(app, b, on);
        case 'onoff'
            b = varargin{1};
            if ~isgraphics(b), return; end
            onoff(app, b);
        case 'pdef'
            b = varargin{1};
            if ~isgraphics(b), return; end
            nm = b.UserData;  if ~ischar(nm) && ~isstring(nm), nm = strtrim(regexprep(b.Text, '^\S\s*', '')); end
            if b.Value
                b.Text = [char(9632) '  ' char(nm)];  b.FontColor = app.clr_black;
                b.BackgroundColor = [1 1 1];         b.FontWeight = 'bold';
            else
                b.Text = [char(9633) '  ' char(nm)];  b.FontColor = app.clr_txt2;
                b.BackgroundColor = [1 1 1];         b.FontWeight = 'normal';
            end
        case 'measures'
            measures(app);
    end
catch
end
end


function chip(app, b, on)
if on
    b.BackgroundColor = app.clr_sel;  b.FontColor = app.clr_black;  b.FontWeight = 'bold';
else
    b.BackgroundColor = app.clr_btn;  b.FontColor = app.clr_txt2;   b.FontWeight = 'normal';
end
end


function onoff(app, b)
b.FontColor = [1 1 1];  b.FontWeight = 'bold';
try, b.FontName = mono_font(); catch, end
if b.Value
    b.Text = 'ON';   b.BackgroundColor = app.clr_on;
else
    b.Text = 'OFF';  b.BackgroundColor = app.clr_off;
end
end


function measures(app)
if isempty(app.h_meas_btns) || ~any(isgraphics(app.h_meas_btns)), return; end
m = app.state.measure_idx;
for mi = 1:numel(app.h_meas_btns)
    b = app.h_meas_btns(mi);
    if ~isgraphics(b), continue; end
    sel = false;
    try, sel = any(app.state.run_sel{mi}); catch, end
    if mi == m
        b.BackgroundColor = app.clr_sel2;  b.FontColor = app.clr_black;     % on screen
    elseif sel
        b.BackgroundColor = app.clr_sel;   b.FontColor = app.clr_black;     % holds selections
    else
        b.BackgroundColor = app.clr_btn;   b.FontColor = app.clr_txt2;
    end
    b.FontWeight = 'bold';
    if mi > numel(app.h_sub_btns), continue; end
    subs = app.MEASURES(mi).subtypes;  if isempty(subs), subs = {app.MEASURES(mi).name}; end
    for ki = 1:numel(app.h_sub_btns{mi})
        h = app.h_sub_btns{mi}(ki);
        if ~isgraphics(h) || mi ~= m, continue; end
        on = false;
        try, on = numel(app.state.run_sel{mi}) >= ki && app.state.run_sel{mi}(ki); catch, end
        chip(app, h, on);
        if ki <= numel(subs) && numel(subs) <= 5          % (MEMR: 8 narrow buttons, no tick)
            if on, h.Text = [char(10003) ' ' subs{ki}]; else, h.Text = subs{ki}; end
        end
    end
end
try                                                        % on-screen measure = strong yellow (no bar)
    if isgraphics(app.h_meas_marker), app.h_meas_marker.Visible = 'off'; end
catch
end
end
