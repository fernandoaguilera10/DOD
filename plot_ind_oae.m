function plot_ind_oae(data,plot_type,EXPname,colors,Conds2Run,Chins2Run,all_Conds2Run,ChinIND,CondIND,outpath,fig_num,ylimits,shapes)
global legend_string
legend_string= Conds2Run;
condition = strsplit(all_Conds2Run{CondIND}, filesep);
if strcmp(plot_type,'SPL')
    data_new = data.spl;
    y_units = 'Amplitude (dB SPL)';
elseif strcmp(plot_type,'EPL')
    data_new = data.epl;
    y_units = 'Amplitude (dB EPL)';
end
if strcmp(EXPname,'DPOAE')
    x_units = 'F2 Frequency (kHz)';
    filename = cell2mat([Chins2Run(ChinIND),'_DPOAEswept_',condition{2},'_',plot_type,'_']);
elseif strcmp(EXPname,'SFOAE')
    x_units = 'Frequency (kHz)';
    filename = cell2mat([Chins2Run(ChinIND),'_SFOAEswept_',condition{2},'_',plot_type,'_']);
elseif strcmp(EXPname,'TEOAE')
    x_units = 'Frequency (kHz)';
    filename = cell2mat([Chins2Run(ChinIND),'_TEOAE_',condition{2},'_',plot_type,'_']);
end
figure(fig_num); hold on;
%plot(data_new.f, data_new.oae,'-', 'linew', 2, 'Color', colors(CondIND,:),'HandleVisibility','off')
%plot(data_new.f, data_new.nf, '--', 'linew', 2, 'Color', [colors(CondIND,:),0.25],'HandleVisibility','off')
plot(data_new.centerFreq, data_new.bandOAE,'Marker',shapes(CondIND,:),'LineStyle','-', 'linew', 2, 'MarkerSize', 12, 'Color', colors(CondIND,:),'MarkerFaceColor', colors(CondIND,:), 'MarkerEdgeColor', colors(CondIND,:))
plot(data_new.centerFreq, data_new.bandNF, 'x','LineStyle','none', 'linew', 4, 'MarkerSize', 12, 'Color', colors(CondIND,:),'MarkerFaceColor', colors(CondIND,:), 'MarkerEdgeColor', colors(CondIND,:),'HandleVisibility','off')
plot(data_new.centerFreq, data_new.bandNF,'LineStyle','--', 'linew', 2, 'Color', [colors(CondIND,:),0.50],'HandleVisibility','off');
set(gca, 'XScale', 'log');
xlim([.5, 16])
ylim(ylimits);
xticks([.5, 1, 2, 4, 8, 16])
ylabel(y_units, 'FontWeight', 'bold')
xlabel(x_units, 'FontWeight', 'bold')
%legend_string{1,CondIND} = sprintf('%s',all_Conds2Run{CondIND});
legend(legend_string,'Location','southoutside','Orientation','horizontal')
legend boxoff
title(sprintf('%s | %s',EXPname,Chins2Run{ChinIND}))
set(gca,'FontSize',15);
set(gcf, 'Units', 'normalized', 'Position', [0.2 0.2 0.5 0.6]);
%% Export
cd(outpath);
print(figure(fig_num),[filename,'_figure'],'-dpng','-r300');
end