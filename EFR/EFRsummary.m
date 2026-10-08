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

%% Store globals per level (3D: {ChinIND, CondIND, LevelIND})
for li = 1:numel(all_levels)
    if ~isempty(data_by_level{li})
        d = data_by_level{li};
        switch plot_type
            case 'RAM'
                efr_f{ChinIND,CondIND,li}             = d.f';
                efr_envelope{ChinIND,CondIND,li}      = d.t_env';
                efr_PLV{ChinIND,CondIND,li}           = d.plv_env';
                efr_peak_amp{ChinIND,CondIND,li}      = d.peaks;
                efr_peak_freq{ChinIND,CondIND,li}     = d.peaks_locs;
                efr_peak_freq_all{ChinIND,CondIND,li} = d.peaks_locs_all;
                if isempty(dim_f)
                    dim_f             = size(d.f');
                    dim_envelope      = size(d.t_env');
                    dim_PLV           = size(d.plv_env');
                    dim_peak_amp      = size(d.peaks);
                    dim_peak_freq     = size(d.peaks_locs);
                    dim_peak_freq_all = size(d.peaks_locs_all);
                end
            case 'dAM'
                efr_trajectory{ChinIND,CondIND,li}        = d.trajectory';
                efr_dAMpower{ChinIND,CondIND,li}          = d.dAMpower';
                efr_NFpower{ChinIND,CondIND,li}           = d.NFpower';
                efr_trajectory_smooth{ChinIND,CondIND,li} = d.smooth.f';
                efr_dAMpower_smooth{ChinIND,CondIND,li}   = d.smooth.dAM';
                efr_NFpower_smooth{ChinIND,CondIND,li}    = d.smooth.NF';
                if isempty(dim_trajectory)
                    dim_trajectory      = size(d.trajectory');
                    dim_dAMpower        = size(d.dAMpower');
                    dim_NFpower         = size(d.NFpower');
                    dim_dAMpower_smooth = size(d.smooth.dAM');
                    dim_NFpower_smooth  = size(d.smooth.NF');
                end
        end
    end
end

ref_li = find(~cellfun(@isempty, data_by_level), 1, 'last');

if ~isempty(ref_li)
    %% Individual plot — accumulate this condition on the per-subject multi-level figure
    plot_ind_efr(data_by_level, all_levels, plot_type, colors, shapes, ...
        Conds2Run, Chins2Run, all_Conds2Run, ChinIND, CondIND, outpath, idx_plot_relative, conds_idx);

    %% Export individual figures when last condition for this subject is done
    if CondIND == conds_idx(end)
        subj_name = Chins2Run{ChinIND};
        cd(outpath); drawnow;
        % Summary: one figure for all conditions
        fh = findobj('Type','figure','Name', sprintf('Summary|EFR %s', plot_type));
        if ~isempty(fh)
            exportgraphics(fh(1), sprintf('%s_EFR_%s_Summary_figure.png', subj_name, plot_type),'Resolution',300);
        end
        % Time Domain and Frequency Domain: one figure per condition
        for ci = 1:numel(conds_idx)
            cp = strsplit(all_Conds2Run{conds_idx(ci)}, filesep);
            cl = cp{end};
            if strcmp(plot_type,'RAM')
                fh = findobj('Type','figure','Name', sprintf('Time Domain|%s', cl));
                if ~isempty(fh)
                    exportgraphics(fh(1), sprintf('%s_EFR_%s_TimeDomain_%s_figure.png', subj_name, plot_type, cl),'Resolution',300);
                end
            end
            fh = findobj('Type','figure','Name', sprintf('Frequency Domain|%s', cl));
            if ~isempty(fh)
                exportgraphics(fh(1), sprintf('%s_EFR_%s_FreqDomain_%s_figure.png', subj_name, plot_type, cl),'Resolution',300);
            end
        end
        cd(cwd);
    end
else
    switch plot_type
        case 'RAM'
            if ~isempty(dim_f)
                for li = 1:numel(all_levels)
                    efr_f{ChinIND,CondIND,li}             = nan(dim_f);
                    efr_envelope{ChinIND,CondIND,li}      = nan(dim_envelope);
                    efr_PLV{ChinIND,CondIND,li}           = nan(dim_PLV);
                    efr_peak_amp{ChinIND,CondIND,li}      = nan(dim_peak_amp);
                    efr_peak_freq{ChinIND,CondIND,li}     = nan(dim_peak_freq);
                    efr_peak_freq_all{ChinIND,CondIND,li} = nan(dim_peak_freq_all);
                end
            end
        case 'dAM'
            if ~isempty(dim_trajectory)
                for li = 1:numel(all_levels)
                    efr_trajectory{ChinIND,CondIND,li}        = nan(dim_trajectory);
                    efr_dAMpower{ChinIND,CondIND,li}          = nan(dim_dAMpower);
                    efr_NFpower{ChinIND,CondIND,li}           = nan(dim_NFpower);
                    efr_trajectory_smooth{ChinIND,CondIND,li} = nan(dim_dAMpower_smooth);
                    efr_dAMpower_smooth{ChinIND,CondIND,li}   = nan(dim_dAMpower_smooth);
                    efr_NFpower_smooth{ChinIND,CondIND,li}    = nan(dim_NFpower_smooth);
                end
            end
    end
    fprintf('No EFR %s data found for %s %s at any level.\n', plot_type, Chins2Run{ChinIND}, condition{2});
end

%% Average plots — one figure per level
if average_flag == 1
    outpath_avg = strcat(OUTdir, filesep, 'EFR');
    fig_num_avg = length(Chins2Run) + 1;
    all_averages_ram = cell(1, numel(all_levels));
    all_averages_dAM = cell(1, numel(all_levels));
    for li = 1:numel(all_levels)
        switch plot_type
            case 'RAM'
                if li > size(efr_peak_freq_all, 3), continue; end
                sl_x   = efr_peak_freq_all(:,:,li);
                sl_y   = efr_peak_amp(:,:,li);
                sl_f   = efr_f(:,:,li);
                sl_plv = efr_PLV(:,:,li);
                if all(cellfun(@isempty, sl_x(:))), continue; end
                average = avg_efr(sl_x, sl_y, sl_f, sl_plv, ...
                    Chins2Run, Conds2Run, all_Conds2Run, fig_num_avg, colors, shapes, ...
                    idx_plot_relative, subject_idx, conds_idx, plot_type);
                all_averages_ram{li} = average;
                filename = ['EFR_RAM223_Average_', num2str(all_levels(li)), 'dBSPL'];
            case 'dAM'
                if li > size(efr_trajectory_smooth, 3), continue; end
                sl_x  = efr_trajectory_smooth(:,:,li);
                sl_y  = efr_dAMpower_smooth(:,:,li);
                sl_nf = efr_NFpower_smooth(:,:,li);
                if all(cellfun(@isempty, sl_x(:))), continue; end
                average = avg_efr(sl_x, sl_y, sl_nf, [], ...
                    Chins2Run, Conds2Run, all_Conds2Run, fig_num_avg, colors, shapes, ...
                    idx_plot_relative, subject_idx, conds_idx, plot_type);
                all_averages_dAM{li} = average;
                filename = ['EFR_dAM4kHz_Average_', num2str(all_levels(li)), 'dBSPL'];
        end
        plot_avg_efr(average, plot_type, all_levels(li), colors, shapes, subject_idx, conds_idx, ...
            Chins2Run, Conds2Run, all_Conds2Run, outpath_avg, filename, fig_num_avg, ylimits, idx_plot_relative);
        fig_num_avg = fig_num_avg + 1;
    end
    if strcmp(plot_type, 'RAM') && any(~cellfun(@isempty, all_averages_ram))
        plot_avg_efr_tabs(all_averages_ram, all_levels, colors, shapes, subject_idx, conds_idx, ...
            Chins2Run, Conds2Run, all_Conds2Run, outpath_avg, ylimits, idx_plot_relative);
    end
    if strcmp(plot_type, 'dAM') && any(~cellfun(@isempty, all_averages_dAM))
        plot_avg_efr_dAM_tabs(all_averages_dAM, all_levels, colors, shapes, subject_idx, ...
            all_Conds2Run, idx_plot_relative);
    end
end
cd(cwd);
end
