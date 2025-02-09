%Author (s): Andrew Sivaprakasam
%Last Updated: May, 2024
%Description: Script to process ABR high level clicks using Dynamic Time
%Warping

%TODO: 
% - Account for NEL latency differences
% - What if multiple click files? Should user pick the right one?
condition = 'Baseline';
subj = 'Q438';
template = load("single_exemplar_chin.mat");

cwd = pwd();
addpath(cwd)
cd(datapath);
%% Load files
datafiles = {dir(fullfile(cd,'a*click*.mat')).name};
for f = 1:length(datafiles)
    matches = regexp(datafiles{f},'a(\d+)_', 'tokens');
    pics(f) = str2double(matches{1}{1});
end

[~,I] = min(pics);
load(datafiles{I});

%abr_data = x.AD_Data.AD_Avg_V{1}{1};
abr_data = x.AD_Data.AD_Avg_V;
%% Resample and make sure the level is correct

fs = 8e3;
abr_data = resample(abr_data,fs,round(x.Stimuli.RPsamprate_Hz));
abr_t = (1:length(abr_data))/fs;

lev = round(x.Stimuli.MaxdBSPLCalib-x.Stimuli.atten_dB);

if lev ~= 90
    warning(['Level not 90 dB SPL! Check ABR Files for Chin: ', subj])
end 

%% Apply template
abr_template = template.abr;
abr_points = template.points;
abr_t_template = template.t;


[pks,lats] = findPeaks_dtw(abr_t_template,abr_data,abr_template,abr_points);

%% Export and end
cd(cwd);