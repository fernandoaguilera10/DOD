%% Plot ABR thresholds from new analysis
clear;
% chins = {'Q412', 'Q424', 'Q426', 'Q430', 'Q431', 'Q427', 'Q428', 'Q421', 'Q425', 'Q443', 'Q422', 'Q440', 'Q441'};
% group = {'TTS', 'TTS', 'TTS', 'CA', 'CA', 'PTS', 'PTS', 'CA', 'CA', 'PTS', 'PTS', 'CA', 'CA'};

chin = []; % placeholder in case we want to only plot one chins data
thresholds = [1 2 3 4 5]; % placeholder while not loading real data

% Directories for individual user
uname = 'sivaprakasaman';
datadir = ['/media/',uname,'/AndrewNVME/Pitch_Study/Pitch_Diagnostics_SH_AS/ABR/Chin/'];
cd([datadir, filesep, 'Baseline'])


set(0,'DefaultFigureRenderer','painters')


if isempty(chin)
    all_chins = dir('Q*');
else
    all_chins = dir(chin);
end

% Get list of chins for each exposure
cd(datadir);
cd('CA_2wksPost')
ca_chins = dir('Q*');
ca_chins = {ca_chins.name};
cd(datadir);
cd('PTS_2wksPost')
pts_chins = dir('Q*');
pts_chins = {pts_chins.name};
cd(datadir);
cd('TTS_2wksPost')
tts_chins = dir('Q*');
tts_chins = {tts_chins.name};
cd(datadir);
cd('GE_2wksPost')
ge_chins = dir('Q*');
ge_chins = {ge_chins.name};

cd(datadir)

% Initialize results/data matrices
freq = [.5, 1, 2, 4, 8]; % kHz
baseline = zeros(numel(all_chins),numel(freq));
post = zeros(numel(all_chins),numel(freq));
exp = [];

for k = 1:numel(all_chins)
    chin = all_chins(k).name;
    
    % Get Baseline data
    cd([all_chins(k).folder,filesep, chin, filesep, 'Processed'])
    cond = 'Baseline';
    load([all_chins(k).name,'_',cond,'_ABR_Data.mat']);
    freq = abr_out.freqs/1e3; %converted to kHz
    baseline(k,:) = abr_out.thresholds;
    
    cd(datadir);
    emptyFlag = 0;
    if sum(strcmp(chin, tts_chins)>0)
        cd(fullfile('TTS_2wksPost', chin, 'Processed'))
        cond = 'TTS_2wksPost';
        exp{k,1} = 'TTS';
    elseif sum(strcmp(chin, pts_chins)>0)
        cd(fullfile('PTS_2wksPost', chin, 'Processed'))
        cond = 'PTS_2wksPost';
        exp{k,1} = 'PTS';
    elseif sum(strcmp(chin, ca_chins)>0)
        cd(fullfile('CA_2wksPost', chin, 'Processed'))
        cond = 'CA_2wksPost';
        exp{k,1} = 'CA';
    elseif sum(strcmp(chin, ge_chins)>0)
        cd(fullfile('GE_2wksPost', chin, 'Processed'))
        cond = 'GE_2wksPost';
        exp{k,1} = 'GE';
    else
        exp{k,1} = 'NA';
        cond = 'Baseline';
        emptyFlag = 1;
    end
    
    %TODO handle missing pre/post data.
    if ~emptyFlag
        load([all_chins(k).name,'_',cond,'_ABR_Data.mat'])
        post(k,:) = abr_out.thresholds;
    end
    
end

%% Plot Data

blck = [0.25, 0.25, 0.25];
rd = [194 106 119]./255; %TTS
blu = [148 203 236]./255; %CA
yel = [220 205 125]./255; %PTS
gre = [93 168 153]./255; %GE

i_blck = [0.25, 0.25, .25, 75];
i_rd = [194 106 119 75]./255; %TTS
i_blu = [148 203 236 75]./255; %CA
i_yel = [220 205 125 75]./255; %PTS
i_gre = [93 168 153 57]./255; %GE

i_cols = [i_blck; i_rd; i_blu; i_yel; i_gre]; 
cols = [blck; rd; blu; yel; gre]; 
groups = {'NH', 'TTS', 'CA', 'PTS', 'GE'}; 
subp = [0 1 3 2 4]'; 

figure;
hold on; 
set(gcf, 'Units', 'inches', 'Position', [1, 1, 16, 12])

if size(all_chins,1) == 1
    plot(freq,baseline, '-o','Color',blck,'linewidth',4, 'MarkerSize', 8)
    plot(freq,baseline, '-o','Color',rd,'linewidth',4, 'MarkerSize', 8)
else
    for j = 1:numel(all_chins)
        grp = strcmp(exp{j}, groups);
        if sum(grp) > 0
            subplot(2,2,grp * subp)
            hold on;
            plot(freq,baseline(j,:), '-o','Color',i_blck(1,1:3),'linewidth',4, 'MarkerSize', 8)
            plot(freq,post(j,:), '-o','Color',grp * i_cols,'linewidth',4, 'MarkerSize', 8)
           text(9,baseline(j,5), all_chins(j).name, 'Units', 'Data', 'Color', i_blck(1,1:3))
           text(9,post(j,5), all_chins(j).name, 'Units', 'Data', 'Color',grp * i_cols)
        end
    end
end
    % TTS
    subplot(2,2,1)
    hold on;
    title('Synaptopathy');
    
    % for i = 1:tts_count
    %     plot(freq,TTS_pre(i,:),'Color',i_blck,'linewidth',3);
    %     plot(freq,TTS_post(i,:),'Color',i_rd,'linewidth',3);
    % end
%     plot(freq,mean(TTS_pre,1, 'omitNaN'),'-o','Color',blck,'linewidth',4, 'MarkerSize', 8);
%     plot(freq,mean(TTS_post,1, 'omitNaN'),'-o','Color',rd,'linewidth',4, 'MarkerSize', 8);
%     
    hold off;
    ylim([0,60])
    ylabel('Threshold (dB SPL)')
    xlabel('Frequency (kHz)')
    xlim([0.5, 8])
    xticks(freq)
    set(gca, 'FontSize', 20, 'XScale', 'log')
    title('Synaptopathy', 'FontSize', 24, 'Color', rd);
    grid on
    
    % Carbo
    subplot(2,2,3)
    hold on;
    title('IHC Dysfunction');
    % for i = 1:ca_count
    %     plot(freq,CA_pre(i,:),'Color',i_blck,'linewidth',3);
    %     plot(freq,CA_post(i,:),'Color',i_blu,'linewidth',3);
    % end
%     plot(freq,mean(CA_pre,1, 'omitNaN'),'-o','Color',blck,'linewidth',4, 'MarkerSize', 8);
%     plot(freq,mean(CA_post,1, 'omitNaN'),'-o','Color',blu,'linewidth',4, 'MarkerSize', 8);
%     
    hold off;
    ylim([0,60])
    ylabel('Threshold (dB SPL)')
    xlabel('Frequency (kHz)')
    xlim([0.5, 8])
    xticks(freq)
    set(gca, 'FontSize', 20, 'XScale', 'log')
    title('IHC Dysfunction', 'FontSize', 24, 'Color', blu);
    grid on
    
    % PTS
    subplot(2,2,2)
    hold on;
    % for i = 1:pts_count
    %     plot(freq,PTS_pre(i,:),'Color',i_blck,'linewidth',3);
    %     plot(freq,PTS_post(i,:),'Color',i_yel,'linewidth',3);
    % end
%     plot(freq,mean(PTS_pre,1, 'omitNaN'),'-o','Color',blck,'linewidth',4, 'MarkerSize', 8);
%     plot(freq,mean(PTS_post,1, 'omitNaN'),'-o','Color',yel,'linewidth',4, 'MarkerSize', 8);
%     
    hold off;
    ylim([0,60])
    ylabel('Threshold (dB SPL)')
    xlabel('Frequency (kHz)')
    xlim([0.5, 8])
    xticks(freq)
    set(gca, 'FontSize', 20, 'XScale', 'log')
    title('Complex SNHL', 'FontSize', 24, 'Color', yel);
    grid on;
    
    subplot(2,2,4)
    hold on;
%     for i = 1:tts_count
%         plot([0,.5], [mean(TTS_pre(i,:)), mean(TTS_post(i,:))], 'o-', 'Color', rd, 'linew',4, 'MarkerSize', 8)
%     end
%     for i = 1:ca_count
%         plot([1.5,2], [mean(CA_pre(i,:)), mean(CA_post(i,:))], 'o-', 'Color', blu, 'linew',4, 'MarkerSize', 8)
%     end
%     for i = 1:pts_count
%         plot([3,3.5], [mean(PTS_pre(i,:)), mean(PTS_post(i,:))], 'o-', 'Color', yel, 'linew',4, 'MarkerSize', 8)
%     end
    ylim([0,60])
    ylabel('Threshold (dB SPL)')
    xlabel('Frequency (kHz)')
    xlim([0.5, 8])
    xticks(freq)
    set(gca, 'FontSize', 20, 'XScale', 'log')
    title('Gentamicin', 'FontSize', 24, 'Color', gre);
    grid on;
    
%% Mean Plots

CA_inds = find(strcmp(exp,'CA'));
ca_mean = [mean(baseline(CA_inds,:))',mean(post(CA_inds,:))']; %col1 pre col2 post
ca_std= [std(baseline(CA_inds,:))',std(post(CA_inds,:))'];

TTS_inds = find(strcmp(exp,'TTS'));
tts_mean = [mean(baseline(TTS_inds,:))',mean(post(TTS_inds,:))']; 
tts_std= [std(baseline(TTS_inds,:))',std(post(TTS_inds,:))'];

PTS_inds = find(strcmp(exp,'PTS'));
pts_mean = [mean(baseline(PTS_inds,:))',mean(post(PTS_inds,:))']; 
pts_std= [std(baseline(PTS_inds,:))',std(post(PTS_inds,:))'];

%Plot
figure;
subplot(2,2,1);
hold on
errorbar(freq,tts_mean(:,1),tts_std(:,1),'o-','color',blck,'LineWidth',2.5)
errorbar(freq,tts_mean(:,2),tts_std(:,2),'o-','color',rd,'LineWidth',2.5)
hold off
xticks(freq);
yticks(0:10:100);
xlabel('Frequency (kHz)');
ylabel('Threshold (dB SPL)');
xlim([.4,10]);
set(gca,'XScale','log');
title('Synaptopathy','color',rd)
grid on


subplot(2,2,3);
hold on
errorbar(freq,ca_mean(:,1),ca_std(:,1),'o-','color',blck,'LineWidth',2.5)
errorbar(freq,ca_mean(:,2),ca_std(:,2),'o-','color',blu,'LineWidth',2.5)
hold off
xticks(freq);
yticks(0:10:100);
xlabel('Frequency (kHz)');
ylabel('Threshold (dB SPL)');
xlim([.4,10]);
set(gca,'XScale','log');
title('IHC Damage','color',blu)
grid on

subplot(2,2,2);
hold on
errorbar(freq,pts_mean(:,1),pts_std(:,1),'o-','color',blck,'LineWidth',2.5)
errorbar(freq,pts_mean(:,2),pts_std(:,2),'o-','color',yel,'LineWidth',2.5)
hold off
xticks(freq);
yticks(0:10:100);
xlabel('Frequency (kHz)');
ylabel('Threshold (dB SPL)');
xlim([.4,10]);
set(gca,'XScale','log');
title('Complex SNHL','color',yel)
grid on

set(gcf,'Position',[675 240 1012 725])

%%

% %%
% cd 'Figures'
% print -dpng -r600 Pre-Post-ABR
% cd ..