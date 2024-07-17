function DPsummary(outpath,OUTdir,Conds2Run,Chins2Run,ChinIND,CondIND,idx_plot_relative,ylimits)% DPOAE swept summary
global dp_f_epl dp_amp_epl dp_nf_epl dp_f2_band_epl dp_amp_band_epl dp_nf_band_epl
global dp_f2_spl dp_amp_spl dp_nf_spl dp_f2_band_spl dp_amp_band_spl dp_nf_band_spl
% Author: Fernando Aguilera de Alba
% Last Updated: 11 May 2024 by Fernando Aguilera de Alba
cwd = pwd;
%colors = ["#0072BD"; "#EDB120"; "#7E2F8E"; "#77AC30"; "#A2142F"; "#FF33FF"];
colors = [0,114,189; 237,177,32; 126,47,142; 119,172,48; 162,20,47; 255,51,255]/255;
shapes = ["x";"^";"v";"diamond";"o";"*"];
%% INDIVIDUAL PLOTS
condition = strsplit(Conds2Run{CondIND}, filesep);
if exist(outpath,"dir")
    cd(outpath)
    search_file = cell2mat(['*',Chins2Run(ChinIND),'_DPOAEswept_',condition{2},'*.mat']);
    datafile = load_files(outpath,search_file);
    load(datafile);
    cd(cwd);
    % PLOTTING EPL
    dp_f_epl{ChinIND,CondIND} = data.epl.f;
    dp_amp_epl{ChinIND,CondIND} = data.epl.oae';
    dp_nf_epl{ChinIND,CondIND} = data.epl.nf';
    dp_f2_band_epl = data.epl.centerFreq';
    dp_amp_band_epl{ChinIND,CondIND} = data.epl.bandOAE';
    dp_nf_band_epl{ChinIND,CondIND} = data.epl.bandNF';
    fig_num_ind = 2*ChinIND-1;
    plot_ind_oae(data,'EPL','DPOAE',colors,Conds2Run,Chins2Run,ChinIND,CondIND,outpath,fig_num_ind,ylimits)
    % PLOTTING SPL
    dp_f2_spl{ChinIND,CondIND} = data.spl.f;
    dp_amp_spl{ChinIND,CondIND} = data.spl.oae';
    dp_nf_spl{ChinIND,CondIND} = data.spl.nf';
    dp_f2_band_spl = data.spl.centerFreq';
    dp_amp_band_spl{ChinIND,CondIND} = data.spl.bandOAE';
    dp_nf_band_spl{ChinIND,CondIND} = data.spl.bandNF';
    plot_ind_oae(data,'SPL','DPOAE',colors,Conds2Run,Chins2Run,ChinIND,CondIND,outpath,fig_num_ind+1,ylimits)
    cd(cwd);
else
    fprintf('No directory found.\n');
end
%% AVERAGE PLOTS (individual + average)
fig_num_avg = 2*length(Chins2Run);
if ChinIND == length(Chins2Run) && CondIND == length(Conds2Run)
    % Plot individual lines
    [average_epl,idx] = avg_oae(dp_f_epl,dp_amp_epl,dp_nf_epl,dp_f2_band_epl,dp_amp_band_epl,dp_nf_band_epl,Chins2Run,Conds2Run,fig_num_avg+1,colors,idx_plot_relative);
    [average_spl,~] = avg_oae(dp_f2_spl,dp_amp_spl,dp_nf_spl,dp_f2_band_spl,dp_amp_band_spl,dp_nf_band_spl,Chins2Run,Conds2Run,fig_num_avg+2,colors,idx_plot_relative);
    % Plot average lines
    outpath = strcat(OUTdir,filesep,'OAE');
    filename_epl = 'DPOAEswept_Average_EPL';
    plot_avg_oae(average_epl,'EPL','DPOAE',colors,idx,Conds2Run,outpath,filename_epl,fig_num_avg+1,ylimits,idx_plot_relative)
    filename_spl = 'DPOAEswept_Average_SPL';
    plot_avg_oae(average_spl,'SPL','DPOAE',colors,idx,Conds2Run,outpath,filename_spl,fig_num_avg+2,ylimits,idx_plot_relative);
end
cd(cwd);
end