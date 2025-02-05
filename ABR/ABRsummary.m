function ABRsummary(outpath,OUTdir,Conds2Run,Chins2Run,ChinIND,CondIND,idx_plot_relative,ylimits_ind,ylimits_avg,colors,shapes,analysis_type)% ABR summary
global abr_f abr_thresholds
cwd = pwd;
%% INDIVIDUAL PLOTS
condition = strsplit(Conds2Run{CondIND}, filesep);
if exist(outpath,"dir")
    cd(outpath)
    if strcmp(analysis_type,'Thresholds') 
        search_file = cell2mat([Chins2Run(ChinIND),'_',condition{1},condition{2},'_ABRdata.mat']);
        datafile = load_files(outpath,search_file);
        load(datafile);
        cd(cwd);
        % PLOTTING SPL
        abr_f{ChinIND,CondIND} = abr_out.freqs;
        abr_thresholds{ChinIND,CondIND} = abr_out.thresholds;
        plot_ind_abr(abr_out,analysis_type,colors,shapes,Conds2Run,Chins2Run,ChinIND,CondIND,outpath,ylimits_ind)
    elseif strcmp(analysis_type,'Peaks')
        %% TBD
        search_file = cell2mat(['*',Chins2Run(ChinIND),'_',condition{1},condition{2},'_ABRpeaks*.mat']);
        datafile = load_files(outpath,search_file);
        load(datafile);
        cd(cwd);
        abrs.plot
    end
    cd(cwd)
else
    fprintf('No directory found.\n');
end
%% AVERAGE PLOTS (individual + average)
fig_num_avg = length(Chins2Run)+1;
if ChinIND == length(Chins2Run) && CondIND == length(Conds2Run)
    if strcmp(analysis_type,'Thresholds')
        % Plot individual lines
        [average,idx] = avg_abr(abr_f,abr_thresholds,Chins2Run,Conds2Run,fig_num_avg,colors,idx_plot_relative);
        % Plot average lines
        outpath = strcat(OUTdir,filesep,'ABR');
        filename = 'ABR_Thresholds_Average_dBSPL';
        plot_avg_abr(average,'Thresholds',colors,shapes,idx,Conds2Run,outpath,filename,fig_num_avg,ylimits_avg,idx_plot_relative)
    elseif strcmp(analysis_type,'Peaks')
        %% TBD
    end
end
cd(cwd);
end