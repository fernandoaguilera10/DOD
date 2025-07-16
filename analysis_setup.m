clc; close all; clear all; warning off;
exposure_group = 'BLAST';   % 'NOISE' or 'BLAST'
plot_relative_flag = 0;     % Relative to Baseline:  Yes = 1   or  No = 0
publish_flag = 0;           % Publish PDF Report:    Yes = 1   or  No = 0     NOT WORKING, NEED TO FIX IT!
reanalyze = 0;              % 1 = redo analysis      0 = skip analysis
efr_level = 80;             % Average EFR Levels: 65 or 80 dB SPL
shapes = ["v";"square";"diamond";"^";"o";">";"pentagram";"*";"x"];
colors = [0 0 0; 255 190 25; 77 192 181; 101 116 205; 149 97 226; 52 144 220; 246 109 155; 246 153 63; 227 52 47]/255;
%% Plot limits
% OAE
ylimits_avg_oae = [-60,60];
ylimits_ind_oae = [-60,60];
% MEMR
xlimits_memr = [70,105];
% EFR
ylimits_efr = [0,1.1];
% ABR - Thresholds
ylimits_ind_abr_threshold = [0,80];
ylimits_avg_abr_threshold = [0,55];
% ABR - Peaks
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
    ROOTdir = 'D:\DOD'; % SSD
    %ROOTdir = 'F:\DOD'; % NEL2
    %ROOTdir = 'E:\DOD'; % LYLE 3035 (Analysis)
end
%% Subjects and Conditions
chinroster_file = 'DOD_ChinRoster.xlsx';    % saved under OUTdir (i.e. Analysis)
if strcmp(exposure_group,'BLAST')
    Conds2Run = {strcat('pre',filesep,'Baseline'),strcat('post',filesep,'D3'),strcat('post',filesep,'D14'),strcat('post',filesep,'D28'),strcat('post',filesep,'D56')};
    Chins2Run={'Q539','Q542','Q543'};
    % Group 0 ALL: 'Q457','Q463','Q478','Q493','Q494','Q499','Q500','Q503'
        % 75 kPa: 'Q457','Q478','Q493','Q499','Q500'
            % Head Free: 'Q457','Q478','Q493','Q500'
        % 150 kPa: 'Q463','Q494','Q503'
            % Head Free: 'Q463','Q494'
        % Group 1 (150 kPa w/earplugs + bite bar):'Q537','Q538','Q540','Q541','Q539','Q542','Q543'
elseif strcmp(exposure_group,'NOISE')
    Conds2Run = {strcat('pre',filesep,'Baseline'),strcat('post',filesep,'D7'),strcat('post',filesep,'D14'),strcat('post',filesep,'D30')};
    Chins2Run={'Q460','Q461','Q462','Q464','Q473','Q474','Q475','Q476','Q479','Q480','Q481','Q482','Q483','Q484','Q485','Q486','Q487','Q488','Q504','Q505'};
    % ALL: 'Q438','Q445','Q446','Q447','Q460','Q461','Q462','Q464','Q473','Q474','Q475','Q476','Q479','Q480','Q481','Q482','Q483','Q484','Q485','Q486','Q487','Q488','Q504','Q505'
        % Group 0: 'Q438','Q445','Q446','Q447' (8hrs/5 days per week)
        % Group 1: 'Q460','Q461','Q462','Q464' (10hrs/4 days per week)
        % Group 2: 'Q473','Q474','Q475','Q476','Q479','Q480' (10hrs/4 days per week)
        % Group 3: 'Q481','Q482','Q483','Q484','Q487','Q488' (10hrs/4 days per week)
        % Group 4: 'Q485','Q486' (10hrs/4 days per week)
        % GROUP 5: 'Q504','Q505' (10hrs/4 days per week)
end
if plot_relative_flag == 1
    plot_relative = {strcat('pre',filesep,'Baseline')};
else
    plot_relative = {};
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
    conds_idx = zeros(size(all_Conds2Run));
    for i=1:length(Conds2Run)
        for j=1:length(all_Conds2Run)
             if strcmp(Conds2Run(i),all_Conds2Run(j))
                 conds_idx(j) = j;
             end
        end
    end
    Chins2Run = chinroster_temp(chins_idx,1);
    chinroster.ChinSex = chinroster_temp(chins_idx,2);
    switch EXPname
        case 'ABR'
            range = col_idx(1):col_idx(1)+conds_length;
            temp = chinroster_temp(:,range);
            chinroster.signal = temp(chins_idx,nonzeros(conds_idx));
        case 'EFR'
            range = col_idx(2):col_idx(2)+conds_length;
            temp = chinroster_temp(:,range);
            chinroster.signal = temp(chins_idx,nonzeros(conds_idx));
        case 'OAE'
            switch EXPname2
                case 'DPOAE'
                    range = col_idx(3):col_idx(3)+conds_length;
                    temp = chinroster_temp(:,range);
                    chinroster.signal = temp(chins_idx,nonzeros(conds_idx));
                case 'SFOAE'
                    range = col_idx(4):col_idx(4)+conds_length;
                    temp = chinroster_temp(:,range);
                    chinroster.signal = temp(chins_idx,nonzeros(conds_idx));
                case 'TEOAE'
                    range = col_idx(5):col_idx(5)+conds_length;
                    temp = chinroster_temp(:,range);
                    chinroster.signal = temp(chins_idx,nonzeros(conds_idx));
            end
        case 'MEMR'
            range = col_idx(6):col_idx(6)+conds_length;
            temp = chinroster_temp(:,range);
            chinroster.signal = temp(chins_idx,nonzeros(conds_idx));
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
define_global_vars(Chins2Run,all_Conds2Run,EXPname,EXPname2);
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
                            abr_out = ABR_audiogram_chin(datapath,filepath,Chins2Run{ChinIND},all_Conds2Run,CondIND);
                        case 'Peaks'
                            switch EXPname3
                                case 'Manual'
                                    abr_peaks_setup(ROOTdir,CODEdir,datapath,filepath,Chins2Run{ChinIND},condition{2})
                                case 'DTW'
                                    %filepath = strcat(OUTdir,filesep,EXPname,filesep,EXPname3,filesep,condition{2});
                                    %if ~exist(filepath,'dir'), mkdir(filepath), end
                                    processClick_dtw(datapath,filepath,Chins2Run,ChinIND,Conds2Run,CondIND,colors,shapes)
                            end
                    end
                case 'EFR'
                    switch EXPname2
                        case 'AM/FM'
                            % TBD
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
                %sourcepath = 'E:\DOD\Data\RAW'; % LYLE 3035 (Analysis)
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
                    filename = 'MEMR_Average';
            end
            flag = -1;
        end
    end
end
cd(cwd);
%% Analysis Summary
Conds2Run = all_Conds2Run;
if flag == -1
    summary_idx = zeros(length(Chins2Run),length(Conds2Run));
    for i=1:size(summary_idx,1)
        for j=1:size(summary_idx,2)
            if filepath_idx(i,j) == 1 && subject_idx(i,j) == 1
                summary_idx(i,j) = 1;
            end
        end
    end
    summary = cell(length(Chins2Run),length(Conds2Run)+1);
    for i=1:size(summary,1)
        for j=2:size(summary,2)
            if summary_idx(i,j-1) == 1
                summary(i,j) = Conds2Run(j-1);
            end
            if j==2
                summary(i,j-1) = Chins2Run(i);
            end
        end
    end
    % Output
    fprintf('\n\nANALYSIS SUMMARY - %s (%s):\n\n', EXPname, EXPname2);
    fprintf('%-10s', 'Subject');
    for j = 1:length(Conds2Run)
        if strcmpi(all_temp{j}, 'Baseline')
            fprintf('%-10s', 'B');
        else
            fprintf('%-10s', all_temp{j});
        end
    end
    fprintf('\n');
    for i = 1:size(summary,1)
        fprintf('%-10s', summary{i,1});
        for j = 2:size(summary,2)
            if ~isempty(summary{i,j})
                fprintf('%-10s', 'YES');
            else
                fprintf('%-10s', 'NO');
            end
        end
        fprintf('\n');
    end
end