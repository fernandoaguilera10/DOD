function thresh=threshold_calc_new

global abr_Stimuli num abr attn spl w data ThreshTypeCorrCovDist 

%% Template waveform

warning('missing the shift to match peak and add for template estimate that in threshold_calc_old');
IndicesInTemplate=bin_of_time(abr_Stimuli.start_template):bin_of_time(abr_Stimuli.end_template);
template1=zeros(length(IndicesInTemplate),abr_Stimuli.num_templates);
for i=1:abr_Stimuli.num_templates
    template1(:,i)=abr(IndicesInTemplate,i);
end
template=mean(template1,2);

%% Cross-correlate template with noise

% for i=1:length(peaks)
%     peaks(i)=corr2(template,abr(end/2+IndicesInTemplate,i));
% end

[mean_peak,stdev_peak]=find_meanstd_ofcorr_with_noise_local(template);

% mean_peak=mean(peaks);
% stdev_peak=std(peaks);

%% Cross-correlate ABRs with template waveform
abr_xx=zeros(length(abr)*2-1,num);
for i = 1:num
    abr_xx(:,i) = xcorr(abr(:,i),template);
end
abr_xx2=(abr_xx(length(abr):length(abr)*2-length(template),:)-mean_peak)/stdev_peak; %Z score

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
% delay_of_max=time_of_bin(bin_of_max);

if ThreshTypeCorrCovDist==1
    temp_corr=corr(abr(IndicesInTemplate,:),template)';
elseif ThreshTypeCorrCovDist==2
    temp_corr=cov([abr(IndicesInTemplate,:),template])';
    temp_corr=temp_corr(1:end-1,1)';
else 
     temp_corr=1./sum(abs((abr(IndicesInTemplate,:))-(repmat(template,1,size(abr,2)))),1);
end


data.z.score=(temp_corr-mean_peak)./stdev_peak;
% data.z.score=data.z.score';

%% Set weights for regression analysis. Z scores below 3 have no weight.
%Weighting decreases with increasing Z score from 1 @ Z=3 to 0.1 @ max Z.
w=zeros(1,num);
for i=1:num
    w(1,i)=1-0.9*((data.z.score(1,i)-3)/(max(data.z.score(1,:))-3));
    if data.z.score(1,i)<3
        w(1,i)=0;
    end
end
w(find(w==0, 1):end)=0;
w(find(w==0, 1))=1; %%SP (so the the regression doesn't become too flat)

%% Weighted regression and threshold calculation
X=ones(num,2);
X(:,2)=spl';
b=lscov3(X,data.z.score',w');
data.z.slope=b(2,1);
data.z.intercept=b(1,1);
data.threshold=(3-b(1,1))/b(2,1);

%% SP: Piecewise Linear threshold
[w1,meanbase]=two_lines_pwl_threshold(spl,data.z.score);

X=ones(num,2);
X(:,2)=spl';
b=lscov3(X,data.z.score',w1');
thresh=(meanbase-b(1,1))/b(2,1);
% w=w1;