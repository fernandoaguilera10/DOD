%% Set up to run MEMR analysis
% Updated: 6 Dec 2023 by Fernando Aguilera de Alba
close all;
clear;
%% User Defined:
% Data and code directories
Chins2Run={'Q438','Q445'};
Conds2Run = {strcat('pre',filesep,'Baseline_2'), strcat('post',filesep,'D2'), strcat('post',filesep,'D7')};
% Data and code directories
if (ismac == 1) %MAC computer
    ROOTdir = strcat(filesep,'Users',filesep,'fernandoaguileradealba',filesep,'Desktop',filesep,'DOD');
else %if using WINDOWS computer..
    ROOTdir = strcat('C:',filesep,'Users',filesep,'aguilerl',filesep,'OneDrive - purdue.edu',filesep,'Desktop',filesep,'DOD-Analysis');
end
EXPname = 'MEMR';
CODEdir = strcat(ROOTdir,filesep,EXPname,filesep);
DATAdir = strcat(filesep,'Volumes',filesep,'FEFE',filesep,'DOD');
%DATAdir = strcat(filesep,'Volumes',filesep,'Heinz-Lab',filesep,'Projects',filesep,'DOD',filesep,'Pilot Study');
OUTdir = strcat(ROOTdir);
%% Looping through subjects and conditions
input1 = input('Would you like to perform MEMR analysis (A) or summary (S): ','s');
for ChinIND=1:length(Chins2Run)
    for CondIND=1:length(Conds2Run)
        datapath = strcat(DATAdir,filesep,'Data',filesep,Chins2Run{ChinIND},filesep,EXPname,filesep,Conds2Run{CondIND});
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
            outpath = pwd;
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
        if input1 == 'A' || input1 == 'a'
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
            WBMEMRanalysis;
        end
        if input1 == 'S' || input1 == 's'
            outpath = strcat(outpath,filesep,Chins2Run{ChinIND},filesep,str{1},filesep,str{2});
            fprintf('\nSubject: %s\nConditions: ',Chins2Run{ChinIND});
            fprintf('%s, ',Conds2Run{:}); fprintf('\n');
            cd(CODEdir)
            WBMEMRsummary;
        end
    end  % Chin loop
end