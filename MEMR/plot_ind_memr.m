function plot_ind_memr(data,EXPname,colors,Conds2Run,Chins2Run,all_Conds2Run,ChinIND,CondIND,outpath,xlimits,shapes) %#ok<INUSL>
%PLOT_IND_MEMR  MEMR individual results, all conditions overlaid (same
%   layout and style as the other measures).
%     left  — ΔAbsorbed power vs elicitor level, one line per condition
%             (conditions side by side at each level, apat_dodge).
%             Axes Tag 'memr_ind_ax'.
%     right — threshold per condition (Axes Tag 'memr_thr_ax').
%   Legend (conditions: line + marker) at the bottom. Figure Tag 'memr_ind'.
%   Conditions accumulate in root appdata 'APAT_memr_ind'; reset on a new
%   subject or when a run starts again from an earlier condition.
cond_parts = strsplit(all_Conds2Run{CondIND}, filesep);
cond_label = cond_parts{end};
subj = Chins2Run{ChinIND};
clr  = colors(CondIND, 1:3);
shp  = strtrim(char(shapes(CondIND,:)));  if isempty(shp), shp = 'o'; end

%% ── Accumulate this condition for the subject ──────────────────────────
key = 'APAT_memr_ind';
S = [];  if isappdata(0, key), S = getappdata(0, key); end
if ~isstruct(S) || ~isfield(S,'subj') || ~strcmp(S.subj, subj) || ~isfield(S.conds,'R') || ~isfield(S.conds,'ntr') || ...
        (~isempty(S.conds) && CondIND <= max([S.conds.idx]))      % run started again
    S = struct('subj',subj, 'conds',struct('name',{},'clr',{},'shp',{},'idx',{},'elic',{},'dp',{},'thr',{},'f',{},'R',{},'ntr',{}));
end
k = find([S.conds.idx] == CondIND, 1);
if isempty(k), k = numel(S.conds) + 1; end
thr = NaN;  if isfield(data,'threshold') && ~isempty(data.threshold), thr = double(data.threshold(1)); end
ntr = NaN;  if isfield(data,'trials') && ~isempty(data.trials), ntr = double(data.trials(1)); end   % trials used (legend)
S.conds(k) = struct('name',cond_label, 'clr',clr, 'shp',shp, 'idx',CondIND, ...
    'elic',double(data.elicitor(:)'), 'dp',double(data.deltapow(:)'), 'thr',thr, 'f',[], 'R',[], 'ntr',ntr);
[S.conds(k).f, S.conds(k).R] = memr_spectra(data);
[~, o] = sort([S.conds.idx]);  S.conds = S.conds(o);
setappdata(0, key, S);

%% ── Figure (always fresh; redrawn from appdata) ────────────────────────
old = findobj('Type','figure','Tag','memr_ind');
if ~isempty(old), close(old); end
fh = figure('NumberTitle','off','Visible','off','Color','w','Tag','memr_ind', ...
    'Units','normalized','Position',[0.05 0.1 0.85 0.75]);
INK = [0.15 0.15 0.15];
axH = axes(fh, 'Position',[0 0.92 1 0.06], 'Visible','off');
text(axH, 0.5, 0.5, sprintf('%s  %s', subj, EXPname), 'FontSize',16, 'FontWeight','bold', ...
    'HorizontalAlignment','center', 'Interpreter','none', 'Color',INK);
% left half: growth function + threshold; right half: reflex response
% (same layout as the average; right strip beyond 0.82 left for the app's
% controls — Growth Response y-limits per condition)
ax  = axes(fh, 'Position',[0.06 0.22 0.256 0.64], 'Tag','memr_ind_ax');  hold(ax,'on');   % full width (no strip on the right, Oct 15)
axT = axes(fh, 'Position',[0.377 0.22 0.098 0.64], 'Tag','memr_thr_ax');  hold(axT,'on');

nC = numel(S.conds);
ev = unique([S.conds.elic]);  ev = ev(isfinite(ev));
de = 5;  if numel(ev) > 1, de = median(diff(ev)); end
offs = apat_dodge(nC) * de;
xl = [min([xlimits(1), ev]) - 0.6*de, max([xlimits(2), ev]) + 0.6*de];
xlim(ax, xl);  xlim(axT, [0.5 nC+0.5]);
ms = apat_ms(ax, 0.7*de);   % points at true x: size from the x spacing
msT = apat_ms(axT, 0.7);                                % one threshold per condition
LC = struct('clr',{},'shp',{},'label',{});
for c = 1:nC
    C = S.conds(c);
    m = min(numel(C.elic), numel(C.dp));
    plot(ax, C.elic(1:m) + offs(c), C.dp(1:m), '-', 'Marker',C.shp, 'MarkerSize',ms, 'LineWidth',2, ...
        'Color',C.clr, 'MarkerFaceColor',C.clr, 'MarkerEdgeColor',C.clr, 'HandleVisibility','off');
    plot(axT, c, C.thr, 'LineStyle','none', 'Marker',C.shp, 'MarkerSize',msT, 'LineWidth',2, ...
        'Color',C.clr, 'MarkerFaceColor',C.clr, 'MarkerEdgeColor',C.clr, 'HandleVisibility','off');
    lbl = C.name;                                          % trials of this recording
    if isfinite(C.ntr), lbl = sprintf('%s (n = %d trials)', C.name, round(C.ntr)); end
    LC(end+1) = struct('clr',C.clr, 'shp',C.shp, 'label',lbl); %#ok<AGROW>
end
memr_style(ax, axT, ev, de, {S.conds.name}, 'Elicitor Level (dB FPL)', ...
    'Reflex Magnitude (dB)', 'Acoustic Reflex Threshold (dB FPL)', false, reshape([S.conds.clr], 3, [])');
RC = struct('name',{S.conds.name}, 'clr',{S.conds.clr}, 'f',{S.conds.f}, 'R',{S.conds.R}, 'elic',{S.conds.elic}, ...
    'thr',{S.conds.thr});                                % levels below the threshold greyed out
[~, KY] = memr_resp_plot(fh, [0.548 0.22 0.415 0.64], RC, '');   % Growth Response + level colour bar
apat_legend(fh, ax, LC, KY, 0.06, 0.903);

%% ── Export ─────────────────────────────────────────────────────────────
% All conditions so far (redrawn each call; the subject's last condition
% leaves the full overlay) → <Subj>/<Subj>_MEMR_figure.png
if exist(outpath, 'dir')
    try, apat_save_fig(fh, apat_out_dir('all_file', outpath, sprintf('%s_MEMR_figure', subj)), 'memr_ind'); catch, end
end
end
