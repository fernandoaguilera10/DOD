function ABRsummary(outpath,OUTdir,PRIVATEdir,Conds2Run,Chins2Run,all_Conds2Run,ChinIND,CondIND,idx_plot_relative,ylimits_ind_threshold,ylimits_ind_peaks,ylimits_ind_lat,ylimits_avg_threshold,ylimits_avg_peaks,ylimits_avg_lat,colors,shapes,analysis_type1, analysis_type2,average_flag,conds_idx,freq,levels)% ABR summary
global abr_f abr_thresholds abr_peaks_amp abr_peaks_lat abr_peaks_f abr_peaks_label abr_peaks_level abr_peaks_waveform abr_peaks_waveform_time
cwd = pwd;
%% INDIVIDUAL PLOTS
condition = strsplit(all_Conds2Run{CondIND}, filesep);
if exist(outpath,"dir")
    cd(PRIVATEdir)
    if strcmp(analysis_type1,'Thresholds')
        search_file = cell2mat([Chins2Run(ChinIND),'_',condition{1},condition{2},'_ABRthresholds.mat']);
        datafile = load_files(outpath,search_file,'data');
        cd(outpath);
        load(datafile);
        cd(cwd);
        % PLOTTING SPL
        abr_f{ChinIND,CondIND} = abr_out.freqs;
        abr_thresholds{ChinIND,CondIND} = abr_out.thresholds;
        plot_ind_abr(abr_out,analysis_type1,colors,shapes,Conds2Run,Chins2Run,all_Conds2Run,ChinIND,CondIND,outpath,ylimits_ind_threshold,[],[],[])
    elseif strcmp(analysis_type1,'Peaks')
        for z = 1:length(freq)
            if strcmp(analysis_type2,'Manual')
                if freq(z) == 0, search_file = cell2mat(['*',Chins2Run(ChinIND),'_',condition{2},'_ABRpeaks_manual_click*.mat']); end
                if freq(z) ~= 0, search_file = cell2mat(['*',Chins2Run(ChinIND),'_',condition{2},'_ABRpeaks_manual_',mat2str(freq(z)),'*.mat']); end
                cd(PRIVATEdir)
                datafile = load_files(outpath,search_file,'data');
                if ~isempty(datafile)
                    cd(outpath);
                    load(datafile);
                    abrs = abrs.plot;
                end
            elseif strcmp(analysis_type2,'DTW')
                if freq(z) == 0, search_file = cell2mat(['*',Chins2Run(ChinIND),'_',condition{2},'_ABRpeaks_dtw_click*.mat']); end
                if freq(z) ~= 0, search_file = cell2mat(['*',Chins2Run(ChinIND),'_',condition{2},'_ABRpeaks_dtw_',mat2str(freq(z)),'*.mat']); end
                cd(PRIVATEdir)
                datafile = load_files(outpath,search_file,'data');
                if ~isempty(datafile)
                    cd(outpath);
                    load(datafile);
                end
            end
            cd(cwd)
            if ~isempty(datafile)
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
        [average,idx] = avg_abr(abr_f,abr_thresholds,Chins2Run,Conds2Run,all_Conds2Run,fig_num_avg,colors,shapes,idx_plot_relative,analysis_type1,[]);
        % Plot average lines
        outpath = strcat(OUTdir,filesep,'ABR');
        filename = 'ABR_Thresholds_Average_dBSPL';
        plot_avg_abr(average,analysis_type1,colors,shapes,idx,conds_idx,Chins2Run,Conds2Run,all_Conds2Run,outpath,filename,fig_num_avg,ylimits_avg_threshold,idx_plot_relative,[])
    elseif strcmp(analysis_type1,'Peaks')
        for z = 1:length(freq)
            if strcmp(analysis_type2,'Manual')
                % Peak-to-peak amplitude
                fig_num_avg = ((ChinIND - 1) * length(Conds2Run) + CondIND)+1;
                [average,idx] = avg_abr(abr_peaks_level,abr_peaks_amp,Chins2Run,Conds2Run,all_Conds2Run,fig_num_avg,colors,shapes,idx_plot_relative,analysis_type1,'Amplitude');
                outpath = strcat(OUTdir,filesep,'ABR');
                if freq(z) == 0, filename = 'ABR_PeakAmplitude_Average_manual_click'; end
                if freq(z) ~= 0, filename = ['ABR_PeakAmplitude_Average_manual_',mat2str(freq(z))]; end
                cd()
                plot_avg_abr(average,analysis_type1,colors,shapes,idx,conds_idx,Chins2Run,Conds2Run,all_Conds2Run,outpath,filename,fig_num_avg,[],idx_plot_relative,'Amplitude',freq(z))
                % Peak latency
                fig_num_avg = ((ChinIND - 1) * length(Conds2Run) + CondIND)+7;
                [average,idx] = avg_abr(abr_peaks_level,abr_peaks_lat,Chins2Run,Conds2Run,all_Conds2Run,fig_num_avg,colors,shapes,idx_plot_relative,analysis_type1,'Latency');
                outpath = strcat(OUTdir,filesep,'ABR'); cd(cwd);
                if freq(z) == 0, filename = 'ABR_PeakLatency_Average_manual_click'; end
                if freq(z) ~= 0, filename = ['ABR_PeakLatency_Average_manual_',mat2str(freq(z))]; end
                plot_avg_abr(average,analysis_type1,colors,shapes,idx,conds_idx,Chins2Run,Conds2Run,all_Conds2Run,outpath,filename,fig_num_avg,[],idx_plot_relative,'Latency',freq(z))
            elseif strcmp(analysis_type2,'DTW')
                % Peak-to-peak amplitude
                fig_num_avg = (ChinIND - 1) * (length(freq) * length(all_Conds2Run)) +  length(all_Conds2Run) + CondIND +1;
                [average,idx] = avg_abr(abr_peaks_level,abr_peaks_amp,Chins2Run,Conds2Run,all_Conds2Run,fig_num_avg,colors,shapes,idx_plot_relative,analysis_type1,'Amplitude');
                outpath = strcat(OUTdir,filesep,'ABR');
                if freq(z) == 0, filename = 'ABR_PeakAmplitude_Average_dtw_click'; end
                if freq(z) ~= 0, filename = ['ABR_PeakAmplitude_Average_dtw_',mat2str(freq(z))]; end
                plot_avg_abr(average,analysis_type1,colors,shapes,idx,conds_idx,Chins2Run,Conds2Run,all_Conds2Run,outpath,filename,fig_num_avg,[],idx_plot_relative,'Amplitude',freq(z))
                % Peak latency
                fig_num_avg = (ChinIND - 1) * (length(freq) * length(all_Conds2Run)) +  length(all_Conds2Run) + CondIND +7;
                [average,idx] = avg_abr(abr_peaks_level,abr_peaks_lat,Chins2Run,Conds2Run,all_Conds2Run,fig_num_avg,colors,shapes,idx_plot_relative,analysis_type1,'Latency');
                outpath = strcat(OUTdir,filesep,'ABR'); cd(cwd);
                if freq(z) == 0, filename = 'ABR_PeakLatency_Average_dtw_click'; end
                if freq(z) ~= 0, filename = ['ABR_PeakLatency_Average_dtw_',mat2str(freq(z))]; end
                plot_avg_abr(average,analysis_type1,colors,shapes,idx,conds_idx,Chins2Run,Conds2Run,all_Conds2Run,outpath,filename,fig_num_avg,[],idx_plot_relative,'Latency',freq(z))
            end
            outpath = strcat(OUTdir,filesep,'ABR');
            cd(outpath)
            if freq(z) == 0, filename = 'ABR_Waveforms_click'; end
            if freq(z) ~= 0, filename = ['ABR_Waveforms_',mat2str(freq(z))]; end
            waveforms.x = abr_peaks_waveform_time;
            waveforms.y = abr_peaks_waveform;
            waveforms.freq = abr_peaks_f;
            waveforms.levels = abr_peaks_level;
            waveforms.subjects = Chins2Run;
            waveforms.conditions = [convertCharsToStrings(all_Conds2Run);idx];
            save(filename,'waveforms');
            cd(cwd);
        end
    end
end
cd(cwd);
end