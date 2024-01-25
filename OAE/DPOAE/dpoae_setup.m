%% Set up to run DPOAE analysis
% Updated: 7 December 2023 - Fernando Aguilera de Alba
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
EXPname2 = 'DPOAE';
CODEdir = strcat(ROOTdir,filesep,'Code Archive',filesep,EXPname,filesep,EXPname2);
%% Subjects and Conditions
Chins2Run={'Q434','Q435'};
Conds2Run = {strcat('pre',filesep,'Baseline_1'), strcat('post',filesep,'2_day')};
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
        DPanalysis;
    end  % Chin loop
end