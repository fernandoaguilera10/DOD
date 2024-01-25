function [f,P1_env,P1_tfs,PLV_env,PLV_tfs] = getSpectMag(pos_r,neg_r,Fs)
%Returns the mean raw spectral magnitude in dB
% Example:
% pos = all positive trials
% neg = all negative trials
% Fs0 = 48828.125; %sampling rate in
% Fs = 15e3 (example); %resample to
% numtrials = 100; %Number of trials to pull per polarity
%% Remove DC

pos_r = pos_r-mean(pos_r);
neg_r = neg_r-mean(neg_r);

%% Create FFT Matrices of pos and neg data for analysis
%remember fft is applied to COLUMNS

pos_fft = fft(pos_r*1e6);
neg_fft = fft(neg_r*1e6);

sum_pos = sum(pos_fft,2);
sum_neg = sum(neg_fft,2);

sum_all = (sum_pos+sum_neg)/(2*size(pos_r,2));
%sum_all = (sum_pos)/(size(pos_r,2));

L = length(sum_all);

P2 = 20*log10((abs(sum_all/(L)))); %Taking the average numtrials*2??
P2 = 20*log10(((sum_all/(L))));
P1_env = P2(1:floor(L/2)+1);

f = Fs*(0:(L/2))/L;

%TFS
sum_all = (sum_pos-sum_neg)/(2*size(pos_r,2));

L = length(sum_all);

P2 = 20*log10((abs(sum_all/(L)))); %Taking the average numtrials*2??
P2 = 20*log10(((sum_all/(L)))); %Taking the average numtrials*2??
P1_tfs = P2(1:floor(L/2)+1);


%% Calculate PLV
pos_phase = angle(pos_fft(1:floor(L/2)+1,:));
pos_vector = sum(exp(1i*pos_phase),2);

neg_phase = angle(neg_fft(1:floor(L/2)+1,:));
neg_vector = sum(exp(1i*neg_phase),2);

PLV_env = abs(pos_vector+neg_vector)/(size(pos_r,2)*2);
%PLV_env = abs(pos_vector)/(size(pos_r,2)*2);

PLV_tfs = abs(pos_vector-neg_vector)/(size(pos_r,2)*2);

%% Calculate the mean of all trials
% %Setting this up in a way that should work well with the above logic
% 
% pos_sum = zeros([1,length(pos{1})]);
% neg_sum = zeros([1,length(neg{1})]);
% 
% %Compute the averages of pos and neg polarities, remove DC, and get a sum
% for i = 1:numtrials
%     pos_sum = pos_r{i} + pos_sum;
% end
% 
% mean_pos = (pos_sum-mean(pos_sum))/numtrials;
% 
% for i = 1:numtrials
%     neg_sum = neg_r{i} + neg_sum;
% end
% 
% mean_neg = (neg_sum-mean(neg_sum))/numtrials;
% 
% sum_all = mean_pos+mean_neg;
% %% FFT
% mag_envresponse = fft(sum_all*1e6);
% L = length(sum_all);
% P2 = 20*log10((abs(mag_envresponse/L)));
% P1 = P2(1:L/2+1);
% 
% f = Fs*(0:(L/2))/L;
% 
% %% PLV
% % 
%   pos_fft = fft(mean_pos*1e6);
%   L = length(sum_all);
%   pos_phase = angle(pos_fft(1:L/2+1));
%   pos_vector = exp(1i*pos_phase);
%   
%   neg_fft = fft(mean_neg*1e6);
%   L = length(sum_all);
%   neg_phase = angle(neg_fft(1:L/2+1));
%   neg_vector = exp(1i*neg_phase);
% 
% %PLV = angle(mag_envresponse);
% %PLV = PLV(1:L/2+1);

end

