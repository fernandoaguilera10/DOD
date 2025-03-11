function ABRsummary(outpath,OUTdir,Conds2Run,Chins2Run,all_Conds2Run,ChinIND,CondIND,idx_plot_relative,ylimits_ind_threshold,ylimits_ind_peaks,ylimits_ind_lat,ylimits_avg_threshold,ylimits_avg_peaks,ylimits_avg_lat,colors,shapes,analysis_type1, analysis_type2,average_flag,conds_idx)% ABR summary
global abr_f abr_thresholds abr_peaks_amp abr_peaks_lat abr_peaks_f abr_peaks_label abr_peaks_level abr_peaks_waveform abr_peaks_waveform_time
cwd = pwd;
%% INDIVIDUAL PLOTS
condition = strsplit(all_Conds2Run{CondIND}, filesep);
if exist(outpath,"dir")
    cd(outpath)
    if strcmp(analysis_type1,'Thresholds')
        search_file = cell2mat([Chins2Run(ChinIND),'_',condition{1},condition{2},'_ABRthresholds.mat']);
        datafile = load_files(outpath,search_file);
        load(datafile);
        cd(cwd);
        % PLOTTING SPL
        abr_f{ChinIND,CondIND} = abr_out.freqs;
        abr_thresholds{ChinIND,CondIND} = abr_out.thresholds;
        plot_ind_abr(abr_out,analysis_type1,colors,shapes,Conds2Run,Chins2Run,all_Conds2Run,ChinIND,CondIND,outpath,ylimits_ind_threshold,[],[])
    elseif strcmp(analysis_type1,'Peaks')
        if strcmp(analysis_type2,'Manual')
            search_file = cell2mat(['*',Chins2Run(ChinIND),'_',condition{1},condition{2},'_ABRpeaks*.mat']);
            datafile = load_files(outpath,search_file);
            load(datafile);
            cd(cwd);
        elseif strcmp(analysis_type2,'DTW')
            search_file = cell2mat(['*',Chins2Run(ChinIND),'_',condition{1},condition{2},'_ABRpeaks_dtw*.mat']);
            datafile = load_files(outpath,search_file);
            load(datafile);
            cd(cwd);
        end
        abr_peaks_amp{ChinIND,CondIND} = abrs.plot.peak_amplitude;
        abr_peaks_lat{ChinIND,CondIND} = abrs.plot.peak_latency;
        abr_peaks_f{ChinIND,CondIND} = abrs.plot.freq;
        %abr_peaks_label{ChinIND,CondIND} = abrs.plot.peaks;
        abr_peaks_level{ChinIND,CondIND} = abrs.plot.levels;
        abr_peaks_waveform{ChinIND,CondIND} = abrs.plot.waveforms;
        abr_peaks_waveform_time{ChinIND,CondIND} = abrs.plot.waveforms_time;
        plot_ind_abr(abrs.plot,analysis_type1,colors,shapes,Conds2Run,Chins2Run,ChinIND,CondIND,outpath,[],ylimits_ind_peaks,ylimits_ind_lat)
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
        [average,idx] = avg_abr(abr_f,abr_thresholds,Chins2Run,Conds2Run,all_Conds2Run,fig_num_avg,colors,shapes,idx_plot_relative,analysis_type1,[]);
        % Plot average lines
        outpath = strcat(OUTdir,filesep,'ABR');
        filename = 'ABR_Thresholds_Average_dBSPL';
        plot_avg_abr(average,analysis_type1,colors,shapes,idx,conds_idx,Chins2Run,Conds2Run,all_Conds2Run,outpath,filename,fig_num_avg,ylimits_avg_threshold,idx_plot_relative)
    elseif strcmp(analysis_type1,'Peaks')
        if strcmp(analysis_type2,'Manual')
            % Peak-to-peak amplitude
            fig_num_avg = ((ChinIND - 1) * length(Conds2Run) + CondIND)+1;
            [average,idx] = avg_abr(abr_peaks_level,abr_peaks_amp,Chins2Run,Conds2Run,fig_num_avg,colors,shapes,idx_plot_relative,analysis_type1,'Amplitude');
            outpath = strcat(OUTdir,filesep,'ABR');
            filename = 'ABR_PeakAmplitude_Average';
            plot_avg_abr(average,analysis_type1,colors,shapes,idx,conds_idx,Conds2Run,outpath,filename,fig_num_avg,[],idx_plot_relative,'Amplitude')
            % Peak latency
            fig_num_avg = ((ChinIND - 1) * length(Conds2Run) + CondIND)+7;
            [average,idx] = avg_abr(abr_peaks_level,abr_peaks_lat,Chins2Run,Conds2Run,fig_num_avg,colors,shapes,idx_plot_relative,analysis_type1,'Latency');
            outpath = strcat(OUTdir,filesep,'ABR'); cd(cwd);
            filename = 'ABR_PeakLatency_Average';
            plot_avg_abr(average,analysis_type1,colors,shapes,idx,conds_idx,Conds2Run,outpath,filename,fig_num_avg,[],idx_plot_relative,'Latency')
        elseif strcmp(analysis_type2,'DTW')
            % Peak-to-peak amplitude
            fig_num_avg = ((ChinIND - 1) * length(Conds2Run) + CondIND)+1;
            [average,idx] = avg_abr(abr_peaks_level,abr_peaks_amp,Chins2Run,Conds2Run,fig_num_avg,colors,shapes,idx_plot_relative,analysis_type1,'Amplitude');
            outpath = strcat(OUTdir,filesep,'ABR');
            filename = 'ABR_PeakAmplitude_Average_dtw';
            plot_avg_abr(average,analysis_type1,colors,shapes,idx,conds_idx,Conds2Run,outpath,filename,fig_num_avg,[],idx_plot_relative,'Amplitude')
            % Peak latency
            fig_num_avg = ((ChinIND - 1) * length(Conds2Run) + CondIND)+7;
            [average,idx] = avg_abr(abr_peaks_level,abr_peaks_lat,Chins2Run,Conds2Run,fig_num_avg,colors,shapes,idx_plot_relative,analysis_type1,'Latency');
            outpath = strcat(OUTdir,filesep,'ABR'); cd(cwd);
            filename = 'ABR_PeakLatency_Average_dtw';
            plot_avg_abr(average,analysis_type1,colors,shapes,idx,conds_idx,Conds2Run,outpath,filename,fig_num_avg,[],idx_plot_relative,'Latency')
        end
    end
end
cd(cwd);
end