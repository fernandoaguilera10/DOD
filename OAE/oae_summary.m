function oae_summary(EXPname, file_tag, outpath, OUTdir, PRIVATEdir, Chins2Run, all_Conds2Run, ...
    ChinIND, CondIND, idx_plot_relative, shapes, colors, average_flag, conds_idx)
%OAE_SUMMARY  Shared summary step for DPOAE / SFOAE / TEOAE.
%   Loads this subject/condition's analysis file, keeps it in the global
%   oae_store (reset per run by define_global_vars), draws the individual
%   figures and — after the last subject/condition — the group figures.
%   Band averaging, SNR criterion and regions come from oae_opts (Setup tab)
%   and are applied here, so changing them needs no re-analysis.
%
%   file_tag  part of the analysis file name, e.g. '_DPOAEswept_'
global oae_store
cwd = pwd;
o = oae_opts();
nS = numel(Chins2Run);  nC = numel(all_Conds2Run);
if ~iscell(oae_store) || ~isequal(size(oae_store), [nS nC])
    oae_store = cell(nS, nC);
end

%% ── Individual ──────────────────────────────────────────────────────────
condition = strsplit(all_Conds2Run{CondIND}, filesep);
if exist(outpath, 'dir')
    search_file = ['*', Chins2Run{ChinIND}, file_tag, condition{end}, '*.mat'];
    datafile = load_files(outpath, search_file, 'data', [], true);
    if ~isempty(datafile)
        S = load(fullfile(outpath, datafile), 'data');
        if isfield(S, 'data')
            if ~isfield(S.data, 'n_trials')            % trials for the individual legend
                S.data.n_trials = oae_trials(S.data, fullfile(outpath, datafile));
            end
            oae_store{ChinIND, CondIND} = S.data;
            plot_ind_oae(S.data, EXPname, colors, shapes, Chins2Run, all_Conds2Run, ...
                ChinIND, CondIND, outpath, conds_idx, o);
            try      % band / region rows kept for the average files + the CSV next to the .mat
                apat_csv('rec', EXPname, [Chins2Run{ChinIND} '|' condition{end}], ...
                    oae_rows(EXPname, Chins2Run{ChinIND}, condition{end}, S.data, o), ...
                    fullfile(outpath, sprintf('%s_%s_%s.csv', Chins2Run{ChinIND}, EXPname, condition{end})));
            catch ME, warning('APAT:csv', '%s CSV: %s', EXPname, ME.message);
            end
        end
    end
else
    fprintf('No directory found.\n');
end

%% ── Average (after the last subject / condition) ────────────────────────
if average_flag == 1
    % Exclusions: means / SD / n without the excluded data; subject points
    % keep everyone (full copy taken before oae_store is masked)
    store_all = oae_store;
    apat_excl('apply', Chins2Run, all_Conds2Run);
    scales = {};
    for sc = {'epl','spl'}
        if any(cellfun(@(d) isstruct(d) && isfield(d, sc{1}) && ~isempty(d.(sc{1})), oae_store(:)))
            scales{end+1} = sc{1}; %#ok<AGROW>
        end
    end
    A = struct();
    for k = 1:numel(scales)
        A.(scales{k}) = avg_oae(oae_store, scales{k}, all_Conds2Run, idx_plot_relative, o);
        try    % subject points: every subject (band_pts / reg_pts), means from the masked data
            AF = avg_oae(store_all, scales{k}, all_Conds2Run, idx_plot_relative, o);
            G = A.(scales{k});
            G.band_pts = G.band;  G.reg_pts = G.reg;
            for kk = 1:numel(G.cols)
                kf = find(AF.cols == G.cols(kk), 1);
                if ~isempty(kf), G.band_pts{kk} = AF.band{kf};  G.reg_pts{kk} = AF.reg{kf}; end
            end
            G.all_oae_band = AF.all_oae_band;
            A.(scales{k}) = G;
        catch
        end
    end
    avg_dir = apat_out_dir('avg', fullfile(OUTdir, 'OAE'));   % Analysis/OAE/Average
    if ~isempty(scales)
        plot_avg_oae(A, EXPname, colors, shapes, Chins2Run, all_Conds2Run, idx_plot_relative, avg_dir, o);
    end
    % Individual values (Excluded flag) + cell Mean / SD / N: CSV, and field
    % average.individual of each <prefix>_Average_<EPL|SPL>.mat (rows of that scale)
    try
        I = apat_csv('average', EXPname, fullfile(avg_dir, sprintf('%s_Average.csv', EXPname)), ...
            Chins2Run, all_Conds2Run, idx_plot_relative);
        if apat_csv('avg_mat') && istable(I)
            pfx = EXPname;  if any(strcmp(EXPname, {'DPOAE','SFOAE'})), pfx = [EXPname 'swept']; end   % as plot_avg_oae
            for sc = {'EPL','SPL'}
                apat_csv('attach', fullfile(avg_dir, sprintf('%s_Average_%s.mat', pfx, sc{1})), I(strcmp(I.Scale, sc{1}), :));
            end
        end
    catch
    end
end
cd(cwd);
end


% ═════════════════════════════════════════════════════════════════════════
function T = oae_rows(meas, subj, cond, data, o)
%OAE_ROWS  Tidy CSV rows of one OAE recording, per scale (EPL / SPL): the
%   band and Low / Mid / High region values (OAE, noise floor, SNR, SNR
%   criterion met as 0/1) with the Setup band options. Frequency_kHz is
%   text: the band centre (e.g. "1.414") or the region range (e.g. "0.5-2").
%   Band edges and the full-resolution spectrum stay in the .mat (plotting).
T = table();
cf = oae_bands(o);
r = o.regions;  rn = {'Low','Mid','High'};
met = {'OAE','NoiseFloor','SNR','MeetsSNRCriterion'};
fb = arrayfun(@(x) sprintf('%.4g', x), cf(:), 'UniformOutput', false);
fr = arrayfun(@(k) sprintf('%g-%g', r(k), r(k+1)), (1:3)', 'UniformOutput', false);
for sc = {'epl','spl'}
    D = oae_derive(data, sc{1}, o);
    if isempty(D), continue; end
    u = ['dB ' upper(sc{1})];
    base = struct('Measure',meas, 'Subject',subj, 'Condition',cond, 'Scale',upper(sc{1}));
    B = D.band;  nb = numel(cf);  G = D.reg;
    T = [T; apat_csv('mk', base, struct( ...
        'Region',{[repmat({''},4*nb,1); repmat(rn(:),4,1)]}, ...
        'Frequency_kHz',{[repmat(fb,4,1); repmat(fr,4,1)]}, ...
        'Metric',{[reshape(repmat(met,nb,1),[],1); reshape(repmat(met,3,1),[],1)]}, ...
        'Value',[B.oae(:); B.nf(:); B.snr(:); double(B.ok(:)); G.oae(:); G.nf(:); G.snr(:); double(G.ok(:))], ...
        'Units',{[repmat({u},2*nb,1); repmat({'dB'},nb,1); repmat({''},nb,1); ...
                  repmat({u},6,1); repmat({'dB'},3,1); repmat({''},3,1)]}))]; %#ok<AGROW>
end
end
