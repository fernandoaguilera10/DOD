function out = apat_sex(action, varargin)
%APAT_SEX  Subject sex from the chinroster (Sex column, right after Subject).
%
%   apat_sex('set', map)     keep map (containers.Map subject → 'M' / 'F' /
%                            '' as written in the roster, trimmed) in root
%                            appdata 'APAT_subject_sex' for the run
%                            (analysis_run, read once from the sheet).
%                            map = [] clears it.
%   s = apat_sex('get', subj)  that subject's sex (char), '' if unknown.
%   M = apat_sex('read', C)  map from a readcell() roster sheet C: header
%                            row = the first cell reading "Sex" (any case);
%                            subject IDs in column 1 below it.
%   Never throws.
out = '';
try
    switch action
        case 'set'
            m = [];  if ~isempty(varargin), m = varargin{1}; end
            if isa(m, 'containers.Map')
                setappdata(0, 'APAT_subject_sex', m);
            elseif isappdata(0, 'APAT_subject_sex')
                rmappdata(0, 'APAT_subject_sex');
            end
        case 'get'
            subj = strtrim(char(varargin{1}));
            if ~isappdata(0, 'APAT_subject_sex'), return; end
            m = getappdata(0, 'APAT_subject_sex');
            if isa(m, 'containers.Map') && isKey(m, subj), out = char(m(subj)); end
        case 'read'
            out = read_map(varargin{1});
    end
catch
end
end


function m = read_map(C)
m = containers.Map('KeyType','char','ValueType','any');
if ~iscell(C) || isempty(C), return; end
is_sex = cellfun(@(v) (ischar(v) || isstring(v)) && isscalar(string(v)) && strcmpi(strtrim(char(v)), 'Sex'), C);
[r, c] = find(is_sex, 1);
if isempty(r), return; end
for i = r+1:size(C,1)
    id = C{i,1};
    if isstring(id), id = char(id); end
    if ~ischar(id) || isempty(strtrim(id)), continue; end
    sx = C{i,c};
    if isstring(sx), sx = char(sx); end
    if ischar(sx), sx = strtrim(sx); else, sx = ''; end
    m(strtrim(id)) = sx;
end
end
