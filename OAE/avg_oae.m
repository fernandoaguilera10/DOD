function A = avg_oae(store, scale, all_Conds2Run, idx_plot_relative, o)
%AVG_OAE  Group data for one scale ('epl' | 'spl') from the per-subject store.
%
%   A = avg_oae(store, scale, all_Conds2Run, idx_plot_relative, o)
%     store   cell {nSubjects x nConditions} of saved OAE data structs
%   Every subject contributes one row per condition (NaN when missing), so
%   the means are true group means (the earlier running mean weighted later
%   subjects more). With idx_plot_relative set, each value is the subject's
%   change from its own reference condition (subjects without the reference
%   are left out of that condition).
%
%   A.cols          condition indices shown (reference removed when relative)
%   A.cf            band centres (kHz)
%   A.band{k}       nS x nBands values (dB, or SNR / change, see o.y_measure)
%   A.band_nf{k}    nS x nBands band noise floor (amplitude only; [] otherwise)
%   A.reg{k}        nS x 3 region values
%   A.fg, A.full{k} common log frequency grid and nS x nf full-resolution
%                   values (interpolated) for the mean curve
%   A.n(k)          subjects with data
%   plus the fields of the old average files (bandF, bandOAE, bandNF,
%   oae_band_std, all_oae_band, f, oae, nf) for downstream scripts.
if nargin < 5, o = oae_opts(); end
[nS, nC] = size(store);
rel = ~isempty(idx_plot_relative);
cols = 1:nC;
if rel, cols = setdiff(cols, idx_plot_relative); end
[cf, ~, ~] = oae_bands(o);
nb = numel(cf);
fg = 2 .^ linspace(log2(o.frange(1)), log2(o.frange(2)), 512);
snr = strcmp(o.y_measure, 'snr');
excl = strcmp(o.gate_avg, 'exclude');

% ── per subject / condition values ───────────────────────────────────────
V  = nan(nS, nb, nC);  NF = nan(nS, nb, nC);  R = nan(nS, 3, nC);
F  = nan(nS, numel(fg), nC);  FN = nan(nS, numel(fg), nC);
has = false(nS, nC);
for s = 1:nS
    for c = 1:nC
        D = [];
        if ~isempty(store{s,c}), D = oae_derive(store{s,c}, scale, o); end
        if isempty(D), continue; end
        has(s,c) = true;
        b = D.band;  r = D.reg;
        if snr
            bv = b.snr;  rv = r.snr;  full = D.oae - D.nf;
        else
            bv = b.oae;  rv = r.oae;  full = D.oae;
        end
        if excl, bv(~b.ok) = NaN;  rv(~r.ok) = NaN; end
        V(s,:,c)  = bv;   NF(s,:,c) = b.nf;   R(s,:,c) = rv;
        [fu, iu] = unique(D.f);
        if numel(fu) > 1
            F(s,:,c)  = interp1(fu, full(iu),  fg, 'linear', NaN);
            FN(s,:,c) = interp1(fu, D.nf(iu), fg, 'linear', NaN);
        end
    end
end

% ── relative to reference condition ─────────────────────────────────────
if rel
    ref = idx_plot_relative;
    for c = cols
        V(:,:,c) = V(:,:,c) - V(:,:,ref);
        R(:,:,c) = R(:,:,c) - R(:,:,ref);
        F(:,:,c) = F(:,:,c) - F(:,:,ref);
        has(:,c) = has(:,c) & has(:,ref);
    end
end

% ── pack ─────────────────────────────────────────────────────────────────
A = struct();
A.scale = upper(scale);  A.cols = cols;  A.cf = cf;  A.fg = fg;
A.relative = rel;  A.ref = idx_plot_relative;  A.opts = o;
nk = numel(cols);
A.band = cell(1,nk);  A.band_nf = cell(1,nk);  A.reg = cell(1,nk);
A.full = cell(1,nk);  A.full_nf = cell(1,nk);  A.n = zeros(1,nk);
for k = 1:nk
    c = cols(k);  m = has(:,c);
    v = V(:,:,c);   v(~m,:) = NaN;   A.band{k} = v;
    r = R(:,:,c);   r(~m,:) = NaN;   A.reg{k}  = r;
    f = F(:,:,c);   f(~m,:) = NaN;   A.full{k} = f;
    if ~rel && ~snr
        nf = NF(:,:,c);  nf(~m,:) = NaN;  A.band_nf{k} = nf;
        fn = FN(:,:,c);  fn(~m,:) = NaN;  A.full_nf{k} = fn;
    end
    A.n(k) = nnz(m);
end

% Fields of the previous average files (kept for downstream scripts)
A.bandF = cf(:);
A.f = cell(1,nk);  A.oae = cell(1,nk);  A.nf = cell(1,nk);
A.bandOAE = cell(1,nk);  A.bandNF = cell(1,nk);  A.oae_band_std = cell(1,nk);
A.all_oae_band = cell(nS, nk);
for k = 1:nk
    if A.n(k) == 0, continue; end
    A.f{k}       = fg;
    A.oae{k}     = mean(A.full{k}, 1, 'omitnan');
    A.bandOAE{k} = mean(A.band{k}, 1, 'omitnan');
    A.oae_band_std{k} = std(A.band{k}, 0, 1, 'omitnan');
    if ~isempty(A.band_nf{k})
        A.nf{k}     = mean(A.full_nf{k}, 1, 'omitnan');
        A.bandNF{k} = mean(A.band_nf{k}, 1, 'omitnan');
    end
    for s = 1:nS
        if all(isnan(A.band{k}(s,:))), continue; end
        A.all_oae_band{s,k} = A.band{k}(s,:);
    end
end
end
