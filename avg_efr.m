function average = avg_efr(peaks_locs,peaks,f,plv_env,Chins2Run,Conds2Run,all_Conds2Run,counter,colors,shapes,idx_plot_relative,idx,conds_idx)
if isempty(idx_plot_relative)
    conds = length(all_Conds2Run);
elseif ~isempty(idx_plot_relative)
    conds = length(all_Conds2Run)-1;
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
all_ratio_weighted{1,conds} = [];
all_low_high_peaks{1,conds} = [];
all_low_high_peaks_weighted{1,conds} = [];
peaks_std{1,conds} = [];
ratio_std{1,conds} = [];
idx_peaks = 1:3;
if isempty(idx_plot_relative)   % plot all timepoints, including baseline
    for cols = 1:length(all_Conds2Run)
        for rows = 1:length(Chins2Run)
            avg_peaks_locs{1,cols} = nanmean([avg_peaks_locs{1,cols}; peaks_locs{rows, cols}],1);
            avg_peaks{1,cols} = nanmean([avg_peaks{1,cols}; peaks{rows, cols}],1);
            if ~isempty(peaks{rows, cols})
                ratio = nansum(peaks{rows, cols}(idx_peaks(end)+1:end))/nansum(peaks{rows, cols}(idx_peaks));
                all_low_high_peaks{rows,cols} = [nansum(peaks{rows, cols}(idx_peaks)), nansum(peaks{rows, cols}(idx_peaks(end)+1:end))];
                all_weighted = nansum(peaks{rows, cols}(idx_peaks)) + nansum(peaks{rows, cols}(idx_peaks(end)+1:end));
                low_weighted = nansum(peaks{rows, cols}(idx_peaks))/all_weighted;
                high_weighted = nansum(peaks{rows, cols}(idx_peaks(end)+1:end))/all_weighted;
                all_low_high_peaks_weighted{rows,cols} = [low_weighted,high_weighted];
            else
                ratio = [];
                all_low_high_peaks{rows,cols} = [];
                all_weighted = [];
                low_weighted = [];
                high_weighted = [];
                all_low_high_peaks_weighted{rows,cols} = [];
            end
            avg_ratio{1,cols} = nanmean([avg_ratio{1,cols}; ratio],1);
            all_peaks{rows,cols} = peaks{rows, cols};
            all_ratio{rows,cols} = ratio;
            all_ratio_weighted{rows,cols} = high_weighted/low_weighted;
            peaks_std{1,cols} = nanstd(cell2mat(all_peaks(:,cols)),0,1);
            ratio_std{1,cols} = nanstd(cell2mat(all_ratio(:,cols)),0,1);
            avg_plv_env{1,cols} = mean([avg_plv_env{1,cols}; plv_env{rows, cols}],1);
            avg_f{1,cols} = mean([avg_f{1,cols}; f{rows, cols}],1);
            if idx(rows,cols) == 1
                % Plot individual traces with average
                figure(counter); hold on;
                %plot(peaks_locs{rows, cols}, peaks{rows, cols},'Marker',shapes(cols,:),'LineStyle','-', 'linew', 2,'Color', [colors(cols,:),0.30], 'MarkerSize', 3, 'MarkerFaceColor', colors(cols,:), 'MarkerEdgeColor', colors(cols,:),'HandleVisibility','off');
            end
        end
    end
elseif ~isempty(idx_plot_relative)
    for cols = 1:length(all_Conds2Run)
        for rows = 1:length(Chins2Run)
            if cols ~= idx_plot_relative && idx(rows,cols) == 1
                avg_peaks_locs{1,cols-1} = nanmean([avg_peaks_locs{1,cols-1}; peaks_locs{rows, cols}],1);
                avg_peaks{1,cols-1} = nanmean([avg_peaks{1,cols-1}; peaks{rows, cols}-peaks{rows, idx_plot_relative}],1);
                ratio1 = nansum(peaks{rows, cols}(idx_peaks(end)+1:end))/nansum(peaks{rows, cols}(idx_peaks));
                ratio2 = nansum(peaks{rows, idx_plot_relative}(idx_peaks(end)+1:end))/nansum(peaks{rows, idx_plot_relative}(idx_peaks));
                avg_ratio{1,cols-1} = nanmean([avg_ratio{1,cols-1}; ratio1-ratio2],1);
                low_harm = nansum(peaks{rows, cols}(idx_peaks)) - nansum(peaks{rows, idx_plot_relative}(idx_peaks));
                high_harm = nansum(peaks{rows, cols}(idx_peaks(end)+1:end)) - nansum(peaks{rows, idx_plot_relative}(idx_peaks(end)+1:end));
                all_low_high_peaks{rows,cols-1} = [low_harm, high_harm];
                all_weighted = nansum(low_harm^2 + high_harm^2);
                low_weighted = nansum(low_harm)/all_weighted;
                high_weighted = nansum(high_harm)/all_weighted;
                all_low_high_peaks_weighted{rows,cols-1} = [low_weighted,high_weighted];
                all_peaks{rows,cols-1} = peaks{rows, cols}-peaks{rows, idx_plot_relative};
                all_ratio{rows,cols-1} = ratio1-ratio2;
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
average.all_ratio_weighted = all_ratio_weighted;
average.all_peaks = all_peaks;
average.all_low_high_peaks = all_low_high_peaks;
average.all_low_high_peaks_weighted = all_low_high_peaks_weighted;
end