function fmt = apat_export_fmt()
%APAT_EXPORT_FMT  Data export format chosen in Setup: 'mat', 'csv' or 'both'.
%   Set by RunButtonPushed>run_one as root appdata 'APAT_export_fmt'
%   (headless callers may set cfg.export_fmt; analysis_run copies it there).
%   'mat'  = MATLAB .mat files only (old behaviour).
%   'csv'  = tidy .csv files for other software; per-recording .mat files are
%            still written (APAT's own cache, needed to build averages / skip
%            re-analysis), group-average .mat files are not.
%   'both' = .mat and .csv everywhere.
fmt = 'mat';
try
    v = getappdata(0, 'APAT_export_fmt');
    if ischar(v) && any(strcmpi(v, {'mat','csv','both'})), fmt = lower(v); end
catch
end
end
