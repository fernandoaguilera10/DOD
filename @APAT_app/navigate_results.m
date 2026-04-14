function navigate_results(app, action, varargin)
%NAVIGATE_RESULTS  All Results-tab navigation and setup-tab measure highlighting.
%
%   navigate_results(app, 'ind')                    — switch to Individual mode
%   navigate_results(app, 'avg')                    — switch to Average mode
%   navigate_results(app, 'meas_btn', idx)          — Results-tab measure button #idx
%   navigate_results(app, 'subj')                   — subject dropdown changed
%   navigate_results(app, 'freq')                   — freq dropdown changed
%   navigate_results(app, 'measures')               — refresh setup-tab measure buttons
%   navigate_results(app, 'after_ind_embed', mi, s) — post-embed: show ind panel
%   navigate_results(app, 'after_avg_embed', mi)    — post-embed: show avg panel
%   navigate_results(app, 'cond_tab', mi, s)        — ABR Peaks condition tab changed
%   navigate_results(app, 'filter_ind')             — apply individual freq filter
%   navigate_results(app, 'filter_avg')             — apply average freq filter
%   navigate_results(app, 'reset_dds')              — reset and re-populate FigFreqDD

switch action
    case 'ind',             do_ind(app);
    case 'avg',             do_avg(app);
    case 'meas_btn',        do_meas_btn(app, varargin{1});
    case 'subj',            do_subj(app);
    case 'freq',            do_freq(app);
    case 'measures',        do_measures(app);
    case 'after_ind_embed', do_after_ind_embed(app, varargin{1}, varargin{2});
    case 'after_avg_embed', do_after_avg_embed(app, varargin{1});
    case 'cond_tab',        do_cond_tab(app, varargin{1}, varargin{2});
    case 'filter_ind',      do_filter_ind(app);
    case 'filter_avg',      do_filter_avg(app);
    case 'reset_dds',       do_reset_dds(app);
end
end


% ─────────────────────────────────────────────────────────────────────
%  MODE CALLBACKS
% ─────────────────────────────────────────────────────────────────────

function do_ind(app)
app.FigIndBtn.Value = true;   app.FigAvgBtn.Value = false;
app.FigIndBtn.BackgroundColor = app.clr_gold;
app.FigAvgBtn.BackgroundColor = app.clr_btn;
app.FigSubjDropdown.Visible   = 'on';
switch_panel(app, 1, app.res.meas_idx);
subj = app.FigSubjDropdown.Value;
if ~strcmp(subj,'-')
    do_update_dds(app, app.res.meas_idx, subj);
    do_filter_ind(app);
end
end

function do_avg(app)
app.FigAvgBtn.Value = true;   app.FigIndBtn.Value = false;
app.FigAvgBtn.BackgroundColor = app.clr_gold;
app.FigIndBtn.BackgroundColor = app.clr_btn;
app.FigSubjDropdown.Visible   = 'off';
switch_panel(app, 2, app.res.meas_idx);
set_freq_visible(app, app.res.meas_idx);
sync_avg_freq(app, app.res.meas_idx);
do_filter_avg(app);
end


% ─────────────────────────────────────────────────────────────────────
%  RESULTS-TAB MEASURE BUTTON
% ─────────────────────────────────────────────────────────────────────

function do_meas_btn(app, idx)
for k = 1:numel(app.res.btns)
    if isvalid(app.res.btns(k))
        app.res.btns(k).BackgroundColor = ternary(k==idx, app.clr_gold, app.clr_btn);
    end
end
switch_panel(app, app.res.mode, idx);
set_freq_visible(app, idx);
refresh_subj_dd(app, idx);
do_reset_dds(app);
if app.res.mode == 1
    subj = app.FigSubjDropdown.Value;
    if ~strcmp(subj,'-'), do_update_dds(app, idx, subj); do_filter_ind(app); end
else
    sync_avg_freq(app, idx);
    do_filter_avg(app);
end
end


% ─────────────────────────────────────────────────────────────────────
%  DROPDOWN CALLBACKS
% ─────────────────────────────────────────────────────────────────────

function do_subj(app)
data = app.res.subj_data{app.res.meas_idx};
if isempty(data.names), return; end
subj = app.FigSubjDropdown.Value;
if strcmp(subj,'-'), return; end
si = find(strcmp(data.names, subj), 1);
if isempty(si), return; end
for k = 1:numel(data.panels)
    if isvalid(data.panels{k}), data.panels{k}.Visible = 'off'; end
end
if isvalid(data.panels{si}), data.panels{si}.Visible = 'on'; end
do_update_dds(app, app.res.meas_idx, subj);
do_filter_ind(app);
end

function do_freq(app)
do_filter_ind(app);
if app.res.mode == 2, do_filter_avg(app); end
end

function do_cond_tab(app, meas_idx, subject)
do_update_dds(app, meas_idx, subject);
do_filter_ind(app);
end


% ─────────────────────────────────────────────────────────────────────
%  SETUP-TAB MEASURE BUTTON REFRESH  (replaces refreshMeasureButtons)
% ─────────────────────────────────────────────────────────────────────

function do_measures(app)
if isempty(app.h_meas_btns) || ~any(isvalid(app.h_meas_btns)), return; end
m      = app.state.measure_idx;
k      = app.state.subtype_idx;
COMB_H = app.layout_meas_h;

% Highlight selected measure; show/hide subtype buttons
for mi = 1:app.n_meas
    if ~isvalid(app.h_meas_btns(mi)), continue; end
    app.h_meas_btns(mi).BackgroundColor = ternary(mi==m, app.clr_gold, app.clr_btn);
    for ki = 1:numel(app.MEASURES(mi).subtypes)
        if ~isvalid(app.h_sub_btns{mi}(ki)), continue; end
        if mi == m
            app.h_sub_btns{mi}(ki).Visible = 'on';
            if ki == k
                app.h_sub_btns{mi}(ki).BackgroundColor = app.clr_gold_dk;
                app.h_sub_btns{mi}(ki).FontColor = [1 1 1];
            else
                app.h_sub_btns{mi}(ki).BackgroundColor = app.clr_btn;
                app.h_sub_btns{mi}(ki).FontColor = app.clr_black;
            end
        else
            app.h_sub_btns{mi}(ki).Visible = 'off';
        end
    end
end

% Description label positioning
subs     = app.MEASURES(m).subtypes;
PAD      = 8;  panel_w = app.MeasuresPanel.Position(3);
sub_end  = app.meas_sub_area_start;
if ~isempty(subs) && ~isempty(app.h_sub_btns{m})
    last_valid = find(isvalid(app.h_sub_btns{m}), 1, 'last');
    if ~isempty(last_valid)
        lp = app.h_sub_btns{m}(last_valid).Position;
        sub_end = lp(1) + lp(3);
    end
end
DESC_GAP = 12;  DESC_W = max(200, round(panel_w * 0.20));
DESC_X   = sub_end + DESC_GAP;
ABR_X    = DESC_X + DESC_W + DESC_GAP;
ABR_W    = max(300, panel_w - ABR_X - PAD);

y_sel     = 0.99 - m*(app.meas_h + app.meas_gap) + app.meas_gap;
btn_top_y = round((y_sel + app.meas_h) * COMB_H);
btn_bot_y = round(y_sel * COMB_H);
title_h   = 22;
body_bot  = max(6, btn_bot_y - 4);
body_h    = max(20, btn_top_y - title_h - body_bot - 6);
title_y   = body_bot + body_h + 4;
if ~isempty(subs)
    app.DescTitleLabel.Text = sprintf('%s (%s): %s', app.MEASURES(m).label, app.MEASURES(m).name, subs{k});
else
    app.DescTitleLabel.Text = sprintf('%s (%s)', app.MEASURES(m).label, app.MEASURES(m).name);
end
app.DescLabel.Text = app.MEASURES(m).descriptions{k};
app.DescTitleLabel.Position = [DESC_X title_y DESC_W title_h];
app.DescLabel.Position      = [DESC_X body_bot DESC_W body_h];

% Show only the parameter panel for the selected measure
is_abr  = (m==1);  is_efr = (m==2);  is_oae = (m==3);  is_memr = (m==4);
is_peaks = is_abr && (k==2);
update_param_panels(app, is_abr, is_efr, is_oae, is_memr, is_peaks, ABR_X, ABR_W);
end


% ─────────────────────────────────────────────────────────────────────
%  POST-EMBED PANEL ROUTING
% ─────────────────────────────────────────────────────────────────────

function do_after_ind_embed(app, meas_idx, subject)
% Highlight this measure's Results button
for k = 1:numel(app.res.btns)
    if isvalid(app.res.btns(k))
        app.res.btns(k).BackgroundColor = ternary(k==meas_idx, app.clr_gold, app.clr_btn);
    end
end
switch_panel(app, 1, meas_idx);
app.FigIndBtn.Value = true;  app.FigAvgBtn.Value = false;
app.FigIndBtn.BackgroundColor = app.clr_gold;
app.FigAvgBtn.BackgroundColor = app.clr_btn;
app.FigSubjDropdown.Visible   = 'on';
% Populate subject dropdown
data = app.res.subj_data{meas_idx};
if isempty(data.names)
    app.FigSubjDropdown.Items = {'-'};
    app.FigSubjDropdown.Value = '-';
else
    app.FigSubjDropdown.Items = data.names(:)';
    if ~isempty(subject) && any(strcmp(data.names, subject))
        app.FigSubjDropdown.Value = subject;
    elseif ~any(strcmp(data.names, app.FigSubjDropdown.Value))
        app.FigSubjDropdown.Value = data.names{1};
    end
end
set_freq_visible(app, meas_idx);
if ~isempty(subject)
    do_update_dds(app, meas_idx, subject);
    do_filter_ind(app);
end
end

function do_after_avg_embed(app, meas_idx)
for k = 1:numel(app.res.btns)
    if isvalid(app.res.btns(k))
        app.res.btns(k).BackgroundColor = ternary(k==meas_idx, app.clr_gold, app.clr_btn);
    end
end
switch_panel(app, 2, meas_idx);
app.FigAvgBtn.Value = true;  app.FigIndBtn.Value = false;
app.FigAvgBtn.BackgroundColor = app.clr_gold;
app.FigIndBtn.BackgroundColor = app.clr_btn;
app.FigSubjDropdown.Visible   = 'off';
set_freq_visible(app, meas_idx);
end


% ─────────────────────────────────────────────────────────────────────
%  FILTERING  (replaces apply_filter + apply_avg_filter)
% ─────────────────────────────────────────────────────────────────────

function do_filter_ind(app)
meas_idx = app.res.meas_idx;
data     = app.res.subj_data{meas_idx};
if isempty(data.names), return; end
subj = app.FigSubjDropdown.Value;
if strcmp(subj,'-'), return; end
si = find(strcmp(data.names, subj), 1);
if isempty(si), return; end
sp = data.panels{si};

freq_filter = get_freq_filter(app);
titled_ps   = collect_titled_panels(sp);

% Condition tabgroup (ABR Peaks multi-condition individual)
if isempty(titled_ps)
    for chk = sp.Children(:)'
        if isa(chk,'matlab.ui.container.TabGroup') && ~isempty(chk.Children)
            active = chk.SelectedTab;
            for chk2 = active.Children(:)'
                if isa(chk2,'matlab.ui.container.Panel')
                    for chk3 = chk2.Children(:)'
                        if isa(chk3,'matlab.ui.container.Panel') && ...
                                (~isempty(chk3.Tag) || ~isempty(chk3.Title))
                            titled_ps{end+1} = chk3; %#ok<AGROW>
                        end
                    end
                end
            end
        end
    end
end
if isempty(titled_ps), return; end

apply_stacked_or_grid_filter(app, titled_ps, freq_filter);
end

function do_filter_avg(app)
meas_idx    = app.res.meas_idx;
avg_panel   = app.res.panels{2, meas_idx};
if ~isvalid(avg_panel) || isempty(avg_panel.Children), return; end
sync_avg_freq(app, meas_idx);  % Restore labels after measure switch

freq_filter = get_freq_filter(app);

tg = [];
for ch = avg_panel.Children(:)'
    if isa(ch,'matlab.ui.container.TabGroup'), tg = ch; break; end
end
if isempty(tg), return; end

actual_tag = '';
for ti = 1:numel(tg.Children)
    tab = tg.Children(ti);
    tab_panel = [];
    for ch = tab.Children(:)'
        if isa(ch,'matlab.ui.container.Panel'), tab_panel = ch; break; end
    end
    if isempty(tab_panel), continue; end

    freq_panels = {};
    for ch = tab_panel.Children(:)'
        if isa(ch,'matlab.ui.container.Panel') && ~isempty(ch.Tag)
            freq_panels{end+1} = ch; %#ok<AGROW>
        end
    end
    if isempty(freq_panels), continue; end

    first_p = freq_panels{end};  % MATLAB Children are reverse creation order
    matched = false;
    for i = 1:numel(freq_panels)
        p = freq_panels{i};
        if isempty(freq_filter)
            p.Visible = ternary(p==first_p, 'on', 'off');
        else
            hits = strcmpi(p.Tag, freq_filter);
            p.Visible = ternary(hits, 'on', 'off');
            if hits, matched = true; end
        end
    end
    if ~isempty(freq_filter) && ~matched, first_p.Visible = 'on'; end
    if isempty(actual_tag)
        actual_tag = ternary(matched, freq_filter, first_p.Tag);
    end
end

if ~isempty(actual_tag) && strcmp(app.FigFreqDD.Visible,'on') && ...
        ~strcmp(app.FigFreqDD.Value, actual_tag) && ...
        any(strcmp(app.FigFreqDD.Items, actual_tag))
    app.FigFreqDD.Value = actual_tag;
end
end


% ─────────────────────────────────────────────────────────────────────
%  DROPDOWN HELPERS
% ─────────────────────────────────────────────────────────────────────

function do_reset_dds(app)
app.FigFreqDD.Items = {'—'}; app.FigFreqDD.Value = '—';
end

function do_update_dds(app, meas_idx, subject)
%DO_UPDATE_DDS  Populate FigFreqDD from embedded figure panels for this subject.
si = find(strcmp(app.res.subj_data{meas_idx}.names, subject), 1);
if isempty(si), return; end
sp = app.res.subj_data{meas_idx}.panels{si};

lbl_f = findall(app.UIFigure,'Tag','fig_freq_lbl');

titles = {};
% Direct child panels (stacked or grid)
for chk = sp.Children(:)'
    if isa(chk,'matlab.ui.container.Panel')
        lbl = chk.Tag; if isempty(lbl), lbl = chk.Title; end
        if ~isempty(lbl), titles{end+1} = lbl; end %#ok<AGROW>
    end
end
% One level deeper (scroll container)
if isempty(titles)
    for chk = sp.Children(:)'
        if isa(chk,'matlab.ui.container.Panel')
            for chk2 = chk.Children(:)'
                if isa(chk2,'matlab.ui.container.Panel')
                    lbl = chk2.Tag; if isempty(lbl), lbl = chk2.Title; end
                    if ~isempty(lbl), titles{end+1} = lbl; end %#ok<AGROW>
                end
            end
        end
    end
end
% Tabgroup: two layouts are possible.
%   Category layout (ABR Thresholds): tabs = 'ABR Waveforms','Sigmoid Fits','Summary';
%     freq_p panels inside each tab are CONDITIONS.
%     → collect from ALL non-Summary tabs; hide dropdown when Summary is active.
%   Condition layout (ABR Peaks): tabs = condition names; freq_p = frequencies.
%     → collect from the active tab only (existing behaviour).
if isempty(titles)
    cat_tab_names = {'Waveforms','Amplitudes','Latencies','ABR Waveforms','Sigmoid Fits','Summary'};
    for chk = sp.Children(:)'
        if ~isa(chk,'matlab.ui.container.TabGroup') || isempty(chk.Children), continue; end
        tab_titles = arrayfun(@(t) t.Title, chk.Children, 'UniformOutput', false);
        is_cat_tg  = any(ismember(tab_titles, cat_tab_names));

        if is_cat_tg
            % Category tabs: hide dropdown when Summary is selected
            if strcmp(chk.SelectedTab.Title, 'Summary')
                app.FigFreqDD.Visible = 'off';
                if ~isempty(lbl_f), lbl_f.Visible = 'off'; end
                return;
            end
            % Collect condition labels from ALL non-Summary tabs
            for tab = chk.Children(:)'
                if strcmp(tab.Title, 'Summary'), continue; end
                for chk2 = tab.Children(:)'
                    if isa(chk2,'matlab.ui.container.Panel')
                        for chk3 = chk2.Children(:)'
                            if isa(chk3,'matlab.ui.container.Panel')
                                lbl = chk3.Tag; if isempty(lbl), lbl = chk3.Title; end
                                if ~isempty(lbl) && ~any(strcmp(titles, lbl))
                                    titles{end+1} = lbl; %#ok<AGROW>
                                end
                            end
                        end
                    end
                end
            end
        else
            % Condition tabs (ABR Peaks): collect frequencies from active tab only
            active = chk.SelectedTab;
            for chk2 = active.Children(:)'
                if isa(chk2,'matlab.ui.container.Panel')
                    for chk3 = chk2.Children(:)'
                        if isa(chk3,'matlab.ui.container.Panel')
                            lbl = chk3.Tag; if isempty(lbl), lbl = chk3.Title; end
                            if ~isempty(lbl), titles{end+1} = lbl; end %#ok<AGROW>
                        end
                    end
                end
            end
        end
        break;  % only one tabgroup per sp
    end
end

titles = unique(titles,'stable');
if isempty(titles), return; end

% Sort to match Setup tab condition order (last path component of conds_all)
if ~isempty(app.state) && isfield(app.state,'conds_all') && ~isempty(app.state.conds_all)
    cend = cellfun(@(c) strsplit(c,filesep), app.state.conds_all, 'UniformOutput',false);
    cend = cellfun(@(c) c{end}, cend, 'UniformOutput',false);
    ordered = cend(ismember(cend, titles));
    if numel(ordered) == numel(titles)
        titles = ordered(:)';
    end
end

app.FigFreqDD.Items = titles(:)';
if ~any(strcmp(titles, app.FigFreqDD.Value)), app.FigFreqDD.Value = titles{1}; end

is_freq = any(cellfun(@(t) ~isempty(regexp(t,'\d+\s*(k?Hz|click)','once','ignorecase')), titles));
if ~isempty(lbl_f)
    lbl_f.Text    = ternary(is_freq, 'Freq:', 'Cond:');
    lbl_f.Visible = 'on';
end
app.FigFreqDD.Visible = 'on';
end

function sync_avg_freq(app, meas_idx)
%SYNC_AVG_FREQ  Merge freq labels from avg tabgroup into FigFreqDD.
if meas_idx ~= 2 || isempty(app.res.panels), return; end
avg_panel = app.res.panels{2, meas_idx};
if ~isvalid(avg_panel), return; end

tg = [];
for ch = avg_panel.Children(:)'
    if isa(ch,'matlab.ui.container.TabGroup'), tg = ch; break; end
end
if isempty(tg), return; end

tab_freqs = {};
for ti = 1:numel(tg.Children)
    tab = tg.Children(ti);
    for ch = tab.Children(:)'
        if isa(ch,'matlab.ui.container.Panel')
            for ch2 = ch.Children(:)'
                if isa(ch2,'matlab.ui.container.Panel') && ~isempty(ch2.Tag)
                    if ~any(strcmp(tab_freqs, ch2.Tag))
                        tab_freqs{end+1} = ch2.Tag; %#ok<AGROW>
                    end
                end
            end
        end
    end
end

if ~isempty(tab_freqs)
    existing  = app.FigFreqDD.Items;
    existing  = existing(~strcmp(existing,'—'));
    new_items = tab_freqs(~ismember(tab_freqs, existing));
    merged    = [existing, new_items];
    if ~isempty(merged) && ~isequal(merged, app.FigFreqDD.Items)
        app.FigFreqDD.Items = merged;
        if ~any(strcmp(merged, app.FigFreqDD.Value))
            app.FigFreqDD.Value = merged{1};
        end
    end
end
end

function refresh_subj_dd(app, meas_idx)
data = app.res.subj_data{meas_idx};
if isempty(data.names)
    app.FigSubjDropdown.Items = {'-'};
    app.FigSubjDropdown.Value = '-'; return;
end
items = data.names(:)';
app.FigSubjDropdown.Items = items;
if ~any(strcmp(items, app.FigSubjDropdown.Value))
    app.FigSubjDropdown.Value = items{1};
end
end


% ─────────────────────────────────────────────────────────────────────
%  LOW-LEVEL HELPERS
% ─────────────────────────────────────────────────────────────────────

function switch_panel(app, mode, meas_idx)
if ~isempty(app.res.panels)
    app.res.panels{app.res.mode, app.res.meas_idx}.Visible = 'off';
end
app.res.mode     = mode;
app.res.meas_idx = meas_idx;
app.res.panels{mode, meas_idx}.Visible = 'on';
end

function set_freq_visible(app, meas_idx)
show = meas_idx == 2;   % only ABR Peaks uses the freq dropdown
fv   = ternary(show, 'on', 'off');
app.FigFreqDD.Visible = fv;
lbl = findall(app.UIFigure,'Tag','fig_freq_lbl');
if ~isempty(lbl), lbl.Visible = fv; end
end

function freq_filter = get_freq_filter(app)
freq_filter = '';
if strcmp(app.FigFreqDD.Visible,'on') && ~strcmp(app.FigFreqDD.Value,'—')
    freq_filter = app.FigFreqDD.Value;
end
end

function apply_stacked_or_grid_filter(app, titled_ps, freq_filter)
is_stacked = numel(titled_ps) > 1 && ...
    all(cellfun(@(p) p.Position(1), titled_ps) == titled_ps{1}.Position(1)) && ...
    all(cellfun(@(p) p.Position(2), titled_ps) == titled_ps{1}.Position(2));

if is_stacked
    first_p = titled_ps{end};  % MATLAB Children are reverse creation order
    matched = false;
    for i = 1:numel(titled_ps)
        p = titled_ps{i};
        if isempty(freq_filter)
            p.Visible = ternary(p==first_p, 'on', 'off');
        else
            hits = strcmpi(p.Tag, freq_filter);
            p.Visible = ternary(hits, 'on', 'off');
            if hits, matched = true; end
        end
    end
    if ~isempty(freq_filter) && ~matched, first_p.Visible = 'on'; end
    % Sync dropdown to what is actually visible
    if strcmp(app.FigFreqDD.Visible,'on')
        actual = ternary(matched, freq_filter, first_p.Tag);
        if ~isempty(actual) && any(strcmp(app.FigFreqDD.Items, actual)) && ...
                ~strcmp(app.FigFreqDD.Value, actual)
            app.FigFreqDD.Value = actual;
        end
    end
else
    % Grid: show all or filter by tag/title.
    % freq_p panels from embed_categorized_tabs use Tag=label, Title=''.
    % Older grid panels (2-col scrollable) use Title=label, Tag=''.
    % Always prefer Tag when non-empty so both layouts are handled.
    for i = 1:numel(titled_ps)
        p = titled_ps{i};
        if isempty(freq_filter)
            p.Visible = 'on';
        else
            lbl = p.Tag; if isempty(lbl), lbl = p.Title; end
            p.Visible = ternary(strcmpi(lbl, freq_filter), 'on', 'off');
        end
    end
end
end

function titled_ps = collect_titled_panels(sp)
titled_ps = {};
for chk = sp.Children(:)'
    if isa(chk,'matlab.ui.container.Panel') && (~isempty(chk.Tag) || ~isempty(chk.Title))
        titled_ps{end+1} = chk; %#ok<AGROW>
    end
end
if isempty(titled_ps)
    for chk = sp.Children(:)'
        if isa(chk,'matlab.ui.container.Panel')
            for chk2 = chk.Children(:)'
                if isa(chk2,'matlab.ui.container.Panel') && ...
                        (~isempty(chk2.Tag) || ~isempty(chk2.Title))
                    titled_ps{end+1} = chk2; %#ok<AGROW>
                end
            end
        end
    end
end
end

function update_param_panels(app, is_abr, is_efr, is_oae, is_memr, is_peaks, ABR_X, ABR_W)
if ~isempty(app.h_abr_param_panel) && isvalid(app.h_abr_param_panel)
    if is_abr
        old = app.h_abr_param_panel.Position;
        app.h_abr_param_panel.Position = [ABR_X old(2) ABR_W old(4)];
    end
    app.h_abr_param_panel.Visible = ternary(is_abr, 'on', 'off');
    lev_vis = ternary(is_peaks, 'on', 'off');
    for tag = {'abr_lev_lbl','abr_wave_lbl'}
        h = findall(app.h_abr_param_panel,'Tag',tag{1});
        if ~isempty(h), h.Visible = lev_vis; end
    end
    for li = 1:numel(app.h_abr_level_checks)
        if isvalid(app.h_abr_level_checks(li))
            app.h_abr_level_checks(li).Visible = lev_vis;
        end
    end
    for wi = 1:numel(app.h_abr_wave_checks)
        if isvalid(app.h_abr_wave_checks(wi))
            app.h_abr_wave_checks(wi).Visible = lev_vis;
        end
    end
end
if ~isempty(app.h_efr_param_panel) && isvalid(app.h_efr_param_panel)
    if is_efr
        old = app.h_efr_param_panel.Position;
        app.h_efr_param_panel.Position = [ABR_X old(2) ABR_W old(4)];
    end
    app.h_efr_param_panel.Visible = ternary(is_efr, 'on', 'off');
    ram_vis = ternary(is_efr && (app.state.subtype_idx==2), 'on', 'off');
    for tag = {'efr_ram_hdr','efr_ram_info','efr_harm_lbl','efr_win_lbl', ...
               'efr_win_s_lbl','efr_win_e_lbl','efr_harmonics','efr_win_start','efr_win_end'}
        h = findall(app.h_efr_param_panel,'Tag',tag{1});
        if ~isempty(h), h.Visible = ram_vis; end
    end
    for fld = {'h_efr_harmonics_field','h_efr_window_start_field','h_efr_window_end_field'}
        if ~isempty(app.(fld{1})) && isvalid(app.(fld{1}))
            app.(fld{1}).Visible = ram_vis;
        end
    end
end
if ~isempty(app.h_oae_param_panel) && isvalid(app.h_oae_param_panel)
    if is_oae
        old = app.h_oae_param_panel.Position;
        app.h_oae_param_panel.Position = [ABR_X old(2) ABR_W old(4)];
    end
    app.h_oae_param_panel.Visible = ternary(is_oae, 'on', 'off');
end
if ~isempty(app.h_memr_param_panel) && isvalid(app.h_memr_param_panel)
    if is_memr
        old = app.h_memr_param_panel.Position;
        app.h_memr_param_panel.Position = [ABR_X old(2) ABR_W old(4)];
    end
    app.h_memr_param_panel.Visible = ternary(is_memr, 'on', 'off');
end
end
