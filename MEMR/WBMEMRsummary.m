function WBMEMRsummary(outpath,OUTdir,PRIVATEdir,Conds2Run,Chins2Run,all_Conds2Run,ChinIND,CondIND,idx_plot_relative,xlimits,thresholdlimits,shapes,colors,average_flag,conds_idx)% WBMEMR Analysis
global elicitor deltapow threshold
% Author: Fernando Aguilera de Alba
% Last Updated: 11 May 2024 by Fernando Aguilera de Alba
% Load Data
cwd = pwd;
%% INDIVIDUAL PLOTS
condition = strsplit(all_Conds2Run{CondIND}, filesep);
if exist(outpath,"dir")
    cd(PRIVATEdir)
    search_file = cell2mat(['*',Chins2Run(ChinIND),'_MEMR_WB_',condition{2},'*.mat']);
    datafile = load_files(outpath,search_file);
    cd(outpath);
    load(datafile);
    % PLOTTING FPL
    elicitor{ChinIND,CondIND} = memr.elicitor;
    deltapow{ChinIND,CondIND} = memr.deltapow';
    threshold{ChinIND,CondIND} = memr.threshold;
    plot_ind_memr(memr,'MEMR',colors,Conds2Run,Chins2Run,all_Conds2Run,ChinIND,CondIND,outpath,xlimits,shapes)
    cd(cwd);
else
    fprintf('No directory found.\n');
end
%% AVERAGE PLOTS (individual + average)
if average_flag == 1
    % Plot individual lines
    [average,idx] = avg_memr(elicitor,deltapow,threshold,Chins2Run,Conds2Run,all_Conds2Run,colors,shapes,idx_plot_relative);
    % Plot average lines
    outpath = strcat(OUTdir,filesep,'MEMR');
    filename = 'WBMEMR_Average';
    plot_avg_memr(average,'MEMR',colors,idx,Chins2Run,Conds2Run,all_Conds2Run,outpath,filename,xlimits,thresholdlimits,idx_plot_relative,shapes,conds_idx)
end
cd(cwd);
end