function ABR_thresholds_xcorr(ROOTdir,CODEdir,datapath,outpath,subject,all_datafiles,condition)
% Author (s): Fernando Aguilera de Alba
% Last Updated: 18 September 2025

% Description: Script to estimate and process ABR thresholds (a-files only)
% based on cross-correlation with template (based on Henry et al. 2011)

% Citation: Henry, Kenneth S., Sushrut Kale, Ryan E. Scheidt, and
% Michael G. Heinz. “Auditory Brainstem Responses Predict Auditory Nerve
% Fiber Thresholds and Frequency Selectivity in Hearing Impaired
% Chinchillas.” Hearing Research 280, nos. 1–2 (2011): 236–44.
% https://doi.org/10.1016/j.heares.2011.06.002.

cwd = pwd;
fs = 8e3; % resampling rate
%% Check frequencies available
all_freqs = cellfun(@(x) erase(extractAfter(x,'ABR_'), '.mat'), all_datafiles, 'UniformOutput', false);
all_freqs(strcmp(all_freqs,'click')) = {'0'};
freq = unique(str2double(all_freqs));
%% Check ABR levels available
idx_abr = nan(size(freq));
for z = 1:length(freq)
    if freq(z) == 0, freq_str = 'click'; end
    if freq(z) ~= 0, freq_str = num2str(freq(z)); end
    cd(datapath);
    abr_str = dir(sprintf('*ABR_%s*.mat',freq_str));
    if ~isempty(abr_str)
        idx_abr(z) = length(abr_str);   % number of files per stimulus
    end
end
%% Check templates available
TEMPLATEdir = strcat(CODEdir,filesep,'templates');
cd(TEMPLATEdir)
idx_template = nan(size(freq));
for z = 1:length(freq)
    if freq(z) == 0, freq_str = 'click'; end
    if freq(z) ~= 0, freq_str = num2str(freq(z)); end
    template_str = dir(sprintf('*template_thresholds_%s*.mat',freq_str));
    if ~isempty(template_str)
        idx_template(z) = length(template_str); % number of templates per stimulus
    end
end
%% Load Templates
templates = [];
avg_template = [];
template_level = [];
avg_template_all = cell(1,length(freq));
for z = 1:length(freq)
    if ~isnan(idx_abr(z)) && ~isnan(idx_template(z))
        if freq(z) == 0, freq_str = 'click'; end
        if freq(z) ~= 0, freq_str = num2str(freq(z)); end
        cd(TEMPLATEdir);
        % Load template file
        template_filename = {dir(fullfile(cd,sprintf('*template_thresholds_%s*.mat',freq_str))).name}';
        for d = 1:length(template_filename)
            load(template_filename{d})
            fs_orig = x.Stimuli.RPsamprate_Hz;
            temp = x.AD_Data.AD_Avg_V{1};
            template_level(d) = round(x.Stimuli.MaxdBSPLCalib-x.Stimuli.atten_dB);
            if iscell(temp)
                temp = temp{1};
            end
            % Demean and resample
            temp = temp-mean(temp,'all');
            temp  = temp'./x.AD_Data.Gain;
            temp = resample(temp, fs, round(fs_orig));
            % Trim template to 8 ms
            template_dur = length(temp)/fs*1000; % duration of template in ms
            duration = 8;   % desired template duration in ms
            duration_samples = duration/1000*fs;
            if template_dur > duration
                noise_floor = mean(max(temp(end-duration_samples:end)/max(temp)));
                [~,template_locs] = findpeaks(temp/max(temp),"MinPeakHeight",noise_floor); % find first peak for reference
                template_locs = template_locs(1)-10;
                if template_locs < 1; template_locs = 1; end
                temp = temp(template_locs:template_locs+duration_samples);
            end
            templates(:,d) = temp;
        end
        avg_template(:,z) = mean(templates,2);
        avg_template_all(z) = {avg_template};
    end
end
%% Load ABR files
abr_waveforms = [];
abr_level = [];
abr_all = cell(1,length(freq));
abr_level_all = cell(1,length(freq));
for z = 1:length(freq)
    if ~isnan(idx_abr(z)) && ~isnan(idx_template(z))
        if freq(z) == 0, freq_str = 'click'; end
        if freq(z) ~= 0, freq_str = num2str(freq(z)); end
        abr_filename = all_datafiles(str2double(all_freqs) == freq(z));
        % Load ABR files
        for d = 1:length(abr_filename)
            cd(datapath);
            load(abr_filename{d})
            fs_orig = x.Stimuli.RPsamprate_Hz;
            temp = x.AD_Data.AD_Avg_V{1};
            abr_level(d) = round(x.Stimuli.MaxdBSPLCalib-x.Stimuli.atten_dB);
            if iscell(temp)
                temp = temp{1};
            end
            % Demean and resample
            temp = temp-mean(temp,'all');
            temp  = temp'./x.AD_Data.Gain;
            temp = resample(temp, fs, round(fs_orig));
            abr_waveforms(:,d) = temp;
        end
        % Sort waveforms by increasing level
        [abr_level,I] = sort(abr_level);
        abr_waveforms = abr_waveforms(:,I);
        abr_all(z) = {abr_waveforms};
        abr_level_all(z) = {abr_level};
    end
end
%% Z-score Calculation
z_score = nan(length(freq),max(idx_abr));
for z = 1:length(freq)
    if ~isnan(idx_abr(z)) && ~isnan(idx_template(z))
        for j = 1:length(abr_level)
            % Template vs ABR
            abr_xcorr = xcorr(avg_template(:,z),abr_waveforms(:,j));
            % Template vs Noise
            abr_noise = mean(abr_waveforms(end-50:end,:),2);  % average last 50 samples across all levels to represent noise floor
            noise_xcorr = xcorr(avg_template(:,z),abr_noise);
            % Calculate z-score
            %z_score(z,j) = abs(max(abr_xcorr))/std(noise_xcorr);
            z_score(z,j) = abs(max(abr_xcorr))/std(noise_xcorr);
        end
    end
end
%% Z-score Weighting
z_max = max(z_score(:),[],'omitnan');
weights = nan(size(z_score));
for z = 1:length(freq)
    if ~isnan(idx_abr(z)) && ~isnan(idx_template(z))
        for j = 1:length(abr_level)
            if z_score(z,j) < 3
                weights(z,j) = 0;
            else
                % Linear scaling: w = m*z + b --> w = 1 at z = 3 and w = 0.1 at z = z_max
                coeff = rref([3 1 1; z_max 1 0.1]);
                m = coeff(1,end);
                b = coeff(2,end);
                weights(z,j) = m*z_score(z,j)+ b;
            end
        end
        z_score_w = z_score.*weights;
    end
end
%% Fitting
nr_flag = false;
thresh = nan(size(freq));
cor_fit = cell(1,length(freq));
x = 0:0.1:15;
maximum = z_max;
mid = median(z_score,2);
steep = 1.3;
start = 0.01;
sigmoid = '(a-d)./(1+exp(b*(x-c)))+d';
for z = 1:length(freq)
    if ~isnan(idx_abr(z)) && ~isnan(idx_template(z))
        if max(z_score_w(z,:)) < 3
            nr_flag = true;
        end
        for j = 1:length(abr_level_all(z))
            startPoints = [maximum, steep, mid(z), start];
            fops = fitoptions('Method','NonLinearLeastSquares','Lower',[0.4, 0, min(cell2mat(abr_level_all(z))), 0],'Upper',[1, inf, 100, inf],'StartPoint',startPoints);
            ft = fittype(sigmoid,'options',fops);
            if length(z_score_w(z,:)) > 4      % at least 4 points needed for sigmoid fit
                cor_fit(z) = {fit(cell2mat(abr_level_all(z))', z_score_w(z,:)',ft)};
                %Find x value on sigmoid that is 20% of the way to transition point
                tol = 0.20;
                y_transit = (cor_fit{z}.a+cor_fit{z}.d)/2;
                y_thresh = cor_fit{z}.d+tol*(y_transit-cor_fit{z}.d);
                % Estimate threshold
                thresh(z) = cor_fit{z}.c-log((cor_fit{z}.a-cor_fit{z}.d)/(y_thresh-cor_fit{z}.d)-1)/cor_fit{z}.b;
            else
                thresh(z) = NaN;
                cor_fit{z} = zeros(1,80);
            end
            % Unrealistic thresholds
            if nr_flag
                thresh(z) = 120;
            end
            if thresh(z) < 0, thresh(z) = 0; end
            if thresh(z) > 80,thresh(z) = 80; end

        end
    end
end
%% Plotting
abr_vis = figure;
set(abr_vis,'Position',[411 105 1387 808])
fit_vis = figure;
set(fit_vis,'Position',[7 485 809 474])
thr_vis = figure;
set(thr_vis,'Position',[7 485 809 474])
clr_no = [0,0,0,.3];
clr_yes = [0,0,0,1];
for z = 1:length(freq)
    if ~isnan(idx_abr(z)) && ~isnan(idx_template(z))
        % ABR Waveforms           *************** CHECK ABR PLOTTING ****************
        figure(abr_vis);
        subplot(ceil(length(freq)/3),3,z);
        wforms = cell2mat(abr_all(z));
        lev = cell2mat(abr_level_all(z));
        buff = 1.25*max(max(wforms))*(1:size(wforms,2));
        wform_plot = wforms+buff;
        t = (1:size(wforms,1))/fs;
        t = t*1e3; %time in ms
        hold on
        if sum(lev>thresh(z))~=0
            plot(t,wform_plot(:,lev>=round(thresh(z),-1)),'color',clr_yes,'linewidth',3);
        end
        if round(thresh(z),-1) ~= 0 && ~isnan(thresh(z)) && sum(lev<round(thresh(z),-1)) ~= 0
            plot(t,wform_plot(:,lev<round(thresh(z),-1)),'color',clr_no,'linewidth',3);
        end
        if sum(lev<round(thresh(z),-1)) == 0
            plot(t,wform_plot,'color',clr_yes,'linewidth',3);
        end
        if isnan(thresh(z))
            plot(t,wform_plot,'color',clr_yes,'linewidth',3);
        end
        xlim([0,30])
        hold off
        set(gca,'FontSize',25);
        yticks(mean(wform_plot));
        yticklabels(round(lev));
        ylim([min(min(wform_plot)),max(max(wform_plot))])
        ylabel('Sound Level (dB SPL)','FontWeight','bold')
        xlabel('Time (ms)','FontWeight','bold');
        if freq(z)==0
            title('Click');
        else
            title([num2str(freq(z)), ' Hz']);
        end
        subtitle(sprintf('Threshold: %.1f dB SPL',thresh(z)));
        
        % Threshold Estimate: Sigmoid Fit
        figure(fit_vis);
        subplot(ceil(length(freq)/3),3,z);
        hold on
        if freq(z)==0
            title('Click');
        else
            title([num2str(freq(z)), ' Hz']);
        end
        level = cell2mat(abr_level_all(z));
        plot(level,z_score_w(z,:),'*','linewidth',1.5,'markersize',10); hold on;
        plot(1:max(level),cor_fit{z}(1:max(level)),'--k','linewidth',2);
        ylim([0,max(z_score_w(z,:))])
        xline(thresh(z),'r','linewidth',2);
        xticks(0:10:max(level));
        xtickangle(90);
        xlim([0,max(level)]);
        ylabel('Weighted Z-score');
        xlabel('Level (dB SPL)');
        hold off
        grid on
        set(gca,'FontSize',15);
        
        % Audiogram
        figure(thr_vis); clf;
        plot(freq,thresh,'*-k','linewidth',2);
        grid on;
        xticks(freq);
        set(gca,'xscale','log');
        set(gca,'FontSize',25);
        yticks(0:10:100);
        ylim([0,100]);
        title(['ABR-Audiogram | ',subject,' | ',condition{2}]);
        xlabel('Frequency (Hz)')
        ylabel('Threshold (dB SPL)');
    end
end
%% Export
cd(outpath);
filename = cell2mat([subject,'_',condition]);
print(abr_vis,[filename,'_ABRwaves.png'],'-dpng','-r300');
print(fit_vis,[filename,'_ABRfit.png'],'-dpng','-r300');
%print(thr_vis,[filename,'_ABRthresholds.png'],'-dpng','-r300');

abr_out.freqs = freq;
abr_out.thresholds = thresh;
abr_out.subj = subject;
abr_out.method = 'Template XCORR';
save([filename,'_ABRthresholds.mat'],'abr_out');
cd(cwd);
end
