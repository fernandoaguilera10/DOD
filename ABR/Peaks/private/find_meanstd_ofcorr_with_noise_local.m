function [corrmean,corrstd]=find_meanstd_ofcorr_with_noise_local(template)

global noise_local ThreshTypeCorrCovDist
lnoise=noise_local;
local_ThreshTypeCorrCovDist=ThreshTypeCorrCovDist;

nNoiseFloorPoints=240;
CorvdNoise=zeros(nNoiseFloorPoints,1); % Same metric to save either correlation, covariance or distance 

for i=1:nNoiseFloorPoints
    ind_start=ceil(rand(1)*(length(lnoise)-length(template)-1));
    cur_noise= lnoise(ind_start:ind_start+length(template)-1)';
    if ~prod(size(cur_noise)==size(template))
       cur_noise=cur_noise'; 
    end
    
    cur_noise=cur_noise*50; % Scaling to match the scale of other ABR signals.
%     cur_noise=apply_dtw(template,cur_noise); %For DTW 
    
    if local_ThreshTypeCorrCovDist==1
        CorvdNoise(i)=corr2(template,cur_noise);
    elseif local_ThreshTypeCorrCovDist==2
        temp_cov=cov(template,cur_noise);
        CorvdNoise(i)=temp_cov(1,2);
    else
        CorvdNoise(i)=1/sum(abs(template-cur_noise));
    end
end

corrmean=mean(CorvdNoise);
corrstd=std(CorvdNoise);