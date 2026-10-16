function out = apat_avg_mat(action, varargin)
%APAT_AVG_MAT  Group-average .mat files holding every Experiment (Oct 16 2026).
%
%   Averages of all Experiments (chinroster sheets, e.g. NOISE, BLAST) share
%   ONE file per average type in Analysis/<Measure>/Average/. Layout of such
%   a file ("per-experiment" layout):
%     average      struct, one field per Experiment:  average.NOISE,
%                  average.BLAST … (field = matlab.lang.makeValidName(sheet));
%                  each field is the plain average struct the plot code made
%                  (+ .individual, the tidy individual table, apat_csv 'attach')
%     waveforms    (ABR_Waveforms_*.mat) same, one field per Experiment
%     excluded     (apat_excl 'stamp') same, one field per Experiment
%     experiments  cellstr of the Experiment (sheet) names, in the order they
%                  were added; its presence marks the per-experiment layout
%   Older files (before Oct 16 2026: Average/<Group>/ or loose) hold the plain
%   struct in `average` and no `experiments` variable — 'load' / 'get'
%   read both layouts.
%
%   apat_avg_mat('save', file, var, value [, exp])
%       store value as <var>.<exp> in file (.mat added when missing), keeping
%       the other Experiments (and other variables) already in the file; a
%       file in the old plain layout is replaced. exp defaults to the run's
%       Experiment (root appdata 'APAT_experiment', set by analysis_run);
%       none → plain save of var (old layout). Never throws (warning).
%   apat_avg_mat('set_field', file, var, field, value [, exp])
%       <var>.<exp>.<field> = value (e.g. average.NOISE.individual); old
%       layout: <var>.<field> = value. Nothing when var is missing.
%   L = apat_avg_mat('load', file [, var])
%       struct array, one element per Experiment: .experiment (name; '' for
%       an old plain file) and .value (the plain struct). var default 'average'.
%   v = apat_avg_mat('get', file, var, exp)    one Experiment's plain struct
%       ([] when missing; old plain file: its struct whatever exp is)
%   tf = apat_avg_mat('is_multi', file)         per-experiment layout?
%   e  = apat_avg_mat('experiment')            the run's Experiment ('' none)
%   k  = apat_avg_mat('key', name)             field name of an Experiment
out = [];
switch action
    case 'save'
        [file, var, val] = varargin{1:3};
        ex = cur_exp();  if numel(varargin) >= 4, ex = char(varargin{4}); end
        do_save(mat_name(file), var, val, ex);
    case 'set_field'
        [file, var, fld, val] = varargin{1:4};
        ex = cur_exp();  if numel(varargin) >= 5, ex = char(varargin{5}); end
        do_set_field(mat_name(file), var, fld, val, ex);
    case 'load'
        var = 'average';  if numel(varargin) >= 2, var = varargin{2}; end
        out = do_load(mat_name(varargin{1}), var);
    case 'get'
        [file, var, ex] = varargin{1:3};
        L = do_load(mat_name(file), var);
        for i = 1:numel(L)
            if isempty(L(i).experiment) || strcmp(L(i).experiment, char(ex)) || ...
                    strcmp(key(L(i).experiment), key(ex))
                out = L(i).value;  return
            end
        end
    case 'is_multi'
        out = is_multi(mat_name(varargin{1}));
    case 'experiment'
        out = cur_exp();
    case 'key'
        out = key(varargin{1});
    otherwise
        error('apat_avg_mat: unknown action %s', action);
end
end


function e = cur_exp()
e = '';
try
    if isappdata(0, 'APAT_experiment'), e = char(getappdata(0, 'APAT_experiment')); end
catch
end
end


function k = key(name)
k = matlab.lang.makeValidName(char(name));
end


function f = mat_name(f)
f = char(f);
[~, ~, e] = fileparts(f);
if ~strcmpi(e, '.mat'), f = [f '.mat']; end
end


function tf = is_multi(file)
tf = false;
try
    if ~exist(file, 'file'), return; end
    w = whos('-file', file);
    tf = any(strcmp({w.name}, 'experiments'));
catch
end
end


function do_save(file, var, val, ex)
try
    d = fileparts(file);
    if ~isempty(d) && ~exist(d, 'dir'), mkdir(d); end
    if isempty(ex)                                     % no Experiment: old plain layout
        S = struct();  S.(var) = val;
        save(file, '-struct', 'S');
        return
    end
    S = struct();
    if is_multi(file), S = load(file); end            % keep the other Experiments
    if ~isfield(S, var) || ~isstruct(S.(var)) || ~isscalar(S.(var)), S.(var) = struct(); end
    S.(var).(key(ex)) = val;
    E = {};
    if isfield(S, 'experiments'), E = cellstr(S.experiments); E = E(:)'; end
    if ~any(strcmp(E, ex)), E{end+1} = ex; end
    S.experiments = E;
    save(file, '-struct', 'S');
catch ME
    warning('APAT:avgMat', 'Could not save %s: %s', file, ME.message);
end
end


function do_set_field(file, var, fld, val, ex)
try
    if ~exist(file, 'file'), return; end
    w = whos('-file', file);
    if ~any(strcmp({w.name}, var)), return; end
    S = load(file, var);
    if is_multi(file) && ~isempty(ex)
        k = key(ex);
        if ~isfield(S.(var), k) || ~isstruct(S.(var).(k)), return; end
        S.(var).(k).(fld) = val;
    else
        if ~isstruct(S.(var)), return; end
        S.(var).(fld) = val;
    end
    save(file, '-struct', 'S', var, '-append');
catch ME
    warning('APAT:avgMat', 'Could not update %s: %s', file, ME.message);
end
end


function L = do_load(file, var)
L = struct('experiment', {}, 'value', {});
try
    if ~exist(file, 'file'), return; end
    w = whos('-file', file);
    if ~any(strcmp({w.name}, var)), return; end
    if is_multi(file)
        S = load(file, var, 'experiments');
        E = cellstr(S.experiments);
        f = fieldnames(S.(var));
        for i = 1:numel(E)                               % listed order first
            k = key(E{i});
            if isfield(S.(var), k), L(end+1) = struct('experiment', E{i}, 'value', {S.(var).(k)}); end %#ok<AGROW>
        end
        known = cellfun(@key, E, 'UniformOutput', false);
        for i = 1:numel(f)                               % fields not listed (should not happen)
            if ~any(strcmp(known, f{i})), L(end+1) = struct('experiment', f{i}, 'value', {S.(var).(f{i})}); end %#ok<AGROW>
        end
    else
        S = load(file, var);
        L(1) = struct('experiment', '', 'value', {S.(var)});
    end
catch
    L = struct('experiment', {}, 'value', {});
end
end
