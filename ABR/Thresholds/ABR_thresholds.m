function ABR_thresholds(datapath,outpath,subject,all_Conds2Run,CondIND,freq_filter,dup_mode)
%Author (s): Andrew Sivaprakasam
%Last Updated: 25 March 2026 - FA
%Description: Script to estimate and process ABR thresholds based on bootstrapped
%cross-corelation (loosely-based on Luke Shaheen ARO2024 presentation)
%dup_mode (optional): Repeated Levels — 'all' (default: every file is its own
%level entry) or 'average' (files with the same rounded level at a frequency
%are merged by pooling their sweeps before the bootstrap). Default from root
%appdata APAT_abr_dup_levels (set by analysis_run>get_measure_params).
cwd = pwd;
if ~exist('dup_mode','var') || isempty(dup_mode), dup_mode = dup_levels_mode(); end
dup_mode = lower(char(dup_mode));
if ~strcmp(dup_mode,'average'), dup_mode = 'all'; end
pooled   = struct('freq',{},'level',{},'files',{},'n_sweeps',{});   % 'average': merged files
repeated = struct('freq',{},'level',{},'files',{});                 % 'all': repeated levels
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
        % Read every file of this frequency: rounded level + sweeps by polarity
        R = struct('lev',{},'pos',{},'neg',{},'file',{});
        for d = 1:length(freqs_datafiles)
            S_raw = load(freqs_datafiles{d}, 'x');  x = S_raw.x;  clear S_raw
            fs_orig = x.Stimuli.RPsamprate_Hz;
            all_trials  = x.AD_Data.AD_All_V{1};
            % Nominal level, rounded to the nearest dB (calibration max minus
            % attenuation gives e.g. 89.7 for the 90 dB SPL step). Same rule as
            % ABR_dtw and the EFR analyses; the sigmoid fit, threshold, plots and
            % exports all use the rounded level.
            R(d).lev  = round(x.Stimuli.MaxdBSPLCalib-x.Stimuli.atten_dB);
            R(d).file = freqs_datafiles{d};
            
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
            R(d).pos = all_trials(:,1:2:end);
            R(d).neg = all_trials(:,2:2:end);
        end
        clear all_trials
        % Repeated Levels: 'all' = one entry per file (file order, as before);
        % 'average' = files with the same rounded level pooled into one entry
        groups = num2cell(1:numel(R));
        if ~isempty(R)
            [ul, ~, gk] = unique([R.lev]);
            for k = 1:numel(ul)
                gi = find(gk(:)' == k);
                if numel(gi) < 2, continue; end
                if strcmp(dup_mode,'average')
                    pooled(end+1) = struct('freq',freqs(f),'level',ul(k),'files',{{R(gi).file}}, ...
                        'n_sweeps',arrayfun(@(r) size(r.pos,2)+size(r.neg,2), R(gi))); %#ok<AGROW>
                    fprintf('  [ABR_thresholds] %s %g dB SPL: pooled %d files (%s).\n', ...
                        freq_label(freqs(f)), ul(k), numel(gi), strjoin({R(gi).file}, ', '));
                else
                    repeated(end+1) = struct('freq',freqs(f),'level',ul(k),'files',{{R(gi).file}}); %#ok<AGROW>
                end
            end
            if strcmp(dup_mode,'average')
                first = arrayfun(@(k) find(gk == k, 1), 1:numel(ul));
                [~, og] = sort(first);                    % keep file order of first appearance
                groups = arrayfun(@(k) find(gk(:)' == k), og, 'UniformOutput', false);
            end
        end
        for d = 1:numel(groups)
            gi = groups{d};
            lev(d) = R(gi(1)).lev;
            if isscalar(gi)
                all_pos = R(gi).pos;
                all_neg = R(gi).neg;
            else
                % Pool the sweeps of every file at this level (same polarity
                % split as one file); trim to the shortest record if needed
                ns = min(arrayfun(@(r) size(r.pos,1), R(gi)));
                all_pos = cell2mat(arrayfun(@(r) r.pos(1:ns,:), R(gi), 'UniformOutput', false));
                all_neg = cell2mat(arrayfun(@(r) r.neg(1:ns,:), R(gi), 'UniformOutput', false));
            end
            
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
        clear R all_pos all_neg
        
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
        yticklabels(lev_labels(lev));     % repeated levels: '90 (1)', '90 (2)'
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
    % One figure per recording: the waveform stack (threshold in each
    % subtitle). The sigmoid fits are in the .mat / CSV and the Results
    % per-frequency view (no separate _ABRfit.png any more).
    try, apat_save_fig(abr_vis, fullfile(outpath, [filename '_ABRwaves']), 'abr_thr_rec'); catch, end
    % Figures are intentionally left open — analysis_run.m embeds then closes them.
    
    abr_out.freqs      = freqs';
    abr_out.thresholds = thresh;
    abr_out.subj       = subject;
    abr_out.plot_data  = plot_data;
    abr_out.fs         = fs;
    abr_out.dup_levels = dup_mode;   % Repeated Levels setting used: 'all' | 'average'
    abr_out.pooled     = pooled;     % 'average': freq, level, files pooled, sweeps per file
    abr_out.repeated   = repeated;   % 'all': freq, level, files (each kept as its own entry)
    abr_out.sex        = apat_sex('get', subject);   % chinroster Sex column ('' if unknown)
    save([filename,'_ABRthresholds.mat'],'abr_out');
    cd(cwd);
else
    fprintf('No data directory found.\n');
end
end


function L = lev_labels(lev)
%LEV_LABELS  Tick labels of the level stack; a level recorded more than
%   once is numbered in plot order ('90 (1)', '90 (2)').
L = cell(1, numel(lev));
for k = 1:numel(lev)
    n = sum(lev == lev(k));
    if n > 1
        L{k} = sprintf('%g (%d)', round(lev(k)), sum(lev(1:k) == lev(k)));
    else
        L{k} = sprintf('%g', round(lev(k)));
    end
end
end


function s = freq_label(f)
if f == 0, s = 'Click'; else, s = sprintf('%g Hz', f); end
end


function m = dup_levels_mode()
%DUP_LEVELS_MODE  'all' (default) or 'average' from root appdata
%   APAT_abr_dup_levels (Setup "Repeated Levels", via get_measure_params).
m = 'all';
try
    if isappdata(0, 'APAT_abr_dup_levels')
        v = lower(char(getappdata(0, 'APAT_abr_dup_levels')));
        if strcmp(v, 'average'), m = 'average'; end
    end
catch
end
end
