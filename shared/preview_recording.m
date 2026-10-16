function P = preview_recording(folder, file)
%PREVIEW_RECORDING  Quick look at one raw recording, for choosing between
%   several files of a data folder (pick_datafile, Manual data-file rule).
%
%   P = preview_recording(folder, file)
%
%   Fast and approximate — enough to see whether a recording is usable, not
%   a replacement for the analysis (no FPL calibration: levels are ear-canal
%   SPL from the microphone sensitivity only).
%     swept DPOAE  DP level (2f1−f2) and noise floor vs f2  + energy of every trial
%     swept SFOAE  SF level and noise floor vs probe frequency + trial energy
%     TEOAE        averaged waveform + spectrum with noise floor
%     WB MEMR      vector change vs elicitor level (+ noise floor) + spectral
%                  change of clicks 2–7 re. click 1 for every level
%   Noise floor = half the difference of the odd and even trial averages
%   (OAEs) or the trial-to-trial spread (MEMR, as mx_metrics).
%
%   P.kind   'DPOAE' | 'SFOAE' | 'TEOAE' | 'MEMR' | '' (other files)
%   P.info   one line: recording date, trials completed, comment
%   P.ax(1:2) struct: title, xlab, ylab, xscale, yscale, lines (struct array
%            x, y, style, clr, lw, name), bars (x, y, clr), hline (y, or [])
%   P.note   text shown when there is nothing to plot

P = struct('kind','', 'info','', 'ax',struct([]), 'note','');
try
    S = load(fullfile(folder, file), 'x');
    x = S.x;
catch err
    P.note = sprintf('Could not read this file (%s).', err.message);
    return
end
fn = fieldnames(x);
key = '';
for i = 1:numel(fn)
    v = x.(fn{i});
    if isstruct(v) && isfield(v, 'stim'), key = fn{i}; break; end
end
if isempty(key)
    P.note = 'No preview for this file type.';
    return
end
st = x.(key).stim;
P.info = info_line(st);
try
    switch key
        case 'sweptDPOAEData', P = swept(P, st, 'DPOAE');
        case 'sweptSFOAEData', P = swept(P, st, 'SFOAE');
        case 'TEOAEData',      P = teoae(P, st);
        case 'MemrData',       P = memr(P, st);
        otherwise,             P.note = sprintf('No preview for %s files.', key);
    end
catch err
    P.ax = struct([]);
    P.note = sprintf('Preview failed: %s', err.message);
end
end


% ══════════════════════════════════════════════════════════════════════════
function s = info_line(st)
parts = {};
if isfield(st, 'date') && ~isempty(st.date), parts{end+1} = sprintf('Recorded %s', char(st.date)); end
if isfield(st, 'NUMtrials_Completed')
    n = double(st.NUMtrials_Completed(1));
    t = sprintf('%d trials', n);
    if isfield(st, 'ALLtrials_Completed')
        if double(st.ALLtrials_Completed(1)) > 0, t = [t ' (all completed)'];
        else, t = [t ' (stopped early)']; end
    end
    parts{end+1} = t;
end
if isfield(st, 'comment') && ~isempty(st.comment) && ischar(st.comment)
    parts{end+1} = sprintf('Comment: %s', strtrim(st.comment));
end
s = strjoin(parts, '   ·   ');
end


% ══════════════════════════════════════════════════════════════════════════
function P = swept(P, st, kind)
% Least-squares fit of the emission phase in moving windows (as DPanalysis /
% SFanalysis, coarser: 60 points), on the mean of the clean trials.
P.kind = kind;
Fs = double(st.Fs);
if strcmp(kind, 'DPOAE')
    R   = double(st.resp);
    ph  = 2*double(st.phi1_inst(:)') - double(st.phi2_inst(:)');   % cycles
    phx = double(st.phi2_inst(:)');                                % x axis: f2
    xlab = 'F2 Frequency (kHz)';  ttl = 'DPOAE (2f_1 - f_2)';
else
    R   = double(st.ProbeBuffs) + double(st.SuppBuffs) - double(st.BothBuffs);
    ph  = double(st.phiProbe_inst(:)');
    phx = ph;
    xlab = 'Probe Frequency (kHz)';  ttl = 'SFOAE';
end
used = any(R ~= 0, 2);
R = R(used, :);
nT = size(R, 1);
if nT == 0, P.note = 'No recorded trials in this file.'; return; end
[keep, edb] = clean_trials(R);
A  = mean(R(keep, :), 1);
ko = find(keep);
if numel(ko) >= 2
    NF = (mean(R(ko(1:2:end), :), 1) - mean(R(ko(2:2:end), :), 1)) / 2;
else
    NF = zeros(size(A));
end
v2spl = 1 / 20e-6;
if isfield(st, 'VoltageToPascal'), v2spl = double(st.VoltageToPascal) / 20e-6; end
win = 0.1;  if isfield(st, 'windowdur'), win = double(st.windowdur); end
nw  = max(64, round(win * Fs));
N   = numel(A);
fx  = gradient(phx) * Fs;                          % instantaneous frequency (Hz)
c   = round(linspace(nw/2 + 1, N - nw/2, 60));
tap = hann_(nw);
L = nan(1, numel(c));  Ln = L;  fq = L;
for k = 1:numel(c)
    idx = c(k) - floor(nw/2) + (0:nw-1);
    M = [cos(2*pi*ph(idx)) .* tap; -sin(2*pi*ph(idx)) .* tap];
    a = M.' \ (A(idx) .* tap).';
    b = M.' \ (NF(idx) .* tap).';
    L(k)  = 20*log10(max(abs(a(1) + 1i*a(2)) * v2spl, eps));
    Ln(k) = 20*log10(max(abs(b(1) + 1i*b(2)) * v2spl, eps));
    fq(k) = fx(c(k)) / 1e3;
end
ok = fq > 0;
P.ax = [ax_spec(ttl, xlab, 'Level (dB SPL, Uncalibrated)', 'log', ...
           [line_(fq(ok), L(ok), '-', [0.10 0.35 0.75], 2, kind), ...
            line_(fq(ok), Ln(ok), '--', [0.45 0.45 0.45], 1.5, 'Noise Floor')]), ...
        trial_ax(edb, keep)];
end


function P = teoae(P, st)
P.kind = 'TEOAE';
R = double(st.resp);
used = any(R ~= 0, 2);  R = R(used, :);
if isempty(R), P.note = 'No recorded trials in this file.'; return; end
i0 = 1;  if isfield(st, 'StimWin'), i0 = double(st.StimWin) + 1; end
nr = size(R, 2) - i0 + 1;  if isfield(st, 'RespDur'), nr = min(nr, double(st.RespDur)); end
R = R(:, i0:i0+nr-1);
R = R - mean(R, 2);
keep = clean_trials(R);
ko = find(keep);
A  = mean(R(ko, :), 1);
NF = zeros(size(A));
if numel(ko) >= 2, NF = (mean(R(ko(1:2:end), :), 1) - mean(R(ko(2:2:end), :), 1)) / 2; end
fsk = 48.828125;  if isfield(st, 'SamplingRate'), fsk = double(st.SamplingRate); end   % kHz
fac = 1;
if all(isfield(st, {'DR_onesided','mic_gain','mic_sens'}))
    fac = double(st.DR_onesided) * double(st.mic_gain) * double(st.mic_sens);      % V per Pa
end
t = (0:nr-1) / fsk;                                  % ms
w = hann_(nr);
F  = fft(A .* w);  Fn = fft(NF .* w);
nb = floor(nr/2) + 1;
f  = (0:nb-1) * fsk / nr;                            % kHz
sc = 2 / sum(w) / fac / 20e-6;
Ld = 20*log10(max(abs(F(1:nb)) * sc, eps));
Ln = 20*log10(max(abs(Fn(1:nb)) * sc, eps));
b  = f >= 0.5 & f <= 16;
P.ax = [ax_spec('Averaged Waveform', 'Time (ms)', 'Pressure (mPa)', 'linear', ...
           [line_(t, A / fac * 1e3, '-', [0.10 0.35 0.75], 1.2, 'TEOAE'), ...
            line_(t, NF / fac * 1e3, '-', [0.60 0.60 0.60], 1, 'Noise Floor')]), ...
        ax_spec('Spectrum', 'Frequency (kHz)', 'Level (dB SPL, Uncalibrated)', 'log', ...
           [line_(f(b), Ld(b), '-', [0.10 0.35 0.75], 2, 'TEOAE'), ...
            line_(f(b), Ln(b), '--', [0.45 0.45 0.45], 1.5, 'Noise Floor')])];
P.info = sprintf('%s   ·   %d of %d trials clean', P.info, numel(ko), numel(keep));
end


function P = memr(P, st)
% Same spectra as mx_metrics (click window, 4096-point FFT, complex mean of
% the good clicks; good = variance over the click window <= 1, as ART).
P.kind = 'MEMR';
Fs  = double(st.Fs);
att = double(st.noiseatt(:)');
if min(att) == 6, lev = 105 - (att - 6); else, lev = 105 - att; end
nck = ceil(double(st.clickwin) * Fs * 1e-3);
r1  = st.resp(:, :, 1, 1);
if size(st.resp, 1) == 1, tr = r1(:)' ~= 0; else, tr = any(r1 ~= 0, 1); end
if ~any(tr), P.note = 'No recorded trials in this file.'; return; end
cw = double(st.resp(:, tr, :, 1:nck));              % L x T x 7 x N
[nL, nT, ~, ~] = size(cw);
good = var(cw, 0, 4) <= 1;
nfft = 4096;
f  = (0:nfft/2) * Fs / nfft;
kf = find(f >= 200 & f <= 8000);  f = f(kf);
X  = fft(cw, nfft, 4);  X = X(:, :, :, kf);
X(~repmat(good, [1 1 1 numel(f)])) = NaN;
Xm = nmean(X, 2);                                   % L x 1 x 7 x F
base = reshape(Xm(:, 1, 1, :), nL, []);
elic = reshape(nmean(Xm(:, 1, 2:end, :), 3), nL, []);
b   = f >= 500 & f <= 2000;
den = sum(abs(base(:, b)), 2)';
V   = 100 * sum(abs(elic(:, b) - base(:, b)), 2)' ./ den;
Vn  = nan(1, nL);
for k = 1:nL
    xk = reshape(X(k, :, :, :), nT, size(X,3), []);
    d  = reshape(nmean(xk(:, 2:end, :), 2), nT, []) - reshape(xk(:, 1, :), nT, []);
    okt = all(isfinite(d(:, b)), 2);  n = sum(okt);
    if n >= 3
        sd = sqrt(var(real(d(okt, b)), 0, 1) + var(imag(d(okt, b)), 0, 1));
        Vn(k) = 100 * sum(sqrt(pi)/2 * sd / sqrt(n)) / den(k);
    end
end
[lev, o] = sort(lev);  V = V(o);  Vn = Vn(o);  base = base(o, :);  elic = elic(o, :);
dB = 20*log10(abs(elic) ./ abs(base));
sm = 15;  dB = conv2(dB, ones(1, sm) / sm, 'same');
anc = [0.267 0.005 0.329; 0.283 0.141 0.458; 0.254 0.265 0.530; 0.207 0.372 0.553; ...
       0.164 0.471 0.558; 0.128 0.567 0.551; 0.135 0.659 0.518; 0.267 0.749 0.441; ...
       0.478 0.821 0.318; 0.741 0.873 0.150; 0.993 0.906 0.144];
HM = interp1(linspace(0, 1, size(anc,1)), anc, linspace(0, 1, max(nL, 2)));
LS = line_([], [], '-', [0 0 0], 1, '');  LS(1) = [];
for k = 1:nL
    LS(end+1) = line_(f / 1e3, dB(k, :), '-', HM(k, :), 1.5, sprintf('%g dB FPL', lev(k))); %#ok<AGROW>
end
A1 = ax_spec('Vector Change', 'Elicitor Level (dB FPL)', 'Vector Change (%)', 'linear', ...
    [line_(lev, V, '-o', [0.10 0.35 0.75], 2, 'Response'), ...
     line_(lev, Vn, '--', [0.45 0.45 0.45], 1.5, 'Noise Floor')]);
A2 = ax_spec('Spectral Change (Clicks 2–7 re. Click 1)', 'Frequency (kHz)', '\DeltaLevel (dB)', 'log', LS);
A2.hline = 0;  A2.legend = false;
P.ax = [A1, A2];
P.info = sprintf('%s   ·   %d levels, %.0f %% good clicks', P.info, nL, 100 * mean(good(:)));
end


% ══════════════════════════════════════════════════════════════════════════
function [keep, edb] = clean_trials(R)
% trial energy re. the median trial (dB); > 6 dB above = artifact
e = sqrt(mean(R.^2, 2));
edb = 20*log10(max(e, eps) / max(median(e), eps));
keep = edb <= 6;
if ~any(keep), keep = true(size(keep)); end
end


function A = trial_ax(edb, keep)
n = numel(edb);
bars = struct('x', 1:n, 'y', edb(:)', 'clr', [0.35 0.55 0.80]);
if any(~keep), bars(2) = struct('x', find(~keep(:)'), 'y', edb(~keep)', 'clr', [0.85 0.25 0.20]); end
A = ax_spec(sprintf('Trial Energy (%d of %d Clean)', sum(keep), n), 'Trial', 'dB re. Median Trial', 'linear', ...
    line_([], [], '-', [0 0 0], 1, ''));
A.lines = A.lines([]);
A.bars = bars;  A.hline = 6;  A.legend = false;
end


function A = ax_spec(ttl, xl, yl, xs, lines)
A = struct('title',ttl, 'xlab',xl, 'ylab',yl, 'xscale',xs, 'lines',lines, ...
    'bars',struct('x',{},'y',{},'clr',{}), 'hline',[], 'legend',true);
end


function L = line_(x, y, style, clr, lw, name)
L = struct('x',x, 'y',y, 'style',style, 'clr',clr, 'lw',lw, 'name',name);
end


function w = hann_(n)
w = 0.5 - 0.5*cos(2*pi*(0:n-1)/(n-1));
end


function m = nmean(X, d)
ok = isfinite(X);  X(~ok) = 0;
m = sum(X, d) ./ sum(ok, d);
end
