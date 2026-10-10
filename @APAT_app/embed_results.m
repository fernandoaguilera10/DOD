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

if ~isvalid(app), return; end
valid_figs = figs(arrayfun(@(f) isvalid(f) && ~isempty(findall(f,'Type','axes')), figs));
if isempty(valid_figs), return; end

meas_idx = find(strcmp(APAT_app.measure_tab_labels(), label), 1);
if isempty(meas_idx), return; end

switch mode
    case 'ind',  embed_individual(app, valid_figs, meas_idx, varargin{1});
    case 'avg',  embed_average(app, valid_figs, meas_idx);
end
end


% ── Individual embedding ──────────────────────────────────────────────

function embed_individual(app, figs, meas_idx, subject)
ind_panel = app.res.panels{1, meas_idx};
pos       = ind_panel.Position;

% Find or create the per-subject sub-panel
data = app.res.subj_data{meas_idx};
si   = find(strcmp(data.names, subject), 1);
if isempty(si)
    si = numel(data.names) + 1;
    sp = uipanel(ind_panel,'BorderType','none', ...
        'BackgroundColor',app.clr_bg, ...
        'Position',[0 0 pos(3) pos(4)],'Visible','off');
    data.names{si}  = subject;
    data.panels{si} = sp;
    app.res.subj_data{meas_idx} = data;
end

sp = app.res.subj_data{meas_idx}.panels{si};
delete(sp.Children);
embed_figs(app, figs, sp);

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

navigate_results(app, 'after_ind_embed', meas_idx, subject);
if any(meas_idx == [3 4]), add_efr_time_ctrl(app, sp); end   % EFR Time tab: time window
subject_pick(app, 'wire');                       % clickable subject points
app.TabGroup.SelectedTab = app.ResultsTab;
drawnow;
end


% ── Average embedding ─────────────────────────────────────────────────

function embed_average(app, figs, meas_idx)
panel = app.res.panels{2, meas_idx};
delete(panel.Children);
embed_figs(app, figs, panel);

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

navigate_results(app, 'after_avg_embed', meas_idx);
app.TabGroup.SelectedTab = app.ResultsTab;
drawnow;
navigate_results(app, 'filter_avg');
if meas_idx == 2, add_abr_avg_toolbars(app, panel); end   % ABR Peaks view controls
if meas_idx == 1, add_thr_avg_ctrl(app, panel); end       % ABR Thresholds view controls
if any(meas_idx == [3 4]), add_efr_avg_ctrl(app, panel); end   % EFR dAM / RAM view controls
subject_pick(app, 'wire');                                 % clickable subject points
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
pos = parent.Position;
W   = pos(3);
VH  = pos(4);
n   = numel(figs);
fw  = W - 2*PAD;
fh  = VH - 2*PAD;

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
        sub_p = uipanel(parent,'Position',[PAD PAD fw fh], ...
            'BackgroundColor','white','Visible',vis,'Title','','Tag',names{i},'FontSize',14);
        h_copy  = [findall(figs(i),'Type','axes'); findall(figs(i),'Type','legend')];
        new_axs = copyobj(h_copy, sub_p);
        arrayfun(@(a) set(a,'Units','normalized'), new_axs);
    end
elseif n == 1
    ttl1 = names{1};  bt1 = 'line';
    if strcmp(get(figs(1),'Tag'),'APAT_thr_avg'), ttl1 = ''; bt1 = 'none'; end
    sub_p   = uipanel(parent,'Position',[PAD PAD fw fh], ...
        'BackgroundColor','white','Title',ttl1,'BorderType',bt1,'FontSize',14);
    h_copy  = [findall(figs(1),'Type','axes'); findall(figs(1),'Type','legend')];
    new_axs = copyobj(h_copy, sub_p);
    arrayfun(@(a) set(a,'Units','normalized'), new_axs);
elseif n == 2
    fw2 = floor((W - 3*PAD) / 2);
    for i = 1:2
        x     = PAD + (i-1)*(fw2+PAD);
        sub_p = uipanel(parent,'Position',[x PAD fw2 fh], ...
            'BackgroundColor','white','Title',names{i},'FontSize',14);
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
        'BackgroundColor',app.clr_bg,'Position',[0 0 W VH]);
    for i = 1:n
        col   = mod(i-1,2);  row = floor((i-1)/2);
        x     = PAD + col*(fw2+PAD);
        y     = total_h - (row+1)*(fh+PAD);
        sub_p = uipanel(scroll,'Position',[x y fw2 fh], ...
            'BackgroundColor','white','Title',names{i},'FontSize',14);
        h_copy  = [findall(figs(i),'Type','axes'); findall(figs(i),'Type','legend')];
        new_axs = copyobj(h_copy, sub_p);
        arrayfun(@(a) set(a,'Units','normalized'), new_axs);
    end
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
W = panel.Position(3);
H = max(panel.Position(4) - 30, 300);           % tab content size (px)
for tab = tg(1).Children(:)'
    if isempty(tab.Children), continue; end
    tab_panel = tab.Children(end);               % content panel created by embed
    switch tab.Title
        case 'Waveforms'
            axs = findall(tab_panel, 'Type','axes', 'Tag','abr_waterfall');
            if isempty(axs), continue; end
            % Region under the legend (normalized, same frame as the plots)
            lg = findall(tab_panel, 'Type','legend');
            if ~isempty(lg)
                set(lg, 'Units','normalized');
                lp = lg(1).Position;
                rx = lp(1);  rw = min(1 - lp(1) - 0.01, max(lp(3), 150/W));
                top = lp(2) - 0.03;
            else
                rx = 0.86;  rw = 0.13;  top = 0.6;
            end
            bot = 0.06;
            cp = uipanel(tab, 'Units','normalized', 'Position',[rx bot rw max(0.2, top-bot)], ...
                'BorderType','none', 'BackgroundColor','white');
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
                'BorderType','none', 'BackgroundColor','white');
            [pw, ph] = px_size(cp);
            build_peak_ctrl(app, cp, tab_panel, axs, pw, ph);
    end
end
end


function [pw, ph] = px_size(cp)
%PX_SIZE  Actual pixel size of a (normalized) panel, after layout.
drawnow;
cp.Units = 'pixels';  p = cp.Position;  cp.Units = 'normalized';
pw = max(120, round(p(3)));  ph = max(120, round(p(4)));
end


function style_toggle(app, b)
%STYLE_TOGGLE  On = the app gold (same as Average / Individual and the
%   selected measure), off = white with grey text.
if b.Value
    b.BackgroundColor = app.clr_gold;      b.FontColor = app.clr_black;
else
    b.BackgroundColor = [1 1 1];           b.FontColor = [0.60 0.60 0.60];
end
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
sbtn = uibutton(cp,'state','Text','Hidden','Value',false,'FontSize',12,'FontWeight','bold', ...
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
    style_toggle(app, sbtn);  sbtn.Text = ternary(sbtn.Value, 'Shown', 'Hidden');
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

ctl_label(cp, 'Subjects', [x y LW rh]);
sbtn = uibutton(cp,'state','Text','Hidden','Value',false,'FontSize',12,'FontWeight','bold', ...
    'Position',[x+LW y 2*fw+14 rh]);
y = y - rh - gap;
ctl_label(cp, 'Sample size (n)', [x y LW rh]);
nbtn = uibutton(cp,'state','Text','Shown','Value',true,'FontSize',12,'FontWeight','bold', ...
    'Position',[x+LW y 2*fw+14 rh]);
y = y - rh - gap;
ctl_label(cp, 'Y-axis', [x y LW rh]);
y0 = uieditfield(cp,'numeric','Value',round(yl(1),1),'FontSize',12,'Position',[x+LW y fw rh]);
uilabel(cp,'Text','–','FontSize',13,'HorizontalAlignment','center','Position',[x+LW+fw y 14 rh]);
y1 = uieditfield(cp,'numeric','Value',round(yl(2),1),'FontSize',12,'Position',[x+LW+fw+14 y fw rh]);
y = y - rh - gap;
ctl_label(cp, 'X-axis (dB)', [x y LW rh]);
x0 = uieditfield(cp,'numeric','Value',xl(1),'FontSize',12,'Position',[x+LW y fw rh]);
uilabel(cp,'Text','–','FontSize',13,'HorizontalAlignment','center','Position',[x+LW+fw y 14 rh]);
x1 = uieditfield(cp,'numeric','Value',xl(2),'FontSize',12,'Position',[x+LW+fw+14 y fw rh]);
y = y - rh - gap;
auto = uibutton(cp,'push','Text','Reset axes','FontSize',12,'BackgroundColor','white', ...
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
        style_toggle(app, nbtn);
        nbtn.Text = ternary(nbtn.Value, 'Shown', 'Hidden');
        set(findall(tab_panel,'Tag','abr_n_lbl'), 'Visible', ternary(nbtn.Value,'on','off'));
    end
    function style_s()
        style_toggle(app, sbtn);
        sbtn.Text = ternary(sbtn.Value, 'Shown', 'Hidden');
        set(findall(tab_panel,'Tag','abr_subj_pts'), 'Visible', ternary(sbtn.Value,'on','off'));
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

function add_thr_avg_ctrl(app, panel)
ax = findall(panel, 'Type','axes', 'Tag','abr_thr_avg');
if isempty(ax), return; end
ax = ax(1);  host = ax.Parent;
% Right of the plot, top-aligned with it (legend sits under the plot)
set(ax, 'Units','normalized');  ap = ax.Position;
x0 = ap(1) + ap(3) + 0.02;
cp = uipanel(host, 'Units','normalized', 'Position',[x0 ap(2) max(0.15, 0.99-x0) ap(4)], ...
    'BorderType','none', 'BackgroundColor','white');
[PW, PH] = px_size(cp);
yl0 = ax.YLim;
LW = 120;  fw = 52;  rh = 26;  gap = 10;
w  = LW + 2*fw + 14;  x = max(4, round((PW - w)/2));  y = PH - rh - 4;

ctl_label(cp, 'Subjects', [x y LW rh]);
sbtn = uibutton(cp,'state','Text','Shown','Value',true,'FontSize',12,'FontWeight','bold', ...
    'Position',[x+LW y 2*fw+14 rh]);
y = y - rh - gap;
ctl_label(cp, 'Y-axis (dB)', [x y LW rh]);
y0 = uieditfield(cp,'numeric','Value',round(yl0(1),1),'FontSize',12,'Position',[x+LW y fw rh]);
uilabel(cp,'Text','–','FontSize',13,'HorizontalAlignment','center','Position',[x+LW+fw y 14 rh]);
y1 = uieditfield(cp,'numeric','Value',round(yl0(2),1),'FontSize',12,'Position',[x+LW+fw+14 y fw rh]);
y = y - rh - gap;
rst = uibutton(cp,'push','Text','Reset axes','FontSize',12,'BackgroundColor','white', ...
    'Position',[x+LW y 2*fw+14 rh]);

sbtn.ValueChangedFcn = @(~,~) style_tog(sbtn, 'thr_subj_pts');
y0.ValueChangedFcn   = @(~,~) apply_lim();
y1.ValueChangedFcn   = @(~,~) apply_lim();
rst.ButtonPushedFcn  = @(~,~) reset_lim();
style_tog(sbtn, 'thr_subj_pts');

    function style_tog(b, tag)
        style_toggle(app, b);
        b.Text = ternary(b.Value, 'Shown', 'Hidden');
        set(findall(ax,'Tag',tag), 'Visible', ternary(b.Value,'on','off'));
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
    x0 = max(P(:,1) + P(:,3)) + 0.03;
    cp = uipanel(host, 'Units','normalized', 'Position',[x0 min(P(:,2)) max(0.12, 0.99-x0) max(P(:,4))], ...
        'BorderType','none', 'BackgroundColor','white');
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
ctl_label(cp, 'Subjects', [x y LW rh]);
on0  = ~isempty(pts);                        % shown by default
sbtn = uibutton(cp,'state','Text','Shown','Value',on0,'FontSize',12,'FontWeight','bold', ...
    'Position',[x+LW y 2*fw+14 rh]);
y = y - rh - gap;
ctl_label(cp, 'Y-axis', [x y LW rh]);
y0 = uieditfield(cp,'numeric','Value',round(yl0(1),2),'FontSize',12,'Position',[x+LW y fw rh]);
uilabel(cp,'Text','–','FontSize',13,'HorizontalAlignment','center','Position',[x+LW+fw y 14 rh]);
y1 = uieditfield(cp,'numeric','Value',round(yl0(2),2),'FontSize',12,'Position',[x+LW+fw+14 y fw rh]);
y = y - rh - gap;
rst = uibutton(cp,'push','Text','Reset axes','FontSize',12,'BackgroundColor','white', ...
    'Position',[x+LW y 2*fw+14 rh]);
if isempty(pts), sbtn.Enable = 'off'; end
sbtn.ValueChangedFcn = @(~,~) style_s();
y0.ValueChangedFcn   = @(~,~) apply_lim();
y1.ValueChangedFcn   = @(~,~) apply_lim();
rst.ButtonPushedFcn  = @(~,~) reset_lim();
style_s();

    function style_s()
        style_toggle(app, sbtn);
        sbtn.Text = ternary(sbtn.Value, 'Shown', 'Hidden');
        set(findall(host,'Tag','efr_subj_pts'), 'Visible', ternary(sbtn.Value,'on','off'));
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
        'BorderType','none', 'BackgroundColor','white');
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
ctl_label(cp, 'Time (s)', [x y LW rh]);
t0 = uieditfield(cp,'numeric','Value',round(xl0(1),3),'FontSize',12,'Position',[x+LW y fw rh]);
uilabel(cp,'Text','–','FontSize',13,'HorizontalAlignment','center','Position',[x+LW+fw y 14 rh]);
t1 = uieditfield(cp,'numeric','Value',round(xl0(2),3),'FontSize',12,'Position',[x+LW+fw+14 y fw rh]);
y = y - rh - gap;
fb = uibutton(cp,'push','Text','Full length','FontSize',12,'BackgroundColor','white', ...
    'Position',[x+LW y 2*fw+14 rh]);
y = y - rh - gap;
rst = uibutton(cp,'push','Text','Reset','FontSize',12,'BackgroundColor','white', ...
    'Position',[x+LW y 2*fw+14 rh]);
t0.ValueChangedFcn  = @(~,~) apply_t();
t1.ValueChangedFcn  = @(~,~) apply_t();
fb.ButtonPushedFcn  = @(~,~) set_t(0, tmax);
rst.ButtonPushedFcn = @(~,~) set_t(xl0(1), xl0(2));

% ── Listen: one play button per waveform ─────────────────────────────
if isempty(waves), return; end
y = y - rh - 2*gap;
ctl_label(cp, 'Listen', [x y w rh]);
levs   = arrayfun(@(h) double(h.UserData(1)), waves);
multi  = numel(unique(levs)) > 1;            % RAM Time tab: several levels
[~, o] = sortrows([-levs(:), (1:numel(waves))']);  waves = waves(o);
for h = waves(:)'
    y = y - rh - gap;
    if y < 4, break; end
    lbl = h.DisplayName;
    if multi, lbl = sprintf('%g dB · %s', h.UserData(1), lbl); end
    clr = h.Color(1:3);
    tc  = [1 1 1];  if 0.299*clr(1)+0.587*clr(2)+0.114*clr(3) > 0.62, tc = [0 0 0]; end
    uibutton(cp,'push','Text',['▶  ' lbl],'FontSize',12,'FontWeight','bold', ...
        'BackgroundColor',clr,'FontColor',tc,'HorizontalAlignment','left', ...
        'Tooltip','Play this waveform as sound', ...
        'Position',[x y w rh], 'ButtonPushedFcn',@(~,~) play_wave(app, h));
end
y = y - rh - gap;
if y >= 4
    uibutton(cp,'push','Text','■  Stop','FontSize',12,'BackgroundColor','white', ...
        'Position',[x y w rh], 'ButtonPushedFcn',@(~,~) stop_wave(app));
end

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


function play_wave(app, h)
%PLAY_WAVE  Play an EFR waveform (whole recording) as sound. Sample rate
%   is taken from the time axis; the signal is mean-removed, normalised to
%   90% full scale and given 10 ms fades so it does not click.
if ~isvalid(h), return; end
stop_wave(app);
x = double(h.XData(:));  y = double(h.YData(:));
ok = isfinite(x) & isfinite(y);  x = x(ok);  y = y(ok);
if numel(y) < 10, return; end
fs = 1 / median(diff(x));
if ~(fs > 0), return; end
y = y - mean(y);
pk = max(abs(y));  if pk > 0, y = 0.9 * y / pk; end
nr = min(numel(y), round(0.01*fs));
ramp = (0:nr-1)'/max(nr,1);
y(1:nr) = y(1:nr) .* ramp;  y(end-nr+1:end) = y(end-nr+1:end) .* flipud(ramp);
fs_out = round(fs);
if fs_out < 4000 || fs_out > 192000              % keep within audio-device range
    y = resample(y, 44100, fs_out);  fs_out = 44100;
end
try
    app.res.player = audioplayer(y, fs_out);
    play(app.res.player);
catch err
    uialert(app.UIFigure, sprintf('Could not play sound: %s', err.message), 'Audio');
end
end


function stop_wave(app)
if isfield(app.res,'player') && ~isempty(app.res.player)
    try, stop(app.res.player); catch, end
end
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
