clc; close all;
reanalyze = 0; % 1 = redo analysis      0 = skip analysis
%% Chins2Run = list of subjects to analyze data
Chins2Run={'Q438'};
% NAIVE: 'Q493', 'Q494','Q495','Q499','Q500','Q503','Q504','Q505','Q506'
% BLAST: 'Q457','Q463','Q478'
% 75 kPa: 'Q457','Q478'
% 150 kPa: 'Q463'
% NOISE: 'Q438','Q445','Q446','Q447','Q460','Q461','Q462','Q473','Q474','Q475','Q476','Q479','Q480','Q481','Q482','Q483','Q484','Q485','Q486','Q487','Q488','Q464'
% Group 1: 'Q438','Q445','Q446','Q447' (8hrs/5 days per week)
% Group 2: 'Q460','Q461','Q462','Q464' (10hrs/4 days per week)
% Group 3: 'Q473','Q474','Q475','Q476','Q479','Q480' (10hrs/4 days per week)
% Group 4: 'Q481','Q482','Q483','Q484','Q487','Q488' (10hrs/4 days per week)
% Group 5: 'Q485','Q486' (10hrs/4 days per week)
%% Conds2Run = list of conditions to analyze data (pre vs post)
Conds2Run = {strcat('pre',filesep,'Baseline'),strcat('post',filesep,'D7')};
plot_relative = {};
% Baseline = strcat('pre',filesep,'Baseline')
% Week 1 = strcat('post',filesep,'D7')
% Week 2 = strcat('post',filesep,'D14')
% Week 4 = strcat('post',filesep,'D30')
%% Plot limits
ylimits_avg_oae = [-25,40];
ylimits_ind_oae = [-80,60];
xlimits_memr = [50,105];
ylimits_efr = [-0.6,1.2];
ylimits_ind_abr_threshold = [0,80];
ylimits_avg_abr_threshold = [-20,20];
ylimits_ind_abr_peaks = [0,2];
ylimits_avg_abr_peaks = [-1,4];
ylimits_ind_abr_lat = [4,10];
ylimits_avg_abr_lat = [0,15];
shapes = ["o";"square";"diamond";"^";"pentagram";"v"];
colors = [0,114,189; 237,177,32; 126,47,142; 119,172,48; 204,0,0; 255,51,255]/255;
%% Analysis Code
cwd = pwd;
if ~isempty(plot_relative)
    idx_plot_relative = ismember(plot_relative,Conds2Run);
else
    idx_plot_relative = [];
end
[EXPname, EXPname2] = analysis_menu;
if ~exist('ROOTdir','var')
    uiwait(msgbox('Press OK to select root directory','Root Directory','help'));
    ROOTdir = uigetdir('', 'Select the root directory');
    addpath(strcat(ROOTdir,filesep,'Code Archive'));
end
[DATAdir, OUTdir, CODEdir] = get_directory(ROOTdir,EXPname,EXPname2);
if strcmp(EXPname,'OAE')
    searchfile = ['*',EXPname2,'*.mat'];
else
    searchfile = ['*',EXPname,'*.mat'];
end
% Check if RAW data has been converted for analysis
flag = 0;
files = cell(length(Chins2Run),length(Conds2Run));
for ChinIND=1:length(Chins2Run)
    for CondIND=1:length(Conds2Run)
        filepath = strcat(OUTdir,filesep,EXPname,filesep,Chins2Run{ChinIND},filesep,Conds2Run{CondIND});
        datapath = strcat(DATAdir,filesep,Chins2Run{ChinIND},filesep,EXPname,filesep,Conds2Run{CondIND});
        calibpath = datapath;
        files{ChinIND,CondIND} = search_files(Chins2Run{ChinIND},Conds2Run{CondIND},datapath,filepath);
        file_check =  dir(fullfile(files{ChinIND,CondIND}.dir,searchfile));
        condition = strsplit(Conds2Run{CondIND}, filesep);
        cd(CODEdir);
        if isempty(file_check) && isfolder(datapath)    % convert RAW data for analysis for no existing analyzed file
            fprintf('\nSubject: %s (%s)\n',Chins2Run{ChinIND},Conds2Run{CondIND});
            switch EXPname
                case 'ABR'
                    switch EXPname2
                        case 'Thresholds'
                            abr_out = ABR_audiogram_chin(datapath,filepath,Chins2Run{ChinIND},Conds2Run,CondIND);
                        case 'Peaks'
                            abr_peaks_setup(ROOTdir,datapath,filepath,Chins2Run{ChinIND},condition{2})
                    end
                case 'EFR'
                    switch EXPname2
                        case 'AM/FM'
                            %% TBD
                        case 'RAM'
                            EFRanalysis(datapath,filepath,Chins2Run{ChinIND},condition{2});
                            cd(CODEdir)
                    end
                case 'OAE'
                    switch EXPname2
                        case 'DPOAE'
                            DPanalysis(datapath,filepath,Chins2Run{ChinIND},condition{2});
                        case 'SFOAE'
                            SFanalysis(datapath,filepath,Chins2Run{ChinIND},condition{2});
                        case 'TEOAE'
                            TEanalysis(datapath,filepath,Chins2Run{ChinIND},condition{2});
                    end
                case 'MEMR'
                    WBMEMRanalysis(datapath,filepath,Chins2Run{ChinIND},condition{2});
            end
        elseif ~isempty(file_check) && isfolder(datapath) && reanalyze == 1     % convert RAW data for existing analyzed file
            fprintf('\nSubject: %s (%s)\n',Chins2Run{ChinIND},Conds2Run{CondIND});
            switch EXPname
                case 'ABR'
                    switch EXPname2
                        case 'Thresholds'
                            abr_out = ABR_audiogram_chin(datapath,filepath,Chins2Run{ChinIND},Conds2Run,CondIND);
                        case 'Peaks'
                            abr_peaks_setup(ROOTdir,datapath,filepath,Chins2Run{ChinIND},condition)
                    end
                case 'EFR'
                    switch EXPname2
                        case 'AM/FM'
                            %% TBD
                        case 'RAM'
                            EFRanalysis(datapath,filepath,Chins2Run{ChinIND},condition{2});
                            cd(CODEdir)
                    end
                case 'OAE'
                    switch EXPname2
                        case 'DPOAE'
                            DPanalysis(datapath,filepath,Chins2Run{ChinIND},condition{2});
                        case 'SFOAE'
                            SFanalysis(datapath,filepath,Chins2Run{ChinIND},condition{2});
                        case 'TEOAE'
                            TEanalysis(datapath,filepath,Chins2Run{ChinIND},condition{2});
                    end
                case 'MEMR'
                    WBMEMRanalysis(datapath,filepath,Chins2Run{ChinIND},condition{2});
            end
        else
            fprintf('\nLoading Data for Averaging...\nSubject: %s (%s)\n',Chins2Run{ChinIND},Conds2Run{CondIND});
            switch EXPname
                case 'ABR'
                    cd(strcat(ROOTdir,filesep,'Code Archive',filesep,'ABR'));
                    switch EXPname2
                        case 'Thresholds'
                            ABRsummary(filepath,OUTdir,Conds2Run,Chins2Run,ChinIND,CondIND,idx_plot_relative,ylimits_ind_abr_threshold,[],[],ylimits_avg_abr_threshold,[],[],colors,shapes,'Thresholds');
                        case 'Peaks'
                            ABRsummary(filepath,OUTdir,Conds2Run,Chins2Run,ChinIND,CondIND,idx_plot_relative,[],ylimits_ind_abr_peaks,ylimits_ind_abr_lat,[],ylimits_avg_abr_peaks,ylimits_avg_abr_lat,colors,shapes,'Peaks');
                        case 'Waveforms'
                            ABRwaveform()
                    end
                case 'EFR'
                    cd(CODEdir)
                    if flag == 0
                        answer = questdlg('Select EFR level:', ...
                            'EFR Level', ...
                            '65 dB SPL','80 dB SPL','80 dB SPL');
                        % Handle response
                        switch answer
                            case '65 dB SPL'
                                efr_level = 65;
                            case '80 dB SPL'
                                efr_level = 80;
                        end
                        flag = 1;
                    end
                    EFRsummary(filepath,OUTdir,Conds2Run,Chins2Run,ChinIND,CondIND,ylimits_efr,idx_plot_relative,efr_level,shapes,colors);
                case 'OAE'
                    cd(CODEdir)
                    switch EXPname2
                        case 'DPOAE'
                            DPsummary(filepath,OUTdir,Conds2Run,Chins2Run,ChinIND,CondIND,idx_plot_relative,ylimits_ind_oae,ylimits_avg_oae,shapes,colors);
                        case 'SFOAE'
                            SFsummary(filepath,OUTdir,Conds2Run,Chins2Run,ChinIND,CondIND,idx_plot_relative,ylimits_ind_oae,ylimits_avg_oae,shapes,colors);
                        case 'TEOAE'
                            TEsummary(filepath,OUTdir,Conds2Run,Chins2Run,ChinIND,CondIND,idx_plot_relative,ylimits_ind_oae,ylimits_avg_oae,shapes,colors);
                    end
                case 'MEMR'
                    cd(CODEdir)
                    WBMEMRsummary(filepath,OUTdir,Conds2Run,Chins2Run,ChinIND,CondIND,idx_plot_relative,xlimits_memr,shapes,colors)
            end
        end
    end
end
cd(cwd);

