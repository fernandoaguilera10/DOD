function abr_out = ABR_audiogram_chin(datapath,outpath,subject,Conds2Run,CondIND)
%Author (s): Andrew Sivaprakasam
%Last Updated: Februrary, 2024
%Description: Script to estimate and process ABR thresholds based on bootstrapped
%cross-corelation (loosely-based on Luke Shaheen ARO2024 presentation)
close all; cwd = pwd; addpath(cwd);
freqs = [0,0.5,1,2,4,8]*1000;
condition = strsplit(Conds2Run{CondIND}, filesep);
fs = 8e3; %resampled to 8e3
samps = 400;
iters = 200;
%% Change into directory
if exist(datapath,"dir")
    cd(datapath);
    %% Fitting Properties
    x = 0:0.1:15;
    maximum = .8;
    mid =6;
    steep = 1.3;
    start = 0.01;
    sigmoid = '(a-d)./(1+exp(-b*(x-c)))+d';
    startPoints = [maximum, steep, mid, start];
    fops = fitoptions('Method','NonLinearLeastSquares','Lower',[0.8, 0, 1, 0],'Upper',[1, inf, 100, inf],'StartPoint',startPoints);
    ft = fittype(sigmoid,'options',fops);

    % sigmoid = 'a./(1+exp(-b*(x-c)))+d';
    % startPoints = [maximum, steep, mid, start];
    % fops = fitoptions('Method','NonLinearLeastSquares','Lower',[-inf, 0, 1],'Upper',[1, inf, 80],'StartPoint',startPoints);
    % ft = fittype(sigmoid,'options',fops);

    % sig_fit = fit(ranks_ord, sig_data,ft);
    % sig_model = sig_fit(x);


    %% Load the files for a given freq
    % abr_vis = tiledlayout(ceil(length(freqs)/3),3)
    % fit_vis = tiledlayout(ceil(length(freqs)/3),3)

    abr_vis = figure;
    set(abr_vis,'Position',[411 105 1387 808])

    fit_vis = figure;
    set(fit_vis,'Position',[7 485 809 474])

    for f = 1:length(freqs)

        %find files
        if freqs(f) == 0
            datafiles = {dir(fullfile(cd,'p*click*.mat')).name};
        else
            datafiles = {dir(fullfile(cd,['p*',num2str(freqs(f)),'*.mat'])).name};
        end

        lev = [];
        wforms=[];
        cor_temp = [];
        cor_err_temp = [];
        nr_flag = false;

        for d = 1:length(datafiles)
            load(datafiles{d})
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

            %Cross-correlate first half w/second half
            xcor_t = helper.xcorr_matrix(combined_1,combined_2);

            wforms(:,d) = mean(combined_1+combined_2,2);

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


        %Set minimum of sigmoid to lowest level recorded
        fops = fitoptions('Method','NonLinearLeastSquares','Lower',[0.4, 0, min(lev), 0],'Upper',[1, inf, 100, inf],'StartPoint',startPoints);
        ft = fittype(sigmoid,'options',fops);

        %if correlation is very low across the board, no response.
        %TODO think about how to save an NR

        if max(cor_temp)<0.3
            nr_flag = true;
        end

        cor_temp = cor_temp/max(cor_temp); %normalize
        cor_fit = fit(lev', cor_temp',ft);

        %Threshold estimate is the transition point of the sigmoid:
        %     thresh(f) = cor_fit.c;
        %
        %     tol = 4;
        %     c_y = (cor_fit.a+cor_fit.d)/2;
        %     y = (c_y-cor_fit.d)*tol;
        %     thresh(f) = cor_fit.c-y/cor_fit.b;

        %Find x value on sigmoid that is 25% of the way to transition point

        tol = .20;
        y_transit = (cor_fit.a+cor_fit.d)/2;
        y_thresh = cor_fit.d+tol*(y_transit-cor_fit.d);

        %invert
        thresh(f) = cor_fit.c-log((cor_fit.a-cor_fit.d)/(y_thresh-cor_fit.d)-1)/cor_fit.b;

        %bad
        if nr_flag
            thresh(f) = 120;
        end

        clr_no = [0,0,0,.3];
        clr_yes = [0,0,0,1];

        figure(abr_vis);
        subplot(ceil(length(freqs)/3),3,f);
        buff = 1.25*max(max(wforms))*(1:size(wforms,2));
        wform_plot = wforms+buff;

        t = (1:size(wforms,1))/fs;
        t = t*1e3; %time in ms

        hold on
        if sum(lev>thresh(f))~=0
            plot(t,wform_plot(:,lev>thresh(f)),'color',clr_yes,'linewidth',2);
        end
        plot(t,wform_plot(:,lev<=thresh(f)),'color',clr_no,'linewidth',2);
        xlim([0,30])
        hold off
        yticks(mean(wform_plot));
        yticklabels(round(lev));
        ylim([min(min(wform_plot)),max(max(wform_plot))])
        ylabel('Sound Level (dB SPL)');
        if freqs(f)==0
            title('Frequency = Click');
        else
            title(['Frequency = ', num2str(freqs(f)), ' Hz']);
        end

        figure(fit_vis);
        subplot(ceil(length(freqs)/3),3,f);
        hold on
        if freqs(f)==0
            title('Frequency = Click');
        else
            title(['Frequency = ', num2str(freqs(f)), ' Hz']);
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
        %     yline(thresh,'r--','linewidth',2);
    end
    thr_vis = figure;
    set(thr_vis,'Position',[7 485 809 474])
    figure(thr_vis)
    %subplot(ceil(length(freqs)/3),3,f+1);
    plot(freqs,thresh,'*-k','linewidth',2);
    grid on;
    xticks(freqs);
    set(gca,'xscale','log');
    yticks(0:10:100);
    ylim([0,100]);
    title(['ABR-Audiogram | ',subject,' | ',condition{2}]);
    xlabel('Frequency (Hz)')
    ylabel('Threshold (dB SPL)');
    %% Export
    cd(outpath);
    filename = cell2mat([subject,'_',condition]);
    print(abr_vis,[filename,'_ABRwaves.png'],'-dpng','-r300');
    print(fit_vis,[filename,'_ABRfit.png'],'-dpng','-r300');
    print(thr_vis,[filename,'_ABRthresholds.png'],'-dpng','-r300');
    
    abr_out.freqs = freqs;
    abr_out.thresholds = thresh;
    abr_out.subj = subject;
    save([filename,'_ABRdata.mat'],'abr_out');
    cd(cwd);
else
    fprintf('No data directory found.\n');
end
end