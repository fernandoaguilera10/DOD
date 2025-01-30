clc; close all;
%% User Input:
Chins2Run={'Q506'};
Conds2Run = {strcat('pre',filesep,'Baseline')};
if ismac
    %source = '/Volumes/heinz/data/UserTESTS/FA/DOD/Data/RAW';  % data depot
    source = '/Volumes/FefeSSD/DOD/Code Archive';
else
    %source = 'Z:\data\UserTESTS\FA\DOD\Data\RAW';   % data depot
    source = 'D:\DOD\Data\RAW'; % SSD
end
%% CODE
% Ensure the source directory exists
if ~isfolder(source)
    error('Source directory does not exist.');
end
if ~exist('ROOTdir','var')
    uiwait(msgbox('Press OK to select root directory','Root Directory','help'));
    ROOTdir = uigetdir('', 'Select root directory');
    addpath(strcat(ROOTdir,filesep,'Code Archive'));
end
% Display menu options at the center of the screen
analysis_options = {'ABR', 'EFR', 'OAE', 'MEMR'};
choice = listdlg('PromptString','Select file type: ','ListString',analysis_options,'SelectionMode','single','ListSize', [100 80]);
% Check the user's choice
switch choice
    case 1
        EXPname = 'ABR';
    case 2
        EXPname = 'EFR';
    case 3
        EXPname = 'OAE';
    case 4
        EXPname = 'MEMR';
end
[DATAdir, OUTdir, CODEdir] = get_directory(ROOTdir,EXPname,[]);
for ChinIND=1:length(Chins2Run)
    for CondIND=1:length(Conds2Run)
        targetDir = strcat(DATAdir,filesep,Chins2Run{ChinIND},filesep,EXPname,filesep,Conds2Run{CondIND});
        temp = dir(fullfile(source, ['*',Chins2Run{ChinIND},'*']));
        temp = temp([temp.isdir]); % Filter for directories only
        for i=1:length(temp)
            sourceDir_temp(i) = {temp(i).name};
        end
        if ~isempty(temp)
            [selectionIndex, tf] = listdlg('PromptString', sprintf('Select source directory (%s - %s):',EXPname,cell2mat(Conds2Run(CondIND))), ...
                'SelectionMode', 'single', ...
                'ListString', sourceDir_temp,'ListSize', [500 150]);
            if tf
                sourceDir = cell2mat(strcat(source,filesep,sourceDir_temp(selectionIndex)));
            else
                disp('\nPlease select the source directory');
                sourceDir = [];
            end
        end
        % Ensure the target directory exists or create it
        if ~isfolder(targetDir)
            mkdir(targetDir);
        end
        cd(sourceDir)
        if strcmp(EXPname,'EFR')
            datafiles = dir('*FFR*');
        else
            datafiles = dir(['*',EXPname,'*']);
        end
        calibfiles = dir('*p*calib*');
        if ~isempty(datafiles)
            fprintf('\nMoving files...');
            fprintf('\nTarget directory: %s\n', targetDir);
            fprintf('Source directory: %s\n', sourceDir);
            if strcmp(EXPname,'ABR') || strcmp(EXPname,'EFR') || strcmp(EXPname,'OAE')
                 % Move each calib file to the target directory
                for k = 1:length(calibfiles)
                    sourceFile = fullfile(sourceDir, calibfiles(k).name);
                    targetFile = fullfile(targetDir, calibfiles(k).name);
                    % Move the file
                    copyfile(sourceFile, targetFile);
                    % Display a message
                    fprintf('\nFile: %s', calibfiles(k).name);
                end
                % Move each data file to the target directory
                for k = 1:length(datafiles)
                    sourceFile = fullfile(sourceDir, datafiles(k).name);
                    targetFile = fullfile(targetDir, datafiles(k).name);
                    % Move the file
                    copyfile(sourceFile, targetFile);
                    % Display a message
                    fprintf('\nFile: %s', datafiles(k).name);
                end
            elseif strcmp(EXPname,'MEMR')
                % Move each data file to the target directory
                for k = 1:length(datafiles)
                    sourceFile = fullfile(sourceDir, datafiles(k).name);
                    targetFile = fullfile(targetDir, datafiles(k).name);
                    % Move the file
                    copyfile(sourceFile, targetFile);
                    % Display a message
                    fprintf('\nFile: %s', datafiles(k).name);
                end
            end
            fprintf('\n\nFiles have been succesfully copied for %s (%s)\n\n',Chins2Run{ChinIND},Conds2Run{CondIND});
        else
            fprintf('\nNo files found under current directory');
        end
        clear temp sourceDir sourceDir_temp;
        beep;
    end
end
cd(CODEdir)