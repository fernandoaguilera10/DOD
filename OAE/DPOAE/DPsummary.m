function DPsummary(outpath,OUTdir,PRIVATEdir,Conds2Run,Chins2Run,all_Conds2Run,ChinIND,CondIND,idx_plot_relative,ylimits_ind,ylimits_avg,shapes,colors,average_flag,conds_idx)% DPOAE swept summary
global dp_f_epl dp_amp_epl dp_nf_epl dp_f2_band_epl dp_amp_band_epl dp_nf_band_epl
global dp_f2_spl dp_amp_spl dp_nf_spl dp_f2_band_spl dp_amp_band_spl dp_nf_band_spl
% Author: Fernando Aguilera de Alba
% Last Updated: 11 May 2024 by Fernando Aguilera de Alba
cwd = pwd;
%% INDIVIDUAL PLOTS
condition = strsplit(all_Conds2Run{CondIND}, filesep);
if exist(outpath,"dir")
    cd(PRIVATEdir)
    search_file = cell2mat(['*',Chins2Run(ChinIND),'_DPOAEswept_',condition{2},'*.mat']);
    datafile = load_files(outpath,search_file,'data',[],true);
    cd(outpath);
    load(datafile);
    cd(cwd);
    cd ..
    % Store globals for averaging (EPL)
    dp_f_epl{ChinIND,CondIND} = data.epl.f;
    dp_amp_epl{ChinIND,CondIND} = data.epl.oae';
    dp_nf_epl{ChinIND,CondIND} = data.epl.nf';
    dp_f2_band_epl = data.epl.centerFreq';
    dp_amp_band_epl{ChinIND,CondIND} = data.epl.bandOAE';
    dp_nf_band_epl{ChinIND,CondIND} = data.epl.bandNF';
    % Store globals for averaging (SPL)
    dp_f2_spl{ChinIND,CondIND} = data.spl.f;
    dp_amp_spl{ChinIND,CondIND} = data.spl.oae';
    dp_nf_spl{ChinIND,CondIND} = data.spl.nf';
    dp_f2_band_spl = data.spl.centerFreq';
    dp_amp_band_spl{ChinIND,CondIND} = data.spl.bandOAE';
    dp_nf_band_spl{ChinIND,CondIND} = data.spl.bandNF';
    plot_ind_oae(data,'DPOAE',colors,Conds2Run,Chins2Run,all_Conds2Run,ChinIND,CondIND,outpath,shapes,conds_idx)
    cd(cwd);
    cd ..
else
    fprintf('No directory found.\n');
end
%% AVERAGE PLOTS (individual + average)
fig_num_avg = 2*length(Chins2Run);
if average_flag == 1
    figure(fig_num_avg+1);
    if strcmp(get(0,'DefaultFigureVisible'),'off'), set(gcf,'Visible','off'); end
    clf;  % clear stale content before drawing
    figure(fig_num_avg+2);
    if strcmp(get(0,'DefaultFigureVisible'),'off'), set(gcf,'Visible','off'); end
    clf;
    % Compute averages
    [average_epl,idx] = avg_oae(dp_f_epl,dp_amp_epl,dp_nf_epl,dp_f2_band_epl,dp_amp_band_epl,dp_nf_band_epl,Chins2Run,Conds2Run,all_Conds2Run,fig_num_avg+1,colors,shapes,idx_plot_relative);
    [average_spl,~]   = avg_oae(dp_f2_spl,dp_amp_spl,dp_nf_spl,dp_f2_band_spl,dp_amp_band_spl,dp_nf_band_spl,Chins2Run,Conds2Run,all_Conds2Run,fig_num_avg+2,colors,shapes,idx_plot_relative);
    % Combined EPL+SPL average figure
    outpath = strcat(OUTdir,filesep,'OAE');
    plot_avg_oae({average_epl,average_spl},{'EPL','SPL'},'DPOAE',colors,idx,conds_idx, ...
        Chins2Run,Conds2Run,all_Conds2Run,outpath, ...
        {'DPOAEswept_Average_EPL','DPOAEswept_Average_SPL'},fig_num_avg+1,idx_plot_relative,shapes);
end
cd(cwd);
end