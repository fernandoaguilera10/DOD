function plot_avg_abr(average,plot_type,colors,shapes,idx,Conds2Run,outpath,filename,counter,ylimits_threshold,idx_plot_relative,peak_analysis)
str_plot_relative = strsplit(Conds2Run{idx_plot_relative}, filesep);
legend_string = [];
rows = 1:4; % plot highest 4 levels [90 80 70 60] dB SPL
if isempty(idx_plot_relative)
    if strcmp(plot_type,'Thresholds')
        x_units = 'Frequency (kHz)';
        y_units = 'Threshold (dB SPL)';
        for cols = 1:length(average.y)
            % Average
            left_width = 0.60;
            right_width = 0.10; 
            height = 0.80;     
            figure(counter);
            % Click
            subplot('Position', [left_width+0.18,0.17, right_width, height-0.07]); hold on;
            errorbar(average.x{1,cols}, average.y{1,cols},average.y_std{1,cols},'Marker',shapes(cols,:),'LineStyle','none', 'linew', 2, 'Color', colors(cols,:), 'MarkerSize', 8, 'MarkerFaceColor', colors(cols,:), 'MarkerEdgeColor', colors(cols,:));
            xticks(average.x{1,1}); set(gca,'yticklabel',[]);
            xticklabels({'Click', '0.5', '1', '2', '4', '8'});
            set(gca,'FontSize',15); xlim([-1,1]);
            legend_string{1,cols} = sprintf('%s (n = %s)',cell2mat(Conds2Run(cols)),mat2str(sum(idx(:,cols))));
            legend(legend_string,'Location','southoutside','Orientation','horizontal','FontSize',8);
            grid on; set(legend,'visible','off')
            if ~isempty(ylimits_threshold)
                ylim(ylimits_threshold);
            end
            % Frequency
            subplot('Position', [0.15,0.10, left_width, height]); hold on;
            errorbar(average.x{1,cols}, average.y{1,cols},average.y_std{1,cols},'Marker',shapes(cols,:),'LineStyle','-', 'linew', 2, 'Color', colors(cols,:), 'MarkerSize', 8, 'MarkerFaceColor', colors(cols,:), 'MarkerEdgeColor', colors(cols,:));
            plot(average.x{1,cols}, average.y{1,cols},'Marker',shapes(cols,:),'LineStyle','-', 'linew', 2, 'MarkerSize', 8, 'Color', colors(cols,:),'MarkerFaceColor', colors(cols,:), 'MarkerEdgeColor', colors(cols,:))
            xticks(average.x{1,1});
            xticklabels({'Click', '0.5', '1', '2', '4', '8'});
            ylabel(y_units, 'FontWeight', 'bold');
            xlabel(x_units, 'FontWeight', 'bold');
            sgtitle(sprintf('ABR Thresholds | Average (n = %.0f)',sum(idx(:,1))), 'FontSize', 16,'FontWeight','bold');
            legend(legend_string,'Location','southoutside','Orientation','horizontal','FontSize',8);
            legend boxoff; hold off; grid on;
            if ~isempty(ylimits_threshold)
                ylim(ylimits_threshold);
            end
            set(gca,'FontSize',15);
            set(gca,'xscale','log'); set(legend,'visible','on'); xlim([-inf,inf]);
        end
    elseif strcmp(plot_type,'Peaks')
        x_units = 'Sound Level (dB SPL)';
        if strcmp(peak_analysis,'Amplitude')
            y_units = 'Peak-to-Peak Amplitude (\muV)';
            title_str = sprintf('ABR Peak-to-Peak Amplitude | Average (n = %.0f)',sum(idx(:,1)));
        elseif strcmp(peak_analysis,'Latency')
            y_units = 'Time (ms)';
            title_str = sprintf('ABR Absolute Peak Latency | Average (n = %.0f)',sum(idx(:,1)));
        end
        for cols = 1:length(average.w1)
            figure(counter); hold on; % wave 1
            w1 = errorbar(round(average.x{1,cols}(rows)), average.w1{1,cols}(rows),average.w1_std{1,cols}(rows),'Marker',shapes(1,:),'LineStyle','-', 'linew', 2, 'Color', colors(cols,:), 'MarkerSize', 8, 'MarkerFaceColor', colors(cols,:), 'MarkerEdgeColor', colors(cols,:));
            w1_fit = fillmissing(flip(average.w1{1,cols}(rows)),'linear','SamplePoints',flip(round(average.x{1,cols}(rows)))); w1_fit = flip(w1_fit);
            plot(round(average.x{1,cols}(rows)),w1_fit,'LineStyle','-', 'linew', 2, 'Color', colors(cols,:),'HandleVisibility','off');
            subtitle('Wave I'); xlim([-inf,inf]); grid on;
            ylabel(y_units, 'FontWeight', 'bold');
            xticks(round(unique(average.x{1,1}(rows))));
            xlabel(x_units, 'FontWeight', 'bold'); hold off;
            legend_string{1,cols} = sprintf('%s (n = %s)',cell2mat(Conds2Run(cols)),mat2str(sum(idx(:,cols))));
            legend(legend_string,'Location','southoutside','Orientation','horizontal');
            legend boxoff; set(gca,'FontSize',15); title(title_str, 'FontSize', 16);
            
            figure(counter+1); hold on; % wave 2
            w2 = errorbar(round(average.x{1,cols}(rows)), average.w2{1,cols}(rows),average.w2_std{1,cols}(rows),'Marker',shapes(2,:),'LineStyle','-', 'linew', 2, 'Color', colors(cols,:), 'MarkerSize', 8, 'MarkerFaceColor', colors(cols,:), 'MarkerEdgeColor', colors(cols,:));
            w2_fit = fillmissing(flip(average.w2{1,cols}(rows)),'linear','SamplePoints',flip(round(average.x{1,cols}(rows)))); w2_fit = flip(w2_fit);
            plot(round(average.x{1,cols}(rows)), w2_fit,'LineStyle','-', 'linew', 2, 'Color', colors(cols,:),'HandleVisibility','off'); grid on;
            xticks(round(unique(average.x{1,1}(rows))));
            subtitle('Wave II'); xlim([-inf,inf]);
            ylabel(y_units, 'FontWeight', 'bold'); grid on;
            xlabel(x_units, 'FontWeight', 'bold'); hold off;
            legend(legend_string,'Location','southoutside','Orientation','horizontal');
            legend boxoff; set(gca,'FontSize',15); title(title_str, 'FontSize', 16);
            
            figure(counter+2); hold on; % wave 3
            w3 = errorbar(round(average.x{1,cols}(rows)), average.w3{1,cols}(rows),average.w3_std{1,cols}(rows),'Marker',shapes(3,:),'LineStyle','-', 'linew', 2, 'Color', colors(cols,:), 'MarkerSize', 8, 'MarkerFaceColor', colors(cols,:), 'MarkerEdgeColor', colors(cols,:));
            w3_fit = fillmissing(flip(average.w3{1,cols}(rows)),'linear','SamplePoints',flip(round(average.x{1,cols}(rows)))); w3_fit = flip(w3_fit);
            plot(round(average.x{1,cols}(rows)), w3_fit,'LineStyle','-', 'linew', 2, 'Color', colors(cols,:),'HandleVisibility','off');
            ylabel(y_units, 'FontWeight', 'bold'); grid on;
            xticks(round(unique(average.x{1,1}(rows))));
            subtitle('Wave III'); xlim([-inf,inf]);
            ylabel(y_units, 'FontWeight', 'bold'); grid on;
            xlabel(x_units, 'FontWeight', 'bold'); hold off;
            legend(legend_string,'Location','southoutside','Orientation','horizontal');
            legend boxoff; set(gca,'FontSize',15); title(title_str, 'FontSize', 16);
            
            figure(counter+3); hold on; % wave 4
            w4 = errorbar(round(average.x{1,cols}(rows)), average.w4{1,cols}(rows),average.w4_std{1,cols}(rows),'Marker',shapes(4,:),'LineStyle','-', 'linew', 2, 'Color', colors(cols,:), 'MarkerSize', 8, 'MarkerFaceColor', colors(cols,:), 'MarkerEdgeColor', colors(cols,:));
            w4_fit = fillmissing(flip(average.w4{1,cols}(rows)),'linear','SamplePoints',flip(round(average.x{1,cols}(rows)))); w4_fit = flip(w4_fit);
            plot(round(average.x{1,cols}(rows)), w4_fit,'LineStyle','-', 'linew', 2, 'Color', colors(cols,:),'HandleVisibility','off'); grid on;
            xticks(round(unique(average.x{1,1}(rows))));
            subtitle('Wave IV'); xlim([-inf,inf]);
            ylabel(y_units, 'FontWeight', 'bold'); grid on;
            xticks(round(unique(average.x{1,1}(rows))));
            ylabel(y_units, 'FontWeight', 'bold'); grid on;
            xlabel(x_units, 'FontWeight', 'bold'); hold off;
            legend(legend_string,'Location','southoutside','Orientation','horizontal');
            legend boxoff; set(gca,'FontSize',15); title(title_str, 'FontSize', 16);
            
            figure(counter+4); hold on;% wave 5
            w5 = errorbar(round(average.x{1,cols}(rows)), average.w5{1,cols}(rows),average.w5_std{1,cols}(rows),'Marker',shapes(5,:),'LineStyle','-', 'linew', 2, 'Color', colors(cols,:), 'MarkerSize', 8, 'MarkerFaceColor', colors(cols,:), 'MarkerEdgeColor', colors(cols,:));
            w5_fit = fillmissing(flip(average.w5{1,cols}(rows)),'linear','SamplePoints',flip(round(average.x{1,cols}(rows)))); w5_fit = flip(w5_fit);
            plot(round(average.x{1,cols}(rows)), w5_fit,'LineStyle','-', 'linew', 2, 'Color', colors(cols,:),'HandleVisibility','off');
            xticks(round(unique(average.x{1,1}(rows)))); hold off; grid on;
            subtitle('Wave V'); xlim([-inf,inf]);
            ylabel(y_units, 'FontWeight', 'bold'); grid on;
            xticks(round(unique(average.x{1,1}(rows))));
            xlabel(x_units, 'FontWeight', 'bold'); hold off;
            ylabel(y_units, 'FontWeight', 'bold'); grid on;
            legend(legend_string,'Location','southoutside','Orientation','horizontal');
            legend boxoff; set(gca,'FontSize',15); title(title_str, 'FontSize', 16);
            
            figure(counter+5); hold on;% wave 1/5 ratio
            w1and5 = errorbar(round(average.x{1,cols}(rows)), average.w1and5{1,cols}(rows),average.w1and5_std{1,cols}(rows),'Marker',shapes(6,:),'LineStyle','-', 'linew', 2, 'Color', colors(cols,:), 'MarkerSize', 8, 'MarkerFaceColor', colors(cols,:), 'MarkerEdgeColor', colors(cols,:));
            w1and5_fit = fillmissing(flip(average.w1and5{1,cols}(rows)),'linear','SamplePoints',flip(round(average.x{1,cols}(rows)))); w1and5_fit = flip(w1and5_fit);
            plot(round(average.x{1,cols}(rows)), w1and5_fit,'LineStyle','-', 'linew', 2, 'Color', colors(cols,:),'HandleVisibility','off');
            xticks(round(unique(average.x{1,1}(rows))));
            xlabel(x_units, 'FontWeight', 'bold'); hold off; grid on;
            ylabel('Wave I/V Ratio', 'FontWeight', 'bold');
            subtitle('Wave I/V'); xlim([-inf,inf]);
            legend(legend_string,'Location','southoutside','Orientation','horizontal');
            legend boxoff; set(gca,'FontSize',15); title(title_str, 'FontSize', 16);
        end
    end
end

if ~isempty(idx_plot_relative)  %plot relative to
    if strcmp(plot_type,'Thresholds')
        x_units = 'Frequency (kHz)';
        y_units = sprintf('Threshold Shift (re. %s)',str_plot_relative{2});
        for cols = 1:length(average.y)
            % Average
            figure(counter); hold on;
            errorbar(average.x{1,cols}, average.y{1,cols},average.y_std{1,cols},'Marker',shapes(cols+1,:),'LineStyle','-', 'linew', 2, 'Color', colors(cols+1,:), 'MarkerSize', 8, 'MarkerFaceColor', colors(cols+1,:), 'MarkerEdgeColor', colors(cols+1,:));
            plot(average.x{1,cols}, average.y{1,cols},'LineStyle','-', 'linew', 2, 'Color', colors(cols+1,:),'HandleVisibility','off');
            plot(average.x{1,cols}, zeros(size(average.x{1,cols})),'LineStyle','--', 'linew', 2, 'Color', 'k','HandleVisibility','off');
            xticks(average.x{1,1});
            xticklabels({'Click', '0.5', '1', '2', '4', '8'});
            ylabel(y_units, 'FontWeight', 'bold');
            xlabel(x_units, 'FontWeight', 'bold');
            title(sprintf('ABR Thresholds | Average (n = %.0f)',sum(idx(:,1))), 'FontSize', 16);
            legend_string{1,cols} = sprintf('%s (n = %s)',cell2mat(Conds2Run(cols+1)),mat2str(sum(idx(:,cols+1))));
            legend(legend_string,'Location','southoutside','Orientation','horizontal','FontSize',8);
            legend boxoff; hold off; grid on;
            if ~isempty(ylimits_threshold)
                ylim(ylimits_threshold);
            end
            set(gca,'FontSize',15);
            set(gca,'xscale','log');
        end
    elseif strcmp(plot_type,'Peaks')
        x_units = 'Sound Level (dB SPL)';
        if strcmp(peak_analysis,'Amplitude')
            y_units = sprintf('Peak-to-Peak Amplitude Shift (re. %s)',str_plot_relative{2});
            title_str = sprintf('ABR Peak-to-Peak Amplitude | Average (n = %.0f)',sum(idx(:,1)));
        elseif strcmp(peak_analysis,'Latency')
            y_units = sprintf('Latency Shift (re. %s)',str_plot_relative{2});
            title_str = sprintf('ABR Absolute Peak Latency | Average (n = %.0f)',sum(idx(:,1)));
        end
        for cols = 1:length(average.w1)
            figure(counter); hold on; % wave 1
            w1 = errorbar(round(average.x{1,cols}(rows)), average.w1{1,cols}(rows),average.w1_std{1,cols}(rows),'Marker',shapes(1,:),'LineStyle','-', 'linew', 2, 'Color', colors(cols+1,:), 'MarkerSize', 8, 'MarkerFaceColor', colors(cols+1,:), 'MarkerEdgeColor', colors(cols+1,:));
            w1_fit = fillmissing(flip(average.w1{1,cols}(rows)),'linear','SamplePoints',flip(round(average.x{1,cols}(rows)))); w1_fit = flip(w1_fit);
            plot(round(average.x{1,cols}(rows)), w1_fit,'LineStyle','-', 'linew', 2, 'Color', colors(cols+1,:),'HandleVisibility','off');
            plot(round(average.x{1,cols}(rows)), zeros(size(average.x{1,cols}(rows))),'LineStyle','--', 'linew', 2, 'Color', 'k','HandleVisibility','off');
            subtitle('Wave I'); xlim([-inf,inf]); grid on;
            ylabel(y_units, 'FontWeight', 'bold');
            xticks(round(unique(average.x{1,1}(rows))));
            xlabel(x_units, 'FontWeight', 'bold'); hold off;
            legend_string{1,cols} = sprintf('%s (n = %s)',cell2mat(Conds2Run(cols)),mat2str(sum(idx(:,cols))));
            legend(legend_string,'Location','southoutside','Orientation','horizontal');
            legend boxoff; set(gca,'FontSize',15); title(title_str, 'FontSize', 16);
            
            
            figure(counter+1); hold on; % wave 2
            w2 = errorbar(round(average.x{1,cols}(rows)), average.w2{1,cols}(rows),average.w2_std{1,cols}(rows),'Marker',shapes(2,:),'LineStyle','-', 'linew', 2, 'Color', colors(cols+1,:), 'MarkerSize', 8, 'MarkerFaceColor', colors(cols+1,:), 'MarkerEdgeColor', colors(cols+1,:));
            w2_fit = fillmissing(flip(average.w2{1,cols}(rows)),'linear','SamplePoints',flip(round(average.x{1,cols}(rows)))); w2_fit = flip(w2_fit);
            plot(round(average.x{1,cols}(rows)), w2_fit,'LineStyle','-', 'linew', 2, 'Color', colors(cols+1,:),'HandleVisibility','off'); grid on;
            plot(round(average.x{1,cols}(rows)), zeros(size(average.x{1,cols}(rows))),'LineStyle','--', 'linew', 2, 'Color', 'k','HandleVisibility','off');
            xticks(round(unique(average.x{1,1}(rows))));
            subtitle('Wave II'); xlim([-inf,inf]);
            ylabel(y_units, 'FontWeight', 'bold'); grid on;
            xlabel(x_units, 'FontWeight', 'bold'); hold off;
            legend(legend_string,'Location','southoutside','Orientation','horizontal');
            legend boxoff; set(gca,'FontSize',15); title(title_str, 'FontSize', 16);
            
            
            figure(counter+2); hold on; % wave 3
            w3 = errorbar(round(average.x{1,cols}(rows)), average.w3{1,cols}(rows),average.w3_std{1,cols}(rows),'Marker',shapes(3,:),'LineStyle','-', 'linew', 2, 'Color', colors(cols+1,:), 'MarkerSize', 8, 'MarkerFaceColor', colors(cols+1,:), 'MarkerEdgeColor', colors(cols+1,:));
            w3_fit = fillmissing(flip(average.w3{1,cols}(rows)),'linear','SamplePoints',flip(round(average.x{1,cols}(rows)))); w3_fit = flip(w3_fit);
            plot(round(average.x{1,cols}(rows)), w3_fit,'LineStyle','-', 'linew', 2, 'Color', colors(cols+1,:),'HandleVisibility','off');
            plot(round(average.x{1,cols}(rows)), zeros(size(average.x{1,cols}(rows))),'LineStyle','--', 'linew', 2, 'Color', 'k','HandleVisibility','off');
            ylabel(y_units, 'FontWeight', 'bold'); grid on;
            xticks(round(unique(average.x{1,1}(rows))));
            subtitle('Wave III'); xlim([-inf,inf]);
            ylabel(y_units, 'FontWeight', 'bold'); grid on;
            xlabel(x_units, 'FontWeight', 'bold'); hold off;
            legend(legend_string,'Location','southoutside','Orientation','horizontal');
            legend boxoff; set(gca,'FontSize',15); title(title_str, 'FontSize', 16);
            
            
            figure(counter+3); hold on; % wave 4
            w4 = errorbar(round(average.x{1,cols}(rows)), average.w4{1,cols}(rows),average.w4_std{1,cols}(rows),'Marker',shapes(4,:),'LineStyle','-', 'linew', 2, 'Color', colors(cols+1,:), 'MarkerSize', 8, 'MarkerFaceColor', colors(cols+1,:), 'MarkerEdgeColor', colors(cols+1,:));
            w4_fit = fillmissing(flip(average.w4{1,cols}(rows)),'linear','SamplePoints',flip(round(average.x{1,cols}(rows)))); w4_fit = flip(w4_fit);
            plot(round(average.x{1,cols}(rows)), w4_fit,'LineStyle','-', 'linew', 2, 'Color', colors(cols+1,:),'HandleVisibility','off'); grid on;
            plot(round(average.x{1,cols}(rows)), zeros(size(average.x{1,cols}(rows))),'LineStyle','--', 'linew', 2, 'Color', 'k','HandleVisibility','off');
            xticks(round(unique(average.x{1,1}(rows))));
            subtitle('Wave IV'); xlim([-inf,inf]);
            ylabel(y_units, 'FontWeight', 'bold'); grid on;
            xticks(round(unique(average.x{1,1}(rows))));
            ylabel(y_units, 'FontWeight', 'bold'); grid on;
            xlabel(x_units, 'FontWeight', 'bold'); hold off;
            legend(legend_string,'Location','southoutside','Orientation','horizontal');
            legend boxoff; set(gca,'FontSize',15); title(title_str, 'FontSize', 16);
            
            
            figure(counter+4); hold on;% wave 5
            w5 = errorbar(round(average.x{1,cols}(rows)), average.w5{1,cols}(rows),average.w5_std{1,cols}(rows),'Marker',shapes(5,:),'LineStyle','-', 'linew', 2, 'Color', colors(cols+1,:), 'MarkerSize', 8, 'MarkerFaceColor', colors(cols+1,:), 'MarkerEdgeColor', colors(cols+1,:));
            w5_fit = fillmissing(flip(average.w5{1,cols}(rows)),'linear','SamplePoints',flip(round(average.x{1,cols}(rows)))); w5_fit = flip(w5_fit);
            plot(round(average.x{1,cols}(rows)), w5_fit,'LineStyle','-', 'linew', 2, 'Color', colors(cols+1,:),'HandleVisibility','off');
            plot(round(average.x{1,cols}(rows)), zeros(size(average.x{1,cols}(rows))),'LineStyle','--', 'linew', 2, 'Color', 'k','HandleVisibility','off');
            xticks(round(unique(average.x{1,1}(rows)))); hold off; grid on;
            subtitle('Wave V'); xlim([-inf,inf]);
            ylabel(y_units, 'FontWeight', 'bold'); grid on;
            xticks(round(unique(average.x{1,1}(rows))));
            xlabel(x_units, 'FontWeight', 'bold'); hold off;
            ylabel(y_units, 'FontWeight', 'bold'); grid on;
            legend(legend_string,'Location','southoutside','Orientation','horizontal');
            legend boxoff; set(gca,'FontSize',15); title(title_str, 'FontSize', 16);
            
            
            figure(counter+5); hold on;% wave 1/5 ratio
            w1and5 = errorbar(round(average.x{1,cols}(rows)), average.w1and5{1,cols}(rows),average.w1and5_std{1,cols}(rows),'Marker',shapes(1,:),'LineStyle','-', 'linew', 2, 'Color', colors(cols+1,:), 'MarkerSize', 8, 'MarkerFaceColor', colors(cols+1,:), 'MarkerEdgeColor', colors(cols+1,:));
            w1and5_fit = fillmissing(flip(average.w1and5{1,cols}(rows)),'linear','SamplePoints',flip(round(average.x{1,cols}(rows)))); w1and5_fit = flip(w1and5_fit);
            plot(round(average.x{1,cols}(rows)), w1and5_fit,'LineStyle','-', 'linew', 2, 'Color', colors(cols+1,:),'HandleVisibility','off');
            plot(round(average.x{1,cols}(rows)), zeros(size(average.x{1,cols}(rows))),'LineStyle','--', 'linew', 2, 'Color', 'k','HandleVisibility','off');
            xticks(round(unique(average.x{1,1}(rows))));
            xlabel(x_units, 'FontWeight', 'bold'); hold off; grid on;
            ylabel('Wave I/V Ratio', 'FontWeight', 'bold');
            subtitle('Wave I/V'); xlim([-inf,inf]);
            legend(legend_string,'Location','southoutside','Orientation','horizontal');
            legend boxoff; set(gca,'FontSize',15); title(title_str, 'FontSize', 16);
        end
    end
end
%% Export
cd(outpath);
print(figure(counter),[filename,'_w1_figure'],'-dpng','-r300');
print(figure(counter+1),[filename,'_w2_figure'],'-dpng','-r300');
print(figure(counter+2),[filename,'_w3_figure'],'-dpng','-r300');
print(figure(counter+3),[filename,'_w4_figure'],'-dpng','-r300');
print(figure(counter+4),[filename,'_w5_figure'],'-dpng','-r300');
print(figure(counter+5),[filename,'_w1and5_figure'],'-dpng','-r300');
end