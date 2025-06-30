%% Extract OAE amplitude for each frequency band

data = average.all_oae_band;
[num_rows, num_cols] = size(data);
num_freqs = length(average.bandF);

for f = 1:num_freqs
    freq_data{f} = NaN(num_rows, num_cols);
end

for i = 1:num_rows
    for j = 1:num_cols
        if ~isempty(data{i,j})
            for f = 1:num_freqs
                freq_data{f}(i,j) = data{i,j}(f);
            end
        end
    end
end
%% Average across all frequencies
oae_mean = cell(1, num_freqs);
for f = 1:num_freqs
    current_freq = freq_data{f};
    oae_mean{f} = nanmean(current_freq, 1);
end