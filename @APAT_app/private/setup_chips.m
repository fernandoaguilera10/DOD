function setup_chips(app, what, force)
%SETUP_CHIPS  Place the Setup chips in their grids (uigridlayout, built in
%   createComponents>buildSetupTab; handles in appdata 'apat_chip_grid' of
%   the section panel). MATLAB does the sizing and scrolling; only the cells
%   are set here.
%   setup_chips(app, 'subj' [, force])  subject chips (app.h_subj_checks):
%       columns = how many 72 px chips fit the section width (each '1x'),
%       rows 28 px, the grid scrolls when they do not fit. Re-run by the
%       Subjects section's SizeChangedFcn (createComponents>chips_cb): only
%       does something when the column count changes (or force = true,
%       chinroster_ops after rebuilding the chips).
%   setup_chips(app, 'conds')           condition rows: include chip '1x' |
%       colour swatch 26 | marker 26, rows 26 px, scrolls.
%   Silent: never throws.
if nargin < 3, force = false; end
try
    switch what
        case 'subj'
            P = app.SubjectsPanel;
            G = getappdata(P, 'apat_chip_grid');
            if isempty(G) || ~isvalid(G), return; end
            h = app.h_subj_checks;
            h = h(isgraphics(h));
            n = numel(h);
            % section width − border − section padding − grid padding
            w = P.Position(3) - 2 - 24 - 8;
            nc = max(1, floor((w + 6) / (72 + 6)));
            key = [nc n];
            if ~force && isequal(getappdata(G, 'apat_chip_key'), key), return; end
            setappdata(G, 'apat_chip_key', key);
            nr = max(1, ceil(n / nc));
            % grow first (every chip keeps a valid cell while moving), place,
            % then set the final size
            G.ColumnWidth = repmat({'1x'}, 1, max(nc, numel(G.ColumnWidth)));
            G.RowHeight   = repmat({28}, 1, max(nr, numel(G.RowHeight)));
            for i = 1:n
                h(i).Layout.Row    = ceil(i / nc);
                h(i).Layout.Column = mod(i - 1, nc) + 1;
            end
            G.ColumnWidth = repmat({'1x'}, 1, nc);
            G.RowHeight   = repmat({28}, 1, nr);
        case 'conds'
            G = getappdata(app.ConditionsPanel, 'apat_chip_grid');
            if isempty(G) || ~isvalid(G), return; end
            n = numel(app.h_cond_checks);
            G.ColumnWidth = {'1x', 26, 26};
            G.RowHeight   = repmat({26}, 1, max(1, n));
            for i = 1:n
                H = {app.h_cond_checks, app.h_cond_swatches, app.h_cond_markers};
                for c = 1:3
                    if numel(H{c}) >= i && isgraphics(H{c}(i))
                        H{c}(i).Layout.Row    = i;
                        H{c}(i).Layout.Column = c;
                    end
                end
            end
    end
catch
end
end
