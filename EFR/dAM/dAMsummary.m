function dAMsummary(outpath,OUTdir,PRIVATEdir,Conds2Run,Chins2Run,all_Conds2Run,ChinIND,CondIND,ylimits,idx_plot_relative,all_levels,shapes,colors,average_flag,subject_idx,conds_idx)% EFR dAM summary
global efr_trajectory efr_dAMpower efr_NFpower efr_trajectory_smooth efr_dAMpower_smooth efr_NFpower_smooth dim_trajectory dim_dAMpower dim_NFpower dim_dAMpower_smooth dim_NFpower_smooth
cwd = pwd;
condition = strsplit(all_Conds2Run{CondIND}, filesep);

%% Load data for every available level
data_by_level = cell(1, numel(all_levels));
if exist(outpath,'dir')
    for li = 1:numel(all_levels)
        cd(PRIVATEdir);
        search_file = cell2mat(['*',Chins2Run(ChinIND),'_EFR_dAM_',condition{2},'_',num2str(all_levels(li)),'dBSPL*.mat']);
        datafile = load_files(outpath, search_file, 'data', [], true);
        if ~isempty(datafile)
            cd(outpath); load(datafile); cd(cwd); %#ok<LOAD>
            data_by_level{li} = efr;
        else
            cd(cwd);
        end
    end
else
    fprintf('No directory found.\n');
end

%% Store globals — use highest found level as reference for average functions
ref_li = find(~cellfun(@isempty, data_by_level), 1, 'last');
if ~isempty(ref_li)
    efr_ref = data_by_level{ref_li};
    efr_trajectory{ChinIND,CondIND}        = efr_ref.trajectory';
    efr_dAMpower{ChinIND,CondIND}          = efr_ref.dAMpower';
    efr_NFpower{ChinIND,CondIND}           = efr_ref.NFpower';
    efr_trajectory_smooth{ChinIND,CondIND} = efr_ref.smooth.f';
    efr_dAMpower_smooth{ChinIND,CondIND}   = efr_ref.smooth.dAM';
    efr_NFpower_smooth{ChinIND,CondIND}    = efr_ref.smooth.NF';
    dim_trajectory      = size(efr_ref.trajectory');
    dim_dAMpower        = size(efr_ref.dAMpower');
    dim_NFpower         = size(efr_ref.NFpower');
    dim_dAMpower_smooth = size(efr_ref.smooth.dAM');
    dim_NFpower_smooth  = size(efr_ref.smooth.NF');

    %% Individual plot — accumulate this condition on the per-subject multi-level figure
    plot_ind_efr(data_by_level, all_levels, 'dAM', colors, shapes, ...
        Conds2Run, Chins2Run, all_Conds2Run, ChinIND, CondIND, outpath, idx_plot_relative, conds_idx);

    %% Export when last condition for this subject is done
    if CondIND == conds_idx(end)
        subj_name = Chins2Run{ChinIND};
        fig_name  = [subj_name ' | EFR dAM'];
        fh = findobj('Type','figure','Name',fig_name);
        if ~isempty(fh)
            cd(outpath);
            exportgraphics(fh(1), [subj_name '_EFR_dAM_allLevels_figure.png'], 'Resolution',300);
            cd(cwd);
        end
    end
else
    % No data found for any level
    if ~isempty(dim_trajectory)
        efr_trajectory{ChinIND,CondIND}        = nan(dim_trajectory);
        efr_dAMpower{ChinIND,CondIND}          = nan(dim_dAMpower);
        efr_NFpower{ChinIND,CondIND}           = nan(dim_NFpower);
        efr_trajectory_smooth{ChinIND,CondIND} = nan(dim_dAMpower_smooth);
        efr_dAMpower_smooth{ChinIND,CondIND}   = nan(dim_dAMpower_smooth);
        efr_NFpower_smooth{ChinIND,CondIND}    = nan(dim_NFpower_smooth);
    end
    fprintf('No EFR dAM data found for %s %s at any level.\n', Chins2Run{ChinIND}, condition{2});
end

%% Average plots
fig_num_avg = length(Chins2Run)+1;
if average_flag == 1
    average = avg_efr_dAM(efr_trajectory_smooth, efr_dAMpower_smooth, efr_NFpower_smooth, ...
        Chins2Run, Conds2Run, all_Conds2Run, fig_num_avg, colors, shapes, ...
        idx_plot_relative, subject_idx, conds_idx);
    outpath_avg = strcat(OUTdir, filesep, 'EFR');
    ref_level   = all_levels(ref_li);
    filename    = ['EFR_dAM4kHz_Average_', num2str(ref_level), 'dBSPL'];
    plot_avg_efr_dAM(average, 'dAM', ref_level, colors, shapes, subject_idx, conds_idx, ...
        Chins2Run, Conds2Run, all_Conds2Run, outpath_avg, filename, fig_num_avg, ylimits, idx_plot_relative);
end
cd(cwd);
end
