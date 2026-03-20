function plot_abr_waveform(waveforms,amplitudes,latencies,plot_type,colors,shapes,idx,conds_idx,Chins2Run,Conds2Run,all_Conds2Run,outpath,filename,counter,ylimits,idx_plot_relative,freq)
str_plot_relative = strsplit(Conds2Run{idx_plot_relative}, filesep);
legend_string = [];
cwd = pwd;
if isempty(idx_plot_relative)
    if strcmp(plot_type,'Peaks')
        if freq == 0, freq_str = 'Click'; end
        if freq ~= 0, freq_str = [mat2str(freq),' Hz']; end
        valid_cols = cellfun(@(c) ~(isempty(c) || (isnumeric(c) && isequal(size(c),[0 0]))), waveforms.y);
        cols_idx = find(any(valid_cols, 1));

        w_names = {'all_w1','all_w2','all_w3','all_w4','all_w5'};
        waveforms_all = nan(length(Chins2Run),length(cell2mat(waveforms.y(1,1))));
        amplitudes_all = nan(length(Chins2Run),length(w_names));
        latencies_all = nan(length(Chins2Run),length(w_names));
        for l = 1:length(waveforms.levels{1,1})
            figure(counter+l+6); hold on;
            for w = 1:length(w_names)
                for i = 1:length(Chins2Run)
                    for cols = cols_idx

                        %% FIX ISSUE WITH TIMEPOINTS! 

                        % average waveforms
                        y_cell = waveforms.y(:,cols);
                        valid_cells = y_cell(:,cols);
                        waveforms_all(i, :) = valid_cells{i,cols}(l, :);
                        % averake peaks
                        y_cell = amplitudes.(w_names{w});
                        valid_cells = y_cell(:,cols);
                        amplitudes_all(i, w) = valid_cells{i,cols}(l, :);
                        % average latencies
                        y_cell = latencies.(w_names{w});
                        valid_cells = y_cell(:,cols);
                        latencies_all(i, w) = valid_cells{i,cols}(l, :);

                        % individual traces
                        plot(waveforms.x{i,cols},waveforms.y{i,cols}(l,:),'LineStyle','-', 'linew', 1, 'Color', [colors(cols,:),0.05],'HandleVisibility','off');
                        fs = waveforms.x{i,cols}(3)-waveforms.x{i,cols}(2);
                        t_idx = round(latencies_all(i, w)/fs);
                        if ~isnan(t_idx) && ~isempty(t_idx)
                            plot(latencies_all(i, w), waveforms.y{i,cols}(l,t_idx), shapes(w),'LineWidth', 1, 'Color', [colors(cols,:),0.05],'HandleVisibility','off');
                        end
                    end
                end
                % average waveform
                if w == 1
                    figure(counter+l+6); hold on;
                    waveforms_avg = mean(waveforms_all,1);
                    std_wave = std(waveforms_all,0,1);
                    shaded_x = [waveforms.x{i,cols}, fliplr(waveforms.x{i,cols})];
                    shaded_y = [waveforms_avg + std_wave, fliplr(waveforms_avg - std_wave)];
                    %fill(shaded_x, shaded_y, colors(cols,:), 'FaceAlpha', 0.1, 'EdgeColor', 'none','HandleVisibility','off');
                    plot(waveforms.x{i,cols}, waveforms_avg, 'LineWidth', 2.5, 'Color', colors(cols,:));
                    xlim([0,20]); ylim(ylimits); grid on;
                    ylabel('Amplitude (\muV)', 'FontWeight', 'bold');
                    xlabel('Time (ms)', 'FontWeight', 'bold'); hold off;
                    title_str = sprintf('ABR Waveform - %s @%s dB SPL',freq_str,num2str(waveforms.levels{1,1}(l)));
                    temp{1,cols} = sprintf('%s (n = %s)',cell2mat(all_Conds2Run(cols)),mat2str(sum(idx(:,cols))));
                    legend_idx = find(~cellfun(@isempty,temp));
                    legend_string = temp(legend_idx);
                    legend(legend_string,'Location','southoutside','Orientation','horizontal');
                    legend boxoff; set(gca,'FontSize',15); title(title_str, 'FontSize', 16);
                end
    
                % average latencies
                latencies_avg = nanmean(latencies_all,1);
                amplitudes_avg = nanmean(amplitudes_all,1);
                figure(counter+l+6); hold on;
                %xline(latencies_avg(w), '--', 'LineWidth', 2, 'Color', colors(w+4,:),'HandleVisibility','off');
                t_idx = round(latencies_avg(w)/fs);
                if ~isnan(t_idx) && ~isempty(t_idx)
                    plot(latencies_avg(w), waveforms_avg(t_idx), shapes(w),'MarkerSize',10,'LineWidth', 2.5, 'MarkerEdgeColor', colors(cols,:),'MarkerFaceColor',colors(cols,:),'HandleVisibility','off');
                end
            end
        end
    end
end
end