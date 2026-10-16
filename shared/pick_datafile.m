function [selected, timed_out] = pick_datafile(file_names, title_str, folder, timeout)
%PICK_DATAFILE  Choose one recording when a data folder holds several
%   (Manual data-file rule, called by choose_recording).
%
%   selected = pick_datafile(file_names, title_str, folder)
%
%   Files on the left; clicking a file shows a quick preview of its data on
%   the right (preview_recording: DPOAE / SFOAE level + noise floor and the
%   energy of every trial, TEOAE waveform + spectrum, MEMR growth + spectral
%   change), so a bad recording can be spotted before the analysis runs.
%   Double-click a file (or "Use Selected File") to use it. Cancel or
%   closing the window returns ''. Previews are kept while the window is
%   open, so going back to a file is instant.
%
%   file_names : cell array of file names (in FOLDER)
%   title_str  : window title
%   folder     : folder holding the files ('' = no preview)
%   timeout    : seconds without an answer (each click restarts it) after
%                which the window closes, selected = '', timed_out = true —
%                the caller takes its automatic rule. Default: root appdata
%                'APAT_prompt_timeout' (30 s during a run, set by
%                analysis_run), else Inf (wait).

if nargin < 2 || isempty(title_str), title_str = 'Select file'; end
if nargin < 3, folder = ''; end
if nargin < 4 || isempty(timeout)
    timeout = Inf;
    if isappdata(0, 'APAT_prompt_timeout'), timeout = getappdata(0, 'APAT_prompt_timeout'); end
end
selected = '';  timed_out = false;
if isempty(file_names), return; end
file_names = file_names(:)';
if numel(file_names) == 1, selected = file_names{1}; return; end

INK = [0.15 0.15 0.15];  GRY = [0.45 0.45 0.45];
W = 1180;  H = 640;  LW = 270;  PAD = 12;
scr = get(0, 'ScreenSize');
dlg = uifigure('Name', title_str, 'Color','white', 'WindowStyle','modal', ...
    'Position', [round((scr(3)-W)/2) round((scr(4)-H)/2) W H], 'Resize','off');
dlg.CloseRequestFcn = @(~,~) do_cancel();

where = '';
if ~isempty(folder)
    p = strsplit(strrep(char(folder), '\', '/'), '/');  p = p(~cellfun(@isempty, p));
    i = find(strcmp(p, 'Data'), 1, 'last');
    if ~isempty(i) && i < numel(p), where = strjoin(p(i+1:end), ' / ');
    else, where = strjoin(p(max(1, end-3):end), ' / '); end
end
uilabel(dlg, 'Text','Several recordings in this folder — choose the one to analyse', ...
    'FontSize',15, 'FontWeight','bold', 'FontColor',INK, 'Position',[PAD H-38 W-2*PAD 26]);
uilabel(dlg, 'Text',where, 'FontSize',12, 'FontColor',GRY, 'Interpreter','none', ...
    'Position',[PAD H-60 W-2*PAD 20]);

% ── files (left) ─────────────────────────────────────────────────────────
uilabel(dlg, 'Text','Click = preview   ·   double-click = use it', 'FontSize',11, ...
    'FontColor',GRY, 'Position',[PAD H-86 LW 20]);
lb = uilistbox(dlg, 'Items',file_names, 'FontSize',12, 'Position',[PAD 60 LW H-150]);
lb.ValueChangedFcn = @(~,~) show(lb.Value);
try, lb.DoubleClickedFcn = @(~,~) do_select(); catch, end    % R2021a+

% ── preview (right) ──────────────────────────────────────────────────────
x0 = PAD + LW + 18;  pw = W - x0 - PAD;
info = uilabel(dlg, 'Text','', 'FontSize',12, 'FontColor',INK, 'Interpreter','none', ...
    'WordWrap','on', 'Position',[x0 H-104 pw 40]);
aw = floor((pw - 24) / 2);  ah = H - 190;
ax = [uiaxes(dlg, 'Position',[x0 60 aw ah]), uiaxes(dlg, 'Position',[x0+aw+24 60 aw ah])];
for a = ax, a.Toolbar.Visible = 'off';  disableDefaultInteractivity(a); end
msg = uilabel(dlg, 'Text','', 'FontSize',14, 'FontColor',GRY, 'HorizontalAlignment','center', ...
    'Position',[x0 60 + ah/2 - 15 pw 30]);

% ── buttons ──────────────────────────────────────────────────────────────
uibutton(dlg, 'Text','Use Selected File', 'FontSize',12, 'FontWeight','bold', ...
    'BackgroundColor',[0.18 0.49 0.31], 'FontColor','white', ...
    'Position',[W-PAD-280 14 160 34], 'ButtonPushedFcn',@(~,~) do_select());
uibutton(dlg, 'Text','Cancel', 'FontSize',12, 'Position',[W-PAD-110 14 110 34], ...
    'ButtonPushedFcn',@(~,~) do_cancel());

cnt = uilabel(dlg, 'Text','', 'FontSize',11, 'FontColor',GRY, 'Interpreter','none', ...
    'Position',[PAD 20 W-PAD-300 22]);
cache = containers.Map();
deadline = now * 86400 + timeout; %#ok<TNOW1>
drawnow;
show(lb.Value);                                     % first file right away
while isvalid(dlg)                                  % no answer → automatic rule (caller)
    left = deadline - now * 86400; %#ok<TNOW1>
    if left <= 0, timed_out = true;  selected = '';  break; end
    if isfinite(left)
        try, cnt.Text = sprintf('No answer in %d s → automatic choice (most trials)', ceil(left)); catch, end
    end
    uiwait(dlg, min(1, left));
end
if isvalid(dlg), delete(dlg); end

    % ─────────────────────────────────────────────────────────────────────
    function show(f)
        if ~isvalid(dlg) || isempty(f), return; end
        deadline = now * 86400 + timeout; %#ok<TNOW1> someone is choosing
        if isempty(folder)
            draw(struct('kind','', 'info','', 'ax',struct([]), 'note','No preview available.'));
            return
        end
        if ~isKey(cache, f)
            for a2 = ax, cla(a2, 'reset');  a2.Visible = 'off'; end
            info.Text = f;  msg.Text = 'Loading preview…';  msg.Visible = 'on';
            dlg.Pointer = 'watch';  drawnow;
            try
                P = preview_recording(folder, f);
            catch err
                P = struct('kind','', 'info','', 'ax',struct([]), 'note',['Preview failed: ' err.message]);
            end
            if ~isvalid(dlg), return; end
            dlg.Pointer = 'arrow';
            cache(f) = P;
        end
        if ~isequal(lb.Value, f), return; end        % another file was clicked meanwhile
        draw(cache(f));
    end

    function draw(P)
        txt = lb.Value;
        if ~isempty(P.info), txt = sprintf('%s   ·   %s', txt, P.info); end
        info.Text = txt;
        for a2 = ax, cla(a2, 'reset');  a2.Visible = 'off';  legend(a2, 'off'); end
        if isempty(P.ax)
            msg.Text = P.note;  msg.Visible = 'on';
            return
        end
        msg.Visible = 'off';
        for k = 1:min(2, numel(P.ax))
            A = P.ax(k);  a2 = ax(k);
            a2.Visible = 'on';  hold(a2, 'on');
            for j = 1:numel(A.bars)
                bar(a2, A.bars(j).x, A.bars(j).y, 0.8, 'FaceColor',A.bars(j).clr, 'EdgeColor','none');
            end
            hl = gobjects(0);  nm = {};
            for j = 1:numel(A.lines)
                L = A.lines(j);
                h = plot(a2, L.x, L.y, L.style, 'Color',L.clr, 'LineWidth',L.lw, 'MarkerFaceColor',L.clr);
                if ~isempty(L.name), hl(end+1) = h; nm{end+1} = L.name; end %#ok<AGROW>
            end
            if ~isempty(A.hline), yline(a2, A.hline, ':', 'Color',[0.2 0.2 0.2], 'LineWidth',1.2); end
            a2.XScale = A.xscale;
            if strcmp(A.xscale, 'log')
                tk = [0.25 0.5 1 2 4 8 16];
                xl = [min(arrayfun(@(L) min([L.x(:); inf]), A.lines)), max(arrayfun(@(L) max([L.x(:); -inf]), A.lines))];
                if all(isfinite(xl)) && xl(2) > xl(1)
                    a2.XLim = xl;  a2.XTick = tk(tk >= xl(1) & tk <= xl(2));
                end
            end
            grid(a2, 'on');  a2.FontSize = 11;  a2.Box = 'off';
            title(a2, A.title, 'FontSize',12, 'FontWeight','bold');
            xlabel(a2, A.xlab);  ylabel(a2, A.ylab);
            if A.legend && ~isempty(hl)
                legend(a2, hl, nm, 'Location','best', 'FontSize',10, 'Box','off');
            end
            hold(a2, 'off');
        end
    end

    function do_select()
        if ~isvalid(dlg), return; end
        selected = lb.Value;
        uiresume(dlg);
        delete(dlg);
    end

    function do_cancel()
        selected = '';
        if isvalid(dlg), uiresume(dlg); delete(dlg); end
    end
end
