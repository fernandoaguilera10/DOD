function ABR_thresholds(datapath,outpath,subject,all_Conds2Run,CondIND,freq_filter)
%Author (s): Andrew Sivaprakasam
%Last Updated: 25 March 2026 - FA
%Description: Script to estimate and process ABR thresholds based on bootstrapped
%cross-corelation (loosely-based on Luke Shaheen ARO2024 presentation)
cwd = pwd; addpath(cwd);
condition = strsplit(all_Conds2Run{CondIND}, filesep);
fs = 8e3; %resampled to 8e3
samps = 400; % ABR trials per group for bootstraping
iters = 200; % bootstrap iterations 
%% Change into directory
if exist(datapath,"dir")
    cd(datapath);
    %% Check frequencies available
    all_datafiles = {dir(fullfile(cd,'p*ABR*.mat')).name}';
    all_freqs = cellfun(@(x) erase(extractAfter(x,'ABR_'), '.mat'), all_datafiles, 'UniformOutput', false);
    all_freqs(strcmp(all_freqs,'click')) = {'0'};
    freqs = unique(str2double(all_freqs));
    % Apply frequency filter if provided (0 = click, values in Hz)
    if exist('freq_filter','var') && ~isempty(freq_filter)
        freqs = freqs(ismember(freqs, freq_filter));
    end
    %% Fitting Properties
    x = 0:0.1:15;
    maximum = 0.8;
    %mid = 6;
    %steep = 1.3;
    %start = 0.01;
    mid = 15;
    steep = 0.05;
    start = 0;
    sigmoid = '(a-d)./(1+exp(-b*(x-c)))+d';
    startPoints = [maximum, steep, mid, start];
    %% Load the files for a given freq
    
    abr_vis = figure('Visible','off','Name',sprintf('ABR Waveforms | %s | %s', subject, condition{end}));
    set(abr_vis, 'Units', 'Normalized', 'OuterPosition', [0.35, 0.025, 0.65, 0.9]);
    fit_vis = figure('Visible','off','Name',sprintf('Sigmoid Fits | %s | %s', subject, condition{end}));
    set(fit_vis, 'Units', 'Normalized', 'OuterPosition', [0, 0.45, 0.35, 0.4725]);
    
    for f = 1:length(freqs)
        
        lev = [];
        wforms=[];
        cor_temp = [];
        cor_err_temp = [];
        nr_flag = false;
        freqs_datafiles = all_datafiles(str2double(all_freqs) == freqs(f));
        for d = 1:length(freqs_datafiles)
            load(freqs_datafiles{d})
            fs_orig = x.Stimuli.RPsamprate_Hz;
            all_trials  = x.AD_Data.AD_All_V{1};
            lev(d) = x.Stimuli.MaxdBSPLCalib-x.Stimuli.atten_dB;
            
            %2nd dimension in run levels for some reason
            if iscell(all_trials)
                all_trials = all_trials{1};
            end
            
            %Filter [300,3e3] (match SR560 limit)
            
            %TODO Test this
            all_trials = all_trials-mean(all_trials,'all');
            all_trials  = all_trials'./x.AD_Data.Gain;
            all_trials = resample(all_trials, fs, round(fs_orig));
            %         [b,a] = butter(4,[300,3e3]./(fs/2));
            %         all_trials = filtfilt(b,a,all_trials);
            
            %Separate into pos/negs
            all_pos = all_trials(:,1:2:end);
            all_neg = all_trials(:,2:2:end);
            
            %Bootstrap - return the means of iters number of replicates (with samps number of
            %samples)
            pos_boot_1 = helper.boots(all_pos(:,1:2:end), samps, iters);
            neg_boot_1 = helper.boots(all_neg(:,1:2:end), samps, iters);
            combined_1 = (pos_boot_1 + neg_boot_1)/2;
            
            pos_boot_2 = helper.boots(all_pos(:,2:2:end), samps, iters);
            neg_boot_2 = helper.boots(all_neg(:,2:2:end), samps, iters);
            combined_2 = (pos_boot_2 + neg_boot_2)/2;
            
            
            %comb filter
            %         q =90; %sharpness
            %         bw = (freqs(f)/(fs/2))/q;
            %         [b,a] = iircomb(fs/freqs(f),bw,'notch');
            %         [b,a] = iirnotch(freqs(f)/(fs/2),bw);
            %
            %         combined_1 = filtfilt(b,a,combined_1);
            %         combined_2 = filtfilt(b,a,combined_2);
            lev_all = cell(1,length(freqs));
            wforms_all = cell(1,length(freqs));
            cor_all = cell(1,length(freqs));
            cor_err_all = cell(1,length(freqs));
            %Cross-correlate first half w/second half
            xcor_t = helper.xcorr_matrix(combined_1,combined_2);
            
            wforms(:,d) = real(mean(combined_1+combined_2,2));
            %points at zero lag
            midpoint = ceil(size(xcor_t,1)/2);
            cor = mean(xcor_t(midpoint,:)); %maybe can use the variability here too?
            cor_err = std(xcor_t(midpoint,:));
            cor_temp(d) = cor;
            cor_err_temp(d) = cor_err;
            %         cor_temp2(d) = mean(mscohere(combined_1,combined_2),'all');
        end
        
        %sort waveforms by increasing level
        [lev,I] = sort(lev);
        wforms = wforms(:,I);
        cor_temp = cor_temp(I);
        cor_err_temp = cor_err_temp(I);
        % save all
        lev_all(f) = {lev};
        wforms_all(f) = {wforms};
        cor_all(f) = {cor_temp};
        cor_err_all(f) = {cor_err_temp};
        
        %Set minimum of sigmoid to lowest level recorded
        fops = fitoptions('Method','NonLinearLeastSquares','Lower',[0.4, 0, min(lev), 0],'Upper',[1, inf, 100, inf],'StartPoint',startPoints);
        ft = fittype(sigmoid,'options',fops);
        
        if max(cor_temp)<0.3
            nr_flag = true;
        end
        if length(lev) > 4      % at least 4 points needed for sigmoid fit
            cor_temp = cor_temp/max(cor_temp); %normalize
            cor_fit = fit(lev', cor_temp',ft);
            
            %Find x value on sigmoid that is 25% of the way to transition point
            % tol = .20;
            % y_transit = (cor_fit.a+cor_fit.d)/2;
            % y_thresh = cor_fit.d+tol*(y_transit-cor_fit.d);
            
            % Estimate threshold at rising portion of sigmoid (SH)
            ci = confint(cor_fit); % look at a confidence interval around d (baseline of sigmoid)
            max_d = ci(2,4);
            y_thresh= cor_fit.d + 0.1; % go a little above d?

            %invert
            thresh_raw = cor_fit.c-log((cor_fit.a-cor_fit.d)/(y_thresh-cor_fit.d)-1)/cor_fit.b;
            thresh(f) = real(thresh_raw);
        else
            thresh(f) = NaN;
            cor_fit = zeros(1,80);
            cor_temp = zeros(size(lev));
            cor_err_temp = zeros(size(lev));
        end
        %bad
        if nr_flag
            thresh(f) = 120;
        end
        if thresh(f) < 0, thresh(f) = 0; end
        if thresh(f) > 80,thresh(f) = 80; end
        % Save plot data so figures can be reconstructed from the .mat file
        % without re-running the analysis (used by ABRsummary when data exists).
        if length(lev) > 4
            plot_data(f).cor_fit_vals = double(cor_fit(1:80));
        else
            plot_data(f).cor_fit_vals = zeros(1,80);
        end
        plot_data(f).lev     = lev;
        plot_data(f).wforms  = wforms;
        plot_data(f).cor     = cor_temp;
        plot_data(f).cor_err = cor_err_temp;
        plot_data(f).thresh  = thresh(f);
        plot_data(f).freq    = freqs(f);

        clr_no = [0,0,0,.3];
        clr_yes = [0,0,0,1];
        
        set(0,'CurrentFigure', abr_vis);
        subplot(ceil(length(freqs)/3),3,f);
        buff = 1.25*max(max(wforms))*(1:size(wforms,2));
        wform_plot = wforms+buff;
        
        t = (1:size(wforms,1))/fs;
        t = t*1e3; %time in ms
        
        hold on
        
        if sum(lev>thresh(f))~=0
            plot(t,wform_plot(:,lev>=round(thresh(f),-1)),'color',clr_yes,'linewidth',2);
        end
        if round(thresh(f),-1) ~= 0 && ~isnan(thresh(f)) && sum(lev<round(thresh(f),-1)) ~= 0
            plot(t,wform_plot(:,lev<round(thresh(f),-1)),'color',clr_no,'linewidth',2);
        end
        if sum(lev<round(thresh(f),-1)) == 0
            plot(t,wform_plot,'color',clr_yes,'linewidth',2);
        end
        if isnan(thresh(f))
            plot(t,wform_plot,'color',clr_yes,'linewidth',2);
        end
        xlim([0,30])
        hold off
        set(gca,'FontSize',15);
        yticks(mean(wform_plot));
        yticklabels(round(lev));
        ylim([0.9*min(min(wform_plot)),1.03*max(max(wform_plot))])
        ylabel('Sound Level (dB SPL)','FontWeight','bold')
        xlabel('Time (ms)','FontWeight','bold');
        if freqs(f)==0
            title('Click');
        else
            title([num2str(freqs(f)), ' Hz']);
        end
        subtitle(sprintf('Threshold: %.1f dB SPL',thresh(f)));
        
        set(0,'CurrentFigure', fit_vis);
        subplot(ceil(length(freqs)/3),3,f);
        hold on
        if freqs(f)==0
            title('Click');
        else
            title([num2str(freqs(f)), ' Hz']);
        end
        plot(1:80,cor_fit(1:80),'--k','linewidth',2);
        errorbar(lev,cor_temp,cor_err_temp,'.b','linewidth',1.5,'markersize',10);
        ylim([0,1])
        xline(thresh(f),'r','linewidth',2);
        xticks(0:10:100);
        xtickangle(90);
        xlim([0,100]);
        xlabel('Level (dB SPL)');
        hold off
        grid on
    end
    
    %% Export
    cd(outpath);
    filename = cell2mat([subject,'_',condition]);
    drawnow;
    exportgraphics(abr_vis,[filename,'_ABRwaves.png'],'Resolution',300);
    exportgraphics(fit_vis,[filename,'_ABRfit.png'],'Resolution',300);
    % Figures are intentionally left open — analysis_run.m embeds then closes them.
    
    abr_out.freqs      = freqs';
    abr_out.thresholds = thresh;
    abr_out.subj       = subject;
    abr_out.plot_data  = plot_data;
    abr_out.fs         = fs;
    save([filename,'_ABRthresholds.mat'],'abr_out');
    cd(cwd);
else
    fprintf('No data directory found.\n');
end
end