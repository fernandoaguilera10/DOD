function [ok, info] = res_load(app, label, sheet, t_min, key, stamp)
%RES_LOAD  Rebuild one analysis' Results views from its saved file
%   (shared/apat_res_store) — seconds, nothing is analysed or plotted again.
%
%   [ok, info] = res_load(app, label, sheet [, t_min])
%     label  Results label ('ABR Thresholds', 'EFR dAM', 'DPOAE', 'MEMR',
%            'MEMR Vector' …), sheet = Experiment (roster sheet)
%     t_min  only a file saved at or after this time (datenum) is used
%            (Resume: saved by the run being resumed); [] = any
%     key, stamp  (optional) only a file saved with this settings key and
%            data / code stamp (RunButtonPushed>run_one: nothing changed)
%     ok     true when the views were rebuilt
%     info   when it was saved ('2026-10-17 21:40') or why not
%   The Average views are embedded at once; each subject's individual view
%   is parked and built the first time it is opened (embed_results 'park_files').
%   Images are not written again (the saved figures have none pending).
ok = false;  info = '';
if nargin < 4, t_min = []; end
if nargin < 6, key = []; stamp = []; end
try
    root = strtrim(app.RootDirField.Value);
    f = apat_res_store('file', fullfile(root, 'Analysis'), label, sheet);
    if exist(f, 'file') ~= 2, info = 'not saved yet'; return; end
    H = load(f, 'meta');                         % header first: the figures only when it is used
    if ~isfield(H, 'meta'), info = 'not saved yet'; return; end
    R = struct('meta', H.meta);
    if ~isempty(t_min) && (~isfield(R.meta, 'time') || R.meta.time < t_min)
        info = 'saved before this run';  return
    end
    % current = same settings key, and saved after every input last changed
    % (results / raw data / roster / figure code: res_fresh stamp)
    if ~isempty(key) && ~(isfield(R.meta, 'key') && isequal(R.meta.key, key) && ...
            isfield(R.meta, 'time') && R.meta.time >= stamp)
        info = 'changed since it was saved';  return
    end
    meas_idx = find(strcmp(APAT_app.measure_tab_labels(), label), 1);
    if isempty(meas_idx), info = 'unknown analysis'; return; end
    R = apat_res_store('read', f);
    if isempty(R), info = 'not saved yet'; return; end

    % same preparation as RunButtonPushed>run_one
    res_exp(app, 'activate', sheet);
    app.res.run_sheet = sheet;
    if isfield(R.meta, 'run_conds') && isstruct(R.meta.run_conds), app.res.run_conds = R.meta.run_conds; end
    if isfield(R.meta, 'plot_defaults') && isstruct(R.meta.plot_defaults), app.state.plot_defaults = R.meta.plot_defaults; end
    clear_measure(app, meas_idx);

    d = apat_img_cache('park_dir');
    % individual views: parked (built when the subject is opened)
    for k = 1:numel(R.ind)
        files = cell(1, numel(R.ind(k).figs));
        for j = 1:numel(files)
            files{j} = [tempname(d) '.fig'];
            write_bytes(files{j}, R.ind(k).figs{j});
        end
        if ~isempty(files), embed_results(app, 'park_files', meas_idx, R.ind(k).subj, files); end
    end
    % average views: embedded now
    figs = gobjects(0);  tmp = {};
    for j = 1:numel(R.avg)
        tmp{j} = [tempname(d) '.fig']; %#ok<AGROW>
        write_bytes(tmp{j}, R.avg{j});
        try
            h = openfig(tmp{j}, 'invisible');  figs(end+1) = h(1); %#ok<AGROW>
        catch
        end
    end
    if ~isempty(figs)
        embed_results(app, 'avg', figs, label);
    else
        navigate_results(app, 'after_ind_embed', meas_idx, '');
    end
    delete(figs(isvalid(figs)));
    for j = 1:numel(tmp), try, delete(tmp{j}); catch, end, end
    ok = true;
    info = '';  if isfield(R.meta, 'saved'), info = R.meta.saved; end
catch err
    info = err.message;
end
end


function clear_measure(app, meas_idx)
% (as run_one) this measure's views of the current Experiment emptied
if isempty(app.res.panels), return; end
p_ind = app.res.panels{1, meas_idx};
if isvalid(p_ind)
    data = app.res.subj_data{meas_idx};
    for k = 1:numel(data.panels)
        if isvalid(data.panels{k}), delete(data.panels{k}); end
    end
    app.res.subj_data{meas_idx} = struct('names',{{}},'panels',{{}});
end
p_avg = app.res.panels{2, meas_idx};
if isvalid(p_avg), delete(p_avg.Children); end
if app.res.meas_idx == meas_idx
    app.FigSubjDropdown.Items = {'-'};  app.FigSubjDropdown.Value = '-';
    app.FigFreqDD.Items = {'—'};        app.FigFreqDD.Value = '—';
end
end


function write_bytes(file, b)
fid = fopen(file, 'w');
if fid < 0, error('APAT:resLoad', 'Cannot write %s', file); end
c = onCleanup(@() fclose(fid));
fwrite(fid, b, 'uint8');
end
