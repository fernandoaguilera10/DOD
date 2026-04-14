function chinroster_ops(app, action, varargin)
%CHINROSTER_OPS  Chinroster file scanning, loading, and subject/condition UI.
%
%   chinroster_ops(app, 'scan', preferred_name) — scan Analysis/ for .xlsx files
%   chinroster_ops(app, 'load')                  — load selected roster, refresh sheets
%   chinroster_ops(app, 'refresh_from', filepath)— re-parse this filepath's active sheet
%   chinroster_ops(app, 'set_subj', subjs, checked) — rebuild subject checkbox grid
%   chinroster_ops(app, 'refresh_conds')         — rebuild condition checkbox list

switch action
    case 'scan',          do_scan(app, varargin{1});
    case 'load',          do_load(app);
    case 'refresh_from',  do_refresh_from(app, varargin{1});
    case 'set_subj',      do_set_subj(app, varargin{1}, varargin{2});
    case 'refresh_conds', do_refresh_conds(app);
end
end


% ── Scan Analysis/ for roster files ──────────────────────────────────

function do_scan(app, preferred_name)
rootdir = strtrim(app.RootDirField.Value);
if isempty(rootdir), return; end
analysis_dir = fullfile(rootdir,'Analysis');
if ~exist(analysis_dir,'dir')
    app.RosterDropdown.Items = {'(Analysis folder not found)'};
    app.RosterDropdown.Value = '(Analysis folder not found)'; return
end
files = [dir(fullfile(analysis_dir,'*.xlsx')); dir(fullfile(analysis_dir,'*.xls'))];
files = files(~strncmp({files.name},'._',2));
if isempty(files)
    app.RosterDropdown.Items = {'(no Excel files found)'};
    app.RosterDropdown.Value = '(no Excel files found)'; return
end
names = {files.name};
app.RosterDropdown.Items = names;
if ~isempty(preferred_name) && any(strcmp(names, preferred_name))
    app.RosterDropdown.Value = preferred_name;
else
    app.RosterDropdown.Value = names{1};
end
do_load(app);
end


% ── Load selected roster → populate sheets ────────────────────────────

function do_load(app)
rootdir  = strtrim(app.RootDirField.Value);
if isempty(rootdir), return; end
chinfile = app.RosterDropdown.Value;
if isempty(chinfile) || chinfile(1) == '(', return; end
filepath = fullfile(rootdir,'Analysis',chinfile);
if ~exist(filepath,'file')
    app.SheetDropdown.Items = {'(file not found)'};
    app.SheetDropdown.Value = '(file not found)';
    do_set_subj(app, {}, []);
    do_refresh_conds(app);
    return
end
try
    sheets = cellstr(sheetnames(filepath));
catch
    app.SheetDropdown.Items = {'(error reading file)'};
    app.SheetDropdown.Value = '(error reading file)'; return
end
cur_idx = find(strcmp(sheets, app.state.sheet), 1);
if isempty(cur_idx), cur_idx = 1; end
app.SheetDropdown.Items = sheets;
app.SheetDropdown.Value = sheets{cur_idx};
app.state.sheet         = sheets{cur_idx};
do_refresh_from(app, filepath);
end


% ── Parse chinroster and refresh subjects + conditions ─────────────────

function do_refresh_from(app, filepath)
[subjects, app.state.conds_all, app.state.cond_labels] = ...
    APAT_app.read_chinroster_sheet(filepath, app.state.sheet);
do_set_subj(app, subjects, true(numel(subjects),1));
do_refresh_conds(app);
settings_ops(app, 'load');
end


% ── Rebuild subject checkbox grid ─────────────────────────────────────

function do_set_subj(app, subjs, checked)
valid = app.h_subj_checks(isvalid(app.h_subj_checks));
if ~isempty(valid), delete(valid); end
app.h_subj_checks = gobjects(0);
app.subj_ids      = {};
if isempty(subjs), return; end
subjs   = subjs(:);
checked = checked(:);
n       = numel(subjs);
app.subj_ids = subjs;

pp          = app.SubjectsPanel.Position;
pw          = pp(3) - 14;
ph          = pp(4);
item_w      = 68;
n_cols      = max(1, floor(pw / item_w));
n_rows      = ceil(n / n_cols);
TITLE_CLEAR = 38;
BTN_CLEAR   = 48;
grid_top    = ph - TITLE_CLEAR;
grid_bot    = BTN_CLEAR;
item_h      = min(24, (grid_top - grid_bot) / max(n_rows,1));

app.h_subj_checks = gobjects(1, n);
for ii = 1:n
    row = ceil(ii / n_cols) - 1;
    col = mod(ii - 1, n_cols);
    x   = 4 + col * item_w;
    y   = grid_top - (row + 1) * item_h;
    app.h_subj_checks(ii) = uicheckbox(app.SubjectsPanel, ...
        'Text',subjs{ii},'Value',logical(checked(ii)), ...
        'Position',[x y item_w item_h], 'FontSize',15);
end
end


% ── Rebuild condition checkbox list ───────────────────────────────────

function do_refresh_conds(app)
valid = app.h_cond_checks(isvalid(app.h_cond_checks));
if ~isempty(valid), delete(valid); end
app.h_cond_checks = gobjects(0);
labels = app.state.cond_labels;
n = numel(labels);
if n == 0, return; end

app.h_cond_checks = gobjects(1, n);
ROW2_H      = app.layout_row2_h;
TITLE_CLEAR = 38;
avail_h     = ROW2_H - TITLE_CLEAR - 10;
item_h      = max(18, min(28, floor(avail_h / n)));
pp_cond     = app.ConditionsPanel.Position;
cond_inner_w = max(120, pp_cond(3) - 18);
for ci = 1:n
    y_pos = ROW2_H - TITLE_CLEAR - ci * item_h;
    app.h_cond_checks(ci) = uicheckbox(app.ConditionsPanel, ...
        'Text',labels{ci},'Value',true, ...
        'Position',[10 y_pos cond_inner_w item_h], 'FontSize',16);
end
end
