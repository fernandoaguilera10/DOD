function c = busy_start(app, msg)
%BUSY_START  Modal "Loading…" box + busy pointer for anything that redraws
%   the Results view (view switches, clicking a subject point, opening a
%   subject). Returns an onCleanup: the box closes when the caller finishes
%   (or errors). Nested calls share one box (counter in UIFigure appdata),
%   so a click that triggers several view switches shows a single popup.
if nargin < 2 || isempty(msg), msg = 'Loading results — please wait…'; end
dlg = [];  top = false;
try
    n = 0;
    if isappdata(app.UIFigure, 'apat_busy_n'), n = getappdata(app.UIFigure, 'apat_busy_n'); end
    setappdata(app.UIFigure, 'apat_busy_n', n + 1);
    if n == 0
        top = true;
        app.UIFigure.Pointer = 'watch';
        dlg = uiprogressdlg(app.UIFigure, 'Title','Loading', 'Message',msg, 'Indeterminate','on');
        drawnow;                                   % paint the box before the work starts
    end
catch
end
c = onCleanup(@() busy_stop(app, dlg, top));
end


function busy_stop(app, dlg, top)
try
    if isvalid(app) && isvalid(app.UIFigure)
        n = 1;
        if isappdata(app.UIFigure, 'apat_busy_n'), n = getappdata(app.UIFigure, 'apat_busy_n'); end
        n = max(0, n - 1);
        if top, n = 0; end                         % outermost call: always reset
        setappdata(app.UIFigure, 'apat_busy_n', n);
        if n == 0, app.UIFigure.Pointer = 'arrow'; end
    end
catch
end
try, if ~isempty(dlg) && isvalid(dlg), close(dlg); end, catch, end
end
