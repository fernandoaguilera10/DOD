function dirname = get_directory

global abr_data_dir abr_Stimuli han latcomp dataFolderpath abr_out_dir han viewraw dimcheck freqUsed abr_FIG

%% Reset checkbox to unchecked when loading new directory
dimcheck = 0;
set(han.viewraw,'Enable','on');
set(han.viewraw,'Value',0);

%% List of folders from DATA folder
%HG added 10/17 -- grab data from DATA folder
%d = dir(abr_data_dir);
cd(abr_data_dir)
folderNum = 1;
formatCorrect = false;
%         set(abr_FIG.push.peaks,'Enable','off');
folders = dir;
for num = 1:length(folders)
    FolderofInterest{folderNum} = folders(num).name;
    folderNum = folderNum + 1;
end
str = FolderofInterest;

%HG added 2/4/20 -- removes duplicate folders, if any
%str = unique(str);

%% User chooses folder from list
d = dir(abr_data_dir);
d = d([d.isdir]==1 & strncmp('.',{d.name},1)==0); % Only directories which are not '.' nor '..'
str = {d.name};
[selection, ok] = listdlg('Name', 'File Manager', ...
    'PromptString',   'Select an Existing Data Directory:',...
    'SelectionMode',  'single',...
    'ListSize',       [300,300], ...
    'OKString',       'Re-Activate', ...
    'CancelString',   'Exit', ...
    'InitialValue',    1, ...
    'ListString',      str);
drawnow; %updates figures/graphics immediately
if (ok==0 || isempty(selection))
    dirname = abr_Stimuli.dir;
else
    dirname = str{selection};
    %clear out contents of all axes
    set([han.abr_panel han.amp_panel han.lat_panel han.text_panel han.xcor_panel han.z_panel han.peak_panel],'NextPlot','replacechildren')
    plot(han.abr_panel,0,0,'-w'); plot(han.amp_panel,0,0,'-w'); plot(han.lat_panel,0,0,'-w');
    plot(han.xcor_panel,0,0,'-w'); plot(han.z_panel,0,0,'-w'); plot(han.text_panel,0,0,'-w'); plot(han.peak_panel,0,0,'-w');
    %	axis([han.abr_panel han.amp_panel han.lat_panel han.xcor_panel han.z_panel han.peak_panel],'off')
    latcomp=NaN(1,4);
end

%% Now go back and find dirname
if (formatCorrect == 1)
    %First determine animal number
    Qlocation_start = strfind(dirname,'Q');
    
    %Assuming number is 3 digits
    Qlocation_end = Qlocation_start+3;
    Qnumber = dirname(Qlocation_start:Qlocation_end);
    
    Qfolders_pwd = pwd;
    cd(Qnumber);
    %cd('Q403');
    %cd('dummy');
    
    %Run through both pre and post folders to find folder of Interest
    marker = 0;
    for num3 = 1:2
        if (num3 == 1) %PRE FIRST
            cd('ABR');
            cd('pre')
            preFolders = dir;
            foldersDIR_pre = pwd;
            for pre2 = 1:length(preFolders)
                if ~contains(preFolders(pre2).name, '.')
                    cd(preFolders(pre2).name);
                    %HG ADDED 1/17/20
                    checkforFolder = dir;
                    for ppp = 1:length(checkforFolder)
                        if contains(checkforFolder(ppp).name,dirname)
                            %if exist(dirname)
                            %Load data from here!!!!
                            %fprintf('DATA FOUND\n');
                            marker = 1;
                            cd(dirname);
                            dataFolderpath = pwd;
                            break; %exit loops because location was found
                        end
                    end
                    cd(foldersDIR_pre);
                end
            end
            if (marker == 1)
                break; %exits main loop too, doesn't check post
            end
        else %NEXT POST
            cd(Qfolders_pwd);
            cd(Qnumber);
            cd('ABR');
            cd('post');
            postFolders = dir;
            foldersDIR_post = pwd;
            for post2 = 1:length(postFolders)
                if ~contains(postFolders(post2).name, '.')
                    cd(postFolders(post2).name);
                    %HG ADDED 1/17/20
                    checkforFolder = dir;
                    for ppp = 1:length(checkforFolder)
                        if contains(checkforFolder(ppp).name,dirname)
                            %if exist(dirname)
                            %Load data from here!!!!
                            %fprintf('DATA FOUND\n');
                            marker = 1;
                            cd(dirname);
                            dataFolderpath = pwd;
                            break; %exit loops because location was found
                        end
                    end
                    cd(foldersDIR_post);
                end
            end
        end
    end
    CURdir=pwd;
else
    dataFolderpath = [pwd filesep dirname];
end

%% Go back to data directory to: 1) check for extra calibs, 2) do artifact correction
if exist(dataFolderpath,'dir')
    cd (dataFolderpath)
end

%% Warn if more than one calib file, if so list pics (Commented out 10/5/21 due to missing findPics, will comment back later)
calibPICs = dir('*calib_inv*.m');
fn = {calibPICs.name};
if length(calibPICs) > 1
    [calib_idx,ok] = listdlg('Name', 'Calibration File Manager', ...
        'PromptString',{'Please, select one calibration file to use.',''},...
        'ListSize',       [300,300], ...
        'SelectionMode','single','ListString',fn);
    abr_Stimuli.cal_pic = sscanf(fn{calib_idx},'p%d_');
    set(abr_FIG.parm_txt(1),'string',calibPICs(calib_idx).name,'Interpreter','none','Color',[0.4660 0.6740 0.1880]);
end
if length(calibPICs) == 1
    abr_Stimuli.cal_pic = sscanf(fn{1},'p%d_');
    set(abr_FIG.parm_txt(1),'string',calibPICs(1).name,'Interpreter','none','Color',[0.4660 0.6740 0.1880]);
end
if isempty(calibPICs)
    mydlg=warndlg('No Calibration Files Detected. Please Make Sure To Include One Within The Selected Directory or Select a New Directory','Calibration Files');
    waitfor(mydlg)
    set(abr_FIG.parm_txt(1),'string','Select Calibration','Interpreter','none','Color','r');
    
end


% Determine which freqs are present in the data
% If freq is present, it is added to freqUsed
freqUsed = [];
TEMPdir=dir('*ABR_click.mat');
if ~isempty(TEMPdir)
    freqUsed(end + 1) = NaN;
    set(abr_FIG.push.freqClick,'Enable','on');
else
    set(abr_FIG.push.freqClick,'Enable','off');
end
TEMPdir=dir('*ABR_500.mat');
if ~isempty(TEMPdir)
    freqUsed(end + 1) = 500;
    set(abr_FIG.push.freq500,'Enable','on');
else
    set(abr_FIG.push.freq500,'Enable','off');
end
TEMPdir=dir('*ABR_1000.mat');
if ~isempty(TEMPdir)
    freqUsed(end + 1) = 1000;
    set(abr_FIG.push.freq1k,'Enable','on');
else
    set(abr_FIG.push.freq1k,'Enable','off');
end
TEMPdir=dir('*ABR_2000.mat');
if ~isempty(TEMPdir)
    freqUsed(end + 1) = 2000;
    set(abr_FIG.push.freq2k,'Enable','on');
else
    set(abr_FIG.push.freq2k,'Enable','off');
end
TEMPdir=dir('*ABR_4000.mat');
if ~isempty(TEMPdir)
    freqUsed(end + 1) = 4000;
    set(abr_FIG.push.freq4k,'Enable','on');
else
    set(abr_FIG.push.freq4k,'Enable','off');
end
TEMPdir=dir('*ABR_8000.mat');
if ~isempty(TEMPdir)
    freqUsed(end + 1) = 8000;
    set(abr_FIG.push.freq8k,'Enable','on');
else
    set(abr_FIG.push.freq8k,'Enable','off');
end
% Do artifact Correction
% call abr_rejection (if needed) here since already in data directory
% araw files exist if AR has already been performed - don't perform AR again
% No araw files exist if AR - perform AR for ALL files

TEMPdir=dir('*_AR*');
a_files_all = dir('a*.mat'); %should we check for mat files here?
if isempty(TEMPdir)
    %If AR_marker exists, user set that AR does not need to be performed
    %Load in first a file to check for AR_marker
    if ~isempty(a_files_all)
        load(a_files_all(1).name);
    else
        return;
    end
    %     load(a_files_all(1.name);
    %     x = ans;
    %AR_marker = x.AR_marker;
    %If AR_marker does not exist, call artifact rejection
    %if ~exist('AR_marker','var')
    if ~isfield(x,'AR_marker')
        %Call AR if no araw files exist AND AR_marker does not exist
        %Only calls abr_artifact_rejection if AR needs to be performed
        abr_artifact_rejection;
    else %tell user that previous user indicated that AR does not need to be performed
        uiwait(warndlg('A previous user has indicated that AR does not need to be performed on this data set.','Artifact Correction NOT NECESSARY','modal'));
        %AFTER FIRST GO-AROUND - data has already been processed
        %Unable "view raw data" checkbox - because AC doesnt exist
        set(han.viewraw,'Enable','off');
        dimcheck = 1;
    end
else
    uiwait(warndlg('This folder has already been artifact corrected.','Artifact Correction COMPLETE','modal'));
    viewraw = 0;
end
CURdir = pwd;
cd(CURdir) % return after artifact correction