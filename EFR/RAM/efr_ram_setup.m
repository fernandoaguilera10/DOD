% Set up to run EFR - RAM analysis
% Updated: 8 December 2023 - Fernando Aguilera de Alba
%Here's where you can define your own parameters for input/output
%directories.
close all;
clear; clc;
%% User Defined:
Chins2Run={'Q465'};
Conds2Run = {strcat('pre',filesep,'Baseline_1')};
level_spl = 80;
EXPname = 'EFR';
EXPname2 = 'RAM';
% Data and code directories
if (ismac == 1) %MAC computer
    ROOTdir = strcat(filesep,'Users',filesep,'fernandoaguileradealba',filesep,'Desktop',filesep,'DOD-Analysis',filesep,'Code Archive');
    DATAdir = strcat(filesep,'Users',filesep,'fernandoaguileradealba',filesep,'Desktop',filesep,'DOD-Analysis');
    OUTdir = strcat(filesep,'Users',filesep,'fernandoaguileradealba',filesep,'Desktop',filesep,'DOD-Analysis');
    CODEdir = strcat(ROOTdir,filesep,EXPname,filesep,EXPname2);

    %Synology:
    %ROOTdir = strcat(filesep,'Volumes',filesep,'Heinz-Lab',filesep,'Projects',filesep,'DOD',filesep,'Pilot Study',filesep,'Code Archive');
    %DATAdir = strcat(filesep,'Volumes',filesep,'Heinz-Lab',filesep,'Projects',filesep,'DOD',filesep,'Pilot Study');
    %OUTdir = strcat(filesep,'Volumes',filesep,'Heinz-Lab',filesep,'Projects',filesep,'DOD',filesep,'Pilot Study');
    %CODEdir = strcat(ROOTdir,filesep,EXPname,filesep,EXPname2);
else %if using WINDOWS computer..
    ROOTdir = strcat('C:',filesep,'Users',filesep,'aguilerl',filesep,'OneDrive - purdue.edu',filesep,'Desktop',filesep,'DOD-Analysis',filesep,'Code Archive');
    DATAdir = strcat('C:',filesep,'Users',filesep,'aguilerl',filesep,'OneDrive - purdue.edu',filesep,'Desktop',filesep,'DOD-Analysis');
    OUTdir = strcat('C:',filesep,'Users',filesep,'aguilerl',filesep,'OneDrive - purdue.edu',filesep,'Desktop',filesep,'DOD-Analysis');
    CODEdir = strcat(ROOTdir,filesep,EXPname,filesep,EXPname2);

    %Synology:
    %ROOTdir = strcat('Y:',filesep,'Projects',filesep,'DOD',filesep,'Pilot Study',filesep,'Code Archive');
    %DATAdir = strcat('Y:',filesep,'Projects',filesep,'DOD',filesep,'Pilot Study');
    %OUTdir = strcat('Y:',filesep,'Projects',filesep,'DOD',filesep,'Pilot Study');
    %CODEdir = strcat(ROOTdir,filesep,EXPname,filesep,EXPname2);

end
%% Subjects and Conditions
input1 = input('Would you like to perform MEMR analysis (A), or summary (S): ','s');
legend_string = {};
for ChinIND=1:length(Chins2Run)
    count = 0;
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
        if input1 == 'A' | input1 == 'a'
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
            EFRanalysis;
        end
        if input1 == 'S' | input1 == 's'
            outpath = strcat(outpath,filesep,Chins2Run{ChinIND},filesep,str{1},filesep,str{2});
            fprintf('\nSubject: %s\nConditions: ',Chins2Run{ChinIND});
            fprintf('%s',Conds2Run{CondIND}); fprintf('\n');
            cd(CODEdir)
            EFRsummary;
        end
    end  % Chin loop
end