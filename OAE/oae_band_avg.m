function B = oae_band_avg(f, oae, nf, lo, hi, o)
%OAE_BAND_AVG  Average a full-resolution OAE spectrum into frequency bands.
%
%   B = oae_band_avg(f, oae, nf, lo, hi, o)
%     f        frequency (kHz), oae / nf in dB (same length)
%     lo, hi   band edges (kHz); a point belongs to a band when lo <= f < hi
%     o        options (oae_opts): .method, .snr_on, .snr_min, .min_frac
%
%   B.oae   band OAE level (dB)            B.nf   band noise floor (dB)
%   B.snr   B.oae − B.nf (dB)              B.ok   band meets the SNR criterion
%   B.npts  points in band                 B.npass points passing the criterion
%
%   Methods (o.method):
%     'snrw'    weighted mean of dB, weight = (10^(SNR/10))^2 (original APAT)
%     'power'   10·log10(mean(10^(L/10)))  — mean of pressure², then dB
%     'meandb'  mean of dB
%     'median'  median of dB
%   SNR criterion (o.snr_on): only points with OAE − NF >= o.snr_min enter
%   the OAE average. When fewer than o.min_frac % of the band's points pass,
%   the band uses all its points and B.ok = false. The noise floor always
%   uses every point of the band.
if nargin < 6, o = oae_opts(); end
f = double(f(:)');  oae = double(oae(:)');  nf = double(nf(:)');
m = min([numel(f), numel(oae), numel(nf)]);
f = f(1:m);  oae = oae(1:m);  nf = nf(1:m);
good = isfinite(f) & isfinite(oae) & isfinite(nf);
nb = numel(lo);
B = struct('oae',nan(1,nb), 'nf',nan(1,nb), 'snr',nan(1,nb), 'ok',false(1,nb), ...
    'npts',zeros(1,nb), 'npass',zeros(1,nb));
for z = 1:nb
    in = good & f >= lo(z) & f < hi(z);
    B.npts(z) = nnz(in);
    if ~any(in), continue; end
    L = oae(in);  N = nf(in);  S = L - N;
    use = true(size(L));
    B.ok(z) = true;
    if o.snr_on
        pass = S >= o.snr_min;
        B.npass(z) = nnz(pass);
        if nnz(pass) > 0 && 100 * nnz(pass) / numel(L) >= o.min_frac
            use = pass;
        else
            B.ok(z) = false;
        end
    else
        B.npass(z) = numel(L);
    end
    switch o.method
        case 'snrw'
            w  = (10 .^ (S ./ 10)) .^ 2;
            wu = w(use);
            if sum(wu) > 0 && all(isfinite(wu))
                B.oae(z) = sum(wu .* L(use)) / sum(wu);
            else
                B.oae(z) = mean(L(use));
            end
            if sum(w) > 0 && all(isfinite(w))
                B.nf(z) = sum(w .* N) / sum(w);
            else
                B.nf(z) = mean(N);
            end
        case 'power'
            B.oae(z) = 10 * log10(mean(10 .^ (L(use) ./ 10)));
            B.nf(z)  = 10 * log10(mean(10 .^ (N ./ 10)));
        case 'median'
            B.oae(z) = median(L(use));
            B.nf(z)  = median(N);
        otherwise   % 'meandb'
            B.oae(z) = mean(L(use));
            B.nf(z)  = mean(N);
    end
end
B.snr = B.oae - B.nf;
end
