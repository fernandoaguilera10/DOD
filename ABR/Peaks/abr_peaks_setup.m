function abr_peaks_setup(ROOTdir,datapath,outpath,subject,condition)
global abr_root_dir abr_data_dir abr_out_dir animal ChinCondition ChinID
ChinID = subject;
ChinCondition = condition;
animal = ChinID(2:end);
abr_root_dir = ROOTdir;
abr_data_dir = datapath;
abr_out_dir = outpath;
addpath(abr_data_dir)
addpath(abr_root_dir)
if ~exist(abr_out_dir,'dir')
    mkdir(abr_out_dir);
end
abr_analysis_HL;
end