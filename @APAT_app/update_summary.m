function update_summary(app)
%UPDATE_SUMMARY  Refresh the Setup tab's live feedback:
%   • Run Summary card  — subject / condition / dataset counts + what will run
%   • Project status    — Data/Analysis folders found, roster contents
%   • Toggle chips      — subtle yellow when selected, beige when off; ON/OFF
%                         pills green / red; measure + type buttons
%                         (private/setup_style.m — also restyles after
%                         navigate_results>do_measures, which calls this)
%   Called from every Setup control that changes the run configuration.

if isempty(app.h_summary) || ~isstruct(app.h_summary), return; end
S = app.h_summary;

% ── Toggle-chip styling (ABR frequencies / waves) ───────────────────────
chips = [app.h_abr_freq_checks(:); app.h_abr_wave_checks(:)];
for c = chips(:)'
    if ~isgraphics(c) || ~isprop(c,'Value'), continue; end
    setup_style(app, 'chip', c);
end

% ── Subject / condition chips + option pills + measure / type buttons ────
for c = [app.h_subj_checks(:); app.h_cond_checks(:)]'
    if ~isgraphics(c), continue; end
    setup_style(app, 'chip', c);
end
% selected subjects / conditions: green = analysed, orange = partly, red =
% not yet (for the selected analyses; private/analysis_status.m)
analysis_status(app, 'paint');
% condition swatch / marker of an excluded condition: faded (as the design)
try
    for ci = 1:numel(app.h_cond_checks)
        on = isgraphics(app.h_cond_checks(ci)) && app.h_cond_checks(ci).Value;
        if ci <= numel(app.h_cond_markers) && isgraphics(app.h_cond_markers(ci)) && ci <= size(app.state.cond_colors,1)
            rgb = app.state.cond_colors(ci,:);
            if ~on, rgb = 0.45*rgb + 0.55*[1 1 1]; end
            app.h_cond_markers(ci).FontColor = rgb;
        end
        if ci <= numel(app.h_cond_swatches) && isgraphics(app.h_cond_swatches(ci)) && ci <= size(app.state.cond_colors,1)
            rgb = app.state.cond_colors(ci,:);
            if ~on, rgb = 0.45*rgb + 0.55*app.clr_panel; end
            app.h_cond_swatches(ci).BackgroundColor = rgb;
        end
    end
catch
end
for o = {app.ReanalyzeCheck, app.PlotRelativeCheck, app.BlindCheck}
    b = o{1};
    if isempty(b) || ~isgraphics(b), continue; end
    setup_style(app, 'onoff', b);
end
setup_style(app, 'measures');

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
% analyses selected for the run (several possible): [measure type] rows
runs = zeros(0,2);
if isfield(app.state,'run_sel')
    for mm = 1:numel(app.MEASURES)
        for kk = find(app.state.run_sel{mm}), runs(end+1,:) = [mm kk]; end %#ok<AGROW>
    end
end
% datasets per analysis: ABR = one per selected frequency of THAT type
% (Thresholds and Peaks have their own frequency selection)
fl = arrayfun(@(b) string(b.Text), app.h_abr_freq_checks);
n_per = 0;
for ri = 1:size(runs,1)
    if strcmp(app.MEASURES(runs(ri,1)).name, 'ABR'), n_per = n_per + nnz(abr_sel_of(app, runs(ri,2)));
    else, n_per = n_per + 1; end
end
if numel(app.h_row2_badges) == 2 && all(isgraphics(app.h_row2_badges))
    app.h_row2_badges(1).Text = sprintf('%d of %d', nS, numel(subj_on));
    app.h_row2_badges(2).Text = sprintf('%d of %d', nC, numel(cond_on));
end
% Totals over every selected Experiment (each with its own subjects /
% conditions, sheet_sel 'counts'; the sheet on screen = its chips):
% Subjects = Σ subjects, Conditions = Σ conditions, Datasets = Σ subjects ×
% conditions × the per-analysis factor. Breakdown row "NOISE 1 × 2 · BLAST 2 × 3".
exps = {};  per = zeros(0, 2);
try
    exps = sheet_sel(app, 'selected');
    scr  = sheet_sel(app, 'on_screen');
    per  = zeros(numel(exps), 2);
    for ei = 1:numel(exps)
        if strcmp(exps{ei}, scr), per(ei,:) = [nS nC];
        else, per(ei,:) = sheet_sel(app, 'counts', exps{ei}); end
    end
catch
    exps = {};  per = zeros(0, 2);
end
if isempty(per), per = [nS nC]; end
counts = [sum(per(:,1)) sum(per(:,2)) sum(per(:,1).*per(:,2))*n_per];
for ti = 1:3
    if isgraphics(S.tiles(ti))
        S.tiles(ti).Text = sprintf('%d', counts(ti));
        if counts(ti) == 0
            S.tiles(ti).FontColor = [0.85 0.40 0.35];   % nothing selected → warn
        else
            S.tiles(ti).FontColor = app.clr_black;
        end
    end
end

if isfield(S, 'head_n') && isgraphics(S.head_n)                % "n ANALYSES" (Run Summary header)
    nA = size(runs,1);
    if nA == 0, S.head_n.Text = ''; elseif nA == 1, S.head_n.Text = '1 ANALYSIS';
    else, S.head_n.Text = sprintf('%d ANALYSES', nA); end
end

% ── What will run: one row per selected analysis, in run order ────────────
parts = {};
for ri = 1:size(runs,1)
    M = app.MEASURES(runs(ri,1));  k = runs(ri,2);
    if isempty(M.subtypes), t = sprintf('<b>%s</b>', M.name);
    else, t = sprintf('%s › <b>%s</b>', M.name, M.subtypes{k}); end
    if strcmp(M.name,'ABR')
        v = abr_sel_of(app, k);
        if ~any(v),     fsel = '<font color="#b5463a">no frequencies selected</font>';
        elseif all(v),  fsel = 'all frequencies';
        else,           fsel = char(strjoin(fl(v), ', '));
        end
        t = sprintf('%s  ·  %s', t, fsel);
        if k == 2
            w = strrep(chip_labels(app.h_abr_wave_checks), 'Wave ', '');
            if isempty(w), w = 'I–V'; end
            t = sprintf('%s  ·  Waves %s', t, w);
        end
    end
    parts{end+1} = sprintf('%d.&nbsp;&nbsp;%s', ri, t); %#ok<AGROW>
end
yes = '<font color="#2e7d32">✓</font>';
no  = '<font color="#b0b0b0">✗</font>';
opts = sprintf('Options: Re-analyze %s  |  Relative %s  |  Blind %s', ...
    pick(app.ReanalyzeCheck.Value, yes, no), pick(app.PlotRelativeCheck.Value, yes, no), ...
    pick(app.BlindCheck.Value, yes, no));
% ABR repeated levels — only when an ABR analysis is selected
try
    hr = findall(app.MeasuresPanel, 'Tag','abr_dup_dd');
    if any(runs(:,1) == 1) && ~isempty(hr) && strcmp(hr(1).Value, 'average')
        opts = sprintf('%s  |  Repeated Levels: Average', opts);
    end
catch
end
% Data File rule — only when an OAE or MEMR analysis is selected
try
    uses = any(arrayfun(@(r) any(strcmp(app.MEASURES(r).name, {'OAE','MEMR'})), runs(:,1)));
    hd = findall(app.MeasuresPanel, 'Tag','rec_data_dd');
    if uses && ~isempty(hd)
        nm = @(h) h(1).Items{find(strcmp(h(1).ItemsData, h(1).Value), 1)};
        opts = sprintf('%s  |  Data File: %s', opts, nm(hd));
    end
catch
end
% rows: analyses (heading only when there are several), then the options
nL = numel(S.lines);
if isempty(parts)
    rows = {'<font color="#b5463a">No analysis selected — pick a measure, then its type</font>'};
elseif numel(parts) == 1
    rows = {['Analysis: ' regexprep(parts{1}, '^1\.&nbsp;&nbsp;', '')]};
else
    rows = [{sprintf('<b>%d analyses</b>, run one after another:', numel(parts))}, parts];
end
if ~isempty(exps) && size(per,1) == numel(exps)  % Experiment(s): subjects × conditions each
    bd = arrayfun(@(i) sprintf('<b>%s</b> %d %s %d', exps{i}, per(i,1), char(215), per(i,2)), ...
        1:numel(exps), 'UniformOutput', false);
    if numel(exps) > 1
        rows = [{sprintf('Experiments (subjects %s conditions): %s', char(215), ...
            strjoin(bd, ['  ' char(183) '  ']))}, rows];
    else
        rows = [{sprintf('Experiment (subjects %s conditions): %s', char(215), bd{1})}, rows];
    end
end
outp = '';                                        % Output: export format + images
try, outp = ['Output: ' output_opts(app, 'summary')]; catch, end
nO = 1 + ~isempty(outp);                          % rows kept for options (+ output)
if numel(rows) > nL - nO                          % keep the options rows visible
    extra = numel(rows) - (nL - nO - 1);
    rows = [rows(1:nL-nO-1), {sprintf('<font color="#777777">+ %d more</font>', extra)}];
end
rows{end+1} = opts;
if ~isempty(outp), rows{end+1} = outp; end
for li = 1:nL
    if ~isgraphics(S.lines(li)), continue; end
    if li <= numel(rows), S.lines(li).Text = rows{li}; else, S.lines(li).Text = ''; end
end

% ── Project status (right side of Project Settings) ──────────────────────
if isfield(S,'proj') && numel(S.proj) == 3 && all(isgraphics(S.proj))
    root = strtrim(app.RootDirField.Value);
    has_root = ~isempty(root) && exist(root,'dir') == 7;
    has_data = has_root && exist(fullfile(root,'Data'),'dir') == 7;
    has_ana  = has_root && exist(fullfile(root,'Analysis'),'dir') == 7;
    % design: counts first, then the folders found
    nsub = numel(app.subj_ids);  ncond = numel(app.state.cond_labels);
    if nsub > 0
        S.proj(1).Text = sprintf('<b><font size="4">%d</font></b> Subjects', nsub);
        S.proj(2).Text = sprintf('<b><font size="4">%d</font></b> Conditions', ncond);
    else
        S.proj(1).Text = sprintf('%s Roster not loaded', no);
        S.proj(2).Text = '';
    end
    S.proj(3).Text = sprintf('%s Data  %s Analysis', pick(has_data, yes, no), pick(has_ana, yes, no));
end
end


function v = abr_sel_of(app, k)
% ABR frequency selection of type k (1 Thresholds, 2 Peaks), logical 1×n
n = numel(app.h_abr_freq_checks);
v = true(1, n);
if isfield(app.state,'abr_freq') && numel(app.state.abr_freq) >= k
    w = logical(app.state.abr_freq{k}(:)');  v = false(1, n);  v(1:min(n,numel(w))) = w(1:min(n,numel(w)));
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
