function L = efr_ram_labels(o)
%EFR_RAM_LABELS  Text labels for the RAM harmonic sums (Setup options).
if nargin < 1 || isempty(o), o = efr_opts(); end
rng = @(r) sprintf('H%d–H%d', r(1), r(end));
L.low   = sprintf('Low (%s)',  rng(o.low));
L.high  = sprintf('High (%s)', rng(o.high));
L.total = 'Total PLV (all)';
if strcmp(o.measure,'snr'), L.measure = 'SNR sum (dB)'; else, L.measure = 'PLV sum'; end
if o.normalize, L.measure = [L.measure ' / all harmonics']; end
end
