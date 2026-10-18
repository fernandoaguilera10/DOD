function out = apat_table_fit(action, varargin)
%APAT_TABLE_FIT  Keep the text of the value tables drawn next to the plots
%   (OAE band averages, EFR harmonic sums, ABR thresholds) inside its
%   column, however many conditions / sub-columns there are: column
%   headers no longer run into each other (user, Oct 17 2026).
%
%   fs = apat_table_fit('fs', ax, strs, fs, maxw, fs_min [, weight])
%       Largest font size <= FS (and >= FS_MIN) at which every string in
%       STRS is at most MAXW wide (data units of AX; tables use XLim [0 1]).
%   apat_table_fit('text', h, maxw, fs_min [, max_lines])
%       Fit text object H into MAXW: smaller font first (down to FS_MIN),
%       then two lines split at a space / '-' / '_' (MAX_LINES 2, default),
%       then shortened with '…'. The full text stays in the figure as the
%       object's UserData.
%   Widths are measured with the text extents (a 6 % margin is kept so the
%   embedded Results view, slightly different in size, still fits). Never
%   throws: on failure the text is left as it was.
out = [];
try
    switch action
        case 'fs',   out = fit_fs(varargin{:});
        case 'text', fit_text(varargin{:});
    end
catch
    if strcmp(action, 'fs') && numel(varargin) >= 3, out = varargin{3}; end
end
end


function fs = fit_fs(ax, strs, fs, maxw, fs_min, weight)
if nargin < 6 || isempty(weight), weight = 'normal'; end
if ischar(strs), strs = {strs}; end
lim = 0.94 * maxw;
while fs > fs_min && widest(ax, strs, fs, weight) > lim
    fs = fs - 1;
end
end


function fit_text(h, maxw, fs_min, max_lines)
if nargin < 4 || isempty(max_lines), max_lines = 2; end
if ~isgraphics(h), return; end
lim = 0.94 * maxw;
s = h.String;  if iscell(s), s = strjoin(s, ' '); end
s = char(s);
h.UserData = s;                                  % full text (shortened below)
if ext_w(h) <= lim, return; end
fs0 = h.FontSize;
while h.FontSize > fs_min && ext_w(h) > lim      % 1) smaller font
    h.FontSize = h.FontSize - 1;
end
if ext_w(h) <= lim, return; end
if max_lines >= 2                                % 2) two lines (back to a larger font if it fits)
    [a, b] = split2(s);
    if ~isempty(b)
        h.String = {a; b};
        h.FontSize = fs0;
        while h.FontSize > fs_min && ext_w(h) > lim
            h.FontSize = h.FontSize - 1;
        end
        if ext_w(h) <= lim, return; end
        h.String = s;
    end
end
h.FontSize = fs_min;                             % 3) shortened
n = numel(s);
while n > 2 && ext_w(h) > lim
    n = n - 1;
    h.String = [strtrim(s(1:n)) '…'];
end
end


function [a, b] = split2(s)
% split at the break (space, '-', '_', '/') closest to the middle
a = s;  b = '';
k = regexp(s, '[\s\-_/]');
k = k(k > 1 & k < numel(s));
if isempty(k), return; end
[~, i] = min(abs(k - numel(s)/2));
k = k(i);
if isspace(s(k))
    a = strtrim(s(1:k-1));  b = strtrim(s(k+1:end));
else
    a = s(1:k);  b = s(k+1:end);                 % keep the '-' / '_' on the first line
end
end


function w = widest(ax, strs, fs, weight)
w = 0;
for k = 1:numel(strs)
    t = text(ax, 0, 0.5, strs{k}, 'FontSize',fs, 'FontWeight',weight, 'Units','data', ...
        'Visible','off', 'Interpreter','none', 'HandleVisibility','off');
    w = max(w, ext_w(t));
    delete(t);
end
end


function w = ext_w(h)
e = h.Extent;  w = e(3);
end
