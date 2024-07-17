function [average,idx] = avg_oae(f,oae_amp,oae_nf,f_band,oae_amp_band,oae_nf_band,Chins2Run,Conds2Run,counter,colors,idx_plot_relative)
if isempty(idx_plot_relative)
    conds = length(Conds2Run);
elseif ~isempty(idx_plot_relative)
    conds = length(Conds2Run)-1;
end
if conds < 1
    uiwait(msgbox('ERROR: Must have at least 2 conditions to do comparison','Conditions to Run','error'));
    return
end
avg_f{1,conds} = [];
avg_amp{1,conds} = [];
avg_nf{1,conds} = [];
avg_oae_band{1,conds} = [];
avg_nf_band{1,conds} = [];
idx = ~cellfun(@isempty,oae_amp);    % find if data file is present: rows = Chins2Run, cols = Conds2Run
if isempty(idx_plot_relative)   % plot all timepoints, including baseline
    for cols = 1:length(Conds2Run)
        for rows = 1:length(Chins2Run)
            avg_f{1,cols} = mean([avg_f{1,cols}; f{rows, cols}],1);
            avg_amp{1,cols} = mean([avg_amp{1,cols}; oae_amp{rows, cols}],1);
            avg_nf{1,cols} = mean([avg_nf{1,cols}; oae_nf{rows, cols}],1);
            avg_oae_band{1,cols} = mean([avg_oae_band{1,cols}; oae_amp_band{rows, cols}],1);
            avg_nf_band{1,cols} = mean([avg_nf_band{1,cols}; oae_nf_band{rows, cols}],1);
            % check if data is present for a given timepoint and subject
            if idx(rows,cols) == 1
                % Plot individual traces with average
                figure(counter); hold on;
                plot(f{rows, cols}, oae_amp{rows, cols}, '-', 'linew', 2, 'Color', [colors(cols,:),0.25],'HandleVisibility','off');
                %plot(f{rows, cols}, oae_nf{rows, cols}, '--', 'linew', 2, 'Color', [colors(cols,:),0.25],'HandleVisibility','off');
                set(gca, 'XScale', 'log', 'FontSize', 14);
            end
        end
    end
elseif ~isempty(idx_plot_relative)
    for cols = 1:length(Conds2Run)
        for rows = 1:length(Chins2Run)
            if cols ~= idx_plot_relative && idx(rows,cols) == 1
                avg_f{1,cols-1} = mean([avg_f{1,cols-1}; f{rows, cols}],1);
                avg_amp{1,cols-1} = mean([avg_amp{1,cols-1}; oae_amp{rows, cols}-oae_amp{rows, idx_plot_relative}],1);
                avg_nf{1,cols-1} = mean([avg_nf{1,cols-1}; oae_nf{rows, cols}-oae_nf{rows, idx_plot_relative}],1);
                avg_oae_band{1,cols-1} = mean([avg_oae_band{1,cols-1}; oae_amp_band{rows, cols}-oae_amp_band{rows, idx_plot_relative}],1);
                avg_nf_band{1,cols-1} = mean([avg_nf_band{1,cols-1}; oae_nf_band{rows, cols}-oae_nf_band{rows, idx_plot_relative}],1);
                % check if data is present for a given timepoint and subject
                if idx(rows,cols) == 1
                    % Plot individual traces with average
                    figure(counter); hold on;
                    plot(f{rows, cols}, oae_amp{rows, cols}-oae_amp{rows, idx_plot_relative}, '-', 'linew', 2, 'Color', [colors(cols,:),0.25],'HandleVisibility','off');
                    %plot(f{rows, cols}, oae_nf{rows, cols}-oae_nf{rows, idx_plot_relative}, '--', 'linew', 2, 'Color', [colors(cols,:),0.25],'HandleVisibility','off');
                    set(gca, 'XScale', 'log', 'FontSize', 14);
                end
            end
        end
    end
end
average.f = avg_f;
average.oae = avg_amp;
average.nf = avg_nf;
average.bandF = [f_band]';
average.bandOAE = avg_oae_band;
average.bandNF = avg_nf_band;
end