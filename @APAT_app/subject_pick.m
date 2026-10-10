function subject_pick(app, action, src)
%SUBJECT_PICK  Click an individual-subject point in any Results plot to see
%   which subject it is and highlight that subject everywhere in APAT
%   (ABR Thresholds average, ABR Peaks Amplitudes / Latencies / Waveforms,
%   EFR dAM / RAM averages, every tab). The selection stays active while you switch
%   measures and is re-applied to figures embedded later.
%
%   subject_pick(app, 'wire')        — make all subject points clickable
%   subject_pick(app, 'click', h)    — point clicked (toggle that subject)
%   subject_pick(app, 'clear')       — clear the selection
%   subject_pick(app, 'open')        — open the subject's Individual results
%
%   Subject points carry Tag 'thr_subj_pts' / 'abr_subj_pts' and the
%   subject ID in DisplayName (set by the plotting functions).
if nargin < 3, src = []; end
if ~isfield(app.res, 'sel_subj'), app.res.sel_subj = ''; end
switch action
    case 'wire'
        for h = all_pts(app)'
            h.ButtonDownFcn = @(o,~) subject_pick(app, 'click', o);
            h.PickableParts = 'visible';
            h.HitTest = 'on';
            try                                  % hover tooltip: Subject row
                n = numel(h.XData);
                rows = h.DataTipTemplate.DataTipRows;
                if any(arrayfun(@(r) strcmp(r.Label,'Subject'), rows)), continue; end
                h.DataTipTemplate.DataTipRows(end+1) = ...
                    dataTipTextRow('Subject', repmat({h.DisplayName}, 1, n));
            catch
            end
        end
        apply_sel(app, []);
    case 'click'
        if isempty(src) || ~isvalid(src), return; end
        nm = src.DisplayName;
        if isempty(nm), return; end
        if strcmp(nm, app.res.sel_subj)
            app.res.sel_subj = '';               % second click on same subject = clear
        else
            app.res.sel_subj = nm;
        end
        apply_sel(app, src);
    case 'clear'
        app.res.sel_subj = '';
        apply_sel(app, []);
    case 'open'
        nm = app.res.sel_subj;
        if isempty(nm), return; end
        mi = app.res.meas_idx;
        data = app.res.subj_data{mi};
        if ~any(strcmp(data.names, nm))
            % fall back to any measure that has this subject analysed
            mi = find(cellfun(@(d) any(strcmp(d.names, nm)), app.res.subj_data), 1);
            if isempty(mi)
                uialert(app.UIFigure, sprintf('No individual results for %s yet.', nm), 'Subject');
                return;
            end
            navigate_results(app, 'meas_btn', mi);
        end
        navigate_results(app, 'ind');
        app.FigSubjDropdown.Items = app.res.subj_data{mi}.names(:)';
        app.FigSubjDropdown.Value = nm;
        navigate_results(app, 'subj');
end
end


% ── helpers ────────────────────────────────────────────────────────────

function H = all_pts(app)
H = [findall(app.ResultsTab, 'Tag','thr_subj_pts'); findall(app.ResultsTab, 'Tag','abr_subj_pts'); ...
     findall(app.ResultsTab, 'Tag','efr_subj_pts')];
H = H(arrayfun(@(h) isprop(h,'SizeData'), H));
end

function apply_sel(app, clicked)
nm = app.res.sel_subj;
delete(findall(app.ResultsTab, 'Tag','subj_pick_lbl'));
for h = all_pts(app)'
    o = getappdata(h, 'pick_orig');
    if isempty(o)
        o = struct('SizeData',h.SizeData, 'MarkerFaceAlpha',h.MarkerFaceAlpha, ...
            'MarkerEdgeAlpha',h.MarkerEdgeAlpha, 'MarkerEdgeColor',h.MarkerEdgeColor, ...
            'LineWidth',h.LineWidth);
        setappdata(h, 'pick_orig', o);
    end
    if isempty(nm)                                   % restore
        set(h, 'SizeData',o.SizeData, 'MarkerFaceAlpha',o.MarkerFaceAlpha, ...
            'MarkerEdgeAlpha',o.MarkerEdgeAlpha, 'MarkerEdgeColor',o.MarkerEdgeColor, ...
            'LineWidth',o.LineWidth);
    elseif strcmp(h.DisplayName, nm)                 % selected subject
        set(h, 'SizeData',o.SizeData*2.2, 'MarkerFaceAlpha',1, 'MarkerEdgeAlpha',1, ...
            'MarkerEdgeColor',[0 0 0], 'LineWidth',1.5);
        try, uistack(h, 'top'); catch, end
    else                                             % everyone else fades
        set(h, 'SizeData',o.SizeData, 'MarkerFaceAlpha',0.08, 'MarkerEdgeAlpha',0.08, ...
            'MarkerEdgeColor',o.MarkerEdgeColor, 'LineWidth',o.LineWidth);
    end
end
% Name tag next to the clicked point
if ~isempty(nm) && ~isempty(clicked) && isvalid(clicked)
    ax = ancestor(clicked, 'axes');
    cp = ax.CurrentPoint;  xc = cp(1,1);  yc = cp(1,2);
    xd = clicked.XData;  yd = clicked.YData;
    if ~isempty(xd)
        [~, k] = min(hypot((xd - xc)/max(eps,diff(ax.XLim)), (yd - yc)/max(eps,diff(ax.YLim))));
        xc = xd(k);  yc = yd(k);
    end
    t = text(ax, xc, yc, ['  ' nm], 'FontSize',12, 'FontWeight','bold', ...
        'Color',[0 0 0], 'BackgroundColor',[1 1 1], 'Margin',1, ...
        'VerticalAlignment','bottom', 'Interpreter','none', 'Tag','subj_pick_lbl', ...
        'Clipping','on', 'HitTest','off');
    if isnumeric(clicked.UserData) && isscalar(clicked.UserData)
        t.UserData = clicked.UserData;               % moves with its waterfall level
    end
end
% Control-bar chip
if isfield(app.res, 'pick_ui') && all(isvalid(app.res.pick_ui))
    u = app.res.pick_ui;     % [caption, name label, open button, clear button]
    if isempty(nm)
        set(u, 'Visible','off');
    else
        u(2).Text = nm;
        set(u, 'Visible','on');
    end
end
end
