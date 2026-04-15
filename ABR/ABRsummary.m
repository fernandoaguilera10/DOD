function ABRsummary(outpath,OUTdir,PRIVATEdir,Conds2Run,Chins2Run,all_Conds2Run,ChinIND,CondIND,idx_plot_relative,ylimits_ind_threshold,ylimits_ind_peaks,ylimits_ind_lat,ylimits_avg_threshold,ylimits_avg_peaks,ylimits_avg_lat,colors,shapes,analysis_type1,average_flag,conds_idx,freq,levels,wave_sel)% ABR summary
global abr_f abr_thresholds abr_peaks_amp abr_peaks_lat abr_peaks_f abr_peaks_label abr_peaks_level abr_peaks_waveform abr_peaks_waveform_time
if ~exist('wave_sel','var') || isempty(wave_sel), wave_sel = true(1,5); end
cwd = pwd;
%% INDIVIDUAL PLOTS
condition = strsplit(all_Conds2Run{CondIND}, filesep);
if exist(outpath,"dir")
    cd(PRIVATEdir)
    if strcmp(analysis_type1,'Thresholds')
        search_file = cell2mat([Chins2Run(ChinIND),'_',condition{1},condition{2},'_ABRthresholds.mat']);
        datafile = load_files(outpath,search_file,'data',[],true);
        cd(outpath);
        load(datafile);
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
        % Build diagnostic figures for this condition's waveforms and sigmoid fits.
        % Always create fresh figures — never reuse open figures from prior runs.
        % Branch 1 figures use a different naming convention ('Name | subj | cond'
        % vs 'Name|cond') and are closed before Branch 3, so there is no risk of
        % duplication within a single run.  Stale same-named figures from a
        % previous run that were not properly closed would suppress creation via
        % the old diag_missing guard; creating unconditionally avoids that trap.
        diag_names = {sprintf('ABR Waveforms|%s', condition{end}), ...
                      sprintf('Sigmoid Fits|%s',  condition{end})};

        if isfield(abr_out_full,'plot_data') && ~isempty(abr_out_full.plot_data)
            pd   = abr_out_full.plot_data;
            fs_r = abr_out_full.fs;
            % Filter plot_data to selected frequencies (same filter applied to abr_out above)
            if exist('freq','var') && ~isempty(freq)
                pd_freqs = arrayfun(@(p) p.freq, pd);
                pd = pd(ismember(pd_freqs, freq));
            end
            nf   = numel(pd);
            clr_no  = [0,0,0,.3];  clr_yes = [0,0,0,1];

            abr_vis = figure('Name',diag_names{1},'NumberTitle','off','Visible','off');
            set(abr_vis,'Units','Normalized','OuterPosition',[0.35,0.025,0.65,0.9]);
            fit_vis = figure('Name',diag_names{2},'NumberTitle','off','Visible','off');
            set(fit_vis,'Units','Normalized','OuterPosition',[0,0.45,0.35,0.4725]);

            for f_r = 1:nf
                lev_r   = pd(f_r).lev;
                wforms_r = pd(f_r).wforms;
                thr_r   = pd(f_r).thresh;
                if isempty(wforms_r), continue; end
                t_r   = (1:size(wforms_r,1)) / fs_r * 1e3;
                buff  = 1.25*max(max(wforms_r)) * (1:size(wforms_r,2));
                wp    = wforms_r + buff;

                set(0,'CurrentFigure', abr_vis);
                subplot(ceil(nf/3),3,f_r); hold on
                if sum(lev_r > thr_r) ~= 0
                    plot(t_r, wp(:,lev_r>=round(thr_r,-1)), 'color',clr_yes,'linewidth',2);
                end
                if round(thr_r,-1)~=0 && ~isnan(thr_r) && sum(lev_r<round(thr_r,-1))~=0
                    plot(t_r, wp(:,lev_r<round(thr_r,-1)), 'color',clr_no,'linewidth',2);
                end
                if sum(lev_r<round(thr_r,-1))==0 || isnan(thr_r)
                    plot(t_r, wp, 'color',clr_yes,'linewidth',2);
                end
                xlim([0,30]); hold off; set(gca,'FontSize',15);
                yticks(mean(wp)); yticklabels(round(lev_r));
                ylim([0.9*min(min(wp)), 1.03*max(max(wp))]);
                ylabel('Sound Level (dB SPL)','FontWeight','bold');
                xlabel('Time (ms)','FontWeight','bold');
                if pd(f_r).freq==0, title('Click');
                else, title([num2str(pd(f_r).freq),' Hz']); end
                subtitle(sprintf('Threshold: %.1f dB SPL', thr_r));

                set(0,'CurrentFigure', fit_vis);
                subplot(ceil(nf/3),3,f_r); hold on
                if pd(f_r).freq==0, title('Click');
                else, title([num2str(pd(f_r).freq),' Hz']); end
                plot(1:80, pd(f_r).cor_fit_vals, '--k','linewidth',2);
                errorbar(lev_r, pd(f_r).cor, pd(f_r).cor_err, '.b','linewidth',1.5,'markersize',10);
                ylim([0,1]); xline(thr_r,'r','linewidth',2);
                xticks(0:10:100); xtickangle(90); xlim([0,100]);
                xlabel('Level (dB SPL)'); hold off; grid on
            end
            sgtitle(abr_vis,'ABR Waveforms','FontSize',13,'FontWeight','bold');
            sgtitle(fit_vis,'Bootstrap Cross-Correlation  —  Sigmoid Fits','FontSize',13,'FontWeight','bold');
        end

        % Safety net: ensure each diagnostic figure exists and has at least one
        % axes object so it passes the valid_figs filter in embed_results.
        % Covers: (a) no plot_data field (old MAT format), (b) plot_data present
        % but all waveforms empty (analysis ran but found no raw files).
        for kdn = 1:numel(diag_names)
            f_ex = findobj('Type','figure','Name',diag_names{kdn});
            has_axes = ~isempty(f_ex) && ...
                any(arrayfun(@(f) ~isempty(findall(f,'Type','axes')), f_ex));
            if ~has_axes
                if ~isempty(f_ex)
                    close(f_ex);   % discard any axesless figure with this name
                end
                ph = figure('Name',diag_names{kdn},'NumberTitle','off','Visible','off');
                ax = axes(ph); axis(ax,'off');
                text(ax, 0.5, 0.5, 'No waveform data available.', ...
                    'HorizontalAlignment','center','FontSize',14,'Units','normalized');
            end
        end
    elseif strcmp(analysis_type1,'Peaks')
        % Pre-scan all saved ABR Peaks MAT files to compute global y-limits
        % so amplitude and latency axes are comparable across subjects.
        global_amp_lim = [Inf, -Inf];
        global_lat_lim = [Inf, -Inf];
        peak_scan = dir(fullfile(OUTdir, 'ABR', '**', '*ABRpeaks_dtw*.mat'));
        for ps_i = 1:length(peak_scan)
            try
                tmp_ps = load(fullfile(peak_scan(ps_i).folder, peak_scan(ps_i).name), 'abrs');
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
                                global_amp_lim(1) = min(global_amp_lim(1), min(amp_pp));
                                global_amp_lim(2) = max(global_amp_lim(2), max(amp_pp));
                            end
                        end
                    end
                    if ~isempty(plat)
                        lat_vals = plat(isfinite(plat) & plat > 0);
                        if ~isempty(lat_vals)
                            global_lat_lim(1) = min(global_lat_lim(1), min(lat_vals));
                            global_lat_lim(2) = max(global_lat_lim(2), max(lat_vals));
                        end
                    end
                end
            catch, end  % skip unreadable files
        end
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
            cd(PRIVATEdir)
            datafile = load_files(outpath,search_file,'data',[],true);
            if ~isempty(datafile)
                cd(outpath);
                load(datafile);
            end
            cd(cwd)
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
            end
        end
    end
    cd(cwd)
else
    fprintf('No directory found.\n');
end
%% AVERAGE PLOTS (individual + average)
if average_flag == 1
    if strcmp(analysis_type1,'Thresholds')
        fig_num_avg = length(Chins2Run)+1;
        % Plot individual lines
        [thresholds,idx] = avg_abr(abr_f,abr_thresholds,Chins2Run,Conds2Run,all_Conds2Run,fig_num_avg,colors,shapes,idx_plot_relative,analysis_type1,[]);
        % Plot average lines
        outpath = strcat(OUTdir,filesep,'ABR');
        filename = 'ABR_Thresholds_Average_dBSPL';
        plot_avg_abr(thresholds,analysis_type1,colors,shapes,idx,conds_idx,Chins2Run,Conds2Run,all_Conds2Run,outpath,filename,fig_num_avg,ylimits_avg_threshold,idx_plot_relative,[])
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
                    cd(PRIVATEdir);
                    df_z = load_files(subj_outpath_z, sf_z, 'data', [], true);
                    cd(cwd);
                    if ~isempty(df_z)
                        cd(subj_outpath_z);
                        tmp_z = load(df_z);
                        cd(cwd);
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
            outpath_avg = strcat(OUTdir,filesep,'ABR');
            fig_num_base = (ChinIND - 1) * (length(freq) * length(all_Conds2Run)) + (z-1)*20 + length(all_Conds2Run) + CondIND;

            % Peak-to-peak amplitude (fig base+1)
            fig_num_avg = fig_num_base + 1;
            [amplitudes,idx] = avg_abr(lev_freq,amp_freq,Chins2Run,Conds2Run,all_Conds2Run,fig_num_avg,colors,shapes,idx_plot_relative,analysis_type1,'Amplitude');
            if freq(z) == 0, filename = 'ABR_PeakAmplitude_Average_dtw_click';
            else,            filename = ['ABR_PeakAmplitude_Average_dtw_',mat2str(freq(z))]; end
            plot_avg_abr(amplitudes,analysis_type1,colors,shapes,idx,conds_idx,Chins2Run,Conds2Run,all_Conds2Run,outpath_avg,filename,fig_num_avg,[],idx_plot_relative,'Amplitude',freq(z),wave_sel)

            % Peak latency (fig base+2)
            fig_num_avg = fig_num_base + 2;
            [latencies,idx] = avg_abr(lev_freq,lat_freq,Chins2Run,Conds2Run,all_Conds2Run,fig_num_avg,colors,shapes,idx_plot_relative,analysis_type1,'Latency');
            if freq(z) == 0, filename = 'ABR_PeakLatency_Average_dtw_click';
            else,            filename = ['ABR_PeakLatency_Average_dtw_',mat2str(freq(z))]; end
            plot_avg_abr(latencies,analysis_type1,colors,shapes,idx,conds_idx,Chins2Run,Conds2Run,all_Conds2Run,outpath_avg,filename,fig_num_avg,[],idx_plot_relative,'Latency',freq(z),wave_sel)

            % Build trough-latency table: move N columns (even) to odd positions so
            % avg_abr's 1:2:width scan picks them up as w1…w5.
            lat_trough_freq = cell(n_subj, n_cond);
            for ci_t = 1:n_subj
                for cj_t = 1:n_cond
                    m = lat_freq{ci_t, cj_t};
                    if isempty(m) || size(m,2) < 2, continue; end
                    n_waves = floor(size(m,2)/2);
                    tmp = zeros(size(m,1), n_waves*2);
                    for ww = 1:n_waves
                        tmp(:, 2*ww-1) = m(:, 2*ww);   % N (trough) into odd column
                    end
                    lat_trough_freq{ci_t, cj_t} = tmp;
                end
            end
            [trough_lat,~] = avg_abr(lev_freq, lat_trough_freq, Chins2Run, Conds2Run, ...
                all_Conds2Run, fig_num_avg, colors, shapes, idx_plot_relative, ...
                analysis_type1, 'Latency');

            % Waveform waterfall (fig base+3)
            waveforms.x         = wft_freq;
            waveforms.y         = wf_freq;
            waveforms.freq      = freq_cell;
            waveforms.levels    = lev_freq;
            waveforms.subjects  = Chins2Run;
            waveforms.conditions = [convertCharsToStrings(all_Conds2Run(:)');idx];
            fig_num_wf = fig_num_base + 3;
            plot_abr_waterfall(waveforms, latencies, trough_lat, colors, shapes, Chins2Run, Conds2Run, all_Conds2Run, conds_idx, freq(z), outpath_avg, fig_num_wf);

            cd(outpath_avg);
            if freq(z) == 0, filename = 'ABR_Waveforms_click';
            else,            filename = ['ABR_Waveforms_',mat2str(freq(z))]; end
            save(filename,'waveforms');
            cd(cwd);
        end
    end
end
cd(cwd);
end