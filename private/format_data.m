%% Format Data
% Objective: transform short-format data into long-format data for statistical analysis
% Author: Fernando Aguilera de Alba
% Date: 15 January 2026
%% User Input
clear all; close all; clc;
if ismac    % Mac
    DATAdir = '/Users/fernandoaguileradealba/Library/Mobile Documents/com~apple~CloudDocs/Desktop/Purdue/Heinz Lab/Presentations/ARO 2026/Stats/RAW/Blast';
    OUTdir = '/Users/fernandoaguileradealba/Library/Mobile Documents/com~apple~CloudDocs/Desktop/Purdue/Heinz Lab/Presentations/ARO 2026/Stats/Data/Blast';
    ROOTdir = '/Volumes/FefeSSD/DOD/Code Archive/private';
else        % Windows
    DATAdir = 'N/A';
end
Conds2Run = ["D3";"D7";"D14"]'; % Define grouping units (e.g., timepoints,conditions)
relative_flag = 0;  % 1 = relative to baseline      0 = do not compare to baseline
%% Script
[EXPname,EXPname2,search_file] = measure_menu();
[average,filename] = load_files(DATAdir,search_file);
[data,x_str,filename] = define_data(average,EXPname,EXPname2,filename);
write_table(data,average,Conds2Run,x_str,relative_flag,filename,EXPname,EXPname2,OUTdir);
%% ------------------------------------------------------------------------------------------------------------------------------------------------------------------------
% Functions
function [EXPname,EXPname2,search_file] = measure_menu()
% Display menu options at the center of the screen
analysis_options = {'ABR', 'EFR-RAM','EFR-dAM', 'DPOAE', 'SFOAE','TEOAE', 'MEMR'};
choice = listdlg('PromptString','Select analysis type: ','ListString',analysis_options,'SelectionMode','single','ListSize', [100 80]);
% Check the user's choice
switch choice
    case 1  % ABR
        EXPname = 'ABR';
        EXPname2 = questdlg('Select ABR analysis:', ...
            'ABR Analysis', ...
            'Thresholds','Peaks','Thresholds');
        search_file = EXPname;
    case 2  % EFR RAM
        EXPname = 'EFR-RAM';
        EXPname2 = [];
        search_file = 'RAM';
    case 3  % EFR dAM
        EXPname = 'EFR-dAM';
        EXPname2 = [];
        search_file = 'dAM';
    case 4  % DPOAE
        EXPname = 'DPOAE';
        EXPname2 = [];
        search_file = EXPname;
    case 5  % SFOAE
        EXPname = 'SFOAE';
        EXPname2 = [];
        search_file = EXPname;
    case 6  % TEOAE
        EXPname = 'TEOAE';
        EXPname2 = [];
        search_file = EXPname;
    case 7  % MEMR
        EXPname = 'MEMR';
        EXPname2 = [];
        search_file = EXPname;
end
end
function [average,filename] = load_files(DATAdir,datafile)
    if exist(DATAdir,'dir')
        cwd = pwd;
        cd(DATAdir);
        datafile = ['*',datafile,'*.mat'];
        filename = dir(fullfile(cd,datafile));
        if length(filename) < 1 || isempty(filename)
            fprintf('No files found.\n')
            cd(cwd);
            average = [];
            return
        elseif size(filename,1) > 1
            fprintf('Multiple data files found. Please select one file to format. \n');
            filename = uigetfile(datafile);
        elseif size(filename,1) == 1
            filename = filename.name;
        end
        fprintf('File: %s\n',filename);
    else
        fprintf('Directory was not found: %s\n',DATAdir);
        filename = [];
        average = [];
    end
    load(filename);
    cd(cwd)
    filename = filename(1:end-4);
end
function [data,x_str,out_filename] = define_data(average,EXPname,EXPname2,filename)
switch EXPname
    case 'ABR'
        out_filename = filename;
        switch EXPname2
            case 'Thresholds'
                x_str = ["Click","0.5","1","2","4","8"];
                data = average.all_y;
            case 'Peaks'
                x_str = ["w1","w2","w3","w4","w5"];
                data = [];
        end

    case 'EFR-RAM'
            x_str = round(average.peaks_locs{1,1});  % individual harmonics
            data = average.all_peaks;
            out_filename = filename;

    case 'EFR-dAM'
            x_str = round(average.trajectory{1,1});  % frequency trajectory
            calcSNR = @(d, n) real(10*log10(d ./ n)); % calculate SNR
            hasData = ~cellfun(@isempty, average.all_dAMpower) & ~cellfun(@isempty, average.all_NFpower);
            SNR_dB = cell(size(average.all_dAMpower));
            SNR_dB(hasData) = cellfun(calcSNR,average.all_dAMpower(hasData),average.all_NFpower(hasData),'UniformOutput', false);
            data = SNR_dB;
            out_filename = filename;

    case 'DPOAE'
        x_str = average.bandF;
        data = average.all_oae_band;
        out_filename = filename;

    case 'SFOAE'
        x_str = average.bandF;
        data = average.all_oae_band;
        out_filename = filename;

    case 'TEOAE'
        x_str = average.bandF;
        data = average.all_oae_band;
        out_filename = filename;

    case 'MEMR'
        x_str = "N/A";
        data = average.all_thresholds;
        out_filename = filename;
end
end
function write_table(data,average,Conds2Run,x_str,relative_flag,filename,EXPname,EXPname2,OUTdir)
cwd = pwd;
subjects = average.subjects;
%all_y = cell(size(data));
y = nan(size(data,1),size(Conds2Run,2)+1);
y_relative = nan(size(data,1),size(Conds2Run,2));
if relative_flag == 0,Conds2Run = ["Baseline",Conds2Run];end
for x_idx = 1:length(x_str)
    for rows = 1:size(data,1)
        for cols = 1:size(data,2)
            %all_y{rows,cols} = nan(1,length(x_str));
            if ~isempty(data{rows,cols})
                %all_y{rows,cols}(x_idx) = data{rows,cols}(x_idx);
                if strcmp(EXPname,'EFR-RAM') && strcmp(EXPname2,'SumPeaks') 
                    y(rows,cols) = data{rows,cols}(2)+data{rows,cols}(1);
                elseif strcmp(EXPname,'EFR-RAM') && strcmp(EXPname2,'LowPeaks')
                    y(rows,cols) = data{rows,cols}(1);
                elseif strcmp(EXPname,'EFR-RAM') && strcmp(EXPname2,'HighPeaks')
                    y(rows,cols) = data{rows,cols}(2);
                else
                    y(rows,cols) = data{rows,cols}(x_idx);
                end
            end
        end
    end
    for cols = 1:width(y_relative)
        y_relative(:,cols) = y(:,cols+1)-y(:,1);
    end
    if relative_flag
        y_glm = y_relative;
    else
        y_glm = y;
    end
    % Create long-format data table
    glm_table = array2table(y_glm,'VariableNames',Conds2Run);
    glm_table.Subject = subjects;
    glm_table.Frequency = repmat(x_str(x_idx),1,size(y_glm,1))';
    glm_table.Frequency_Cat = x_idx*ones(1,size(y_glm,1))';
    glm_long_table_new = stack(glm_table,{Conds2Run},'NewDataVariableName','y','IndexVariableName','Timepoint');
    if x_idx == 1
        glm_long_table = glm_long_table_new;   % initialize
    else
        glm_long_table = [glm_long_table ; glm_long_table_new];
    end
end
for k = 1:length(Conds2Run)
    glm_long_table.Timepoints_Cat(glm_long_table.Timepoint == Conds2Run(k)) = k;
end
% Save long-format data as .csv file
filename_csv = strcat(filename,'.csv');
cd(OUTdir)
writetable(glm_long_table,filename_csv, ...
    'FileType', 'text', ...
    'Delimiter', ',', ...
    'QuoteStrings', true, ...
    'WriteVariableNames', true);
cd(cwd)
end