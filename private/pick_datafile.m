function selected = pick_datafile(file_names, title_str)
%PICK_DATAFILE  Blocking MATLAB listbox for selecting one file from a list.
%
%   selected = pick_datafile(file_names, title_str)
%
%   file_names : cell array of filename strings
%   title_str  : dialog title
%   selected   : the chosen filename string, or '' if cancelled

if nargin < 2, title_str = 'Select file'; end

selected = '';
if isempty(file_names), return; end
if numel(file_names) == 1, selected = file_names{1}; return; end

% Build a compact blocking figure
dlg_w = 480; dlg_h = min(60 + numel(file_names)*22 + 60, 500);
scr = get(0,'ScreenSize');
dlg = uifigure('Name', title_str, ...
    'Position', [round((scr(3)-dlg_w)/2) round((scr(4)-dlg_h)/2) dlg_w dlg_h], ...
    'Resize', 'off');

uilabel(dlg, 'Text', 'Multiple data files found. Select one to continue:', ...
    'Position', [10 dlg_h-40 dlg_w-20 30], 'FontSize', 11);

lb = uilistbox(dlg, ...
    'Items', file_names, ...
    'Position', [10 60 dlg_w-20 dlg_h-110], ...
    'FontSize', 10);

uibutton(dlg, 'Text', 'Select', ...
    'Position', [dlg_w-210 10 90 35], ...
    'FontSize', 11, 'FontWeight', 'bold', ...
    'ButtonPushedFcn', @(~,~) do_select());

uibutton(dlg, 'Text', 'Cancel', ...
    'Position', [dlg_w-110 10 90 35], ...
    'FontSize', 11, ...
    'ButtonPushedFcn', @(~,~) do_cancel());

uiwait(dlg);

    function do_select()
        selected = lb.Value;
        uiresume(dlg);
        delete(dlg);
    end

    function do_cancel()
        selected = '';
        uiresume(dlg);
        delete(dlg);
    end
end
