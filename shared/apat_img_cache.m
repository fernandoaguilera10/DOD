function out = apat_img_cache(action, varargin)
%APAT_IMG_CACHE  Skip work for individual (per-subject) Results views whose
%   saved images are already up to date, and build those views only when
%   they are opened.
%
%   Why: a re-run (after a crash, a Stop, or "Save & Update Average") used
%   to copy every subject's figures into the Results tab and export every
%   image again, even when nothing had changed. Most of a summary-only run
%   was spent there.
%
%   How: every individual image APAT exports is recorded in
%   Analysis/Settings/APAT_image_index.mat with a fingerprint of what it was made
%   from:
%     · the run settings that can change the picture (cfg without the run
%       plumbing, subjects, conditions and their colours / markers, axis
%       limits, Setup → Output plot defaults, Experiment …),
%     · the newest result file (*.mat) of the run's subjects for that
%       measure (Analysis/<Measure>/<Subj>/…) — new or re-analysed data
%       changes it,
%     · the newest code file (*.m) of the APAT code folder — any code
%       change makes every image count as out of date.
%   When a subject's individual figures all have up-to-date images, the
%   app does not embed or export them during the run: each figure is saved
%   to a temporary .fig file ("parked") and embedded the first time that
%   subject is opened in the Results tab (embed_results 'unpark',
%   navigate_results). Anything else is embedded and exported as before.
%   Averages are always rebuilt and exported.
%
%   Skipping is only allowed in an analysis where nothing is (re)analysed:
%   Reanalyze off, every selected subject × condition already has a result,
%   not blind; the first raw analysis of the run turns it off ('deny').
%   When images are not saved at all (Setup → Output, Save Images OFF) the
%   views are always parked (nothing to export).
%
%   apat_img_cache('begin', ctx)  analysis_run, before the subject loop:
%        ctx.file   index file (Analysis/Settings/APAT_image_index.mat)
%        ctx.key    analysis id ('EFR dAM|BLAST')
%        ctx.sig    uint8 fingerprint of the settings (getByteStreamFromArray)
%        ctx.stamp  newest result-file / code-file time (datenum)
%        ctx.allow  skipping allowed in this analysis
%   apat_img_cache('deny')        a raw analysis ran: no more skipping
%   tf = apat_img_cache('fresh', figs)
%        true when FIGS can be parked: none has an image to write, or (skipping
%        allowed) every image to write is recorded with this analysis'
%        fingerprint and its files exist
%   apat_img_cache('record', base, files)   exported: base (apat_save_path of
%        the source figure) → its PNG files (several when one figure gave
%        several views: _65dBSPL, _80dBSPL …)
%   apat_img_cache('flush')       write the index file (after 'record's)
%   apat_img_cache('end')         analysis_run cleanup: flush, forget ctx
%   d = apat_img_cache('park_dir')   folder of the parked .fig files
%   Never throws.
out = [];
try
    switch action
        case 'begin'
            ctx = varargin{1};
            setappdata(0, 'APAT_img_ctx', ctx);
            setappdata(0, 'APAT_img_index', load_index(ctx.file));
            setappdata(0, 'APAT_img_dirty', false);
        case 'deny'
            if isappdata(0, 'APAT_img_ctx')
                ctx = getappdata(0, 'APAT_img_ctx');  ctx.allow = false;
                setappdata(0, 'APAT_img_ctx', ctx);
            end
        case 'fresh'
            out = fresh(varargin{1});
        case 'record'
            record(varargin{1}, varargin{2});
        case 'flush'
            flush();
        case 'end'
            flush();
            for k = {'APAT_img_ctx','APAT_img_index','APAT_img_dirty'}
                if isappdata(0, k{1}), rmappdata(0, k{1}); end
            end
        case 'park_dir'
            out = park_dir();
    end
catch err
    if strcmp(action, 'fresh'), out = false; end
    warning('APAT:imgCache', 'Image cache (%s): %s', action, err.message);
end
end


% ── up-to-date check ──────────────────────────────────────────────────

function tf = fresh(figs)
tf = false;
if ~isappdata(0, 'APAT_img_ctx'), return; end
ctx = getappdata(0, 'APAT_img_ctx');
figs = figs(isgraphics(figs));
if isempty(figs), return; end
pend = arrayfun(@(f) isappdata(f, 'apat_save_pending') && ...
    isequal(getappdata(f, 'apat_save_pending'), true), figs);
if ~any(pend), tf = true; return; end           % nothing to export (Save Images OFF …)
if ~ctx.allow, return; end
I = getappdata(0, 'APAT_img_index');
ver = key_version(I, ctx);
if ver == 0, return; end                         % this fingerprint never exported
for f = reshape(figs(pend), 1, [])
    base = char(getappdata(f, 'apat_save_path'));
    k = find(strcmp(I.base, base), 1);
    if isempty(k), return; end
    e = I.entry(k);
    if ~strcmp(e.key, ctx.key) || e.ver ~= ver || e.stamp ~= ctx.stamp, return; end
    if isempty(e.files) || ~all(cellfun(@(x) exist(x, 'file') == 2, e.files)), return; end
end
tf = true;
end


function ver = key_version(I, ctx)
% version number of ctx.sig for ctx.key (0 = not recorded)
ver = 0;
k = find(strcmp(I.keys, ctx.key), 1);
if isempty(k), return; end
if isequal(I.sigs{k}, ctx.sig), ver = I.vers(k); end
end


% ── recording exports ─────────────────────────────────────────────────

function record(base, files)
if ~isappdata(0, 'APAT_img_ctx'), return; end
ctx = getappdata(0, 'APAT_img_ctx');
I = getappdata(0, 'APAT_img_index');
% current fingerprint of this analysis (a new one gets the next version, so
% images recorded with an older fingerprint no longer count)
k = find(strcmp(I.keys, ctx.key), 1);
if isempty(k)
    I.keys{end+1} = ctx.key;  I.sigs{end+1} = ctx.sig;  I.vers(end+1) = 1;  k = numel(I.keys);
elseif ~isequal(I.sigs{k}, ctx.sig)
    I.sigs{k} = ctx.sig;  I.vers(k) = I.vers(k) + 1;
end
e = struct('key', ctx.key, 'ver', I.vers(k), 'stamp', ctx.stamp, 'files', {cellstr(files)});
base = char(base);
j = find(strcmp(I.base, base), 1);
if isempty(j)
    I.base{end+1} = base;  I.entry(end+1) = e;
else
    I.entry(j) = e;
end
setappdata(0, 'APAT_img_index', I);
setappdata(0, 'APAT_img_dirty', true);
end


function flush()
if ~isappdata(0, 'APAT_img_ctx') || ~isappdata(0, 'APAT_img_dirty'), return; end
if ~isequal(getappdata(0, 'APAT_img_dirty'), true), return; end
ctx = getappdata(0, 'APAT_img_ctx');
idx = getappdata(0, 'APAT_img_index'); %#ok<NASGU>
d = fileparts(ctx.file);
if ~isempty(d) && ~exist(d, 'dir'), mkdir(d); end
tmp = [ctx.file(1:end-4) '_tmp.mat'];
save(tmp, 'idx');
movefile(tmp, ctx.file, 'f');                    % never a half-written index
setappdata(0, 'APAT_img_dirty', false);
end


function I = load_index(file)
I = struct('keys', {{}}, 'sigs', {{}}, 'vers', zeros(1,0), 'base', {{}}, ...
    'entry', struct('key',{}, 'ver',{}, 'stamp',{}, 'files',{}));
try
    if exist(file, 'file') == 2
        L = load(file, 'idx');
        if isfield(L, 'idx') && all(isfield(L.idx, fieldnames(I))), I = L.idx; end
    end
catch
end
end


% ── parked figures ────────────────────────────────────────────────────

function d = park_dir()
persistent swept
d = fullfile(tempdir, 'APAT_parked');
if ~exist(d, 'dir'), mkdir(d); end
if isempty(swept)                                % once per MATLAB session:
    swept = true;                                % leftovers of a crashed session
    try
        L = dir(fullfile(d, '*.fig'));
        old = L([L.datenum] < now - 1); %#ok<TNOW1>
        for k = 1:numel(old), delete(fullfile(d, old(k).name)); end
    catch
    end
end
end
