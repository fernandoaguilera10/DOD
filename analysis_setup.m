clc; close all; clear all; warning off;
%% ROOT Directory
if ismac
    %ROOTdir = '/Volumes/heinz/data/UserTESTS/FA/DOD';  % data depot
    ROOTdir = '/Volumes/FefeSSD/DOD';
else
    %ROOTdir = 'Z:\data\UserTESTS\FA\DOD'; % data depot
    %ROOTdir = 'D:\DOD'; % SSD
    %ROOTdir = 'F:\DOD'; % NEL2
    ROOTdir = 'E:\DOD'; % LYLE 3035 (Analysis)
end
%% Subjects and Conditions
plot_relative_flag = 1;     % Relative to Baseline:  Yes = 1   or  No = 0
reanalyze = 0;              % 1 = redo analysis      0 = skip analysis
chinroster_filename = 'DOD_ChinRoster.xlsx';    % saved under OUTdir (i.e. Analysis)
chinroster_sheet = 'BLAST';   % 'NOISE' or 'BLAST'

if strcmp(chinroster_sheet,'BLAST')
    Conds2Run = {strcat('pre',filesep,'Baseline'),strcat('post',filesep,'D3'),strcat('post',filesep,'D14'),strcat('post',filesep,'D28'),strcat('post',filesep,'D56')};
    Chins2Run={'Q541'}; 
    % Group 0 ALL: 'Q457','Q463','Q478','Q493','Q494','Q499','Q500','Q503'
        % 75 kPa: 'Q457','Q478','Q493','Q499','Q500'
            % Head Free: 'Q457','Q478','Q493','Q500'
        % 150 kPa: 'Q463','Q494','Q503','Q537','Q541','Q542'
            % Head Free: 'Q463','Q494'
        % Group 1 (150 kPa w/earplugs + bite bar):'Q537','Q538','Q540','Q541','Q539','Q542','Q543'
elseif strcmp(chinroster_sheet,'NOISE')
    Conds2Run = {strcat('pre',filesep,'Baseline'),strcat('post',filesep,'D7'),strcat('post',filesep,'D14'),strcat('post',filesep,'D30')};
    Chins2Run={'Q488','Q504','Q505'};
    % ALL: 'Q438','Q445','Q446','Q447','Q460','Q461','Q462','Q464','Q473','Q474','Q475','Q476','Q479','Q480','Q481','Q482','Q483','Q484','Q485','Q486','Q487','Q488','Q504','Q505'
        % Group 0: 'Q438','Q445','Q446','Q447' (8hrs/5 days per week)
        % Group 1: 'Q460','Q461','Q462','Q464' (10hrs/4 days per week)
        % Group 2: 'Q473','Q474','Q475','Q476','Q479','Q480' (10hrs/4 days per week)
        % Group 3: 'Q481','Q482','Q483','Q484','Q487','Q488' (10hrs/4 days per week)
        % Group 4: 'Q485','Q486' (10hrs/4 days per week)
        % GROUP 5: 'Q504','Q505' (10hrs/4 days per week)
else
    Conds2Run = {strcat('pre',filesep,'Baseline')};
    Chins2Run={'Q312'};
end
analysis_run(ROOTdir,Chins2Run,Conds2Run,chinroster_filename,chinroster_sheet,plot_relative_flag,reanalyze);