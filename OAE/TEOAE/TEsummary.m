function TEsummary(outpath,OUTdir,Conds2Run,Chins2Run,ChinIND,CondIND,idx_plot_relative,ylimits_ind,ylimits_avg,shapes,colors,average_flag)% TEOAE summary
global te_f_epl te_amp_epl te_nf_epl te_f_band_epl te_amp_band_epl te_nf_band_epl
global te_f_spl te_amp_spl te_nf_spl te_f_band_spl te_amp_band_spl te_nf_band_spl
% Author: Fernando Aguilera de Alba
% Last Updated: 11 May 2024 by Fernando Aguilera de Alba
cwd = pwd;
%% INDIVIDUAL PLOTS
condition = strsplit(Conds2Run{CondIND}, filesep);
if exist(outpath,"dir")
    cd(outpath)
    search_file = cell2mat(['*',Chins2Run(ChinIND),'_TEOAE_',condition{2},'*.mat']);
    datafile = load_files(outpath,search_file);
    load(datafile);
    cd(cwd);
    % PLOTTING SPL
    te_f_spl{ChinIND,CondIND} = data.spl.f';
    te_amp_spl{ChinIND,CondIND} = data.spl.oae;
    te_nf_spl{ChinIND,CondIND} = data.spl.nf;
    te_f_band_spl = data.spl.centerFreq';
    te_amp_band_spl{ChinIND,CondIND} = data.spl.bandOAE';
    te_nf_band_spl{ChinIND,CondIND} = data.spl.bandNF';
    fig_num_ind = ChinIND;
    plot_ind_oae(data,'SPL','TEOAE',colors,Conds2Run,Chins2Run,ChinIND,CondIND,outpath,fig_num_ind,ylimits_ind)
    cd(cwd);
else
    fprintf('No directory found.\n');
end
%% AVERAGE PLOTS (individual + average)
fig_num_avg = ChinIND+1;
if average_flag == 1
    % Plot individual lines
    [average_spl,idx] = avg_oae(te_f_spl,te_amp_spl,te_nf_spl,te_f_band_spl,te_amp_band_spl,te_nf_band_spl,Chins2Run,Conds2Run,fig_num_avg,colors,idx_plot_relative);
    % Plot average lines
    outpath = strcat(OUTdir,filesep,'OAE');
    filename_spl = 'TEOAE_Average_SPL';
    plot_avg_oae(average_spl,'SPL','TEOAE',colors,idx,Conds2Run,outpath,filename_spl,fig_num_avg,ylimits_avg,idx_plot_relative,shapes);
end
cd(cwd);
end