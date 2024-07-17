%% U.S. Navy Aircraft Carrier Noise Spectra (Komrower et al. 2019)
clear all; clc; close all;
% Figure 5: Noise radiated by compartment surfaces in Node Room
% dB re. 1 microPa
freq = [31.5; 63; 125; 250; 500; 1000; 2000; 4000; 8000];
fig5_PortBulkhead = [83.6234; 84.2219; 84.2111; 88.988; 85.495; 86.0935; 78.7704; 66.5723; 56.2894];  % dB(A) = 89
fig5_ForwardBulkhead = [63.4275; 84.5701; 84.9075; 85.3319; 90.8923; 88.531; 79.9891; 67.7911; 56.9857];  % dB(A) = 92
fig5_Overhead = [77.5299; 77.6061; 78.2916; 93.8629; 84.6245; 66.0718; 51.4363; 40.8052; 31.741]; % dB(A) = 87
yellow = [0.9290 0.6940 0.1250]; orange = [0.8500 0.3250 0.0980]; blue = [0 0.4470 0.7410]; green = [0.4660 0.6740 0.1880];
figure(1); hold on;
plot(freq,fig5_PortBulkhead,'^-','Color',yellow,'LineWidth',2, 'MarkerFaceColor',yellow);
plot(freq,fig5_ForwardBulkhead,'s-','Color',orange,'LineWidth',2, 'MarkerFaceColor', orange);
plot(freq,fig5_Overhead,'d-','Color',blue,'LineWidth',2, 'MarkerFaceColor', blue);
set (gca, 'xscale', 'log'); xlabel('Frequency [Hz]'); ylabel('Level [dB re. 1\muPa]'); hold off;
title('Figure 5: Noise Radiated by Compartment Surfaces in Node Room');
legend('Port Bulkhead','Forward Bulkhead','Overhead');
figure(2); hold on;
shift = 26; % conversion 1 microPa to 20 microPa (dB SPL)
fig5_PortBulkheadS = fig5_PortBulkhead - shift;
fig5_ForwardBulkheadS = fig5_ForwardBulkhead - shift;
fig5_OverheadS = fig5_Overhead - shift;
plot(freq,fig5_PortBulkheadS,'^-','Color',yellow,'LineWidth',2, 'MarkerFaceColor',yellow);
plot(freq,fig5_ForwardBulkheadS,'s-','Color',orange,'LineWidth',2, 'MarkerFaceColor', orange);
plot(freq,fig5_OverheadS,'d-','Color',blue,'LineWidth',2, 'MarkerFaceColor', blue);
set (gca, 'xscale', 'log'); xlabel('Frequency [Hz]'); ylabel('Level [dB re. 20\muPa]'); hold off;
title('Figure 5: Shifted Noise Radiated by Compartment Surfaces in Node Room');
legend('Port Bulkhead','Forward Bulkhead','Overhead');
% Figure 6: Noise level in Node Room
% dB re. 20 microPa --> dB SPL
fig6_measured = [96.1743; 97.6313; 96.1075; 97.5644; 97.7097; 88.7911; 81.304; 75.1286; 67.1642]; % dB(A) = 97
fig6_calc = [85.2024; 88.3292; 88.3558; 96.1335; 92.9393; 91.4153; 82.9737; 70.7165; 60.1282]; % dB(A) = 95
figure(3); hold on;
plot(freq,fig6_measured,'d-','Color',blue,'LineWidth',2, 'MarkerFaceColor',blue);
plot(freq,fig6_calc,'s-','Color',orange,'LineWidth',2, 'MarkerFaceColor',orange);
set (gca, 'xscale', 'log'); xlabel('Frequency [Hz]'); ylabel('Level [dB re. 20\muPa]'); hold off;
title('Figure 6: Noise Levels in Node Room');
legend('Measured','Calculated');
% Figure 7: Noise radiated by compartment surfaces in Sponson Area
% dB re. 20 microPa --> dB SPL
fig7_Overhead = [64.7782; 67.9649; 71.152; 80.9628; 82.9077; 72.433; 50.6421; 37.6829; 28.174]; % dB(A) = 81
fig7_AftBulkhead = [62.2941; 68.517; 62.3197; 68.5428; 64.8298; 72.2949; 67.8916; 59.6246; 48.046]; % dB(A) = 75
fig7_StdbBulkhead = [59.9481; 57.6148; 57.4898; 67.5768; 61.2418; 59.3229; 54.7819; 57.2787; 52.7378]; % dB(A) = 66
fig7_Deck = [61.7421; 63.963; 63.0099; 59.8489; 67.0378; 68.8451; 59.198; 50.931; 41.5602]; % dB(A) = 71
figure(4); hold on;
plot(freq,fig7_Overhead,'d-','Color',blue,'LineWidth',2, 'MarkerFaceColor',blue);
plot(freq,fig7_AftBulkhead,'s-','Color',orange,'LineWidth',2, 'MarkerFaceColor',orange);
plot(freq,fig7_StdbBulkhead,'o-','Color',green,'LineWidth',2, 'MarkerFaceColor',green);
plot(freq,fig7_Deck,'^-','Color',yellow,'LineWidth',2, 'MarkerFaceColor',yellow);
set (gca, 'xscale', 'log'); xlabel('Frequency [Hz]'); ylabel('Level [dB re. 20\muPa]'); hold off;
title('Figure 7: Noise Radiated by Compartment Surfaces in Sponson Area');
legend('Overhead','Aft Bulkhead','Stdb Bulkhead','Deck');
% Figure 8: Noise level in Sponson Area
% dB re. 20 microG
fig8_measured = [83.0586; 81.3974; 81.8451; 79.3052; 81.5101; 80.3761; 74.0581; 68.7067; 58.6984]; % dB(A) = 84
fig8_calc = [68.561; 72.2596; 72.5314; 81.5897; 83.0917; 76.4222; 68.7863; 61.8533; 54.0417]; % dB(A) = 83
figure(5); hold on;
plot(freq,fig8_measured,'d-','Color',blue,'LineWidth',2, 'MarkerFaceColor',blue);
plot(freq,fig8_calc,'s-','Color',orange,'LineWidth',2, 'MarkerFaceColor',orange);
set (gca, 'xscale', 'log'); xlabel('Frequency [Hz]'); ylabel('Level [dB re. 20\muG]'); hold off;
title('Figure 8: Noise Levels in Sponson Area');
legend('Measured','Calculated');
figure(6); hold on;
shift2 = 40; % conversion 20microG to 20microPa (dB SPL)
fig8_measuredS = fig8_measured + shift2;
fig8_calcS = fig8_calc + shift2;
plot(freq,fig8_measuredS,'d-','Color',blue,'LineWidth',2, 'MarkerFaceColor',blue);
plot(freq,fig8_calcS,'s-','Color',orange,'LineWidth',2, 'MarkerFaceColor',orange);
set (gca, 'xscale', 'log'); xlabel('Frequency [Hz]'); ylabel('Level [dB re. 20\muPa]'); hold off;
title('Figure 8: Shifted Noise Levels in Sponson Area');
legend('Measured','Calculated');
%% Spectral Averaging 
%(Node Room and Sponson Area)
spectra_fig5 = [ fig5_PortBulkheadS fig5_ForwardBulkheadS fig5_OverheadS ]';
spectra_fig6 = [ fig6_measured fig6_calc ]';
spectra_fig7 = [ fig7_Overhead fig7_AftBulkhead fig7_StdbBulkhead fig7_Deck ]';
spectra_fig8 = [ fig8_measuredS fig8_calcS ]';
fullSpectra = [spectra_fig5; spectra_fig6; spectra_fig7; spectra_fig8]; % dB SPL
fullSpectraLegend = [ "fig5: PortBulkhead" "fig5: ForwardBulkhead" "fig5: Overhead" "fig6: Node Room (Measured)" "fig6: Node Room (Calculated)"...
                                    "fig7: Overhead" "fig7: AftBulkhead" "fig7: StdbBulkhead" "fig7: Deck" "fig8: Sponson Area (Measured)" "fig8: Sponson Area (Calculated)" ];
selection = [0 0 0 1 0 0 0 0 0 1 0]; % choose spectra for averaging based on fullSpectra array order
index = find(selection==1);
selectedSpectra = fullSpectra(index,:);
selectedSpectraLegend = [fullSpectraLegend(index) "Average"];
avgSpectra = mean(selectedSpectra);
figure(7); hold on;
h_selected = plot(freq,selectedSpectra,'d-','LineWidth',2,'MarkerSize',6);
set(h_selected, {'MarkerFaceColor'}, get(h_selected,'Color'));
plot(freq,avgSpectra, '--', 'LineWidth',2); 
set (gca, 'xscale', 'log'); xlabel('Frequency [Hz]'); ylabel('Level [dB re. 20\muPa]'); hold off;
title('Average Noise Levels');
legend(selectedSpectraLegend,'Location','southwest');
save('noise_spectra','freq','avgSpectra')