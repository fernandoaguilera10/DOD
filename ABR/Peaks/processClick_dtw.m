function processClick_dtw(datapath,outpath,Chins2Run,ChinIND,Conds2Run,CondIND,colors,shapes)
%Author (s): Andrew Sivaprakasam
%Last Updated: May, 2024
%Description: Script to process ABR high level clicks using Dynamic Time
%Warping

%TODO:
% - Account for NEL latency differences
% - What if multiple click files? Should user pick the right one?
freq = [0 0.5 1 2 4 8]*10^3;
levels = [90 80 70 60 50];
condition = strsplit(Conds2Run{CondIND}, filesep);
for z = 1:length(freq)
    if freq(z) == 0, freq_str = 'click'; end
    if freq(z) ~= 0, freq_str = [num2str(freq(z)), ' Hz']; end
    template_str = dir(sprintf('suprathreshold_template_%s.mat',freq_str));
    if ~isempty(template_str)
        template = load(template_str.name);
        %% Load files
        cwd = pwd();
        addpath(cwd)
        %Load Template
        cd(datapath);
        datafiles = {dir(fullfile(cd,'p*click*.mat')).name};
        for f = 1:length(datafiles)
            matches = regexp(datafiles{f},'p(\d+)_', 'tokens');
            pics(f) = str2double(matches{1}{1});
        end
        for j=1:length(levels)
            for i=1:length(datafiles)
                cd(datapath)
                load(datafiles{i});
                lev = round(x.Stimuli.MaxdBSPLCalib-x.Stimuli.atten_dB);
                if lev == levels(j)
                    I = i;
                    break;
                end
                clear x;
            end
            load(datafiles{I});
            %% Resample and make sure the level is correct
            fs = 8e3;
            if iscell(x.AD_Data.AD_All_V{1})
                abr_data = mean(x.AD_Data.AD_All_V{1}{1}) - mean(mean(x.AD_Data.AD_All_V{1}{1})); % waveform with DC offset removed
            else
                abr_data =mean(cell2mat(x.AD_Data.AD_All_V)) - mean(mean(cell2mat(x.AD_Data.AD_All_V))); % waveform with DC offset removed
            end
            abr_data = resample(abr_data,fs,round(x.Stimuli.RPsamprate_Hz));
            abr_t = (1:length(abr_data))/fs;
            %% Apply template
            abr_template = template.abr - mean(template.abr);
            abr_points = template.points;
            abr_t_template = template.t;
            fig_num = ((ChinIND - 1) * length(Conds2Run) + CondIND);
            [peaks,latencies] = findPeaks_dtw(abr_t_template,abr_data,abr_template,abr_points,Chins2Run(ChinIND),condition{2},CondIND,levels,fig_num,j,colors,shapes);
            abrs.plot.freq = freq(z);
            abrs.plot.peak_amplitude(j,:) = peaks;
            abrs.plot.peak_latency(j,:) = latencies;
            abrs.plot.waveforms(j,:) = abr_data*10^2;
            abrs.plot.waveforms_time = abr_t_template*10^3;
            abrs.plot.levels = levels';
            %abrs.plot.peaks =
        end
        %% Export and end
        cd(outpath);
        filename = cell2mat([Chins2Run(ChinIND),'_',condition,'_ABRpeaks_dtw_',freq_str]);
        print(figure(fig_num),[filename,'_figure'],'-dpng','-r300');
        save(filename,'abrs')
        cd(cwd)
    else
        fprintf('ERROR: No template was found for %s\n',freq_str)
    end
end
end