function [abrDATA1] = preprocess1_ABR(DATAdir1,ANALYSISdir,Chin,Cond,Freqs2Run,Freqs2Run_vector);

% File:  preprocess1_ABR.m
%% Save basic processed ABR data from NEL for one chin/condition
% runs through ALL ABR for a single chin/condition (i.e, all freqs and
% levels - saves P1,N1, P5, N1 amps and Latencies for top 3 levels.  
% Saves ABRDATA1 for each chin/condition, and TIF file.
% Passed DATAdir1 and ANALYSISdir1 to get/save data 
%
%% M. Heinz
% Jan 21 2019
% updated: Apr 23 2020 for finalizing paper (M. Heinz)
% * modifying some figs to be consistent from individ conds to chin to AVG 
% * adding in W1/5 ratio


%% LATER ???  CLEAN UP FROM HERE
% - call abranalysis (compute by hand?)
% - build freq list, piclist?
% - load in all data for one condition 
% - save to structure ABR{freq}(SPL,time)
% - COMPUTE:
% - freq
% - THR_dBSPL(freq)
% - wave 1 vs SPL{freq}
% - wave 5 vs SPL{freq}

% LATER: Setup error check (to confirm all key conditions are same
% across conditions)

beep
disp(sprintf('***LATER***\n   add ABR level functions to pre-process1 (follow MEMRlevel functions CODE)\n'))

ANALYSISdir1=strcat(ANALYSISdir,filesep,'ABR',filesep,Chin,filesep,Cond,filesep); %save for later
cd(DATAdir1)
filename=sprintf('ABRs_%s_%s',Chin,Cond(findstr(Cond,'\')+1:end));  % filename to save this data and TIF file 

% Find all abr_analysis mat files in this directory 
Dlist=dir('*mat');
 
%% setup data structure to save for this chin/condition
abrDATA1.Freqs_str=Freqs2Run;
abrDATA1.Freqs_Hz=Freqs2Run_vector;
abrDATA1.Thresholds_dBSPL=NaN+zeros(size(Freqs2Run));
abrDATA1.AmplitudesALL_uV=cell(size(Freqs2Run));
abrDATA1.LatenciesALL_uV=cell(size(Freqs2Run));
abrDATA1.HighLevels_dBSPL = [60 70 80];
abrDATA1.HighLev_Amplitude_uV=cell(size(Freqs2Run));
abrDATA1.HighLev_Latency_ms=cell(size(Freqs2Run));

%% Loop through all frequencies asked for in Freqs2Run
for FreqIND=1:length(Freqs2Run)

    %% Find data file for this frequency
    % There should only be one file per frequency! check this.
    Atrack = 0;    
    if strcmp(Freqs2Run{FreqIND},'click')  % string for click
        strFreq = Freqs2Run{FreqIND};
    else % make string for tone freq
        %Find one file per frequency ONLY
        strFreq = num2str(Freqs2Run_vector(FreqIND));
    end
    for rr = 1:length(Dlist)
        if contains(Dlist(rr).name,strFreq)
            Atrack = Atrack + 1;
            stophere = rr;
        end
    end
    %CHECK: Only ONE FILE should exist in folder for a particular freq
    if (Atrack > 1)
        error('   ***TWO DATA FILES EXIST FOR %s FREQ in FOLDER: Choose only one file for Chin: %s;  Cond: %s\n',Freqs2Run{FreqIND},Chins2Run{ChinIND},Conds2Run{CondIND});
    elseif (Atrack < 1)
        error('   ***NO DATA FILES EXIST FOR %s FREQ in FOLDER:  Make sure data is in folder for Chin: %s;  Cond: %s\n',Freqs2Run{FreqIND},Chins2Run{ChinIND},Conds2Run{CondIND});
        SKIP=1;
    else %ONLY ONE FILE EXISTS
        filenameofInt = Dlist(stophere).name;
        SKIP=0;
    end
  
    if (~SKIP) %If data does not exist, skip this frequency
                      
        %% Load in ABR processed data
        load(filenameofInt);  % all data from abr_analysis stored in abrs

        %% Save just key data for this Project
        %
        %% Threshold  (abrs.thresholds = [freq CCthreshold PPthreshold ???]
        TEMPind=find(abrs.thresholds(:,1)==Freqs2Run_vector(FreqIND)); % Find row with this freqs' thresholds;
        abrDATA1.Thresholds_dBSPL(FreqIND)=abrs.thresholds(TEMPind,2);

        %% Amplitudes (abrs.y has picked peaks: [0 dBSPL P1 N1 P2 N2 P3 N3 P4 N4 P5 N5]
        abrDATA1.AmplitudesALL_uV{FreqIND}.levels_dBSPL=abrs.y(:,2)';
        abrDATA1.AmplitudesALL_uV{FreqIND}.P1=abrs.y(:,3)';
        abrDATA1.AmplitudesALL_uV{FreqIND}.N1=abrs.y(:,4)';
        %         abrDATA1.AmplitudesALL_uV{FreqIND}.P2=abrs.y(:,5)';
        %         abrDATA1.AmplitudesALL_uV{FreqIND}.N2=abrs.y(:,6)';
        %         abrDATA1.AmplitudesALL_uV{FreqIND}.P3=abrs.y(:,7)';
        %         abrDATA1.AmplitudesALL_uV{FreqIND}.N3=abrs.y(:,8)';
        %         abrDATA1.AmplitudesALL_uV{FreqIND}.P4=abrs.y(:,9)';
        %         abrDATA1.AmplitudesALL_uV{FreqIND}.N4=abrs.y(:,10)';
        abrDATA1.AmplitudesALL_uV{FreqIND}.P5=abrs.y(:,11)';
        abrDATA1.AmplitudesALL_uV{FreqIND}.N5=abrs.y(:,12)';
        
        %% Latencies (abrs.x has picked peaks: [0 dBSPL P1 N1 P2 N2 P3 N3 P4 N4 P5 N5]
        abrDATA1.LatenciesALL_uV{FreqIND}.P1=abrs.x(:,3)';
        abrDATA1.LatenciesALL_uV{FreqIND}.N1=abrs.x(:,4)';
        %         abrDATA1.LatenciesALL_uV{FreqIND}.P2=abrs.x(:,5)';
        %         abrDATA1.LatenciesALL_uV{FreqIND}.N2=abrs.x(:,6)';
        %         abrDATA1.LatenciesALL_uV{FreqIND}.P3=abrs.x(:,7)';
        %         abrDATA1.LatenciesALL_uV{FreqIND}.N3=abrs.x(:,8)';
        %         abrDATA1.LatenciesALL_uV{FreqIND}.P4=abrs.x(:,9)';
        %         abrDATA1.LatenciesALL_uV{FreqIND}.N4=abrs.x(:,10)';
        abrDATA1.LatenciesALL_uV{FreqIND}.P5=abrs.x(:,11)';
        abrDATA1.LatenciesALL_uV{FreqIND}.N5=abrs.x(:,12)';

        %% Find High-Level Amplitude and Latency (in abrDATA1.HighLevels_dB SPL)
        HighLevINDs=find(ismember(round(abrDATA1.AmplitudesALL_uV{1}.levels_dBSPL/10)*10,abrDATA1.HighLevels_dBSPL)); % rounds within 5dB of real levels
        % just check to be sure we're getting top 3 levels for each freq 
        if length(HighLevINDs)~=3
            error('not 3 high level indices [60 70 80]')
        end
        if ~(ismember(1,HighLevINDs)&ismember(2,HighLevINDs)&ismember(3,HighLevINDs))
            error('not top 3 levels chosen for [60 70 80]')
        end
        abrDATA1.HighLev_Amplitude_uV{FreqIND}.P1 = nanmean(abrDATA1.AmplitudesALL_uV{FreqIND}.P1(HighLevINDs));
        abrDATA1.HighLev_Amplitude_uV{FreqIND}.N1 = nanmean(abrDATA1.AmplitudesALL_uV{FreqIND}.N1(HighLevINDs));
        %         abrDATA1.HighLev_Amplitude_uV{FreqIND}.P2 = nanmean(abrDATA1.AmplitudesALL_uV{FreqIND}.P2(HighLevINDs));
        %         abrDATA1.HighLev_Amplitude_uV{FreqIND}.N2 = nanmean(abrDATA1.AmplitudesALL_uV{FreqIND}.N2(HighLevINDs));
        %         abrDATA1.HighLev_Amplitude_uV{FreqIND}.P3 = nanmean(abrDATA1.AmplitudesALL_uV{FreqIND}.P3(HighLevINDs));
        %         abrDATA1.HighLev_Amplitude_uV{FreqIND}.N3 = nanmean(abrDATA1.AmplitudesALL_uV{FreqIND}.N3(HighLevINDs));
        %         abrDATA1.HighLev_Amplitude_uV{FreqIND}.P4 = nanmean(abrDATA1.AmplitudesALL_uV{FreqIND}.P4(HighLevINDs));
        %         abrDATA1.HighLev_Amplitude_uV{FreqIND}.N4 = nanmean(abrDATA1.AmplitudesALL_uV{FreqIND}.N4(HighLevINDs));
        abrDATA1.HighLev_Amplitude_uV{FreqIND}.P5 = nanmean(abrDATA1.AmplitudesALL_uV{FreqIND}.P5(HighLevINDs));
        abrDATA1.HighLev_Amplitude_uV{FreqIND}.N5 = nanmean(abrDATA1.AmplitudesALL_uV{FreqIND}.N5(HighLevINDs));
        % Compute Waves 1 and 5 and 1/5
        abrDATA1.HighLev_Amplitude_uV{FreqIND}.W1 = abrDATA1.HighLev_Amplitude_uV{FreqIND}.P1 - abrDATA1.HighLev_Amplitude_uV{FreqIND}.N1;
        %         abrDATA1.HighLev_Amplitude_uV{FreqIND}.W2 = abrDATA1.HighLev_Amplitude_uV{FreqIND}.P2 - abrDATA1.HighLev_Amplitude_uV{FreqIND}.N2;
        %         abrDATA1.HighLev_Amplitude_uV{FreqIND}.W3 = abrDATA1.HighLev_Amplitude_uV{FreqIND}.P3 - abrDATA1.HighLev_Amplitude_uV{FreqIND}.N3;
        %         abrDATA1.HighLev_Amplitude_uV{FreqIND}.W4 = abrDATA1.HighLev_Amplitude_uV{FreqIND}.P4 - abrDATA1.HighLev_Amplitude_uV{FreqIND}.N4;
        abrDATA1.HighLev_Amplitude_uV{FreqIND}.W5 = abrDATA1.HighLev_Amplitude_uV{FreqIND}.P5 - abrDATA1.HighLev_Amplitude_uV{FreqIND}.N5;
        abrDATA1.HighLev_Amplitude_uV{FreqIND}.W1_W5rat = abrDATA1.HighLev_Amplitude_uV{FreqIND}.W1/abrDATA1.HighLev_Amplitude_uV{FreqIND}.W5;

        abrDATA1.HighLev_Latency_ms{FreqIND}.P1 = nanmean(abrDATA1.LatenciesALL_uV{FreqIND}.P1(HighLevINDs));
        abrDATA1.HighLev_Latency_ms{FreqIND}.N1 = nanmean(abrDATA1.LatenciesALL_uV{FreqIND}.N1(HighLevINDs));
        %         abrDATA1.HighLev_Latency_ms{FreqIND}.P2 = nanmean(abrDATA1.LatenciesALL_uV{FreqIND}.P2(HighLevINDs));
        %         abrDATA1.HighLev_Latency_ms{FreqIND}.N2 = nanmean(abrDATA1.LatenciesALL_uV{FreqIND}.N2(HighLevINDs));
        %         abrDATA1.HighLev_Latency_ms{FreqIND}.P3 = nanmean(abrDATA1.LatenciesALL_uV{FreqIND}.P3(HighLevINDs));
        %         abrDATA1.HighLev_Latency_ms{FreqIND}.N3 = nanmean(abrDATA1.LatenciesALL_uV{FreqIND}.N3(HighLevINDs));
        %         abrDATA1.HighLev_Latency_ms{FreqIND}.P4 = nanmean(abrDATA1.LatenciesALL_uV{FreqIND}.P4(HighLevINDs));
        %         abrDATA1.HighLev_Latency_ms{FreqIND}.N4 = nanmean(abrDATA1.LatenciesALL_uV{FreqIND}.N4(HighLevINDs));
        abrDATA1.HighLev_Latency_ms{FreqIND}.P5 = nanmean(abrDATA1.LatenciesALL_uV{FreqIND}.P5(HighLevINDs));
        abrDATA1.HighLev_Latency_ms{FreqIND}.N5 = nanmean(abrDATA1.LatenciesALL_uV{FreqIND}.N5(HighLevINDs));
        
    else
        disp(sprintf('NO data for: %s',Freqs2Run{FreqIND}))
    end % SKIP
end % Freq
cd(ANALYSISdir1)  
save(filename,'abrDATA1') 


%% Plot individual Chin/Condition Data -- Thresholds
figure(str2num(Chin(2:end))); clf
set(gcf, 'units', 'normalized', 'position', [0.0005    0.0565    0.4375    0.5833]);
%Common variables
markerSIZE=6;
marker_LW=2;
textFNTSIZE=16;
legendSIZE=12;
labelFNTSIZE=18;
gcaFNTSIZE=16;
gcaLW=2;

% Set up click plotting
click_FreqIND = find(strcmp(Freqs2Run,'click'));
toneINDs=setdiff(1:length(Freqs2Run),click_FreqIND);
clickPLOT_Freq_Hz = 350;
freqs_plot = [clickPLOT_Freq_Hz,Freqs2Run_vector(2:end)];

if ~isempty(strfind(Cond,'pre'))
    colorCOND='b';
elseif ~isempty(strfind(Cond,'post'))
    colorCOND='r';
else
    colorCOND='k';
end

%Plot Thresholds
semilogx(Freqs2Run_vector(toneINDs)/1000,abrDATA1.Thresholds_dBSPL(toneINDs),'-o','color',colorCOND,...
    'LineWidth',gcaLW,'MarkerSize',markerSIZE,'MarkerFaceColor',colorCOND)
hold on
plot(clickPLOT_Freq_Hz/1000,abrDATA1.Thresholds_dBSPL(click_FreqIND),'s','color',colorCOND, ...
    'LineWidth',gcaLW,'MarkerSize',markerSIZE+2,'MarkerFaceColor',colorCOND)
% List condition
text(.05,.9,Cond,'HorizontalAlignment','left','FontSize', textFNTSIZE,'units','norm')
Y_SCALE_min=0;
Y_SCALE_max=50;
if ~isempty(strfind(Cond,'post')) % Add exposure band as grey bar
    patch([1/sqrt(2) sqrt(2) sqrt(2) 1/sqrt(2)],[Y_SCALE_min Y_SCALE_min Y_SCALE_max Y_SCALE_max], ...
        0.75*ones(1,3),'LineStyle','none')
    set(gca,'children',flipud(get(gca,'children')))  % Needed to get grey bar behind axes
end
set(gca, 'FontSize', gcaFNTSIZE);
title(strcat('ABR Thresholds -- ',Chin),'FontSize',labelFNTSIZE);
xlabel('Frequency (kHz)', 'FontSize', labelFNTSIZE);
ylabel('Threshold (dB SPL)', 'FontSize', labelFNTSIZE);
ylim([Y_SCALE_min,Y_SCALE_max]);
set(gca, 'XTick', [.1 1 10], 'XTickLabel', [.1 1 10]);
set(gca,'xscale','log');
xlim([.25 10])
% grid on
set(gca,'linew',2);
set(gca, 'Layer', 'top')  % keeps patch under axes
text(clickPLOT_Freq_Hz/1000,Y_SCALE_min*.95,'click','Color','k','FontSize',labelFNTSIZE,'units','data','HorizontalAlignment','center','VerticalAlignment','top')
hold off

print('-dtiff',strcat(filename,'_Thrs'))



%% Plot individual Chin/Condition Data -- Amplitudes and Latencies
figure(str2num(Chin(2:end))+1); clf
set(gcf,'units','norm','pos',[.55    0.0565    0.4375    0.8324])
%Common variables
plotcolors = {'b','r','g','c','m','k'};
markerStyles = {'o','+','*','x','s','d'}; %for 6 freq values
markerSIZE=12;

%Top - Amplitudes
ax(1) = subplot(211);

for FreqIND = 1:length(Freqs2Run)
    styleTXT= strcat(plotcolors{FreqIND},markerStyles{FreqIND});
    %Plot amplitudes
    plot(1, abrDATA1.HighLev_Amplitude_uV{FreqIND}.P1,styleTXT,'MarkerSize',markerSIZE,'LineWidth',marker_LW)
    hold on
    plot(2, abrDATA1.HighLev_Amplitude_uV{FreqIND}.N1,styleTXT,'MarkerSize',markerSIZE,'LineWidth',marker_LW)

    plot(4, abrDATA1.HighLev_Amplitude_uV{FreqIND}.P5,styleTXT,'MarkerSize',markerSIZE,'LineWidth',marker_LW)
    plot(5, abrDATA1.HighLev_Amplitude_uV{FreqIND}.N5,styleTXT,'MarkerSize',markerSIZE,'LineWidth',marker_LW)

    plot(7, abrDATA1.HighLev_Amplitude_uV{FreqIND}.W1,styleTXT,'MarkerSize',markerSIZE,'LineWidth',marker_LW)
    plot(8, abrDATA1.HighLev_Amplitude_uV{FreqIND}.W5,styleTXT,'MarkerSize',markerSIZE,'LineWidth',marker_LW)  
    plot(9, abrDATA1.HighLev_Amplitude_uV{FreqIND}.W1_W5rat,styleTXT,'MarkerSize',markerSIZE,'LineWidth',marker_LW)
    
end

Y_SCALE_min=-1.5;
Y_SCALE_max=3.5;
text(1,Y_SCALE_min,'P1','Color','b','FontSize', textFNTSIZE,'VerticalAlignment','top','HorizontalAlignment','center')
text(2,Y_SCALE_min,'N1','Color','r','FontSize', textFNTSIZE,'VerticalAlignment','top','HorizontalAlignment','center')
text(4,Y_SCALE_min,'P5','Color','b','FontSize', textFNTSIZE,'VerticalAlignment','top','HorizontalAlignment','center')
text(5,Y_SCALE_min,'N5','Color','r','FontSize', textFNTSIZE,'VerticalAlignment','top','HorizontalAlignment','center')
text(7,Y_SCALE_min,'W1','Color','k','FontSize', textFNTSIZE,'VerticalAlignment','top','HorizontalAlignment','center')
text(8,Y_SCALE_min,'W5','Color','k','FontSize', textFNTSIZE,'VerticalAlignment','top','HorizontalAlignment','center')
text(9,Y_SCALE_min,'W1/W5','Color','m','FontSize', textFNTSIZE,'VerticalAlignment','top','HorizontalAlignment','center')
set(gca, 'FontSize', gcaFNTSIZE);
title(strcat('ABR Amplitudes -- ',Chin),'FontSize',labelFNTSIZE);
ylabel('Amplitude (\muV)', 'FontSize', labelFNTSIZE,'Interpreter','tex');
set(gca, 'XTick',[1 2 4 5 7 8 9], 'XTickLabel', []);
ylim([Y_SCALE_min,Y_SCALE_max]);
xlim([0 10])
% grid on
set(gca,'linew',gcaLW);


%Bottom - Latencies 
ax(2) = subplot(212);

for FreqIND = 1:length(Freqs2Run)
    styleTXT= strcat(plotcolors{FreqIND},markerStyles{FreqIND});
    %Plot latencies
    plot(1, abrDATA1.HighLev_Latency_ms{FreqIND}.P1,styleTXT,'MarkerSize',markerSIZE,'LineWidth',marker_LW)
    hold on
    plot(2, abrDATA1.HighLev_Latency_ms{FreqIND}.N1,styleTXT,'MarkerSize',markerSIZE,'LineWidth',marker_LW)

    plot(4, abrDATA1.HighLev_Latency_ms{FreqIND}.P5,styleTXT,'MarkerSize',markerSIZE,'LineWidth',marker_LW)
    plot(5, abrDATA1.HighLev_Latency_ms{FreqIND}.N5,styleTXT,'MarkerSize',markerSIZE,'LineWidth',marker_LW)
   
    % prep legends
    hleg(FreqIND) = plot(NaN,NaN,styleTXT,'MarkerSize',markerSIZE,'LineWidth',marker_LW);
end
legend(gca,hleg,Freqs2Run,'Location','Southeast','FontSize',legendSIZE);
% List condition
text(.95,.9,Cond,'HorizontalAlignment','right','FontSize', textFNTSIZE,'units','norm')

Y_SCALE_min=2;
Y_SCALE_max=9;
text(1,Y_SCALE_min,'P1','Color','b','FontSize', textFNTSIZE,'VerticalAlignment','top','HorizontalAlignment','center')
text(2,Y_SCALE_min,'N1','Color','r','FontSize', textFNTSIZE,'VerticalAlignment','top','HorizontalAlignment','center')
text(4,Y_SCALE_min,'P5','Color','b','FontSize', textFNTSIZE,'VerticalAlignment','top','HorizontalAlignment','center')
text(5,Y_SCALE_min,'N5','Color','r','FontSize', textFNTSIZE,'VerticalAlignment','top','HorizontalAlignment','center')
set(gca, 'FontSize', gcaFNTSIZE);
title(strcat('ABR Latencies -- ',Chin),'FontSize',labelFNTSIZE);
ylabel('Latency (ms)', 'Interpreter','tex','FontSize',labelFNTSIZE);
set(gca, 'XTick',[1 2 4 5 ], 'XTickLabel', []);
ylim([Y_SCALE_min,Y_SCALE_max]);
xlim([0 10])
% grid on
set(gca,'linew',gcaLW);

orient tall
hold off

print('-dtiff',strcat(filename,'_AmpLat'))
