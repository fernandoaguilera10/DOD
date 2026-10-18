function out = res_exp(app, action, varargin)
%RES_EXP  Results views of every Experiment (roster sheet) of a run.
%
%   res_exp(app, 'reset')            new run (Run button): delete the views of
%                                    every Experiment, empty the current hosts
%   res_exp(app, 'activate', sheet)  run_one: make SHEET's views the current
%                                    ones (empty hosts are made the first time)
%   res_exp(app, 'show', sheet)      Plot Settings "Experiment" button: activate
%                                    SHEET and redraw the view on screen
%   names = res_exp(app, 'list')     Experiments of the run (run order)
%
%   All Results code works on app.res.panels (2 × measures host panels),
%   app.res.subj_data, app.res.run_conds and app.res.cond_on = the views of
%   the Experiment on screen (app.res.run_sheet = app.res.exp_cur). The
%   other Experiments' sets are kept in app.res.exp_sets (struct array: name,
%   panels, subj_data, run_conds, cond_on) with their host panels hidden;
%   'activate' swaps the handles, so navigation, Save Image, Exclude,
%   tracking, Conditions, status strip and relayout need no changes.
%   Silent: never throws.
out = [];
try
    switch action
        case 'reset',    do_reset(app);
        case 'activate', activate(app, varargin{1});
        case 'show',     show(app, varargin{1});
        case 'list',     out = list(app);
    end
catch
end
end


function names = list(app)
names = {};
if isfield(app.res, 'exp_names') && iscell(app.res.exp_names), names = app.res.exp_names; end
end

function nm = cur(app)
nm = '';
if isfield(app.res, 'exp_cur') && ischar(app.res.exp_cur), nm = app.res.exp_cur; end
end


function do_reset(app)
try, exp_overlay(app, 'clear'); catch, end        % Experiment overlay (exp_overlay.m) off
app.res.exp_show = {};
% sets of other Experiments: delete their hosts
if isfield(app.res, 'exp_sets')
    for i = 1:numel(app.res.exp_sets)
        E = app.res.exp_sets(i);
        if strcmp(E.name, cur(app)), continue; end
        for k = 1:numel(E.panels)
            try, if isvalid(E.panels{k}), delete(E.panels{k}); end, catch, end
        end
    end
end
% current hosts: empty, with their placeholder
for mi = 1:size(app.res.panels, 2)
    for mode = 1:2
        p = app.res.panels{mode, mi};
        if ~isvalid(p), continue; end
        delete(p.Children);
        placeholder(p, mode);
    end
    app.res.subj_data{mi} = struct('names',{{}},'panels',{{}});
end
app.res.exp_sets  = struct('name',{}, 'panels',{}, 'subj_data',{}, 'run_conds',{}, 'cond_on',{});
app.res.exp_names = {};
app.res.exp_cur   = '';
try, app.FigSubjDropdown.Items = {'-'};  app.FigSubjDropdown.Value = '-'; catch, end
end


function activate(app, sheet)
sheet = char(sheet);
if ~isfield(app.res, 'exp_names') || ~iscell(app.res.exp_names), app.res.exp_names = {}; end
if ~isfield(app.res, 'exp_sets')
    app.res.exp_sets = struct('name',{}, 'panels',{}, 'subj_data',{}, 'run_conds',{}, 'cond_on',{});
end
if ~any(strcmp(app.res.exp_names, sheet)), app.res.exp_names{end+1} = sheet; end
c = cur(app);
if strcmp(c, sheet), app.res.run_sheet = sheet; return; end
if isempty(c)                                     % first Experiment: adopts the current hosts
    app.res.exp_cur = sheet;  app.res.run_sheet = sheet;
    return
end
store(app);
for k = 1:numel(app.res.panels)                   % hide the Experiment going off screen
    try, if isvalid(app.res.panels{k}), app.res.panels{k}.Visible = 'off'; end, catch, end
end
i = find(strcmp({app.res.exp_sets.name}, sheet), 1);
ok = ~isempty(i) && all(cellfun(@(p) isvalid(p), app.res.exp_sets(i).panels(:)));
if ok
    E = app.res.exp_sets(i);
    app.res.panels    = E.panels;
    app.res.subj_data = E.subj_data;
    app.res.run_conds = E.run_conds;
    app.res.cond_on   = E.cond_on;
else                                              % new Experiment: empty hosts like the base ones
    P = app.res.panels;
    for mi = 1:size(P, 2)
        for mode = 1:2
            P{mode, mi} = new_host(P{mode, mi}, mode);
        end
        app.res.subj_data{mi} = struct('names',{{}},'panels',{{}});
    end
    % new hosts below the Results buttons / blind cover: ONE reorder for all
    % (Oct 18 2026: 28 single moves of a large Results window at the switch
    % to the next Experiment preceded a MATLAB crash)
    try
        par = P{1,1}.Parent;  ch = par.Children;
        isnew = false(size(ch));
        for k = 1:numel(P), isnew = isnew | (ch == P{k}); end
        par.Children = [ch(~isnew); ch(isnew)];
    catch
    end
    app.res.panels  = P;
    app.res.cond_on = [];                         % its Conditions start all ON
    if ~isempty(i), app.res.exp_sets(i) = []; end
end
app.res.exp_cur   = sheet;
app.res.run_sheet = sheet;
end


function store(app)
c = cur(app);
if isempty(c), return; end
rc = [];  co = [];
if isfield(app.res, 'run_conds'), rc = app.res.run_conds; end
if isfield(app.res, 'cond_on'),   co = app.res.cond_on;   end
E = struct('name',c, 'panels',{app.res.panels}, 'subj_data',{app.res.subj_data}, ...
    'run_conds',{rc}, 'cond_on',{co});
i = find(strcmp({app.res.exp_sets.name}, c), 1);
if isempty(i), app.res.exp_sets(end+1) = E; else, app.res.exp_sets(i) = E; end
end


function show(app, sheet)
if isappdata(app.UIFigure, 'apat_running') && isequal(getappdata(app.UIFigure, 'apat_running'), true)
    return                                        % embedding goes to the Experiment being run
end
if strcmp(cur(app), sheet) || ~any(strcmp(list(app), sheet)), return; end
subj = '';  try, subj = app.FigSubjDropdown.Value; catch, end
activate(app, sheet);
navigate_results(app, 'meas_btn', app.res.meas_idx);
if app.res.mode == 1                              % same subject when this Experiment has it
    d = app.res.subj_data{app.res.meas_idx};
    if any(strcmp(d.names, subj))
        app.FigSubjDropdown.Value = subj;
        navigate_results(app, 'subj');
    end
end
end


function p = new_host(base, mode)
p = uipanel(base.Parent, 'BorderType','line', 'BackgroundColor',[1 1 1], ...
    'Units',base.Units, 'Position',base.Position, 'Visible','off');
try, p.BorderColor = base.BorderColor; catch, try, p.HighlightColor = base.HighlightColor; catch, end, end
placeholder(p, mode);
% (moved below the Results buttons / blind cover by activate, all at once)
end


function placeholder(p, mode)
if mode == 2
    make_placeholder(p, 'No average figures yet', ...
        ['Pick subjects and a measure on the Setup tab, then press Run Analysis ' ...
                '(analyses that did not change since their last run load in seconds).']);
else
    make_placeholder(p, 'No individual figures yet', ...
        'Figures for each subject appear here as the analysis runs.');
end
end
