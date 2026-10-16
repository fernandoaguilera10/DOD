function ABRsummary(outpath,OUTdir,PRIVATEdir,Conds2Run,Chins2Run,all_Conds2Run,ChinIND,CondIND,idx_plot_relative,ylimits_ind_threshold,ylimits_ind_peaks,ylimits_ind_lat,ylimits_avg_threshold,ylimits_avg_peaks,ylimits_avg_lat,colors,shapes,analysis_type1,average_flag,conds_idx,freq,levels,wave_sel,exp_name)% ABR summary
global abr_f abr_thresholds abr_peaks_amp abr_peaks_lat abr_peaks_f abr_peaks_label abr_peaks_level abr_peaks_waveform abr_peaks_waveform_time
if ~exist('wave_sel','var') || isempty(wave_sel), wave_sel = true(1,5); end
if ~exist('exp_name','var') || isempty(exp_name), exp_name = ''; end   %#ok<NASGU> (no longer in the file names: Experiment = field of average)
cwd = pwd;
%% INDIVIDUAL PLOTS
condition = strsplit(all_Conds2Run{CondIND}, filesep);
if exist(outpath,"dir")
    if strcmp(analysis_type1,'Thresholds')
        search_file = cell2mat([Chins2Run(ChinIND),'_',condition{1},condition{2},'_ABRthresholds.mat']);
        datafile = load_files(outpath,search_file,'data',[],true);
        S_thr = load(fullfile(outpath, datafile), 'abr_out');  abr_out = S_thr.abr_out;
        % Repeated Levels changed since this result was saved (missing = 'all')
        % and the recording has a level twice → re-analyse it with the new
        % setting (the other re-run checks live in analysis_run's main body)
        if exist('freq','var'), fr_req = freq; else, fr_req = []; end
        abr_out = thr_dup_rerun(abr_out, fullfile(outpath, datafile), outpath, OUTdir, ...
            Chins2Run{ChinIND}, all_Conds2Run, CondIND, fr_req);
        abr_out_full = abr_out;   % preserve all fields before frequency filtering
        cd(cwd);
        % Filter to currently selected frequencies when freq list is provided
        if exist('freq','var') && ~isempty(freq)
            mask = ismember(abr_out.freqs, freq);
            if any(mask)
                abr_out.freqs      = abr_out.freqs(mask);
                abr_out.thresholds = abr_out.thresholds(mask);
            end
        end
        % PLOTTING SPL
        abr_f{ChinIND,CondIND} = abr_out.freqs;
        abr_thresholds{ChinIND,CondIND} = abr_out.thresholds;
        plot_ind_abr(abr_out,analysis_type1,colors,shapes,Conds2Run,Chins2Run,all_Conds2Run,ChinIND,CondIND,outpath,ylimits_ind_threshold,[],[],[])
        % Rows of this recording (kept for the average files) + its CSV next
        % to the .mat (Setup "Data Export" CSV / Both)
        try
            subj = Chins2Run{ChinIND};
            apat_csv('rec', 'abr_thr', [subj '|' condition{end}], thr_rows(subj, condition{end}, abr_out, abr_out_full), ...
                fullfile(outpath, sprintf('%s_ABRThresholds_%s.csv', subj, condition{end})));
        catch ME, warning('APAT:csv', 'ABR Thresholds CSV: %s', ME.message);
        end
        % Per-frequency figures named 'Freq|Condition' -> one tab per
        % frequency with a Condition dropdown (same layout as ABR Peaks).
        if isfield(abr_out_full,'plot_data') && ~isempty(abr_out_full.plot_data)
            pd = abr_out_full.plot_data;
            if exist('freq','var') && ~isempty(freq)
                pd_freqs = arrayfun(@(p) p.freq, pd);
                pd = pd(ismember(pd_freqs, freq));
            end
            plot_thr_individual(pd, abr_out_full.fs, condition{end}, colors(CondIND,:));
        else
            ph = figure('Name',sprintf('No data|%s',condition{end}),'NumberTitle','off','Visible','off','Color','w');
            ax = axes(ph); axis(ax,'off');
            text(ax, 0.5, 0.5, 'No Waveform Data Saved For This Condition (Re-Run The Analysis)', ...
                'HorizontalAlignment','center','FontSize',14,'Color',[0.45 0.45 0.45],'Units','normalized');
        end
    elseif strcmp(analysis_type1,'Peaks')
        % Pre-scan all saved ABR Peaks MAT files to compute global y-limits
        % so amplitude and latency axes are comparable across subjects.
        % Per-file limits are cached for the run (peak_scan_lims), so each
        % file is read once instead of once per subject x condition.
        [global_amp_lim, global_lat_lim] = peak_scan_lims(OUTdir);
        % Add 20% padding; fall back to [] (data-driven) if no files found
        if isfinite(global_amp_lim(1)) && isfinite(global_amp_lim(2))
            rng_a = global_amp_lim(2) - global_amp_lim(1); if rng_a == 0, rng_a = 1; end
            global_amp_ylim = [max(0, global_amp_lim(1) - 0.2*rng_a), global_amp_lim(2) + 0.2*rng_a];
        else
            global_amp_ylim = [];
        end
        if isfinite(global_lat_lim(1)) && isfinite(global_lat_lim(2))
            rng_l = global_lat_lim(2) - global_lat_lim(1); if rng_l == 0, rng_l = 1; end
            global_lat_ylim = [max(0, global_lat_lim(1) - 0.2*rng_l), global_lat_lim(2) + 0.2*rng_l];
        else
            global_lat_ylim = [];
        end
        for z = 1:length(freq)
            if freq(z) == 0, search_file = cell2mat(['*',Chins2Run(ChinIND),'_',condition{2},'_ABRpeaks_dtw_click.mat']); end
            if freq(z) ~= 0, search_file = cell2mat(['*',Chins2Run(ChinIND),'_',condition{2},'_ABRpeaks_dtw_',num2str(freq(z)),'Hz.mat']); end
            datafile = load_files(outpath,search_file,'data',[],true);
            if ~isempty(datafile)
                S_pk = load(fullfile(outpath, datafile), 'abrs');  abrs = S_pk.abrs;
            end
            if ~isempty(datafile)
                if any(mean(abs(abrs.peak_amplitude)) > 10)
                    abrs.peak_amplitude = abrs.peak_amplitude/10^2; % convert V to microV
                end
                if any(mean(abrs.peak_latency) > 1000)
                    abrs.peak_latency = abrs.peak_latency/10^3; % convert s to ms
                end
                abr_peaks_amp{ChinIND,CondIND} = abrs.peak_amplitude;
                abr_peaks_lat{ChinIND,CondIND} = abrs.peak_latency;
                abr_peaks_f{ChinIND,CondIND} = abrs.freq;
                abr_peaks_level{ChinIND,CondIND} = abrs.levels;
                abr_peaks_waveform{ChinIND,CondIND} = abrs.waveforms;
                abr_peaks_waveform_time{ChinIND,CondIND} = abrs.waveforms_time;
                plot_ind_abr(abrs,analysis_type1,colors,shapes,Conds2Run,Chins2Run,all_Conds2Run,ChinIND,CondIND,outpath,[],global_amp_ylim,global_lat_ylim,freq,wave_sel)
                try          % rows kept for the average files; CSV when export is on
                    subj = Chins2Run{ChinIND};
                    if freq(z) == 0, fstr = 'click'; else, fstr = [num2str(freq(z)) 'Hz']; end
                    apat_csv('rec', 'abr_peaks', [subj '|' condition{end} '|' fstr], peak_rows(subj, condition{end}, abrs), ...
                        fullfile(outpath, sprintf('%s_ABRPeaks_%s_%s.csv', subj, condition{end}, fstr)));
                catch ME, warning('APAT:csv', 'ABR Peaks CSV: %s', ME.message);
                end
            end
        end
    end
    cd(cwd)
else
    fprintf('No directory found.\n');
end
%% AVERAGE PLOTS (individual + average)
if average_flag == 1
    % Exclusions: means / SD / n leave the excluded data out; the subject
    % points keep everyone (excluded ones are marked in the app)
    XM = apat_excl('mask', Chins2Run, all_Conds2Run);
    if strcmp(analysis_type1,'Thresholds')
        fig_num_avg = length(Chins2Run)+1;
        thrF = avg_abr(abr_f,abr_thresholds,Chins2Run,Conds2Run,all_Conds2Run,fig_num_avg,colors,shapes,idx_plot_relative,analysis_type1,[]);   % everyone
        apat_excl('apply', Chins2Run, all_Conds2Run);
        % Plot individual lines
        [thresholds,idx] = avg_abr(abr_f,abr_thresholds,Chins2Run,Conds2Run,all_Conds2Run,fig_num_avg,colors,shapes,idx_plot_relative,analysis_type1,[]);
        thresholds.all_y_pts = thrF.all_y;   % subject points incl. excluded
        % Plot average lines (group files in Analysis/ABR/Average). ONE file
        % for every Experiment (average.<EXP>, apat_avg_mat; before Oct 16
        % 2026 the sheet was in the name: ABR_Thresholds_Average_dBSPL_<sheet>)
        outpath = apat_out_dir('avg', fullfile(OUTdir, 'ABR'));
        filename = 'ABR_Thresholds_Average_dBSPL';
        plot_avg_abr(thresholds,analysis_type1,colors,shapes,idx,conds_idx,Chins2Run,Conds2Run,all_Conds2Run,outpath,filename,fig_num_avg,ylimits_avg_threshold,idx_plot_relative,[])
        % Individual values (all subjects × conditions, Excluded flag) + cell
        % Mean / SD / N: the CSV and field average.individual of the .mat
        try
            I = apat_csv('average', 'abr_thr', fullfile(outpath, [strrep(filename, '_dBSPL', '') '.csv']), ...
                Chins2Run, all_Conds2Run, idx_plot_relative);
            if apat_csv('avg_mat'), apat_csv('attach', fullfile(outpath, filename), I); end
        catch
        end
    elseif strcmp(analysis_type1,'Peaks')
        % Average section reloads per-frequency data directly from saved files.
        % This avoids the global-variable overwrite bug where the z-loop in the
        % individual section leaves only the LAST frequency in abr_peaks_*.
        for z = 1:length(freq)
            % --- Reload per-frequency data for ALL subjects/conditions ---
            n_subj = length(Chins2Run);
            n_cond = length(all_Conds2Run);
            amp_freq  = cell(n_subj, n_cond);
            lat_freq  = cell(n_subj, n_cond);
            lev_freq  = cell(n_subj, n_cond);
            wf_freq   = cell(n_subj, n_cond);
            wft_freq  = cell(n_subj, n_cond);
            freq_cell = cell(n_subj, n_cond);
            for ci = 1:n_subj
                for cj = 1:n_cond
                    cond_parts_z = strsplit(all_Conds2Run{cj}, filesep);
                    subj_outpath_z = strcat(OUTdir,filesep,'ABR',filesep,Chins2Run{ci},filesep,all_Conds2Run{cj});
                    if freq(z) == 0
                        sf_z = cell2mat(['*',Chins2Run(ci),'_',cond_parts_z{end},'_ABRpeaks_dtw_click.mat']);
                    else
                        sf_z = cell2mat(['*',Chins2Run(ci),'_',cond_parts_z{end},'_ABRpeaks_dtw_',num2str(freq(z)),'Hz.mat']);
                    end
                    if ~exist(subj_outpath_z, 'dir'), continue; end
                    df_z = load_files(subj_outpath_z, sf_z, 'data', [], true);
                    if ~isempty(df_z)
                        tmp_z = load(fullfile(subj_outpath_z, df_z), 'abrs');
                        if isfield(tmp_z,'abrs')
                            pamp_z = tmp_z.abrs.peak_amplitude;
                            plat_z = tmp_z.abrs.peak_latency;
                            if ~isempty(pamp_z) && any(mean(abs(pamp_z(:))) > 10), pamp_z = pamp_z/1e2; end
                            if ~isempty(plat_z) && any(mean(abs(plat_z(:))) > 1000), plat_z = plat_z/1e3; end
                            amp_freq{ci,cj}  = pamp_z;
                            lat_freq{ci,cj}  = plat_z;
                            lev_freq{ci,cj}  = tmp_z.abrs.levels;
                            freq_cell{ci,cj} = tmp_z.abrs.freq;
                            if ~isempty(tmp_z.abrs.waveforms)
                                wf_freq{ci,cj}  = tmp_z.abrs.waveforms;
                                wft_freq{ci,cj} = tmp_z.abrs.waveforms_time;
                            end
                        end
                    end
                end
            end

            % --- Compute and plot averages for this frequency ---
            outpath_avg = apat_out_dir('avg', fullfile(OUTdir, 'ABR'));
            if ~exist(outpath_avg, 'dir'), try, mkdir(outpath_avg); catch, end, end
            fig_num_base = (ChinIND - 1) * (length(freq) * length(all_Conds2Run)) + (z-1)*20 + length(all_Conds2Run) + CondIND;

            % Exclusions: *_m = without the excluded data (means / SD / n);
            % the full arrays keep every subject for the subject points
            lev_m = apat_excl('blank', lev_freq, XM);  amp_m = apat_excl('blank', amp_freq, XM);
            lat_m = apat_excl('blank', lat_freq, XM);
            wf_m  = apat_excl('blank', wf_freq, XM);   wft_m = apat_excl('blank', wft_freq, XM);

            % Peak-to-peak amplitude (fig base+1)
            fig_num_avg = fig_num_base + 1;
            ampF = avg_abr(lev_freq,amp_freq,Chins2Run,Conds2Run,all_Conds2Run,fig_num_avg,colors,shapes,idx_plot_relative,analysis_type1,'Amplitude');
            [amplitudes,idx] = avg_abr(lev_m,amp_m,Chins2Run,Conds2Run,all_Conds2Run,fig_num_avg,colors,shapes,idx_plot_relative,analysis_type1,'Amplitude');
            amplitudes = apat_excl('merge', ampF, amplitudes, {'all_w1','all_w2','all_w3','all_w4','all_w5','all_w1and5','all_x_subj'});
            if freq(z) == 0, filename = 'ABR_PeakAmplitude_Average_dtw_click';
            else,            filename = ['ABR_PeakAmplitude_Average_dtw_',mat2str(freq(z))]; end
            plot_avg_abr(amplitudes,analysis_type1,colors,shapes,idx,conds_idx,Chins2Run,Conds2Run,all_Conds2Run,outpath_avg,filename,fig_num_avg,[],idx_plot_relative,'Amplitude',freq(z),wave_sel)

            % Peak latency (fig base+2)
            fig_num_avg = fig_num_base + 2;
            latF = avg_abr(lev_freq,lat_freq,Chins2Run,Conds2Run,all_Conds2Run,fig_num_avg,colors,shapes,idx_plot_relative,analysis_type1,'Latency');
            [latencies,idx] = avg_abr(lev_m,lat_m,Chins2Run,Conds2Run,all_Conds2Run,fig_num_avg,colors,shapes,idx_plot_relative,analysis_type1,'Latency');
            latencies = apat_excl('merge', latF, latencies, {'all_w1','all_w2','all_w3','all_w4','all_w5','all_w1and5','all_x_subj'});
            if freq(z) == 0, filename = 'ABR_PeakLatency_Average_dtw_click';
            else,            filename = ['ABR_PeakLatency_Average_dtw_',mat2str(freq(z))]; end
            plot_avg_abr(latencies,analysis_type1,colors,shapes,idx,conds_idx,Chins2Run,Conds2Run,all_Conds2Run,outpath_avg,filename,fig_num_avg,[],idx_plot_relative,'Latency',freq(z),wave_sel)

            % Build trough-latency table: move N columns (even) to odd positions so
            % avg_abr's 1:2:width scan picks them up as w1…w5.
            lat_trough_freq = cell(n_subj, n_cond);
            for ci_t = 1:n_subj
                for cj_t = 1:n_cond
                    m = lat_m{ci_t, cj_t};
                    if isempty(m) || size(m,2) < 2, continue; end
                    n_waves = floor(size(m,2)/2);
                    tmp = zeros(size(m,1), n_waves*2);
                    for ww = 1:n_waves
                        tmp(:, 2*ww-1) = m(:, 2*ww);   % N (trough) into odd column
                    end
                    lat_trough_freq{ci_t, cj_t} = tmp;
                end
            end
            [trough_lat,~] = avg_abr(lev_m, lat_trough_freq, Chins2Run, Conds2Run, ...
                all_Conds2Run, fig_num_avg, colors, shapes, idx_plot_relative, ...
                analysis_type1, 'Latency');

            % Waveform waterfall (fig base+3)
            waveforms.x         = wft_m;      % mean waveforms without the excluded data
            waveforms.y         = wf_m;
            waveforms.freq      = freq_cell;
            waveforms.levels    = lev_freq;
            waveforms.peak_lat  = lat_freq;   % per-subject peak/trough latencies (subject points, everyone)
            waveforms.x_subj    = wft_freq;   % every subject's waveform (subject points, incl. excluded)
            waveforms.y_subj    = wf_freq;
            waveforms.subjects  = Chins2Run;
            waveforms.conditions = [convertCharsToStrings(all_Conds2Run(:)');idx];
            fig_num_wf = fig_num_base + 3;
            plot_abr_waterfall(waveforms, latencies, trough_lat, colors, shapes, Chins2Run, Conds2Run, all_Conds2Run, conds_idx, freq(z), outpath_avg, fig_num_wf, wave_sel);

            if freq(z) == 0, filename = 'ABR_Waveforms_click';
            else,            filename = ['ABR_Waveforms_',mat2str(freq(z))]; end
            if apat_csv('avg_mat'), try, apat_avg_mat('save', fullfile(outpath_avg, filename), 'waveforms', waveforms); catch, end, end   % waveforms.<EXP>
        end
        % Individual values + cell Mean / SD / N: ABR_Peaks_Average.csv, and
        % field average.individual of each frequency's amplitude / latency .mat
        try
            outpath_avg = apat_out_dir('avg', fullfile(OUTdir, 'ABR'));
            I = apat_csv('average', 'abr_peaks', fullfile(outpath_avg, 'ABR_Peaks_Average.csv'), ...
                Chins2Run, all_Conds2Run, idx_plot_relative);
            if apat_csv('avg_mat') && istable(I)
                for z = 1:length(freq)
                    if freq(z) == 0, fs = 'click'; else, fs = mat2str(freq(z)); end
                    if freq(z) == 0, If = I(strcmp(I.Stimulus, 'Click'), :);
                    else,            If = I(abs(I.Frequency_kHz - freq(z)/1000) < 1e-9, :); end
                    apat_csv('attach', fullfile(outpath_avg, ['ABR_PeakAmplitude_Average_dtw_' fs]), ...
                        If(contains(If.Metric, 'Amplitude'), :));
                    apat_csv('attach', fullfile(outpath_avg, ['ABR_PeakLatency_Average_dtw_' fs]), ...
                        If(contains(If.Metric, 'Latency'), :));
                end
            end
        catch
        end
    end
end
cd(cwd);
end


% ═════════════════════════════════════════════════════════════════════════
%  CSV rows (tidy: one row per observation)
% ═════════════════════════════════════════════════════════════════════════
function T = thr_rows(subj, cond, abr_out, abr_full)
% Threshold per frequency + the response correlation (bootstrap
% cross-correlation the threshold is fitted to) per frequency and level.
% Repeat numbers a level recorded twice at one frequency ('all' mode:
% "90 (1)", "90 (2)"), so no two rows share their keys.
f  = double(abr_out.freqs(:));  th = double(abr_out.thresholds(:));
n  = min(numel(f), numel(th));  f = f(1:n);  th = th(1:n);
F = f;  L = nan(n,1);  M = repmat({'Threshold'}, n, 1);  V = th;  U = repmat({'dB SPL'}, n, 1);
if isfield(abr_full, 'plot_data') && ~isempty(abr_full.plot_data)
    for p = abr_full.plot_data(:)'
        if ~ismember(p.freq, f) || ~isfield(p,'cor') || isempty(p.cor), continue; end
        lv = double(p.lev(:));  cr = double(p.cor(:));  m = min(numel(lv), numel(cr));
        F = [F; repmat(double(p.freq), m, 1)];  L = [L; lv(1:m)];          %#ok<AGROW>
        M = [M; repmat({'ResponseCorrelation'}, m, 1)];  V = [V; cr(1:m)]; %#ok<AGROW>
        U = [U; repmat({''}, m, 1)];                                        %#ok<AGROW>
    end
end
T = apat_csv('mk', struct('Measure','ABR_Thresholds', 'Subject',subj, 'Condition',cond), ...
    struct('Stimulus',{stim_name(F)}, 'Frequency_kHz',khz(F), 'Level_dBSPL',L, ...
    'Repeat',rep_index(F, L, M), 'Metric',{M}, 'Value',V, 'Units',{U}));
end


function T = peak_rows(subj, cond, abrs)
% Per level and wave: peak / trough amplitude (µV) and latency (ms), the
% peak-to-peak amplitude; plus the visual threshold of this frequency.
A = double(abrs.peak_amplitude);  Lt = double(abrs.peak_latency);   % µV / ms (converted by the caller)
lev = double(abrs.levels(:));
wn = {'I','II','III','IV','V'};
nW = floor(min(size(A,2), size(Lt,2)) / 2);
nL = min([numel(lev), size(A,1), size(Lt,1)]);
Lv = [];  W = {};  M = {};  V = [];  U = {};
for k = 1:nW
    pk = A(1:nL,2*k-1);  tr = A(1:nL,2*k);  lp = Lt(1:nL,2*k-1);  lt = Lt(1:nL,2*k);
    vals = {pk, tr, pk - tr, lp, lt};
    mets = {'PeakAmplitude','TroughAmplitude','PeakToPeakAmplitude','PeakLatency','TroughLatency'};
    unit = {'uV','uV','uV','ms','ms'};
    for j = 1:numel(vals)
        Lv = [Lv; lev(1:nL)];  V = [V; vals{j}];                           %#ok<AGROW>
        W  = [W; repmat(wn(min(k,5)), nL, 1)];                             %#ok<AGROW>
        M  = [M; repmat(mets(j), nL, 1)];  U = [U; repmat(unit(j), nL, 1)]; %#ok<AGROW>
    end
end
if isfield(abrs, 'threshold_visual') && ~isempty(abrs.threshold_visual)
    Lv = [Lv; NaN];  W = [W; {''}];  M = [M; {'VisualThreshold'}];
    V = [V; double(abrs.threshold_visual(1))];  U = [U; {'dB SPL'}];
end
fq = NaN;  if isfield(abrs,'freq') && ~isempty(abrs.freq), fq = double(abrs.freq); end
T = apat_csv('mk', struct('Measure','ABR_Peaks', 'Subject',subj, 'Condition',cond, ...
    'Stimulus',stim_name(fq), 'Frequency_kHz',khz(fq)), ...
    struct('Level_dBSPL',Lv, 'Repeat',rep_index(Lv, Lv, strcat(W, '|', M)), 'Wave',{W}, ...
    'Metric',{M}, 'Value',V, 'Units',{U}));
end


function s = stim_name(f)
% 'Click' (0 Hz) or 'Tone' — one text per value (cell for vectors); the
% tone frequency is in Frequency_kHz
s = arrayfun(@(x) ternary_s(x == 0, 'Click', 'Tone'), double(f(:)), 'UniformOutput', false);
if isscalar(f), s = s{1}; end
end


function k = khz(f)
% Hz → kHz; click (0 Hz) → NaN (empty in the CSV)
k = double(f) / 1000;  k(double(f) == 0) = NaN;
end


function r = rep_index(f, l, m)
% occurrence number (1, 2, …) of each row's (frequency, level, metric) key
r = ones(0, 1);  if isempty(f), return; end
key = strcat(cellstr(compose('%.6g', double(f(:)))), '|', cellstr(compose('%.6g', double(l(:)))), '|', cellstr(m(:)));
r = ones(numel(key), 1);
for i = 2:numel(key)
    r(i) = sum(strcmp(key(1:i), key{i}));
end
end


function s = ternary_s(c, a, b)
if c, s = a; else, s = b; end
end


function [amp_lim, lat_lim] = peak_scan_lims(OUTdir)
%PEAK_SCAN_LIMS  Min / max peak-to-peak amplitude and latency over every
%   saved *ABRpeaks_dtw*.mat under OUTdir/ABR (global y-limits of the ABR
%   Peaks individual plots). Each file's limits are cached in root appdata
%   'APAT_abr_peak_scan' (cleared by analysis_run at the start of a run),
%   keyed by its path + date + size, so a file is re-read only when it is
%   new or was rewritten (e.g. re-analysed later in the same run). min / max
%   do not depend on order, so the result equals a full re-scan.
amp_lim = [Inf, -Inf];
lat_lim = [Inf, -Inf];
peak_scan = dir(fullfile(OUTdir, 'ABR', '**', '*ABRpeaks_dtw*.mat'));
C = [];
if isappdata(0, 'APAT_abr_peak_scan'), C = getappdata(0, 'APAT_abr_peak_scan'); end
if ~isa(C, 'containers.Map'), C = containers.Map('KeyType','char','ValueType','any'); end
for ps_i = 1:length(peak_scan)
    fp  = fullfile(peak_scan(ps_i).folder, peak_scan(ps_i).name);
    sig = [peak_scan(ps_i).datenum, peak_scan(ps_i).bytes];
    if isKey(C, fp) && isequal(C(fp).sig, sig)
        L = C(fp).lims;
    else
        L = one_file_lims(fp);
        C(fp) = struct('sig', sig, 'lims', L);
    end
    amp_lim(1) = min(amp_lim(1), L(1));  amp_lim(2) = max(amp_lim(2), L(2));
    lat_lim(1) = min(lat_lim(1), L(3));  lat_lim(2) = max(lat_lim(2), L(4));
end
setappdata(0, 'APAT_abr_peak_scan', C);
end


function L = one_file_lims(fp)
% [amp_min amp_max lat_min lat_max] of one ABR Peaks file (Inf / -Inf when
% it has no usable values or cannot be read) — same rules as before.
L = [Inf, -Inf, Inf, -Inf];
try
    tmp_ps = load(fp, 'abrs');
    if isfield(tmp_ps, 'abrs')
        pamp = tmp_ps.abrs.peak_amplitude;
        plat = tmp_ps.abrs.peak_latency;
        if ~isempty(pamp) && any(mean(abs(pamp(:))) > 10), pamp = pamp/1e2; end
        if ~isempty(plat) && any(mean(abs(plat(:))) > 1000), plat = plat/1e3; end
        if ~isempty(pamp)
            n_slots = floor(size(pamp,2)/2);
            for ks = 1:n_slots
                amp_pp = pamp(:,2*ks-1) - pamp(:,2*ks);
                amp_pp = amp_pp(isfinite(amp_pp));
                if ~isempty(amp_pp)
                    L(1) = min(L(1), min(amp_pp));
                    L(2) = max(L(2), max(amp_pp));
                end
            end
        end
        if ~isempty(plat)
            lat_vals = plat(isfinite(plat) & plat > 0);
            if ~isempty(lat_vals)
                L(3) = min(L(3), min(lat_vals));
                L(4) = max(L(4), max(lat_vals));
            end
        end
    end
catch   % skip unreadable files
end
end


function abr_out = thr_dup_rerun(abr_out, matfile, outpath, OUTdir, subj, all_Conds2Run, CondIND, freq)
%THR_DUP_RERUN  Re-run ABR_thresholds for this recording when the Repeated
%   Levels setting (root appdata APAT_abr_dup_levels, default 'all') differs
%   from the one the result was saved with (abr_out.dup_levels, missing =
%   'all') AND the recording has a repeated level. Needs the raw data
%   (Data/<subj>/ABR/<cond>, next to Analysis/); otherwise the saved result
%   is kept. Cheap when nothing changed: only the loaded abr_out is read.
try
    want = 'all';
    if isappdata(0, 'APAT_abr_dup_levels') && strcmpi(char(getappdata(0, 'APAT_abr_dup_levels')), 'average')
        want = 'average';
    end
    have = 'all';
    if isfield(abr_out, 'dup_levels') && strcmpi(char(abr_out.dup_levels), 'average'), have = 'average'; end
    if strcmp(want, have), return; end
    % Does this recording have a repeated level?
    dups = false;
    if isfield(abr_out, 'pooled') && ~isempty(abr_out.pooled), dups = true; end
    if ~dups && isfield(abr_out, 'repeated') && ~isempty(abr_out.repeated), dups = true; end
    if ~dups && isfield(abr_out, 'plot_data') && ~isempty(abr_out.plot_data)
        for p = abr_out.plot_data(:)'
            lv = double(p.lev(:));
            if numel(unique(lv)) < numel(lv), dups = true; break; end
        end
    end
    if ~dups, return; end
    datapath = fullfile(fileparts(OUTdir), 'Data', subj, 'ABR', all_Conds2Run{CondIND});
    if ~exist(datapath, 'dir') || isempty(dir(fullfile(datapath, 'p*ABR*.mat'))) || ~exist('ABR_thresholds', 'file')
        fprintf('\nABR Thresholds: Repeated Levels "%s" requested for %s (%s) but raw data not found — keeping the "%s" result.\n', ...
            want, subj, all_Conds2Run{CondIND}, have);
        return
    end
    fprintf('\nABR Thresholds: Repeated Levels changed (%s → %s) for %s (%s) — re-analysing.\n', ...
        have, want, subj, all_Conds2Run{CondIND});
    fr = abr_out.freqs(:)';
    if ~isempty(freq), fr = unique([fr, freq(:)']); end
    figs0 = findall(0, 'Type', 'figure');
    cwd = pwd;
    ABR_thresholds(datapath, outpath, subj, all_Conds2Run, CondIND, fr, want);
    cd(cwd);
    % Analysis-stage figures are not part of the summary views
    nf = setdiff(findall(0, 'Type', 'figure'), figs0);
    nf = nf(isvalid(nf));
    if ~isempty(nf), close(nf); end
    S = load(matfile, 'abr_out');  abr_out = S.abr_out;
catch ME
    warning('APAT:abr_dup', 'ABR Thresholds Repeated Levels re-run: %s', ME.message);
end
end
