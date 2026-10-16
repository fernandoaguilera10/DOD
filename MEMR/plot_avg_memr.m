function plot_avg_memr(average,EXPname,colors,idx,Chins2Run,Conds2Run,all_Conds2Run,outpath,filename,xlimits,thresholdlimits,idx_plot_relative,shapes,conds_idx) %#ok<INUSL>
%PLOT_AVG_MEMR  MEMR group figure (same layout and style as the other measures).
%     left  — mean ± SD ΔAbsorbed power vs elicitor level, conditions side by
%             side (apat_dodge), subject points (Tag 'memr_subj_pts', subject
%             ID in DisplayName). Axes Tag 'memr_avg_ax'.
%     right — threshold mean ± SD per condition + subject points
%             (Axes Tag 'memr_thr_ax').
%   Condition legend (line + marker) at the bottom; right strip left free for
%   the app's controls. Figure Tag 'memr_avg'. Saves <filename>.mat
%   (struct 'average') and <filename>_figure.png.
rel = ~isempty(idx_plot_relative);
col_offset = double(rel);
ref_label = '';
if rel
    p = strsplit(all_Conds2Run{idx_plot_relative}, filesep);  ref_label = p{end};
end
old = findobj('Type','figure','Tag','memr_avg');
if ~isempty(old), close(old); end
fh = figure('NumberTitle','off','Visible','off','Color','w','Tag','memr_avg', ...
    'Units','normalized','Position',[0.05 0.1 0.85 0.75]);
INK = [0.15 0.15 0.15];
ttl = sprintf('%s Average', EXPname);  if rel, ttl = sprintf('%s (re. %s)', ttl, ref_label); end
axH = axes(fh, 'Position',[0 0.92 1 0.06], 'Visible','off');
text(axH, 0.5, 0.5, ttl, 'FontSize',16, 'FontWeight','bold', 'HorizontalAlignment','center', ...
    'Interpreter','none', 'Color',INK);
% left half: growth function + threshold; right half: reflex response
% (right strip beyond 0.82 is left for the app's controls)
ax  = axes(fh, 'Position',[0.06 0.22 0.256 0.64], 'Tag','memr_avg_ax');  hold(ax,'on');   % full width (no strip on the right, Oct 15)
axT = axes(fh, 'Position',[0.377 0.22 0.098 0.64], 'Tag','memr_thr_ax');  hold(axT,'on');

% conditions with data (average.* columns; colours shifted by one when relative)
has = find(~cellfun(@isempty, average.deltapow));
nK  = numel(has);
ev  = [];
for c = has, ev = [ev, double(average.elicitor{1,c}(:)')]; end %#ok<AGROW>
ev = unique(ev(isfinite(ev)));
de = 5;  if numel(ev) > 1, de = median(diff(ev)); end
offs = apat_dodge(nK) * de;
xl = [min([xlimits(1), ev]) - 0.6*de, max([xlimits(2), ev]) + 0.6*de];
xlim(ax, xl);  xlim(axT, [0.5 max(nK,1)+0.5]);
[ms, sa] = apat_ms(ax, 0.7*de);   % points at true x: size from the x spacing
[msT, saT] = apat_ms(axT, 0.7);
LC = struct('clr',{},'shp',{},'label',{});  cn = cell(1, nK);  CC = zeros(nK, 3);
for j = 1:nK
    c  = has(j);  ci = c + col_offset;
    clr = colors(mod(ci-1, size(colors,1)) + 1, 1:3);
    shp = strtrim(char(shapes(mod(ci-1, size(shapes,1)) + 1, :)));  if isempty(shp), shp = 'o'; end
    pc  = strsplit(all_Conds2Run{min(ci, numel(all_Conds2Run))}, filesep);  cn{j} = pc{end};  CC(j,:) = clr;
    n   = 0;  if size(idx,2) >= ci, n = sum(idx(:,ci)); end
    x   = double(average.elicitor{1,c}(:)') + offs(j);
    % subject points (growth + threshold)
    for s = 1:size(average.all_deltapow, 1)
        if size(average.all_deltapow,2) < c || isempty(average.all_deltapow{s,c}), continue; end
        y = double(average.all_deltapow{s,c}(:)');  m = min(numel(x), numel(y));
        jit = ((mod(s*7,11)/10) - 0.5) * 0.06 * de;
        sn = sprintf('Subject %d', s);  if numel(Chins2Run) >= s, sn = char(Chins2Run{s}); end
        scatter(ax, x(1:m) + jit, y(1:m), sa, clr, shp, 'filled', 'MarkerFaceAlpha',0.30, ...
            'MarkerEdgeColor','none', 'HandleVisibility','off', 'Tag','memr_subj_pts', 'DisplayName',sn);
        if size(average.all_thresholds,2) >= c && ~isempty(average.all_thresholds{s,c})
            scatter(axT, j + ((mod(s*7,11)/10) - 0.5) * 0.08, double(average.all_thresholds{s,c}(1)), saT, clr, shp, ...
                'filled', 'MarkerFaceAlpha',0.30, 'MarkerEdgeColor','none', 'HandleVisibility','off', ...
                'Tag','memr_subj_pts', 'DisplayName',sn);
        end
    end
    % mean ± SD
    mu = double(average.deltapow{1,c}(:)');  sd = double(average.deltapow_std{1,c}(:)');
    m  = min([numel(x), numel(mu)]);  sd(end+1:m) = NaN;
    plot(ax, x(1:m), mu(1:m), '-', 'LineWidth',2, 'Color',clr, 'HandleVisibility','off');
    errorbar(ax, x(1:m), mu(1:m), sd(1:m), 'Marker',shp, 'LineStyle','none', 'LineWidth',2, ...
        'MarkerSize',ms, 'Color',clr, 'MarkerFaceColor',clr, 'MarkerEdgeColor',clr, 'HandleVisibility','off');
    tm = average.threshold{1,c};  ts = average.threshold_std{1,c};
    if isempty(ts), ts = NaN; end
    if ~isempty(tm)
        errorbar(axT, j, double(tm(1)), double(ts(1)), 'Marker',shp, 'LineStyle','none', 'LineWidth',2, ...
            'MarkerSize',msT, 'Color',clr, 'MarkerFaceColor',clr, 'MarkerEdgeColor',clr, 'HandleVisibility','off');
    end
    LC(end+1) = struct('clr',clr, 'shp',shp, 'label',sprintf('%s (n = %d)', cn{j}, n)); %#ok<AGROW>
end
if rel
    ylab = sprintf('Reflex Magnitude Shift (dB re. %s)', ref_label);  tlab = 'ART Shift (dB)';
else
    ylab = 'Reflex Magnitude (dB)';  tlab = 'Acoustic Reflex Threshold (dB FPL)';
end
memr_style(ax, axT, ev, de, cn, 'Elicitor Level (dB FPL)', ylab, tlab, rel, CC);
RC = struct('name',{},'clr',{},'f',{},'R',{},'elic',{},'thr',{},'sd',{});
for j = 1:nK
    c = has(j);  f = [];  R = [];  e = [];  sdv = [];
    if isfield(average,'resp') && numel(average.resp) >= c && ~isempty(average.resp{1,c})
        f = average.resp_freq{1,c};  R = average.resp{1,c};  e = average.resp_elic{1,c};
        if isfield(average,'resp_sd') && numel(average.resp_sd) >= c, sdv = average.resp_sd{1,c}; end
    end
    th = NaN;                                          % mean threshold (not when relative: that is a shift)
    if ~rel && ~isempty(average.threshold{1,c}), th = double(average.threshold{1,c}(1)); end
    RC(end+1) = struct('name',cn{j}, 'clr',CC(j,:), 'f',f, 'R',R, 'elic',e, 'thr',th, 'sd',sdv); %#ok<AGROW>
end
[~, KY] = memr_resp_plot(fh, [0.548 0.22 0.415 0.64], RC, ref_label);   % Growth Response + level colour bar
apat_legend(fh, ax, LC, KY, 0.06, 0.903);

%% ── Save data and export ────────────────────────────────────────────────
average.subjects   = Chins2Run;
average.conditions = [convertCharsToStrings(all_Conds2Run(:)'); idx];
if ~exist(outpath, 'dir'), try, mkdir(outpath); catch, end, end
if exist(outpath, 'dir')
    if apat_csv('avg_mat'), try, apat_avg_mat('save', fullfile(outpath, filename), 'average', average); catch, end, end   % average.<EXP>
    try, apat_save_fig(fh, fullfile(outpath, [filename '_figure']), 'memr_avg'); catch, end
end
end
