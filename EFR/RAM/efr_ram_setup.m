% Set up to run EFR - RAM analysis
% Updated: 8 December 2023 - Fernando Aguilera de Alba
%Here's where you can define your own parameters for input/output
%directories.
close all;
clear;
%% User Defined:
Chins2Run={'Q438','Q445','Q446','Q447'};
Conds2Run = {strcat('pre',filesep,'Baseline_2'), strcat('post',filesep,'D7')};
EXPname = 'EFR';
EXPname2 = 'RAM';
% Data and code directories
if (ismac == 1) %MAC computer
    ROOTdir = strcat(filesep,'Users',filesep,'fernandoaguileradealba',filesep,'Desktop',filesep,'DOD');
    DATAdir = strcat(ROOTdir);
else %if using WINDOWS computer..
    ROOTdir = strcat('C:',filesep,'Users',filesep,'aguilerl',filesep,'OneDrive - purdue.edu',filesep,'Desktop',filesep,'DOD-Analysis',filesep,'Code Archive');
    DATAdir = strcat('C:',filesep,'Users',filesep,'aguilerl',filesep,'OneDrive - purdue.edu',filesep,'Desktop',filesep,'DOD-Analysis');
end
CODEdir = strcat(ROOTdir,filesep,EXPname,filesep,EXPname2);
OUTdir = strcat(ROOTdir);
%% Subjects and Conditions
for ChinIND=1:length(Chins2Run)
    for CondIND=1:length(Conds2Run)
        datapath = strcat(DATAdir,filesep,'Data',filesep,Chins2Run{ChinIND},filesep,EXPname,filesep,Conds2Run{CondIND});
        calibpath = datapath;
        subj = Chins2Run{ChinIND};
        str = strsplit(Conds2Run{CondIND}, filesep);
        condition = strcat(str{1},'-',str{2});
        % Check if MEMR analyzed data folder exist for selected chins and time points
        outpath = strcat(ROOTdir,filesep,'Analysis',filesep,EXPname);
        Outlist = dir(outpath);
        if isempty(Outlist) %create directory if it doesn't exist
            cd(OUTdir)
            mkdir('Analysis')
            cd(strcat(OUTdir,filesep,'Analysis'))
            mkdir(EXPname)
        end
        cd(outpath)
        Dlist=dir(Chins2Run{ChinIND});
        if isempty(Dlist) %create directory if it doesn't exist
            fprintf('Creating analysis folder for %s...\n',Chins2Run{ChinIND})
            mkdir(Chins2Run{ChinIND})
            cd(Chins2Run{ChinIND})
            mkdir('pre')
            mkdir('post')
        end
        cd(strcat(outpath,filesep,Chins2Run{ChinIND},filesep,str{1}))
        list=dir(str{2});
        if isempty(list) %create directory if it doesn't exist
            fprintf('Creating analysis folder for %s...\n',Chins2Run{ChinIND})
            mkdir(str{2});
        end
        cd(str{2})
        outpath = pwd;
        fprintf('\nSubject: %s (%s - %s)\n',Chins2Run{ChinIND},str{1},str{2});
        cd(CODEdir)
        processChin;
    end  % Chin loop
end