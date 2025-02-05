function analyzeABRs_AVG(ROOTdir,datapath,outpath,subject,condition)
%% Analyze ABR data from NEL (after pre-processing raw data)
%
% M. Heinz
% Feb 2, 2019
% Updated: Apr 23 2020 (new data structure to save all data/TIFs at all
% stages. Addded in W1/W5, and all high-level AVGs per chin/cond)
%
% Compares:
%    1) pre and post comparisons for all chins,
%    2) AVG data across all chins
% 
% - No hand picking, just hard coded what chins and conditions to run
% - must have run preprocessALL_ABRs first, to save processed data for
% each chin/condition into Analysis folder.
% - this reads in preprocessed data to save time, rather than all raw data.
% Also saves processed data for use in figures and stats for papers. Also
% adds in AVG(4,8 kHz) to match to Hari's 3-8 kHz click ABRs.

close all
warning off

% Set save to 1 if you would only like to plot the summary figure, using
% saved data already; 0 if yuo want to gather all data across chins/conds.
plot_only = 1; % Still needs set up

%% Specify Experiment Specifics, including Directories

outpath=strcat(ROOTdir,filesep,'Analysis');
filename_ABRresults = 'ABRs_AllChins_AVG';  % filename_prefix for saving Project data and TIFs
addpath(strcat(outpath,filesep,'generalCODE'));


%% Specify Chins and Conds to include
Chins2Run={'Q348','Q350','Q351','Q363','Q364','Q365','Q368'};  % all 7 chins
Conds2Run={'pre\1weekPreTTS','post\2weeksPostTTS'};
Freqs2Run = {'click','500Hz','1kHz','2kHz','4kHz','8kHz'};
Freqs2Run_vector = [0, 500, 1000, 2000, 4000, 8000];
FreqAVG2Run = '4&8kHz';
FreqAVG2Run_vector= [4000 8000];
ABRpeaks2Run={'P1','N1','P5','N5','W1','W5','W1_W5rat'};

% Common plotting variables
markerStyles = {'o','+','*','x','s','d','<'};
plotcolors = {'b','y','g','c','m','r','k'};    % for 7 freq values
        
if ~plot_only % Compile and AVG all data

    %% Initialize Data structures
    abrDATAfull=cell(length(Chins2Run),length(Conds2Run));  % Save ALL abrDATA1s for all chins/conds.
    clear abrDATAuse
    % General
    abrDATAuse.Chins = Chins2Run;    % Save ALL data 2 use for figures & stats
    abrDATAuse.Conditions = Conds2Run;
    abrDATAuse.Freqs_str = Freqs2Run;
    abrDATAuse.Freqs_Hz = Freqs2Run_vector;
    % Thresholds
    abrDATAuse.Thresholds_dBSPL.chindata = cell(size(Conds2Run));
    for CondIND=1:length(Conds2Run)
        abrDATAuse.Thresholds_dBSPL.chindata{CondIND} = NaN+zeros(length(Chins2Run),length(Freqs2Run));
    end
    abrDATAuse.Thresholds_dBSPL.chinAVG = NaN + zeros(length(Conds2Run),length(Freqs2Run));
    abrDATAuse.Thresholds_dBSPL.chinSTD = NaN + zeros(length(Conds2Run),length(Freqs2Run));
    abrDATAuse.Thresholds_dBSPL.Cohen_d.group_val = NaN + zeros(1,length(Freqs2Run));
    abrDATAuse.Thresholds_dBSPL.Cohen_d.group_size = cell(1,length(Freqs2Run));
    abrDATAuse.Thresholds_dBSPL.Cohen_d.within_val = NaN + zeros(1,length(Freqs2Run));
    abrDATAuse.Thresholds_dBSPL.Cohen_d.within_size = cell(1,length(Freqs2Run));
    % Amplitudes
    abrDATAuse.HighLev_Amplitude_uV.Freqs_str = [Freqs2Run strcat('avg',FreqAVG2Run)];
    abrDATAuse.HighLev_Amplitude_uV.Freqs_Hz = [Freqs2Run_vector 9999];
    for PeakIND=1:length(ABRpeaks2Run)
        eval(['abrDATAuse.HighLev_Amplitude_uV.' ABRpeaks2Run{PeakIND} '.chindata{CondIND} = cell(size(Conds2Run));']);
    end
    for PeakIND=1:length(ABRpeaks2Run)
        for CondIND=1:length(Conds2Run)
            eval(['abrDATAuse.HighLev_Amplitude_uV.' ABRpeaks2Run{PeakIND} '.chindata{CondIND} = NaN+zeros(length(Chins2Run),length(abrDATAuse.HighLev_Amplitude_uV.Freqs_Hz));']);
        end
        eval(['abrDATAuse.HighLev_Amplitude_uV.' ABRpeaks2Run{PeakIND} '.chinAVG = NaN + zeros(length(Conds2Run),length(abrDATAuse.HighLev_Amplitude_uV.Freqs_Hz));']);
        eval(['abrDATAuse.HighLev_Amplitude_uV.' ABRpeaks2Run{PeakIND} '.chinSTD = NaN + zeros(length(Conds2Run),length(abrDATAuse.HighLev_Amplitude_uV.Freqs_Hz));']);
        eval(['abrDATAuse.HighLev_Amplitude_uV.' ABRpeaks2Run{PeakIND} '.Cohen_d.group_val = NaN + zeros(1,length(abrDATAuse.HighLev_Amplitude_uV.Freqs_Hz));']);
        eval(['abrDATAuse.HighLev_Amplitude_uV.' ABRpeaks2Run{PeakIND} '.Cohen_d.group_size = cell(1,length(abrDATAuse.HighLev_Amplitude_uV.Freqs_Hz));']);
        eval(['abrDATAuse.HighLev_Amplitude_uV.' ABRpeaks2Run{PeakIND} '.Cohen_d.within_val = NaN + zeros(1,length(abrDATAuse.HighLev_Amplitude_uV.Freqs_Hz));']);
        eval(['abrDATAuse.HighLev_Amplitude_uV.' ABRpeaks2Run{PeakIND} '.Cohen_d.within_size = cell(1,length(abrDATAuse.HighLev_Amplitude_uV.Freqs_Hz));']);
    end
    % Latencies
    for PeakIND=1:length(ABRpeaks2Run(1:4))   % only P1,N1,P5,N5 stored
        eval(['abrDATAuse.HighLev_Latency_ms.' ABRpeaks2Run{PeakIND} '.chindata{CondIND} = cell(size(Conds2Run));']);
    end
    for PeakIND=1:length(ABRpeaks2Run(1:4))   % only P1,N1,P5,N5 stored
        for CondIND=1:length(Conds2Run)
            eval(['abrDATAuse.HighLev_Latency_ms.' ABRpeaks2Run{PeakIND} '.chindata{CondIND} = NaN+zeros(length(Chins2Run),length(abrDATAuse.HighLev_Amplitude_uV.Freqs_Hz));']);
        end
        eval(['abrDATAuse.HighLev_Latency_ms.' ABRpeaks2Run{PeakIND} '.chinAVG = NaN + zeros(length(Conds2Run),length(abrDATAuse.HighLev_Amplitude_uV.Freqs_Hz));']);
        eval(['abrDATAuse.HighLev_Latency_ms.' ABRpeaks2Run{PeakIND} '.chinSTD = NaN + zeros(length(Conds2Run),length(abrDATAuse.HighLev_Amplitude_uV.Freqs_Hz));']);
        eval(['abrDATAuse.HighLev_Latency_ms.' ABRpeaks2Run{PeakIND} '.Cohen_d.group_val = NaN + zeros(1,length(abrDATAuse.HighLev_Amplitude_uV.Freqs_Hz));']);
        eval(['abrDATAuse.HighLev_Latency_ms.' ABRpeaks2Run{PeakIND} '.Cohen_d.group_size = cell(1,length(abrDATAuse.HighLev_Amplitude_uV.Freqs_Hz));']);
        eval(['abrDATAuse.HighLev_Latency_ms.' ABRpeaks2Run{PeakIND} '.Cohen_d.within_val = NaN + zeros(1,length(abrDATAuse.HighLev_Amplitude_uV.Freqs_Hz));']);
        eval(['abrDATAuse.HighLev_Latency_ms.' ABRpeaks2Run{PeakIND} '.Cohen_d.within_size = cell(1,length(abrDATAuse.HighLev_Amplitude_uV.Freqs_Hz));']);
    end
    
    
    %% Store individual Chin data by Chin/Condition for use in later chin comps and AVG figures/analyses
    for ChinIND=1:length(Chins2Run)
        Chin=Chins2Run{ChinIND};
        for CondIND=1:length(Conds2Run)
            Cond=Conds2Run{CondIND};
            
            %% Read in data for this chin/condition
            fprintf('Gathering ABR Data for Chin: %s;  Cond: %s\n',Chin,Cond)
            cd(strcat(outpath,filesep,'ABR',filesep,Chin,filesep,Cond))
            
            filename2Read=sprintf('ABRs_%s_%s',Chin,Cond(findstr(Cond,'\')+1:end));  % filename to save this data and TIF file
            Dlist=dir(strcat(filename2Read,'.mat'));
            if isempty(Dlist)
                error(sprintf('The data file: %s.mat DOES NOT EXIST (run preprocessALL/1 to create this file)',filename2Read))
            else
                disp(sprintf('   Loading data file: %s.mat ',filename2Read))
            end
            load(Dlist.name);
            
            %% Save full data structure by chin/condition
            abrDATAfull{ChinIND,CondIND}=abrDATA1;
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %% Save data to use for final figures/analyses/stats
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            % Thresholds
            abrDATAuse.Thresholds_dBSPL.chindata{CondIND}(ChinIND,:) = abrDATA1.Thresholds_dBSPL;
            
            % Amplitudes
            for PeakIND=1:length(ABRpeaks2Run)
                for FreqIND=1:length(Freqs2Run)
                    eval(['abrDATAuse.HighLev_Amplitude_uV.' ABRpeaks2Run{PeakIND} '.chindata{CondIND}(ChinIND,FreqIND) = abrDATA1.HighLev_Amplitude_uV{FreqIND}.' ABRpeaks2Run{PeakIND} ';']);
                end
                % Add one AVG-across-freq value to end
                FreqAVG_INDs=find(ismember(abrDATAuse.HighLev_Amplitude_uV.Freqs_Hz,FreqAVG2Run_vector)); % indices of freqs to AVG
                tempVALs=NaN+zeros(size(FreqAVG_INDs));
                for FreqIND=1:length(FreqAVG_INDs)
                    eval(['tempVALs(FreqIND) = abrDATA1.HighLev_Amplitude_uV{FreqAVG_INDs(FreqIND)}.' ABRpeaks2Run{PeakIND} ';'])
                end
                eval(['abrDATAuse.HighLev_Amplitude_uV.' ABRpeaks2Run{PeakIND} '.chindata{CondIND}(ChinIND,end) = mean(tempVALs);']);
            end
            
            % Latencies
            for PeakIND=1:length(ABRpeaks2Run(1:4)) % only P1, N1, P5, N5 stored for latencies
                for FreqIND=1:length(Freqs2Run)
                    eval(['abrDATAuse.HighLev_Latency_ms.' ABRpeaks2Run{PeakIND} '.chindata{CondIND}(ChinIND,FreqIND) = abrDATA1.HighLev_Latency_ms{FreqIND}.' ABRpeaks2Run{PeakIND} ';']);
                end
                % Add one AVG-across-freq value to end
                FreqAVG_INDs=find(ismember(abrDATAuse.HighLev_Amplitude_uV.Freqs_Hz,FreqAVG2Run_vector)); % indices of freqs to AVG
                tempVALs=NaN+zeros(size(FreqAVG_INDs));
                for FreqIND=1:length(FreqAVG_INDs)
                    eval(['tempVALs(FreqIND) = abrDATA1.HighLev_Latency_ms{FreqAVG_INDs(FreqIND)}.' ABRpeaks2Run{PeakIND} ';'])
                end
                eval(['abrDATAuse.HighLev_Latency_ms.' ABRpeaks2Run{PeakIND} '.chindata{CondIND}(ChinIND,end) = mean(tempVALs);']);
            end
            
        end   % Cond loop
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %% Plot individual Chin Comparisons
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        cd(strcat(outpath,filesep,'ABR',filesep,Chin))
        
        %% Thresholds
        %% Plot individual chin comparison (pre vs. post) -- Thresholds
        figure(str2num(Chin(2:end))); clf
        set(gcf, 'units', 'normalized', 'position', [0.0005    0.0565    0.4375    0.5833]);
        %Common variables
        markerSIZE=6;
        marker_LW=2;
        textFNTSIZE=16;
        labelFNTSIZE=18;
        legendSIZE=12;
        gcaFNTSIZE=16;
        gcaLW=2;
        
        % Set up click plotting
        click_FreqIND = find(strcmp(Freqs2Run,'click'));
        toneINDs=setdiff(1:length(Freqs2Run),click_FreqIND);
        clickPLOT_Freq_Hz = 350;
        
        for CondIND=1:length(Conds2Run)
            Cond=Conds2Run{CondIND};
            if ~isempty(strfind(Cond,'pre'))
                colorCOND='b';
            elseif ~isempty(strfind(Cond,'post'))
                colorCOND='r';
            else
                colorCOND='k';
            end
            
            %Plot Thresholds
            hplot(CondIND)=semilogx(abrDATAuse.Freqs_Hz(toneINDs)/1000,abrDATAuse.Thresholds_dBSPL.chindata{CondIND}(ChinIND,toneINDs), ...
                '-o','color',colorCOND,'LineWidth',gcaLW,'MarkerSize',markerSIZE,'MarkerFaceColor',colorCOND);
            hold on
            plot(clickPLOT_Freq_Hz/1000,abrDATAuse.Thresholds_dBSPL.chindata{CondIND}(ChinIND,click_FreqIND), ...
                's','color',colorCOND,'LineWidth',gcaLW,'MarkerSize',markerSIZE+2,'MarkerFaceColor',colorCOND)
        end
        Y_SCALE_min=0;
        Y_SCALE_max=50;
        patch([1/sqrt(2) sqrt(2) sqrt(2) 1/sqrt(2)],[Y_SCALE_min Y_SCALE_min Y_SCALE_max Y_SCALE_max], ...
            0.75*ones(1,3),'LineStyle','none')
        set(gca,'children',flipud(get(gca,'children')))
        legend(gca,hplot,Conds2Run,'Location','Northeast','FontSize',legendSIZE);
        
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
        
        print('-dtiff',strcat('ABRs_',Chin,'_compare_Thrs'))
        
        
        %% Amplitudes and Latencies
        %% Plot individual Chin/Condition Data -- Amplitudes and Latencies
        figure(10*str2num(Chin(2:end))); clf
        set(gcf,'units','norm','pos',[.55    0.0565    0.4375    0.8324])
        %Common variables
        markerSIZE=12;
        
        %Top - Amplitudes
        ax(1) = subplot(211);
        for FreqIND = 1:length(abrDATAuse.HighLev_Amplitude_uV.Freqs_str)
            styleTXT= strcat(plotcolors{FreqIND},markerStyles{FreqIND},'-');
            plot(1+[0 (CondIND-1)/2], ...
                [abrDATAuse.HighLev_Amplitude_uV.P1.chindata{1}(ChinIND,FreqIND) abrDATAuse.HighLev_Amplitude_uV.P1.chindata{2}(ChinIND,FreqIND)], ...
                styleTXT,'MarkerSize',markerSIZE,'LineWidth',marker_LW)
            hold on
            plot(2+[0 (CondIND-1)/2], ...
                [abrDATAuse.HighLev_Amplitude_uV.N1.chindata{1}(ChinIND,FreqIND) abrDATAuse.HighLev_Amplitude_uV.N1.chindata{2}(ChinIND,FreqIND)], ...
                styleTXT,'MarkerSize',markerSIZE,'LineWidth',marker_LW)
            plot(4+[0 (CondIND-1)/2], ...
                [abrDATAuse.HighLev_Amplitude_uV.P5.chindata{1}(ChinIND,FreqIND) abrDATAuse.HighLev_Amplitude_uV.P5.chindata{2}(ChinIND,FreqIND)], ...
                styleTXT,'MarkerSize',markerSIZE,'LineWidth',marker_LW)
            plot(5+[0 (CondIND-1)/2], ...
                [abrDATAuse.HighLev_Amplitude_uV.N5.chindata{1}(ChinIND,FreqIND) abrDATAuse.HighLev_Amplitude_uV.N5.chindata{2}(ChinIND,FreqIND)], ...
                styleTXT,'MarkerSize',markerSIZE,'LineWidth',marker_LW)
            plot(7+[0 (CondIND-1)/2], ...
                [abrDATAuse.HighLev_Amplitude_uV.W1.chindata{1}(ChinIND,FreqIND) abrDATAuse.HighLev_Amplitude_uV.W1.chindata{2}(ChinIND,FreqIND)], ...
                styleTXT,'MarkerSize',markerSIZE,'LineWidth',marker_LW)
            plot(8+[0 (CondIND-1)/2], ...
                [abrDATAuse.HighLev_Amplitude_uV.W5.chindata{1}(ChinIND,FreqIND) abrDATAuse.HighLev_Amplitude_uV.W5.chindata{2}(ChinIND,FreqIND)], ...
                styleTXT,'MarkerSize',markerSIZE,'LineWidth',marker_LW)
            plot(9+[0 (CondIND-1)/2], ...
                [abrDATAuse.HighLev_Amplitude_uV.W1_W5rat.chindata{1}(ChinIND,FreqIND) abrDATAuse.HighLev_Amplitude_uV.W1_W5rat.chindata{2}(ChinIND,FreqIND)], ...
                styleTXT,'MarkerSize',markerSIZE,'LineWidth',marker_LW)
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
                
        % Bottom - Latencies
        ax(2) = subplot(212);
        
        for FreqIND = 1:length(abrDATAuse.HighLev_Amplitude_uV.Freqs_str)
            styleTXT= strcat(plotcolors{FreqIND},markerStyles{FreqIND},'-');
            plot(1+[0 (CondIND-1)/2], ...
                [abrDATAuse.HighLev_Latency_ms.P1.chindata{1}(ChinIND,FreqIND) abrDATAuse.HighLev_Latency_ms.P1.chindata{2}(ChinIND,FreqIND)], ...
                styleTXT,'MarkerSize',markerSIZE,'LineWidth',marker_LW)
            hold on
            plot(2+[0 (CondIND-1)/2], ...
                [abrDATAuse.HighLev_Latency_ms.N1.chindata{1}(ChinIND,FreqIND) abrDATAuse.HighLev_Latency_ms.N1.chindata{2}(ChinIND,FreqIND)], ...
                styleTXT,'MarkerSize',markerSIZE,'LineWidth',marker_LW)
            plot(4+[0 (CondIND-1)/2], ...
                [abrDATAuse.HighLev_Latency_ms.P5.chindata{1}(ChinIND,FreqIND) abrDATAuse.HighLev_Latency_ms.P5.chindata{2}(ChinIND,FreqIND)], ...
                styleTXT,'MarkerSize',markerSIZE,'LineWidth',marker_LW)
            plot(5+[0 (CondIND-1)/2], ...
                [abrDATAuse.HighLev_Latency_ms.N5.chindata{1}(ChinIND,FreqIND) abrDATAuse.HighLev_Latency_ms.N5.chindata{2}(ChinIND,FreqIND)], ...
                styleTXT,'MarkerSize',markerSIZE,'LineWidth',marker_LW)
            
            % prep legends
            hleg(FreqIND) = plot(NaN,NaN,styleTXT,'MarkerSize',markerSIZE,'LineWidth',marker_LW);
        end
        legend(gca,hleg,abrDATAuse.HighLev_Amplitude_uV.Freqs_str,'Location','Southeast','FontSize',legendSIZE);
        % List condition
        text(.975,.93,Conds2Run(1),'HorizontalAlignment','right','FontSize', textFNTSIZE,'units','norm')
        text(.975,.85,Conds2Run(2),'HorizontalAlignment','right','FontSize', textFNTSIZE,'units','norm')
        
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
        
        print('-dtiff',strcat('ABRs_',Chin,'_compare_AmpLats'))
        
    end % Chin loop
    close all

    %% Compute Stats across chins
    cd(strcat(outpath,filesep,'ABR'))
    %% Thresholds
    for CondIND=1:length(Conds2Run)
        abrDATAuse.Thresholds_dBSPL.chinAVG(CondIND,:) = mean(abrDATAuse.Thresholds_dBSPL.chindata{CondIND});
        abrDATAuse.Thresholds_dBSPL.chinSTD(CondIND,:) = std(abrDATAuse.Thresholds_dBSPL.chindata{CondIND});
    end
    % compute Effect Size (both d "value" and "size" category) for Thresholds
    % (re: 1st condition)
    for FreqIND=1:length(Freqs2Run)
        sample1=abrDATAuse.Thresholds_dBSPL.chindata{1}(:,FreqIND);  % Sample 1 is the reference condition ("pre" here)
        sample2=abrDATAuse.Thresholds_dBSPL.chindata{2}(:,FreqIND);
        % compute Cohen-d both as group comparison and as within-subject
        % comparison [within_yes=0 and 1, respectively];
        [abrDATAuse.Thresholds_dBSPL.Cohen_d.group_val(FreqIND) abrDATAuse.Thresholds_dBSPL.Cohen_d.group_size{FreqIND}]= Cohen_d(sample1,sample2,0);
        [abrDATAuse.Thresholds_dBSPL.Cohen_d.within_val(FreqIND) abrDATAuse.Thresholds_dBSPL.Cohen_d.within_size{FreqIND}]= Cohen_d(sample1,sample2,1);
    end
    
    %% Amplitudes
    for CondIND=1:length(Conds2Run)
        for PeakIND=1:length(ABRpeaks2Run)
            eval(['abrDATAuse.HighLev_Amplitude_uV.' ABRpeaks2Run{PeakIND} '.chinAVG(CondIND,:) = mean(abrDATAuse.HighLev_Amplitude_uV.' ABRpeaks2Run{PeakIND} '.chindata{CondIND});'])
            eval(['abrDATAuse.HighLev_Amplitude_uV.' ABRpeaks2Run{PeakIND} '.chinSTD(CondIND,:) = std(abrDATAuse.HighLev_Amplitude_uV.' ABRpeaks2Run{PeakIND} '.chindata{CondIND});'])
        end
    end
    % compute Effect Size for Amplitudes
    for PeakIND=1:length(ABRpeaks2Run)
        for FreqIND=1:length(abrDATAuse.HighLev_Amplitude_uV.Freqs_str)
            eval(['sample1=abrDATAuse.HighLev_Amplitude_uV.' ABRpeaks2Run{PeakIND} '.chindata{1}(:,FreqIND);'])  % Sample 1 is the reference condition ("pre" here) 
            eval(['sample2=abrDATAuse.HighLev_Amplitude_uV.' ABRpeaks2Run{PeakIND} '.chindata{2}(:,FreqIND);'])
            eval(['[abrDATAuse.HighLev_Amplitude_uV.' ABRpeaks2Run{PeakIND} '.Cohen_d.group_val(FreqIND) abrDATAuse.HighLev_Amplitude_uV.' ABRpeaks2Run{PeakIND} '.Cohen_d.group_size{FreqIND}] = Cohen_d(sample1,sample2,0);'])
            eval(['[abrDATAuse.HighLev_Amplitude_uV.' ABRpeaks2Run{PeakIND} '.Cohen_d.within_val(FreqIND) abrDATAuse.HighLev_Amplitude_uV.' ABRpeaks2Run{PeakIND} '.Cohen_d.within_size{FreqIND}] = Cohen_d(sample1,sample2,1);'])
        end
    end
    
    %% Latencies
    for CondIND=1:length(Conds2Run)
        for PeakIND=1:4   % only P1,N1,P5,N5 stored
            eval(['abrDATAuse.HighLev_Latency_ms.' ABRpeaks2Run{PeakIND} '.chinAVG(CondIND,:) = mean(abrDATAuse.HighLev_Latency_ms.' ABRpeaks2Run{PeakIND} '.chindata{CondIND});'])
            eval(['abrDATAuse.HighLev_Latency_ms.' ABRpeaks2Run{PeakIND} '.chinSTD(CondIND,:) = std(abrDATAuse.HighLev_Latency_ms.' ABRpeaks2Run{PeakIND} '.chindata{CondIND});'])
        end
    end
    % compute Effect Size for Amplitudes
    for PeakIND=1:4   % only P1,N1,P5,N5 stored
        for FreqIND=1:length(abrDATAuse.HighLev_Amplitude_uV.Freqs_str)
            eval(['sample1=abrDATAuse.HighLev_Latency_ms.' ABRpeaks2Run{PeakIND} '.chindata{1}(:,FreqIND);']) % Sample 1 is the reference condition ("pre" here)
            eval(['sample2=abrDATAuse.HighLev_Latency_ms.' ABRpeaks2Run{PeakIND} '.chindata{2}(:,FreqIND);'])
            eval(['[abrDATAuse.HighLev_Latency_ms.' ABRpeaks2Run{PeakIND} '.Cohen_d.group_val(FreqIND) abrDATAuse.HighLev_Latency_ms.' ABRpeaks2Run{PeakIND} '.Cohen_d.group_size{FreqIND}] = Cohen_d(sample1,sample2,0);'])
            eval(['[abrDATAuse.HighLev_Latency_ms.' ABRpeaks2Run{PeakIND} '.Cohen_d.within_val(FreqIND) abrDATAuse.HighLev_Latency_ms.' ABRpeaks2Run{PeakIND} '.Cohen_d.within_size{FreqIND}] = Cohen_d(sample1,sample2,1);'])
        end
    end
    
    %% Save Full Data sets (full and use)
    save(strcat(filename_ABRresults,'_abrDATAfull'),'abrDATAfull')
    save(strcat(filename_ABRresults,'_abrDATAuse'),'abrDATAuse')

else % plot ONLY
    disp(sprintf('*** USING saved data from:\n      %s\n*** ONLY generating FINAL PLOTS',pwd))
    %% Load Data set to PLOT (use)
    load(strcat(filename_ABRresults,'_abrDATAuse'))
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Plot AVG Comparisons
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Thresholds
figure(1); clf
set(gcf, 'units', 'normalized', 'position', [0.0005    0.0565    0.4375    0.5833]);
%Common variables
markerSIZE=6;
marker_LW=2;
textFNTSIZE=16;
labelFNTSIZE=18;
legendSIZE=12;
gcaFNTSIZE=16;
gcaLW=2;

% Set up click plotting
click_FreqIND = find(strcmp(Freqs2Run,'click'));
toneINDs=setdiff(1:length(Freqs2Run),click_FreqIND);
clickPLOT_Freq_Hz = 350;

for CondIND=1:length(Conds2Run)
    Cond=Conds2Run{CondIND};
    if ~isempty(strfind(Cond,'pre'))
        colorCOND='b';
    elseif ~isempty(strfind(Cond,'post'))
        colorCOND='r';
    else
        colorCOND='k';
    end
    
    %Plot Thresholds
    hplot(CondIND)=errorbar(abrDATAuse.Freqs_Hz(toneINDs)/1000,abrDATAuse.Thresholds_dBSPL.chinAVG(CondIND,toneINDs), ...
        abrDATAuse.Thresholds_dBSPL.chinSTD(CondIND,toneINDs)/sqrt(length(Chins2Run)),'-o','color',colorCOND, ...
        'LineWidth',gcaLW,'MarkerSize',markerSIZE,'MarkerFaceColor',colorCOND);
    hold on
    errorbar(clickPLOT_Freq_Hz/1000,abrDATAuse.Thresholds_dBSPL.chinAVG(CondIND,click_FreqIND), ...
        abrDATAuse.Thresholds_dBSPL.chinSTD(CondIND,click_FreqIND)/sqrt(length(Chins2Run)),'s','color',colorCOND, ...
        'LineWidth',gcaLW,'MarkerSize',markerSIZE+2,'MarkerFaceColor',colorCOND)
end
Y_SCALE_min=0;
Y_SCALE_max=50;
patch([1/sqrt(2) sqrt(2) sqrt(2) 1/sqrt(2)],[Y_SCALE_min Y_SCALE_min Y_SCALE_max Y_SCALE_max], ...
    0.75*ones(1,3),'LineStyle','none')
set(gca,'children',flipud(get(gca,'children')))
legend(gca,hplot,Conds2Run,'Location','Northeast','FontSize',legendSIZE);

set(gca, 'FontSize', gcaFNTSIZE);
title(sprintf('Average ABR Thresholds -- %d Chins',length(Chins2Run)),'FontSize',labelFNTSIZE);
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

print('-dtiff',strcat(filename_ABRresults,'_Thrs'))


%% Threshold SHIFT
figure(2); clf
set(gcf, 'units', 'normalized', 'position', [0.0005    0.0565    0.4375    0.5833]);
%Common variables
markerSIZE=6;
marker_LW=2;
textFNTSIZE=16;
labelFNTSIZE=18;
legendSIZE=12;
gcaFNTSIZE=16;
gcaLW=2;

% Set up click plotting
click_FreqIND = find(strcmp(Freqs2Run,'click'));
toneINDs=setdiff(1:length(Freqs2Run),click_FreqIND);
clickPLOT_Freq_Hz = 350;
   
%Plot Threshold Shift
% Control (pre) to show STE
plot([.25 10],[0 0],'k-','LineWidth',1)
hold on
hplot(1)=errorbar(abrDATAuse.Freqs_Hz(toneINDs)/1000,abrDATAuse.Thresholds_dBSPL.chinAVG(1,toneINDs)-abrDATAuse.Thresholds_dBSPL.chinAVG(1,toneINDs), ...
    abrDATAuse.Thresholds_dBSPL.chinSTD(1,toneINDs)/sqrt(length(Chins2Run)),'-o','color','b', ...
    'LineWidth',gcaLW,'MarkerSize',markerSIZE,'MarkerFaceColor','b');
hold on
% Post 
hplot(2)=errorbar(abrDATAuse.Freqs_Hz(toneINDs)/1000,abrDATAuse.Thresholds_dBSPL.chinAVG(2,toneINDs)-abrDATAuse.Thresholds_dBSPL.chinAVG(1,toneINDs), ...
    abrDATAuse.Thresholds_dBSPL.chinSTD(2,toneINDs)/sqrt(length(Chins2Run)),'-o','color','r', ...
    'LineWidth',gcaLW,'MarkerSize',markerSIZE,'MarkerFaceColor','r');
errorbar(clickPLOT_Freq_Hz/1000,abrDATAuse.Thresholds_dBSPL.chinAVG(1,click_FreqIND)-abrDATAuse.Thresholds_dBSPL.chinAVG(1,click_FreqIND), ...
    abrDATAuse.Thresholds_dBSPL.chinSTD(1,click_FreqIND)/sqrt(length(Chins2Run)),'s','color','b', ...
    'LineWidth',gcaLW,'MarkerSize',markerSIZE+2,'MarkerFaceColor','b')
errorbar(clickPLOT_Freq_Hz/1000,abrDATAuse.Thresholds_dBSPL.chinAVG(2,click_FreqIND)-abrDATAuse.Thresholds_dBSPL.chinAVG(1,click_FreqIND), ...
    abrDATAuse.Thresholds_dBSPL.chinSTD(2,click_FreqIND)/sqrt(length(Chins2Run)),'s','color','r', ...
    'LineWidth',gcaLW,'MarkerSize',markerSIZE+2,'MarkerFaceColor','r')

Y_SCALE_min=-20;
Y_SCALE_max=50;
patch([1/sqrt(2) sqrt(2) sqrt(2) 1/sqrt(2)],[Y_SCALE_min Y_SCALE_min Y_SCALE_max Y_SCALE_max], ...
    0.75*ones(1,3),'LineStyle','none')
set(gca,'children',flipud(get(gca,'children')))
legend(gca,hplot,Conds2Run,'Location','Northeast','FontSize',legendSIZE);

set(gca, 'FontSize', gcaFNTSIZE);
title(sprintf('Average ABR Threshold Shift -- %d Chins',length(Chins2Run)),'FontSize',labelFNTSIZE);
xlabel('Frequency (kHz)', 'FontSize', labelFNTSIZE);
ylabel('Threshold Shift (dB)', 'FontSize', labelFNTSIZE);
ylim([Y_SCALE_min,Y_SCALE_max]);
set(gca, 'XTick', [.1 1 10], 'XTickLabel', [.1 1 10]);
set(gca,'xscale','log');
xlim([.25 10])
% grid on
set(gca,'linew',2);
set(gca, 'Layer', 'top')  % keeps patch under axes
text(clickPLOT_Freq_Hz/1000,Y_SCALE_min*.95,'click','Color','k','FontSize',labelFNTSIZE,'units','data','HorizontalAlignment','center','VerticalAlignment','top')
hold off

print('-dtiff',strcat(filename_ABRresults,'_ThrShift'))


%% Amplitudes and Latencies
figure(3); clf
set(gcf,'units','norm','pos',[.55    0.0565    0.4375    0.8324])
%Common variables
markerSIZE=12;

%Top - Amplitudes
ax(1) = subplot(211);
for FreqIND = 1:length(abrDATAuse.HighLev_Amplitude_uV.Freqs_str)
    styleTXT= strcat(plotcolors{FreqIND},markerStyles{FreqIND},'-');
    errorbar(1+[0 (CondIND-1)/2], ...
        [abrDATAuse.HighLev_Amplitude_uV.P1.chinAVG(1,FreqIND) abrDATAuse.HighLev_Amplitude_uV.P1.chinAVG(2,FreqIND)], ...
        [abrDATAuse.HighLev_Amplitude_uV.P1.chinSTD(1,FreqIND) abrDATAuse.HighLev_Amplitude_uV.P1.chinSTD(2,FreqIND)]/sqrt(length(Chins2Run)), ...
        styleTXT,'MarkerSize',markerSIZE,'LineWidth',marker_LW)
    hold on
    errorbar(2+[0 (CondIND-1)/2], ...
        [abrDATAuse.HighLev_Amplitude_uV.N1.chinAVG(1,FreqIND) abrDATAuse.HighLev_Amplitude_uV.N1.chinAVG(2,FreqIND)], ...
        [abrDATAuse.HighLev_Amplitude_uV.N1.chinSTD(1,FreqIND) abrDATAuse.HighLev_Amplitude_uV.N1.chinSTD(2,FreqIND)]/sqrt(length(Chins2Run)), ...
        styleTXT,'MarkerSize',markerSIZE,'LineWidth',marker_LW)
    errorbar(4+[0 (CondIND-1)/2], ...
        [abrDATAuse.HighLev_Amplitude_uV.P5.chinAVG(1,FreqIND) abrDATAuse.HighLev_Amplitude_uV.P5.chinAVG(2,FreqIND)], ...
        [abrDATAuse.HighLev_Amplitude_uV.P5.chinSTD(1,FreqIND) abrDATAuse.HighLev_Amplitude_uV.P5.chinSTD(2,FreqIND)]/sqrt(length(Chins2Run)), ...
        styleTXT,'MarkerSize',markerSIZE,'LineWidth',marker_LW)
    errorbar(5+[0 (CondIND-1)/2], ...
        [abrDATAuse.HighLev_Amplitude_uV.N5.chinAVG(1,FreqIND) abrDATAuse.HighLev_Amplitude_uV.N5.chinAVG(2,FreqIND)], ...
        [abrDATAuse.HighLev_Amplitude_uV.N5.chinSTD(1,FreqIND) abrDATAuse.HighLev_Amplitude_uV.N5.chinSTD(2,FreqIND)]/sqrt(length(Chins2Run)), ...
        styleTXT,'MarkerSize',markerSIZE,'LineWidth',marker_LW)
    errorbar(7+[0 (CondIND-1)/2], ...
        [abrDATAuse.HighLev_Amplitude_uV.W1.chinAVG(1,FreqIND) abrDATAuse.HighLev_Amplitude_uV.W1.chinAVG(2,FreqIND)], ...
        [abrDATAuse.HighLev_Amplitude_uV.W1.chinSTD(1,FreqIND) abrDATAuse.HighLev_Amplitude_uV.W1.chinSTD(2,FreqIND)]/sqrt(length(Chins2Run)), ...
        styleTXT,'MarkerSize',markerSIZE,'LineWidth',marker_LW)
    errorbar(8+[0 (CondIND-1)/2], ...
        [abrDATAuse.HighLev_Amplitude_uV.W5.chinAVG(1,FreqIND) abrDATAuse.HighLev_Amplitude_uV.W5.chinAVG(2,FreqIND)], ...
        [abrDATAuse.HighLev_Amplitude_uV.W5.chinSTD(1,FreqIND) abrDATAuse.HighLev_Amplitude_uV.W5.chinSTD(2,FreqIND)]/sqrt(length(Chins2Run)), ...
        styleTXT,'MarkerSize',markerSIZE,'LineWidth',marker_LW)
    errorbar(9+[0 (CondIND-1)/2], ...
        [abrDATAuse.HighLev_Amplitude_uV.W1_W5rat.chinAVG(1,FreqIND) abrDATAuse.HighLev_Amplitude_uV.W1_W5rat.chinAVG(2,FreqIND)], ...
        [abrDATAuse.HighLev_Amplitude_uV.W1_W5rat.chinSTD(1,FreqIND) abrDATAuse.HighLev_Amplitude_uV.W1_W5rat.chinSTD(2,FreqIND)]/sqrt(length(Chins2Run)), ...
        styleTXT,'MarkerSize',markerSIZE,'LineWidth',marker_LW)
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
title(sprintf('Average ABR Amplitudes -- %d Chins',length(Chins2Run)),'FontSize',labelFNTSIZE);
ylabel('Amplitude (\muV)', 'FontSize', labelFNTSIZE,'Interpreter','tex');
set(gca, 'XTick',[1 2 4 5 7 8 9], 'XTickLabel', []);
ylim([Y_SCALE_min,Y_SCALE_max]);
xlim([0 10])
% grid on
set(gca,'linew',gcaLW);


% Bottom - Latencies
ax(2) = subplot(212);

for FreqIND = 1:length(abrDATAuse.HighLev_Amplitude_uV.Freqs_str)
    styleTXT= strcat(plotcolors{FreqIND},markerStyles{FreqIND},'-');
    errorbar(1+[0 (CondIND-1)/2], ...
        [abrDATAuse.HighLev_Latency_ms.P1.chinAVG(1,FreqIND) abrDATAuse.HighLev_Latency_ms.P1.chinAVG(2,FreqIND)], ...
        [abrDATAuse.HighLev_Latency_ms.P1.chinSTD(1,FreqIND) abrDATAuse.HighLev_Latency_ms.P1.chinSTD(2,FreqIND)]/sqrt(length(Chins2Run)), ...
        styleTXT,'MarkerSize',markerSIZE,'LineWidth',marker_LW)
    hold on
    errorbar(2+[0 (CondIND-1)/2], ...
        [abrDATAuse.HighLev_Latency_ms.N1.chinAVG(1,FreqIND) abrDATAuse.HighLev_Latency_ms.N1.chinAVG(2,FreqIND)], ...
        [abrDATAuse.HighLev_Latency_ms.N1.chinSTD(1,FreqIND) abrDATAuse.HighLev_Latency_ms.N1.chinSTD(2,FreqIND)]/sqrt(length(Chins2Run)), ...
        styleTXT,'MarkerSize',markerSIZE,'LineWidth',marker_LW)
    errorbar(4+[0 (CondIND-1)/2], ...
        [abrDATAuse.HighLev_Latency_ms.P5.chinAVG(1,FreqIND) abrDATAuse.HighLev_Latency_ms.P5.chinAVG(2,FreqIND)], ...
        [abrDATAuse.HighLev_Latency_ms.P5.chinSTD(1,FreqIND) abrDATAuse.HighLev_Latency_ms.P5.chinSTD(2,FreqIND)]/sqrt(length(Chins2Run)), ...
        styleTXT,'MarkerSize',markerSIZE,'LineWidth',marker_LW)
    errorbar(5+[0 (CondIND-1)/2], ...
        [abrDATAuse.HighLev_Latency_ms.N5.chinAVG(1,FreqIND) abrDATAuse.HighLev_Latency_ms.N5.chinAVG(2,FreqIND)], ...
        [abrDATAuse.HighLev_Latency_ms.N5.chinSTD(1,FreqIND) abrDATAuse.HighLev_Latency_ms.N5.chinSTD(2,FreqIND)]/sqrt(length(Chins2Run)), ...
        styleTXT,'MarkerSize',markerSIZE,'LineWidth',marker_LW)
    
    % prep legends
    hleg(FreqIND) = plot(NaN,NaN,styleTXT,'MarkerSize',markerSIZE,'LineWidth',marker_LW);
end
legend(gca,hleg,abrDATAuse.HighLev_Amplitude_uV.Freqs_str,'Location','Southeast','FontSize',legendSIZE);
% List condition
text(.975,.93,Conds2Run(1),'HorizontalAlignment','right','FontSize', textFNTSIZE,'units','norm')
text(.975,.85,Conds2Run(2),'HorizontalAlignment','right','FontSize', textFNTSIZE,'units','norm')

Y_SCALE_min=2;
Y_SCALE_max=9;
text(1,Y_SCALE_min,'P1','Color','b','FontSize', textFNTSIZE,'VerticalAlignment','top','HorizontalAlignment','center')
text(2,Y_SCALE_min,'N1','Color','r','FontSize', textFNTSIZE,'VerticalAlignment','top','HorizontalAlignment','center')
text(4,Y_SCALE_min,'P5','Color','b','FontSize', textFNTSIZE,'VerticalAlignment','top','HorizontalAlignment','center')
text(5,Y_SCALE_min,'N5','Color','r','FontSize', textFNTSIZE,'VerticalAlignment','top','HorizontalAlignment','center')
set(gca, 'FontSize', gcaFNTSIZE);
title(sprintf('Average ABR Latencies -- %d Chins',length(Chins2Run)),'FontSize',labelFNTSIZE);
ylabel('Latency (ms)', 'Interpreter','tex','FontSize',labelFNTSIZE);
set(gca, 'XTick',[1 2 4 5 ], 'XTickLabel', []);
ylim([Y_SCALE_min,Y_SCALE_max]);
xlim([0 10])
% grid on
set(gca,'linew',gcaLW);

orient tall
hold off

print('-dtiff',strcat(filename_ABRresults,'_Amps_Lats'))


%% Plot w1, w1/w5 Amplitudes (pre/post)
figure(4); clf
set(gcf, 'units', 'normalized', 'position', [1.2 .1 .6 .8]);
clear legendstr plotnum
XLIMITs=[1 5];
clickIND=1;
HPclickIND=7;
abrFontSize=10;
markerSIZE=8;

% w1/w5; click
YLIMITs=[0.5 4.5];
subplot(321)
freqIND=clickIND;
errorbar(2, abrDATAuse.HighLev_Amplitude_uV.W1_W5rat.chinAVG(1,freqIND), abrDATAuse.HighLev_Amplitude_uV.W1_W5rat.chinSTD(1,freqIND)/sqrt(length(Chins2Run)), ...
    'ob','MarkerSize',markerSIZE,'LineWidth',marker_LW)
hold on
errorbar(4, abrDATAuse.HighLev_Amplitude_uV.W1_W5rat.chinAVG(2,freqIND), abrDATAuse.HighLev_Amplitude_uV.W1_W5rat.chinSTD(2,freqIND)/sqrt(length(Chins2Run)), ...
    'xr','MarkerSize',markerSIZE,'LineWidth',marker_LW)
ht=title(sprintf('ABRs-- AVG DATA (n=%d; mean+-STE)',length(Chins2Run)));
set(ht,'pos',[6.0 YLIMITs(2)*1.05    0.0000])
ylim(YLIMITs)
xlim(XLIMITs)
text(.8,.9,sprintf('%s',abrDATAuse.HighLev_Amplitude_uV.Freqs_str{freqIND}),'Color','k','FontSize', abrFontSize,'VerticalAlignment','top','HorizontalAlignment','center','units','norm')
text(2,YLIMITs(1),sprintf('Pre TTS'),'Color','k','FontSize', abrFontSize,'VerticalAlignment','top','HorizontalAlignment','center')
text(4,YLIMITs(1),sprintf('Post TTS\n(2 weeks)'),'Color','k','FontSize', abrFontSize,'VerticalAlignment','top','HorizontalAlignment','center')
ylabel('w1/w5 Ratio', 'FontSize', abrFontSize);
set(gca, 'FontSize', abrFontSize);
set(gca, 'XTick',[2 4], 'XTickLabel', []);
set(gca,'linew',2);
hold off

% w1/w5; 4&8 kHz AVG = ~HPclick
subplot(322)
freqIND=HPclickIND;
errorbar(2, abrDATAuse.HighLev_Amplitude_uV.W1_W5rat.chinAVG(1,freqIND), abrDATAuse.HighLev_Amplitude_uV.W1_W5rat.chinSTD(1,freqIND)/sqrt(length(Chins2Run)), ...
    'ob','MarkerSize',markerSIZE,'LineWidth',marker_LW)
hold on
errorbar(4, abrDATAuse.HighLev_Amplitude_uV.W1_W5rat.chinAVG(2,freqIND), abrDATAuse.HighLev_Amplitude_uV.W1_W5rat.chinSTD(2,freqIND)/sqrt(length(Chins2Run)), ...
    'xr','MarkerSize',markerSIZE,'LineWidth',marker_LW)
ylim(YLIMITs)
xlim(XLIMITs)
text(.75,.9,sprintf('%s',abrDATAuse.HighLev_Amplitude_uV.Freqs_str{freqIND}),'Color','k','FontSize', abrFontSize,'VerticalAlignment','top','HorizontalAlignment','center','units','norm')
text(2,YLIMITs(1),sprintf('Pre TTS'),'Color','k','FontSize', 12,'VerticalAlignment','top','HorizontalAlignment','center')
text(4,YLIMITs(1),sprintf('Post TTS\n(2 weeks)'),'Color','k','FontSize', abrFontSize,'VerticalAlignment','top','HorizontalAlignment','center')
ylabel('w1/w5 Ratio', 'FontSize', abrFontSize);
set(gca, 'FontSize', abrFontSize);
set(gca, 'XTick',[2 4], 'XTickLabel', []);
set(gca,'linew',2);
hold off

% w1; click
YLIMITs=[0.5 2.5];
subplot(323)
freqIND=clickIND;
errorbar(2, abrDATAuse.HighLev_Amplitude_uV.W1.chinAVG(1,freqIND), abrDATAuse.HighLev_Amplitude_uV.W1.chinSTD(1,freqIND)/sqrt(length(Chins2Run)), ...
    'ob','MarkerSize',markerSIZE,'LineWidth',marker_LW)
hold on
errorbar(4, abrDATAuse.HighLev_Amplitude_uV.W1.chinAVG(2,freqIND), abrDATAuse.HighLev_Amplitude_uV.W1.chinSTD(2,freqIND)/sqrt(length(Chins2Run)), ...
    'xr','MarkerSize',markerSIZE,'LineWidth',marker_LW)
ylim(YLIMITs)
xlim(XLIMITs)
text(.8,.9,sprintf('%s',abrDATAuse.HighLev_Amplitude_uV.Freqs_str{freqIND}),'Color','k','FontSize', abrFontSize,'VerticalAlignment','top','HorizontalAlignment','center','units','norm')
text(2,YLIMITs(1),sprintf('Pre TTS'),'Color','k','FontSize', abrFontSize,'VerticalAlignment','top','HorizontalAlignment','center')
text(4,YLIMITs(1),sprintf('Post TTS\n(2 weeks)'),'Color','k','FontSize', abrFontSize,'VerticalAlignment','top','HorizontalAlignment','center')
ylabel('w1 Amplitude (\muV)', 'FontSize', abrFontSize,'Interpreter','tex');
set(gca, 'FontSize', abrFontSize);
set(gca, 'XTick',[2 4], 'XTickLabel', []);
set(gca,'linew',2);
hold off

% w1; 4&8 kHz AVG = ~HPclick
subplot(324)
freqIND=HPclickIND;
errorbar(2, abrDATAuse.HighLev_Amplitude_uV.W1.chinAVG(1,freqIND), abrDATAuse.HighLev_Amplitude_uV.W1.chinSTD(1,freqIND)/sqrt(length(Chins2Run)), ...
    'ob','MarkerSize',markerSIZE,'LineWidth',marker_LW)
hold on
errorbar(4, abrDATAuse.HighLev_Amplitude_uV.W1.chinAVG(2,freqIND), abrDATAuse.HighLev_Amplitude_uV.W1.chinSTD(2,freqIND)/sqrt(length(Chins2Run)), ...
    'xr','MarkerSize',markerSIZE,'LineWidth',marker_LW)
ylim(YLIMITs)
xlim(XLIMITs)
text(.75,.9,sprintf('%s',abrDATAuse.HighLev_Amplitude_uV.Freqs_str{freqIND}),'Color','k','FontSize', abrFontSize,'VerticalAlignment','top','HorizontalAlignment','center','units','norm')
text(2,YLIMITs(1),sprintf('Pre TTS'),'Color','k','FontSize', abrFontSize,'VerticalAlignment','top','HorizontalAlignment','center')
text(4,YLIMITs(1),sprintf('Post TTS\n(2 weeks)'),'Color','k','FontSize', abrFontSize,'VerticalAlignment','top','HorizontalAlignment','center')
ylabel('w1 Amplitude (\muV)', 'FontSize', abrFontSize,'Interpreter','tex');
set(gca, 'FontSize', abrFontSize);
set(gca, 'XTick',[2 4], 'XTickLabel', []);
set(gca,'linew',2);
hold off

% w5; click
subplot(325)
freqIND=clickIND;
errorbar(2, abrDATAuse.HighLev_Amplitude_uV.W5.chinAVG(1,freqIND), abrDATAuse.HighLev_Amplitude_uV.W5.chinSTD(1,freqIND)/sqrt(length(Chins2Run)), ...
    'ob','MarkerSize',markerSIZE,'LineWidth',marker_LW)
hold on
errorbar(4, abrDATAuse.HighLev_Amplitude_uV.W5.chinAVG(2,freqIND), abrDATAuse.HighLev_Amplitude_uV.W5.chinSTD(2,freqIND)/sqrt(length(Chins2Run)), ...
    'xr','MarkerSize',markerSIZE,'LineWidth',marker_LW)
ylim(YLIMITs)
xlim(XLIMITs)
text(.8,.9,sprintf('%s',abrDATAuse.HighLev_Amplitude_uV.Freqs_str{freqIND}),'Color','k','FontSize', abrFontSize,'VerticalAlignment','top','HorizontalAlignment','center','units','norm')
text(2,YLIMITs(1),sprintf('Pre TTS'),'Color','k','FontSize', abrFontSize,'VerticalAlignment','top','HorizontalAlignment','center')
text(4,YLIMITs(1),sprintf('Post TTS\n(2 weeks)'),'Color','k','FontSize', abrFontSize,'VerticalAlignment','top','HorizontalAlignment','center')
ylabel('w5 Amplitude (\muV)', 'FontSize', abrFontSize,'Interpreter','tex');
set(gca, 'FontSize', abrFontSize);
set(gca, 'XTick',[2 4], 'XTickLabel', []);
set(gca,'linew',2);
hold off

% w5; 4&8 kHz AVG = ~HPclick
subplot(326)
freqIND=HPclickIND;
errorbar(2, abrDATAuse.HighLev_Amplitude_uV.W5.chinAVG(1,freqIND), abrDATAuse.HighLev_Amplitude_uV.W5.chinSTD(1,freqIND)/sqrt(length(Chins2Run)), ...
    'ob','MarkerSize',markerSIZE,'LineWidth',marker_LW)
hold on
errorbar(4, abrDATAuse.HighLev_Amplitude_uV.W5.chinAVG(2,freqIND), abrDATAuse.HighLev_Amplitude_uV.W5.chinSTD(2,freqIND)/sqrt(length(Chins2Run)), ...
    'xr','MarkerSize',markerSIZE,'LineWidth',marker_LW)
ylim(YLIMITs)
xlim(XLIMITs)
text(.75,.9,sprintf('%s',abrDATAuse.HighLev_Amplitude_uV.Freqs_str{freqIND}),'Color','k','FontSize', abrFontSize,'VerticalAlignment','top','HorizontalAlignment','center','units','norm')
text(2,YLIMITs(1),sprintf('Pre TTS'),'Color','k','FontSize', abrFontSize,'VerticalAlignment','top','HorizontalAlignment','center')
text(4,YLIMITs(1),sprintf('Post TTS\n(2 weeks)'),'Color','k','FontSize', abrFontSize,'VerticalAlignment','top','HorizontalAlignment','center')
ylabel('w5 Amplitude (\muV)', 'FontSize', abrFontSize,'Interpreter','tex');
set(gca, 'FontSize', abrFontSize);
set(gca, 'XTick',[2 4], 'XTickLabel', []);
set(gca,'linew',2);
hold off

print('-dtiff',strcat(filename_ABRresults,'_w1w5amps'))

%%
return;
