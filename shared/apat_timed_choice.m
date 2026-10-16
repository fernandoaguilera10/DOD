function [idx, timed_out] = apat_timed_choice(ttl, prompt, items, preselect, timeout, default_txt)
%APAT_TIMED_CHOICE  List choice that answers itself when nobody is there.
%   [idx, timed_out] = apat_timed_choice(ttl, prompt, items, preselect, timeout, default_txt)
%   Window with a list (ITEMS, PRESELECT highlighted), "Use Selected" and
%   "Skip". With no answer within TIMEOUT seconds (each click restarts the
%   countdown) it closes and returns idx = 0, timed_out = true — the caller
%   takes its automatic choice (DEFAULT_TXT, shown in the countdown line).
%   idx = 0, timed_out = false: Skip / window closed. TIMEOUT = Inf waits.
%   Run default: root appdata 'APAT_prompt_timeout' (set by analysis_run).
if nargin < 4 || isempty(preselect), preselect = 1; end
if nargin < 5 || isempty(timeout)
    timeout = Inf;
    if isappdata(0, 'APAT_prompt_timeout'), timeout = getappdata(0, 'APAT_prompt_timeout'); end
end
if nargin < 6, default_txt = 'skip'; end
idx = 0;  timed_out = false;
items = cellstr(items);
if isempty(items), return; end
preselect = min(max(1, preselect), numel(items));

W = 620;  H = 300;  PAD = 12;
scr = get(0, 'ScreenSize');
dlg = uifigure('Name', ttl, 'Color','white', 'WindowStyle','modal', 'Resize','off', ...
    'Position', [round((scr(3)-W)/2) round((scr(4)-H)/2) W H]);
done = false;
dlg.CloseRequestFcn = @(~,~) finish(0);
uilabel(dlg, 'Text',prompt, 'FontSize',13, 'FontWeight','bold', 'WordWrap','on', ...
    'Interpreter','none', 'Position',[PAD H-52 W-2*PAD 42]);
lb = uilistbox(dlg, 'Items',items, 'ItemsData',1:numel(items), 'Value',preselect, ...
    'FontSize',12, 'Position',[PAD 56 W-2*PAD H-118]);
lb.ValueChangedFcn = @(~,~) poke();
try, lb.DoubleClickedFcn = @(~,~) finish(lb.Value); catch, end
cnt = uilabel(dlg, 'Text','', 'FontSize',11, 'FontColor',[0.45 0.45 0.45], ...
    'Interpreter','none', 'Position',[PAD 16 W-280 24]);
uibutton(dlg, 'Text','Use Selected', 'FontSize',12, 'FontWeight','bold', ...
    'BackgroundColor',[0.18 0.49 0.31], 'FontColor','white', ...
    'Position',[W-PAD-240 14 130 30], 'ButtonPushedFcn',@(~,~) finish(lb.Value));
uibutton(dlg, 'Text','Skip', 'FontSize',12, 'Position',[W-PAD-100 14 100 30], ...
    'ButtonPushedFcn',@(~,~) finish(0));

deadline = now_s() + timeout;
while ~done && isvalid(dlg)
    left = deadline - now_s();
    if left <= 0
        timed_out = true;  idx = 0;
        break
    end
    if isfinite(left)
        try, cnt.Text = sprintf('No answer in %d s → %s', ceil(left), default_txt); catch, end
    end
    uiwait(dlg, min(1, left));
end
if isvalid(dlg), delete(dlg); end

    function poke()
        deadline = now_s() + timeout;             % someone is choosing
    end
    function finish(v)
        idx = v;  done = true;
        try, uiresume(dlg); catch, end
    end
end

function t = now_s()
t = now * 86400; %#ok<TNOW1>
end
