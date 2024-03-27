%% EFRsummary
% Load Data
cwd = pwd;
cd(outpath)
fname = ['*',subj,'_DPOAEswept_',condition,'*.mat'];
datafile = {dir(fname).name};
if length(datafile) > 1
    fprintf('More than 1 data file. Check this is correct file!\n');
    datafile = {uigetfile(fname)};
end
if isempty(datafile)
    fprintf('No file found. Please analyze raw data first.\n');
end
load(datafile{1});
cd(cwd);