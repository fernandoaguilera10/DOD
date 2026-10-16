function out = apat_excl(action, varargin)
%APAT_EXCL  Subjects / conditions left out of the group averages.
%
%   apat_excl('set', pairs, ref)
%       pairs — n×2 cell {subject, condition}; condition '*' = every
%       condition of that subject. Kept in root appdata 'APAT_excl' for the
%       run (analysis_run sets it from cfg.exclude and clears it at the end).
%       ref (optional) — reference condition name when plotting relative to
%       it: excluding a subject's reference excludes that whole subject
%       (its other conditions have nothing to be compared with).
%   M = apat_excl('mask', Chins2Run, all_Conds2Run)
%       logical nSubj × nCond, true = excluded from the average.
%   subject_idx = apat_excl('apply', Chins2Run, all_Conds2Run, subject_idx)
%       Called by every *summary function just before the group average:
%       empties the excluded {subject, condition, …} cells of every global
%       result array of this run (size nSubj × nCond × …), so the averages,
%       n counts and subject points treat them as missing. subject_idx (if
%       given) is returned with the excluded entries set to 0. Individual
%       figures are drawn before this and are unchanged.
%   R = apat_excl('record', Chins2Run, all_Conds2Run)
%       struct saved with the averages: .subjects .conditions (names),
%       .excluded (logical nSubj × nCond), .list (n×2 {subject, condition}),
%       .note.
%   M = apat_excl('merge', F, M, fields)
%       copies the listed fields (per-subject arrays used ONLY for the
%       subject points) from F (average of everyone) into M (average without
%       the excluded data): means / SD / n stay without them, the points
%       keep every subject (the app marks the excluded ones).
%   C = apat_excl('blank', C, X)   cells of C where X is true set to [].
%   apat_excl('stamp', folder, t0, Chins2Run, all_Conds2Run)
%       Appends that record to every *Average*.mat under folder written at
%       or after t0 (datenum), i.e. by this run: per-experiment files
%       (apat_avg_mat) get excluded.<EXP> for the run's Experiment (other
%       Experiments' records kept), old plain files variable 'excluded'. No separate CSV: every group-average
%       file (.mat field average.individual and the CSV) carries each
%       subject × condition with an Excluded column (apat_csv 'average').
out = [];
switch action
    case 'set'
        p = {};  if ~isempty(varargin), p = varargin{1}; end
        if isempty(p), p = cell(0, 2); end
        setappdata(0, 'APAT_excl', p);
        ref = '';  if numel(varargin) >= 2, ref = char(varargin{2}); end
        setappdata(0, 'APAT_excl_ref', ref);
    case 'mask'
        out = mask_of(varargin{1}, varargin{2});
    case 'apply'
        Chins = varargin{1};  Conds = varargin{2};
        sidx = [];  if numel(varargin) >= 3, sidx = varargin{3}; end
        M = mask_of(Chins, Conds);
        out = sidx;
        if ~any(M(:)), return; end
        mask_globals(M);
        if ~isempty(sidx) && size(sidx,1) == size(M,1) && size(sidx,2) == size(M,2)
            sidx(M) = 0;  out = sidx;
        end
        [s, c] = find(M);
        for k = 1:numel(s)
            fprintf('Excluded from the average: %s (%s)\n', Chins{s(k)}, last_part(Conds{c(k)}));
        end
    case 'record'
        out = record_of(varargin{1}, varargin{2});
    case 'merge'
        F = varargin{1};  out = varargin{2};  fl = varargin{3};
        if ~isstruct(F) || ~isstruct(out), return; end
        for k = 1:numel(fl)
            if isfield(F, fl{k}), out.(fl{k}) = F.(fl{k}); end
        end
    case 'blank'
        out = varargin{1};  X = varargin{2};
        if iscell(out) && size(out,1) == size(X,1) && size(out,2) == size(X,2)
            out(X) = {[]};
        end
    case 'stamp'
        stamp(varargin{:});
end
end


function M = mask_of(Chins, Conds)
nS = numel(Chins);  nC = numel(Conds);
M = false(nS, nC);
p = {};
if isappdata(0, 'APAT_excl'), p = getappdata(0, 'APAT_excl'); end
if isempty(p) || ~iscell(p) || size(p,2) < 2, return; end
cn = cellfun(@last_part, Conds, 'UniformOutput', false);
for r = 1:size(p,1)
    s = find(strcmp(Chins, char(p{r,1})));
    if isempty(s), continue; end
    cond = char(p{r,2});
    if strcmp(cond, '*')
        M(s, :) = true;
    else
        M(s, strcmp(cn, cond)) = true;
    end
end
ref = '';
if isappdata(0, 'APAT_excl_ref'), ref = getappdata(0, 'APAT_excl_ref'); end
r = find(strcmp(cn, ref), 1);
if ~isempty(r), M(M(:, r), :) = true; end
end


function mask_globals(M)
% Every global result array of the run is a cell array {subject, condition, …}
% (define_global_vars); empty the excluded cells in all of them.
nS = size(M,1);  nC = size(M,2);
names = who('global');
[s, c] = find(M);
for k = 1:numel(names)
    nm = names{k};
    try
        eval(['global ' nm]);
        v = eval(nm);
        if ~iscell(v) || size(v,1) ~= nS || size(v,2) ~= nC, continue; end
        for j = 1:numel(s)
            v(s(j), c(j), :) = {[]};
        end
        eval([nm ' = v;']);
    catch
    end
end
end


function R = record_of(Chins, Conds)
M = mask_of(Chins, Conds);
cn = cellfun(@last_part, Conds, 'UniformOutput', false);
[s, c] = find(M);
L = [reshape(Chins(s), [], 1), reshape(cn(c), [], 1)];
if isempty(L), L = cell(0, 2); end
R = struct('subjects',{Chins(:)'}, 'conditions',{cn(:)'}, 'excluded',M, 'list',{L}, ...
    'note','Subject / condition pairs left out of this group average (APAT Exclusions).', ...
    'date',datestr(now, 'yyyy-mm-dd HH:MM')); %#ok<TNOW1,DATST>
end


function stamp(folder, t0, Chins, Conds)
if ~exist(folder, 'dir'), return; end
excluded = record_of(Chins, Conds);
d = dir(fullfile(folder, '**', '*Average*.mat'));
d = d(~strncmp({d.name}, '._', 2));
for k = 1:numel(d)
    if d(k).datenum < t0 - 2/86400, continue; end          % not written by this run
    f = fullfile(d(k).folder, d(k).name);
    try
        if apat_avg_mat('is_multi', f)                      % one file, every Experiment:
            apat_avg_mat('save', f, 'excluded', excluded);  % excluded.<EXP> (this run's sheet)
        else
            save(f, 'excluded', '-append');                 % old plain layout
        end
    catch
    end
end
end


function s = last_part(p)
s = char(p);
q = strsplit(s, {'/','\'});
s = q{end};
end
