function R = earl_ref_data()
%EARL_REF_DATA  Chinchilla click-ABR latencies from Earl (1983).
%   Earl, D. C. (1983). Morphology of the brainstem electric response of the
%   chinchilla. Master's thesis, University of Tennessee. 10 normal young
%   chinchillas; broadband 20-us click, 10/s, 100-5000 Hz, 512 averages.
%   SL = dB above each animal's ABR threshold (lowest level with a
%   replicable waveform).
%   R.sl        8x1   sensation levels (dB SL), 70:-10:0
%   R.abs_min/abs_max/abs_mean/abs_sd  8x5 Table 3 (ms), waves I-V (NaN = NR)
%   R.animal    8x10x5 per-animal latency (ms), Tables A-1..A-8 (NaN = no wave)
%   R.rel_min/rel_max/rel_mean/rel_sd/rel_n  8x5 interpeak latency re Wave I
%               computed per animal (animals with both waves); column 1 = 0.
R.sl = (70:-10:0)';
R.abs_min = [ ...
    1.16 2.04 3.08 3.72 4.72
    1.28 2.28 3.24 3.76 4.88
    1.28 2.32 3.16 3.84 4.96
    1.28 2.40 3.24 3.92 5.12
    1.56 2.48 3.24 4.00 5.12
    1.76 2.88 3.32 4.32 5.60
    1.84 3.00 4.04 4.44 NaN
    2.00 3.16 4.48 4.76 NaN];
R.abs_max = [ ...
    1.64 2.68 3.56 4.40 5.40
    1.72 2.76 3.88 4.52 5.64
    1.76 3.04 3.72 4.56 5.68
    1.88 3.08 3.88 4.72 5.80
    2.00 3.20 4.12 4.80 5.92
    2.20 3.28 4.12 4.80 5.60
    2.36 3.56 4.36 5.16 NaN
    2.76 4.04 4.68 5.48 NaN];
R.abs_sd = [ ...
    0.13 0.23 0.18 0.25 0.25
    0.16 0.17 0.24 0.24 0.25
    0.17 0.23 0.20 0.21 0.22
    0.20 0.18 0.36 0.25 0.21
    0.17 0.23 0.35 0.29 0.20
    0.16 0.28 0.34 0.23 NaN
    0.15 0.19 0.14 0.32 NaN
    0.27 0.28 0.09 0.29 NaN];
R.abs_mean = [ ...
    1.39 2.39 3.35 4.03 5.08
    1.51 2.56 3.54 4.06 5.18
    1.57 2.66 3.42 4.08 5.26
    1.64 2.75 3.55 4.16 5.42
    1.78 2.90 3.83 4.26 5.65
    2.00 3.21 3.93 4.51 5.60
    2.18 3.28 4.23 4.56 NaN
    2.35 3.53 4.60 5.14 NaN];
R.animal = nan(8,10,5);
R.animal(1,:,:) = reshape([ ...
    1.44 2.44 NaN 3.92 5.16
    1.36 2.24 3.20 3.76 4.72
    1.40 2.60 NaN 4.24 NaN
    1.44 2.56 NaN 4.00 NaN
    1.44 2.40 3.44 4.32 5.28
    1.16 2.04 3.32 3.84 4.88
    1.44 2.60 NaN 3.84 5.04
    1.64 2.68 3.48 4.36 5.40
    1.28 2.04 3.08 3.72 NaN
    1.28 2.32 3.56 4.28 NaN], [1 10 5]);
R.animal(2,:,:) = reshape([ ...
    1.44 2.52 NaN 3.92 5.24
    1.32 2.28 3.24 3.76 4.88
    1.64 2.76 NaN 4.32 NaN
    1.56 2.56 NaN 4.00 5.32
    1.72 2.64 3.76 NaN 5.08
    1.32 2.28 3.36 3.80 5.04
    1.60 2.72 NaN 3.92 5.16
    1.68 2.72 3.53 4.40 5.64
    1.28 2.64 3.48 4.04 NaN
    1.52 2.44 3.88 4.36 NaN], [1 10 5]);
R.animal(3,:,:) = reshape([ ...
    1.60 2.56 NaN 4.04 5.32
    1.36 2.32 3.16 3.92 5.20
    1.68 2.88 NaN 4.56 NaN
    1.68 2.72 NaN 4.08 5.32
    1.76 2.72 3.72 NaN 5.16
    1.28 2.40 3.44 3.84 4.96
    1.72 2.76 NaN 4.00 5.16
    1.68 2.72 3.40 4.24 5.68
    1.40 2.76 3.40 4.00 NaN
    1.56 2.68 NaN 4.08 NaN], [1 10 5]);
R.animal(4,:,:) = reshape([ ...
    1.68 2.64 NaN 4.24 5.52
    1.44 2.40 3.24 3.96 5.44
    1.84 3.08 NaN 4.72 NaN
    1.76 2.80 NaN 4.08 5.48
    1.80 2.80 3.88 NaN 5.32
    1.28 2.76 NaN 3.92 5.12
    1.88 2.88 NaN 4.12 5.28
    1.72 2.80 3.24 4.24 5.80
    1.44 2.76 NaN 4.04 NaN
    1.52 2.56 3.84 NaN NaN], [1 10 5]);
R.animal(5,:,:) = reshape([ ...
    1.92 2.80 NaN 4.04 5.56
    1.48 2.48 3.24 4.00 NaN
    1.84 3.12 NaN 4.80 NaN
    1.92 3.20 NaN 4.32 5.92
    1.88 2.92 4.00 NaN 5.64
    1.56 2.84 3.96 NaN 5.44
    2.00 3.00 NaN 4.20 5.48
    1.88 3.16 NaN 4.24 5.88
    1.64 2.72 4.12 NaN NaN
    1.72 2.72 3.84 NaN NaN], [1 10 5]);
R.animal(6,:,:) = reshape([ ...
    2.08 3.24 NaN 4.36 NaN
    NaN NaN 3.32 4.40 NaN
    2.08 3.24 NaN 4.92 NaN
    2.08 3.40 NaN 4.40 NaN
    2.08 3.08 4.04 NaN NaN
    1.76 2.96 4.08 NaN 5.60
    2.20 3.28 NaN 4.64 NaN
    2.12 3.28 NaN 4.32 NaN
    1.76 3.00 4.12 NaN NaN
    1.88 2.88 4.08 NaN NaN], [1 10 5]);
R.animal(7,:,:) = reshape([ ...
    2.16 3.24 NaN 4.44 NaN
    NaN 3.08 4.04 NaN NaN
    2.24 3.52 NaN 5.16 NaN
    2.28 3.56 NaN 4.56 NaN
    2.20 3.24 4.24 NaN NaN
    2.12 3.20 NaN 4.48 NaN
    2.28 3.32 NaN 4.72 NaN
    2.36 3.48 NaN 4.52 NaN
    1.84 3.00 4.28 NaN NaN
    2.12 3.20 4.36 NaN NaN], [1 10 5]);
R.animal(8,:,:) = reshape([ ...
    2.28 3.28 NaN NaN NaN
    NaN NaN 4.60 NaN NaN
    2.56 4.04 NaN 5.28 NaN
    NaN 3.72 NaN NaN NaN
    NaN 3.68 4.64 NaN NaN
    2.28 3.60 NaN 5.24 NaN
    2.28 3.36 NaN 4.92 NaN
    2.76 3.68 NaN 4.76 NaN
    2.00 3.16 4.48 NaN NaN
    NaN NaN 3.28 4.68 NaN], [1 10 5]);
R.rel_min = nan(8,5); R.rel_max = nan(8,5); R.rel_mean = nan(8,5); R.rel_sd = nan(8,5); R.rel_n = zeros(8,5);
R.rel_min(:,1) = 0; R.rel_max(:,1) = 0; R.rel_mean(:,1) = 0;
for li = 1:8
    a = squeeze(R.animal(li,:,:));            % 10 x 5
    for k = 2:5
        d = a(:,k) - a(:,1);  d = d(~isnan(d));
        R.rel_n(li,k) = numel(d);
        if isempty(d), continue; end
        R.rel_min(li,k) = min(d);  R.rel_max(li,k) = max(d);  R.rel_mean(li,k) = mean(d);
        if numel(d) > 1, R.rel_sd(li,k) = std(d); end
    end
end
R.source = 'Earl (1983), chinchilla click ABR, Table 3 and Tables A-1 to A-8';
end
