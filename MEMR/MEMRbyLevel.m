%% MEMR by level

function [res] = MEMRbyLevel(stim)
plotTrials_flag = 0;    % plot all reps = 1
bad_trials = 0;
freq = linspace(200, 8000, 1024);
MEMband = [500, 2000];
ind = (freq >= MEMband(1)) & (freq <= MEMband(2));
endsamps = ceil(stim.clickwin*stim.Fs*1e-3);
if(min(stim.noiseatt) == 6)
    elicitor = 105 - (stim.noiseatt - 6);
else
    elicitor = 105 - stim.noiseatt;
end

% check valid trials
allTrials = any(squeeze(stim.resp(:, :, 1, 1)),1);
goodTrials = zeros(size(allTrials));
response_all = stim.resp(:, allTrials(allTrials==1),:,:); % extract available trials
allTrial_length = length(allTrials(allTrials==1));
temp = cell(length(elicitor),allTrial_length);
idx_good = cell(size(temp));
idx_bad = cell(size(temp));
good_response = cell(size(temp));
bad_response = cell(size(temp));
tolerance = 1;
for t = 1:allTrial_length
    for k = 1:stim.nLevels
        response = squeeze(response_all(k, t, :, 1:endsamps))';  % (endsamps x reps)
        temp(k,t) = {var(response)};   % variance across time for each rep
        mask_good = temp{k,t} <= tolerance;
        mask_bad  = temp{k,t} > tolerance;
        idx_good{k,t} = mask_good;
        idx_bad{k,t}  = mask_bad;
        tmp_good = nan(endsamps, size(response,2));
        tmp_bad  = nan(endsamps, size(response,2));
        tmp_good(:,mask_good) = response(:,mask_good);
        tmp_bad(:,mask_bad)   = response(:,mask_bad);
        good_response{k,t} = tmp_good;
        bad_response{k,t}  = tmp_bad;
        
                
        %% CHECK THIS: count as bad if more than half the reps are bad
%         if length(find(mask_bad == 1)) >= 4
%             mask_bad = ones(1,length(mask_bad));
%             mask_good = zeros(1,length(mask_bad));
%         end
        %% ***************************************
        if plotTrials_flag == 1
            figure; 
            % plot good + bad reps
            subplot(1,3,1); plot(response,'linewidth',2);
            title(sprintf('Level: %d FPL', elicitor(k)));
            % identify bad reps
            subplot(1,3,2); plot(temp{k,t},'*k','markersize',10,'linewidth',2); yline(tolerance,'r--','linewidth',2);
            title(sprintf('Trial: %d', t));
            xticks(1:7); xlim([0,8]);
            if max(temp{k,t}) < tolerance; ylim([0,1.05]); end
            % plot good reps
            subplot(1,3,3); 
            hold on;
            plot(bad_response{k,t},'color',[0.9 0.9 0.9]); 
            plot(good_response{k,t},'linewidth',2);
            title(sprintf('Good Reps: %d/%d', sum(idx_good{k,t}),length(idx_good{k,t})));
        end
    end
end
% calculate response
stim.Averages = length(allTrials(allTrials==1));
fprintf(1, ' (n = %d)\n',stim.Averages);
    for k = 1:stim.nLevels
        fprintf(1, 'Analyzing level # %d / %d...\n', k, stim.nLevels);
        temp = cat(2, good_response{k,1:stim.Averages});
        mask = cat(2, idx_good{k,1:stim.Averages}); 
        temp_valid = temp(:,mask);
        nw = 4; % taper's time half-bandwidth (slepian)
        tempf = pmtm(temp_valid, nw, freq, stim.Fs)';
        resp_freq(:,k) = median(tempf, 1);
        blevs = k; % Which levels to use as baseline (consider 1:k)
        temp2 = cat(2, good_response{k,1:stim.Averages});   % 2047x7x4 
        mask = cat(2, idx_good{k,1:stim.Averages}); 
        % Extract first good rep in each block for baseline
        nReps = 7;
        first_cols = nan(1, stim.Averages);
        for g = 1:stim.Averages
            rep_idx = mask((g-1)*nReps + (1:nReps));            
            idx = find(rep_idx, 1, 'first');                   
            if ~isempty(idx)
                first_cols(g) = (g-1)*nReps + idx;
            elseif isempty(idx)   % no good reps             
                first_cols(g) = (g-1)*nReps + 1;
                bad_trials = bad_trials + 1;
            end
        end
        temp2 = temp2(:, first_cols);
        if(numel(blevs) > 1)
            temp2 = reshape(temp2, size(temp2, 2)*numel(blevs), endsamps);
        end
        idx_nan = isnan(temp2);
        idx_nan = idx_nan(1,:);
        idx_nan = find(idx_nan == 1);
        if ~isempty(idx_nan)
            fprintf(1, 'Unable to analyze level # %d / %d (Bad trials = %d)\n', k, stim.nLevels,bad_trials);
            for i = 1:length(idx_nan)
                temp2(:,idx_nan(i)) = zeros(1,endsamps);
            end
        end
        temp2f = pmtm(temp2, 4, freq, stim.Fs);
        bline_freq(:,k) = median(temp2f', 1);
    end
MEM = pow2db(resp_freq ./ bline_freq);
res.freq = freq; 
res.MEM = MEM; 
res.elicitor = elicitor; 
res.ind = ind;
res.trials = stim.Averages-bad_trials;
end
