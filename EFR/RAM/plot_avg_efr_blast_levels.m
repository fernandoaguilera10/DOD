%all_Conds2Run = {strcat('pre',filesep,'Baseline'),strcat('post',filesep,'D3'),strcat('post',filesep,'D15'),strcat('post',filesep,'D43'),strcat('post',filesep,'D92'),strcat('post',filesep,'D107'),strcat('post',filesep,'D120')};
all_Conds2Run = {strcat('post',filesep,'D3'),strcat('post',filesep,'D15'),strcat('post',filesep,'D43'),strcat('post',filesep,'D92'),strcat('post',filesep,'D107'),strcat('post',filesep,'D120')};
level = 65;
ylimits = [-0.7,0.5];
x_units = 'Frequency (Hz)';
y_units = sprintf('PLV (re. Baseline)');
%shapes = ["o";"square";"diamond";"^";"v";">";"pentagram"];
%colors = [0,114,189; 237,177,32; 126,47,142; 119,172,48; 204,0,0; 255,51,255; 217 83 25]/255;
shapes = ["square";"diamond";"^";"v";">";"pentagram"];
colors = [237,177,32; 126,47,142; 119,172,48; 204,0,0; 255,51,255; 217 83 25]/255;

for cols = 1:length( average.peaks)
    if ~isempty(average.peaks_locs{1,cols})
        % Average
        figure(1); hold on;
        errorbar(average.peaks_locs{1,cols}, average.peaks{1,cols},average.peaks_std{1,cols},'Marker',shapes(cols,:),'LineStyle','none', 'linew', 2, 'Color', colors(cols,:), 'MarkerSize', 12, 'MarkerFaceColor', colors(cols,:), 'MarkerEdgeColor', colors(cols,:),'HandleVisibility','off');
        plot(average.peaks_locs{1,cols}, average.peaks{1,cols},'Marker',shapes(cols,:),'LineStyle','-', 'linew', 2,'Color', colors(cols,:), 'MarkerSize', 12, 'MarkerFaceColor', colors(cols,:), 'MarkerEdgeColor', colors(cols,:));
        %plot(average.peaks_locs{1,cols}, zeros(size(average.peaks_locs{1,cols})),'LineStyle','--', 'linew', 2,'Color', 'k','HandleVisibility','off');
        ylabel(y_units, 'FontWeight', 'bold');
        xlabel(x_units, 'FontWeight', 'bold');
        title(sprintf('EFR (f_m = 223 Hz) | %s dB SPL',mat2str(level)), 'FontSize', 16,'FontWeight','bold');
        temp{1,cols} = sprintf('%s',cell2mat(all_Conds2Run(cols)));
        legend_idx = find(~cellfun(@isempty,temp));
        legend_string = temp(legend_idx);
        %legend(legend_string,'Location','southoutside','Orientation','horizontal');
        %legend boxoff; hold off; grid on;
        if ~isempty(ylimits)
            ylim(ylimits);
        end
        idx_peaks = ~isnan(average.peaks{1,cols});
        x_max = round(max(average.peaks_locs{1,cols}(idx_peaks)),-3);
        xlim([0,x_max]); set(gca,'xscale','linear');
        set(gca,'FontSize',15); xticks(round(average.peaks_locs{1,cols}));
    end
end
