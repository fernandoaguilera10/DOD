function ABRsummary(outpath,OUTdir,PRIVATEdir,Conds2Run,Chins2Run,all_Conds2Run,ChinIND,CondIND,idx_plot_relative,ylimits_ind_threshold,ylimits_ind_peaks,ylimits_ind_lat,ylimits_avg_threshold,ylimits_avg_peaks,ylimits_avg_lat,colors,shapes,analysis_type1,average_flag,conds_idx,freq,levels,wave_sel,wave_ratios)% ABR summary
global abr_f abr_thresholds abr_peaks_amp abr_peaks_lat abr_peaks_f abr_peaks_label abr_peaks_level abr_peaks_waveform abr_peaks_waveform_time
if nargin < 24 || isempty(wave_sel),    wave_sel    = true(1,5); end
if nargin < 25,                          wave_ratios = {};        end
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
        if nargin >= 21 && ~isempty(freq)
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
        % Recreate diagnostic figures from saved plot data when Branch 1
        % (analysis) was skipped. Uses data saved in _ABRthresholds.mat —
        % no re-running of the bootstrapping analysis.
        diag_names = {sprintf('ABR Waveforms|%s', condition{end}), ...
                      sprintf('Sigmoid Fits|%s',  condition{end}), ...
                      sprintf('Audiogram|%s',     condition{end})};
        diag_missing = any(cellfun(@(n) isempty(findobj('Type','figure','Name',n)), diag_names));
        if diag_missing && isfield(abr_out_full,'plot_data') && ~isempty(abr_out_full.plot_data)
            pd   = abr_out_full.plot_data;
            fs_r = abr_out_full.fs;
            nf   = numel(pd);
            clr_no  = [0,0,0,.3];  clr_yes = [0,0,0,1];

            abr_vis = figure('Name',sprintf('ABR Waveforms|%s',condition{end}), ...
                             'NumberTitle','off','Visible','off');
            set(abr_vis,'Units','Normalized','OuterPosition',[0.35,0.025,0.65,0.9]);
            fit_vis = figure('Name',sprintf('Sigmoid Fits|%s',condition{end}), ...
                             'NumberTitle','off','Visible','off');
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

            freqs_r = abr_out_full.freqs;  thresh_r = abr_out_full.thresholds;
            thr_vis = figure('Name',sprintf('Audiogram|%s',condition{end}), ...
                             'NumberTitle','off','Visible','off');
            set(thr_vis,'Units','Normalized','OuterPosition',[0,0.025,0.35,0.425]);
            set(0,'CurrentFigure', thr_vis);
            fp = freqs_r/1000;
            if any(fp==0)
                nc = fp(fp>0);
                if ~isempty(nc), fp(fp==0) = nc(1)/2; else, fp(fp==0) = 0.25; end
            end
            plot(fp, thresh_r, '*-k','linewidth',2); grid on; xticks(fp);
            tick_lbl = cell(1,length(freqs_r));
            for fi_r = 1:length(freqs_r)
                if freqs_r(fi_r)==0, tick_lbl{fi_r}='Click';
                else, tick_lbl{fi_r}=num2str(freqs_r(fi_r)/1000); end
            end
            xticklabels(tick_lbl); set(gca,'xscale','log'); set(gca,'FontSize',15);
            yticks(0:10:100); ylim([0,90]);
            title(['ABR Thresholds | ',cell2mat(Chins2Run(ChinIND)),' | ',condition{2}]);
            xlabel('Frequency (Hz)','FontWeight','bold');
            ylabel('Threshold (dB SPL)','FontWeight','bold');
        end
    elseif strcmp(analysis_type1,'Peaks')
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
                plot_ind_abr(abrs,analysis_type1,colors,shapes,Conds2Run,Chins2Run,all_Conds2Run,ChinIND,CondIND,outpath,[],ylimits_ind_peaks,ylimits_ind_lat,freq)
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
            plot_avg_abr(amplitudes,analysis_type1,colors,shapes,idx,conds_idx,Chins2Run,Conds2Run,all_Conds2Run,outpath_avg,filename,fig_num_avg,[],idx_plot_relative,'Amplitude',freq(z),wave_sel,wave_ratios)

            % Peak latency (fig base+2)
            fig_num_avg = fig_num_base + 2;
            [latencies,idx] = avg_abr(lev_freq,lat_freq,Chins2Run,Conds2Run,all_Conds2Run,fig_num_avg,colors,shapes,idx_plot_relative,analysis_type1,'Latency');
            if freq(z) == 0, filename = 'ABR_PeakLatency_Average_dtw_click';
            else,            filename = ['ABR_PeakLatency_Average_dtw_',mat2str(freq(z))]; end
            plot_avg_abr(latencies,analysis_type1,colors,shapes,idx,conds_idx,Chins2Run,Conds2Run,all_Conds2Run,outpath_avg,filename,fig_num_avg,[],idx_plot_relative,'Latency',freq(z),wave_sel,wave_ratios)

            % Waveform waterfall (fig base+3)
            waveforms.x         = wft_freq;
            waveforms.y         = wf_freq;
            waveforms.freq      = freq_cell;
            waveforms.levels    = lev_freq;
            waveforms.subjects  = Chins2Run;
            waveforms.conditions = [convertCharsToStrings(all_Conds2Run(:)');idx];
            fig_num_wf = fig_num_base + 3;
            plot_abr_waterfall(waveforms, latencies, colors, shapes, Chins2Run, Conds2Run, all_Conds2Run, conds_idx, freq(z), outpath_avg, fig_num_wf);

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