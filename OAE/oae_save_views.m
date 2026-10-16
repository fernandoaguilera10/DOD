function keep = oae_save_views(views, o, mode)
%OAE_SAVE_VIEWS  Which scale views to save, from the Setup 'Save files' choice.
%   views  cell of views, each a cell of scales, e.g. {{'EPL'},{'SPL'},{'EPL','SPL'}}
%   keep   logical, one per view: a view is saved when all its scales are
%          chosen. If no view qualifies (e.g. TEOAE with only EPL chosen),
%          the single-scale views that exist are saved.
%   vi = oae_save_views(views, o, 'one')
%          index of the ONE view saved as an image: the kept view with the
%          most scales (EPL + SPL when both are chosen), else the first.
want = {};
if o.save_epl, want{end+1} = 'EPL'; end
if o.save_spl, want{end+1} = 'SPL'; end
keep = cellfun(@(v) all(ismember(v, want)), views);
if ~any(keep), keep = cellfun(@numel, views) == 1; end
if nargin >= 3 && strcmp(mode, 'one')
    n = cellfun(@numel, views);  n(~keep) = -1;
    [~, keep] = max(n);                       % first of the largest kept views
end
end
