function [average,idx] = avg_abr(x,y,Chins2Run,Conds2Run,counter,colors,shapes,idx_plot_relative,analysis_type)
if isempty(idx_plot_relative)
    conds = length(Conds2Run);
elseif ~isempty(idx_plot_relative)
    conds = length(Conds2Run)-1;
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
    idx = ~cellfun(@isempty,y);    % find if data file is present: rows = Chins2Run, cols = Conds2Run
    if isempty(idx_plot_relative)   % plot all timepoints, including baseline
        for cols = 1:length(Conds2Run)
            for rows = 1:length(Chins2Run)
                avg_x{1,cols} = mean([avg_x{1,cols}; x{rows, cols}],1);
                avg_y{1,cols} = mean([avg_y{1,cols}; y{rows, cols}],1);
                all_y{rows,cols} = y{rows, cols};
                y_std{1,cols} = std(cell2mat(all_y(:,cols)));
                % check if data is present for a given timepoint and subject
                if idx(rows,cols) == 1
                    % Plot individual traces with average
                    figure(counter); hold on;
                    %plot(x{rows, cols}, y{rows, cols}, '-', 'linew', 2, 'Color', [colors(cols,:),0.25],'HandleVisibility','off');
                end
            end
        end
    elseif ~isempty(idx_plot_relative)
        for cols = 1:length(Conds2Run)
            for rows = 1:length(Chins2Run)
                if cols ~= idx_plot_relative && idx(rows,cols) == 1
                    avg_x{1,cols-1} = mean([avg_x{1,cols-1}; x{rows, cols}],1);
                    avg_y{1,cols-1} = mean([avg_y{1,cols-1}; y{rows, cols}-y{rows, idx_plot_relative}],1);
                    all_y{rows,cols-1} = y{rows, cols}-y{rows, idx_plot_relative};
                    y_std{1,cols-1} = std(cell2mat(all_y(:,cols-1)));
                    % check if data is present for a given timepoint and subject
                    if idx(rows,cols) == 1
                        % Plot individual traces with average
                        figure(counter); hold on;
                        %plot(x{rows, cols}, y{rows, cols}-y{rows, idx_plot_relative}, '-', 'linew', 2, 'Color', colors(cols,:),'HandleVisibility','off');
                    end
                end
            end
        end
    end
    average.x = avg_x;
    average.y = avg_y;
    average.y_std = y_std;
elseif strcmp(analysis_type,'Peaks')
    avg_x{1,conds} = [];
    peak_to_peak{1,conds} = [];
    avg_w1{1,conds} = [];
    avg_w2{1,conds} = [];
    avg_w3{1,conds} = [];
    avg_w4{1,conds} = [];
    avg_w5{1,conds} = [];
    all_w1{1,conds} = [];
    all_w2{1,conds} = [];
    all_w3{1,conds} = [];
    all_w4{1,conds} = [];
    all_w5{1,conds} = [];
    w1_std{1,conds} = [];
    w2_std{1,conds} = [];
    w3_std{1,conds} = [];
    w4_std{1,conds} = [];
    w5_std{1,conds} = [];
    idx = ~cellfun(@isempty,y);    % find if data file is present: rows = Chins2Run, cols = Conds2Run
    if isempty(idx_plot_relative)   % plot all timepoints, including baseline
        for cols = 1:length(Conds2Run)
            for rows = 1:length(Chins2Run)
                for i=1:2:width(y{rows,cols})-1
                    peak_to_peak{rows,cols}(:,(i+1)/2) = y{rows,cols}(:,i)-y{rows,cols}(:,i+1);
                end
                avg_x{1,cols} = mean([avg_x{1,cols}; x{rows, cols}],2);
                avg_w1{1,cols} = mean([avg_w1{1,cols}, peak_to_peak{rows, cols}(:,1)],2);
                avg_w2{1,cols} = mean([avg_w2{1,cols}, peak_to_peak{rows, cols}(:,2)],2);
                avg_w3{1,cols} = mean([avg_w3{1,cols}, peak_to_peak{rows, cols}(:,3)],2);
                avg_w4{1,cols} = mean([avg_w4{1,cols}, peak_to_peak{rows, cols}(:,4)],2);
                avg_w5{1,cols} = mean([avg_w5{1,cols}, peak_to_peak{rows, cols}(:,5)],2);
                all_w1{rows,cols} = peak_to_peak{rows,cols}(:,1);
                all_w2{rows,cols} = peak_to_peak{rows,cols}(:,2);
                all_w3{rows,cols} = peak_to_peak{rows,cols}(:,3);
                all_w4{rows,cols} = peak_to_peak{rows,cols}(:,4);
                all_w5{rows,cols} = peak_to_peak{rows,cols}(:,5);
                w1_std{1,cols} = nanstd(cell2mat(all_w1(:,cols)));
                w2_std{1,cols} = nanstd(cell2mat(all_w2(:,cols)));
                w3_std{1,cols} = nanstd(cell2mat(all_w3(:,cols)));
                w4_std{1,cols} = nanstd(cell2mat(all_w4(:,cols)));
                w5_std{1,cols} = nanstd(cell2mat(all_w5(:,cols)));
                % check if data is present for a given timepoint and subject
                if idx(rows,cols) == 1
                    % Plot individual traces with average
                    figure(counter); hold on;
                    for i=1:5
                        subplot(5,1,i); hold on;
                        %plot(x{rows, cols}, peak_to_peak{rows, cols}(:,i),'Marker',shapes(i,:),'LineStyle','-', 'linew', 2, 'MarkerSize', 8, 'Color', colors(cols,:),'MarkerFaceColor', colors(cols,:), 'MarkerEdgeColor', colors(cols,:),'HandleVisibility','off')
                    end
                end
            end
        end
    end
    average.x = avg_x;
    average.w1 = avg_w1;
    average.w2 = avg_w2;
    average.w3 = avg_w3;
    average.w4 = avg_w4;
    average.w5 = avg_w5;
    average.w1_std = w1_std;
    average.w2_std = w2_std;
    average.w3_std = w3_std;
    average.w4_std = w4_std;
    average.w5_std = w5_std;
end
end