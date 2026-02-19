function define_global_vars(Chins2Run,all_Conds2Run,EXPname,EXPname2)
dim_size = [length(Chins2Run),length(all_Conds2Run)];
switch EXPname
    case 'ABR'
        global abr_f abr_thresholds abr_peaks_amp abr_peaks_lat abr_peaks_f abr_peaks_label abr_peaks_level abr_peaks_waveform abr_peaks_waveform_time
        abr_f = cell(dim_size);
        abr_thresholds = cell(dim_size);
        abr_peaks_amp = cell(dim_size);
        abr_peaks_lat = cell(dim_size);
        abr_peaks_f = cell(dim_size);
        abr_peaks_label = cell(dim_size);
        abr_peaks_level = cell(dim_size);
        abr_peaks_waveform = cell(dim_size);
        abr_peaks_waveform_time = cell(dim_size);
    case 'EFR'
        switch EXPname2
            case 'RAM'
                global efr_f efr_envelope efr_PLV efr_peak_amp efr_peak_freq efr_peak_freq_all dim_f dim_envelope dim_PLV dim_peak_amp dim_peak_freq dim_peak_freq_all
                efr_f = cell(dim_size);
                efr_envelope = cell(dim_size);
                efr_PLV = cell(dim_size);
                efr_peak_amp = cell(dim_size);
                efr_peak_freq = cell(dim_size);
                efr_peak_freq_all = cell(dim_size);
            case 'dAM'
                global efr_trajectory efr_dAMpower efr_NFpower efr_trajectory_smooth efr_dAMpower_smooth efr_NFpower_smooth dim_trajectory dim_dAMpower dim_NFpower dim_dAMpower_smooth dim_NFpower_smooth
                efr_trajectory = cell(dim_size);
                efr_dAMpower = cell(dim_size);
                efr_NFpower = cell(dim_size);
                efr_trajectory_smooth = cell(dim_size);
                efr_dAMpower_smooth = cell(dim_size);
                efr_NFpower_smooth = cell(dim_size);
        end
    case 'OAE'
        switch EXPname2
            case 'DPOAE'
                global dp_f_epl dp_amp_epl dp_nf_epl dp_f2_band_epl dp_amp_band_epl dp_nf_band_epl
                global dp_f2_spl dp_amp_spl dp_nf_spl dp_f2_band_spl dp_amp_band_spl dp_nf_band_spl
                % EPL
                dp_f_epl = cell(dim_size);
                dp_amp_epl = cell(dim_size);
                dp_nf_epl = cell(dim_size);
                dp_f2_band_epl = cell(dim_size);
                dp_amp_band_epl = cell(dim_size);
                dp_nf_band_epl = cell(dim_size);
                % SPL
                dp_f2_spl = cell(dim_size);
                dp_amp_spl = cell(dim_size);
                dp_nf_spl = cell(dim_size);
                dp_f2_band_spl = cell(dim_size);
                dp_amp_band_spl = cell(dim_size);
                dp_nf_band_spl = cell(dim_size);
            case 'SFOAE'
                global sf_f_epl sf_amp_epl sf_nf_epl sf_f_band_epl sf_amp_band_epl sf_nf_band_epl
                global sf_f_spl sf_amp_spl sf_nf_spl sf_f_band_spl sf_amp_band_spl sf_nf_band_spl
                % EPL
                sf_f_epl = cell(dim_size);
                sf_amp_epl = cell(dim_size);
                sf_nf_epl = cell(dim_size);
                sf_f_band_epl = cell(dim_size);
                sf_amp_band_epl = cell(dim_size);
                sf_nf_band_epl = cell(dim_size);
                % SPL
                sf_f_spl = cell(dim_size);
                sf_amp_spl = cell(dim_size);
                sf_nf_spl = cell(dim_size);
                sf_f_band_spl = cell(dim_size);
                sf_amp_band_spl = cell(dim_size);
                sf_nf_band_spl = cell(dim_size);
            case 'TEOAE'
                global te_f_epl te_amp_epl te_nf_epl te_f_band_epl te_amp_band_epl te_nf_band_epl
                global te_f_spl te_amp_spl te_nf_spl te_f_band_spl te_amp_band_spl te_nf_band_spl
                % EPL
                te_f_epl = cell(dim_size);
                te_amp_epl = cell(dim_size);
                te_nf_epl = cell(dim_size);
                te_f_band_epl = cell(dim_size);
                te_amp_band_epl = cell(dim_size);
                te_nf_band_epl = cell(dim_size);
                % SPL
                te_f_spl = cell(dim_size);
                te_amp_spl = cell(dim_size);
                te_nf_spl = cell(dim_size);
                te_f_band_spl = cell(dim_size);
                te_amp_band_spl = cell(dim_size);
                te_nf_band_spl = cell(dim_size);
        end
    case 'MEMR'
        global elicitor deltapow threshold
        elicitor = cell(dim_size);
        deltapow = cell(dim_size);
        threshold = cell(dim_size);
end
end


