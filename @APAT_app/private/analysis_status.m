function out = analysis_status(app, action, varargin)
%ANALYSIS_STATUS  Colour the selected Subject and Condition chips of the
%   Setup tab by how much of the selected analyses is already done (user,
%   Oct 17 2026; replaces the "Resume previous run" question):
%     green   every selected condition analysed (every selected analysis)
%     orange  some analysed
%     red     none analysed — and every selected chip when Re-Analyze
%             Data is ON (everything will be analysed again)
%   Chips that are not selected keep the plain (grey / beige) look, and so
%   do selected ones with nothing expected (no "X" for the selection).
%   Subject chip = over the selected conditions; Condition chip = over the
%   selected subjects. Only subject × condition pairs the roster marks as
%   recorded ("X" in that measure's block of the sheet) count; a pair counts
%   as analysed for an analysis when its result file exists
%   (Analysis/<Measure>/<Subj>/<pre|post>/<Cond>/<pattern>, as analysis_run).
%   The tooltip says how many.
%
%   analysis_status(app, 'paint')       colour the chips (update_summary);
%                                       results on disk are read once per
%                                       analysis and cached
%   analysis_status(app, 'invalidate')  forget the cache (a run finished,
%                                       another roster / sheet / folder)
%   tf = analysis_status(app, 'complete', m, k, sheet, chins, conds)
%                                       every pair of CHINS × CONDS (paths)
%                                       the roster expects for analysis
%                                       [m k] has its result file (read now,
%                                       not cached) — Run Analysis loads saved
%                                       Results only then (RunButtonPushed)
%   Never throws.
out = [];
if nargin < 2, action = 'paint'; end
try
    fig = app.UIFigure;
    if strcmp(action, 'invalidate')
        if isappdata(fig, 'apat_astatus'), rmappdata(fig, 'apat_astatus'); end
        return
    end
    if strcmp(action, 'complete')
        out = false;
        [m, k, sheet, chins, conds] = varargin{1:5};
        chins = cellstr(chins(:)');  conds = cellstr(conds(:)');
        [exp1, exp2, blk] = run_names(app, m, k);
        file = '';  if isfield(app.state, 'sheet_file'), file = app.state.sheet_file; end
        M = roster_marks(file, sheet, chins, conds);
        if isempty(M), return; end                % roster not readable: run instead
        D = done_pairs(strtrim(app.RootDirField.Value), exp1, exp2, chins, conds);
        mk = M(:,:,min(blk, size(M,3)));
        out = all(D(mk));
        return
    end
    paint(app, fig);
catch
end
end


function paint(app, fig)
subjs = app.subj_ids(:)';
conds = app.state.conds_all(:)';
hs = app.h_subj_checks;  hc = app.h_cond_checks;
if isempty(subjs) || isempty(conds), return; end
runs = zeros(0, 2);
if isfield(app.state, 'run_sel')
    for m = 1:numel(app.MEASURES)
        for k = find(app.state.run_sel{m}), runs(end+1,:) = [m k]; end %#ok<AGROW>
    end
end
s_on = arrayfun(@(b) isgraphics(b) && b.Value, hs);
c_on = arrayfun(@(b) isgraphics(b) && b.Value, hc);
if isempty(runs)                                  % nothing selected to run: plain look
    clear_tips(hs);  clear_tips(hc);  return
end
root = strtrim(app.RootDirField.Value);
sheet = '';  try, sheet = sheet_sel(app, 'on_screen'); catch, end
file = '';  if isfield(app.state, 'sheet_file'), file = app.state.sheet_file; end
sig = strjoin([{root, file, char(sheet)}, subjs, conds], '|');

C = struct('sig','', 'marks',[], 'keys',{{}}, 'have',{{}});
if isappdata(fig, 'apat_astatus'), C = getappdata(fig, 'apat_astatus'); end
if ~strcmp(C.sig, sig)                            % another roster / sheet / folder
    C = struct('sig',sig, 'marks',roster_marks(file, sheet, subjs, conds), 'keys',{{}}, 'have',{{}});
end
nS = numel(subjs);  nC = numel(conds);
need = zeros(nS, nC);  have = zeros(nS, nC);
for r = 1:size(runs, 1)
    [exp1, exp2, blk] = run_names(app, runs(r,1), runs(r,2));
    key = sprintf('%s|%s', exp1, exp2);
    i = find(strcmp(C.keys, key), 1);
    if isempty(i)                                 % read once (then cached)
        C.keys{end+1} = key;  C.have{end+1} = done_pairs(root, exp1, exp2, subjs, conds);
        i = numel(C.keys);
    end
    mk = true(nS, nC);
    if ~isempty(C.marks) && blk <= size(C.marks, 3), mk = C.marks(:,:,blk); end
    need = need + mk;
    have = have + (mk & C.have{i});
end
setappdata(fig, 'apat_astatus', C);
rean = false;  try, rean = logical(app.ReanalyzeCheck.Value); catch, end
if rean, have(:) = 0; end                         % everything is analysed again

% a subject × condition is expected when any selected analysis expects it,
% found when every one that expects it has its result
exp_p = need > 0;  fnd_p = exp_p & (have >= need);
clab = cell(1, nC);
for c = 1:nC, [~, clab{c}] = fileparts(conds{c}); end
% subject chips: over the selected conditions
for s = 1:min(nS, numel(hs))
    if ~isgraphics(hs(s)), continue; end
    N = sum(need(s, c_on));  H = sum(have(s, c_on));
    cs = find(c_on & exp_p(s, :));
    tip = found_tip(subjs{s}, 'condition', clab(cs), fnd_p(s, cs), rean);
    tint(app, hs(s), s_on(s), N, H, tip);
end
% condition chips: over the selected subjects
for c = 1:min(nC, numel(hc))
    if ~isgraphics(hc(c)), continue; end
    N = sum(need(s_on, c));  H = sum(have(s_on, c));
    ss = find(s_on(:)' & exp_p(:, c)');
    tip = found_tip(clab{c}, 'subject', subjs(ss), fnd_p(ss, c)', rean);
    tint(app, hc(c), c_on(c), N, H, tip);
end
end


function tint(app, b, on, N, H, tip)
if ~on                                            % not selected: plain look (setup_style)
    b.Tooltip = '';  return
end
if N == 0                                         % nothing expected: greyed out (not counted)
    b.BackgroundColor = app.clr_btn;  b.FontColor = app.clr_txt2;  b.FontWeight = 'normal';
    b.Tooltip = tip;  return
end
if N > 0 && H >= N,  clr = app.clr_on;            % all analysed
elseif H > 0,        clr = [0.85 0.52 0.13];      % some
else,                clr = app.clr_off;           % none
end
b.BackgroundColor = clr;  b.FontColor = [1 1 1];  b.FontWeight = 'bold';
b.Tooltip = tip;
end


function tip = found_tip(name, what, items, found, rean)
% 'Q447: 4 of 4 conditions found (Baseline, D7, D14, D30)'
% 'D30: 1 of 2 subjects found (Q447) — missing Q460'
n = numel(items);
if n == 0
    tip = sprintf('%s: not expected for the selected analyses — not counted', name);  return
end
pl = '';  if n ~= 1, pl = 's'; end
if rean
    tip = sprintf('%s: Re-Analyze is ON — %d %s%s analysed again (%s)', name, n, what, pl, strjoin(items, ', '));
    return
end
tip = sprintf('%s: %d of %d %s%s found', name, nnz(found), n, what, pl);
if any(found), tip = sprintf('%s (%s)', tip, strjoin(items(found), ', ')); end
if ~all(found), tip = sprintf('%s — missing %s', tip, strjoin(items(~found), ', ')); end
end


function s = words(N, H, rean)
if N == 0, s = 'not expected (no X in the roster for the selected analyses / subjects) — not counted'; return; end
if rean, s = sprintf('Re-Analyze is ON — all %d will be analysed again', N); return; end
s = sprintf('%d of %d expected analysed (roster X × selected analyses)', H, N);
end


function clear_tips(h)
for b = h(:)'
    if isgraphics(b), b.Tooltip = ''; end
end
end


function [exp1, exp2, blk] = run_names(app, m, k)
% measure folder / type of an analysis and its block in the roster sheet
% (ABR, EFR, DPOAE, SFOAE, TEOAE, MEMR — as analysis_run)
exp1 = app.MEASURES(m).name;  exp2 = '';
st = app.MEASURES(m).subtypes;
if ~isempty(st), exp2 = st{k}; end
switch exp1
    case 'ABR',  blk = 1;
    case 'EFR',  blk = 2;
    case 'OAE',  blk = find(strcmp({'DPOAE','SFOAE','TEOAE'}, exp2), 1) + 2;
    case 'MEMR', blk = 6;  if k == 1, exp2 = ''; end      % ART; exploratory types share _MX_ files
    otherwise,   blk = 1;
end
if isempty(blk), blk = 1; end
end


function D = done_pairs(root, exp1, exp2, subjs, conds)
% result file of this analysis present, per subject × condition
D = false(numel(subjs), numel(conds));
pat = out_pattern(exp1, exp2);
base = fullfile(root, 'Analysis', exp1);
if ~exist(base, 'dir'), return; end
for s = 1:numel(subjs)
    sd = fullfile(base, subjs{s});
    if ~exist(sd, 'dir'), continue; end
    for c = 1:numel(conds)
        L = dir(fullfile(sd, conds{c}, pat));
        D(s, c) = any(~startsWith({L.name}, '._'));
    end
end
end


function p = out_pattern(exp1, exp2)
% same patterns as analysis_run>get_file_patterns (result files)
switch exp1
    case 'ABR'
        switch exp2
            case 'Thresholds', p = '*ABRthresholds*.mat';
            case 'Peaks',      p = '*ABRpeaks_dtw*.mat';
            otherwise,         p = ['*ABR' exp2 '*.mat'];
        end
    case 'EFR',  p = ['*EFR_' exp2 '*.mat'];
    case 'OAE',  p = ['*' exp2 '*.mat'];
    case 'MEMR'
        if isempty(exp2), p = '*MEMR*.mat'; else, p = '*_MX_*.mat'; end
    otherwise,   p = ['*' exp1 '*.mat'];
end
end


function M = roster_marks(file, sheet, subjs, conds)
% M(s,c,b) = roster marks subject s × condition c as recorded ("X") in
% measure block b (1 ABR, 2 EFR, 3 DPOAE, 4 SFOAE, 5 TEOAE, 6 MEMR):
% blocks start at each "Baseline" / "B" header cell (as analysis_run).
% [] when the sheet cannot be read (then every pair counts).
M = [];
try
    if isempty(file) || isempty(sheet) || exist(file, 'file') ~= 2, return; end
    R = readcell(file, 'Sheet', sheet);
    R(cellfun(@(x) any(isa(x, 'missing')), R)) = {NaN};
    isB = cellfun(@(v) (ischar(v) || isstring(v)) && (strcmpi(strtrim(char(v)), 'Baseline') || strcmp(strtrim(char(v)), 'B')), R);
    [rr, cc] = find(isB);
    if isempty(cc), return; end
    hdr = max(rr);  cols = sort(cc(rr == hdr))';
    if numel(cols) < 2, w = numel(conds); else, w = cols(2) - cols(1); end
    lab = cell(1, w);                                  % condition labels of block 1
    for j = 1:w
        v = R{hdr, cols(1) + j - 1};  lab{j} = '';
        if isstring(v), v = char(v); end
        if ischar(v), lab{j} = strtrim(v); end
    end
    ids = repmat({''}, size(R, 1), 1);                 % subject IDs (first column; blanks are numbers)
    for i = 1:size(R, 1)
        v = R{i,1};
        if isstring(v), v = char(v); end
        if ischar(v), ids{i} = strtrim(v); end
    end
    M = false(numel(subjs), numel(conds), max(6, numel(cols)));
    for c = 1:numel(conds)
        [~, nm] = fileparts(conds{c});                 % 'post/D7' → 'D7'
        j = find(strcmp(lab, nm), 1);
        if isempty(j), continue; end
        for s = 1:numel(subjs)
            r = find(strcmp(ids, subjs{s}), 1);
            if isempty(r), continue; end
            for b = 1:numel(cols)
                col = cols(b) + j - 1;
                if col <= size(R, 2)
                    v = R{r, col};
                    if isstring(v), v = char(v); end
                    M(s, c, b) = ischar(v) && strcmpi(strtrim(v), 'x');
                end
            end
        end
    end
catch
    M = [];
end
end


function v = ternary_s(c, a, b)
if c, v = a; else, v = b; end
end
