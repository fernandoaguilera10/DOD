%% FIX THIS TO REFLECT EFR!!
function [average,idx] = avg_efr(peaks_locs,peaks,f,plv_env,Chins2Run,Conds2Run,counter,colors,idx_plot_relative)
if isempty(idx_plot_relative)
    conds = length(Conds2Run);
elseif ~isempty(idx_plot_relative)
    conds = length(Conds2Run)-1;
end
if conds < 1
    uiwait(msgbox('ERROR: Must have at least 2 conditions to do comparison','Conditions to Run','error'));
    return
end
avg_peaks_locs{1,conds} = [];
avg_peaks{1,conds} = [];
avg_plv_env{1,conds} = [];
avg_f{1,conds} = [];
avg_ratio{1,conds} = [];
all_peaks{1,conds} = [];
all_ratio{1,conds} = [];
peaks_std{1,conds} = [];
ratio_std{1,conds} = [];
idx_peaks = 1:3;
idx = ~cellfun(@isempty,peaks_locs);    % find if data file is present: rows = Chins2Run, cols = Conds2Run
if isempty(idx_plot_relative)   % plot all timepoints, including baseline
    for cols = 1:length(Conds2Run)
        for rows = 1:length(Chins2Run)
            avg_peaks_locs{1,cols} = nanmean([avg_peaks_locs{1,cols}; peaks_locs{rows, cols}],1);
            avg_peaks{1,cols} = nanmean([avg_peaks{1,cols}; peaks{rows, cols}],1);
            if ~isempty(peaks{rows, cols})
                peak_sum = nansum(peaks{rows, cols}(idx_peaks(end)+1:end))/nansum(peaks{rows, cols}(idx_peaks));
            else
                peak_sum = [];
            end
            avg_ratio{1,cols} = nanmean([avg_ratio{1,cols}; peak_sum],1);
            all_peaks{rows,cols} = peaks{rows, cols};
            all_ratio{rows,cols} = peak_sum;
            peaks_std{1,cols} = nanstd(cell2mat(all_peaks(:,cols)),0,1);
            ratio_std{1,cols} = nanstd(cell2mat(all_ratio(:,cols)),0,1);
            avg_plv_env{1,cols} = mean([avg_plv_env{1,cols}; plv_env{rows, cols}],1);
            avg_f{1,cols} = mean([avg_f{1,cols}; f{rows, cols}],1);
            if idx(rows,cols) == 1
                % Plot individual traces with average
                figure(counter); hold on;
                %plot(peaks_locs{rows, cols}, peaks{rows, cols},'-', 'linew', 2, 'Color', [colors(cols,:),0.25],'HandleVisibility','off');
            end
        end
    end
elseif ~isempty(idx_plot_relative)
    for cols = 1:length(Conds2Run)
        for rows = 1:length(Chins2Run)
            if cols ~= idx_plot_relative && idx(rows,cols) == 1
                avg_peaks_locs{1,cols-1} = nanmean([avg_peaks_locs{1,cols-1}; peaks_locs{rows, cols}],1);
                avg_peaks{1,cols-1} = nanmean([avg_peaks{1,cols-1}; peaks{rows, cols}-peaks{rows, idx_plot_relative}],1);
                peak_sum1 = nansum(peaks{rows, cols}(idx_peaks(end)+1:end))/nansum(peaks{rows, cols}(idx_peaks));
                peak_sum2 = nansum(peaks{rows, idx_plot_relative}(idx_peaks(end)+1:end))/nansum(peaks{rows, idx_plot_relative}(idx_peaks));
                avg_ratio{1,cols-1} = nanmean([avg_ratio{1,cols-1}; peak_sum1-peak_sum2],1);
                all_peaks{rows,cols-1} = peaks{rows, cols}-peaks{rows, idx_plot_relative};
                all_ratio{rows,cols-1} = peak_sum1-peak_sum2;
                peaks_std{1,cols-1} = nanstd(cell2mat(all_peaks(:,cols-1)),0,1);
                ratio_std{1,cols-1} = nanstd(cell2mat(all_ratio(:,cols-1)),0,1);
                avg_plv_env{1,cols-1} = mean([avg_plv_env{1,cols-1}; plv_env{rows, cols}-plv_env{rows, idx_plot_relative}],1);
                avg_f{1,cols-1} = mean([avg_f{1,cols-1}; f{rows, cols}],1);
                % check if data is present for a given timepoint and subject
                if idx(rows,cols) == 1
                    % Plot individual traces with average
                    figure(counter); hold on;
                    %plot(peaks_locs{rows, cols}, peaks{rows, cols}-peaks{rows, idx_plot_relative},'-', 'linew', 2, 'Color', [colors(cols,:),0.25],'HandleVisibility','off');
                end
            end
        end
    end
end
temp_idx = cellfun(@(x) any(isempty(x)), all_ratio);
all_ratio(temp_idx) = {NaN};

average.f = avg_f;
average.plv_env = avg_plv_env;
average.peaks_locs = avg_peaks_locs;
average.peaks = avg_peaks;
average.peaks_std = peaks_std;
average.ratio = avg_ratio;
average.ratio_std = ratio_std;
average.all_ratio = all_ratio;
end