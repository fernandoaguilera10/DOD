function sorted = sort_tab_labels(labels)
%SORT_TAB_LABELS  Sort tab labels: known condition names first, then numerically.
cond_order = {'pre','Baseline','post','D3','D7','D14','D30'};
n   = numel(labels);
idx = nan(1, n);
for k = 1:n
    ci = find(strcmpi(labels{k}, cond_order), 1);
    if ~isempty(ci)
        idx(k) = ci;
    else
        num = regexp(labels{k}, '[\d\.]+', 'match', 'once');
        if ~isempty(num)
            idx(k) = str2double(num) + 100;
        else
            idx(k) = 200;
        end
    end
end
[~, si] = sort(idx);
sorted  = labels(si);
end
