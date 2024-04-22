%% EFRsummary
% Load Data
cwd = pwd;
if exist(outpath,"dir")
    cd(outpath)
    fname = ['*',subj,'_EFR_RAM_223_',condition,'_',num2str(level_spl),'dBSPL*.mat'];
    datafile = {dir(fname).name};
    if length(datafile) > 1
        fprintf('More than 1 data file. Check this is correct file!\n');
        datafile = {uigetfile(fname)};
    end
    load(datafile{1});
    cd(cwd);
    envelope{ChinIND,CondIND} = T_env';
    PLV{ChinIND,CondIND} = PLV_env';
    peak_amp{ChinIND,CondIND} = PKS;
    peak_freq{ChinIND,CondIND} = LOCS;
    %% Plot individual
    %colors = ["#0072BD"; "#EDB120"; "#7E2F8E"; "#77AC30"; "#A2142F"; "#FF33FF"];
    colors = [0,114,189; 237,177,32; 126,47,142; 119,172,48; 162,20,47; 255,51,255]/255;
    shapes = ["x";"^";"v";"diamond";"o";"*"];
    %Frequency Domain
    figure(ChinIND); hold on;
    title(sprintf('%s | EFR 223 Hz - 25%% Duty Cycle | %.0f dB SPL', subj, level_spl), 'FontSize', 16);
    xlabel('Frequency (Hz)', 'FontWeight', 'bold');
    ylabel('PLV','FontWeight', 'bold');
    if contains(str{1},'pre')
        plot(f,PLV{CondIND},'k','linewidth',2,'HandleVisibility','off');
        plot(peak_freq{CondIND},peak_amp{CondIND},'*k','linew', 2);
    else
        plot(peak_freq{CondIND},peak_amp{CondIND},'*','linew', 2, 'Color', [colors(CondIND,:),1]);
    end
    ylim([0,1]); hold off;
    legend_string = [legend_string; sprintf('%s',cell2mat(Conds2Run(CondIND)))];
    legend(legend_string,'Location','southoutside','Orientation','horizontal','FontSize',8)
    legend boxoff
    % Export:
    file_outpath = strcat(OUTdir,filesep,'Analysis',filesep,'EFR',filesep,Chins2Run{ChinIND});
    cd(file_outpath);
    fname = [subj,'_EFR_RAM223_All','_',num2str(level_spl),'dBSPL'];
    print(figure(ChinIND),[fname,'_figure'],'-dpng','-r300');
    cd(cwd);
else
    fprintf('No directory found.\n');
    count = count + 1;
    return
end
