clear 
close all

set(0,'DefaultFigureRenderer','painters')

%color 
blck = [0.25, 0.25, 0.25];
c_ca = [0.8500, 0.3250, 0.0980];
c_tts = [0, 0.4470, 0.7410];

new_template = true;

%% Load data
addpath('Aggregate');
load('abr_thresh_out.mat')

%Correct ABR Waveform orientation
ca_pre_click_wform = -ca_pre_click_wform;
tts_pre_click_wform = -tts_pre_click_wform;
ca_pre_4k_wform = -ca_pre_4k_wform;
tts_pre_4k_wform = -tts_pre_4k_wform;

%ca_post chin 3 needs inverted, rest are fine
ca_post_click_wform(:,3) = -ca_post_click_wform(:,3);
ca_post_4k_wform(:,3) = -ca_post_4k_wform(:,3);

%all TTS need inverted:
tts_post_click_wform = -tts_post_click_wform;
tts_post_4k_wform = -tts_post_4k_wform;

%De-Mean
ca_pre_click_wform = ca_pre_click_wform - mean(ca_pre_click_wform);
ca_pre_4k_wform = ca_pre_4k_wform - mean(ca_pre_4k_wform);
tts_pre_click_wform = tts_pre_click_wform - mean(tts_pre_click_wform);
tts_pre_4k_wform = tts_pre_4k_wform - mean(tts_pre_4k_wform);

ca_post_click_wform = ca_post_click_wform - mean(ca_post_click_wform);
ca_post_4k_wform = ca_post_4k_wform - mean(ca_post_4k_wform);
tts_post_click_wform = tts_post_click_wform - mean(tts_post_click_wform);
tts_post_4k_wform = tts_post_4k_wform - mean(tts_post_4k_wform);

%% ABR Waveform plots
fs = 48828*2; %Sample rate was doubled in old ABR_analysis script
len = 3024;
t = 1:len;
t = t/fs; 
t = t*1e3; %convert to ms

fig_click = figure;
alp = 0.15;
%Click TTS
subplot(1,2,1);
title('TTS Exposure')
hold on
plot(t,mean(tts_pre_click_wform(1:len,:),2),'color',blck,'Linewidth',2);
plot(t,mean(tts_post_click_wform(1:len,:),2),'color',c_tts,'Linewidth',2);
% plot(tts_pre_click_latencies([2,9],:),-tts_pre_click_pks([2,9],:),'*','color',blck)
plot(t,tts_pre_click_wform(1:len,:),'color',[blck,alp],'Linewidth',1);
plot(t,tts_post_click_wform(1:len,:),'color',[c_tts,alp],'Linewidth',1);

hold off
grid on 
xlabel('Time (ms)');
ylabel('Amplitude (\muV)');
legend('Pre','Post')
xlim([0,16]);
ylim([-.7,1]);

%Click CA
subplot(1,2,2);
title('CA Exposure')
hold on
plot(t,mean(ca_pre_click_wform(1:len,:),2),'color',blck,'Linewidth',2);
plot(t,mean(ca_post_click_wform(1:len,:),2),'color',c_ca,'Linewidth',2);
plot(t,ca_pre_click_wform(1:len,:),'color',[blck,alp],'Linewidth',1);
plot(t,ca_post_click_wform(1:len,:),'color',[c_ca,alp],'Linewidth',1);

hold off
grid on 
xlabel('Time (ms)');
ylabel('Amplitude (\muV)');
legend('Pre','Post')
xlim([0,16]);
ylim([-.7,1]);
sgtitle('Click ABRs')

set(gcf,'Position',[356 310 1552 618]);
print(fig_click,'click_abr_pre_post','-dpng','-r600')


fig_4k = figure;
alp = 0.15;
%4k TTS
subplot(1,2,1);
title('TTS Exposure')
hold on
plot(t,mean(tts_pre_4k_wform(1:len,:),2),'color',blck,'Linewidth',2);
plot(t,mean(tts_post_4k_wform(1:len,:),2),'color',c_tts,'Linewidth',2);
% plot(tts_pre_click_latencies([2,9],:),-tts_pre_click_pks([2,9],:),'*','color',blck)
plot(t,tts_pre_4k_wform(1:len,:),'color',[blck,alp],'Linewidth',1);
plot(t,tts_post_4k_wform(1:len,:),'color',[c_tts,alp],'Linewidth',1);

hold off
grid on 
xlabel('Time (ms)');
ylabel('Amplitude (\muV)');
legend('Pre','Post')
xlim([0,16]);
ylim([-.7,1]);

%4 CA
subplot(1,2,2);
title('CA Exposure')
hold on
plot(t,mean(ca_pre_4k_wform(1:len,:),2),'color',blck,'Linewidth',2);
plot(t,mean(ca_post_4k_wform(1:len,:),2),'color',c_ca,'Linewidth',2);
plot(t,ca_pre_4k_wform(1:len,:),'color',[blck,alp],'Linewidth',1);
plot(t,ca_post_4k_wform(1:len,:),'color',[c_ca,alp],'Linewidth',1);

hold off
grid on 
xlabel('Time (ms)');
ylabel('Amplitude (\muV)');
legend('Pre','Post')
xlim([0,16]);
ylim([-.7,1]);
sgtitle('4k ABRs')

set(gcf,'Position',[356 310 1552 618]);
print(fig_4k,'4k_abr_pre_post','-dpng','-r600')

%% Peak finding

%Make Templates (Can make this conditional)

inds = [2,10]; %Find best match in this chopped waveform (in ms)
inds = (inds/1e3)*fs;
inds = round(inds(1)):round(inds(2));
t2 = t(inds);

baseline_mean_click = mean(horzcat(tts_pre_click_wform(inds,:),ca_pre_click_wform(inds,:)),2);

tts_mean_pre_click = mean(tts_pre_click_wform(inds,:),2);
tts_mean_post_click = mean(tts_post_click_wform(inds,:),2);
ca_mean_pre_click = mean(ca_pre_click_wform(inds,:),2);
ca_mean_post_click = mean(ca_post_click_wform(inds,:),2);

tts_mean_pre_4k = mean(tts_pre_4k_wform(inds,:),2);
tts_mean_post_4k = mean(tts_post_4k_wform(inds,:),2);
ca_mean_pre_4k = mean(ca_pre_4k_wform(inds,:),2);
ca_mean_post_4k = mean(ca_post_4k_wform(inds,:),2);

if new_template
    %Identify Peaks on template
    baseline_pts_click = make_ABR_Template(t2,baseline_mean_click,'baseline_template.mat');
    tts_pts_pre_click = make_ABR_Template(t2,tts_mean_pre_click,'tts_pre_click_template.mat');
    ca_pts_pre_click = make_ABR_Template(t2,ca_mean_pre_click,'ca_pre_click_template.mat');
    tts_pts_post_click = make_ABR_Template(t2,tts_mean_post_click,'tts_post_click_template.mat');
    ca_pts_post_click = make_ABR_Template(t2,ca_mean_post_click,'ca_post_click_template.mat');

    tts_pts_pre_4k = make_ABR_Template(t2,tts_mean_pre_4k,'tts_pre_4k_template.mat');
    ca_pts_pre_4k = make_ABR_Template(t2,ca_mean_pre_4k,'ca_pre_4k_template.mat');
    tts_pts_post_4k = make_ABR_Template(t2,tts_mean_post_4k,'tts_post_4k_template.mat');
    ca_pts_post_4k = make_ABR_Template(t2,ca_mean_post_4k,'ca_post_4k_template.mat');
else
%     load('baseline_template.mat');
%     baseline_pts_click = points;
    load('tts_pre_click_template.mat')
    tts_pts_pre_click = points;
    load('tts_post_click_template.mat')
    tts_pts_post_click = points;
    load('ca_pre_click_template.mat')
    ca_pts_pre_click = points;
    load('ca_post_click_template.mat')
    ca_pts_post_click = points;

    load('tts_pre_4k_template.mat')
    tts_pts_pre_4k = points;
    load('tts_post_4k_template.mat')
    tts_pts_post_4k = points;
    load('ca_pre_4k_template.mat')
    ca_pts_pre_4k = points;
    load('ca_post_4k_template.mat')
    ca_pts_post_4k = points;
end


%Time Warping to match peaks
for chin = 1:size(tts_post_4k_wform,2) %aka 4
    [tts_pre_click_pks2(:,chin),tts_pre_click_lats2(:,chin)] = findPeaks_dtw(t2,tts_pre_click_wform(inds,chin),tts_mean_pre_click,tts_pts_pre_click);
    [ca_pre_click_pks2(:,chin),ca_pre_click_lats2(:,chin)] = findPeaks_dtw(t2,ca_pre_click_wform(inds,chin),ca_mean_pre_click,ca_pts_pre_click);
    [tts_post_click_pks2(:,chin),tts_post_click_lats2(:,chin)] = findPeaks_dtw(t2,tts_post_click_wform(inds,chin),tts_mean_post_click,tts_pts_post_click);
    [ca_post_click_pks2(:,chin),ca_post_click_lats2(:,chin)] = findPeaks_dtw(t2,ca_post_click_wform(inds,chin),ca_mean_post_click,ca_pts_post_click);


    [tts_pre_4k_pks2(:,chin),tts_pre_4k_lats2(:,chin)] = findPeaks_dtw(t2,tts_pre_4k_wform(inds,chin),tts_mean_pre_4k,tts_pts_pre_4k);
    [ca_pre_4k_pks2(:,chin),ca_pre_4k_lats2(:,chin)] = findPeaks_dtw(t2,ca_pre_4k_wform(inds,chin),ca_mean_pre_4k,ca_pts_pre_4k);
    [tts_post_4k_pks2(:,chin),tts_post_4k_lats2(:,chin)] = findPeaks_dtw(t2,tts_post_4k_wform(inds,chin),tts_mean_post_4k,tts_pts_post_4k);
    [ca_post_4k_pks2(:,chin),ca_post_4k_lats2(:,chin)] = findPeaks_dtw(t2,ca_post_4k_wform(inds,chin),ca_mean_post_4k,ca_pts_post_4k);
end

%% wave I/v ratio

%click
ca_click_pre_i_v_ratio = ca_pre_click_pks2(1,:)./ca_pre_click_pks2(9,:);
ca_click_post_i_v_ratio = ca_post_click_pks2(1,:)./ca_post_click_pks2(9,:);
tts_click_pre_i_v_ratio = tts_pre_click_pks2(1,:)./tts_pre_click_pks2(9,:);
tts_click_post_i_v_ratio = tts_post_click_pks2(1,:)./tts_post_click_pks2(9,:);

%4k
ca_4k_pre_i_v_ratio = ca_pre_4k_pks2(1,:)./ca_pre_4k_pks2(9,:);
ca_4k_post_i_v_ratio = ca_post_4k_pks2(1,:)./ca_post_4k_pks2(9,:);
tts_4k_pre_i_v_ratio = tts_pre_4k_pks2(1,:)./tts_pre_4k_pks2(9,:);
tts_4k_post_i_v_ratio = tts_post_4k_pks2(1,:)./tts_post_4k_pks2(9,:);

%Plotting
figure
sgtitle('Wave I/V Ratio')
subplot(2,2,1);
hold on
scatter(ones(1,length(tts_click_pre_i_v_ratio)),tts_click_pre_i_v_ratio,100,'sq','filled','markerfacecolor',blck)
scatter(2*ones(1,length(tts_click_pre_i_v_ratio)),tts_click_post_i_v_ratio,100,'sq','filled','markerfacecolor',c_tts)
for c = 1:4
    plot([1,2],[tts_click_pre_i_v_ratio(:,c),tts_click_post_i_v_ratio(:,c)],'--','Color',[blck,.6]);
end
hold off
xticks([1,2]);
xticklabels(["Pre","Post"])
grid on
xlim([0.5,2.5])
ylabel('I/V Ratio');
% ylim([-7,5]);
title('TTS Click Wave I/V Ratio');

subplot(2,2,2);
hold on
scatter(ones(1,length(ca_click_pre_i_v_ratio)),ca_click_pre_i_v_ratio,100,'sq','filled','markerfacecolor',blck)
scatter(2*ones(1,length(ca_click_pre_i_v_ratio)),ca_click_post_i_v_ratio,100,'sq','filled','markerfacecolor',c_ca)
for c = 1:4
    plot([1,2],[ca_click_pre_i_v_ratio(:,c),ca_click_post_i_v_ratio(:,c)],'--','Color',[blck,.6]);
end
hold off
xticks([1,2]);
xticklabels(["Pre","Post"])
grid on
xlim([0.5,2.5])
ylabel('I/V Ratio');
% ylim([-7,5]);
title('CA Click Wave I/V Ratio');

subplot(2,2,3);
hold on
scatter(ones(1,length(tts_4k_pre_i_v_ratio)),tts_4k_pre_i_v_ratio,100,'sq','filled','markerfacecolor',blck)
scatter(2*ones(1,length(tts_4k_pre_i_v_ratio)),tts_4k_post_i_v_ratio,100,'sq','filled','markerfacecolor',c_tts)
for c = 1:4
    plot([1,2],[tts_4k_pre_i_v_ratio(:,c),tts_4k_post_i_v_ratio(:,c)],'--','Color',[blck,.6]);
end
hold off
xticks([1,2]);
xticklabels(["Pre","Post"])
grid on
xlim([0.5,2.5])
ylabel('I/V Ratio');
% ylim([-7,5]);
title('TTS 4k Wave I/V Ratio');


subplot(2,2,4);
hold on
scatter(ones(1,length(ca_4k_pre_i_v_ratio)),ca_4k_pre_i_v_ratio,100,'sq','filled','markerfacecolor',blck)
scatter(2*ones(1,length(ca_4k_pre_i_v_ratio)),ca_4k_post_i_v_ratio,100,'sq','filled','markerfacecolor',c_ca)
for c = 1:4
    plot([1,2],[ca_4k_pre_i_v_ratio(:,c),ca_4k_post_i_v_ratio(:,c)],'--','Color',[blck,.6]);
end
hold off
xticks([1,2]);
xticklabels(["Pre","Post"])
grid on
xlim([0.5,2.5])
ylabel('I/V Ratio');
% ylim([-7,5]);
title('CA 4k Wave I/V Ratio');


print(gcf,'wave_i_v_plot','-dpng','-r300');

%% dtw Check fig

point_names = {'P1', 'N1', 'P2', 'N2', 'P3', 'N3', 'P4', 'N4', 'P5', 'N5'};

% point_names = {'P1', 'N1','P5', 'N5'};

figure
hold on

%only show wave 1 and v
% sig = tts_pre_click_wform;
% lats = tts_pre_click_lats2([1,2,9,10],:);
% pks = tts_pre_click_pks2([1,2,9,10],:);

% sig = tts_post_click_wform;
% lats = tts_post_click_lats2([1,2,9,10],:);
% pks = tts_post_click_pks2([1,2,9,10],:);

sig = ca_pre_click_wform(1:len,:);
lats = ca_pre_click_lats2([1,2,9,10],:);
pks = ca_pre_click_pks2([1,2,9,10],:);
lats = ca_pre_click_lats2;
pks = ca_pre_click_pks2;

% sig = ca_post_click_wform(1:len,:);
% lats = ca_post_click_lats2([1,2,9,10],:);
% pks = ca_post_click_pks2([1,2,9,10],:);

% sig = tts_pre_4k_wform;
% lats = tts_pre_4k_lats2([1,2,9,10],:);
% pks = tts_pre_4k_pks2([1,2,9,10],:);


plot(t,sig,'color',[blck,0.3],'linewidth',1);
plot(lats,pks,'.','color',[c_tts,0.001]);

plot(t,mean(sig,2),'color',[blck],'linewidth',2);
plot(mean(lats,2),mean(pks,2),'.','color',[c_tts,0.001],'markersize',20);
text(mean(lats,2),mean(pks,2), point_names, 'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'right'); % Label the point
grid on
xlim([2,10]);

ylabel('Amplitude (\muV)')
xlabel('Time (ms)');
title('Peaks Identified through DTW');

hold off
print(gcf,'dtw_demo_abr','-dpng','-r600');


%% Saving
save('abr_aggregate_2.mat')