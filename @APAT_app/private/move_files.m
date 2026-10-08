function move_files(Chins2Run, Conds2Run, ChinIND, CondIND, sourcepath, EXPname, DATAdir, CODEdir)
%MOVE_FILES  Copy RAW session files into the organised subject/measure/condition tree.
%
%   Source: sourcepath/<session_folder>
%   Target: DATAdir/<AnimalID>/<EXPname>/<Condition>/
%
%   Auto-selects when exactly one matching folder exists.
%   Prompts with listdlg only when multiple candidates are found.

animalID  = Chins2Run{ChinIND};
condLabel = Conds2Run{CondIND};           % e.g. 'pre/Baseline'
parts     = strsplit(condLabel, filesep);
condDisp  = parts{end};                   % e.g. 'Baseline'  (for display)
targetDir = fullfile(DATAdir, animalID, EXPname, condLabel);
numericID = regexprep(animalID, '^[Qq]', '');   % strip Q-prefix for broader match

fprintf('\n══ move_files: %s  |  %s  |  %s ══\n', animalID, EXPname, condDisp);

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
if numel(hits) == 1
    % Only one candidate — auto-select, no dialog needed
    sourceDir = fullfile(sourcepath, hits(1).name);
    fprintf('  Source (auto): %s\n', hits(1).name);
else
    % Multiple candidates — ask user to choose
    names = {hits.name};
    fprintf('  Multiple session folders found for %s — showing selection dialog.\n', animalID);
    [sel, tf] = listdlg( ...
        'PromptString', sprintf('Select folder for  %s  [%s — %s]:', animalID, EXPname, condDisp), ...
        'SelectionMode', 'single', ...
        'ListString',    names, ...
        'ListSize',      [520 160]);
    if ~tf
        fprintf('  [SKIP] No folder selected — skipping.\n');
        cd(CODEdir);
        return
    end
    sourceDir = fullfile(sourcepath, names{sel});
    fprintf('  Source (selected): %s\n', names{sel});
end

% ── Collect data files (measure-specific, no subdirectories) ─────────────
if strcmp(EXPname, 'EFR')
    datafiles = dir(fullfile(sourceDir, '*FFR*'));
else
    datafiles = dir(fullfile(sourceDir, ['*', EXPname, '*']));
end
datafiles = datafiles(~[datafiles.isdir]);

% ── Collect calibration files (p*calib*, coef*calib*, etc.) ──────────────
calibfiles = dir(fullfile(sourceDir, '*calib*'));
calibfiles = calibfiles(~[calibfiles.isdir]);

if isempty(datafiles)
    fprintf('  [SKIP] No *%s* files found in:\n    %s\n', EXPname, sourceDir);
    cd(CODEdir);
    return
end

% ── Create target directory if needed ────────────────────────────────────
if ~isfolder(targetDir)
    mkdir(targetDir);
end

fprintf('  Target: %s\n', targetDir);
fprintf('  Copying %d data + %d calib files...\n', numel(datafiles), numel(calibfiles));

% Copy calibration files
for k = 1 : numel(calibfiles)
    copyfile(fullfile(sourceDir, calibfiles(k).name), ...
             fullfile(targetDir, calibfiles(k).name));
end

% Copy data files
for k = 1 : numel(datafiles)
    copyfile(fullfile(sourceDir, datafiles(k).name), ...
             fullfile(targetDir, datafiles(k).name));
    fprintf('    %s\n', datafiles(k).name);
end

% ── Verify ────────────────────────────────────────────────────────────────
copied = dir(fullfile(targetDir, '*.mat'));
fprintf('  Done: %d .mat files now in target.\n', numel(copied));

cd(CODEdir);
end
