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
            avg_peaks_locs{1,cols} = nanmean([avg_peaks_locs{1,cols}; peaks_locs{rows,cols}], 1);
            avg_peaks{1,cols}      = nanmean([avg_peaks{1,cols};      peaks{rows,cols}],      1);
            if ~isempty(peaks{rows,cols})
                plv_sum = nansum(peaks{rows,cols}(idx_plv_sum));
                all_low_high_peaks{rows,cols} = [nansum(peaks{rows,cols}(idx_harm)), ...
                                                  nansum(peaks{rows,cols}(idx_harm(end)+1:end))];
            else
                plv_sum = [];
                all_low_high_peaks{rows,cols} = [];
            end
            all_peaks{rows,cols}   = peaks{rows,cols};
            all_plv_sum{rows,cols} = plv_sum;
            peaks_std{1,cols}      = nanstd(cell2mat(all_peaks(:,cols)), 0, 1);
            avg_plv_env{1,cols}    = mean([avg_plv_env{1,cols}; plv_env{rows,cols}], 1);
            avg_f{1,cols}          = mean([avg_f{1,cols};       f{rows,cols}],       1);
            if idx(rows,cols) == 1
                fh_avg = figure(counter); set(fh_avg,'Visible','off');
                hold on;
            end
        end
    end
else
    for cols = 1:length(all_Conds2Run)
        for rows = 1:length(Chins2Run)
            if cols ~= idx_plot_relative && idx(rows,cols) == 1
                avg_peaks_locs{1,cols-1} = nanmean([avg_peaks_locs{1,cols-1}; peaks_locs{rows,cols}], 1);
                avg_peaks{1,cols-1}      = nanmean([avg_peaks{1,cols-1}; peaks{rows,cols}-peaks{rows,idx_plot_relative}], 1);
                plv_sum1   = nansum(peaks{rows,cols}(idx_plv_sum));
                plv_sum2   = nansum(peaks{rows,idx_plot_relative}(idx_plv_sum));
                low_harm   = nansum(peaks{rows,cols}(idx_harm))           - nansum(peaks{rows,idx_plot_relative}(idx_harm));
                high_harm  = nansum(peaks{rows,cols}(idx_harm(end)+1:end)) - nansum(peaks{rows,idx_plot_relative}(idx_harm(end)+1:end));
                all_low_high_peaks{rows,cols-1} = [low_harm, high_harm];
                all_peaks{rows,cols-1}   = peaks{rows,cols} - peaks{rows,idx_plot_relative};
                all_plv_sum{rows,cols-1} = plv_sum1 - plv_sum2;
                peaks_std{1,cols-1}      = nanstd(cell2mat(all_peaks(:,cols-1)), 0, 1);
                avg_plv_env{1,cols-1}    = mean([avg_plv_env{1,cols-1}; plv_env{rows,cols}-plv_env{rows,idx_plot_relative}], 1);
                avg_f{1,cols-1}          = mean([avg_f{1,cols-1}; f{rows,cols}], 1);
                if idx(rows,cols) == 1
                    fh_avg = figure(counter); set(fh_avg,'Visible','off');
                    hold on;
                end
            end
        end
    end
end
average.f              = avg_f;
average.plv_env        = avg_plv_env;
average.peaks_locs     = avg_peaks_locs;
average.peaks          = avg_peaks;
average.peaks_std      = peaks_std;
average.all_plv_sum    = all_plv_sum;
average.all_peaks      = all_peaks;
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
            avg_trajectory{1,cols} = nanmean([avg_trajectory{1,cols}; trajectory{rows,cols}], 1);
            avg_dAMpower{1,cols}   = nanmean([avg_dAMpower{1,cols};   dAMpower{rows,cols}],   1);
            avg_NFpower{1,cols}    = nanmean([avg_NFpower{1,cols};    NFpower{rows,cols}],     1);
            all_trajectory{rows,cols} = trajectory{rows,cols};
            all_dAMpower{rows,cols}   = dAMpower{rows,cols};
            all_NFpower{rows,cols}    = NFpower{rows,cols};
            dAMpower_std{1,cols} = nanstd(cell2mat(all_dAMpower(:,cols)), 0, 1);
            NFpower_std{1,cols}  = nanstd(cell2mat(all_NFpower(:,cols)),  0, 1);
            if idx(rows,cols) == 1
                fh_avg = figure(counter); set(fh_avg,'Visible','off');
                hold on;
                set(gca,'XScale','log');
            end
        end
    end
else
    for cols = 1:length(all_Conds2Run)
        for rows = 1:length(Chins2Run)
            if cols ~= idx_plot_relative && idx(rows,cols) == 1
                avg_trajectory{1,cols-1} = nanmean([avg_trajectory{1,cols-1}; trajectory{rows,cols}], 1);
                avg_dAMpower{1,cols-1}   = nanmean([avg_dAMpower{1,cols-1}; dAMpower{rows,cols}-dAMpower{rows,idx_plot_relative}], 1);
                avg_NFpower{1,cols-1}    = nanmean([avg_NFpower{1,cols-1};  NFpower{rows,cols}-NFpower{rows,idx_plot_relative}],    1);
                all_trajectory{rows,cols-1} = trajectory{rows,cols};
                all_dAMpower{rows,cols-1}   = dAMpower{rows,cols} - dAMpower{rows,idx_plot_relative};
                all_NFpower{rows,cols-1}    = NFpower{rows,cols}  - NFpower{rows,idx_plot_relative};
                dAMpower_std{1,cols-1} = nanstd(cell2mat(all_dAMpower(:,cols-1)), 0, 1);
                NFpower_std{1,cols-1}  = nanstd(cell2mat(all_NFpower(:,cols-1)),  0, 1);
                if idx(rows,cols) == 1
                    fh_avg = figure(counter); set(fh_avg,'Visible','off');
                    hold on;
                    set(gca,'XScale','log');
                end
            end
        end
    end
end
average.trajectory   = avg_trajectory;
average.dAMpower     = avg_dAMpower;
average.NFpower      = avg_NFpower;
average.dAMpower_std = dAMpower_std;
average.NFpower_std  = NFpower_std;
average.all_trajectory = all_trajectory;
average.all_dAMpower   = all_dAMpower;
average.all_NFpower    = all_NFpower;
end
