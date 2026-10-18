function embed_results(app, mode, figs, label, varargin)
%EMBED_RESULTS  Route analysis figures into the Results tab panels.
%
%   embed_results(app, 'ind', figs, measure_label, subject)
%       Called by embed_fns.analysis — routes individual figures into a
%       per-subject sub-panel inside the measure's Individual panel.
%
%   embed_results(app, 'avg', figs, measure_label)
%       Called by embed_fns.average — places averaged figures into the
%       measure's Average panel.
%
%   embed_results(app, 'park_files', meas_idx, subject, files)
%       A subject's view from saved .fig files (private/res_load: saved
%       Results): parked, built when the subject is opened.
%
%   embed_results(app, 'unpark', meas_idx, subject)
%       Build a subject's Individual view that was parked during the run
%       (navigate_results, when the subject is opened).
%
%   Parked views (shared/apat_img_cache): when every image of a subject's
%   individual figures is already saved and up to date (or images are not
%   saved), 'ind' does not embed or export them: each figure is saved to a
%   temporary .fig ("parked", appdata 'apat_parked' on the subject panel)
%   and embedded the first time the subject is opened — same view, built
%   later. The temporary files go when the panel is deleted.

if ~isvalid(app), return; end
if strcmp(mode, 'unpark'), unpark(app, figs, label); return; end
if strcmp(mode, 'park_files'), park_files(app, figs, label, varargin{1}); return; end   % res_load
valid_figs = figs(arrayfun(@(f) isvalid(f) && ~isempty(findall(f,'Type','axes')), figs));
if isempty(valid_figs), return; end

meas_idx = find(strcmp(APAT_app.measure_tab_labels(), label), 1);
if isempty(meas_idx), return; end

switch mode
    case 'ind'
        if apat_img_cache('fresh', valid_figs) && park(app, valid_figs, meas_idx, varargin{1})
            return                                 % images up to date: built when opened
        end
        embed_individual(app, valid_figs, meas_idx, varargin{1});
    case 'avg',  embed_average(app, valid_figs, meas_idx);
end
end


% ── Individual embedding ──────────────────────────────────────────────

function embed_individual(app, figs, meas_idx, subject, ready)
% ready (optional): .fig files these figures came from (unpark) — kept so
% the view can be unloaded again without saving anything
if nargin < 5, ready = {}; end
sp = subj_panel(app, meas_idx, subject);
drop_parked(sp);                                 % (a parked view of an earlier pass)
delete(sp.Children);
t_ = tic;  embed_figs(app, figs, sp);  apat_timing('ind: embed_figs', toc(t_));

% Attach SelectionChangedFcn to any condition tabgroup (ABR Peaks) so
% the freq dropdown refreshes when the user switches condition tabs.
for ch = sp.Children(:)'
    if isa(ch,'matlab.ui.container.TabGroup')
        ch.SelectionChangedFcn = @(~,~) navigate_results(app, 'cond_tab', meas_idx, subject);
        break;
    end
end

% Show this subject, hide all others
for k = 1:numel(app.res.subj_data{meas_idx}.panels)
    if isvalid(app.res.subj_data{meas_idx}.panels{k})
        app.res.subj_data{meas_idx}.panels{k}.Visible = 'off';
    end
end
sp.Visible = 'on';

t_ = tic;  navigate_results(app, 'after_ind_embed', meas_idx, subject);  apat_timing('ind: navigate_results after_ind_embed', toc(t_));
if any(meas_idx == [3 4])                                      % EFR: level buttons, time window
    t_ = tic;  add_efr_time_ctrl(app, sp);  navigate_results(app, 'efr_level_sync');  apat_timing('ind: add_efr_time_ctrl', toc(t_));
end
if any(meas_idx == [5 6 7])                                    % OAE view controls
    t_ = tic;  add_oae_ctrl(app, sp, 'ind');  navigate_results(app, 'oae_scale');  apat_timing('ind: add_oae_ctrl', toc(t_));
end
if meas_idx == 8, add_memr_ind_ctrl(app, sp); end              % MEMR: conditions + response y-limits
if is_mx(meas_idx), add_mx_ctrl(app, sp, 'ind'); end           % MEMR exploratory views
t_ = tic;  subject_pick(app, 'wire');  apat_timing('ind: subject_pick wire', toc(t_));  % clickable subject points
t_ = tic;  cond_filter(app, 'apply');  apat_timing('ind: cond_filter apply', toc(t_));  % conditions switched off stay hidden
app.TabGroup.SelectedTab = app.ResultsTab;
t_ = tic;  plot_settings(app, 'stash', sp);  apat_timing('ind: plot_settings stash', toc(t_));  % controls → "Plot Settings" panel (hidden)
t_ = tic;  fit_layout(sp);  apat_timing('ind: fit_layout', toc(t_));  % margins: window edges, legends; plots use the full width
t_ = tic;  apply_shade(app, sp);  apat_timing('ind: apply_shade', toc(t_));  % Shading ON / OFF choice
t_ = tic;  plot_settings(app, 'sync');  apat_timing('ind: plot_settings sync', toc(t_));
t_ = tic;  drawnow;  apat_timing('ind: drawnow', toc(t_));
save_view(app, 'auto', sp, figs);                % images = these Results views (deferred by apat_save_fig)
% Keep the Results window light (Oct 18 2026: a full run kept ~340 subject
% views built — every step got slower and MATLAB crashed at the next
% Experiment): this view keeps its figures as .fig files, and every OTHER
% built subject view is unloaded to its files (parked: rebuilt when opened).
try
    if isempty(ready), ready = fig_files(figs); end
    setappdata(sp, 'apat_park_ready', ready);
    trim_views(app, sp);
catch err
    warning('APAT:trim', 'Results views not unloaded: %s', err.message);
end
end


function files = fig_files(figs)
%FIG_FILES  The figures as temporary .fig files (park dir): the bytes just
%   saved for the Results file (apat_res_store) when there are, else savefig.
files = {};
d = apat_img_cache('park_dir');
L = [];
if isappdata(0, 'APAT_res_last'), L = getappdata(0, 'APAT_res_last'); end
for k = 1:numel(figs)
    f = figs(k);
    if ~isgraphics(f), continue; end
    fn = [tempname(d) '.fig'];
    j = [];
    if isstruct(L) && ~isempty(L.figs), j = find(arrayfun(@(x) isgraphics(x) && x == f, L.figs), 1); end
    if ~isempty(j)
        fid = fopen(fn, 'w');
        if fid < 0, error('APAT:park', 'cannot write %s', fn); end
        fwrite(fid, L.blobs{j}, 'uint8');  fclose(fid);
    else
        pend = [];
        if isappdata(f, 'apat_save_pending'), pend = getappdata(f, 'apat_save_pending'); setappdata(f, 'apat_save_pending', false); end
        savefig(f, fn, 'compact');
        if ~isempty(pend), setappdata(f, 'apat_save_pending', pend); end
    end
    files{end+1} = fn; %#ok<AGROW>
end
end


function trim_views(app, keep)
%TRIM_VIEWS  Every built subject view except KEEP (all measures, every
%   Experiment) that has its .fig files is emptied and parked again.
sets = {app.res.subj_data};
try
    for e = 1:numel(app.res.exp_sets), sets{end+1} = app.res.exp_sets(e).subj_data; end %#ok<AGROW>
catch
end
for i = 1:numel(sets)
    sd = sets{i};
    for m = 1:numel(sd)
        if ~isstruct(sd{m}) || ~isfield(sd{m}, 'panels'), continue; end
        for k = 1:numel(sd{m}.panels)
            p = sd{m}.panels{k};
            if ~isvalid(p) || p == keep || ~isappdata(p, 'apat_park_ready') || isempty(p.Children), continue; end
            files = getappdata(p, 'apat_park_ready');
            rmappdata(p, 'apat_park_ready');
            delete(p.Children);
            setappdata(p, 'apat_parked', files);
        end
    end
end
end


function sp = subj_panel(app, meas_idx, subject)
%SUBJ_PANEL  The subject's panel in the measure's Individual view (created
%   hidden the first time).
data = app.res.subj_data{meas_idx};
si   = find(strcmp(data.names, subject), 1);
if isempty(si)
    si = numel(data.names) + 1;
    sp = uipanel(app.res.panels{1, meas_idx},'BorderType','none', ...
        'BackgroundColor',[1 1 1], ...
        'Units','normalized','Position',[0 0 1 1],'Visible','off');   % follows the card
    sp.DeleteFcn = @(h, ~) drop_parked(h);       % parked .fig files go with the panel
    data.names{si}  = subject;
    data.panels{si} = sp;
    app.res.subj_data{meas_idx} = data;
end
sp = app.res.subj_data{meas_idx}.panels{si};
end


% ── Parked individual views (images up to date: built when opened) ────

function ok = park(app, figs, meas_idx, subject)
%PARK  Keep a subject's individual figures as temporary .fig files instead
%   of embedding them now. Returns false (→ embedded now) if it fails.
ok = false;
t_ = tic;
files = {};
try
    d = apat_img_cache('park_dir');
    L = [];                                      % bytes just saved for the Results file (apat_res_store)
    if isappdata(0, 'APAT_res_last'), L = getappdata(0, 'APAT_res_last'); end
    for k = 1:numel(figs)
        f = figs(k);
        if isappdata(f, 'apat_save_pending'), setappdata(f, 'apat_save_pending', false); end   % image is up to date
        files{k} = [tempname(d) '.fig']; %#ok<AGROW>
        j = [];
        if isstruct(L) && ~isempty(L.figs), j = find(arrayfun(@(x) isgraphics(x) && x == f, L.figs), 1); end
        if ~isempty(j)                           % same figure, already as .fig bytes: write them
            fid = fopen(files{k}, 'w');
            if fid < 0, error('APAT:park', 'cannot write %s', files{k}); end
            fwrite(fid, L.blobs{j}, 'uint8');  fclose(fid);
        else
            savefig(f, files{k}, 'compact');
        end
    end
catch err
    warning('APAT:park', 'Individual view of %s built now (%s).', subject, err.message);
    for k = 1:numel(files), try, delete(files{k}); catch, end, end
    return
end
sp = subj_panel(app, meas_idx, subject);
drop_parked(sp);
delete(sp.Children);
setappdata(sp, 'apat_parked', files);
ok = true;
try                                              % subject list of the view on screen
    if app.res.meas_idx == meas_idx && app.res.mode == 1
        names = app.res.subj_data{meas_idx}.names(:)';
        v = app.FigSubjDropdown.Value;
        app.FigSubjDropdown.Items = names;
        if any(strcmp(names, v)), app.FigSubjDropdown.Value = v; else, app.FigSubjDropdown.Value = names{1}; end
    end
catch
end
apat_timing('ind: parked (image up to date)', toc(t_));
end


function park_files(app, meas_idx, subject, files)
%PARK_FILES  Parked view from existing .fig files (saved Results)
sp = subj_panel(app, meas_idx, subject);
drop_parked(sp);
delete(sp.Children);
setappdata(sp, 'apat_parked', files);
try
    if app.res.meas_idx == meas_idx && app.res.mode == 1
        names = app.res.subj_data{meas_idx}.names(:)';
        v = app.FigSubjDropdown.Value;
        app.FigSubjDropdown.Items = names;
        if any(strcmp(names, v)), app.FigSubjDropdown.Value = v; else, app.FigSubjDropdown.Value = names{1}; end
    end
catch
end
end


function unpark(app, meas_idx, subject)
%UNPARK  Embed a parked subject view (it is being opened).
data = app.res.subj_data{meas_idx};
si = find(strcmp(data.names, subject), 1);
if isempty(si) || ~isvalid(data.panels{si}) || ~isappdata(data.panels{si}, 'apat_parked'), return; end
sp = data.panels{si};
files = getappdata(sp, 'apat_parked');
rmappdata(sp, 'apat_parked');
figs = gobjects(0);
for k = 1:numel(files)
    try
        f = openfig(files{k}, 'invisible');
        figs(end+1) = f(1); %#ok<AGROW>
    catch err
        warning('APAT:park', 'Could not reopen part of %s''s view: %s', subject, err.message);
    end
end
try
    if isempty(figs)
        delete(sp.Children);
        make_placeholder(sp, 'View not available', ...
            'Run this analysis again to rebuild this subject''s view (its saved images are in Analysis).');
        for k = 1:numel(data.panels)
            if isvalid(data.panels{k}), data.panels{k}.Visible = 'off'; end
        end
        sp.Visible = 'on';
    else
        embed_individual(app, figs, meas_idx, subject, files);   % files stay: it can be unloaded again
        files = {};
    end
catch err
    warning('APAT:park', 'Individual view of %s: %s', subject, err.message);
end
delete(figs(isvalid(figs)));
for k = 1:numel(files), try, delete(files{k}); catch, end, end
end


function drop_parked(sp)
%DROP_PARKED  Delete the temporary .fig files of a parked view (or of a
%   built view that can be unloaded).
try
    if ~isvalid(sp), return; end
    for key = {'apat_parked', 'apat_park_ready'}
        if ~isappdata(sp, key{1}), continue; end
        files = getappdata(sp, key{1});
        rmappdata(sp, key{1});
        for k = 1:numel(files), try, delete(files{k}); catch, end, end
    end
catch
end
end


% ── Average embedding ─────────────────────────────────────────────────

function embed_average(app, figs, meas_idx)
panel = app.res.panels{2, meas_idx};
delete(panel.Children);
t_ = tic;  embed_figs(app, figs, panel);  apat_timing('avg: embed_figs', toc(t_));

% For ABR Peaks: merge freq labels into FigFreqDD so Average mode has them
if meas_idx == 2
    avg_names = arrayfun(@(f) get(f,'Name'), figs, 'UniformOutput', false);
    avg_freqs = {};
    for fi = 1:numel(avg_names)
        pts = strsplit(avg_names{fi}, '|');
        if numel(pts) >= 2 && ~isempty(pts{2})
            avg_freqs{end+1} = pts{2}; %#ok<AGROW>
        end
    end
    avg_freqs = unique(avg_freqs,'stable');
    if ~isempty(avg_freqs)              % Average mode lists frequencies only
        app.FigFreqDD.Items = avg_freqs;
        app.FigFreqDD.Value = avg_freqs{1};
    end
end

t_ = tic;  navigate_results(app, 'after_avg_embed', meas_idx);  apat_timing('avg: navigate_results after_avg_embed', toc(t_));
app.TabGroup.SelectedTab = app.ResultsTab;
drawnow;
t_ = tic;  navigate_results(app, 'filter_avg');  apat_timing('avg: navigate_results filter_avg', toc(t_));
if meas_idx == 2, add_abr_avg_toolbars(app, panel); end   % ABR Peaks view controls
if meas_idx == 1, add_thr_avg_ctrl(app, panel); end       % ABR Thresholds view controls
if meas_idx == 8                                           % MEMR view controls
    t_ = tic;  add_thr_avg_ctrl(app, panel, 'memr_avg_ax', 'memr_subj_pts', 'Y-Axis (dB)');  apat_timing('avg: add_thr_avg_ctrl', toc(t_));
end
if is_mx(meas_idx), add_mx_ctrl(app, panel, 'avg'); end    % MEMR exploratory views
if any(meas_idx == [3 4])                                      % EFR dAM / RAM view controls
    t_ = tic;  add_efr_avg_ctrl(app, panel);  navigate_results(app, 'efr_level_sync');  apat_timing('avg: add_efr_avg_ctrl', toc(t_));
end
if any(meas_idx == [5 6 7])                                    % OAE view controls
    t_ = tic;  add_oae_ctrl(app, panel, 'avg');  navigate_results(app, 'oae_scale');  apat_timing('avg: add_oae_ctrl', toc(t_));
end
t_ = tic;  subject_pick(app, 'wire');  apat_timing('avg: subject_pick wire', toc(t_));  % clickable subject points
t_ = tic;  cond_filter(app, 'apply');  apat_timing('avg: cond_filter apply', toc(t_));  % conditions switched off stay hidden
t_ = tic;  plot_settings(app, 'stash', panel);  apat_timing('avg: plot_settings stash', toc(t_));  % controls → "Plot Settings" panel (hidden)
t_ = tic;  fit_layout(panel);  apat_timing('avg: fit_layout', toc(t_));  % margins: window edges, legends; plots use the full width
t_ = tic;  apply_shade(app, panel);  apat_timing('avg: apply_shade', toc(t_));  % Shading ON / OFF choice
t_ = tic;  try, exclusions(app, 'mark', panel, meas_idx); catch, end;  apat_timing('avg: exclusions mark', toc(t_));  % ✕ = subject points excluded from the average
t_ = tic;  plot_settings(app, 'sync');  apat_timing('avg: plot_settings sync', toc(t_));
t_ = tic;  drawnow;  apat_timing('avg: drawnow', toc(t_));
save_view(app, 'auto', panel, figs);                       % images = these Results views (deferred by apat_save_fig)
end


% ── Figure embedding into a panel ────────────────────────────────────

function embed_figs(app, figs, parent)
%EMBED_FIGS  Copy axes from figs into parent panel.
%   Layout:
%     Category|Label names → categorized tab layout
%     Multiple named figs  → stacked panels (FigFreqDD controls which is visible)
%     Single fig           → full panel
%     Two figs             → side-by-side
%     3+ unnamed figs      → 2-column scrollable grid
PAD = 4;
pos = px_wh(parent);                 % pixel size (the cards / subject panels are normalized)
W   = pos(1);
VH  = pos(2);
n   = numel(figs);
fw  = W - 2*PAD;
fh  = VH - 2*PAD;
nrm = @(r) r ./ [W VH W VH];         % sub-panels in normalized units: they follow window resizes

% Widen the plots to the full width in the (hidden) figure BEFORE copying,
% so they appear full width at once (the right strip that used to hold the
% controls is free now — Plot Settings); fit_layout then only fine-tunes.
for f = figs(:)', prewiden(f); end

names       = arrayfun(@(f) get(f,'Name'), figs, 'UniformOutput', false);
has_category = any(cellfun(@(nm) ~isempty(nm) && contains(nm,'|'), names));
if has_category
    embed_categorized_tabs(app, figs, names, parent);
    return;
end
use_stacked = n > 1 && all(~cellfun(@isempty, names));

if use_stacked
    for i = 1:n
        vis   = ternary(i==1, 'on', 'off');
        sub_p = uipanel(parent,'Units','normalized','Position',nrm([PAD PAD fw fh]), ...
            'BackgroundColor','white','Visible',vis,'Title','','Tag',names{i},'FontSize',14);
        tag_save(sub_p, figs(i));
        h_copy  = [findall(figs(i),'Type','axes'); findall(figs(i),'Type','legend')];
        new_axs = copyobj(h_copy, sub_p);
        arrayfun(@(a) set(a,'Units','normalized'), new_axs);
    end
elseif n == 1
    ttl1 = names{1};  bt1 = 'line';
    if strcmp(get(figs(1),'Tag'),'APAT_thr_avg') || isempty(ttl1), ttl1 = ''; bt1 = 'none'; end
    sub_p   = uipanel(parent,'Units','normalized','Position',nrm([PAD PAD fw fh]), ...
        'BackgroundColor','white','Title',ttl1,'BorderType',bt1,'FontSize',14);
    tag_save(sub_p, figs(1));
    h_copy  = [findall(figs(1),'Type','axes'); findall(figs(1),'Type','legend')];
    new_axs = copyobj(h_copy, sub_p);
    arrayfun(@(a) set(a,'Units','normalized'), new_axs);
elseif n == 2
    fw2 = floor((W - 3*PAD) / 2);
    for i = 1:2
        x     = PAD + (i-1)*(fw2+PAD);
        sub_p = uipanel(parent,'Units','normalized','Position',nrm([x PAD fw2 fh]), ...
            'BackgroundColor','white','Title',names{i},'FontSize',14);
        tag_save(sub_p, figs(i));
        h_copy  = [findall(figs(i),'Type','axes'); findall(figs(i),'Type','legend')];
        new_axs = copyobj(h_copy, sub_p);
        arrayfun(@(a) set(a,'Units','normalized'), new_axs);
    end
else
    % 2-column scrollable grid for 3+ unnamed figs
    fw2     = floor((W - 3*PAD) / 2);
    n_rows  = ceil(n/2);
    total_h = n_rows*(fh+PAD)+PAD;
    scroll  = uipanel(parent,'Scrollable','on','BorderType','none', ...
        'BackgroundColor',[1 1 1],'Units','normalized','Position',[0 0 1 1]);
    for i = 1:n
        col   = mod(i-1,2);  row = floor((i-1)/2);
        x     = PAD + col*(fw2+PAD);
        y     = total_h - (row+1)*(fh+PAD);
        sub_p = uipanel(scroll,'Position',[x y fw2 fh], ...
            'BackgroundColor','white','Title',names{i},'FontSize',14);
        tag_save(sub_p, figs(i));
        h_copy  = [findall(figs(i),'Type','axes'); findall(figs(i),'Type','legend')];
        new_axs = copyobj(h_copy, sub_p);
        arrayfun(@(a) set(a,'Units','normalized'), new_axs);
    end
end
end


function prewiden(fig)
%PREWIDEN  In a figure about to be embedded: widen its plot axes (as one
%   group, left edge kept, ≤ 1.6×) so their outer box — tick labels and
%   y-labels included — reaches ~1.5 % from the right edge, or stops before a
%   value table (axes '*_table') on the right. Bottom legends are re-centred
%   under the widened plots. Same rule as fit_layout's widening, done before
%   the figure is shown so the view does not visibly jump.
try
    ax = findall(fig, 'Type','axes');
    if isempty(ax), return; end
    isT  = ~cellfun(@isempty, regexp({ax.Tag}, '_table$', 'once'));
    vis  = arrayfun(@(a) strcmp(a.Visible,'on'), ax);
    main = ax(vis & ~isT);   tabs = ax(isT);
    if isempty(main), return; end
    set(main, 'Units','normalized');
    P = cell2mat(arrayfun(@(a) a.Position, main(:), 'UniformOutput', false));
    TI = cell2mat(arrayfun(@(a) a.TightInset, main(:), 'UniformOutput', false));
    PL = min(P(:,1));  PR = max(P(:,1) + P(:,3));  PB = min(P(:,2));  PT = max(P(:,2) + P(:,4));
    OR = max(P(:,1) + P(:,3) + TI(:,3));
    inR = OR - PR;
    xr = 0.985;
    for t = tabs(:)'
        set(t, 'Units','normalized');  q = t.Position;
        if q(2) < PT && q(2) + q(4) > PB && q(1) >= PR - 0.002, xr = min(xr, q(1) - 0.012); end
    end
    if ~(xr - OR > 0.03) || PR <= PL, return; end
    sx = min(1.6, (xr - inR - PL) / (PR - PL));
    if sx <= 1.001, return; end
    for k = 1:numel(main)
        p = main(k).Position;
        main(k).Position = [PL + (p(1) - PL)*sx, p(2), p(3)*sx, p(4)];
    end
    % bottom legends (and their helper axes) re-centred under the plots
    cx = (PL + PL + (PR - PL)*sx) / 2;  cy = (PB + PT) / 2;
    for g = findall(fig, 'Type','legend')'
        set(g, 'Units','normalized');  q = g.Position;
        if q(2) + q(4)/2 < cy && (strcmp(g.Tag,'apat_legend') || isempty(g.Tag))
            g.Position = [cx - q(3)/2, q(2), q(3), q(4)];
        end
    end
catch
end
end


function tag_save(dst, src)
%TAG_SAVE  Remember on the Results container DST where its source figure SRC
%   was saved (apat_save_fig: appdata 'apat_save_path' without extension,
%   'apat_view_key'), so Results → Save Image / Save As New (save_view.m)
%   write the view on screen to that file. Figures saved without
%   apat_save_fig have no path (Save Image then asks for a file name).
%   In the app the auto-saved image is written from this container too,
%   right after embedding (save_view 'auto', end of embed_individual /
%   embed_average).
try
    if isappdata(src, 'apat_save_path')
        setappdata(dst, 'apat_save_path', getappdata(src, 'apat_save_path'));
        vk = '';  if isappdata(src, 'apat_view_key'), vk = getappdata(src, 'apat_view_key'); end
        setappdata(dst, 'apat_view_key', vk);
    end
    setappdata(dst, 'apat_view_src', true);      % one saved image = this container
    setappdata(dst, 'apat_view_fig', src);       % its source figure (save_view 'auto': which views to write, fallback)
catch
end
end


function v = pdef(app, field)
%PDEF  Setup → Output plot default (apat_plot_defaults field) of the last
%   run: the Plot Settings buttons start in this state, so the Results view
%   and the auto-saved image agree.
v = true;
try
    s = [];
    if isstruct(app.state) && isfield(app.state, 'plot_defaults'), s = app.state.plot_defaults; end
    o = apat_plot_defaults('opts', s);
    v = logical(o.(field));
catch
end
end


% ── Categorized tab layout ─────────────────────────────────────────────

function embed_categorized_tabs(app, figs, names, parent)
%EMBED_CATEGORIZED_TABS  Tab layout for 'Category|Label' named figures.
%   Each unique category gets one tab. Within the tab, stacked panels (one
%   per label) are toggled by FigFreqDD.
PAD = 4;

n           = numel(figs);
categories  = cell(1, n);
freq_labels = cell(1, n);
for i = 1:n
    parts = strsplit(names{i},'|');
    if numel(parts) >= 2
        categories{i}  = parts{1};
        freq_labels{i} = parts{2};
    else
        categories{i}  = 'Summary';
        freq_labels{i} = '';
    end
end

% EFR: every figure is 'Level|<lev> dB SPL' → no tabs; stacked panels (one
% per level) that the Level dropdown in the Results bar switches.
if all(strcmp(categories, 'Level'))
    labs = sort_level_labels(freq_labels);
    for li = 1:numel(labs)
        k = find(strcmp(freq_labels, labs{li}), 1);
        lp = uipanel(parent, 'Units','normalized', 'Position',[0 0 1 1], 'Tag',labs{li}, ...
            'BorderType','none', 'BackgroundColor','white', ...
            'Visible',ternary(li == numel(labs), 'on', 'off'));
        tag_save(lp, figs(k));
        h_copy  = [findall(figs(k),'Type','axes'); findall(figs(k),'Type','legend')];
        new_axs = copyobj(h_copy, lp);
        arrayfun(@(a) set(a,'Units','normalized'), new_axs);
    end
    return;
end

% OAE: every figure is 'Scale|<EPL | SPL | EPL + SPL>' → no tabs; stacked
% panels (one per view) that the Scale dropdown in the Results bar switches.
if all(strcmp(categories, 'Scale'))
    order = {'EPL','SPL','EPL + SPL'};
    labs  = order(ismember(order, freq_labels));
    for li = 1:numel(labs)
        k = find(strcmp(freq_labels, labs{li}), 1);
        lp = uipanel(parent, 'Units','normalized', 'Position',[0 0 1 1], 'Tag',labs{li}, ...
            'BorderType','none', 'BackgroundColor','white', ...
            'Visible',ternary(li == 1, 'on', 'off'));
        tag_save(lp, figs(k));
        h_copy  = [findall(figs(k),'Type','axes'); findall(figs(k),'Type','legend')];
        new_axs = copyobj(h_copy, lp);
        arrayfun(@(a) set(a,'Units','normalized'), new_axs);
    end
    return;
end

cat_order   = {'Waveforms','Amplitudes','Latencies', ...
               'ABR Waveforms','Sigmoid Fits'};
unique_cats = unique(categories,'stable');
present     = cat_order(ismember(cat_order, unique_cats));
others      = unique_cats(~ismember(unique_cats, [cat_order, {'Summary'}]));
others      = sort_freq_tabs(others);          % Click, then ascending frequency
has_summary = ismember('Summary', unique_cats);
ordered_cats = [present, others, ternary(has_summary, {'Summary'}, {})];

tg = uitabgroup(parent,'Units','normalized','Position',[0 0 1 1]);

for ci = 1:numel(ordered_cats)
    cat      = ordered_cats{ci};
    cat_mask = strcmp(categories, cat);
    cat_figs = figs(cat_mask);
    cat_freq = freq_labels(cat_mask);

    tab       = uitab(tg,'Title',cat);
    tab_panel = uipanel(tab,'Units','normalized','Position',[0 0 1 1], ...
        'BorderType','none','BackgroundColor','white');

    if strcmp(cat,'Summary') || all(strcmp(cat_freq, '*'))   % '*' = one view, no dropdown
        for k = 1:numel(cat_figs)
            if k == 1, tag_save(tab_panel, cat_figs(k)); end      % one image per tab: the first figure's file
            h_copy  = [findall(cat_figs(k),'Type','axes'); findall(cat_figs(k),'Type','legend')];
            new_axs = copyobj(h_copy, tab_panel);
            arrayfun(@(a) set(a,'Units','normalized'), new_axs);
        end
        continue;
    end

    unique_freqs = sort_tab_labels(unique(cat_freq,'stable'));
    for fi = 1:numel(unique_freqs)
        fq      = unique_freqs{fi};
        fq_mask = strcmp(cat_freq, fq);
        fq_figs = cat_figs(fq_mask);
        vis     = ternary(fi==1, 'on', 'off');

        freq_p = uipanel(tab_panel,'Title','','Tag',fq,'FontSize',14, ...
            'Visible',vis,'BackgroundColor','white', ...
            'Units','normalized','Position',[0 0 1 1]);

        nf = numel(fq_figs);
        if nf == 1
            tag_save(freq_p, fq_figs(1));
            h_copy  = [findall(fq_figs(1),'Type','axes'); findall(fq_figs(1),'Type','legend')];
            new_axs = copyobj(h_copy, freq_p);
            arrayfun(@(a) set(a,'Units','normalized'), new_axs);
        else
            nc = 2;  nr = ceil(nf/nc);
            for k = 1:nf
                r = floor((k-1)/nc);  c = mod(k-1,nc);
                inner_p = uipanel(freq_p,'Units','normalized', ...
                    'Position',[c/nc, 1-(r+1)/nr, 1/nc, 1/nr], ...
                    'BackgroundColor','white','BorderType','none');
                tag_save(inner_p, fq_figs(k));
                h_copy  = [findall(fq_figs(k),'Type','axes'); findall(fq_figs(k),'Type','legend')];
                new_axs = copyobj(h_copy, inner_p);
                arrayfun(@(a) set(a,'Units','normalized'), new_axs);
            end
        end
    end
end
end


% ══════════════════════════════════════════════════════════════════════════
%  ABR Peaks — Average view controls, styled like the plots (white, plain
%  text) and placed in empty space: Waveforms → under the legend;
%  Amplitudes / Latencies → the empty 6th tile slot. Display only; saved
%  files are not changed.
% ══════════════════════════════════════════════════════════════════════════

function add_abr_avg_toolbars(app, panel)
tg = findobj(panel.Children, 'flat', 'Type','uitabgroup');
if isempty(tg), return; end
wh = px_wh(panel);
W = wh(1);
H = max(wh(2) - 30, 300);                       % tab content size (px)
for tab = tg(1).Children(:)'
    if isempty(tab.Children), continue; end
    tab_panel = tab.Children(end);               % content panel created by embed
    switch tab.Title
        case 'Waveforms'
            axs = findall(tab_panel, 'Type','axes', 'Tag','abr_waterfall');
            if isempty(axs), continue; end
            % Strip right of the plot, top-aligned with it (legends sit under the plot)
            set(axs, 'Units','normalized');
            P   = cell2mat(arrayfun(@(a) a.Position, axs(:), 'UniformOutput', false));
            rx  = max(P(:,1) + P(:,3)) + 0.03;  rw = max(0.12, 0.99 - rx);
            top = max(P(:,2) + P(:,4));  bot = min(P(:,2));
            cp = uipanel(tab, 'Units','normalized', 'Position',[rx bot rw max(0.2, top-bot)], ...
                'BorderType','none', 'BackgroundColor','white', 'Tag','apat_ctrl', 'Visible','off');   % hidden from the start (Plot Settings)
            [pw, ph] = px_size(cp);
            build_wf_ctrl(app, cp, axs, pw, ph);
        case {'Amplitudes','Latencies'}
            axs = findall(tab_panel, 'Type','axes', 'Tag','abr_wave_tile');
            if isempty(axs), continue; end
            for a = axs(:)', uistack(findall(a,'Tag','abr_n_lbl'), 'top'); end
            % Empty 6th slot: right-most column x-range, bottom row y-range
            P   = cell2mat(arrayfun(@(a) a.Position, axs(:), 'UniformOutput', false));
            one = axs(1).Parent;  P = P(arrayfun(@(a) a.Parent == one, axs(:)), :);
            x0  = max(P(:,1));  w0 = max(P(P(:,1) == x0, 3));
            y0  = min(P(:,2));  h0 = max(P(P(:,2) == y0, 4));
            slot_free = size(P,1) == 5;
            if ~slot_free                                 % fallback: bottom-right corner
                w0 = 230/W;  h0 = 230/H;  x0 = 1 - w0 - 0.01;  y0 = 0.04;
            end
            cp = uipanel(tab, 'Units','normalized', 'Position',[x0 y0 w0 h0], ...
                'BorderType','none', 'BackgroundColor','white', 'Tag','apat_ctrl_slot', 'Visible','off');
            [pw, ph] = px_size(cp);
            build_peak_ctrl(app, cp, tab_panel, axs, pw, ph);
    end
end
end


function wh = px_wh(h)
%PX_WH  Pixel [width height] of a container: pixel units → its Position;
%   normalized → the parent's pixel size × its normalized size.
wh = [800 600];
try
    if isprop(h, 'Units') && strcmp(h.Units, 'normalized')
        pw = px_wh(h.Parent);
        wh = pw .* h.Position(3:4);
    else
        wh = h.Position(3:4);
    end
catch
end
wh = max(wh, [50 50]);
end


function [pw, ph] = px_size(cp)
%PX_SIZE  Actual pixel size of a (normalized) panel, after layout.
drawnow;
cp.Units = 'pixels';  p = cp.Position;  cp.Units = 'normalized';
pw = max(120, round(p(3)));  ph = max(120, round(p(4)));
end


function style_onoff(b)
%STYLE_ONOFF  Show / hide toggles (Subjects, Sweep, Noise Floor, Sample size,
%   Shading, Response SD): ON = green, OFF = red, white bold text
%   (Results theme, private/res_style.m).
if ~isvalid(b), return; end
res_style('onoff', b);
end


function style_toggle(~, b)
%STYLE_TOGGLE  Level / segmented choices: on = subtle yellow, dark bold
%   text; off = cream with grey text (private/res_style.m).
if ~isvalid(b), return; end
res_style('seg', b, logical(b.Value));
end


function h = ctl_label(parent, txt, pos)
h = uilabel(parent, 'Text',txt, 'FontSize',13, 'FontWeight','bold', ...
    'FontColor',[0.15 0.15 0.15], 'Position',pos);
end


function build_wf_ctrl(app, cp, axs, PW, PH)
%BUILD_WF_CTRL  Level toggles (2 columns, re-stacked) + time limits.
lev_all = [];
for ax = axs(:)'
    if isstruct(ax.UserData) && isfield(ax.UserData,'levels')
        lev_all = union(lev_all, ax.UserData.levels);
    end
end
lev_all = sort(lev_all, 'descend');
x = 4;  w = PW - 8;  y = PH - 24;
y = cond_filter(app, 'chips', cp, axs(1).Parent, x, y, w, 22, 10);
ctl_label(cp, 'Levels (dB SPL)', [x y w 20]);
gap = 4;  bw = floor((w - gap) / 2);  bh = 22;
y = y - bh - 4;
b_all  = uibutton(cp,'push','Text','All',  'FontSize',11,'BackgroundColor','white','Position',[x y bw bh]);
b_none = uibutton(cp,'push','Text','Clear','FontSize',11,'BackgroundColor','white','Position',[x+bw+gap y bw bh]);
chips = gobjects(1, numel(lev_all));
for k = 1:numel(lev_all)
    col = mod(k-1, 2);
    if col == 0, y = y - bh - gap; end
    chips(k) = uibutton(cp,'state','Text',sprintf('%g',lev_all(k)),'Value',true, ...
        'FontSize',12,'FontWeight','bold','UserData',lev_all(k), ...
        'Position',[x + col*(bw+gap) y bw bh]);
end
y = y - 34;
ctl_label(cp, 'Time (ms)', [x y w 20]);
y = y - 28;
fw = 46;                                          % fits 2–3 digits
t0 = uieditfield(cp,'numeric','Value',0,'Limits',[0 50],'FontSize',12,'Position',[x y fw 24]);
uilabel(cp,'Text','–','FontSize',13,'HorizontalAlignment','center','Position',[x+fw y 14 24]);
t1 = uieditfield(cp,'numeric','Value',20,'Limits',[0.5 50],'FontSize',12,'Position',[x+fw+14 y fw 24]);
y = y - 34;
ctl_label(cp, 'Subjects', [x y w 20]);
y = y - 28;
sbtn = uibutton(cp,'state','Text','OFF','Value',pdef(app,'subj_pts'),'FontSize',12,'FontWeight','bold', ...
    'Position',[x y 2*fw+14 24]);
upd = @(~,~) wf_update(app, axs, chips, t0, t1, sbtn);
set(chips, 'ValueChangedFcn', upd);
t0.ValueChangedFcn = upd;  t1.ValueChangedFcn = upd;  sbtn.ValueChangedFcn = upd;
b_all.ButtonPushedFcn  = @(~,~) set_all_chips(chips, true,  upd);
b_none.ButtonPushedFcn = @(~,~) set_all_chips(chips, false, upd);
wf_update(app, axs, chips, t0, t1, sbtn);
end


function set_all_chips(chips, val, upd)
%SET_ALL_CHIPS  Check all / clear all level toggles, then redraw.
set(chips, 'Value', val);
upd([], []);
end


function wf_update(app, axs, chips, t0, t1, sbtn)
%WF_UPDATE  Show only the selected levels (re-stacked without gaps) and apply
%   the time limits to every waterfall (one per frequency).
sel = [];
if any([chips.Value]), sel = arrayfun(@(c) c.UserData, chips([chips.Value])); end
for c = chips(:)', style_toggle(app, c); end
show_subj = false;
if nargin >= 6 && ~isempty(sbtn) && isvalid(sbtn)
    style_onoff(sbtn);
    show_subj = sbtn.Value;
end
a = t0.Value;  b = t1.Value;
if b <= a, b = a + 0.5; t1.Value = b; end
for ax = axs(:)'
    ud = ax.UserData;
    if ~isstruct(ud) || ~isfield(ud,'levels'), continue; end
    vis = ismember(ud.levels, sel);
    sb_h = [findall(ax,'Tag','abr_wf_sb'); findall(ax,'Tag','abr_wf_sbT')];
    if ~any(vis)                                   % "Clear": hide every level
        for h = findall(ax)'
            if h ~= ax && isnumeric(h.UserData) && isscalar(h.UserData), h.Visible = 'off'; end
        end
        set(sb_h, 'Visible','off');
        ax.YTick = [];  ax.XLim = [a b];
        continue;
    end
    set(sb_h, 'Visible','on');
    new_off = nan(size(ud.cur));
    new_off(vis) = -(0:nnz(vis)-1) * ud.vsp;
    % findall (not Children): traces/markers have HandleVisibility 'off'
    for h = findall(ax)'
        if h == ax, continue; end
        L = h.UserData;
        if ~(isnumeric(L) && isscalar(L) && L >= 1 && L <= numel(vis) && L == round(L)), continue; end
        if vis(L)
            d = new_off(L) - ud.cur(L);
            if d ~= 0 && isprop(h,'YData'), h.YData = h.YData + d; end
            if strcmp(h.Tag,'abr_subj_pts')
                h.Visible = ternary(show_subj, 'on', 'off');
            else
                h.Visible = 'on';
            end
        else
            h.Visible = 'off';
        end
    end
    ud.cur(vis) = new_off(vis);
    ax.UserData = ud;
    ax.YTick      = fliplr(new_off(vis));
    ax.YTickLabel = arrayfun(@(v) sprintf('%g',v), fliplr(ud.levels(vis)), 'UniformOutput',false);
    ax.YLim  = [min(new_off(vis)) - 0.8*ud.vsp, max(new_off(vis)) + 0.9*ud.vsp];
    ax.XLim  = [a b];
    y_b  = min(new_off(vis));                        % 1 µV bar: bottom visible level
    x_sb = b - 0.0125*(b - a);
    sb  = findall(ax,'Tag','abr_wf_sb');   sbT = findall(ax,'Tag','abr_wf_sbT');
    if ~isempty(sb),  set(sb, 'XData',[x_sb x_sb], 'YData',[y_b y_b+1]); end
    if ~isempty(sbT), set(sbT,'Position',[x_sb - 0.015*(b-a), y_b+0.5, 0]); end
end
cond_filter(app, 'refresh');
end

function build_peak_ctrl(app, cp, tab_panel, axs, PW, PH)
%BUILD_PEAK_CTRL  In the empty tile slot: sample-size toggle, one y-axis and
%   one x-axis range for all wave plots, and Auto.
yl = [inf -inf];  xl = [inf -inf];
for ax = axs(:)'
    setappdata(ax, 'ylim0', ax.YLim);  setappdata(ax, 'xlim0', ax.XLim);
    yl = [min(yl(1), ax.YLim(1)), max(yl(2), ax.YLim(2))];
    xl = [min(xl(1), ax.XLim(1)), max(xl(2), ax.XLim(2))];
end
% Compact block, top-aligned with the plots in this row
xl = [floor(xl(1)), ceil(xl(2))];
LW = 120;  fw = 52;  rh = 26;  gap = 10;          % label width, box width (2–3 digits)
w  = LW + 2*fw + 14;
x  = max(4, round((PW - w)/2));
y  = PH - rh - 4;
y  = cond_filter(app, 'chips', cp, tab_panel, x, y, w, rh, gap);

ctl_label(cp, 'Subjects', [x y LW rh]);
sbtn = uibutton(cp,'state','Text','OFF','Value',pdef(app,'subj_pts'),'FontSize',12,'FontWeight','bold', ...
    'Position',[x+LW y 2*fw+14 rh]);
y = y - rh - gap;
ctl_label(cp, 'Sample Size (n)', [x y LW rh]);
nbtn = uibutton(cp,'state','Text','ON','Value',pdef(app,'abr_n'),'FontSize',12,'FontWeight','bold', ...
    'Position',[x+LW y 2*fw+14 rh]);
y = y - rh - gap;
y = shade_row(app, cp, x, y, LW, 2*fw+14, rh, gap);
ctl_label(cp, 'Y-Axis', [x y LW rh]);
y0 = uieditfield(cp,'numeric','Value',round(yl(1),1),'FontSize',12,'Position',[x+LW y fw rh]);
uilabel(cp,'Text','–','FontSize',13,'HorizontalAlignment','center','Position',[x+LW+fw y 14 rh]);
y1 = uieditfield(cp,'numeric','Value',round(yl(2),1),'FontSize',12,'Position',[x+LW+fw+14 y fw rh]);
y = y - rh - gap;
ctl_label(cp, 'X-Axis (dB)', [x y LW rh]);
x0 = uieditfield(cp,'numeric','Value',xl(1),'FontSize',12,'Position',[x+LW y fw rh]);
uilabel(cp,'Text','–','FontSize',13,'HorizontalAlignment','center','Position',[x+LW+fw y 14 rh]);
x1 = uieditfield(cp,'numeric','Value',xl(2),'FontSize',12,'Position',[x+LW+fw+14 y fw rh]);
y = y - rh - gap;
auto = uibutton(cp,'push','Text','Reset Axes','FontSize',12,'BackgroundColor','white', ...
    'Position',[x+LW y 2*fw+14 rh]);

nbtn.ValueChangedFcn = @(~,~) style_n();
sbtn.ValueChangedFcn = @(~,~) style_s();
y0.ValueChangedFcn   = @(~,~) apply_lim();
y1.ValueChangedFcn   = @(~,~) apply_lim();
x0.ValueChangedFcn   = @(~,~) apply_lim();
x1.ValueChangedFcn   = @(~,~) apply_lim();
auto.ButtonPushedFcn = @(~,~) reset_lim();
style_n();
style_s();
apply_lim();                                     % same axes on every plot from the start

    function style_n()
        style_onoff(nbtn);
        set(findall(tab_panel,'Tag','abr_n_lbl'), 'Visible', ternary(nbtn.Value,'on','off'));
    end
    function style_s()
        style_onoff(sbtn);
        cond_filter(app, 'set_vis', findall(tab_panel,'Tag','abr_subj_pts'), ternary(sbtn.Value,'on','off'));
    end
    function apply_lim()
        if isfinite(y0.Value) && isfinite(y1.Value) && y1.Value > y0.Value
            set(axs, 'YLimMode','manual', 'YLim',[y0.Value y1.Value]);
        end
        if isfinite(x0.Value) && isfinite(x1.Value) && x1.Value > x0.Value
            set(axs, 'XLimMode','manual', 'XLim',[x0.Value x1.Value]);
        end
    end
    function reset_lim()
        y0.Value = round(yl(1),1);  y1.Value = round(yl(2),1);
        x0.Value = xl(1);           x1.Value = xl(2);
        apply_lim();
    end
end


function out = sort_freq_tabs(labs)
%SORT_FREQ_TABS  'Click' first, then frequency labels ascending ('500 Hz',
%   '1 kHz' ...); anything else keeps its order at the end.
if isempty(labs), out = labs; return; end
key = inf(1, numel(labs));
for k = 1:numel(labs)
    t = strtrim(labs{k});
    if strcmpi(t,'click'), key(k) = -1; continue; end
    tok = regexp(t, '^([\d\.]+)\s*(k?Hz)$', 'tokens', 'once', 'ignorecase');
    if ~isempty(tok)
        key(k) = str2double(tok{1}) * (1 + 999*strcmpi(tok{2},'kHz'));
    end
end
[~, si] = sort(key);                    % stable: non-frequency labels keep order
out = labs(si);
end


% ══════════════════════════════════════════════════════════════════════════
%  ABR Thresholds — Average view controls (right column, under the legend):
%  subject points and sample size Shown/Hidden, y-axis range, reset.
%  Display only; saved files are not changed.
% ══════════════════════════════════════════════════════════════════════════

function add_thr_avg_ctrl(app, panel, ax_tag, pts_tag, ylab)
%   Also used for MEMR (ax_tag 'memr_avg_ax', pts_tag 'memr_subj_pts').
if nargin < 3, ax_tag = 'abr_thr_avg'; end
if nargin < 4, pts_tag = 'thr_subj_pts'; end
if nargin < 5, ylab = 'Y-Axis (dB)'; end
ax = findall(panel, 'Type','axes', 'Tag',ax_tag);
if isempty(ax), return; end
ax = ax(1);  host = ax.Parent;
% Right of the plots (past their tick labels / y-labels), top-aligned with
% the plot (legend sits under the plot)
set(ax, 'Units','normalized');  ap = ax.Position;
x0 = outer_right(vis_axes(host)) + 0.025;
cp = uipanel(host, 'Units','normalized', 'Position',[x0 ap(2) max(0.15, 0.99-x0) ap(4)], ...
    'BorderType','none', 'BackgroundColor','white', 'Tag','apat_ctrl', 'Visible','off');   % hidden from the start (Plot Settings)
[PW, PH] = px_size(cp);
yl0 = ax.YLim;
LW = 120;  fw = 52;  rh = 26;  gap = 10;
w  = LW + 2*fw + 14;  x = max(4, round((PW - w)/2));  y = PH - rh - 4;
y  = cond_filter(app, 'chips', cp, host, x, y, w, rh, gap);

ctl_label(cp, 'Subjects', [x y LW rh]);
sbtn = uibutton(cp,'state','Text','ON','Value',pdef(app,'subj_pts'),'FontSize',12,'FontWeight','bold', ...
    'Position',[x+LW y 2*fw+14 rh]);
y = y - rh - gap;
y = shade_row(app, cp, x, y, LW, 2*fw+14, rh, gap);
ctl_label(cp, ylab, [x y LW rh]);
y0 = uieditfield(cp,'numeric','Value',round(yl0(1),1),'FontSize',12,'Position',[x+LW y fw rh]);
uilabel(cp,'Text','–','FontSize',13,'HorizontalAlignment','center','Position',[x+LW+fw y 14 rh]);
y1 = uieditfield(cp,'numeric','Value',round(yl0(2),1),'FontSize',12,'Position',[x+LW+fw+14 y fw rh]);
y = y - rh - gap;
rst = uibutton(cp,'push','Text','Reset Axes','FontSize',12,'BackgroundColor','white', ...
    'Position',[x+LW y 2*fw+14 rh]);
if strcmp(ax_tag, 'memr_avg_ax')                  % MEMR: Growth Response y-limits per condition
    memr_resp_rows(cp, host, x, y - rh - 2*gap, LW, fw, rh, gap, '', pdef(app,'resp_sd'));
end

sbtn.ValueChangedFcn = @(~,~) style_tog(sbtn, pts_tag);
y0.ValueChangedFcn   = @(~,~) apply_lim();
y1.ValueChangedFcn   = @(~,~) apply_lim();
rst.ButtonPushedFcn  = @(~,~) reset_lim();
style_tog(sbtn, pts_tag);

    function style_tog(b, tag)
        style_onoff(b);
        cond_filter(app, 'set_vis', findall(host,'Tag',tag), ternary(b.Value,'on','off'));
    end
    function apply_lim()
        if isfinite(y0.Value) && isfinite(y1.Value) && y1.Value > y0.Value
            set(ax, 'YLimMode','manual', 'YLim',[y0.Value y1.Value]);
        end
    end
    function reset_lim()
        y0.Value = round(yl0(1),1);  y1.Value = round(yl0(2),1);
        apply_lim();
    end
end


% ══════════════════════════════════════════════════════════════════════════
%  MEMR — Growth Response y-limits, one row per condition panel (the panels
%  have their own scales). Average: rows under the strip of add_thr_avg_ctrl;
%  Individual: own strip (Conditions buttons + these rows).
% ══════════════════════════════════════════════════════════════════════════

function add_memr_ind_ctrl(app, sp)
A = findall(sp, 'Type','axes', 'Tag','memr_resp_ax');
if isempty(A), return; end
host = A(1).Parent;
set(A, 'Units','normalized');
P  = cell2mat(arrayfun(@(a) a.Position, A(:), 'UniformOutput', false));
x0 = outer_right(vis_axes(host)) + 0.025;
y0 = min(P(:,2));  y1 = max(P(:,2) + P(:,4));
cp = uipanel(host, 'Units','normalized', 'Position',[x0 y0 max(0.15, 0.99-x0) y1-y0], ...
    'BorderType','none', 'BackgroundColor','white', 'Tag','apat_ctrl', 'Visible','off');   % hidden from the start (Plot Settings)
[PW, PH] = px_size(cp);
LW = 120;  fw = 52;  rh = 26;  gap = 10;
w  = LW + 2*fw + 14;  x = max(4, round((PW - w)/2));  y = PH - rh - 4;
y  = cond_filter(app, 'chips', cp, host, x, y, w, rh, gap);
y  = shade_row(app, cp, x, y, LW, 2*fw+14, rh, gap);
memr_resp_rows(cp, host, x, y - gap, LW, fw, rh, gap, '', pdef(app,'resp_sd'));
end

function y = memr_resp_rows(cp, host, x, y, LW, fw, rh, gap, ttl, sd_on)
if nargin < 9 || isempty(ttl), ttl = 'Growth Response Y (dB)'; end
if nargin < 10, sd_on = true; end                   % Response SD start state (Setup → Output)
A = findall(host, 'Type','axes', 'Tag','memr_resp_ax');
if isempty(A), return; end
k = arrayfun(@(a) resp_k(a), A);  [~, o] = sort(k);  A = A(o);
SD = findall(host, 'Tag','memr_resp_sd');
if ~isempty(SD)                                    % Average: mean ± SD bands ON / OFF
    ctl_label(cp, 'Response SD', [x y LW rh]);
    sdb = uibutton(cp, 'state', 'Text','ON', 'Value',sd_on, 'FontSize',12, 'FontWeight','bold', ...
        'Tooltip','Shaded mean ± SD across subjects for every level', ...
        'Position',[x+LW y 2*fw+14 rh]);
    sdb.ValueChangedFcn = @(~,~) sd_toggle(sdb, host);
    sd_toggle(sdb, host);                          % start as Setup → Output says
    y = y - rh - gap;
end
ctl_label(cp, ttl, [x y LW+2*fw+14 rh]);
y = y - rh - 4;
F = gobjects(numel(A), 2);  Y0 = zeros(numel(A), 2);
for i = 1:numel(A)
    a = A(i);  Y0(i,:) = a.YLim;
    nm = sprintf('Condition %d', i);  clr = [0.15 0.15 0.15];
    if isstruct(a.UserData) && isfield(a.UserData, 'memr_cond')
        nm = char(a.UserData.memr_cond);  clr = a.UserData.clr;
    end
    lb = uilabel(cp, 'Text',nm, 'FontSize',12, 'FontWeight','bold', 'Interpreter','none', ...
        'FontColor',clr * 0.85, 'Position',[x y LW rh]);  %#ok<NASGU>
    F(i,1) = uieditfield(cp, 'numeric', 'Value',round(a.YLim(1),2), 'FontSize',12, 'Position',[x+LW y fw rh]);
    uilabel(cp, 'Text','–', 'FontSize',13, 'HorizontalAlignment','center', 'Position',[x+LW+fw y 14 rh]);
    F(i,2) = uieditfield(cp, 'numeric', 'Value',round(a.YLim(2),2), 'FontSize',12, 'Position',[x+LW+fw+14 y fw rh]);
    F(i,1).ValueChangedFcn = @(~,~) resp_lim(a, F(i,1), F(i,2));
    F(i,2).ValueChangedFcn = @(~,~) resp_lim(a, F(i,1), F(i,2));
    y = y - rh - 6;
end
y = y - gap + 6;
uibutton(cp, 'push', 'Text','Reset Response Axes', 'FontSize',12, 'BackgroundColor','white', ...
    'Position',[x+LW-40 y 2*fw+54 rh], 'ButtonPushedFcn',@(~,~) resp_reset(A, F, Y0));
y = y - rh - gap;
end

% ══════════════════════════════════════════════════════════════════════════
%  MEMR exploratory views (Results labels 'MEMR Vector' … 'MEMR Quality',
%  MEMR/Explore/mx_summary): one strip right of the plots — Conditions,
%  Subjects (Average), Shading and, when the view has level-family panels
%  (Tag memr_resp_ax), their y-limits per condition (+ SD bands ON / OFF).
% ══════════════════════════════════════════════════════════════════════════

function tf = is_mx(meas_idx)
L = APAT_app.measure_tab_labels();
tf = meas_idx >= 1 && meas_idx <= numel(L) && strncmp(L{meas_idx}, 'MEMR ', 5);
end

function add_mx_ctrl(app, root, mode)
A = [findall(root, 'Type','axes', 'Tag','mx_ax'); findall(root, 'Type','axes', 'Tag','memr_resp_ax')];
if isempty(A), return; end
host = A(1).Parent;
set(A, 'Units','normalized');
P  = cell2mat(arrayfun(@(a) a.Position, A(:), 'UniformOutput', false));
x0 = outer_right(vis_axes(host)) + 0.025;
y0 = min(P(:,2));  y1 = max(P(:,2) + P(:,4));
cp = uipanel(host, 'Units','normalized', 'Position',[x0 y0 max(0.15, 0.99-x0) y1-y0], ...
    'BorderType','none', 'BackgroundColor','white', 'Tag','apat_ctrl', 'Visible','off');   % hidden from the start (Plot Settings)
[PW, PH] = px_size(cp);
LW = 120;  fw = 52;  rh = 26;  gap = 10;
w  = LW + 2*fw + 14;  x = max(4, round((PW - w)/2));  y = PH - rh - 4;
y  = cond_filter(app, 'chips', cp, host, x, y, w, rh, gap);
if strcmp(mode, 'avg') && ~isempty(findall(host, 'Tag','memr_subj_pts'))
    ctl_label(cp, 'Subjects', [x y LW rh]);
    sbtn = uibutton(cp, 'state', 'Text','ON', 'Value',pdef(app,'subj_pts'), 'FontSize',12, 'FontWeight','bold', ...
        'Position',[x+LW y 2*fw+14 rh]);
    sbtn.ValueChangedFcn = @(~,~) subj_tog(sbtn);
    subj_tog(sbtn);
    y = y - rh - gap;
end
y = shade_row(app, cp, x, y, LW, 2*fw+14, rh, gap);
if ~isempty(findall(host, 'Type','axes', 'Tag','memr_resp_ax'))
    memr_resp_rows(cp, host, x, y - gap, LW, fw, rh, gap, 'Panel Y-Axis Ranges', pdef(app,'resp_sd'));
end
    function subj_tog(b)
        style_onoff(b);
        cond_filter(app, 'set_vis', findall(host, 'Tag','memr_subj_pts'), ternary(b.Value, 'on', 'off'));
    end
end

function sd_toggle(b, host)
style_onoff(b);
set(findall(host, 'Tag','memr_resp_sd'), 'Visible', ternary(b.Value, 'on', 'off'));
end

function k = resp_k(a)
k = 0;
if isstruct(a.UserData) && isfield(a.UserData, 'k'), k = a.UserData.k; end
end

function resp_lim(a, f0, f1)
if isvalid(a) && isfinite(f0.Value) && isfinite(f1.Value) && f1.Value > f0.Value
    set(a, 'YLimMode','manual', 'YLim',[f0.Value f1.Value]);
end
end

function resp_reset(A, F, Y0)
for i = 1:numel(A)
    if ~isvalid(A(i)), continue; end
    F(i,1).Value = round(Y0(i,1),2);  F(i,2).Value = round(Y0(i,2),2);
    set(A(i), 'YLimMode','manual', 'YLim',Y0(i,:));
end
end


% ══════════════════════════════════════════════════════════════════════════
%  EFR dAM / RAM — Average view controls (right strip of every tab):
%  Subjects Shown/Hidden, one y-axis range for all level tiles, reset.
% ══════════════════════════════════════════════════════════════════════════

function add_efr_avg_ctrl(app, panel)
% One control strip per level panel (right of the plots).
all_t = findall(panel, 'Type','axes', 'Tag','efr_tile');
if isempty(all_t), return; end
hosts = unique(arrayfun(@(a) a.Parent, all_t));
for host = hosts(:)'
    axs  = findall(host, 'Type','axes', 'Tag','efr_tile');
    allx = [axs; findall(host, 'Type','axes', 'Tag','efr_spec_tile'); findall(host, 'Type','axes', 'Tag','efr_tile_total')];
    set(allx, 'Units','normalized');
    P  = cell2mat(arrayfun(@(a) a.Position, allx(:), 'UniformOutput', false));
    x0 = max(max(P(:,1) + P(:,3)) + 0.03, outer_right(allx) + 0.025);   % past the right y-axis labels
    cp = uipanel(host, 'Units','normalized', 'Position',[x0 min(P(:,2)) max(0.12, 0.99-x0) max(P(:,4))], ...
        'BorderType','none', 'BackgroundColor','white', 'Tag','apat_ctrl', 'Visible','off');   % hidden from the start (Plot Settings)
    [PW, PH] = px_size(cp);
    build_efr_ctrl(app, cp, host, axs, PW, PH);
end
end

function build_efr_ctrl(app, cp, host, axs, PW, PH)
yl0 = [inf -inf];
for a = axs(:)', yl0 = [min(yl0(1), a.YLim(1)), max(yl0(2), a.YLim(2))]; end
pts = findall(host, 'Tag','efr_subj_pts');
LW = 90;  fw = 52;  rh = 26;  gap = 10;
w  = LW + 2*fw + 14;  x = max(4, round((PW - w)/2));  y = PH - rh - 4;
y  = add_level_chips(app, cp, host, x, y, LW, 2*fw+14, rh, gap);
y  = cond_filter(app, 'chips', cp, host, x, y, w, rh, gap);
ctl_label(cp, 'Subjects', [x y LW rh]);
on0  = ~isempty(pts) && pdef(app,'subj_pts');   % Setup → Output default
sbtn = uibutton(cp,'state','Text','ON','Value',on0,'FontSize',12,'FontWeight','bold', ...
    'Position',[x+LW y 2*fw+14 rh]);
y = y - rh - gap;
y = shade_row(app, cp, x, y, LW, 2*fw+14, rh, gap);
ctl_label(cp, 'Y-Axis', [x y LW rh]);
y0 = uieditfield(cp,'numeric','Value',round(yl0(1),2),'FontSize',12,'Position',[x+LW y fw rh]);
uilabel(cp,'Text','–','FontSize',13,'HorizontalAlignment','center','Position',[x+LW+fw y 14 rh]);
y1 = uieditfield(cp,'numeric','Value',round(yl0(2),2),'FontSize',12,'Position',[x+LW+fw+14 y fw rh]);
y = y - rh - gap;
rst = uibutton(cp,'push','Text','Reset Axes','FontSize',12,'BackgroundColor','white', ...
    'Position',[x+LW y 2*fw+14 rh]);
if isempty(pts), sbtn.Enable = 'off'; end
sbtn.ValueChangedFcn = @(~,~) style_s();
y0.ValueChangedFcn   = @(~,~) apply_lim();
y1.ValueChangedFcn   = @(~,~) apply_lim();
rst.ButtonPushedFcn  = @(~,~) reset_lim();
style_s();

    function style_s()
        style_onoff(sbtn);
        cond_filter(app, 'set_vis', findall(host,'Tag','efr_subj_pts'), ternary(sbtn.Value,'on','off'));
    end
    function apply_lim()
        if isfinite(y0.Value) && isfinite(y1.Value) && y1.Value > y0.Value
            set(axs, 'YLimMode','manual', 'YLim',[y0.Value y1.Value]);
        end
    end
    function reset_lim()
        y0.Value = round(yl0(1),2);  y1.Value = round(yl0(2),2);
        for a = axs(:)', a.YLim = yl0; end
    end
end


% ══════════════════════════════════════════════════════════════════════════
%  EFR individual — Time tab: one time window for all level tiles + reset.
% ══════════════════════════════════════════════════════════════════════════

function add_efr_time_ctrl(app, sp)
%ADD_EFR_TIME_CTRL  For every tab holding EFR time-series tiles: a control
%   strip on the right with the time window (all tiles in that tab) and a
%   "Listen" list with a play button per waveform (condition × level).
all_t = findall(sp, 'Type','axes', 'Tag','efr_time_tile');
if isempty(all_t), return; end
hosts = unique(arrayfun(@(a) a.Parent, all_t));
for host = hosts(:)'
    axs  = findall(host, 'Type','axes', 'Tag','efr_time_tile');
    allx = [axs; findall(host, 'Type','axes', 'Tag','efr_freq_tile')];
    set(allx, 'Units','normalized');
    P  = cell2mat(arrayfun(@(a) a.Position, allx(:), 'UniformOutput', false));
    tb = findall(host, 'Type','axes', 'Tag','efr_table');
    if ~isempty(tb)                                   % RAM: strip under the harmonic-sum table
        set(tb, 'Units','normalized');  tp = tb(1).Position;
        cpos = [tp(1) 0.04 tp(3) max(0.2, tp(2) - 0.06)];
    else
        x0 = max(P(:,1) + P(:,3)) + 0.03;
        cpos = [x0 0.04 max(0.12, 0.99-x0) 0.84];
    end
    cp = uipanel(host, 'Units','normalized', 'Position',cpos, ...
        'BorderType','none', 'BackgroundColor','white', 'Tag','apat_ctrl', 'Visible','off');   % hidden from the start (Plot Settings)
    [PW, PH] = px_size(cp);
    build_efr_time_ctrl(app, cp, axs, PW, PH);
end
end


function build_efr_time_ctrl(app, cp, axs, PW, PH)
xl0  = axs(1).XLim;
tmax = 0;
waves = findall(axs, 'Type','line', 'Tag','efr_wave');
for h = waves(:)'
    xd = h.XData;  if ~isempty(xd), tmax = max(tmax, max(xd(isfinite(xd)))); end
end
LW = 70;  fw = 56;  rh = 26;  gap = 8;
w  = LW + 2*fw + 14;  x = max(4, round((PW - w)/2));  y = PH - rh - 4;
y  = add_level_chips(app, cp, axs(1).Parent, x, y, LW, 2*fw+14, rh, gap);
y  = cond_filter(app, 'chips', cp, axs(1).Parent, x, y, w, rh, gap);
if ~isempty(findall(axs(1).Parent, 'Tag','apat_xgroup'))
    y = shade_row(app, cp, x, y, LW, 2*fw+14, rh, gap);
end
ctl_label(cp, 'Time (s)', [x y LW rh]);
t0 = uieditfield(cp,'numeric','Value',round(xl0(1),3),'FontSize',12,'Position',[x+LW y fw rh]);
uilabel(cp,'Text','–','FontSize',13,'HorizontalAlignment','center','Position',[x+LW+fw y 14 rh]);
t1 = uieditfield(cp,'numeric','Value',round(xl0(2),3),'FontSize',12,'Position',[x+LW+fw+14 y fw rh]);
y = y - rh - gap;
fb = uibutton(cp,'push','Text','Full Length','FontSize',12,'BackgroundColor','white', ...
    'Position',[x+LW y 2*fw+14 rh]);
y = y - rh - gap;
rst = uibutton(cp,'push','Text','Reset','FontSize',12,'BackgroundColor','white', ...
    'Position',[x+LW y 2*fw+14 rh]);
t0.ValueChangedFcn  = @(~,~) apply_t();
t1.ValueChangedFcn  = @(~,~) apply_t();
fb.ButtonPushedFcn  = @(~,~) set_t(0, tmax);
rst.ButtonPushedFcn = @(~,~) set_t(xl0(1), xl0(2));

% ── Listen: play buttons in a bar right under the time plot (outside the
%    Plot Settings panel, always visible) ───────────────────────────────
if ~isempty(waves), add_listen_bar(app, axs(1), waves); end

    function apply_t()
        if isfinite(t0.Value) && isfinite(t1.Value) && t1.Value > t0.Value
            set(axs, 'XLimMode','manual', 'XLim',[t0.Value t1.Value]);
        end
    end
    function set_t(a, b)
        if ~(b > a), return; end
        t0.Value = round(a,3);  t1.Value = round(b,3);
        apply_t();
    end
end


function add_listen_bar(app, ax, waves)
%ADD_LISTEN_BAR  EFR: "Listen" bar under the time plot — one play button per
%   waveform in its condition colour (highest level first, then the roster
%   order Baseline → D7 → D14 …), then Stop and Loop (ON = replays until
%   Stop). A uipanel (Tag 'apat_under_ax', UserData = the time axes) with a
%   grid layout, so it resizes with the plot; fit_layout keeps room for it
%   under the axes' x-label and places it there, aligned with the plot.
host = ax.Parent;
delete(findobj(host.Children, 'flat', 'Tag','apat_under_ax'));
levs  = arrayfun(@(h) double(h.UserData(1)), waves);
multi = numel(unique(levs)) > 1;             % RAM Time tab: several levels
cnames = {};
try
    pth = app.res.run_conds.paths;  if ischar(pth), pth = {pth}; end
    cnames = cellfun(@(q) regexprep(q, '^.*[\\/]', ''), pth, 'UniformOutput', false);
catch
end
cidx = arrayfun(@(h) cond_rank(h.DisplayName, cnames), waves);
[~, o] = sortrows([-levs(:), cidx(:), (1:numel(waves))']);  waves = waves(o);
n = numel(waves);  if n == 0, return; end
per = min(n, 6);  nr = ceil(n / per);
RSPAN = nr;  if nr > 1, RSPAN = [1 nr]; end   % [1 1] is rejected by uigridlayout
BH = 24;  bh_px = nr*BH + (nr-1)*4 + 8;
set(ax, 'Units','normalized');  ap = ax.Position;
hp = getpixelposition(host);
bar = uipanel(host, 'Units','normalized', 'BorderType','none', 'BackgroundColor','white', ...
    'Position',[ap(1) max(0.01, ap(2) - 0.12) ap(3) bh_px / max(hp(4),1)], ...
    'Tag','apat_under_ax', 'UserData',ax);
g = uigridlayout(bar, [nr, per + 3], 'Padding',[0 4 0 4], 'RowSpacing',4, 'ColumnSpacing',4, ...
    'BackgroundColor','white');
g.ColumnWidth = [{'fit'}, repmat({'1x'}, 1, per), {'fit','fit'}];
g.RowHeight   = repmat({BH}, 1, nr);
lb = uilabel(g, 'Text','Listen', 'FontSize',12, 'FontWeight','bold', 'FontColor',[0.15 0.15 0.15]);
lb.Layout.Row = RSPAN;  lb.Layout.Column = 1;
for k = 1:n
    h = waves(k);
    lbl = h.DisplayName;  tip = sprintf('Play %s as sound', lbl);
    if multi
        tip = sprintf('Play %s at %g dB as sound', lbl, h.UserData(1));
        lbl = sprintf('%g·%s', h.UserData(1), lbl);
    end
    clr = h.Color(1:3);
    tc  = [1 1 1];  if 0.299*clr(1)+0.587*clr(2)+0.114*clr(3) > 0.62, tc = [0 0 0]; end
    b = uibutton(g, 'push', 'Text',[char(9654) ' ' lbl], 'FontSize',11, 'FontWeight','bold', ...
        'BackgroundColor',clr, 'FontColor',tc, 'Tooltip',tip, 'ButtonPushedFcn',@(~,~) play_wave(app, h));
    b.Layout.Row = ceil(k / per);  b.Layout.Column = 1 + mod(k-1, per) + 1;
end
sb = uibutton(g, 'push', 'Text',[char(9632) ' Stop'], 'FontSize',11, 'FontWeight','bold', ...
    'BackgroundColor','white', 'Tooltip','Stop playing', 'ButtonPushedFcn',@(~,~) stop_wave(app));
sb.Layout.Row = RSPAN;  sb.Layout.Column = per + 2;
lp = uibutton(g, 'state', 'Text','Loop', 'Value',loop_state(app), 'FontSize',11, 'FontWeight','bold', ...
    'Tag','efr_loop_btn', 'Tooltip','Loop ON: the waveform replays until you press Stop');
lp.Layout.Row = RSPAN;  lp.Layout.Column = per + 3;
lp.ValueChangedFcn = @(src,~) set_loop(app, src);
style_loop(lp);
end


function y = add_level_chips(app, cp, host, x, y, LW, AW, rh, gap)
%ADD_LEVEL_CHIPS  EFR: one button per stimulus level (like the ABR waterfall
%   level buttons), replacing the Level dropdown. The levels are the sibling
%   level panels of HOST (Tag '<lev> dB SPL'); clicking shows that level
%   (navigate_results 'efr_level'); do_level keeps every strip in sync.
%   Returns the y for the next row.
par = host.Parent;
lp  = findobj(par.Children, 'flat', 'Type','uipanel', '-regexp', 'Tag', 'dB SPL$');
if isempty(lp), return; end
tags = arrayfun(@(p) p.Tag, lp, 'UniformOutput', false);
tags = sort_level_labels(tags);
n  = numel(tags);  per = min(n, 3);  cg = 6;
cw = floor((AW - (per-1)*cg) / per);
ctl_label(cp, 'Level (dB)', [x y LW rh]);
for k = 1:n
    col = mod(k-1, per);
    if col == 0 && k > 1, y = y - rh - cg; end
    v = sscanf(tags{k}, '%f');  txt = tags{k};  if ~isempty(v), txt = sprintf('%g', v(1)); end
    uibutton(cp, 'state', 'Text',txt, 'Value',false, 'FontSize',12, 'FontWeight','bold', ...
        'Tag','efr_lev_btn', 'UserData',tags{k}, 'Position',[x+LW+col*(cw+cg) y cw rh], ...
        'BackgroundColor',[0.97 0.96 0.93], 'FontColor',[0.40 0.38 0.35], ...
        'Tooltip',sprintf('Show %s', tags{k}), ...
        'ValueChangedFcn',@(src,~) navigate_results(app, 'efr_level', src.UserData));
end
y = y - rh - gap;
end


function play_wave(app, h)
%PLAY_WAVE  Play an EFR waveform (whole recording) as sound. Sample rate
%   is taken from the time axis. Every waveform is played at the SAME
%   loudness: mean removed, scaled to a fixed RMS (not to its peak, so a
%   recording with a few large spikes is not played quieter), with a soft
%   limiter that only acts on rare peaks near full scale, and 10 ms fades so
%   it does not click. Level differences between recordings are therefore
%   not audible — compare their sound, not their size.
if ~isvalid(h), return; end
stop_wave(app);
x = double(h.XData(:));  y = double(h.YData(:));
ok = isfinite(x) & isfinite(y);  x = x(ok);  y = y(ok);
if numel(y) < 10, return; end
fs = 1 / median(diff(x));
if ~(fs > 0), return; end
fs_out = round(fs);
if fs_out < 4000 || fs_out > 192000              % keep within audio-device range
    y = resample(y, 44100, fs_out);  fs_out = 44100;
end
TARGET_RMS = 0.12;                               % same loudness for every waveform
y = y - mean(y);
r = sqrt(mean(y.^2));
if r > 0, y = y * (TARGET_RMS / r); end
y = 0.98 * tanh(y / 0.98);                       % soft limit: only peaks near ±1 are touched
nr = min(numel(y), round(0.01*fs_out));
ramp = (0:nr-1)'/max(nr,1);
y(1:nr) = y(1:nr) .* ramp;  y(end-nr+1:end) = y(end-nr+1:end) .* flipud(ramp);
try
    app.res.stop_req = false;
    app.res.player = audioplayer(y, fs_out);
    app.res.player.StopFcn = @(p,~) loop_replay(app, p);    % Loop ON → replay
    play(app.res.player);
catch err
    uialert(app.UIFigure, sprintf('Could not play sound: %s', err.message), 'Audio');
end
end


function stop_wave(app)
app.res.stop_req = true;                         % a real stop: no loop replay
if isfield(app.res,'player') && ~isempty(app.res.player)
    try, stop(app.res.player); catch, end
end
end


function r = cond_rank(nm, cnames)
%COND_RANK  Position of condition NM in the roster order (unknown → last).
r = find(strcmp(cnames, nm), 1);
if isempty(r), r = 1e3; end
end


function loop_replay(app, p)
%LOOP_REPLAY  Player finished: start again when Loop is ON (not after Stop).
try
    if isvalid(app) && loop_state(app) && ~(isfield(app.res,'stop_req') && app.res.stop_req)
        play(p);
    end
catch
end
end


function v = loop_state(app)
v = isfield(app.res,'loop_on') && isequal(app.res.loop_on, true);
end


function set_loop(app, b)
%SET_LOOP  Loop toggle (shared by every Listen strip).
app.res.loop_on = logical(b.Value);
for h = findall(app.ResultsTab, 'Tag','efr_loop_btn')'
    h.Value = app.res.loop_on;  style_loop(h);
end
end


function style_loop(b)
if b.Value
    b.Text = ['Loop  ' char(10227)];  b.BackgroundColor = [0.18 0.49 0.31];  b.FontColor = [1 1 1];
else
    b.Text = 'Loop';  b.BackgroundColor = [0.88 0.88 0.88];  b.FontColor = [0.40 0.40 0.40];
end
end


function y = shade_row(app, cp, x, y, LW, AW, rh, gap)
%SHADE_ROW  "Shading" ON / OFF row in a control strip: shows / hides the
%   x-group bands (Tag 'apat_xgroup') in every Results plot; the choice is
%   kept for the session (app.res.xgroup_on) and all strips stay in sync.
ctl_label(cp, 'Shading', [x y LW rh]);
b = uibutton(cp,'state','Text','ON','Value',shade_state(app),'FontSize',12,'FontWeight','bold', ...
    'Tag','apat_shade_btn', 'Position',[x+LW y AW rh], ...
    'Tooltip','Show / hide the shaded bands that group the points of one x value');
b.ValueChangedFcn = @(src,~) set_shade(app, src.Value);
style_onoff(b);
y = y - rh - gap;
end


function v = shade_state(app)
v = ~isfield(app.res,'xgroup_on') || ~isequal(app.res.xgroup_on, false);
end


function set_shade(app, on)
app.res.xgroup_on = logical(on);
apply_shade(app, app.ResultsTab);
end


function apply_shade(app, root)
%APPLY_SHADE  Shading bands and every Shading button follow app.res.xgroup_on.
on = shade_state(app);
try, set(findall(root, 'Tag','apat_xgroup'), 'Visible', ternary(on,'on','off')); catch, end
for b = findall(app.ResultsTab, 'Tag','apat_shade_btn')'
    try, b.Value = on;  style_onoff(b); catch, end
end
end


% ══════════════════════════════════════════════════════════════════════════
%  OAE (DPOAE / SFOAE / TEOAE) — view controls in every scale panel:
%    Individual: under the band table — Scale (EPL / SPL), Sweep, Noise Floor,
%                Y-axis, Reset.
%    Average:    right of the plots — Scale, Subjects, Sweep, Noise Floor,
%                Y-axis (band plot), Reset.
%  Display only; saved files are not changed.
% ══════════════════════════════════════════════════════════════════════════

function add_oae_ctrl(app, parent, mode)
if strcmp(mode, 'ind'), main_tag = 'oae_ind_ax'; else, main_tag = 'oae_avg_ax'; end
all_ax = findall(parent, 'Type','axes', 'Tag',main_tag);
if isempty(all_ax), return; end
for ax = all_ax(:)'
    host = ax.Parent;
    if strcmp(mode, 'ind')
        tb = findall(host, 'Type','axes', 'Tag','oae_table');
        if isempty(tb), continue; end
        set(tb, 'Units','normalized');  tp = tb(1).Position;
        cpos = [tp(1) 0.04 tp(3) max(0.2, tp(2) - 0.06)];
    else
        allx = [ax; findall(host, 'Type','axes', 'Tag','oae_reg_ax')];
        set(allx, 'Units','normalized');
        P  = cell2mat(arrayfun(@(a) a.Position, allx(:), 'UniformOutput', false));
        x0 = max(max(P(:,1) + P(:,3)) + 0.04, outer_right(allx) + 0.025);
        cpos = [x0 min(P(:,2)) max(0.12, 0.99 - x0) max(P(:,2) + P(:,4)) - min(P(:,2))];
    end
    cp = uipanel(host, 'Units','normalized', 'Position',cpos, ...
        'BorderType','none', 'BackgroundColor','white', 'Tag','apat_ctrl', 'Visible','off');   % hidden from the start (Plot Settings)
    [PW, PH] = px_size(cp);
    build_oae_ctrl(app, cp, host, ax, mode, PW, PH);
end
end


function build_oae_ctrl(app, cp, host, ax, mode, PW, PH)
yl0 = ax.YLim;
LW = 92;  fw = 50;  rh = 26;  gap = 10;
w  = LW + 2*fw + 14;  x = max(4, round((PW - w)/2));  y = PH - rh - 4;
btns = struct('b',{},'tag',{});
% Scale: EPL / SPL (both on = EPL + SPL view); state and availability are
% synced by navigate_results>do_scale for every view's strip.
ctl_label(cp, 'Scale', [x y LW rh]);
bw2 = fw;  stxt = {'EPL','SPL'};  stag = {'oae_scale_epl','oae_scale_spl'};   % columns of the Y-axis boxes (gap 14)
for k = 1:2
    bs = uibutton(cp,'state','Text',stxt{k},'Value',true,'FontSize',12,'FontWeight','bold', ...
        'Tag',stag{k},'Position',[x+LW+(k-1)*(bw2+14) y bw2 rh], ...
        'Tooltip',sprintf('Show %s (both on = EPL and SPL together)', stxt{k}), ...
        'ValueChangedFcn',@(src,~) navigate_results(app, 'oae_toggle', k, src));
    res_style('seg', bs, true);                    % synced by navigate_results>do_scale
end
y = y - rh - gap;
y = cond_filter(app, 'chips', cp, host, x, y, w, rh, gap);
if strcmp(mode, 'avg')
    pts = findall(host, 'Tag','oae_subj_pts');
    sb = tog('Subjects', ~isempty(pts) && pdef(app,'subj_pts'), 'oae_subj_pts');
    if isempty(pts), sb.Enable = 'off'; end
end
tog('Sweep', pdef(app,'oae_sweep'), 'oae_raw');
if ~isempty(findall(host, 'Tag','oae_nf')), tog('Noise Floor', pdef(app,'oae_nf'), 'oae_nf'); end
y = shade_row(app, cp, x, y, LW, 2*fw+14, rh, gap);
ctl_label(cp, 'Y-Axis (dB)', [x y LW rh]);
y0 = uieditfield(cp,'numeric','Value',round(yl0(1),1),'FontSize',12,'Position',[x+LW y fw rh]);
uilabel(cp,'Text','–','FontSize',13,'HorizontalAlignment','center','Position',[x+LW+fw y 14 rh]);
y1 = uieditfield(cp,'numeric','Value',round(yl0(2),1),'FontSize',12,'Position',[x+LW+fw+14 y fw rh]);
y = y - rh - gap;
rst = uibutton(cp,'push','Text','Reset Axes','FontSize',12,'BackgroundColor','white', ...
    'Position',[x+LW y 2*fw+14 rh]);
y0.ValueChangedFcn  = @(~,~) apply_lim();
y1.ValueChangedFcn  = @(~,~) apply_lim();
rst.ButtonPushedFcn = @(~,~) reset_lim();

    function b = tog(txt, on, tag)
        ctl_label(cp, txt, [x y LW rh]);
        b = uibutton(cp,'state','Text','ON','Value',on,'FontSize',12,'FontWeight','bold', ...
            'Position',[x+LW y 2*fw+14 rh]);
        b.ValueChangedFcn = @(src,~) style_vis(src, tag);
        style_vis(b, tag);
        btns(end+1) = struct('b',b,'tag',tag);
        y = y - rh - gap;
    end
    function style_vis(b, tag)
        style_onoff(b);
        cond_filter(app, 'set_vis', findall(host, 'Tag',tag), ternary(b.Value,'on','off'));
    end
    function apply_lim()
        if isfinite(y0.Value) && isfinite(y1.Value) && y1.Value > y0.Value
            set(ax, 'YLimMode','manual', 'YLim',[y0.Value y1.Value]);
        end
    end
    function reset_lim()
        y0.Value = round(yl0(1),1);  y1.Value = round(yl0(2),1);
        ax.YLim = yl0;
    end
end


function xr = outer_right(axs)
%OUTER_RIGHT  Right edge (normalized, in the axes' container) of AXS
%   including their tick labels / right y-axis labels (TightInset).
xr = 0;
try, drawnow; catch, end
for a = axs(:)'
    if ~isvalid(a), continue; end
    set(a, 'Units','normalized');  p = a.Position;  ti = [0 0 0 0];
    try, ti = a.TightInset; catch, end
    xr = max(xr, p(1) + p(3) + ti(3));
end
end


function A = vis_axes(host)
%VIS_AXES  Plot axes (visible) directly inside HOST.
A = findobj(host.Children, 'flat', 'Type','axes', 'Visible','on');
end


function out = sort_level_labels(labs)
%SORT_LEVEL_LABELS  '<lev> dB SPL' labels in ascending level order (unique).
labs = unique(labs, 'stable');
v = inf(1, numel(labs));
for k = 1:numel(labs)
    x = sscanf(labs{k}, '%f');  if ~isempty(x), v(k) = x(1); end
end
[~, o] = sort(v);  out = labs(o);
end
