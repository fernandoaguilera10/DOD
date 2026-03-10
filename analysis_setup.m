clc; close all; clear all; warning off;
%% ROOT Directory
if ismac
    ROOTdir = '/Users/ipek/Desktop/MATLAB_Heinz/DOD';
else
    ROOTdir = 'E:\DOD';
end
dir(fullfile(ROOTdir,'**','abr_gui_initiate.m'))
%% Subjects and Conditions
plot_relative_flag = 1;     % Relative to Baseline:  Yes = 1   or  No = 0
reanalyze = 1;              % 1 = redo analysis      0 = skip analysis
chinroster_filename = 'DOD_ChinRoster.xlsx';    % saved under OUTdir (i.e. Analysis)
chinroster_sheet = 'NOISE';   % 'NOISE' or 'BLAST'
Conds2Run = {strcat('pre',filesep,'Baseline'),strcat('post',filesep,'D7'),strcat('post',filesep,'D14'),strcat('post',filesep,'D30')};
Chins2Run={'Q438'};
analysis_run(ROOTdir,Chins2Run,Conds2Run,chinroster_filename,chinroster_sheet,plot_relative_flag,reanalyze);