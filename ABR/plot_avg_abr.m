function plot_avg_abr(average,plot_type,colors,shapes,idx,conds_idx,Chins2Run,Conds2Run,all_Conds2Run,outpath,filename,counter,ylimits_threshold,idx_plot_relative,peak_analysis,freq,wave_sel)
str_plot_relative = strsplit(Conds2Run{idx_plot_relative}, filesep);
legend_string = [];
cwd = pwd;
%% Plot ALL
if isempty(idx_plot_relative)
    %% Thresholds
    if strcmp(plot_type,'Thresholds')
        y_units = 'Threshold (dB SPL)';
        fh_thr_avg = findobj('Type','figure','Tag','APAT_thr_avg');
        if isempty(fh_thr_avg)
            fh_thr_avg = figure('Name','ABR Thresholds Average', ...
                'NumberTitle','off','Tag','APAT_thr_avg','Visible','off');
        else
            fh_thr_avg = fh_thr_avg(1); set(0,'CurrentFigure', fh_thr_avg);
        end
        ref_col = find(~cellfun(@isempty, average.x), 1);
        if ~isempty(ref_col), ref_freqs = average.x{1, ref_col}; else, ref_freqs = [0 500 1000 2000 4000 8000]; end
        cond_names = cellfun(@(c) regexprep(c,'^.*[\\/]',''), all_Conds2Run, 'UniformOutput', false);
        plot_thr_average(fh_thr_avg, average.all_y, ref_freqs, cond_names, colors, shapes, ...
            y_units, ylimits_threshold, false, Chins2Run, pts_of(average));
        idx_temp = idx;
        average.subjects = Chins2Run;
        average.conditions = Conds2Run;
        average.analysis_log = idx;
        % Export
        save_avg(outpath, filename, average, fh_thr_avg, 'abr_thr_avg');
        idx = idx_temp;
%% Peaks
    elseif strcmp(plot_type,'Peaks')
        if freq == 0
            freq_str   = 'Click';
            freq_label = 'Click';
        else
            freq_str = [mat2str(freq),' Hz'];
            if freq >= 1000
                freq_label = sprintf('%.4g kHz', freq/1000);
            else
                freq_label = sprintf('%.4g Hz', freq);
            end
        end
        x_units = 'Sound Level (dB SPL)';
        if strcmp(peak_analysis,'Amplitude')
            y_units = 'Peak-to-Peak Amplitude (\muV)';
            title_str = sprintf('ABR Peak-to-Peak Amplitude (%s)',freq_str);
        elseif strcmp(peak_analysis,'Latency')
            y_units = 'Latency (ms)';
            title_str = sprintf('ABR Absolute Peak Latency (%s)',freq_str);
        end
        % Wave selection defaults
        if ~exist('wave_sel','var') || isempty(wave_sel), wave_sel = true(1,5); end
        valid_cols = cellfun(@(c) ~(isempty(c) || (isnumeric(c) && isequal(size(c),[0 0]))), average.w1);
        cols_idx = find(any(valid_cols, 1));
        if strcmp(peak_analysis,'Latency'), cat_label = 'Latencies'; else, cat_label = [peak_analysis 's']; end
        fig_name_str = [cat_label '|' freq_label];
        all_wave_names  = {'Wave I','Wave II','Wave III','Wave IV','Wave V'};
        all_wave_fields = {'w1','w2','w3','w4','w5'};
        all_wave_std    = {'w1_std','w2_std','w3_std','w4_std','w5_std'};
        shown_wi = find(wave_sel);
        n_tiles  = numel(shown_wi);
        if n_tiles == 0, n_tiles = 1; end
        t_cols = min(n_tiles, 3);
        t_rows = ceil(n_tiles / t_cols);
        % Build single tiledlayout figure
        fh = figure(counter); clf;
        set(fh,'Visible','off', 'Units','normalized', 'Position',[0.05 0.1 0.85 0.75]);
        set(fh, 'Name', fig_name_str);
        tl = tiledlayout(fh, t_rows, t_cols, 'TileSpacing','compact', 'Padding','compact');
        title(tl, title_str, 'FontSize',16, 'FontWeight','bold');
        ax1 = [];  ms_tile = [];
        wave_axes = gobjects(numel(shown_wi), 1);
        % --- Wave tiles ---
        for wi_idx = 1:numel(shown_wi)
            wnum = shown_wi(wi_idx);
            wf   = all_wave_fields{wnum};
            wsf  = all_wave_std{wnum};
            wn   = all_wave_names{wnum};
            ax = nexttile(tl);
            ax.Tag = 'abr_wave_tile';
            wave_axes(wi_idx) = ax;
            if isempty(ax1), ax1 = ax; end
            hold(ax,'on');
            if ~isempty(cols_idx)
                x_tks = round(unique(average.x{1,cols_idx(1)}));
            else
                x_tks = [];
            end
            xticks(ax, x_tks);
            % conditions side by side at each level (same spacing as ABR Thresholds)
            [dx_of, ms, sa, ms_tile] = peak_dodge(ax, x_tks, cols_idx, numel(average.(wf)), ms_tile);
            for cols = cols_idx
                add_subj_points(ax, average, cols, wnum, colors(cols,:), shapes(cols,:), peak_analysis, Chins2Run, dx_of(cols), sa);
            end
            for cols = cols_idx
                errorbar(ax, round(average.x{1,cols}) + dx_of(cols), average.(wf){1,cols}, average.(wsf){1,cols}, ...
                    'Marker',shapes(cols,:),'LineStyle','-','LineWidth',2,'Color',colors(cols,:),...
                    'MarkerSize',ms,'MarkerFaceColor',colors(cols,:),'MarkerEdgeColor',colors(cols,:),...
                    'HandleVisibility','off');
                fit_y = fillmissing(flip(average.(wf){1,cols}),'linear','SamplePoints',flip(round(average.x{1,cols})),'EndValues','none'); fit_y = flip(fit_y);  % bridge interior gaps only, never extrapolate
                plot(ax, round(average.x{1,cols}) + dx_of(cols), fit_y, 'Marker','none','LineStyle','-','LineWidth',2,...
                    'Color',colors(cols,:),'HandleVisibility','off');
            end
            title(ax, wn, 'FontSize',14); grid(ax,'on'); set(ax,'FontSize',14);
            apat_xgroups(ax, x_tks);                 % one column per level
            % Per-tile axis labels: ylabel on left column, xlabel on every tile
            if mod(wi_idx-1, t_cols) == 0, ylabel(ax, y_units, 'FontSize',14, 'FontWeight','bold'); end
            xlabel(ax, x_units, 'FontSize',14, 'FontWeight','bold');
            for cc = find(~cellfun(@isempty, average.(wf)(1,:)))   % n labels drawn last → on top
                add_n_labels(ax, average, cc, wnum, wf, dx_of(min(cc,numel(dx_of))));
            end
            hold(ax,'off');
        end
        % Link wave y-axes so amplitudes/latencies are directly comparable
        if numel(shown_wi) > 1
            linkaxes(wave_axes, 'y');
        end
        % Latency: tight ylim fitted to data+errorbars, ticks every 0.5 ms
        if strcmp(peak_analysis,'Latency') && numel(shown_wi) > 0
            lat_lo = Inf; lat_hi = -Inf;
            for wai = 1:numel(shown_wi)
                wf_tmp  = all_wave_fields{shown_wi(wai)};
                wsf_tmp = all_wave_std{shown_wi(wai)};
                for c_tmp = cols_idx
                    v_tmp = average.(wf_tmp){1,c_tmp};
                    s_tmp = average.(wsf_tmp){1,c_tmp};
                    if ~isempty(v_tmp) && any(isfinite(v_tmp(:)))
                        fin = isfinite(v_tmp(:));
                        err = zeros(size(v_tmp(:)));
                        if ~isempty(s_tmp) && any(isfinite(s_tmp(:))), err = s_tmp(:); err(~isfinite(err)) = 0; end
                        lat_lo = min(lat_lo, min(v_tmp(fin) - err(fin)));
                        lat_hi = max(lat_hi, max(v_tmp(fin) + err(fin)));
                    end
                end
            end
            if isfinite(lat_lo) && isfinite(lat_hi)
                step = 0.5;
                t0 = floor(lat_lo/step)*step;
                t1 = ceil(lat_hi/step)*step;
                set(wave_axes, 'YTick', t0:1:t1, 'YLim', [t0-step/2, t1+step/2]);
            end
        end
        % --- Condition legend (south of entire layout) ---
        if ~isempty(ax1) && ~isempty(cols_idx)
            LC = struct('clr',{},'shp',{},'label',{});
            for c = cols_idx
                LC(end+1) = struct('clr',colors(c,1:3), 'shp',strtrim(char(shapes(c,:))), ...
                    'label',sprintf('%s (n = %d)', last_part(all_Conds2Run{c}), sum(idx(:,c)))); %#ok<AGROW>
            end
            tile_legend(tl, ax1, LC);
        end
        average.subjects   = Chins2Run;
        average.conditions = [convertCharsToStrings(all_Conds2Run(:)');idx];
        % Export
        save_avg(outpath, filename, average, fh, 'abr_peaks_avg');
    end
end
%% Plot relative to Baseline
if ~isempty(idx_plot_relative)  
    %% Thresholds
    if strcmp(plot_type,'Thresholds')
        y_units = sprintf('Threshold Shift (re. %s)',str_plot_relative{2});
        fh_thr_avg = findobj('Type','figure','Tag','APAT_thr_avg');
        if isempty(fh_thr_avg)
            fh_thr_avg = figure('Name','ABR Thresholds Average', ...
                'NumberTitle','off','Tag','APAT_thr_avg','Visible','off');
        else
            fh_thr_avg = fh_thr_avg(1); set(0,'CurrentFigure', fh_thr_avg);
        end
        ref_col = find(~cellfun(@isempty, average.x), 1);
        if ~isempty(ref_col), ref_freqs = average.x{1, ref_col}; else, ref_freqs = [0 500 1000 2000 4000 8000]; end
        cond_names = cellfun(@(c) regexprep(c,'^.*[\\/]',''), all_Conds2Run(2:end), 'UniformOutput', false);
        plot_thr_average(fh_thr_avg, average.all_y, ref_freqs, cond_names, colors(2:end,:), shapes(2:end,:), ...
            y_units, ylimits_threshold, true, Chins2Run, pts_of(average));
        idx_temp = idx;
        average.subjects = Chins2Run;
        average.conditions = Conds2Run;
        average.analysis_log = idx;
        % Export
        save_avg(outpath, filename, average, fh_thr_avg, 'abr_thr_avg');
        idx = idx_temp;
    elseif strcmp(plot_type,'Peaks')
        x_units = 'Sound Level (dB SPL)';
        if strcmp(peak_analysis,'Amplitude')
            y_units = sprintf('Peak-to-Peak Amplitude Shift (re. %s)',str_plot_relative{2});
            title_str = sprintf('ABR Peak-to-Peak Amplitude');
        elseif strcmp(peak_analysis,'Latency')
            y_units = sprintf('Latency Shift (re. %s)',str_plot_relative{2});
            title_str = sprintf('ABR Absolute Peak Latency');
        end
        % Wave selection defaults
        if ~exist('wave_sel','var') || isempty(wave_sel), wave_sel = true(1,5); end
        all_wave_names  = {'Wave I','Wave II','Wave III','Wave IV','Wave V'};
        all_wave_fields = {'w1','w2','w3','w4','w5'};
        all_wave_std    = {'w1_std','w2_std','w3_std','w4_std','w5_std'};
        shown_wi = find(wave_sel);
        n_tiles  = numel(shown_wi);
        if n_tiles == 0, n_tiles = 1; end
        t_cols = min(n_tiles, 3);
        t_rows = ceil(n_tiles / t_cols);
        % Build single tiledlayout figure
        fh = figure(counter); clf;
        set(fh,'Visible','off', 'Units','normalized', 'Position',[0.05 0.1 0.85 0.75]);
        tl = tiledlayout(fh, t_rows, t_cols, 'TileSpacing','compact', 'Padding','compact');
        title(tl, title_str, 'FontSize',16, 'FontWeight','bold');
        n_rel_cols = size(average.w1, 1);  % number of post conditions (rows in average struct)
        ax1 = [];  ms_tile = [];  ms_tile = [];
        wave_axes = gobjects(numel(shown_wi), 1);
        % --- Wave tiles ---
        for wi_idx = 1:numel(shown_wi)
            wnum = shown_wi(wi_idx);
            wf   = all_wave_fields{wnum};
            wsf  = all_wave_std{wnum};
            wn   = all_wave_names{wnum};
            ax = nexttile(tl);
            ax.Tag = 'abr_wave_tile';
            if isempty(ax1), ax1 = ax; end
            hold(ax,'on');
            x_tks = round(unique(average.x{1,1}));
            xticks(ax, x_tks);
            rel_cols = find(~cellfun(@isempty, average.(wf)(1,:)));
            rel_cols = rel_cols(rel_cols <= n_rel_cols);
            [dx_of, ms, sa, ms_tile] = peak_dodge(ax, x_tks, rel_cols, numel(average.(wf)), ms_tile);
            for cols = rel_cols
                c_idx = cols + 1;  % colors shifted by 1 for relative plots
                add_subj_points(ax, average, cols, wnum, colors(c_idx,:), shapes(c_idx,:), peak_analysis, Chins2Run, dx_of(cols), sa);
                errorbar(ax, round(average.x{1,cols}) + dx_of(cols), average.(wf){1,cols}, average.(wsf){1,cols}, ...
                    'Marker',shapes(c_idx,:),'LineStyle','-','LineWidth',2,'Color',colors(c_idx,:),...
                    'MarkerSize',ms,'MarkerFaceColor',colors(c_idx,:),'MarkerEdgeColor',colors(c_idx,:),...
                    'HandleVisibility','off');
                fit_y = fillmissing(flip(average.(wf){1,cols}),'linear','SamplePoints',flip(round(average.x{1,cols})),'EndValues','none'); fit_y = flip(fit_y);  % bridge interior gaps only, never extrapolate
                plot(ax, round(average.x{1,cols}) + dx_of(cols), fit_y,'Marker','none','LineStyle','-','LineWidth',2,...
                    'Color',colors(c_idx,:),'HandleVisibility','off');
            end
            if ~isempty(rel_cols)
                xx = xlim(ax);
                plot(ax, xx, [0 0],'LineStyle','--','LineWidth',2,'Color','k','HandleVisibility','off');
            end
            title(ax, wn, 'FontSize',14); grid(ax,'on'); set(ax,'FontSize',14);
            apat_xgroups(ax, x_tks);                 % one column per level
            % Per-tile axis labels: ylabel on left column, xlabel on every tile
            if mod(wi_idx-1, t_cols) == 0, ylabel(ax, y_units, 'FontSize',14, 'FontWeight','bold'); end
            xlabel(ax, x_units, 'FontSize',14, 'FontWeight','bold');
            for cc = find(~cellfun(@isempty, average.(wf)(1,:)))   % n labels drawn last → on top
                add_n_labels(ax, average, cc, wnum, wf, dx_of(min(cc,numel(dx_of))));
            end
            hold(ax,'off');
            wave_axes(wi_idx) = ax;
        end
        % Link wave y-axes for comparable view across waves
        valid_wave_ax = wave_axes(arrayfun(@(a) ~isequal(a, gobjects(1)), wave_axes) & isvalid(wave_axes));
        if numel(valid_wave_ax) > 1
            linkaxes(valid_wave_ax, 'y');
        end
        % Latency: tight ylim fitted to data+errorbars, ticks every 0.5 ms
        if strcmp(peak_analysis,'Latency') && numel(valid_wave_ax) > 0
            lat_lo = Inf; lat_hi = -Inf;
            for wai = 1:numel(shown_wi)
                wf_tmp  = all_wave_fields{shown_wi(wai)};
                wsf_tmp = all_wave_std{shown_wi(wai)};
                for c_tmp = 1:n_rel_cols
                    v_tmp = average.(wf_tmp){1,c_tmp};
                    s_tmp = average.(wsf_tmp){1,c_tmp};
                    if ~isempty(v_tmp) && any(isfinite(v_tmp(:)))
                        fin = isfinite(v_tmp(:));
                        err = zeros(size(v_tmp(:)));
                        if ~isempty(s_tmp) && any(isfinite(s_tmp(:))), err = s_tmp(:); err(~isfinite(err)) = 0; end
                        lat_lo = min(lat_lo, min(v_tmp(fin) - err(fin)));
                        lat_hi = max(lat_hi, max(v_tmp(fin) + err(fin)));
                    end
                end
            end
            if isfinite(lat_lo) && isfinite(lat_hi)
                step = 0.5;
                t0 = floor(lat_lo/step)*step;
                t1 = ceil(lat_hi/step)*step;
                set(valid_wave_ax, 'YTick', t0:step:t1, 'YLim', [t0-step/2, t1+step/2]);
            end
        end
        % --- Condition legend (south of entire layout) ---
        if ~isempty(ax1)
            LC = struct('clr',{},'shp',{},'label',{});
            for cols = 1:n_rel_cols
                c_idx = cols + 1;
                LC(end+1) = struct('clr',colors(c_idx,1:3), 'shp',strtrim(char(shapes(c_idx,:))), ...
                    'label',sprintf('%s (n = %d)', last_part(Conds2Run{cols+1}), sum(idx(:,conds_idx(cols+1))))); %#ok<AGROW>
            end
            tile_legend(tl, ax1, LC);
        end
        average.subjects   = Chins2Run;
        average.conditions = [convertCharsToStrings(all_Conds2Run(:)');idx];
        % Export
        save_avg(outpath, filename, average, fh, 'abr_peaks_avg');
    end
end
cd(cwd)
end


function save_avg(outpath, filename, average, fh, view_key)
%SAVE_AVG  Group data (<filename>.mat, not in CSV-only mode) and the group
%   figure (<filename>_figure.png) in outpath (= Analysis/ABR/Average).
if ~exist(outpath, 'dir'), try, mkdir(outpath); catch, end, end
if apat_csv('avg_mat')
    % one file for every Experiment: average.<EXP> (apat_avg_mat)
    try, apat_avg_mat('save', fullfile(outpath, filename), 'average', average); catch, end
end
drawnow;
try, apat_save_fig(fh, fullfile(outpath, [filename '_figure']), view_key); catch, end
end


function [dx_of, ms, sa, ms_tile] = peak_dodge(ax, x_tks, cols, n_cols, ms_tile)
%PEAK_DODGE  Conditions side by side at each level (apat_dodge spacing,
%   fraction of the level step), x-limits with room for the offsets, and the
%   shared marker size (computed once per figure, all tiles the same size).
dl = 10;
if numel(x_tks) > 1, dl = min(diff(x_tks)); end
offs = apat_dodge(numel(cols)) * dl;
dx_of = zeros(1, max([n_cols, cols(:)', 1]));
if ~isempty(cols), dx_of(cols) = offs; end
if numel(x_tks) > 1
    x_pad = max((x_tks(end)-x_tks(1))*0.06, max(abs(offs)) + 0.35*dl);
    xlim(ax, [x_tks(1)-x_pad, x_tks(end)+x_pad]);
end
if isempty(ms_tile)
    drawnow;                                   % tile sizes are known after layout
    ms_tile = apat_ms(ax, 0.7*dl);   % points at true x: size from the x spacing
end
ms = ms_tile;
sa = max(36, round(90 * (ms/20)^2));
end


function tile_legend(tl, ax1, LC)
%TILE_LEGEND  Condition legend (line + condition marker, as every measure)
%   in the south tile of the layout.
hold(ax1, 'on');
lh = gobjects(1, numel(LC));
for k = 1:numel(LC)
    lh(k) = plot(ax1, NaN, NaN, 'LineStyle','-', 'Marker',LC(k).shp, 'MarkerSize',10, 'LineWidth',2, ...
        'Color',LC(k).clr, 'MarkerFaceColor',LC(k).clr, 'MarkerEdgeColor',LC(k).clr, 'Tag','apat_leg_item');
end
hold(ax1, 'off');
lg = legend(ax1, lh, {LC.label}, 'Orientation','horizontal', 'Box','off', 'FontSize',13, ...
    'Interpreter','none', 'AutoUpdate','off');
lg.Tag = 'apat_legend';
lg.Layout.Tile = 'south';
end


function s = last_part(p)
s = regexprep(char(p), '^.*[\\/]', '');
end


function add_n_labels(ax, average, col, wnum, wf, dx)
if nargin < 6, dx = 0; end
%ADD_N_LABELS  Sample size (subjects contributing) written inside each data
%   point. Nothing is drawn where n = 0 (no data). Tagged 'abr_n_lbl' so the
%   app can show/hide them.
if ~isfield(average,'n') || numel(average.n) < col || isempty(average.n{1,col}), return; end
cnt = average.n{1,col};
if size(cnt,2) < wnum, return; end
xs = round(average.x{1,col}) + dx;
ys = average.(wf){1,col};
for li = 1:min(numel(xs), size(cnt,1))
    if cnt(li,wnum) < 1 || ~isfinite(ys(li)), continue; end
    text(ax, xs(li), ys(li), sprintf('%d', cnt(li,wnum)), 'Color',[1 1 1], ...
        'FontSize',9, 'FontWeight','bold', 'HorizontalAlignment','center', ...
        'VerticalAlignment','middle', 'Tag','abr_n_lbl', 'Clipping','on');
end
end


function add_subj_points(ax, average, col, wnum, clr, shp, peak_analysis, subj_names, dx, sa)
%ADD_SUBJ_POINTS  Individual subjects behind the mean (same marker/colour,
%   transparent). Tagged 'abr_subj_pts' and hidden by default; the app's
%   "Subjects" toggle shows them. Exported figures are unchanged.
if nargin < 9, dx = 0; end
if nargin < 10, sa = 60; end
fx = 'all_x_subj';  fw = sprintf('all_w%d', wnum);
if ~isfield(average, fw) || ~isfield(average, fx), return; end
X = average.(fx);  Y = average.(fw);
if size(Y,2) < col, return; end
shp = strtrim(char(shp));  if isempty(shp), shp = 'o'; end
for r = 1:size(Y,1)
    y = Y{r,col};  if isempty(y) || size(X,1) < r || isempty(X{r,col}), continue; end
    x = round(X{r,col}(:));  y = y(:);
    m = min(numel(x), numel(y));  x = x(1:m);  y = y(1:m);
    ok = isfinite(x) & isfinite(y);
    if ~any(ok), continue; end
    jit = ((mod(r*7,11)/10) - 0.5) * 0.6;          % small, fixed x-jitter (dB), inside the dodge slot
    if nargin >= 8 && numel(subj_names) >= r, sn = char(subj_names{r}); else, sn = sprintf('Subject %d', r); end
    scatter(ax, x(ok) + dx + jit, y(ok), sa, clr, shp, 'filled', 'MarkerFaceAlpha',0.30, ...
        'MarkerEdgeColor','none', 'HandleVisibility','off', 'Tag','abr_subj_pts', 'Visible','off', ...
        'DisplayName',sn);
end
end


function P = pts_of(average)
% Subject points incl. data excluded from the average (Exclusions); [] = same as all_y
P = [];
if isfield(average, 'all_y_pts'), P = average.all_y_pts; end
end
