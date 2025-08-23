function plot_avg_oae(average,plot_type,EXPname,colors,idx,conds_idx,Chins2Run,Conds2Run,all_Conds2Run,outpath,filename,counter,ylimits,idx_plot_relative,shapes)
cwd = pwd;
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
        if ~isempty(average.bandOAE{1,cols})
            % Average DP + NF
            figure(counter); hold on;
            %plot(average.f{1,cols}, average.oae{1,cols},'-', 'linew', 2, 'Color', [colors(cols,:),0.75]);
            %plot(average.f{1,cols}, average.nf{1,cols},'--', 'linew', 2, 'Color', [colors(cols,:),0.75],'HandleVisibility','off');
            errorbar(average.bandF, average.bandOAE{1,cols},average.oae_band_std{1,cols},'Marker',shapes(cols,:),'LineStyle','-', 'linew', 2, 'Color', colors(cols,:), 'MarkerSize', 12, 'MarkerFaceColor', colors(cols,:), 'MarkerEdgeColor', colors(cols,:),'HandleVisibility','off');
            plot(average.bandF, average.bandOAE{1,cols},'Marker',shapes(cols,:),'LineStyle','-', 'linew', 2, 'Color', colors(cols,:), 'MarkerSize', 12, 'MarkerFaceColor', colors(cols,:), 'MarkerEdgeColor', colors(cols,:));
            plot(average.bandF, average.bandNF{1,cols}, 'x', 'linew', 4, 'MarkerSize', 12, 'MarkerFaceColor', colors(cols,:), 'MarkerEdgeColor', colors(cols,:),'HandleVisibility','off');
            plot(average.bandF, average.bandNF{1,cols},'LineStyle','--', 'linew', 2, 'Color', [colors(cols,:),0.50],'HandleVisibility','off');
            set(gca, 'XScale', 'log');
            xlim([.5, 16]); xticks([.5, 1, 2, 4, 8, 16]);
            ylabel(y_units, 'FontWeight', 'bold');
            xlabel(x_units, 'FontWeight', 'bold');
            title(sprintf('%s',EXPname));
            temp{1,cols} = sprintf('%s (n = %s)',cell2mat(all_Conds2Run(cols)),mat2str(sum(idx(:,cols))));
            legend_idx = find(~cellfun(@isempty,temp));
            legend_string = temp(legend_idx);
            legend(legend_string,'Location','southoutside','Orientation','horizontal');
            legend boxoff; hold off;
            ylim(ylimits); grid on;
            set(gca,'FontSize',15);
        end
    end
    set(gcf, 'Units', 'normalized', 'Position', [0.2 0.2 0.5 0.6]);
end

if ~isempty(idx_plot_relative)  %plot relative to
    if strcmp(plot_type,'SPL')
        y_units = sprintf('Amplitude (dB re. %s)',str_plot_relative{2});
    elseif strcmp(plot_type,'EPL')
        y_units = sprintf('Amplitude (dB re. %s)',str_plot_relative{2});
    end
    for cols = 1:length(average.oae)
        if ~isempty(average.bandOAE{1,cols})
            % Average DP + NF
            figure(counter); hold on;
            %plot(average.f{1,cols}, average.oae{1,cols},'-', 'linew', 2, 'Color', [colors(cols+1,:),0.75]);
            %plot(average.f{1,cols}, average.nf{1,cols},'--', 'linew', 2, 'Color', [colors(cols+1,:),0.75],'HandleVisibility','off');
            errorbar(average.bandF, average.bandOAE{1,cols},average.oae_band_std{1,cols},'Marker',shapes(cols+1,:),'LineStyle','-', 'linew', 3, 'Color', colors(cols+1,:),'MarkerSize', 15, 'MarkerFaceColor', colors(cols+1,:), 'MarkerEdgeColor', colors(cols+1,:),'HandleVisibility','off');
            plot(average.bandF, average.bandOAE{1,cols},'Marker',shapes(cols+1,:),'LineStyle','-', 'linew', 3, 'Color', colors(cols+1,:),'MarkerSize', 15, 'MarkerFaceColor', colors(cols+1,:), 'MarkerEdgeColor', colors(cols+1,:));
            plot(average.bandF, zeros(size(average.bandF)),'LineStyle','--', 'linew', 3, 'Color', 'k','HandleVisibility','off');
            set(gca, 'XScale', 'log');
            xlim([.5, 16]); xticks([.5, 1, 2, 4, 8, 16]);
            ylabel(y_units, 'FontWeight', 'bold');
            xlabel(x_units, 'FontWeight', 'bold');
            title(sprintf('%s',EXPname));        
            temp{1,cols} = sprintf('%s (n = %s)',cell2mat(all_Conds2Run(cols+1)),mat2str(sum(idx(:,cols+1))));
            legend_idx = find(~cellfun(@isempty,temp));
            legend_string = temp(legend_idx);
            legend(legend_string,'Location','southoutside','Orientation','horizontal');
            legend boxoff; hold off;
            ylim(ylimits); grid on;
            set(gca,'FontSize',25);
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
cd(cwd)
end