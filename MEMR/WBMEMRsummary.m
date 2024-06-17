function WBMEMRsummary(outpath,OUTdir,Conds2Run,Chins2Run,ChinIND,CondIND,idx_plot_relative,xlimits)% WBMEMR Analysis
global elicitor deltapow
% Author: Fernando Aguilera de Alba
% Last Updated: 11 May 2024 by Fernando Aguilera de Alba
% Load Data
cwd = pwd;
%colors = ["#0072BD"; "#EDB120"; "#7E2F8E"; "#77AC30"; "#A2142F"; "#FF33FF"];
colors = [0,114,189; 237,177,32; 126,47,142; 119,172,48; 162,20,47; 255,51,255]/255;
shapes = ["x";"^";"v";"diamond";"o";"*"];
%% INDIVIDUAL PLOTS
condition = strsplit(Conds2Run{CondIND}, filesep);
if exist(outpath,"dir")
    cd(outpath)
    search_file = cell2mat(['*',Chins2Run(ChinIND),'_MEMR_WB_',condition{2},'*.mat']);
    datafile = load_files(outpath,search_file);
    load(datafile);
    cd(cwd);
    % PLOTTING FPL
    elicitor{ChinIND,CondIND} = memr.elicitor;
    deltapow{ChinIND,CondIND} = memr.deltapow';
    plot_ind_memr(memr,'MEMR',colors,Conds2Run,Chins2Run,ChinIND,CondIND,outpath,xlimits,shapes)
    cd(cwd);
else
    fprintf('No directory found.\n');
end
%% AVERAGE PLOTS (individual + average)
if ChinIND == length(Chins2Run) && CondIND == length(Conds2Run)
    % Plot individual lines
    [average,idx] = avg_memr(elicitor,deltapow,Chins2Run,Conds2Run,colors,idx_plot_relative);
    % Plot average lines
    outpath = strcat(OUTdir,filesep,'MEMR');
    filename = 'WBMEMR_Average';
    plot_avg_memr(average,'MEMR',colors,idx,Chins2Run,Conds2Run,outpath,filename,xlimits,idx_plot_relative,shapes)
end
cd(cwd);
end