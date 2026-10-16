function mx = mx_metrics(stim, calib, opts)
%MX_METRICS  Exploratory wideband MEMR metrics from one raw recording.
%
%   mx = mx_metrics(stim, calib)
%   stim   x.MemrData.stim of a wbmemr recording: resp (levels x trials x 7
%          clicks x samples), Fs, clickwin (ms), noiseatt, click, noise
%   calib  x.FPLearData of the session's FPL calibration ([] = none; the
%          absorbance metrics are then left empty)
%
%   Paradigm: each of the 7 sweeps of a trial is one probe click followed by
%   the elicitor noise (same noise in the 7 sweeps of a trial, a new noise
%   in every trial). Click 1 comes before any elicitor = baseline; clicks
%   2-7 each follow an elicitor burst.
%
%   Spectra: FFT of the click window (0 - clickwin ms, 4096 points),
%   averaged as complex numbers over the good trials of each level / click
%   (keeps phase). A click is rejected with the same rule as the ART
%   analysis (variance over the click window > 1).
%
%   Fields (L = number of elicitor levels, all "%" values are 100 x ratio):
%   .elicitor          1xL dB FPL (same formula as MEMRbyLevel)
%   .freq, .base, .elic  FFT frequency (Hz, 0.2-8 kHz) and the complex mean
%                      click spectra: click 1 (L x F) and clicks 2-7 (L x F)
%   VECTOR   .V   1xL  vector change = sum|elic - base| / sum|base| over
%                      0.5-2 kHz (%), magnitude and phase together
%            .Vn  1xL  noise floor: the V expected from trial-to-trial noise
%                      alone (sqrt(pi)/2 * complex SD / sqrt(n), per bin)
%            .snr = V ./ Vn,  .detected = snr >= opts.snr_crit (3)
%            .thr_nf      noise-floor threshold (dB FPL): lowest level of the
%                         run of detected levels that reaches the top level,
%                         interpolated where the SNR crosses the criterion
%                         (NaN = no reflex at the top level)
%            .vart, .sig  vector ART: 4-parameter sigmoid on V, 10 % of its
%                         range (same rule as ART); sig = [y0 L k x0]
%            .P_db 1xL    band power change of clicks 2-7 re. click 1 over
%                         0.5-2 kHz, signed dB (coherent, click 1 left out)
%   GROWTH   .gf  max (%), x0 (dB FPL), slope_mid (%/dB), dyn_range (dB,
%                 10-90 % of the fit), auc (% x dB above the noise floor),
%                 supra_slope (%/dB above thr_nf), fit_x / fit_y
%   KINETICS .kin t_ms (1x6, click time re. first elicitor onset), Vr (L x 6,
%                 vector change of each click 2-7 re. click 1, %), first,
%                 late (mean clicks 5-7), bi (late - first) / max (+ build-up,
%                 - adaptation), tau (ms, exponential fit, detected levels)
%   SPECTRAL .sp  fl (log grid, Hz), db (L x nf, 1/6-octave smoothed level
%                 change of clicks 2-7 re. click 1, dB), bands (5x2 Hz),
%                 band_db (L x 5), peak_f (1xL, Hz of the largest |change|)
%   ABSORB.  .ab  ok, channel, fl, A0 (baseline absorbance, 1 x nf), dA
%                 (L x nf), dA_low (0.25-1 kHz, 1xL), dA_mid (1-2 kHz, 1xL)
%   PROBE    .pr  t_ms (window centres re. noise onset), D (L x J, vector
%                 change of the recorded elicitor, clicks 4-7 vs 1, same
%                 trial, %), N (L x J, noise: sweep 6 vs 7), Dmean, Nmean,
%                 snr, detected, thr, tpeak (ms)
%   QUALITY  .q   n_trials, good_frac (1xL), base_var (1xL, % trial-to-trial
%                 variability of click 1), drift (1xL, % change of click 1
%                 re. the lowest level), snr, probe_snr

if nargin < 2, calib = []; end
if nargin < 3, opts = struct(); end
opts = defaults(opts);

Fs  = double(stim.Fs);
att = double(stim.noiseatt(:)');
if min(att) == 6, lev = 105 - (att - 6); else, lev = 105 - att; end
resp = double(stim.resp);                           % L x T x 7 x N
tr = any(squeeze(resp(:,:,1,1)) ~= 0, 1);           % trials recorded (as ART)
if size(resp,1) == 1, tr = resp(1,:,1,1) ~= 0; end
resp = resp(:, tr, :, :);
[nL, nT, nR, nS] = size(resp);
ns_click = ceil(double(stim.clickwin) * Fs * 1e-3);

mx = struct();
mx.version  = 1;
mx.opts     = opts;
mx.fs       = Fs;
mx.fc       = double(stim.fc);
mx.elicitor = lev;
mx.n_trials = nT;

%% ── Click spectra ──────────────────────────────────────────────────────
cw   = resp(:, :, :, 1:ns_click);
good = var(cw, 0, 4) <= opts.tol;                   % L x T x 7 (ART rule)
nfft = opts.nfft;
f    = (0:nfft/2) * Fs / nfft;
kf   = find(f >= opts.frange(1) & f <= opts.frange(2));
f    = f(kf);
X = fft(cw, nfft, 4);
X = X(:, :, :, kf);                                 % L x T x 7 x F
G  = repmat(good, [1 1 1 numel(f)]);
Xg = X;  Xg(~G) = NaN;
Xm = squeeze_lev(nanmean_(Xg, 2));                  % L x 7 x F
base = reshape(Xm(:, 1, :), nL, []);
elic = reshape(nanmean_(Xm(:, 2:end, :), 2), nL, []);
b = f >= opts.band(1) & f <= opts.band(2);
den = sum(abs(base(:, b)), 2)';

mx.freq = f;
mx.base = single(base);                             % (single: smaller file)
mx.elic = single(elic);

%% ── Vector change + noise floor ─────────────────────────────────────────
V  = sum(abs(elic(:, b) - base(:, b)), 2)' ./ den;
Vn = nan(1, nL);
for k = 1:nL
    xk = reshape(Xg(k, :, :, :), nT, nR, []);       % T x 7 x F
    d  = reshape(nanmean_(xk(:, 2:end, :), 2), nT, []) - reshape(xk(:, 1, :), nT, []);
    okt = all(isfinite(d(:, b)), 2);
    n = sum(okt);
    if n >= 3
        sd = sqrt(var(real(d(okt, b)), 0, 1) + var(imag(d(okt, b)), 0, 1));
        Vn(k) = sum(sqrt(pi)/2 * sd / sqrt(n)) / den(k);
    end
end
snr = V ./ Vn;
det = snr >= opts.snr_crit;
mx.V = 100 * V;
mx.Vn = 100 * Vn;
mx.snr = snr;
mx.detected = det;
mx.thr_nf = crossing_threshold(lev, snr, det, opts.snr_crit);
[mx.vart, mx.sig] = mx_sigfit(lev, 100 * V);
mx.P_db = 10 * log10(sum(abs(elic(:, b)).^2, 2)' ./ sum(abs(base(:, b)).^2, 2)');

%% ── Growth-function features (from the sigmoid on V) ───────────────────
gf = struct('max',NaN, 'x0',NaN, 'slope_mid',NaN, 'dyn_range',NaN, 'auc',NaN, ...
    'supra_slope',NaN, 'fit_x',[], 'fit_y',[]);
Vp = 100 * V;  Vnp = 100 * Vn;
gf.max = Vp(end);
ex = max(Vp - Vnp, 0);  ex(~isfinite(ex)) = 0;
if nL > 1, gf.auc = trapz(lev, ex); end
if all(isfinite(mx.sig))
    s = mx.sig;
    gf.fit_x = linspace(min(lev), max(lev), 121);
    gf.fit_y = s(1) + s(2) ./ (1 + exp(-s(3) * (gf.fit_x - s(4))));
    if isfinite(mx.thr_nf)                          % fit parameters only for a detected reflex
        gf.x0 = s(4);
        gf.slope_mid = s(2) * s(3) / 4;
        if s(3) > 0, gf.dyn_range = 2 * log(9) / s(3); end
    end
end
if isfinite(mx.thr_nf)
    sel = lev >= mx.thr_nf - 1e-9;
    if nnz(sel) >= 2
        p = polyfit(lev(sel), Vp(sel), 1);  gf.supra_slope = p(1);
    end
end
mx.gf = gf;

%% ── Kinetics: each click 2-7 vs click 1 ─────────────────────────────────
sweep_ms = nS / Fs * 1e3;
[~, ic] = max(abs(double(stim.click(:))));  click_ms = (ic - 1) / Fs * 1e3;
[on_i, off_i] = noise_span(stim);
noise_on_ms = (on_i - 1) / Fs * 1e3;
kin = struct();
kin.t_ms = (1:nR-1) * sweep_ms + click_ms - noise_on_ms;  % clicks 2..7
Vr = nan(nL, nR - 1);
for r = 2:nR
    xr = reshape(Xm(:, r, :), nL, []);
    Vr(:, r-1) = sum(abs(xr(:, b) - base(:, b)), 2) ./ den';
end
kin.Vr    = 100 * Vr;
kin.first = kin.Vr(:, 1)';
kin.late  = mean(kin.Vr(:, max(1, end-2):end), 2)';
kin.bi    = (kin.late - kin.first) ./ max(kin.late, kin.first);
kin.bi(~det) = NaN;                                 % only where a reflex is detected
kin.tau   = nan(1, nL);
for k = find(det)
    kin.tau(k) = exp_tau(kin.t_ms, kin.Vr(k, :));
end
mx.kin = kin;

%% ── Spectral change ─────────────────────────────────────────────────────
fl = logspace(log10(opts.frange(1)), log10(opts.frange(2)), opts.nlog);
sp = struct();
sp.fl = fl;
sp.db = nan(nL, numel(fl));
pe = abs(elic).^2;  pb = abs(base).^2;
for i = 1:numel(fl)
    w = f >= fl(i) * 2^(-1/12) & f <= fl(i) * 2^(1/12);
    if ~any(w), [~, j] = min(abs(f - fl(i)));  w = false(size(f));  w(j) = true; end
    sp.db(:, i) = 10 * log10(sum(pe(:, w), 2) ./ sum(pb(:, w), 2));
end
sp.bands = opts.bands;
sp.band_db = nan(nL, size(opts.bands, 1));
for j = 1:size(opts.bands, 1)
    w = f >= opts.bands(j,1) & f < opts.bands(j,2);
    sp.band_db(:, j) = 10 * log10(sum(pe(:, w), 2) ./ sum(pb(:, w), 2));
end
[~, ip] = max(abs(sp.db), [], 2);
sp.peak_f = fl(ip);
sp.peak_f(~det) = NaN;                              % only where a reflex is detected
mx.sp = sp;

%% ── Absorbance change (FPL calibration) ────────────────────────────────
mx.ab = absorbance(calib, f, base, elic, fl, nL);

%% ── Elicitor as probe (same trial, same noise in every sweep) ──────────
mx.pr = probe(resp, good, Fs, on_i, off_i, lev, opts);

%% ── Quality ─────────────────────────────────────────────────────────────
q = struct();
q.n_trials  = nT;
q.good_frac = reshape(mean(mean(good, 3), 2), 1, []);
q.base_var  = nan(1, nL);
for k = 1:nL
    x1 = reshape(Xg(k, :, 1, :), nT, []);
    okt = all(isfinite(x1(:, b)), 2);
    if any(okt)
        dev = sum(abs(x1(okt, b) - base(k, b)), 2) / den(k);
        q.base_var(k) = 100 * mean(dev);
    end
end
q.drift = 100 * sum(abs(base(:, b) - base(1, b)), 2)' / den(1);
q.snr = snr;
q.probe_snr = mx.pr.snr;
mx.q = q;
end


% ══════════════════════════════════════════════════════════════════════════
function o = defaults(o)
d = struct('tol',1, 'nfft',4096, 'frange',[200 8000], 'band',[500 2000], ...
    'snr_crit',3, 'nlog',121, 'bands',[250 500; 500 1000; 1000 2000; 2000 4000; 4000 8000], ...
    'abs_low',[250 1000], 'abs_mid',[1000 2000], 'pr_win_ms',8, 'pr_hop_ms',4, 'pr_ramp_ms',6);
fn = fieldnames(d);
for i = 1:numel(fn)
    if ~isfield(o, fn{i}) || isempty(o.(fn{i})), o.(fn{i}) = d.(fn{i}); end
end
end


function m = nanmean_(x, dim)
% mean over dim ignoring NaN (complex-safe; MATLAB and Octave)
ok = ~isnan(x);
x(~ok) = 0;
n = sum(ok, dim);
m = sum(x, dim) ./ n;
m(n == 0) = NaN;
end


function y = squeeze_lev(x)
% L x 1 x 7 x F  ->  L x 7 x F (keeps L = 1)
sz = size(x);
y = reshape(x, [sz(1), sz(3:end)]);
end


function thr = crossing_threshold(lev, snr, det, crit)
% Lowest level of the run of detected levels that reaches the top level,
% interpolated (log SNR vs level) between it and the level below.
thr = NaN;
if isempty(det) || ~det(end), return; end
j = numel(det);
while j > 1 && det(j-1), j = j - 1; end
if j == 1, thr = lev(1); return; end
s0 = snr(j-1);  s1 = snr(j);
if ~(isfinite(s0) && s0 > 0 && isfinite(s1) && s1 > s0), thr = lev(j); return; end
a = (log(crit) - log(s0)) / (log(s1) - log(s0));
a = min(max(a, 0), 1);
thr = lev(j-1) + a * (lev(j) - lev(j-1));
end


function tau = exp_tau(t, v)
% v(t) = a + b exp(-t / tau), tau limited to 10-3000 ms
tau = NaN;
t = double(t(:)');  v = double(v(:)');
if numel(v) < 4 || any(~isfinite(v)) || max(v) - min(v) <= 0, return; end
t = t - t(1);
unpack = @(q) [q(1), q(2), 10 + 2990 ./ (1 + exp(-q(3)))];
model  = @(p, tt) p(1) + p(2) * exp(-tt / p(3));
cost   = @(q) sum((model(unpack(q), t) - v).^2);
q0 = [v(end), v(1) - v(end), 0];
try
    q = fminsearch(cost, q0, optimset('Display','off', 'MaxFunEvals',3000, 'MaxIter',3000));
    p = unpack(q);
    if abs(p(2)) > 0.05 * max(abs(v)), tau = p(3); end
catch
end
end


function [on_i, off_i] = noise_span(stim)
% first / last sample of the elicitor noise in a sweep (5 % of its peak)
on_i = NaN;  off_i = NaN;
try
    nz = double(stim.noise);
    w = abs(reshape(nz(1, 1, :), 1, []));
    k = find(w > 0.05 * max(w));
    if ~isempty(k), on_i = k(1);  off_i = k(end); end
catch
end
if ~isfinite(on_i)                                   % fallback: wbmemr timing
    Fs = double(stim.Fs);
    on_i = round(double(stim.clickwin) * 1e-3 * Fs) + 1;
    off_i = on_i + round(double(stim.noisewin) * 1e-3 * Fs) - 1;
end
end


function ab = absorbance(calib, f, base, elic, fl, nL)
% Ear-canal impedance during the elicitor from the measured pressure ratio
% rho = P_elic / P_base and the FPL calibration of the same ear:
%   Zec_elic = Zs rho Zc / (Zs + Zc - rho Zc)
% (Zs = probe source impedance, Zc = ear-canal impedance at calibration =
% the no-elicitor state). Reflectance R = (Z - Z0)/(Z + Z0), absorbance
% A = 1 - |R|^2; dA = A_elic - A_baseline. Channel: 1 if its baseline
% absorbance is physically valid (0-1) over 0.2-8 kHz, else 2.
ab = struct('ok',false, 'channel',NaN, 'fl',fl, 'A0',[], 'dA',[], ...
    'dA_low',nan(1,nL), 'dA_mid',nan(1,nL), 'note','No FPL calibration found');
if isempty(calib), return; end
try
    cf = double(calib.freq(:)');
    if max(cf) < 100, cf = cf * 1e3; end             % kHz -> Hz (safety)
    best = 0;  frac = [0 0];
    for ch = 1:2
        fz = sprintf('Zs_%d', ch);  fc = sprintf('Zec_%d', ch);  f0 = sprintf('Z0_%d', ch);
        if ~isfield(calib, fz) || ~isfield(calib, fc) || ~isfield(calib, f0), continue; end
        Zc = cinterp(cf, calib.(fc), f);
        R0 = (Zc - calib.(f0)) ./ (Zc + calib.(f0));
        A0 = 1 - abs(R0).^2;
        frac(ch) = mean(A0 >= -0.05 & A0 <= 1.05);
    end
    if frac(1) >= 0.9, best = 1; elseif frac(2) > frac(1), best = 2; elseif frac(1) > 0, best = 1; end
    if best == 0, ab.note = 'FPL calibration not usable'; return; end
    Zs = cinterp(cf, calib.(sprintf('Zs_%d', best)), f);
    Zc = cinterp(cf, calib.(sprintf('Zec_%d', best)), f);
    Z0 = double(calib.(sprintf('Z0_%d', best)));
    rho = elic ./ base;                               % L x F
    Ze  = (Zs .* rho .* Zc) ./ (Zs + Zc - rho .* Zc);
    A0  = 1 - abs((Zc - Z0) ./ (Zc + Z0)).^2;
    Ae  = 1 - abs((Ze - Z0) ./ (Ze + Z0)).^2;
    dA  = Ae - repmat(A0, nL, 1);
    ab.A0 = nan(1, numel(fl));  ab.dA = nan(nL, numel(fl));
    for i = 1:numel(fl)
        w = f >= fl(i) * 2^(-1/12) & f <= fl(i) * 2^(1/12);
        if ~any(w), [~, j] = min(abs(f - fl(i)));  w = false(size(f));  w(j) = true; end
        ab.A0(i) = mean(A0(w));
        ab.dA(:, i) = mean(dA(:, w), 2);
    end
    wl = f >= 250 & f < 1000;  wm = f >= 1000 & f < 2000;
    ab.dA_low = mean(dA(:, wl), 2)';
    ab.dA_mid = mean(dA(:, wm), 2)';
    ab.ok = true;  ab.channel = best;
    ab.note = sprintf('FPL calibration channel %d', best);
catch err
    ab.note = ['Absorbance failed: ' err.message];
end
end


function z = cinterp(x, y, xi)
y = double(y(:)).';                                   % .' : no complex conjugate
z = interp1(x, real(y), xi, 'linear', 'extrap') + 1i * interp1(x, imag(y), xi, 'linear', 'extrap');
end


function pr = probe(resp, good, Fs, on_i, off_i, lev, opts)
% The recorded elicitor noise is the same waveform in the 7 sweeps of a
% trial, so the same stretch of it can be compared between sweeps of one
% trial: D = sum|mean(sweeps 4-7) - sweep 1| / sum|sweep 1| over 0.5-2 kHz
% in sliding windows (8 ms Hann, 4 ms hop, first / last 6 ms skipped),
% averaged over trials. Sweep 1 = the first elicitor burst (reflex not yet
% built up); sweeps 4-7 = reflex already active. N = the same between
% sweeps 6 and 7 (both active), scaled to the noise expected in D.
[nL, nT, nR, ~] = size(resp);
W   = round(opts.pr_win_ms * 1e-3 * Fs);
hop = round(opts.pr_hop_ms * 1e-3 * Fs);
rp  = round(opts.pr_ramp_ms * 1e-3 * Fs);
i0 = on_i + rp;  i1 = off_i - rp;
starts = i0:hop:(i1 - W + 1);
pr = struct('t_ms',[], 'D',[], 'N',[], 'Dmean',nan(1,nL), 'Nmean',nan(1,nL), ...
    'snr',nan(1,nL), 'detected',false(1,nL), 'thr',NaN, 'tpeak',nan(1,nL));
if isempty(starts) || nR < 7, return; end
J = numel(starts);
nfft = 2^nextpow2(W);
fb = (0:nfft-1) * Fs / nfft;
b = fb >= opts.band(1) & fb <= opts.band(2);
win = 0.5 * (1 - cos(2*pi*(0:W-1)' / (W - 1)));
pr.t_ms = (starts - on_i + W/2) / Fs * 1e3;
idx = repmat((0:W-1)', 1, J) + repmat(starts, W, 1);   % W x J sample indices
D = nan(nL, J);  N = nan(nL, J);
late = 4:7;
for k = 1:nL
    Dk = nan(nT, J);  Nk = nan(nT, J);
    for t = 1:nT
        g = reshape(good(k, t, :), 1, []);
        if ~g(1), continue; end
        lr = late(g(late));
        if isempty(lr), continue; end
        xs  = reshape(resp(k, t, :, :), nR, [])';          % samples x 7
        seg = reshape(xs(idx(:), :), W, J, nR);             % W x J x 7
        Y = fft(seg .* repmat(win, [1 J nR]), nfft, 1);     % nfft x J x 7
        Y = Y(b, :, :);
        Y1 = Y(:, :, 1);
        Yl = mean(Y(:, :, lr), 3);
        Dk(t, :) = sum(abs(Yl - Y1), 1) ./ sum(abs(Y1), 1);
        if g(6) && g(7)
            Nk(t, :) = sqrt((1 + 1/numel(lr)) / 2) * sum(abs(Y(:,:,6) - Y(:,:,7)), 1) ./ sum(abs(Y(:,:,7)), 1);
        end
    end
    D(k, :) = nanmean_(Dk, 1);
    N(k, :) = nanmean_(Nk, 1);
end
pr.D = 100 * D;  pr.N = 100 * N;
pr.Dmean = nanmean_(pr.D, 2)';
pr.Nmean = nanmean_(pr.N, 2)';
pr.snr = pr.Dmean ./ pr.Nmean;
pr.detected = pr.snr >= opts.snr_crit;
pr.thr = crossing_threshold(lev, pr.snr, pr.detected, opts.snr_crit);
for k = 1:nL
    [~, j] = max(pr.D(k, :));
    if isfinite(pr.D(k, j)), pr.tpeak(k) = pr.t_ms(j); end
end
end
