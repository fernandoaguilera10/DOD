%% Format Data
% Objective: transform short-format data into long-format data for statistical analysis
% Author: Fernando Aguilera de Alba
% Date: 15 January 2026
%% User Input
clear all; close all; clc;
if ismac    % Mac
    DATAdir = '/Users/fernandoaguileradealba/Library/Mobile Documents/com~apple~CloudDocs/Desktop/Purdue/Heinz Lab/Presentations/ASA 2026/Stats/RAW/Blast';
    OUTdir = '/Users/fernandoaguileradealba/Library/Mobile Documents/com~apple~CloudDocs/Desktop/Purdue/Heinz Lab/Presentations/ASA 2026/Stats/Data/Blast';
    ROOTdir = '/Volumes/FefeSSD/DOD/Code Archive/tools';
else        % Windows
    DATAdir = 'N/A';
end
Conds2Run = ["D3";"D7";"D14"]'; % Define grouping units (e.g., timepoints,conditions)
%Conds2Run = ["D5";"D12";"D26"]';
relative_flag = 0;  % 1 = relative to baseline      0 = do not compare to baseline
%% Script
[EXPname,EXPname2,search_file] = measure_menu();
[average,filename] = load_files(DATAdir,search_file);
if isstruct(average) && isfield(average,'individual') && istable(average.individual)
    % Group .mat files from APAT (Oct 2026 on) carry the tidy individual
    % table (apat_csv: Measure, Experiment, Subject, Sex, Condition, Reference,
    % Excluded, keys, Metric, Value, Units; files with several Experiments:
    % every Experiment stacked) — written as is; relative_flag
    % keeps the change rows (Reference set) instead of the absolute ones.
    I = average.individual;
    if ismember('Reference', I.Properties.VariableNames)
        isrel = ~cellfun(@isempty, cellstr(I.Reference));
        if relative_flag, I = I(isrel,:); else, I = I(~isrel,:); end
    end
    apat_write_csv(I, fullfile(OUTdir, [filename '.csv']));
    fprintf('Wrote %s\n', fullfile(OUTdir, [filename '.csv']));
    return
end
[data,x_str,filename] = define_data(average,EXPname,EXPname2,filename);
if strcmp(EXPname,'ABR') && strcmp(EXPname2,'Peaks')
    write_table_abr_peaks(data,average,Conds2Run,x_str,relative_flag,filename,OUTdir);
else
    write_table(data,average,Conds2Run,x_str,relative_flag,filename,EXPname,EXPname2,OUTdir);
end
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
        % Group averages: <Measure>/Average (Oct 16 2026 on: one file holds
        % every Experiment), then (older runs) an Average/<Group> folder, then
        % (old) loose in <Measure>
        avg_dir = fullfile(DATAdir,'Average');
        cand = {avg_dir};
        hit = '';
        for ci = 1:numel(cand)
            if exist(cand{ci},'dir') && ~isempty(dir(fullfile(cand{ci},datafile))), hit = cand{ci}; break; end
        end
        if isempty(hit) && exist(avg_dir,'dir')
            g = dir(fullfile(avg_dir,'*',datafile));
            g = g(~strncmp({g.name},'._',2));
            if ~isempty(g)
                gf = unique({g.folder});
                if numel(gf) == 1
                    hit = gf{1};
                else
                    [~, gn] = cellfun(@fileparts, gf, 'UniformOutput', false);
                    k = listdlg('PromptString','Select the analysis group:','ListString',gn, ...
                        'SelectionMode','single','ListSize',[220 120]);
                    if ~isempty(k), hit = gf{k}; end
                end
            end
        end
        if ~isempty(hit), cd(hit); end
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
    average = unwrap_average(filename);
    cd(cwd)
    filename = filename(1:end-4);
end
function average = unwrap_average(file)
% `average` of an APAT group file. Per-experiment files (variable
% `experiments`, average.<EXP>; apat_avg_mat): the individual tables of
% every Experiment stacked when all have one, else the Experiment picked
% from a list. Older files: the plain struct.
L = apat_avg_mat('load', file, 'average');
average = [];
if isempty(L), return; end
if numel(L) == 1, average = L(1).value; return; end
has = arrayfun(@(e) isstruct(e.value) && isfield(e.value,'individual') && istable(e.value.individual), L);
if all(has)
    average = struct('individual', {vertcat_tables(arrayfun(@(e) e.value.individual, L, 'UniformOutput', false))});
    return
end
k = listdlg('PromptString','Select the experiment:','ListString',{L.experiment}, ...
    'SelectionMode','single','ListSize',[220 120]);
if isempty(k), k = 1; end
average = L(k).value;
end
function T = vertcat_tables(C)
% stack tables whose columns may differ (missing: '' / NaN)
names = {};
for i = 1:numel(C), names = [names, setdiff(C{i}.Properties.VariableNames, names, 'stable')]; end %#ok<AGROW>
for i = 1:numel(C)
    for m = setdiff(names, C{i}.Properties.VariableNames, 'stable')
        r = [];
        for q = 1:numel(C), if ismember(m{1}, C{q}.Properties.VariableNames), r = C{q}.(m{1}); break; end, end
        if iscell(r), C{i}.(m{1}) = repmat({''}, height(C{i}), 1); else, C{i}.(m{1}) = nan(height(C{i}), 1); end
    end
    C{i} = C{i}(:, names);
end
T = vertcat(C{:});
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
                wave_fields = {'all_w1','all_w2','all_w3','all_w4','all_w5'};
                n_subj = size(average.all_w1, 1);
                n_cond = size(average.all_w1, 2);
                data = cell(n_subj, n_cond);
                for r = 1:n_subj
                    for c = 1:n_cond
                        if ~isempty(average.all_w1{r,c})
                            n_lvl = length(average.all_w1{r,c});
                            mat = NaN(n_lvl, 5);
                            for w = 1:5
                                if ~isempty(average.(wave_fields{w}){r,c})
                                    mat(:, w) = average.(wave_fields{w}){r,c};
                                end
                            end
                            data{r,c} = mat;  % [n_levels × 5]
                        end
                    end
                end
        end

    case 'EFR-RAM'
            x_str = round(average.peaks_locs{1,1});  % individual harmonics
            data = average.all_peaks;
            out_filename = filename;

    case 'EFR-dAM'
            x_str = round(average.trajectory{1,1});  % frequency trajectory
            calcSNR = @(d, n) d - n; % SNR in dB: signal minus noise floor
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
    glm_table.Frequency_Index = x_idx*ones(1,size(y_glm,1))';
    glm_long_table_new = stack(glm_table,{Conds2Run},'NewDataVariableName','Value','IndexVariableName','Condition');
    if x_idx == 1
        glm_long_table = glm_long_table_new;   % initialize
    else
        glm_long_table = [glm_long_table ; glm_long_table_new];
    end
end
for k = 1:length(Conds2Run)
    glm_long_table.Condition_Index(glm_long_table.Condition == Conds2Run(k)) = k;
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
function write_table_abr_peaks(data,average,Conds2Run,x_str,relative_flag,filename,OUTdir)
cwd = pwd;
subjects = average.subjects;
wave_names = x_str;  % ["w1","w2","w3","w4","w5"]

% Get stimulus levels from first non-empty condition in average.x
level_vals = [];
for c = 1:length(average.x)
    if ~isempty(average.x{c})
        level_vals = average.x{c};
        break;
    end
end
n_levels = length(level_vals);
n_waves  = length(wave_names);
n_subj   = size(data, 1);
n_cond   = size(data, 2);

if relative_flag == 0
    Conds2Run = ["Baseline", Conds2Run];
end

glm_long_table = [];

for w_idx = 1:n_waves
    for lvl_idx = 1:n_levels
        y = nan(n_subj, n_cond);
        for r = 1:n_subj
            for c = 1:n_cond
                if ~isempty(data{r,c}) && lvl_idx <= size(data{r,c},1)
                    y(r,c) = data{r,c}(lvl_idx, w_idx);
                end
            end
        end

        y_relative = nan(n_subj, n_cond-1);
        for c = 1:size(y_relative,2)
            y_relative(:,c) = y(:,c+1) - y(:,1);
        end

        if relative_flag
            y_glm = y_relative;
        else
            y_glm = y;
        end

        glm_table = array2table(y_glm, 'VariableNames', Conds2Run);
        glm_table.Subject   = subjects';
        glm_table.Wave      = repmat(wave_names(w_idx), n_subj, 1);
        glm_table.Wave_Index  = w_idx * ones(n_subj, 1);
        glm_table.Level_dBSPL = repmat(level_vals(lvl_idx), n_subj, 1);
        glm_table.Level_Index = lvl_idx * ones(n_subj, 1);

        glm_long_new = stack(glm_table, {Conds2Run}, ...
            'NewDataVariableName', 'Value', ...
            'IndexVariableName',   'Condition');

        if isempty(glm_long_table)
            glm_long_table = glm_long_new;
        else
            glm_long_table = [glm_long_table; glm_long_new];
        end
    end
end

for k = 1:length(Conds2Run)
    glm_long_table.Condition_Index(glm_long_table.Condition == Conds2Run(k)) = k;
end

filename_csv = strcat(filename, '.csv');
cd(OUTdir)
writetable(glm_long_table, filename_csv, ...
    'FileType',           'text', ...
    'Delimiter',          ',', ...
    'QuoteStrings',       true, ...
    'WriteVariableNames', true);
cd(cwd)
end