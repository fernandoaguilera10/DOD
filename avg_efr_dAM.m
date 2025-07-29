function average = avg_efr_dAM(trajectory,dAMpower,NFpower,Chins2Run,Conds2Run,all_Conds2Run,counter,colors,shapes,idx_plot_relative,idx,conds_idx)
if isempty(idx_plot_relative)
    conds = length(all_Conds2Run);
elseif ~isempty(idx_plot_relative)
    conds = length(all_Conds2Run)-1;
end
if conds < 1
    uiwait(msgbox('ERROR: Must have at least 2 conditions to do comparison','Conditions to Run','error'));
    return
end
avg_trajectory{1,conds} = [];
avg_dAMpower{1,conds} = [];
avg_NFpower{1,conds} = [];
all_trajectory{1,conds} = [];
all_dAMpower{1,conds} = [];
all_NFpower{1,conds} = [];
dAMpower_std{1,conds} = [];
NFpower_std{1,conds} = [];
if isempty(idx_plot_relative)   % plot all timepoints, including baseline
    for cols = 1:length(all_Conds2Run)
        for rows = 1:length(Chins2Run)
            avg_trajectory{1,cols} = nanmean([avg_trajectory{1,cols}; trajectory{rows, cols}],1);
            avg_dAMpower{1,cols} = nanmean([avg_dAMpower{1,cols}; dAMpower{rows, cols}],1);
            avg_NFpower{1,cols} = nanmean([avg_NFpower{1,cols}; NFpower{rows, cols}],1);
            all_trajectory{rows,cols} = trajectory{rows, cols};
            all_dAMpower{rows,cols} = dAMpower{rows, cols};
            all_NFpower{rows,cols} = NFpower{rows, cols};
            dAMpower_std{1,cols} = nanstd(cell2mat(all_dAMpower(:,cols)),0,1);
            NFpower_std{1,cols} = nanstd(cell2mat(all_NFpower(:,cols)),0,1);
            if idx(rows,cols) == 1
                % Plot individual traces with average
                figure(counter); hold on;
                %plot(trajectory{rows, cols}, dAMpower{rows, cols},'LineStyle','-', 'linew', 2,'Color', [colors(cols,:),0.30],'HandleVisibility','off');
                %plot(trajectory{rows, cols}, NFpower{rows, cols},'LineStyle','--', 'linew', 2,'Color', [colors(cols,:),0.30],'HandleVisibility','off');
                set(gca, 'XScale', 'log')
            end
        end
    end




    
    %% ****** FIX THIS!!
elseif ~isempty(idx_plot_relative)  
%     for cols = 1:length(all_Conds2Run)
%         for rows = 1:length(Chins2Run)
%             if cols ~= idx_plot_relative && idx(rows,cols) == 1
%                 avg_trajectory{1,cols-1} = nanmean([avg_trajectory{1,cols-1}; peaks_locs{rows, cols}],1);
%                 avg_dAMpower{1,cols-1} = nanmean([avg_dAMpower{1,cols-1}; peaks{rows, cols}-peaks{rows, idx_plot_relative}],1);
%                 plv_sum1 = nansum(peaks{rows, cols}(idx_plv_sum));
%                 plv_sum2 = nansum(peaks{rows, idx_plot_relative}(idx_plv_sum));
%                 low_harm = nansum(peaks{rows, cols}(idx_peaks)) - nansum(peaks{rows, idx_plot_relative}(idx_peaks));
%                 high_harm = nansum(peaks{rows, cols}(idx_peaks(end)+1:end)) - nansum(peaks{rows, idx_plot_relative}(idx_peaks(end)+1:end));
%                 all_NFpower{rows,cols-1} = [low_harm, high_harm];
%                 all_trajectory{rows,cols-1} = peaks{rows, cols}-peaks{rows, idx_plot_relative};
%                 all_dAMpower{rows,cols-1} = plv_sum1-plv_sum2;
%                 dAMpower_std{1,cols-1} = nanstd(cell2mat(all_trajectory(:,cols-1)),0,1);
%                 avg_NFpower{1,cols-1} = mean([avg_NFpower{1,cols-1}; plv_env{rows, cols}-plv_env{rows, idx_plot_relative}],1);
%                 avg_f{1,cols-1} = mean([avg_f{1,cols-1}; f{rows, cols}],1);
%                 % check if data is present for a given timepoint and subject
%                 if idx(rows,cols) == 1
%                     % Plot individual traces with average
%                     figure(counter); hold on;
%                     %plot(peaks_locs{rows, cols}, peaks{rows, cols}-peaks{rows, idx_plot_relative},'-', 'linew', 2, 'Color', [colors(cols,:),0.25],'HandleVisibility','off');
%                 end
%             end
%         end
%     end
end
temp_idx = cellfun(@(x) any(isempty(x)), all_dAMpower);
all_dAMpower(temp_idx) = {NaN};
average.trajectory = avg_trajectory;
average.dAMpower = avg_dAMpower;
average.NFpower = avg_NFpower;
average.dAMpower_std = dAMpower_std;
average.NFpower_std = NFpower_std;
average.all_trajectory = all_trajectory;
average.all_dAMpower = all_dAMpower;
average.all_NFpower = all_NFpower;
end