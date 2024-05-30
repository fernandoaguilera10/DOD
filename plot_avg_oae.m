function plot_avg_oae(average,plot_type,EXPname,colors,idx,Conds2Run,outpath,filename,counter)

if strcmp(plot_type,'SPL')
    y_units = 'Amplitude (dB SPL)';
    filename = 'DPOAEswept_Average_SPL';
elseif strcmp(plot_type,'EPL')
    y_units = 'Amplitude (dB EPL)';
    filename = 'DPOAEswept_Average_EPL';
end
if strcmp(EXPname,'DPOAE')
    x_units = 'F2 Frequency (kHz)';
else
    x_units = 'Frequency (kHz)';
end
legend_string = [];
N = 0;
for cols = 1:length(Conds2Run)
    % Average DP + NF
    N = N + sum(idx(:,cols));
    figure(counter+1); hold on;
    plot(average.f{1,cols}, average.oae{1,cols},'-', 'linew', 2, 'Color', colors(cols,:));
    plot(average.f{1,cols}, average.nf{1,cols},'--', 'linew', 2, 'Color', [colors(cols,:),0.50],'HandleVisibility','off');
    plot(average.bandF, average.bandOAE{1,cols}, 'o', 'linew', 2, 'MarkerSize', 8, 'MarkerFaceColor', colors(cols,:), 'MarkerEdgeColor', colors(cols,:),'HandleVisibility','off');
    plot(average.bandF, average.bandNF{1,cols}, 'x', 'linew', 4, 'MarkerSize', 8, 'MarkerFaceColor', colors(cols,:), 'MarkerEdgeColor', colors(cols,:),'HandleVisibility','off');
    uplim = max(average.oae{1,cols});
    lowlim = min(average.nf{1,cols});
    set(gca, 'XScale', 'log', 'FontSize', 14);
    ylim([round(lowlim - 5,1), round(uplim + 10,1)]);
    xlim([.5, 16]); xticks([.5, 1, 2, 4, 8, 16]);
    ylabel(y_units, 'FontWeight', 'bold');
    xlabel(x_units, 'FontWeight', 'bold');
    title(sprintf('%s | Average (n = %.0f)',EXPname,N), 'FontSize', 16);
    legend_string = [legend_string; sprintf('%s (n = %d)',cell2mat(Conds2Run(cols)),sum(idx(:,cols)))];
    legend(legend_string,'Location','southoutside','Orientation','horizontal','FontSize',8);
    legend boxoff; hold off;
    ylim([round(lowlim - 5,1), round(uplim + 5,1)]);
end
%% Export
cd(outpath);
print(figure(counter),[filename,'_figure'],'-dpng','-r300');
end