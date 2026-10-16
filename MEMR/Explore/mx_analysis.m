function mx_analysis(ROOTdir, datapath, outpath, subject, condition)
%MX_ANALYSIS  Exploratory wideband MEMR metrics for one subject / condition.
%
%   mx_analysis(ROOTdir, datapath, outpath, subject, condition)
%
%   Reads the raw MEMR recording (pNNNN_memr.mat, x.MemrData.stim) and the
%   FPL calibration of the same session (pNNNN_calib_FPL_raw.mat), computes
%   every exploratory metric once (mx_metrics) and saves
%       <outpath>/<subject>_MX_<condition>_<pNNNN>.mat   (struct 'mx')
%   All MEMR sub-options except ART (Vector, Growth, Kinetics, Spectral,
%   Absorbance, Probe, Quality) read this one file, so it is computed only
%   the first time any of them runs (or with Re-analyze). The ART analysis
%   (WBMEMRanalysis) is not touched and its files are not read or changed.
%
%   Raw-file choice when a folder has several *memr*.mat files: the same as
%   ART (load_files → choose_recording, Setup → Options → Multiple recordings),
%   so both analyse the same recording.

if nargin < 5, condition = ''; end
d = dir(fullfile(datapath, '*memr*.mat'));
d = d(~strncmp({d.name}, '._', 2));
if isempty(d)
    fprintf('MEMR (explore): no raw MEMR file in %s\n', datapath);
    return
end
names = {d.name};
datafile = '';
if numel(names) > 1
    if isempty(datafile)
        try
            datafile = load_files(datapath, '*memr*.mat', 'data');
        catch
        end
        if iscell(datafile), datafile = datafile{1}; end
        if isempty(datafile), datafile = names{end}; end
    end
else
    datafile = names{1};
end
fprintf('MEMR (explore): %s %s — %s\n', subject, condition, datafile);
S = load(fullfile(datapath, datafile), 'x');
stim = S.x.MemrData.stim;
clear S

% FPL calibration (latest calib_FPL_raw recorded before the MEMR file)
calib = [];  calib_file = '';
pn = p_number(datafile);
c = dir(fullfile(datapath, '*calib_FPL_raw*.mat'));
c = c(~strncmp({c.name}, '._', 2));
if isempty(c)
    c = dir(fullfile(datapath, '*calib_FPL*.mat'));
    c = c(~strncmp({c.name}, '._', 2));
end
if ~isempty(c)
    % same rule as the OAE analyses: the calibration recorded closest before
    % the MEMR file (no setting; choose_recording kind 'calib')
    names_c = {c.name};  cf = names_c{1};
    if numel(names_c) > 1
        try
            cf = choose_recording(datapath, names_c, '*calib_FPL_raw*.mat', 'calib', datafile);
        catch
            cn = cellfun(@p_number, names_c);  ok = cn < pn;  if ~any(ok), ok = true(size(cn)); end
            cand = find(ok);  [~, j] = max(cn(cand));  cf = names_c{cand(j)};
        end
    end
    try
        C = load(fullfile(datapath, cf), 'x');
        if isfield(C, 'x') && isfield(C.x, 'FPLearData')
            calib = C.x.FPLearData;  calib_file = cf;
        end
    catch
    end
end

mx = mx_metrics(stim, calib);
mx.subject    = subject;
mx.sex        = apat_sex('get', subject);   % chinroster Sex column ('' if unknown)
mx.condition  = condition;
mx.datafile   = datafile;
mx.calib_file = calib_file;
mx.date       = datestr(now, 'yyyy-mm-dd HH:MM'); %#ok<TNOW1,DATST>

if ~exist(outpath, 'dir'), mkdir(outpath); end
[~, base] = fileparts(datafile);
tag = regexp(base, '^p\d+', 'match', 'once');  if isempty(tag), tag = base; end
fname = sprintf('%s_MX_%s_%s.mat', subject, condition, tag);
save(fullfile(outpath, fname), 'mx');
fprintf('MEMR (explore): saved %s\n', fname);
end


function n = p_number(name)
tok = regexp(name, 'p(\d+)', 'tokens', 'once');
n = inf;  if ~isempty(tok), n = str2double(tok{1}); end
end
