function plot_ind_oae(data,plot_type,EXPname,colors,Conds2Run,Chins2Run,ChinIND,CondIND,outpath,fig_num)
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
plot(data_new.f2, data_new.oae,'-', 'linew', 2, 'Color', colors(CondIND,:))
plot(data_new.f2, data_new.nf, '--', 'linew', 2, 'Color', [colors(CondIND,:),0.25],'HandleVisibility','off')
plot(data_new.centerFreq, data_new.bandOAE, 'o', 'linew', 2, 'MarkerSize', 8, 'MarkerFaceColor', colors(CondIND,:), 'MarkerEdgeColor', colors(CondIND,:),'HandleVisibility','off')
plot(data_new.centerFreq, data_new.bandNF, 'x', 'linew', 4, 'MarkerSize', 8, 'MarkerFaceColor', colors(CondIND,:), 'MarkerEdgeColor', colors(CondIND,:),'HandleVisibility','off')
set(gca, 'XScale', 'log', 'FontSize', 14)
xlim([.5, 16])
uplim = 0; lowlim = 0;
if CondIND > 1
    upperlim_temp = max(data_new.oae);
    lowerlim_temp = min(data_new.nf);
    if upperlim_temp > uplim
        uplim = upperlim_temp;
    end
    if lowerlim_temp < lowlim
        lowlim = lowerlim_temp;
    end
else
    lowlim = min(data_new.nf);
    uplim = max(data_new.oae);
end
ylim([round(lowlim - 5,1), round(uplim + 5,1)])
xticks([.5, 1, 2, 4, 8, 16])
ylabel(y_units, 'FontWeight', 'bold')
xlabel(x_units, 'FontWeight', 'bold')
legend(Conds2Run{CondIND},'Location','southoutside','Orientation','horizontal','FontSize',8)
legend boxoff
title(sprintf('%s | %s',EXPname,Chins2Run{ChinIND}), 'FontSize', 16)
%% Export
cd(outpath);
print(figure(fig_num),[filename,'_figure'],'-dpng','-r300');
end