function [f_s, dam_s, nf_s] = efr_dam_smooth(traj, dam, nf, n_bands)
%EFR_DAM_SMOOTH  Band-average dAM power along the modulation-frequency
%   trajectory into n_bands log-spaced bands, SNR-weighted (same method as
%   dAManalysis 'band' smoothing). Default 16 bands (matches the 16 RAM
%   harmonics). Edges: 2*n_bands+4 log-spaced points; band edges = even
%   points, centres = odd points between them.
if nargin < 4 || isempty(n_bands), n_bands = 16; end
traj = double(traj(:));  dam = double(dam(:));  nf = double(nf(:));
ok = isfinite(traj) & traj > 0;
traj = traj(ok);  dam = dam(ok);  nf = nf(ok);
fmin = min(traj);  fmax = max(traj);
edges     = 2 .^ linspace(log2(fmin), log2(fmax), 2*n_bands + 4);
bandEdges = edges(2:2:end-1);
f_s       = edges(3:2:end-2)';
dam_s = nan(numel(f_s),1);  nf_s = nan(numel(f_s),1);
for z = 1:numel(f_s)
    band = find(traj >= bandEdges(z) & traj < bandEdges(z+1));
    if isempty(band), continue; end
    w = (10.^((dam(band) - nf(band))./10)).^2;          % SNR weighting
    dam_s(z) = sum(w.*dam(band)) / sum(w);
    nf_s(z)  = sum(w.*nf(band))  / sum(w);
end
end
