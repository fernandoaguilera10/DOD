function bar_fit(app)
%BAR_FIT  Column widths of the Results bar grid (createComponents>
%   buildResultsTab, app.res.bar). The bar is a uigridlayout, so nothing in
%   it is ever placed past the window edge; this only decides widths:
%     - hidden items get width 0: Subject + Exclude (Average view), the
%       Frequency dropdown (all but ABR Peaks), the Tracking chip (no
%       subject tracked);
%     - the measure buttons keep their design widths while they fit; on a
%       narrower bar they share the room by weight (proportional to their
%       design widths) and the spacer before Tracking goes to 0, so Tracking
%       stays right-anchored and everything fits.
%   Called after building, from res_style 'bar_sync' (every Results view
%   change), subject_pick (Tracking shown / hidden) and relayout_results
%   (window resize). Silent: never throws.
try
    if ~isvalid(app) || ~isfield(app.res, 'bar'), return; end
    B = app.res.bar;
    g = B.grid;
    if isempty(g) || ~isvalid(g), return; end
    cw = B.cols;
    if ~(isfield(app.res, 'mode') && app.res.mode == 1)
        cw{B.subj(1)} = 0;  cw{B.subj(2)} = 0;
    end
    if ~(isvalid(app.FigFreqDD) && is_on(app.FigFreqDD))
        cw{B.freq} = 0;
    end
    trk = false;
    try, trk = is_on(app.res.pick_ui(2)); catch, end
    if ~trk
        cw{B.track(1)} = 0;  cw{B.track(2)} = 0;
    end
    % room left for the measure buttons at the bar's current width
    W = 0;
    try, W = g.Parent.Position(3); catch, end
    if W > 100
        fixed = 0;
        for k = 1:numel(cw)
            if isnumeric(cw{k}) && ~any(k == B.meas), fixed = fixed + cw{k}; end
        end
        avail = W - B.pad - B.gap*(numel(cw) - 1) - fixed;
        if avail < sum(B.meas_w)
            for k = 1:numel(B.meas)
                cw{B.meas(k)} = sprintf('%dx', round(B.meas_w(k)));
            end
            cw{B.spacer} = 0;
        end
    end
    if ~isequal(g.ColumnWidth, cw), g.ColumnWidth = cw; end
catch
end
end


function tf = is_on(h)
%IS_ON  Visible property as logical (char 'on' / 'off' or OnOffSwitchState).
v = h.Visible;
if ischar(v) || isstring(v), tf = strcmp(v, 'on'); else, tf = logical(v); end
end
