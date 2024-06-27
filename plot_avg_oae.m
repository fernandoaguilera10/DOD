function plot_avg_oae(average,plot_type,EXPname,colors,idx,Conds2Run,outpath,filename,counter,ylimits,idx_plot_relative)
str_plot_relative = strsplit(Conds2Run{idx_plot_relative}, filesep);
legend_string = [];
if strcmp(EXPname,'DPOAE')
    x_units = 'F2 Frequency (kHz)';
else
    x_units = 'Frequency (kHz)';
end
if isempty(idx_plot_relative)
    if strcmp(plot_type,'SPL')
        y_units = 'Amplitude (dB SPL)';
    elseif strcmp(plot_type,'EPL')
        y_units = 'Amplitude (dB EPL)';
    end
    for cols = 1:length(average.oae)
        % Average DP + NF
        figure(counter); hold on;
        plot(average.f{1,cols}, average.oae{1,cols},'-', 'linew', 2, 'Color', [colors(cols,:),0.75]);
        %plot(average.f{1,cols}, average.nf{1,cols},'--', 'linew', 2, 'Color', [colors(cols,:),0.75],'HandleVisibility','off');
        plot(average.bandF, average.bandOAE{1,cols}, 'o', 'linew', 2, 'MarkerSize', 8, 'MarkerFaceColor', colors(cols,:), 'MarkerEdgeColor', colors(cols,:),'HandleVisibility','off');
        plot(average.bandF, average.bandNF{1,cols}, 'x', 'linew', 4, 'MarkerSize', 8, 'MarkerFaceColor', colors(cols,:), 'MarkerEdgeColor', colors(cols,:),'HandleVisibility','off');
        set(gca, 'XScale', 'log', 'FontSize', 14);
        xlim([.5, 16]); xticks([.5, 1, 2, 4, 8, 16]);
        ylabel(y_units, 'FontWeight', 'bold');
        xlabel(x_units, 'FontWeight', 'bold');
        title(sprintf('%s | Average (n = %.0f)',EXPname,sum(idx(:,1))), 'FontSize', 16);
        legend_string{1,cols} = sprintf('%s',cell2mat(Conds2Run(cols)));
        legend(legend_string,'Location','southoutside','Orientation','horizontal','FontSize',8);
        legend boxoff; hold off;
        ylim(ylimits);
    end
end

if ~isempty(idx_plot_relative)  %plot relative to
    if strcmp(plot_type,'SPL')
        y_units = sprintf('Amplitude (dB re. %s)',str_plot_relative{2});
    elseif strcmp(plot_type,'EPL')
        y_units = sprintf('Amplitude (dB re. %s)',str_plot_relative{2});
    end
    for cols = 1:length(average.oae)
        % Average DP + NF
        figure(counter); hold on;
        plot(average.f{1,cols}, average.oae{1,cols},'-', 'linew', 2, 'Color', [colors(cols+1,:),0.75]);
        %plot(average.f{1,cols}, average.nf{1,cols},'--', 'linew', 2, 'Color', [colors(cols+1,:),0.75],'HandleVisibility','off');
        plot(average.bandF, average.bandOAE{1,cols}, 'o', 'linew', 2, 'MarkerSize', 8, 'MarkerFaceColor', colors(cols+1,:), 'MarkerEdgeColor', colors(cols+1,:),'HandleVisibility','off');
        %plot(average.bandF, average.bandNF{1,cols}, 'x', 'linew', 4, 'MarkerSize', 8, 'MarkerFaceColor', colors(cols+1,:), 'MarkerEdgeColor', colors(cols+1,:),'HandleVisibility','off');
        set(gca, 'XScale', 'log', 'FontSize', 14);
        xlim([.5, 16]); xticks([.5, 1, 2, 4, 8, 16]);
        ylabel(y_units, 'FontWeight', 'bold');
        xlabel(x_units, 'FontWeight', 'bold');
        title(sprintf('%s | Average (n = %.0f)',EXPname,sum(idx(:,1))), 'FontSize', 16);
        legend_string{1,cols} = sprintf('%s',cell2mat(Conds2Run(cols+1)));
        legend(legend_string,'Location','southoutside','Orientation','horizontal','FontSize',8);
        legend boxoff; hold off;
        ylim(ylimits);
    end
end
%% Export
cd(outpath);
print(figure(counter),[filename,'_figure'],'-dpng','-r300');
end