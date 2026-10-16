function save_view(app, mode, root_arg, figs_arg)
%SAVE_VIEW  Results "Save Image" / "Save As New": write the view on screen —
%   exactly as shown (Plot Settings toggles, conditions, axis limits, tracked
%   subject …) — as a PNG.
%
%   save_view(app, 'save')   overwrite the image auto-saved for this view
%                            (apat_save_fig path, kept on the view's
%                            container by embed_results>tag_save)
%   save_view(app, 'new')    same folder, next free name: <name>_2.png,
%                            <name>_3.png … (never overwrites)
%   save_view(app, 'sync')   enable the buttons when the view has plots
%   save_view(app, 'auto', root, figs)  auto-save after embedding (called by
%                            embed_results): every container in ROOT whose
%                            source figure (one of FIGS) has a deferred image
%                            (apat_save_fig: 'apat_save_pending') is exported
%                            with the same routine as Save Image, to its
%                            apat_save_path, at the Setup dpi (Save Images
%                            OFF: nothing). Several containers with the same
%                            path get a suffix from their level / condition
%                            label (_65dBSPL, _D7 …; the container's path is
%                            updated so Save Image overwrites that file).
%                            Hidden containers (other level / tab / Results
%                            tab not shown) are shown for the export and put
%                            back; if the export fails, the source figure is
%                            written instead. Never throws.
%
%   The view's container (one per source figure: the figure panel, the
%   level / scale / frequency panel or the tab on screen) is exported with
%   exportgraphics at the Setup → Output resolution, white background. The
%   Plot Settings strips (Tag apat_ctrl / apat_ctrl_slot) and the EFR Listen
%   bar (apat_under_ax) are hidden while exporting; the Results bar and the
%   buttons are outside the container. A view without a saved path (figures
%   from before apat_save_fig) asks for a file name once, starting in the
%   Analysis folder, and remembers it. Feedback: a short label under the
%   buttons (app.res.save_msg), hidden after 6 s — no blocking dialog.
if nargin < 2, mode = 'save'; end
if strcmp(mode, 'sync'), sync_btns(app); return; end
if strcmp(mode, 'auto')
    try, auto_save(app, root_arg, figs_arg); catch err
        warning('APAT:autoSave', 'Results images not saved: %s', err.message);
    end
    return
end
root = cur_root(app);
if isempty(root) || isempty(findall(root, 'Type','axes'))
    toast(app, 'Nothing to save in this view yet.');  return
end
T = targets(root);
if isempty(T), T = root; end
dpi = 300;
try, o = output_opts(app, 'get');  dpi = o.plot.dpi; catch, end

fig = app.UIFigure;
ptr = fig.Pointer;  fig.Pointer = 'watch';
restore = onCleanup(@() set_ptr(fig, ptr));
saved = {};  failed = {};
for t = T(:)'
    base = '';
    if isappdata(t, 'apat_save_path'), base = getappdata(t, 'apat_save_path'); end
    asked = false;
    if isempty(base)
        base = ask_file(app, root);
        if isempty(base), continue; end              % cancelled
        asked = true;
    end
    if ~asked, base = exp_overlay(app, 'file', base); end   % overlay shown: <name>_NOISE_BLAST
    if strcmp(mode, 'new') && ~asked, file = next_free(base); else, file = [base '.png']; end
    try
        d = fileparts(file);
        if ~isempty(d) && ~exist(d, 'dir'), mkdir(d); end
        export_one(root, t, file, dpi);
        saved{end+1} = file; %#ok<AGROW>
        if asked, setappdata(t, 'apat_save_path', base); end   % next Save Image overwrites it
    catch err
        failed{end+1} = sprintf('%s (%s)', file, err.message); %#ok<AGROW>
    end
end
clear restore
if ~isempty(saved)                                   % status strip: "SAVED hh:mm"
    try, app.res.last_save = now; catch, end %#ok<TNOW1>
    try, res_style('status', app); catch, end
end
if ~isempty(failed)
    toast(app, ['Could not save ' strjoin(failed, '; ')]);
elseif isempty(saved)
    toast(app, 'Not saved.');
elseif numel(saved) == 1
    toast(app, ['Saved ' short_name(saved{1}) '  ·  ' fileparts(saved{1})]);
else
    toast(app, sprintf('Saved %d images: %s', numel(saved), ...
        strjoin(cellfun(@short_name, saved, 'UniformOutput', false), ', ')));
end
end


% ── auto-save after embedding ───────────────────────────────────────────

function auto_save(app, root, figs)
if isempty(root) || ~isgraphics(root), return; end
figs = figs(isgraphics(figs));
pend = false(size(figs));
for i = 1:numel(figs)                                % deferred images of these figures
    pend(i) = isappdata(figs(i), 'apat_save_pending') && isequal(getappdata(figs(i), 'apat_save_pending'), true);
    if pend(i), setappdata(figs(i), 'apat_save_pending', false); end   % embedded: no DeleteFcn write
end
if ~any(pend), return; end
o = struct('save_images', true, 'dpi', 300);
try, o = apat_plot_defaults('opts'); catch, end
if ~o.save_images, return; end
src_p = figs(pend);
T = gobjects(0);  S = gobjects(0);
for c = findall(root, 'Type','uipanel')'
    if ~isappdata(c, 'apat_view_src') || ~isappdata(c, 'apat_save_path') || ~isappdata(c, 'apat_view_fig'), continue; end
    f = getappdata(c, 'apat_view_fig');
    if isempty(f) || ~isgraphics(f) || ~any(src_p == f), continue; end
    T(end+1) = c;  S(end+1) = f; %#ok<AGROW>
end
if isempty(T), return; end
T = flip(T);  S = flip(S);                           % creation order (findall lists newest first)
bases = arrayfun(@(t) char(getappdata(t, 'apat_save_path')), T, 'UniformOutput', false);
files = bases;
ub = unique(bases);
for bi = 1:numel(ub)
    b = ub(bi);
    k = find(strcmp(bases, b{1}));
    if numel(k) < 2, continue; end
    used = {};
    for j = k(:)'
        sfx = view_label(T(j), root);
        if isempty(sfx) || any(strcmp(used, sfx)), sfx = sprintf('%d', numel(used) + 1); end
        used{end+1} = sfx; %#ok<AGROW>
        files{j} = [b{1} '_' sfx];
        setappdata(T(j), 'apat_save_path', files{j});   % Save Image → same file
    end
end
fig = app.UIFigure;
for j = 1:numel(T)
    file = [files{j} '.png'];
    try
        d = fileparts(file);
        if ~isempty(d) && ~exist(d, 'dir'), mkdir(d); end
    catch
    end
    R = struct('h',{}, 'prop',{}, 'val',{});
    try
        R = reveal(T(j), root, fig);
        export_one(root, T(j), file, o.dpi);
    catch err
        try                                          % the source figure, as before
            exportgraphics(S(j), file, 'Resolution', o.dpi);
            fprintf('APAT: %s saved from its source figure (%s).\n', short_name(file), err.message);
        catch err2
            warning('APAT:autoSave', 'Could not save %s: %s', file, err2.message);
        end
    end
    put_back(R);
end
try, app.res.last_save = now; res_style('status', app); catch, end %#ok<TNOW1>
end

function R = reveal(t, root, fig)
%REVEAL  Make container T render: every hidden ancestor shown, tabs on the
%   path selected (up to the Results tab), and — only when something had to
%   be shown — visible sibling panels inside ROOT hidden so they do not
%   cover it. Returns what to put back (put_back).
R = struct('h',{}, 'prop',{}, 'val',{});
chain = gobjects(0);
h = t;
while ~isempty(h) && isgraphics(h) && h ~= fig
    chain(end+1) = h; %#ok<AGROW>
    h = h.Parent;
end
changed = false;
for h = chain
    p = h.Parent;
    if isa(h, 'matlab.ui.container.Tab')
        if ~isequal(p.SelectedTab, h)
            R(end+1) = struct('h',p, 'prop','SelectedTab', 'val',p.SelectedTab); %#ok<AGROW>
            p.SelectedTab = h;  changed = true;
        end
    elseif isprop(h, 'Visible') && strcmp(h.Visible, 'off')
        R(end+1) = struct('h',h, 'prop','Visible', 'val','off'); %#ok<AGROW>
        h.Visible = 'on';  changed = true;
    end
end
if ~changed, return; end
inside = true;
for h = chain                                        % t … root: hide covering siblings
    if ~inside, break; end
    if h == root, inside = false; continue; end
    p = h.Parent;
    if isa(h, 'matlab.ui.container.Tab'), continue; end
    for sb = p.Children(:)'
        if sb == h || ~isa(sb, 'matlab.ui.container.Panel') || ~strcmp(sb.Visible, 'on'), continue; end
        if startsWith(sb.Tag, 'apat_'), continue; end   % strips / Listen bar: export_one
        R(end+1) = struct('h',sb, 'prop','Visible', 'val','on'); %#ok<AGROW>
        sb.Visible = 'off';
    end
end
end

function put_back(R)
for i = numel(R):-1:1
    try, if isgraphics(R(i).h), R(i).h.(R(i).prop) = R(i).val; end, catch, end
end
end

function s = view_label(t, root)
%VIEW_LABEL  File suffix of a container: its Tag (level, frequency, scale,
%   condition label), else its Title, else the title of the tab it is in.
s = '';
h = t;
while isempty(s) && ~isempty(h) && isgraphics(h)
    if isprop(h, 'Tag') && ~isempty(h.Tag) && ~startsWith(h.Tag, 'apat_'), s = h.Tag;
    elseif isprop(h, 'Title') && ~isempty(h.Title), s = char(h.Title);
    end
    if h == root, break; end
    h = h.Parent;
end
s = regexprep(char(s), '[^\w\-]+', '');
end


% ── what to export ──────────────────────────────────────────────────────

function T = targets(root)
%TARGETS  Containers on screen that hold one source figure each (appdata
%   apat_view_src, set by embed_results>tag_save); innermost only.
T = gobjects(0);
C = findall(root, 'Type','uipanel');            % includes root (a uipanel)
for c = C(:)'
    if isappdata(c, 'apat_view_src') && on_screen(c, root), T(end+1) = c; end %#ok<AGROW>
end
if numel(T) < 2, return; end
keep = true(1, numel(T));
for i = 1:numel(T)
    for j = 1:numel(T)
        if i ~= j && is_ancestor(T(i), T(j)), keep(i) = false; end   % T(i) holds T(j)
    end
end
T = T(keep);
end

function tf = on_screen(h, root)
tf = true;
while ~isempty(h) && isvalid(h)
    if isprop(h, 'Visible') && strcmp(h.Visible, 'off'), tf = false; return; end
    p = h.Parent;
    if isa(h, 'matlab.ui.container.Tab') && ~isempty(p) && ~isequal(p.SelectedTab, h), tf = false; return; end
    if h == root, return; end
    h = p;
end
end

function tf = is_ancestor(a, b)
tf = false;
h = b.Parent;
while ~isempty(h) && isvalid(h) && ~isa(h, 'matlab.ui.Figure')
    if h == a, tf = true; return; end
    h = h.Parent;
end
end

function export_one(root, t, file, dpi)
% Plot Settings panel / Listen bar off while exporting, then back as they were
H = [findall(root, 'Type','uipanel', 'Tag','apat_ctrl'); ...
     findall(root, 'Type','uipanel', 'Tag','apat_ctrl_slot'); ...
     findall(root, 'Type','uipanel', 'Tag','apat_under_ax')];
H = H(arrayfun(@(h) strcmp(h.Visible, 'on'), H));
set(H, 'Visible','off');
back = onCleanup(@() set(H(isvalid(H)), 'Visible','on'));
drawnow;
exportgraphics(t, file, 'Resolution', dpi, 'BackgroundColor', 'white');
end


% ── file names ──────────────────────────────────────────────────────────

function file = next_free(base)
%NEXT_FREE  <base>.png when it does not exist yet, else <base>_2.png, _3 …
file = [base '.png'];
if ~exist(file, 'file'), return; end
n = 2;
while exist(sprintf('%s_%d.png', base, n), 'file'), n = n + 1; end
file = sprintf('%s_%d.png', base, n);
end

function base = ask_file(app, root)
%ASK_FILE  Save dialog for a view that has no saved image yet.
base = '';
start = '';
try
    r = strtrim(app.RootDirField.Value);
    if ~isempty(r), start = fullfile(r, 'Analysis'); end
    lbl = APAT_app.measure_tab_labels();  lbl = lbl{app.res.meas_idx};
    meas = strtok(lbl);                              % ABR, EFR, OAE, MEMR …
    subj = '';
    if app.res.mode == 1, subj = app.FigSubjDropdown.Value; end
    cand = {fullfile(start, meas, subj), fullfile(start, subj), fullfile(start, meas), start};
    if isempty(subj), cand = cand(3:end); end
    for k = 1:numel(cand)
        if ~isempty(cand{k}) && exist(cand{k}, 'dir'), start = cand{k}; break; end
    end
    if app.res.mode == 1, nm = [lbl '_' subj]; else, nm = [lbl '_Average']; end
catch
    nm = 'APAT_view';
end
nm = regexprep(nm, '[^\w\-]+', '_');
if isempty(start) || ~exist(start, 'dir'), start = pwd; end
[f, p] = uiputfile({'*.png','PNG image (*.png)'}, 'Save Image As', fullfile(start, [nm '.png']));
try, figure(app.UIFigure); catch, end
if isequal(f, 0), return; end
[~, n] = fileparts(f);
base = fullfile(p, n);
end

function s = short_name(file)
[~, n, e] = fileparts(file);  s = [n e];
end


% ── feedback / buttons ──────────────────────────────────────────────────

function toast(app, msg)
try
    L = app.res.save_msg;
    L.Text = msg;  L.Visible = 'on';
    try, L.Tooltip = msg; catch, end
    old = timerfind('Name','APAT_savemsg');
    if ~isempty(old), stop(old); delete(old); end
    t = timer('Name','APAT_savemsg', 'StartDelay',6, 'ExecutionMode','singleShot', ...
        'TimerFcn',@(tm,~) hide_toast(L, tm));
    start(t);
catch
end
end

function hide_toast(L, tm)
try, if isvalid(L), L.Visible = 'off'; end, catch, end
try, delete(tm); catch, end
end

function set_ptr(fig, ptr)
try, if isvalid(fig), fig.Pointer = ptr; end, catch, end
end

function sync_btns(app)
has = false;
try
    root = cur_root(app);
    has = ~isempty(root) && ~isempty(findall(root, 'Type','axes'));
catch
end
for f = {'save_btn','savenew_btn'}
    try
        if isfield(app.res, f{1}) && isvalid(app.res.(f{1}))
            if has, app.res.(f{1}).Enable = 'on'; else, app.res.(f{1}).Enable = 'off'; end
        end
    catch
    end
end
end

function root = cur_root(app)
% Results panel on screen (current subject's panel or the Average panel)
root = [];
try
    m = app.res.meas_idx;
    if app.res.mode == 1
        data = app.res.subj_data{m};
        si = shown_subject(app, data);
        if ~isempty(si) && isvalid(data.panels{si}), root = data.panels{si}; end
    elseif isvalid(app.res.panels{2,m})
        root = app.res.panels{2,m};
    end
catch
end
end
