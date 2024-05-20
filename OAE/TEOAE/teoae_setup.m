% Set up to run TEOAE analysis
% Updated: 20 February 2024 - Fernando Aguilera de Alba
% Define the following variables according to your project
% ROOTdir = directory with your project
% CODEdir = directory with MATLAB files (Github)
% DATAdir = directory with data to analyze
% Chins2Run = list of subjects to analyze data
% Conds2Run = list of conditions to analyze data (baseline vs post)
% 
% 
% Output: 
% TEanalysis - analyzes RAW data to plot TEgram for Chins2Run and Conds2Run
% TEsummary - combines analyzed data to compare TEgrams between Cond2Run
close all;
clear; clc;
%% User Defined:
Chins2Run={'Q465','Q464'};
Conds2Run = {strcat('pre',filesep,'Baseline_1')};
% Data and code directories
EXPname = 'OAE';
EXPname2 = 'TEOAE';
if (ismac == 1) %MAC computer
    ROOTdir = strcat(filesep,'Users',filesep,'fernandoaguileradealba',filesep,'Desktop',filesep,'DOD-Analysis',filesep,'Code Archive');
    DATAdir = strcat(filesep,'Users',filesep,'fernandoaguileradealba',filesep,'Desktop',filesep,'DOD-Analysis',filesep,'Data');
    OUTdir = strcat(filesep,'Users',filesep,'fernandoaguileradealba',filesep,'Desktop',filesep,'DOD-Analysis',filesep,'Analysis');
    CODEdir = strcat(ROOTdir,filesep,EXPname,filesep,EXPname2);
    
    %Synology:
    %ROOTdir = strcat(filesep,'Volumes',filesep,'Heinz-Lab',filesep,'Projects',filesep,'DOD',filesep,'Pilot Study',filesep,'Code Archive');
    %DATAdir = strcat(filesep,'Volumes',filesep,'Heinz-Lab',filesep,'Projects',filesep,'DOD',filesep,'Pilot Study',filesep,'Data');
    %OUTdir = strcat(filesep,'Volumes',filesep,'Heinz-Lab',filesep,'Projects',filesep,'DOD',filesep,'Pilot Study',filesep,'Analysis');
    %CODEdir = strcat(ROOTdir,filesep,EXPname,filesep,EXPname2);
else %if using WINDOWS computer..
    ROOTdir = strcat('C:',filesep,'Users',filesep,'aguilerl',filesep,'OneDrive - purdue.edu',filesep,'Desktop',filesep,'DOD-Analysis',filesep,'Code Archive');
    DATAdir = strcat('C:',filesep,'Users',filesep,'aguilerl',filesep,'OneDrive - purdue.edu',filesep,'Desktop',filesep,'DOD-Analysis',filesep,'Data');
    OUTdir = strcat('C:',filesep,'Users',filesep,'aguilerl',filesep,'OneDrive - purdue.edu',filesep,'Desktop',filesep,'DOD-Analysis',filesep,'Analysis');
    CODEdir = strcat(ROOTdir,filesep,EXPname,filesep,EXPname2);
    
    %Synology:
    %ROOTdir = strcat('Y:',filesep,'Heinz-Lab',filesep,'Projects',filesep,'DOD',filesep,'Pilot Study',filesep,'Code Archive');
    %DATAdir = strcat('Y:',filesep,'Heinz-Lab',filesep,'Projects',filesep,'DOD',filesep,'Pilot Study',filesep,'Data');
    %OUTdir = strcat('Y:',filesep,'Heinz-Lab',filesep,'Projects',filesep,'DOD',filesep,'Pilot Study',filesep,'Analysis');
    %CODEdir = strcat(ROOTdir,filesep,EXPname,filesep,EXPname2);
end
%% Subjects and Conditions
input1 = input('Would you like to perform TEOAE analysis (A) or summary (S): ','s');
count = 0;
for ChinIND=1:length(Chins2Run)
    for CondIND=1:length(Conds2Run)
        datapath = strcat(DATAdir,filesep,Chins2Run{ChinIND},filesep,EXPname,filesep,Conds2Run{CondIND});
        calibpath = datapath;
        subj = Chins2Run{ChinIND};
        str = strsplit(Conds2Run{CondIND}, filesep);
        condition = strcat(str{1},'-',str{2});
        outpath = strcat(OUTdir,filesep,EXPname);
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
            TEanalysis;
        end
        if input1 == 'S' || input1 == 's'
            outpath = strcat(outpath,filesep,Chins2Run{ChinIND},filesep,str{1},filesep,str{2});
            fprintf('\nSubject: %s\nConditions: ',Chins2Run{ChinIND});
            fprintf('%s',Conds2Run{CondIND}); fprintf('\n');
            cd(CODEdir)
            TEsummary;
        end
    end  % Chin loop
end