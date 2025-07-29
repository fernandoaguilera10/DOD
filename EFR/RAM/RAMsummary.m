function RAMsummary(outpath,OUTdir,Conds2Run,Chins2Run,all_Conds2Run,ChinIND,CondIND,ylimits,idx_plot_relative,level_spl,shapes,colors,average_flag,subject_idx,conds_idx)% EFR summary
global efr_f efr_envelope efr_PLV efr_peak_amp efr_peak_freq efr_peak_freq_all dim_f dim_envelope dim_PLV dim_peak_amp dim_peak_freq dim_peak_freq_all
cwd = pwd;
%% INDIVIDUAL PLOTS
condition = strsplit(all_Conds2Run{CondIND}, filesep);
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
    efr_peak_freq_all{ChinIND,CondIND} = efr.peaks_locs_all;
    plot_ind_efr(efr,'RAM',colors,shapes,Conds2Run,Chins2Run,all_Conds2Run,ChinIND,CondIND,outpath,idx_plot_relative,subject_idx)
    cd(cwd)
    dim_f = size(efr.f');
    dim_envelope = size(efr.t_env');
    dim_PLV = size(efr.plv_env');
    dim_peak_amp = size(efr.peaks);
    dim_peak_freq = size(efr.peaks_locs);
    dim_peak_freq_all = size(efr.peaks_locs_all);
else
    fprintf('No directory found.\n');
    efr_f{ChinIND,CondIND} = nan(dim_f);
    efr_envelope{ChinIND,CondIND} = nan(dim_envelope);
    efr_PLV{ChinIND,CondIND} = nan(dim_PLV);
    efr_peak_amp{ChinIND,CondIND} = nan(dim_peak_amp);
    efr_peak_freq{ChinIND,CondIND} = nan(dim_peak_freq);
    efr_peak_freq_all{ChinIND,CondIND} = nan(dim_peak_freq_all);
end
%% AVERAGE PLOTS (individual + average)
fig_num_avg = length(Chins2Run)+1;
if average_flag == 1
    % Plot individual lines
    average = avg_efr_RAM(efr_peak_freq_all,efr_peak_amp,efr_f,efr_PLV,Chins2Run,Conds2Run,all_Conds2Run,fig_num_avg,colors,shapes,idx_plot_relative,subject_idx,conds_idx);
    % Plot average lines
    outpath = strcat(OUTdir,filesep,'EFR');
    filename = ['EFR_RAM223_Average_',num2str(level_spl),'dBSPL'];
    plot_avg_efr_RAM(average,'RAM',level_spl,colors,shapes,subject_idx,conds_idx,Chins2Run,Conds2Run,all_Conds2Run,outpath,filename,fig_num_avg,ylimits,idx_plot_relative)
end
cd(cwd);
end