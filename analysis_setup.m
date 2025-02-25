clc; close all; clear all;
reanalyze = 0; % 1 = redo analysis      0 = skip analysis
efr_level = 65; % EFR Levels = 65 or 80 dB SPL
%% ROOT Directory 
if ismac
    %ROOTdir = '/Volumes/heinz/data/UserTESTS/FA/DOD';  % data depot
    ROOTdir = '/Volumes/FefeSSD/DOD';
else
    %ROOTdir = 'Z:\data\UserTESTS\FA\DOD';  
    % data depot
    ROOTdir = 'D:\DOD'; % SSD
end
%% Chins2Run = list of subjects to analyze data
Chins2Run={'Q438','Q445','Q446','Q447','Q460','Q461','Q462','Q473','Q474','Q475','Q476','Q479','Q480','Q481','Q482','Q483','Q484','Q485','Q486','Q487','Q488','Q464'};
% NAIVE: 'Q493', 'Q494','Q495','Q499','Q500','Q503','Q504','Q505','Q506'
% BLAST: 'Q457','Q463','Q478'
% 75 kPa: 'Q457','Q478'
% 150 kPa: 'Q463'
% NOISE:'Q438','Q445','Q446','Q447','Q460','Q461','Q462','Q473','Q474','Q475','Q476','Q479','Q480','Q481','Q482','Q483','Q484','Q485','Q486','Q487','Q488','Q464'
% Group 1: 'Q438','Q445','Q446','Q447' (8hrs/5 days per week)
% Group 2: 'Q460','Q461','Q462','Q464' (10hrs/4 days per week)
% Group 3: 'Q473','Q474','Q475','Q476','Q479','Q480' (10hrs/4 days per week)
% Group 4: 'Q481','Q482','Q483','Q484','Q487','Q488' (10hrs/4 days per week)
% Group 5: 'Q485','Q486' (10hrs/4 days per week)
%% Conds2Run = list of conditions to analyze data (pre vs post)
Conds2Run = {strcat('pre',filesep,'Baseline'),strcat('post',filesep,'D7'),strcat('post',filesep,'D14'),strcat('post',filesep,'D30')};
all_Conds2Run = {strcat('pre',filesep,'Baseline'),strcat('post',filesep,'D7'),strcat('post',filesep,'D14'),strcat('post',filesep,'D30')};
plot_relative = {strcat('pre',filesep,'Baseline')};
% Baseline = strcat('pre',filesep,'Baseline')
% Week 1 = strcat('post',filesep,'D7')
% Week 2 = strcat('post',filesep,'D14')
% Week 4 = strcat('post',filesep,'D30')
%% Plot limits
ylimits_avg_oae = [-70,20];
ylimits_ind_oae = [-inf,inf];
xlimits_memr = [70,105];
ylimits_efr = [-1,1];
ylimits_ind_abr_threshold = [-inf,inf];
%ylimits_avg_abr_threshold = [-25,50];
ylimits_avg_abr_threshold = [-30,65];
ylimits_ind_abr_peaks = [0,inf];
ylimits_avg_abr_peaks = [-inf,inf];
ylimits_ind_abr_lat = [-inf,inf];
ylimits_avg_abr_lat = [-inf,inf];
shapes = ["o";"square";"diamond";"^";"v";"pentagram"];
colors = [0,114,189; 237,177,32; 126,47,142; 119,172,48; 204,0,0; 255,51,255]/255;
%% Analysis Code
cwd = pwd;
if ~isempty(plot_relative)
    idx_plot_relative = ismember(plot_relative,Conds2Run);
else
    idx_plot_relative = [];
end
[EXPname, EXPname2, EXPname3] = analysis_menu;
[DATAdir, OUTdir, CODEdir] = get_directory(ROOTdir,EXPname,EXPname2);
addpath(CODEdir);
if strcmp(EXPname,'OAE')
    filepath_searchfile = ['*',EXPname2,'*.mat'];
    datapath_searchfile = filepath_searchfile;
elseif strcmp(EXPname,'ABR')
    datapath_searchfile = '*ABR*.mat';
    switch EXPname2
        case 'Thresholds'
            filepath_searchfile = ['*',EXPname,'thresholds*.mat'];
        case 'Peaks'
            switch EXPname3
                case 'Manual'
                    filepath_searchfile = ['*',EXPname,'peaks*.mat'];
                case 'DTW'
                    filepath_searchfile = ['*',EXPname,'peaks_dtw*.mat'];
            end
    end
elseif strcmp(EXPname,'EFR')
    filepath_searchfile = '*EFR*.mat';
    datapath_searchfile = '*FFR*.mat';
else
    filepath_searchfile = ['*',EXPname,'*.mat'];
    datapath_searchfile = filepath_searchfile;
end
% Check available subjects and conditions
chinroster_file = 'DOD_ChinRoster.xlsx';
if ~isempty(search_files(OUTdir,chinroster_file).files)
    cd(OUTdir)
    chinroster_temp = readcell(chinroster_file);
    temp_idx = cellfun(@(x) any(isa(x,'missing')), chinroster_temp);
    chinroster_temp(temp_idx) = {NaN};
    temp = zeros(1,length(chinroster_temp));
    for i=3:length(chinroster_temp)
        for j=1:length(Chins2Run)
            if strcmp(chinroster_temp(i,1),Chins2Run{j})
                temp(i) = 1;
            end
        end
    end
    chins_idx = find(temp==1);
    conds_idx = zeros(size(Conds2Run));
    for i=1:length(Conds2Run)
        conds_idx(i) = find(strcmp(Conds2Run(i),all_Conds2Run));
    end
    colors = colors(conds_idx,:);
    Chins2Run = chinroster_temp(chins_idx,1);
    chinroster.ChinSex = chinroster_temp(chins_idx,2);
    switch EXPname
        case 'ABR'
            temp = chinroster_temp(:,3:6);
            chinroster.signal = temp(chins_idx,conds_idx);
        case 'EFR'
            temp = chinroster_temp(:,7:10);
            chinroster.signal = temp(chins_idx,conds_idx);
        case 'OAE'
            switch EXPname2
                case 'DPOAE'
                    temp = chinroster_temp(:,11:14);
                    chinroster.signal = temp(chins_idx,conds_idx);
                case 'SFOAE'
                    temp = chinroster_temp(:,15:18);
                    chinroster.signal = temp(chins_idx,conds_idx);
                case 'TEOAE'
                    temp = chinroster_temp(:,19:22);
                    chinroster.signal = temp(chins_idx,conds_idx);
            end
        case 'MEMR'
            temp = chinroster_temp(:,23:26);
            chinroster.signal = temp(chins_idx,conds_idx);
    end
end
% Check if RAW data has been analyzed
counter = 0;
flag = 0;
chins_idx = [];
filepath_idx = zeros(length(Chins2Run),length(Conds2Run));
datapath_idx = zeros(length(Chins2Run),length(Conds2Run));
subject_idx = zeros(length(Chins2Run),length(Conds2Run));
addpath(strcat(ROOTdir,filesep,'Code Archive'))
for ChinIND=1:length(Chins2Run)
    for CondIND=1:length(Conds2Run)
        filepath = strcat(OUTdir,filesep,EXPname,filesep,Chins2Run{ChinIND},filesep,Conds2Run{CondIND});
        datapath = strcat(DATAdir,filesep,Chins2Run{ChinIND},filesep,EXPname,filesep,Conds2Run{CondIND});
        calibpath = datapath;
        filepath_files{ChinIND,CondIND} = search_files(filepath,filepath_searchfile).files;  % analyzed raw data files available
        datapath_files{ChinIND,CondIND} = search_files(datapath,datapath_searchfile).files; % raw data files available
        filepath_dir_temp{ChinIND,CondIND} = search_files(filepath,filepath_searchfile).dir;  % analyzed raw data files available
        datapath_dir_temp{ChinIND,CondIND} = search_files(datapath,datapath_searchfile).dir; % raw data files available
        if ~isempty(filepath_files{ChinIND,CondIND})
            filepath_idx(ChinIND,CondIND) = 1;
        end
        if ~isempty(datapath_files{ChinIND,CondIND})
            datapath_idx(ChinIND,CondIND) = 1;
        end
        if strcmp(chinroster.signal(ChinIND,CondIND),'X') || strcmp(chinroster.signal(ChinIND,CondIND),'x')
            subject_idx(ChinIND,CondIND) = 1;
        end
    end
end
% Remove subjects if baseline is not present for relative to
if idx_plot_relative == 1
    chins_idx = find(subject_idx(:,idx_plot_relative) == 0);
    Chins2Run(chins_idx) = [];
    chinroster.ChinSex(chins_idx,:) = [];
    chinroster.signal(chins_idx, :) = [];
    subject_idx(chins_idx, :) = [];
    datapath_idx(chins_idx, :) = [];
    filepath_idx(chins_idx, :) = [];
    filepath_dir_temp(chins_idx, :) = [];
    datapath_dir_temp(chins_idx, :) = [];
end
% Remove timepoints that are not present
filepath_dir = cell(size(filepath_dir_temp));
datapath_dir = cell(size(datapath_dir_temp));
filepath_dir(filepath_idx==1) = filepath_dir_temp(filepath_idx==1);
datapath_dir(datapath_idx==1) = datapath_dir_temp(datapath_idx==1);
for ChinIND=1:length(Chins2Run)
    for CondIND=1:length(Conds2Run)
        file_check = filepath_idx(ChinIND,CondIND);
        data_check = datapath_idx(ChinIND,CondIND);
        subject_check = subject_idx(ChinIND,CondIND);
        condition = strsplit(Conds2Run{CondIND}, filesep);
        cd(CODEdir);
        if file_check == 0 && data_check == 1 && subject_check == 1 || reanalyze == 1  % convert RAW data for analysis for no existing analyzed file
            fprintf('\nSubject: %s (%s)\n',Chins2Run{ChinIND},Conds2Run{CondIND});
            filepath = strcat(OUTdir,filesep,EXPname,filesep,Chins2Run{ChinIND},filesep,Conds2Run{CondIND});
            datapath = datapath_dir{ChinIND,CondIND};
            calibpath = datapath;
            if ~exist(filepath, 'dir')
                fprintf('\nCreating analysis directory for %s (%s)...\n',subject, condition);
                mkdir(filepath);
            end
            switch EXPname
                case 'ABR'
                    switch EXPname2
                        case 'Thresholds'
                            abr_out = ABR_audiogram_chin(datapath,filepath,Chins2Run{ChinIND},Conds2Run,CondIND);
                        case 'Peaks'
                            switch EXPname3
                                case 'Manual'
                                    abr_peaks_setup(ROOTdir,datapath,filepath,Chins2Run{ChinIND},condition{2})
                                case 'DTW'
                                    %filepath = strcat(OUTdir,filesep,EXPname,filesep,EXPname3,filesep,condition{2});
                                    %if ~exist(filepath,'dir'), mkdir(filepath), end
                                    processClick_dtw(datapath,filepath,Chins2Run,ChinIND,Conds2Run,CondIND,colors,shapes)
                            end
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
        elseif data_check == 0 && subject_check == 1   % move files from Data/RAW directory into individual folder
            datapath = strcat(DATAdir,filesep,Chins2Run{ChinIND},filesep,EXPname,filesep,Conds2Run{CondIND});
            if ~exist(datapath, 'dir')
                fprintf('\nCreating analysis directory for %s (%s)...\n',Chins2Run{ChinIND}, Conds2Run{CondIND});
                mkdir(datapath);
            end
            cd(CODEdir)
            if ismac
                %source = '/Volumes/heinz/data/UserTESTS/FA/DOD/Data/RAW';  % data depot
                sourcepath = '/Volumes/FefeSSD/DOD/Code Archive';
            else
                %source = 'Z:\data\UserTESTS\FA\DOD\Data\RAW';   % data depot
                sourcepath = 'D:\DOD\Data\RAW'; % SSD
            end
            move_files(Chins2Run,Conds2Run,sourcepath,EXPname,DATAdir,CODEdir);
        elseif file_check == 1 && data_check == 1 && subject_check == 1
            counter = counter+1;
            if counter == sum(sum(subject_idx))
                flag = 1;
            end
            fprintf('\nLoading Data for Averaging...\nSubject: %s (%s)\n',Chins2Run{ChinIND},Conds2Run{CondIND});
            filepath = filepath_dir{ChinIND,CondIND};
            datapath = datapath_dir{ChinIND,CondIND};
            switch EXPname
                case 'ABR'
                    cd(strcat(ROOTdir,filesep,'Code Archive',filesep,'ABR'));
                    switch EXPname2
                        case 'Thresholds'
                            ABRsummary(filepath,OUTdir,Conds2Run,Chins2Run,ChinIND,CondIND,idx_plot_relative,ylimits_ind_abr_threshold,[],[],ylimits_avg_abr_threshold,[],[],colors,shapes,EXPname2,EXPname3,flag);
                        case 'Peaks'
                            switch EXPname3
                                case 'Manual'
                                    ABRsummary(filepath,OUTdir,Conds2Run,Chins2Run,ChinIND,CondIND,idx_plot_relative,[],ylimits_ind_abr_peaks,ylimits_ind_abr_lat,[],ylimits_avg_abr_peaks,ylimits_avg_abr_lat,colors,shapes,EXPname2,EXPname3,flag);
                                case 'DTW'
                                    %filepath = strcat(OUTdir,filesep,EXPname,filesep,EXPname3,filesep,condition{2});
                                    ABRsummary(filepath,OUTdir,Conds2Run,Chins2Run,ChinIND,CondIND,idx_plot_relative,[],ylimits_ind_abr_peaks,ylimits_ind_abr_lat,[],ylimits_avg_abr_peaks,ylimits_avg_abr_lat,colors,shapes,EXPname2,EXPname3,flag);
                            end
                    end
                case 'EFR'
                    cd(CODEdir)
                    EFRsummary(filepath,OUTdir,Conds2Run,Chins2Run,ChinIND,CondIND,ylimits_efr,idx_plot_relative,efr_level,shapes,colors,flag,subject_idx);
                case 'OAE'
                    cd(CODEdir)
                    switch EXPname2
                        case 'DPOAE'
                            DPsummary(filepath,OUTdir,Conds2Run,Chins2Run,ChinIND,CondIND,idx_plot_relative,ylimits_ind_oae,ylimits_avg_oae,shapes,colors,flag);
                        case 'SFOAE'
                            SFsummary(filepath,OUTdir,Conds2Run,Chins2Run,ChinIND,CondIND,idx_plot_relative,ylimits_ind_oae,ylimits_avg_oae,shapes,colors,flag);
                        case 'TEOAE'
                            TEsummary(filepath,OUTdir,Conds2Run,Chins2Run,ChinIND,CondIND,idx_plot_relative,ylimits_ind_oae,ylimits_avg_oae,shapes,colors,flag);
                    end
                case 'MEMR'
                    cd(CODEdir)
                    WBMEMRsummary(filepath,OUTdir,Conds2Run,Chins2Run,ChinIND,CondIND,idx_plot_relative,xlimits_memr,shapes,colors,flag)
            end
        end
    end
end
cd(cwd);

