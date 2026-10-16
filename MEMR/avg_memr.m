function [average,idx] = avg_memr(elicitor,deltapow,threshold,Chins2Run,Conds2Run,all_Conds2Run,colors,shapes,idx_plot_relative) %#ok<INUSL>
% Group mean / SD per condition (plots are drawn by plot_avg_memr).
if isempty(idx_plot_relative)
    conds = length(all_Conds2Run);
elseif ~isempty(idx_plot_relative)
    conds = length(all_Conds2Run)-1;
end
if conds < 1
    try, apat_run_error('error', 'Must have at least 2 conditions to do a comparison (relative mode) — no group average.', 'average'); catch, end
    average = struct();  idx = [];
    return
end
avg_elicitor{1,conds} = [];
avg_deltapow{1,conds} = [];
avg_threshold{1,conds} = [];
all_deltapow{1,conds} = [];
deltapow_std{1,conds} = [];
threshold_std{1,conds} = [];
all_threshold{1,conds} = [];
idx = ~cellfun(@isempty,deltapow);    % find if data file is present: rows = Chins2Run, cols = Conds2Run
if isempty(idx_plot_relative)   % plot all timepoints, including baseline
    for cols = 1:length(all_Conds2Run)
        for rows = 1:length(Chins2Run)
            avg_elicitor{1,cols} = [avg_elicitor{1,cols}; elicitor{rows, cols}];
            avg_deltapow{1,cols} = [avg_deltapow{1,cols}; deltapow{rows, cols}];
            avg_threshold{1,cols} = [avg_threshold{1,cols}; threshold{rows, cols}];
            all_deltapow{rows,cols} = deltapow{rows, cols};
            deltapow_std{1,cols} = std(cell2mat(all_deltapow(:,cols)),0,1);
            all_threshold{rows,cols} = threshold{rows, cols};
            threshold_std{1,cols} = std(cell2mat(all_threshold(:,cols)),0,1);
        end
    end
elseif ~isempty(idx_plot_relative)
    for cols = 1:length(all_Conds2Run)
        for rows = 1:length(Chins2Run)
            if cols ~= idx_plot_relative && idx(rows,cols) == 1
                avg_elicitor{1,cols-1} = [avg_elicitor{1,cols-1}; elicitor{rows, cols}];
                avg_deltapow{1,cols-1} = [avg_deltapow{1,cols-1}; deltapow{rows, cols}-deltapow{rows, idx_plot_relative}];
                avg_threshold{1,cols-1} = [avg_threshold{1,cols-1}; threshold{rows, cols}-threshold{rows, idx_plot_relative}];    
                all_deltapow{rows,cols-1} = deltapow{rows, cols}-deltapow{rows, idx_plot_relative};
                deltapow_std{1,cols-1} = std(cell2mat(all_deltapow(:,cols-1)),0,1);
                all_threshold{rows,cols-1} = threshold{rows, cols}-threshold{rows, idx_plot_relative};
                threshold_std{1,cols-1} = std(cell2mat(all_threshold(:,cols-1)),0,1);
            end
        end
    end
end
avg_elicitor  = stack_mean(avg_elicitor, false);
avg_deltapow  = stack_mean(avg_deltapow, false);
avg_threshold = stack_mean(avg_threshold, false);
average.elicitor = avg_elicitor;
average.deltapow = avg_deltapow;
average.deltapow_std = deltapow_std;
average.all_deltapow = all_deltapow;
average.all_thresholds = all_threshold;
average.threshold = avg_threshold;
average.threshold_std = threshold_std;
end

function c = stack_mean(c, omit_nan)
% Equal-weight group mean. Each cell holds one row per subject (stacked in
% the loop above); average them in one step so every subject counts 1/N.
% (Replaces the old running mean([avg; new]), which weighted later subjects
% more: a/4 + b/4 + c/2 for three subjects.)
for k = 1:numel(c)
    if isempty(c{k}), continue; end
    if omit_nan, c{k} = mean(c{k}, 1, 'omitnan'); else, c{k} = mean(c{k}, 1); end
end
end
