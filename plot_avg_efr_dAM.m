function plot_avg_efr_dAM(average,plot_type,level_spl,colors,shapes,idx,conds_idx,Chins2Run,Conds2Run,all_Conds2Run,outpath,filename,counter,ylimits,idx_plot_relative,flag)
str_plot_relative = strsplit(all_Conds2Run{idx_plot_relative}, filesep);
legend_string = [];
x_units = 'Frequency (Hz)';
title_str = 'dAM 4 kHz';
if isempty(idx_plot_relative)
    for cols = 1:length(average.dAMpower)
        if ~isempty(average.dAMpower{1,cols})
            row_idx{cols} = find(~cellfun('isempty', average.dAMpower(:, cols)));
            %% Average PLV Spectrum
            figure(counter); hold on;
            % dAM Power
            plot(average.trajectory{1,cols},average.dAMpower{1,cols},'LineStyle','-','linew', 3,'Color', colors(cols,:));   % Average
            dAM_upper_std = average.dAMpower{1,cols} + average.dAMpower_std{1,cols};
            dAM_lower_std = average.dAMpower{1,cols} - average.dAMpower_std{1,cols};
            %plot(average.trajectory{1,cols},dAM_upper_std,'LineStyle','-','linew', 1,'Color', colors(cols,:),'HandleVisibility','off');   % Upper STD
            %plot(average.trajectory{1,cols},dAM_lower_std,'LineStyle','-','linew', 1,'Color', colors(cols,:),'HandleVisibility','off');   % Lower STD
            %patch([average.trajectory{1,cols},fliplr(average.trajectory{1,cols})],[dAM_upper_std, fliplr(dAM_lower_std)],colors(cols,:),'FaceAlpha',0.2,'HandleVisibility','off');

            % NF Power
%             plot(average.trajectory{1,cols},average.NFpower{1,cols},'LineStyle','--','linew', 3,'Color', colors(cols,:));   % Average
%             NF_upper_std = average.NFpower{1,cols} + average.NFpower_std{1,cols};
%             NF_lower_std = average.NFpower{1,cols} - average.NFpower_std{1,cols};
%             plot(average.trajectory{1,cols},NF_upper_std,'LineStyle','--','linew', 1,'Color', colors(cols,:),'HandleVisibility','off');   % Upper STD
%             plot(average.trajectory{1,cols},NF_lower_std,'LineStyle','--','linew', 1,'Color', colors(cols,:),'HandleVisibility','off');   % Lower STD
%             patch([average.trajectory{1,cols},fliplr(average.trajectory{1,cols})],[NF_upper_std, fliplr(NF_lower_std)],colors(cols,:),'FaceAlpha',0.2,'HandleVisibility','off');

            ylabel('Power (dB)', 'FontWeight', 'bold');
            xlabel(x_units, 'FontWeight', 'bold');
            title(sprintf('EFR (%s) | %.0f dB SPL',title_str,level_spl), 'FontSize', 16);
            temp{1,cols} = sprintf('%s (n = %s)',cell2mat(all_Conds2Run(cols)),mat2str(sum(idx(:,cols))));
            legend_idx = find(~cellfun(@isempty,temp));
            legend_string = temp(legend_idx);
            legend(legend_string,'Location','southoutside','Orientation','horizontal');
            legend boxoff; hold off;
            ylim(ylimits); grid on;
            xlim([-inf,inf]); set(gca, 'XScale', 'log'); set(gca,'FontSize',15);
        end
    end
    set(gcf, 'Units', 'normalized', 'Position', [0.2 0.2 0.5 0.6]);   
end
%% Plot relative to Baseline ****** FIX THIS!!
if ~isempty(idx_plot_relative)
    for cols = 1:length(average.peaks)
        if ~isempty(average.peaks_locs{1,cols})
%             figure(counter); hold on;
%             errorbar(average.peaks_locs{1,cols},average.peaks{1,cols},average.peaks_std{1,cols},'Marker',shapes(cols+1,:),'LineStyle','-','linew', 2, 'MarkerSize', 12, 'Color', colors(cols+1,:), 'MarkerFaceColor', colors(cols+1,:), 'MarkerEdgeColor', colors(cols+1,:),'HandleVisibility','off');
%             %average.efr_fit = fillmissing(average.peaks{1,cols},'linear','SamplePoints',average.peaks_locs{1,cols});
%             %plot(average.peaks_locs{1,cols},average.efr_fit,'Marker',shapes(cols+1,:),'LineStyle','-', 'linew', 2,'Color', colors(cols+1,:), 'MarkerSize', 12, 'MarkerFaceColor', colors(cols+1,:), 'MarkerEdgeColor', colors(cols+1,:));
%             %plot(average.peaks_locs{1,cols},average.peaks{1,cols},'*k','linewidth',2)
%             plot(average.peaks_locs{1,cols}, zeros(size(average.peaks_locs{1,cols})),'LineStyle','--', 'linew', 2, 'Color', 'k','HandleVisibility','off');
%             ylabel('PLV Shift (re. Baseline)', 'FontWeight', 'bold');
%             xlabel(x_units, 'FontWeight', 'bold');
%             title(sprintf('EFR (%s) | %.0f dB SPL',title_str,level_spl), 'FontSize', 16);
%             temp{1,cols} = sprintf('%s (n = %s)',cell2mat(all_Conds2Run(cols+1)),mat2str(sum(idx(:,cols+1))));
%             legend_idx = find(~cellfun(@isempty,temp));
%             legend_string = temp(legend_idx);
%             legend(legend_string,'Location','southoutside','Orientation','horizontal');
%             legend boxoff; hold off;
%             ylim(ylimits); grid on;
%             idx_peaks = ~isnan(average.peaks{1,cols});
%             if ~isnan(average.peaks_locs{1,cols}(idx_peaks))
%                 x_max = round(max(average.peaks_locs{1,cols}(idx_peaks)),-3);
%                 xticks(round(average.peaks_locs{1,cols}));
%                 xlim([0,x_max+200]);
%             end
%             set(gca,'xscale','linear');
%             set(gca,'FontSize',15);
        end        
    end
    set(gcf, 'Units', 'normalized', 'Position', [0.2 0.2 0.5 0.6]);
end
average.subjects = Chins2Run;
average.conditions = [convertCharsToStrings(all_Conds2Run);idx];
%% Export
cd(outpath);
save(filename,'average');
print(figure(counter),[filename,'_figure'],'-dpng','-r300');
end