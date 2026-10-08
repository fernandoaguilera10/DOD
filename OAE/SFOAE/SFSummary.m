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
    datafile = load_files(outpath,search_file,'data',[],true);
    cd(outpath);
    load(datafile);
    cd(cwd);
    cd ..
    % Store globals for averaging (EPL)
    sf_f_epl{ChinIND,CondIND} = data.epl.f;
    sf_amp_epl{ChinIND,CondIND} = data.epl.oae';
    sf_nf_epl{ChinIND,CondIND} = data.epl.nf';
    sf_f_band_epl = data.epl.centerFreq';
    sf_amp_band_epl{ChinIND,CondIND} = data.epl.bandOAE';
    sf_nf_band_epl{ChinIND,CondIND} = data.epl.bandNF';
    % Store globals for averaging (SPL)
    sf_f_spl{ChinIND,CondIND} = data.spl.f;
    sf_amp_spl{ChinIND,CondIND} = data.spl.oae';
    sf_nf_spl{ChinIND,CondIND} = data.spl.nf';
    sf_f_band_spl = data.spl.centerFreq';
    sf_amp_band_spl{ChinIND,CondIND} = data.spl.bandOAE';
    sf_nf_band_spl{ChinIND,CondIND} = data.spl.bandNF';
    plot_ind_oae(data,'SFOAE',colors,Conds2Run,Chins2Run,all_Conds2Run,ChinIND,CondIND,outpath,shapes,conds_idx)
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
    [average_epl,idx] = avg_oae(sf_f_epl,sf_amp_epl,sf_nf_epl,sf_f_band_epl,sf_amp_band_epl,sf_nf_band_epl,Chins2Run,Conds2Run,all_Conds2Run,fig_num_avg+1,colors,shapes,idx_plot_relative);
    [average_spl,~]   = avg_oae(sf_f_spl,sf_amp_spl,sf_nf_spl,sf_f_band_spl,sf_amp_band_spl,sf_nf_band_spl,Chins2Run,Conds2Run,all_Conds2Run,fig_num_avg+2,colors,shapes,idx_plot_relative);
    % Combined EPL+SPL average figure
    outpath = strcat(OUTdir,filesep,'OAE');
    plot_avg_oae({average_epl,average_spl},{'EPL','SPL'},'SFOAE',colors,idx,conds_idx, ...
        Chins2Run,Conds2Run,all_Conds2Run,outpath, ...
        {'SFOAEswept_Average_EPL','SFOAEswept_Average_SPL'},fig_num_avg+1,idx_plot_relative,shapes);
end
cd(cwd);
end