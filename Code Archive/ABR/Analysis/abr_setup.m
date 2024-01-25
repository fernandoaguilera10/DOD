%% Data formatting - see Y:\Projects\___Project_Name_TEMPLATE
% 3 folders in project directory
% Analysis - 3 subfolders with experiment type (e.g. ABR, EFR, MEMR, OAE)
% Code Archive - 3 subfolders with experiment type (e.g. ABR, EFR, MEMR, OAE)
% Data - individual data folders with subject ID (e.g. Q123)
%% Animal ID
ChinID = 'Q445';
ChinCondition = 'pre';
ChinFile = 'Baseline_2'; 
%% Directories
% PROJdir = directory containing project folder
% abr_data_dir = directory containing data folder
if (ismac == 1) %MAC computer
    %PROJdir = strcat(filesep,'Volumes',filesep,'Heinz-Lab',filesep,'Projects',filesep,'DOD',filesep,'Pilot Study');
    %abr_data_dir = strcat(PROJdir,filesep,'Data',filesep,ChinID,filesep,'ABR',filesep,ChinCondition);
    PROJdir = strcat(filesep,'Users',filesep,'fernandoaguileradealba',filesep,'Desktop',filesep,'DOD_Analysis_GIT');
    abr_data_dir = strcat(PROJdir,filesep,'Data',filesep,ChinID,filesep,'ABR',filesep,ChinCondition);
else %if using WINDOWS computer..
%     PROJdir = strcat('Y:',filesep,'Projects',filesep,'DOD',filesep,'Pilot Study');
%     abr_data_dir = strcat(PROJdir,filesep,'Data',filesep,ChinID,filesep,'ABR',filesep,ChinCondition);
    PROJdir = strcat('C:',filesep,'Users',filesep,'aguilerl',filesep,'OneDrive - purdue.edu',filesep,'Desktop',filesep,'ABR-Analysis');
    abr_data_dir = strcat(PROJdir,filesep,'Data',filesep,ChinID,filesep,'ABR',filesep,ChinCondition);
end
%% Function
global abr_root_dir abr_data_dir abr_out_dir animal ChinCondition ChinFile ChinID
rmpath(genpath('Trash'));
animal = ChinID(2:end);
addpath(genpath(PROJdir))
abr_root_dir = pwd; % path of the directory containing your 'ABRAnalysis' folder
abr_out_dir = [PROJdir strcat(filesep,'Analysis',filesep,'ABR',filesep,ChinID,filesep,ChinCondition,filesep,ChinFile)];
addpath(abr_root_dir)
if ~exist(abr_out_dir,'dir')
    mkdir(abr_out_dir);
end
abr_analysis_HL;