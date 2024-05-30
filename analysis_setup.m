clc; close all;
%% User Input:
% Chins2Run = list of subjects to analyze data
% Conds2Run = list of conditions to analyze data (baseline vs post)
Chins2Run={'Q460','Q461'};
Conds2Run = {strcat('pre',filesep,'Baseline_1')};
%% Analysis
cwd = pwd;
[EXPname, EXPname2] = analysis_menu;
if ~exist('ROOTdir','var')
    uiwait(msgbox('Press OK to select root directory','Root Directory','help'));
    ROOTdir = uigetdir('', 'Select the root directory');
    addpath(strcat(ROOTdir,filesep,'Code Archive'));
end
[DATAdir, OUTdir, CODEdir] = get_directory(ROOTdir,EXPname,EXPname2);
% Check if RAW data has been converted for analysis
files = cell(length(Chins2Run),length(Conds2Run));
for ChinIND=1:length(Chins2Run)
    for CondIND=1:length(Conds2Run)
        filepath = strcat(OUTdir,filesep,EXPname,filesep,Chins2Run{ChinIND},filesep,Conds2Run{CondIND});
        datapath = strcat(DATAdir,filesep,Chins2Run{ChinIND},filesep,EXPname,filesep,Conds2Run{CondIND});
        calibpath = datapath;
        files{ChinIND,CondIND} = search_files(Chins2Run{ChinIND},Conds2Run{CondIND},filepath);
        condition = strsplit(Conds2Run{CondIND}, filesep);
        cd(CODEdir);
        if isempty(files{ChinIND,CondIND}.files)    % convert RAW data for analysis
            fprintf('\nSubject: %s (%s)\n',Chins2Run{ChinIND},Conds2Run{CondIND});
            switch EXPname
                case 'ABR'
                    abr_plotting;
                case 'EFR'
                    EFRanalysis(datapath,calibpath,filepath,Chins2Run{ChinIND},condition{2});
                case 'OAE'
                    switch EXPname2
                        case 'DPOAE'
                            DPanalysis(datapath,calibpath,filepath,Chins2Run{ChinIND},condition{2});
                        case 'SFOAE'
                            SFanalysis(datapath,calibpath,filepath,Chins2Run{ChinIND},condition{2});
                        case 'TEOAE'
                            TEanalysis(datapath,calibpath,filepath,Chins2Run{ChinIND},condition{2});
                    end
                case 'MEMR'
                    WBMEMRanalysis(datapath,calibpath,filepath,Chins2Run{ChinIND},condition{2});
            end
        else
            fprintf('\nLoading Data for Averaging...\nSubject: %s (%s)\n',Chins2Run{ChinIND},Conds2Run{CondIND});
            switch EXPname
                case 'ABR'
                    
                case 'EFR'
                    
                case 'OAE'
                    switch EXPname2
                        case 'DPOAE'
                            DPsummary(filepath,OUTdir,Conds2Run,Chins2Run,ChinIND,CondIND);
                        case 'SFOAE'
                            
                        case 'TEOAE'
                            
                    end
                case 'MEMR'
                    
            end

        end
    end
end
cd(cwd);

