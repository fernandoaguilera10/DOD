function [f, P1_env, P1_tfs, PLV_env, PLV_tfs, T_tfs, T_env] = getSpectAverage(pos,neg, fs, subset, k_iters)
    
    trials_p = size(pos,2);
    trials_n = size(neg,2);

    
    P1_env = zeros(floor(length(pos)/2)+1,k_iters);
    P1_tfs = P1_env;

    PLV_env = P1_env;
    PLV_tfs = P1_env;
    
    for i=1:k_iters
        %disp(i);
        %sample_pos
        pos_sub = pos(:,randperm(trials_p,subset));
        %pos_a_sub = pos_abr(:,randperm(trials,subset));
        
        %[b,a] = butter(6,[80,2000]/(fs/2));
        %pos_sub = filtfilt(b,a,pos_sub);

        neg_sub = neg(:,randperm(trials_n,subset));
        %neg_a_sub = neg_abr(:,randperm(trials,subset));
        %neg_sub = filtfilt(b,a,neg_sub);

        [f,P1_env(:,i),P1_tfs(:,i),PLV_env(:,i), PLV_tfs(:,i)] = helper.getSpectMag(pos_sub,neg_sub,fs);
        %[f,P1_a_env(:,i),P1_a_tfs(:,i),PLV_a_env(:,i), PLV_a_tfs(:,i)] = getSpectMag(pos_a_sub,neg_a_sub,fs);

        %temporal averaging
      
       tfs_t(:,i) = mean((pos_sub - neg_sub)/2,2); 
       
       %TFS IS NOT TFS HERE
       %tfs_t(:,i) = mean(pos_sub,2);
       env_t(:,i) = mean((pos_sub + neg_sub)/2,2);

    end

PLV_env = mean(PLV_env,2);
PLV_tfs = mean(PLV_tfs,2);

P1_env = mean(P1_env,2);
P1_tfs = mean(P1_tfs,2);

%HARD CODED FILTERING...DONT FORGET
% [b,a] = butter(6,[60,500]/(fs/2));
% T_tfs = filtfilt(b,a,tfs_t);
% T_env = filtfilt(b,a,env_t);

T_tfs = mean(tfs_t,2);
T_env = mean(env_t,2);
% 
% T_tfs = tfs_t;
% T_env = env_t;

end

