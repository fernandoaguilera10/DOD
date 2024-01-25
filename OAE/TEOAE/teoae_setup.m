% Set up to run TEOAE analysis
% Updated: 8 December 2023 - Fernando Aguilera de Alba
%Here's where you can define your own parameters for input/output
%directories.
close all;
clear;
%% User Defined:
% Data and code directories
if (ismac == 1) %MAC computer
    ROOTdir = strcat(filesep,'Volumes',filesep,'Heinz-Lab/Users/Hannah');
else %if using WINDOWS computer..
    ROOTdir = strcat('C:',filesep,'Users',filesep,'aguilerl',filesep,'OneDrive - purdue.edu',filesep,'Desktop',filesep,'DOD-Analysis');
end
EXPname = 'OAE';
EXPname2 = 'TEOAE';
CODEdir = strcat(ROOTdir,filesep,'Code Archive',filesep,EXPname,filesep,EXPname2);
%% Subjects and Conditions
Chins2Run={'Q445'};
Conds2Run = {strcat('pre',filesep,'Baseline_1')};
for ChinIND=1:length(Chins2Run)
    for CondIND=1:length(Conds2Run)
        datapath = strcat(ROOTdir,filesep,'Data',filesep,Chins2Run{ChinIND},filesep,EXPname,filesep,Conds2Run{CondIND});
        calibpath = datapath;
        subj = Chins2Run{ChinIND};
        str = strsplit(Conds2Run{CondIND}, '\');
        condition = strcat(str{1},'-',str{2});
        % Check if MEMR analyzed data folder exist for selected chins and time points
        outpath = strcat(ROOTdir,filesep,'Analysis',filesep,EXPname);
        cd(outpath)
        Dlist=dir(Chins2Run{ChinIND});
        if isempty(Dlist) %create directory if it doesn't exist
            fprintf('Creating analysis folder for %s...\n',Chins2Run{ChinIND})
            mkdir(Chins2Run{ChinIND})
            cd(Chins2Run{ChinIND})
            mkdir('pre')
            mkdir('post')
        end
        outpath = strcat(ROOTdir,filesep,'Analysis',filesep,EXPname,filesep,Chins2Run{ChinIND},filesep,str{1});
        cd(CODEdir)
        fprintf('\nSubject: %s (%s - %s)\n',Chins2Run{ChinIND},str{1},str{2})
        TEOAE_Analysis;
    end  % Chin loop
end