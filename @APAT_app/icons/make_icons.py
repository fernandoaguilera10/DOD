#!/usr/bin/env python3
"""Generate APAT Setup-tab button icons as retro pixel art.

Each icon is drawn on a small pixel grid (32x16 for measure buttons, 50x17
for type buttons) and upscaled x3 with nearest-neighbour so the pixels stay
crisp. Output: RGBA PNGs with transparent background next to this script,
plus preview.png (contact sheet on both button colours).

    python3 make_icons.py
"""
import math, os
import numpy as np
from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
SCALE = 3
# palette index -> RGBA (0 = transparent)
PAL = {0: (0, 0, 0, 0),
       1: (38, 38, 38, 255),      # ink
       2: (140, 107, 31, 255),    # dark gold
       3: (176, 64, 52, 255),     # red accent
       4: (240, 232, 210, 255),   # light highlight
       5: (100, 100, 100, 255)}   # grey: sub-threshold ABR traces
K, G, R, H, Y = 1, 2, 3, 4, 5
MW, MH = 32, 16      # measure-button grid
TW, TH = 50, 17      # type-button grid


class Grid:
    def __init__(s, w, h):
        s.w, s.h = w, h
        s.a = np.zeros((h, w), dtype=np.uint8)

    def px(s, x, y, c):
        x, y = int(round(x)), int(round(y))
        if 0 <= x < s.w and 0 <= y < s.h:
            s.a[y, x] = c

    def vline(s, x, y0, y1, c):
        for y in range(min(y0, y1), max(y0, y1) + 1):
            s.px(x, y, c)

    def hline(s, x0, x1, y, c):
        for x in range(min(x0, x1), max(x0, x1) + 1):
            s.px(x, y, c)

    def rect(s, x0, y0, x1, y1, c):
        for y in range(y0, y1 + 1):
            s.hline(x0, x1, y, c)

    def trace(s, ys, x0=0, c=K, shadow=G):
        """Stepped pixel line through integer rows ys[i] at column x0+i.
        Consecutive columns are joined by vertical runs (no anti-aliasing);
        a gold drop-shadow one pixel below gives the 16-bit look."""
        ys = [int(round(v)) for v in ys]
        if shadow:
            for i, y in enumerate(ys):
                x = x0 + i
                if i and abs(ys[i] - ys[i - 1]) > 1:
                    pass
                if s.a[min(y + 1, s.h - 1), x] == 0 if 0 <= x < s.w and y + 1 < s.h else False:
                    s.px(x, y + 1, shadow)
        for i, y in enumerate(ys):
            x = x0 + i
            if i:
                p = ys[i - 1]
                if y < p:      # rising: fill this column up from previous
                    s.vline(x, y, p - 1, c)
                elif y > p:    # falling: fill previous column down
                    s.vline(x - 1, p + 1, y, c)
            s.px(x, y, c)

    def sq(s, x, y, c=R, outline=K):
        """2x2 data point with ink outline-ish corner."""
        s.rect(x, y, x + 1, y + 1, c)

    def image(s):
        rgba = np.zeros((s.h, s.w, 4), dtype=np.uint8)
        for k, v in PAL.items():
            rgba[s.a == k] = v
        im = Image.fromarray(rgba, 'RGBA')
        return im.resize((s.w * SCALE, s.h * SCALE), Image.NEAREST)


def bumps(n, centers, amps, width, base, extra=None):
    """Sum of gaussian bumps sampled at n columns -> row values (y down)."""
    out = []
    for x in range(n):
        v = sum(a * math.exp(-((x - c) / width) ** 2) for c, a in zip(centers, amps))
        if extra:
            v += extra(x)
        out.append(base - v)
    return out


# ── tiny pixel font for roman numerals (I: 1x3, V: 3x3) ────────────────────
GLYPH = {'I': ["x", "x", "x"], 'V': ["x.x", "x.x", ".x."]}


def text(g, s, x, y, c=K):
    for ch in s:
        rows = GLYPH[ch]
        for dy, row in enumerate(rows):
            for dx, p in enumerate(row):
                if p == 'x':
                    g.px(x + dx, y + dy, c)
        x += len(rows[0]) + 1


def text_w(s):
    return sum(len(GLYPH[ch][0]) + 1 for ch in s) - 1


# ── Real-data templates (embedded so the script needs no data files) ───────
# ABR: Analysis/ABR/Q438/pre/Baseline/Q438_Baseline_ABRpeaks_dtw_4000Hz.mat
#      (abrs.waveforms, 4 kHz tone bursts, levels 80/60/40/20/0 dB SPL,
#       samples 4.5-12.5 ms at 0.125 ms, uV)
# MEMR: Analysis/MEMR/Q438/pre/Baseline/Q438_MEMR_WB_Baseline_p0010.mat
#      (memr.MEM interpolated at 40 log-spaced frequencies 0.3-8 kHz,
#       elicitor levels 81-105 dB)
ABR_T0, ABR_DT = 4.500, 0.125
ABR_WAVES = {
    80: [-0.016, -0.055, 0.011, -0.022, 0.012, -0.051, -0.096, 0.050, 0.084, 0.509, 0.540, 0.298, 0.139, -0.067, -0.267, -0.059, 0.409, 0.935, 0.980, 1.267, 1.532, 1.452, 0.778, 0.074, 0.273, 0.868, 1.336, 2.009, 2.330, 1.205, -0.128, -0.762, -0.099, 0.911, 1.616, 1.528, 1.532, 1.340, 0.934, 0.246, -0.276, -0.056, 0.383, 0.525, 0.209, 0.067, -0.258, -0.582, -0.888, -1.014, -1.157, -0.881, -0.839, -0.727, -0.459, -0.359, -0.313, -0.414, -0.458, -0.426, -0.532, -0.417, -0.421, -0.574, -0.456],
    60: [-0.146, 0.004, 0.003, 0.065, 0.017, 0.034, 0.072, -0.091, -0.067, 0.010, 0.112, 0.063, -0.037, 0.066, 0.025, 0.144, 0.110, 0.185, 0.104, 0.042, -0.003, 0.234, 0.654, 0.858, 1.138, 1.221, 0.851, 0.264, -0.503, -0.447, 0.224, 0.616, 0.739, 0.989, 1.638, 1.410, 0.590, 0.270, 0.197, -0.344, -0.418, 0.130, 0.716, 1.170, 0.904, 0.267, -0.134, -0.446, -0.913, -1.087, -1.046, -0.830, -0.517, -0.452, -0.190, 0.089, 0.120, -0.030, -0.082, 0.118, -0.280, -0.426, -0.317, -0.516, -0.455],
    40: [0.068, 0.035, 0.063, 0.019, -0.027, 0.029, -0.047, -0.047, 0.062, 0.154, 0.062, 0.013, 0.006, 0.149, 0.013, 0.062, 0.021, 0.014, -0.020, -0.020, -0.050, 0.030, 0.010, -0.015, 0.237, 0.341, 0.860, 0.887, 0.466, -0.245, -1.013, -0.821, -0.570, 0.620, 1.503, 1.057, 0.897, 1.211, 0.833, -0.424, -1.371, -1.035, -0.408, 0.297, 0.950, 1.145, 0.569, -0.145, -0.476, -0.747, -0.742, -0.588, -0.424, -0.228, -0.080, 0.074, 0.194, -0.005, -0.154, -0.218, -0.253, -0.347, -0.298, -0.164, -0.037],
    20: [-0.155, -0.105, -0.090, -0.173, -0.077, -0.014, 0.010, 0.035, -0.048, -0.057, -0.091, -0.108, -0.154, -0.160, 0.081, 0.049, 0.059, -0.123, -0.013, -0.060, 0.102, 0.095, -0.093, -0.132, -0.036, 0.071, 0.001, -0.034, -0.047, 0.076, 0.359, 0.417, 0.258, -0.050, -0.300, -0.336, -0.088, 0.161, 0.402, 0.538, 0.554, 0.522, 0.248, -0.040, -0.644, -0.589, -0.201, 0.020, 0.243, 0.385, 0.145, 0.124, 0.027, -0.136, -0.187, -0.120, -0.048, -0.200, -0.141, -0.032, -0.041, -0.028, -0.149, 0.072, 0.102],
    0: [-0.032, -0.105, -0.040, -0.073, -0.050, -0.025, -0.119, 0.154, 0.075, -0.012, -0.099, -0.088, -0.028, -0.074, 0.017, -0.131, 0.008, 0.091, 0.034, 0.033, 0.024, 0.085, -0.107, -0.109, 0.145, 0.201, 0.064, -0.096, -0.023, -0.053, 0.016, 0.084, 0.071, 0.065, -0.053, -0.011, 0.070, 0.017, 0.105, 0.031, -0.030, 0.056, 0.078, 0.094, 0.053, -0.120, 0.012, 0.063, 0.106, 0.101, 0.040, -0.135, -0.089, -0.052, -0.075, -0.135, 0.043, 0.153, 0.124, -0.128, -0.218, 0.056, 0.034, -0.116, 0.169],
}
MEMR_F = [300, 326, 355, 386, 420, 457, 497, 541, 588, 640, 696, 757, 824, 896, 975, 1061, 1154, 1255, 1365, 1485, 1616, 1758, 1912, 2080, 2263, 2462, 2678, 2913, 3169, 3447, 3750, 4079, 4438, 4827, 5251, 5713, 6214, 6760, 7354, 8000]
MEMR_CURVES = {
    81: [-0.010, -0.016, -0.017, -0.011, -0.012, -0.023, 0.003, 0.004, 0.002, 0.013, 0.041, 0.055, 0.041, 0.087, -0.002, -0.042, -0.013, -0.023, -0.023, -0.037, -0.038, -0.035, -0.011, -0.018, -0.013, -0.001, -0.046, 0.009, -0.026, 0.023, 0.031, 0.082, 0.037, 0.036, 0.030, 0.072, 0.015, -0.051, -0.037, -0.026],
    87: [-0.040, -0.042, -0.040, -0.040, -0.042, -0.025, -0.020, 0.014, 0.100, 0.187, 0.294, 0.326, 0.390, 0.383, 0.131, 0.082, 0.027, -0.020, -0.044, -0.038, -0.018, -0.025, -0.043, -0.071, -0.094, -0.045, -0.083, -0.027, -0.017, -0.040, -0.077, -0.078, -0.010, 0.060, 0.096, 0.069, -0.001, 0.003, -0.023, -0.024],
    93: [-0.110, -0.137, -0.164, -0.161, -0.141, -0.113, -0.036, 0.090, 0.296, 0.724, 1.198, 1.571, 1.655, 1.371, 0.629, -0.011, -0.288, -0.495, -0.476, -0.417, -0.322, -0.248, -0.088, -0.296, -0.327, -0.182, -0.288, -0.155, -0.088, -0.091, -0.028, 0.056, 0.223, 0.252, 0.261, 0.065, -0.211, -0.057, -0.078, -0.055],
    99: [-0.262, -0.309, -0.358, -0.364, -0.358, -0.302, -0.172, 0.058, 0.475, 1.208, 2.204, 3.073, 3.577, 3.382, 2.219, 0.665, -0.322, -1.141, -1.188, -1.096, -0.768, -0.684, -0.221, -0.788, -0.871, -0.522, -0.692, -0.461, -0.303, -0.215, -0.089, 0.125, 0.552, 0.702, 0.658, 0.127, -0.118, -0.285, -0.231, -0.175],
    105: [-0.372, -0.457, -0.563, -0.630, -0.674, -0.659, -0.570, -0.298, 0.170, 1.031, 2.426, 4.168, 5.679, 6.359, 5.797, 3.986, 1.577, -0.094, -1.002, -1.600, -1.329, -1.118, -0.596, -1.902, -1.865, -1.294, -1.479, -1.627, -1.263, -0.896, -0.619, -0.224, 0.673, 1.423, 1.689, 0.938, -0.081, -0.613, -0.569, -0.454],
}


def abr_template(level, n, t0=4.5, t1=12.5):
    """Recorded ABR (uV) between t0 and t1 ms resampled to n columns."""
    w = np.array(ABR_WAVES[level])
    t = ABR_T0 + ABR_DT * np.arange(len(w))
    return np.interp(np.linspace(t0, t1, n), t, w)


def ms_to_col(ms, n, t0=4.5, t1=12.5):
    return (ms - t0) / (t1 - t0) * (n - 1)


# Latencies (ms) of waves I-V in the 80 dB recording (local maxima; I, III,
# IV and V agree with the file's DTW peak_latency)
ABR_PEAK_MS = [5.75, 7.0, 8.0, 8.75, 9.875]


# ── ABR ────────────────────────────────────────────────────────────────────
def smooth(w, k=(1, 2, 3, 2, 1)):
    """Light FIR smoothing (edge-padded) that keeps waves I-V and the trough."""
    k = np.array(k, float) / sum(k)
    h = len(k) // 2
    return np.convolve(np.pad(w, h, mode='edge'), k, mode='valid')


def icon_abr():
    g = Grid(MW, MH)
    w = np.array(ABR_WAVES[80])
    t = ABR_T0 + ABR_DT * np.arange(len(w))
    w = np.interp(np.linspace(4.5, 12.5, MW), t, smooth(w)) / smooth(w).max()
    g.trace(10.5 - 9 * w)
    return g


def icon_abr_thresholds():
    """Clean waterfall: 80/60/40/20 dB, each trace kept inside its own band
    (one empty row between bands, so traces never touch); band heights
    shrink downwards and the 20 dB trace is almost flat."""
    g = Grid(TW, TH)
    levels = [80, 60, 40, 20]
    tops = [0.0, 5.5, 10.0, 14.5]
    spans = [4.0, 3.0, 2.0, 0.8]
    colours = [K, K, Y, Y]          # at/above threshold ink, below grey
    for L, top, r, c in zip(levels, tops, spans, colours):
        w = abr_template(L, TW)
        w = (w.max() - w) / (w.max() - w.min())      # 0 at max, 1 at min
        g.trace(top + r * w, c=c, shadow=None)
    return g


def icon_abr_peaks():
    g = Grid(TW, TH)
    t0, t1 = 5.0, 11.5
    w = abr_template(80, TW, t0, t1) / max(ABR_WAVES[80])
    ys = 12.3 - 6.8 * w
    g.trace(ys)
    boxes = []
    for ms, lab in zip(ABR_PEAK_MS, ['I', 'II', 'III', 'IV', 'V']):
        c = int(round(ms_to_col(ms, TW, t0, t1)))
        x = min(range(c - 1, c + 2), key=lambda k: ys[k])   # snap to local max
        y = int(round(ys[x]))
        g.px(x - 1, y - 1, R); g.px(x, y - 1, R); g.px(x + 1, y - 1, R)
        tw = text_w(lab)
        lx = x - tw // 2
        ly = y - 5
        while ly > 0 and any(lx <= bx1 + 1 and lx + tw - 1 >= bx0 - 1 and
                             ly <= by1 + 1 and ly + 2 >= by0 - 1
                             for bx0, by0, bx1, by1 in boxes):
            ly -= 1
        ly = max(0, ly)
        boxes.append((lx, ly, lx + tw - 1, ly + 2))
        text(g, lab, lx, ly, K)
    return g


# ── EFR ────────────────────────────────────────────────────────────────────
def icon_efr():
    g = Grid(MW, MH)
    floor = 13
    g.hline(0, MW - 1, floor + 1, K)                # axis
    for x in range(MW):
        g.px(x, floor, G)                           # noise floor
    heights = [11, 9, 7, 5, 4, 3]
    for i, h in enumerate(heights):
        x = 3 + i * 5
        g.vline(x, floor - h, floor, K)
        g.rect(x - 1, floor - h - 1, x, floor - h, R)  # 2x2 stem head
    return g


def osc_trace(g, env, mid, c=K):
    """Carrier at the pixel Nyquist rate (sign flips every column) scaled by
    env(x): reads as a dense oscillation whose outline is the envelope."""
    ys = [mid - env(x) * (1 if x % 2 == 0 else -1) for x in range(g.w)]
    g.trace(ys, c=c, shadow=None)


def icon_efr_dam():
    g = Grid(TW, TH)
    # envelope modulation rate sweeps up across the icon (chirp envelope)
    phase = lambda x: 2 * math.pi * (0.012 * x + 0.0026 * x * x)
    osc_trace(g, lambda x: 7 * (0.5 + 0.5 * math.cos(phase(x))), 8)
    return g


def icon_efr_ram():
    g = Grid(TW, TH)
    period, on = 16, 4                       # 25 % duty
    osc_trace(g, lambda x: 6.5 if (x - 1) % period < on else 0.0, 8)
    return g


# ── OAE ────────────────────────────────────────────────────────────────────
def axes(g):
    g.vline(0, 0, g.h - 1, K); g.hline(0, g.w - 1, g.h - 1, K)


def noise_floor(g, curve, x0, hi, lo, seed, c=G, gap=2):
    """Jagged, broken noise floor: high (row `hi`) at low frequencies, falling
    to row `lo` then flattening, with small random bumps (fixed seed); kept
    at least 2 rows below the emission curve. Pixels on columns where
    (x % 3 == gap) are left out so it reads as a broken line."""
    rng = np.random.default_rng(seed)
    n = g.w - x0
    bump = rng.integers(-1, 2, n) + (rng.random(n) < 0.15)
    for i in range(n):
        x = x0 + i
        y = lo - (lo - hi) * math.exp(-i / (0.22 * n)) + bump[i]
        if curve is not None:
            y = max(y, curve[i] + 2)
        y = min(int(round(y)), g.h - 2)
        if x % 3 != gap:
            g.px(x, y, c)


def icon_oae():
    g = Grid(MW, MH)
    axes(g)
    curve = [8.5 - 5 * math.exp(-((x - 14) / 9) ** 2) - 0.8 * math.sin(x / 2.5) for x in range(1, MW)]
    noise_floor(g, curve, 1, 10, 13.4, seed=3)
    g.trace(curve, x0=1, shadow=None)
    for x in range(3, MW - 1, 5):
        y = int(round(curve[x - 1]))
        g.rect(x - 1, y - 1, x, y, R)
    return g


def icon_oae_dpoae():
    g = Grid(TW, TH)
    axes(g)
    curve = [10.5 - 8 * math.exp(-((x - 22) / 14) ** 2) for x in range(1, TW)]
    noise_floor(g, curve, 1, 12, 14.6, seed=7)
    g.trace(curve, x0=1, shadow=G)
    for x in range(5, TW - 1, 7):
        y = int(round(curve[x - 1]))
        g.rect(x - 1, y - 1, x, y, R)
    return g


def icon_oae_sfoae():
    g = Grid(TW, TH)
    axes(g)
    curve = [7.5 - 3 * math.exp(-((x - 20) / 18) ** 2) + 2.2 * math.sin(x * 1.25) * (0.6 + 0.4 * math.cos(x / 9))
             for x in range(1, TW)]
    noise_floor(g, curve, 1, 11.5, 14.6, seed=11)
    g.trace(curve, x0=1, shadow=None)
    return g


def icon_oae_teoae():
    g = Grid(TW, TH)
    axes(g)
    # TEOAE amplitude spectrum: broad plateau at low/mid frequencies with
    # small irregularities, rolling off steeply at high frequency
    curve = []
    for x in range(1, TW):
        f = x / TW
        roll = 0 if f < 0.5 else 26 * (f - 0.5) ** 1.3
        curve.append(min(13, 4 + 1.0 * math.sin(x / 2.3) + 0.6 * math.sin(x / 1.1) + roll))
    noise_floor(g, curve, 1, 11.5, 14.6, seed=5)
    g.trace(curve, x0=1, shadow=G)
    for x in range(5, TW - 1, 7):
        y = int(round(curve[x - 1]))
        g.rect(x - 1, y - 1, x, y, R)
    return g


# ── MEMR ───────────────────────────────────────────────────────────────────
def memr_icon(w, h):
    """Wideband MEMR spectra (pressure change vs log frequency) at two
    elicitor levels (93 dB red, 105 dB ink), single-pixel lines, no shadow.
    |v|^0.5 compression keeps the 1.5-3 kHz dip and the ~5 kHz peak visible
    next to the large ~1 kHz peak; scaled to the full icon height."""
    g = Grid(w, h)
    lf = np.log(MEMR_F)
    cols = np.linspace(lf[0], lf[-1], w)
    comp = lambda v: np.sign(v) * np.abs(v) ** 0.5
    top = comp(np.interp(cols, lf, MEMR_CURVES[105]))
    pos, neg = top.max(), -top.min()
    amp = (h - 1.6) / (pos + neg)
    base = 0.4 + amp * pos
    for x in range(0, w, 2):
        g.px(x, base, H)                     # faint dotted 0 line
    for L, c in [(93, R), (105, K)]:
        v = comp(np.interp(cols, lf, MEMR_CURVES[L]))
        g.trace(base - amp * v, c=c, shadow=None)
    return g


# MEMR 7-click train (wbmemr.m: 7 sweeps per trial, each a probe click
# followed by the elicitor noise). Reflex size per click = complex vector
# change |X_k - X_1| / |X_1| over 0.5-2 kHz, trial-averaged spectra, from
# Data/Q474/MEMR/pre/Baseline/p0007_memr.mat at 105 dB FPL. Click 1 comes
# before any elicitor (baseline), so its change is 0.
MEMR_CLICK_CHANGE = [0.0, 0.738, 0.697, 0.682, 0.664, 0.656, 0.667]


def icon_memr():
    """Measure button: the 7-click train. Click 1 (ink, no elicitor yet) at
    full height; clicks 2-7 (red) shorter by the reflex change measured at
    each click (illustrative scale 0.45), on a gold baseline. The ART button
    keeps the reflex-spectra icon (memr_icon)."""
    g = Grid(MW, MH)
    mid = 8
    for k, ch in enumerate(MEMR_CLICK_CHANGE):
        x = int(round(2 + k * 4.5))
        h = int(round(6.5 * (1 - 0.45 * ch)))
        c = K if k == 0 else R
        g.vline(x, mid - h, mid + h, c)                       # click
        g.vline(x + 1, mid - int(h * 0.6), mid + int(h * 0.6), c)   # ringing
    for x in range(MW):
        if g.a[mid, x] == 0:
            g.px(x, mid, G)
    return g


def icon_memr_type():
    return memr_icon(TW, TH)


# ── MEMR type buttons (ART + exploratory analyses) ────────────────────────
def icon_memr_art():
    """ART: the reflex-spectra icon (same as icon_memr_type)."""
    return memr_icon(TW, TH)


def icon_memr_vector():
    """Vector change: baseline vector (ink) and elicitor vector (red) from a
    common origin, with the gold difference vector joining their tips."""
    g = Grid(TW, TH)
    ox, oy = 14, 14
    g.hline(4, 46, oy, Y)                      # real axis
    g.vline(ox, 1, 16, Y)                      # imaginary axis
    def seg(x0, y0, x1, y1, c):
        n = int(max(abs(x1 - x0), abs(y1 - y0))) * 2 + 1
        for t in np.linspace(0, 1, n):
            g.px(x0 + (x1 - x0) * t, y0 + (y1 - y0) * t, c)
    seg(ox, oy, 40, 5, K)                      # baseline (click 1)
    seg(ox, oy, 33, 2, R)                      # during the elicitor
    seg(40, 5, 33, 2, G)                       # difference = vector change
    g.rect(39, 4, 40, 5, K)
    g.rect(32, 1, 33, 2, R)
    return g


def icon_memr_growth():
    """Growth: sigmoid growth function with data points and a dashed noise floor."""
    g = Grid(TW, TH)
    axes(g)
    ys = [14.5 - 12 / (1 + math.exp(-(x - 30) / 4.5)) for x in range(1, TW)]
    for x in range(2, TW, 3):
        g.px(x, 13, G)                         # noise floor
    g.trace(ys, x0=1, shadow=None)
    for x in range(5, TW - 1, 7):
        y = int(round(ys[x - 1]))
        g.rect(x - 1, y - 1, x, y, R)
    return g


def icon_memr_kinetics():
    """Kinetics: reflex size at clicks 2-7 building up towards a plateau."""
    g = Grid(TW, TH)
    axes(g)
    for k in range(6):
        x = 6 + k * 7
        h = int(round(4 + 9 * (1 - math.exp(-k / 1.6))))
        g.rect(x, TH - 1 - h, x + 2, TH - 2, K if k else Y)
        g.rect(x, TH - 1 - h, x + 2, TH - 1 - h, R)
    return g


def icon_memr_spectral():
    """Spectral: level change across frequency (rise near 0.5-1 kHz, dip at
    2-4 kHz) around a dotted zero line."""
    g = Grid(TW, TH)
    base = 8
    for x in range(0, TW, 2):
        g.px(x, base, H)
    ys = [base - 6 * math.exp(-((x - 14) / 7) ** 2) + 4 * math.exp(-((x - 30) / 5) ** 2)
          - 1.5 * math.exp(-((x - 42) / 3) ** 2) for x in range(TW)]
    g.trace(ys, shadow=None)
    return g


def icon_memr_absorbance():
    """Absorbance: baseline absorbance (ink) and the lower curve during the
    reflex (red) below ~1 kHz, meeting at higher frequencies."""
    g = Grid(TW, TH)
    axes(g)
    a0 = [13 - 10 / (1 + math.exp(-(x - 12) / 4)) for x in range(1, TW)]
    a1 = [a + 4.0 * math.exp(-((x + 1 - 13) / 7) ** 2) for x, a in enumerate(a0)]
    g.trace(a1, x0=1, c=R, shadow=None)
    g.trace(a0, x0=1, c=K, shadow=None)
    return g


def icon_memr_probe():
    """Elicitor as probe: a noise burst whose recorded level steps down once
    the reflex is on (first burst ink, later part red)."""
    g = Grid(TW, TH)
    mid = 8
    rng = np.random.default_rng(5)
    ys = []
    for x in range(TW):
        env = 6.5 if x < 18 else 4.0
        if x < 2 or x > TW - 3:
            env = 1.5
        a = env * (0.45 + 0.55 * rng.random())
        ys.append(mid - a * (1 if x % 2 == 0 else -1))
    g.trace(ys[:19], shadow=None)
    g.trace(ys[18:], x0=18, c=R, shadow=None)
    return g


def icon_memr_quality():
    """Quality: signal-to-noise bars over a dotted criterion line, with a check."""
    g = Grid(TW, TH)
    axes(g)
    hs = [3, 4, 3, 6, 9, 12, 14]
    for k, h in enumerate(hs):
        x = 4 + k * 5
        c = K if h >= 6 else Y
        g.rect(x, TH - 1 - h, x + 2, TH - 2, c)
    for x in range(1, TW, 2):
        g.px(x, TH - 1 - 6, R)                 # detection criterion
    for i, (dx, dy) in enumerate([(0, 0), (1, 1), (2, 2), (3, 1), (4, 0), (5, -1), (6, -2), (7, -3)]):
        g.px(40 + dx, 6 + dy, G); g.px(40 + dx, 7 + dy, G)
    return g


# Measure-button icons (icon_abr / icon_efr / icon_oae / icon_memr) come from
# make_sprites.py since Oct 16 2026 (ear + tone, AM wave -> brain, hair cells,
# ossicles); the old icon_abr / icon_efr / icon_oae / icon_memr functions
# above are kept for reference only.
ICONS = [
    ('icon_abr_thresholds', icon_abr_thresholds),
    ('icon_abr_peaks', icon_abr_peaks),
    ('icon_efr_dam', icon_efr_dam), ('icon_efr_ram', icon_efr_ram),
    ('icon_oae_dpoae', icon_oae_dpoae),
    ('icon_oae_sfoae', icon_oae_sfoae), ('icon_oae_teoae', icon_oae_teoae),
    ('icon_memr_type', icon_memr_type),
    ('icon_memr_art', icon_memr_art), ('icon_memr_vector', icon_memr_vector),
    ('icon_memr_growth', icon_memr_growth), ('icon_memr_kinetics', icon_memr_kinetics),
    ('icon_memr_spectral', icon_memr_spectral), ('icon_memr_absorbance', icon_memr_absorbance),
    ('icon_memr_probe', icon_memr_probe), ('icon_memr_quality', icon_memr_quality),
]


def main():
    ims = []
    for name, fn in ICONS:
        im = fn().image()
        im.save(os.path.join(HERE, name + '.png'))
        ims.append((name, im))
    # measure icons + run-card chinchilla sprites (make_sprites.py)
    import sys
    sys.dont_write_bytecode = True          # no __pycache__ next to the icons
    import make_sprites
    ims = [(n, im) for n, im in make_sprites.main() if n.startswith('icon_')] + ims
    # contact sheet: each icon on subtle yellow (selected) and beige (unselected)
    GREEN, BEIGE = (233, 213, 133), (219, 214, 201)
    cw, ch = 200, 80
    sheet = Image.new('RGB', (40 + 2 * cw + 220, 20 + ch * len(ims)), (255, 255, 255))
    d = ImageDraw.Draw(sheet)
    for i, (name, im) in enumerate(ims):
        y = 10 + i * ch
        d.text((10, y + ch // 2 - 6), name, fill=(0, 0, 0))
        for j, bg in enumerate((GREEN, BEIGE)):
            x = 210 + j * (cw + 10)
            d.rectangle([x, y, x + cw, y + ch - 6], fill=bg)
            sheet.paste(im, (x + (cw - im.width) // 2, y + (ch - 6 - im.height) // 2), im)
    sheet.save(os.path.join(HERE, 'preview.png'))
    for n, im in ims:
        print(n, im.size)


if __name__ == '__main__':
    main()
