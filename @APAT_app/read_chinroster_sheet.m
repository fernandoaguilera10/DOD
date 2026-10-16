function [subjects, cond_paths, cond_labels] = read_chinroster_sheet(filepath, sheet)
%READ_CHINROSTER_SHEET  Static method: parse subjects and condition paths from a chinroster sheet.
subjects    = {};
cond_paths  = {};
cond_labels = {};
try
    data = readcell(filepath,'Sheet',sheet);
catch
    return
end
miss_idx = cellfun(@(x) any(isa(x,'missing')), data);
data(miss_idx) = {NaN};
[nrows, ncols] = size(data);
header_row     = 0;
baseline_cols  = [];
for i = 1:nrows
    for j = 1:ncols
        val = data{i,j};
        if ischar(val) && (strcmpi(val,'Baseline') || strcmp(val,'B'))
            if header_row == 0, header_row = i; end
            baseline_cols(end+1) = j; %#ok<AGROW>
        end
    end
end
if header_row > 0 && ~isempty(baseline_cols)
    c1 = baseline_cols(1);
    c2 = ncols;
    if numel(baseline_cols) >= 2, c2 = baseline_cols(2) - 1; end
    for j = c1:c2
        val = data{header_row,j};
        if ischar(val) && ~isempty(strtrim(val))
            cond_labels{end+1} = val; %#ok<AGROW>
            if strcmpi(val,'Baseline') || strcmp(val,'B')
                cond_paths{end+1} = strcat('pre',filesep,val); %#ok<AGROW>
            else
                cond_paths{end+1} = strcat('post',filesep,val); %#ok<AGROW>
            end
        end
    end
end
for i = 1:nrows
    if i == header_row, continue; end
    val = data{i,1};
    if ischar(val) && ~isempty(strtrim(val)) && ~isempty(regexp(strtrim(val),'\d','once'))
        subjects{end+1} = strtrim(val); %#ok<AGROW>
    end
end
subjects = subjects(:);
end
