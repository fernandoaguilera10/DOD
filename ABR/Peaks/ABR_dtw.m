function ABR_dtw(ROOTdir,CODEdir,datapath,outpath,Chins2Run,ChinIND,all_Conds2Run,Conds2Run,CondIND,nel_delay,colors,shapes,ylimits_ind,freq,levels,template_per_level)
%Author (s): Andrew Sivaprakasam
%Last Updated: 11 Sep 2025
%Description: Script to process ABR waveforms to automatically select peaks
%using Dynamic Time Warping (DTW)

%TODO:
% - Account for NEL latency differences

template_shift = 'none';        % xcorr = cross-correlation     % peak = first significant peak     % none = no shift
if nargin < 16 || isempty(template_per_level), template_per_level = false; end
cwd = pwd;
TEMPLATEdir = strcat(CODEdir,filesep,'templates');
condition = strsplit(all_Conds2Run{CondIND}, filesep);
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
%% NEL delay for this subject/condition (same logic as findPeaks_dtw)
if ~isempty(nel_delay) && ~isnan(nel_delay.delay_ms(ChinIND,CondIND))
    nel_delay_ms = nel_delay.delay_ms(ChinIND,CondIND);
else
    nel_delay_ms = 0;
end

%% Dynamic Time Warping (DTW)
all_point_names = {'P1','N1','P2','N2','P3','N3','P4','N4','P5','N5'};
abr_points = nan(length(all_point_names),3);
for z = 1:length(freq)
    for j = 1:length(levels)
        if freq(z) == 0, freq_str = 'click'; end
        if freq(z) ~= 0, freq_str = [num2str(freq(z)), 'Hz']; end
        if ~isnan(idx_abr(j,z))      % ABR available
            % Determine which template file to use.
            % template_per_level=true: strict — only use the level's own template.
            % template_per_level=false (default): fall back to highest-level template.
            if ~isnan(idx_template(j,z))
                template_filename = sprintf('template_%s_%sdBSPL.mat',freq_str,mat2str(levels(j)));
            elseif ~template_per_level && ~isnan(idx_template(1,z))
                template_filename = sprintf('template_%s_%sdBSPL.mat',freq_str,mat2str(levels(1)));
                fprintf('  [ABR_dtw] Using %d dB template as fallback for %s %d dB SPL.\n', levels(1), freq_str, levels(j));
            else
                template_filename = '';
            end
            % Load template (guard against missing file)
            if ~isempty(template_filename) && exist(fullfile(TEMPLATEdir,template_filename),'file')
                cd(TEMPLATEdir);
                load(template_filename)
                abr_template = abr - mean(abr);
                idx_abr_points = ismember(all_point_names,point_names);
                abr_points(idx_abr_points,:) = points;
            else
                if ~isempty(template_filename)
                    fprintf('  [ABR_dtw] Template not found: %s — running without template.\n', template_filename);
                else
                    fprintf('  [ABR_dtw] No template for %s %d dB SPL — running without template.\n', freq_str, levels(j));
                end
                abr_template = nan(1,1);
                abr_points   = nan(10,3);
            end
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

            % Check if MetaData exists
            if isfield(x,'MetaData') && ~isempty(x.MetaData)
                abrs.nel = str2double(x.MetaData.NEL(end));
                abrs.subject = x.MetaData.ChinID;
                abrs.sex = x.MetaData.Sex;
            else
                abrs.nel = [];
                abrs.subject = [];
                abrs.sex = [];
            end
            
            %% Shift template to better match ABR waveform
            switch template_shift
                case 'xcorr' % XCORR --> max peak
                    [xcorr_out, lags] = xcorr(abr_data/(max(abr_data)-min(abr_data)), abr_template/(max(abr_template)-min(abr_template)), 'coeff');
                    [~, max_idx] = max(xcorr_out);
                    sample_diff = lags(max_idx);
                case 'peak' % First peak
                minPeakDistance = round(0.001 * fs);    % 1 ms resolution
                abr_prom_thresh = median(abs(abr_data/(max(abr_data)-min(abr_data))));
                template_prom_thresh = median(abs(abr_template/(max(abr_template)-min(abr_template)))); 
                [~, locs_abr] = findpeaks(abr_data/(max(abr_data)-min(abr_data)),'MinPeakProminence',abr_prom_thresh,'MinPeakDistance', minPeakDistance); 
                [~, locs_template] = findpeaks(abr_template/(max(abr_template)-min(abr_template)),'MinPeakProminence',template_prom_thresh,'MinPeakDistance', minPeakDistance);
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
            fig_num = (ChinIND-1)*length(freq)*length(Conds2Run) + (CondIND-1)*length(freq) + z;
            [peaks,latencies] = findPeaks_dtw(abr_t,abr_data,abr_template,abr_points,nel_delay,Chins2Run(ChinIND),condition{2},Conds2Run,CondIND,ChinIND,levels,fig_num,j,colors,shapes,ylimits_ind,freq_str,idx_abr(j,z),idx_template(j,z),outpath);
            abrs.freq = freq(z);
            abrs.peak_amplitude(j,:) = peaks;
            abrs.peak_latency(j,:) = latencies;
            abrs.waveforms(j,:) = abr_data*10^2;
            abrs.waveforms_time = abr_t*10^3 - nel_delay_ms;
            abrs.levels = levels';
        elseif isnan(idx_abr(j,z))  % ABR unavailable
            fig_num = (ChinIND-1)*length(freq)*length(Conds2Run) + (CondIND-1)*length(freq) + z;
            [peaks,latencies] = findPeaks_dtw([],[],[],[],[],Chins2Run(ChinIND),condition{2},Conds2Run,CondIND,ChinIND,levels,fig_num,j,colors,shapes,ylimits_ind,freq_str,idx_abr(j,z),idx_template(j,z),outpath);
            abrs.freq = [];
            abrs.peak_amplitude(j,:) = peaks;
            abrs.peak_latency(j,:) = latencies;
            abrs.waveforms(j,:) = [];
            abrs.waveforms_time = [];
            abrs.levels = levels';
        end
    end
    %% Export
    abrs.nel_delay_ms = nel_delay_ms;   % stored so waveforms_time can be reconstructed without delay if needed
    cd(outpath);
    filename = cell2mat([Chins2Run(ChinIND),'_',condition{2},'_ABRpeaks_dtw_',freq_str]);
    % Find waterfall by Name (avoids figure-number collisions with plot_ind_abr)
    wf_name = sprintf('Peaks Waterfall|%s|%s', condition{end}, freq_str);
    fh = findobj('Type','figure','Name',wf_name);
    if ~isempty(fh) && isvalid(fh(1))
        print(fh(1),[filename,'_figure'],'-dpng','-r300');
        % Do NOT close — analysis_run.m embeds then closes it.
    end
    % Close the interactive editing figure (not embedded)
    fedit = findobj('Type','figure','Name','ABR Peak Selection');
    if ~isempty(fedit), close(fedit); end
    save(filename,'abrs')
    cd(cwd)
end
end