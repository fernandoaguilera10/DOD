function dAMsummary(outpath,OUTdir,Conds2Run,Chins2Run,all_Conds2Run,ChinIND,CondIND,ylimits,idx_plot_relative,level_spl,shapes,colors,average_flag,subject_idx,conds_idx)% EFR summary
global efr_trajectory efr_dAMpower efr_NFpower dim_trajectory dim_dAMpower dim_NFpower
cwd = pwd;
%% INDIVIDUAL PLOTS
condition = strsplit(all_Conds2Run{CondIND}, filesep);
if exist(outpath,"dir")
    cd(outpath)
    search_file = cell2mat(['*',Chins2Run(ChinIND),'_EFR_dAM_',condition{2},'_',num2str(level_spl),'dBSPL*.mat']);
    datafile = load_files(outpath,search_file);
    load(datafile);
    cd(cwd);
    % PLOTTING SPL
    efr_trajectory{ChinIND,CondIND} = efr.trajectory';
    efr_dAMpower{ChinIND,CondIND} = efr.dAMpower';
    efr_NFpower{ChinIND,CondIND} = efr.NFpower';
    plot_ind_efr(efr,'dAM',colors,shapes,Conds2Run,Chins2Run,all_Conds2Run,ChinIND,CondIND,outpath,idx_plot_relative,subject_idx)
    cd(cwd)
    dim_trajectory = size(efr.trajectory');
    dim_dAMpower = size(efr.dAMpower');
    dim_NFpower = size(efr.NFpower');
else
    fprintf('No directory found.\n');
    efr_trajectory{ChinIND,CondIND} = nan(dim_trajectory);
    efr_dAMpower{ChinIND,CondIND} = nan(dim_dAMpower);
    efr_NFpower{ChinIND,CondIND} = nan(dim_NFpower);
end
%% AVERAGE PLOTS (individual + average)
fig_num_avg = length(Chins2Run)+1;
if average_flag == 1
    % Plot individual lines
    average = avg_efr_dAM(efr_trajectory,efr_dAMpower,efr_NFpower,Chins2Run,Conds2Run,all_Conds2Run,fig_num_avg,colors,shapes,idx_plot_relative,subject_idx,conds_idx);
    % Plot average lines
    outpath = strcat(OUTdir,filesep,'EFR');
    filename = ['EFR_dAM4kHz_Average_',num2str(level_spl),'dBSPL'];
    plot_avg_efr_dAM(average,'dAM',level_spl,colors,shapes,subject_idx,conds_idx,Chins2Run,Conds2Run,all_Conds2Run,outpath,filename,fig_num_avg,ylimits,idx_plot_relative)
end
cd(cwd);
end