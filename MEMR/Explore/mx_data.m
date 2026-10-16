function out = mx_data(action, varargin)
%MX_DATA  Data side of the exploratory MEMR views (no plotting).
%
%   Q = mx_data('quant', type, mx)
%       What one recording contributes to view TYPE ('Vector', 'Growth',
%       'Kinetics', 'Spectral', 'Absorbance', 'Probe', 'Quality'):
%         Q.ok    false when the view has no data for it (e.g. Absorbance
%                 without an FPL calibration)
%         Q.elic  elicitor levels (dB FPL)
%         Q.lev   struct of series vs elicitor level (same length as elic)
%         Q.sca   struct of scalars
%         Q.cur   struct of curves  .x .y
%         Q.fam   one family of curves (one per level): .x .Y (levels x x)
%                 .elic   ([] when the view has none)
%         Q.note  short text shown under the figure title
%
%   A = mx_data('avg', type, F, M, Chins2Run, all_Conds2Run, colors, shapes, ref)
%       Group data per output condition. F = results of everyone (subject
%       points), M = without the excluded subject / condition pairs (means,
%       SD, n). ref = index of the reference condition when plotting
%       relative to it ([] = absolute): every subject's reference values are
%       subtracted from its other conditions (matched by elicitor level) and
%       the reference column is left out. Each condition keeps its own
%       colour / marker (by its real index).
%         A.subjects, A.cols(j): name, clr, shp, idx, n, lev.(key).x/.M/.F
%         (subjects x levels), sca.(key).M/.F (subjects x 1),
%         cur.(key).x/.M/.F, fam.x/.elic/.M/.F (subjects x levels x x)
%
%   s = mx_data('stats', X)   mean / SD / n over the rows of X, NaN ignored
%                             (SD = 0 for a single subject, as in ART)

switch action
    case 'quant', out = quant(varargin{:});
    case 'avg',   out = group(varargin{:});
    case 'stats', out = stats(varargin{1});
    otherwise,    error('mx_data: unknown action %s', action);
end
end


% ══════════════════════════════════════════════════════════════════════════
function Q = quant(type, mx)
Q = struct('ok',true, 'elic',[], 'lev',struct(), 'sca',struct(), 'cur',struct(), ...
    'fam',struct('x',[],'Y',[],'elic',[]), 'note','');
if ~isstruct(mx) || ~isfield(mx, 'elicitor'), Q.ok = false; return; end
lev = double(mx.elicitor(:)');
Q.elic = lev;
Q.ntr  = NaN;  if isfield(mx, 'n_trials'), Q.ntr = double(mx.n_trials); end   % trials (individual legend)
top = numel(lev);
switch type
    case 'Vector'
        Q.lev.V  = mx.V;
        Q.lev.Vn = mx.Vn;
        Q.lev.P  = mx.P_db;
        Q.sca.thr_nf = mx.thr_nf;
        Q.sca.vart   = mx.vart;
    case 'Growth'
        Q.lev.V  = mx.V;
        Q.lev.Vn = mx.Vn;
        g = mx.gf;
        Q.cur.fit = struct('x', g.fit_x, 'y', g.fit_y);
        Q.sca.max   = g.max;
        Q.sca.x0    = g.x0;
        Q.sca.slope = g.slope_mid;
        Q.sca.dyn   = g.dyn_range;
        Q.sca.auc   = g.auc;
        Q.sca.supra = g.supra_slope;
    case 'Kinetics'
        k = mx.kin;
        Q.lev.bi = k.bi;
        Q.sca.tau = k.tau(top);
        Q.fam = struct('x', k.t_ms, 'Y', k.Vr, 'elic', lev);
    case 'Spectral'
        s = mx.sp;
        bc = sqrt(s.bands(:,1) .* s.bands(:,2))';      % band centres (Hz)
        Q.cur.band = struct('x', bc, 'y', s.band_db(top, :));
        Q.sca.peak = s.peak_f(top) / 1e3;
        Q.fam = struct('x', s.fl, 'Y', s.db, 'elic', lev);
    case 'Absorbance'
        a = mx.ab;
        Q.note = a.note;
        if ~a.ok, Q.ok = false; return; end
        Q.lev.dA_low = a.dA_low;
        Q.lev.dA_mid = a.dA_mid;
        Q.cur.A0 = struct('x', a.fl, 'y', a.A0);
        Q.fam = struct('x', a.fl, 'Y', a.dA, 'elic', lev);
    case 'Probe'
        p = mx.pr;
        if isempty(p.D), Q.ok = false; Q.note = 'No elicitor-probe data'; return; end
        Q.lev.D = p.Dmean;
        Q.lev.N = p.Nmean;
        Q.sca.thr = p.thr;
        Q.fam = struct('x', p.t_ms, 'Y', p.D, 'elic', lev);
    case 'Quality'
        q = mx.q;
        Q.lev.good  = 100 * q.good_frac;
        Q.lev.var   = q.base_var;
        Q.lev.drift = q.drift;
        Q.lev.snr   = q.snr;
        Q.lev.psnr  = q.probe_snr;
        Q.sca.ntr   = q.n_trials;
    otherwise
        error('mx_data: unknown view %s', type);
end
% every level series as a row of the same length as elic
fn = fieldnames(Q.lev);
for i = 1:numel(fn)
    v = double(Q.lev.(fn{i})(:)');
    if numel(v) ~= numel(lev), v = nan(1, numel(lev)); end
    Q.lev.(fn{i}) = v;
end
end


% ══════════════════════════════════════════════════════════════════════════
function A = group(type, F, M, Chins, Conds, colors, shapes, ref)
nS = size(F, 1);  nC = size(F, 2);
if nargin < 8, ref = []; end
QF = cell(nS, nC);  QM = cell(nS, nC);
for s = 1:nS
    for c = 1:nC
        if ~isempty(F{s,c}), QF{s,c} = quant(type, F{s,c}); end
        if size(M,1) >= s && size(M,2) >= c && ~isempty(M{s,c}), QM{s,c} = quant(type, M{s,c}); end
    end
end
cols = 1:nC;
if ~isempty(ref), cols(cols == ref) = []; end
A = struct();
A.type = type;
A.subjects = Chins(:)';
A.relative = ~isempty(ref);
A.ref_name = '';
if ~isempty(ref), A.ref_name = last_part(Conds{ref}); end
A.cols = struct('name',{}, 'clr',{}, 'shp',{}, 'idx',{}, 'n',{}, 'lev',{}, 'sca',{}, 'cur',{}, 'fam',{});
for c = cols
    has = false(1, nS);
    for s = 1:nS
        has(s) = (valid(QF{s,c}) || valid(QM{s,c})) && ...
            (isempty(ref) || valid(QF{s,ref}) || valid(QM{s,ref}));   % relative: needs its reference
    end
    if ~any(has), continue; end
    C = struct();
    C.name = last_part(Conds{c});
    C.clr  = colors(mod(c-1, size(colors,1)) + 1, 1:3);
    shp = strtrim(char(shapes(mod(c-1, size(shapes,1)) + 1, :)));  if isempty(shp), shp = 'o'; end
    C.shp = shp;
    C.idx = c;
    nm = 0;
    for s = 1:nS
        if valid(QM{s,c}) && (isempty(ref) || valid(QM{s,ref})), nm = nm + 1; end
    end
    C.n = nm;
    % template = first subject with data here
    T = [];
    for s = find(has)
        if valid(QF{s,c}), T = QF{s,c}; else, T = QM{s,c}; end
        break
    end
    % levels: union over subjects
    X = [];
    for s = 1:nS
        if valid(QF{s,c}), X = [X, QF{s,c}.elic]; end %#ok<AGROW>
    end
    X = unique(X(isfinite(X)));
    C.lev = struct();
    for key = fieldnames(T.lev)'
        k = key{1};
        C.lev.(k) = struct('x', X, ...
            'F', lev_matrix(QF, c, ref, k, X), ...
            'M', lev_matrix(QM, c, ref, k, X));
    end
    C.sca = struct();
    for key = fieldnames(T.sca)'
        k = key{1};
        C.sca.(k) = struct('F', sca_vector(QF, c, ref, k), 'M', sca_vector(QM, c, ref, k));
    end
    C.cur = struct();
    for key = fieldnames(T.cur)'
        k = key{1};
        x = double(T.cur.(k).x(:)');
        C.cur.(k) = struct('x', x, 'F', cur_matrix(QF, c, ref, k, x), 'M', cur_matrix(QM, c, ref, k, x));
    end
    C.fam = struct('x',[], 'elic',[], 'F',[], 'M',[]);
    if ~isempty(T.fam.x)
        x = double(T.fam.x(:)');
        C.fam = struct('x', x, 'elic', X, 'F', fam_array(QF, c, ref, x, X), 'M', fam_array(QM, c, ref, x, X));
    end
    A.cols(end+1) = C;
end
end


function tf = valid(Q)
tf = isstruct(Q) && isfield(Q, 'ok') && Q.ok;
end


function Y = lev_matrix(Q, c, ref, k, X)
nS = size(Q, 1);
Y = nan(nS, numel(X));
for s = 1:nS
    if ~valid(Q{s,c}), continue; end
    y = on_levels(Q{s,c}, k, X);
    if ~isempty(ref)
        if ~valid(Q{s,ref}), continue; end
        y = y - on_levels(Q{s,ref}, k, X);
    end
    Y(s, :) = y;
end
end


function y = on_levels(q, k, X)
y = nan(1, numel(X));
[tf, loc] = ismember(q.elic, X);
v = q.lev.(k);
y(loc(tf)) = v(tf);
end


function v = sca_vector(Q, c, ref, k)
nS = size(Q, 1);
v = nan(nS, 1);
for s = 1:nS
    if ~valid(Q{s,c}) || ~isfield(Q{s,c}.sca, k), continue; end
    a = double(Q{s,c}.sca.(k));  if isempty(a), a = NaN; end
    if ~isempty(ref)
        if ~valid(Q{s,ref}), continue; end
        r = double(Q{s,ref}.sca.(k));  if isempty(r), r = NaN; end
        a = a - r;
    end
    v(s) = a(1);
end
end


function Y = cur_matrix(Q, c, ref, k, x)
nS = size(Q, 1);
Y = nan(nS, numel(x));
for s = 1:nS
    if ~valid(Q{s,c}) || ~isfield(Q{s,c}.cur, k), continue; end
    y = on_x(Q{s,c}.cur.(k), x);
    if ~isempty(ref)
        if ~valid(Q{s,ref}) || ~isfield(Q{s,ref}.cur, k), continue; end
        y = y - on_x(Q{s,ref}.cur.(k), x);
    end
    Y(s, :) = y;
end
end


function y = on_x(cv, x)
xs = double(cv.x(:)');  ys = double(cv.y(:)');
if isempty(xs) || isempty(ys), y = nan(1, numel(x)); return; end
if numel(xs) == numel(x) && all(abs(xs - x) <= 1e-6 * max(abs(x))), y = ys; return; end
y = interp1(xs, ys, x, 'linear', NaN);
end


function Y = fam_array(Q, c, ref, x, X)
nS = size(Q, 1);
Y = nan(nS, numel(X), numel(x));
for s = 1:nS
    if ~valid(Q{s,c}), continue; end
    y = fam_on(Q{s,c}.fam, x, X);
    if ~isempty(ref)
        if ~valid(Q{s,ref}), continue; end
        y = y - fam_on(Q{s,ref}.fam, x, X);
    end
    Y(s, :, :) = reshape(y, [1 size(y)]);
end
end


function y = fam_on(fm, x, X)
y = nan(numel(X), numel(x));
if isempty(fm.x) || isempty(fm.Y), return; end
for i = 1:numel(fm.elic)
    r = find(X == fm.elic(i), 1);
    if isempty(r) || i > size(fm.Y, 1), continue; end
    y(r, :) = on_x(struct('x', fm.x, 'y', fm.Y(i,:)), x);
end
end


% ══════════════════════════════════════════════════════════════════════════
function s = stats(X)
ok = isfinite(X);
n  = sum(ok, 1);
X0 = X;  X0(~ok) = 0;
mu = sum(X0, 1) ./ n;
d  = X - repmat(mu, size(X,1), 1);  d(~ok) = 0;
sd = sqrt(sum(d.^2, 1) ./ max(n - 1, 1));
mu(n == 0) = NaN;  sd(n == 0) = NaN;
s = struct('mean', mu, 'sd', sd, 'n', n);
end


function s = last_part(p)
q = strsplit(char(p), {'/','\'});
s = q{end};
end
