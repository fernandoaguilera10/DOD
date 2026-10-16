function si = shown_subject(app, data)
%SHOWN_SUBJECT  Index (in data.names / data.panels of one measure) of the
%   subject panel that is actually on screen in the Individual view. Uses
%   the panel that is visible; the Subject dropdown only decides when no
%   panel (or several) is visible. When the visible panel and the dropdown
%   disagree, the dropdown is set to the subject on screen (Plot Settings,
%   Conditions and the other controls then act on what is shown).
si = [];
try
    if isempty(data) || ~isfield(data, 'panels') || isempty(data.panels), return; end
    vis = cellfun(@(p) isvalid(p) && strcmp(p.Visible, 'on'), data.panels);
    dd  = find(strcmp(data.names, app.FigSubjDropdown.Value), 1);
    if nnz(vis) == 1
        si = find(vis, 1);
        if ~isequal(si, dd) && any(strcmp(app.FigSubjDropdown.Items, data.names{si}))
            app.FigSubjDropdown.Value = data.names{si};
        end
    else
        si = dd;
    end
catch
end
end
