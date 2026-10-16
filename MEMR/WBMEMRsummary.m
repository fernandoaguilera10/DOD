function WBMEMRsummary(outpath,OUTdir,PRIVATEdir,Conds2Run,Chins2Run,all_Conds2Run,ChinIND,CondIND,idx_plot_relative,xlimits,thresholdlimits,shapes,colors,average_flag,conds_idx)% WBMEMR Analysis
global elicitor deltapow threshold memr_freq memr_resp
% Author: Fernando Aguilera de Alba
% Last Updated: 11 May 2024 by Fernando Aguilera de Alba
% Load Data
cwd = pwd;
%% INDIVIDUAL PLOTS
condition = strsplit(all_Conds2Run{CondIND}, filesep);
if exist(outpath,"dir")
    search_file = cell2mat(['*',Chins2Run(ChinIND),'_MEMR_WB_',condition{2},'*.mat']);
    datafile = load_files(outpath,search_file,'data',[],true);
    cd(outpath);
    S_memr = load(datafile, 'memr');  memr = S_memr.memr;
    % PLOTTING FPL
    elicitor{ChinIND,CondIND} = memr.elicitor;
    deltapow{ChinIND,CondIND} = memr.deltapow';
    threshold{ChinIND,CondIND} = memr.threshold;
    [memr_freq{ChinIND,CondIND}, memr_resp{ChinIND,CondIND}] = memr_spectra(memr);
    plot_ind_memr(memr,'MEMR',colors,Conds2Run,Chins2Run,all_Conds2Run,ChinIND,CondIND,outpath,xlimits,shapes)
    try                                   % rows kept for the average files; CSV next to the .mat
        subj = Chins2Run{ChinIND};
        apat_csv('rec', 'memr', [subj '|' condition{end}], memr_rows(subj, condition{end}, memr), ...
            fullfile(outpath, sprintf('%s_MEMR_%s.csv', subj, condition{end})));
    catch ME, warning('APAT:csv', 'MEMR CSV: %s', ME.message);
    end
    cd(cwd);
else
    fprintf('No directory found.\n');
end
%% AVERAGE PLOTS (individual + average)
if average_flag == 1
    % Exclusions: means / SD / n without the excluded data; subject points
    % keep everyone (excluded ones are marked in the app)
    avgF = avg_memr(elicitor,deltapow,threshold,Chins2Run,Conds2Run,all_Conds2Run,colors,shapes,idx_plot_relative);
    apat_excl('apply', Chins2Run, all_Conds2Run);
    % Plot individual lines
    [average,idx] = avg_memr(elicitor,deltapow,threshold,Chins2Run,Conds2Run,all_Conds2Run,colors,shapes,idx_plot_relative);
    average = apat_excl('merge', avgF, average, {'all_deltapow','all_thresholds'});
    average = avg_memr_resp(average, elicitor, memr_freq, memr_resp, idx_plot_relative);
    % Plot average lines
    outpath = apat_out_dir('avg', fullfile(OUTdir, 'MEMR'));   % Analysis/MEMR/Average
    filename = 'WBMEMR_Average';
    plot_avg_memr(average,'MEMR',colors,idx,Chins2Run,Conds2Run,all_Conds2Run,outpath,filename,xlimits,thresholdlimits,idx_plot_relative,shapes,conds_idx)
    % Individual values (Excluded flag) + cell Mean / SD / N: CSV + average.individual
    try
        I = apat_csv('average', 'memr', fullfile(outpath, 'MEMR_Average.csv'), Chins2Run, all_Conds2Run, idx_plot_relative);
        if apat_csv('avg_mat'), apat_csv('attach', fullfile(outpath, filename), I); end
    catch
    end
end
cd(cwd);
end


function average = avg_memr_resp(average, elicitor, F, R, ref)
% Group mean reflex response (ear-canal pressure change vs frequency) per
% condition and elicitor level -> average.resp{1,c} (levels x freq),
% average.resp_freq{1,c} (Hz), average.resp_elic{1,c}. With a reference
% condition (relative plot) each subject's reference response is
% subtracted first and the columns shift by one, as in avg_memr.
nS = size(R,1);  nC = size(R,2);
nOut = nC;  if ~isempty(ref), nOut = nC - 1; end
average.resp = cell(1, max(nOut,0));  average.resp_freq = average.resp;  average.resp_elic = average.resp;
average.resp_sd = average.resp;                  % SD across subjects (levels x freq)
if isempty(F) || isempty(R), return; end
for c = 1:nC
    if ~isempty(ref) && c == ref, continue; end
    o = c;  if ~isempty(ref), o = c - 1; end         % same column shift as avg_memr
    if o < 1 || o > nOut, continue; end
    f0 = [];  lv = [];
    for s = 1:nS
        if isempty(R{s,c}) || size(elicitor,2) < c, continue; end
        if isempty(f0), f0 = double(F{s,c}(:)'); end
        lv = [lv, double(elicitor{s,c}(:)')]; %#ok<AGROW>
    end
    if isempty(f0), continue; end
    lv = unique(lv(isfinite(lv)));
    acc = nan(numel(lv), numel(f0), nS);
    for s = 1:nS
        if isempty(R{s,c}), continue; end
        y = interp_rows(F{s,c}, R{s,c}, f0);
        if ~isempty(ref)
            if size(R,2) < ref || isempty(R{s,ref}), continue; end
            yr = interp_rows(F{s,ref}, R{s,ref}, f0);
            [~, ia, ib] = intersect(double(elicitor{s,c}(:)'), double(elicitor{s,ref}(:)'));
            y2 = nan(size(y));  y2(ia,:) = y(ia,:) - yr(ib,:);  y = y2;
        end
        e = double(elicitor{s,c}(:)');
        for k = 1:min(numel(e), size(y,1))
            r = find(lv == e(k), 1);
            if ~isempty(r), acc(r,:,s) = y(k,:); end
        end
    end
    average.resp{1,o}      = mean(acc, 3, 'omitnan');
    average.resp_sd{1,o}   = std(acc, 0, 3, 'omitnan');
    average.resp_freq{1,o} = f0;
    average.resp_elic{1,o} = lv;
end
end


function y = interp_rows(f, Y, f0)
f = double(f(:)');  Y = double(Y);
if isequal(numel(f), numel(f0)) && all(abs(f - f0) < 1e-6 * max(f0)), y = Y; return; end
y = nan(size(Y,1), numel(f0));
for k = 1:size(Y,1)
    y(k,:) = interp1(f, Y(k,:), f0, 'linear', NaN);
end
end


function T = memr_rows(subj, cond, memr)
% Tidy CSV rows of one MEMR (ART) recording: reflex magnitude (growth
% function) per elicitor level, the acoustic reflex threshold, trials used.
e = double(memr.elicitor(:));  g = double(memr.deltapow(:));
n = min(numel(e), numel(g));  e = e(1:n);  g = g(1:n);
L = e;  M = repmat({'ReflexMagnitude'}, n, 1);  V = g;  U = repmat({'dB'}, n, 1);
if isfield(memr, 'threshold') && ~isempty(memr.threshold)
    L = [L; NaN];  M = [M; {'ReflexThreshold'}];  V = [V; double(memr.threshold(1))];  U = [U; {'dB FPL'}];
end
if isfield(memr, 'trials') && ~isempty(memr.trials)
    L = [L; NaN];  M = [M; {'TrialsUsed'}];  V = [V; double(memr.trials(1))];  U = [U; {''}];
end
T = apat_csv('mk', struct('Measure','MEMR', 'Subject',subj, 'Condition',cond), ...
    struct('Elicitor_dBFPL',L, 'Metric',{M}, 'Value',V, 'Units',{U}));
end
