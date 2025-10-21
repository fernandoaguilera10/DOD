function [average,idx] = avg_memr(elicitor,deltapow,threshold,Chins2Run,Conds2Run,all_Conds2Run,colors,shapes,idx_plot_relative)
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
avg_threshold{1,conds} = [];
all_deltapow{1,conds} = [];
deltapow_std{1,conds} = [];
threshold_std{1,conds} = [];
all_threshold{1,conds} = [];
idx = ~cellfun(@isempty,deltapow);    % find if data file is present: rows = Chins2Run, cols = Conds2Run
if isempty(idx_plot_relative)   % plot all timepoints, including baseline
    for cols = 1:length(all_Conds2Run)
        for rows = 1:length(Chins2Run)
            avg_elicitor{1,cols} = mean([avg_elicitor{1,cols}; elicitor{rows, cols}],1);
            avg_deltapow{1,cols} = mean([avg_deltapow{1,cols}; deltapow{rows, cols}],1);
            avg_threshold{1,cols} = mean([avg_threshold{1,cols}; threshold{rows, cols}],1);
            all_deltapow{rows,cols} = deltapow{rows, cols};
            deltapow_std{1,cols} = std(cell2mat(all_deltapow(:,cols)),0,1);
            all_threshold{rows,cols} = threshold{rows, cols};
            threshold_std{1,cols} = std(cell2mat(all_threshold(:,cols)),0,1);
            % check if data is present for a given timepoint and subject
            if idx(rows,cols) == 1
                % Plot individual traces with average
                figure(length(Chins2Run)+1); subplot(1,4,[1,3]); hold on;
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
                avg_threshold{1,cols-1} = mean([avg_threshold{1,cols-1}; threshold{rows, cols}-threshold{rows, idx_plot_relative}],1);    
                all_deltapow{rows,cols-1} = deltapow{rows, cols}-deltapow{rows, idx_plot_relative};
                deltapow_std{1,cols-1} = std(cell2mat(all_deltapow(:,cols-1)),0,1);
                all_threshold{rows,cols-1} = threshold{rows, cols}-threshold{rows, idx_plot_relative};
                threshold_std{1,cols-1} = std(cell2mat(all_threshold(:,cols-1)),0,1);
                % check if data is present for a given timepoint and subject
                if idx(rows,cols) == 1
                    % Plot individual traces with average
                    figure(length(Chins2Run)+1); subplot(1,4,[1,3]); hold on;
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
average.threshold = avg_threshold;
average.threshold_std = threshold_std;
end