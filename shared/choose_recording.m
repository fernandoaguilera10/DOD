function file_out = choose_recording(folder, names, pattern, kind, datafile)
%CHOOSE_RECORDING  Pick one file when a data folder holds several, without
%   asking when possible. Called by load_files:
%     kind 'data'  (default) raw recordings, e.g. p0004 / p0014_sweptDPOAE.mat
%     kind 'calib' FPL calibrations for the data file DATAFILE: always the
%                  calibration recorded closest before it (all of them are
%                  candidates when none is earlier) — no setting, no question
%
%   Rule for data files = Setup → OAE / MEMR Parameters → "Data File" (root
%   appdata 'APAT_rec_policy', set for the run by RunButtonPushed; the
%   dropdown is the same setting in both panels):
%     'complete'   Auto (Most Trials): all trials completed first, then most
%                  trials completed, then the most recent (data default)
%     'latest'     Auto (Most Recent): highest p-number
%     'earliest'   Auto (Least Recent): lowest p-number
%     'ask_once'   Manual (Ask Once): ask and remember the answer
%     'ask_every'  Manual (Always): ask every time, nothing remembered (also
%                  when no rule is set, e.g. headless runs)
%   Manual: pick_datafile lists the files with a quick preview of each
%   (preview_recording: click = preview, double-click = use it).
%     'previous'   (no menu item) the recording the folder's existing results
%                  used, else Auto (Most Trials)
%   An answer given with Manual (Ask Once) is used by every rule except
%   Manual (Always) (Analysis/Settings/APAT_recording_choices.mat). Automatic choices
%   are deterministic, so every analysis of a folder gets the same file.
%   Every choice is logged once in Analysis/Logs/APAT_recording_choices_log.txt.
%   Note (Oct 2026 check of 66 folders): 39 earlier manual data picks were
%   not the most complete recording (often the first file of the list).

if nargin < 4 || isempty(kind), kind = 'data'; end
if nargin < 5, datafile = ''; end
is_cal = strcmp(kind, 'calib');
file_out = '';  timed_out = false;
if isempty(names), return; end
names = names(:)';
if is_cal && ~isempty(datafile)                      % calibrations recorded before the data
    pd = p_number(char(datafile));
    pc = cellfun(@p_number, names);
    if any(pc < pd), names = names(pc < pd); end
end
if numel(names) == 1, file_out = names{1}; return; end

if is_cal
    policy = 'latest';  what = 'calibration file';  % follows the data file, never asks
else
    policy = 'ask_every';  what = 'data file';
    if isappdata(0, 'APAT_rec_policy')
        p = getappdata(0, 'APAT_rec_policy');
        if ischar(p) && ~isempty(p), policy = p; end
    end
end
ttl = sprintf('Select %s', what);
if ~isempty(datafile) && is_cal, ttl = sprintf('Select calibration file for %s', char(datafile)); end
if strcmp(policy, 'ask_every')
    [file_out, to] = pick_datafile(names, ttl, folder);
    if ~to, return; end
    policy = 'complete';                             % no answer within 30 s: most trials, logged
    timed_out = true;
end

[root, rel] = split_root(folder);
kw  = keyword(pattern);
key = [rel '|' kw];
if is_cal && ~isempty(datafile), key = sprintf('%s|%s', key, regexprep(char(datafile), '\.mat$', '')); end
reg_file = '';
if ~isempty(root), reg_file = apat_paths(fullfile(root, 'Analysis'), 'settings', 'APAT_recording_choices.mat'); end

% 1. a file you picked yourself (Manual (Ask Once))
C = load_reg(reg_file);
k = find(strcmp({C.key}, key), 1);
if ~is_cal && ~isempty(k) && any(strcmp(names, C(k).file)) && strcmp(C(k).reason, 'chosen by you')
    file_out = C(k).file;
    fprintf('%s (your earlier pick): %s\n', upper1(what), file_out);
    return
end

% 2. earlier results ('previous' only, data files)
reason = '';
if strcmp(policy, 'previous') && ~is_cal
    f = from_results(root, rel, names, kw);
    if ~isempty(f), file_out = f;  reason = 'used by the existing results'; end
end

% 3. rule
if isempty(file_out)
    pn = cellfun(@p_number, names);
    switch policy
        case 'latest'
            [~, i] = max(pn);  file_out = names{i};  reason = 'most recent';
        case 'earliest'
            [~, i] = min(pn);  file_out = names{i};  reason = 'least recent';
        case 'ask_once'
            [file_out, to] = pick_datafile(names, [ttl ' (remembered)'], folder);
            reason = 'chosen by you';
            if to                                    % no answer: most trials (not remembered as yours)
                [file_out, reason] = most_complete(folder, names, pn);
                reason = ['no answer — ' reason];  timed_out = true;
            end
            if isempty(file_out), return; end
        otherwise                                   % 'complete' / 'previous' fallback
            [file_out, reason] = most_complete(folder, names, pn);
            if timed_out, reason = ['no answer — ' reason]; end
    end
end
if timed_out
    try, apat_run_error('auto', sprintf('%s: %s — no answer within the time limit, used %s (%s).', ...
        upper1(what), rel, file_out, reason)); catch, end
end

% remember + log (once per folder and result)
fprintf('%s chosen automatically: %s (%s)\n', upper1(what), file_out, reason);
if ~isempty(k) && strcmp(C(k).file, file_out) && strcmp(C(k).reason, reason), return; end
C(end+1) = struct('key',key, 'file',file_out, 'reason',reason, ...
    'date',datestr(now, 'yyyy-mm-dd HH:MM'));       %#ok<TNOW1,DATST>
if ~isempty(k), C(k) = []; end
save_reg(reg_file, C);
msg = sprintf('%s  %s  %s  [%s]  ->  %s  (%s)', datestr(now, 'yyyy-mm-dd HH:MM'), what, rel, ...
    strjoin(names, ', '), file_out, reason);         %#ok<TNOW1,DATST>
if ~isempty(root)
    try
        fid = fopen(apat_paths(fullfile(root, 'Analysis'), 'logs', 'APAT_recording_choices_log.txt'), 'a');
        if fid > 0, fprintf(fid, '%s\n', msg); fclose(fid); end
    catch
    end
end
end


function s = upper1(s)
s(1) = upper(s(1));
end


% ══════════════════════════════════════════════════════════════════════════
function [root, rel] = split_root(folder)
% <ROOT>/Data/<subject>/<measure>/<pre|post>/<condition> -> ROOT, relative path
f = strrep(char(folder), '\', '/');
i = strfind(f, '/Data/');
if isempty(i), root = '';  rel = f; return; end
i = i(end);
root = f(1:i-1);
rel  = f(i+6:end);
if ~isempty(rel) && rel(end) == '/', rel(end) = []; end
end


function kw = keyword(pattern)
% '*sweptDPOAE*.mat' -> 'dpoae', '*memr*.mat' -> 'memr', '*TEOAE*.mat' -> 'teoae'
kw = lower(char(pattern));
kw = regexprep(kw, '\.mat$', '');
kw = regexprep(kw, '[\*\?]', '');
kw = strrep(kw, 'swept', '');
end


function f = from_results(root, rel, names, kw)
% Output folder mirrors the data folder with measure and subject swapped:
% Data/<subj>/<EXP>/<pp>/<cond> -> Analysis/<EXP>/<subj>/<pp>/<cond>.
% A result file whose name contains the measure and _pNNNN of one of the
% candidates tells which recording was analysed (newest result wins).
f = '';
if isempty(root), return; end
parts = strsplit(rel, '/');
if numel(parts) < 4, return; end
out = fullfile(root, 'Analysis', parts{2}, parts{1}, parts{3:end});
if ~exist(out, 'dir'), return; end
d = dir(fullfile(out, '*.mat'));
d = d(~strncmp({d.name}, '._', 2));
if isempty(d), return; end
low = lower({d.name});
use = ~cellfun(@isempty, strfind(low, kw));
if strcmp(kw, 'memr'), use = use | ~cellfun(@isempty, strfind(low, '_mx_')); end
d = d(use);
if isempty(d), return; end
[~, o] = sort([d.datenum], 'descend');  d = d(o);
cand = cellfun(@(n) sprintf('p%04d', p_number(n)), names, 'UniformOutput', false);
for j = 1:numel(d)
    tok = regexp(d(j).name, 'p\d{4}', 'match');
    for t = 1:numel(tok)
        hit = find(strcmpi(cand, tok{t}), 1);
        if ~isempty(hit), f = names{hit}; return; end
    end
end
end


function [f, reason] = most_complete(folder, names, pn)
% all trials completed (ALLtrials_Completed) first, then most trials
% completed (NUMtrials_Completed), then the latest p-number
n = numel(names);
score = -inf(n, 2);
for i = 1:n
    try
        S = load(fullfile(folder, names{i}), 'x');
        st = find_stim(S.x);
        a = 0;  t = 0;
        if isfield(st, 'ALLtrials_Completed'), a = double(st.ALLtrials_Completed(1)); end
        if isfield(st, 'NUMtrials_Completed'), t = double(st.NUMtrials_Completed(1)); end
        score(i, :) = [a, t];
    catch
    end
end
M = [score, pn(:)];
[~, o] = sortrows(M, [-1 -2 -3]);
f = names{o(1)};
reason = sprintf('most complete: %d trials%s', score(o(1),2), ...
    ternary_s(score(o(1),1) > 0, ', all trials completed', ''));
if ~isfinite(score(o(1),2))                         % none could be read
    [~, i] = max(pn);  f = names{i};  reason = 'latest recording (trial counts not readable)';
end
end


function st = find_stim(x)
% Struct holding NUMtrials_Completed / ALLtrials_Completed:
% x.<Something>Data.stim (sweptDPOAEData, sweptSFOAEData, TEOAEData, MemrData)
% or, for FPL calibrations, x.FPLearData / x.FPLprobeData.calib
st = struct();
fn = fieldnames(x);
for i = 1:numel(fn)
    v = x.(fn{i});
    if ~isstruct(v), continue; end
    if isfield(v, 'stim'), st = v.stim; return; end
    if isfield(v, 'NUMtrials_Completed'), st = v; return; end
    if isfield(v, 'calib') && isstruct(v.calib) && isfield(v.calib, 'NUMtrials_Completed'), st = v.calib; return; end
end
end


function n = p_number(name)
tok = regexp(name, 'p(\d+)', 'tokens', 'once');
n = inf;  if ~isempty(tok), n = str2double(tok{1}); end
end


function C = load_reg(f)
C = struct('key',{}, 'file',{}, 'reason',{}, 'date',{});
if isempty(f) || ~exist(f, 'file'), return; end
try
    S = load(f, 'choices');
    if isfield(S, 'choices') && isstruct(S.choices) && isfield(S.choices, 'key'), C = S.choices(:)'; end
catch
end
end


function save_reg(f, choices) %#ok<INUSD>
if isempty(f), return; end
try, save(f, 'choices'); catch, end
end


function s = ternary_s(c, a, b)
if c, s = a; else, s = b; end
end
