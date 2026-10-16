function m = efr_ram_metrics(peaks, peaks_locs, f, plv_env, o, t_env)
%EFR_RAM_METRICS  Harmonic sums for one EFR RAM recording.
%   m.total  PLV summed over ALL harmonics (PLV amplitude); with
%            o.normalize the same normalisation applies, so it is 1 (the
%            whole of which Low / High are fractions)
%   m.low    chosen measure summed over o.low  harmonics  (optionally
%   m.high   chosen measure summed over o.high harmonics   normalised)
%   m.snr    per-harmonic PLV SNR (dB): PLV at the harmonic vs the mean PLV
%            of neighbouring bins 5–40 Hz away on both sides.
%   m.mag    per-harmonic spectral magnitude (µV) of the averaged envelope
%            t_env (efr_ram_mag); NaN when t_env is not given.
%   o = efr_opts() if omitted.
if nargin < 5 || isempty(o), o = efr_opts(); end
p   = double(peaks(:)');   loc = double(peaks_locs(:)');
nH  = numel(p);
m.total = sum(p, 'omitnan');
if all(isnan(p)), m.total = NaN; end
% per-harmonic SNR (needs the PLV spectrum)
m.snr = nan(1, nH);
if nargin >= 4 && ~isempty(f) && ~isempty(plv_env)
    f = double(f(:));  pe = double(plv_env(:));
    n = min(numel(f), numel(pe));  f = f(1:n);  pe = pe(1:n);
    for h = 1:nH
        if ~isfinite(loc(min(h,numel(loc)))) || ~isfinite(p(h)), continue; end
        d  = abs(f - loc(h));
        nb = pe(d > 5 & d <= 40);
        nz = mean(nb, 'omitnan');
        if nz > 0, m.snr(h) = 20*log10(p(h) / nz); end
    end
end
% per-harmonic magnitude (µV, needs the envelope waveform)
m.mag = nan(1, nH);
if nargin >= 6 && ~isempty(t_env)
    m.mag = efr_ram_mag(t_env, f, o.ram_f0, nH);
end
switch o.measure
    case 'snr',       v = m.snr;
    case 'magnitude', v = m.mag;
    otherwise,  v = p;
end
pick = @(r) v(max(1,r(1)) : min(nH, r(end)));
m.low  = sum(pick(o.low),  'omitnan');
m.high = sum(pick(o.high), 'omitnan');
if all(isnan(pick(o.low))),  m.low  = NaN; end
if all(isnan(pick(o.high))), m.high = NaN; end
if o.normalize
    allv = sum(v, 'omitnan');
    if allv ~= 0 && isfinite(allv), m.low = m.low/allv;  m.high = m.high/allv;  m.total = 1;
    else, m.low = NaN;  m.high = NaN;  m.total = NaN; end
end
end
