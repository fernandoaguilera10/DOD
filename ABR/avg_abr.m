function [average,idx] = avg_abr(x,y,Chins2Run,Conds2Run,all_Conds2Run,counter,colors,shapes,idx_plot_relative,analysis_type,peak_analysis)
if isempty(idx_plot_relative)
    conds = length(all_Conds2Run);
elseif ~isempty(idx_plot_relative)
    conds = length(all_Conds2Run)-1;
end
if conds < 1
    uiwait(msgbox('ERROR: Must have at least 2 conditions to do comparison','Conditions to Run','error'));
    return
end
if strcmp(analysis_type,'Thresholds')
    avg_x{1,conds} = [];
    avg_y{1,conds} = [];
    all_y{1,conds} = [];
    y_std{1,conds} = [];
    threshold_click{1,conds} = [];
    threshold_500{1,conds} = [];
    threshold_1000{1,conds} = [];
    threshold_2000{1,conds} = [];
    threshold_4000{1,conds} = [];
    threshold_8000{1,conds} = [];
    idx = ~cellfun(@isempty,y);    % find if data file is present: rows = Chins2Run, cols = Conds2Run
    if isempty(idx_plot_relative)   % plot all timepoints, including baseline
        for cols = 1:length(all_Conds2Run)
            for rows = 1:length(Chins2Run)
                avg_x{1,cols} = mean([avg_x{1,cols}; x{rows, cols}],1);
                avg_y{1,cols} = mean([avg_y{1,cols}; y{rows, cols}],1);
                all_y{rows,cols} = y{rows, cols};
                ne_mask = ~cellfun(@isempty, all_y(:,cols));
                if sum(ne_mask) > 1
                    y_std{1,cols} = std(cell2mat(all_y(ne_mask,cols)), 0, 1);
                end
                % check if data is present for a given timepoint and subject
                if idx(rows,cols) == 1
                    % Plot individual traces with average
                    fh_thr_avg = findobj('Type','figure','Tag','APAT_thr_avg');
                    if isempty(fh_thr_avg)
                        fh_thr_avg = figure('Name','ABR Thresholds Average', ...
                            'NumberTitle','off','Tag','APAT_thr_avg');
                    else
                        figure(fh_thr_avg(1));
                    end
                    hold on;
                    freq = 1:length(x{rows,cols});
                    freq_threshold = [nan,  y{rows,cols}(2:end)];
                    freq_click = [y{rows,cols}(1),nan(1,length(freq)-1)];
                    n_f = length(y{rows,cols});
                    if n_f >= 1, threshold_click{rows,cols} = y{rows,cols}(1); end
                    if n_f >= 2, threshold_500{rows,cols} = y{rows,cols}(2); end
                    if n_f >= 3, threshold_1000{rows,cols} = y{rows,cols}(3); end
                    if n_f >= 4, threshold_2000{rows,cols} = y{rows,cols}(4); end
                    if n_f >= 5, threshold_4000{rows,cols} = y{rows,cols}(5); end
                    if n_f >= 6, threshold_8000{rows,cols} = y{rows,cols}(6); end
                end
            end
        end
    elseif ~isempty(idx_plot_relative)
        for cols = 1:length(all_Conds2Run)
            for rows = 1:length(Chins2Run)
                if cols ~= idx_plot_relative && idx(rows,cols) == 1
                    avg_x{1,cols-1} = mean([avg_x{1,cols-1}; x{rows, cols}],1);
                    avg_y{1,cols-1} = mean([avg_y{1,cols-1}; y{rows, cols}-y{rows, idx_plot_relative}],1);
                    all_y{rows,cols-1} = y{rows, cols}-y{rows, idx_plot_relative};
                    ne_mask = ~cellfun(@isempty, all_y(:,cols-1));
                    if sum(ne_mask) > 1
                        y_std{1,cols-1} = std(cell2mat(all_y(ne_mask,cols-1)), 0, 1);
                    end
                    % check if data is present for a given timepoint and subject
                    if idx(rows,cols) == 1
                        % Plot individual traces with average
                        fh_thr_avg = findobj('Type','figure','Tag','APAT_thr_avg');
                        if isempty(fh_thr_avg)
                            fh_thr_avg = figure('Name','ABR Thresholds Average', ...
                                'NumberTitle','off','Tag','APAT_thr_avg');
                        else
                            figure(fh_thr_avg(1));
                        end
                        hold on;
                        freq = 1:length(x{rows,cols});
                        freq_threshold = [nan,  y{rows,cols}(2:end)-y{rows,idx_plot_relative}(2:end)];
                        freq_click = [y{rows,cols}(1)-y{rows,idx_plot_relative}(1),nan(1,length(freq)-1)];
                        n_f = length(y{rows,cols});
                        if n_f >= 1, threshold_click{rows,cols-1} = y{rows,cols}(1)-y{rows,idx_plot_relative}(1); end
                        if n_f >= 2, threshold_500{rows,cols-1} = y{rows,cols}(2)-y{rows,idx_plot_relative}(2); end
                        if n_f >= 3, threshold_1000{rows,cols-1} = y{rows,cols}(3)-y{rows,idx_plot_relative}(3); end
                        if n_f >= 4, threshold_2000{rows,cols-1} = y{rows,cols}(4)-y{rows,idx_plot_relative}(4); end
                        if n_f >= 5, threshold_4000{rows,cols-1} = y{rows,cols}(5)-y{rows,idx_plot_relative}(5); end
                        if n_f >= 6, threshold_8000{rows,cols-1} = y{rows,cols}(6)-y{rows,idx_plot_relative}(6); end
                    end
                end
            end
        end
    end
    average.x = avg_x;
    average.y = avg_y;
    average.y_std = y_std;
    average.all_y = all_y;
    average.threshold_click = threshold_click;
    average.threshold_500 = threshold_500;
    average.threshold_1000 = threshold_1000;
    average.threshold_2000 = threshold_2000;
    average.threshold_4000 = threshold_4000;
    average.threshold_8000 = threshold_8000;

elseif strcmp(analysis_type,'Peaks')
    avg_x{1,conds}       = [];
    peak{1,conds}        = [];
    avg_w1{1,conds}      = [];  avg_w2{1,conds}      = [];  avg_w3{1,conds}      = [];
    avg_w4{1,conds}      = [];  avg_w5{1,conds}      = [];  avg_w1and5{1,conds}  = [];
    all_x_subj{1,conds}  = [];
    all_w1{1,conds}      = [];  all_w2{1,conds}      = [];  all_w3{1,conds}      = [];
    all_w4{1,conds}      = [];  all_w5{1,conds}      = [];  all_w1and5{1,conds}  = [];
    w1_std{1,conds}      = [];  w2_std{1,conds}      = [];  w3_std{1,conds}      = [];
    w4_std{1,conds}      = [];  w5_std{1,conds}      = [];  w1and5_std{1,conds}  = [];
    idx = ~cellfun(@isempty,y);

    if isempty(idx_plot_relative)
        % ── Phase 1: extract per-subject peaks at their native levels ──────
        for cols = 1:length(all_Conds2Run)
            for rows = 1:length(Chins2Run)
                if isempty(x{rows,cols}) || isempty(y{rows,cols}), continue; end
                for i = 1:2:width(y{rows,cols})-1
                    if strcmp(peak_analysis,'Amplitude')
                        peak{rows,cols}(:,(i+1)/2) = y{rows,cols}(:,i) - y{rows,cols}(:,i+1);
                    elseif strcmp(peak_analysis,'Latency')
                        peak{rows,cols}(:,(i+1)/2) = y{rows,cols}(:,i);
                    end
                end
                [~, idx_peaks] = unique(round(x{rows,cols})); idx_peaks = flip(idx_peaks);
                if isempty(idx_peaks), continue; end
                all_x_subj{rows,cols} = x{rows,cols}(idx_peaks,:);
                nw = size(peak{rows,cols}, 2);
                if nw >= 1, all_w1{rows,cols}     = peak{rows,cols}(idx_peaks,1); end
                if nw >= 2, all_w2{rows,cols}     = peak{rows,cols}(idx_peaks,2); end
                if nw >= 3, all_w3{rows,cols}     = peak{rows,cols}(idx_peaks,3); end
                if nw >= 4, all_w4{rows,cols}     = peak{rows,cols}(idx_peaks,4); end
                if nw >= 5
                    all_w5{rows,cols}     = peak{rows,cols}(idx_peaks,5);
                    all_w1and5{rows,cols} = peak{rows,cols}(idx_peaks,1) ./ peak{rows,cols}(idx_peaks,5);
                end
            end
        end
        % ── Phase 2: level-aligned averages across subjects ─────────────
        for cols = 1:length(all_Conds2Run)
            [avg_x{1,cols}, avg_w1{1,cols}, avg_w2{1,cols}, avg_w3{1,cols}, ...
             avg_w4{1,cols}, avg_w5{1,cols}, avg_w1and5{1,cols}, ...
             w1_std{1,cols}, w2_std{1,cols}, w3_std{1,cols}, ...
             w4_std{1,cols}, w5_std{1,cols}, w1and5_std{1,cols}] = ...
                level_align_avg(all_x_subj(:,cols), all_w1(:,cols), all_w2(:,cols), ...
                                all_w3(:,cols), all_w4(:,cols), all_w5(:,cols), all_w1and5(:,cols));
        end

    elseif ~isempty(idx_plot_relative)
        % ── Phase 1a: compute peaks for ALL conditions (baseline needed) ──
        for cols = 1:length(all_Conds2Run)
            for rows = 1:length(Chins2Run)
                if isempty(x{rows,cols}) || isempty(y{rows,cols}), continue; end
                for i = 1:2:width(y{rows,cols})-1
                    if strcmp(peak_analysis,'Amplitude')
                        peak{rows,cols}(:,(i+1)/2) = y{rows,cols}(:,i) - y{rows,cols}(:,i+1);
                    elseif strcmp(peak_analysis,'Latency')
                        peak{rows,cols}(:,(i+1)/2) = y{rows,cols}(:,i);
                    end
                end
            end
        end
        % ── Phase 1b: differences at levels common to both conditions ────
        out_col = 0;
        for cols = 1:length(all_Conds2Run)
            if cols == idx_plot_relative, continue; end
            out_col = out_col + 1;
            for rows = 1:length(Chins2Run)
                if idx(rows,cols) ~= 1 || idx(rows,idx_plot_relative) ~= 1, continue; end
                if isempty(x{rows,cols}) || isempty(x{rows,idx_plot_relative}), continue; end
                [~, idx_pc] = unique(round(x{rows,cols}));              idx_pc = flip(idx_pc);
                [~, idx_pb] = unique(round(x{rows,idx_plot_relative})); idx_pb = flip(idx_pb);
                lev_c = round(x{rows,cols}(idx_pc));
                lev_b = round(x{rows,idx_plot_relative}(idx_pb));
                [~, ia, ib] = intersect(lev_c, lev_b);   % common levels, ascending
                if isempty(ia), continue; end
                all_x_subj{rows,out_col} = lev_c(ia);    % ascending order, aligned with diffs
                nw = min(size(peak{rows,cols},2), size(peak{rows,idx_plot_relative},2));
                if nw >= 1
                    all_w1{rows,out_col} = peak{rows,cols}(idx_pc(ia),1) - peak{rows,idx_plot_relative}(idx_pb(ib),1);
                end
                if nw >= 2
                    all_w2{rows,out_col} = peak{rows,cols}(idx_pc(ia),2) - peak{rows,idx_plot_relative}(idx_pb(ib),2);
                end
                if nw >= 3
                    all_w3{rows,out_col} = peak{rows,cols}(idx_pc(ia),3) - peak{rows,idx_plot_relative}(idx_pb(ib),3);
                end
                if nw >= 4
                    all_w4{rows,out_col} = peak{rows,cols}(idx_pc(ia),4) - peak{rows,idx_plot_relative}(idx_pb(ib),4);
                end
                if nw >= 5
                    all_w5{rows,out_col}     = peak{rows,cols}(idx_pc(ia),5) - peak{rows,idx_plot_relative}(idx_pb(ib),5);
                    all_w1and5{rows,out_col} = (peak{rows,cols}(idx_pc(ia),1) ./ peak{rows,cols}(idx_pc(ia),5)) - ...
                                               (peak{rows,idx_plot_relative}(idx_pb(ib),1) ./ peak{rows,idx_plot_relative}(idx_pb(ib),5));
                end
            end
        end
        % ── Phase 2: level-aligned averages ─────────────────────────────
        for out_col = 1:conds
            [avg_x{1,out_col}, avg_w1{1,out_col}, avg_w2{1,out_col}, avg_w3{1,out_col}, ...
             avg_w4{1,out_col}, avg_w5{1,out_col}, avg_w1and5{1,out_col}, ...
             w1_std{1,out_col}, w2_std{1,out_col}, w3_std{1,out_col}, ...
             w4_std{1,out_col}, w5_std{1,out_col}, w1and5_std{1,out_col}] = ...
                level_align_avg(all_x_subj(:,out_col), all_w1(:,out_col), all_w2(:,out_col), ...
                                all_w3(:,out_col), all_w4(:,out_col), all_w5(:,out_col), all_w1and5(:,out_col));
        end
    end

    average.x         = avg_x;
    average.w1        = avg_w1;
    average.w2        = avg_w2;
    average.w3        = avg_w3;
    average.w4        = avg_w4;
    average.w5        = avg_w5;
    average.w1and5    = avg_w1and5;
    average.w1_std    = w1_std;
    average.w2_std    = w2_std;
    average.w3_std    = w3_std;
    average.w4_std    = w4_std;
    average.w5_std    = w5_std;
    average.w1and5_std = w1and5_std;
    average.all_w1    = all_w1;
    average.all_w2    = all_w2;
    average.all_w3    = all_w3;
    average.all_w4    = all_w4;
    average.all_w5    = all_w5;
    average.all_w1and5 = all_w1and5;
end
end

% ── Local helpers ──────────────────────────────────────────────────────────

function [avg_x, avg_w1, avg_w2, avg_w3, avg_w4, avg_w5, avg_w1and5, ...
          s1, s2, s3, s4, s5, s1and5] = level_align_avg(x_cells, w1c, w2c, w3c, w4c, w5c, w1and5c)
% Average peak data across subjects with proper level alignment.
% Subjects may have different dB SPL level sets or different frequencies;
% data is aligned by level VALUE (not index position) before averaging.
all_lvls = [];
for k = 1:numel(x_cells)
    if ~isempty(x_cells{k})
        all_lvls = union(all_lvls, round(x_cells{k}(:))');
    end
end
if isempty(all_lvls)
    [avg_x, avg_w1, avg_w2, avg_w3, avg_w4, avg_w5, avg_w1and5, ...
     s1, s2, s3, s4, s5, s1and5] = deal([]);
    return;
end
all_lvls = flip(sort(all_lvls(:)));   % descending (high → low, standard ABR sweep)
n = numel(all_lvls);
m = numel(x_cells);
M1  = NaN(n,m); M2  = NaN(n,m); M3  = NaN(n,m);
M4  = NaN(n,m); M5  = NaN(n,m); M15 = NaN(n,m);
for k = 1:m
    if isempty(x_cells{k}), continue; end
    lv = round(x_cells{k}(:));
    for li = 1:numel(lv)
        pos = find(all_lvls == lv(li), 1);
        if isempty(pos), continue; end
        if ~isempty(w1c{k})     && numel(w1c{k})     >= li, M1(pos,k)  = w1c{k}(li);     end
        if ~isempty(w2c{k})     && numel(w2c{k})     >= li, M2(pos,k)  = w2c{k}(li);     end
        if ~isempty(w3c{k})     && numel(w3c{k})     >= li, M3(pos,k)  = w3c{k}(li);     end
        if ~isempty(w4c{k})     && numel(w4c{k})     >= li, M4(pos,k)  = w4c{k}(li);     end
        if ~isempty(w5c{k})     && numel(w5c{k})     >= li, M5(pos,k)  = w5c{k}(li);     end
        if ~isempty(w1and5c{k}) && numel(w1and5c{k}) >= li, M15(pos,k) = w1and5c{k}(li); end
    end
end
avg_x      = all_lvls;
avg_w1     = nanmean(M1,2);  s1     = nanstd(M1,0,2);
avg_w2     = nanmean(M2,2);  s2     = nanstd(M2,0,2);
avg_w3     = nanmean(M3,2);  s3     = nanstd(M3,0,2);
avg_w4     = nanmean(M4,2);  s4     = nanstd(M4,0,2);
avg_w5     = nanmean(M5,2);  s5     = nanstd(M5,0,2);
avg_w1and5 = nanmean(M15,2); s1and5 = nanstd(M15,0,2);
end
