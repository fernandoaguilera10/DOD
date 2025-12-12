warning off; clc; close all; clear all;
Conds2Run = ["D3";"D14";"D28"]';
%Conds2Run = ["D7";"D14";"D30"]';
relative_flag = 1;
%% ABR Thresholds
data = average.all_y;
freq_str = ["Click","0.5","1","2","4","8"];
subjects = average.subjects;
all_y = cell(size(data));
y = nan(size(data,1),size(Conds2Run,2)+1);
y_relative = nan(size(data,1),size(Conds2Run,2));
for freq_idx = 1:length(freq_str)
    for rows = 1:length(data)
        for cols = 1:width(data)
            all_y{rows,cols} = nan(1,length(freq_str));
            if ~isempty(data{rows,cols})
                all_y{rows,cols}(freq_idx) = data{rows,cols}(freq_idx);
                y(rows,cols) = data{rows,cols}(freq_idx);
            end
        end
    end
    for cols = 1:width(y_relative)
        y_relative(:,cols) = y(:,cols+1)-y(:,1);
    end
    
    if relative_flag
        oae_glm = y_relative;
    else
        oae_glm = y;
    end
    % GLM - fixed effects
    glm_table = array2table(oae_glm,'VariableNames',Conds2Run);
    glm_table.Subject = subjects;
    glm_table.Frequency = repmat(freq_str(freq_idx),1,length(oae_glm))';
    glm_table.Frequency_Cat = freq_idx*ones(1,length(oae_glm))';
    glm_long_table_new = stack(glm_table,{Conds2Run},'NewDataVariableName','y','IndexVariableName','Timepoint');
    if freq_idx == 1
        glm_long_table = glm_long_table_new;   % initialize
    else
        glm_long_table = [glm_long_table ; glm_long_table_new];
    end
end
for k = 1:length(Conds2Run)
    glm_long_table.Timepoints_Cat(glm_long_table.Timepoint == Conds2Run(k)) = k;
end
writetable(glm_long_table, 'ABR.csv', ...
    'FileType', 'text', ...
    'Delimiter', ',', ...
    'QuoteStrings', true, ...
    'WriteVariableNames', true);
%% EFR PLV Total Sum
data = average.all_low_high_peaks;
freq_str = ["1-16"];  % harmonics
subjects = average.subjects;
all_y = cell(size(data));
y = nan(size(data,1),size(Conds2Run,2)+1);
y_relative = nan(size(data,1),size(Conds2Run,2));
for freq_idx = 1:length(freq_str)
    for rows = 1:length(data)
        for cols = 1:width(data)
            all_y{rows,cols} = nan(1,length(freq_str));
            if ~isempty(data{rows,cols})
                all_y{rows,cols}(freq_idx) = data{rows,cols}(freq_idx);
                y(rows,cols) = data{rows,cols}(2)+data{rows,cols}(1);
            end
        end
    end
    for cols = 1:width(y_relative)
        y_relative(:,cols) = y(:,cols+1)-y(:,1);
    end
    
    if relative_flag
        oae_glm = y_relative;
    else
        oae_glm = y;
    end
    % GLM - fixed effects
    glm_table = array2table(oae_glm,'VariableNames',Conds2Run);
    glm_table.Subject = subjects;
    glm_table.Frequency = repmat(freq_str(freq_idx),1,length(oae_glm))';
    glm_table.Frequency_Cat = freq_idx*ones(1,length(oae_glm))';
    glm_long_table_new = stack(glm_table,{Conds2Run},'NewDataVariableName','y','IndexVariableName','Timepoint');
    if freq_idx == 1
        glm_long_table = glm_long_table_new;   % initialize
    else
        glm_long_table = [glm_long_table ; glm_long_table_new];
    end
end
for k = 1:length(Conds2Run)
    glm_long_table.Timepoints_Cat(glm_long_table.Timepoint == Conds2Run(k)) = k;
end
writetable(glm_long_table, 'EFR_sum.csv', ...
    'FileType', 'text', ...
    'Delimiter', ',', ...
    'QuoteStrings', true, ...
    'WriteVariableNames', true);
%% EFR PLV Individual Harmonics
data = average.all_peaks;
freq_str = round(average.peaks_locs{1,1});  % harmonics
subjects = average.subjects;
all_y = cell(size(data));
y = nan(size(data,1),size(Conds2Run,2)+1);
y_relative = nan(size(data,1),size(Conds2Run,2));
for freq_idx = 1:length(freq_str)
    for rows = 1:length(data)
        for cols = 1:width(data)
            all_y{rows,cols} = nan(1,length(freq_str));
            if ~isempty(data{rows,cols})
                all_y{rows,cols}(freq_idx) = data{rows,cols}(freq_idx);
                y(rows,cols) = data{rows,cols}(freq_idx);
            end
        end
    end
    for cols = 1:width(y_relative)
        y_relative(:,cols) = y(:,cols+1)-y(:,1);
    end
    
    if relative_flag
        oae_glm = y_relative;
    else
        oae_glm = y;
    end
    % GLM - fixed effects
    glm_table = array2table(oae_glm,'VariableNames',Conds2Run);
    glm_table.Subject = subjects;
    glm_table.Frequency = round(freq_str(freq_idx),2)*ones(1,length(oae_glm))';
    glm_table.Frequency_Cat = freq_idx*ones(1,length(oae_glm))';
    glm_long_table_new = stack(glm_table,{Conds2Run},'NewDataVariableName','y','IndexVariableName','Timepoint');
    if freq_idx == 1
        glm_long_table = glm_long_table_new;   % initialize
    else
        glm_long_table = [glm_long_table ; glm_long_table_new];
    end
end
for k = 1:length(Conds2Run)
    glm_long_table.Timepoints_Cat(glm_long_table.Timepoint == Conds2Run(k)) = k;
end
writetable(glm_long_table, 'EFR_harmonics.csv', ...
    'FileType', 'text', ...
    'Delimiter', ',', ...
    'QuoteStrings', true, ...
    'WriteVariableNames', true);
%% OAE
data = average.all_oae_band;
freq_str = average.bandF;  % band average in kHz
subjects = average.subjects;
all_y = cell(size(data));
y = nan(size(data,1),size(Conds2Run,2)+1);
y_relative = nan(size(data,1),size(Conds2Run,2));
for freq_idx = 1:length(freq_str)
    for rows = 1:length(data)
        for cols = 1:width(data)
            all_y{rows,cols} = nan(1,length(freq_str));
            if ~isempty(data{rows,cols})
                all_y{rows,cols}(freq_idx) = data{rows,cols}(freq_idx);
                y(rows,cols) = data{rows,cols}(freq_idx);
            end
        end
    end
    for cols = 1:width(y_relative)
        y_relative(:,cols) = y(:,cols+1)-y(:,1);
    end
    
    if relative_flag
        oae_glm = y_relative;
    else
        oae_glm = y;
    end
    % GLM - fixed effects
    glm_table = array2table(oae_glm,'VariableNames',Conds2Run);
    glm_table.Subject = subjects;
    glm_table.Frequency = round(freq_str(freq_idx),2)*ones(1,length(oae_glm))';
    glm_table.Frequency_Cat = freq_idx*ones(1,length(oae_glm))';
    glm_long_table_new = stack(glm_table,{Conds2Run},'NewDataVariableName','y','IndexVariableName','Timepoint');
    if freq_idx == 1
        glm_long_table = glm_long_table_new;   % initialize
    else
        glm_long_table = [glm_long_table ; glm_long_table_new];
    end
end
for k = 1:length(Conds2Run)
    glm_long_table.Timepoints_Cat(glm_long_table.Timepoint == Conds2Run(k)) = k;
end
writetable(glm_long_table, 'OAE.csv', ...
    'FileType', 'text', ...
    'Delimiter', ',', ...
    'QuoteStrings', true, ...
    'WriteVariableNames', true);
%% MEMR Thresholds
criteria = 0.3;
level = average.elicitor{1,1};
memr_thresholds = nan(size(average.all_deltapow));
for rows = 1:length(average.all_deltapow)
    for cols = 1:width(average.all_deltapow)
        if ~isempty(average.all_deltapow{rows,cols})
            memr_avg = mean(average.all_deltapow{rows,cols});
            memr_std = std(average.all_deltapow{rows,cols});
            memr = average.all_deltapow{rows,cols};
            memr = memr/max(memr);
            memr_crit = level(find(memr >= criteria));
            if ~isempty(memr_crit)
                memr_thresholds(rows,cols) = memr_crit(1);
            end
        end
    end
end