# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

MATLAB analysis toolkit for auditory neurophysiology research at Purdue University (Dr. Michael G. Heinz Lab). Analyzes four measurement modalities: **ABR** (Auditory Brainstem Response), **EFR** (Envelope Frequency Response), **OAE** (Otoacoustic Emissions), and **MEMR** (Wideband Middle Ear Muscle Reflex). Requires MATLAB R2025b.

## Running Analysis

All analysis starts from `analysis_setup.m`. Edit these variables before running:

```matlab
ROOTdir       % Root data directory (macOS: /Volumes/FefeSSD/DOD, Windows: E:\DOD)
Chins2Run     % Cell array of subject IDs (e.g., {'CH1','CH2'})
Conds2Run     % Cell array of conditions (e.g., {'pre','post'})
chinroster_filename  % Path to Excel spreadsheet with subject metadata
chinroster_sheet     % 'BLAST' or 'NOISE' experiment type
reanalyze     % 1 = force re-analysis, 0 = skip if already analyzed
```

Then run `analysis_setup` in MATLAB. An interactive GUI guides selection of analysis type and sub-type.

## Architecture

### Data Flow

```
analysis_setup.m → analysis_run.m (orchestrator)
    ├── analysis_menu()         % GUI: select analysis type
    ├── plot_limits()           % get y-axis ranges per modality
    ├── get_directory()         % resolve paths: ROOTdir → Data/, Analysis/, Code Archive/
    ├── define_global_vars()    % initialize global variables for selected modality
    ├── search_files()          % locate raw .mat files in Data/RAW/
    ├── [per subject/condition]
    │   └── {ABR_thresholds | ABR_dtw | dAManalysis | RAManalysis |
    │          DPanalysis | SFanalysis | TEanalysis | WBMEMRanalysis}
    └── [aggregation]
        ├── {ABRsummary | dAMsummary | RAMsummary | DPsummary | ...}
        ├── avg_*() functions
        └── plot_avg_*() functions
```

### Directory Layout

- `private/` — Core utilities accessible to all modules: `analysis_run.m`, `analysis_menu.m`, `define_global_vars.m`, `get_directory.m`, `load_files.m`, `format_data.m`, `search_files.m`, `plot_limits.m`
- `ABR/Thresholds/` — Bootstrapped cross-correlation threshold estimation (`ABR_thresholds.m`)
- `ABR/Peaks/` — Dynamic Time Warping peak detection (`ABR_dtw.m`, `findPeaks_dtw.m`); DTW library in `+dtw_lib/` package
- `ABR/Peaks/private/` — ABR-specific utilities (artifact rejection, GUI, calibration readers)
- `EFR/RAM/` — Phase Locking Value analysis for 223 Hz RAM stimulus (`RAManalysis.m`); helpers in `+helper/`
- `EFR/dAM/` — SNR analysis for AM-sweep stimulus (`dAManalysis.m`)
- `OAE/DPOAE/`, `OAE/SFOAE/`, `OAE/TEOAE/` — Swept OAE analyses using Forward Pressure Level calibration
- `MEMR/` — Growth function and threshold analysis (`WBMEMRanalysis.m`, `MEMRbyLevel.m`)
- `Exposure Stimuli/` — Stimulus generation scripts (not part of analysis pipeline)

### Data Storage Pattern

**Input:** `Data/RAW/[Subject]/[EXPname]/[pre|post]/[Condition]/*.mat`  
**Calibration:** `Data/Calibration/*calib*.mat` — `load_files.m` auto-selects closest earlier calibration by p-number  
**Output:** `Analysis/[ABR|EFR|OAE|MEMR]/[Subject]/[pre|post]/[Condition]/*.mat`  
**Figures:** `Analysis/[modality]/*_Average_*.fig` and `*_Average_*.png`

### Global Variables

Each modality uses MATLAB global variables for cross-function data sharing during aggregation. Initialized in `define_global_vars.m`:
- ABR: `abr_f`, `abr_thresholds`, `abr_peaks_amp`, `abr_peaks_lat`, `abr_waveform`
- EFR: `efr_f`, `efr_PLV`, `efr_peak_amp`, `efr_peak_freq`, `efr_envelope`
- OAE: `dp_f_epl`, `dp_amp_epl`, `dp_nf_epl`, `sf_f_epl`, `te_f_epl` (EPL and SPL variants)
- MEMR: `elicitor`, `deltapow`, `threshold`

### Experiment Configurations

- **BLAST:** timepoints Pre/Baseline, Post/D3, D7, D14
- **NOISE:** timepoints Pre/Baseline, Post/D7, D14, D30

### Key Technical Parameters

| Modality | Key Parameters |
|----------|----------------|
| ABR Thresholds | Resampled to 8 kHz; 200 bootstrap iterations, 400 samples; sigmoid fit |
| ABR Peaks (DTW) | Frequencies: Click, 0.5/1/2/4/8 kHz; Levels: 80–40 dB SPL |
| EFR RAM | Mod freq: 223 Hz; filter [60–4000 Hz]; up to 16th harmonic; window 0.2–0.9 s |
| EFR dAM | Carrier: 4 kHz; AM sweep 4–10.5 Hz over 1.5 s; demod filter [10–1500 Hz] |
| DPOAE | Window: 0.25 s; 512 FFT pts; f1/f2 = 1.2; log-spaced frequencies |
| MEMR | Frequency range: 0.2–8 kHz; metric: Δ absorbed power (dB) vs. elicitor level |
