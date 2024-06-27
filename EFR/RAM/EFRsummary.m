function EFRsummary(outpath,OUTdir,Conds2Run,Chins2Run,ChinIND,CondIND,ylimits,idx_plot_relative,level_spl)% EFR summary
global efr_f efr_envelope efr_PLV efr_peak_amp efr_peak_freq
cwd = pwd;
%colors = ["#0072BD"; "#EDB120"; "#7E2F8E"; "#77AC30"; "#A2142F"; "#FF33FF"];
colors = [0,114,189; 237,177,32; 126,47,142; 119,172,48; 162,20,47; 255,51,255]/255;
shapes = ["x";"^";"v";"diamond";"o";"*"];
%% INDIVIDUAL PLOTS
condition = strsplit(Conds2Run{CondIND}, filesep);
if exist(outpath,"dir")
    cd(outpath)
    search_file = cell2mat(['*',Chins2Run(ChinIND),'_EFR_RAM_',condition{2},'_',num2str(level_spl),'dBSPL*.mat']);
    datafile = load_files(outpath,search_file);
    load(datafile);
    cd(cwd);
    % PLOTTING SPL
    efr_f{ChinIND,CondIND} = efr.f';
    efr_envelope{ChinIND,CondIND} = efr.t_env';
    efr_PLV{ChinIND,CondIND} = efr.plv_env';
    efr_peak_amp{ChinIND,CondIND} = efr.peaks;
    efr_peak_freq{ChinIND,CondIND} = efr.peaks_locs;
    plot_ind_efr(efr,'RAM',colors,shapes,Conds2Run,Chins2Run,ChinIND,CondIND,outpath)
    cd(cwd)
else
    fprintf('No directory found.\n');
end
%% AVERAGE PLOTS (individual + average)
fig_num_avg = length(Chins2Run)+1;
if ChinIND == length(Chins2Run) && CondIND == length(Conds2Run)
    % Plot individual lines
    [average,idx] = avg_efr(efr_peak_freq,efr_peak_amp,efr_f,efr_PLV,Chins2Run,Conds2Run,fig_num_avg,colors,idx_plot_relative);
    % Plot average lines
    outpath = strcat(OUTdir,filesep,'EFR');
    filename = ['EFR_RAM223_Average_',num2str(level_spl),'dBSPL'];
    plot_avg_efr(average,'RAM',level_spl,colors,shapes,idx,Conds2Run,outpath,filename,fig_num_avg,ylimits,idx_plot_relative)
end
cd(cwd);
end