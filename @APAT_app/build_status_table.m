function build_status_table(app)
%BUILD_STATUS_TABLE  Populate the Data Status tab with per-modality subtabs.
ROOTdir = strtrim(app.RootDirField.Value);
if isempty(ROOTdir)
    uialert(app.UIFigure,'Set the root directory first.','Data Status'); return
end
if isempty(app.subj_ids) || isempty(app.state.conds_all)
    uialert(app.UIFigure,'Load the chinroster first.','Data Status'); return
end

analysis_dir = fullfile(ROOTdir,'Analysis');
subjs  = app.subj_ids;
conds  = app.state.conds_all;
labels = app.state.cond_labels;
n_s    = numel(subjs);
n_c    = numel(conds);

modalities = { ...
    'ABR Thresholds', fullfile('ABR','%s','%s'),         '*ABRthresholds*.mat'; ...
    'ABR Peaks',      fullfile('ABR','%s','%s'),         '*ABRpeaks_dtw*.mat'; ...
    'EFR RAM',        fullfile('EFR','%s','%s'),         '*EFR_RAM*.mat'; ...
    'EFR dAM',        fullfile('EFR','%s','%s'),         '*EFR_dAM*.mat'; ...
    'DPOAE',          fullfile('OAE','DPOAE','%s','%s'), '*DPOAE*.mat'; ...
    'SFOAE',          fullfile('OAE','SFOAE','%s','%s'), '*SFOAE*.mat'; ...
    'TEOAE',          fullfile('OAE','TEOAE','%s','%s'), '*TEOAE*.mat'; ...
    'MEMR',           fullfile('MEMR','%s','%s'),        '*MEMR*.mat'; ...
};
n_mod = size(modalities,1);

% Pre-compute data availability per (subject, condition, modality)
has_any  = false(n_s, n_c);
mod_data = false(n_s, n_c, n_mod);
for mi = 1:n_mod
    for si = 1:n_s
        for ci = 1:n_c
            fdir = fullfile(analysis_dir, sprintf(modalities{mi,2}, subjs{si}, conds{ci}));
            hits = dir(fullfile(fdir, modalities{mi,3}));
            hits = hits(~strncmp({hits.name},'._',2));
            mod_data(si,ci,mi) = ~isempty(hits);
            if mod_data(si,ci,mi), has_any(si,ci) = true; end
        end
    end
end

delete(app.StatusInnerTG.Children);

clr_green = [0.18 0.72 0.42];
clr_amber = [0.97 0.72 0.22];
clr_grey  = [0.82 0.82 0.82];
col_w_subj = 90;
col_w_cond = max(80, round((app.UIFigure.Position(3) - col_w_subj) / max(n_c,1)));
tg_h       = app.StatusInnerTG.Position(4) - 28;

col_names  = [{'Subject'}, labels(:)'];
col_widths = [col_w_subj, repmat(col_w_cond, 1, n_c)];

for mi = 1:n_mod
    mod_tab  = uitab(app.StatusInnerTG, 'Title', modalities{mi,1});
    tbl_data = cell(n_s, n_c + 1);
    for si = 1:n_s
        tbl_data{si,1} = subjs{si};
        for ci = 1:n_c
            tbl_data{si,ci+1} = ternary(mod_data(si,ci,mi), '✓', '');
        end
    end
    tbl = uitable(mod_tab, ...
        'Data',tbl_data,'ColumnName',col_names, ...
        'ColumnWidth',num2cell(col_widths), ...
        'RowName',{}, ...
        'Position',[0 0 app.UIFigure.Position(3) tg_h]);
    for si = 1:n_s
        for ci = 1:n_c
            if mod_data(si,ci,mi)
                clr = clr_green;
            elseif has_any(si,ci)
                clr = clr_amber;
            else
                clr = clr_grey;
            end
            addStyle(tbl, uistyle('BackgroundColor',clr), 'cell', [si, ci+1]);
        end
    end
end
end
