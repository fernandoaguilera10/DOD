function analysis_run(ROOTdir,USERdir,Chins2Run,Conds2Run,chinroster_filename,chinroster_sheet,plot_relative_flag,reanalyze)
cwd = pwd;
%% Define plotting parameters
shapes = ["v";"square";"diamond";"^";"o";">";"pentagram";"*";"x"];
colors = [0 0 0; 255 190 25; 77 192 181; 101 116 205; 149 97 226; 52 144 220; 246 109 155; 246 153 63; 227 52 47]/255;
if plot_relative_flag == 1
    plot_relative = Conds2Run(1);
else
    plot_relative = {};
end
if ~isempty(plot_relative)
    idx_plot_relative = ismember(plot_relative,Conds2Run);
else
    idx_plot_relative = [];
end
[EXPname, EXPname2, EXPname3] = analysis_menu; % select analysis type: ABR, EFR, OAE, MEMR
limits = plot_limits(EXPname,EXPname2,idx_plot_relative); % define plot limits
[DATAdir, OUTdir, CODEdir,PRIVATEdir] = get_directory(ROOTdir,USERdir,EXPname,EXPname2); % define subdirectories based on ROOTdir
addpath(genpath(CODEdir));
%% Define search filename to load data
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
    efr_level_temp = questdlg('Select EFR level:', ...
            'EFR Level', ...
            '65 dB SPL','80 dB SPL','80 dB SPL');
    efr_level = str2double(efr_level_temp(1:2));
    switch EXPname2
        case 'dAM'
            filepath_searchfile = '*EFR_dAM*.mat';
            datapath_searchfile = '*FFR_*AMFM*.mat';
        case 'RAM'
            filepath_searchfile = '*EFR_RAM*.mat';
            datapath_searchfile = '*FFR_RAM*.mat';
    end
else
    filepath_searchfile = ['*',EXPname,'*.mat'];
    datapath_searchfile = filepath_searchfile;
end

%% Check available subjects and conditions based on spreadsheet (chinroster_filename) and sheet (chinroster_sheet)
if ~isempty(search_files(OUTdir,chinroster_filename).files)
    cd(OUTdir)
    chinroster_temp = readcell(chinroster_filename,'Sheet',chinroster_sheet);
    temp_idx = cellfun(@(x) any(isa(x,'missing')), chinroster_temp);
    chinroster_temp(temp_idx) = {NaN};
    [temp_rows,temp_cols] = size(chinroster_temp);
    temp = zeros(1,temp_rows);
    % Define subjects to include
    for i=1:temp_rows
        for j=1:length(Chins2Run)
            if strcmp(chinroster_temp(i,1),Chins2Run{j})
                temp(i) = 1;
            end
        end
    end
    % Define conditions to include
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

%% Check if RAW data has been analyzed
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
%% Remove subjects if baseline is not present for relative to
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
                        case 'dAM'
                            dAManalysis(datapath,filepath,Chins2Run{ChinIND},condition{2});
                            cd(CODEdir)
                        case 'RAM'
                            RAManalysis(datapath,filepath,Chins2Run{ChinIND},condition{2});
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
            sourcepath = strcat(DATAdir,filesep,'RAW');
            cd(CODEdir)
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
                            ABRsummary(filepath,OUTdir,PRIVATEdir,Conds2Run,Chins2Run,all_Conds2Run,ChinIND,CondIND,idx_plot_relative,limits.ind,[],[],limits.avg,[],[],colors,shapes,EXPname2,EXPname3,flag,conds_idx);                        case 'Peaks'
                            switch EXPname3
                                case 'Manual'
                                    ABRsummary(filepath,OUTdir,PRIVATEdir,Conds2Run,Chins2Run,all_Conds2Run,ChinIND,CondIND,idx_plot_relative,[],limits.ind.peaks,limits.ind.latency,[],limits.avg.peaks,limits.avg.latency,colors,shapes,EXPname2,EXPname3,flag,conds_idx);
                                case 'DTW'
                                    %filepath = strcat(OUTdir,filesep,EXPname,filesep,EXPname3,filesep,condition{2});
                                    ABRsummary(filepath,OUTdir,Conds2Run,Chins2Run,all_Conds2Run,ChinIND,CondIND,idx_plot_relative,[],limits.ind.peaks,limits.ind.latency,[],limits.avg.peaks,limits.avg.latency,colors,shapes,EXPname2,EXPname3,flag,conds_idx);
                            end
                    end
                case 'EFR'
                    switch EXPname2
                        case 'dAM'
                            cd(CODEdir)
                            dAMsummary(filepath,OUTdir,PRIVATEdir,Conds2Run,Chins2Run,all_Conds2Run,ChinIND,CondIND,limits.avg,idx_plot_relative,efr_level,shapes,colors,flag,subject_idx,conds_idx);
                        case 'RAM'
                            cd(CODEdir)
                            RAMsummary(filepath,OUTdir,PRIVATEdir,Conds2Run,Chins2Run,all_Conds2Run,ChinIND,CondIND,limits.avg,idx_plot_relative,efr_level,shapes,colors,flag,subject_idx,conds_idx);
                    end
                case 'OAE'
                    cd(CODEdir)
                    switch EXPname2
                        case 'DPOAE'
                            DPsummary(filepath,OUTdir,PRIVATEdir,Conds2Run,Chins2Run,all_Conds2Run,ChinIND,CondIND,idx_plot_relative,limits.ind,limits.avg,shapes,colors,flag,conds_idx);
                        case 'SFOAE'
                            SFSummary(filepath,OUTdir,PRIVATEdir,Conds2Run,Chins2Run,all_Conds2Run,ChinIND,CondIND,idx_plot_relative,limits.ind,limits.avg,shapes,colors,flag,conds_idx);
                        case 'TEOAE'
                            TEsummary(filepath,OUTdir,PRIVATEdir,Conds2Run,Chins2Run,all_Conds2Run,ChinIND,CondIND,idx_plot_relative,limits.ind,limits.avg,shapes,colors,flag,conds_idx);
                    end
                case 'MEMR'
                    cd(CODEdir)
                    WBMEMRsummary(filepath,OUTdir,PRIVATEdir,Conds2Run,Chins2Run,all_Conds2Run,ChinIND,CondIND,idx_plot_relative,limits.avg,shapes,colors,flag,conds_idx)
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
end