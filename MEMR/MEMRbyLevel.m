%% MEMR by level helper function

function [res] = MEMRbyLevel(stim)

freq = linspace(200, 8000, 1024);
MEMband = [500, 2000];
ind = (freq >= MEMband(1)) & (freq <= MEMband(2));

endsamps = ceil(stim.clickwin*stim.Fs*1e-3);
% check how many trials are valid! (assuming data collection interrupted
% before all 32 trials are completed)
goodTrials = any(squeeze(stim.resp(:, :, 1, 1)),1);
stim.Averages = length(goodTrials(goodTrials==1));
fprintf(1, '(n = %d)\n',stim.Averages);
for k = 1:stim.nLevels
    fprintf(1, 'Analyzing level # %d / %d ...\n', k, stim.nLevels);
    temp = reshape(squeeze(stim.resp(k, 1:stim.Averages, 2:end, 1:endsamps)),...
        (stim.nreps-1)*stim.Averages, endsamps);
    tempf = pmtm(temp', 4, freq, stim.Fs)';
    resp_freq(k, :) = median(tempf, 1); %#ok<*SAGROW>
    
    blevs = k; % Which levels to use as baseline (consider 1:k)
    temp2 = squeeze(stim.resp(blevs, 1:stim.Averages, 1, 1:endsamps));
    
    if(numel(blevs) > 1)
        temp2 = reshape(temp2, size(temp2, 2)*numel(blevs), endsamps);
    end
    
    temp2f = pmtm(temp2', 4, freq, stim.Fs)';
    bline_freq(k, :) = median(temp2f, 1);
end


if(min(stim.noiseatt) == 6)
    elicitor = 105 - (stim.noiseatt - 6);
else
    elicitor = 105 - stim.noiseatt;
end

MEM = pow2db(resp_freq ./ bline_freq);

res.freq = freq; 
res.MEM = MEM; 
res.elicitor = elicitor; 
res.ind = ind;
res.trials = stim.Averages;
end
