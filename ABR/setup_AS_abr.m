%Setup file for directory information (ABR threshold)

close all;
clear;

set(0,'defaultfigurerenderer','painters')

condition = ['pre',filesep,'Baseline_1'];
subj = 'Q473';

export = 0;
mode = 0; %0 - Process single chin, 1 - plot single chin pre/post, 2 - batch process all, 3 - plot compiled pre-post for all

prefix = '/Users/fernandoaguileradealba/Desktop/DOD-Analysis/Data';

%if processing click, put a 0 in freqs
freqs = [500,1e3,2e3,4e3,8e3];
% freqs = [500,4e3,0]; 

switch mode 
    case 0 
        disp("Processing Single Chin...");

        suffix = [filesep,subj,filesep,'ABR',filesep,condition];
        datapath = [prefix,suffix];

        ABR_audiogram_chin;
    case 1
        warning("Sorry, will come back to this. For now, look at the summary plots in case 3")
%         disp("Processing Single Chin Pre vs Post...")
    case 2 
        disp("Batch Processing every chin, pre and post...This might take a while!")
        datapath = prefix;
        conditions = ["Baseline","CA_2wksPost","TTS_2wksPost","PTS_2wksPost","GE_1wkPost"];
        Run_batchMode;
    case 3
        disp("Plotting summarized chin data");
        datapath = prefix;
        make_abr_summary_plots;
end






