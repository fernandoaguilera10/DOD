function load_saved(app)
%LOAD_SAVED  (Not used since Oct 17 2026: Run Analysis loads saved Results by
%   itself when nothing changed — RunButtonPushed>run_one. Kept for use from
%   the Command Window.) The Results tab rebuilt from the
%   saved Results files (shared/apat_res_store) of every selected analysis
%   of every selected Experiment — nothing is analysed or plotted, so
%   earlier results can be browsed in seconds. Analyses never run (or only
%   run with an older APAT) are listed as not saved.
root = strtrim(app.RootDirField.Value);
if isempty(root)
    uialert(app.UIFigure, 'Set the root directory first.', 'Load Saved Results');  return
end
sheets = {};
try, sheet_sel(app, 'store');  sheets = sheet_sel(app, 'selected'); catch, end
if isempty(sheets), try, sheets = {sheet_sel(app, 'on_screen')}; catch, end, end
runs = zeros(0, 2);
if isfield(app.state, 'run_sel')
    for m = 1:numel(app.MEASURES)
        for k = find(app.state.run_sel{m}), runs(end+1,:) = [m k]; end %#ok<AGROW>
    end
end
if isempty(runs) || isempty(sheets)
    uialert(app.UIFigure, 'Select at least one analysis (a measure button, then its type).', ...
        'Load Saved Results');  return
end
b = busy_start(app); %#ok<NASGU>
res_exp(app, 'reset');
got = {};  miss = {};
for si = 1:numel(sheets)
    for r = 1:size(runs, 1)
        lbl = meas_label(app, runs(r,1), runs(r,2));
        [ok, info] = res_load(app, lbl, sheets{si});
        nm = lbl;  if numel(sheets) > 1, nm = sprintf('%s (%s)', lbl, sheets{si}); end
        if ok, got{end+1} = sprintf('%s — saved %s', nm, info); %#ok<AGROW>
        else,  miss{end+1} = nm; end %#ok<AGROW>
    end
end
app.TabGroup.SelectedTab = app.ResultsTab;
clear b                                          % "Loading…" box closed before the summary
msg = '';
if ~isempty(got), msg = sprintf('Loaded:\n  %s', strjoin(got, '\n  ')); end
if ~isempty(miss)
    msg = sprintf('%s%sNot saved yet (run them once to save their Results):\n  %s', msg, ...
        repmat(sprintf('\n\n'), 1, ~isempty(msg)), strjoin(miss, '\n  '));
end
uialert(app.UIFigure, msg, 'Load Saved Results', 'Icon', ternary(isempty(got), 'warning', 'success'));
end
