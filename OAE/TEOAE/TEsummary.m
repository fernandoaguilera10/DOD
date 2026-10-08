function TEsummary(outpath,OUTdir,PRIVATEdir,Conds2Run,Chins2Run,all_Conds2Run,ChinIND,CondIND,idx_plot_relative,ylimits_ind,ylimits_avg,shapes,colors,average_flag,conds_idx)% TEOAE summary
global te_f_epl te_amp_epl te_nf_epl te_f_band_epl te_amp_band_epl te_nf_band_epl
global te_f_spl te_amp_spl te_nf_spl te_f_band_spl te_amp_band_spl te_nf_band_spl
% Author: Fernando Aguilera de Alba
% Last Updated: 11 May 2024 by Fernando Aguilera de Alba
cwd = pwd;
%% INDIVIDUAL PLOTS
condition = strsplit(all_Conds2Run{CondIND}, filesep);
if exist(outpath,"dir")
    cd(PRIVATEdir)
    search_file = cell2mat(['*',Chins2Run(ChinIND),'_TEOAE_',condition{2},'*.mat']);
    datafile = load_files(outpath,search_file,'data',[],true);
    cd(outpath);
    load(datafile);
    cd(cwd);
    cd ..
    % Store globals for averaging (SPL)
    te_f_spl{ChinIND,CondIND} = data.spl.f';
    te_amp_spl{ChinIND,CondIND} = data.spl.oae;
    te_nf_spl{ChinIND,CondIND} = data.spl.nf;
    te_f_band_spl = data.spl.centerFreq';
    te_amp_band_spl{ChinIND,CondIND} = data.spl.bandOAE';
    te_nf_band_spl{ChinIND,CondIND} = data.spl.bandNF';
    plot_ind_oae(data,'TEOAE',colors,Conds2Run,Chins2Run,all_Conds2Run,ChinIND,CondIND,outpath,shapes,conds_idx)
    cd(cwd);
    cd ..
else
    fprintf('No directory found.\n');
end
%% AVERAGE PLOTS (individual + average)
fig_num_avg = ChinIND+1;
if average_flag == 1
    figure(fig_num_avg);
    if strcmp(get(0,'DefaultFigureVisible'),'off'), set(gcf,'Visible','off'); end
    clf;  % clear stale content before drawing
    % Compute average
    [average_spl,idx] = avg_oae(te_f_spl,te_amp_spl,te_nf_spl,te_f_band_spl,te_amp_band_spl,te_nf_band_spl,Chins2Run,Conds2Run,all_Conds2Run,fig_num_avg,colors,shapes,idx_plot_relative);
    % SPL-only average figure (TEOAE has no EPL)
    outpath = strcat(OUTdir,filesep,'OAE');
    plot_avg_oae({average_spl},{'SPL'},'TEOAE',colors,idx,conds_idx, ...
        Chins2Run,Conds2Run,all_Conds2Run,outpath, ...
        {'TEOAE_Average_SPL'},fig_num_avg,idx_plot_relative,shapes);
end
cd(cwd);
end