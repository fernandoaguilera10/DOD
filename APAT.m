% APAT  —  Auditory Physiology Analysis Tool
%
%   Double-click this file (or open it and press Run / F5) to start APAT.
%   Everything else (measure code, shared helpers, the app) is found from here.

apat_root = fileparts(mfilename('fullpath'));
addpath(apat_root, fullfile(apat_root, 'shared'));     % app class + shared helpers (measure folders are added per run)

% ── Friendly checks (warnings only — APAT still opens) ───────────────────
if ~exist('isMATLABReleaseOlderThan', 'file') || isMATLABReleaseOlderThan('R2023b')
    warning('APAT:release', ['APAT is written for MATLAB R2023b or newer (tested in R2025b); ' ...
        'this is %s. Some features may not work.'], version('-release'));
end
if ~(license('test', 'Signal_Toolbox') && exist('dtw', 'file'))
    warning('APAT:signal', ['Signal Processing Toolbox not found: ABR, EFR and OAE analyses ' ...
        '(filtering, resampling, ABR peak DTW) will not run. Summaries of results already in Analysis/ still work.']);
end
if ~(license('test', 'Curve_Fitting_Toolbox') && exist('fit', 'file'))
    warning('APAT:curvefit', ['Curve Fitting Toolbox not found: ABR Thresholds and MEMR ART ' ...
        '(sigmoid fits) will not run. Other measures are not affected.']);
end
if ~(license('test', 'Statistics_Toolbox') && exist('trimmean', 'file'))
    warning('APAT:stats', 'Statistics and Machine Learning Toolbox not found: the TEOAE analysis (trimmean) will not run.');
end
clear apat_root

APAT_app();
