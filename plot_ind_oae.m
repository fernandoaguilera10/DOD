function plot_ind_oae(data,plot_type,EXPname,colors,Conds2Run,Chins2Run,ChinIND,CondIND,outpath,fig_num,ylimits)
global legend_string
condition = strsplit(Conds2Run{CondIND}, filesep);
if strcmp(plot_type,'SPL')
    data_new = data.spl;
    y_units = 'Amplitude (dB SPL)';
    filename = cell2mat([Chins2Run(ChinIND),'_DPOAEswept_',condition{2},'_SPL_']);
elseif strcmp(plot_type,'EPL')
    data_new = data.epl;
    y_units = 'Amplitude (dB EPL)';
    filename = cell2mat([Chins2Run(ChinIND),'_DPOAEswept_',condition{2},'_EPL_']);
end
if strcmp(EXPname,'DPOAE')
    x_units = 'F2 Frequency (kHz)';
else
    x_units = 'Frequency (kHz)';
end
figure(fig_num); hold on;
plot(data_new.f, data_new.oae,'-', 'linew', 2, 'Color', colors(CondIND,:))
plot(data_new.f, data_new.nf, '--', 'linew', 2, 'Color', [colors(CondIND,:),0.25],'HandleVisibility','off')
plot(data_new.centerFreq, data_new.bandOAE, 'o', 'linew', 2, 'MarkerSize', 8, 'MarkerFaceColor', colors(CondIND,:), 'MarkerEdgeColor', colors(CondIND,:),'HandleVisibility','off')
plot(data_new.centerFreq, data_new.bandNF, 'x', 'linew', 4, 'MarkerSize', 8, 'MarkerFaceColor', colors(CondIND,:), 'MarkerEdgeColor', colors(CondIND,:),'HandleVisibility','off')
set(gca, 'XScale', 'log', 'FontSize', 14)
xlim([.5, 16])
ylim(ylimits);
xticks([.5, 1, 2, 4, 8, 16])
ylabel(y_units, 'FontWeight', 'bold')
xlabel(x_units, 'FontWeight', 'bold')
legend_string{1,CondIND} = sprintf('%s',Conds2Run{CondIND});
legend(legend_string,'Location','southoutside','Orientation','horizontal','FontSize',8)
legend boxoff
title(sprintf('%s | %s',EXPname,Chins2Run{ChinIND}), 'FontSize', 16)
%% Export
cd(outpath);
print(figure(fig_num),[filename,'_figure'],'-dpng','-r300');
end