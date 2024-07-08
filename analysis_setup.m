clc; close all;
%% User Input:
% Chins2Run = list of subjects to analyze data
% Conds2Run = list of conditions to analyze data (baseline vs post)
Chins2Run={'Q438','Q445','Q446','Q447'};
Conds2Run = {strcat('pre',filesep,'Baseline_2'),strcat('post',filesep,'D7'),strcat('post',filesep,'D14'),strcat('post',filesep,'D30')};
plot_relative = {strcat('pre',filesep,'Baseline_2')};
ylimits_oae = [-80,60];
xlimits_memr = [50,100];
ylimits_efr = [-1,1];
%% Analysis
cwd = pwd;
if ~isempty(plot_relative)
    idx_plot_relative = ismember(plot_relative,Conds2Run);
else
    idx_plot_relative = [];
end
[EXPname, EXPname2] = analysis_menu;
if ~exist('ROOTdir','var')
    uiwait(msgbox('Press OK to select root directory','Root Directory','help'));
    ROOTdir = uigetdir('', 'Select the root directory');
    addpath(strcat(ROOTdir,filesep,'Code Archive'));
end
[DATAdir, OUTdir, CODEdir] = get_directory(ROOTdir,EXPname,EXPname2);
if strcmp(EXPname,'OAE')
    searchfile = ['*',EXPname2,'*.mat'];
else
    searchfile = ['*',EXPname,'*.mat'];
end
% Check if RAW data has been converted for analysis
flag = 0;
files = cell(length(Chins2Run),length(Conds2Run));
for ChinIND=1:length(Chins2Run)
    for CondIND=1:length(Conds2Run)
        filepath = strcat(OUTdir,filesep,EXPname,filesep,Chins2Run{ChinIND},filesep,Conds2Run{CondIND});
        datapath = strcat(DATAdir,filesep,Chins2Run{ChinIND},filesep,EXPname,filesep,Conds2Run{CondIND});
        calibpath = datapath;
        files{ChinIND,CondIND} = search_files(Chins2Run{ChinIND},Conds2Run{CondIND},filepath);
        file_check =  dir(fullfile(files{ChinIND,CondIND}.dir,searchfile));
        condition = strsplit(Conds2Run{CondIND}, filesep);
        cd(CODEdir);
        if isempty(file_check)    % convert RAW data for analysis
            fprintf('\nSubject: %s (%s)\n',Chins2Run{ChinIND},Conds2Run{CondIND});
            switch EXPname
                case 'ABR'
                    abr_type = questdlg('Select ABR analysis:', ...
                        'ABR Analysis', ...
                        'Thresholds','Peaks','Peaks');
                    % Handle response
                    switch abr_type
                        case 'Thresholds'
                            cd([CODEdir,filesep,'Thresholds'])
                            abr_out = ABR_audiogram_chin(datapath,filepath,Chins2Run{ChinIND},Conds2Run,CondIND);
                        case 'Peaks'
                            cd([CODEdir,filesep,'Peaks'])
                            %% TBD FUNCTION
                    end
                case 'EFR'
                    cd([CODEdir,filesep,'RAM'])
                    EFRanalysis(datapath,filepath,Chins2Run{ChinIND},condition{2});
                    cd(CODEdir)
                case 'OAE'
                    switch EXPname2
                        case 'DPOAE'
                            DPanalysis(datapath,filepath,Chins2Run{ChinIND},condition{2});
                        case 'SFOAE'
                            SFanalysis(datapath,filepath,Chins2Run{ChinIND},condition{2});
                        case 'TEOAE'
                            TEanalysis(datapath,filepath,Chins2Run{ChinIND},condition{2});
                    end
                case 'MEMR'
                    WBMEMRanalysis(datapath,filepath,Chins2Run{ChinIND},condition{2});
            end
        else
            fprintf('\nLoading Data for Averaging...\nSubject: %s (%s)\n',Chins2Run{ChinIND},Conds2Run{CondIND});
            switch EXPname
                case 'ABR'
                    %% TBD FUNCTION
                case 'EFR'
                    cd([CODEdir,filesep,'RAM'])
                    if flag == 0
                        answer = questdlg('Select EFR level:', ...
                            'EFR Level', ...
                            '65 dB SPL','80 dB SPL','80 dB SPL');
                        % Handle response
                        switch answer
                            case '65 dB SPL'
                                efr_level = 65;
                            case '80 dB SPL'
                                efr_level = 80;
                        end
                        flag = 1;
                    end
                    EFRsummary(filepath,OUTdir,Conds2Run,Chins2Run,ChinIND,CondIND,ylimits_efr,idx_plot_relative,efr_level);
                case 'OAE'
                    switch EXPname2
                        case 'DPOAE'
                            DPsummary(filepath,OUTdir,Conds2Run,Chins2Run,ChinIND,CondIND,idx_plot_relative,ylimits_oae);
                        case 'SFOAE'
                            SFsummary(filepath,OUTdir,Conds2Run,Chins2Run,ChinIND,CondIND,idx_plot_relative,ylimits_oae);
                        case 'TEOAE'
                            TEsummary(filepath,OUTdir,Conds2Run,Chins2Run,ChinIND,CondIND,idx_plot_relative,ylimits_oae);
                    end
                case 'MEMR'
                    WBMEMRsummary(filepath,OUTdir,Conds2Run,Chins2Run,ChinIND,CondIND,idx_plot_relative,xlimits_memr)
            end
        end
    end
end
cd(cwd);

