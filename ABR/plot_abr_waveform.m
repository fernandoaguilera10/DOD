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
        waveforms_all = cell(length(Chins2Run),length(all_Conds2Run));
        amplitudes_all = cell(length(Chins2Run),length(all_Conds2Run));
        latencies_all = cell(length(Chins2Run),length(all_Conds2Run));
        for l = 1:length(waveforms.levels{1,1})
            for waves = 1:length(w_names)
                for cols = cols_idx
                    for rows = 1:length(Chins2Run)
                        % all waveforms
                        valid_cells = waveforms.y(:,cols);
                        waveforms_all(rows, cols) = {valid_cells{rows}(l, :)};
                        % all peaks
                        y_cell = amplitudes.(w_names{waves});
                        valid_cells = y_cell(:,cols);
                        amplitudes_all{rows, cols}(l, waves) = {valid_cells{rows}(l)};
                        % all latencies
                        y_cell = latencies.(w_names{waves});
                        valid_cells = y_cell(:,cols);
                        latencies_all{rows, cols}(l, waves) = {valid_cells{rows}(l)};

                        % individual latencies
                        figure(counter+l+6); hold on;
                        plot(waveforms.x{rows,cols},waveforms.y{rows,cols}(l,:),'LineStyle','-', 'linew', 1, 'Color', [colors(cols,:),0.05],'HandleVisibility','off');
                        fs = waveforms.x{rows,cols}(3)-waveforms.x{rows,cols}(2);
                        t_idx = round(latencies_all{rows, cols}{l,waves}/fs);
                        if ~isnan(t_idx) && ~isempty(t_idx)
                            plot(latencies_all{rows, cols}{l,waves}, waveforms.y{rows,cols}(l,t_idx), shapes(waves),'LineWidth', 1, 'Color', [colors(cols,:),0.05],'HandleVisibility','off');
                        end

                        % average waveforms
                        filled = waveforms_all(1:rows, cols);               
                        non_empty = filled(~cellfun(@isempty, filled));     
                        if ~isempty(non_empty)
                            waveforms_avg = nanmean(vertcat(non_empty{:}), 1);
                            waveforms_std = nanstd(vertcat(non_empty{:}),0,1);
                        end
                        
                        % average latencies
                        filled = latencies_all(1:rows, cols);
                        non_empty = filled(~cellfun(@isempty, filled));
                        if ~isempty(non_empty)
                            stacked = cellfun(@(x) x{l, waves}, non_empty);     % extract scalar from each cell → N×1 double
                            latencies_avg(waves) = nanmean(stacked, 1);
                            latencies_std(waves) = nanstd(stacked, 0, 1);
                        end

                    end
                    
                    % plot average waveform
                    if waves == 1
                        figure(counter+l+6); hold on;
                        shaded_x = [waveforms.x{rows,cols}, fliplr(waveforms.x{rows,cols})];
                        shaded_y = [waveforms_avg + waveforms_std, fliplr(waveforms_avg - waveforms_std)];
                        %fill(shaded_x, shaded_y, colors(cols,:), 'FaceAlpha', 0.1, 'EdgeColor', 'none','HandleVisibility','off');
                        plot(waveforms.x{rows,cols}, waveforms_avg, 'LineWidth', 2.5, 'Color', colors(cols,:));
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
                end
            end
        end
    end
end
end