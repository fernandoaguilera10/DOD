function roster_builder(app)
%ROSTER_BUILDER  Window to create or edit the subject roster workbook in APAT.
%   roster_builder(app) opens a separate "Subject Roster" window. The roster
%   is written to <ROOT>/Analysis/<name>.xlsx, one sheet per experiment, in
%   the exact layout read by read_chinroster_sheet and analysis_run:
%     row 1   'Subject','Sex','ABR','',..,'EFR','',..,'WB-MEMR','',..,'Notes'
%     row 2   '',''  then the condition names repeated for each measure block
%     rows 3+ subject ID, sex, 'X' (recorded) / '' per measure x condition, notes
%   All callbacks are nested functions of this file (anonymous callbacks that
%   name a private function fail when they fire).

MEAS = {'ABR','EFR','DPOAE','SFOAE','TEOAE','WB-MEMR'};
NM   = numel(MEAS);
SEXES = {'M','F','?'};
FS   = 13;
W = 1150;  H = 700;

% ── Defaults from the app ────────────────────────────────────────────
root = '';
try, root = strtrim(app.RootDirField.Value); catch, end
fname = 'Roster.xlsx';
try
    v0 = app.RosterDropdown.Value;
    if ischar(v0) && ~isempty(v0) && v0(1) ~= '(', fname = v0; end
catch
end
sheet = 'Experiment1';
try
    s0 = sheet_sel(app, 'on_screen');
    if ischar(s0) && ~isempty(strtrim(s0)), sheet = strtrim(s0); end
catch
end

conds = {'Baseline'};            % applied conditions (table columns)

% ── Window ────────────────────────────────────────────────────────────
pos = [100 100 W H];
try
    ap  = app.UIFigure.Position;
    pos = [ap(1) + (ap(3)-W)/2, ap(2) + (ap(4)-H)/2, W, H];
    pos(1:2) = max(pos(1:2), [20 40]);
catch
end
fig = uifigure('Name','Subject Roster','Position',round(pos), ...
    'Color',app.clr_bg,'Resize','off');

uilabel(fig,'Position',[16 H-34 W-32 24],'FontSize',FS,'FontColor',[0.42 0.42 0.42], ...
    'Text',['Each row is a subject. Each measure has one column per condition — ', ...
            'tick a box when data were recorded for that measure and condition.']);

% ── Location panel ───────────────────────────────────────────────────
locP = uipanel(fig,'Title','Roster file','FontSize',FS,'FontWeight','bold', ...
    'BackgroundColor',app.clr_panel,'Position',[16 H-136 W-32 96]);
style_panel(locP);
uilabel(locP,'Text','Root folder:','FontSize',FS,'Position',[10 42 100 22]);
rootLbl = uilabel(locP,'Text',root_text(),'FontSize',FS,'FontWeight','bold', ...
    'Position',[112 42 760 22]);
uibutton(locP,'push','Text','Browse…','FontSize',FS, ...
    'BackgroundColor',app.clr_btn,'Position',[880 42 100 24], ...
    'Tooltip','Choose the project root folder (also sets it in APAT)', ...
    'Visible',onoff(isempty(root)),'ButtonPushedFcn',@on_browse);
uilabel(locP,'Text','File name:','FontSize',FS,'Position',[10 10 100 22]);
fileFld = uieditfield(locP,'text','Value',fname,'FontSize',FS, ...
    'BackgroundColor','white','Position',[112 10 300 24], ...
    'Tooltip','Saved in <root>/Analysis/ (always .xlsx)', ...
    'ValueChangedFcn',@on_file_changed);
uilabel(locP,'Text','Experiment (sheet):','FontSize',FS,'Position',[430 10 135 22]);
sheetFld = uieditfield(locP,'text','Value',sheet,'FontSize',FS, ...
    'BackgroundColor','white','Position',[568 10 200 24], ...
    'Tooltip','One sheet per experiment, e.g. NOISE');
uibutton(locP,'push','Text','Load existing','FontSize',FS, ...
    'BackgroundColor',app.clr_btn,'Position',[784 10 130 24], ...
    'Tooltip','Read this file and sheet into the editor', ...
    'ButtonPushedFcn',@on_load);

% ── Conditions row ───────────────────────────────────────────────────
condP = uipanel(fig,'BorderType','line','BackgroundColor',app.clr_panel, ...
    'Position',[16 H-186 W-32 42]);
style_panel(condP);
uilabel(condP,'Text','Conditions (in order, comma-separated):','FontSize',FS, ...
    'FontWeight','bold','Position',[10 9 270 22]);
condFld = uieditfield(condP,'text','Value',strjoin(conds,', '),'FontSize',FS, ...
    'BackgroundColor','white','Position',[284 8 620 26], ...
    'Tooltip','e.g. Baseline, D7, D14, D30 — the first must be Baseline');
uibutton(condP,'push','Text','Apply','FontSize',FS,'BackgroundColor',app.clr_btn, ...
    'Position',[912 8 90 26],'Tooltip','Rebuild the table columns (marks kept for unchanged names)', ...
    'ButtonPushedFcn',@on_apply);

% ── Table ─────────────────────────────────────────────────────────────
TBL_Y = 112;
tbl = uitable(fig,'Position',[16 TBL_Y W-32 H-196-TBL_Y],'FontSize',FS-1, ...
    'RowName',{},'SelectionType','row','Multiselect','on', ...
    'CellEditCallback',@on_cell_edit);

% ── Row buttons ───────────────────────────────────────────────────────
BY = 72;  BH = 28;
uibutton(fig,'push','Text','+ Add subject','FontSize',FS,'BackgroundColor',app.clr_btn, ...
    'Position',[16 BY 120 BH],'ButtonPushedFcn',@on_add_one);
rngP = uipanel(fig,'BorderType','line','BackgroundColor',app.clr_panel, ...
    'Position',[146 BY-3 396 BH+6]);
style_panel(rngP);
uilabel(rngP,'Text','Add range:','FontSize',FS,'Position',[6 6 74 22]);
uilabel(rngP,'Text','Prefix','FontSize',FS-1,'Position',[80 6 40 22]);
preFld = uieditfield(rngP,'text','Value','Q','FontSize',FS,'BackgroundColor','white', ...
    'Position',[120 5 44 24]);
uilabel(rngP,'Text','From','FontSize',FS-1,'Position',[170 6 34 22]);
fromFld = uieditfield(rngP,'numeric','Value',1,'FontSize',FS,'BackgroundColor','white', ...
    'Limits',[0 Inf],'RoundFractionalValues','on','Position',[204 5 54 24]);
uilabel(rngP,'Text','To','FontSize',FS-1,'Position',[264 6 20 22]);
toFld = uieditfield(rngP,'numeric','Value',1,'FontSize',FS,'BackgroundColor','white', ...
    'Limits',[0 Inf],'RoundFractionalValues','on','Position',[284 5 54 24]);
uibutton(rngP,'push','Text','Add','FontSize',FS,'BackgroundColor',app.clr_btn, ...
    'Position',[344 5 46 24],'Tooltip','e.g. Q, 438, 445 adds Q438 … Q445 (existing IDs skipped)', ...
    'ButtonPushedFcn',@on_add_range);
uibutton(fig,'push','Text','Remove selected','FontSize',FS,'BackgroundColor',app.clr_btn, ...
    'Position',[554 BY 140 BH],'Tooltip','Remove the selected subject rows', ...
    'ButtonPushedFcn',@on_remove);
uibutton(fig,'push','Text','Mark all recorded','FontSize',FS,'BackgroundColor',app.clr_btn, ...
    'Position',[704 BY 150 BH], ...
    'Tooltip','Tick every measure × condition for the selected rows (all rows if none selected)', ...
    'ButtonPushedFcn',@on_mark_all);
uibutton(fig,'push','Text','Clear marks','FontSize',FS,'BackgroundColor',app.clr_btn, ...
    'Position',[864 BY 120 BH], ...
    'Tooltip','Untick every measure × condition for the selected rows (all rows if none selected)', ...
    'ButtonPushedFcn',@on_clear_marks);

% ── Bottom row ────────────────────────────────────────────────────────
dataChk = uicheckbox(fig,'Text','Also create Data/ and Data/RAW folders','FontSize',FS, ...
    'Position',[16 20 360 24],'Value',true);
uibutton(fig,'push','Text','Cancel','FontSize',FS,'BackgroundColor',app.clr_btn, ...
    'Position',[W-16-140-10-110 18 110 32],'ButtonPushedFcn',@on_cancel);
uibutton(fig,'push','Text','Save roster','FontSize',FS+1,'FontWeight','bold', ...
    'BackgroundColor',app.clr_gold,'FontColor',app.clr_black, ...
    'Position',[W-16-140 18 140 32],'ButtonPushedFcn',@on_save);
update_data_chk();

% ── Initial content ───────────────────────────────────────────────────
set_table(cell(0, 3 + NM*numel(conds)));
loaded = false;
fp0 = roster_path();
if ~isempty(fp0) && exist(fp0,'file')
    try
        if any(strcmp(cellstr(sheetnames(fp0)), sheet))
            loaded = load_sheet(fp0, sheet, false);
        end
    catch
    end
end
if ~loaded
    conds = {'Baseline'};
    condFld.Value = 'Baseline';
    set_table(empty_row());
end


% ═════════════════════════════════════════════════════════════════════
%  Nested helpers
% ═════════════════════════════════════════════════════════════════════

    function style_panel(p)
        if isprop(p,'BorderColor'), p.BorderColor = app.clr_gold; end
    end

    function s = onoff(tf)
        if tf, s = 'on'; else, s = 'off'; end
    end

    function t = root_text()
        if isempty(root), t = '(not set — choose a project folder)';
        else, t = root; end
    end

    function ok = alive()
        ok = ~isempty(fig) && isvalid(fig);
    end

    function msg(txt, ttl, icon)
        if nargin < 3, icon = 'warning'; end
        if alive(), uialert(fig, txt, ttl, 'Icon', icon); end
    end

    function n = clean_fname()
        n = strtrim(fileFld.Value);
        [~, b, ~] = fileparts(n);
        n = b;
        if ~isempty(n), n = [n '.xlsx']; end
    end

    function fp = roster_path()
        fp = '';
        n  = clean_fname();
        if isempty(root) || isempty(n), return; end
        fp = apat_paths(fullfile(root, 'Analysis'), 'roster', n);   % Analysis/Roster
    end

    function update_data_chk()
        missing = ~isempty(root) && ~exist(fullfile(root,'Data'),'dir');
        dataChk.Enable = onoff(missing);
        dataChk.Value  = missing;
        if isempty(root)
            dataChk.Tooltip = 'Choose a root folder first';
        elseif missing
            dataChk.Tooltip = 'The Data folder does not exist yet in the root folder';
        else
            dataChk.Tooltip = 'Data folder already exists';
        end
    end

    % ── Table model ─────────────────────────────────────────────────
    %  Columns: 1 Subject | 2 Sex | 3 .. 2+NM*nc checkboxes (measure-major,
    %  same order as the file) | last Notes
    function r = empty_row()
        r = [{'', '?'}, num2cell(false(1, NM*numel(conds))), {''}];
    end

    function set_table(D)
        nc    = numel(conds);
        names = cell(1, 3 + NM*nc);
        fmt   = cell(1, 3 + NM*nc);
        wid   = cell(1, 3 + NM*nc);
        names{1} = 'Subject';  fmt{1} = 'char';    wid{1} = 90;
        names{2} = 'Sex';      fmt{2} = SEXES;     wid{2} = 60;
        for m = 1:NM
            for c = 1:nc
                k = 2 + (m-1)*nc + c;
                names{k} = sprintf('%s · %s', MEAS{m}, conds{c});
                fmt{k}   = 'logical';
                wid{k}   = max(80, 8*numel(names{k}) + 14);
            end
        end
        names{end} = 'Notes';  fmt{end} = 'char';  wid{end} = 220;
        tbl.Data           = D;
        tbl.ColumnName     = names;
        tbl.ColumnFormat   = fmt;
        tbl.ColumnWidth    = wid;
        tbl.ColumnEditable = true(1, numel(names));
    end

    function D = get_data()
        D = tbl.Data;
        if isempty(D), D = cell(0, 3 + NM*numel(conds)); end
    end

    function ids = current_ids()
        D = get_data();
        ids = cell(size(D,1), 1);
        for i = 1:size(D,1), ids{i} = strtrim(to_char(D{i,1})); end
    end

    function rows = selected_rows()
        D = get_data();
        rows = [];
        try, rows = tbl.Selection; catch, end
        rows = unique(rows(:)');
        rows = rows(rows >= 1 & rows <= size(D,1));
    end

    % ── Callbacks ───────────────────────────────────────────────────
    function on_browse(~, ~)
        start = pwd;
        if ~isempty(root) && exist(root,'dir'), start = root; end
        d = uigetdir(start, 'Choose the project root folder');
        if alive(), figure(fig); end
        if isequal(d, 0) || ~alive(), return; end
        root = d;
        try, app.RootDirField.Value = d; catch, end
        rootLbl.Text = root_text();
        update_data_chk();
        fp = roster_path();
        if ~isempty(fp) && exist(fp,'file')
            try
                if any(strcmp(cellstr(sheetnames(fp)), strtrim(sheetFld.Value)))
                    load_sheet(fp, strtrim(sheetFld.Value), false);
                end
            catch
            end
        end
    end

    function on_file_changed(~, ~)
        n = clean_fname();
        if ~isempty(n), fileFld.Value = n; end
    end

    function on_load(~, ~)
        fp = roster_path();
        sh = strtrim(sheetFld.Value);
        if isempty(fp)
            msg('Set the root folder and a file name first.', 'Load roster'); return
        end
        if ~exist(fp,'file')
            msg(sprintf('File not found:\n%s', fp), 'Load roster'); return
        end
        try
            shs = cellstr(sheetnames(fp));
        catch err
            msg(sprintf('Could not read the workbook:\n%s', err.message), 'Load roster'); return
        end
        if ~any(strcmp(shs, sh))
            msg(sprintf('Sheet "%s" not found. Sheets in this file: %s', sh, strjoin(shs, ', ')), ...
                'Load roster'); return
        end
        load_sheet(fp, sh, true);
    end

    function ok = load_sheet(fp, sh, verbose)
        ok = false;
        try
            R = readcell(fp, 'Sheet', sh);
        catch err
            if verbose, msg(sprintf('Could not read the sheet:\n%s', err.message), 'Load roster'); end
            return
        end
        miss = cellfun(@(x) any(isa(x,'missing')), R);
        R(miss) = {''};
        [nr, ncl] = size(R);
        % header row = first row with a Baseline cell
        hr = 0;
        for i = 1:nr
            for j = 1:ncl
                if is_marker(R{i,j}), hr = i; break; end
            end
            if hr > 0, break; end
        end
        if hr == 0
            if verbose, msg('No "Baseline" header found in this sheet.', 'Load roster'); end
            return
        end
        bcols = [];
        for j = 1:ncl
            if is_marker(R{hr,j}), bcols(end+1) = j; end %#ok<AGROW>
        end
        if numel(bcols) >= 2
            w = bcols(2) - bcols(1);
        else
            w = 0;
            while bcols(1)+w <= ncl && ~isempty(strtrim(to_char(R{hr,bcols(1)+w}))), w = w + 1; end
        end
        offs = [];  newc = {};
        for k = 0:w-1
            lab = strtrim(to_char(R{hr, bcols(1)+k}));
            if ~isempty(lab), offs(end+1) = k; newc{end+1} = lab; end %#ok<AGROW>
        end
        nc = numel(newc);
        % notes column: a 'Notes' header cell, else the column after the last block
        ncol = 0;
        for i = 1:hr
            for j = 1:ncl
                if strcmpi(strtrim(to_char(R{i,j})), 'Notes'), ncol = j; end
            end
        end
        if ncol == 0, ncol = bcols(end) + w; end
        D = cell(0, 3 + NM*nc);
        for i = 1:nr
            if i == hr, continue; end
            id = R{i,1};
            if ~ischar(id) && ~isstring(id), continue; end
            id = strtrim(char(id));
            if isempty(id) || isempty(regexp(id, '\d', 'once')), continue; end
            sx = upper(strtrim(to_char(R{i,2})));
            if ~isempty(sx) && any(strcmp(sx(1), {'M','F'})), sx = sx(1); else, sx = '?'; end
            mk = false(1, NM*nc);
            for m = 1:min(NM, numel(bcols))
                for c = 1:nc
                    col = bcols(m) + offs(c);
                    if col <= ncl
                        v = R{i,col};
                        mk((m-1)*nc + c) = (ischar(v) || isstring(v)) && strcmpi(strtrim(char(v)), 'x');
                    end
                end
            end
            nt = '';
            if ncol <= ncl, nt = to_char(R{i,ncol}); end
            D(end+1, :) = [{id, sx}, num2cell(mk), {nt}]; %#ok<AGROW>
        end
        conds = newc;
        condFld.Value = strjoin(conds, ', ');
        if isempty(D), D = empty_row(); end
        set_table(D);
        ok = true;
        if verbose && numel(bcols) < NM
            msg(sprintf(['Only %d of the %d measure blocks were found in this sheet; ', ...
                'the missing measures are shown empty and will be added when you save.'], ...
                numel(bcols), NM), 'Load roster', 'info');
        end
    end

    function tf = is_marker(v)
        tf = false;
        if ischar(v) || isstring(v)
            t  = strtrim(char(v));
            tf = strcmpi(t, 'Baseline') || strcmp(t, 'B');
        end
    end

    function on_apply(~, ~)
        apply_conditions();
    end

    function ok = apply_conditions()
        ok = false;
        parts = strtrim(strsplit(condFld.Value, ','));
        parts = parts(~cellfun(@isempty, parts));
        if isempty(parts)
            msg('Enter at least one condition (the first must be Baseline).', 'Conditions'); return
        end
        for k = 1:numel(parts)
            if strcmpi(parts{k}, 'Baseline'), parts{k} = 'Baseline'; end
        end
        note = '';
        if ~any(strcmp(parts{1}, {'Baseline','B'}))
            parts = parts(~strcmp(parts, 'Baseline'));
            parts = [{'Baseline'}, parts];
            note  = 'The first condition must be Baseline, so it was added at the start.';
        end
        if numel(unique(parts)) < numel(parts)
            [u, ~, ic] = unique(parts);
            dup = u(accumarray(ic(:), 1) > 1);
            msg(sprintf('Condition names must be unique. Repeated: %s', strjoin(dup, ', ')), 'Conditions'); return
        end
        later = parts(2:end);
        if any(strcmpi(later, 'Baseline') | strcmp(later, 'B'))
            msg('Only the first condition may be Baseline (or B).', 'Conditions'); return
        end
        bad = parts(~cellfun(@isempty, regexp(parts, '[\\/:*?"<>|]', 'once')));
        if ~isempty(bad)
            msg(sprintf('Condition names are folder names and cannot contain \\ / : * ? " < > |\nCheck: %s', ...
                strjoin(bad, ', ')), 'Conditions'); return
        end
        % remap marks by condition name
        D   = get_data();
        oc  = conds;  onc = numel(oc);  nnc = numel(parts);
        N   = cell(size(D,1), 3 + NM*nnc);
        for i = 1:size(D,1)
            mk = false(1, NM*nnc);
            for m = 1:NM
                for c = 1:nnc
                    k = find(strcmp(oc, parts{c}), 1);
                    if ~isempty(k)
                        mk((m-1)*nnc + c) = is_true(D{i, 2 + (m-1)*onc + k});
                    end
                end
            end
            N(i,:) = [D(i,1:2), num2cell(mk), D(i,end)];
        end
        conds = parts;
        condFld.Value = strjoin(conds, ', ');
        set_table(N);
        ok = true;
        if ~isempty(note), msg(note, 'Conditions', 'info'); end
    end

    function on_cell_edit(~, ev)
        try
            col = ev.Indices(2);
            if col == 1 || col == 3 + NM*numel(conds)
                D = tbl.Data;
                v = D{ev.Indices(1), col};
                if ~ischar(v), D{ev.Indices(1), col} = to_char(v); tbl.Data = D; end
            end
        catch
        end
    end

    function on_add_one(~, ~)
        D = get_data();
        tbl.Data = [D; empty_row()];
        try, scroll(tbl, 'bottom'); catch, end
    end

    function on_add_range(~, ~)
        pre = strtrim(preFld.Value);
        a = fromFld.Value;  b = toFld.Value;
        if b < a
            msg('"To" must be greater than or equal to "From".', 'Add range'); return
        end
        if b - a > 999
            msg('That range is too large (max 1000 subjects at once).', 'Add range'); return
        end
        ids = current_ids();
        D   = get_data();
        % replace a single blank placeholder row
        if size(D,1) == 1 && isempty(ids{1}) && ~any(cellfun(@is_true, D(1,3:end-1)))
            D = D([], :);  ids = {};
        end
        added = 0;
        for n = a:b
            id = sprintf('%s%d', pre, n);
            if any(strcmp(ids, id)), continue; end
            r = empty_row();  r{1} = id;
            D(end+1, :) = r; %#ok<AGROW>
            ids{end+1} = id; %#ok<AGROW>
            added = added + 1;
        end
        tbl.Data = D;
        if added == 0
            msg('All subjects in that range already exist.', 'Add range', 'info');
        end
    end

    function on_remove(~, ~)
        D = get_data();
        rows = selected_rows();
        if isempty(rows)
            msg('Select one or more rows in the table first.', 'Remove subjects', 'info'); return
        end
        D(rows, :) = [];
        try, tbl.Selection = []; catch, end
        tbl.Data = D;
    end

    function on_mark_all(~, ~)
        set_marks(true);
    end

    function on_clear_marks(~, ~)
        set_marks(false);
    end

    function set_marks(val)
        D = get_data();
        if isempty(D), return; end
        rows = selected_rows();
        if isempty(rows), rows = 1:size(D,1); end
        D(rows, 3:end-1) = {logical(val)};
        tbl.Data = D;
    end

    function on_cancel(~, ~)
        if alive(), delete(fig); end
    end

    function on_save(~, ~)
        if ~alive(), return; end
        % pending condition edit → apply first
        if ~strcmp(strtrim(condFld.Value), strjoin(conds, ', '))
            if ~apply_conditions(), return; end
        end
        if isempty(root)
            msg('Choose the project root folder first (Browse…).', 'Save roster'); return
        end
        fn = clean_fname();
        if isempty(fn) || ~isempty(regexp(fn, '[\\/:*?"<>|]', 'once'))
            msg('Enter a valid file name (letters, numbers, - and _).', 'Save roster'); return
        end
        fileFld.Value = fn;
        sh = strtrim(sheetFld.Value);
        if isempty(sh) || numel(sh) > 31 || ~isempty(regexp(sh, '[\[\]:*?/\\]', 'once'))
            msg('Enter a valid experiment (sheet) name: 1–31 characters, no [ ] : * ? / \', 'Save roster'); return
        end
        sheetFld.Value = sh;

        % validate subjects (fully blank rows are dropped silently)
        D  = get_data();
        nc = numel(conds);
        keep = true(size(D,1), 1);
        ids  = cell(size(D,1), 1);
        bad  = {};
        for i = 1:size(D,1)
            ids{i} = strtrim(to_char(D{i,1}));
            mk  = any(cellfun(@is_true, D(i,3:end-1)));
            nt  = strtrim(to_char(D{i,end}));
            if isempty(ids{i}) && ~mk && isempty(nt), keep(i) = false; continue; end
            if isempty(ids{i})
                bad{end+1} = sprintf('row %d: empty ID', i); %#ok<AGROW>
            elseif isempty(regexp(ids{i}, '\d', 'once'))
                bad{end+1} = sprintf('"%s": must contain a number', ids{i}); %#ok<AGROW>
            end
            if is_marker(nt)
                bad{end+1} = sprintf('row %d: a note cannot be just "%s"', i, nt); %#ok<AGROW>
            end
        end
        D = D(keep, :);  ids = ids(keep);
        ne = ids(~cellfun(@isempty, ids));
        if ~isempty(ne)
            [u, ~, ic] = unique(ne);
            dup = u(accumarray(ic(:), 1) > 1);
            for k = 1:numel(dup), bad{end+1} = sprintf('"%s": duplicated', dup{k}); end %#ok<AGROW>
        end
        if isempty(D)
            msg('Add at least one subject before saving.', 'Save roster'); return
        end
        if ~isempty(bad)
            msg(sprintf('Please fix these subject IDs:\n%s', strjoin(bad, newline)), 'Save roster'); return
        end

        adir = fullfile(root, 'Analysis');
        fp   = apat_paths(adir, 'roster', fn);           % Analysis/Roster
        exists_file = exist(fp, 'file') == 2;
        if exists_file
            shs = {};
            try, shs = cellstr(sheetnames(fp)); catch, end
            if any(strcmp(shs, sh))
                sel = uiconfirm(fig, sprintf(['Sheet "%s" already exists in %s.\n', ...
                    'Overwrite it with this roster? Other sheets are kept.'], sh, fn), ...
                    'Overwrite sheet', 'Options', {'Overwrite','Cancel'}, ...
                    'DefaultOption', 2, 'CancelOption', 2, 'Icon', 'warning');
                if ~alive() || ~strcmp(sel, 'Overwrite'), return; end
            end
        end

        % folders
        try
            if ~exist(adir, 'dir'), mkdir(adir); end
            if strcmp(dataChk.Enable, 'on') && dataChk.Value
                if ~exist(fullfile(root,'Data'), 'dir'), mkdir(fullfile(root,'Data')); end
                if ~exist(fullfile(root,'Data','RAW'), 'dir'), mkdir(fullfile(root,'Data','RAW')); end
            end
        catch err
            msg(sprintf('Could not create the project folders:\n%s', err.message), 'Save roster'); return
        end

        % build the cell array in the roster format
        ns = size(D,1);
        C  = repmat({''}, 2 + ns, 3 + NM*nc);
        C{1,1} = 'Subject';  C{1,2} = 'Sex';  C{1,end} = 'Notes';
        for m = 1:NM
            c0 = 2 + (m-1)*nc;
            C{1, c0+1} = MEAS{m};
            C(2, c0+(1:nc)) = conds;
        end
        for i = 1:ns
            C{2+i, 1} = ids{i};
            sx = to_char(D{i,2});
            if any(strcmp(sx, {'M','F'})), C{2+i, 2} = sx; end
            for k = 1:NM*nc
                if is_true(D{i, 2+k}), C{2+i, 2+k} = 'X'; end
            end
            C{2+i, end} = to_char(D{i,end});
        end

        try
            if exists_file
                writecell(C, fp, 'Sheet', sh, 'WriteMode', 'overwritesheet');
            else
                writecell(C, fp, 'Sheet', sh);
            end
        catch err
            msg(sprintf(['Could not write the roster:\n%s\n\n', ...
                'If the file is open in Excel, close it and try again.'], err.message), 'Save roster');
            return
        end

        % hand over to APAT
        delete(fig);
        try
            if isvalid(app)
                sheet_sel(app, 'set_on_screen', sh, false);   % shown (and selected) after the rescan
                chinroster_ops(app, 'scan', fn);
                uialert(app.UIFigure, sprintf('Roster saved: %d subjects, %d conditions', ns, nc), ...
                    'Subject Roster', 'Icon', 'success');
            end
        catch err
            try
                uialert(app.UIFigure, sprintf('Roster saved, but APAT could not reload it:\n%s', err.message), ...
                    'Subject Roster');
            catch
            end
        end
    end

end


% ═════════════════════════════════════════════════════════════════════
%  Local functions
% ═════════════════════════════════════════════════════════════════════

function tf = is_true(v)
%IS_TRUE  Checkbox cell value → logical scalar.
tf = (islogical(v) || isnumeric(v)) && ~isempty(v) && v(1) ~= 0 && ~(isnumeric(v) && isnan(v(1)));
end

function s = to_char(v)
%TO_CHAR  Cell value → char ('' for empty / missing / NaN).
if ischar(v)
    s = v;
elseif isstring(v)
    if isempty(v) || ismissing(v(1)), s = ''; else, s = char(v(1)); end
elseif isnumeric(v) || islogical(v)
    if isempty(v) || (isnumeric(v) && isnan(v(1))), s = ''; else, s = num2str(v(1)); end
elseif isdatetime(v)
    s = char(v);
else
    s = '';
end
end
