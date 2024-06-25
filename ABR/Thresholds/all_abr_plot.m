clear; 
chins = {'Q412', 'Q424', 'Q426', 'Q430', 'Q431', 'Q427', 'Q428', 'Q421', 'Q425', 'Q443', 'Q422', 'Q440', 'Q441'};
group = {'TTS', 'TTS', 'TTS', 'CA', 'CA', 'PTS', 'PTS', 'CA', 'CA', 'PTS', 'PTS', 'CA', 'CA'};

freq = [.5, 1, 2, 4, 8]; 

TTS_pre = [27, 13.7 18.7 14.6 6.8; 
    23.1, 13.6, 29.4, 11.1, 14.4;
    12.8, 7.5, 11.8, 16, 21.8; 
    ]; 
TTS_post = [22 13.1 22.1 20 21.4; 
    40.8, 31.2, 15.6, 6.3, 7.0; 
    19 11.3 23.5 23.5 22.5; 
    ]; 

PTS_pre = [19.5 18.1 19 18.3 29; 
    9.5 13.6 16.8 16 42.2; 
    24.5 19 15.9 19.9 26.2; 
    30.1 31.6 29.3 25.6 25.9]; 
PTS_post = [21.6, 20.6 18 21.1 24.4; %q422
    35 49.7 64 52.6 52; 
    28.4, 23.9, 25.1, 30.4, 49.7; 
    44.1 31.5 39.7 38.7 39.9]; 

CA_pre = [26.4, 17.1 21.5 21 22.6; 
    21.1 19.3 18.8 20.4 22; 
    30.5, 13 7.3 18.9 14.1; 
    21.6 18 21.7 14.7 35.2; 
    24.3 12.9 20.1 13.9 29.5]; 

CA_post = [27.7 22.8 24.6 32 29.2; 
    23.4, 11.4, 20.6, 20.3, 19.1; 
    31, 19.6, 22.2 15.5 18.2; 
    19.9, 20.8 19.4 29.3 45; 
    21.4 20.2 26.9 12.9 31.8]; 

tts_count = size(TTS_pre, 1); ca_count = size(CA_pre, 1); pts_count = size(PTS_pre, 1); 

%% Plot Data

% blck = [0.25, 0.25, 0.25];
% rd = [216, 27, 96]./255; %TTS
% blu = [30, 136, 229]./255; %CA
% yel = [255, 193, 7]./255; %PTS
% gre = [115, 177, 117]./255; %GE
% 
% i_blck = [0.75, 0.75, 0.75];
% i_rd = [216, 27, 96, 75]./255; %TTS
% i_blu = [30, 136, 229, 75]./255; %CA
% i_yel = [255, 193, 7, 75]./255; %PTS
% i_gre = [115, 177, 117, 57]./255; %GE

blck = [0.25, 0.25, 0.25];
rd = [217, 95, 2]./255; %TTS
blu = [117, 112, 179]./255; %CA
yel = [27, 158, 119]./255; %PTS
gre = [115, 177, 117]./255; %GE

i_blck = [0.75, 0.75, 0.75];
i_rd = [217, 95, 2 75]./255; %TTS
i_blu = [117, 112, 179, 75]./255; %CA
i_yel = [27, 158, 119, 75]./255; %PTS
i_gre = [115, 177, 117, 57]./255; %GE


figure;
set(gcf, 'Units', 'inches', 'Position', [1, 1, 16, 12])
% TTS
subplot(2,2,1)
hold on;
title('Synaptopathy');

% for i = 1:tts_count
%     plot(freq,TTS_pre(i,:),'Color',i_blck,'linewidth',3);
%     plot(freq,TTS_post(i,:),'Color',i_rd,'linewidth',3);
% end
plot(freq,mean(TTS_pre,1, 'omitNaN'),'-o','Color',blck,'linewidth',4, 'MarkerSize', 8);
plot(freq,mean(TTS_post,1, 'omitNaN'),'-o','Color',rd,'linewidth',4, 'MarkerSize', 8);

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
plot(freq,mean(CA_pre,1, 'omitNaN'),'-o','Color',blck,'linewidth',4, 'MarkerSize', 8);
plot(freq,mean(CA_post,1, 'omitNaN'),'-o','Color',blu,'linewidth',4, 'MarkerSize', 8);

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
plot(freq,mean(PTS_pre,1, 'omitNaN'),'-o','Color',blck,'linewidth',4, 'MarkerSize', 8);
plot(freq,mean(PTS_post,1, 'omitNaN'),'-o','Color',yel,'linewidth',4, 'MarkerSize', 8);

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
for i = 1:tts_count
    plot([0,.5], [mean(TTS_pre(i,:)), mean(TTS_post(i,:))], 'o-', 'Color', rd, 'linew',4, 'MarkerSize', 8)
end
for i = 1:ca_count
    plot([1.5,2], [mean(CA_pre(i,:)), mean(CA_post(i,:))], 'o-', 'Color', blu, 'linew',4, 'MarkerSize', 8)
end
for i = 1:pts_count
    plot([3,3.5], [mean(PTS_pre(i,:)), mean(PTS_post(i,:))], 'o-', 'Color', yel, 'linew',4, 'MarkerSize', 8)
end
xlim([-.5,4])
xticks([.25, 1.75, 3.25])
xticklabels({'Syn','IHC','Complex',})
ylabel('Threshold (dB SPL)')
set(gca, 'FontSize', 20)
title('Average Threshold', 'FontSize', 24);
grid on


% title('GE | RAM - 25% Duty Cycle','FontSize',14);
% plot(mean(GE_Pre_elicitors_all,1, 'omitNaN'),mean(GE_Pre_thresh_env_all,1, 'omitNaN'),'Color',blck,'linewidth',1.5);
% 
% hold on;
% plot(mean(GE_Post_elicitors_all,1, 'omitNaN'),mean(GE_Post_thresh_env_all,1, 'omitNaN'),'Color',gre,'linewidth',1.5);
% 
% hold off;
% ylim([0,5])
% ylabel('PLV','FontWeight','bold')
% xlabel('Frequency(Hz)','FontWeight','bold')
% 
% 
% subplot(2,2,4)
% title('Thresholds')
% hold on; 
% for i = 1:tts_count
%     plot([0,1], [TTS_Pre_thresh_all(i), TTS_Post_thresh_all(i)], 'o-', 'Color', rd, 'linew',3)
% end
% for i = 1:ca_count
%     plot([0,1], [CA_Pre_thresh_all(i), CA_Post_thresh_all(i)], 'o-', 'Color', blu, 'linew',3)
% end
% for i = 1:pts_count
%     plot([0,1], [PTS_Pre_thresh_all(i), PTS_Post_thresh_all(i)], 'o-', 'Color', yel, 'linew',3)
% end
% xlim([-.5,1.5])
% xticks([0,1])
% xticklabels({'Pre', 'Post'})
% ylabel('Threshold (dB FPL)')
% set(gca, 'FontSize', 16)
%% 
cd 'Figures'
print -dpng -r600 Pre-Post-ABR
cd .. 