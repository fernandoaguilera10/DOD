function [average,idx] = avg_abr(x,y,Chins2Run,Conds2Run,counter,colors,idx_plot_relative)
if isempty(idx_plot_relative)
    conds = length(Conds2Run);
elseif ~isempty(idx_plot_relative)
    conds = length(Conds2Run)-1;
end
if conds < 1
    uiwait(msgbox('ERROR: Must have at least 2 conditions to do comparison','Conditions to Run','error'));
    return
end
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
end