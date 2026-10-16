function out = apat_out_dir(kind, varargin)
%APAT_OUT_DIR  Output folders of the APAT Analysis/ tree (one place).
%
%   Layout:
%     Analysis/<Measure>/<Subj>/<pre|post>/<Cond>/   data of that recording
%                                                    (+ its analysis figure)
%     Analysis/<Measure>/<Subj>/                     overlay (Results
%                                                    individual) figures,
%                                                    next to pre/ and post/
%     Analysis/<Measure>/Average/                    group averages of EVERY
%                                                    Experiment (one file per
%                                                    average type; Experiment
%                                                    = CSV column / field of
%                                                    `average`, apat_avg_mat;
%                                                    figures <name>_<EXP>_figure)
%
%   (Oct 16 2026: the Average/<Group>/ subfolders and the Setup "Group:"
%   field are gone. Old results there are still found by 'find'.)
%
%   p = apat_out_dir('all', cond_dir)
%       subject folder (next to pre/ and post/) owning recording folder
%       cond_dir (= <Measure>/<Subj>/<pre|post>/<Cond>). Only the
%       all-conditions figures go here; no combined data file is written
%       (the per-recording files already hold the data).
%   f = apat_out_dir('all_file', cond_dir, name)
%       <subject folder>/<name> (no extension, no suffix: the figure shows
%       one subject's own conditions).
%   p = apat_out_dir('avg', meas_dir)
%       Average folder of measure folder meas_dir (= Analysis/<Measure>).
%   d = apat_out_dir('find', meas_dir, pattern)
%       dir() result of files matching pattern in <meas_dir>/Average, else
%       in any <meas_dir>/Average/<old group>/ folder, else (old layout)
%       meas_dir itself. ._ files are left out.
%   s = apat_out_dir('sanitize', s)  s made folder / file-name safe
switch kind
    case 'all'
        p = strip_sep(varargin{1});
        out = fileparts(fileparts(p));
    case 'all_file'
        p = strip_sep(varargin{1});
        nm = char(varargin{2});      % no group suffix (user, Oct 16)
        out = fullfile(fileparts(fileparts(p)), nm);
    case 'avg'
        out = fullfile(strip_sep(varargin{1}), 'Average');
    case 'find'
        m = strip_sep(varargin{1});  pat = varargin{2};
        out = ls_clean(fullfile(m, 'Average', pat));
        if isempty(out), out = ls_clean(fullfile(m, 'Average', '*', pat)); end   % old Average/<Group>/
        if isempty(out), out = ls_clean(fullfile(m, pat)); end
    case 'sanitize'
        out = sanitize(varargin{1});
    otherwise
        error('apat_out_dir: unknown kind %s', kind);
end
end


function s = sanitize(s)
% folder-safe: letters, digits, - and _ (spaces / others → _), no leading
% or trailing _ / . , at most 64 characters
try, s = char(s); catch, s = ''; end
if isempty(s), s = ''; return; end
s = regexprep(strtrim(s(:)'), '[^A-Za-z0-9_\-]+', '_');
s = regexprep(s, '_+', '_');
s = regexprep(s, '^[_.\-]+|[_.]+$', '');
if numel(s) > 64, s = s(1:64); end
end


function p = strip_sep(p)
p = char(p);
while numel(p) > 1 && any(p(end) == '/\'), p = p(1:end-1); end
end


function d = ls_clean(pat)
d = dir(pat);
if ~isempty(d), d = d(~strncmp({d.name}, '._', 2) & ~[d.isdir]); end
end
