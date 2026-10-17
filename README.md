# APAT — Auditory Physiology Analysis Toolkit

**Version 1.0.1 · 17 October 2026** · MATLAB R2025b (R2023b or newer)

MATLAB-based Interface for Auditory Physiology Analysis (Chinchilla)

**Author:** Fernando Aguilera de Alba (https://github.com/fernandoaguilera10)
**Contributors:** Michael Heinz, Hari Bharadwaj, Andrew Sivaprakasam, Sam Hauser, Afagh Farhadi, Satyabrata Parida

## Measures
1. **ABR** (auditory brainstem response): automated thresholds (bootstrapped split-half correlation + sigmoid fit) and Wave I–V peak/trough picking (dynamic time warping) with manual review.
2. **EFR** (envelope following response): RAM — phase-locking value, SNR or spectral magnitude (µV) at 223 Hz harmonics; dAM — response and noise power along modulation sweep.
3. **OAE** (otoacoustic emissions): swept DPOAE, swept SFOAE and TEOAE — half-octave band and frequency region average (dB EPL and dB SPL)
4. **MEMR** (wideband middle-ear muscle reflex): acoustic reflex threshold plus exploratory techniques (vector, growth, kinetics, spectral, absorbance, probe, quality).
5. Aircraft carrier noise (Komrower et al., 2019)
6. dAM stimulus generation (Parida et al. 2024)

## What's new in 1.0.1
- Faster long runs: the EFR RAM average spectrum is drawn as one line per condition (it was ~22,000 line objects, which slowed every later measure 3–4×).
- Timing log: each run writes `Analysis/APAT_timing.csv` (seconds per step: RAW retrieval, analysis, summary, Results display, image export, total).
- Measure code is loaded from the folder APAT is started from (not a hard-coded `Code Archive`), so a copy or git worktree runs its own code.
- Results UI updates; no more "already-destroyed variable 'busy'" hover warning; spinner timer no longer forces a redraw mid-plot.

## Getting started
1. Download this repository and rename it to `Code Archive/`.
2. Put this folder `Code Archive/` inside your project root next to `Data/` and `Analysis/`.
3. Go to `Code Archive/` to open **`APAT.m`** in MATLAB. Press **Run** (it checks the MATLAB release and toolboxes: Signal Processing, Curve Fitting, Statistics and Machine Learning).
4. In **Setup**: pick your user, root directory and subject roster (Excel; one sheet per experiment, e.g. NOISE, BLAST), select one or more **Experiments**, subjects, conditions and analyses, then **Run Analysis**.
5. Browse figures in **Results** (Average / Individual; Plot Settings to toggle conditions, subjects, shading, axes, and to show or overlay experiments). **Save Image** / **Save As New** export the view on screen.

## Folder layout
```
<root>/
  Code Archive/   APAT.m (launcher) · @APAT_app/ (app) · ABR/ EFR/ OAE/ MEMR/ (analyses)
                  shared/ (helpers) · tools/ (stand-alone utilities) · Exposure Stimuli/
  Data/           <Subject>/<Measure>/<pre|post>/<Condition>/  (raw recordings; Data/RAW/ incoming)
  Analysis/       <Measure>/<Subject>/<pre|post>/<Condition>/  per-recording results
                  <Measure>/<Subject>/                         all-conditions figures
                  <Measure>/Average/                           group results (all experiments)
                  DOD_ChinRoster.xlsx · APAT_data_dictionary.csv · APAT_error_log.txt
```

## Outputs
- **Data export** (Setup › Output): MATLAB `.mat`, `.csv`, or both. Only CSVs are long `tidy` data structures for open-source use — `Measure, Experiment, Subject, Sex, Condition, …keys, Metric, Value, Units` — with group statistics (`Mean, SD, N`). See `Analysis/APAT_data_dictionary.csv` for variable definition.
- **Figures**: one image per subject across conditions, saved with plot defaults chosen in Setup (300 or 150 dpi).
- Errors during unattended runs are logged to `Analysis/APAT_error_log.txt` without interrupting the analysis run.

## Tools (`tools/`, add to the path when needed)
- `format_data` — export per-subject values from average `.mat` files.
- `create_abr_template` — build ABR peak templates.

## Lab
Auditory Neurophysiology and Modeling Lab — Dr. Michael G. Heinz
Lyles-Porter Hall, Room 3064, Purdue University, 715 Clinic Dr, West Lafayette, IN 47906
https://engineering.purdue.edu/HeinzLab · https://github.com/HeinzLabPurdue
