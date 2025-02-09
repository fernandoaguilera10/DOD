%Setup file for directory information (ABR threshold)

close all;
clear;

set(0,'defaultfigurerenderer','painters')

condition = 'Baseline';
subj = 'Q438';

export = 1;
mode = 0; %0 - Process single chin, 1 - plot single chin pre/post, 2 - batch process all, 3 - plot compiled pre-post for all

uname = 'sivaprakasaman';
prefix = ['/media/',uname,'/AndrewNVME/Pitch_Study/Pitch_Diagnostics_SH_AS/ABR/Chin/'];

%Load Template
template = load("single_exemplar_chin.mat");

switch mode 
    case 0 
        disp("Processing Single Chin...");

        suffix = [condition,'/',subj];
        datapath = [prefix,suffix];

        processClick;
%     case 1
%         warning("Sorry, will come back to this. For now, look at the summary plots in case 3")
% %         disp("Processing Single Chin Pre vs Post...")
%     case 2 
%         disp("Batch Processing every chin, pre and post...This might take a while!")
%         datapath = prefix;
%         conditions = ["Baseline","CA_2wksPost","TTS_2wksPost","PTS_2wksPost","GE_1wkPost"];
%         Run_batchMode;
%     case 3
%         disp("Plotting summarized chin data");
%         datapath = prefix;
%         make_abr_summary_plots;
end






