function [abr_xx2,delay_of_max]=threshold_calc_old

global abr_Stimuli num dt abr attn spl w data noise_local include_spl include_zscore include_w

%% Template waveform
txcor=nan(length(abr)*2-1,abr_Stimuli.num_templates);
delay=nan(1,abr_Stimuli.num_templates);
delay1=zeros(1,abr_Stimuli.num_templates);

% averages required number of templates making sure the peaks line up (i.e. correlation is max)
template1= zeros(bin_of_time(abr_Stimuli.end_template)-bin_of_time(abr_Stimuli.start_template)+1, abr_Stimuli.num_templates);
for i=1:abr_Stimuli.num_templates
    txcor(:,i)=xcorr(abr(:,i),abr(:,1));
    [~, delay1(i)]=max(txcor(:,i));
    delay(1,i)=(delay1(i)-delay1(1))*dt;
    template1(:,i)=abr(bin_of_time(abr_Stimuli.start_template+delay(1,i)):bin_of_time(abr_Stimuli.end_template+delay(1,i)),i);
    template1(:,i)=template1(:,i)-mean(template1(:,i));
end
template=mean(template1,2);

%% Cross-correlate template with noise
null_xx=xcorr((noise_local/20000*1000000),template); % both waves in uV: abr was normalized in load_abr_data: in the future, will normalize noise_local right away
null_xx2=null_xx(length(noise_local):length(noise_local)*2-length(template));
[peaks_vals, ~]= findpeaks(null_xx2, 'MinPeakHeight', 0);

mean_peak=mean(peaks_vals);
stdev_peak=std(peaks_vals);
% [mean_peak,stdev_peak]=find_meanstd_ofcorr_with_noise_local(template); %SP

%% Cross-correlate ABRs with template waveform
abr_xx=zeros(length(abr)*2-1,num);
for i = 1:num
    abr_xx(:,i) = xcorr(abr(:,i),template);
end
%Calculates z-score with abr data
abr_xx2=(abr_xx(size(abr,1):(size(abr,1)*2-length(template)),:)-mean_peak)/stdev_peak; %Z score

%% Measure the Z score of each ABR
data.z.score=nan(1,num);
bin_of_max=nan(1,num);
[data.z.score(1,1),bin_of_max(1,1)]=max(abr_xx2(:,1));
for i = 2:num
    add_attn=attn(1,i-1)-attn(1,i); 
    exp_bin=bin_of_max(1,i-1) + bin_of_time(add_attn/40) - 1;
    [data.z.score(1,i),delay]=max(abr_xx2(exp_bin-bin_of_time(1):exp_bin+bin_of_time(1),i));
    bin_of_max(1,i)=exp_bin-bin_of_time(1)+delay-1;
end
delay_of_max=time_of_bin(bin_of_max);

%% Set weights for regression analysis. Z scores below 3 have no weight.
%Weighting decreases with increasing Z score from 1 @ Z=3 to 0.1 @ max Z.
w=zeros(1,num);
for i=1:num
    w(1,i)=1-0.9*((data.z.score(1,i)-3)/(max(data.z.score(1,:))-3));
    if data.z.score(1,i)< 3.99
        w(1,i)=0;
    end
end
w(find(w==0, 1 ):end)=0;
w(find(w==0, 1))=1; %%SP (so the the regression doesn't become too flat)
% N_nonzero_in_w=sum(w~=0);
% w(1:N_nonzero_in_w-3)=0; % why? 


%% Weighted regression and threshold calculation
%HG ADDED 11/22/19
round_spl = round(spl);
find_spl = find(round_spl <= 60);
include_spl = spl(find_spl);
include_zscore = data.z.score(find_spl);
include_w = w(find_spl);
%X=ones(num,2);
%X(:,2)=spl';
X=ones(length(include_spl),2);
X(:,2)=include_spl';
%b=lscov3(X,data.z.score',w');
b=lscov3(X,include_zscore',include_w');
data.z.slope=b(2,1);
data.z.intercept=b(1,1);
data.threshold=(3-b(1,1))/b(2,1);