function file = apat_write_csv(T, file, keep_by)
%APAT_WRITE_CSV  Write a table (or struct) as a CSV file for other software.
%   file = apat_write_csv(T, file)
%   file = apat_write_csv(T, file, keep_by)
%     keep_by  column name (e.g. 'Experiment'): rows of an existing file
%           whose keep_by value is NOT in T are kept (read back as text),
%           so one file collects several Experiments; T's values replace
%           the old rows of theirs. Blocks keep the order of the old file
%           (new values appended). An old file without that column is
%           replaced.
%     T     table, or struct (struct array / scalar struct of equal-length
%           columns) converted with struct2table
%     file  full path (.csv added when missing); folders are created
%   Cells are written analysis-ready: numbers as plain text (%.10g, no
%   thousands separators), NaN as an empty cell (missing), logicals as
%   true / false. Returns the written file ('' when T is empty or writing
%   failed). Never throws: a failed write only prints a warning (saves are
%   best-effort, as the figure / .mat saves).
if nargin < 2 || isempty(file), file = ''; return; end
if nargin < 3, keep_by = ''; end
file = char(file);
[d, ~, e] = fileparts(file);
if ~strcmpi(e, '.csv'), file = [file '.csv']; end
try
    if isstruct(T)
        try
            T = struct2table(T);
        catch
            T = struct2table(T, 'AsArray', true);
        end
    end
    if ~istable(T) || width(T) == 0 || height(T) == 0, file = ''; return; end
    if ~isempty(d) && ~exist(d, 'dir'), mkdir(d); end
    C = csv_cells(T);
    if ~isempty(keep_by) && exist(file, 'file') && ismember(keep_by, C.Properties.VariableNames)
        C = merge_old(C, file, keep_by);
    end
    writetable(C, file);
catch ME
    warning('APAT:writeCsv', 'Could not write %s: %s', file, ME.message);
    file = '';
end
end


function T = csv_cells(T)
% numeric → text with NaN as '' (missing), logical → 'true' / 'false'
vn = T.Properties.VariableNames;
for i = 1:numel(vn)
    v = T.(vn{i});
    if islogical(v) && size(v, 2) == 1
        c = repmat({'false'}, size(v, 1), 1);  c(v) = {'true'};
        T.(vn{i}) = c;
    elseif isnumeric(v) && size(v, 2) == 1
        v = double(v);
        c = cellstr(compose('%.10g', v));
        c(isnan(v)) = {''};
        T.(vn{i}) = c;
    end
end
end


function C = merge_old(C, file, by)
% rows of the existing file for other values of column `by` + C (all text)
try
    o = detectImportOptions(file, 'FileType', 'text', 'Delimiter', ',');
    o.VariableNamingRule = 'preserve';
    o.VariableNamesLine = 1;  o.DataLines = [2 Inf];
    o = setvartype(o, o.VariableNames, 'char');
    o = setvaropts(o, o.VariableNames, 'WhitespaceRule', 'preserve');
    O = readtable(file, o);
catch
    return
end
if ~istable(O) || height(O) == 0 || ~ismember(by, O.Properties.VariableNames), return; end
vo = cellstr(O.(by));  vn = cellstr(C.(by));
if all(ismember(vo, vn)), return; end
names = [C.Properties.VariableNames, setdiff(O.Properties.VariableNames, C.Properties.VariableNames, 'stable')];
O = fill_cols(O, names);  C = fill_cols(C, names);
order = unique([vo(:); vn(:)], 'stable');
B = cell(numel(order), 1);
for i = 1:numel(order)
    if any(strcmp(vn, order{i})), B{i} = C(strcmp(vn, order{i}), :);
    else,                        B{i} = O(strcmp(vo, order{i}), :); end
end
C = vertcat(B{:});
end


function T = fill_cols(T, names)
% every column text; missing columns '' ; columns in the order of names
vn = T.Properties.VariableNames;
for i = 1:numel(vn)
    v = T.(vn{i});
    if isstring(v), v = cellstr(v); end
    if ~iscell(v), v = cellstr(string(v)); end
    v(cellfun(@(x) ~ischar(x), v)) = {''};
    T.(vn{i}) = v;
end
for m = setdiff(names, vn, 'stable')
    T.(m{1}) = repmat({''}, height(T), 1);
end
T = T(:, names);
end
