%% ABR Thresholds
thresholds = nan(size(average.all_y));
freq_idx = 1;   % click = 1,  0.5kHz = 2,  1kHz = 3,  2kHz = 4,  4kHz = 5,  8kHz = 6
freq = average.x{1,1}(freq_idx);
for rows = 1:length(average.all_y)
    for cols = 1:width(average.all_y)
        if ~isempty(average.all_y{rows,cols})
            thresholds(rows,cols) = average.all_y{rows,cols}(freq_idx);
        end
    end
end