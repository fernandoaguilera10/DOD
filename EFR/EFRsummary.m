function EFRsummary(outpath,OUTdir,PRIVATEdir,Conds2Run,Chins2Run,all_Conds2Run,ChinIND,CondIND,ylimits,idx_plot_relative,all_levels,shapes,colors,average_flag,subject_idx,conds_idx,plot_type)
% EFR summary: loads data, fills globals, builds individual and average plots.
%   plot_type : 'RAM' | 'dAM'
global efr_f efr_envelope efr_PLV efr_peak_amp efr_peak_freq efr_peak_freq_all dim_f dim_envelope dim_PLV dim_peak_amp dim_peak_freq dim_peak_freq_all
global efr_trajectory efr_dAMpower efr_NFpower efr_trajectory_smooth efr_dAMpower_smooth efr_NFpower_smooth dim_trajectory dim_dAMpower dim_NFpower dim_dAMpower_smooth dim_NFpower_smooth
cwd = pwd;
condition = strsplit(all_Conds2Run{CondIND}, filesep);

%% Load data for every available level
data_by_level = cell(1, numel(all_levels));
if exist(outpath,'dir')
    for li = 1:numel(all_levels)
        cd(PRIVATEdir);
        search_file = cell2mat(['*',Chins2Run(ChinIND),'_EFR_',plot_type,'_',condition{2},'_',num2str(all_levels(li)),'dBSPL*.mat']);
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
    switch plot_type
        case 'RAM'
            efr_f{ChinIND,CondIND}             = efr_ref.f';
            efr_envelope{ChinIND,CondIND}      = efr_ref.t_env';
            efr_PLV{ChinIND,CondIND}           = efr_ref.plv_env';
            efr_peak_amp{ChinIND,CondIND}      = efr_ref.peaks;
            efr_peak_freq{ChinIND,CondIND}     = efr_ref.peaks_locs;
            efr_peak_freq_all{ChinIND,CondIND} = efr_ref.peaks_locs_all;
            dim_f             = size(efr_ref.f');
            dim_envelope      = size(efr_ref.t_env');
            dim_PLV           = size(efr_ref.plv_env');
            dim_peak_amp      = size(efr_ref.peaks);
            dim_peak_freq     = size(efr_ref.peaks_locs);
            dim_peak_freq_all = size(efr_ref.peaks_locs_all);
        case 'dAM'
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
    end

    %% Individual plot — accumulate this condition on the per-subject multi-level figure
    plot_ind_efr(data_by_level, all_levels, plot_type, colors, shapes, ...
        Conds2Run, Chins2Run, all_Conds2Run, ChinIND, CondIND, outpath, idx_plot_relative, conds_idx);

    %% Export individual figure when last condition for this subject is done
    if CondIND == conds_idx(end)
        subj_name = Chins2Run{ChinIND};
        fig_name  = [subj_name ' | EFR ' plot_type];
        fh = findobj('Type','figure','Name',fig_name);
        if ~isempty(fh)
            cd(outpath);
            drawnow;
            exportgraphics(fh(1), [subj_name '_EFR_' plot_type '_allLevels_figure.png'], 'Resolution',300);
            cd(cwd);
        end
    end
else
    switch plot_type
        case 'RAM'
            if ~isempty(dim_f)
                efr_f{ChinIND,CondIND}             = nan(dim_f);
                efr_envelope{ChinIND,CondIND}      = nan(dim_envelope);
                efr_PLV{ChinIND,CondIND}           = nan(dim_PLV);
                efr_peak_amp{ChinIND,CondIND}      = nan(dim_peak_amp);
                efr_peak_freq{ChinIND,CondIND}     = nan(dim_peak_freq);
                efr_peak_freq_all{ChinIND,CondIND} = nan(dim_peak_freq_all);
            end
        case 'dAM'
            if ~isempty(dim_trajectory)
                efr_trajectory{ChinIND,CondIND}        = nan(dim_trajectory);
                efr_dAMpower{ChinIND,CondIND}          = nan(dim_dAMpower);
                efr_NFpower{ChinIND,CondIND}           = nan(dim_NFpower);
                efr_trajectory_smooth{ChinIND,CondIND} = nan(dim_dAMpower_smooth);
                efr_dAMpower_smooth{ChinIND,CondIND}   = nan(dim_dAMpower_smooth);
                efr_NFpower_smooth{ChinIND,CondIND}    = nan(dim_NFpower_smooth);
            end
    end
    fprintf('No EFR %s data found for %s %s at any level.\n', plot_type, Chins2Run{ChinIND}, condition{2});
end

%% Average plots
fig_num_avg = length(Chins2Run)+1;
if average_flag == 1 && ~isempty(ref_li)
    switch plot_type
        case 'RAM'
            average = avg_efr(efr_peak_freq_all, efr_peak_amp, efr_f, efr_PLV, ...
                Chins2Run, Conds2Run, all_Conds2Run, fig_num_avg, colors, shapes, ...
                idx_plot_relative, subject_idx, conds_idx, plot_type);
            filename = ['EFR_RAM223_Average_', num2str(all_levels(ref_li)), 'dBSPL'];
        case 'dAM'
            average = avg_efr(efr_trajectory_smooth, efr_dAMpower_smooth, efr_NFpower_smooth, [], ...
                Chins2Run, Conds2Run, all_Conds2Run, fig_num_avg, colors, shapes, ...
                idx_plot_relative, subject_idx, conds_idx, plot_type);
            filename = ['EFR_dAM4kHz_Average_', num2str(all_levels(ref_li)), 'dBSPL'];
    end
    outpath_avg = strcat(OUTdir, filesep, 'EFR');
    plot_avg_efr(average, plot_type, all_levels(ref_li), colors, shapes, subject_idx, conds_idx, ...
        Chins2Run, Conds2Run, all_Conds2Run, outpath_avg, filename, fig_num_avg, ylimits, idx_plot_relative);
end
cd(cwd);
end
