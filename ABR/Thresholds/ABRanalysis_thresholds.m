function ABRanalysis_thresholds(ROOTdir,CODEdir,datapath,outpath,subject,all_Conds2Run,CondIND)
close all; cwd = pwd; addpath(cwd);
condition = strsplit(all_Conds2Run{CondIND}, filesep);
%% Check files available (a-files vs p-files)
if exist(datapath,"dir")
    cd(datapath);
    p_datafiles = {dir(fullfile(cd,'p*ABR*.mat')).name}';
    a_datafiles = {dir(fullfile(cd,'a*ABR*.mat')).name}';
    if isempty(p_datafiles) && ~isempty(a_datafiles)     % run XCORR method (Henry)
        sprintf('Only a-files available - %s (%s).\n',subject,all_Conds2Run{CondIND});
        all_datafiles = a_datafiles;
        ABR_thresholds_template(ROOTdir,CODEdir,datapath,outpath,subject,all_datafiles,condition)
    elseif ~isempty(p_datafiles)  % run bootstrapping method (Andrew/Sam)
        all_datafiles = p_datafiles;
        ABR_thresholds_subaverage(datapath,outpath,subject,all_datafiles,condition)
    else
        sprintf('No a-files or p-files available - %s (%s).\n',subject,all_Conds2Run{CondIND});
    end

else
    sprintf('NO DATA DIRECTORY - %s (%s).\n',subject,all_Conds2Run{CondIND});
end
end