function plot_avg_memr(average,EXPname,colors,idx,Chins2Run,Conds2Run,outpath,filename,xlimits,idx_plot_relative,shapes)
str_plot_relative = strsplit(Conds2Run{idx_plot_relative}, filesep);
legend_string = [];
if isempty(idx_plot_relative)
    for cols = 1:length(average.elicitor)
        % Average MEMR
        figure(length(Chins2Run)+1); hold on;
        errorbar(average.elicitor{1,cols}, average.deltapow{1,cols},average.deltapow_std{1,cols},'Marker',shapes(cols,:),'LineStyle','-','linew', 2, 'MarkerSize', 12, 'Color', colors(cols,:),'MarkerFaceColor', colors(cols,:),'HandleVisibility','off');
        plot(average.elicitor{1,cols}, average.deltapow{1,cols},'Marker',shapes(cols,:),'LineStyle','-','linew', 2, 'MarkerSize', 12, 'Color', colors(cols,:),'MarkerFaceColor', colors(cols,:));
        xlim(xlimits);
        xticks(xlimits(1):5:xlimits(2));
        xlabel('Elicitor Level (dB FPL)', 'FontWeight', 'bold');
        ylabel('\Delta Absorbed Power (dB)','FontWeight', 'bold');
        set(gca, 'XScale', 'log');
        title(sprintf('%s | Average (n = %.0f)',EXPname,sum(idx(:,1))));
        legend_string{1,cols} = sprintf('%s (n = %s)',cell2mat(Conds2Run(cols)),mat2str(sum(idx(:,cols))));
        legend(legend_string,'Location','southoutside','Orientation','horizontal');
        legend boxoff; hold off; grid on;
        set(gca,'FontSize',15);
    end
end

if ~isempty(idx_plot_relative)  %plot relative to
    y_units = sprintf('\\Delta Absorbed Power (dB re. %s)',str_plot_relative{2});
    for cols = 1:length(average.elicitor)
        % Average MEMR
        figure(length(Chins2Run)+1); hold on;
        errorbar(average.elicitor{1,cols}, average.deltapow{1,cols},average.deltapow_std{1,cols},'Marker',shapes(cols+1,:),'LineStyle','-','linew', 2, 'MarkerSize', 12, 'Color', colors(cols+1,:),'MarkerFaceColor', colors(cols+1,:),'HandleVisibility','off');
        plot(average.elicitor{1,cols}, average.deltapow{1,cols},'Marker',shapes(cols+1,:),'LineStyle','-','linew', 2, 'MarkerSize', 12, 'Color', colors(cols+1,:),'MarkerFaceColor', colors(cols+1,:));
        plot(average.elicitor{1,cols}, zeros(size(average.elicitor{1,cols})),'LineStyle','--', 'linew', 2, 'Color', 'k','HandleVisibility','off');
        xlim(xlimits);
        xticks(xlimits(1):5:xlimits(2));
        xlabel('Elicitor Level (dB FPL)', 'FontWeight', 'bold');
        ylabel(y_units,'FontWeight', 'bold');
        set(gca, 'XScale', 'log');
        title(sprintf('%s | Average (n = %.0f)',EXPname,sum(idx(:,1))));
        legend_string{1,cols} = sprintf('%s (n = %s)',cell2mat(Conds2Run(cols+1)),mat2str(sum(idx(:,cols+1))));
        legend(legend_string,'Location','southoutside','Orientation','horizontal');
        legend boxoff; hold off; grid on;
        set(gca,'FontSize',15);
    end
end
%% Export
cd(outpath);
print(figure(length(Chins2Run)+1),[filename,'_figure'],'-dpng','-r300');
end