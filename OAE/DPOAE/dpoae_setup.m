%% Set up to run DPOAE analysis
% Updated: 26 February 2024 - Fernando Aguilera de Alba
% Define the following variables according to your project
% ROOTdir = directory with your project
% CODEdir = directory with MATLAB files (Github)
% DATAdir = directory with data to analyze
% Chins2Run = list of subjects to analyze data
% Conds2Run = list of conditions to analyze data (baseline vs post)
% 
% 
% Output: 
% DPanalysis - analyzes RAW data to plot DPgram for Chins2Run and Conds2Run
% DPsummary - combines analyzed data to compare DPgrams between Cond2Run
close all;
clear;
%% User Defined:
Chins2Run={'Q438','Q445','Q446','Q447'};
Conds2Run = {strcat('pre',filesep,'Baseline_2'), strcat('post',filesep,'D2'), strcat('post',filesep,'D7'), strcat('post',filesep,'D14')};
% Data and code directories
EXPname = 'OAE';
EXPname2 = 'DPOAE';
if (ismac == 1) %MAC computer
    ROOTdir = strcat(filesep,'Users',filesep,'fernandoaguileradealba',filesep,'Desktop',filesep,'DOD-Analysis',filesep,'Code Archive');
    DATAdir = strcat(filesep,'Users',filesep,'fernandoaguileradealba',filesep,'Desktop',filesep,'DOD-Analysis');
    OUTdir = strcat(filesep,'Users',filesep,'fernandoaguileradealba',filesep,'Desktop',filesep,'DOD-Analysis');
    CODEdir = strcat(ROOTdir,filesep,EXPname,filesep,EXPname2);
else %if using WINDOWS computer..
    ROOTdir = strcat('C:',filesep,'Users',filesep,'aguilerl',filesep,'OneDrive - purdue.edu',filesep,'Desktop',filesep,'DOD-Analysis',filesep,'Code Archive');
    DATAdir = strcat('C:',filesep,'Users',filesep,'aguilerl',filesep,'OneDrive - purdue.edu',filesep,'Desktop',filesep,'DOD-Analysis');
    OUTdir = strcat('C:',filesep,'Users',filesep,'aguilerl',filesep,'OneDrive - purdue.edu',filesep,'Desktop',filesep,'DOD-Analysis');
    CODEdir = strcat(ROOTdir,filesep,EXPname,filesep,EXPname2);
end
%% Subjects and Conditions
input1 = input('Would you like to perform DPOAE analysis (A) or summary (S): ','s');
for ChinIND=1:length(Chins2Run)
    for CondIND=1:length(Conds2Run)
        datapath = strcat(DATAdir,filesep,'Data',filesep,Chins2Run{ChinIND},filesep,EXPname,filesep,Conds2Run{CondIND});
        calibpath = datapath;
        subj = Chins2Run{ChinIND};
        str = strsplit(Conds2Run{CondIND}, filesep);
        condition = strcat(str{1},'-',str{2});
        % Check if MEMR analyzed data folder exist for selected chins and time points
        outpath = strcat(OUTdir,filesep,'Analysis',filesep,EXPname);
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
            DPanalysis;
        end
        if input1 == 'S' || input1 == 's'
            outpath = strcat(outpath,filesep,Chins2Run{ChinIND},filesep,str{1},filesep,str{2});
            fprintf('\nSubject: %s\nConditions: ',Chins2Run{ChinIND});
            fprintf('%s',Conds2Run{CondIND}); fprintf('\n');
            cd(CODEdir)
            DPsummary;
        end
    end  % Chin loop
end