function [mag, A, fa] = efr_ram_mag(t_env, f, F0, nH)
%EFR_RAM_MAG  Spectral magnitude (µV) of the EFR RAM envelope at each harmonic.
%   mag = efr_ram_mag(t_env, f, F0, nH)
%     t_env  averaged envelope waveform, (pos+neg)/2, in µV (efr.t_env,
%            RAManalysis window, fs = 8 kHz)
%     f      frequency axis of the PLV spectrum (efr.f) — gives fs
%     F0     modulation frequency (223 Hz);  nH  number of harmonics
%   mag(h)  single-sided amplitude spectrum, 2·|FFT|/L (µV), maximum within
%           ±5 Hz of h·F0 — the same search window as the PLV peaks
%           (RAM/+helper/getPeaks).
%   A, fa   the whole amplitude spectrum (µV) and its frequency axis.
mag = nan(1, nH);  A = [];  fa = [];
if isempty(t_env) || isempty(f), return; end
x = double(t_env(:));
if all(~isfinite(x)), return; end
x(~isfinite(x)) = 0;
L = numel(x);
f = double(f(:));
df = f(min(2,end)) - f(1);
if numel(f) < 2 || ~(df > 0), return; end
fs = df * L;                                   % f = fs·(0:L/2)/L
X  = fft(x - mean(x));
A  = 2*abs(X(1:floor(L/2)+1)) / L;   A(1) = A(1)/2;
fa = fs*(0:floor(L/2))'/L;
for h = 1:nH
    in = fa > h*F0 - 5 & fa < h*F0 + 5;
    if any(in), mag(h) = max(A(in)); end
end
end
