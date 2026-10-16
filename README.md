# APAT — Auditory Physiology Analysis Toolkit

**Version 1.0.0 · 16 October 2026** · MATLAB R2025b (R2023b or newer)

Data analysis app for auditory physiology recorded in the chinchilla DOD noise / blast exposure study (pre and post exposure).

**Author:** Fernando Aguilera de Alba (https://github.com/fernandoaguilera10)
**Contributors:** Michael Heinz, Hari Bharadwaj, Andrew Sivaprakasam, Sam Hauser, Afagh Farhadi, Ipek Yuzcelik

## Measures
1. **ABR** (auditory brainstem response): automated thresholds (bootstrapped split-half correlation + sigmoid fit) and Wave I–V peak/trough picking (dynamic time warping) with manual review.
2. **EFR** (envelope following response): RAM — phase-locking value, SNR or spectral magnitude (µV) at 223 Hz harmonics; dAM — response and noise power along the modulation sweep.
3. **OAE** (otoacoustic emissions): swept DPOAE, swept SFOAE and TEOAE, FPL-calibrated (EPL / SPL), by half-octave band and frequency region.
4. **MEMR** (wideband middle-ear muscle reflex): growth function and acoustic reflex threshold, plus exploratory views (vector change, growth, kinetics, spectral, absorbance, probe, quality).
5. Aircraft carrier noise / dAM stimulus generation scripts (`Exposure Stimuli/`, stand-alone; Komrower et al., 2019).

## Getting started
1. Put this folder (`Code Archive/`) inside your project root next to `Data/` and `Analysis/`.
2. Open **`APAT.m`** in MATLAB and press **Run** (it checks the MATLAB release and toolboxes: Signal Processing, Curve Fitting, Statistics and Machine Learning).
3. In **Setup**: pick your user, root directory and subject roster (Excel; one sheet per experiment, e.g. NOISE, BLAST), select one or more **Experiments**, subjects, conditions and analyses, then **Run Analysis**.
4. Browse figures in **Results** (Average / Individual; Plot Settings to toggle conditions, subjects, shading, axes, and to show or overlay experiments). **Save Image** / **Save As New** export the view on screen.

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
- **Data export** (Setup › Output): MATLAB `.mat`, `.csv`, or both. CSVs are long ("tidy") tables — `Measure, Experiment, Subject, Sex, Condition, …keys, Metric, Value, Units` — with group statistics (`Mean, SD, N`) in `<name>.csv` and every subject × condition value (with an `Excluded` flag) in `<name>_Individual.csv`. Column definitions: `Analysis/APAT_data_dictionary.csv`.
- **Figures**: one image per Results view, saved with the plot defaults chosen in Setup (300 or 150 dpi).
- Errors during unattended runs are logged to `Analysis/APAT_error_log.txt`; the run continues.

## Tools (`tools/`, add to the path when needed)
- `apat_tidy_outputs(ROOTdir[, true])` — move an Analysis tree from the old layout to the current one (dry run by default; never deletes).
- `format_data` — export per-subject values from average `.mat` files.
- `create_abr_template` — build ABR peak templates.

## Lab
Auditory Neurophysiology and Modeling Lab — Dr. Michael G. Heinz
Lyles-Porter Hall, Room 3064, Purdue University, 715 Clinic Dr, West Lafayette, IN 47906
https://engineering.purdue.edu/HeinzLab · https://github.com/HeinzLabPurdue
