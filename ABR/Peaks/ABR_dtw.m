function ABR_dtw(ROOTdir,CODEdir,datapath,outpath,Chins2Run,ChinIND,Conds2Run,CondIND,colors,shapes,ylimits_ind)
%Author (s): Andrew Sivaprakasam
%Last Updated: 11 Sep 2025
%Description: Script to process ABR waveforms to automatically select peaks
%using Dynamic Time Warping (DTW)

%TODO:
% - Account for NEL latency differences

%freq = [0 0.5 1 2 4 8]*10^3;
freq = [0];
levels = [80];
template_shift = 'none';        % xcorr = cross-correlation     % peak = first significant peak     % none = no shift
cwd = pwd;
TEMPLATEdir = strcat(CODEdir,filesep,'templates');
condition = strsplit(Conds2Run{CondIND}, filesep);
%% Check ABR levels and templates available
% Check all ABR levels available
idx_abr = nan(length(levels),length(freq));
for z = 1:length(freq)
    for j = 1:length(levels)
        cd(datapath);
        if freq(z) == 0, datafiles = {dir(fullfile(cd,'p*click*.mat')).name}; end
        if freq(z) ~= 0, datafiles = {dir(fullfile(cd,['p*',mat2str(freq(z)),'*.mat'])).name}; end
        for i=1:length(datafiles)
            cd(datapath)
            load(datafiles{i});
            lev = round(x.Stimuli.MaxdBSPLCalib-x.Stimuli.atten_dB);
            if lev == levels(j)
                idx_abr(j,z) = i;
            end
            clear x;
        end
    end
end
% Check all templates available
idx_template = nan(size(idx_abr));
for z = 1:length(freq)
    for j = 1:length(levels)
        if freq(z) == 0, freq_str = 'click'; end
        if freq(z) ~= 0, freq_str = [num2str(freq(z)), 'Hz']; end
        cd(TEMPLATEdir)
        template_str = dir(sprintf('template_%s_%sdBSPL.mat',freq_str,mat2str(levels(j))));
        if ~isempty(template_str)
            idx_template(j,z) = 1;
        end
    end
end
fprintf('\n\nTemplate Availability\n\n');
fprintf('%-10s', 'dB SPL');
% for z = 1:length(idx_template)
%     if freq(z) == 0
%         fprintf('%-10s', 'Click');
%     else
%         fprintf('%-10s', mat2str(freq(z)));
%     end
% end
fprintf('\n');
for i = 1:size(levels,2)
    fprintf('%-10s', mat2str(levels(i)));
    for j = 1:size(idx_template,2)
        if ~isnan(idx_template(i,j))
            fprintf('%-10s', 'YES');
        else
            fprintf('%-10s', 'NO');
        end
    end
    fprintf('\n');
end
%% Dynamic Time Warping (DTW)
for z = 1:length(freq)
    for j = 1:length(levels)
        if freq(z) == 0, freq_str = 'click'; end
        if freq(z) ~= 0, freq_str = [num2str(freq(z)), 'Hz']; end
        if ~isnan(idx_abr(j,z)) && ~isnan(idx_template(j,z)) || ~isnan(idx_abr(j,z)) && ~isnan(idx_template(1,z))      % ABR + template available
            % Load template file
            cd(TEMPLATEdir);
            % if no other templates available, use template at highest level
            if ~isnan(idx_template(1,z))
                template_filename = sprintf('template_%s_%sdBSPL.mat',freq_str,mat2str(levels(1)));
            else
                template_filename = sprintf('template_%s_%sdBSPL.mat',freq_str,mat2str(levels(j)));
            end
            load(template_filename)
            abr_template = abr - mean(abr);
            abr_points = points;
            % Load ABR file
            cd(datapath);
            if freq(z) == 0, datafiles = {dir(fullfile(cd,'p*click*.mat')).name}; end
            if freq(z) ~= 0, datafiles = {dir(fullfile(cd,['p*',mat2str(freq(z)),'*.mat'])).name}; end
            load(datafiles{idx_abr(j,z)});
            % Resample and make sure the level is correct
            fs = 8e3;
            if iscell(x.AD_Data.AD_All_V{1})
                abr_data = mean(x.AD_Data.AD_All_V{1}{1}) - mean(mean(x.AD_Data.AD_All_V{1}{1})); % waveform with DC offset removed
            else
                abr_data =mean(cell2mat(x.AD_Data.AD_All_V)) - mean(mean(cell2mat(x.AD_Data.AD_All_V))); % waveform with DC offset removed
            end
            abr_data = resample(abr_data,fs,round(x.Stimuli.RPsamprate_Hz));
            abr_t = (1:length(abr_data))/fs;
            %% Shift template to better match ABR waveform
            switch template_shift
                case 'xcorr' % XCORR --> max peak
                    [xcorr_out, lags] = xcorr(abr_data, abr_template, 'coeff');
                    [~, max_idx] = max(xcorr_out);
                    sample_diff = lags(max_idx);
                case 'peak' % First peak
                minPeakDistance = round(0.001 * fs);    % 1 ms resolution
                abr_prom_thresh = 3 * median(abs(abr_data));    % 3 std above NF
                template_prom_thresh = 3 * median(abs(abr_template));    % 3 std above NF
                [~, locs_abr] = findpeaks(abr_data,'MinPeakProminence',abr_prom_thresh,'MinPeakDistance', minPeakDistance); 
                [~, locs_template] = findpeaks(abr_template,'MinPeakProminence',template_prom_thresh,'MinPeakDistance', minPeakDistance);
                sample_diff = locs_abr(1) - locs_template(1);
                case 'none'
                    sample_diff = 0;
            end

            % Shift template or ABR
            if sample_diff > 0      % ABR leading
                temp = abr_template(1:abs(sample_diff));
                template_temp = [temp,temp,abr_template(abs(sample_diff)+1:end-abs(sample_diff))];
                abr_template = template_temp;
                abr_points(:,1) = abr_points(:,1) + sample_diff/fs;
                abr_points(:,3) = abr_points(:,3) + sample_diff;
            elseif sample_diff < 0   % template leading
                temp = abr_template(end-abs(sample_diff)+1:end);
                template_temp = [abr_template(abs(sample_diff)+1:end-abs(sample_diff)),temp,temp];
                abr_template = template_temp;
                abr_points(:,1) = abr_points(:,1) - sample_diff/fs;
                abr_points(:,3) = abr_points(:,3) - sample_diff;
            end

            % DTW and plotting
            fig_num = (z-1)*length(levels) + j;
            [peaks,latencies] = findPeaks_dtw(abr_t,abr_data,abr_template,abr_points,Chins2Run(ChinIND),condition{2},Conds2Run,CondIND,levels,fig_num,j,colors,shapes,ylimits_ind,freq_str,idx_abr(j,z),idx_template(j,z));
            abrs.freq = freq(z);
            abrs.peak_amplitude(j,:) = peaks;
            abrs.peak_latency(j,:) = latencies;
            abrs.waveforms(j,:) = abr_data*10^2;
            abrs.waveforms_time = abr_t*10^3;
            abrs.levels = levels';
        elseif ~isnan(idx_abr(j,z)) && isnan(idx_template(j,z)) && isnan(idx_template(1,z))     % ABR available + no template
            % Load ABR file
            cd(datapath);
            if freq(z) == 0, datafiles = {dir(fullfile(cd,'p*click*.mat')).name}; end
            if freq(z) ~= 0, datafiles = {dir(fullfile(cd,['p*',mat2str(freq(z)),'*.mat'])).name}; end
            load(datafiles{idx_abr(j,z)});
            %% Resample and make sure the level is correct
            fs = 8e3;
            if iscell(x.AD_Data.AD_All_V{1})
                abr_data = mean(x.AD_Data.AD_All_V{1}{1}) - mean(mean(x.AD_Data.AD_All_V{1}{1})); % waveform with DC offset removed
            else
                abr_data =mean(cell2mat(x.AD_Data.AD_All_V)) - mean(mean(cell2mat(x.AD_Data.AD_All_V))); % waveform with DC offset removed
            end
            abr_data = resample(abr_data,fs,round(x.Stimuli.RPsamprate_Hz));
            abr_t = (1:length(abr_data))/fs;
            abr_template = nan(size(abr_data));
            abr_points = nan(10,3);
            fig_num = (z-1)*length(levels) + j;
            [peaks,latencies] = findPeaks_dtw(abr_t,abr_data,abr_template,abr_points,Chins2Run(ChinIND),condition{2},Conds2Run,CondIND,levels,fig_num,j,colors,shapes,ylimits_ind,freq_str,idx_abr(j,z),idx_template(j,z));
            abrs.freq = freq(z);
            abrs.peak_amplitude(j,:) = peaks;
            abrs.peak_latency(j,:) = latencies;
            abrs.waveforms(j,:) = abr_data*10^2;
            abrs.waveforms_time = abr_t*10^3;
            abrs.levels = levels';
        elseif isnan(idx_abr(j,z))  % ABR unavailable
            fig_num = (z-1)*length(levels) + j;
            [peaks,latencies] = findPeaks_dtw([],[],[],[],Chins2Run(ChinIND),condition{2},Conds2Run,CondIND,levels,fig_num,j,colors,shapes,ylimits_ind,freq_str,idx_abr(j,z),idx_template(j,z));
            abrs.freq = [];
            abrs.peak_amplitude(j,:) = peaks;
            abrs.peak_latency(j,:) = latencies;
            abrs.waveforms(j,:) = [];
            abrs.waveforms_time = [];
            abrs.levels = levels';
        end
    end
    % Standardize data format to match manual ABR peak picking
%     abrs.thresholds = [freq(z),nan,nan,nan];
%     abrs.z.par = [freq(z),nan,nan];
%     abrs.z.score = [repmat(freq(z),10,1),levels',flip(sort(rand(10,2),1))];
%     abrs.amp = [repmat(freq(z),10,1),flip(levels)',flip(sort(rand(10,2),1))];
%     abrs.x = [repmat(freq(z),10,1),levels',abrs.peak_latency];
%     abrs.y = [repmat(freq(z),10,1),levels',abrs.peak_amplitude];
%     abrs.waves = [repmat(freq(z),10,1),levels',abrs.waveforms];
    %% Export
    cd(outpath);
    filename = cell2mat([Chins2Run(ChinIND),'_',condition{2},'_ABRpeaks_dtw_',freq_str]);
    print(figure(fig_num),[filename,'_figure'],'-dpng','-r300');
    save(filename,'abrs')
    cd(cwd)
end
end