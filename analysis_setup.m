clc; close all; clear all;
exposure_group = 'BLAST'; % 'NOISE' or 'BLAST'
plot_relative = {};
reanalyze = 0; % 1 = redo analysis      0 = skip analysis
efr_level = 65; % EFR Levels = 65 or 80 dB SPL
shapes = ["o";"square";"diamond";"^";"v";">";"pentagram"];
colors = [0,114,189; 237,177,32; 126,47,142; 119,172,48; 204,0,0; 255,51,255; 217 83 25]/255;
%% Plot limits
ylimits_avg_oae = [-60,60];
ylimits_ind_oae = [-60,60];
xlimits_memr = [70,105];
ylimits_efr = [0,1.3];
ylimits_ind_abr_threshold = [0,40];
ylimits_avg_abr_threshold = [0,40];
ylimits_ind_abr_peaks = [0,inf];
ylimits_avg_abr_peaks = [-inf,inf];
ylimits_ind_abr_lat = [-inf,inf];
ylimits_avg_abr_lat = [-inf,inf];
%% ROOT Directory
if ismac
    %ROOTdir = '/Volumes/heinz/data/UserTESTS/FA/DOD';  % data depot
    ROOTdir = '/Volumes/FefeSSD/DOD';
else
    %ROOTdir = 'Z:\data\UserTESTS\FA\DOD'; % data depot
    %ROOTdir = 'D:\DOD'; % SSD
    ROOTdir = 'F:\DOD'; % NEL2
end
%% Subjects and Conditions
if strcmp(exposure_group,'BLAST')
    Conds2Run = {strcat('pre',filesep,'Baseline'),strcat('post',filesep,'D3'),strcat('post',filesep,'D15'),strcat('post',filesep,'D43'),strcat('post',filesep,'D92'),strcat('post',filesep,'D107'),strcat('post',filesep,'D120')};
    Chins2Run={'Q463','Q494'};
    % BLAST: 'Q457','Q463','Q478','Q493','Q494'
    % 75 kPa: 'Q457','Q478','Q493'
    % 150 kPa: 'Q463','Q494'
elseif strcmp(exposure_group,'NOISE')
    Conds2Run = {strcat('pre',filesep,'Baseline'),strcat('post',filesep,'D7'),strcat('post',filesep,'D14'),strcat('post',filesep,'D30')};
    Chins2Run={'Q438','Q445','Q446','Q447','Q460','Q461','Q462','Q464','Q473','Q474','Q475','Q476','Q479','Q480','Q481','Q482','Q483','Q484','Q485','Q486','Q487','Q488'};
    % Group 1: 'Q438','Q445','Q446','Q447' (8hrs/5 days per week)
    % Group 2: 'Q460','Q461','Q462','Q464' (10hrs/4 days per week)
    % Group 3: 'Q473','Q474','Q475','Q476','Q479','Q480' (10hrs/4 days per week)
    % Group 4: 'Q481','Q482','Q483','Q484','Q487','Q488' (10hrs/4 days per week)
    % Group 5: 'Q485','Q486' (10hrs/4 days per week)
end
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
    chinroster_temp = readcell(chinroster_file,'Sheet',exposure_group);
    temp_idx = cellfun(@(x) any(isa(x,'missing')), chinroster_temp);
    chinroster_temp(temp_idx) = {NaN};
    [temp_rows,temp_cols] = size(chinroster_temp);
    temp = zeros(1,temp_rows);
    % Define rows for subjects to include
    for i=1:temp_rows
        for j=1:length(Chins2Run)
            if strcmp(chinroster_temp(i,1),Chins2Run{j})
                temp(i) = 1;
            end
        end
    end
    % Define cols for conditions to include
    col_idx = zeros(1,temp_cols);
    for i=1:temp_rows
        for j=1:temp_cols
            if strcmp(chinroster_temp(i,j),'Baseline') || strcmp(chinroster_temp(i,j),'B')
                col_idx(j) = 1;
                row_idx = i;
            end
        end
    end
    col_idx = find(col_idx == 1);
    conds_length = col_idx(2)-col_idx(1)-1;
    all_temp = chinroster_temp(row_idx,col_idx(1):col_idx(1)+conds_length);
    for i=1:length(all_temp)
        if strcmp(all_temp{i},'Baseline') || strcmp(all_temp{i},'B')
            all_Conds2Run{i} = strcat('pre',filesep,all_temp{i});
        else
            all_Conds2Run{i} = strcat('post',filesep,all_temp{i});
        end
    end
    chins_idx = find(temp==1);
    conds_idx = zeros(size(Conds2Run));
    for i=1:length(Conds2Run)
        conds_idx(i) = find(strcmp(Conds2Run(i),all_Conds2Run));
    end
    Chins2Run = chinroster_temp(chins_idx,1);
    chinroster.ChinSex = chinroster_temp(chins_idx,2);
    switch EXPname
        case 'ABR'
            range = col_idx(1):col_idx(1)+conds_length;
            temp = chinroster_temp(:,range);
            chinroster.signal = temp(chins_idx,conds_idx);
        case 'EFR'
            range = col_idx(2):col_idx(2)+conds_length;
            temp = chinroster_temp(:,range);
            chinroster.signal = temp(chins_idx,conds_idx);
        case 'OAE'
            switch EXPname2
                case 'DPOAE'
                    range = col_idx(3):col_idx(3)+conds_length;
                    temp = chinroster_temp(:,range);
                    chinroster.signal = temp(chins_idx,conds_idx);
                case 'SFOAE'
                    range = col_idx(4):col_idx(4)+conds_length;
                    temp = chinroster_temp(:,range);
                    chinroster.signal = temp(chins_idx,conds_idx);
                case 'TEOAE'
                    range = col_idx(5):col_idx(5)+conds_length;
                    temp = chinroster_temp(:,range);
                    chinroster.signal = temp(chins_idx,conds_idx);
            end
        case 'MEMR'
            range = col_idx(6):col_idx(6)+conds_length;
            temp = chinroster_temp(:,range);
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
    conds_idx = find(subject_idx(ChinIND,:)==1);
    Conds2Run = all_Conds2Run(conds_idx);
    for i=1:length(conds_idx)
        CondIND = conds_idx(i);
        file_check = filepath_idx(ChinIND,CondIND);
        data_check = datapath_idx(ChinIND,CondIND);
        subject_check = subject_idx(ChinIND,CondIND);
        condition = strsplit(all_Conds2Run{CondIND}, filesep);
        cd(CODEdir);
        if file_check == 0 && data_check == 1 && subject_check == 1 || reanalyze == 1  % convert RAW data for analysis for no existing analyzed file
            fprintf('\nSubject: %s (%s)\n',Chins2Run{ChinIND},all_Conds2Run{CondIND});
            filepath = strcat(OUTdir,filesep,EXPname,filesep,Chins2Run{ChinIND},filesep,all_Conds2Run{CondIND});
            datapath = datapath_dir{ChinIND,CondIND};
            calibpath = datapath;
            if ~exist(filepath, 'dir')
                fprintf('\nCreating analysis directory for %s (%s)...\n',Chins2Run{ChinIND},all_Conds2Run{CondIND});
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
            datapath = strcat(DATAdir,filesep,Chins2Run{ChinIND},filesep,EXPname,filesep,all_Conds2Run{CondIND});
            if ~exist(datapath, 'dir')
                fprintf('\nCreating analysis directory for %s (%s)...\n',Chins2Run{ChinIND},all_Conds2Run{CondIND});
                mkdir(datapath);
            end
            cd(CODEdir)
            if ismac
                %sourcepath = '/Volumes/heinz/data/UserTESTS/FA/DOD/Data/RAW';  % data depot
                sourcepath = '/Volumes/FefeSSD/DOD/Data/RAW';
            else
                %sourcepath = 'Z:\data\UserTESTS\FA\DOD\Data\RAW';   % data depot
                sourcepath = 'D:\DOD\Data\RAW'; % SSD
            end
            move_files(Chins2Run,all_Conds2Run,ChinIND,CondIND,sourcepath,EXPname,DATAdir,CODEdir);
        elseif file_check == 1 && data_check == 1 && subject_check == 1 || flag == 1
            counter = counter+1;
            if counter == sum(sum(subject_idx))
                flag = 1;
            end
            fprintf('\nLoading Data for Averaging...\nSubject: %s (%s)\n',Chins2Run{ChinIND},all_Conds2Run{CondIND});
            filepath = filepath_dir{ChinIND,CondIND};
            datapath = datapath_dir{ChinIND,CondIND};
            switch EXPname
                case 'ABR'
                    cd(strcat(ROOTdir,filesep,'Code Archive',filesep,'ABR'));
                    switch EXPname2
                        case 'Thresholds'
                            ABRsummary(filepath,OUTdir,Conds2Run,Chins2Run,all_Conds2Run,ChinIND,CondIND,idx_plot_relative,ylimits_ind_abr_threshold,[],[],ylimits_avg_abr_threshold,[],[],colors,shapes,EXPname2,EXPname3,flag,conds_idx);                        case 'Peaks'
                            switch EXPname3
                                case 'Manual'
                                    ABRsummary(filepath,OUTdir,Conds2Run,Chins2Run,all_Conds2Run,ChinIND,CondIND,idx_plot_relative,[],ylimits_ind_abr_peaks,ylimits_ind_abr_lat,[],ylimits_avg_abr_peaks,ylimits_avg_abr_lat,colors,shapes,EXPname2,EXPname3,flag,conds_idx);
                                case 'DTW'
                                    %filepath = strcat(OUTdir,filesep,EXPname,filesep,EXPname3,filesep,condition{2});
                                    ABRsummary(filepath,OUTdir,Conds2Run,Chins2Run,all_Conds2Run,ChinIND,CondIND,idx_plot_relative,[],ylimits_ind_abr_peaks,ylimits_ind_abr_lat,[],ylimits_avg_abr_peaks,ylimits_avg_abr_lat,colors,shapes,EXPname2,EXPname3,flag,conds_idx);
                            end
                    end
                case 'EFR'
                    cd(CODEdir)
                    EFRsummary(filepath,OUTdir,Conds2Run,Chins2Run,all_Conds2Run,ChinIND,CondIND,ylimits_efr,idx_plot_relative,efr_level,shapes,colors,flag,subject_idx,conds_idx);
                case 'OAE'
                    cd(CODEdir)
                    switch EXPname2
                        case 'DPOAE'
                            DPsummary(filepath,OUTdir,Conds2Run,Chins2Run,all_Conds2Run,ChinIND,CondIND,idx_plot_relative,ylimits_ind_oae,ylimits_avg_oae,shapes,colors,flag,conds_idx);
                        case 'SFOAE'
                            SFSummary(filepath,OUTdir,Conds2Run,Chins2Run,all_Conds2Run,ChinIND,CondIND,idx_plot_relative,ylimits_ind_oae,ylimits_avg_oae,shapes,colors,flag,conds_idx);
                        case 'TEOAE'
                            TEsummary(filepath,OUTdir,Conds2Run,Chins2Run,all_Conds2Run,ChinIND,CondIND,idx_plot_relative,ylimits_ind_oae,ylimits_avg_oae,shapes,colors,flag,conds_idx);
                    end
                case 'MEMR'
                    cd(CODEdir)
                    WBMEMRsummary(filepath,OUTdir,Conds2Run,Chins2Run,all_Conds2Run,ChinIND,CondIND,idx_plot_relative,xlimits_memr,shapes,colors,flag,conds_idx)
            end
            flag = -1;
        end
    end
end
cd(cwd);

