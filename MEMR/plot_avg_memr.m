function plot_avg_memr(average,EXPname,colors,idx,Chins2Run,Conds2Run,all_Conds2Run,outpath,filename,xlimits,thresholdlimits,idx_plot_relative,shapes,conds_idx)
str_plot_relative = strsplit(all_Conds2Run{idx_plot_relative}, filesep);
legend_string = [];
if isempty(idx_plot_relative)
    for cols = 1:length(average.elicitor)
        if ~isempty(average.deltapow{1,cols})
            % Average MEMR
            figure(length(Chins2Run)+1); subplot(1,2,1); hold on;
            errorbar(average.elicitor{1,cols}, average.deltapow{1,cols},average.deltapow_std{1,cols},'Marker',shapes(cols,:),'LineStyle','-','linew', 2, 'MarkerSize', 12, 'Color', colors(cols,:),'MarkerFaceColor', colors(cols,:),'HandleVisibility','off');
            plot(average.elicitor{1,cols}, average.deltapow{1,cols},'Marker',shapes(cols,:),'LineStyle','-','linew', 2, 'MarkerSize', 12, 'Color', colors(cols,:),'MarkerFaceColor', colors(cols,:));
            xlim(xlimits);xticks(xlimits(1):5:xlimits(2));xtickangle(90);
            xlabel('Elicitor Level (dB FPL)', 'FontWeight', 'bold');
            ylabel('\Delta Absorbed Power (dB)','FontWeight', 'bold');
            title(sprintf('%s',EXPname));
            temp{1,cols} = sprintf('%s (n = %s)',cell2mat(all_Conds2Run(cols)),mat2str(sum(idx(:,cols))));
            legend_idx = find(~cellfun(@isempty,temp));
            legend_string = temp(legend_idx);
            legend(legend_string,'Location','northwest','Orientation','vertical');
            legend boxoff;
            set(gca,'FontSize',25);
            subplot(1,2,2); hold on;
            errorbar(average.threshold{1,cols},average.threshold_std{1,cols},'Marker',shapes(cols,:),'LineStyle','-','linew', 2, 'MarkerSize', 12, 'Color', colors(cols,:),'MarkerFaceColor', colors(cols,:),'HandleVisibility','off');
            plot(average.threshold{1,cols},'Marker',shapes(cols,:),'LineStyle','-','linew', 2, 'MarkerSize', 20, 'Color', colors(cols,:), 'MarkerFaceColor', colors(cols,:));
            ylabel('Threshold (dB FPL)', 'FontWeight', 'bold'); xticklabels([]); xticks([]);
            ylim(thresholdlimits);
            set(gca,'FontSize',25);
            set(gcf, 'Units', 'normalized', 'Position', [0.2 0.2 0.5 0.6]);
        end
    end
    set(gcf, 'Units', 'normalized', 'Position', [0.2 0.2 0.5 0.6]);
end

if ~isempty(idx_plot_relative)  %plot relative to
    y_units = sprintf('\\Delta Absorbed Power (dB re. %s)',str_plot_relative{2});
    for cols = 1:length(average.elicitor)
        if ~isempty(average.deltapow{1,cols})
            % Average MEMR
            figure(length(Chins2Run)+1); subplot(1,2,1); hold on;
            errorbar(average.elicitor{1,cols}, average.deltapow{1,cols},average.deltapow_std{1,cols},'Marker',shapes(cols+1,:),'LineStyle','-','linew', 2, 'MarkerSize', 12, 'Color', colors(cols+1,:),'MarkerFaceColor', colors(cols+1,:),'HandleVisibility','off');
            plot(average.elicitor{1,cols}, average.deltapow{1,cols},'Marker',shapes(cols+1,:),'LineStyle','-','linew', 2, 'MarkerSize', 12, 'Color', colors(cols+1,:),'MarkerFaceColor', colors(cols+1,:));
            yline(zeros(size(average.elicitor{1,cols})),'LineStyle','--', 'linew', 2, 'Color', 'k','HandleVisibility','off');
            xlim(xlimits);xticks(xlimits(1):5:xlimits(2));xtickangle(90);
            xlabel('Elicitor Level (dB FPL)', 'FontWeight', 'bold');
            ylabel(y_units,'FontWeight', 'bold');
            title(sprintf('%s',EXPname));
            temp{1,cols} = sprintf('%s (n = %s)',cell2mat(all_Conds2Run(cols+1)),mat2str(sum(idx(:,cols+1))));
            legend_idx = find(~cellfun(@isempty,temp));
            legend_string = temp(legend_idx);
            legend(legend_string,'Location','northwest','Orientation','vertical');
            legend boxoff;
            set(gca,'FontSize',25);
            subplot(1,2,2); hold on;
            errorbar(average.threshold{1,cols},average.threshold_std{1,cols},'Marker',shapes(cols+1,:),'LineStyle','-','linew', 2, 'MarkerSize', 12, 'Color', colors(cols+1,:),'MarkerFaceColor', colors(cols+1,:),'HandleVisibility','off');
            plot(average.threshold{1,cols},'Marker',shapes(cols+1,:),'LineStyle','-','linew', 2, 'MarkerSize', 20, 'Color', colors(cols+1,:), 'MarkerFaceColor', colors(cols+1,:));
            yline(zeros(size(average.threshold{1,cols})),'LineStyle','--', 'linew', 2, 'Color', 'k','HandleVisibility','off');
            ylabel('Threshold Shift (dB)', 'FontWeight', 'bold'); xticklabels([]); xticks([]);
            ylim(thresholdlimits);
            set(gca,'FontSize',25);
            set(gcf, 'Units', 'normalized', 'Position', [0.2 0.2 0.5 0.6]);
        end
    end
    set(gcf, 'Units', 'normalized', 'Position', [0.2 0.2 0.5 0.6]);
end
average.subjects = Chins2Run;
average.conditions = [convertCharsToStrings(all_Conds2Run);idx];
%% Export
cd(outpath);
save(filename,'average');
print(figure(length(Chins2Run)+1),[filename,'_figure'],'-dpng','-r300');
end