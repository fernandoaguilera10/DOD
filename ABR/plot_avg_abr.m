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
            y_units, ylimits_threshold, false, Chins2Run);
        idx_temp = idx;
        average.subjects = Chins2Run;
        average.conditions = Conds2Run;
        average.analysis_log = idx;
        % Export
        cd(outpath);
        save(filename,'average');
        drawnow;
        exportgraphics(fh_thr_avg,[filename,'_figure.png'],'Resolution',300);
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
        set(fh,'Visible','off');
        set(fh, 'Name', fig_name_str);
        tl = tiledlayout(fh, t_rows, t_cols, 'TileSpacing','compact', 'Padding','compact');
        title(tl, title_str, 'FontSize',16, 'FontWeight','bold');
        ax1 = [];
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
            for cols = cols_idx
                add_subj_points(ax, average, cols, wnum, colors(cols,:), shapes(wnum,:), peak_analysis, Chins2Run);
            end
            for cols = cols_idx
                errorbar(ax, round(average.x{1,cols}), average.(wf){1,cols}, average.(wsf){1,cols}, ...
                    'Marker',shapes(wnum,:),'LineStyle','-','LineWidth',2,'Color',colors(cols,:),...
                    'MarkerSize',16,'MarkerFaceColor',colors(cols,:),'MarkerEdgeColor',colors(cols,:),...
                    'HandleVisibility','off');
                fit_y = fillmissing(flip(average.(wf){1,cols}),'linear','SamplePoints',flip(round(average.x{1,cols})),'EndValues','none'); fit_y = flip(fit_y);  % bridge interior gaps only, never extrapolate
                plot(ax, round(average.x{1,cols}), fit_y, 'Marker','none','LineStyle','-','LineWidth',2,...
                    'Color',colors(cols,:),'MarkerSize',12,'MarkerFaceColor',colors(cols,:),'MarkerEdgeColor',colors(cols,:),...
                    'HandleVisibility','off');
            end
            if ~isempty(cols_idx)
                x_tks = round(unique(average.x{1,cols_idx(1)}));
            else
                x_tks = [];
            end
            xticks(ax, x_tks);
            if numel(x_tks) > 1, x_pad = (x_tks(end)-x_tks(1))*0.06; xlim(ax,[x_tks(1)-x_pad, x_tks(end)+x_pad]); end
            title(ax, wn, 'FontSize',14); grid(ax,'on'); set(ax,'FontSize',14);
            % Per-tile axis labels: ylabel on left column, xlabel on every tile
            if mod(wi_idx-1, t_cols) == 0, ylabel(ax, y_units, 'FontSize',14, 'FontWeight','bold'); end
            xlabel(ax, x_units, 'FontSize',14, 'FontWeight','bold');
            for cc = find(~cellfun(@isempty, average.(wf)(1,:)))   % n labels drawn last → on top
                add_n_labels(ax, average, cc, wnum, wf);
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
            hold(ax1,'on');
            lh = gobjects(numel(cols_idx),1);
            leg_str = {};
            for li = 1:numel(cols_idx)
                c = cols_idx(li);
                lh(li) = plot(ax1, NaN, NaN, 's', 'MarkerFaceColor',colors(c,:), ...
                    'MarkerEdgeColor','k','MarkerSize',12,'LineWidth',1.5);
                leg_str{li} = sprintf('%s (n = %s)', cell2mat(all_Conds2Run(c)), mat2str(sum(idx(:,c))));
            end
            hold(ax1,'off');
            lg = legend(ax1, lh, leg_str, 'Orientation','horizontal', 'Box','off');
            lg.Layout.Tile = 'south';
        end
        average.subjects   = Chins2Run;
        average.conditions = [convertCharsToStrings(all_Conds2Run(:)');idx];
        % Export
        cd(outpath);
        save(filename,'average');
        print(counter, [filename,'_figure'], '-dpng', '-r300');
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
            y_units, ylimits_threshold, true, Chins2Run);
        idx_temp = idx;
        average.subjects = Chins2Run;
        average.conditions = Conds2Run;
        average.analysis_log = idx;
        % Export
        cd(outpath);
        save(filename,'average');
        drawnow;
        exportgraphics(fh_thr_avg,[filename,'_figure.png'],'Resolution',300);
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
        set(fh,'Visible','off');
        tl = tiledlayout(fh, t_rows, t_cols, 'TileSpacing','compact', 'Padding','compact');
        title(tl, title_str, 'FontSize',16, 'FontWeight','bold');
        n_rel_cols = size(average.w1, 1);  % number of post conditions (rows in average struct)
        ax1 = [];
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
            for cols = 1:n_rel_cols
                if isempty(average.(wf){1,cols}), continue; end
                c_idx = cols + 1;  % colors shifted by 1 for relative plots
                add_subj_points(ax, average, cols, wnum, colors(c_idx,:), shapes(wnum,:), peak_analysis, Chins2Run);
                errorbar(ax, round(average.x{1,cols}), average.(wf){1,cols}, average.(wsf){1,cols}, ...
                    'Marker',shapes(wnum,:),'LineStyle','-','LineWidth',2,'Color',colors(c_idx,:),...
                    'MarkerSize',16,'MarkerFaceColor',colors(c_idx,:),'MarkerEdgeColor',colors(c_idx,:),...
                    'HandleVisibility','off');
                fit_y = fillmissing(flip(average.(wf){1,cols}),'linear','SamplePoints',flip(round(average.x{1,cols})),'EndValues','none'); fit_y = flip(fit_y);  % bridge interior gaps only, never extrapolate
                plot(ax, round(average.x{1,cols}), fit_y,'Marker','none','LineStyle','-','LineWidth',2,...
                    'Color',colors(c_idx,:),'MarkerSize',12,'MarkerFaceColor',colors(c_idx,:),'MarkerEdgeColor',colors(c_idx,:),...
                    'HandleVisibility','off');
                plot(ax, round(average.x{1,cols}), zeros(size(average.x{1,cols})),'LineStyle','--','LineWidth',2,'Color','k','HandleVisibility','off');
            end
            x_tks = round(unique(average.x{1,1}));
            xticks(ax, x_tks);
            if numel(x_tks) > 1, x_pad = (x_tks(end)-x_tks(1))*0.06; xlim(ax,[x_tks(1)-x_pad, x_tks(end)+x_pad]); end
            title(ax, wn, 'FontSize',14); grid(ax,'on'); set(ax,'FontSize',14);
            % Per-tile axis labels: ylabel on left column, xlabel on every tile
            if mod(wi_idx-1, t_cols) == 0, ylabel(ax, y_units, 'FontSize',14, 'FontWeight','bold'); end
            xlabel(ax, x_units, 'FontSize',14, 'FontWeight','bold');
            for cc = find(~cellfun(@isempty, average.(wf)(1,:)))   % n labels drawn last → on top
                add_n_labels(ax, average, cc, wnum, wf);
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
            hold(ax1,'on');
            lh = gobjects(n_rel_cols,1);
            leg_str = {};
            for cols = 1:n_rel_cols
                c_idx = cols + 1;
                lh(cols) = plot(ax1, NaN, NaN, 's', 'MarkerFaceColor',colors(c_idx,:), ...
                    'MarkerEdgeColor','k','MarkerSize',12,'LineWidth',1.5);
                leg_str{cols} = sprintf('%s (n = %s)', cell2mat(Conds2Run(cols+1)), mat2str(sum(idx(:,conds_idx(cols+1)))));
            end
            hold(ax1,'off');
            lg = legend(ax1, lh, leg_str, 'Orientation','horizontal', 'Box','off');
            lg.Layout.Tile = 'south';
        end
        average.subjects   = Chins2Run;
        average.conditions = [convertCharsToStrings(all_Conds2Run(:)');idx];
        % Export
        cd(outpath);
        save(filename,'average');
        print(counter, [filename,'_figure'], '-dpng', '-r300');
    end
end
cd(cwd)
end


function add_n_labels(ax, average, col, wnum, wf)
%ADD_N_LABELS  Sample size (subjects contributing) written inside each data
%   point. Nothing is drawn where n = 0 (no data). Tagged 'abr_n_lbl' so the
%   app can show/hide them.
if ~isfield(average,'n') || numel(average.n) < col || isempty(average.n{1,col}), return; end
cnt = average.n{1,col};
if size(cnt,2) < wnum, return; end
xs = round(average.x{1,col});
ys = average.(wf){1,col};
for li = 1:min(numel(xs), size(cnt,1))
    if cnt(li,wnum) < 1 || ~isfinite(ys(li)), continue; end
    text(ax, xs(li), ys(li), sprintf('%d', cnt(li,wnum)), 'Color',[1 1 1], ...
        'FontSize',9, 'FontWeight','bold', 'HorizontalAlignment','center', ...
        'VerticalAlignment','middle', 'Tag','abr_n_lbl', 'Clipping','on');
end
end


function add_subj_points(ax, average, col, wnum, clr, shp, peak_analysis, subj_names)
%ADD_SUBJ_POINTS  Individual subjects behind the mean (same marker/colour,
%   transparent). Tagged 'abr_subj_pts' and hidden by default; the app's
%   "Subjects" toggle shows them. Exported figures are unchanged.
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
    jit = ((mod(r*7,11)/10) - 0.5) * 1.2;          % small, fixed x-jitter (dB)
    if nargin >= 8 && numel(subj_names) >= r, sn = char(subj_names{r}); else, sn = sprintf('Subject %d', r); end
    scatter(ax, x(ok) + jit, y(ok), 60, clr, shp, 'filled', 'MarkerFaceAlpha',0.30, ...
        'MarkerEdgeColor','none', 'HandleVisibility','off', 'Tag','abr_subj_pts', 'Visible','off', ...
        'DisplayName',sn);
end
end
