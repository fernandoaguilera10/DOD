function n = oae_trials(data, outfile)
%OAE_TRIALS  Number of trials an OAE result was computed from (for the
%   individual legends, "(n = 14 trials)").
%   Newer results store it (data.n_trials, written by DP/SF/TEanalysis).
%   For older results it is read once from the raw recording named in the
%   result file name (…_p0004_sweptDPOAE_… → Data/<subj>/OAE/<pre|post>/<cond>/
%   p0004_sweptDPOAE.mat) and appended to the result file, so the raw file is
%   only opened the first time. DPOAE / SFOAE: even number of trials (as the
%   analysis uses them, pairs for the noise floor); TEOAE: all trials.
%   Returns NaN when it cannot be found.
n = NaN;
if isstruct(data) && isfield(data, 'n_trials') && ~isempty(data.n_trials)
    n = double(data.n_trials(1));  return
end
if nargin < 2 || isempty(outfile) || ~exist(outfile, 'file'), return; end
try
    [outdir, nm] = fileparts(outfile);
    raw = regexp(nm, 'p\d{3,5}_(sweptDPOAE|sweptSFOAE|TEOAE)', 'match', 'once');
    if isempty(raw), return; end
    f = strrep(outdir, '\', '/');
    i = strfind(f, '/Analysis/');  if isempty(i), return; end
    i = i(end);  root = f(1:i-1);
    parts = strsplit(f(i+10:end), '/');               % OAE / subj / pre|post / cond
    if numel(parts) < 4, return; end
    rawfile = fullfile(root, 'Data', parts{2}, parts{1}, parts{3:end}, [raw '.mat']);
    if ~exist(rawfile, 'file'), return; end
    S = load(rawfile, 'x');
    switch lower(regexprep(raw, '^p\d+_', ''))
        case 'sweptdpoae', n = floor(size(S.x.sweptDPOAEData.stim.resp, 1) / 2) * 2;
        case 'sweptsfoae', n = floor(size(S.x.sweptSFOAEData.stim.ProbeBuffs, 1) / 2) * 2;
        case 'teoae',      n = size(S.x.TEOAEData.stim.resp, 1);
    end
    if isfinite(n)                                    % remember it in the result file
        data.n_trials = n;
        save(outfile, 'data', '-append');
    end
catch
    n = NaN;
end
end
