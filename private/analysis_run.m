function analysis_run(ROOTdir,Chins2Run,Conds2Run,chinroster_filename,chinroster_sheet,plot_relative_flag,reanalyze,EXPname_in,EXPname2_in,show_figs_in,embed_fns_in)
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
if nargin >= 8 && ~isempty(EXPname_in)
    EXPname  = EXPname_in;
    EXPname2 = EXPname2_in;
else
    [EXPname, EXPname2] = analysis_menu; % select analysis type: ABR, EFR, OAE, MEMR
end
% Figure visibility flags (default: hide analysis figs, show ind + avg)
if nargin >= 10 && ~isempty(show_figs_in)
    show_figs = show_figs_in;
else
    show_figs.analysis = false;
    show_figs.ind      = true;
    show_figs.avg      = true;
end
% In-app embedding: when embed_fns is supplied, force all figures invisible
% so they get routed into the app tabs instead of floating windows.
use_embed = nargin >= 11 && ~isempty(embed_fns_in) && isstruct(embed_fns_in);
if use_embed
    embed_fns         = embed_fns_in;
    show_figs.analysis = false;
    show_figs.ind      = false;
    show_figs.avg      = false;
end
limits = plot_limits(EXPname,EXPname2,idx_plot_relative); % define plot limits
[DATAdir, OUTdir, CODEdir,PRIVATEdir] = get_directory(ROOTdir,EXPname,EXPname2); % define subdirectories based on ROOTdir
addpath(genpath(CODEdir));
%% Define search filename to load data
if strcmp(EXPname,'OAE')
    filepath_searchfile = ['*',EXPname2,'*.mat'];
    datapath_searchfile = filepath_searchfile;
elseif strcmp(EXPname,'ABR')
    datapath_searchfile = '*ABR*.mat';
    %abr_freq = [0 0.5 1 2 4 8]*10^3;
    abr_freq = [0]*10^3;
    abr_levels = [80 70 60 50 40];
    switch EXPname2
        case 'Thresholds'
            filepath_searchfile = ['*',EXPname,'thresholds*.mat'];
        case 'Peaks'
            filepath_searchfile = ['*',EXPname,'peaks_dtw*.mat'];
    end
elseif strcmp(EXPname,'EFR')
    efr_levels = [];   % detected automatically per subject/condition from saved filenames
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
        case 'EFR'
            range = col_idx(2):col_idx(2)+conds_length;
        case 'OAE'
            switch EXPname2
                case 'DPOAE'
                    range = col_idx(3):col_idx(3)+conds_length;
                case 'SFOAE'
                    range = col_idx(4):col_idx(4)+conds_length;
                case 'TEOAE'
                    range = col_idx(5):col_idx(5)+conds_length;
            end
        case 'MEMR'
            range = col_idx(6):col_idx(6)+conds_length;
    end
    temp = chinroster_temp(:,range);
    chinroster.signal = temp(chins_idx,:);
end

%% Check if RAW data has been analyzed
counter = 0;
flag = 0;
chins_idx = [];
filepath_idx = zeros(length(Chins2Run),length(all_Conds2Run));
datapath_idx = zeros(length(Chins2Run),length(all_Conds2Run));
subject_idx = zeros(length(Chins2Run),length(all_Conds2Run));
addpath(strcat(ROOTdir,filesep,'Code Archive'))
for ChinIND=1:length(Chins2Run)
    for CondIND=1:length(all_Conds2Run)
        filepath = strcat(OUTdir,filesep,EXPname,filesep,Chins2Run{ChinIND},filesep,all_Conds2Run{CondIND});
        datapath = strcat(DATAdir,filesep,Chins2Run{ChinIND},filesep,EXPname,filesep,all_Conds2Run{CondIND});
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
            if ~isempty(find(conds_idx==CondIND))
                subject_idx(ChinIND,CondIND) = 1;
            end
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

% Estimate NEL delay
if strcmp(EXPname,'ABR') && strcmp(EXPname2,'Peaks')
    nel_delay_file = fullfile(OUTdir,'ABR',['ABR_NEL_delay_' chinroster_sheet '.mat']);
    % Always initialise for current subjects/timepoints
    nel_delay.delay_ms      = nan(length(Chins2Run), length(all_Conds2Run));
    nel_delay.nel           = nan(length(Chins2Run), length(all_Conds2Run));
    nel_delay.is_estimated  = false(length(Chins2Run), length(all_Conds2Run));
    nel_delay.nel_confirmed = false(length(Chins2Run), length(all_Conds2Run));
    nel_delay.subjects      = Chins2Run(:);
    nel_delay.timepoints    = all_Conds2Run;
    if exist(nel_delay_file,'file')
        tmp   = load(nel_delay_file,'nel_delay');
        saved = tmp.nel_delay;
        % Map saved entries to current indices by subject and timepoint name
        for s = 1:length(Chins2Run)
            saved_s = find(strcmp(saved.subjects, Chins2Run{s}), 1);
            if isempty(saved_s), continue; end
            for t = 1:length(all_Conds2Run)
                saved_t = find(strcmp(saved.timepoints, all_Conds2Run{t}), 1);
                if isempty(saved_t), continue; end
                nel_delay.delay_ms(s,t)     = saved.delay_ms(saved_s, saved_t);
                nel_delay.nel(s,t)          = saved.nel(saved_s, saved_t);
                nel_delay.is_estimated(s,t) = saved.is_estimated(saved_s, saved_t);
                if isfield(saved, 'nel_confirmed')
                    nel_delay.nel_confirmed(s,t) = saved.nel_confirmed(saved_s, saved_t);
                end
                % Guard against inconsistent state: if NEL number is unknown
                % (cleared by user) but a stale delay was left behind, reset it
                if isnan(nel_delay.nel(s,t)) && ~nel_delay.nel_confirmed(s,t)
                    nel_delay.delay_ms(s,t)     = NaN;
                    nel_delay.is_estimated(s,t) = false;
                end
            end
        end
        fprintf('  [NEL] Loaded existing ABR_NEL_delay.mat (%d subjects, %d timepoints mapped)\n', ...
            length(Chins2Run), length(all_Conds2Run));
    end
    for ChinIND=1:length(Chins2Run)
        for CondIND=1:length(all_Conds2Run)
            if datapath_idx(ChinIND,CondIND) && isnan(nel_delay.delay_ms(ChinIND,CondIND))
                nel_delay = get_nel_delay(ROOTdir,datapath_dir{ChinIND,CondIND},Chins2Run,ChinIND,all_Conds2Run,CondIND,nel_delay,nel_delay_file);
            end
        end
    end

    % Build expected matrix from chinroster: true where animal has 'X' for that timepoint
    nel_expected = false(length(Chins2Run), length(all_Conds2Run));
    for s = 1:length(Chins2Run)
        for t = 1:length(all_Conds2Run)
            if strcmp(chinroster.signal(s,t),'X') || strcmp(chinroster.signal(s,t),'x')
                nel_expected(s,t) = true;
            end
        end
    end
    nel_delay = prompt_missing_nel(nel_delay, Chins2Run, all_Conds2Run, nel_delay_file, nel_expected);
end


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
        % Branch 2: move files from Data/RAW into subject/condition folder
        if data_check == 0 && subject_check == 1
            datapath = strcat(DATAdir,filesep,Chins2Run{ChinIND},filesep,EXPname,filesep,all_Conds2Run{CondIND});
            if ~exist(datapath, 'dir')
                fprintf('\nCreating data directory for %s (%s)...\n',Chins2Run{ChinIND},all_Conds2Run{CondIND});
                mkdir(datapath);
            end
            sourcepath = strcat(DATAdir,filesep,'RAW');
            cd(CODEdir)
            move_files(Chins2Run,all_Conds2Run,ChinIND,CondIND,sourcepath,EXPname,DATAdir,CODEdir);
            % Update so Branch 1 can run in this same pass
            new_dp = search_files(datapath,datapath_searchfile);
            if ~isempty(new_dp.files)
                datapath_idx(ChinIND,CondIND) = 1;
                datapath_dir{ChinIND,CondIND} = new_dp.dir;
                data_check = 1;
            end
        end

        % Branch 1: convert RAW data to analyzed format
        if file_check == 0 && data_check == 1 && subject_check == 1 || reanalyze == 1
            fprintf('\nSubject: %s (%s)\n',Chins2Run{ChinIND},all_Conds2Run{CondIND});
            filepath = strcat(OUTdir,filesep,EXPname,filesep,Chins2Run{ChinIND},filesep,all_Conds2Run{CondIND});
            datapath = datapath_dir{ChinIND,CondIND};
            calibpath = datapath;
            if ~exist(filepath, 'dir')
                fprintf('\nCreating analysis directory for %s (%s)...\n',Chins2Run{ChinIND},all_Conds2Run{CondIND});
                mkdir(filepath);
            end
            if use_embed, pre_figs_b1 = findall(0,'Type','figure'); end
            set(0,'DefaultFigureVisible', onoff(show_figs.analysis));
            switch EXPname
                case 'ABR'
                    switch EXPname2
                        case 'Thresholds'
                            ABR_thresholds(datapath,filepath,Chins2Run{ChinIND},all_Conds2Run,CondIND);
                        case 'Peaks'
                            ABR_dtw(ROOTdir,CODEdir,datapath,filepath,Chins2Run,ChinIND,all_Conds2Run,Conds2Run,CondIND,nel_delay,colors,shapes,limits.ind.peaks,abr_freq,abr_levels)
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
                            DPanalysis(ROOTdir,datapath,filepath,Chins2Run{ChinIND},condition{2});
                        case 'SFOAE'
                            SFanalysis(ROOTdir,datapath,filepath,Chins2Run{ChinIND},condition{2});
                        case 'TEOAE'
                            TEanalysis(ROOTdir,datapath,filepath,Chins2Run{ChinIND},condition{2});
                    end
                case 'MEMR'
                    WBMEMRanalysis(ROOTdir,datapath,filepath,Chins2Run{ChinIND},condition{2});
            end
            set(0,'DefaultFigureVisible','on');
            if use_embed
                new_figs = setdiff(findall(0,'Type','figure'), pre_figs_b1);
                new_figs = new_figs(isvalid(new_figs));
                if ~isempty(new_figs)
                    lbl = sprintf('%s | %s', Chins2Run{ChinIND}, condition{end});
                    embed_fns.analysis(new_figs, lbl);
                end
            end
            % Mark analyzed file as available so Branch 3 runs in this same pass
            filepath_idx(ChinIND,CondIND) = 1;
            filepath_dir{ChinIND,CondIND} = filepath;
            file_check = 1;
        end

        % Branch 3: load analyzed data and run summary/averaging
        if file_check == 1 && data_check == 1 && subject_check == 1 || flag == 1
            counter = counter+1;
            if counter == sum(sum(subject_idx))
                flag = 1;
            end
            fprintf('\nLoading Data for Averaging...\nSubject: %s (%s)\n',Chins2Run{ChinIND},all_Conds2Run{CondIND});
            filepath = filepath_dir{ChinIND,CondIND};
            datapath = datapath_dir{ChinIND,CondIND};
            if use_embed, pre_figs_b3 = findall(0,'Type','figure'); end
            set(0,'DefaultFigureVisible', onoff(show_figs.ind || show_figs.avg));
            switch EXPname
                case 'ABR'
                    cd(strcat(ROOTdir,filesep,'Code Archive',filesep,'ABR'));
                    switch EXPname2
                        case 'Thresholds'
                            ABRsummary(filepath,OUTdir,PRIVATEdir,Conds2Run,Chins2Run,all_Conds2Run,ChinIND,CondIND,idx_plot_relative,limits.ind,[],[],limits.avg,[],[],colors,shapes,EXPname2,flag,conds_idx);
                        case 'Peaks'
                            ABRsummary(filepath,OUTdir,PRIVATEdir,Conds2Run,Chins2Run,all_Conds2Run,ChinIND,CondIND,idx_plot_relative,[],limits.ind.peaks,limits.ind.latency,[],limits.avg.peaks,limits.avg.latency,colors,shapes,EXPname2,flag,conds_idx,abr_freq,abr_levels);
                    end
                case 'EFR'
                    % Auto-detect level from saved filenames (use first found, fallback 80)
                    switch EXPname2
                        case 'dAM', lvl_pattern = '*EFR_dAM*.mat';
                        case 'RAM', lvl_pattern = '*EFR_RAM*.mat';
                    end
                    lvl_files = dir(fullfile(filepath, lvl_pattern));
                    lvl_files = lvl_files(~strncmp({lvl_files.name},'._',2));
                    efr_level = 80;  % fallback
                    if ~isempty(lvl_files)
                        tok = regexp(lvl_files(1).name,'_(\d+)dBSPL','tokens');
                        if ~isempty(tok), efr_level = str2double(tok{1}{1}); end
                    end
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
                    WBMEMRsummary(filepath,OUTdir,PRIVATEdir,Conds2Run,Chins2Run,all_Conds2Run,ChinIND,CondIND,idx_plot_relative,limits.avg,limits.threshold,shapes,colors,flag,conds_idx)
                    filename = 'MEMR_Average';
            end
            set(0,'DefaultFigureVisible','on');
            if use_embed
                new_figs = setdiff(findall(0,'Type','figure'), pre_figs_b3);
                new_figs = new_figs(isvalid(new_figs));
                if ~isempty(new_figs)
                    lbl = sprintf('%s %s', EXPname, EXPname2);
                    embed_fns.average(new_figs, lbl);
                end
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

function s = onoff(tf)
% Return 'on' or 'off' string from a logical value
if tf, s = 'on'; else, s = 'off'; end
end