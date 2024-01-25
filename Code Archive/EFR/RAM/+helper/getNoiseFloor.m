function [floorx,floory] = getNoiseFloor(pos_trials,neg_trials,Fs,iters)
%Simple computation of noisefloor

num_trials_p = size(pos_trials,2);
num_trials_n = size(neg_trials,2);

samps = size(pos_trials,1);
floorx = Fs*(0:floor(samps/2))/samps;
floory_all = zeros(floor(samps/2)+1,iters);

for j = 1:iters
    %randomly choose a subset of 1/5th number of trials:
    r_neg = randsample(num_trials_n,round(num_trials_n/6)); 
    r_pos = randsample(num_trials_p,round(num_trials_p/6)); 

    r_pos_trials = pos_trials(:,r_pos);
    r_neg_trials = neg_trials(:,r_neg);

    r_pos_trials(:,2:2:end) = -r_pos_trials(:,2:2:end);
    r_neg_trials(:,2:2:end) = -r_neg_trials(:,2:2:end);

    combined_avg = mean(horzcat(r_pos_trials, r_neg_trials),2);
    
    %subtract out DC here, then compute:
    floor_fft = fft((combined_avg-mean(combined_avg))*1e6);

    floory_db = db(abs(floor_fft/samps));
    floory_all(:,j) = floory_db(1:(floor(samps/2)+1));

end 

floory = mean(floory_all,2)';

end