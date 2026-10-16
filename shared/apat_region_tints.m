function T = apat_region_tints()
%APAT_REGION_TINTS  Grey shades that link a summary plot to the plot it
%   summarises (used with apat_xgroups and for the matching table rows):
%   rows = Low, Mid, High region, getting darker. Greys only, so the shading
%   never competes with the condition colours of the data.
%   OAE: Low / Mid / High band averages <-> the bands in each region (and the
%   table rows). EFR RAM: Low / High harmonic sums <-> the harmonics in each
%   range (and the table rows).
%   Drawn at 50 % opacity: the shade seen on white is apat_shade_eff(T).
T = [0.88 0.88 0.88;    % Low   (≈ 0.94 on white)
     0.76 0.76 0.76;    % Mid   (≈ 0.88)
     0.52 0.52 0.52];   % High  (≈ 0.76; darker than Mid, Oct 15)
end
