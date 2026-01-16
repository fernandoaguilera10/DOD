%% Format Data
% Objective: transform short-format data into long-format data for statistical analysis
% Author: Fernando Aguilera de Alba
% Date: 15 January 2026
%% User Input
if ismac    % Mac
    DATAdir = '/Users/fernandoaguileradealba/Library/Mobile Documents/com~apple~CloudDocs/Desktop/Purdue/Heinz Lab/Presentations/Lab Meeting/Spring 2026/Mixed Effects Model';
else        % Windows
    DATAdir = 'N/A';
end
Conds2Run = ["D7";"D14";"D30"]'; % Define grouping units (e.g., timepoints,conditions)
relative_flag = 1;  % 1 = relative to baseline      0 = do not compare to baseline
%% --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
%% Script
% Select auditory measure type: ABR, EFR RAM, EFR dAM, OAE, MEMR
[EXPname,EXPname2] = measure_menu();
filename = load_files(DATAdir,datafile);
write_table(average,Conds2Run,x_str,relative_flag,filename);
function filename = load_files(DATAdir,datafile)
    if exist(DATAdir,'dir')
        cwd = pwd;
        cd(DATAdir);
        filename = dir(fullfile(cd,datafile));
        if length(filename) < 1 || isempty(filename)
            fprintf('No files found.\n')
            cd(cwd);
            return
        elseif size(filename,1) > 1
            fprintf('Multiple data files found. Please select one file to format. \n');
            filename = uigetfile(datafile);
        elseif size(filename,1) == 1
            filename = filename.name;
        end
        fprintf('File: %s\n',filename);
        cd(cwd);
    else
        fprintf('Directory was not found: %s\n',DATAdir);
        filename = [];
    end
end
function [EXPname,EXPname2,data,x_str,average] = measure_menu()
% Display menu options at the center of the screen
analysis_options = {'ABR', 'EFR', 'OAE', 'MEMR'};
choice = listdlg('PromptString','Select analysis type: ','ListString',analysis_options,'SelectionMode','single','ListSize', [100 80]);
% Check the user's choice
switch choice
    case 1
        EXPname = 'ABR';
        EXPname2 = questdlg('Select ABR analysis:', ...
            'ABR Analysis', ...
            'Thresholds','Peaks','Thresholds');
        switch EXPname2
            case 1
                x_str = ["Click","0.5","1","2","4","8"];
                data = average.all_y;
            case 2
                x_str = ["w1","w2","w3","w4","w5"];
                data = average.all_y;   % need to fix this
            otherwise
                uiwait(msgbox('ERROR: Invalid selection','Analysis Type','error'));
        end

    case 2
        EXPname = 'EFR RAM';
        EXPname2 = questdlg('Select EFR RAM analysis:', ...
            'EFR RAM Analysis', ...
            'Sum Peaks','All Peaks','Sum Peaks');
       switch EXPname2
            case 1
                x_str = ["1-16"];  % all harmonics
                data = average.all_low_high_peaks;
            case 2
                x_str = round(average.peaks_locs{1,1});  % individual harmonics
                data = average.all_peaks;
            otherwise
                uiwait(msgbox('ERROR: Invalid selection','Analysis Type','error'));
        end

    case 3
        EXPname = 'OAE';
        OAEanalysis_options = {'DPOAE', 'SFOAE', 'TEOAE'};
        oae_type = listdlg('PromptString','Select OAE type: ','ListString',OAEanalysis_options,'SelectionMode','single','ListSize', [100 80]);
        switch oae_type
            case 1
                EXPname2 = 'DPOAE';
            case 2
                EXPname2 = 'SFOAE';
            case 3
                EXPname2 = 'TEOAE';
            otherwise
                uiwait(msgbox('ERROR: Invalid selection','Analysis Type','error'));
        end
    case 4
        EXPname = 'MEMR';
        EXPname2 = [];
    otherwise
        uiwait(msgbox('ERROR: Invalid selection','Analysis Type','error'));
end
end
function write_table(average,Conds2Run,x_str,relative_flag,filename)
subjects = average.subjects;
all_y = cell(size(data));
y = nan(size(data,1),size(Conds2Run,2)+1);
y_relative = nan(size(data,1),size(Conds2Run,2));
for x_idx = 1:length(x_str)
    for rows = 1:length(data)
        for cols = 1:width(data)
            all_y{rows,cols} = nan(1,length(x_str));
            if ~isempty(data{rows,cols})
                all_y{rows,cols}(x_idx) = data{rows,cols}(x_idx);
                if strcmp(EXPname2,'Sum Peaks')  % EFR RAM 
                    y(rows,cols) = data{rows,cols}(2)+data{rows,cols}(1);
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
    glm_table.Frequency = repmat(x_str(x_idx),1,length(y_glm))';
    glm_table.Frequency_Cat = x_idx*ones(1,length(y_glm))';
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
writetable(glm_long_table,filename_csv, ...
    'FileType', 'text', ...
    'Delimiter', ',', ...
    'QuoteStrings', true, ...
    'WriteVariableNames', true);

end