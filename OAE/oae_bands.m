function [cf, lo, hi] = oae_bands(o)
%OAE_BANDS  Band centres and edges (kHz) for the Setup band width / range.
%   Centres run from fmin·2^w to fmax·2^-w in steps of w = 1/bands_per_oct
%   octave; each band spans centre·2^(±w/2). With the defaults (½ octave,
%   0.5–16 kHz) this gives the original 9 bands, 0.707–11.3 kHz.
if nargin < 1, o = oae_opts(); end
w  = 1 / o.bands_per_oct;
n  = floor(log2(o.frange(2) / o.frange(1)) / w - 1 + 1e-9);
n  = max(n, 1);
cf = o.frange(1) .* 2 .^ (w .* (1:n));
lo = cf .* 2 .^ (-w/2);
hi = cf .* 2 .^ ( w/2);
end
