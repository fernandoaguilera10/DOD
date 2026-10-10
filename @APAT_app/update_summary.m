function update_summary(app)
%UPDATE_SUMMARY  Refresh the Setup tab's live feedback:
%   • Run Summary card  — subject / condition / dataset counts + what will run
%   • Project status    — Data/Analysis folders found, roster contents
%   • ABR toggle chips  — gold when selected, grey when off
%   Called from every Setup control that changes the run configuration.

if isempty(app.h_summary) || ~isstruct(app.h_summary), return; end
S = app.h_summary;

% ── Toggle-chip styling (ABR frequencies / waves) ───────────────────────
chips = [app.h_abr_freq_checks(:); app.h_abr_wave_checks(:)];
for c = chips(:)'
    if ~isgraphics(c) || ~isprop(c,'Value'), continue; end
    if c.Value
        c.BackgroundColor = app.clr_gold;     c.FontColor = app.clr_black;
    else
        c.BackgroundColor = app.clr_btn;      c.FontColor = [0.45 0.45 0.45];
    end
end

% ── Subject / condition chips + option pills ─────────────────────────────
for c = [app.h_subj_checks(:); app.h_cond_checks(:)]'
    if ~isgraphics(c), continue; end
    if c.Value
        c.BackgroundColor = app.clr_gold;     c.FontColor = app.clr_black;
    else
        c.BackgroundColor = [0.98 0.97 0.94]; c.FontColor = [0.55 0.55 0.55];
    end
end
for o = {app.ReanalyzeCheck, app.PlotRelativeCheck, app.BlindCheck}
    b = o{1};
    if isempty(b) || ~isgraphics(b), continue; end
    if b.Value
        b.Text = 'ON';  b.BackgroundColor = [0.30 0.62 0.36]; b.FontColor = [1 1 1];
    else
        b.Text = 'OFF'; b.BackgroundColor = app.clr_btn;      b.FontColor = [0.40 0.40 0.40];
    end
end

% ── Selected subjects / conditions ───────────────────────────────────────
subj_on = false(1, numel(app.h_subj_checks));
for ii = 1:numel(app.h_subj_checks)
    subj_on(ii) = isvalid(app.h_subj_checks(ii)) && app.h_subj_checks(ii).Value;
end
cond_on = false(1, numel(app.h_cond_checks));
for ci = 1:numel(app.h_cond_checks)
    cond_on(ci) = isvalid(app.h_cond_checks(ci)) && app.h_cond_checks(ci).Value;
end
nS = sum(subj_on);  nC = sum(cond_on);
% ABR: every selected frequency is its own dataset (none selected = all run)
nF = 1;
if strcmp(app.MEASURES(app.state.measure_idx).name, 'ABR') && ~isempty(app.h_abr_freq_checks)
    f_on = arrayfun(@(b) isgraphics(b) && b.Value, app.h_abr_freq_checks);
    nF = sum(f_on);
    if nF == 0, nF = numel(app.h_abr_freq_checks); end
end
if numel(app.h_row2_badges) == 2 && all(isgraphics(app.h_row2_badges))
    app.h_row2_badges(1).Text = sprintf('%d of %d selected', nS, numel(subj_on));
    app.h_row2_badges(2).Text = sprintf('%d of %d selected', nC, numel(cond_on));
end
counts = [nS nC nS*nC*nF];
for ti = 1:3
    if isgraphics(S.tiles(ti))
        S.tiles(ti).Text = sprintf('%d', counts(ti));
        if counts(ti) == 0
            S.tiles(ti).FontColor = [0.85 0.40 0.35];   % nothing selected → warn
        else
            S.tiles(ti).FontColor = app.clr_gold;
        end
    end
end

% ── What will run ────────────────────────────────────────────────────────
m = app.state.measure_idx;  k = app.state.subtype_idx;
M = app.MEASURES(m);
what = sprintf('<b>%s</b>', M.name);
if ~isempty(M.subtypes), what = sprintf('%s › <b>%s</b>', what, M.subtypes{k}); end
if strcmp(M.name,'ABR')
    fsel = chip_labels(app.h_abr_freq_checks);
    if isempty(fsel), fsel = 'all frequencies'; end
    what = sprintf('%s  ·  %s', what, fsel);
    if k == 2
        w = chip_labels(app.h_abr_wave_checks);
        w = strrep(w, 'Wave ', '');
        if isempty(w), w = 'I–V'; end
        what = sprintf('%s  ·  Waves %s', what, w);
    end
end
yes = '<font color="#2e7d32">✓</font>';
no  = '<font color="#b0b0b0">✗</font>';
opts = sprintf('Options: Re-analyze %s  |  Relative %s  |  Blind %s', ...
    pick(app.ReanalyzeCheck.Value, yes, no), pick(app.PlotRelativeCheck.Value, yes, no), ...
    pick(app.BlindCheck.Value, yes, no));
if nS == 0
    subj_txt = '<font color="#b5463a">No subjects selected</font>';
else
    ids = app.subj_ids(subj_on);
    if numel(ids) > 10, ids = [ids(1:10); {sprintf('+%d more', numel(ids)-10)}]; end
    subj_txt = ['Subjects: ' strjoin(ids(:)', ', ')];
end
txt = {['Analysis: ' what], opts, subj_txt};
for li = 1:min(3, numel(S.lines))
    if isgraphics(S.lines(li)), S.lines(li).Text = txt{li}; end
end

% ── Project status (right side of Project Settings) ──────────────────────
if isfield(S,'proj') && numel(S.proj) == 3 && all(isgraphics(S.proj))
    root = strtrim(app.RootDirField.Value);
    has_root = ~isempty(root) && exist(root,'dir') == 7;
    has_data = has_root && exist(fullfile(root,'Data'),'dir') == 7;
    has_ana  = has_root && exist(fullfile(root,'Analysis'),'dir') == 7;
    S.proj(1).Text = sprintf('%s Data folder', pick(has_data, yes, no));
    S.proj(2).Text = sprintf('%s Analysis folder', pick(has_ana, yes, no));
    nsub = numel(app.subj_ids);  ncond = numel(app.state.cond_labels);
    if nsub > 0
        S.proj(3).Text = sprintf('%s Roster: <b>%d</b> subjects · <b>%d</b> conditions', yes, nsub, ncond);
    else
        S.proj(3).Text = sprintf('%s Roster not loaded', no);
    end
end
end


function s = chip_labels(btns)
% Comma-separated labels of the selected toggle chips ('' if all or none).
s = '';
if isempty(btns), return; end
ok  = arrayfun(@(b) isgraphics(b) && b.Value, btns);
if all(ok) || ~any(ok), return; end
lbl = arrayfun(@(b) string(b.Text), btns(ok));
s = char(strjoin(lbl, ', '));
end


function out = pick(cond, a, b)
if cond, out = a; else, out = b; end
end
