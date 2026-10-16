function move_files(Chins2Run, Conds2Run, ChinIND, CondIND, sourcepath, EXPname, DATAdir, CODEdir)
%MOVE_FILES  Retrieve missing RAW session files into the subject/measure/condition tree.
%
%   Source: sourcepath/<session_folder>          (RAW, straight from NEL)
%   Target: DATAdir/<AnimalID>/<EXPname>/<Condition>/
%
%   Called for every rostered subject/condition before analysis. Returns
%   silently when the target already holds everything the analysis needs:
%     • the measure's data files      (*<EXPname>*, or *FFR* for EFR)
%     • the measure's calibration     MEMR/OAE: *calib_FPL_raw*.mat (FPL)
%                                     EFR     : *calib*.m
%   Otherwise the missing files are copied from the RAW session, together
%   with all of that session's *calib* files. Existing files are never
%   overwritten, so folders filled by older versions (which did not copy
%   the calibration for MEMR) are completed on the next run.
%
%   Session selection:
%     • target already has data → the RAW session holding the same files
%       (same names and byte sizes); no dialog.
%     • target empty → auto-select when exactly one session matches the
%       animal ID, a list only when several do (apat_timed_choice: no
%       answer within 30 s during a run → skipped, logged).
%   Anything that cannot be retrieved is reported and left missing (the
%   analysis then shows no data / no calibration as before).

animalID  = Chins2Run{ChinIND};
condLabel = Conds2Run{CondIND};           % e.g. 'pre/Baseline'
parts     = strsplit(condLabel, filesep);
condDisp  = parts{end};                   % e.g. 'Baseline'  (for display)
targetDir = fullfile(DATAdir, animalID, EXPname, condLabel);
numericID = regexprep(animalID, '^[Qq]', '');   % strip Q-prefix for broader match
numericID = regexprep(numericID, '-\d+$', '');  % Q460-2 → 460

% ── Required files for this measure ──────────────────────────────────────
if strcmp(EXPname, 'EFR')
    dataPattern = '*FFR*';
else
    dataPattern = ['*', EXPname, '*'];
end
switch EXPname
    case {'MEMR', 'OAE'}, calibPattern = '*calib_FPL_raw*.mat';
    case 'EFR',           calibPattern = '*calib*.m';
    otherwise,            calibPattern = '';
end

have      = list_files(targetDir, dataPattern);
haveData  = ~isempty(have);
haveCalib = isempty(calibPattern) || ~isempty(list_files(targetDir, calibPattern));
if haveData && haveCalib
    cd(CODEdir);
    return                                % nothing missing
end

fprintf('\n══ move_files: %s  |  %s  |  %s ══\n', animalID, EXPname, condDisp);
if ~haveData
    fprintf('  Missing: %s data files\n', EXPname);
else
    fprintf('  Missing: calibration (%s)\n', calibPattern);
end

% ── Guard: source root must exist ────────────────────────────────────────
if ~isfolder(sourcepath)
    fprintf('  [SKIP] RAW source folder not found:\n    %s\n', sourcepath);
    cd(CODEdir);
    return
end

% ── Find candidate session directories ───────────────────────────────────
hits = dir(fullfile(sourcepath, ['*', numericID, '*']));
hits = hits([hits.isdir] & ~startsWith({hits.name}, '.'));

if isempty(hits)
    fprintf('  [SKIP] No directories matching *%s* in RAW folder:\n    %s\n', ...
            numericID, sourcepath);
    fprintf('  Contents of RAW:\n');
    all_raw = dir(sourcepath);
    all_raw = all_raw([all_raw.isdir] & ~startsWith({all_raw.name}, '.'));
    for k = 1 : numel(all_raw)
        fprintf('    %s\n', all_raw(k).name);
    end
    cd(CODEdir);
    return
end

% ── Select source folder ──────────────────────────────────────────────────
if haveData
    % Data already here — use the session these exact files came from
    match = {};
    for s = 1 : numel(hits)
        sdir = fullfile(sourcepath, hits(s).name);
        ok   = true;
        for k = 1 : numel(have)
            f = dir(fullfile(sdir, have(k).name));
            if isempty(f) || f(1).bytes ~= have(k).bytes, ok = false; break; end
        end
        if ok, match{end+1} = sdir; end %#ok<AGROW>
    end
    if numel(match) ~= 1
        fprintf(['  [SKIP] %d RAW sessions contain the data already in the target — ' ...
                 'calibration not retrieved:\n    %s\n'], numel(match), targetDir);
        cd(CODEdir);
        return
    end
    sourceDir = match{1};
    [~, sname] = fileparts(sourceDir);
    fprintf('  Source (matched to existing data): %s\n', sname);
elseif numel(hits) == 1
    % Only one candidate — auto-select, no dialog needed
    sourceDir = fullfile(sourcepath, hits(1).name);
    fprintf('  Source (auto): %s\n', hits(1).name);
else
    % Multiple candidates — ask user to choose (no answer in 30 s during
    % a run: skip this pair, logged — apat_timed_choice / apat_run_error)
    names = {hits.name};
    fprintf('  Multiple session folders found for %s — showing selection dialog.\n', animalID);
    pre = find(contains(lower(names), lower(condDisp)), 1);
    if isempty(pre), pre = 1; end
    [sel, timed_out] = apat_timed_choice('Select RAW Session', ...
        sprintf('Select the RAW folder for  %s  [%s — %s]:', animalID, EXPname, condDisp), ...
        names, pre, [], 'skip this subject / condition');
    if timed_out
        try, apat_run_error('auto', sprintf(['%s %s %s: several RAW sessions (%s) and no answer — ' ...
            'skipped, nothing copied.'], animalID, EXPname, condDisp, strjoin(names, ', '))); catch, end
    end
    if sel == 0
        fprintf('  [SKIP] No folder selected — skipping.\n');
        cd(CODEdir);
        return
    end
    sourceDir = fullfile(sourcepath, names{sel});
    fprintf('  Source (selected): %s\n', names{sel});
end

% ── Collect data + calibration files (p*calib*, coef*calib*, etc.) ───────
datafiles  = list_files(sourceDir, dataPattern);
calibfiles = list_files(sourceDir, '*calib*');

if isempty(datafiles)
    fprintf('  [SKIP] No %s files found in:\n    %s\n', dataPattern, sourceDir);
    cd(CODEdir);
    return
end

% ── Create target directory if needed ────────────────────────────────────
if ~isfolder(targetDir)
    mkdir(targetDir);
end
fprintf('  Target: %s\n', targetDir);

% ── Copy whatever is missing (never overwrite) ───────────────────────────
nCalib = copy_missing(calibfiles, sourceDir, targetDir);
nData  = copy_missing(datafiles,  sourceDir, targetDir);
fprintf('  Copied %d data + %d calib files.\n', nData, nCalib);

% ── Verify ────────────────────────────────────────────────────────────────
if ~isempty(calibPattern) && isempty(list_files(targetDir, calibPattern))
    fprintf('  [WARN] No %s in the RAW session — %s analysed without calibration.\n', ...
            calibPattern, EXPname);
end

cd(CODEdir);
end

% ─────────────────────────────────────────────────────────────────────────
function f = list_files(folder, pattern)
% Files (no directories) in FOLDER matching PATTERN; empty if folder missing.
if ~isfolder(folder), f = struct('name', {}, 'bytes', {}); return; end
f = dir(fullfile(folder, pattern));
f = f(~[f.isdir]);
end

function n = copy_missing(files, sourceDir, targetDir)
% Copy FILES from SOURCEDIR to TARGETDIR, skipping any already there.
n = 0;
for k = 1 : numel(files)
    tgt = fullfile(targetDir, files(k).name);
    if ~isfile(tgt)
        copyfile(fullfile(sourceDir, files(k).name), tgt);
        fprintf('    %s\n', files(k).name);
        n = n + 1;
    end
end
end
