function L = efr_ram_labels(o, nH)
%EFR_RAM_LABELS  Text labels for the RAM harmonic sums (Setup options).
%   nH (optional) = number of harmonics analysed (Setup harmonics range);
%   used in the "All Harmonics (H1–Hn)" label.
if nargin < 1 || isempty(o), o = efr_opts(); end
if nargin < 2 || isempty(nH), nH = max([o.high(:); o.low(:)]); end
rng = @(r) sprintf('H%d–H%d', r(1), r(end));
L.low   = sprintf('Low (%s)',  rng(o.low));
L.high  = sprintf('High (%s)', rng(o.high));
L.total = sprintf('All Harmonics (H1–H%d)', round(nH));
switch o.measure
    case 'snr',       L.measure = 'SNR Sum (dB)';
    case 'magnitude', L.measure = 'Magnitude Sum (µV)';
    otherwise,        L.measure = 'PLV Sum';
end
if o.normalize, L.measure = [L.measure ' / All Harmonics']; end
end
