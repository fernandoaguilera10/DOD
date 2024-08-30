function [abr_xx2,delay_of_max]=threshold_calc_SDT_SP

global abr_Stimuli num dt abr attn spl w data noise_local

%% Template waveform
txcor=nan(length(abr)*2-1,abr_Stimuli.num_templates);
delay=nan(1,abr_Stimuli.num_templates);
delay1=zeros(1,abr_Stimuli.num_templates);


for i=1:abr_Stimuli.num_templates
    txcor(:,i)=xcorr(abr(:,i),abr(:,1));
    [~, delay1(i)]=max(txcor(:,i));
    delay(1,i)=(delay1(i)-delay1(1))*dt;
    template1(:,i)=abr(bin_of_time(abr_Stimuli.start_template+delay(1,i)):bin_of_time(abr_Stimuli.end_template+delay(1,i)),i);
end
template=mean(template1,2);


%% Cross-correlate template with noise
% null_xx=xcorr((noise_local/20000*1000000),template); % both waves in uV
% null_xx2=null_xx(length(noise_local):length(noise_local)*2-length(template),1);
% peaks=[];
% count=0;
% for i=2:length(null_xx2)-1
%     if (null_xx2(i,1)>0) && (null_xx2(i,1)>null_xx2(i-1,1)) && (null_xx2(i,1)>null_xx2(i+1,1))
%         count=count+1;
%         peaks(count)=null_xx2(i,1); 
%     end
% end
% 
% mean_peak=mean(peaks);
% stdev_peak=std(peaks);
% [mean_peak,stdev_peak]=find_meanstd_ofcorr_with_noise_local(template); %SP

%% Cross-correlate ABRs with template waveform
abr_xx=zeros(length(abr)*2-1,num);
for i = 1:num
    abr_xx(:,i) = xcorr(abr(:,i),template);
end
abr_xx2=abr_xx(length(abr):length(abr)*2-length(template),:);

%% Measure the Z score of each ABR
data.z.score=nan(1,num);
bin_of_max=nan(1,num);
[data.z.score(1,1),bin_of_max(1,1)]=max(abr_xx2(:,1));

for i = 2:num
    add_attn=attn(1,i-1)-attn(1,i); 
    expexted_bin=bin_of_max(1,i-1) + bin_of_time(add_attn/40) - 1;
    [data.z.score(1,i),delay]=max(abr_xx2(expexted_bin-bin_of_time(1):expexted_bin+bin_of_time(1),i));
    bin_of_max(1,i)=expexted_bin-bin_of_time(1)+delay-1;
end
delay_of_max=time_of_bin(bin_of_max);

corr_ratio=fliplr(data.z.score);
for i=2:length(corr_ratio)
    if corr_ratio(i)<corr_ratio(i-1)
        corr_ratio(i)=corr_ratio(i-1);
    end
end

pSDT=corr_ratio/max(corr_ratio);
pSDT(pSDT==1)=.99;
zpSDT=norminv(pSDT);
cum_d_prime=cumsum([0 diff(zpSDT)]);

ind_theta_1= find(cum_d_prime<1, 1, 'last');
ind_theta_2= find(cum_d_prime>1, 1);
flag_plot_cum_dprime=0;
if (ind_theta_2-ind_theta_1)~=1
    fprintf(2, 'this should not have happened\n');
elseif flag_plot_cum_dprime
    flipped_spl=fliplr(spl);
    theta_cum_d_prime=interp1(cum_d_prime(ind_theta_1:ind_theta_2), flipped_spl(ind_theta_1:ind_theta_2), 1);
    
    figure(111);
    clf;
    plot(fliplr(spl), cum_d_prime);
    hold on;
    plot(fliplr(spl), cum_d_prime,'*');
    plot([min(spl) max(spl)],[1 1],'k');
    title(['$ \theta=' sprintf('%.1f', theta_cum_d_prime) '\  dB SPL$'], 'interpreter', 'latex');
    ylabel('Cumulative d-prime');
    xlabel('SPL (dB)');
    grid on;
end

%% Set weights for regression analysis. Z scores below 3 have no weight.
%Weighting decreases with increasing Z score from 1 @ Z=3 to 0.1 @ max Z.
w=zeros(1,num);
for i=1:num
    w(1,i)=1-0.9*((data.z.score(1,i)-3)/(max(data.z.score(1,:))-3));
    if data.z.score(1,i)<3
        w(1,i)=0;
    end
end
w(find(w==0, 1 ):end)=0;
w(find(w==0, 1))=1; %%SP (so the the regression doesn't become too flat)
N_nonzero_in_w=sum(w~=0);
w(1:N_nonzero_in_w-3)=0;


%% Weighted regression and threshold calculation
X=ones(num,2);
X(:,2)=spl';
b=lscov3(X,data.z.score',w');
data.z.slope=b(2,1);
data.z.intercept=b(1,1);
data.threshold=(3-b(1,1))/b(2,1);