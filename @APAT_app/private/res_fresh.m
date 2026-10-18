function [key, stamp] = res_fresh(app, exp1, exp2, cfg, chins, conds, sheet, roster_file)
%RES_FRESH  What an analysis' saved Results (shared/apat_res_store) depend
%   on, so Run Analysis can load them instead of running when nothing
%   changed (user, Oct 17 2026 — speed):
%     key    settings fingerprint (uint8): cfg without the run plumbing
%            (callbacks, peak editor, CSV flags; exclusions and plot
%            defaults stay in), subjects, conditions, Experiment
%     stamp  newest of: this analysis' result files and raw data files of
%            these subjects (its own file patterns only — EFR RAM results do
%            not invalidate EFR dAM), the roster file and the code that makes
%            the figures (measure folders ABR / EFR / OAE / MEMR and shared/;
%            not the app's own display code in @APAT_app)
%   Saved Results count as current when they were saved after the stamp
%   (res_load: meta.time >= stamp).
%   RunButtonPushed>run_one compares both with the saved file (res_load) and
%   stores them when it saves. Never throws (key = [] → never fresh).
key = [];  stamp = 0;
try
    c = cfg;
    for f = {'embed_fns','peak_ui','csv_keep','reanalyze','blind'}
        if isfield(c, f{1}), c = rmfield(c, f{1}); end
    end
    key = getByteStreamFromArray(struct('cfg', plain(c), 'chins', {cellstr(chins(:)')}, ...
        'conds', {cellstr(conds(:)')}, 'sheet', char(sheet)));
    root = strtrim(app.RootDirField.Value);
    [op, dp] = patterns(exp1, exp2);
    for i = 1:numel(chins)
        stamp = max(stamp, newest(fullfile(root, 'Analysis', exp1, chins{i}), op));
        stamp = max(stamp, newest(fullfile(root, 'Data', chins{i}, exp1), dp));
    end
    if exist(roster_file, 'file') == 2, L = dir(roster_file);  stamp = max(stamp, L(1).datenum); end
    code_root = fileparts(fileparts(fileparts(mfilename('fullpath'))));
    for sub = {'ABR','EFR','OAE','MEMR','shared'}
        stamp = max(stamp, newest(fullfile(code_root, sub{1}), '*.m'));
    end
catch
    key = [];
end
end


function t = newest(d, pat)
t = 0;
if ~exist(d, 'dir'), return; end
L = dir(fullfile(d, '**', pat));
L = L(~[L.isdir] & ~startsWith({L.name}, '._'));
if ~isempty(L), t = max([L.datenum]); end
end


function [op, dp] = patterns(exp1, exp2)
% result / raw-data file patterns (as analysis_run>get_file_patterns)
switch exp1
    case 'ABR'
        dp = '*ABR*.mat';
        switch exp2
            case 'Thresholds', op = '*ABRthresholds*.mat';
            case 'Peaks',      op = '*ABRpeaks_dtw*.mat';
            otherwise,         op = ['*ABR' exp2 '*.mat'];
        end
    case 'EFR'
        op = ['*EFR_' exp2 '*.mat'];
        switch exp2
            case 'dAM', dp = '*FFR_*AMFM*.mat';
            case 'RAM', dp = '*FFR_RAM*.mat';
            otherwise,  dp = ['*FFR_' exp2 '*.mat'];
        end
    case 'OAE'
        op = ['*' exp2 '*.mat'];  dp = op;
    case 'MEMR'
        dp = '*MEMR*.mat';
        if isempty(exp2), op = '*MEMR*.mat'; else, op = '*_MX_*.mat'; end
    otherwise
        op = ['*' exp1 '*.mat'];  dp = op;
end
end


function v = plain(v)
% data only (handles / objects removed): a stable fingerprint
if isstruct(v)
    f = fieldnames(v);
    for k = 1:numel(f)
        for j = 1:numel(v)
            x = v(j).(f{k});
            if isa(x, 'function_handle') || (isobject(x) && ~isstring(x)), v(j).(f{k}) = [];
            else, v(j).(f{k}) = plain(x); end
        end
    end
elseif iscell(v)
    for k = 1:numel(v), v{k} = plain(v{k}); end
elseif isa(v, 'function_handle') || (isobject(v) && ~isstring(v))
    v = [];
end
end
