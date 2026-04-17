function RAMsummary(outpath,OUTdir,PRIVATEdir,Conds2Run,Chins2Run,all_Conds2Run,ChinIND,CondIND,ylimits,idx_plot_relative,all_levels,shapes,colors,average_flag,subject_idx,conds_idx)% EFR RAM summary
global efr_f efr_envelope efr_PLV efr_peak_amp efr_peak_freq efr_peak_freq_all dim_f dim_envelope dim_PLV dim_peak_amp dim_peak_freq dim_peak_freq_all
cwd = pwd;
condition = strsplit(all_Conds2Run{CondIND}, filesep);

%% Load data for every available level
data_by_level = cell(1, numel(all_levels));
if exist(outpath,'dir')
    for li = 1:numel(all_levels)
        cd(PRIVATEdir);
        search_file = cell2mat(['*',Chins2Run(ChinIND),'_EFR_RAM_',condition{2},'_',num2str(all_levels(li)),'dBSPL*.mat']);
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
    efr_f{ChinIND,CondIND}            = efr_ref.f';
    efr_envelope{ChinIND,CondIND}     = efr_ref.t_env';
    efr_PLV{ChinIND,CondIND}          = efr_ref.plv_env';
    efr_peak_amp{ChinIND,CondIND}     = efr_ref.peaks;
    efr_peak_freq{ChinIND,CondIND}    = efr_ref.peaks_locs;
    efr_peak_freq_all{ChinIND,CondIND}= efr_ref.peaks_locs_all;
    dim_f            = size(efr_ref.f');
    dim_envelope     = size(efr_ref.t_env');
    dim_PLV          = size(efr_ref.plv_env');
    dim_peak_amp     = size(efr_ref.peaks);
    dim_peak_freq    = size(efr_ref.peaks_locs);
    dim_peak_freq_all= size(efr_ref.peaks_locs_all);

    %% Individual plot — accumulate this condition on the per-subject multi-level figure
    plot_ind_efr(data_by_level, all_levels, 'RAM', colors, shapes, ...
        Conds2Run, Chins2Run, all_Conds2Run, ChinIND, CondIND, outpath, idx_plot_relative, conds_idx);

    %% Export when last condition for this subject is done
    if CondIND == conds_idx(end)
        subj_name = Chins2Run{ChinIND};
        fig_name  = [subj_name ' | EFR RAM'];
        fh = findobj('Type','figure','Name',fig_name);
        if ~isempty(fh)
            cd(outpath);
            exportgraphics(fh(1), [subj_name '_EFR_RAM_allLevels_figure.png'], 'Resolution',300);
            cd(cwd);
        end
    end
else
    % No data found for any level — fill globals with NaN to keep cell array consistent
    if ~isempty(dim_f)
        efr_f{ChinIND,CondIND}             = nan(dim_f);
        efr_envelope{ChinIND,CondIND}      = nan(dim_envelope);
        efr_PLV{ChinIND,CondIND}           = nan(dim_PLV);
        efr_peak_amp{ChinIND,CondIND}      = nan(dim_peak_amp);
        efr_peak_freq{ChinIND,CondIND}     = nan(dim_peak_freq);
        efr_peak_freq_all{ChinIND,CondIND} = nan(dim_peak_freq_all);
    end
    fprintf('No EFR RAM data found for %s %s at any level.\n', Chins2Run{ChinIND}, condition{2});
end

%% Average plots
fig_num_avg = length(Chins2Run)+1;
if average_flag == 1
    average = avg_efr_RAM(efr_peak_freq_all, efr_peak_amp, efr_f, efr_PLV, ...
        Chins2Run, Conds2Run, all_Conds2Run, fig_num_avg, colors, shapes, ...
        idx_plot_relative, subject_idx, conds_idx);
    outpath_avg = strcat(OUTdir, filesep, 'EFR');
    ref_level   = all_levels(ref_li);
    filename    = ['EFR_RAM223_Average_', num2str(ref_level), 'dBSPL'];
    plot_avg_efr_RAM(average, 'RAM', ref_level, colors, shapes, subject_idx, conds_idx, ...
        Chins2Run, Conds2Run, all_Conds2Run, outpath_avg, filename, fig_num_avg, ylimits, idx_plot_relative);
end
cd(cwd);
end
