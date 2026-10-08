function average = avg_efr(x1, y1, y2, y3, Chins2Run, Conds2Run, all_Conds2Run, counter, colors, shapes, idx_plot_relative, idx, conds_idx, plot_type)
% Accumulate per-subject EFR data and return average struct.
%   plot_type 'RAM': x1=peaks_locs_all, y1=peaks, y2=f, y3=plv_env
%   plot_type 'dAM': x1=trajectory_smooth, y1=dAMpower_smooth, y2=NFpower_smooth, y3=[]
if isempty(idx_plot_relative)
    conds = length(all_Conds2Run);
else
    conds = length(all_Conds2Run)-1;
end
if conds < 1
    uiwait(msgbox('ERROR: Must have at least 2 conditions to do comparison','Conditions to Run','error'));
    return
end

switch plot_type
    case 'RAM'
        average = avg_RAM(x1, y1, y2, y3, Chins2Run, all_Conds2Run, idx_plot_relative, idx, conds, counter);
    case 'dAM'
        average = avg_dAM(x1, y1, y2, Chins2Run, all_Conds2Run, idx_plot_relative, idx, conds, counter);
end
end


% ── RAM accumulator ───────────────────────────────────────────────────────────
function average = avg_RAM(peaks_locs, peaks, f, plv_env, Chins2Run, all_Conds2Run, idx_plot_relative, idx, conds, counter)
avg_peaks_locs{1,conds} = [];
avg_peaks{1,conds}      = [];
avg_plv_env{1,conds}    = [];
avg_f{1,conds}          = [];
all_peaks{1,conds}      = [];
all_plv_sum{1,conds}    = [];
all_low_high_peaks{1,conds} = [];
peaks_std{1,conds}      = [];
idx_harm    = 1:4;    % low harmonics
idx_plv_sum = 1:16;   % PLV sum range

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
                avg_peaks_locs{1,cols} = nanmean([avg_peaks_locs{1,cols}; peaks_locs{rows,cols}], 1);
                avg_peaks{1,cols}      = nanmean([avg_peaks{1,cols}; p], 1);
                plv_sum = nansum(p(idx_plv_sum));
                all_low_high_peaks{rows,cols} = [nansum(p(idx_harm)), nansum(p(idx_harm(end)+1:end))];
                all_peaks{rows,cols}   = p;
                all_plv_sum{rows,cols} = plv_sum;
            end
            peaks_std{1,cols}   = safe_std(all_peaks(:,cols));
            avg_plv_env{1,cols} = nanmean_rows([avg_plv_env{1,cols}; plv_env{rows,cols}]);
            avg_f{1,cols}       = nanmean_rows([avg_f{1,cols};       f{rows,cols}]);
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
                    avg_peaks_locs{1,c_idx} = nanmean([avg_peaks_locs{1,c_idx}; peaks_locs{rows,cols}], 1);
                    avg_peaks{1,c_idx}      = nanmean([avg_peaks{1,c_idx}; diff_p], 1);
                    plv_sum1   = nansum(pc(idx_plv_sum));
                    plv_sum2   = nansum(pr(idx_plv_sum));
                    low_harm   = nansum(pc(idx_harm))           - nansum(pr(idx_harm));
                    high_harm  = nansum(pc(idx_harm(end)+1:end)) - nansum(pr(idx_harm(end)+1:end));
                    all_low_high_peaks{rows,c_idx} = [low_harm, high_harm];
                    all_peaks{rows,c_idx}   = diff_p;
                    all_plv_sum{rows,c_idx} = plv_sum1 - plv_sum2;
                    avg_plv_env{1,c_idx}    = nanmean_rows([avg_plv_env{1,c_idx}; plv_env{rows,cols}-plv_env{rows,idx_plot_relative}]);
                    avg_f{1,c_idx}          = nanmean_rows([avg_f{1,c_idx}; f{rows,cols}]);
                end
                peaks_std{1,c_idx} = safe_std(all_peaks(:,c_idx));
            end
        end
    end
end
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
                avg_trajectory{1,cols} = nanmean_rows([avg_trajectory{1,cols}; trajectory{rows,cols}]);
                avg_dAMpower{1,cols}   = nanmean_rows([avg_dAMpower{1,cols};   d]);
                avg_NFpower{1,cols}    = nanmean_rows([avg_NFpower{1,cols};    n]);
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
                    avg_trajectory{1,c_idx} = nanmean_rows([avg_trajectory{1,c_idx}; trajectory{rows,cols}]);
                    avg_dAMpower{1,c_idx}   = nanmean_rows([avg_dAMpower{1,c_idx}; dc - dr]);
                    avg_NFpower{1,c_idx}    = nanmean_rows([avg_NFpower{1,c_idx};  nc - nr]);
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
% nanstd across a cell column, skipping empties.
col = col_cell(:);
ne  = find(~cellfun(@isempty, col));
if isempty(ne), s = []; return; end
ref = size(col{ne(1)});
for ri = 1:numel(col)
    if isempty(col{ri}), col{ri} = nan(ref); end
end
s = nanstd(cell2mat(col), 0, 1);
end

function out = nanmean_rows(A)
% mean(A,1) tolerant of empty A.
if isempty(A), out = []; else, out = nanmean(A, 1); end
end
