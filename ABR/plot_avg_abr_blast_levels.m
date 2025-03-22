%average = avg_75kpa;
average = avg_150kpa;
%all_Conds2Run = {strcat('pre',filesep,'Baseline'),strcat('post',filesep,'D3'),strcat('post',filesep,'D15'),strcat('post',filesep,'D43'),strcat('post',filesep,'D92'),strcat('post',filesep,'D107'),strcat('post',filesep,'D120')};
all_Conds2Run = {strcat('post',filesep,'D3'),strcat('post',filesep,'D15'),strcat('post',filesep,'D43'),strcat('post',filesep,'D92'),strcat('post',filesep,'D107'),strcat('post',filesep,'D120')};
ylimits_threshold = [-10,50];
x_units = 'Frequency (kHz)';
y_units = sprintf('Threshold Shift (re. Baseline)');
%shapes = ["o";"square";"diamond";"^";"v";">";"pentagram"];
%colors = [0,114,189; 237,177,32; 126,47,142; 119,172,48; 204,0,0; 255,51,255; 217 83 25]/255;
shapes = ["square";"diamond";"^";"v";">";"pentagram"];
colors = [237,177,32; 126,47,142; 119,172,48; 204,0,0; 255,51,255; 217 83 25]/255;

for cols = 1:length(average.y)
    if ~isempty(average.x{1,cols})
        % Average
        freq = 1:length(average.x{1,cols});
        freq_threshold = [nan,average.y{1,cols}(2:end)];
        figure(1); hold on;
        errorbar(freq, average.y{1,cols},average.y_std{1,cols},'Marker',shapes(cols,:),'LineStyle','none', 'linew', 2, 'Color', colors(cols,:), 'MarkerSize', 12, 'MarkerFaceColor', colors(cols,:), 'MarkerEdgeColor', colors(cols,:),'HandleVisibility','off');
        plot(freq, freq_threshold,'Marker',shapes(cols,:),'LineStyle','--', 'linew', 2,'Color', colors(cols,:), 'MarkerSize', 12, 'MarkerFaceColor', colors(cols,:), 'MarkerEdgeColor', colors(cols,:));
        xticks(freq); xlim([0.5,6.5]);
        xticklabels({'Click', '0.5', '1', '2', '4', '8'});
        ylabel(y_units, 'FontWeight', 'bold');
        xlabel(x_units, 'FontWeight', 'bold');
        title(sprintf('ABR Thresholds'), 'FontSize', 16,'FontWeight','bold');
        temp{1,cols} = sprintf('%s',cell2mat(all_Conds2Run(cols)));
        legend_idx = find(~cellfun(@isempty,temp));
        legend_string = temp(legend_idx);
        legend(legend_string,'Location','southoutside','Orientation','horizontal');
        legend boxoff; hold off; grid on;
        if ~isempty(ylimits_threshold)
            ylim(ylimits_threshold);
        end
        set(gca,'FontSize',15);
    end
end
