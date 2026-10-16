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
        search_file = cell2mat(['*',Chins2Run(ChinIND),'_EFR_',plot_type,'_',condition{2},'_',num2str(all_levels(li)),'dBSPL*.mat']);
        datafile = load_files(outpath, search_file, 'data', [], true);
        if ~isempty(datafile)
            S_efr = load(fullfile(outpath, datafile), 'efr');  efr = S_efr.efr;
            if strcmp(plot_type,'dAM') && isfield(efr,'trajectory') && isfield(efr,'NFpower')
                % Re-band the saved dAM power with the Setup "dAM bands" value
                % (no re-analysis needed).
                o = efr_opts();
                [efr.smooth.f, efr.smooth.dAM, efr.smooth.NF] = ...
                    efr_dam_smooth(efr.trajectory, efr.dAMpower, efr.NFpower, o.dam_bands);
            end
            data_by_level{li} = efr;
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

    %% Rows of this recording (kept for the average files) + its CSV (one per
    %% level file, next to its .mat; Setup "Data Export" CSV / Both)
    for li = find(~cellfun(@isempty, data_by_level))
        try
            T = efr_rows(Chins2Run{ChinIND}, condition{end}, all_levels(li), data_by_level{li}, plot_type);
            apat_csv('rec', ['efr_' plot_type], sprintf('%s|%s|%g', Chins2Run{ChinIND}, condition{end}, all_levels(li)), T, ...
                fullfile(outpath, sprintf('%s_EFR%s_%s_%gdBSPL.csv', Chins2Run{ChinIND}, plot_type, condition{end}, all_levels(li))));
        catch ME, warning('APAT:csv', 'EFR %s CSV: %s', plot_type, ME.message);
        end
    end

    %% Export individual figures when last condition for this subject is done
    % (all conditions overlaid, one per level) → <Subj>/ (next to pre/ post/)
    if CondIND == conds_idx(end)
        subj_name = Chins2Run{ChinIND};
        drawnow;
        % Every individual level figure ('Level|<lev> dB SPL', not the averages)
        figs_x = findobj('Type','figure');
        for fx = figs_x(:)'
            nm = get(fx,'Name');
            if strncmp(nm, 'Level|', 6) && ~strcmp(get(fx,'Tag'), 'APAT_efr_avg')
                tag = regexprep(nm(7:end), '\s+', '');
                try, apat_save_fig(fx, apat_out_dir('all_file', outpath, sprintf('%s_EFR_%s_%s_figure', subj_name, plot_type, tag)), ...
                        ['efr_' lower(plot_type) '_ind']); catch, end
            end
        end
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
    % Exclusions: means / SD / n without the excluded data; subject points
    % keep everyone (full copies taken before the globals are masked)
    XF = struct('pfa',{efr_peak_freq_all}, 'pa',{efr_peak_amp}, 'f',{efr_f}, 'plv',{efr_PLV}, ...
        'tr',{efr_trajectory_smooth}, 'dp',{efr_dAMpower_smooth}, 'nf',{efr_NFpower_smooth}, 'env',{efr_envelope});
    sidx_all = subject_idx;
    subject_idx = apat_excl('apply', Chins2Run, all_Conds2Run, subject_idx);
    outpath_avg = apat_out_dir('avg', fullfile(OUTdir, 'EFR'));   % group files in Analysis/EFR/Average
    fig_num_avg = length(Chins2Run) + 1;
    all_averages_ram = cell(1, numel(all_levels));
    all_averages_dAM = cell(1, numel(all_levels));
    avg_names        = cell(1, numel(all_levels));   % file name per level (save + PNG)
    for li = 1:numel(all_levels)
        switch plot_type
            case 'RAM'
                if li > size(efr_peak_freq_all, 3), continue; end
                sl_x   = efr_peak_freq_all(:,:,li);
                sl_y   = efr_peak_amp(:,:,li);
                sl_f   = efr_f(:,:,li);
                sl_plv = efr_PLV(:,:,li);
                if all(cellfun(@isempty, sl_x(:))), continue; end
                sl_env = cell(size(sl_y));                     % envelopes for Magnitude (µV) sums
                try, sl_env = efr_envelope(:,:,li); catch, end
                average = avg_efr(sl_x, sl_y, sl_f, sl_plv, ...
                    Chins2Run, Conds2Run, all_Conds2Run, fig_num_avg, colors, shapes, ...
                    idx_plot_relative, subject_idx, conds_idx, plot_type, sl_env);
                try
                    xf_env = cell(size(XF.pa(:,:,li)));
                    try, xf_env = XF.env(:,:,li); catch, end
                    avgF = avg_efr(XF.pfa(:,:,li), XF.pa(:,:,li), XF.f(:,:,li), XF.plv(:,:,li), ...
                        Chins2Run, Conds2Run, all_Conds2Run, fig_num_avg, colors, shapes, ...
                        idx_plot_relative, sidx_all, conds_idx, plot_type, xf_env);
                    average = apat_excl('merge', avgF, average, {'all_peaks'});
                    average.all_plv_sum_pts        = avgF.all_plv_sum;          % sums: points incl. excluded
                    average.all_low_high_peaks_pts = avgF.all_low_high_peaks;
                catch
                end
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
                try
                    avgF = avg_efr(XF.tr(:,:,li), XF.dp(:,:,li), XF.nf(:,:,li), [], ...
                        Chins2Run, Conds2Run, all_Conds2Run, fig_num_avg, colors, shapes, ...
                        idx_plot_relative, sidx_all, conds_idx, plot_type);
                    average = apat_excl('merge', avgF, average, {'all_trajectory','all_dAMpower','all_NFpower'});
                catch
                end
                all_averages_dAM{li} = average;
                filename = ['EFR_dAM4kHz_Average_', num2str(all_levels(li)), 'dBSPL'];
        end
        % Save the group data (read by tools/format_data.m for the stats export)
        average.subjects   = Chins2Run;
        average.conditions = [convertCharsToStrings(all_Conds2Run(:)'); subject_idx];
        if ~exist(outpath_avg, 'dir'), try, mkdir(outpath_avg); catch, end, end
        if apat_csv('avg_mat'), try, apat_avg_mat('save', fullfile(outpath_avg, filename), 'average', average); catch, end, end   % average.<EXP>
        avg_names{li} = filename;
    end
    if strcmp(plot_type, 'RAM') && any(~cellfun(@isempty, all_averages_ram))
        plot_avg_efr_tabs(all_averages_ram, all_levels, colors, shapes, subject_idx, conds_idx, ...
            Chins2Run, Conds2Run, all_Conds2Run, outpath_avg, ylimits, idx_plot_relative);
    end
    if strcmp(plot_type, 'dAM') && any(~cellfun(@isempty, all_averages_dAM))
        plot_avg_efr_dAM_tabs(all_averages_dAM, all_levels, colors, shapes, subject_idx, ...
            all_Conds2Run, idx_plot_relative, Chins2Run);
    end
    % Export the group figures shown in the app (one per level)
    for li = 1:numel(all_levels)
        if isempty(avg_names{li}), continue; end
        fh = findobj('Type','figure','Tag','APAT_efr_avg', ...
            'Name',sprintf('Level|%d dB SPL', round(all_levels(li))));
        if isempty(fh), continue; end
        try, apat_save_fig(fh(1), fullfile(outpath_avg, [avg_names{li} '_figure']), ['efr_' lower(plot_type) '_avg']); catch, end
    end
    % Individual values (all subjects × conditions, Excluded flag) + cell
    % Mean / SD / N: the CSV and field average.individual of each level's .mat
    try
        I = apat_csv('average', ['efr_' plot_type], fullfile(outpath_avg, sprintf('EFR_%s_Average.csv', plot_type)), ...
            Chins2Run, all_Conds2Run, idx_plot_relative);
        if apat_csv('avg_mat') && istable(I)
            for li = 1:numel(all_levels)
                if isempty(avg_names{li}), continue; end
                apat_csv('attach', fullfile(outpath_avg, avg_names{li}), I(I.Level_dBSPL == all_levels(li), :));
            end
        end
    catch
    end
end
cd(cwd);
end


% ═════════════════════════════════════════════════════════════════════════
function T = efr_rows(subj, cond, lev, d, plot_type)
%EFR_ROWS  Tidy CSV rows of one EFR recording (one level).
%   RAM: PLV and PLVSNR per harmonic (ModFrequency_Hz = k × F0, the axis the
%        app uses), plus the harmonic sums (Region All / Low / High with
%        their HarmonicRange, Setup ranges; normalised sums get the suffix
%        Fraction, and the all-harmonics sum — then always 1 — is left out).
%   dAM: band-averaged dAM power, noise floor and SNR per modulation
%        frequency of the trajectory.
base = struct('Measure',['EFR_' plot_type], 'Subject',subj, 'Condition',cond, 'Level_dBSPL',lev);
switch plot_type
    case 'RAM'
        o = efr_opts();
        p = double(d.peaks(:)');  nH = numel(p);
        loc = nan(1, nH);
        if isfield(d,'peaks_locs_all'), q = double(d.peaks_locs_all(:)'); loc(1:min(nH,numel(q))) = q(1:min(nH,numel(q))); end
        te = [];  if isfield(d,'t_env'), te = d.t_env; end
        mt = efr_ram_metrics(p, loc, d.f, d.plv_env, o, te);
        mg = nan(1, nH);  if isfield(mt,'mag') && ~isempty(mt.mag), q = double(mt.mag(:)'); mg(1:min(nH,numel(q))) = q(1:min(nH,numel(q))); end
        k = 1:nH;
        H = [k, k, k];  F = [k, k, k] * o.ram_f0;
        R = repmat({''}, 1, 3*nH);  HR = R;
        M = [repmat({'PLV'}, 1, nH), repmat({'PLVSNR'}, 1, nH), repmat({'Magnitude'}, 1, nH)];
        V = [p, mt.snr, mg];  U = [repmat({''}, 1, nH), repmat({'dB'}, 1, nH), repmat({'uV'}, 1, nH)];
        rs = @(r) sprintf('H%d-H%d', round(r(1)), round(r(end)));
        sm = 'PLVSum';  su = '';
        if strcmp(o.measure, 'snr'), sm = 'PLVSNRSum';  su = 'dB'; end
        if strcmp(o.measure, 'magnitude'), sm = 'MagnitudeSum';  su = 'uV'; end
        if o.normalize, sm = [sm 'Fraction'];  su = 'fraction'; end
        if ~o.normalize                     % normalised: the total is 1 by definition
            H = [H, NaN];  F = [F, NaN];  R = [R, {'All'}];  HR = [HR, {rs([1 nH])}];
            M = [M, {'PLVSum'}];  V = [V, mt.total];  U = [U, {''}];
        end
        H = [H, NaN, NaN];  F = [F, NaN, NaN];  R = [R, {'Low','High'}];  HR = [HR, {rs(o.low), rs(o.high)}];
        M = [M, {sm, sm}];  V = [V, mt.low, mt.high];  U = [U, {su, su}];
        T = apat_csv('mk', base, struct('Harmonic',H, 'ModFrequency_Hz',F, 'Region',{R}, ...
            'HarmonicRange',{HR}, 'Metric',{M}, 'Value',V, 'Units',{U}));
    case 'dAM'
        f = double(d.smooth.f(:)');  a = double(d.smooth.dAM(:)');  nf = double(d.smooth.NF(:)');
        n = min([numel(f), numel(a), numel(nf)]);  f = f(1:n);  a = a(1:n);  nf = nf(1:n);
        T = apat_csv('mk', base, struct('ModFrequency_Hz',[f f f], ...
            'Metric',{[repmat({'dAMPower'},1,n), repmat({'NoiseFloor'},1,n), repmat({'SNR'},1,n)]}, ...
            'Value',[a nf a-nf], 'Units',{repmat({'dB'},1,3*n)}));
    otherwise
        T = table();
end
end
