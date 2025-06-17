function [average,idx] = avg_memr(elicitor,deltapow,Chins2Run,Conds2Run,all_Conds2Run,colors,shapes,idx_plot_relative)
if isempty(idx_plot_relative)
    conds = length(all_Conds2Run);
elseif ~isempty(idx_plot_relative)
    conds = length(all_Conds2Run)-1;
end
if conds < 1
    uiwait(msgbox('ERROR: Must have at least 2 conditions to do comparison','Conditions to Run','error'));
    return
end
avg_elicitor{1,conds} = [];
avg_deltapow{1,conds} = [];
all_deltapow{1,conds} = [];
deltapow_std{1,conds} = [];
all_threshold{1,conds} = [];
idx = ~cellfun(@isempty,deltapow);    % find if data file is present: rows = Chins2Run, cols = Conds2Run
if isempty(idx_plot_relative)   % plot all timepoints, including baseline
    for cols = 1:length(all_Conds2Run)
        for rows = 1:length(Chins2Run)
            avg_elicitor{1,cols} = mean([avg_elicitor{1,cols}; elicitor{rows, cols}],1);
            avg_deltapow{1,cols} = mean([avg_deltapow{1,cols}; deltapow{rows, cols}],1);
            all_deltapow{rows,cols} = deltapow{rows, cols};
            deltapow_std{1,cols} = std(cell2mat(all_deltapow(:,cols)),0,1);
            threshold_idx = find(deltapow{rows, cols} > 0.1, 1, 'first');
            if isempty(threshold_idx), threshold_idx = 11; end
            all_threshold{rows,cols} = elicitor{rows, cols}(threshold_idx);
            % check if data is present for a given timepoint and subject
            if idx(rows,cols) == 1
                % Plot individual traces with average
                figure(length(Chins2Run)+1); hold on;
                %plot(elicitor{rows, cols}, deltapow{rows, cols},'Marker',shapes(cols,:),'LineStyle','-', 'linew', 2,'Color', [colors(cols,:),0.30], 'MarkerSize', 3, 'MarkerFaceColor', colors(cols,:), 'MarkerEdgeColor', colors(cols,:),'HandleVisibility','off');
                set(gca, 'XScale', 'log', 'FontSize', 14);
            end
        end
    end
elseif ~isempty(idx_plot_relative)
    for cols = 1:length(all_Conds2Run)
        for rows = 1:length(Chins2Run)
            if cols ~= idx_plot_relative && idx(rows,cols) == 1
                avg_elicitor{1,cols-1} = mean([avg_elicitor{1,cols-1}; elicitor{rows, cols}],1);
                avg_deltapow{1,cols-1} = mean([avg_deltapow{1,cols-1}; deltapow{rows, cols}-deltapow{rows, idx_plot_relative}],1);
                all_deltapow{rows,cols-1} = deltapow{rows, cols}-deltapow{rows, idx_plot_relative};
                deltapow_std{1,cols-1} = std(cell2mat(all_deltapow(:,cols-1)),0,1);
                threshold_idx_1 = find(deltapow{rows, cols} > 0.1, 1, 'first');
                threshold_idx_2 = find(deltapow{rows, idx_plot_relative} > 0.1, 1, 'first');
                if isempty(threshold_idx_1), threshold_idx_1 = 11; end
                if isempty(threshold_idx_2), threshold_idx_2 = 11; end
                threshold = elicitor{rows, cols}(threshold_idx_1)-elicitor{rows, idx_plot_relative}(threshold_idx_2);
                all_threshold{rows,cols-1} = threshold;
                % check if data is present for a given timepoint and subject
                if idx(rows,cols) == 1
                    % Plot individual traces with average
                    figure(length(Chins2Run)+1); hold on;
                    %plot(elicitor{rows, cols}, deltapow{rows, cols}-deltapow{rows, idx_plot_relative}, '-', 'linew', 2, 'Color', [colors(cols,:),0.25],'HandleVisibility','off');
                    set(gca, 'XScale', 'log', 'FontSize', 14);
                end
            end
        end
    end
end
average.elicitor = avg_elicitor;
average.deltapow = avg_deltapow;
average.deltapow_std = deltapow_std;
average.all_deltapow = all_deltapow;
average.all_thresholds = all_threshold;
end