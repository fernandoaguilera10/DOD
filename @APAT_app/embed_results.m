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
    if ~isempty(avg_freqs)
        existing  = app.FigFreqDD.Items;
        existing  = existing(~strcmp(existing,'—'));
        new_items = avg_freqs(~ismember(avg_freqs, existing));
        merged    = [existing, new_items];
        if isempty(merged), merged = avg_freqs; end
        app.FigFreqDD.Items = merged;
        app.FigFreqDD.Value = avg_freqs{1};
    end
end

navigate_results(app, 'after_avg_embed', meas_idx);
app.TabGroup.SelectedTab = app.ResultsTab;
drawnow;
navigate_results(app, 'filter_avg');
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
    sub_p   = uipanel(parent,'Position',[PAD PAD fw fh], ...
        'BackgroundColor','white','Title',names{1},'FontSize',14);
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

cat_order   = {'Waveforms','Amplitudes','Latencies', ...
               'ABR Waveforms','Sigmoid Fits'};
unique_cats = unique(categories,'stable');
present     = cat_order(ismember(cat_order, unique_cats));
others      = unique_cats(~ismember(unique_cats, [cat_order, {'Summary'}]));
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

    if strcmp(cat,'Summary')
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
