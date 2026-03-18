function plot_abr_waveform(waveforms,plot_type,colors,shapes,idx,conds_idx,Chins2Run,Conds2Run,all_Conds2Run,outpath,filename,counter,ylimits_threshold,idx_plot_relative,freq)
str_plot_relative = strsplit(Conds2Run{idx_plot_relative}, filesep);
legend_string = [];
cwd = pwd;
if isempty(idx_plot_relative)
   %% Peaks
    if strcmp(plot_type,'Peaks')
        if freq == 0, freq_str = 'Click'; end
        if freq ~= 0, freq_str = [mat2str(freq),' Hz']; end
        valid_cols = cellfun(@(c) ~(isempty(c) || (isnumeric(c) && isequal(size(c),[0 0]))), waveforms.y);
        cols_idx = find(any(valid_cols, 1));
        for l = 1:length(waveforms.levels)
            for rows = 1:length(Chins2Run)
                for cols = cols_idx
                    figure(counter+l+6); hold on;
                    plot(waveforms.x{rows,cols},waveforms.y{rows,cols}(l,:),'LineStyle','-', 'linew', 2, 'Color', colors(cols,:));
                    xlim([0,20]); grid on;
                    ylabel('Amplitude (\muV)', 'FontWeight', 'bold');
                    xlabel('Time (ms)', 'FontWeight', 'bold'); hold off;
                    title_str = sprintf('ABR Waveform | %s @%s dB SPL',freq_str,num2str(waveforms.levels{1,1}(l)));
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
%% ADD AVERAGE WAVEFORM AT EACH LEVEL
