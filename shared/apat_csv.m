function out = apat_csv(action, varargin)
%APAT_CSV  Tidy (long) CSV export of APAT results — one row per observation.
%
%   Rows are tables: Measure (ABR_Thresholds, ABR_Peaks, EFR_RAM, EFR_dAM,
%   DPOAE, SFOAE, TEOAE, MEMR, MEMR_<view>), Experiment (chinroster sheet of
%   the run, root appdata 'APAT_experiment'), Subject, Sex (chinroster,
%   apat_sex), Condition, measure-specific key columns (units in the name:
%   Frequency_kHz, Level_dBSPL, Elicitor_dBFPL, ModFrequency_Hz; Repeat,
%   Wave, Harmonic, Region, Scale …), then Metric (PascalCase id), Value,
%   Units (of Value). Every column is described in
%   Analysis/APAT_data_dictionary.csv (apat_data_dictionary, written with
%   the first CSV of a run). The row store lives in
%   root appdata 'APAT_csv_store' for one APAT run (reset at the start of
%   analysis_run unless cfg.csv_keep — the app keeps it across the
%   Experiments of one run; rows are kept per Experiment × recording;
%   filled in every export format, so the group-average .mat files can
%   carry the individual values too) and feeds the group (Average) files.
%   Average files hold EVERY Experiment: one <name>.csv / <name>_Individual.csv
%   per average type, Experiment a column (and a key of the statistics);
%   rewritten after each Experiment of the run, rows of Experiments not in
%   this run are kept from the existing file (apat_write_csv keep_by).
%   ('subject' is kept but no longer called: the per-recording CSVs already
%   hold every condition's data.)
%
%   tf = apat_csv('on')
%       true when CSV files are written (apat_export_fmt 'csv' or 'both').
%   tf = apat_csv('avg_mat')
%       true when group-average .mat files are written (not in 'csv' mode;
%       per-recording .mat files are always written — APAT's own cache).
%   apat_csv('reset')
%       empty the row store and the per-file average store (analysis_run,
%       start of a run).
%   T = apat_csv('mk', base, cols)
%       table: every field of struct base (scalar / char) repeated on every
%       row, then the columns of struct cols (equal-length vectors / cellstr).
%       A base with Subject (and no Sex) gets Sex = apat_sex('get', Subject)
%       right after it; a base with Measure (and no Experiment) gets
%       Experiment (the run's sheet) right after Measure.
%   apat_csv('rec', key, id, T, file)
%       keep T in the store under measure key (e.g. 'abr_thr') and recording
%       id of this Experiment (same Experiment + id replaces), and write it to file (per-recording CSV,
%       next to its .mat) when CSV export is on. file = '' → only kept.
%   apat_csv('subject', key, subj, file)
%       write every kept row of subject subj (all conditions) to file.
%   I = apat_csv('average', key, file, Chins2Run, all_Conds2Run, ref)
%       The individual values that went into the group average of THIS
%       Experiment (rows of the run's Experiment only), one row per
%       subject × condition × keys × metric: Measure, Experiment, Subject, Sex,
%       Condition, Reference, Excluded (logical), keys…, Metric, Value,
%       Units. Excluded
%       pairs (apat_excl 'mask') keep their values but are left out of the
%       group statistics. Conditions in roster order, then subjects in run
%       order. ref (index into all_Conds2Run, [] = none): rows of each
%       subject's change re. that condition are added (Reference = its
%       name; '' = absolute values). When CSV export is on and file is not
%       '' TWO files are written (user, Oct 16): file = the group results,
%       one row per cell (Measure, Experiment, Condition, Reference, keys…,
%       Metric, Mean, SD, N, Units; cell = every column but Subject / Sex /
%       Excluded / Value, so never pooled across Experiments; statistics
%       without the excluded rows), and <file>_Individual.csv = the
%       individual rows (Excluded as true / false) — both with every
%       Experiment of the run (APAT_csv_avg store, per file) plus the rows
%       of other Experiments already in the files. I (this Experiment's
%       individual rows) is returned for the .mat ('attach').
%   G = apat_csv('group', T, Chins2Run, all_Conds2Run, ref)   same, no write.
%   apat_csv('attach', matfile, I)
%       adds I as field 'individual' of this Experiment's average in matfile
%       (average.<EXP>.individual, apat_avg_mat 'set_field'; old plain files:
%       average.individual; nothing when the file or the variable is
%       missing). Never throws.
out = [];
switch action
    case 'on'
        out = any(strcmp(apat_export_fmt(), {'csv','both'}));
    case 'avg_mat'          % group-average .mat files: not in 'csv' mode
        out = ~strcmp(apat_export_fmt(), 'csv');
    case 'reset'
        setappdata(0, 'APAT_csv_store', struct());
        setappdata(0, 'APAT_csv_avg', struct('file',{}, 'exps',{}, 'G',{}));
        if isappdata(0, 'APAT_csv_dict'), rmappdata(0, 'APAT_csv_dict'); end
    case 'mk'
        out = mk(varargin{:});
    case 'rec'
        [key, id, T, file] = varargin{1:4};
        if ~istable(T) || height(T) == 0, return; end
        S = store();
        k = matlab.lang.makeValidName(key);
        if ~isfield(S, k), S.(k) = struct('ids',{{}}, 'T',{{}}); end
        id = [experiment() '#' char(id)];             % one entry per Experiment × recording
        j = find(strcmp(S.(k).ids, id), 1);
        if isempty(j), j = numel(S.(k).ids) + 1; end
        S.(k).ids{j} = id;  S.(k).T{j} = T;
        setappdata(0, 'APAT_csv_store', S);
        if ~isempty(file) && apat_csv('on')
            out = apat_write_csv(T, file);
            dictionary(file);
        end
    case 'subject'
        [key, subj, file] = varargin{1:3};
        T = rows_of(key);
        if isempty(T), return; end
        T = T(strcmp(cellstr(T.Subject), subj), :);
        out = apat_write_csv(T, file);
    case 'average'
        [key, file, Chins, Conds] = varargin{1:4};
        ref = [];  if numel(varargin) >= 5, ref = varargin{5}; end
        T = rows_of(key);
        if isempty(T), return; end
        ex = experiment();
        if ismember('Experiment', T.Properties.VariableNames)   % this Experiment's rows only
            T = T(strcmp(cellstr(T.Experiment), ex), :);
            if height(T) == 0, return; end
        end
        out = group(T, Chins, Conds, ref);
        if isempty(file), return; end
        % every Experiment of this run for this file (store kept across sheets)
        file = char(file);
        [d, nm] = fileparts(file);
        A = avg_store(fullfile(d, nm), ex, out);
        if apat_csv('on')
            apat_write_csv(summarize(A), fullfile(d, [nm '.csv']), 'Experiment');
            apat_write_csv(A, fullfile(d, [nm '_Individual.csv']), 'Experiment');   % Excluded → true / false
            dictionary(file);
        end
    case 'group'
        ref = [];  if numel(varargin) >= 4, ref = varargin{4}; end
        out = group(varargin{1:3}, ref);
    case 'attach'
        attach(varargin{1:2});
    otherwise
        error('apat_csv: unknown action %s', action);
end
end


% ═════════════════════════════════════════════════════════════════════════
function S = store()
S = struct();
if isappdata(0, 'APAT_csv_store'), S = getappdata(0, 'APAT_csv_store'); end
if ~isstruct(S), S = struct(); end
end


function e = experiment()
% the run's Experiment (chinroster sheet; analysis_run sets it)
e = '';
try
    if isappdata(0, 'APAT_experiment'), e = char(getappdata(0, 'APAT_experiment')); end
catch
end
end


function A = avg_store(fkey, ex, G)
% per average file (full path without extension): the individual tables of
% every Experiment of this run, in run order; returns them stacked
P = struct('file',{}, 'exps',{}, 'G',{});
if isappdata(0, 'APAT_csv_avg'), P = getappdata(0, 'APAT_csv_avg'); end
if ~isstruct(P) || ~isfield(P, 'file'), P = struct('file',{}, 'exps',{}, 'G',{}); end
i = find(strcmp({P.file}, fkey), 1);
if isempty(i)
    i = numel(P) + 1;
    P(i).file = fkey;  P(i).exps = {};  P(i).G = {};
end
j = find(strcmp(P(i).exps, ex), 1);
if isempty(j), j = numel(P(i).exps) + 1; end
P(i).exps{j} = ex;  P(i).G{j} = G;
setappdata(0, 'APAT_csv_avg', P);
A = stack_tables(P(i).G);
end


function T = stack_tables(C)
% vertical concatenation of tables whose columns may differ (missing
% columns: NaN for numbers, '' for text, false for logicals)
C = C(cellfun(@(t) istable(t) && height(t) > 0, C));
T = table();
if isempty(C), return; end
names = {};
for i = 1:numel(C)
    names = [names, setdiff(C{i}.Properties.VariableNames, names, 'stable')]; %#ok<AGROW>
end
for i = 1:numel(C)
    t = C{i};
    for m = setdiff(names, t.Properties.VariableNames, 'stable')
        ref = [];
        for q = 1:numel(C)
            if ismember(m{1}, C{q}.Properties.VariableNames), ref = C{q}.(m{1}); break; end
        end
        if iscell(ref),        t.(m{1}) = repmat({''}, height(t), 1);
        elseif islogical(ref), t.(m{1}) = false(height(t), 1);
        else,                  t.(m{1}) = nan(height(t), 1); end
    end
    C{i} = t(:, names);
end
try
    T = vertcat(C{:});
catch
    T = C{end};
end
end


function T = rows_of(key)
T = [];
S = store();  k = matlab.lang.makeValidName(key);
if ~isfield(S, k) || isempty(S.(k).T), return; end
try, T = vertcat(S.(k).T{:}); catch, T = []; end
end


function T = mk(base, cols)
fc = fieldnames(cols);
n = 0;
for i = 1:numel(fc), n = max(n, numel(cols.(fc{i}))); end
T = table();
if n == 0, return; end
fb = fieldnames(base);
for i = 1:numel(fb)
    v = base.(fb{i});
    if ischar(v) || isstring(v), T.(fb{i}) = repmat({char(v)}, n, 1);
    elseif isempty(v),           T.(fb{i}) = nan(n, 1);
    else,                        T.(fb{i}) = repmat(double(v(1)), n, 1); end
    if strcmp(fb{i}, 'Measure') && ~isfield(base, 'Experiment')   % chinroster sheet of the run
        T.Experiment = repmat({experiment()}, n, 1);
    end
    if strcmp(fb{i}, 'Subject') && ~isfield(base, 'Sex')      % chinroster Sex column
        T.Sex = repmat({apat_sex('get', char(v))}, n, 1);
    end
end
for i = 1:numel(fc)
    v = cols.(fc{i});
    if ischar(v), v = {v}; end
    if isstring(v), v = cellstr(v); end
    if iscell(v)
        v = v(:);  if numel(v) == 1 && n > 1, v = repmat(v, n, 1); end
        T.(fc{i}) = cellfun(@char, v, 'UniformOutput', false);
    else
        v = double(v(:));  if numel(v) == 1 && n > 1, v = repmat(v, n, 1); end
        T.(fc{i}) = v;
    end
end
end


function G = group(T, Chins, Conds, ref)
% Individual rows (all subjects × conditions, Excluded flag) + the cell
% statistics without the excluded pairs (see 'average').
G = table();
if ~istable(T) || height(T) == 0, return; end
cn = cellfun(@last_part, Conds, 'UniformOutput', false);
if ~ismember('Sex', T.Properties.VariableNames)
    T.Sex = cellfun(@(x) apat_sex('get', x), cellstr(T.Subject), 'UniformOutput', false);
end
if ~ismember('Experiment', T.Properties.VariableNames)
    T.Experiment = repmat({experiment()}, height(T), 1);
end
subj = cellstr(T.Subject);  cond = cellstr(T.Condition);
% pairs excluded from the average (rows kept, flagged)
M = apat_excl('mask', Chins, Conds);
[~, si] = ismember(subj, Chins);  [~, ci] = ismember(cond, cn);
ex = false(height(T), 1);
ok = si > 0 & ci > 0;
ex(ok) = M(sub2ind(size(M), si(ok), ci(ok)));
T.Excluded = ex;
T.Reference = repmat({''}, height(T), 1);
G = T;
if ~isempty(ref), ref = double(ref(1)); end      % idx_plot_relative may be logical true (= 1)
if ~isempty(ref) && ref >= 1 && ref <= numel(cn)
    % each subject's change re. the reference condition, matched on every
    % other key (excluding the reference excludes the subject: apat_excl)
    keys = setdiff(T.Properties.VariableNames, {'Subject','Sex','Value','Excluded','Reference'}, 'stable');
    k2 = setdiff(keys, {'Condition'}, 'stable');
    kstr = key_str(T, k2);
    isref = strcmp(cond, cn{ref});
    rk = strcat(subj(isref), '#', kstr(isref));  rv = T.Value(isref);
    [hit, loc] = ismember(strcat(subj, '#', kstr), rk);
    use = hit & ~isref;
    if any(use)
        Ts = T(use, :);
        Ts.Value = T.Value(use) - rv(loc(use));
        Ts.Reference = repmat(cn(ref), height(Ts), 1);
        G = [G; Ts];
        si = [si; si(use)];  ci = [ci; ci(use)];
    end
end
% order: absolute then change rows, roster condition order, subjects in
% run order, then as stored
isrel = ~cellfun(@isempty, G.Reference);
ci(ci == 0) = numel(cn) + 1;  si(si == 0) = numel(Chins) + 1;
[~, o] = sortrows([double(isrel), ci(:), si(:), (1:height(G))']);
G = G(o, :);
front = intersect({'Measure','Experiment','Subject','Sex','Condition','Reference','Excluded'}, G.Properties.VariableNames, 'stable');
tail  = intersect({'Metric','Value','Units'}, G.Properties.VariableNames, 'stable');
rest  = setdiff(G.Properties.VariableNames, [front, tail], 'stable');
G = G(:, [front, rest, tail]);
end


function S = summarize(G)
% Group results: one row per cell (every column but Subject / Sex /
% Excluded / Value), Mean / SD / N without the excluded rows, in the order
% the cells first appear in G (absolute then change rows, roster order).
S = table();
if ~istable(G) || height(G) == 0, return; end
keys = setdiff(G.Properties.VariableNames, {'Subject','Sex','Value','Excluded'}, 'stable');
[~, first, g] = unique(key_str(G, keys), 'stable');
ng = numel(first);
mu = nan(ng,1);  sd = nan(ng,1);  n = zeros(ng,1);
v = G.Value;  use = ~G.Excluded & isfinite(v);
for j = 1:ng
    x = v(g == j & use);
    n(j) = numel(x);
    if n(j) > 0, mu(j) = mean(x);  sd(j) = 0; end
    if n(j) > 1, sd(j) = std(x); end
end
S = G(first, keys);
S.Mean = mu;  S.SD = sd;  S.N = n;
if ismember('Units', keys), S = S(:, [setdiff(S.Properties.VariableNames, {'Units'}, 'stable'), {'Units'}]); end
end


function dictionary(file)
% Analysis/APAT_data_dictionary.csv, once per run (the Analysis folder above file)
try
    d = fileparts(char(file));
    for k = 1:8
        [up, nm] = fileparts(d);
        if strcmpi(nm, 'Analysis'), break; end
        if isempty(nm) || strcmp(up, d), return; end
        d = up;
    end
    if ~strcmpi(nm, 'Analysis'), return; end
    if isappdata(0, 'APAT_csv_dict') && strcmp(getappdata(0, 'APAT_csv_dict'), d), return; end
    apat_data_dictionary(fullfile(d, 'APAT_data_dictionary.csv'));
    setappdata(0, 'APAT_csv_dict', d);
catch
end
end


function attach(matfile, I)
% average.<EXP>.individual (per-experiment file) / average.individual (old)
try
    if ~istable(I) || isempty(matfile), return; end
    apat_avg_mat('set_field', char(matfile), 'average', 'individual', I);
catch ME
    warning('APAT:avgIndividual', 'Could not add the individual values to %s: %s', matfile, ME.message);
end
end


function s = key_str(T, keys)
s = repmat({''}, height(T), 1);
for i = 1:numel(keys)
    v = T.(keys{i});
    if isnumeric(v) || islogical(v)
        c = cellstr(compose('%.10g', double(v)));
    else
        c = cellstr(v);
    end
    s = strcat(s, '|', c);
end
end


function s = last_part(p)
q = strsplit(char(p), {'/','\'});
s = q{end};
end
