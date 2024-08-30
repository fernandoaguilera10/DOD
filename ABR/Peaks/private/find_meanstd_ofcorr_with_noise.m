function [corrmean,corrstd]=find_meanstd_ofcorr_with_noise(template)

global noisemean_std_SP 

nNoiseFloorPoints=120;
CovNoise=zeros(nNoiseFloorPoints,1);

noise_meanstd_all=noisemean_std_SP;

parfor i=1:nNoiseFloorPoints
   cur_noise= noise_meanstd_all(1)+noise_meanstd_all(2)*randn(size(template));
   
   
   cur_noise=cur_noise*50; % Scaling to match the scale of other ABR signals.
   cur_noise=apply_dtw(template,cur_noise);
   temp_cov=cov(template,cur_noise);
   CovNoise(i)=temp_cov(1,2);
   
%    CovNoise(i)=corr(template,cur_noise);
   
%    CovNoise(i)=1/sum(abs(template-cur_noise));
end
corrmean=mean(CovNoise);
corrstd=std(CovNoise);