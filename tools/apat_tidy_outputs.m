function plan = apat_tidy_outputs(ROOTdir, do_it, sheets)
%APAT_TIDY_OUTPUTS  One-time move of an existing Analysis/ tree to the new layout.
%
%   apat_tidy_outputs(ROOTdir)          dry run: prints the planned moves
%   apat_tidy_outputs(ROOTdir, true)    does them
%   apat_tidy_outputs(ROOTdir, do_it, sheets)  sheet names recognised in
%                                       average file names (default BLAST, NOISE)
%   plan = apat_tidy_outputs(...)       n×2 cell {from, to} of the moves
%
%   New layout (Oct 15 2026):
%     Analysis/<Measure>/<Subj>/<pre|post>/<Cond>/  that recording's data
%                                                   file(s) + ONE figure
%     Analysis/<Measure>/<Subj>/                    all-conditions overlay figures
%                                                   (next to pre/ and post/)
%     Analysis/<Measure>/Average/                   group averages (Oct 16 2026,
%                                                   later: ONE file per average
%                                                   for every Experiment — field
%                                                   average.<SHEET>, apat_avg_mat;
%                                                   the Average/<Group>/ folders
%                                                   are no longer written)
%
%   Nothing is deleted: duplicate / obsolete images go to
%   Analysis/_to_delete/<same relative path> (check, then delete that folder
%   yourself). Per-recording .mat files stay where they are (APAT finds its
%   results by those names and locations). ._ files are skipped.
%
%   In each recording folder an image is kept only when it is the
%   recording's own analysis figure (or the ABR Peaks per-recording view):
%     ABR   <S>_<pre|post><Cond>_ABRwaves.png
%           <S>_<Cond>_ABRpeaks_dtw_<f>[_vN]_figure.png
%     EFR   <S>_EFR_<RAM|dAM>_<Cond>_<lev>dBSPL_<raw>_figure.png
%     OAE   <S>_<DPOAEswept|SFOAEswept|TEOAE>_<Cond>_<raw>…_figure.png
%     MEMR  <S>_MEMR_<WB|HP>_<Cond>_pNNNN_figure.png
%   Every other image there → _to_delete: _ABRfit.png, the ABR Thresholds
%   overlay (_ABRthresholds_figure.png), EFR level overlays
%   (<S>_EFR_RAM_65dBSPL_figure.png) and older variants (…_Baseline_figure,
%   …_Time_figure, …_TimeDomain_…, …_Summary_figure), OAE scale overlays
%   (<S>_DPOAE_EPL|SPL|EPL-SPL_figure.png), MEMR overlays
%   (<S>_MEMR_WB_<Cond>_figure.png, <S>_MEMR_<View>_figure.png). The
%   overlays are drawn again in <Subj>/ (next to pre/ post/) on the next run.
%   Exception (no information lost): the old ABR Peaks per-recording view
%   <S>_<pre|post><Cond>_ABRpeaks_<click | f Hz>_figure.png is renamed to
%   its new name <S>_<Cond>_ABRpeaks_dtw_<click | fHz>_figure.png (an older
%   waterfall-only image of that name goes to _to_delete).
%
%   Loose files in Analysis/<Measure>/: group-average .mat / .png / .csv
%   (names with 'Average', ABR_Waveforms_*, ABR_WaterfallWaveforms_*) →
%   <Measure>/Average/. OAE average images: one is kept per OAE type (EPL-SPL
%   view, else EPL, else SPL → <prefix>_Average_figure.png), the other
%   scale variants → _to_delete. Other loose images → _to_delete; other
%   loose files are left alone (listed).
%
%   Analysis groups: an average whose name ends in the sheet (_BLAST /
%   _NOISE before the extension or _figure, e.g.
%   ABR_Thresholds_Average_dBSPL_BLAST.mat) goes to Average/<SHEET>/ —
%   loose ones and ones already in Average/ (old plain-struct files are
%   archived there per sheet: they cannot be merged into the new
%   per-experiment files; APAT's 'find' and tools/format_data still read
%   them). Averages whose group cannot be told from the name stay in
%   Average/. Other sheet names: apat_tidy_outputs(ROOTdir, do_it, {'SHEET1', …}).
if nargin < 2 || isempty(do_it), do_it = false; end
if nargin < 3 || isempty(sheets), sheets = {'BLAST','NOISE'}; end
sheets = cellstr(sheets);
do_it = logical(do_it);
ana = fullfile(ROOTdir, 'Analysis');
plan = cell(0, 2);
if ~exist(ana, 'dir')
    fprintf('apat_tidy_outputs: no Analysis folder in %s\n', ROOTdir);
    return
end
trash = fullfile(ana, '_to_delete');
left = {};
for meas = {'ABR','EFR','OAE','MEMR'}
    m = meas{1};
    mdir = fullfile(ana, m);
    if ~exist(mdir, 'dir'), continue; end
    % ── recording folders <Subj>/<pre|post>/<Cond> ─────────────────────
    for s = subdirs(mdir)
        if any(strcmp(s{1}, {'Average','All Conditions'})), continue; end
        sdir = fullfile(mdir, s{1});
        for pp = subdirs(sdir)
            if strcmp(pp{1}, 'All Conditions'), continue; end
            for c = subdirs(fullfile(sdir, pp{1}))
                cdir = fullfile(sdir, pp{1}, c{1});
                rel  = fullfile(m, s{1}, pp{1}, c{1});
                for f = files(cdir, '*.png')
                    nm = f{1};
                    [keep, newname] = rec_rule(m, nm, s{1}, c{1});
                    if keep, continue; end
                    if ~isempty(newname)
                        tgt = fullfile(cdir, newname);
                        if exist(tgt, 'file')                     % older waterfall-only image
                            plan(end+1,:) = {tgt, fullfile(trash, rel, newname)}; %#ok<AGROW>
                        end
                        plan(end+1,:) = {fullfile(cdir, nm), tgt}; %#ok<AGROW>
                    else
                        plan(end+1,:) = {fullfile(cdir, nm), fullfile(trash, rel, nm)}; %#ok<AGROW>
                    end
                end
            end
        end
    end
    % ── loose files in <Measure>/ ──────────────────────────────────────
    avg = fullfile(mdir, 'Average');
    loose = files(mdir, '*');
    oae_pick = struct();
    for f = loose
        nm = f{1};
        [~, ~, ext] = fileparts(nm);
        is_avg = ~isempty(regexp(nm, 'Average', 'once')) || ...
                 ~isempty(regexp(nm, '^ABR_(Waveforms|WaterfallWaveforms)_', 'once'));
        if strcmp(m, 'OAE') && strcmpi(ext, '.png')
            tok = regexp(nm, '^(.+)_Average_(EPL-SPL|EPL|SPL)_figure\.png$', 'tokens', 'once');
            if ~isempty(tok)                                     % keep one scale view per OAE type
                k = matlab_name(tok{1});
                rank = find(strcmp(tok{2}, {'EPL-SPL','EPL','SPL'}));
                if ~isfield(oae_pick, k), oae_pick.(k) = struct('prefix',tok{1}, 'names',{{}}, 'rank',[]); end
                oae_pick.(k).names{end+1} = nm;  oae_pick.(k).rank(end+1) = rank;
                continue
            end
        end
        if is_avg && any(strcmpi(ext, {'.mat','.png','.csv'}))
            plan(end+1,:) = {fullfile(mdir, nm), fullfile(group_dir(avg, nm, sheets), nm)}; %#ok<AGROW>
        elseif strcmpi(ext, '.png')
            plan(end+1,:) = {fullfile(mdir, nm), fullfile(trash, m, nm)}; %#ok<AGROW>
        else
            left{end+1} = fullfile(m, nm); %#ok<AGROW>
        end
    end
    for k = fieldnames(oae_pick)'
        P = oae_pick.(k{1});
        [~, best] = min(P.rank);
        for i = 1:numel(P.names)
            if i == best
                plan(end+1,:) = {fullfile(mdir, P.names{i}), fullfile(group_dir(avg, P.names{i}, sheets), [P.prefix '_Average_figure.png'])}; %#ok<AGROW>
            else
                plan(end+1,:) = {fullfile(mdir, P.names{i}), fullfile(trash, m, P.names{i})}; %#ok<AGROW>
            end
        end
    end
    % ── averages already in Average/ (no group): into Average/<SHEET>/ when
    % the sheet is in the name; others stay
    for f = files(avg, '*')
        g = group_dir(avg, f{1}, sheets);
        if ~strcmp(g, avg), plan(end+1,:) = {fullfile(avg, f{1}), fullfile(g, f{1})}; end %#ok<AGROW>
    end
end

% ── report / do ──────────────────────────────────────────────────────────
n_avg = 0;  n_del = 0;  n_ren = 0;
for i = 1:size(plan, 1)
    to = plan{i,2};
    if strncmp(to, trash, numel(trash)), n_del = n_del + 1; tag = 'to_delete';
    elseif ~isempty(regexp(to, '[\\/]Average([\\/][^\\/]+)?[\\/][^\\/]+$', 'once')), n_avg = n_avg + 1; tag = 'Average  ';
    else, n_ren = n_ren + 1; tag = 'rename   '; end
    fprintf('%s  %s\n            -> %s\n', tag, rel_of(plan{i,1}, ana), rel_of(to, ana));
end
fprintf('\n%d image(s) to _to_delete, %d file(s) to <Measure>/Average[/<Group>], %d renamed.\n', n_del, n_avg, n_ren);
if ~isempty(left)
    fprintf('Left in place (not average / image files):\n');
    fprintf('    %s\n', left{:});
end
if ~do_it
    fprintf('Dry run — nothing moved. Run apat_tidy_outputs(ROOTdir, true) to move.\n');
    return
end
nf = 0;
for i = 1:size(plan, 1)
    to = plan{i,2};
    d = fileparts(to);
    try
        if ~exist(d, 'dir'), mkdir(d); end
        if exist(to, 'file')        % never overwrite: keep both
            [dd, nn, ee] = fileparts(to);  j = 2;
            while exist(fullfile(dd, sprintf('%s_old%d%s', nn, j, ee)), 'file'), j = j + 1; end
            to = fullfile(dd, sprintf('%s_old%d%s', nn, j, ee));
        end
        [ok, msg] = movefile(plan{i,1}, to);
        if ~ok, error(msg); end
    catch ME
        nf = nf + 1;
        fprintf(2, 'Could not move %s: %s\n', plan{i,1}, ME.message);
    end
end
fprintf('Done: %d moved, %d failed. Check Analysis/_to_delete, then delete it.\n', size(plan,1) - nf, nf);
end


% ═════════════════════════════════════════════════════════════════════════
function [keep, newname] = rec_rule(m, nm, subj, cond)
% Is image nm (in recording folder <subj>/<pre|post>/<cond>) the
% recording's own figure? newname: old ABR Peaks view → its new name.
newname = '';
switch m
    case 'ABR'
        keep = ~isempty(regexp(nm, '_ABRwaves\.png$', 'once')) || ...
               ~isempty(regexp(nm, '_ABRpeaks_dtw_.+_figure\.png$', 'once'));
        if ~keep
            tok = regexp(nm, '_ABRpeaks_(click|[\d.]+ ?Hz)_figure\.png$', 'tokens', 'once');
            if ~isempty(tok)
                newname = sprintf('%s_%s_ABRpeaks_dtw_%s_figure.png', subj, cond, strrep(tok{1}, ' ', ''));
            end
        end
    case 'EFR'
        keep = ~isempty(regexp(nm, '_EFR_(RAM|dAM)_.+_\d+(\.\d+)?dBSPL_.+_figure\.png$', 'once'));
    case 'OAE'
        keep = ~isempty(regexp(nm, '_(DPOAEswept|SFOAEswept|TEOAE)_.+_figure\.png$', 'once')) && ...
               isempty(regexp(nm, '_(DPOAE|SFOAE|TEOAE)_(EPL|SPL|EPL-SPL)_figure\.png$', 'once'));
    case 'MEMR'
        keep = ~isempty(regexp(nm, '_MEMR_(WB|HP)_.+_[^_]+_figure\.png$', 'once'));
    otherwise
        keep = true;
end
end


function g = group_dir(avg, nm, sheets)
% Average/<SHEET> when the file name ends in _<SHEET> (before the extension
% or _figure), else Average/
g = avg;
[~, b] = fileparts(nm);
b = regexprep(b, '_figure$', '');
for k = 1:numel(sheets)
    sh = sheets{k};
    if numel(b) > numel(sh) + 1 && strcmpi(b(end-numel(sh):end), ['_' sh])
        g = fullfile(avg, sh);  return
    end
end
end


function c = subdirs(p)
d = dir(p);
d = d([d.isdir]);
c = {d.name};
c = c(~strncmp(c, '.', 1) & ~strncmp(c, '_', 1));
end


function c = files(p, pat)
d = dir(fullfile(p, pat));
d = d(~[d.isdir]);
c = {d.name};
c = c(~strncmp(c, '._', 2) & ~strncmp(c, '.', 1));
end


function r = rel_of(p, base)
r = p;
if strncmp(p, base, numel(base)), r = p(numel(base)+2:end); end
end


function k = matlab_name(s)
k = regexprep(s, '[^A-Za-z0-9_]', '_');
if isempty(k) || ~isletter(k(1)), k = ['x' k]; end
end
