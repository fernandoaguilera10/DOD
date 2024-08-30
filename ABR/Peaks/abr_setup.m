function abr_peaks_setup(ROOTdir)
global abr_root_dir abr_data_dir abr_out_dir animal ChinCondition ChinFile ChinID
%% Animal ID
ChinID = 'Q456';
ChinCondition = 'post';
ChinFile = 'D5';
%% Directories
% PROJdir = directory containing project folder
% abr_data_dir = directory containing data folder
if (ismac == 1) %MAC computer
    %Synology:
    %PROJdir = strcat(filesep,'Volumes',filesep,'Heinz-Lab',filesep,'Projects',filesep,'DOD',filesep,'Pilot Study');
    %abr_data_dir = strcat(PROJdir,filesep,'Data',filesep,ChinID,filesep,'ABR',filesep,ChinCondition);
    PROJdir = strcat(filesep,'Users',filesep,'fernandoaguileradealba',filesep,'Desktop',filesep,'DOD-Analysis');
    abr_data_dir = strcat(filesep,'Users',filesep,'fernandoaguileradealba',filesep,'Desktop',filesep,'DOD-Analysis',filesep,'Data',filesep,ChinID,filesep,'ABR',filesep,ChinCondition);
    
else %if using WINDOWS computer..
    %Synology:
    %PROJdir = strcat('Y:',filesep,'Projects',filesep,'DOD',filesep,'Pilot Study');
    %abr_data_dir = strcat(PROJdir,filesep,'Data',filesep,ChinID,filesep,'ABR',filesep,ChinCondition);
    PROJdir = strcat('C:',filesep,'Users',filesep,'aguilerl',filesep,'OneDrive - purdue.edu',filesep,'Desktop',filesep,'DOD-Analysis');
    abr_data_dir = strcat('C:',filesep,'Users',filesep,'aguilerl',filesep,'OneDrive - purdue.edu',filesep,'Desktop',filesep,'DOD-Analysis',filesep,'Data',filesep,ChinID,filesep,'ABR',filesep,ChinCondition);
end
%% Function
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
end