function out = apat_res_store(action, varargin)
%APAT_RES_STORE  One file per finished analysis with everything the Results
%   tab shows (user, Oct 17 2026): every subject's individual figures, the
%   average figures and what the views need (conditions, colours, markers,
%   plot defaults). The Results tab can then be rebuilt from it in seconds
%   (private/res_load.m): "Load Saved Results" on the Setup tab (browse
%   earlier results without running anything) and Resume (analyses that were
%   already done are loaded, not run again).
%
%   File: Analysis/<Measure>/Results/<Analysis>_<Experiment>_Results.mat
%     meta  struct: label (Results label, 'EFR dAM' …), exp1 / exp2 (measure
%           folder / type), sheet, subjects (order shown), conds, time
%           (datenum of saving), saved (text), run_conds, plot_defaults
%     ind   struct array: subj, figs (cell of uint8 — the bytes of a .fig
%           file per figure, in the order they are embedded)
%     avg   cell of uint8 (average figures, .fig bytes)
%   Figures are stored as they were built (Save Image paths kept), with no
%   image waiting to be written, so loading never re-exports images.
%
%   apat_res_store('begin', file, meta)   analysis_run, before the subjects
%   apat_res_store('add_ind', subj, figs) a subject's individual figures
%   apat_res_store('add_avg', figs)       the average figures
%   apat_res_store('complete')            analysis_run reached its end
%   apat_res_store('commit', extra)       RunButtonPushed>run_one after a
%                                         successful analysis: extra fields
%                                         of meta (run_conds, plot_defaults);
%                                         written only after 'complete'
%   apat_res_store('drop')                forget (error / Stop / blind)
%   f = apat_res_store('file', adir, label, sheet)   path of that file
%   R = apat_res_store('read', file)      struct with meta / ind / avg ([] if none)
%   Never throws.
out = [];
try
    switch action
        case 'begin'
            S = struct('file',varargin{1}, 'meta',varargin{2}, ...
                'ind',struct('subj',{}, 'figs',{}), 'avg',{{}}, 'complete',false);
            setappdata(0, 'APAT_res_store', S);
        case 'add_ind'
            if ~isappdata(0, 'APAT_res_store'), return; end
            S = getappdata(0, 'APAT_res_store');
            subj = char(varargin{1});  [B, Fs] = blobs(varargin{2});
            % the same bytes serve embed_results>park (no second savefig)
            setappdata(0, 'APAT_res_last', struct('figs', Fs, 'blobs', {B}));
            k = find(strcmp({S.ind.subj}, subj), 1);
            if isempty(k), k = numel(S.ind) + 1; end
            S.ind(k).subj = subj;  S.ind(k).figs = B;
            setappdata(0, 'APAT_res_store', S);
        case 'add_avg'
            if ~isappdata(0, 'APAT_res_store'), return; end
            S = getappdata(0, 'APAT_res_store');
            S.avg = [S.avg, blobs(varargin{1})];
            setappdata(0, 'APAT_res_store', S);
        case 'complete'
            if ~isappdata(0, 'APAT_res_store'), return; end
            S = getappdata(0, 'APAT_res_store');  S.complete = true;
            setappdata(0, 'APAT_res_store', S);
        case 'commit'
            if ~isappdata(0, 'APAT_res_store'), return; end
            S = getappdata(0, 'APAT_res_store');
            rmappdata(0, 'APAT_res_store');
            if isappdata(0, 'APAT_res_last'), rmappdata(0, 'APAT_res_last'); end
            if ~S.complete || (isempty(S.ind) && isempty(S.avg)), return; end
            meta = S.meta;
            if nargin >= 2 && isstruct(varargin{1})
                x = varargin{1};
                for f = fieldnames(x)', meta.(f{1}) = x.(f{1}); end
            end
            meta.time = now; %#ok<TNOW1>
            meta.saved = char(datetime('now', 'Format', 'yyyy-MM-dd HH:mm'));
            meta.subjects = {S.ind.subj};
            ind = S.ind;  avg = S.avg; %#ok<NASGU>
            d = fileparts(S.file);
            if ~exist(d, 'dir'), mkdir(d); end
            tmp = [S.file(1:end-4) '_tmp.mat'];
            try
                save(tmp, 'meta', 'ind', 'avg', '-v7');
            catch
                save(tmp, 'meta', 'ind', 'avg', '-v7.3');   % very large runs
            end
            movefile(tmp, S.file, 'f');                       % never a half-written file
        case 'drop'
            if isappdata(0, 'APAT_res_store'), rmappdata(0, 'APAT_res_store'); end
            if isappdata(0, 'APAT_res_last'), rmappdata(0, 'APAT_res_last'); end
        case 'file'
            adir = char(varargin{1});  label = char(varargin{2});  sheet = char(varargin{3});
            out = fullfile(adir, measure_folder(label), 'Results', ...
                sprintf('%s_%s_Results.mat', clean(label), clean(sheet)));
        case 'read'
            f = varargin{1};
            if exist(f, 'file') ~= 2, return; end
            out = load(f, 'meta', 'ind', 'avg');
            if ~isfield(out, 'meta') || ~isfield(out, 'ind'), out = []; end
    end
catch err
    if any(strcmp(action, {'commit','read'}))
        warning('APAT:resStore', 'Saved Results (%s): %s', action, err.message);
    end
    if strcmp(action, 'commit') && isappdata(0, 'APAT_res_store'), rmappdata(0, 'APAT_res_store'); end
end
end


function [B, Fs] = blobs(figs)
% .fig bytes of each figure (temporary file), with no pending image; Fs =
% the figures they belong to
B = {};  Fs = gobjects(0);
for f = reshape(figs, 1, [])
    if ~isgraphics(f), continue; end
    tmp = [tempname '.fig'];
    pend = [];
    try
        if isappdata(f, 'apat_save_pending')
            pend = getappdata(f, 'apat_save_pending');  setappdata(f, 'apat_save_pending', false);
        end
        savefig(f, tmp, 'compact');
        fid = fopen(tmp, 'r');  B{end+1} = fread(fid, inf, '*uint8'); fclose(fid); %#ok<AGROW>
        Fs(end+1) = f; %#ok<AGROW>
    catch
    end
    if ~isempty(pend), try, setappdata(f, 'apat_save_pending', pend); catch, end, end
    if exist(tmp, 'file'), delete(tmp); end
end
end


function m = measure_folder(label)
switch strtok(label)
    case {'ABR','EFR','MEMR'}, m = strtok(label);
    otherwise,                 m = 'OAE';            % DPOAE / SFOAE / TEOAE
end
end


function s = clean(s)
s = regexprep(strtrim(char(s)), '[^\w\-]+', '_');
end
