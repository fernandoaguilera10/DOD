function preprocessALL_ABRs(ROOTdir,DATAdir,ANALYSISdir,Chins2Run,Conds2Run,ChinIND,CondIND)
%% Save basic processed ABR data for a list of chins and conditions
%
% M. Heinz
% Jan 21 2019
% updated: Apr 23 2020 for finalizing paper (M. Heinz)
% * modifying some figs to be consistent from individ conds to chin to AVG 
% * adding in W1/5 ratio
% * separating latencies since we probably won't use those in paper
% * removing pre/post comparisons here since in analyzeABRs_AVG
% NOTE: for Hannah's ABRs, where abr_analysis gets run on raw data, we put
% those waterfalls in Analysis.  probably want those in Data in future? 
%
% preprocessALL_ABR - runs through all chins, all conditions
%   Saves. ABRDATA as full structure {Chin x Cond} cell array of ABRDATA1,
%   as well as the summary charts we actually will use (Chin x Cond). Saves
%   TIF pre-vs-post figs for each chin, and sumamry AVG TIF pre-vs-post.
% preprocess1_ABR - runs through ALL ABR for a single chin/condition (i.e,
%   all freqs and levels - saves P1,N1, P5, N1 amps and Latencies for top 3
%   levels.  Saves ABRDATA1 for each chin/condition, and TIF file.
%
% Run through list of:
%    1) chins
%    2) conditions
% 
Freqs2Run = {'click','500Hz','1kHz','2kHz','4kHz','8kHz'};
Freqs2Run_vector = [0, 500, 1000, 2000, 4000, 8000];
[abrDATA1] = preprocess1_ABR(DATAdir,ANALYSISdir,Chins2Run{ChinIND},Conds2Run{CondIND},Freqs2Run,Freqs2Run_vector);
end