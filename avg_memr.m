function [average,idx] = avg_memr(elicitor,deltapow,Chins2Run,Conds2Run,colors,idx_plot_relative)
if isempty(idx_plot_relative)
    conds = length(Conds2Run);
elseif ~isempty(idx_plot_relative)
    conds = length(Conds2Run)-1;
end
if conds < 1
    uiwait(msgbox('ERROR: Must have at least 2 conditions to do comparison','Conditions to Run','error'));
    return
end
avg_elicitor{1,conds} = [];
avg_deltapow{1,conds} = [];
idx = ~cellfun(@isempty,deltapow);    % find if data file is present: rows = Chins2Run, cols = Conds2Run
if isempty(idx_plot_relative)   % plot all timepoints, including baseline
    for cols = 1:length(Conds2Run)
        for rows = 1:length(Chins2Run)
            avg_elicitor{1,cols} = mean([avg_elicitor{1,cols}; elicitor{rows, cols}],1);
            avg_deltapow{1,cols} = mean([avg_deltapow{1,cols}; deltapow{rows, cols}],1);
            % check if data is present for a given timepoint and subject
            if idx(rows,cols) == 1
                % Plot individual traces with average
                figure(length(Chins2Run)+1); hold on;
                plot(elicitor{rows, cols}, deltapow{rows, cols}, '-', 'linew', 2, 'Color', [colors(cols,:),0.25],'HandleVisibility','off');
                %plot(f{rows, cols}, oae_nf{rows, cols}, '--', 'linew', 2, 'Color', [colors(cols,:),0.25],'HandleVisibility','off');
                set(gca, 'XScale', 'log', 'FontSize', 14);
            end
        end
    end
elseif ~isempty(idx_plot_relative)
    for cols = 1:length(Conds2Run)
        for rows = 1:length(Chins2Run)
            if cols ~= idx_plot_relative && idx(rows,cols) == 1
                avg_elicitor{1,cols-1} = mean([avg_elicitor{1,cols-1}; elicitor{rows, cols}],1);
                avg_deltapow{1,cols-1} = mean([avg_deltapow{1,cols-1}; deltapow{rows, cols}-deltapow{rows, idx_plot_relative}],1);
                % check if data is present for a given timepoint and subject
                if idx(rows,cols) == 1
                    % Plot individual traces with average
                    figure(length(Chins2Run)+1); hold on;
                    plot(elicitor{rows, cols}, deltapow{rows, cols}-deltapow{rows, idx_plot_relative}, '-', 'linew', 2, 'Color', [colors(cols,:),0.25],'HandleVisibility','off');
                    set(gca, 'XScale', 'log', 'FontSize', 14);
                end
            end
        end
    end
end
average.elicitor = avg_elicitor;
average.deltapow = avg_deltapow;
end