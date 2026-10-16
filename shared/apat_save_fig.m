function file = apat_save_fig(fh, file_noext, view_key)
%APAT_SAVE_FIG  The ONE place APAT decides a figure's image.
%   file = apat_save_fig(fh, file_noext, view_key)
%   apat_save_fig('flush', fh)   write a deferred image now (see below)
%
%   In the app (analysis_run sets root appdata 'APAT_embed_save'), figures
%   of Results views (keys *_ind, *_avg, abr_waterfall) are NOT written
%   here: the path is recorded (appdata 'apat_save_pending' = true) and
%   embed_results exports the embedded Results container instead (save_view
%   'auto' — same look as the Results tab, Plot Settings hidden). If such a
%   figure is deleted before it was embedded, its DeleteFcn writes it from
%   the figure as before. Headless runs (no embedding) and per-recording
%   images (*_rec) are written here directly.
%     fh         figure (usually invisible) as built by the plot code
%     file_noext full path without extension; folders are created
%     view_key   short id of the Results view, e.g. 'oae_ind','oae_avg',
%                'abr_thr_ind' — used by apat_plot_defaults to know which
%                plot defaults (sweeps, noise floor, subject points …) apply.
%   Applies the Setup plot defaults to fh (so the saved image and the
%   Results view start the same), writes <file_noext>.png, and remembers
%   the path on the figure (appdata 'apat_save_path' + 'apat_view_key') so
%   the Results "Save Image" button overwrites the same file.
%   Average views (keys *_avg, abr_waterfall) of a run with an Experiment
%   (root appdata 'APAT_experiment' = chinroster sheet) get the Experiment
%   in the name — <name>_<EXP>_figure (before a trailing _figure, else
%   appended) — because the averages of every Experiment share one
%   Average/ folder while each figure shows one Experiment's groups.
%   Returns the written file ('' if image saving is off or it failed).
%   Setup → Output: "Save Images" OFF skips the PNG (the path is still
%   remembered, so Results → Save Image can write it later); "Resolution"
%   150 / 300 dpi. Never throws.
file = '';
if ischar(fh) && strcmp(fh, 'flush')
    try, flush(file_noext); catch, end
    return
end
if nargin < 3 || ~ischar(view_key), view_key = ''; end
try
    if isempty(fh) || ~isgraphics(fh), return; end
    if isstring(file_noext), file_noext = char(file_noext); end
    if ~ischar(file_noext) || isempty(file_noext), return; end
    [d, n, e] = fileparts(file_noext);
    if any(strcmpi(e, {'.png','.jpg','.tif','.tiff','.pdf','.fig'})), file_noext = fullfile(d, n); end
catch
    return
end
file_noext = exp_name(file_noext, view_key);       % average views: <name>_<EXP>_figure
try, setappdata(fh, 'apat_save_path', file_noext); setappdata(fh, 'apat_view_key', view_key); catch, end
opts = struct('save_images', true, 'dpi', 300);
try, opts = apat_plot_defaults('opts'); catch, end
try, apat_plot_defaults('apply', fh, view_key, opts); catch, end
if ~opts.save_images, return; end
defer = false;
try
    defer = isappdata(0, 'APAT_embed_save') && isequal(getappdata(0, 'APAT_embed_save'), true) && ...
        ~isempty(regexp(view_key, '(_ind|_avg)$|^abr_waterfall$', 'once'));
catch
end
if defer                                           % written from Results after embedding
    try
        setappdata(fh, 'apat_save_pending', true);
        setappdata(fh, 'apat_save_dpi', opts.dpi);
        if isempty(fh.DeleteFcn), fh.DeleteFcn = @(h, ~) apat_save_fig('flush', h); end
    catch
    end
    file = [file_noext '.png'];
    return
end
try
    d = fileparts(file_noext);
    if ~isempty(d) && ~exist(d, 'dir'), mkdir(d); end
    file = [file_noext '.png'];
    exportgraphics(fh, file, 'Resolution', opts.dpi);
catch ME
    warning('APAT:saveFig', 'Could not save %s: %s', file_noext, ME.message);
    file = '';
end
end


function flush(fh)
%FLUSH  Write a deferred image from the figure itself (it was not embedded).
if isempty(fh) || ~isgraphics(fh) || ~isappdata(fh, 'apat_save_pending'), return; end
if ~isequal(getappdata(fh, 'apat_save_pending'), true), return; end
setappdata(fh, 'apat_save_pending', false);
base = getappdata(fh, 'apat_save_path');
dpi = 300;  if isappdata(fh, 'apat_save_dpi'), dpi = getappdata(fh, 'apat_save_dpi'); end
try
    d = fileparts(base);
    if ~isempty(d) && ~exist(d, 'dir'), mkdir(d); end
    exportgraphics(fh, [base '.png'], 'Resolution', dpi);
catch ME
    warning('APAT:saveFig', 'Could not save %s: %s', base, ME.message);
end
end


function f = exp_name(f, view_key)
% <dir>/<name>_figure → <dir>/<name>_<EXP>_figure for average views
try
    if isempty(regexp(view_key, '_avg$|^abr_waterfall$', 'once')), return; end
    ex = '';
    if isappdata(0, 'APAT_experiment'), ex = apat_out_dir('sanitize', getappdata(0, 'APAT_experiment')); end
    if isempty(ex), return; end
    f = char(f);                                   % (no fileparts: names may hold dots)
    if ~isempty(regexp(f, ['_' regexptranslate('escape', ex) '(_figure)?$'], 'once')), return; end   % already named
    if numel(f) > 7 && strcmp(f(end-6:end), '_figure')
        f = [f(1:end-7) '_' ex '_figure'];
    else
        f = [f '_' ex];
    end
catch
end
end
