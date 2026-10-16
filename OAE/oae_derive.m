function D = oae_derive(data, scale, o)
%OAE_DERIVE  Bands and regions for one subject / condition / scale, using
%   the Setup options (applied at summary time from the saved full-resolution
%   spectrum, so no re-analysis is needed).
%
%   D = oae_derive(data, 'epl'|'spl', o)  — [] if that scale is not saved.
%     D.f, D.oae, D.nf      full resolution (kHz, dB)
%     D.cf, D.band          band centres and oae_band_avg result
%     D.reg                 oae_band_avg result for the 3 regions (Low/Mid/High)
if nargin < 3, o = oae_opts(); end
D = [];
scale = lower(scale);
if ~isstruct(data) || ~isfield(data, scale) || isempty(data.(scale)), return; end
x = data.(scale);
if ~all(isfield(x, {'f','oae','nf'})) || isempty(x.f), return; end
D.f   = double(x.f(:)');
D.oae = double(x.oae(:)');
D.nf  = double(x.nf(:)');
[D.cf, lo, hi] = oae_bands(o);
D.band = oae_band_avg(D.f, D.oae, D.nf, lo, hi, o);
r = o.regions;
D.reg  = oae_band_avg(D.f, D.oae, D.nf, r(1:3), r(2:4), o);
end
