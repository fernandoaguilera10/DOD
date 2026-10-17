function average = avg_efr(x1, y1, y2, y3, Chins2Run, Conds2Run, all_Conds2Run, counter, colors, shapes, idx_plot_relative, idx, conds_idx, plot_type, env)
% Accumulate per-subject EFR data and return average struct.
%   plot_type 'RAM': x1=peaks_locs_all, y1=peaks, y2=f, y3=plv_env,
%                    env (optional) = envelope waveforms t_env (µV), for
%                    the Magnitude (µV) harmonic sums
%   plot_type 'dAM': x1=trajectory_smooth, y1=dAMpower_smooth, y2=NFpower_smooth, y3=[]
if isempty(idx_plot_relative)
    conds = length(all_Conds2Run);
else
    conds = length(all_Conds2Run)-1;
end
if conds < 1
    try, apat_run_error('error', 'Must have at least 2 conditions to do a comparison (relative mode) — no group average.', 'average'); catch, end
    return
end

switch plot_type
    case 'RAM'
        if nargin < 15 || isempty(env), env = cell(size(y1)); end
        average = avg_RAM(x1, y1, y2, y3, env, Chins2Run, all_Conds2Run, idx_plot_relative, idx, conds, counter);
    case 'dAM'
        average = avg_dAM(x1, y1, y2, Chins2Run, all_Conds2Run, idx_plot_relative, idx, conds, counter);
end
end


% ── RAM accumulator ───────────────────────────────────────────────────────────
function average = avg_RAM(peaks_locs, peaks, f, plv_env, env, Chins2Run, all_Conds2Run, idx_plot_relative, idx, conds, counter)
avg_peaks_locs{1,conds} = [];
avg_peaks{1,conds}      = [];
avg_plv_env{1,conds}    = [];
avg_f{1,conds}          = [];
all_peaks{1,conds}      = [];
all_plv_sum{1,conds}    = [];
all_low_high_peaks{1,conds} = [];
peaks_std{1,conds}      = [];
o = efr_opts();   % low/high harmonic ranges, measure, normalisation (Setup tab)

if isempty(idx_plot_relative)
    for cols = 1:length(all_Conds2Run)
        for rows = 1:length(Chins2Run)
            p = peaks{rows,cols};
            if isempty(p)
                % Subject has no data for this condition — store sentinels
                all_peaks{rows,cols}          = [];
                all_plv_sum{rows,cols}         = NaN;
                all_low_high_peaks{rows,cols}  = [NaN NaN];
            else
                avg_peaks_locs{1,cols} = [avg_peaks_locs{1,cols}; peaks_locs{rows,cols}];
                avg_peaks{1,cols}      = [avg_peaks{1,cols}; p];
                mt = efr_ram_metrics(p, peaks_locs{rows,cols}, f{rows,cols}, plv_env{rows,cols}, o, env{rows,cols});
                all_low_high_peaks{rows,cols} = [mt.low, mt.high];   % chosen measure
                all_peaks{rows,cols}   = p;
                all_plv_sum{rows,cols} = mt.total;                   % PLV, all harmonics
            end
            peaks_std{1,cols}   = safe_std(all_peaks(:,cols));
            avg_plv_env{1,cols} = [avg_plv_env{1,cols}; plv_env{rows,cols}(:)'];
            avg_f{1,cols}       = [avg_f{1,cols}; f{rows,cols}(:)'];   % rows: f is saved as a column
        end
    end
else
    for cols = 1:length(all_Conds2Run)
        for rows = 1:length(Chins2Run)
            if cols ~= idx_plot_relative
                pc = peaks{rows,cols};
                pr = peaks{rows,idx_plot_relative};
                c_idx = cols - (cols > idx_plot_relative);   % destination column index
                if isempty(pc) || isempty(pr) || numel(pc) ~= numel(pr)
                    all_peaks{rows,c_idx}         = [];
                    all_plv_sum{rows,c_idx}        = NaN;
                    all_low_high_peaks{rows,c_idx} = [NaN NaN];
                else
                    diff_p = pc - pr;
                    avg_peaks_locs{1,c_idx} = [avg_peaks_locs{1,c_idx}; peaks_locs{rows,cols}];
                    avg_peaks{1,c_idx}      = [avg_peaks{1,c_idx}; diff_p];
                    mc = efr_ram_metrics(pc, peaks_locs{rows,cols}, f{rows,cols}, plv_env{rows,cols}, o, env{rows,cols});
                    mr = efr_ram_metrics(pr, peaks_locs{rows,idx_plot_relative}, f{rows,idx_plot_relative}, ...
                        plv_env{rows,idx_plot_relative}, o, env{rows,idx_plot_relative});
                    all_low_high_peaks{rows,c_idx} = [mc.low - mr.low, mc.high - mr.high];
                    all_peaks{rows,c_idx}   = diff_p;
                    all_plv_sum{rows,c_idx} = mc.total - mr.total;
                    avg_plv_env{1,c_idx}    = [avg_plv_env{1,c_idx}; plv_env{rows,cols}(:)'-plv_env{rows,idx_plot_relative}(:)'];
                    avg_f{1,c_idx}          = [avg_f{1,c_idx}; f{rows,cols}(:)'];
                end
                peaks_std{1,c_idx} = safe_std(all_peaks(:,c_idx));
            end
        end
    end
end
avg_f          = stack_mean(avg_f, true);
avg_plv_env    = stack_mean(avg_plv_env, true);
avg_peaks_locs = stack_mean(avg_peaks_locs, true);
avg_peaks      = stack_mean(avg_peaks, true);
average.f                  = avg_f;
average.plv_env            = avg_plv_env;
average.peaks_locs         = avg_peaks_locs;
average.peaks              = avg_peaks;
average.peaks_std          = peaks_std;
average.all_plv_sum        = all_plv_sum;
average.all_peaks          = all_peaks;
average.all_low_high_peaks = all_low_high_peaks;
end


% ── dAM accumulator ──────────────────────────────────────────────────────────
function average = avg_dAM(trajectory, dAMpower, NFpower, Chins2Run, all_Conds2Run, idx_plot_relative, idx, conds, counter)
avg_trajectory{1,conds} = [];
avg_dAMpower{1,conds}   = [];
avg_NFpower{1,conds}    = [];
all_trajectory{1,conds} = [];
all_dAMpower{1,conds}   = [];
all_NFpower{1,conds}    = [];
dAMpower_std{1,conds}   = [];
NFpower_std{1,conds}    = [];

if isempty(idx_plot_relative)
    for cols = 1:length(all_Conds2Run)
        for rows = 1:length(Chins2Run)
            d = dAMpower{rows,cols};
            n = NFpower{rows,cols};
            if isempty(d) || isempty(n)
                all_trajectory{rows,cols} = [];
                all_dAMpower{rows,cols}   = [];
                all_NFpower{rows,cols}    = [];
            else
                avg_trajectory{1,cols} = [avg_trajectory{1,cols}; trajectory{rows,cols}];
                avg_dAMpower{1,cols}   = [avg_dAMpower{1,cols}; d];
                avg_NFpower{1,cols}    = [avg_NFpower{1,cols}; n];
                all_trajectory{rows,cols} = trajectory{rows,cols};
                all_dAMpower{rows,cols}   = d;
                all_NFpower{rows,cols}    = n;
            end
            dAMpower_std{1,cols} = safe_std(all_dAMpower(:,cols));
            NFpower_std{1,cols}  = safe_std(all_NFpower(:,cols));
        end
    end
else
    for cols = 1:length(all_Conds2Run)
        for rows = 1:length(Chins2Run)
            if cols ~= idx_plot_relative
                dc = dAMpower{rows,cols};  dr = dAMpower{rows,idx_plot_relative};
                nc = NFpower{rows,cols};   nr = NFpower{rows,idx_plot_relative};
                c_idx = cols - (cols > idx_plot_relative);
                if isempty(dc) || isempty(dr) || isempty(nc) || isempty(nr) || ...
                        numel(dc) ~= numel(dr) || numel(nc) ~= numel(nr)
                    all_trajectory{rows,c_idx} = [];
                    all_dAMpower{rows,c_idx}   = [];
                    all_NFpower{rows,c_idx}    = [];
                else
                    avg_trajectory{1,c_idx} = [avg_trajectory{1,c_idx}; trajectory{rows,cols}];
                    avg_dAMpower{1,c_idx}   = [avg_dAMpower{1,c_idx}; dc - dr];
                    avg_NFpower{1,c_idx}    = [avg_NFpower{1,c_idx}; nc - nr];
                    all_trajectory{rows,c_idx} = trajectory{rows,cols};
                    all_dAMpower{rows,c_idx}   = dc - dr;
                    all_NFpower{rows,c_idx}    = nc - nr;
                end
                dAMpower_std{1,c_idx} = safe_std(all_dAMpower(:,c_idx));
                NFpower_std{1,c_idx}  = safe_std(all_NFpower(:,c_idx));
            end
        end
    end
end
avg_trajectory = stack_mean(avg_trajectory, true);
avg_dAMpower   = stack_mean(avg_dAMpower, true);
avg_NFpower    = stack_mean(avg_NFpower, true);
average.trajectory     = avg_trajectory;
average.dAMpower       = avg_dAMpower;
average.NFpower        = avg_NFpower;
average.dAMpower_std   = dAMpower_std;
average.NFpower_std    = NFpower_std;
average.all_trajectory = all_trajectory;
average.all_dAMpower   = all_dAMpower;
average.all_NFpower    = all_NFpower;
end


% ── Helpers ───────────────────────────────────────────────────────────────────

function s = safe_std(col_cell)
% NaN-ignoring std across a cell column, skipping empties.
col = col_cell(:);
ne  = find(~cellfun(@isempty, col));
if isempty(ne), s = []; return; end
ref = size(col{ne(1)});
for ri = 1:numel(col)
    if isempty(col{ri}), col{ri} = nan(ref); end
end
s = std(cell2mat(col), 0, 1, 'omitmissing');
end

function out = nanmean_rows(A)
% mean(A,1) tolerant of empty A.
if isempty(A), out = []; else, out = mean(A, 1, 'omitmissing'); end
end

function c = stack_mean(c, omit_nan)
% Equal-weight group mean. Each cell holds one row per subject (stacked in
% the loop above); average them in one step so every subject counts 1/N.
% (Replaces the old running mean([avg; new]), which weighted later subjects
% more: a/4 + b/4 + c/2 for three subjects.)
for k = 1:numel(c)
    if isempty(c{k}), continue; end
    if omit_nan, c{k} = mean(c{k}, 1, 'omitnan'); else, c{k} = mean(c{k}, 1); end
end
end
