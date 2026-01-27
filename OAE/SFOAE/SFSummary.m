function SFsummary(outpath,OUTdir,PRIVATEdir,Conds2Run,Chins2Run,all_Conds2Run,ChinIND,CondIND,idx_plot_relative,ylimits_ind,ylimits_avg,shapes,colors,average_flag,conds_idx)% SFOAE swept summary
global sf_f_epl sf_amp_epl sf_nf_epl sf_f_band_epl sf_amp_band_epl sf_nf_band_epl
global sf_f_spl sf_amp_spl sf_nf_spl sf_f_band_spl sf_amp_band_spl sf_nf_band_spl
% Author: Fernando Aguilera de Alba
% Last Updated: 11 May 2024 by Fernando Aguilera de Alba
cwd = pwd;
%% INDIVIDUAL PLOTS
condition = strsplit(all_Conds2Run{CondIND}, filesep);
if exist(outpath,"dir")
    cd(PRIVATEdir)
    search_file = cell2mat(['*',Chins2Run(ChinIND),'_SFOAEswept_',condition{2},'*.mat']);
    datafile = load_files(outpath,search_file,'data');
    cd(outpath);
    load(datafile);
    cd(cwd);
    cd ..
    % PLOTTING EPL
    sf_f_epl{ChinIND,CondIND} = data.epl.f;
    sf_amp_epl{ChinIND,CondIND} = data.epl.oae';
    sf_nf_epl{ChinIND,CondIND} = data.epl.nf';
    sf_f_band_epl = data.epl.centerFreq';
    sf_amp_band_epl{ChinIND,CondIND} = data.epl.bandOAE';
    sf_nf_band_epl{ChinIND,CondIND} = data.epl.bandNF';
    fig_num_ind = 2*ChinIND-1;
    plot_ind_oae(data,'EPL','SFOAE',colors,Conds2Run,Chins2Run,all_Conds2Run,ChinIND,CondIND,outpath,fig_num_ind,ylimits_ind,shapes)
    % PLOTTING SPL
    sf_f_spl{ChinIND,CondIND} = data.spl.f;
    sf_amp_spl{ChinIND,CondIND} = data.spl.oae';
    sf_nf_spl{ChinIND,CondIND} = data.spl.nf';
    sf_f_band_spl = data.spl.centerFreq';
    sf_amp_band_spl{ChinIND,CondIND} = data.spl.bandOAE';
    sf_nf_band_spl{ChinIND,CondIND} = data.spl.bandNF';
    plot_ind_oae(data,'SPL','SFOAE',colors,Conds2Run,Chins2Run,all_Conds2Run,ChinIND,CondIND,outpath,fig_num_ind+1,ylimits_ind,shapes)
    cd(cwd);
    cd ..
else
    fprintf('No directory found.\n');
end
%% AVERAGE PLOTS (individual + average)
fig_num_avg = 2*length(Chins2Run);
if average_flag == 1
    % Plot individual lines
    [average_epl,idx] = avg_oae(sf_f_epl,sf_amp_epl,sf_nf_epl,sf_f_band_epl,sf_amp_band_epl,sf_nf_band_epl,Chins2Run,Conds2Run,all_Conds2Run,fig_num_avg+1,colors,shapes,idx_plot_relative);
    [average_spl,~] = avg_oae(sf_f_spl,sf_amp_spl,sf_nf_spl,sf_f_band_spl,sf_amp_band_spl,sf_nf_band_spl,Chins2Run,Conds2Run,all_Conds2Run,fig_num_avg+2,colors,shapes,idx_plot_relative);
    % Plot average lines
    outpath = strcat(OUTdir,filesep,'OAE');
    filename_epl = 'SFOAEswept_Average_EPL';
    plot_avg_oae(average_epl,'EPL','SFOAE',colors,idx,conds_idx,Chins2Run,Conds2Run,all_Conds2Run,outpath,filename_epl,fig_num_avg+1,ylimits_avg,idx_plot_relative,shapes)
    filename_spl = 'SFOAEswept_Average_SPL';
    plot_avg_oae(average_spl,'SPL','SFOAE',colors,idx,conds_idx,Chins2Run,Conds2Run,all_Conds2Run,outpath,filename_spl,fig_num_avg+2,ylimits_avg,idx_plot_relative,shapes);
end
cd(cwd);
end